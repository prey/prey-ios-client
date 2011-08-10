//
//  AlarmModule.m
//  Prey
//
//  Created by Carlos Yaconi on 19/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>


#import "AlarmModule.h"


@implementation AlarmModule
@synthesize backgroundMusicPlayer;

- (void)main {
    PreyLogMessage(@"alarm", 10, @"Playing the alarm now!");
    
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
}

- (NSString *) getName {
	return @"alarm";
}

-(void)dealloc {
    [backgroundMusicPlayer release];
    [super dealloc];
}
@end
