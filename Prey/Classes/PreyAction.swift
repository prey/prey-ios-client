//
//  PreyAction.swift
//  Prey
//
//  Created by Javier Cala Uribe on 5/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation


class PreyAction : Operation {
   
    // MARK: Properties
    
    var target: kAction
    var command: kCommand
    var options: NSDictionary?
    var messageId: String?
    var deviceJobId: String?
    
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
        
        let actionItem: PreyAction?
        
        switch target {

        case kAction.location:
            actionItem = Location.initLocationAction(withTarget: kAction.location, withCommand: cmd, withOptions: opt)

        case kAction.alarm:
            actionItem = Alarm(withTarget: kAction.alarm, withCommand: cmd, withOptions: opt)

        case kAction.alert:
            actionItem = Alert(withTarget: kAction.alert, withCommand: cmd, withOptions: opt)
            
        case kAction.report:
            actionItem = Report(withTarget: kAction.report, withCommand: cmd, withOptions: opt)

        case kAction.geofencing:
            actionItem = Geofencing(withTarget: kAction.geofencing, withCommand: cmd, withOptions: opt)

        case kAction.detach:
            actionItem = Detach(withTarget: kAction.detach, withCommand: cmd, withOptions: opt)

        case kAction.camouflage:
            actionItem = Camouflage(withTarget: kAction.camouflage, withCommand: cmd, withOptions: opt)
            
        case kAction.ping:
            actionItem = Ping(withTarget: kAction.ping, withCommand: cmd, withOptions: opt)
        }
        
        return actionItem
    }

    // Return params to response endpoint
    func getParamsTo(_ target:String, command:String, status:String) -> [String: String] {
        
        // Params struct
        var params:[String: String] = [
            kData.status.rawValue   : status,
            kData.target.rawValue   : target,
            kData.command.rawValue  : command]
        
        if let jobId = deviceJobId {
            params[kData.reason.rawValue] = jobId
        }
        
        return params
    }
    
    // Send data to panel
    func sendData(_ params:[String: Any], toEndpoint:String) {

        PreyLogger("data")
        
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:params, messageId:messageId, httpMethod:Method.POST.rawValue, endPoint:toEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.dataSend, preyAction:self, onCompletion:{(isSuccess: Bool) in PreyLogger("Request dataSend")}))
        } else {
            PreyLogger("Error send data auth")
        }
    }

    // Send report to panel
    func sendDataReport(_ params:NSMutableDictionary, images:NSMutableDictionary, toEndpoint:String) {
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.sendDataReportToPrey(username, password:"x", params:params, images: images, messageId:messageId, httpMethod:Method.POST.rawValue, endPoint:toEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.dataSend, preyAction:self, onCompletion:{(isSuccess: Bool) in PreyLogger("Request dataSend")}))
        } else {
            PreyLogger("Error send data auth")
        }
        
    }
    
    // Check Geofence Zones
    func checkGeofenceZones(_ action:Geofencing) {
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:nil, messageId:nil, httpMethod:Method.GET.rawValue, endPoint:geofencingEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.geofenceZones, preyAction:action, onCompletion:{(isSuccess: Bool) in PreyLogger("Request geofencesZones")}))
        } else {
            PreyLogger("Error auth check Geofence")
        }
    }

    // Delete device in Panel
    func sendDeleteDevice(_ onCompletion:@escaping (_ isSuccess: Bool) -> Void) {
        
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:nil, messageId:nil, httpMethod:Method.DELETE.rawValue, endPoint:deleteDeviceEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.deleteDevice, preyAction:nil, onCompletion:onCompletion))
        } else {
            let titleMsg = "Couldn't delete your device".localized
            let alertMsg = "Device not ready!".localized
            displayErrorAlert(alertMsg, titleMessage:titleMsg)
            onCompletion(false)
        }
    }
}
