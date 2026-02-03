//
//  BluetoothDevice.swift
//  Aezakmi
//
//  Created by petar on 04.02.2026.
//

import Foundation
import CoreBluetooth
import SwiftUI

struct BluetoothDevice: Identifiable, Codable, Equatable {
  let id: UUID
  let peripheralId: UUID
  var name: String?
  let uuid: String
  var rssi: Int
  var status: ConnectionStatus
  var advertisementData: [String: Any]?
  var lastSeen: Date
  var services: [String]?
  
  init(
    id: UUID = UUID(),
    peripheral: CBPeripheral? = nil,
    name: String? = nil,
    uuid: String,
    rssi: Int = -100,
    status: ConnectionStatus = .unknown,
    advertisementData: [String: Any]? = nil,
    services: [String]? = nil
  ) {
    self.id = id
    self.peripheralId = peripheral?.identifier ?? UUID()
    self.name = name ?? peripheral?.name
    self.uuid = uuid
    self.rssi = rssi
    self.status = status
    self.advertisementData = advertisementData
    self.services = services
    self.lastSeen = Date()
  }
  
  enum CodingKeys: String, CodingKey {
    case id, peripheralId, name, uuid, rssi, status, lastSeen, services
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(UUID.self, forKey: .id)
    peripheralId = try container.decode(UUID.self, forKey: .peripheralId)
    name = try container.decodeIfPresent(String.self, forKey: .name)
    uuid = try container.decode(String.self, forKey: .uuid)
    rssi = try container.decode(Int.self, forKey: .rssi)
    status = try container.decode(ConnectionStatus.self, forKey: .status)
    lastSeen = try container.decode(Date.self, forKey: .lastSeen)
    services = try container.decodeIfPresent([String].self, forKey: .services)
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(peripheralId, forKey: .peripheralId)
    try container.encodeIfPresent(name, forKey: .name)
    try container.encode(uuid, forKey: .uuid)
    try container.encode(rssi, forKey: .rssi)
    try container.encode(status, forKey: .status)
    try container.encode(lastSeen, forKey: .lastSeen)
    try container.encodeIfPresent(services, forKey: .services)
  }
  
  static func == (lhs: BluetoothDevice, rhs: BluetoothDevice) -> Bool {
    lhs.peripheralId == rhs.peripheralId
  }
}

extension BluetoothDevice {
  var displayName: String {
    if let name = name, !name.isEmpty {
      return name
    } else if !uuid.isEmpty {
      return String(format: "unknown_device_format".localized, uuid.prefix(8) as CVarArg)
    } else {
      return "unknown".localized
    }
  }
  
  var formattedRSSI: String {
    "\(rssi) dBm"
  }
  
  var signalStrength: SignalStrength {
    switch rssi {
    case ..<(-80):
      return .weak
    case -80..<(-60):
      return .medium
    case -60..<0:
      return .strong
    default:
      return .unknown
    }
  }
  
  enum SignalStrength {
    case weak, medium, strong, unknown
    
    var description: String {
      switch self {
      case .weak: return "weak_signal".localized
      case .medium: return "medium_signal".localized
      case .strong: return "strong_signal".localized
      case .unknown: return "unknown".localized
      }
    }
    
    var color: Color {
      switch self {
      case .weak: return .rssiWeak
      case .medium: return .rssiMedium
      case .strong: return .rssiStrong
      case .unknown: return .textTertia
      }
    }
  }
}
