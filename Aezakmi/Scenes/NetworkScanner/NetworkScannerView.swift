//
//  NetworkDevicesView.swift
//  Aezakmi
//
//  Created by petar on 05.02.2026.
//

import SwiftUI
import Lottie

struct NetworkScannerView: View {
  @StateObject private var viewModel = NetworkScannerViewModel()
  @EnvironmentObject var mainVM: MainViewModel
  
  var body: some View {
    ZStack {
      Color.mainBackground.ignoresSafeArea()
      VStack(spacing: 0) {
        VStack(alignment: .leading, spacing: 12) {
          Text("network_title".localized)
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.textPrim)
          HStack {
            HStack {
              Image(systemName: "wifi")
                .foregroundColor(getNetworkStatusColor())
              
              Text("network_ready".localized)
                .font(.subheadline)
                .foregroundColor(getNetworkStatusColor())
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
            ProgressView(value: 1.0, total: 1.0)
              .progressViewStyle(LinearProgressViewStyle(tint: .primary))
              .frame(height: 6)
              .padding(.horizontal, 20)
            
            LottieView(animation: .named("network"))
              .looping()
              .animationSpeed(2)
              .frame(width: 120, height: 120)
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
    .alert("network_error".localized, isPresented: $viewModel.showAlert) {
      Button("ok".localized, role: .cancel) { }
    } message: {
      if let error = viewModel.errorMessage {
        Text(error)
      }
    }
  }
  
  private func getNetworkStatusColor() -> Color {
    return .statusConnected
  }
  
  private var emptyStateView: some View {
    VStack(spacing: 24) {
      Spacer()
      Image(systemName: "wifi")
        .font(.system(size: 80))
        .foregroundColor(.network.opacity(0.3))
        .padding(.bottom, 8)
      VStack(spacing: 8) {
        Text(viewModel.isScanning ? "scanning_network_message".localized : "no_network_devices".localized)
          .font(.title2)
          .fontWeight(.medium)
          .foregroundColor(.textPrim)
        Text(viewModel.isScanning ? "scanning_network_message".localized : "no_devices_message".localized)
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
            NetworkDeviceDetailView(
              device: device,
              scanner: viewModel.networkScanner
            )
          } label: {
            NetworkDeviceRow(device: device)
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
        Text(viewModel.isScanning ? "stop_scanning".localized : "start_network_scan".localized)
          .fontWeight(.semibold)
      }
      .foregroundColor(.white)
      .frame(maxWidth: .infinity)
      .frame(height: 56)
      .background(
        viewModel.isScanning ? LinearGradient(colors: [.statusError], startPoint: .leading, endPoint: .trailing) : Color.scanButtonGradient
      )
      .cornerRadius(16)
      .shadow(
        color: (viewModel.isScanning ? Color("Error") : .primary).opacity(0.3),
        radius: 8, x: 0, y: 4
      )
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(Color.white.opacity(0.2), lineWidth: 1)
      )
    }
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
