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

@property (nonatomic,retain) NSString *apiKey;
@property (nonatomic,retain) NSString *name;
@property (nonatomic,retain) NSString *email;
@property (nonatomic,retain) NSString *country;
@property (nonatomic,retain) NSString *password;
@property (nonatomic,retain) NSString *repassword;
@property (nonatomic,retain) NSArray *devices;
@property (nonatomic, getter = isPro) BOOL pro;

+ (void)allocWithEmail:(NSString*)emailUser password:(NSString*)passwordUser  withBlock:(void (^)(User *user, NSError *error))block;
+ (void)createNew:(NSString*)nameUser email:(NSString*)emailUser password:(NSString*)passwordUser repassword:(NSString*)repasswordUser  withBlock:(void (^)(User *user, NSError *error))block;

@end
