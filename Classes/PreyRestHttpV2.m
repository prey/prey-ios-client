//
//  RestHttpUser.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 18-03-10.
//  Copyright 2010 Fork Ltd.. All rights reserved.
//
//


#import "PreyRestHttpV2.h"
#import "ReportModule.h"
#import "AFNetworking.h"
#import "PreyStatusClientV2.h"
#import "PreyConfig.h"
#import "Constants.h"
#import "JsonConfigParser.h"
#import "PreyAppDelegate.h"
#import "PreyCoreData.h"

@implementation PreyRestHttpV2

#pragma mark Init

+ (void)checkGeofenceZones:(NSInteger)reload withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block
{
    NSString  *deviceKey  = [[PreyConfig instance] deviceKey];

    [[PreyStatusClientV2 sharedClient] GET:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat:@"/devices/%@/geofencing.json",deviceKey]
                                parameters:nil
                                   success:^(NSURLSessionDataTask *operation, id responseObject)
     {
         PreyLogMessage(@"PreyRestHttp", 21, @"GET geofencing.json: %@",responseObject);
         
         if (responseObject != nil) {
             [[PreyCoreData instance] updateGeofenceZones:responseObject];
         }
         
         if (block) {
             block(nil, nil);
         }
         
     } failure:^(NSURLSessionDataTask *operation, NSError *error)
     {
         NSHTTPURLResponse* resp = (NSHTTPURLResponse*)operation.response;
         if ( ([resp statusCode] == 503) && (reload > 0) )
         {
             // Call method again
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                 [self checkGeofenceZones:reload-1 withBlock:block];
             });
         }
         // When reload <= 0 then return statusCode:503
         else if ( ([resp statusCode] == 503) && (reload <= 0) )
             [self returnStatusCode503:block checkCompletionHandler:NO];
         
         // Return response to block
         else if (block)
         {
             block(nil, error);
         }
         
         PreyLogMessage(@"PreyRestHttp", 10,@"Error profile.json: %@",error);
     }];
}


+ (void)checkTransaction:(NSInteger)reload withString:(NSString *)receiptData withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block
{
    NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
    if (receiptData)
        [requestData setObject:receiptData forKey:@"receipt-data"];
    
    [[PreyStatusClientV2 sharedClient] POST:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingString:@"/subscriptions/receipt"]
                                 parameters:requestData
                                    success:^(NSURLSessionDataTask *operation, id responseObject)
    {
        PreyLogMessage(@"PreyRestHttp", 21, @"subscriptions/receipt: %@",responseObject);

        NSHTTPURLResponse* resp = (NSHTTPURLResponse*)operation.response;
         if (block)
             block(resp, nil);
         
     }failure:^(NSURLSessionDataTask *operation, NSError *error)
     {
         NSHTTPURLResponse* resp = (NSHTTPURLResponse*)operation.response;
         if ( ([resp statusCode] == 503) && (reload > 0) )
         {
             // Call method again
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                 [self checkTransaction:reload -1 withString:receiptData withBlock:block];
             });
         }
         // When reload <= 0 then return statusCode:503
         else if ( ([resp statusCode] == 503) && (reload <= 0) )
             [self returnStatusCode503:block checkCompletionHandler:NO];
         
         // Return response to block
         else if (block)
             block(resp, error);
         
         PreyLogMessage(@"PreyRestHttp", 10,@"Error /subscriptions: %@",error);
     }];
}

