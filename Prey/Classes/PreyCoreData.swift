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

    static let sharedInstance = PreyCoreData()
    private init() {
    }
    
    // Object context
    var managedObjectContext: NSManagedObjectContext {
        let objectCtx = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        objectCtx.persistentStoreCoordinator = persistentStoreCoordinator
        return objectCtx
    }
    
    // Object model
    var managedObjectModel: NSManagedObjectModel! {
        if let modelURL = NSBundle.mainBundle().URLForResource("PreyModelData", withExtension: "momd") {
            return NSManagedObjectModel(contentsOfURL: modelURL)
        }
        return nil
    }
    
    // Persistent store
    var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        let persistentStore = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        do {
            let storeURL = applicationDocumentsDirectory.URLByAppendingPathComponent("PreyModelData.sqlite")
            try persistentStore.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
            try NSFileManager.defaultManager().removeItemAtURL(storeURL)
        } catch let error as NSError {
            print("CoreData error: \(error.localizedDescription)")
        }
        return persistentStore
    }

    let applicationDocumentsDirectory:NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains:.UserDomainMask).last!

    
    // MARK: Functions
    

    // Update Geofence Zones
    func updateGeofenceZones(response:NSDictionary) {
        
        let localZonesArray = getCurrentGeofenceZones()
        
        // Added zones events
        
    }

    // Get Added Zones
    func getAddedZones(serverResponse:NSDictionary, withLocalZones localZonesArray:[GeofenceZones]) -> NSMutableArray {
        
        let addedZones = NSMutableArray()
        
        for (key, value) in serverResponse {
            
            if key as! String == "id" {

                let serverZone = NSNumber(float:value.floatValue)
                var isLocalZone = false
                
                for localZone:GeofenceZones in localZonesArray {
                    if serverZone == localZone.zone_id {
                        isLocalZone = true
                    }
                }
                
                if isLocalZone == false {
                    addedZones.addObject([key, value])
                }
            }
        }
        
        return addedZones
    }
    
    // Get current geofence zones
    func getCurrentGeofenceZones() -> NSArray {
    
        var fetchedObjects  = NSArray()
        let fetchRequest    = NSFetchRequest()
        
        guard let entity = NSEntityDescription.entityForName("GeofenceZones", inManagedObjectContext: managedObjectContext) else {
            return fetchedObjects
        }
        
        fetchRequest.entity = entity
        
        do {
            fetchedObjects = try managedObjectContext.executeFetchRequest(fetchRequest)
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