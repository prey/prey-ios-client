//
//  PreyDevice.swift
//  Prey
//
//  Created by Javier Cala Uribe on 15/03/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
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
    private init() {
        name        = UIDevice.currentDevice().name
        type        = (IS_IPAD) ? "Tablet" : "Phone"
        os          = "iOS"
        vendor      = "Apple"
        model       = UIDevice.currentDevice().deviceModel
        version     = UIDevice.currentDevice().systemVersion
        uuid        = UIDevice.currentDevice().identifierForVendor?.UUIDString
        macAddress  = "02:00:00:00:00:00" // iOS default
        ramSize     = UIDevice.currentDevice().ramSize
        cpuModel    = UIDevice.currentDevice().hwModel
        cpuSpeed    = UIDevice.currentDevice().cpuSpeed
        cpuCores    = UIDevice.currentDevice().cpuCores
    }
    
    // Add new device to Panel Prey
    class func addDeviceWith(onCompletion:(isSuccess: Bool) -> Void) {
        
        let preyDevice = PreyDevice()
        
        let params:[String: AnyObject] = [
            "name"                              : preyDevice.name!,
            "device_type"                       : preyDevice.type!,
            "os_version"                        : preyDevice.version!,
            "model_name"                        : preyDevice.model!,
            "vendor_name"                       : preyDevice.vendor!,
            "os"                                : preyDevice.os!,
            "physical_address"                  : preyDevice.macAddress!,
            "hardware_attributes[uuid]"         : preyDevice.uuid!,
            "hardware_attributes[serial_number]": preyDevice.uuid!,
            "hardware_attributes[cpu_model]"    : preyDevice.cpuModel!,
            "hardware_attributes[cpu_speed]"    : preyDevice.cpuSpeed!,
            "hardware_attributes[cpu_cores]"    : preyDevice.cpuCores!,
            "hardware_attributes[ram_size]"     : preyDevice.ramSize!]
        
        // If userApiKey is empty select userEmail
        let username = (PreyConfig.sharedInstance.userApiKey != nil) ? PreyConfig.sharedInstance.userApiKey : ""
        
        PreyHTTPClient.sharedInstance.userRegisterToPrey(username!, password:"x", params:params, httpMethod:Method.POST.rawValue, endPoint:devicesEndpoint, onCompletion:({(data, response, error) in
            
            // Check error with NSURLSession request
            guard error == nil else {
                
                let alertMessage = (error?.localizedRecoverySuggestion != nil) ? error?.localizedRecoverySuggestion : error?.localizedDescription
                displayErrorAlert(alertMessage!.localized, titleMessage:"Couldn't add your device".localized)
                onCompletion(isSuccess:false)
                
                return
            }
            
            print("PreyDevice: data:\(data) \nresponse:\(response) \nerror:\(error)")
            
            let httpURLResponse = response as! NSHTTPURLResponse
            
            switch httpURLResponse.statusCode {
                
            // === Success
            case 201:
                let jsonObject: NSDictionary
                
                do {
                    jsonObject = try NSJSONSerialization.JSONObjectWithData(data!, options:NSJSONReadingOptions.MutableContainers) as! NSDictionary
                    
                    let deviceKeyStr = jsonObject.objectForKey("key") as! String
                    PreyConfig.sharedInstance.devicekey = deviceKeyStr
                    
                    onCompletion(isSuccess:true)
                    
                } catch let error as NSError{
                    print("json error: \(error.localizedDescription)")
                }
                
            // === Client Error
            case 302, 403:
                let titleMsg = "Couldn't add your device".localized
                let alertMsg = "It seems you've reached your limit for devices on the Control Panel. Try removing this device from your account if you had already added.".localized
                displayErrorAlert(alertMsg, titleMessage:titleMsg)
                onCompletion(isSuccess:false)
                
            // === Error
            default:
                let titleMsg = "Couldn't add your device".localized
                let alertMsg = "Error".localized
                displayErrorAlert(alertMsg, titleMessage:titleMsg)
                onCompletion(isSuccess:false)
            }
        }))
    }
}