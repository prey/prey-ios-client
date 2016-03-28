//
//  RestHttpUser.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 18-03-10.
//  Copyright 2010 Fork Ltd.. All rights reserved.
//
//


#import "PreyRestHttpV1.h"
#import "ReportModule.h"
#import "PreyAFNetworking.h"
#import "PreyStatusClientV1.h"
#import "PreyConfig.h"
#import "Constants.h"
#import "JsonConfigParser.h"
#import "PreyAppDelegate.h"

@implementation PreyRestHttpV1

#pragma mark Init

+ (void)checkTransaction:(NSInteger)reload withString:(NSString *)receiptData withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block
{
    NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
    if (receiptData)
        [requestData setObject:receiptData forKey:@"receipt-data"];
    
    [[PreyStatusClientV1 sharedClient] postPath:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingString:@"/subscriptions/receipt"]
                                     parameters:requestData
                                        success:^(PreyAFHTTPRequestOperation *operation, id responseObject)
     {
         PreyLogMessage(@"PreyRestHttp", 21, @"subscriptions/receipt: %@",[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
         
         if (block)
             block(operation.response, nil);
         
     } failure:^(PreyAFHTTPRequestOperation *operation, NSError *error)
     {
         if ( ([operation.response statusCode] == 503) && (reload > 0) )
         {
             // Call method again
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                 [self checkTransaction:reload -1 withString:receiptData withBlock:block];
             });
         }
            // When reload <= 0 then return statusCode:503
         else if ( ([operation.response statusCode] == 503) && (reload <= 0) )
             [self returnStatusCode503:block checkCompletionHandler:NO];
         
            // Return response to block
         else if (block)
             block(operation.response, error);
         
         PreyLogMessage(@"PreyRestHttp", 10,@"Error /subscriptions: %@",error);
     }];
}

+ (void)getCurrentControlPanelApiKey:(NSInteger)reload withUser:(User *)user withBlock:(void (^)(NSString *apiKey, NSError *error))block
{
    NSString *username = ([PreyConfig instance].apiKey) ? [PreyConfig instance].apiKey : user.email;
    [[PreyStatusClientV1 sharedClient] setAuthorizationHeaderWithUsername:username password:[user password]];
    
    [[PreyStatusClientV1 sharedClient] getPath:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/profile.json"]
                                    parameters:nil
                                       success:^(PreyAFHTTPRequestOperation *operation, id responseObject)
     {
         //PreyLogMessage(@"PreyRestHttp", 21, @"GET profile.json: %@",[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
         
         NSError *error2;
         NSString *respString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
         JsonConfigParser *configParser = [[JsonConfigParser alloc] init];
         [configParser parseRequest:respString forUser:user parseError:&error2];
         
         if (block) {
             block(user.apiKey, nil);
             [[PreyStatusClientV1 sharedClient] setAuthorizationHeaderWithUsername:user.apiKey password:@"x"];
         }
         
     } failure:^(PreyAFHTTPRequestOperation *operation, NSError *error)
     {
         if ( ([operation.response statusCode] == 503) && (reload > 0) )
         {
             // Call method again
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                 [self getCurrentControlPanelApiKey:reload -1 withUser:user withBlock:block];
             });
         }
         // When reload <= 0 then return statusCode:503
         else if ( ([operation.response statusCode] == 503) && (reload <= 0) )
             [self returnStatusCode503WithString:block checkCompletionHandler:NO];
         
         // Return response to block
         else if (block)
         {
             NSString  *showMessage = ([error localizedRecoverySuggestion] != nil) ? [error localizedRecoverySuggestion] : [error localizedDescription];
             
             if ( ([operation.response statusCode] == 401) && ([PreyConfig instance].email != nil) )
                 showMessage = NSLocalizedString(@"Please make sure the password you entered is valid.",nil);
                 
             else if ( ([operation.response statusCode] == 401) && ([PreyConfig instance].email == nil) )
                 showMessage = NSLocalizedString(@"There was a problem getting your account information. Please make sure the email address you entered is valid, as well as your password.",nil);
                  
             [self displayErrorAlert:showMessage title:NSLocalizedString(@"Couldn't check your password",nil)];
             
             block(nil, error);
             [[PreyStatusClientV1 sharedClient] setAuthorizationHeaderWithUsername:[[PreyConfig instance] apiKey] password:@"x"];
         }
         
         PreyLogMessage(@"PreyRestHttp", 10,@"Error profile.json: %@",error);
     }];
}

