//
//  Location.h
//  Prey
//
//  Created by Carlos Yaconi on 23-01-13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import "DataModule.h"

@interface Location : DataModule <CLLocationManagerDelegate>{

    CLLocationManager  *locManager;
    SEL                 methodToInvoke;
    NSObject            *targetObject;
    CLLocation          *bestEffortAtLocation;
}

@property (nonatomic, retain) CLLocationManager *locManager;
@property (nonatomic, retain) CLLocation        *bestEffortAtLocation;

- (void)testLocation;

@end
