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


+ (PreyDeployment *)instance {
    static PreyDeployment *instance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        instance = [[PreyDeployment alloc] init];
    });
    
    return instance;
}


- (void)runPreyDeployment;
{
    if (![[PreyDeployment instance] readDefaultsValues])
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
        
        
        [[PreyDeployment instance] addDeviceForApiKey:apiKeyUser fromQRCode:NO];
    }
}

- (BOOL)readDefaultsValues
{
    BOOL successValue;
    
    NSDictionary *serverConfig = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kConfigurationKey];
    NSString *serverApiKey = serverConfig[kConfigurationApiKey];
    
    // Data coming from MDM server should be validated before use.
    // If validation fails, be sure to set a sensible default value as a fallback, even if it is nil.
    if (serverApiKey && [serverApiKey isKindOfClass:[NSString class]])
    {
        [[PreyDeployment instance] addDeviceForApiKey:serverApiKey fromQRCode:NO];
        successValue = YES;
    }
    else
        successValue = NO;
    
    [[PreyDeployment instance] successManagedAppConfig:successValue];
    
    
    PreyLogMessage(@"PreyDeployment", 10, @"Deployment: %@", (successValue ? @"YES" : @"NO"));
    
    return successValue;
}

- (void)successManagedAppConfig:(BOOL)isSuccess
{
    NSMutableDictionary *feedback = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kFeedbackKey] mutableCopy];
    if (!feedback) {
        feedback = [NSMutableDictionary dictionary];
    }
    feedback[kFeedbackSuccessKey] = @(isSuccess);
    [[NSUserDefaults standardUserDefaults] setObject:feedback forKey:kFeedbackKey];
}

- (void)addDeviceForApiKey:(NSString *)apiKeyUser fromQRCode:(BOOL)isFromQRCode
{
    User *newUser = [[User alloc] init];
    [newUser setApiKey:apiKeyUser];
    
    if (isFromQRCode) {
        PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
        HUD = [MBProgressHUD showHUDAddedTo:appDelegate.viewController.view animated:YES];
        HUD.label.text = NSLocalizedString(@"Attaching device...",nil);
    }
    
    [Device newDeviceForApiKey:newUser
                     withBlock:^(User *user, Device *dev, NSError *error)
     {
         if (isFromQRCode) {
             PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
             [MBProgressHUD hideHUDForView:appDelegate.viewController.view animated:NO];
         }
         
         if (!error) // Device created
         {
             PreyConfig *config = [PreyConfig initWithApiKey:apiKeyUser andDevice:dev fromQRCode:isFromQRCode];
             if (config != nil)
             {
                 [(PreyAppDelegate*)[UIApplication sharedApplication].delegate registerForRemoteNotifications];
                 NSString *txtCongrats = NSLocalizedString(@"Congratulations! You have successfully associated this iOS device with your Prey account.",nil);
                 [[PreyDeployment instance] performSelectorOnMainThread:@selector(showCongratsView:) withObject:txtCongrats waitUntilDone:NO];
             }
         }
     }]; // End Block Device
}

- (void)showCongratsView:(NSString*)congratsText
{
    CongratulationsController *congratsController;
    
    if (IS_IPAD)
        congratsController = [[CongratulationsController alloc] initWithNibName:@"CongratulationsController-iPad" bundle:nil];
    else
        congratsController = (IS_IPHONE5) ? [[CongratulationsController alloc] initWithNibName:@"CongratulationsController-iPhone-568h" bundle:nil] : [[CongratulationsController alloc] initWithNibName:@"CongratulationsController-iPhone" bundle:nil];
    
    congratsController.txtToShow = (NSString*) congratsText;
    
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate.viewController setNavigationBarHidden:YES animated:NO];
    [appDelegate.viewController setViewControllers:[NSArray arrayWithObjects:congratsController, nil] animated:NO];
}

@end
