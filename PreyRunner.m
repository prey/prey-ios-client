//
//  PreyRunner.m
//  Prey
//
//  Created by Carlos Yaconi on 18/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "PreyRunner.h"
#import "LocationModule.h"
#import "DeviceModulesConfig.h"
#import "Report.h"


@implementation PreyRunner

@synthesize lastLocation,config,http;

+(PreyRunner *)instance  {
	static PreyRunner *instance;
	
	@synchronized(self) {
		if(!instance) {
			instance = [[PreyRunner alloc] init];
			LogMessageCompat(@"Registering PreyRunner to receive location updates notifications");
			[[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(locationUpdated:) name:@"locationUpdated" object:nil];
			instance.config = [PreyConfig instance]; 
			instance.http = [[PreyRestHttp alloc] init];
		}
	}
	
	return instance;
}

//this method starts the continous execution of Prey
-(void) startPreyService{
	LogMessageCompat(@"Starting Prey... ");
	lastExecution = [[NSDate date] retain];
	//We'll use the location services to keep Prey running in the background...
	LocationController *locController = [LocationController instance];
	[locController startUpdatingLocation];
	if (![PreyRestHttp checkInternet])
		return;
	[http changeStatusToMissing:YES forDevice:[config deviceKey] fromUser:[config apiKey]];

}

-(void)stopPreyService {
	LogMessageCompat(@"Stopping Prey... ");
	LocationController *locController = [LocationController instance];
	[locController stopUpdatingLocation];
	if (![PreyRestHttp checkInternet])
		return;
	[http changeStatusToMissing:NO forDevice:[config deviceKey] fromUser:[config apiKey]];
}

-(void) startOnIntervalChecking {
	LogMessageCompat(@"Starting interval checking monitoring... ");
	[[LocationController instance] startMonitoringSignificantLocationChanges];
}

-(void) stopOnIntervalChecking {
	LogMessageCompat(@"Stopping interval checking monitoring... ");
	[[LocationController instance] stopMonitoringSignificantLocationChanges];
}


- (void)locationUpdated:(NSNotification *)notification
{
	if (lastExecution != nil) {
		NSTimeInterval lastRunInterval = -[lastExecution timeIntervalSinceNow];
		LogMessage(@"Prey Runner", 0, @"Checking if delay of %i secs. is less than last running interval: %f secs.", [PreyConfig instance].delay, lastRunInterval);
		if (lastRunInterval >= [PreyConfig instance].delay){
			LogMessage(@"Prey Runner", 0, @"Location updated notification received. Waiting interval expired, running Prey now!");
			NSInvocationOperation* theOp = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(runPrey) object:nil] autorelease];
            [theOp start];
            //[self runPrey]; 
            
		}
		LogMessage(@"Prey Runner", 0, @"Location updated notification received, but interval hasn't expired.");
	} else {
		[self runPrey];
	}

	
}


-(void) runPrey{
    @try {
        lastExecution = [[NSDate date] retain];
        if (![PreyRestHttp checkInternet])
            return;
        DeviceModulesConfig *modulesConfig = [[http getXMLforUser:[config apiKey] device:[config deviceKey]] retain];
        if (USE_CONTROL_PANEL_DELAY)
            [PreyConfig instance].delay = [modulesConfig.delay intValue];
        
        if (!modulesConfig.missing){
            LogMessage(@"Prey Runner", 5, @"Not missing anymore... stopping accurate location updates and Prey.");
            [[LocationController instance] stopUpdatingLocation]; //finishes Prey execution
            [modulesConfig release];
            return;
        }
        
        reportQueue = [[NSOperationQueue alloc] init];
        [reportQueue addObserver:self forKeyPath:@"operationCount" options:0 context:modulesConfig.reportToFill];
        
        PreyModule *module;
        for (module in modulesConfig.reportModules){
            [reportQueue  addOperation:module];
        }
        
        actionQueue = [[NSOperationQueue alloc] init];
        for (module in modulesConfig.actionModules){
            [actionQueue  addOperation:module];
        }
        
        
        [modulesConfig release];
    }
    @catch (NSException *exception) {
        LogMessage(@"Prey Runner", 0, @"Exception catched while running Prey: %@", [exception reason]);
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
            LogMessage(@"Prey Runner", 10, @"Queue has completed. Total modules in the report: %i", [report.modules count]);
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object 
                               change:change context:context];
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
