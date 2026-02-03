//
//  NetworkDeviceRow.swift
//  Aezakmi
//
//  Created by petar on 06.02.2026.
//

import Foundation
import SwiftUI

struct NetworkDeviceRow: View {
  let device: NetworkDevice

  var body: some View {
    HStack(spacing: 16) {
      deviceIconView
      deviceInfoView
      Spacer()
      deviceLocationView
    }
    .padding(16)
    .background(Color.cardsBackground)
    .cornerRadius(14)
    .shadow(color: .cardShadow, radius: 4, x: 0, y: 2)
  }
  
  private var deviceIconView: some View {
    ZStack {
      Circle()
        .fill(Color.network.opacity(device.isLocalDevice ? 0.15 : 0.08))
        .frame(width: 50, height: 50)
      Image(systemName: "wifi")
        .font(.system(size: 22))
        .foregroundColor(Color.network.opacity(device.isLocalDevice ? 1.0 : 0.6))
    }
  }
  
  private var deviceInfoView: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(device.displayName)
        .font(.headline)
        .foregroundColor(.textPrim)
        .lineLimit(1)
      Text(device.ipAddress)
        .font(.caption)
        .foregroundColor(.textSecond)
      if let hostname = device.hostname, hostname != device.ipAddress {
        Text(hostname)
          .font(.caption2)
          .foregroundColor(.textTertia)
          .lineLimit(1)
      }
    }
  }
  
  private var deviceLocationView: some View {
    VStack(alignment: .trailing, spacing: 6) {
      HStack(spacing: 4) {
        Circle()
          .fill(device.isLocalDevice ? Color.statusConnected : Color.textTertia)
          .frame(width: 8, height: 8)
        Text(device.isLocalDevice ? "local".localized : "remote".localized)
          .font(.caption)
          .foregroundColor(device.isLocalDevice ? .statusConnected : .textTertia)
      }
      if let mac = device.macAddress {
        Text(mac.prefix(8))
          .font(.caption2)
          .foregroundColor(.textTertia)
          .lineLimit(1)
      }
    }
  }
}
