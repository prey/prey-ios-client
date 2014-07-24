//
//  PreyTests.m
//  PreyTests
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

@interface PreyTests : XCTestCase

@end

@implementation PreyTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testRequestsCheckStatusForDevice
{
    __block id blockError = nil;
    __block NSInteger statusCode;
    
    [Expecta setAsynchronousTestTimeout:5.0];
    
    [PreyRestHttp checkStatusForDevice:5 withBlock:^(NSHTTPURLResponse *response, NSError *error) {
        
        XCTAssertNil(error, @"JsonData error %@", error);
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]])
        {
            statusCode = [(NSHTTPURLResponse *) response statusCode];
            XCTAssertEqual(statusCode, 200, @"status code was not 200; was %ld", (long)statusCode);
        }
        
        blockError = error;
    }];
    
    expect(statusCode).will.equal(200);;
}

@end
