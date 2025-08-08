//
//  PreyCoreData.swift
//  Prey
//
//  Created by Javier Cala Uribe on 6/06/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import CoreData

class PreyCoreData {
    
    // MARK: Properties

    // Object context
    var managedObjectContext: NSManagedObjectContext!

    static let sharedInstance = PreyCoreData()
    fileprivate init() {
        
        // This resource is the same name as your xcdatamodeld contained in your project.
        guard let modelURL = Bundle.main.url(forResource: "PreyData", withExtension:"momd") else {
            PreyLogger("Error loading model from bundle")
            return
        }
        // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            PreyLogger("Error initializing mom from")
            return
        }
        
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = psc
        
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docURL = urls[urls.endIndex-1]
        
        // The directory the application uses to store the Core Data store file.
        // This code uses a file named "PreyData.sqlite" in the application's documents directory.
        
        let storeURL = docURL.appendingPathComponent("PreyData.sqlite")
        do {
            try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
        } catch {
            PreyLogger("Error migrating store: \(error)")
            try! FileManager.default.removeItem(at: storeURL)
        }
    }
    
    // MARK: Functions
    
    // Get current triggers
    func getCurrentTriggers() -> [Triggers] {
        
        var fetchedObjects  = [Triggers]()
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        
        guard let entity = NSEntityDescription.entity(forEntityName: "Triggers", in:managedObjectContext) else {
            return fetchedObjects
        }
        
        fetchRequest.entity = entity
        
        do {
            if let context = managedObjectContext {
                fetchedObjects = try context.fetch(fetchRequest) as! [Triggers]
            }
        } catch let error as NSError {
            PreyLogger("CoreData triggers error: \(error.localizedDescription)")
        }
        
        return fetchedObjects
    }
    
}
