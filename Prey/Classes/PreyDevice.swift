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
    fileprivate init() {
        name        = UIDevice.current.name
        type        = (IS_IPAD) ? "Tablet" : "Phone"
        os          = "iOS"
        vendor      = "Apple"
        model       = UIDevice.current.deviceModel
        version     = UIDevice.current.systemVersion
        uuid        = UIDevice.current.identifierForVendor?.uuidString
        macAddress  = "02:00:00:00:00:00" // iOS default
        ramSize     = UIDevice.current.ramSize
        cpuModel    = UIDevice.current.hwModel
        cpuSpeed    = UIDevice.current.cpuSpeed
        cpuCores    = UIDevice.current.cpuCores
    }
    
    // Add new device to Panel Prey
    class func addDeviceWith(_ onCompletion:@escaping (_ isSuccess: Bool) -> Void) {
        
        let preyDevice = PreyDevice()
        
        let params:[String: String] = [
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
        
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:params, messageId:nil, httpMethod:Method.POST.rawValue, endPoint:devicesEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.addDevice, onCompletion:onCompletion))
        } else {
            let titleMsg = "Couldn't add your device".localized
            let alertMsg = "Error".localized
            displayErrorAlert(alertMsg, titleMessage:titleMsg)
            onCompletion(false)
        }
    }    
}
