//
//  BluetoothScannerViewModel.swift
//  Aezakmi
//
//  Created by petar on 05.02.2026.
//

import Foundation
import SwiftUI
import Combine
import CoreBluetooth

final class BluetoothScannerViewModel: ObservableObject {
  let bluetoothScanner: BluetoothScanner
  private let databaseService: DatabaseService
  @Published var discoveredDevices: [BluetoothDevice] = []
  @Published var isScanning = false
  @Published var scanProgress: Double = 0.0
  @Published var bluetoothState: CBManagerState = .unknown
  @Published var errorMessage: String?
  @Published var showAlert = false
  @Published var showSaveConfirmation = false
  @Published var lastSavedSession: ScanSession?
  private var hasSavedCurrentSession = false
  
  private var cancellables = Set<AnyCancellable>()
  var deviceCount: Int {
    discoveredDevices.count
  }
  
  init(bluetoothScanner: BluetoothScanner = BluetoothScanner(), databaseService: DatabaseService = DatabaseService.shared) {
    self.bluetoothScanner = bluetoothScanner
    self.databaseService = databaseService
    setupBindings()
  }
  
  deinit {
    cancellables.forEach { $0.cancel() }
  }
  
  private func setupBindings() {
    bluetoothScanner.$discoveredDevices
      .receive(on: DispatchQueue.main)
      .assign(to: \.discoveredDevices, on: self)
      .store(in: &cancellables)
    
    bluetoothScanner.$isScanning
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isScanning in
        self?.isScanning = isScanning
        if !isScanning && !(self?.discoveredDevices.isEmpty ?? true) {
          self?.saveScanSession()
        }
      }
      .store(in: &cancellables)
    
    bluetoothScanner.$scanProgress
      .receive(on: DispatchQueue.main)
      .assign(to: \.scanProgress, on: self)
      .store(in: &cancellables)
    
    bluetoothScanner.$bluetoothState
      .receive(on: DispatchQueue.main)
      .assign(to: \.bluetoothState, on: self)
      .store(in: &cancellables)
    
    bluetoothScanner.$errorMessage
      .receive(on: DispatchQueue.main)
      .sink { [weak self] error in
        guard let self = self else { return }
        self.errorMessage = error
        if error != nil {
          self.showAlert = true
        }
      }
      .store(in: &cancellables)
  }
  
  func toggleScan() {
    if isScanning {
      bluetoothScanner.stopScanning()
    } else {
      startScanning()
    }
  }
  
  func startScanning() {
    guard bluetoothState == .poweredOn else {
      showBluetoothError()
      return
    }
    discoveredDevices.removeAll()
    hasSavedCurrentSession = false
    bluetoothScanner.startScanning()
  }
  
  private func saveScanSession() {
    guard !discoveredDevices.isEmpty || hasSavedCurrentSession else { return }
    let startTime = bluetoothScanner.scanStartTime ?? Date()
    let endTime = bluetoothScanner.scanEndTime ?? Date()
    var session = ScanSession(
      startTime: startTime,
      endTime: endTime,
      bluetoothDevices: discoveredDevices,
      networkDevices: [],
      scanType: .bluetooth
    )
    databaseService.saveScanSession(session)
    lastSavedSession = session
    showSaveConfirmation = true
    hasSavedCurrentSession = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
      self?.showSaveConfirmation = false
    }
  }
  
  func showBluetoothError() {
    let message: String
    switch bluetoothState {
    case .poweredOff:
      message = "bluetooth_disabled".localized
    case .unauthorized:
      message = "bluetooth_unauthorized_message".localized
    case .unsupported:
      message = "bluetooth_unsupported".localized
    default:
      message = "bluetooth_unknown".localized
    }
    errorMessage = message
    showAlert = true
  }
}

extension CBManagerState: CustomStringConvertible {
  public var description: String {
    switch self {
    case .unknown: return "unknown".localized
    case .resetting: return "bluetooth_resetting".localized
    case .unsupported: return "bluetooth_unsupported".localized
    case .unauthorized: return "bluetooth_unauthorized".localized
    case .poweredOff: return "bluetooth_off".localized
    case .poweredOn: return "bluetooth_on".localized
    @unknown default: return "unknown".localized
    }
  }
}
