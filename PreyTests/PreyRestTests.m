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

#define EXP_SHORTHAND YES
#import "Expecta.h"
//#import "OCMock.h"

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

- (void)testRestCheckTransactionInAppPurchase
{
    __block id blockError = nil;
    __block NSInteger statusCode;

    NSString *receiptDataString = @"th1s4t3st";
    
    [PreyRestHttp checkTransaction:receiptDataString
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
	newUser.email = @"name@mail.com";
	newUser.password = @"password";
    
    [PreyRestHttp getCurrentControlPanelApiKey:newUser
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

@end