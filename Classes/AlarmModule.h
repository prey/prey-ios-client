//
//  AlarmModule.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 19/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "PreyModule.h"

@class AVAudioPlayer;
@interface AlarmModule : PreyModule 

{
    
}

@property (nonatomic,retain) AVAudioPlayer *audioPlayer;

@end
