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

- (void)testRequests
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSDictionary *data = [NSDictionary new];
    [PreyRestHttp sendJsonData:5 withData:data andRawData:nil
                    toEndpoint:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices/%@/data",[[PreyConfig instance] deviceKey]]
                     withBlock:^(NSHTTPURLResponse *response, NSError *error) {
                         
                         XCTAssertNil(error, @"JsonData error %@", error);
                         
                         if ([response isKindOfClass:[NSHTTPURLResponse class]])
                         {
                             NSInteger statusCode = [(NSHTTPURLResponse *) response statusCode];
                             XCTAssertEqual(statusCode, 200, @"status code was not 200; was %d", statusCode);
                         }
                         
                         XCTAssert(data, @"data nil");
                         
                         dispatch_semaphore_signal(semaphore);
                     }];
    
    long rc = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 60.0 * NSEC_PER_SEC));
    XCTAssertEqual(rc, 0, @"network request timed out");
}

@end
