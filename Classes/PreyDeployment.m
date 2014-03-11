//
//  PreyDeployment.m
//  Prey
//
//  Created by Javier Cala Uribe on 21/11/13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import "PreyDeployment.h"
#import "Device.h"
#import "PreyConfig.h"
#import "PreyAppDelegate.h"
#import "PreyRestHttp.h"

@implementation PreyDeployment

- (BOOL)isCorrect
{
    NSMutableArray *preyFiles = [NSMutableArray array];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *publicDocumentsDir = [paths objectAtIndex:0];
    
    NSError *error;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:publicDocumentsDir error:&error];
    if (files == nil) {
        NSLog(@"Error reading contents of documents directory: %@", [error localizedDescription]);
        return NO;
    }
    
    for (NSString *file in files) {
        if ([file.pathExtension compare:@"prey" options:NSCaseInsensitiveSearch] == NSOrderedSame)
        {
            NSString *fullPath = [publicDocumentsDir stringByAppendingPathComponent:file];
            [preyFiles addObject:fullPath];
        }
    }

    if ([preyFiles count] == 0)
        return NO;

    NSData *fileData = [NSData dataWithContentsOfFile:[preyFiles objectAtIndex:0]];
    if (fileData == nil)
        return NO;
    
    NSString *apiKeyUser = [[[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding] autorelease];
    if (apiKeyUser == nil)
        return NO;

    
    return [self addDeviceForApiKey:apiKeyUser];
}

- (BOOL) addDeviceForApiKey:(NSString *)apiKeyUser
{
	Device *device = nil;
	PreyConfig *config = nil;
	@try {
		device = [Device newDeviceForApiKey:apiKeyUser];
		config = [[PreyConfig initWithApiKey:apiKeyUser andDevice:device] retain];
		if (config != nil){
            [(PreyAppDelegate*)[UIApplication sharedApplication].delegate registerForRemoteNotifications];
            return YES;
        }
	}
	@catch (NSException * e) {
		if (device != nil)
			[self deleteDevice:device];
        
		UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Couldn't add your device",nil) message:[e reason] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		
		[alertView show];
		[alertView release];
        return NO;
        
	} @finally {
        [config release];
		[device release];
	}
}

-(BOOL) deleteDevice: (Device*) dev {
	@try {
		PreyRestHttp *userHttp = [[[PreyRestHttp alloc] init] autorelease];
		return [userHttp deleteDevice:dev];
	}
	@catch (NSException * e) {
		@throw;
	}
	return NO;
}

- (CongratulationsController*)returnViewController
{
    CongratulationsController* congratulationsController;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        if (IS_IPHONE5)
            congratulationsController = [[CongratulationsController alloc] initWithNibName:@"CongratulationsController-iPhone-568h" bundle:nil];
        else
            congratulationsController = [[CongratulationsController alloc] initWithNibName:@"CongratulationsController-iPhone" bundle:nil];
    }
    else
        congratulationsController = [[CongratulationsController alloc] initWithNibName:@"CongratulationsController-iPad" bundle:nil];
    
    congratulationsController.txtToShow = NSLocalizedString(@"Congratulations! You have successfully associated this iOS device with your Prey account.",nil);

    return congratulationsController;
}

@end
