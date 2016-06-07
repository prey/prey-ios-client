//
//  Geofencing.swift
//  Prey
//
//  Created by Javier Cala Uribe on 7/06/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import CoreData

class Geofencing: PreyAction {

    
    // MARK: Functions

    // Prey command
    override func start() {
        
        print("Check geofencing zone")
        checkGeofenceZones(self)
    }
    
    
    
    // Update Geofence Zones
    func updateGeofenceZones(response:NSArray) {
        
        let localZonesArray = PreyCoreData.sharedInstance.getCurrentGeofenceZones() as! [GeofenceZones]
        
        print("ZONES: \(response)")
        
        // Added zones events
        if let addedZones = getAddedZones(response, withLocalZones: localZonesArray) {
            sendEventToPanel(addedZones, withCommand:kCommand.START , withStatus:kStatus.STARTED)
        }
        
        // Deleted zones events
        if let deletedZones = getDeletedZones(response, withLocalZones: localZonesArray) {
            sendEventToPanel(deletedZones, withCommand:kCommand.STOP , withStatus:kStatus.STOPPED)
        }
        
        
        FIXME()
        // WIP: DELETE ALL REGIONS AND ADD ALL NEWS
        
    }
    
    // Send event to panel
    func sendEventToPanel(zonesArray:[GeofenceZones], withCommand cmd:kCommand, withStatus status:kStatus){
        
        // Create a zonesId array with new zones
        var zonesId = [NSNumber]()
        
        for itemAdded in zonesArray {
            zonesId.append(itemAdded.id!)
        }
        
        // Params struct
        let params:[String: AnyObject] = [
            kData.STATUS.rawValue   : status.rawValue,
            kData.TARGET.rawValue   : kAction.GEOFENCING.rawValue,
            kData.COMMAND.rawValue  : cmd.rawValue,
            kData.REASON.rawValue   : zonesId.description]
        
        // Send info to panel
        self.sendData(params, toEndpoint: responseDeviceEndpoint)
    }

    // Get Deleted Zones
    func getDeletedZones(serverResponse:NSArray, withLocalZones localZonesArray:[GeofenceZones]) -> [GeofenceZones]! {
        
        // Init GeofenceZones array to return
        var deletedZones = [GeofenceZones]()
        
        // Compare localZone.id with serverZone.id and add deleted zones to deletedZones array
        for localZone:GeofenceZones in localZonesArray {
            
            var isDeletedZone = false
            
            for serverZonesArray in serverResponse {

                let value       = serverZonesArray.valueForKey("id")!
                let serverZone  = NSNumber(float:value.floatValue)

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
    func getAddedZones(serverResponse:NSArray, withLocalZones localZonesArray:[GeofenceZones]) -> [GeofenceZones]! {
        
        // Init GeofenceZones array to return
        var addedZones = [GeofenceZones]()
        
        // Compare localZone.id with serverZone.id and add new to addedZones array
        for serverZonesArray in serverResponse {
            
            let value       = serverZonesArray.valueForKey("id")!
            let serverZone  = NSNumber(float:value.floatValue)
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
    func getGeofenceZoneItemFromDictionary(serverZonesArray:NSDictionary) -> GeofenceZones {

        // Init NSManagedObject type GeofenceZones
        let zoneEntity = NSEntityDescription.entityForName("GeofenceZones", inManagedObjectContext: PreyCoreData.sharedInstance.managedObjectContext)!
        let geofenceZoneItem = GeofenceZones(entity:zoneEntity, insertIntoManagedObjectContext: PreyCoreData.sharedInstance.managedObjectContext)
        
        // Attributes from GeofenceZones
        let attributes = geofenceZoneItem.entity.attributesByName
        
        for (attribute,description) in attributes {

            if var value = serverZonesArray.objectForKey(attribute){

                switch description.attributeType {
                    
                case .DoubleAttributeType:
                    value = NSNumber(double: value.doubleValue)
                    
                default:
                    value = value.isKindOfClass(NSNull) ? "" : value as! String
                }
                
                // Save {value,key} in GeofenceZone item
                geofenceZoneItem.setValue(value, forKey: attribute)
            }
        }
        return geofenceZoneItem
    }
}