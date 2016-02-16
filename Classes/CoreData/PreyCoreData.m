//
//  PreyCoreData.m
//  Prey
//
//  Created by Javier Cala Uribe on 11/02/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

#import "PreyCoreData.h"
#import "GeofenceZones.h"
#import "PreyGeofencingController.h"
#import "GeofencingModule.h"
#import "Constants.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@implementation PreyCoreData

@synthesize managedObjectContext        = __managedObjectContext;
@synthesize managedObjectModel          = __managedObjectModel;
@synthesize persistentStoreCoordinator  = __persistentStoreCoordinator;

+ (PreyCoreData *)instance {
    static PreyCoreData *instance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        instance = [[PreyCoreData alloc] init];
    });
    
    return instance;
}

- (void)updateGeofenceZones:(id)response
{
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
    [fetch setEntity:[NSEntityDescription entityForName:@"GeofenceZones" inManagedObjectContext:context]];
    NSArray  *localZonesArray = [context executeFetchRequest:fetch error:nil];
    
    // Added zones events
    NSMutableArray *addedZones   = [self getAddedZones:response withLocalZones:localZonesArray];
    if (addedZones)
        [self sendEventToPanel:addedZones withCommand:@"start" withStatus:@"started"];
    
    
    // Deleted zones events
    NSMutableArray *deletedZones = [self getDeletedZones:response withLocalZones:localZonesArray];
    if (deletedZones)
        [self sendEventToPanel:deletedZones withCommand:@"stop" withStatus:@"stopped"];
    
    
    // Delete all regions on Device
    [self deleteAllRegionsOnDevice];
    
    // Delete all regions on CoreData
    [self deleteAllRegionsOnCoreData:localZonesArray withContext:context];
    
    // Add regions to CoreData
    [self addRegionsToCoreData:response withContext:context];

    // Add regions to Device
    [self addRegionsToDevice:context];
}

- (void)sendEventToPanel:(NSMutableArray*)zonesArray withCommand:(NSString*)command withStatus:(NSString*)status
{
    GeofencingModule *geofencingModule = [[GeofencingModule alloc] init];
    NSMutableArray *zonesId = [[NSMutableArray alloc] init];
    
    for (NSDictionary *itemAdded in zonesArray) {
        
        if ([itemAdded isKindOfClass:[GeofenceZones class]]) {
            GeofenceZones *item = (GeofenceZones*)itemAdded;
            [zonesId addObject:item.zone_id];
        }
        else
            [zonesId addObject:[NSNumber numberWithDouble:[[itemAdded valueForKey:@"id"] floatValue]]];
    }
    
    if (zonesId.count > 0) {
        NSString *zones = [NSString stringWithFormat:@"[%@]",[[zonesId valueForKey:@"description"] componentsJoinedByString:@","]];
        [geofencingModule notifyCommandResponse:command withTarget:@"geofencing" withStatus:status withReason:zones];
    }
}

- (NSMutableArray*)getAddedZones:(id)serverResponse withLocalZones:(NSArray*)localZonesArray
{
    NSMutableArray *addedZones   = [[NSMutableArray alloc] init];
    for (NSDictionary *serverZonesArray in serverResponse)
    {
        NSNumber *serverZone = [NSNumber numberWithDouble:[[serverZonesArray valueForKey:@"id"] floatValue]];
        BOOL isLocalZone = NO;
        
        for (GeofenceZones *localZone in localZonesArray)
        {
            if (serverZone == localZone.zone_id)
                isLocalZone = YES;
        }
        
        if (!isLocalZone)
            [addedZones addObject:serverZonesArray];
    }
    return addedZones;
}

- (NSMutableArray*)getDeletedZones:(id)serverResponse withLocalZones:(NSArray*)localZonesArray
{
    NSMutableArray *deletedZones = [[NSMutableArray alloc] init];
    for (GeofenceZones *localZone in localZonesArray)
    {
        BOOL isDeletedZone = YES;
        
        for (NSDictionary *serverZonesArray in serverResponse)
        {
            NSNumber *serverZone = [NSNumber numberWithDouble:[[serverZonesArray valueForKey:@"id"] floatValue]];
            
            if (serverZone == localZone.zone_id)
                isDeletedZone = NO;
        }
        
        if (isDeletedZone)
            [deletedZones addObject:localZone];
    }

    return deletedZones;
}

