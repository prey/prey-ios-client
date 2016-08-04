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
    
    // Test new user
    func testRest01LogInUser() {
        
        let expectation     = self.expectationWithDescription("Prey Expecta")
        
        // LogIn to Panel Prey
        PreyUser.logInToPrey(userEmail, userPassword:userPassword, onCompletion: {(isSuccess: Bool) in
            
            // Check if login is success
            XCTAssertTrue(isSuccess)
            
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(15, handler:nil)
    }
    
    // Test get token from panel
    func testRest02GetToken() {
        
        let expectation     = self.expectationWithDescription("Prey Expecta")
        
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
    func testRest03AddDevice() {
        
        let expectation     = self.expectationWithDescription("Prey Expecta")
        
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
}
