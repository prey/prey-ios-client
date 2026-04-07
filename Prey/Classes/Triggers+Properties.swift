//
//  Triggers+Properties.swift
//  Prey
//
//  Created by Javier Cala Uribe on 17/7/19.
//  Copyright © 2019 Prey, Inc. All rights reserved.
//
//

import CoreData
import Foundation

public extension Triggers {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Triggers> {
        return NSFetchRequest<Triggers>(entityName: "Triggers")
    }

    @NSManaged var id: NSNumber?
    @NSManaged var name: String?
    @NSManaged var actions: NSSet?
    @NSManaged var events: NSSet?
}

// MARK: Generated accessors for actions

public extension Triggers {
    @objc(addActionsObject:)
    @NSManaged func addToActions(_ value: TriggersActions)

    @objc(removeActionsObject:)
    @NSManaged func removeFromActions(_ value: TriggersActions)

    @objc(addActions:)
    @NSManaged func addToActions(_ values: NSSet)

    @objc(removeActions:)
    @NSManaged func removeFromActions(_ values: NSSet)
}

// MARK: Generated accessors for events

public extension Triggers {
    @objc(addEventsObject:)
    @NSManaged func addToEvents(_ value: TriggersEvents)

    @objc(removeEventsObject:)
    @NSManaged func removeFromEvents(_ value: TriggersEvents)

    @objc(addEvents:)
    @NSManaged func addToEvents(_ values: NSSet)

    @objc(removeEvents:)
    @NSManaged func removeFromEvents(_ values: NSSet)
}
