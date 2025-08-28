//
//  PreyTests.swift
//  PreyTests
//
//  Created by Javier Cala Uribe on 5/8/14.
//  Copyright (c) 2014 Prey, Inc. All rights reserved.
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
        
        let expectation     = self.expectation(description: "Expecta Test: Log In")
        
        // LogIn to Panel Prey
        PreyUser.logInToPrey(userEmail, userPassword:userPassword, onCompletion: {(isSuccess: Bool) in
            
            // Check if login is success
            XCTAssertTrue(isSuccess)
            
            // Check if apiKey is nil
            XCTAssertNotNil(PreyConfig.sharedInstance.userApiKey)
            
            expectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 15, handler:nil)
    }
    
    // Test log user
    func testRest02SignUpUser() {
        
        let expectation     = self.expectation(description: "Expecta Test: Sign Up")
        
        let newMail         = String(format:"test%f@prey.io", CFAbsoluteTimeGetCurrent())
        
        // SignUp to Panel Prey
        PreyUser.signUpToPrey("TestUser", userEmail:newMail, userPassword:userPassword, onCompletion: {(isSuccess: Bool) in
            
            // Check if login is success
            XCTAssertTrue(isSuccess)
            
            // Check if apiKey is nil
            XCTAssertNotNil(PreyConfig.sharedInstance.userApiKey)
            
            expectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 15, handler:nil)
    }
    
    // Test get token from panel
    func testRest03GetToken() {
        
        let expectation     = self.expectation(description: "Expecta Test: Get Token")
        
        // Get token from panel
        PreyUser.getTokenFromPanel(userEmail, userPassword:userPassword, onCompletion: {(isSuccess: Bool) in

            // Check if get token is success
            XCTAssertTrue(isSuccess)
            
            // Check if token is nil
            XCTAssertNotNil(PreyConfig.sharedInstance.tokenPanel)
            
            expectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 15, handler:nil)
    }
    
    // Test add device
    func testRest04AddDevice() {
        
        let expectation     = self.expectation(description: "Expecta Test: Add Device")
        
        // Add Device to Panel Prey
        PreyDevice.addDeviceWith({(isSuccess: Bool) in

            // Check if add device is success
            XCTAssertTrue(isSuccess)
            
            // Check if deviceKey is nil
            XCTAssertNotNil(PreyConfig.sharedInstance.deviceKey)
            
            expectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 15, handler:nil)
    }
    
    // Test check status for device
    func testRest05CheckStatusForDevice() {
        
        let expectation     = self.expectation(description: "Expecta Test: Check Status")
        
        let response: (Data?, URLResponse?, Error?) -> Void = { (data, response, error) in
            
            // Error is nil
            XCTAssertNil(error)
            
            let httpURLResponse = response as! HTTPURLResponse
            
            XCTAssertEqual(httpURLResponse.statusCode,200)

            // Check if actionArray is nil
            let actionArray: String? = String(data: data!, encoding: String.Encoding.utf8)
            XCTAssertNotNil(actionArray)
            
            expectation.fulfill()
        }

        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.sendDataToPrey(username, password: "x", params: nil, messageId:nil, httpMethod:Method.GET.rawValue, endPoint:actionsDeviceEndpoint , onCompletion:response)
        } else {
            // Check if apiKey is nil
            XCTAssertNotNil(PreyConfig.sharedInstance.userApiKey)
        }        
        
        self.waitForExpectations(timeout: 15, handler:nil)
    }
    
    // Test NotificationId
    func testRest06CheckNotificationId() {
        
        let expectation     = self.expectation(description: "Expecta Test: Check NotificationId")
    
        let response: (Data?, URLResponse?, Error?) -> Void = { (data, response, error) in
            
            // Error is nil
            XCTAssertNil(error)
            
            let httpURLResponse = response as! HTTPURLResponse
            
            XCTAssertEqual(httpURLResponse.statusCode,200)
            
            expectation.fulfill()
        }
        
        let params:[String: String] = ["notification_id" : "t3stT0k3n"]
        
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.sendDataToPrey(username, password:"x", params:params, messageId:nil, httpMethod:Method.POST.rawValue, endPoint:dataDeviceEndpoint, onCompletion:response)
        } else {
            // Check if apiKey is nil
            XCTAssertNotNil(PreyConfig.sharedInstance.userApiKey)
        }
        
        self.waitForExpectations(timeout: 15, handler:nil)
    }
    
    // Test Transaction InAppPurchase
    func testRest07TransactionInAppPurchase() {
        
        let expectation                 = self.expectation(description: "Expecta Test: Transaction InAppPurchase")
        
        let receipt                     = "t3stT0k3n".data(using: String.Encoding.utf8, allowLossyConversion: true)! as Data
        let receiptDataString           = receipt.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        
        let params:[String: String]  = ["receipt-data" : receiptDataString]

        let response: (Data?, URLResponse?, Error?) -> Void = { (data, response, error) in
            
            // Error is nil
            XCTAssertNil(error)
            
            let httpURLResponse = response as! HTTPURLResponse
            
            XCTAssertEqual(httpURLResponse.statusCode,403)
            
            expectation.fulfill()
        }
        
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.sendDataToPrey(username, password:"x", params:params, messageId:nil, httpMethod:Method.POST.rawValue, endPoint:subscriptionEndpoint, onCompletion:response)
        } else {
            // Check if apiKey is nil
            XCTAssertNotNil(PreyConfig.sharedInstance.userApiKey)
        }
        
        self.waitForExpectations(timeout: 15, handler:nil)
    }
    
    // Test Response Device
    func testRest10ResponseDevice() {
        
        let expectation     = self.expectation(description: "Expecta Test: Response Device")

        let response: (Data?, URLResponse?, Error?) -> Void = { (data, response, error) in
            
            // Error is nil
            XCTAssertNil(error)
            
            let httpURLResponse = response as! HTTPURLResponse
            
            XCTAssertEqual(httpURLResponse.statusCode,200)
            
            expectation.fulfill()
        }

        // Params struct
        let params:[String: Any] = [
            kData.status.rawValue   : kStatus.started.rawValue,
            kData.target.rawValue   : kAction.camouflage.rawValue,
            kData.command.rawValue  : kCommand.start.rawValue]
        
        // Send info to panel
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.sendDataToPrey(username, password:"x", params:params, messageId:nil, httpMethod:Method.POST.rawValue, endPoint:responseDeviceEndpoint, onCompletion:response)
        } else {
            // Check if apiKey is nil
            XCTAssertNotNil(PreyConfig.sharedInstance.userApiKey)
        }
        
        self.waitForExpectations(timeout: 15, handler:nil)
    }
    
    // Test Send Report
    func testRest11SendReport() {
        
        let expectation     = self.expectation(description: "Expecta Test: Response Device")
        
        let response: (Data?, URLResponse?, Error?) -> Void = { (data, response, error) in
            
            // Error is nil
            XCTAssertNil(error)
            
            let httpURLResponse = response as! HTTPURLResponse
            
            XCTAssertEqual(httpURLResponse.statusCode,409) // Device isn't missing on web panel
            
            expectation.fulfill()
        }
        
        let reportData   = NSMutableDictionary()
        let reportImages = NSMutableDictionary()
        
        // Params struct
        let params:[String : Any] = [
            kReportLocation.LONGITURE.rawValue    : 0,
            kReportLocation.LATITUDE.rawValue     : 0,
            kReportLocation.ALTITUDE.rawValue     : 0,
            kReportLocation.ACCURACY.rawValue     : 0]
        
        // Save location to reportData
        reportData.addEntries(from: params)
        
        // Send info to panel
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.sendDataReportToPrey(username, password:"x", params:reportData, images:reportImages, messageId:nil, httpMethod:Method.POST.rawValue, endPoint:reportDataDeviceEndpoint, onCompletion:response)
        } else {
            // Check if apiKey is nil
            XCTAssertNotNil(PreyConfig.sharedInstance.userApiKey)
        }
        
        self.waitForExpectations(timeout: 15, handler:nil)
    }
    
    // Test Delete Device
    func testRest12DeleteDevice() {
        
        let expectation     = self.expectation(description: "Expecta Test: Delete Device")
        
        // Check if deviceKey is nil
        XCTAssertNotNil(PreyConfig.sharedInstance.deviceKey)        
        
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            
            PreyHTTPClient.sharedInstance.sendDataToPrey(username, password:"x", params:nil, messageId:nil, httpMethod:Method.DELETE.rawValue, endPoint:deleteDeviceEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.deleteDevice, preyAction:nil, onCompletion:{(isSuccess: Bool) in
                
                // Check if add device is success
                XCTAssertTrue(isSuccess)
                
                expectation.fulfill()
            }))
            
        } else {
            // Check if apiKey is nil
            XCTAssertNotNil(PreyConfig.sharedInstance.userApiKey)
        }
        
        self.waitForExpectations(timeout: 60, handler:nil)
    }
}
