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
#import "AFNetworking.h"
#import "AFPreyStatusClient.h"
#import "PreyConfig.h"
#import "Constants.h"
#import "JsonConfigParser.h"

@implementation PreyRestHttp

#pragma mark Init

+ (void)getCurrentControlPanelApiKey:(User *)user withBlock:(void (^)(NSString *apiKey, NSError *error))block
{
    [[AFPreyStatusClient sharedClient] setAuthorizationHeaderWithUsername:[user email] password:[user password]];
    
    [[AFPreyStatusClient sharedClient] getPath:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/profile.json"]
                                     parameters:nil
                                        success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         PreyLogMessage(@"PreyRestHttp", 21, @"GET profile.json: %@",[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
         
         NSError *error2;
         NSString *respString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
         JsonConfigParser *configParser = [[JsonConfigParser alloc] init];
         [configParser parseRequest:respString forUser:user parseError:&error2];
         
         if (block) {
             block(user.apiKey, nil);
         }
         
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         
         NSInteger  statusCode  = [operation.response statusCode];
         NSString  *showMessage = [error localizedDescription];
         
         if (statusCode == 401)
         {
             showMessage = NSLocalizedString(@"There was a problem getting your account information. Please make sure the email address you entered is valid, as well as your password.",nil);
         }
         
         UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Couldn't check your password",nil)
                                                             message:showMessage
                                                            delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
         [alertView show];
         [alertView release];
         
         if (block) {
             block(nil, error);
         }
         PreyLogMessage(@"PreyRestHttp", 10,@"Error profile.json: %@",error);
     }];
}

+ (void)createApiKey:(User *)user withBlock:(void (^)(NSString *apiKey, NSError *error))block
{
    NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
    [requestData setObject:[user name] forKey:@"name"];
	[requestData setObject:[user email] forKey:@"email"];
	[requestData setObject:[user country] forKey:@"country_name"];
    [requestData setObject:[user password] forKey:@"password"];
	[requestData setObject:[user repassword] forKey:@"password_confirmation"];
	[requestData setObject:@"" forKey:@"referer_user_id"];
    
    [[AFPreyStatusClient sharedClient] postPath:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/signup.json"]
                                    parameters:requestData
                                       success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         PreyLogMessage(@"PreyRestHttp", 21, @"POST signup.json: %@",[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
         
         NSError *error2;
         NSString *respString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
         JsonConfigParser *configParser = [[JsonConfigParser alloc] init];
         NSString *userKey = [configParser parseKey:respString parseError:&error2];
         
         if (block) {
             block(userKey, nil);
         }
         
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         
         UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"User couldn't be created",nil)
                                                             message:[error localizedDescription]
                                                            delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
         [alertView show];
         [alertView release];
         
         if (block) {
             block(nil, error);
         }
         PreyLogMessage(@"PreyRestHttp", 10,@"Error signup.json: %@",error);
     }];
}

+ (void)createDeviceKeyForDevice:(Device *)device usingApiKey:(NSString *)apiKey withBlock:(void (^)(NSString *deviceKey, NSError *error))block
{
    NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
    [requestData setObject:[device name] forKey:@"name"];
    [requestData setObject:[device type] forKey:@"device_type"];
    [requestData setObject:[device version] forKey:@"os_version"];
    [requestData setObject:[device model] forKey:@"model_name"];
    [requestData setObject:[device vendor] forKey:@"vendor_name"];
    [requestData setObject:[device os] forKey:@"os"];
    [requestData setObject:[device macAddress] forKey:@"physical_address"];
    [requestData setObject:[device uuid] forKey:@"uuid"];
    
    [[AFPreyStatusClient sharedClient] setAuthorizationHeaderWithUsername:apiKey password:@"x"];
    
    [[AFPreyStatusClient sharedClient] postPath:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices.json"]
                                     parameters:requestData
                                        success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         PreyLogMessage(@"PreyRestHttp", 21, @"POST devices.json: %@",[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
         
         NSError *error2 = nil;
         JsonConfigParser *configParser     = [[JsonConfigParser alloc] init];
         NSString         *deviceKeyString  = [configParser parseKey:[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]
                                                          parseError:&error2];
         
         if (block) {
             block(deviceKeyString, nil);
         }
         
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         
         NSInteger  statusCode  = [operation.response statusCode];
         NSString  *showMessage = [error localizedDescription];
         
         if ((statusCode == 302) || (statusCode == 403))
         {
             showMessage = NSLocalizedString(@"It seems you've reached your limit for devices on the Control Panel. Try removing this device from your account if you had already added.",nil);
         }
         
         UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Couldn't add your device",nil)
                                                             message:showMessage
                                                            delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
         [alertView show];
         [alertView release];

         
         if (block) {
             block(nil, error);
         }
         PreyLogMessage(@"PreyRestHttp", 10,@"Error devices.json: %@",error);
     }];
}

+ (void)deleteDevice:(void (^)(NSError *error))block
{
    [[AFPreyStatusClient sharedClient] deletePath:[[PreyConfig instance] deviceCheckPathWithExtension:@""]
                                     parameters:nil
                                        success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         PreyLogMessage(@"PreyRestHttp", 21, @"DELETE device: %@",[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
         
         if (block) {
             block(nil);
         }
         
     } failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
         UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Access Denied",nil)
                                                             message:NSLocalizedString(@"Device not ready!",nil)
                                                            delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
         [alertView show];
         [alertView release];
        
         if (block) {
             block(error);
         }
         PreyLogMessage(@"PreyRestHttp", 10,@"Error DELETE: %@",error);
     }];
}

#warning PENDIENTE
- (void) getAppstoreConfig: (id) delegate inURL: (NSString *) URL
{
    /*
    ASIHTTPRequest *request = [self createGETrequestWithURL:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat:@"/%@",URL]];
    [request setDelegate:delegate];
    [request setDidFinishSelector:@selector(receivedData:)];
    [request startAsynchronous];
    */
}

+ (void)setPushRegistrationId:(NSString *)tokenId withBlock:(void (^)(NSArray *posts, NSError *error))block
{
    NSDictionary    *params     = [NSDictionary dictionaryWithObjectsAndKeys: tokenId, @"notification_id", nil];
    NSString        *deviceKey  = [[PreyConfig instance] deviceKey];
    
    [[AFPreyStatusClient sharedClient] postPath:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices/%@/data",deviceKey]
                                    parameters:params
                                       success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         PreyLogMessage(@"PreyRestHttp", 21, @"POST notificationID: %@",[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
         
         if (block) {
             block([NSArray array], nil);
         }
         
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         if (block) {
             block([NSArray array], error);
         }
         PreyLogMessage(@"PreyRestHttp", 10,@"Error notificationID: %@",error);
     }];
}

+ (void)checkStatusForDevice:(void (^)(NSArray *posts, NSError *error))block
{
    NSString *deviceKey = [[PreyConfig instance] deviceKey];
    
    [[AFPreyStatusClient sharedClient] getPath:[NSString stringWithFormat:@"/api/v2/devices/%@.json", deviceKey]
                                    parameters:nil
                                       success:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        PreyLogMessage(@"PreyRestHttp", 21, @"GET devices/%@.json: %@",deviceKey,[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
        
        NSString *respString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        JsonConfigParser *configParser = [[JsonConfigParser alloc] init];
        
        NSError *error2;
        NewModulesConfig *modulesConfig = [configParser parseModulesConfig:respString parseError:&error2];
        [modulesConfig runAllModules];
        [configParser release];
        
        if (block) {
            block([NSArray array], nil);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block([NSArray array], error);
        }
        PreyLogMessage(@"PreyRestHttp", 10,@"Error: %@",error);
    }];
}

+ (void)sendJsonData:(NSDictionary*)jsonData andRawData:(NSDictionary*)rawData toEndpoint:(NSString *)url withBlock:(void (^)(NSArray *posts, NSError *error))block
{
    if (rawData == nil)
    {
        [[AFPreyStatusClient sharedClient] postPath:url
                                         parameters:jsonData
                                            success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             PreyLogMessage(@"PreyRestHttp", 21, @"POST %@: %@",url,[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
             
             if (block) {
                 block([NSArray array], nil);
             }
             
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             PreyLogMessage(@"PreyRestHttp", 10,@"Error: %@",error);
             
             if ([operation.response statusCode] == 409)
                 [[ReportModule instance] stopSendReport];
             
             if (block) {
                 block([NSArray array], error);
             }
         }];
    }
    else
    {
        NSMutableURLRequest *request;
        request = [[AFPreyStatusClient sharedClient] multipartFormRequestWithMethod:@"POST" path:url parameters:jsonData
                                                          constructingBodyWithBlock: ^(id <AFMultipartFormData>formData)
                   {
                       if ([rawData objectForKey:@"picture"]!=nil)
                           [formData appendPartWithFileData:[rawData objectForKey:@"picture"] name:@"picture" fileName:@"picture.jpg" mimeType:@"image/png"];
                   }];
        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             PreyLogMessage(@"PreyRestHttp", 21, @"POST %@: %@",url,[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
             
         } failure:^(AFHTTPRequestOperation *operation, NSError *error)
         {
             
             PreyLogMessage(@"PreyRestHttp", 10,@"Error: %@",error);
             
             if ([operation.response statusCode] == 409)
                 [[ReportModule instance] stopSendReport];
         }];
        [[AFPreyStatusClient sharedClient] enqueueHTTPRequestOperation:operation];
    }
}

@end
