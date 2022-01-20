//
//  TriggersActions+CoreDataProperties.swift
//  Prey
//
//  Created by Javier Cala Uribe on 17/7/19.
//  Copyright © 2019 Prey, Inc. All rights reserved.
//
//

import Foundation
import CoreData


extension TriggersActions {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TriggersActions> {
        return NSFetchRequest<TriggersActions>(entityName: "TriggersActions")
    }

    @NSManaged public var action: String?
    @NSManaged public var delay: NSNumber?
    @NSManaged public var trigger: Triggers?

}
