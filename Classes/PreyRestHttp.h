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

- (void)getAppstoreConfig:(id) delegate inURL: (NSString *) URL;

+ (void)createApiKey:(User *)user withBlock:(void (^)(NSString *apiKey, NSError *error))block;
+ (void)getCurrentControlPanelApiKey:(User *)user withBlock:(void (^)(NSString *apiKey, NSError *error))block;
+ (void)createDeviceKeyForDevice:(Device *)device usingApiKey:(NSString *)apiKey withBlock:(void (^)(NSString *deviceKey, NSError *error))block;
+ (void)checkStatusForDevice:(void (^)(NSArray *posts, NSError *error))block;
+ (void)sendJsonData:(NSDictionary*)jsonData andRawData:(NSDictionary*)rawData toEndpoint:(NSString *)url withBlock:(void (^)(NSArray *posts, NSError *error))block;
+ (void)setPushRegistrationId:(NSString *)tokenId withBlock:(void (^)(NSArray *posts, NSError *error))block;
+ (void)deleteDevice:(void (^)(NSError *error))block;

@end