+ (void)createApiKey:(NSInteger)reload withUser:(User *)user withBlock:(void (^)(NSString *apiKey, NSError *error))block
{
    NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
    [requestData setObject:[user name] forKey:@"name"];
    [requestData setObject:[user email] forKey:@"email"];
    [requestData setObject:[user country] forKey:@"country_name"];
    [requestData setObject:[user password] forKey:@"password"];
    [requestData setObject:[user repassword] forKey:@"password_confirmation"];
    [requestData setObject:@"" forKey:@"referer_user_id"];
    
    [[PreyStatusClientV1 sharedClient] postPath:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/signup.json"]
                                     parameters:requestData
                                        success:^(PreyAFHTTPRequestOperation *operation, id responseObject)
     {
         PreyLogMessage(@"PreyRestHttp", 21, @"POST signup.json: %@",[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
         
         NSError *error2;
         NSString *respString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
         JsonConfigParser *configParser = [[JsonConfigParser alloc] init];
         NSString *userKey = [configParser parseKey:respString parseError:&error2];
         
         if (block)
             block(userKey, nil);
         
     } failure:^(PreyAFHTTPRequestOperation *operation, NSError *error)
     {
         if ( ([operation.response statusCode] == 503) && (reload > 0) )
         {
             // Call method again
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                 [self createApiKey:reload -1 withUser:user withBlock:block];
             });
         }
            // When reload <= 0 then return statusCode:503
         else if ( ([operation.response statusCode] == 503) && (reload <= 0) )
             [self returnStatusCode503WithString:block checkCompletionHandler:NO];

            // Return response to block
         else if (block)
         {
             NSString  *showMessage = ([error localizedRecoverySuggestion] != nil) ? [error localizedRecoverySuggestion] : [error localizedDescription];
             
             [self displayErrorAlert:showMessage title:NSLocalizedString(@"User couldn't be created",nil)];

             block(nil, error);
         }
         
         PreyLogMessage(@"PreyRestHttp", 10,@"Error signup.json: %@",error);
     }];
}

+ (void)createDeviceKeyForDevice:(NSInteger)reload withDevice:(Device *)device usingApiKey:(NSString *)apiKey withBlock:(void (^)(NSString *deviceKey, NSError *error))block
{
    NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
    [requestData setObject:[device name] forKey:@"name"];
    [requestData setObject:[device type] forKey:@"device_type"];
    [requestData setObject:[device version] forKey:@"os_version"];
    [requestData setObject:[device model] forKey:@"model_name"];
    [requestData setObject:[device vendor] forKey:@"vendor_name"];
    [requestData setObject:[device os] forKey:@"os"];
    [requestData setObject:[device macAddress] forKey:@"physical_address"];
    [requestData setObject:[device uuid] forKey:@"hardware_attributes[uuid]"];
    [requestData setObject:[device uuid] forKey:@"hardware_attributes[serial_number]"];
    [requestData setObject:[device cpu_model] forKey:@"hardware_attributes[cpu_model]"];
    [requestData setObject:[device cpu_speed] forKey:@"hardware_attributes[cpu_speed]"];
    [requestData setObject:[device cpu_cores] forKey:@"hardware_attributes[cpu_cores]"];
    [requestData setObject:[device ram_size] forKey:@"hardware_attributes[ram_size]"];
    
    [[PreyStatusClientV1 sharedClient] setAuthorizationHeaderWithUsername:apiKey password:@"x"];
    
    [[PreyStatusClientV1 sharedClient] postPath:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices.json"]
                                     parameters:requestData
                                        success:^(PreyAFHTTPRequestOperation *operation, id responseObject)
     {
         PreyLogMessage(@"PreyRestHttp", 21, @"POST devices.json: %@",[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
         
         NSError *error2 = nil;
         JsonConfigParser *configParser     = [[JsonConfigParser alloc] init];
         NSString         *deviceKeyString  = [configParser parseKey:[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]
                                                          parseError:&error2];
         
         if (block)
             block(deviceKeyString, nil);
         
     } failure:^(PreyAFHTTPRequestOperation *operation, NSError *error)
     {
         if ( ([operation.response statusCode] == 503) && (reload > 0) )
         {
             // Call method again
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                 [self createDeviceKeyForDevice:reload - 1 withDevice:device usingApiKey:apiKey withBlock:block];
             });
         }
             // When reload <= 0 then return statusCode:503
         else if ( ([operation.response statusCode] == 503) && (reload <= 0) )
             [self returnStatusCode503WithString:block checkCompletionHandler:NO];
         
             // Return response to block
         else if (block)
         {
             NSInteger  statusCode  = [operation.response statusCode];
             NSString  *showMessage = ([error localizedRecoverySuggestion] != nil) ? [error localizedRecoverySuggestion] : [error localizedDescription];
             
             if ((statusCode == 302) || (statusCode == 403))
             {
                 showMessage = NSLocalizedString(@"It seems you've reached your limit for devices on the Control Panel. Try removing this device from your account if you had already added.",nil);
             }
             
             [self displayErrorAlert:showMessage title:NSLocalizedString(@"Couldn't add your device",nil)];
             
             block(nil, error);
         }
         
         PreyLogMessage(@"PreyRestHttp", 10,@"Error devices.json: %@",error);
     }];
}

