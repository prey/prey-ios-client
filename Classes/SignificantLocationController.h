//
//  SignificantLocationController.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 28/03/2011.
//  Copyright 2011 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import <Foundation/Foundation.h>


@interface SignificantLocationController : NSObject <CLLocationManagerDelegate> {
    
}

@property (nonatomic, retain) CLLocationManager *significantLocationManager;

+(SignificantLocationController *) instance;
- (void)startMonitoringSignificantLocationChanges;
- (void)stopMonitoringSignificantLocationChanges;
@end
