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
    
    NSInteger requestNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"requestNumber"] + 2;
    [[NSUserDefaults standardUserDefaults] setInteger:requestNumber forKey:@"requestNumber"];
    
    NSURL* musicFile = [NSURL fileURLWithPath:[[NSBundle mainBundle]
                                               pathForResource:@"siren"
                                               ofType:@"mp3"]];
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:musicFile error:nil];
    audioPlayer.delegate = self;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    //Load the audio into memory
    [audioPlayer prepareToPlay];
    [audioPlayer setVolume:1.0f];
    [audioPlayer play];
    [super notifyCommandResponse:[self getName] withStatus:@"started"];
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
