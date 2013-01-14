//
//  PreyModule.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 18/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import <Foundation/Foundation.h>

enum _ModuleType {DataModuleType = 0, ActionModuleType, SettingModuleType};
typedef NSInteger ModuleType;

@interface PreyModule : NSOperation {
	NSDictionary *options;
    NSString *command;
    ModuleType type;
}

@property (nonatomic, retain) NSDictionary *options;
@property (nonatomic, retain) NSString *command;
@property (nonatomic) ModuleType type;


+ (PreyModule *) newModuleForName: (NSString *) moduleName;
- (NSString *) getName;
- (NSMutableDictionary *) reportData;

@end
