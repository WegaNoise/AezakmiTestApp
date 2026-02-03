//
//  ScanSessionDetailView.swift
//  Aezakmi
//
//  Created by petar on 06.02.2026.
//

import SwiftUI

struct ScanSessionDetailView: View {
  let session: ScanSession
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    ZStack {
      Color.mainBackground.ignoresSafeArea()
      ScrollView {
        VStack(spacing: 24) {
          headerView
          sessionInfoView
          devicesListView
          
          Spacer(minLength: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 30)
      }
    }
    .navigationBarTitleDisplayMode(.inline)
  }
  
  private var headerView: some View {
    VStack(spacing: 16) {
      Image(systemName: session.scanType.icon)
        .font(.system(size: 60))
        .foregroundColor(session.scanType.color)
      VStack(spacing: 4) {
        Text(session.formattedDate)
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.textPrim)
        Text(session.scanType.displayName)
          .font(.subheadline)
          .foregroundColor(session.scanType.color)
          .padding(.horizontal, 12)
          .padding(.vertical, 4)
          .background(session.scanType.color.opacity(0.1))
          .cornerRadius(8)
      }
    }
  }
  
  private var sessionInfoView: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("session_info".localized)
        .font(.headline)
        .foregroundColor(.textPrim)
      
      VStack(spacing: 12) {
        infoRow(title: "scan_type".localized, value: session.scanType.displayName)
        infoRow(title: "start_time".localized, value: formatTime(session.startTime))
        if let endTime = session.endTime {
          infoRow(title: "end_time".localized, value: formatTime(endTime))
        }
        infoRow(title: "duration".localized, value: session.formattedDuration)
        Divider()
          .background(Color.textTertia.opacity(0.3))
        HStack {
          Text("total_devices".localized)
            .foregroundColor(.textSecond)
          Spacer()
          VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 12) {
              if !session.bluetoothDevices.isEmpty {
                Label("\(session.bluetoothDevices.count)", systemImage: "antenna.radiowaves.left.and.right")
                  .font(.subheadline)
                  .foregroundColor(.bluetooth)
              }
              if !session.networkDevices.isEmpty {
                Label("\(session.networkDevices.count)", systemImage: "wifi")
                  .font(.subheadline)
                  .foregroundColor(.network)
              }
            }
          }
        }
      }
    }
    .padding()
    .background(Color.cardsBackground)
    .cornerRadius(12)
    .shadow(color: .cardShadow, radius: 2, x: 0, y: 1)
  }
  
  private var devicesListView: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("devices_list".localized)
        .font(.headline)
        .foregroundColor(.textPrim)
      if !session.bluetoothDevices.isEmpty {
        SectionView(
          title: "bluetooth_devices".localized,
          count: session.bluetoothDevices.count,
          color: .bluetooth,
          icon: "antenna.radiowaves.left.and.right"
        ) {
          ForEach(session.bluetoothDevices) { device in
            BluetoothDeviceRow(device: device)
          }
        }
      }
      
      if !session.networkDevices.isEmpty {
        SectionView(
          title: "network_devices".localized,
          count: session.networkDevices.count,
          color: .network,
          icon: "wifi"
        ) {
          ForEach(session.networkDevices) { device in
            NetworkDeviceRow(device: device)
          }
        }
      }
    }
  }
  
  private func infoRow(title: String, value: String) -> some View {
    HStack {
      Text(title)
        .font(.subheadline)
        .foregroundColor(.textSecond)
      Spacer()
      Text(value)
        .font(.subheadline)
        .foregroundColor(.textPrim)
    }
  }
  
  private func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .medium
    formatter.dateStyle = .none
    return formatter.string(from: date)
  }
}

struct SectionView<Content: View>: View {
  let title: String
  let count: Int
  let color: Color
  let icon: String
  let content: () -> Content
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Label(title, systemImage: icon)
          .font(.subheadline)
          .foregroundColor(color)
        Spacer()
        Text("\(count)")
          .font(.caption)
          .foregroundColor(.textSecond)
          .padding(.horizontal, 8)
          .padding(.vertical, 2)
          .background(color.opacity(0.1))
          .cornerRadius(4)
      }
      content()
    }
    .padding()
    .background(Color.cardsBackground)
    .cornerRadius(12)
    .shadow(color: .cardShadow, radius: 2, x: 0, y: 1)
  }
}
