//
//  PreyCoreData.h
//  Prey
//
//  Created by Javier Cala Uribe on 11/02/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PreyCoreData : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext          *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel            *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator    *persistentStoreCoordinator;

+ (PreyCoreData*)instance;

- (NSArray*)getCurrentGeofenceZones;
- (BOOL)isGeofenceActive;
- (void)updateGeofenceZones:(id)response;

@end
