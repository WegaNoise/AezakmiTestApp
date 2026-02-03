//
//  ScanSessionRow.swift
//  Aezakmi
//
//  Created by petar on 06.02.2026.
//

import SwiftUI

struct ScanSessionRow: View {
  let session: ScanSession
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(session.formattedDate)
            .font(.headline)
            .foregroundColor(.textPrim)
          Text(session.formattedDuration)
            .font(.caption)
            .foregroundColor(.textSecond)
        }
        Spacer()
        Image(systemName: session.scanType.icon)
          .font(.title3)
          .foregroundColor(session.scanType.color)
      }
      HStack(spacing: 16) {
        if !session.bluetoothDevices.isEmpty {
          DeviceStatBadge( count: session.bluetoothDevices.count, type: .bluetooth)
        }
        if !session.networkDevices.isEmpty {
          DeviceStatBadge(count: session.networkDevices.count, type: .network)
        }
        Spacer()
        Text("total".localized + ": \(session.totalDevices)")
          .font(.caption)
          .foregroundColor(.textTertia)
      }
      
      if !session.bluetoothDevices.isEmpty || !session.networkDevices.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(Array(session.bluetoothDevices.prefix(3)), id: \.id) { device in
              DevicePreviewBadge(name: device.displayName, type: .bluetooth)
            }
            ForEach(Array(session.networkDevices.prefix(3)), id: \.id) { device in
              DevicePreviewBadge(name: device.displayName, type: .network)
            }
          }
        }
      }
    }
    .padding(16)
    .background(Color.cardsBackground)
    .cornerRadius(14)
    .shadow(color: .cardShadow, radius: 4, x: 0, y: 2)
  }
}
