//
//  DeviceType.swift
//  Aezakmi
//
//  Created by petar on 04.02.2026.
//

import Foundation
import SwiftUI

enum DeviceType: String, Codable, CaseIterable {
  case bluetooth
  case network
  
  var displayName: String {
    switch self {
    case .bluetooth: return "bluetooth_tab".localized
    case .network: return "network_tab".localized
    }
  }
  
  var iconName: String {
    switch self {
    case .bluetooth: return "antenna.radiowaves.left.and.right"
    case .network: return "wifi"
    }
  }
  
  var color: Color {
    switch self {
    case .bluetooth: return .bluetooth
    case .network: return .network
    }
  }
  
  var gradient: LinearGradient {
    switch self {
    case .bluetooth:
      return LinearGradient(
        colors: [.bluetooth.opacity(0.8), .bluetooth],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case .network:
      return LinearGradient(
        colors: [.network.opacity(0.8), .network],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }
  }
}
