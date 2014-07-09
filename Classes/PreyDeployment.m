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

// The Managed app configuration dictionary pushed down from an MDM server are stored in this key.
static NSString * const kConfigurationKey = @"com.apple.configuration.managed";

// The dictionary that is sent back to the MDM server as feedback must be stored in this key.
static NSString * const kFeedbackKey = @"com.apple.feedback.managed";

static NSString * const kConfigurationApiKey = @"apiKeyPrey";
static NSString * const kFeedbackSuccessKey = @"success";


+ (void)runPreyDeployment;
{
    if (![PreyDeployment readDefaultsValues])
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
        
        NSString *apiKeyUser = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
        if (apiKeyUser == nil)
            return;
        
        
        [PreyDeployment addDeviceForApiKey:apiKeyUser];
    }
}

+ (BOOL)readDefaultsValues
{
    BOOL successValue;
    
    NSDictionary *serverConfig = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kConfigurationKey];
    NSString *serverApiKey = serverConfig[kConfigurationApiKey];
    
    // Data coming from MDM server should be validated before use.
    // If validation fails, be sure to set a sensible default value as a fallback, even if it is nil.
    if (serverApiKey && [serverApiKey isKindOfClass:[NSString class]])
    {
        [PreyDeployment addDeviceForApiKey:serverApiKey];
        successValue = YES;
    }
    else
        successValue = NO;
    
    [PreyDeployment successManagedAppConfig:successValue];
    
    
    PreyLogMessage(@"PreyDeployment", 10, @"Deployment: %@", (successValue ? @"YES" : @"NO"));
    
    return successValue;
}

+ (void)successManagedAppConfig:(BOOL)isSuccess
{
    NSMutableDictionary *feedback = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kFeedbackKey] mutableCopy];
    if (!feedback) {
        feedback = [NSMutableDictionary dictionary];
    }
    feedback[kFeedbackSuccessKey] = @(isSuccess);
    [[NSUserDefaults standardUserDefaults] setObject:feedback forKey:kFeedbackKey];
}

+ (void)addDeviceForApiKey:(NSString *)apiKeyUser
{
    User *newUser = [[User alloc] init];
    [newUser setApiKey:apiKeyUser];
    
    [Device newDeviceForApiKey:newUser
                     withBlock:^(User *user, Device *dev, NSError *error)
     {
         if (!error) // Device created
         {
             PreyConfig *config = [PreyConfig initWithApiKey:apiKeyUser andDevice:dev];
             if (config != nil)
             {
                 [(PreyAppDelegate*)[UIApplication sharedApplication].delegate registerForRemoteNotifications];
                 NSString *txtCongrats = NSLocalizedString(@"Congratulations! You have successfully associated this iOS device with your Prey account.",nil);
                 [PreyDeployment performSelectorOnMainThread:@selector(showCongratsView:) withObject:txtCongrats waitUntilDone:NO];
             }
         }
     }]; // End Block Device
}

+ (void)showCongratsView:(NSString*)congratsText
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
    [appDelegate.viewController setNavigationBarHidden:YES animated:NO];
    [appDelegate.viewController setViewControllers:[NSArray arrayWithObjects:congratsController, nil] animated:NO];
}

@end
