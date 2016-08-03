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
        
        let userEmail       = "test7@prey.io"
        let userPassword    = "password"
        
        let expectation     = self.expectationWithDescription("Prey Expecta")
        
        // LogIn to Panel Prey
        PreyUser.logInToPrey(userEmail, userPassword:userPassword, onCompletion: {(isSuccess: Bool) in
            
            // Check if login is success
            XCTAssertTrue(isSuccess)
            
            expectation.fulfill()
        })

        
        self.waitForExpectationsWithTimeout(15, handler:nil)
    }
}
