//
//  BluetoothScanner.swift
//  Aezakmi
//
//  Created by petar on 05.02.2026.
//

import Foundation
import CoreBluetooth
import Combine

class BluetoothScanner: NSObject, ObservableObject {
  @Published var isScanning = false
  @Published var discoveredDevices: [BluetoothDevice] = []
  @Published var scanProgress: Double = 0.0
  @Published var errorMessage: String?
  @Published var bluetoothState: CBManagerState = .unknown
  
  private var centralManager: CBCentralManager!
  private var scanTimer: Timer?
  var scanStartTime: Date?
  var scanEndTime: Date?
  private let scanTimeout: TimeInterval = 15.0
  
  private var peripherals: [UUID: CBPeripheral] = [:]
  private var deviceDictionary: [UUID: BluetoothDevice] = [:]
  
  private var connectionCallbacks: [UUID: (Result<Void, Error>) -> Void] = [:]
  
  override init() {
    super.init()
    self.centralManager = CBCentralManager(delegate: self, queue: .main)
  }
  
  deinit {
    stopScanning()
    disconnectAll()
  }
  
  func startScanning() {
    guard centralManager.state == .poweredOn else {
      handleBluetoothError(state: centralManager.state)
      return
    }
    guard !isScanning else { return }
    resetScanState()
    isScanning = true
    scanStartTime = Date()
    scanEndTime = nil
    let options: [String: Any] = [CBCentralManagerScanOptionAllowDuplicatesKey: false]
    centralManager.scanForPeripherals(withServices: nil, options: options)
    startProgressTimer()
    scheduleAutoStop()
  }
  
  func stopScanning() {
    guard isScanning else { return }
    centralManager.stopScan()
    scanTimer?.invalidate()
    scanTimer = nil
    scanProgress = 1.0
    scanEndTime = Date()
    isScanning = false
  }
  
  func connect(to device: BluetoothDevice, completion: ((Result<Void, Error>) -> Void)? = nil) {
    guard let peripheral = peripherals[device.peripheralId] else {
      completion?(.failure(NSError(domain: "BluetoothScanner", code: 404,userInfo: [NSLocalizedDescriptionKey: "Device not found"])))
      return
    }
    
    guard peripheral.state != .connected && peripheral.state != .connecting else {
      completion?(.failure(NSError(domain: "BluetoothScanner", code: 400, userInfo: [NSLocalizedDescriptionKey: "Already connected or connecting"])))
      return
    }
    
    if let completion = completion {
      connectionCallbacks[device.peripheralId] = completion
    }
    updateDeviceStatus(peripheralId: device.peripheralId, status: .connecting)
    centralManager.connect(peripheral, options: nil)
  }
  
  func disconnect(from device: BluetoothDevice) {
    guard let peripheral = peripherals[device.peripheralId] else { return }
    
    if peripheral.state == .connected || peripheral.state == .connecting {
      centralManager.cancelPeripheralConnection(peripheral)
      updateDeviceStatus(peripheralId: device.peripheralId, status: .disconnected)
    }
  }
  
  func disconnectAll() {
    for peripheral in peripherals.values {
      if peripheral.state == .connected || peripheral.state == .connecting {
        centralManager.cancelPeripheralConnection(peripheral)
      }
    }
    for device in discoveredDevices {
      if let index = discoveredDevices.firstIndex(where: { $0.id == device.id }) {
        discoveredDevices[index].status = .disconnected
      }
    }
  }
  
  func getConnectionStatus(for device: BluetoothDevice) -> CBPeripheralState {
    return peripherals[device.peripheralId]?.state ?? .disconnected
  }
  
  var deviceCount: Int {
    discoveredDevices.count
  }
  
  var connectedDevices: [BluetoothDevice] {
    discoveredDevices.filter { $0.status == .connected }
  }
  
  func getDevice(by id: UUID) -> BluetoothDevice? {
    deviceDictionary[id]
  }
  
  func clearDevices() {
    discoveredDevices.removeAll()
    deviceDictionary.removeAll()
    peripherals.removeAll()
  }
  
