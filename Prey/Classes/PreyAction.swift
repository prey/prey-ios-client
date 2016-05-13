//
//  PreyAction.swift
//  Prey
//
//  Created by Javier Cala Uribe on 5/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation

class PreyAction : NSOperation {
   
    // MARK: Properties
    
    var command: String!
    var options: NSDictionary?
    
    // MARK: Functions    

    // Return Prey New Action
    class func newAction(withName:String) -> PreyAction? {
        
        let actionItem: PreyAction
        
        switch withName {

        case kAction.LOCATION.rawValue:
            actionItem = Location.sharedInstance
       
        default:
            return nil
        }
        
        return actionItem
    }
    
    // Send data to panel
    func sendData(params:[String: AnyObject]) {
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:params, httpMethod:Method.POST.rawValue, endPoint:dataDeviceEndpoint, onCompletion:PreyHTTPResponse.checkDataSend())
        } else {
            print("Error send data auth")
        }
    }
}