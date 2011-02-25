//
//  PreyRunner.m
//  Prey
//
//  Created by Carlos Yaconi on 18/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "PreyRunner.h"
#import "LocationModule.h"
#import "PreyConfig.h"
#import "PreyRestHttp.h"
#import "DeviceModulesConfig.h"
#import "Report.h"


@implementation PreyRunner

@synthesize lastLocation,lastExecution,delay;

+(PreyRunner *)instance  {
	static PreyRunner *instance;
	
	@synchronized(self) {
		if(!instance) {
			instance = [[PreyRunner alloc] init];
			LogMessageCompat(@"Registering PreyRunner to receive location updates notifications");
			[[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(locationUpdated:) name:@"locationUpdated" object:nil];
			
		}
	}
	
	return instance;
}

//this method starts the continous execution of Prey
-(void) startPreyService{
	LogMessageCompat(@"Starting Prey... ");
	self.lastExecution = [NSDate date];
	//We'll use the location services to keep Prey running in the background...
	LocationController *locController = [LocationController instance];
	[locController startUpdatingLocation];
	if (![PreyRestHttp checkInternet])
		return;
	PreyConfig *config = [PreyConfig instance];
	PreyRestHttp *preyHttp = [[PreyRestHttp alloc] init];
	[preyHttp changeStatusToMissing:YES forDevice:[config deviceKey] fromUser:[config apiKey]];
	[preyHttp release];
	
	[self runPrey];
}

-(void)stopPreyService {
	LogMessageCompat(@"Stopping Prey... ");
	LocationController *locController = [LocationController instance];
	[locController stopUpdatingLocation];
	if (![PreyRestHttp checkInternet])
		return;
	PreyConfig *config = [PreyConfig instance];
	PreyRestHttp *preyHttp = [[PreyRestHttp alloc] init];
	[preyHttp changeStatusToMissing:NO forDevice:[config deviceKey] fromUser:[config apiKey]];
	[preyHttp release];
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
	NSTimeInterval lastRunInterval = -[self.lastExecution timeIntervalSinceNow];
    if (lastRunInterval >= delay.intValue*60/4){
		LogMessage(@"Prey Runner", 0, @"Location updated notification received. Waiting interval expired, running Prey now!");
		[self runPrey]; 
	}
	LogMessage(@"Prey Runner", 0, @"Location updated notification received, but interval hasn't expired.");
}


-(void) runPrey{
	self.lastExecution = [NSDate date];
	if (![PreyRestHttp checkInternet])
		return;
	PreyRestHttp *preyHttp = [[PreyRestHttp alloc] init];
	PreyConfig *config = [PreyConfig instance];
	DeviceModulesConfig *modulesConfig = [preyHttp getXMLforUser:[config apiKey] device:[config deviceKey]];
	[preyHttp release];
	
	delay = modulesConfig.delay;
	if (!modulesConfig.missing){
		 LogMessageCompat(@"Not missing anymore... stopping accurate location updates and Prey.");
		[[LocationController instance] stopUpdatingLocation]; //finishes Prey execution
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
            LogMessageCompat(@"queue has completed. Total modules in the report: %i", [report.modules count]);
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
    [super dealloc];
}
@end
