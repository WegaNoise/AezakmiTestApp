//
//  NetworkScannerViewModel.swift
//  Aezakmi
//
//  Created by petar on 05.02.2026.
//

import Foundation
import SwiftUI
import Combine

final class NetworkScannerViewModel: ObservableObject {
  let networkScanner: NetworkScanner
  private let databaseService: DatabaseService
  @Published var discoveredDevices: [NetworkDevice] = []
  @Published var isScanning = false
  @Published var scanProgress: Double = 0.0
  @Published var errorMessage: String?
  @Published var showAlert = false
  @Published var showSaveConfirmation = false
  @Published var lastSavedSession: ScanSession?
  private var cancellables = Set<AnyCancellable>()
  private var hasSavedCurrentSession = false
  
  var deviceCount: Int {
    discoveredDevices.count
  }
  
  init(networkScanner: NetworkScanner = NetworkScanner(), databaseService: DatabaseService = DatabaseService.shared) {
    self.networkScanner = networkScanner
    self.databaseService = databaseService
    setupBindings()
  }
  
  deinit {
    cancellables.forEach { $0.cancel() }
  }
  
  private func setupBindings() {
    networkScanner.$discoveredDevices
      .receive(on: DispatchQueue.main)
      .assign(to: \.discoveredDevices, on: self)
      .store(in: &cancellables)
    
    networkScanner.$isScanning
      .receive(on: DispatchQueue.main)
      .assign(to: \.isScanning, on: self)
      .store(in: &cancellables)
    
    networkScanner.$scanProgress
      .receive(on: DispatchQueue.main)
      .assign(to: \.scanProgress, on: self)
      .store(in: &cancellables)
    
    networkScanner.$errorMessage
      .receive(on: DispatchQueue.main)
      .sink { [weak self] error in
        self?.errorMessage = error
        if error != nil {
          self?.showAlert = true
        }
      }
      .store(in: &cancellables)
    
    networkScanner.$isScanning
      .removeDuplicates()
      .scan((false, false)) { previous, current in
        (previous.1, current)
      }
      .sink { [weak self] previous, current in
        guard let self else { return }
        if previous == true && current == false {
          self.handleScanFinished()
        }
      }
      .store(in: &cancellables)
  }
  
  func toggleScan() {
    if isScanning {
      networkScanner.stopScan()
    } else {
      startScanning()
    }
  }
  
  func startScanning() {
    discoveredDevices.removeAll()
    hasSavedCurrentSession = false
    networkScanner.startScan()
  }
  
  private func saveScanSession() {
    guard !discoveredDevices.isEmpty || hasSavedCurrentSession else { return }
    let startTime = networkScanner.scanStartTime ?? Date()
    let endTime = networkScanner.scanEndTime ?? Date()
    var session = ScanSession(
      startTime: startTime,
      endTime: endTime,
      bluetoothDevices: [],
      networkDevices: discoveredDevices,
      scanType: .network
    )
//    session.completeScan()
    databaseService.saveScanSession(session)
    lastSavedSession = session
    showSaveConfirmation = true
    hasSavedCurrentSession = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
      self?.showSaveConfirmation = false
    }
  }
  
  private func handleScanFinished() {
    guard !discoveredDevices.isEmpty && errorMessage == nil else { return }
    saveScanSession()
  }
}
