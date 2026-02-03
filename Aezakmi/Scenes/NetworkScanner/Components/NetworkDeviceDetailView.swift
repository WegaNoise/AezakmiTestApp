//
//  NetworkDeviceDetailView.swift
//  Aezakmi
//
//  Created by petar on 06.02.2026.
//

import SwiftUI

struct NetworkDeviceDetailView: View {
  let device: NetworkDevice
  let scanner: NetworkScanner
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    ZStack {
      Color.mainBackground.ignoresSafeArea()
      ScrollView {
        VStack(spacing: 20) {
          headerView
          deviceInfoView
          networkInfoView
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
      ZStack {
        Circle()
          .fill(Color.network.opacity(0.15))
          .frame(width: 100, height: 100)
        Image(systemName: "wifi")
          .font(.system(size: 40))
          .foregroundColor(.network)
      }
      
      VStack(spacing: 4) {
        Text(device.displayName)
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.textPrim)
          .multilineTextAlignment(.center)
        Text(device.isLocalDevice ? "local".localized : "remote".localized)
          .font(.caption)
          .foregroundColor(device.isLocalDevice ? .statusConnected : .textTertia)
          .padding(.horizontal, 12)
          .padding(.vertical, 4)
          .background(device.isLocalDevice ? Color.statusConnected.opacity(0.1) : Color.textTertia.opacity(0.1))
          .cornerRadius(8)
      }
    }
  }
  
  private var deviceInfoView: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("device_info".localized)
        .font(.headline)
        .foregroundColor(.textPrim)
      
      VStack(spacing: 12) {
        infoRow(title: "device_name".localized, value: device.hostname ?? device.ipAddress)
        infoRow(title: "IP Address", value: device.ipAddress)
        
        if let mac = device.macAddress {
          infoRow(title: "MAC Address", value: mac)
        }
        if let vendor = device.vendor {
          infoRow(title: "Vendor", value: vendor)
        }
        infoRow(title: "last_seen".localized, value: formattedDate(device.lastSeen))
      }
    }
    .padding()
    .background(Color.cardsBackground)
    .cornerRadius(12)
    .shadow(color: .cardShadow, radius: 2, x: 0, y: 1)
  }
  
  private var networkInfoView: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("network_info".localized)
        .font(.headline)
        .foregroundColor(.textPrim)
      
      VStack(spacing: 12) {
        infoRow(title: "Device Type", value: device.isLocalDevice ? "local".localized : "remote".localized)
        if let ports = device.openPortsDescription {
          infoRow(title: "Open Ports", value: ports)
        }
        if let responseTime = device.formattedResponseTime {
          infoRow(title: "Response Time", value: responseTime)
        }
      }
    }
    .padding()
    .background(Color.cardsBackground)
    .cornerRadius(12)
    .shadow(color: .cardShadow, radius: 2, x: 0, y: 1)
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
        .lineLimit(2)
        .multilineTextAlignment(.trailing)
    }
  }
  
  private func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}
