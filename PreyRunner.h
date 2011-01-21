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
	NSOperationQueue *reportQueue;
	NSOperationQueue *actionQueue;
	
}
@property (nonatomic, retain) CLLocation *lastLocation;
@property (nonatomic, retain) NSDate *lastExecution;
@property (nonatomic, retain) NSNumber *delay;

+(PreyRunner *) instance;
-(void)startPreyService;
-(void)stopPreyService;
-(void) startOnIntervalChecking;
-(void) stopOnIntervalChecking;
-(void)runPrey;

@end
