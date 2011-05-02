//
//  User.m
//  prey-installer-cocoa
//
//  Created by Carlos Yaconi on 18-03-10.
//  Copyright 2010 Fork Ltd.. All rights reserved.
//

#import "User.h"
#import "PreyRestHttp.h"


@implementation User

@synthesize apiKey;
@synthesize name;
@synthesize country;
@synthesize email;
@synthesize password;
@synthesize repassword;
@synthesize devices;

+(User*) allocWithEmail: (NSString*) _email password: (NSString*) _password {
	User *newUser = [[User alloc] init];
	newUser.email = _email;
	newUser.password = _password;
	
	PreyRestHttp *userHttp = [[[PreyRestHttp alloc] init] autorelease];
	@try {
		NSString *_apiKey = [userHttp getCurrentControlPanelApiKey: newUser];
		newUser.apiKey = _apiKey;
		return newUser;
	}
	@catch (NSException * e) {
		return nil;
	}
	return nil;
}

+(User*) createNew: (NSString*) _name email: (NSString*) _email password: (NSString*) _password repassword: (NSString*) _repassword {
	
	User *newUser = [[User alloc] init];
	
	NSLocale *locale = [NSLocale currentLocale];
    NSString *countryCode = [locale objectForKey: NSLocaleCountryCode];
    NSString *countryName = [locale displayNameForKey:NSLocaleCountryCode value:countryCode];
	
	[newUser setName: _name];
	[newUser setEmail: _email];
	[newUser setCountry: countryName];
	[newUser setPassword: _password];
	[newUser setRepassword: _repassword];
	
	[locale release];
	[countryCode release];
	[countryName release];
	
	@try {
		PreyRestHttp *userHttp = [[[PreyRestHttp alloc] init] autorelease];
		NSString *_apiKey = [userHttp createApiKey: newUser];
		
		[newUser setApiKey:_apiKey];
		
		return newUser;
	}
	@catch (NSException * e) {
		@throw e;
	}
	return nil;
}

-(BOOL) deleteDevice: (Device*) dev {
	@try {
		PreyRestHttp *userHttp = [[[PreyRestHttp alloc] init] autorelease];
		return [userHttp deleteDevice:dev];
	}
	@catch (NSException * e) {
		@throw;
	}
	return NO;
}
@end
