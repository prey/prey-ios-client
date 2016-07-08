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

        case kAction.ALERT:
            actionItem = Alert(withTarget: kAction.ALERT, withCommand: cmd, withOptions: opt)
            
        case kAction.REPORT:
            actionItem = Report(withTarget: kAction.REPORT, withCommand: cmd, withOptions: opt)

        case kAction.GEOFENCING:
            actionItem = Geofencing(withTarget: kAction.GEOFENCING, withCommand: cmd, withOptions: opt)

        case kAction.DETACH:
            actionItem = Detach(withTarget: kAction.DETACH, withCommand: cmd, withOptions: opt)

        case kAction.CAMOUFLAGE:
            actionItem = Camouflage(withTarget: kAction.CAMOUFLAGE, withCommand: cmd, withOptions: opt)
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
    
    // Check Geofence Zones
    func checkGeofenceZones(action:Geofencing) {
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:nil, httpMethod:Method.GET.rawValue, endPoint:geofencingEndpoint, onCompletion:PreyHTTPResponse.checkGeofenceZones(action))
        } else {
            print("Error auth check Geofence")
        }
    }

    // Delete device in Panel
    func sendDeleteDevice(onCompletion:(isSuccess: Bool) -> Void) {
        
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:nil, httpMethod:Method.DELETE.rawValue, endPoint:actionsDeviceEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.DeleteDevice, onCompletion:onCompletion))
        } else {
            let titleMsg = "Couldn't delete your device".localized
            let alertMsg = "Device not ready!".localized
            displayErrorAlert(alertMsg, titleMessage:titleMsg)
            onCompletion(isSuccess:false)
        }
    }
}