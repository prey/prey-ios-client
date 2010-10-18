//
//  PreyModule.h
//  Prey
//
//  Created by Carlos Yaconi on 18/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PreyModule : NSOperation {
	NSMutableDictionary *configParms;
}
@property (nonatomic, retain) NSMutableDictionary *configParms;

+ (PreyModule *) getModuleForName: (NSString *) moduleName;
- (NSString *) getName;

@end
