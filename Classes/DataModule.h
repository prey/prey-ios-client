//
//  DataModule.h
//  Prey
//
//  Created by Carlos Yaconi on 18-12-12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PreyModule.h"

@interface DataModule : PreyModule {

}

- (void) get;
- (NSMutableDictionary*) createResponseFromString: (NSString*) value withKey: (NSString*) key;
- (NSMutableDictionary*) createResponseFromObject: (NSDictionary*) dict;
- (NSMutableDictionary*) createResponseFromObject: dict withKey:(NSString *) key;
- (NSMutableDictionary*) createResponseFromData: (NSData*) rawData withKey: (NSString*) key;
- (void)sendHttp:(NSMutableDictionary*)data;
- (void)sendHttp:(NSMutableDictionary*)data andRaw:(NSMutableDictionary*) rawData;
- (void)sendHttpEvent:(NSMutableDictionary*)event withParameters:(NSMutableDictionary*)parameters;
- (void)notifyCommandResponse:(NSString*)action withTarget:(NSString *)target withStatus:(NSString*)status withReason:(NSString*)reason;

@end
