//
//  User.h
//  prey-installer-cocoa
//
//  Created by Carlos Yaconi on 18-03-10.
//  Copyright 2010 Fork Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Device.h"

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

+(User*) allocWithEmail: (NSString*) email password: (NSString*) password;
+(User*) createNew: (NSString*) name email: (NSString*) email password: (NSString*) password repassword: (NSString*) repassword;
-(BOOL) deleteDevice: (Device*) device;


@end
