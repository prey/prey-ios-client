//
//  SettingModule.h
//  Prey
//
//  Created by Carlos Yaconi on 14-01-13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import "PreyModule.h"

@interface SettingModule : PreyModule {

    
}

@property(nonatomic, retain) NSString *setting;

//read and toggle methods accept parameters to implement the same interface that will be called by a selector.
- (void) read: (NSString*) key;
- (void) update: (NSString*) value;
- (void) toggle: (NSString*) value;

@end
