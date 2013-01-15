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


@implementation AlarmModule

- (void) start {
    PreyLogMessage(@"alarm", 10, @"Playing the alarm now!");
    
    NSURL* musicFile = [NSURL fileURLWithPath:[[NSBundle mainBundle]
                                               pathForResource:@"siren"
                                               ofType:@"mp3"]];
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:musicFile error:nil];
    audioPlayer.delegate = self;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    //Load the audio into memory
    [audioPlayer prepareToPlay];
    [audioPlayer setVolume:1.0f];
    [audioPlayer play];
    [super notifyEvent:@"action_started" withInfo:[self getName]];
    
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
    [super notifyEvent:@"action_stopped" withInfo:[self getName]];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [super notifyEvent:@"action_stopped" withInfo:[self getName]];
}

@end
