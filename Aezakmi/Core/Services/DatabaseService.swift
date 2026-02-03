//
//  DatabaseService.swift
//  Aezakmi
//
//  Created by petar on 05.02.2026.
//

import Foundation
import Combine

class DatabaseService: ObservableObject {
  static let shared = DatabaseService()
  @Published var scanSessions: [ScanSession] = []
  
  private let coreDataService = CoreDataService.shared
  private var cancellables = Set<AnyCancellable>()
  private init() {
    coreDataService.$scanSessions
      .receive(on: DispatchQueue.main)
      .assign(to: \.scanSessions, on: self)
      .store(in: &cancellables)
  }
  
  func saveScanSession(_ session: ScanSession) {
    coreDataService.saveScanSession(session)
  }
  
  func deleteScanSession(_ session: ScanSession) {
    coreDataService.deleteScanSession(session)
  }
  
  func clearAllSessions() {
    coreDataService.clearAllSessions()
  }
  
  func getSessions(filter: DeviceType? = nil) -> [ScanSession] {
    coreDataService.scanSessions.filter { session in
      guard let filter = filter else { return true }
      switch filter {
      case .bluetooth:
        return !session.bluetoothDevices.isEmpty
      case .network:
        return !session.networkDevices.isEmpty
      }
    }
  }
  
  func getSessions(for date: Date) -> [ScanSession] {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)
    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
    return coreDataService.scanSessions.filter { session in
      session.startTime >= startOfDay && session.startTime < endOfDay
    }
  }
  
  func getScanSession(by id: UUID) -> ScanSession? {
    coreDataService.scanSessions.first { $0.id == id }
  }
  
  var numberOfSessions: Int {
    coreDataService.scanSessions.count
  }
  
  var totalDevicesScanned: Int {
    coreDataService.scanSessions.reduce(0) { $0 + $1.totalDevices }
  }
  
  func getRecentSessions(limit: Int = 10) -> [ScanSession] {
    Array(coreDataService.scanSessions.prefix(limit))
  }
}
