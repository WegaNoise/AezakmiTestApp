//
//  NetworkScanner.swift
//  Aezakmi
//
//  Created by petar on 05.02.2026.
//

import Foundation
import Combine
import MMLanScan

class NetworkScanner: NSObject, ObservableObject {
  @Published var isScanning = false
  @Published var discoveredDevices: [NetworkDevice] = []
  @Published var scanProgress: Double = 0.0
  @Published var errorMessage: String?
  private var lanScanner: MMLANScanner?
  private var scanTimer: Timer?
  var scanStartTime: Date?
  var scanEndTime: Date?
  private let scanTimeout: TimeInterval = 15.0
  private var deviceDictionary: [String: NetworkDevice] = [:]
  
  func startScan() {
    guard !isScanning else { return }
    resetScanState()
    isScanning = true
    scanStartTime = Date()
    scanEndTime = nil
    lanScanner = MMLANScanner(delegate: self)
    lanScanner?.start()
    startProgressTimer()
    scheduleAutoStop()
  }
  
  func stopScan() {
    guard isScanning else { return }
    lanScanner?.stop()
    lanScanner = nil
    scanTimer?.invalidate()
    scanTimer = nil
    isScanning = false
    scanProgress = 1.0
    scanEndTime = Date()
  }
  
  var deviceCount: Int {
    discoveredDevices.count
  }
  
  var localDevices: [NetworkDevice] {
    discoveredDevices.filter { $0.isLocalDevice }
  }
  
  func getDevice(by ipAddress: String) -> NetworkDevice? {
    deviceDictionary[ipAddress]
  }
  
  func clearDevices() {
    discoveredDevices.removeAll()
    deviceDictionary.removeAll()
  }
  
  private func resetScanState() {
    discoveredDevices.removeAll()
    deviceDictionary.removeAll()
    scanProgress = 0.0
    errorMessage = nil
  }
  
  private func startProgressTimer() {
    scanTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
      guard let self = self, let startTime = self.scanStartTime, self.isScanning else { return }
      let elapsed = Date().timeIntervalSince(startTime)
      let progress = min(elapsed / self.scanTimeout, 1.0)
      self.scanProgress = progress
      if progress >= 1.0 {
        self.stopScan()
      }
    }
  }
  
  private func scheduleAutoStop() {
    DispatchQueue.main.asyncAfter(deadline: .now() + scanTimeout) { [weak self] in
      self?.stopScan()
    }
  }
  
  private func updateDevice(_ mmDevice: MMDevice) {
    let device = convertToNetworkDevice(mmDevice)
    
    if let existingDevice = deviceDictionary[device.ipAddress] {
      var updatedDevice = existingDevice
      updatedDevice.hostname = device.hostname ?? existingDevice.hostname
      updatedDevice.macAddress = device.macAddress ?? existingDevice.macAddress
      updatedDevice.vendor = device.vendor ?? existingDevice.vendor
      updatedDevice.lastSeen = Date()
      deviceDictionary[device.ipAddress] = updatedDevice
      if let index = discoveredDevices.firstIndex(where: { $0.ipAddress == device.ipAddress }) {
        discoveredDevices[index] = updatedDevice
      }
    } else {
      deviceDictionary[device.ipAddress] = device
      discoveredDevices.append(device)
      discoveredDevices.sort { ip1, ip2 in
        ip1.ipAddress.compare(ip2.ipAddress, options: .numeric) == .orderedAscending
      }
    }
  }
  
  private func convertToNetworkDevice(_ mmDevice: MMDevice) -> NetworkDevice {
    NetworkDevice(
      ipAddress: mmDevice.ipAddress,
      macAddress: mmDevice.macAddress,
      hostname: mmDevice.hostname ?? mmDevice.ipAddress,
      vendor: mmDevice.brand,
      isLocalDevice: mmDevice.isLocalDevice
    )
  }
}

extension NetworkScanner: MMLANScannerDelegate {
  
  func lanScanDidFindNewDevice(_ device: MMDevice!) {
    DispatchQueue.main.async { [weak self] in
      self?.updateDevice(device)
    }
  }
  
  func lanScanDidFinishScanning(with status: MMLanScannerStatus) {
    DispatchQueue.main.async { [weak self] in
      self?.stopScan()
      switch status {
      case MMLanScannerStatusFinished, MMLanScannerStatusCancelled:
        self?.errorMessage = nil
        print("Scaning finished")
      default:
        self?.errorMessage = "network_failed".localized
      }
    }
  }
  
  func lanScanDidFailedToScan() {
    DispatchQueue.main.async { [weak self] in
      self?.stopScan()
      self?.errorMessage = "network_failed".localized
    }
  }
}
