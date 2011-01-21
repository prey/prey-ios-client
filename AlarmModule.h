//
//  AlarmModule.h
//  Prey
//
//  Created by Carlos Yaconi on 19/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioServices.h>
#import "PreyModule.h"

@interface AlarmModule : PreyModule {
	CFURLRef        soundFileURLRef;
    SystemSoundID   soundFileObject;
}

@property (readwrite)   CFURLRef        soundFileURLRef;
@property (readonly)    SystemSoundID   soundFileObject;

@end