+ (void)getCurrentControlPanelApiKey:(NSInteger)reload withUser:(User *)user withBlock:(void (^)(NSString *apiKey, NSError *error))block
{
    [[PreyStatusClientV2 sharedClient].requestSerializer setAuthorizationHeaderFieldWithUsername:[user email] password:[user password]];
    
    [[PreyStatusClientV2 sharedClient] GET:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/profile.json"]
                                    parameters:nil
                                       success:^(NSURLSessionDataTask *operation, id responseObject)
     {
         //PreyLogMessage(@"PreyRestHttp", 21, @"GET profile.json: %@",responseObject);
         
         if (responseObject != nil)
         {
             user.apiKey = [responseObject objectForKey:@"key"];
             user.pro    = [[responseObject objectForKey:@"pro_account"] boolValue];
         }
         
         if (block) {
             block(user.apiKey, nil);
             [[PreyStatusClientV2 sharedClient].requestSerializer setAuthorizationHeaderFieldWithUsername:user.apiKey password:@"x"];
         }
         
     } failure:^(NSURLSessionDataTask *operation, NSError *error)
     {
         NSHTTPURLResponse* resp = (NSHTTPURLResponse*)operation.response;
         if ( ([resp statusCode] == 503) && (reload > 0) )
         {
             // Call method again
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                 [self getCurrentControlPanelApiKey:reload -1 withUser:user withBlock:block];
             });
         }
         // When reload <= 0 then return statusCode:503
         else if ( ([resp statusCode] == 503) && (reload <= 0) )
             [self returnStatusCode503WithString:block checkCompletionHandler:NO];
         
         // Return response to block
         else if (block)
         {
             NSString  *showMessage = ([error localizedRecoverySuggestion] != nil) ? [error localizedRecoverySuggestion] : [error localizedDescription];
             
             if ( ([resp statusCode] == 401) && ([PreyConfig instance].email != nil) )
                 showMessage = NSLocalizedString(@"Please make sure the password you entered is valid.",nil);
                 
             else if ( ([resp statusCode] == 401) && ([PreyConfig instance].email == nil) )
                 showMessage = NSLocalizedString(@"There was a problem getting your account information. Please make sure the email address you entered is valid, as well as your password.",nil);
                  
             [self displayErrorAlert:showMessage title:NSLocalizedString(@"Couldn't check your password",nil)];
             
             block(nil, error);
             [[PreyStatusClientV2 sharedClient].requestSerializer setAuthorizationHeaderFieldWithUsername:[[PreyConfig instance] apiKey]
                                                                                                 password:@"x"];
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
    
    [[PreyStatusClientV2 sharedClient] POST:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/signup.json"]
                                     parameters:requestData
                                        success:^(NSURLSessionDataTask *operation, id responseObject)
     {
         PreyLogMessage(@"PreyRestHttp", 21, @"POST signup.json: %@",responseObject);
         
         NSString *userKey = [responseObject objectForKey:@"key"];
         
         if (block)
             block(userKey, nil);
         
     } failure:^(NSURLSessionDataTask *operation, NSError *error)
     {
         NSHTTPURLResponse* resp = (NSHTTPURLResponse*)operation.response;
         if ( ([resp statusCode] == 503) && (reload > 0) )
         {
             // Call method again
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                 [self createApiKey:reload -1 withUser:user withBlock:block];
             });
         }
            // When reload <= 0 then return statusCode:503
         else if ( ([resp statusCode] == 503) && (reload <= 0) )
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
    
    [[PreyStatusClientV2 sharedClient].requestSerializer setAuthorizationHeaderFieldWithUsername:apiKey password:@"x"];
    
    [[PreyStatusClientV2 sharedClient] POST:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices.json"]
                                     parameters:requestData
                                        success:^(NSURLSessionDataTask *operation, id responseObject)
     {
         PreyLogMessage(@"PreyRestHttp", 21, @"POST devices.json: %@",responseObject);
         
         NSString *deviceKeyString  = [responseObject objectForKey:@"key"];;
         
         if (block)
             block(deviceKeyString, nil);
         
     } failure:^(NSURLSessionDataTask *operation, NSError *error)
     {
         NSHTTPURLResponse* resp = (NSHTTPURLResponse*)operation.response;
         if ( ([resp statusCode] == 503) && (reload > 0) )
         {
             // Call method again
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                 [self createDeviceKeyForDevice:reload - 1 withDevice:device usingApiKey:apiKey withBlock:block];
             });
         }
             // When reload <= 0 then return statusCode:503
         else if ( ([resp statusCode] == 503) && (reload <= 0) )
             [self returnStatusCode503WithString:block checkCompletionHandler:NO];
         
             // Return response to block
         else if (block)
         {
             NSInteger  statusCode  = [resp statusCode];
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
    [[PreyStatusClientV2 sharedClient] DELETE:[[PreyConfig instance] deviceCheckPathWithExtension:@""]
                                       parameters:nil
                                          success:^(NSURLSessionDataTask *operation, id responseObject)
     {
         NSHTTPURLResponse* resp = (NSHTTPURLResponse*)operation.response;
         PreyLogMessage(@"PreyRestHttp", 21, @"DELETE device: %@ : %ld",responseObject, (long)[resp statusCode]);
         
         if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SendReport"])
             [[ReportModule instance] stopSendReport];
         
         if (block)
             block(resp, nil);
         
     } failure:^(NSURLSessionDataTask *operation, NSError *error)
     {
         NSHTTPURLResponse* resp = (NSHTTPURLResponse*)operation.response;
         if ( ([resp statusCode] == 503) && (reload > 0) )
         {
             // Call method again
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                 [self deleteDevice:reload - 1 withBlock:block];
             });
         }
             // When reload <= 0 then return statusCode:503
         else if ( ([resp statusCode] == 503) && (reload <= 0) )
             [self returnStatusCode503:block checkCompletionHandler:NO];
         
             // Return response to block
         else if (block)
         {
             [self displayErrorAlert:NSLocalizedString(@"Device not ready!",nil) title:NSLocalizedString(@"Access Denied",nil)];
             block(resp, error);
         }
         
         PreyLogMessage(@"PreyRestHttp", 10,@"Error DELETE: %@",error);
     }];
}

