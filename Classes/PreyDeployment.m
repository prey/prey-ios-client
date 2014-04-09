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
#import "Constants.h"

@implementation PreyDeployment

+ (void)runPreyDeployment;
{
    NSMutableArray *preyFiles = [NSMutableArray array];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *publicDocumentsDir = [paths objectAtIndex:0];
    
    NSError *error;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:publicDocumentsDir error:&error];
    if (files == nil) {
        NSLog(@"Error reading contents of documents directory: %@", [error localizedDescription]);
        return;
    }
    
    for (NSString *file in files) {
        if ([file.pathExtension compare:@"prey" options:NSCaseInsensitiveSearch] == NSOrderedSame)
        {
            NSString *fullPath = [publicDocumentsDir stringByAppendingPathComponent:file];
            [preyFiles addObject:fullPath];
        }
    }

    if ([preyFiles count] == 0)
        return;

    NSData *fileData = [NSData dataWithContentsOfFile:[preyFiles objectAtIndex:0]];
    if (fileData == nil)
        return;
    
    NSString *apiKeyUser = [[[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding] autorelease];
    if (apiKeyUser == nil)
        return;
    
    
    [PreyDeployment addDeviceForApiKey:apiKeyUser];
}

+ (void)addDeviceForApiKey:(NSString *)apiKeyUser
{
    User *newUser = [[[User alloc] init] autorelease];
    [newUser setApiKey:apiKeyUser];
    
    [Device newDeviceForApiKey:newUser
                     withBlock:^(User *user, Device *dev, NSError *error)
     {
         if (!error) // Device created
         {
             PreyLogMessage(@"PreyDeployment", 10,@"OK" );
             PreyConfig *config = [PreyConfig initWithApiKey:apiKeyUser andDevice:dev];
             if (config != nil)
             {
                 [(PreyAppDelegate*)[UIApplication sharedApplication].delegate registerForRemoteNotifications];
                 NSString *txtCongrats = NSLocalizedString(@"Congratulations! You have successfully associated this iOS device with your Prey account.",nil);
                 [self performSelectorOnMainThread:@selector(showCongratsView:) withObject:txtCongrats waitUntilDone:NO];
             }
         }
     }]; // End Block Device
}

- (void)showCongratsView:(NSString*)congratsText
{
    CongratulationsController *congratsController;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        if (IS_IPHONE5)
            congratsController = [[CongratulationsController alloc] initWithNibName:@"CongratulationsController-iPhone-568h" bundle:nil];
        else
            congratsController = [[CongratulationsController alloc] initWithNibName:@"CongratulationsController-iPhone" bundle:nil];
    }
    else
        congratsController = [[CongratulationsController alloc] initWithNibName:@"CongratulationsController-iPad" bundle:nil];
    
    congratsController.txtToShow = (NSString*) congratsText;
    
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate.viewController setNavigationBarHidden:YES animated:YES];
    [appDelegate.viewController pushViewController:congratsController animated:YES];
    [congratsController release];
}

@end
