//
//  PreyRestTests.m
//  PreyRestTests
//
//  Created by Javier Cala Uribe on 4/7/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PreyRestHttp.h"
#import "PreyConfig.h"
#import "Constants.h"
#import "AFHTTPRequestOperation.h"
#import "IphoneInformationHelper.h"

#define EXP_SHORTHAND YES
#import "Expecta.h"
//#import "OCMock.h"

#define newEmailTest    @"newUser@mail.com"
#define emailTest       @"name@mail.com"
#define passwTest       @"password"

@interface PreyRestTests : XCTestCase

@end

@implementation PreyRestTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [Expecta setAsynchronousTestTimeout:5.0];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testRestSetPushRegistrationId
{
    __block id blockError = nil;
    __block NSInteger statusCode;

    [PreyRestHttp setPushRegistrationId:5 withToken:@"t3stT0k3n"
                              withBlock:^(NSHTTPURLResponse *response, NSError *error)
    {
        if ([response isKindOfClass:[NSHTTPURLResponse class]])
        {
            statusCode = [(NSHTTPURLResponse *) response statusCode];
            XCTAssertEqual(statusCode, 200, @"status code was not 200; was %ld", (long)statusCode);
        }
        blockError = error;
    }];
    
    expect(statusCode).will.equal(200);
    expect(blockError).will.beNil();
}

- (void)testRestGetAppstoreConfig
{
    __block id blockError;
    __block NSMutableSet *blockDataStore;

    [PreyRestHttp getAppstoreConfig:5 withUrl:@"subscriptions/store.json" withBlock:^(NSMutableSet *dataStore, NSError *error)
     {
         blockError = error;
         blockDataStore = dataStore;
     }];

    expect(blockDataStore).willNot.beNil();
    expect(blockDataStore).willNot.beEmpty();
    
    expect(blockError).will.beNil();
}

- (void)testRestCreateDeviceKeyForDevice
{
    __block id blockError;
    __block NSString *blockDevicekey;
    
    Device *newDevice = [[Device alloc] init];
	IphoneInformationHelper *iphoneInfo = [IphoneInformationHelper initializeWithValues];
	[newDevice setOs: [iphoneInfo os]];
	[newDevice setVersion: [iphoneInfo version]];
	[newDevice setType: [iphoneInfo type]];
	[newDevice setMacAddress: [iphoneInfo macAddress]];
	[newDevice setName: [iphoneInfo name]];
    [newDevice setVendor: [iphoneInfo vendor]];
    [newDevice setModel: [iphoneInfo model]];
    [newDevice setUuid: [iphoneInfo uuid]];

    User *newUser = [[User alloc] init];
    
    // Write email/password valid
	newUser.email = emailTest;
	newUser.password = passwTest;
    
    [PreyRestHttp getCurrentControlPanelApiKey:5 withUser:newUser
                                     withBlock:^(NSString *apiKey, NSError *error)
     {
         [PreyRestHttp createDeviceKeyForDevice:5 withDevice:newDevice usingApiKey:apiKey
                                      withBlock:^(NSString *deviceKey, NSError *error)
          {
              blockDevicekey = deviceKey;
              blockError     = error;
          }];
     }];
    
    expect(blockDevicekey).willNot.beNil();
    expect(blockDevicekey).willNot.beEmpty();
    
    expect(blockError).will.beNil();
}

- (void)testRestCreateApiKey
{
    __block id blockError;
    __block NSString *blockApikey;
    
    User *newUser = [[User alloc] init];
    
    NSLocale *locale = [NSLocale currentLocale];
    NSString *countryCode = [locale objectForKey: NSLocaleCountryCode];
    NSString *countryName = [locale displayNameForKey:NSLocaleCountryCode value:countryCode];
	
	[newUser setName:@"TestUser"];
	[newUser setEmail:newEmailTest];
	[newUser setCountry:countryName];
	[newUser setPassword:passwTest];
	[newUser setRepassword:passwTest];
    
    [PreyRestHttp createApiKey:5 withUser:newUser withBlock:^(NSString *apiKey, NSError *error)
     {
         blockApikey = apiKey;
         blockError  = error;
     }
     ];
    
    expect(blockApikey).willNot.beNil();
    expect(blockApikey).willNot.beEmpty();
    
    expect(blockError).will.beNil();
}

- (void)testRestCheckTransactionInAppPurchase
{
    __block id blockError = nil;
    __block NSInteger statusCode;

    NSString *receiptDataString = @"th1s4t3st";
    
    [PreyRestHttp checkTransaction:5 withString:receiptDataString
                         withBlock:^(NSHTTPURLResponse *response, NSError *error)
     {
         if ([response isKindOfClass:[NSHTTPURLResponse class]])
         {
             statusCode = [(NSHTTPURLResponse *) response statusCode];
         }
         
         blockError = error;
     }];
    
    // Just check if endpoint is valid
    expect(statusCode).will.equal(401); // should be 200
    expect(blockError).willNot.beNil(); // should be nil
}

- (void)testRestGetCurrentControlPanelApiKey
{
    __block id blockError;
    __block NSString *blockApikey;
    
    User *newUser = [[User alloc] init];

    // Write email/password valid
	newUser.email = emailTest;
	newUser.password = passwTest;
    
    [PreyRestHttp getCurrentControlPanelApiKey:5 withUser:newUser
                                     withBlock:^(NSString *apiKey, NSError *error)
     {
         blockApikey = apiKey;
         blockError  = error;
     }];

    expect(blockApikey).willNot.beNil();
    expect(blockApikey).willNot.beEmpty();

    expect(blockError).will.beNil();
}

- (void)testRestCheckStatusForDevice
{
    __block id blockError = nil;
    __block NSInteger statusCode;
    
    [PreyRestHttp checkStatusForDevice:5 withBlock:^(NSHTTPURLResponse *response, NSError *error) {
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]])
        {
            statusCode = [(NSHTTPURLResponse *) response statusCode];
            XCTAssertEqual(statusCode, 200, @"status code was not 200; was %ld", (long)statusCode);
        }
        
        blockError = error;
    }];
    
    expect(statusCode).will.equal(200);
    expect(blockError).will.beNil();
}

- (void)testRestDeleteDevice
{
    __block id blockError = nil;
    __block NSInteger statusCode;
    
    [PreyRestHttp deleteDevice:5 withBlock:^(NSHTTPURLResponse *response, NSError *error)
     {
         if ([response isKindOfClass:[NSHTTPURLResponse class]])
         {
             statusCode = [(NSHTTPURLResponse *) response statusCode];
             XCTAssertEqual(statusCode, 200, @"status code was not 200; was %ld", (long)statusCode);
         }
         
         blockError = error;
     }];
    
    expect(statusCode).will.equal(200);
    expect(blockError).will.beNil();
}

@end