//
//  GeofenceZones+CoreDataProperties.swift
//  Prey
//
//  Created by Javier Cala Uribe on 6/06/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension GeofenceZones {

    @NSManaged var account_id: NSNumber?
    @NSManaged var color: String?
    @NSManaged var created_at: String?
    @NSManaged var deleted_at: String?
    @NSManaged var direction: String?
    @NSManaged var expires: String?
    @NSManaged var lat: NSNumber?
    @NSManaged var lng: NSNumber?
    @NSManaged var name: String?
    @NSManaged var radius: NSNumber?
    @NSManaged var state: String?
    @NSManaged var updated_at: String?
    @NSManaged var id: NSNumber?
    @NSManaged var zones: String?

}
