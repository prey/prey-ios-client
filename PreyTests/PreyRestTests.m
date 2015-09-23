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
#import "PreyAFHTTPRequestOperation.h"
#import "IphoneInformationHelper.h"


#define newEmailTest    @"newUser@mail.com"
#define emailTest       @"name@mail.com"
#define passwTest       @"password"

@interface PreyRestTests : XCTestCase

@end

@implementation PreyRestTests

- (void)setUp
{
    [super setUp];

}

- (void)tearDown
{
    [super tearDown];
}

- (void)testRestSetPushRegistrationId
{
    __block id blockError = nil;
    __block NSInteger statusCode;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Prey Expecta"];
    
    [PreyRestHttp setPushRegistrationId:5 withToken:@"t3stT0k3n"
                              withBlock:^(NSHTTPURLResponse *response, NSError *error)
    {
        if ([response isKindOfClass:[NSHTTPURLResponse class]])
        {
            statusCode = [(NSHTTPURLResponse *) response statusCode];
            XCTAssertEqual(statusCode, 200, @"status code was not 200; was %ld", (long)statusCode);
        }
        blockError = error;
        XCTAssertNil(blockError,@"was an error: %@", [error description]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testRestCreateDeviceKeyForDevice
{
    __block id blockError;
    __block NSString *blockDevicekey;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Prey Expecta"];
    
    Device *newDevice = [[Device alloc] init];
	IphoneInformationHelper *iphoneInfo = [IphoneInformationHelper instance];
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
              XCTAssertNotNil(blockDevicekey,@"deviceKey is nil");
              XCTAssertFalse( [deviceKey length] == 0,@"deviceKey is empty");
              XCTAssertNil(blockError,@"was an error: %@", [error description]);
              [expectation fulfill];
          }];
     }];
    
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testRestCreateApiKey
{
    __block id blockError;
    __block NSString *blockApikey;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Prey Expecta"];
    
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
         XCTAssertNotNil(blockApikey,@"deviceKey is nil");
         XCTAssertFalse( [blockApikey length] == 0,@"deviceKey is empty");
         XCTAssertNil(blockError,@"was an error: %@", [error description]);
         [expectation fulfill];
     }
     ];
    
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testRestCheckTransactionInAppPurchase
{
    __block id blockError = nil;
    __block NSInteger statusCode;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Prey Expecta"];
    
    NSString *receiptDataString = @"th1s4t3st";
    
    [PreyRestHttp checkTransaction:5 withString:receiptDataString
                         withBlock:^(NSHTTPURLResponse *response, NSError *error)
     {
         if ([response isKindOfClass:[NSHTTPURLResponse class]])
         {
             statusCode = [(NSHTTPURLResponse *) response statusCode];
             XCTAssertEqual(statusCode, 200, @"status code was not 200; was %ld", (long)statusCode);
         }
         
         blockError = error;
         XCTAssertNil(blockError,@"was an error: %@", [error description]);
         [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testRestGetCurrentControlPanelApiKey
{
    __block id blockError;
    __block NSString *blockApikey;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Prey Expecta"];
    
    User *newUser = [[User alloc] init];

    // Write email/password valid
	newUser.email = emailTest;
	newUser.password = passwTest;
    
    [PreyRestHttp getCurrentControlPanelApiKey:5 withUser:newUser
                                     withBlock:^(NSString *apiKey, NSError *error)
     {
         blockApikey = apiKey;
         blockError  = error;
         
         XCTAssertNotNil(blockApikey,@"deviceKey is nil");
         XCTAssertFalse( [blockApikey length] == 0,@"deviceKey is empty");
         XCTAssertNil(blockError,@"was an error: %@", [error description]);
         [expectation fulfill];

     }];

    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testRestCheckStatusForDevice
{
    __block id blockError = nil;
    __block NSInteger statusCode;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Prey Expecta"];
    
    [PreyRestHttp checkStatusForDevice:5 withBlock:^(NSHTTPURLResponse *response, NSError *error) {
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]])
        {
            statusCode = [(NSHTTPURLResponse *) response statusCode];
            XCTAssertEqual(statusCode, 200, @"status code was not 200; was %ld", (long)statusCode);
        }
        
        blockError = error;
        XCTAssertNil(blockError,@"was an error: %@", [error description]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testRestDeleteDevice
{
    __block id blockError = nil;
    __block NSInteger statusCode;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Prey Expecta"];
    
    [PreyRestHttp deleteDevice:5 withBlock:^(NSHTTPURLResponse *response, NSError *error)
     {
         if ([response isKindOfClass:[NSHTTPURLResponse class]])
         {
             statusCode = [(NSHTTPURLResponse *) response statusCode];
             XCTAssertEqual(statusCode, 200, @"status code was not 200; was %ld", (long)statusCode);
         }
         
         blockError = error;
         XCTAssertNil(blockError,@"was an error: %@", [error description]);
         [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

@end