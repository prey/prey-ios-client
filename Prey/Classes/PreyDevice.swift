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
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:params, messageId:nil, httpMethod:Method.POST.rawValue, endPoint:devicesEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.addDevice, preyAction:nil, onCompletion:onCompletion))
        } else {
            let titleMsg = "Couldn't add your device".localized
            let alertMsg = "Error user ID".localized
            displayErrorAlert(alertMsg, titleMessage:titleMsg)
            onCompletion(false)
        }
    }
    
    class func renameDevice(_ newName: String, onCompletion:@escaping (_ isSuccess: Bool) -> Void) {
        
        let language:String = Locale.preferredLanguages[0] as String
        let languageES  = (language as NSString).substring(to: 2)
        
        let paramsInfo : [String:String] = [
            "new_name"                  : newName]
        
        let params:[String: Any] = [
            "name"                      : "device_renamed",
            "info"                      : paramsInfo]
        
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:params, messageId:nil, httpMethod:Method.POST.rawValue, endPoint:eventsDeviceEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.signUp, preyAction:nil, onCompletion:onCompletion))
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
        let now = Date()
        
        // Check if we should throttle this call
        if let lastCallTime = lastInfoDeviceCallTime,
           now.timeIntervalSince(lastCallTime) < infoDeviceThrottleInterval {
            
            // If there's already a request in progress, queue this callback
            if isInfoDeviceInProgress {
                PreyLogger("infoDevice - Throttled: adding callback to pending queue")
                pendingInfoDeviceCallbacks.append(onCompletion)
                return
            }
            
            // If not in progress but within throttle time, use last result
            PreyLogger("infoDevice - Throttled: using cached result from recent call")
            onCompletion(true) // Assume success for throttled calls
            return
        }
        
        // If there's already a request in progress, queue this callback
        if isInfoDeviceInProgress {
            PreyLogger("infoDevice - Request in progress: adding callback to pending queue")
            pendingInfoDeviceCallbacks.append(onCompletion)
            return
        }
        
        // Mark as in progress and update timestamps
        isInfoDeviceInProgress = true
        lastInfoDeviceCallTime = now
        
        // Generate a unique request ID for tracking retries
        let requestId = UUID().uuidString
        
        // Initialize retry count for this request ID
        infoDeviceRetryCount[requestId] = 0
        
        // Call the actual implementation with retry tracking
        infoDeviceWithRetry(requestId: requestId) { isSuccess in
            // Mark as no longer in progress
            isInfoDeviceInProgress = false
            
            // Call the original completion handler
            onCompletion(isSuccess)
            
            // Call all pending callbacks
            let callbacks = pendingInfoDeviceCallbacks
            pendingInfoDeviceCallbacks.removeAll()
            
            for callback in callbacks {
                callback(isSuccess)
            }
            
            if !callbacks.isEmpty {
                PreyLogger("infoDevice - Completed with \(callbacks.count) pending callbacks")
            }
        }
    }
    
    private class func infoDeviceWithRetry(requestId: String, onCompletion:@escaping (_ isSuccess: Bool) -> Void) {
        guard let username = PreyConfig.sharedInstance.userApiKey else {
            PreyLogger("Error infoDevice - No API key available")
            onCompletion(false)
            return
        }
        
        // Get current retry count
        let currentRetryCount = infoDeviceRetryCount[requestId] ?? 0
        
        // Check if we've exceeded max retries
        if currentRetryCount >= maxRetryAttempts {
            PreyLogger("infoDevice - Max retry attempts (\(maxRetryAttempts)) reached for request \(requestId)")
            // Clean up the retry counter
            infoDeviceRetryCount.removeValue(forKey: requestId)
            onCompletion(false)
            return
        }
        
        // Increment retry count
        infoDeviceRetryCount[requestId] = currentRetryCount + 1
        
        PreyLogger("infoDevice - Starting request (attempt \(currentRetryCount + 1)/\(maxRetryAttempts + 1)) with ID: \(requestId)")
        
        PreyHTTPClient.sharedInstance.userRegisterToPrey(
            username, 
            password: "x", 
            params: nil, 
            messageId: nil, 
            httpMethod: Method.GET.rawValue, 
            endPoint: infoEndpoint, 
            onCompletion: PreyHTTPResponse.checkResponse(
                RequestType.infoDevice, 
                preyAction: nil,  
                onCompletion: { (isSuccess: Bool) in
                    PreyLogger("infoDevice - Request \(requestId) completed with success: \(isSuccess)")
                    
                    if isSuccess {
                        // Clean up the retry counter on success
                        infoDeviceRetryCount.removeValue(forKey: requestId)
                        onCompletion(true)
                    } else if currentRetryCount < maxRetryAttempts {
                        // If not successful and under retry limit, retry after a delay
                        PreyLogger("infoDevice - Will retry request \(requestId) after delay")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            infoDeviceWithRetry(requestId: requestId, onCompletion: onCompletion)
                        }
                    } else {
                        // If we've reached the retry limit, give up
                        PreyLogger("infoDevice - Failed after \(currentRetryCount + 1) attempts for request \(requestId)")
                        infoDeviceRetryCount.removeValue(forKey: requestId)
                        onCompletion(false)
                    }
                }
            )
        )
    }
}