+ (void)setPushRegistrationId:(NSInteger)reload  withToken:(NSString *)tokenId withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block
{
    NSDictionary    *params     = [NSDictionary dictionaryWithObjectsAndKeys: tokenId, @"notification_id", nil];
    NSString        *deviceKey  = [[PreyConfig instance] deviceKey];
    
    [[PreyStatusClientV2 sharedClient] POST:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices/%@/data",deviceKey]
                                     parameters:params
                                        success:^(NSURLSessionDataTask *operation, id responseObject)
     {
         NSHTTPURLResponse* resp = (NSHTTPURLResponse*)operation.response;
         PreyLogMessage(@"PreyRestHttp", 21, @"POST notificationID: %@",responseObject);
         
         if (block)
             block(resp, nil);
         
     } failure:^(NSURLSessionDataTask *operation, NSError *error)
     {
         NSHTTPURLResponse* resp = (NSHTTPURLResponse*)operation.response;
         if ( ([resp statusCode] == 503) && (reload > 0) )
         {
             // Call method again
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                 [self setPushRegistrationId:reload - 1 withToken:tokenId withBlock:block];
             });
         }
             // When reload <= 0 then return statusCode:503
         else if ( ([resp statusCode] == 503) && (reload <= 0) )
             [self returnStatusCode503:block checkCompletionHandler:NO];
         
             // Return response to block
         else if (block)
             block(resp, error);
         
         PreyLogMessage(@"PreyRestHttp", 10,@"Error notificationID: %@",error);
     }];
}

+ (void)checkCommandJsonForDevice:(NSString *)cmdString
{
    NSString *deviceKey = [[PreyConfig instance] deviceKey];
    PreyLogMessage(@"PreyRestHttp", 21, @"GET CMD devices/%@.json: %@",deviceKey, cmdString);
    
    NSError *error2;
    JsonConfigParser *configParser = [[JsonConfigParser alloc] init];
    NewModulesConfig *modulesConfig = [configParser parseModulesConfig:cmdString parseError:&error2];
    
    if ([modulesConfig checkAllModulesEmpty])
    {
        PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate checkedCompletionHandler];
    }
    else
        [modulesConfig runAllModules];

    
    [[PreyStatusClientV2 sharedClient] GET:[NSString stringWithFormat:@"/api/v2/devices/%@.json", deviceKey]
                                    parameters:nil
                                       success:^(NSURLSessionDataTask *operation, id responseObject)
     {
         PreyLogMessage(@"PreyRestHttp", 21, @"GET devices/%@.json: %@",deviceKey,responseObject);
         
     } failure:^(NSURLSessionDataTask *operation, NSError *error) {
         PreyLogMessage(@"PreyRestHttp", 10,@"Error: %@",error);
     }];
}

+ (void)checkStatusForDevice:(NSInteger)reload withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block
{
    NSString *deviceKey = [[PreyConfig instance] deviceKey];
    
    [[PreyStatusClientV2 sharedClient] GET:[NSString stringWithFormat:@"/api/v2/devices/%@.json", deviceKey]
                                    parameters:nil
                                       success:^(NSURLSessionDataTask *operation, id responseObject)
     {
         PreyLogMessage(@"PreyRestHttp", 21, @"GET devices/%@.json: %@",deviceKey,responseObject);
         
         NewModulesConfig *modulesConfig = [[NewModulesConfig alloc] init];
         
         for (NSDictionary *dict in responseObject)
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
         
         NSHTTPURLResponse* resp = (NSHTTPURLResponse*)operation.response;
         if (block)
             block(resp,nil);
         
     } failure:^(NSURLSessionDataTask *operation, NSError *error)
     {
         NSHTTPURLResponse* resp = (NSHTTPURLResponse*)operation.response;
         if ( ([resp statusCode] == 503) && (reload > 0) )
         {
             // Call method again
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                 [self checkStatusForDevice:reload - 1 withBlock:block];
             });
         }
             // When reload <= 0 then return statusCode:503
         else if ( ([resp statusCode] == 503) && (reload <= 0) )
             [self returnStatusCode503:block checkCompletionHandler:NO];
         
             // Return response to block
         else if (block)
             block(resp, error);
         
         PreyLogMessage(@"PreyRestHttp", 10,@"Error: %@",error);
     }];
}

