//
//  Color + ext.swift
//  Aezakmi
//
//  Created by petar on 04.02.2026.
//

import SwiftUI

extension Color {
  static let primary = Color("PrimaryMain")
  static let accentApp = Color("Accent")
  static let mainBackground = Color("Background")
  static let cardsBackground = Color("CardBackground")
  static let statusConnected = Color("Connected")
  static let statusConnecting = Color("Connecting")
  static let statusError = Color("Error")
  static let textPrim = Color("TextPrimary")
  static let textSecond = Color("TextSecondary")
  static let textTertia = Color("TextTertiary")
  
  static let bluetooth = Color(hex: "#3182CE")
  static let network = Color(hex: "#805AD5")
  static let rssiStrong = Color(hex: "#38A169")
  static let rssiMedium = Color(hex: "#D69E2E")
  static let rssiWeak = Color(hex: "#E53E3E")
}

extension Color {
  static var scanButtonGradient: LinearGradient {
    LinearGradient(
      colors: [.accent, .primary],
      startPoint: .leading,
      endPoint: .trailing
    )
  }
  
  static var progressGradient: LinearGradient {
    LinearGradient(
      colors: [.statusConnecting, .statusConnected],
      startPoint: .leading,
      endPoint: .trailing
    )
  }
  
  static func rssiGradient(for rssi: Int) -> LinearGradient {
    let colors: [Color]
    switch rssi {
    case ..<(-80):
      colors = [.rssiWeak, Color(hex: "#742A2A")]
    case -80..<(-70):
      colors = [.rssiWeak, .rssiMedium]
    case -70..<(-60):
      colors = [.rssiMedium, .rssiStrong]
    case -60..<(-50):
      colors = [.rssiStrong, Color(hex: "#2F855A")]
    default:
      colors = [Color(hex: "#276749"), Color(hex: "#22543D")]
    }
    return LinearGradient(
      gradient: Gradient(colors: colors),
      startPoint: .leading,
      endPoint: .trailing
    )
  }
}

extension Color {
  static var selected: Color {
    .accent.opacity(0.1)
  }
  
  static var cardShadow: Color {
    .primary.opacity(0.1)
  }
  
  static var disabled: Color {
    .textTertiary.opacity(0.3)
  }
}

extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3:
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (255, 0, 0, 0)
    }
    
    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }
}

extension ScanSession.ScanType {
  var color: Color {
    switch self {
    case .bluetooth:
      return Color.bluetooth.opacity(0.3)
    case .network:
      return Color.network.opacity(0.3)
    case .combined:
      return Color.gray.opacity(0.3)
    }
  }
}