+ (void)deleteDevice:(NSInteger)reload withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block
{
    [[PreyStatusClientV1 sharedClient] deletePath:[[PreyConfig instance] deviceCheckPathWithExtension:@""]
                                       parameters:nil
                                          success:^(PreyAFHTTPRequestOperation *operation, id responseObject)
     {
         PreyLogMessage(@"PreyRestHttp", 21, @"DELETE device: %@ : %ld",[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding], (long)[operation.response statusCode]);
         
         if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SendReport"])
             [[ReportModule instance] stop];
         
         if (block)
             block(operation.response, nil);
         
     } failure:^(PreyAFHTTPRequestOperation *operation, NSError *error)
     {
         if ( ([operation.response statusCode] == 503) && (reload > 0) )
         {
             // Call method again
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                 [self deleteDevice:reload - 1 withBlock:block];
             });
         }
             // When reload <= 0 then return statusCode:503
         else if ( ([operation.response statusCode] == 503) && (reload <= 0) )
             [self returnStatusCode503:block checkCompletionHandler:NO];
         
             // Return response to block
         else if (block)
         {
             [self displayErrorAlert:NSLocalizedString(@"Device not ready!",nil) title:NSLocalizedString(@"Access Denied",nil)];
             block(operation.response, error);
         }
         
         PreyLogMessage(@"PreyRestHttp", 10,@"Error DELETE: %@",error);
     }];
}

+ (void)setPushRegistrationId:(NSInteger)reload  withToken:(NSString *)tokenId withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block
{
    NSDictionary    *params     = [NSDictionary dictionaryWithObjectsAndKeys: tokenId, @"notification_id", nil];
    NSString        *deviceKey  = [[PreyConfig instance] deviceKey];
    
    [[PreyStatusClientV1 sharedClient] postPath:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices/%@/data",deviceKey]
                                     parameters:params
                                        success:^(PreyAFHTTPRequestOperation *operation, id responseObject)
     {
         PreyLogMessage(@"PreyRestHttp", 21, @"POST notificationID: %@",[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
         
         if (block)
             block(operation.response, nil);
         
     } failure:^(PreyAFHTTPRequestOperation *operation, NSError *error)
     {
         if ( ([operation.response statusCode] == 503) && (reload > 0) )
         {
             // Call method again
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                 [self setPushRegistrationId:reload - 1 withToken:tokenId withBlock:block];
             });
         }
             // When reload <= 0 then return statusCode:503
         else if ( ([operation.response statusCode] == 503) && (reload <= 0) )
             [self returnStatusCode503:block checkCompletionHandler:NO];
         
             // Return response to block
         else if (block)
             block(operation.response, error);
         
         PreyLogMessage(@"PreyRestHttp", 10,@"Error notificationID: %@",error);
     }];
}

