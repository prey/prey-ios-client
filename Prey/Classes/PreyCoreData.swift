//
//  PreyCoreData.swift
//  Prey
//
//  Created by Javier Cala Uribe on 6/06/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import CoreData

class PreyCoreData {
    
    // MARK: Properties

    // Object context
    var managedObjectContext: NSManagedObjectContext!

    static let sharedInstance = PreyCoreData()
    private init() {
        
        // This resource is the same name as your xcdatamodeld contained in your project.
        guard let modelURL = NSBundle.mainBundle().URLForResource("PreyModelData", withExtension:"momd") else {
            print("Error loading model from bundle")
            return
        }
        // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
        guard let mom = NSManagedObjectModel(contentsOfURL: modelURL) else {
            print("Error initializing mom from: \(modelURL)")
            return
        }
        
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = psc
        
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let docURL = urls[urls.endIndex-1]
        
        // The directory the application uses to store the Core Data store file.
        // This code uses a file named "PreyModelData.sqlite" in the application's documents directory.
        
        let storeURL = docURL.URLByAppendingPathComponent("PreyModelData.sqlite")
        do {
            try psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
        } catch {
            print("Error migrating store: \(error)")
            try! NSFileManager.defaultManager().removeItemAtURL(storeURL)
        }
    }
    
    // MARK: Functions
    
    // Get current geofence zones
    func getCurrentGeofenceZones() -> [GeofenceZones] {
    
        var fetchedObjects  = [GeofenceZones]()
        let fetchRequest    = NSFetchRequest()
        
        guard let entity = NSEntityDescription.entityForName("GeofenceZones", inManagedObjectContext:managedObjectContext) else {
            return fetchedObjects
        }
        
        fetchRequest.entity = entity
        
        do {
            let context = managedObjectContext
            fetchedObjects = try context.executeFetchRequest(fetchRequest) as! [GeofenceZones]
        } catch let error as NSError {
            print("CoreData error: \(error.localizedDescription)")
        }
        
        return fetchedObjects
    }
    
    // Check Geofence Active
    func isGeofenceActive() -> Bool {
        let fetchedObjects = getCurrentGeofenceZones()
        return fetchedObjects.count > 0 ? true : false
    }
}