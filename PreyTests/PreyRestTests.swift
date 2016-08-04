//
//  PreyTests.swift
//  PreyTests
//
//  Created by Javier Cala Uribe on 5/8/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

import UIKit
import XCTest
@testable import Prey

class PreyRestTests: XCTestCase {
    
    // MARK: Properties

    let userEmail       = "test7@prey.io"
    let userPassword    = "password"
    
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // Test log user
    func testRest01LogInUser() {
        
        let expectation     = self.expectationWithDescription("Expecta Test: Log In")
        
        // LogIn to Panel Prey
        PreyUser.logInToPrey(userEmail, userPassword:userPassword, onCompletion: {(isSuccess: Bool) in
            
            // Check if login is success
            XCTAssertTrue(isSuccess)
            
            // Check if apiKey is nil
            XCTAssertNotNil(PreyConfig.sharedInstance.userApiKey)
            
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(15, handler:nil)
    }
    
    // Test log user
    func testRest02SignUpUser() {
        
        let expectation     = self.expectationWithDescription("Expecta Test: Sign Up")
        
        let newMail         = String(format:"test%f@prey.io", CFAbsoluteTimeGetCurrent())
        
        // SignUp to Panel Prey
        PreyUser.signUpToPrey("TestUser", userEmail:newMail, userPassword:userPassword, onCompletion: {(isSuccess: Bool) in
            
            // Check if login is success
            XCTAssertTrue(isSuccess)
            
            // Check if apiKey is nil
            XCTAssertNotNil(PreyConfig.sharedInstance.userApiKey)
            
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(15, handler:nil)
    }
    
    // Test get token from panel
    func testRest03GetToken() {
        
        let expectation     = self.expectationWithDescription("Expecta Test: Get Token")
        
        // Get token from panel
        PreyUser.getTokenFromPanel(userEmail, userPassword:userPassword, onCompletion: {(isSuccess: Bool) in

            // Check if get token is success
            XCTAssertTrue(isSuccess)
            
            // Check if token is nil
            XCTAssertNotNil(PreyConfig.sharedInstance.tokenPanel)
            
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(15, handler:nil)
    }
    
    // Test add device
    func testRest04AddDevice() {
        
        let expectation     = self.expectationWithDescription("Expecta Test: Add Device")
        
        // Add Device to Panel Prey
        PreyDevice.addDeviceWith({(isSuccess: Bool) in

            // Check if add device is success
            XCTAssertTrue(isSuccess)
            
            // Check if deviceKey is nil
            XCTAssertNotNil(PreyConfig.sharedInstance.deviceKey)
            
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(15, handler:nil)
    }
    
    // Test check status for device
    func testRest05CheckStatusForDevice() {
        
        let expectation     = self.expectationWithDescription("Expecta Test: Check Status")
        
        let actionDeviceResponse: (NSData?, NSURLResponse?, NSError?) -> Void = { (data, response, error) in
            
            // Error is nil
            XCTAssertNil(error)
            
            let httpURLResponse = response as! NSHTTPURLResponse
            
            XCTAssertEqual(httpURLResponse.statusCode,200)

            // Check if actionArray is nil
            let actionArray: String? = String(data: data!, encoding: NSUTF8StringEncoding)
            XCTAssertNotNil(actionArray)
            
            expectation.fulfill()
        }

        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password: "x", params: nil, httpMethod:Method.GET.rawValue, endPoint:actionsDeviceEndpoint , onCompletion:actionDeviceResponse)
        } else {
            // Check if apiKey is nil
            XCTAssertNotNil(PreyConfig.sharedInstance.userApiKey)
        }        
        
        self.waitForExpectationsWithTimeout(15, handler:nil)
    }
}
