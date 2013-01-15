//
//  SettingModule.m
//  Prey
//
//  Created by Carlos Yaconi on 14-01-13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import "SettingModule.h"
#import "PreyConfig.h"
#import "PreyRestHttp.h"

@implementation SettingModule

@synthesize setting;

- (id) init {
	self = [super init];
	if (self != nil)
		self.type = SettingModuleType;
	return self;
}

-(void) read:(NSString *)key {
    NSString *value = [[PreyConfig instance] readConfigValueForKey:key];
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [data setObject:key forKey:@"key"];
    [data setObject:value forKey:@"value"];
    [dict setObject:data forKey:@"setting"];
    
    PreyRestHttp* http = [[PreyRestHttp alloc] init];
    [http sendSetting:dict];
}


@end
