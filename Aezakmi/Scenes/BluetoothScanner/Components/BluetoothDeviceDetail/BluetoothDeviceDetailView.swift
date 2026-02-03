//
//  BluetoothDeviceDetailView.swift
//  Aezakmi
//
//  Created by petar on 05.02.2026.
//

import SwiftUI
import CoreBluetooth

struct BluetoothDeviceDetailView: View {
  let device: BluetoothDevice
  let scanner: BluetoothScanner
  
  @StateObject private var viewModel: BluetoothDeviceDetailViewModel
  @Environment(\.dismiss) private var dismiss
  
  init(device: BluetoothDevice, scanner: BluetoothScanner) {
    self.device = device
    self.scanner = scanner
    _viewModel = StateObject(wrappedValue: BluetoothDeviceDetailViewModel(device: device, scanner: scanner))
  }
  
  var body: some View {
    ZStack {
      Color.mainBackground.ignoresSafeArea()
      
      ScrollView {
        VStack(spacing: 24) {
          headerView
          connectionStatusView
          deviceInfoView
          signalInfoView
          VStack(spacing: 16) {
            Text("device_actions".localized)
              .font(.headline)
              .foregroundColor(.textPrim)
              .frame(maxWidth: .infinity, alignment: .leading)
            
            connectionButtonView
              .padding(.horizontal, 0)
          }
          
          Spacer(minLength: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 30)
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
      Button("ok".localized, role: .cancel) { }
    } message: {
      Text(viewModel.alertMessage)
    }
    .onAppear {
      viewModel.startObserving()
    }
    .onDisappear {
      viewModel.stopObserving()
    }
  }
  
  private var headerView: some View {
    VStack(spacing: 16) {
      ZStack {
        Circle()
          .fill(viewModel.device.status.color.opacity(0.15))
          .frame(width: 100, height: 100)
        
        Image(systemName: "antenna.radiowaves.left.and.right")
          .font(.system(size: 40))
          .foregroundColor(viewModel.device.status.color)
      }
      
      VStack(spacing: 4) {
        Text(viewModel.device.displayName)
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.textPrim)
          .multilineTextAlignment(.center)
        
        Text(viewModel.device.uuid.prefix(8))
          .font(.caption)
          .foregroundColor(.textSecond)
      }
    }
  }
  
  private var connectionStatusView: some View {
    HStack(spacing: 12) {
      Circle()
        .fill(viewModel.device.status.color)
        .frame(width: 10, height: 10)
      
      Text(viewModel.device.status.displayName)
        .font(.subheadline)
        .foregroundColor(viewModel.device.status.color)
      
      Spacer()
      
      Text(viewModel.formattedLastSeen)
        .font(.caption)
        .foregroundColor(.textTertia)
    }
    .padding()
    .background(Color.cardsBackground)
    .cornerRadius(12)
    .shadow(color: .cardShadow, radius: 2, x: 0, y: 1)
  }
  
  private var deviceInfoView: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("device_info".localized)
        .font(.headline)
        .foregroundColor(.textPrim)
      
      VStack(spacing: 12) {
        infoRow(title: "device_name".localized, value: viewModel.device.name ?? "unknown".localized)
        infoRow(title: "uuid".localized,value: viewModel.device.uuid)
        Divider()
          .background(Color.textTertia.opacity(0.3))
        
        HStack {
          Text("signal_strength".localized)
            .foregroundColor(.textSecond)
          
          Spacer()
          
          VStack(alignment: .trailing, spacing: 4) {
            Text(viewModel.device.formattedRSSI)
              .foregroundColor(.textPrim)
            
            Text(viewModel.device.signalStrength.description)
              .font(.caption)
              .foregroundColor(viewModel.device.signalStrength.color)
          }
        }
      }
    }
    .padding()
    .background(Color.cardsBackground)
    .cornerRadius(12)
    .shadow(color: .cardShadow, radius: 2, x: 0, y: 1)
  }
  
  private var signalInfoView: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("signal_quality".localized)
        .font(.headline)
        .foregroundColor(.textPrim)
      RoundedRectangle(cornerRadius: 4)
        .fill(Color.rssiGradient(for: viewModel.device.rssi))
        .frame(height: 16)
      
      HStack {
        Text("weak_signal".localized)
          .font(.caption)
          .foregroundColor(.textSecond)
        
        Spacer()
        
        Text("strong_signal".localized)
          .font(.caption)
          .foregroundColor(.textSecond)
      }
    }
    .padding()
    .background(Color.cardsBackground)
    .cornerRadius(12)
    .shadow(color: .cardShadow, radius: 2, x: 0, y: 1)
  }
  
  private var connectionButtonView: some View {
    Button {
      viewModel.toggleConnection()
    } label: {
      HStack(spacing: 12) {
        Image(systemName: viewModel.connectionButtonIcon)
          .font(.title3)
        
        Text(viewModel.connectionButtonTitle)
          .fontWeight(.semibold)
      }
      .foregroundColor(.white)
      .frame(maxWidth: .infinity)
      .frame(height: 50)
      .background(viewModel.connectionButtonColor)
      .cornerRadius(12)
      .shadow(color: viewModel.connectionButtonColor.opacity(0.3),
              radius: 6, x: 0, y: 3)
    }
    .disabled(viewModel.isConnectionDisabled)
    .opacity(viewModel.isConnectionDisabled ? 0.6 : 1)
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
        .lineLimit(1)
    }
  }
}
