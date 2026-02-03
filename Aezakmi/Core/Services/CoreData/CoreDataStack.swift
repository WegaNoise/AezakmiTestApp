//
//  CoreDataStack.swift
//  Aezakmi
//
//  Created by petar on 05.02.2026.
//

import Foundation
import CoreData

class CoreDataStack {
  static let shared = CoreDataStack()
  private let modelName: String = "ScanDataModel"
  
  lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: modelName)
    container.loadPersistentStores { storeDescription, error in
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
      print("Core Data store loaded: \(storeDescription)")
    }
    container.viewContext.automaticallyMergesChangesFromParent = true
    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    return container
  }()
  
  var viewContext: NSManagedObjectContext {
    return persistentContainer.viewContext
  }
  
  func newBackgroundContext() -> NSManagedObjectContext {
    let context = persistentContainer.newBackgroundContext()
    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    return context
  }
  
  func saveViewContext() {
    let context = viewContext
    if context.hasChanges {
      do {
        try context.save()
        print("View context saved successfully")
      } catch {
        let nserror = error as NSError
        print("Failed to save view context: \(nserror), \(nserror.userInfo)")
      }
    }
  }
  
  func saveContext(_ context: NSManagedObjectContext) {
    if context.hasChanges {
      do {
        try context.save()
        print("Context saved successfully")
      } catch {
        let nserror = error as NSError
        print("Failed to save context: \(nserror), \(nserror.userInfo)")
        context.rollback()
      }
    }
  }
}
