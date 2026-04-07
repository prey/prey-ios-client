//
//  TriggersEvents+Properties.swift
//  Prey
//
//  Created by Javier Cala Uribe on 17/7/19.
//  Copyright © 2019 Prey, Inc. All rights reserved.
//
//

import CoreData
import Foundation

public extension TriggersEvents {
    @nonobjc class func fetchRequest() -> NSFetchRequest<TriggersEvents> {
        return NSFetchRequest<TriggersEvents>(entityName: "TriggersEvents")
    }

    @NSManaged var info: String?
    @NSManaged var type: String?
    @NSManaged var trigger: Triggers?
}