- (void)deleteAllRegionsOnCoreData:(NSArray*)localZonesArray withContext:(NSManagedObjectContext*)context
{
    for (GeofenceZones *localZone in localZonesArray)
        [context deleteObject:localZone];
}

- (void)deleteAllRegionsOnDevice
{
    NSSet *regions = [[PreyGeofencingController instance] geofencingManager].monitoredRegions;
    for (CLRegion *item in regions)
        [[PreyGeofencingController instance] removeRegion:item.identifier];
}

- (void)addRegionsToCoreData:(id)serverResponse withContext:(NSManagedObjectContext*)context
{
    for (NSDictionary *serverZonesArray in serverResponse)
    {
        GeofenceZones *geofenceZones = [NSEntityDescription insertNewObjectForEntityForName:@"GeofenceZones" inManagedObjectContext:context];
        geofenceZones.account_id     = [NSNumber numberWithDouble:[[serverZonesArray valueForKey:@"account_id"] floatValue]];
        geofenceZones.color          = NULL_TO_NIL([serverZonesArray objectForKey:@"color"]);
        geofenceZones.created_at     = NULL_TO_NIL([serverZonesArray objectForKey:@"created_at"]);
        geofenceZones.deleted_at     = NULL_TO_NIL([serverZonesArray objectForKey:@"deleted_at"]);
        geofenceZones.direction      = NULL_TO_NIL([serverZonesArray objectForKey:@"direction"]);
        geofenceZones.expires        = NULL_TO_NIL([serverZonesArray objectForKey:@"expires"]);
        geofenceZones.zone_id        = [NSNumber numberWithDouble:[[serverZonesArray valueForKey:@"id"] floatValue]];
        geofenceZones.lat            = [NSNumber numberWithDouble:[[serverZonesArray valueForKey:@"lat"] floatValue]];
        geofenceZones.lng            = [NSNumber numberWithDouble:[[serverZonesArray valueForKey:@"lng"] floatValue]];
        geofenceZones.name           = NULL_TO_NIL([serverZonesArray objectForKey:@"name"]);
        geofenceZones.radius         = [NSNumber numberWithDouble:[[serverZonesArray valueForKey:@"radius"] floatValue]];
        geofenceZones.state          = NULL_TO_NIL([serverZonesArray objectForKey:@"state"]);
        geofenceZones.updated_at     = NULL_TO_NIL([serverZonesArray objectForKey:@"updated_at"]);
        geofenceZones.zones          = NULL_TO_NIL([serverZonesArray objectForKey:@"zones"]);
    }
    
    NSError *error;
    if (![context save:&error])
        NSLog(@"Couldn't save: %@", [error localizedDescription]);
}

- (void)addRegionsToDevice:(NSManagedObjectContext*)context
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity  = [NSEntityDescription entityForName:@"GeofenceZones" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (GeofenceZones *info in fetchedObjects) {
        NSLog(@"Name Zone: %@", info.name);
        
        CLLocationDegrees       center_lat  = [info.lat doubleValue];
        CLLocationDegrees       center_lon  = [info.lng doubleValue];
        CLLocationDistance      radius      = [info.radius doubleValue];
        CLLocationCoordinate2D  center      = CLLocationCoordinate2DMake(center_lat, center_lon);
        
        NSString                *zoneID     = [NSString stringWithFormat:@"%f",[info.zone_id floatValue]];
        CLRegion                *region;
        
        if (IS_OS_7_OR_LATER)
        {
            if ([CLLocationManager isMonitoringAvailableForClass:[CLRegion class]])
            {
                region =  [[CLCircularRegion alloc] initWithCenter:center radius:radius identifier:zoneID];
            }
        }
        else
            region = [[CLRegion alloc] initCircularRegionWithCenter:center radius:radius identifier:zoneID];
        
        [[PreyGeofencingController instance] addNewregion:region];
    }
}

#pragma mark - Geofence Methods

- (NSArray*)getCurrentGeofenceZones
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity  = [NSEntityDescription entityForName:@"GeofenceZones" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];

    return fetchedObjects;
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil) {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        __managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }
    NSURL *modelURL         = [[NSBundle mainBundle] URLForResource:@"PreyModelData" withExtension:@"momd"];
    __managedObjectModel    = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil) {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"PreyModelData.sqlite"];
    
    NSError *error  = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        
#warning check Persistents
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    return __persistentStoreCoordinator;
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
