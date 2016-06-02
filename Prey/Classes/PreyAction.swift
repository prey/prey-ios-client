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

// Prey location params
enum kLocation: String {
    case LONGITURE  = "lng"
    case LATITUDE   = "lat"
    case ALTITUDE   = "alt"
    case ACCURACY   = "accuracy"
    case METHOD     = "method"
}

// Prey location params
enum kReportLocation: String {
    case LONGITURE  = "geo[lng]"
    case LATITUDE   = "geo[lat]"
    case ALTITUDE   = "geo[alt]"
    case ACCURACY   = "geo[accuracy]"
    case METHOD     = "geo[method]"
}

// Prey /Data Endpoint struct
enum kData: String {
    case STATUS     = "status"
    case TARGET     = "target"
    case COMMAND    = "command"
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
    
    // Stop method
    func stop () {}
    
    // Return Prey New Action
    class func newAction(withName target:kAction, withCommand cmd:kCommand, withOptions opt: NSDictionary?) -> PreyAction? {
        
        let actionItem: PreyAction
        
        switch target {

        case kAction.LOCATION:
            actionItem = Location(withTarget: kAction.LOCATION, withCommand: cmd, withOptions: opt)

        case kAction.ALARM:
            actionItem = Alarm(withTarget: kAction.ALARM, withCommand: cmd, withOptions: opt)

        case kAction.REPORT:
            actionItem = Report(withTarget: kAction.REPORT, withCommand: cmd, withOptions: opt)
        }
        
        return actionItem
    }

    // Return params to response endpoint
    func getParamsTo(target:String, command:String, status:String) -> [String: AnyObject] {
        
        // Params struct
        let params:[String: AnyObject] = [
            kData.STATUS.rawValue   : status,
            kData.TARGET.rawValue   : target,
            kData.COMMAND.rawValue  : command]
        
        return params
    }
    
    // Send data to panel
    func sendData(params:[String: AnyObject], toEndpoint:String) {

        print("data: \(params.description)")
        
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:params, httpMethod:Method.POST.rawValue, endPoint:toEndpoint, onCompletion:PreyHTTPResponse.checkDataSend(self))
        } else {
            print("Error send data auth")
        }
    }

    // Send report to panel
    func sendDataReport(params:NSMutableDictionary, images:NSMutableDictionary?, toEndpoint:String) {
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.sendDataReportToPrey(username, password:"x", params:params, images: images, httpMethod:Method.POST.rawValue, endPoint:toEndpoint, onCompletion:PreyHTTPResponse.checkDataSend(self))
        } else {
            print("Error send data auth")
        }
        
    }
}