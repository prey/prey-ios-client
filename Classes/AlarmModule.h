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
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "ActionModule.h"

@class AVAudioPlayer;
@interface AlarmModule : ActionModule <AVAudioPlayerDelegate>
{
    AVAudioPlayer *audioPlayer;
}



@end
