//
//  Triggers+CoreDataProperties.swift
//  Prey
//
//  Created by Javier Cala Uribe on 17/7/19.
//  Copyright © 2019 Fork Ltd. All rights reserved.
//
//

import Foundation
import CoreData


extension Triggers {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Triggers> {
        return NSFetchRequest<Triggers>(entityName: "Triggers")
    }

    @NSManaged public var id: NSNumber?
    @NSManaged public var name: String?
    @NSManaged public var actions: NSSet?
    @NSManaged public var events: NSSet?

}

// MARK: Generated accessors for actions
extension Triggers {

    @objc(addActionsObject:)
    @NSManaged public func addToActions(_ value: TriggersActions)

    @objc(removeActionsObject:)
    @NSManaged public func removeFromActions(_ value: TriggersActions)

    @objc(addActions:)
    @NSManaged public func addToActions(_ values: NSSet)

    @objc(removeActions:)
    @NSManaged public func removeFromActions(_ values: NSSet)

}

// MARK: Generated accessors for events
extension Triggers {

    @objc(addEventsObject:)
    @NSManaged public func addToEvents(_ value: TriggersEvents)

    @objc(removeEventsObject:)
    @NSManaged public func removeFromEvents(_ value: TriggersEvents)

    @objc(addEvents:)
    @NSManaged public func addToEvents(_ values: NSSet)

    @objc(removeEvents:)
    @NSManaged public func removeFromEvents(_ values: NSSet)

}
