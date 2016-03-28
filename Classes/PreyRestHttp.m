//
//  RestHttpUser.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 18-03-10.
//  Copyright 2010 Fork Ltd.. All rights reserved.
//
//


#import "PreyRestHttp.h"
#import "ReportModule.h"
#import "PreyAFNetworking.h"
#import "PreyConfig.h"
#import "Constants.h"
#import "JsonConfigParser.h"
#import "PreyAppDelegate.h"
#import "PreyRestHttpV1.h"
#import "PreyRestHttpV2.h"

@implementation PreyRestHttp

#pragma mark Init

+ (Class)getClassVersion
{
    return (IS_OS_7_OR_LATER) ? [PreyRestHttpV2 class] : [PreyRestHttpV1 class];
}

+ (void)checkTransaction:(NSInteger)reload withString:(NSString *)receiptData withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block
{
}

+ (void)getCurrentControlPanelApiKey:(NSInteger)reload withUser:(User *)user withBlock:(void (^)(NSString *apiKey, NSError *error))block
{
}

+ (void)createApiKey:(NSInteger)reload withUser:(User *)user withBlock:(void (^)(NSString *apiKey, NSError *error))block
{

}

+ (void)createDeviceKeyForDevice:(NSInteger)reload withDevice:(Device *)device usingApiKey:(NSString *)apiKey withBlock:(void (^)(NSString *deviceKey, NSError *error))block
{
 
}

+ (void)deleteDevice:(NSInteger)reload withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block
{
 
}

+ (void)setPushRegistrationId:(NSInteger)reload  withToken:(NSString *)tokenId withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block
{
 
}

+ (void)checkCommandJsonForDevice:(id)cmdString
{

}

+ (void)checkStatusForDevice:(NSInteger)reload withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block
{

}

+ (void)sendJsonData:(NSInteger)reload withData:(NSDictionary*)jsonData toEndpoint:(NSString *)url withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block
{
 }

+ (void)sendJsonData:(NSInteger)reload withData:(NSDictionary*)jsonData andRawData:(NSDictionary*)rawData toEndpoint:(NSString *)url withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block
{
}

+ (void)checkStatusInBackground:(NSInteger)reload withURL:(NSString*)endpoint withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block
{
  
}

#pragma mark --

+ (void)returnStatusCode503:(void (^)(NSHTTPURLResponse *response, NSError *error))block checkCompletionHandler:(BOOL)callHandler
{
    if (block)
    {
        NSError *error = [NSError errorWithDomain:@"StatusCode503Reload" code:700 userInfo:nil];
        block(nil, error);

        if (callHandler) {
            PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
            [appDelegate checkedCompletionHandler];
        }
    }
}

+ (void)returnStatusCode503WithString:(void (^)(NSString *response, NSError *error))block checkCompletionHandler:(BOOL)callHandler
{
    if (block)
    {
        NSError *error = [NSError errorWithDomain:@"StatusCode503Reload" code:700 userInfo:nil];
        block(nil, error);
        
        if (callHandler) {
            PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
            [appDelegate checkedCompletionHandler];
        }
    }
}

+ (void)displayErrorAlert:(NSString *)alertMessage title:(NSString*)titleMessage
{
    UIAlertView * anAlert = [[UIAlertView alloc] initWithTitle:titleMessage
                                                       message:alertMessage
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                             otherButtonTitles:nil];
    [anAlert show];
}

@end
