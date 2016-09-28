//
//  Geofencing.swift
//  Prey
//
//  Created by Javier Cala Uribe on 7/06/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation

class Geofencing: PreyAction, CLLocationManagerDelegate {

    // MARK: Properties
    
    let geoManager = CLLocationManager()
    
    
    // MARK: Functions

    // Prey command
    override func start() {
        
        PreyLogger("Check geofencing zone")
        checkGeofenceZones(self)

        isActive = true
    }
    
    // Update Geofence Zones
    func updateGeofenceZones(_ response:NSArray) {
        
        let localZonesArray = PreyCoreData.sharedInstance.getCurrentGeofenceZones()
        
        //PreyLogger("ZONES: \(response)")
        
        // Added zones events
        if let addedZones = getAddedZones(response, withLocalZones: localZonesArray) {
            sendEventToPanel(addedZones, withCommand:kCommand.start , withStatus:kStatus.started)
        }
        
        // Deleted zones events
        if let deletedZones = getDeletedZones(response, withLocalZones: localZonesArray) {
            sendEventToPanel(deletedZones, withCommand:kCommand.stop , withStatus:kStatus.stopped)
        }
        
        // Delete all regions on Device
        deleteAllRegionsOnDevice()
        
        // Delete all regionsOnCoreData
        deleteAllRegionsOnCoreData()
        
        // Add regions to CoreData
        addRegionsToCoreData(response, withContext:PreyCoreData.sharedInstance.managedObjectContext)

        // Add regions to Device
        addRegionsToDevice()
        
        
        isActive = false
        // Remove geofencing action
        PreyModule.sharedInstance.checkStatus(self)
    }
    
