//
//  AlarmModule.h
//  Prey
//
//  Created by Carlos Yaconi on 19/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "PreyModule.h"

@class AVAudioPlayer;
@interface AlarmModule : PreyModule 

{
    
    AVAudioPlayer *backgroundMusicPlayer;
}

@property (nonatomic,retain) AVAudioPlayer *backgroundMusicPlayer;

@end