  private func resetScanState() {
    discoveredDevices.removeAll()
    deviceDictionary.removeAll()
    peripherals.removeAll()
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
        self.stopScanning()
      }
    }
  }
  
  private func scheduleAutoStop() {
    DispatchQueue.main.asyncAfter(deadline: .now() + scanTimeout) { [weak self] in
      self?.stopScanning()
    }
  }
  
  private func handleBluetoothError(state: CBManagerState) {
    let message: String
    switch state {
    case .unsupported:
      message = "bluetooth_unsupported".localized
    case .unauthorized:
      message = "bluetooth_unauthorized_message".localized
    case .poweredOff:
      message = "bluetooth_disabled".localized
    case .resetting:
      message = "bluetooth_resetting".localized
    case .unknown:
      message = "bluetooth_unknown".localized
    case .poweredOn:
      message = ""
    @unknown default:
      message = "bluetooth_unknown".localized
    }
    if !message.isEmpty {
      errorMessage = message
    }
  }
  
  private func updateDevice(_ peripheral: CBPeripheral, rssi: Int, advertisementData: [String: Any]?) {
    let uuid = peripheral.identifier
    peripherals[uuid] = peripheral
    let currentStatus: ConnectionStatus
    switch peripheral.state {
    case .connected:
      currentStatus = .connected
    case .connecting:
      currentStatus = .connecting
    case .disconnected:
      currentStatus = .disconnected
    @unknown default:
      currentStatus = .unknown
    }
    
    let device = BluetoothDevice(
      peripheral: peripheral,
      name: peripheral.name,
      uuid: uuid.uuidString,
      rssi: rssi,
      status: currentStatus,
      advertisementData: advertisementData
    )
    
    if let existingDevice = deviceDictionary[uuid] {
      var updatedDevice = existingDevice
      updatedDevice.rssi = rssi
      updatedDevice.lastSeen = Date()
      updatedDevice.advertisementData = advertisementData
      updatedDevice.status = currentStatus
      deviceDictionary[uuid] = updatedDevice
      if let index = discoveredDevices.firstIndex(where: { $0.peripheralId == uuid }) {
        discoveredDevices[index] = updatedDevice
      }
    } else {
      deviceDictionary[uuid] = device
      discoveredDevices.append(device)
      discoveredDevices.sort { $0.rssi > $1.rssi }
    }
  }
  
  private func updateDeviceStatus(peripheralId: UUID, status: ConnectionStatus) {
    if let index = discoveredDevices.firstIndex(where: { $0.peripheralId == peripheralId }) {
      discoveredDevices[index].status = status
    }
    
    if var device = deviceDictionary[peripheralId] {
      device.status = status
      deviceDictionary[peripheralId] = device
    }
  }
  
  private func handleConnectionCallback(for peripheralId: UUID, result: Result<Void, Error>) {
    if let callback = connectionCallbacks.removeValue(forKey: peripheralId) {
      callback(result)
    }
  }
}

extension BluetoothScanner: CBCentralManagerDelegate {
  
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    bluetoothState = central.state
    switch central.state {
    case .poweredOn:
      errorMessage = nil
    case .poweredOff, .unauthorized, .unsupported, .resetting, .unknown:
      if isScanning {
        stopScanning()
        handleBluetoothError(state: central.state)
      }
    @unknown default:
      break
    }
  }
  
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,advertisementData: [String: Any], rssi RSSI: NSNumber) {
    updateDevice(peripheral, rssi: RSSI.intValue, advertisementData: advertisementData)
  }
  
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    print("Connected to: \(peripheral.name ?? "Unknown")")
    updateDeviceStatus(peripheralId: peripheral.identifier, status: .connected)
    handleConnectionCallback(for: peripheral.identifier, result: .success(()))
  }
  
  func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    print("Failed to connect: \(error?.localizedDescription ?? "Unknown error")")
    updateDeviceStatus(peripheralId: peripheral.identifier, status: .disconnected)
    let error = error ?? NSError(domain: "BluetoothScanner", code: 500,
                                 userInfo: [NSLocalizedDescriptionKey: "Connection failed"])
    handleConnectionCallback(for: peripheral.identifier, result: .failure(error))
  }
  
  func centralManager(_ central: CBCentralManager, didDisconnect peripheral: CBPeripheral, error: Error?) {
    print("Disconnected from: \(peripheral.name ?? "Unknown")")
    updateDeviceStatus(peripheralId: peripheral.identifier, status: .disconnected)
  }
}
