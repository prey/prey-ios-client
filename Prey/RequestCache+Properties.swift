//
//  RequestCache+CoreDataProperties.swift
//  Prey
//
//  Created by Javier Cala Uribe on 29/4/20.
//  Copyright © 2020 Prey, Inc. All rights reserved.
//
//

import Foundation
import CoreData


extension RequestCache {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RequestCache> {
        return NSFetchRequest<RequestCache>(entityName: "RequestCache")
    }

    @NSManaged public var request: Data?
    @NSManaged public var session_config: Data?
    @NSManaged public var error: Data?
    @NSManaged public var timestamp: NSNumber?

}
