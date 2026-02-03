//
//  CoreDataService.swift
//  Aezakmi
//
//  Created by petar on 05.02.2026.
//

import Foundation
import CoreData
import Combine

class CoreDataService: ObservableObject {
  static let shared = CoreDataService()
  private let stack = CoreDataStack.shared
  private var cancellables = Set<AnyCancellable>()
  
  @Published var scanSessions: [ScanSession] = []
  @Published var isLoading = false
  @Published var errorMessage: String?
  
  private init() {
    loadAllScanSessions()
    setupNotifications()
  }
  
  deinit {
    cancellables.forEach { $0.cancel() }
  }
  
  private func setupNotifications() {
    NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] notification in
        self?.handleContextDidSave(notification)
      }
      .store(in: &cancellables)
  }
  
  private func handleContextDidSave(_ notification: Notification) {
    loadAllScanSessions()
  }
  
  func saveScanSession(_ session: ScanSession) {
    isLoading = true
    let backgroundContext = stack.newBackgroundContext()
    backgroundContext.perform { [weak self] in
      guard let self = self else { return }
      do {
        let sessionEntity = self.createSessionEntity(from: session, context: backgroundContext)
        try backgroundContext.save()
        print("Scan session saved: \(session.id)")
        DispatchQueue.main.async {
          self.isLoading = false
        }
      } catch {
        print("Failed to save scan session: \(error)")
        
        DispatchQueue.main.async {
          self.isLoading = false
          self.errorMessage = "Failed to save scan session: \(error.localizedDescription)"
        }
      }
    }
  }
  
  func loadAllScanSessions() {
    isLoading = true
    let backgroundContext = stack.newBackgroundContext()
    backgroundContext.perform { [weak self] in
      guard let self = self else { return }
      let request: NSFetchRequest<ScanSessionEntity> = ScanSessionEntity.fetchRequest()
      request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
      do {
        let entities = try backgroundContext.fetch(request)
        let sessions = entities.compactMap { self.convertToScanSession(entity: $0) }
        DispatchQueue.main.async {
          self.scanSessions = sessions
          self.isLoading = false
          print("Loaded \(sessions.count) scan sessions")
        }
      } catch {
        self.handleError(error, context: "Failed to fetch scan sessions")
        
        DispatchQueue.main.async {
          self.isLoading = false
          self.errorMessage = "database_load_error".localized
        }
      }
    }
  }
  
  private func handleError(_ error: Error, context: String) {
    print("\(context): \(error)")
    DispatchQueue.main.async {
      self.errorMessage = "database_save_error".localized
    }
  }
  
  func getScanSession(by id: UUID) -> ScanSession? {
    let context = stack.viewContext
    let request: NSFetchRequest<ScanSessionEntity> = ScanSessionEntity.fetchRequest()
    request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
    request.fetchLimit = 1
    do {
      let entities = try context.fetch(request)
      return entities.first.map { convertToScanSession(entity: $0) }
    } catch {
      print("Failed to fetch scan session: \(error)")
      return nil
    }
  }
  
  func updateScanSession(_ session: ScanSession) {
    let context = stack.viewContext
    let request: NSFetchRequest<ScanSessionEntity> = ScanSessionEntity.fetchRequest()
    request.predicate = NSPredicate(format: "id == %@", session.id as CVarArg)
    
    do {
      let entities = try context.fetch(request)
      if let entity = entities.first {
        updateSessionEntity(entity, with: session)
        try context.save()
        print("Scan session updated: \(session.id)")
        loadAllScanSessions()
      }
    } catch {
      print("Failed to update scan session: \(error)")
    }
  }
  
  func deleteScanSession(_ session: ScanSession) {
    let context = stack.viewContext
    let request: NSFetchRequest<ScanSessionEntity> = ScanSessionEntity.fetchRequest()
    request.predicate = NSPredicate(format: "id == %@", session.id as CVarArg)
    do {
      let entities = try context.fetch(request)
      for entity in entities {
        context.delete(entity)
      }
      try context.save()
      print("Scan session deleted: \(session.id)")
      loadAllScanSessions()
    } catch {
      print("Failed to delete scan session: \(error)")
    }
  }
  
  func clearAllSessions() {
    let backgroundContext = stack.newBackgroundContext()
    backgroundContext.perform { [weak self] in
      guard let self = self else { return }
      let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ScanSessionEntity.fetchRequest()
      let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
      deleteRequest.resultType = .resultTypeCount
      
      do {
        if let result = try backgroundContext.persistentStoreCoordinator?
          .execute(deleteRequest, with: backgroundContext) as? NSBatchDeleteResult {
          print("Deleted \(result.result ?? 0) sessions")
        }
        backgroundContext.reset()
        DispatchQueue.main.async {
          self.scanSessions.removeAll()
        }
      } catch {
        print("Failed to clear sessions: \(error)")
      }
    }
  }
  
  func getSessions(filter: DeviceType? = nil) -> [ScanSession] {
    guard let filter = filter else { return scanSessions }
    return scanSessions.filter { session in
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
    
    return scanSessions.filter { session in
      session.startTime >= startOfDay && session.startTime < endOfDay
    }
  }
  
  var numberOfSessions: Int {
    scanSessions.count
  }
  
  var totalDevicesScanned: Int {
    scanSessions.reduce(0) { $0 + $1.totalDevices }
  }
  
  func getRecentSessions(limit: Int = 10) -> [ScanSession] {
    Array(scanSessions.prefix(limit))
  }
  
  private func createSessionEntity(from session: ScanSession, context: NSManagedObjectContext) -> ScanSessionEntity {
    let entity = ScanSessionEntity(context: context)
    entity.id = session.id
    entity.startTime = session.startTime
    entity.endTime = session.endTime
    entity.duration = session.duration ?? 0
    entity.scanType = session.scanType.rawValue
    
    for device in session.bluetoothDevices {
      let deviceEntity = BluetoothDeviceEntity(context: context)
      deviceEntity.id = device.id
      deviceEntity.peripheralId = device.peripheralId
      deviceEntity.name = device.name
      deviceEntity.uuid = device.uuid
      deviceEntity.rssi = Int32(device.rssi)
      deviceEntity.status = device.status.rawValue
      deviceEntity.lastSeen = device.lastSeen
      
      if let services = device.services {
        deviceEntity.services = try? JSONEncoder().encode(services)
      }
      entity.addToBluetoothDevices(deviceEntity)
    }
    
    for device in session.networkDevices {
      let deviceEntity = NetworkDeviceEntity(context: context)
      deviceEntity.id = device.id
      deviceEntity.ipAddress = device.ipAddress
      deviceEntity.macAddress = device.macAddress
      deviceEntity.hostname = device.hostname
      deviceEntity.vendor = device.vendor
      deviceEntity.isLocalDevice = device.isLocalDevice
      deviceEntity.lastSeen = device.lastSeen
      
      if let ports = device.ports {
        deviceEntity.ports = try? JSONEncoder().encode(ports)
      }
      entity.addToNetworkDevices(deviceEntity)
    }
    return entity
  }
  
  private func updateSessionEntity(_ entity: ScanSessionEntity, with session: ScanSession) {
    entity.endTime = session.endTime
    entity.duration = session.duration ?? 0
    entity.scanType = session.scanType.rawValue
  }
  
  private func convertToScanSession(entity: ScanSessionEntity) -> ScanSession {
    var session = ScanSession(
      id: entity.id ?? UUID(),
      startTime: entity.startTime ?? Date(),
      endTime: entity.endTime,
      bluetoothDevices: [],
      networkDevices: [],
      scanType: ScanSession.ScanType(rawValue: entity.scanType ?? "combined") ?? .combined
    )
    session.duration = entity.duration > 0 ? entity.duration : nil
    if let bluetoothEntities = entity.bluetoothDevices as? Set<BluetoothDeviceEntity> {
      session.bluetoothDevices = bluetoothEntities.map { convertToBluetoothDevice(entity: $0) }
    }
    if let networkEntities = entity.networkDevices as? Set<NetworkDeviceEntity> {
      session.networkDevices = networkEntities.map { convertToNetworkDevice(entity: $0) }
    }
    return session
  }
  
  private func convertToBluetoothDevice(entity: BluetoothDeviceEntity) -> BluetoothDevice {
    var services: [String]?
    if let servicesData = entity.services,let decodedServices = try? JSONDecoder().decode([String].self, from: servicesData) {
      services = decodedServices
    }
    return BluetoothDevice(
      id: entity.id ?? UUID(),
      peripheral: nil,
      name: entity.name,
      uuid: entity.uuid ?? "",
      rssi: Int(entity.rssi),
      status: ConnectionStatus(rawValue: entity.status ?? "unknown") ?? .unknown,
      services: services
    )
  }
  
  private func convertToNetworkDevice(entity: NetworkDeviceEntity) -> NetworkDevice {
    var ports: [Int]?
    if let portsData = entity.ports,let decodedPorts = try? JSONDecoder().decode([Int].self, from: portsData) {
      ports = decodedPorts
    }
    return NetworkDevice(
      id: entity.id ?? UUID(),
      ipAddress: entity.ipAddress ?? "",
      macAddress: entity.macAddress,
      hostname: entity.hostname,
      vendor: entity.vendor,
      isLocalDevice: entity.isLocalDevice,
      ports: ports
    )
  }
}
