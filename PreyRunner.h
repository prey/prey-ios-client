//
//  PreyRunner.h
//  Prey
//
//  Created by Carlos Yaconi on 18/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LocationController.h"


@interface PreyRunner : NSObject {
	CLLocation *lastLocation;
	NSOperationQueue *queue;
}
@property (nonatomic, retain) CLLocation *lastLocation;
+(PreyRunner *) instance;
-(void)goPrey;
@end
