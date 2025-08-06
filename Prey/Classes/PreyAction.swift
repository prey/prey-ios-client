//
//  PreyAction.swift
//  Prey
//
//  Created by Javier Cala Uribe on 5/05/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation


class PreyAction : Operation, @unchecked Sendable {
   
    // MARK: Properties
    var target: kAction
    var command: kCommand
    var options: NSDictionary?
    var messageId: String?
    var deviceJobId: String?
    var triggerId: String?
    var isActive: Bool = false
    
    // MARK: Functions    

    // Initialize with Target
    init(withTarget t: kAction, withCommand cmd: kCommand, withOptions opt: NSDictionary?) {
        target  = t
        command = cmd
        options = opt
    }

    // Start method
    @objc override func start() {}

    // Stop method
    @objc func stop() {}
    
    // Get method
    @objc func get() {}
    
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

        case kAction.detach:
            actionItem = Detach(withTarget: kAction.detach, withCommand: cmd, withOptions: opt)

        case kAction.camouflage:
            actionItem = Camouflage(withTarget: kAction.camouflage, withCommand: cmd, withOptions: opt)
            
        case kAction.ping:
            actionItem = Ping(withTarget: kAction.ping, withCommand: cmd, withOptions: opt)
            
        case kAction.tree:
            actionItem = FileRetrieval(withTarget: kAction.tree, withCommand: cmd, withOptions: opt)

        case kAction.fileretrieval:
            actionItem = FileRetrieval(withTarget: kAction.fileretrieval, withCommand: cmd, withOptions: opt)

        case kAction.triggers:
            actionItem = Trigger(withTarget: kAction.triggers, withCommand: cmd, withOptions: opt)
            
        case kAction.user_activated:
            actionItem = UserActivated(withTarget: kAction.user_activated, withCommand: cmd, withOptions: opt)
        
        case kAction.list_permissions:
            actionItem = ListPermissions(withTarget: kAction.list_permissions, withCommand: cmd, withOptions: opt)
        }
        
        return actionItem
    }

    // Return params to response endpoint
    func getParamsTo(_ target:String, command:String, status:String) -> [String: Any] {
        
        // Params struct
        var params:[String: Any] = [
            kData.status.rawValue   : status,
            kData.target.rawValue   : target,
            kData.command.rawValue  : command]
        
        if let jobId = deviceJobId {
            let jobIdJson = [kOptions.device_job_id.rawValue : jobId]
            params[kData.reason.rawValue] = jobIdJson
        }

        if let tigreId = triggerId {
            let triggerIdJson = [kOptions.trigger_id.rawValue : tigreId]
            params[kData.reason.rawValue] = triggerIdJson
        }

        return params
    }
    
    // Send data to panel
    func sendData(_ params:[String: Any], toEndpoint:String) {

        PreyLogger("data")
        
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey, PreyConfig.sharedInstance.isRegistered {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:params, messageId:messageId, httpMethod:Method.POST.rawValue, endPoint:toEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.dataSend, preyAction:self, onCompletion:{(isSuccess: Bool) in PreyLogger("Request dataSend")}))
        } else {
            PreyLogger("Error send data auth")
        }
    }

    // Send report to panel
    func sendDataReport(_ params:NSMutableDictionary, images:NSMutableDictionary, toEndpoint:String) {
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey, PreyConfig.sharedInstance.isRegistered {
            PreyHTTPClient.sharedInstance.sendDataReportToPrey(username, password:"x", params:params, images: images, messageId:messageId, httpMethod:Method.POST.rawValue, endPoint:toEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.dataSend, preyAction:self, onCompletion:{(isSuccess: Bool) in PreyLogger("Request dataSend")}))
        } else {
            PreyLogger("Error send data auth")
        }
        
    }

    // Check Triggers
    func checkTriggers(_ action:Trigger) {
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:nil, messageId:nil, httpMethod:Method.GET.rawValue, endPoint:triggerEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.trigger, preyAction:action, onCompletion:{(isSuccess: Bool) in PreyLogger("Request triggers on panel")}))
        } else {
            PreyLogger("Error auth check Triggers")
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