+ (void)checkCommandJsonForDevice:(id)cmdString
{
    NSString *deviceKey = [[PreyConfig instance] deviceKey];
    PreyLogMessage(@"PreyRestHttp", 21, @"GET CMD devices/%@.json: %@",deviceKey, cmdString);
    
    NewModulesConfig *modulesConfig = [[NewModulesConfig alloc] init];
    
    for (NSDictionary *dict in cmdString)
    {
        [modulesConfig addModule:dict];
    }
    
    if ([modulesConfig checkAllModulesEmpty])
    {
        PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate checkedCompletionHandler];
    }
    else
        [modulesConfig runAllModules];

    
    [[PreyStatusClientV1 sharedClient] getPath:[NSString stringWithFormat:@"/api/v2/devices/%@.json", deviceKey]
                                    parameters:nil
                                       success:^(PreyAFHTTPRequestOperation *operation, id responseObject)
     {
         PreyLogMessage(@"PreyRestHttp", 21, @"GET devices/%@.json: %@",deviceKey,[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
         
     } failure:^(PreyAFHTTPRequestOperation *operation, NSError *error) {
         PreyLogMessage(@"PreyRestHttp", 10,@"Error: %@",error);
     }];
}

+ (void)checkStatusForDevice:(NSInteger)reload withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block
{
    NSString *deviceKey = [[PreyConfig instance] deviceKey];
    
    [[PreyStatusClientV1 sharedClient] getPath:[NSString stringWithFormat:@"/api/v2/devices/%@.json", deviceKey]
                                    parameters:nil
                                       success:^(PreyAFHTTPRequestOperation *operation, id responseObject)
     {
         PreyLogMessage(@"PreyRestHttp", 21, @"GET devices/%@.json: %@",deviceKey,[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
         
         NSString *respString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
         JsonConfigParser *configParser = [[JsonConfigParser alloc] init];
         
         NSError *error2;
         NewModulesConfig *modulesConfig = [configParser parseModulesConfig:respString parseError:&error2];
         
         if ([modulesConfig checkAllModulesEmpty])
         {
             PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
             [appDelegate checkedCompletionHandler];
         }
         else
             [modulesConfig runAllModules];
         
         if (block)
             block(operation.response,nil);
         
     } failure:^(PreyAFHTTPRequestOperation *operation, NSError *error)
     {
         if ( ([operation.response statusCode] == 503) && (reload > 0) )
         {
             // Call method again
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                 [self checkStatusForDevice:reload - 1 withBlock:block];
             });
         }
             // When reload <= 0 then return statusCode:503
         else if ( ([operation.response statusCode] == 503) && (reload <= 0) )
             [self returnStatusCode503:block checkCompletionHandler:NO];
         
             // Return response to block
         else if (block)
             block(operation.response, error);
         
         PreyLogMessage(@"PreyRestHttp", 10,@"Error: %@",error);
     }];
}

+ (void)sendJsonData:(NSInteger)reload withData:(NSDictionary*)jsonData toEndpoint:(NSString *)url withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block
{
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    [[PreyStatusClientV1 sharedClient] postPath:url
                                     parameters:jsonData
                                        success:^(PreyAFHTTPRequestOperation *operation, id responseObject)
     {
         PreyLogMessage(@"PreyRestHttp", 21, @"POST %@: %@",url,[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
         if (block)
             block(operation.response, nil);
         
         [appDelegate checkedCompletionHandler];
         
     } failure:^(PreyAFHTTPRequestOperation *operation, NSError *error)
     {
         if ( ([operation.response statusCode] == 503) && (reload > 0) )
         {
             // Call method again
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                 [self sendJsonData:reload - 1 withData:jsonData andRawData:nil toEndpoint:url withBlock:block];
             });
         }
             // When reload <= 0 then return statusCode:503
         else if ( ([operation.response statusCode] == 503) && (reload <= 0) )
             [self returnStatusCode503:block checkCompletionHandler:YES];
         
             // Return response to block
         else if (block)
         {
             if ([operation.response statusCode] == 409)
             {
                 [[ReportModule instance] stop];
                 [appDelegate checkedCompletionHandler];
             }
             
             block(operation.response, error);
             [appDelegate checkedCompletionHandler];
         }
         
         PreyLogMessage(@"PreyRestHttp", 10,@"Error: %@",error);
     }];
}

+ (void)sendJsonData:(NSInteger)reload withData:(NSDictionary*)jsonData andRawData:(NSDictionary*)rawData toEndpoint:(NSString *)url withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block
{
    NSMutableURLRequest *request;
    request = [[PreyStatusClientV1 sharedClient] multipartFormRequestWithMethod:@"POST" path:url parameters:jsonData
                                                      constructingBodyWithBlock: ^(id <PreyAFMultipartFormData>formData)
               {
                   if ([rawData objectForKey:@"picture"]!=nil)
                       [formData appendPartWithFileData:[rawData objectForKey:@"picture"] name:@"picture" fileName:@"picture.jpg" mimeType:@"image/png"];
                   
                   if ([rawData objectForKey:@"screenshot"]!=nil)
                       [formData appendPartWithFileData:[rawData objectForKey:@"screenshot"] name:@"screenshot" fileName:@"screenshot.jpg" mimeType:@"image/png"];
               }];
    
    PreyAFHTTPRequestOperation *operation = [[PreyAFHTTPRequestOperation alloc] initWithRequest:request];
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    
    [operation setCompletionBlockWithSuccess:^(PreyAFHTTPRequestOperation *operation, id responseObject)
     {
         PreyLogMessage(@"PreyRestHttp", 21, @"POST %@: %@",url,[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
         
         if (block)
             block(operation.response, nil);
         
         [appDelegate checkedCompletionHandler];
         
     } failure:^(PreyAFHTTPRequestOperation *operation, NSError *error)
     {
         if ( ([operation.response statusCode] == 503) && (reload > 0) )
         {
             // Call method again
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                 [self sendJsonData:reload - 1 withData:jsonData andRawData:rawData toEndpoint:url withBlock:block];
             });
         }
             // When reload <= 0 then return statusCode:503
         else if ( ([operation.response statusCode] == 503) && (reload <= 0) )
             [self returnStatusCode503:block checkCompletionHandler:YES];
         
             // Return response to block
         else if (block)
         {
             if ([operation.response statusCode] == 409)
             {
                 [[ReportModule instance] stop];
                 [appDelegate checkedCompletionHandler];
             }
             
             block(operation.response, error);
             [appDelegate checkedCompletionHandler];
         }
         
         PreyLogMessage(@"PreyRestHttp", 10,@"Error: %@",error);
     }];
    [[PreyStatusClientV1 sharedClient] enqueueHTTPRequestOperation:operation];
}

+ (void)checkStatusInBackground:(NSInteger)reload withURL:(NSString*)endpoint withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block
{
    NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
    [requestData setObject:[[PreyConfig instance] deviceKey] forKey:@"device_key"];
    
    [[PreyStatusClientV1 sharedClient] postPath:endpoint
                                     parameters:requestData
                                        success:^(PreyAFHTTPRequestOperation *operation, id responseObject)
     {
         PreyLogMessage(@"PreyRestHttp", 21, @"POST: %@",[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
         
         if (block)
             block(operation.response, nil);
         
     } failure:^(PreyAFHTTPRequestOperation *operation, NSError *error)
     {
         if ( ([operation.response statusCode] == 503) && (reload > 0) )
         {
             // Call method again
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                 [self checkStatusInBackground:reload - 1  withURL:endpoint withBlock:block];
             });
         }
             // When reload <= 0 then return statusCode:503
         else if ( ([operation.response statusCode] == 503) && (reload <= 0) )
             [self returnStatusCode503:block checkCompletionHandler:NO];
         
             // Return response to block
         else if (block)
             block(operation.response, error);
         
         PreyLogMessage(@"PreyRestHttp", 10,@"Error: %@",error);
     }];
}

@end