    // Send event to panel
    func sendEventToPanel(_ zonesArray:[GeofenceZones], withCommand cmd:kCommand, withStatus status:kStatus){
        
        // Create a zonesId array with new zones
        var zonesId = [NSNumber]()
        
        for itemAdded in zonesArray {
            zonesId.append(itemAdded.id!)
        }
        
        // Params struct
        let params:[String: String] = [
            kData.status.rawValue   : status.rawValue,
            kData.target.rawValue   : kAction.geofencing.rawValue,
            kData.command.rawValue  : cmd.rawValue,
            kData.reason.rawValue   : zonesId.description]
        
        // Send info to panel
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:params, messageId:nil, httpMethod:Method.POST.rawValue, endPoint:responseDeviceEndpoint, onCompletion:PreyHTTPResponse.checkDataSend(nil))
        } else {
            PreyLogger("Error send data auth")
        }
    }
    
    // Delete all regions on device
    func deleteAllRegionsOnDevice() {
        
        if let regions:NSSet = geoManager.monitoredRegions as NSSet? {
            for item in regions {
                geoManager.stopMonitoring(for: item as! CLRegion)
            }
        }
    }
    
    // Delete all regionsOnCoreData
    func deleteAllRegionsOnCoreData() {
        
        let localZonesArray = PreyCoreData.sharedInstance.getCurrentGeofenceZones()
        let context         = PreyCoreData.sharedInstance.managedObjectContext

        for localZone in localZonesArray {
            context?.delete(localZone)
        }
    }
    
    // Add regions to CoreData
    func addRegionsToCoreData(_ response:NSArray, withContext context:NSManagedObjectContext) {
        
        for serverZonesArray in response {
            
            // Init NSManagedObject type GeofenceZones
            let geofenceZones = NSEntityDescription.insertNewObject(forEntityName: "GeofenceZones", into: PreyCoreData.sharedInstance.managedObjectContext)
            
            // Attributes from GeofenceZones
            let attributes = geofenceZones.entity.attributesByName
            
            for (attribute,description) in attributes {

                if var value = (serverZonesArray as AnyObject).object(forKey: attribute) {
                    
                    switch description.attributeType {
                        
                    case .doubleAttributeType:
                        value = NSNumber(value: (value as AnyObject).doubleValue as Double)
                        
                    default:
                        value = ((value as AnyObject) is NSNull) ? "" : value as! String
                    }
                    
                    // Save {value,key} in GeofenceZone item
                    geofenceZones.setValue(value, forKey: attribute)
                }
            }
        }
        
        // Save CoreData
        do {
            try context.save()
        } catch {
            PreyLogger("Couldn't save: \(error)")
        }
    }
    
    // Add regions to Device
    func addRegionsToDevice() {
        
        // Check if CLRegion is available
        guard CLLocationManager.isMonitoringAvailable(for: CLRegion.self) else {
            PreyLogger("CLRegion is not available")
            return
        }
        
        // Get current GeofenceZones
        let fetchedObjects = PreyCoreData.sharedInstance.getCurrentGeofenceZones()
        
        for info in fetchedObjects {
            
            PreyLogger("Name zone: \(info.name)")
            
            let center_lat  = info.lat?.doubleValue
            let center_lon  = info.lng?.doubleValue
            let radius      = info.radius?.doubleValue
            let center      = CLLocationCoordinate2DMake(center_lat!, center_lon!)
            
            let zoneId      = String(format: "%f", (info.id?.floatValue)!)
            
            let region:CLCircularRegion = CLCircularRegion(center: center, radius: radius!, identifier: zoneId)
            geoManager.startMonitoring(for: region)
        }
    }

    // Get Deleted Zones
    func getDeletedZones(_ serverResponse:NSArray, withLocalZones localZonesArray:[GeofenceZones]) -> [GeofenceZones]! {
        
        // Init GeofenceZones array to return
        var deletedZones = [GeofenceZones]()
        
        // Compare localZone.id with serverZone.id and add deleted zones to deletedZones array
        for localZone:GeofenceZones in localZonesArray {
            
            var isDeletedZone = false
            
            for serverZonesArray in serverResponse {

                let value       = (serverZonesArray as AnyObject).value(forKey: "id")!
                let serverZone  = NSNumber(value: (value as AnyObject).floatValue as Float)

                if serverZone == localZone.id {
                    isDeletedZone = true
                }
            }
            
            // Add new zone
            if isDeletedZone == false {
                deletedZones.append(localZone)
            }
        }
        
        return deletedZones.count > 0 ? deletedZones : nil
    }
    
    // Get Added Zones
    func getAddedZones(_ serverResponse:NSArray, withLocalZones localZonesArray:[GeofenceZones]) -> [GeofenceZones]! {
        
        // Init GeofenceZones array to return
        var addedZones = [GeofenceZones]()
        
        // Compare localZone.id with serverZone.id and add new to addedZones array
        for serverZonesArray in serverResponse {
            
            let value       = (serverZonesArray as AnyObject).value(forKey: "id")!
            let serverZone  = NSNumber(value: (value as AnyObject).floatValue as Float)
            var isLocalZone = false
            
            for localZone:GeofenceZones in localZonesArray {
                if serverZone == localZone.id {
                    isLocalZone = true
                }
            }
            
            // Add new zone
            if isLocalZone == false {
                addedZones.append(getGeofenceZoneItemFromDictionary(serverZonesArray as! NSDictionary))
            }
        }
        
        return addedZones.count > 0 ? addedZones : nil
    }
    
    // Get geofenceZoneItem
    func getGeofenceZoneItemFromDictionary(_ serverZonesArray:NSDictionary) -> GeofenceZones {

        // Init NSManagedObject type GeofenceZones
        let zoneEntity = NSEntityDescription.entity(forEntityName: "GeofenceZones", in: PreyCoreData.sharedInstance.managedObjectContext)!
        let geofenceZoneItem = GeofenceZones(entity:zoneEntity, insertInto: PreyCoreData.sharedInstance.managedObjectContext)
        
        // Attributes from GeofenceZones
        let attributes = geofenceZoneItem.entity.attributesByName
        
        for (attribute,description) in attributes {

            if var value = serverZonesArray.object(forKey: attribute){

                switch description.attributeType {
                    
                case .doubleAttributeType:
                    value = NSNumber(value: (value as AnyObject).doubleValue as Double)
                    
                default:
                    value = ((value as AnyObject) is NSNull) ? "" : value as! String
                }
                
                // Save {value,key} in GeofenceZone item
                geofenceZoneItem.setValue(value, forKey: attribute)
            }
        }
        return geofenceZoneItem
    }
}
