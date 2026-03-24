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
    var vendor: String?
    var os: String?
    var version: String?
    var macAddress: String?
    var uuid: String?
    var cpuCores: String?
    var ramSize: String?
    var machineIdentifier: String?
    // Dynamic hardware info (no hardcoded lists needed)
    var storageCapacity: String?     // Total storage in GB
    var screenSize: String?          // Screen size in points (WxH)
    var screenScale: String?         // Screen scale factor
    var thermalState: String?        // Current thermal state
    var activeProcessorCount: String? // Active processor count

    // MARK: Functions

    // Init function
    init() {
        name        = UIDevice.current.name
        type        = (IS_IPAD) ? "Tablet" : "Phone"
        os          = "iOS"
        vendor      = "Apple"
        version     = UIDevice.current.systemVersion
        uuid        = UIDevice.current.identifierForVendor?.uuidString
        macAddress  = "02:00:00:00:00:00" // iOS default
        ramSize     = UIDevice.current.ramSize
        cpuCores    = UIDevice.current.cpuCores
        machineIdentifier = UIDevice.current.machineIdentifier

        // Dynamic hardware info
        storageCapacity = PreyDevice.getTotalStorageGB()
        screenSize = PreyDevice.getScreenSize()
        screenScale = PreyDevice.getScreenScale()
        thermalState = PreyDevice.getThermalState()
        activeProcessorCount = String(ProcessInfo.processInfo.activeProcessorCount)

        // logDeviceInfo()
    }

    func logDeviceInfo() {
        PreyLogger("──── PreyDevice Info ────")
        PreyLogger("  name:              \(name ?? "nil")")
        PreyLogger("  type:              \(type ?? "nil")")
        PreyLogger("  os:                \(os ?? "nil") \(version ?? "")")
        PreyLogger("  vendor:            \(vendor ?? "nil")")
        PreyLogger("  machineIdentifier: \(machineIdentifier ?? "nil")")
        PreyLogger("  uuid:              \(uuid ?? "nil")")
        PreyLogger("  macAddress:        \(macAddress ?? "nil")")
        PreyLogger("  cpuCores:          \(cpuCores ?? "nil")")
        PreyLogger("  ramSize:           \(ramSize ?? "nil") MB")
        PreyLogger("  storageCapacity:   \(storageCapacity ?? "nil") GB")
        PreyLogger("  screenSize:        \(screenSize ?? "nil")")
        PreyLogger("  screenScale:       \(screenScale ?? "nil")")
        PreyLogger("  thermalState:      \(thermalState ?? "nil")")
        PreyLogger("  activeProcessors:  \(activeProcessorCount ?? "nil")")
        PreyLogger("─────────────────────────")
    }

    // MARK: Dynamic hardware helpers

    private static func getTotalStorageGB() -> String {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        if let values = try? url.resourceValues(forKeys: [.volumeTotalCapacityKey]),
           let totalBytes = values.volumeTotalCapacity {
            let gb = totalBytes / 1_073_741_824
            return String(gb)
        }
        return "0"
    }

    private static func getScreenSize() -> String {
        let bounds = UIScreen.main.bounds
        return "\(Int(bounds.width))x\(Int(bounds.height))"
    }

    private static func getScreenScale() -> String {
        return String(format: "%.1f", UIScreen.main.scale)
    }

    private static func getThermalState() -> String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal:  return "nominal"
        case .fair:     return "fair"
        case .serious:  return "serious"
        case .critical: return "critical"
        @unknown default: return "unknown"
        }
    }
    
    // Add new device to Panel Prey
    class func addDeviceWith(_ onCompletion:@escaping (_ isSuccess: Bool) -> Void) {
        
        let preyDevice = PreyDevice()
        
        let hardwareInfo : [String:String] = [
            "uuid"         : preyDevice.uuid!,
            "serial_number": preyDevice.uuid!,
            "cpu_cores"    : preyDevice.cpuCores!,
            "ram_size"     : preyDevice.ramSize!]

        let params:[String:Any] = [
            "name"                              : preyDevice.name!,
            "device_type"                       : preyDevice.type!,
            "os_version"                        : preyDevice.version!,
            "vendor_name"                       : preyDevice.vendor!,
            "machine_id"                        : preyDevice.machineIdentifier!,
            "os"                                : preyDevice.os!,
            "physical_address"                  : preyDevice.macAddress!,
            "hardware_attributes"               : hardwareInfo]
            // TODO: Send dynamic hardware info when backend is ready
            // "storage_capacity"               : preyDevice.storageCapacity!,
            // "screen_size"                    : preyDevice.screenSize!,
            // "screen_scale"                   : preyDevice.screenScale!,
            // "active_processor_count"         : preyDevice.activeProcessorCount!,
        
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
