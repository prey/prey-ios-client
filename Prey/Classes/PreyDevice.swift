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

    // Device identity
    var name: String?
    var type: String?
    var vendor: String?
    var os: String?
    var version: String?
    var macAddress: String?
    var uuid: String?
    var machineIdentifier: String?

    // Dynamic hardware info (obtained at runtime, no hardcoded lists)
    var cpuCores: String?
    var ramSize: String?

    // MARK: Init

    init() {
        // Device identity
        name              = UIDevice.current.name
        type              = IS_IPAD ? "Tablet" : "Phone"
        os                = "iOS"
        vendor            = "Apple"
        version           = UIDevice.current.systemVersion
        uuid              = UIDevice.current.identifierForVendor?.uuidString
        macAddress        = "02:00:00:00:00:00"
        machineIdentifier = UIDevice.current.machineIdentifier

        // Dynamic hardware info
        cpuCores             = UIDevice.current.cpuCores
        ramSize              = UIDevice.current.ramSize

        // logDeviceInfo()
    }

    // MARK: Debug

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
        PreyLogger("─────────────────────────")
    }

    // MARK: API

    class func addDeviceWith(_ onCompletion: @escaping (_ isSuccess: Bool) -> Void) {

        let device = PreyDevice()

        let hardwareInfo: [String: String] = [
            "uuid"         : device.uuid!,
            "serial_number": device.uuid!,
            "cpu_cores"    : device.cpuCores!,
            "ram_size"     : device.ramSize!]

        let params: [String: Any] = [
            "name"                : device.name!,
            "device_type"         : device.type!,
            "os_version"          : device.version!,
            "vendor_name"         : device.vendor!,
            "machine_id"          : device.machineIdentifier!,
            "os"                  : device.os!,
            "physical_address"    : device.macAddress!,
            "hardware_attributes" : hardwareInfo]

        guard let username = PreyConfig.sharedInstance.userApiKey else {
            displayErrorAlert("Error user ID".localized, titleMessage: "Couldn't add your device".localized)
            onCompletion(false)
            return
        }

        PreyHTTPClient.sharedInstance.sendDataToPrey(
            username, password: "x", params: params, messageId: nil,
            httpMethod: Method.POST.rawValue, endPoint: devicesEndpoint,
            onCompletion: PreyHTTPResponse.checkResponse(RequestType.addDevice, preyAction: nil, onCompletion: onCompletion))
    }

    class func renameDevice(_ newName: String, onCompletion: @escaping (_ isSuccess: Bool) -> Void) {

        let params: [String: Any] = [
            "name" : "device_renamed",
            "info" : ["new_name": newName]]

        guard let username = PreyConfig.sharedInstance.userApiKey else {
            PreyLogger("Error renameDevice")
            return
        }

        PreyHTTPClient.sharedInstance.sendDataToPrey(
            username, password: "x", params: params, messageId: nil,
            httpMethod: Method.POST.rawValue, endPoint: eventsDeviceEndpoint,
            onCompletion: PreyHTTPResponse.checkResponse(RequestType.signUp, preyAction: nil, onCompletion: onCompletion))
    }

    class func infoDevice(_ onCompletion: @escaping (_ isSuccess: Bool) -> Void) {

        guard let username = PreyConfig.sharedInstance.userApiKey else {
            PreyLogger("Error infoDevice - No API key available")
            onCompletion(false)
            return
        }

        PreyNetworkRetry.sendDataWithBackoff(
            username: username, password: "x", params: nil, messageId: nil,
            httpMethod: Method.GET.rawValue, endPoint: infoEndpoint,
            tag: "infoDevice", maxAttempts: 5, nonRetryStatusCodes: [401]
        ) { success in
            onCompletion(success)
        }
    }
}
