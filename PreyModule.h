//
//  PreyModule.h
//  Prey
//
//  Created by Carlos Yaconi on 18/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Report.h"

enum _ModuleType {ReportModuleType = 0, ActionModuleType};
typedef NSInteger ModuleType;

@interface PreyModule : NSOperation {
	NSMutableDictionary *configParms;
	Report *reportToFill;
	ModuleType type;
}
@property (nonatomic, retain) NSMutableDictionary *configParms;
@property (nonatomic, retain) Report *reportToFill;
@property (nonatomic) ModuleType type;

+ (PreyModule *) newModuleForName: (NSString *) moduleName;
- (NSString *) getName;
- (NSMutableDictionary *) reportData;

@end
