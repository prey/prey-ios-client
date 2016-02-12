//
//  GeofenceZones+CoreDataProperties.h
//  Prey
//
//  Created by Javier Cala Uribe on 11/02/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "GeofenceZones.h"

NS_ASSUME_NONNULL_BEGIN

@interface GeofenceZones (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *account_id;
@property (nullable, nonatomic, retain) NSString *color;
@property (nullable, nonatomic, retain) NSString *created_at;
@property (nullable, nonatomic, retain) NSString *deleted_at;
@property (nullable, nonatomic, retain) NSString *direction;
@property (nullable, nonatomic, retain) NSString *expires;
@property (nullable, nonatomic, retain) NSNumber *zone_id;
@property (nullable, nonatomic, retain) NSNumber *lat;
@property (nullable, nonatomic, retain) NSNumber *lng;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSNumber *radius;
@property (nullable, nonatomic, retain) NSString *state;
@property (nullable, nonatomic, retain) NSString *updated_at;
@property (nullable, nonatomic, retain) NSString *zones;

@end

NS_ASSUME_NONNULL_END
