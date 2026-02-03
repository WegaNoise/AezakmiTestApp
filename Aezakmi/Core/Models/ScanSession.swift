//
//  ScanSession.swift
//  Aezakmi
//
//  Created by petar on 04.02.2026.
//

import Foundation

struct ScanSession: Identifiable, Codable, Equatable {
  let id: UUID
  let startTime: Date
  var endTime: Date?
  var duration: TimeInterval?
  var bluetoothDevices: [BluetoothDevice]
  var networkDevices: [NetworkDevice]
  var scanType: ScanType
  
  enum ScanType: String, Codable {
    case bluetooth
    case network
    case combined
    
    var displayName: String {
      switch self {
      case .bluetooth: return "bluetooth_tab".localized
      case .network: return "network_tab".localized
      case .combined: return "combined_scan".localized
      }
    }
    
    var icon: String {
      switch self {
      case .bluetooth: return "antenna.radiowaves.left.and.right"
      case .network: return "wifi"
      case .combined: return "cylinder.split.1x2.fill"
      }
    }
  }
  
  init(
    id: UUID = UUID(),
    startTime: Date = Date(),
    endTime: Date? = nil,
    bluetoothDevices: [BluetoothDevice] = [],
    networkDevices: [NetworkDevice] = [],
    scanType: ScanType = .combined
  ) {
    self.id = id
    self.startTime = startTime
    self.endTime = endTime
    self.bluetoothDevices = bluetoothDevices
    self.networkDevices = networkDevices
    self.scanType = scanType
    
    if let endTime = endTime {
      self.duration = endTime.timeIntervalSince(startTime)
    }
  }
  
  mutating func completeScan() {
    duration = endTime!.timeIntervalSince(startTime)
  }
  
  mutating func addBluetoothDevice(_ device: BluetoothDevice) {
    if let index = bluetoothDevices.firstIndex(where: { $0.peripheralId == device.peripheralId }) {
      bluetoothDevices[index] = device
    } else {
      bluetoothDevices.append(device)
    }
  }
  
  mutating func addNetworkDevice(_ device: NetworkDevice) {
    if let index = networkDevices.firstIndex(where: { $0.ipAddress == device.ipAddress }) {
      networkDevices[index] = device
    } else {
      networkDevices.append(device)
    }
  }
}

extension ScanSession {
  var totalDevices: Int {
    bluetoothDevices.count + networkDevices.count
  }
  
  var formattedDuration: String {
    guard let duration = duration else { return "in_progress".localized }
    if duration < 60 {
      return String(format: "%.1f %@", duration, "seconds".localized)
    } else {
      let minutes = Int(duration / 60)
      let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
      return String(format: "min_sec_format".localized, minutes, seconds)
    }
  }
  
  var formattedDate: String {
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    
    if Calendar.current.isDateInToday(startTime) {
      formatter.dateFormat = "HH:mm"
      return "\("today".localized), \(formatter.string(from: startTime))"
    } else if Calendar.current.isDateInYesterday(startTime) {
      formatter.dateFormat = "HH:mm"
      return "\("yesterday".localized), \(formatter.string(from: startTime))"
    } else {
      formatter.dateStyle = .short
      formatter.timeStyle = .short
      return formatter.string(from: startTime)
    }
  }
  
  var deviceStats: String {
    var stats: [String] = []
    if !bluetoothDevices.isEmpty {
      let count = bluetoothDevices.count
      stats.append("\(count) \("bluetooth_tab".localized.lowercased())")
    }
    if !networkDevices.isEmpty {
      let count = networkDevices.count
      stats.append("\(count) \("network_tab".localized.lowercased())")
    }
    return stats.isEmpty ? "no_devices_message".localized : stats.joined(separator: ", ")
  }
}
