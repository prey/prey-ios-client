//
//  DataModule.h
//  Prey
//
//  Created by Carlos Yaconi on 18-12-12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PreyRestHttp.h"
#import "PreyConfig.h"
#import "PreyModule.h"

@interface DataModule : PreyModule {

}

- (void) get;
- (void) sendData: (NSString*) value forKey: (NSString*) key;


@end