+ (void)sendJsonData:(NSInteger)reload withData:(NSDictionary*)jsonData toEndpoint:(NSString *)url withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block
{
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    [[PreyStatusClientV2 sharedClient] POST:url
                                     parameters:jsonData
                                        success:^(NSURLSessionDataTask *operation, id responseObject)
     {
         NSHTTPURLResponse* resp = (NSHTTPURLResponse*)operation.response;
         PreyLogMessage(@"PreyRestHttp", 21, @"POST %@: %@",url,responseObject);
         if (block)
             block(resp, nil);
         
         [appDelegate checkedCompletionHandler];
         
     } failure:^(NSURLSessionDataTask *operation, NSError *error)
     {
         NSHTTPURLResponse* resp = (NSHTTPURLResponse*)operation.response;
         if ( ([resp statusCode] == 503) && (reload > 0) )
         {
             // Call method again
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                 [self sendJsonData:reload - 1 withData:jsonData andRawData:nil toEndpoint:url withBlock:block];
             });
         }
             // When reload <= 0 then return statusCode:503
         else if ( ([resp statusCode] == 503) && (reload <= 0) )
             [self returnStatusCode503:block checkCompletionHandler:YES];
         
             // Return response to block
         else if (block)
         {
             if ([resp statusCode] == 409)
             {
                 [[ReportModule instance] stopSendReport];
                 [appDelegate checkedCompletionHandler];
             }
             
             block(resp, error);
             [appDelegate checkedCompletionHandler];
         }
         
         PreyLogMessage(@"PreyRestHttp", 10,@"Error: %@",error);
     }];
}

+ (void)sendJsonData:(NSInteger)reload withData:(NSDictionary*)jsonData andRawData:(NSDictionary*)rawData toEndpoint:(NSString *)url withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block
{
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];

    [[PreyStatusClientV2 sharedClient] POST:url
                                 parameters:jsonData
                  constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                      
                      if ([rawData objectForKey:@"picture"]!=nil)
                          [formData appendPartWithFileData:[rawData objectForKey:@"picture"] name:@"picture" fileName:@"picture.jpg" mimeType:@"image/png"];
                      
                      if ([rawData objectForKey:@"screenshot"]!=nil)
                          [formData appendPartWithFileData:[rawData objectForKey:@"screenshot"] name:@"screenshot" fileName:@"screenshot.jpg" mimeType:@"image/png"];
                      
    } success:^(NSURLSessionDataTask *operation, id responseObject) {
        
        NSHTTPURLResponse* resp = (NSHTTPURLResponse*)operation.response;
        PreyLogMessage(@"PreyRestHttp", 21, @"POST %@: %@",url,responseObject);
        
        if (block)
            block(resp, nil);
        
        [appDelegate checkedCompletionHandler];

    } failure:^(NSURLSessionDataTask *operation, NSError *error) {
         NSHTTPURLResponse* resp = (NSHTTPURLResponse*)operation.response;
        if ( ([resp statusCode] == 503) && (reload > 0) )
        {
            // Call method again
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self sendJsonData:reload - 1 withData:jsonData andRawData:rawData toEndpoint:url withBlock:block];
            });
        }
        // When reload <= 0 then return statusCode:503
        else if ( ([resp statusCode] == 503) && (reload <= 0) )
            [self returnStatusCode503:block checkCompletionHandler:YES];
        
        // Return response to block
        else if (block)
        {
            if ([resp statusCode] == 409)
            {
                [[ReportModule instance] stopSendReport];
                [appDelegate checkedCompletionHandler];
            }
            
            block(resp, error);
            [appDelegate checkedCompletionHandler];
        }
        
        PreyLogMessage(@"PreyRestHttp", 10,@"Error: %@",error);

    }];
}

+ (void)checkStatusInBackground:(NSInteger)reload withURL:(NSString*)endpoint withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block
{
    NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
    [requestData setObject:[[PreyConfig instance] deviceKey] forKey:@"device_key"];
    
    [[PreyStatusClientV2 sharedClient] POST:endpoint
                                     parameters:requestData
                                        success:^(NSURLSessionDataTask *operation, id responseObject)
     {
         NSHTTPURLResponse* resp = (NSHTTPURLResponse*)operation.response;
         PreyLogMessage(@"PreyRestHttp", 21, @"POST: %@",responseObject);
         
         if (block)
             block(resp, nil);
         
     } failure:^(NSURLSessionDataTask *operation, NSError *error)
     {
         NSHTTPURLResponse* resp = (NSHTTPURLResponse*)operation.response;
         if ( ([resp statusCode] == 503) && (reload > 0) )
         {
             // Call method again
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                 [self checkStatusInBackground:reload - 1  withURL:endpoint withBlock:block];
             });
         }
             // When reload <= 0 then return statusCode:503
         else if ( ([resp statusCode] == 503) && (reload <= 0) )
             [self returnStatusCode503:block checkCompletionHandler:NO];
         
             // Return response to block
         else if (block)
             block(resp, error);
         
         PreyLogMessage(@"PreyRestHttp", 10,@"Error: %@",error);
     }];
}

@end
