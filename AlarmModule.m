//
//  AlarmModule.m
//  Prey
//
//  Created by Carlos Yaconi on 19/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "AlarmModule.h"


@implementation AlarmModule

@synthesize soundFileURLRef;
@synthesize soundFileObject;

- (void)main {
	NSURL *tapSound   = [[NSBundle mainBundle] URLForResource: @"siren" withExtension: @"mp3"];
	
    // Store the URL as a CFURLRef instance
    self.soundFileURLRef = (CFURLRef) [tapSound retain];
	
    // Create a system sound object representing the sound file.
    AudioServicesCreateSystemSoundID (soundFileURLRef,&soundFileObject);	
	AudioServicesDisposeSystemSoundID (soundFileObject);
    CFRelease (soundFileURLRef);
	LogMessageCompat(@"Playing the alarm now!");
	AudioServicesPlaySystemSound (soundFileObject);
	
	AudioServicesDisposeSystemSoundID (soundFileObject);
}

- (NSString *) getName {
	return @"alarm";
}

@end
