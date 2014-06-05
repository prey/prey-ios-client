//
//  AlarmModule.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 19/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//


#import "AlarmModule.h"
#import "Constants.h"

@implementation AlarmModule

- (void) start {
    PreyLogMessage(@"alarm", 10, @"Playing the alarm now!");
    
    NSInteger requestNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"requestNumber"] + 2;
    [[NSUserDefaults standardUserDefaults] setInteger:requestNumber forKey:@"requestNumber"];
    
    [[AVAudioSession sharedInstance]  setCategory:AVAudioSessionCategoryPlayAndRecord
                                      withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                            error:nil];
    
    [[AVAudioSession sharedInstance]  setActive:YES error:nil];
    
    if (IS_OS_6_OR_LATER)
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    
    [[MPMusicPlayerController applicationMusicPlayer] setVolume:0.25];
    [NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(incrementVolume:) userInfo:nil repeats:YES];

    
    NSURL* musicFile = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"siren" ofType:@"mp3"]];
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:musicFile error:nil];
    audioPlayer.delegate = self;
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    [audioPlayer prepareToPlay];
    [audioPlayer setVolume:1.0f];
    [audioPlayer play];
    
    [super notifyCommandResponse:[self getName] withStatus:@"started"];
}

- (void)incrementVolume:(NSTimer *)timer
{
    PreyLogMessage(@"alarm", 10, @"Volume UP!");
    
    float systemVolume = [[MPMusicPlayerController applicationMusicPlayer] volume];
    
    if ( (systemVolume < 1.0 ) && ([audioPlayer isPlaying]) )
    {
        [[MPMusicPlayerController applicationMusicPlayer] setVolume:(systemVolume+0.25)];
    }
    else
    {
        [timer invalidate];
        timer = nil;
    }
}


- (NSString *) getName {
	return @"alarm";
}

-(void)dealloc {
    [audioPlayer release];
    [super dealloc];
}

#pragma --
#pragma AVAudioPlayerDelegate methods

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    [super notifyCommandResponse:[self getName] withStatus:@"stopped"];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [super notifyCommandResponse:[self getName] withStatus:@"stopped"];
}

@end
