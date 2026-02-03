//
//  BluetoothDeviceRow.swift
//  Aezakmi
//
//  Created by petar on 05.02.2026.
//

import SwiftUI

struct BluetoothDeviceRow: View {
  let device: BluetoothDevice
  
  var body: some View {
    HStack(spacing: 16) {
      deviceIconView
      deviceInfoView
      Spacer()
      deviceStatusView
    }
    .padding(16)
    .background(Color.cardsBackground)
    .cornerRadius(14)
    .shadow(color: .cardShadow, radius: 4, x: 0, y: 2)
  }
  
  private var deviceIconView: some View {
    ZStack {
      Circle()
        .fill(device.status.color.opacity(0.15))
        .frame(width: 50, height: 50)
      Image(systemName: "antenna.radiowaves.left.and.right")
        .font(.system(size: 22))
        .foregroundColor(device.status.color)
    }
  }
  
  private var deviceInfoView: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(device.displayName)
        .font(.headline)
        .foregroundColor(.textPrim)
        .lineLimit(1)
      Text(device.uuid.prefix(8))
        .font(.caption)
        .foregroundColor(.textSecond)
        .lineLimit(1)
    }
  }
  
  private var deviceStatusView: some View {
    VStack(alignment: .trailing, spacing: 6) {
      HStack(spacing: 4) {
        Circle()
          .fill(device.status.color)
          .frame(width: 8, height: 8)
        Text(device.status.displayName)
          .font(.caption)
          .foregroundColor(device.status.color)
      }
      VStack(spacing: 2) {
        RoundedRectangle(cornerRadius: 2)
          .fill(Color.rssiGradient(for: device.rssi))
          .frame(width: 50, height: 4)
        Text(device.formattedRSSI)
          .font(.caption2)
          .foregroundColor(.textTertia)
      }
    }
  }
}
