//
//  NetworkDevice.swift
//  Aezakmi
//
//  Created by petar on 04.02.2026.
//

import Foundation

struct NetworkDevice: Identifiable, Codable, Equatable {
  let id: UUID
  var ipAddress: String
  var macAddress: String?
  var hostname: String?
  var vendor: String?
  var isLocalDevice: Bool
  var lastSeen: Date
  var ports: [Int]?
  var responseTime: TimeInterval?
  
  init(
    id: UUID = UUID(),
    ipAddress: String,
    macAddress: String? = nil,
    hostname: String? = nil,
    vendor: String? = nil,
    isLocalDevice: Bool = false,
    ports: [Int]? = nil,
    responseTime: TimeInterval? = nil
  ) {
    self.id = id
    self.ipAddress = ipAddress
    self.macAddress = macAddress
    self.hostname = hostname
    self.vendor = vendor
    self.isLocalDevice = isLocalDevice
    self.ports = ports
    self.responseTime = responseTime
    self.lastSeen = Date()
  }
  
  static func == (lhs: NetworkDevice, rhs: NetworkDevice) -> Bool {
    lhs.ipAddress == rhs.ipAddress
  }
}

extension NetworkDevice {
  var displayName: String {
    hostname ?? ipAddress
  }
  
  var formattedMAC: String {
    macAddress ?? "mac_unknown".localized
  }
  
  var formattedResponseTime: String? {
    guard let responseTime = responseTime else { return nil }
    return String(format: "%.2f ms", responseTime * 1000)
  }
  
  var openPortsDescription: String? {
    guard let ports = ports, !ports.isEmpty else { return nil }
    return ports.map { String($0) }.joined(separator: ", ")
  }
}
