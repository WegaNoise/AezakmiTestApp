//
//  MainTabView.swift
//  Aezakmi
//
//  Created by petar on 04.02.2026.
//

import SwiftUI
import Combine

struct MainTabView: View {
  @StateObject private var mainVM = MainViewModel()
  @State private var selectedTab = 0
  
  init() {
    let appearance = UITabBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = UIColor(Color.cardsBackground)
    appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.textTertia)
    appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.textTertia)]
    appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.primary)
    appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.primary)]
    UITabBar.appearance().standardAppearance = appearance
    UITabBar.appearance().scrollEdgeAppearance = appearance
  }
  
  var body: some View {
    TabView(selection: $selectedTab) {
      
      NavigationView {
        BluetoothScannerView()
          .environmentObject(mainVM)
      }
      .navigationViewStyle(.stack)
      .tabItem {
        Label("bluetooth_tab".localized, systemImage: "antenna.radiowaves.left.and.right")
      }
      .tag(0)
      
      NavigationView {
        NetworkScannerView()
          .environmentObject(mainVM)
      }
      .navigationViewStyle(.stack)
      .tabItem {
        Label("network_tab".localized, systemImage: "wifi")
      }
      .tag(1)
      
      NavigationView {
        ScanHistoryView()
          .environmentObject(mainVM)
      }
      .navigationViewStyle(.stack)
      .tabItem {
        Label("history_tab".localized, systemImage: "clock.fill")
      }
      .tag(2)
    }
    .accentColor(.primary)
    .alert(mainVM.alertTitle,
           isPresented: $mainVM.showAlert) {
        Button("ok".localized, role: .cancel) { }
    } message: {
        Text(mainVM.alertMessage)
    }
  }
}


class MainViewModel: ObservableObject {
  @Published var showAlert = false
  @Published var alertMessage = ""
  @Published var alertTitle = ""
  
  func showError(title: String, message: String) {
    alertTitle = title
    alertMessage = message
    showAlert = true
  }
}
