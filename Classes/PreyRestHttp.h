//
//  RestHttpUser.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 18-03-10.
//  Copyright 2010 Fork Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "Device.h"

@interface PreyRestHttp : NSObject

+ (void)checkTransaction:(NSInteger)reload withString:(NSString *)receiptData withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block;
+ (void)getCurrentControlPanelApiKey:(NSInteger)reload withUser:(User *)user withBlock:(void (^)(NSString *apiKey, NSError *error))block;
+ (void)createApiKey:(NSInteger)reload withUser:(User *)user withBlock:(void (^)(NSString *apiKey, NSError *error))block;
+ (void)createDeviceKeyForDevice:(NSInteger)reload withDevice:(Device *)device usingApiKey:(NSString *)apiKey withBlock:(void (^)(NSString *deviceKey, NSError *error))block;
+ (void)deleteDevice:(NSInteger)reload withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block;
+ (void)getAppstoreConfig:(NSInteger)reload withUrl:(NSString *)URL withBlock:(void (^)(NSMutableSet *dataStore, NSError *error))block;
+ (void)setPushRegistrationId:(NSInteger)reload  withToken:(NSString *)tokenId withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block;
+ (void)checkCommandJsonForDevice:(NSString *)cmdString;
+ (void)checkStatusForDevice:(NSInteger)reload withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block;
+ (void)sendJsonData:(NSInteger)reload withData:(NSDictionary*)jsonData toEndpoint:(NSString *)url withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block;
+ (void)sendJsonData:(NSInteger)reload withData:(NSDictionary*)jsonData andRawData:(NSDictionary*)rawData toEndpoint:(NSString *)url withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block;
+ (void)checkStatusInBackground:(NSInteger)reload withURL:(NSString*)endpoint withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block;

@end
