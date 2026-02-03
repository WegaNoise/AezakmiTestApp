//
//  BluetoothScannerView.swift
//  Aezakmi
//
//  Created by petar on 05.02.2026.
//

import SwiftUI
import Lottie
import CoreBluetooth

struct BluetoothScannerView: View {
  @StateObject private var viewModel = BluetoothScannerViewModel()
  @EnvironmentObject var mainVM: MainViewModel
  
  var body: some View {
    ZStack {
      Color.mainBackground.ignoresSafeArea()
      VStack(spacing: 0) {
        VStack(alignment: .leading, spacing: 12) {
          Text("bluetooth_title".localized)
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.textPrim)
          HStack {
            HStack {
              Image(systemName: "antenna.radiowaves.left.and.right")
                .foregroundColor(getBluetoothStatusColor())
              Text(getBluetoothStatusText())
                .font(.subheadline)
                .foregroundColor(getBluetoothStatusColor())
            }
            Spacer()
            Text("found_count".localized(viewModel.deviceCount))
              .font(.subheadline)
              .foregroundColor(.textSecond)
          }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
        if viewModel.isScanning {
          VStack(spacing: 8) {
            ProgressView(value: viewModel.scanProgress, total: 1.0)
              .progressViewStyle(LinearProgressViewStyle(tint: .primary))
              .frame(height: 6)
              .padding(.horizontal, 20)
            LottieView(animation: .named("bluetooth"))
              .looping()
              .animationSpeed(2)
              .frame(width: 120, height: 120)

            Text("scanning_progress".localized(Int(viewModel.scanProgress * 100)))
              .font(.caption)
              .foregroundColor(.textSecond)
          }
          .padding(.bottom, 16)
        }
        if viewModel.discoveredDevices.isEmpty {
          emptyStateView
        } else {
          devicesListView
        }
        Spacer()
        scanButtonView
          .padding(.horizontal, 20)
          .padding(.bottom, 30)
      }
      
      if viewModel.showSaveConfirmation {
        saveConfirmationView
      }
    }
    .navigationBarHidden(true)
    .alert("bluetooth_error".localized, isPresented: $viewModel.showAlert) {
      Button("ok".localized, role: .cancel) { }
    } message: {
      if let error = viewModel.errorMessage {
        Text(error)
      }
    }
    .onAppear {
      if viewModel.bluetoothState != .poweredOn {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          if viewModel.bluetoothState != .poweredOn {
            viewModel.showBluetoothError()
          }
        }
      }
    }
  }
  
  private func getBluetoothStatusText() -> String {
    switch viewModel.bluetoothState {
    case .poweredOn:
      return "bluetooth_on".localized
    case .poweredOff:
      return "bluetooth_off".localized
    case .unauthorized:
      return "bluetooth_unauthorized".localized
    case .unsupported:
      return "bluetooth_unsupported".localized
    default:
      return "status_unknown".localized(viewModel.bluetoothState.description)
    }
  }
  
  private func getBluetoothStatusColor() -> Color {
    switch viewModel.bluetoothState {
    case .poweredOn: return .statusConnected
    case .poweredOff: return .statusError
    case .unauthorized: return .statusConnecting
    default: return .textTertia
    }
  }
  
  private var emptyStateView: some View {
    VStack(spacing: 24) {
      Spacer()
      Image(systemName: "antenna.radiowaves.left.and.right")
        .font(.system(size: 80))
        .foregroundColor(.bluetooth.opacity(0.3))
        .padding(.bottom, 8)
      VStack(spacing: 8) {
        Text(viewModel.isScanning ? "scanning_message".localized : "no_bluetooth_devices".localized)
          .font(.title2)
          .fontWeight(.medium)
          .foregroundColor(.textPrim)
        Text(viewModel.isScanning ? "scanning_message".localized : "no_devices_message".localized)
          .font(.body)
          .foregroundColor(.textSecond)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 40)
      }
      if viewModel.isScanning {
        ProgressView()
          .scaleEffect(1.5)
          .padding(.top, 20)
      }
      Spacer()
    }
    .padding(.horizontal, 20)
  }
  
  private var devicesListView: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        ForEach(viewModel.discoveredDevices) { device in
          NavigationLink {
            BluetoothDeviceDetailView(
              device: device,
              scanner: viewModel.bluetoothScanner
            )
          } label: {
            BluetoothDeviceRow(device: device)
          }
          .padding(.horizontal, 20)
        }
      }
      .padding(.vertical, 16)
    }
  }
  
  private var scanButtonView: some View {
    Button {
      viewModel.toggleScan()
    } label: {
      HStack(spacing: 12) {
        Image(systemName: viewModel.isScanning ? "stop.circle.fill" : "play.circle.fill")
          .font(.title2)
          .imageScale(.large)
        Text(viewModel.isScanning ? "stop_scanning".localized : "start_bluetooth_scan".localized)
          .fontWeight(.semibold)
      }
      .foregroundColor(.white)
      .frame(maxWidth: .infinity)
      .frame(height: 56)
      .background(
        viewModel.isScanning ? LinearGradient(colors: [.statusError], startPoint: .leading, endPoint: .trailing) : Color.scanButtonGradient)
      .cornerRadius(16)
      .shadow(
        color: (viewModel.isScanning ? Color("Error") : .primary).opacity(0.3),radius: 8, x: 0, y: 4)
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(Color.white.opacity(0.2), lineWidth: 1)
      )
    }
    .disabled(viewModel.bluetoothState != .poweredOn && !viewModel.isScanning)
    .opacity(viewModel.bluetoothState != .poweredOn && !viewModel.isScanning ? 0.6 : 1)
  }
  
  private var saveConfirmationView: some View {
    VStack {
      Spacer()
      HStack(spacing: 12) {
        Image(systemName: "checkmark.circle.fill")
          .font(.title2)
          .foregroundColor(.statusConnected)
        VStack(alignment: .leading, spacing: 4) {
          Text("scan_complete".localized)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.textPrim)
          if let session = viewModel.lastSavedSession {
            Text("devices_saved".localized(session.totalDevices))
              .font(.caption)
              .foregroundColor(.textSecond)
          }
        }
        Spacer()
      }
      .padding()
      .background(Color.cardsBackground)
      .cornerRadius(12)
      .shadow(color: .cardShadow, radius: 10, x: 0, y: 2)
      .padding(.horizontal, 20)
      .padding(.bottom, 20)
      .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    .animation(.spring(response: 0.3), value: viewModel.showSaveConfirmation)
  }
}
