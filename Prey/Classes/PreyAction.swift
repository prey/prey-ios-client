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
    case GET      = "get"
}

class PreyAction : NSOperation {
   
    // MARK: Properties
    
    var target: kAction
    var command: kCommand
    var options: NSDictionary?
    
    var isActive: Bool = false
    
    // MARK: Functions    

    // Initialize with Target
    init(withTarget t: kAction, withCommand cmd: kCommand, withOptions opt: NSDictionary?) {
        target  = t
        command = cmd
        options = opt
    }
    
    // Return Prey New Action
    class func newAction(withName target:kAction, withCommand cmd:kCommand, withOptions opt: NSDictionary?) -> PreyAction? {
        
        let actionItem: PreyAction
        
        switch target {

        case kAction.LOCATION:
            actionItem = Location(withTarget: kAction.LOCATION, withCommand: cmd, withOptions: opt)

        case kAction.ALARM:
            actionItem = Alarm(withTarget: kAction.ALARM, withCommand: cmd, withOptions: opt)

        case kAction.REPORT:
            actionItem = Alarm(withTarget: kAction.REPORT, withCommand: cmd, withOptions: opt)
            print("report")
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
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:params, httpMethod:Method.POST.rawValue, endPoint:toEndpoint, onCompletion:PreyHTTPResponse.checkDataSend(self))
        } else {
            print("Error send data auth")
        }
    }
}