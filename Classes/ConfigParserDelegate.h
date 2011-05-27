//
//  ConfigParserDelegate.h
//  Prey
//
//  Created by Carlos Yaconi on 18/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DeviceModulesConfig.h"

@interface ConfigParserDelegate : NSObject<NSXMLParserDelegate>  {
	BOOL inMissing;
	BOOL inDelay;
	BOOL inPostUrl;
	BOOL inModules;
	BOOL inModule;
    BOOL inCameraToUse;
    BOOL inAccuracy;
	DeviceModulesConfig *modulesConfig;
	
}

- (DeviceModulesConfig*) parseModulesConfig:(NSData *)request parseError:(NSError **)err;
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict;
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string;

@end
