//
//  PreyRunner.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 18/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "PreyRunner.h"
#import "LocationModule.h"
#import "DeviceModulesConfig.h"
#import "Report.h"
#import "SignificantLocationController.h"


@implementation PreyRunner

@synthesize lastLocation,config,http;

+(PreyRunner *)instance  {
	static PreyRunner *instance;
	
	@synchronized(self) {
		if(!instance) {
			instance = [[PreyRunner alloc] init];
			PreyLogMessage(@"Prey Runner", 0,@"Registering PreyRunner to receive location updates notifications");
			[[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(locationUpdated:) name:@"locationUpdated" object:nil];
            
            PreyRestHttp *preyRestHttp = [[PreyRestHttp alloc] init];
			instance.http              = preyRestHttp;
            [preyRestHttp release];
		}
	}
	instance.config        = [PreyConfig instance];
    
	return instance;
}

-(void) startPreyOnMainThread {
	//We use the location services to keep Prey running in the background...
	LocationController *locController = [LocationController instance];
	[locController startUpdatingLocation];
	if (![PreyRestHttp checkInternet])
		return;
	[http changeStatusToMissing:YES forDevice:[config deviceKey] fromUser:[config apiKey]];
    config.missing=YES;
    PreyLogMessageAndFile(@"Prey Runner", 0,@"Prey service has been started.");

}
//this method starts the continous execution of Prey
-(void) startPreyService{
	[self performSelectorOnMainThread:@selector(startPreyOnMainThread) withObject:nil waitUntilDone:NO];
}

-(void)stopPreyService {
	LocationController *locController = [LocationController instance];
	[locController stopUpdatingLocation];
	if (![PreyRestHttp checkInternet])
		return;
	[http changeStatusToMissing:NO forDevice:[config deviceKey] fromUser:[config apiKey]];
    config.missing=NO;
    lastExecution = nil;
    PreyLogMessageAndFile(@"Prey Runner", 0,@"Prey service has been stopped.");
}

-(void) startOnIntervalChecking {
	[[SignificantLocationController instance] startMonitoringSignificantLocationChanges];
    PreyLogMessageAndFile(@"Prey Runner", 0,@"Interval checking has been started.");
}

-(void) stopOnIntervalChecking {
	[[SignificantLocationController instance] stopMonitoringSignificantLocationChanges];
    lastExecution = nil;
    PreyLogMessageAndFile(@"Prey Runner", 0,@"Interval checking has been stopped.");
}

-(void) runPreyNow {
    lastExecution = nil;
    NSInvocationOperation* theOp = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(runPrey) object:nil] autorelease];
    [theOp start];
}


- (void)locationUpdated:(NSNotification *)notification
{
	NSInvocationOperation* theOp = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(runPrey) object:nil] autorelease];
    [theOp start];
    
    /*
    if (lastExecution != nil) {
		NSTimeInterval lastRunInterval = -[lastExecution timeIntervalSinceNow];
		PreyLogMessage(@"Prey Runner", 0, @"Checking if delay of %i secs. is less than last running interval: %f secs.", [PreyConfig instance].delay, lastRunInterval);
		if (lastRunInterval >= [PreyConfig instance].delay){
			PreyLogMessage(@"Prey Runner", 0, @"New location notification received. Delay expired (%f secs. since last execution), running Prey now!", lastRunInterval);
			
            [theOp start];
            //[self runPrey]; 
		} else
            PreyLogMessage(@"Prey Runner", 5, @"Location updated notification received, but interval hasn't expired. (%f secs. since last execution)",lastRunInterval);
	} else {
		[theOp start];
	}*/
}


-(void) runPrey{
    @try {
        if (lastExecution != nil) {
            NSTimeInterval lastRunInterval = -[lastExecution timeIntervalSinceNow];
            PreyLogMessage(@"Prey Runner", 0, @"Checking if delay of %i secs. is less than last running interval: %f secs.", [PreyConfig instance].delay, lastRunInterval);
            if (lastRunInterval < [PreyConfig instance].delay){
                PreyLogMessage(@"Prey Runner", 0, @"Trying to get device's status but interval hasn't expired. (%f secs. since last execution). Aborting!", lastRunInterval);
                return;
            }
        }
        
        lastExecution = [[NSDate date] retain];
        if (![PreyRestHttp checkInternet])
            return;
        UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication]
                                             beginBackgroundTaskWithExpirationHandler:^{}];
        DeviceModulesConfig *modulesConfig = [[http getXMLforUser:[config apiKey] device:[config deviceKey]] retain];
        
        if (USE_CONTROL_PANEL_DELAY)
            [PreyConfig instance].delay = [modulesConfig.delay intValue] * 60;
        
        if (!modulesConfig.missing){
            PreyLogMessageAndFile(@"Prey Runner", 5, @"Not missing anymore... stopping accurate location updates and Prey.");
            [[LocationController instance] stopUpdatingLocation]; //finishes Prey execution
            [modulesConfig release];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"missingUpdated" object:[PreyConfig instance]];
            lastExecution=nil;
            return;
        }
        
        reportQueue = [[NSOperationQueue alloc] init];
        //[reportQueue addObserver:self forKeyPath:@"operationCount" options:0 context:modulesConfig.reportToFill];
        
        PreyModule *module;
        Report *report = nil;
        for (module in modulesConfig.reportModules){
            //[reportQueue  addOperation:module];
            PreyLogMessage(@"Prey Runner", 5, @"Executing module: %@.", [module getName]);
            [module main];
            //report = module.reportToFill; //WIP
        }
        [report send];
        
        actionQueue = [[NSOperationQueue alloc] init];
        for (module in modulesConfig.actionModules){
            [actionQueue  addOperation:module];
        }
        
        
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        
        [modulesConfig release];
    }
    @catch (NSException *exception) {
        PreyLogMessageAndFile(@"Prey Runner", 0, @"Exception catched while running Prey: %@", [exception reason]);
    }
	
	/*
	
	UILocalNotification *localNotif = [[UILocalNotification alloc] init];
	
    localNotif.fireDate = [NSDate dateWithTimeIntervalSinceNow:[modulesConfig.delay intValue]*60/4];
    localNotif.timeZone = [NSTimeZone defaultTimeZone];
	
    localNotif.alertBody = [NSString stringWithFormat:NSLocalizedString(@"Prey next execution in %i minutes.", nil), [modulesConfig.delay intValue]/4*60];
    localNotif.alertAction = NSLocalizedString(@"View Details", nil);
	
    localNotif.soundName = UILocalNotificationDefaultSoundName;
    //localNotif.applicationIconBadgeNumber = 1;
	
	
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
    [localNotif release];
	*/
	
	
	
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == reportQueue && [keyPath isEqual:@"operationCount"]) {
        if ([reportQueue operationCount] == 0) {
            Report *report = (Report *)context;
			[report send];
            PreyLogMessage(@"Prey Runner", 10, @"Queue has completed. Total modules in the report: %i", [report.modules count]);
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc {
	[reportQueue release], reportQueue = nil;
	[actionQueue release], actionQueue = nil;
	[http release];
	[lastExecution release];
    [super dealloc];
}
@end
