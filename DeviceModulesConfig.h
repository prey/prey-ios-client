//
//  DeviceModulesConfig.h
//  Prey
//
//  Created by Carlos Yaconi on 18/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DeviceModulesConfig : NSObject {
	BOOL missing;
	NSNumber *delay;
	NSString *postUrl;
	NSMutableArray *modules;
	

}
@property (nonatomic) BOOL missing;
@property (nonatomic, retain) NSNumber *delay;
@property (nonatomic, retain) NSString *postUrl;
@property (nonatomic, retain) NSMutableArray *modules;

- (void) addModuleName: (NSString *) name ifActive: (NSString *) isActive;
- (void) addConfigValue: (NSString *) value withKey: (NSString *) key forModuleName: (NSString *) name;

@end
