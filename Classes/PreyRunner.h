//
//  PreyRunner.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 18/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import <Foundation/Foundation.h>
#import "LocationController.h"
#import "PreyConfig.h"
#import "PreyRestHttp.h"


@interface PreyRunner : NSObject {
	CLLocation *lastLocation;
	NSOperationQueue *actionQueue;
	PreyConfig *config;
	PreyRestHttp *preyRestHttp;
	NSDate *lastExecution;
	
}
@property (nonatomic, retain) CLLocation *lastLocation;
//@property (nonatomic, retain) NSDate *lastExecution;
@property (nonatomic, retain) PreyConfig *config;
@property (nonatomic, retain) PreyRestHttp *preyRestHttp;

+(PreyRunner *) instance;
-(void)startPreyService;
-(void)stopPreyService;
-(void) startOnIntervalChecking;
-(void) stopOnIntervalChecking;
-(void) runPrey;
-(void) runPreyNow;

@end
