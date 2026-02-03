//
//  ConnectionStatus.swift
//  Aezakmi
//
//  Created by petar on 04.02.2026.
//

import Foundation
import SwiftUI

enum ConnectionStatus: String, Codable, CaseIterable {
  case disconnected
  case connecting
  case connected
  case unknown
  
  var displayName: String {
    switch self {
    case .disconnected: return "disconnected".localized
    case .connecting: return "connecting".localized
    case .connected: return "connected".localized
    case .unknown: return "unknown".localized
    }
  }
  
  var color: Color {
    switch self {
    case .connected: return .statusConnected
    case .connecting: return .statusConnecting
    case .disconnected, .unknown: return .statusError
    }
  }
  
  var iconName: String {
    switch self {
    case .connected: return "checkmark.circle.fill"
    case .connecting: return "ellipsis.circle.fill"
    case .disconnected: return "xmark.circle.fill"
    case .unknown: return "questionmark.circle.fill"
    }
  }
  
  var isActive: Bool {
    self == .connected || self == .connecting
  }
}
