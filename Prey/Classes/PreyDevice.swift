//
//  PreyDevice.swift
//  Prey
//
//  Created by Javier Cala Uribe on 15/03/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import UIKit

class PreyDevice {
    
    // MARK: Properties
    
    var deviceKey: String?
    var name: String?
    var type: String?
    var model: String?
    var vendor: String?
    var os: String?
    var version: String?
    var macAddress: String?
    var uuid: String?
    var cpuModel: String?
    var cpuSpeed: String?
    var cpuCores: String?
    var ramSize: String?
    
    // MARK: Functions

    // Init function
    init() {
        name        = UIDevice.current.name
        type        = (IS_IPAD) ? "Tablet" : "Phone"
        os          = "iOS"
        vendor      = "Apple"
        model       = UIDevice.current.deviceModel.rawValue
        version     = UIDevice.current.systemVersion
        uuid        = UIDevice.current.identifierForVendor?.uuidString
        macAddress  = "02:00:00:00:00:00" // iOS default
        ramSize     = UIDevice.current.ramSize
        cpuModel    = UIDevice.current.cpuModel
        cpuSpeed    = UIDevice.current.cpuSpeed
        cpuCores    = UIDevice.current.cpuCores
    }
    
    // Add new device to Panel Prey
    class func addDeviceWith(_ onCompletion:@escaping (_ isSuccess: Bool) -> Void) {
        
        let preyDevice = PreyDevice()
        
        let hardwareInfo : [String:String] = [
            "uuid"         : preyDevice.uuid!,
            "serial_number": preyDevice.uuid!,
            "cpu_model"    : preyDevice.cpuModel!,
            "cpu_speed"    : preyDevice.cpuSpeed!,
            "cpu_cores"    : preyDevice.cpuCores!,
            "ram_size"     : preyDevice.ramSize!]
        
        let params:[String:Any] = [
            "name"                              : preyDevice.name!,
            "device_type"                       : preyDevice.type!,
            "os_version"                        : preyDevice.version!,
            "model_name"                        : preyDevice.model!,
            "vendor_name"                       : preyDevice.vendor!,
            "os"                                : preyDevice.os!,
            "physical_address"                  : preyDevice.macAddress!,
            "hardware_attributes"               : hardwareInfo]
        
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.sendDataToPrey(username, password:"x", params:params, messageId:nil, httpMethod:Method.POST.rawValue, endPoint:devicesEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.addDevice, preyAction:nil, onCompletion:onCompletion))
        } else {
            let titleMsg = "Couldn't add your device".localized
            let alertMsg = "Error user ID".localized
            displayErrorAlert(alertMsg, titleMessage:titleMsg)
            onCompletion(false)
        }
    }
    
    class func renameDevice(_ newName: String, onCompletion:@escaping (_ isSuccess: Bool) -> Void) {
        let paramsInfo : [String:String] = [
            "new_name"                  : newName]
        
        let params:[String: Any] = [
            "name"                      : "device_renamed",
            "info"                      : paramsInfo]
        
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.sendDataToPrey(username, password:"x", params:params, messageId:nil, httpMethod:Method.POST.rawValue, endPoint:eventsDeviceEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.signUp, preyAction:nil, onCompletion:onCompletion))
        }else{
            PreyLogger("Error renameDevice")
        }
    }
    
    // Track retry attempts to avoid infinite recursion
    private static var infoDeviceRetryCount = [String: Int]()
    private static let maxRetryAttempts = 2
    
    // Throttling mechanism to prevent excessive infoDevice calls
    private static var lastInfoDeviceCallTime: Date?
    private static var pendingInfoDeviceCallbacks: [(_ isSuccess: Bool) -> Void] = []
    private static var isInfoDeviceInProgress = false
    private static let infoDeviceThrottleInterval: TimeInterval = 60 // 1 minute
    
    class func infoDevice(_ onCompletion:@escaping (_ isSuccess: Bool) -> Void) {

        guard let username = PreyConfig.sharedInstance.userApiKey else {
            PreyLogger("Error infoDevice - No API key available")
            onCompletion(false)
            return
        }

        PreyNetworkRetry.sendDataWithBackoff(
            username: username,
            password: "x",
            params: nil,
            messageId: nil,
            httpMethod: Method.GET.rawValue,
            endPoint: infoEndpoint,
            tag: "infoDevice",
            maxAttempts: 5,
            nonRetryStatusCodes: [401]
        ) { success in
            if success {
                onCompletion(true)
            } else {
                onCompletion(false)
            }
        }
    }
}
