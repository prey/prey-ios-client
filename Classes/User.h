//
//  User.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 18-03-10.
//  Copyright 2010 Fork Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject {
	
	NSString *apiKey;
	NSString *name;
	NSString *email;
	NSString *country;
	NSString *password;
	NSString *repassword;
	NSArray *devices;

}

@property (nonatomic) NSString *apiKey;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *email;
@property (nonatomic) NSString *country;
@property (nonatomic) NSString *password;
@property (nonatomic) NSString *repassword;
@property (nonatomic) NSArray *devices;
@property (nonatomic, getter = isPro) BOOL pro;

+ (void)getTokenFromPanel:(NSString*)emailUser password:(NSString*)passwordUser  withBlock:(void (^)(NSString *token, NSError *error))block;
+ (void)allocWithEmail:(NSString*)emailUser password:(NSString*)passwordUser  withBlock:(void (^)(User *user, NSError *error))block;
+ (void)createNew:(NSString*)nameUser email:(NSString*)emailUser password:(NSString*)passwordUser repassword:(NSString*)repasswordUser  withBlock:(void (^)(User *user, NSError *error))block;

@end
