//
//  TriggersActions+Properties.swift
//  Prey
//
//  Created by Javier Cala Uribe on 17/7/19.
//  Copyright © 2019 Prey, Inc. All rights reserved.
//
//

import CoreData
import Foundation

public extension TriggersActions {
    @nonobjc class func fetchRequest() -> NSFetchRequest<TriggersActions> {
        return NSFetchRequest<TriggersActions>(entityName: "TriggersActions")
    }

    @NSManaged var action: String?
    @NSManaged var delay: NSNumber?
    @NSManaged var trigger: Triggers?
}
