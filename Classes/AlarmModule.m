//
//  AlarmModule.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 19/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import <AVFoundation/AVFoundation.h>


#import "AlarmModule.h"


@implementation AlarmModule
@synthesize audioPlayer;

- (void)main {
    PreyLogMessage(@"alarm", 10, @"Playing the alarm now!");
    
    
    
    NSURL* musicFile = [NSURL fileURLWithPath:[[NSBundle mainBundle]
                                               pathForResource:@"siren"
                                               ofType:@"mp3"]];
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:musicFile error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    //Load the audio into memory
    [audioPlayer prepareToPlay];
    [audioPlayer setVolume:1.0f];
    [audioPlayer play];
    
    
    /*
    NSError *setCategoryError = nil;
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
	//Allowing mixing audios
    OSStatus propertySetError = 0;
    UInt32 allowMixing = true;
    
    propertySetError = AudioSessionSetProperty (
                                                kAudioSessionProperty_OverrideCategoryMixWithOthers,  
                                                sizeof (allowMixing),                                 
                                                &allowMixing                                          
                                                );

	// Create audio player with background music
	NSString *backgroundMusicPath = [[NSBundle mainBundle] pathForResource:@"siren" ofType:@"mp3"];
	NSURL *backgroundMusicURL = [NSURL fileURLWithPath:backgroundMusicPath];
	NSError *error;
	backgroundMusicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:backgroundMusicURL error:&error];
    [backgroundMusicPlayer prepareToPlay];
    [backgroundMusicPlayer play];
     */
     
    
}

- (NSString *) getName {
	return @"alarm";
}

-(void)dealloc {
    [audioPlayer release];
    [super dealloc];
}
@end
