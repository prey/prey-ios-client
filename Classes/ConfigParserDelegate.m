//
//  ConfigParserDelegate.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 18/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "ConfigParserDelegate.h"
#import "DeviceModulesConfig.h"
#import "PreyConfig.h"


@interface ConfigParserDelegate ()
	@property (nonatomic) BOOL inMissing;
	@property (nonatomic) BOOL inDelay;
	@property (nonatomic) BOOL inPostUrl;
	@property (nonatomic) BOOL inModules;
	@property (nonatomic) BOOL inModule;
	@property (nonatomic) BOOL inAlertMessage;
    @property (nonatomic) BOOL inCameraToUse;
    @property (nonatomic) BOOL inAccuracy;
	@property (nonatomic, retain) DeviceModulesConfig *modulesConfig;
@end

@implementation ConfigParserDelegate
@synthesize inMissing,inDelay,inPostUrl,inModules,inModule,inAlertMessage,inCameraToUse,inAccuracy,modulesConfig;

- (id) init {
	self = [super init];
	if (self != nil){
        modulesConfig = [[DeviceModulesConfig alloc] init];    
		inMissing=NO;
		inDelay=NO;
		inPostUrl=NO;
		inModules=NO;
		inModule=NO;
		inAlertMessage=NO;
        inCameraToUse=NO;
        inAccuracy=NO;
	}
    return self;
}

- (DeviceModulesConfig*) parseModulesConfig:(NSData *)response parseError:(NSError **)err {
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:response];
	
	[parser setDelegate:self];
	
	[parser setShouldProcessNamespaces:NO]; // We don't care about namespaces
	[parser setShouldReportNamespacePrefixes:NO]; //
	[parser setShouldResolveExternalEntities:NO]; // We just want data, no other stuff
	
	[parser parse]; // Parse that data..
	
	if (err && [parser parserError]) {
		*err = [parser parserError];
	}
	
	[parser release];		
	return modulesConfig;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict 
{
	if ([elementName isEqualToString:@"missing"]) 
		self.inMissing = YES;
	else if ([elementName isEqualToString:@"delay"]) 
		self.inDelay = YES;
	else if ([elementName isEqualToString:@"post_url"]) 
		self.inPostUrl = YES;
	else if ([elementName isEqualToString:@"modules"]) 
		self.inModules = YES;
	else if ([elementName isEqualToString:@"module"]) {
		self.inModule = YES;
		if (self.inModules) {
			
			NSString *name = [attributeDict objectForKey:@"name"];
			NSString *active = [attributeDict objectForKey:@"active"];	
			NSString *type = [attributeDict objectForKey:@"type"];	
			[modulesConfig addModuleName:name ifActive:active ofType:type];
		}
	}
	if (self.inModule) {
		if ([elementName isEqualToString:@"alert_message"])
			self.inAlertMessage = YES;
        if ([elementName isEqualToString:@"camera"])
            self.inCameraToUse = YES;
        if ([elementName isEqualToString:@"accuracy"])
            self.inAccuracy = YES;
	}
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	if ([elementName isEqualToString:@"missing"]) 
		self.inMissing = NO;
	else if ([elementName isEqualToString:@"delay"]) 
		self.inDelay = NO;
	else if ([elementName isEqualToString:@"post_url"]) 
		self.inPostUrl = NO;
	else if ([elementName isEqualToString:@"modules"]) 
		self.inModules = NO;
	else if ([elementName isEqualToString:@"module"])
		self.inModule = NO;
	else if ([elementName isEqualToString:@"alert_message"])
		self.inAlertMessage = NO;
    else if ([elementName isEqualToString:@"camera"])
		self.inCameraToUse = NO;
    else if ([elementName isEqualToString:@"accuracy"])
		self.inAccuracy = NO;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if (self.inMissing){
		PreyConfig *config = [PreyConfig instance];
		modulesConfig.missing = [string isEqualToString:@"true"];
		config.missing = [string isEqualToString:@"true"];							
	}
	else if (self.inDelay)
		modulesConfig.delay=[NSNumber numberWithInt:[string intValue]];
	else if (self.inPostUrl)
		modulesConfig.postUrl = string;
	else if (self.inAlertMessage)
		[modulesConfig addConfigValue:string withKey:@"alert_message" forModuleName:@"alert"];
    else if (self.inCameraToUse)
		[modulesConfig addConfigValue:string withKey:@"camera" forModuleName:@"webcam"];
    else if (self.inAccuracy){
        PreyConfig *config = [PreyConfig instance];
        if ([string isEqualToString:@"min"])
            config.desiredAccuracy = [[NSNumber numberWithDouble:kCLLocationAccuracyThreeKilometers] doubleValue];
        if ([string isEqualToString:@"med"])
            config.desiredAccuracy = [[NSNumber numberWithDouble:kCLLocationAccuracyNearestTenMeters] doubleValue];
        if ([string isEqualToString:@"max"])
            config.desiredAccuracy = [[NSNumber numberWithDouble:kCLLocationAccuracyBestForNavigation] doubleValue];
    }
	
}


- (void)dealloc {
	[super dealloc];
    [modulesConfig release];
}

@end
