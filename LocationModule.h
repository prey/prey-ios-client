//
//  LocationModule.h
//  Prey
//
//  Created by Carlos Yaconi on 18/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PreyModule.h"
#import "LocationController.h"b

@interface LocationModule : PreyModule <PreyLocationControllerDelegate> {
	LocationController *locationController;
}

- (void)locationUpdate:(CLLocation *)location;
- (void)locationError:(NSError *)error;

@end
