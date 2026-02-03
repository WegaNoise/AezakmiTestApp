//
//  BluetoothDeviceDetailViewModel.swift
//  Aezakmi
//
//  Created by petar on 05.02.2026.
//

import Foundation
import Combine
import SwiftUI
import CoreBluetooth

final class BluetoothDeviceDetailViewModel: ObservableObject {
  @Published var device: BluetoothDevice
  private let scanner: BluetoothScanner
  private var cancellables = Set<AnyCancellable>()
  @Published var showAlert = false
  @Published var alertMessage: String = ""
  @Published var alertTitle: String = ""
  
  var formattedLastSeen: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: device.lastSeen)
  }
  
  var connectionButtonIcon: String {
    switch device.status {
    case .connected: return "xmark.circle.fill"
    case .connecting: return "ellipsis.circle.fill"
    case .disconnected, .unknown: return "link.circle.fill"
    }
  }
  
  var connectionButtonTitle: String {
    switch device.status {
    case .connected: return "disconnect".localized
    case .connecting: return "connecting".localized
    case .disconnected, .unknown: return "connect".localized
    }
  }
  
  var connectionButtonColor: Color {
    switch device.status {
    case .connected: return .statusError
    case .connecting: return .statusConnecting
    case .disconnected, .unknown: return .statusConnected
    }
  }
  
  var isConnectionDisabled: Bool {
    device.status == .connecting || scanner.bluetoothState != .poweredOn
  }
  
  init(device: BluetoothDevice, scanner: BluetoothScanner) {
    self.device = device
    self.scanner = scanner
  }
  
  func startObserving() {
    scanner.$discoveredDevices
      .receive(on: DispatchQueue.main)
      .sink { [weak self] devices in
        guard let self = self else { return }
        if let updatedDevice = devices.first(where: { $0.id == self.device.id }) {
          let oldStatus = self.device.status
          self.device = updatedDevice
          if updatedDevice.status != oldStatus {
            self.showStatusChangeMessage(oldStatus: oldStatus, newStatus: updatedDevice.status)
          }
        }
      }
      .store(in: &cancellables)
  }
  
  func stopObserving() {
    cancellables.forEach { $0.cancel() }
  }
  
  func toggleConnection() {
    switch device.status {
    case .connected:
      disconnect()
    case .disconnected, .unknown:
      connect()
    case .connecting:
      break
    }
  }
  
  private func connect() {
    scanner.connect(to: device) { [weak self] result in
      guard let self = self else { return }
      
      DispatchQueue.main.async {
        switch result {
        case .success:
          self.alertTitle = "connection_success".localized
          self.alertMessage = "connected_successfully".localized
        case .failure(let error):
          self.alertTitle = "connection_error".localized
          self.alertMessage = error.localizedDescription
        }
        self.showAlert = true
      }
    }
  }
  
  private func disconnect() {
    scanner.disconnect(from: device)
    alertTitle = "disconnection_success".localized
    alertMessage = "disconnected_successfully".localized
    showAlert = true
  }
  
  private func showStatusChangeMessage(oldStatus: ConnectionStatus, newStatus: ConnectionStatus) {
    switch newStatus {
    case .connected:
      alertTitle = "connection_status".localized
      alertMessage = "connected".localized
      showAlert = true
    case .disconnected:
      if oldStatus == .connected {
        alertTitle = "connection_status".localized
        alertMessage = "disconnected".localized
        showAlert = true
      }
    default:
      break
    }
  }
}
