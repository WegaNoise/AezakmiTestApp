//
//  ScanHistoryViewModel.swift
//  Aezakmi
//
//  Created by petar on 05.02.2026.
//

import Foundation
import SwiftUI
import Combine

final class ScanHistoryViewModel: ObservableObject {
  private let databaseService: DatabaseService
  @Published var scanSessions: [ScanSession] = []
  @Published var filteredSessions: [ScanSession] = []
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var showAlert = false
  
  @Published var selectedFilter: DeviceType?
  @Published var searchText = ""
  @Published var selectedDate: Date?
  @Published var datePickerDate: Date = Date()
  
  var totalSessions: Int {
    scanSessions.count
  }
  
  var totalDevicesScanned: Int {
    scanSessions.reduce(0) { $0 + $1.totalDevices }
  }
  
  var hasActiveFilters: Bool {
    selectedFilter != nil || selectedDate != nil || !searchText.isEmpty
  }
  
  var filterOptions: [DeviceType?] {
    [nil, .bluetooth, .network]
  }
  
  init(databaseService: DatabaseService = DatabaseService.shared) {
    self.databaseService = databaseService
    setupBindings()
  }
  
  deinit {
    cancellables.forEach { $0.cancel() }
  }
  
  private var cancellables = Set<AnyCancellable>()
  private func setupBindings() {
    databaseService.$scanSessions
      .receive(on: DispatchQueue.main)
      .sink { [weak self] sessions in
        self?.scanSessions = sessions.sorted { $0.startTime > $1.startTime }
        self?.applyFilters()
      }
      .store(in: &cancellables)
    
    Publishers.CombineLatest3($selectedFilter, $selectedDate, $searchText)
      .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
      .sink { [weak self] _, _, _ in
        self?.applyFilters()
      }
      .store(in: &cancellables)
  }
  
  func loadHistory() {
    isLoading = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      self?.isLoading = false
    }
  }
  
  func applyFilters() {
    var filtered = scanSessions
    if let filter = selectedFilter {
      filtered = filtered.filter { session in
        switch filter {
        case .bluetooth:
          return !session.bluetoothDevices.isEmpty
        case .network:
          return !session.networkDevices.isEmpty
        }
      }
    }
    if let date = selectedDate {
      let calendar = Calendar.current
      let startOfDay = calendar.startOfDay(for: date)
      let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
      filtered = filtered.filter { session in
        session.startTime >= startOfDay && session.startTime < endOfDay
      }
    }
    if !searchText.isEmpty {
      let query = searchText.lowercased()
      filtered = filtered.filter { session in
        let bluetoothMatch = session.bluetoothDevices.contains { device in
          device.displayName.lowercased().contains(query) ||
          device.uuid.lowercased().contains(query)
        }
        let networkMatch = session.networkDevices.contains { device in
          device.displayName.lowercased().contains(query) ||
          device.ipAddress.lowercased().contains(query)
        }
        return bluetoothMatch || networkMatch
      }
    }
    filteredSessions = filtered
  }
  
  func deleteSession(_ session: ScanSession) {
    databaseService.deleteScanSession(session)
  }
  
  func clearAllHistory() {
    databaseService.clearAllSessions()
  }
  
  func resetFilters() {
    selectedFilter = nil
    searchText = ""
    selectedDate = nil
  }
}
