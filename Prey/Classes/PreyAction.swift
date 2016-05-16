//
//  PreyAction.swift
//  Prey
//
//  Created by Javier Cala Uribe on 5/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation

// Prey actions definitions
enum kAction: String {
    case LOCATION   = "location"
    case REPORT     = "report"
    case ALARM      = "alarm"
}

// Prey status definitions
enum kStatus: String {
    case STARTED    = "started"
    case STOPPED    = "stopped"
}

// Prey command definitions
enum kCommand: String {
    case START    = "start"
    case STOP     = "stop"
}

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

        case kAction.ALARM.rawValue:
            actionItem = Alarm()
            
        default:
            return nil
        }
        
        return actionItem
    }

    // Return params to response endpoint
    func getParamsTo(target:String, command:String, status:String) -> [String: AnyObject] {
        
        // Params struct
        let params:[String: AnyObject] = [
            "status"    : status,
            "target"    : target,
            "command"   : command]
        
        return params
    }
    
    // Send data to panel
    func sendData(params:[String: AnyObject], toEndpoint:String) {
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:params, httpMethod:Method.POST.rawValue, endPoint:toEndpoint, onCompletion:PreyHTTPResponse.checkDataSend())
        } else {
            print("Error send data auth")
        }
    }
}