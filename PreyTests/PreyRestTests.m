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
#import "UIDevice-Hardware.h"

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

- (void)testRest01CreateApiKey
{
    __block id blockError;
    __block NSString *blockApikey;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Prey Expecta"];
    
    User *newUser = [[User alloc] init];
    
    NSLocale *locale = [NSLocale currentLocale];
    NSString *countryCode = [locale objectForKey: NSLocaleCountryCode];
    NSString *countryName = [locale displayNameForKey:NSLocaleCountryCode value:countryCode];
	
    double    currentTime = CFAbsoluteTimeGetCurrent();
    NSString *newMail     = [NSString stringWithFormat:@"test%f@prey.io",currentTime];
    
    [PreyConfig instance].email = newMail;
    [[PreyConfig instance] saveValues];
    
	[newUser setName:@"TestUser"];
	[newUser setEmail:newMail];
	[newUser setCountry:countryName];
	[newUser setPassword:passwTest];
	[newUser setRepassword:passwTest];
    
    [[PreyRestHttp getClassVersion] createApiKey:5 withUser:newUser withBlock:^(NSString *apiKey, NSError *error)
     {
         blockApikey = apiKey;
         blockError  = error;
         XCTAssertNotNil(blockApikey,@"apiKey is nil");
         XCTAssertFalse( [blockApikey length] == 0,@"apiKey is empty");
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

- (void)testRest02CreateDeviceKeyForDevice
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
    
    float frequency_cpu = [[UIDevice currentDevice] cpuFrequency] / 1000000;
    
    [newDevice setCpu_model:[[UIDevice currentDevice] hwmodel]];
    [newDevice setCpu_cores:[NSString stringWithFormat:@"%lu",(unsigned long)[[UIDevice currentDevice] cpuCount]]];
    [newDevice setCpu_speed:[NSString stringWithFormat:@"%f",frequency_cpu]];
    
    [newDevice setRam_size:[NSString stringWithFormat:@"%lu",(unsigned long)([[UIDevice currentDevice] totalMemory]/1024/1024)]];
    
    User *newUser = [[User alloc] init];
    
    // Write email/password valid
    newUser.email = [PreyConfig instance].email;
    newUser.password = passwTest;
    
    [[PreyRestHttp getClassVersion] getCurrentControlPanelApiKey:5 withUser:newUser
                                                       withBlock:^(NSString *apiKey, NSError *error)
     {
         [[PreyRestHttp getClassVersion] createDeviceKeyForDevice:5 withDevice:newDevice usingApiKey:apiKey
                                                        withBlock:^(NSString *deviceKey, NSError *error)
          {
              blockDevicekey = deviceKey;
              blockError     = error;
              XCTAssertNotNil(blockDevicekey,@"deviceKey is nil");
              XCTAssertFalse( [deviceKey length] == 0,@"deviceKey is empty");
              XCTAssertNil(blockError,@"was an error: %@", [error description]);
              [PreyConfig instance].deviceKey = deviceKey;
              [PreyConfig instance].controlPanelHost = DEFAULT_CONTROL_PANEL_HOST;
              [PreyConfig instance].checkPath = DEFAULT_CHECK_PATH;
              [[PreyConfig instance] saveValues];
              
              [expectation fulfill];
          }];
     }];
    
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testRest03CheckStatusForDevice
{
    __block id blockError = nil;
    __block NSInteger statusCode;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Prey Expecta"];
    
    [[PreyRestHttp getClassVersion] checkStatusForDevice:5 withBlock:^(NSHTTPURLResponse *response, NSError *error) {
        
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

- (void)testRest04GetCurrentControlPanelApiKey
{
    __block id blockError;
    __block NSString *blockApikey;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Prey Expecta"];
    
    User *newUser = [[User alloc] init];

    // Write email/password valid
	newUser.email = [PreyConfig instance].email;
	newUser.password = passwTest;
    
    [[PreyRestHttp getClassVersion] getCurrentControlPanelApiKey:5 withUser:newUser
                                     withBlock:^(NSString *apiKey, NSError *error)
     {
         blockApikey = apiKey;
         blockError  = error;
         
         XCTAssertNotNil(blockApikey,@"apiKey is nil");
         XCTAssertFalse( [blockApikey length] == 0,@"apiKey is empty");
         XCTAssertNil(blockError,@"was an error: %@", [error description]);
         [expectation fulfill];

     }];

    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testRest05CheckTransactionInAppPurchase
{
    __block id blockError = nil;
    __block NSInteger statusCode;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Prey Expecta"];
    
    NSString *receiptDataString = @"t3stT0k3n";
    
    [[PreyRestHttp getClassVersion] checkTransaction:5 withString:receiptDataString
                                           withBlock:^(NSHTTPURLResponse *response, NSError *error)
     {
         if ([response isKindOfClass:[NSHTTPURLResponse class]])
         {
             statusCode = [(NSHTTPURLResponse *) response statusCode];
             XCTAssertEqual(statusCode, 403, @"status code was not 403; was %ld", (long)statusCode);
         }
         
         blockError = error;
         //XCTAssertNil(blockError,@"was an error: %@", [error description]);
         [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testRest06SetPushRegistrationId
{
    __block id blockError = nil;
    __block NSInteger statusCode;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Prey Expecta"];
    
    [[PreyRestHttp getClassVersion] setPushRegistrationId:5 withToken:@"t3stT0k3n"
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

- (void)testRest07DeleteDevice
{
    __block id blockError = nil;
    __block NSInteger statusCode;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Prey Expecta"];
    
    [[PreyRestHttp getClassVersion] deleteDevice:5 withBlock:^(NSHTTPURLResponse *response, NSError *error)
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