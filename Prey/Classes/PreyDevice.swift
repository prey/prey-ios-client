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
        name = UIDevice.current.name
        type = IS_IPAD ? "Tablet" : "Phone"
        os = "iOS"
        vendor = "Apple"
        version = UIDevice.current.systemVersion
        uuid = UIDevice.current.identifierForVendor?.uuidString
        macAddress = "02:00:00:00:00:00"
        machineIdentifier = UIDevice.current.machineIdentifier

        // Dynamic hardware info
        cpuCores = UIDevice.current.cpuCores
        ramSize = UIDevice.current.ramSize

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
            "uuid": device.uuid!,
            "serial_number": device.uuid!,
            "cpu_cores": device.cpuCores!,
            "ram_size": device.ramSize!
        ]

        let params: [String: Any] = [
            "name": device.name!,
            "device_type": device.type!,
            "os_version": device.version!,
            "vendor_name": device.vendor!,
            "machine_id": device.machineIdentifier!,
            "os": device.os!,
            "physical_address": device.macAddress!,
            "hardware_attributes": hardwareInfo
        ]

        guard let username = PreyConfig.sharedInstance.userApiKey else {
            displayErrorAlert("Error user ID".localized, titleMessage: "Couldn't add your device".localized)
            onCompletion(false)
            return
        }

        PreyHTTPClient.sharedInstance.sendDataToPrey(
            username, password: "x", params: params, messageId: nil,
            httpMethod: Method.POST.rawValue, endPoint: devicesEndpoint,
            onCompletion: PreyHTTPResponse.checkResponse(RequestType.addDevice, preyAction: nil, onCompletion: onCompletion)
        )
    }

    class func renameDevice(_ newName: String, onCompletion: @escaping (_ isSuccess: Bool) -> Void) {
        guard let username = PreyConfig.sharedInstance.userApiKey else {
            PreyLogger("Error renameDevice - No API key available")
            onCompletion(false)
            return
        }

        guard let httpBody = try? JSONSerialization.data(withJSONObject: ["name": newName], options: []) else {
            PreyLogger("Error renameDevice - Failed to encode body")
            onCompletion(false)
            return
        }

        let endPoint = actionsDeviceEndpoint
        let auth = PreyHTTPClient.sharedInstance.encodeAuthorization("\(username):x")
        let userAgent = PreyHTTPClient.sharedInstance.userAgent
        let deviceKey = PreyConfig.sharedInstance.deviceKey

        func buildRequest(baseURL: String) -> URLRequest? {
            guard let url = URL(string: baseURL + "/api/v2" + endPoint) else { return nil }
            var request = URLRequest(url: url)
            request.httpMethod = Method.PUT.rawValue
            request.timeoutInterval = 3.0
            request.httpBody = httpBody
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(auth, forHTTPHeaderField: "Authorization")
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
            if let deviceKey = deviceKey {
                request.setValue(deviceKey, forHTTPHeaderField: "X-Prey-Device-Id")
            }
            return request
        }

        func send(_ request: URLRequest, completion: @escaping (Bool, Error?) -> Void) {
            URLSession.shared.dataTask(with: request) { _, response, error in
                if let error = error {
                    completion(false, error)
                    return
                }
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                completion((200 ... 299).contains(code), nil)
            }.resume()
        }

        guard let solidRequest = buildRequest(baseURL: URLSolid) else {
            onCompletion(false)
            return
        }

        send(solidRequest) { success, error in
            if error == nil {
                DispatchQueue.main.async { onCompletion(success) }
                return
            }
            PreyLogger("renameDevice URLSolid failed (\(error?.localizedDescription ?? "unknown")) — falling back to URLPanel")
            guard let panelRequest = buildRequest(baseURL: URLPanel) else {
                DispatchQueue.main.async { onCompletion(false) }
                return
            }
            send(panelRequest) { fallbackSuccess, _ in
                DispatchQueue.main.async { onCompletion(fallbackSuccess) }
            }
        }
    }

    class func infoDevice(_ onCompletion: @escaping (_ isSuccess: Bool) -> Void) {
        guard let username = PreyConfig.sharedInstance.userApiKey else {
            PreyLogger("Error infoDevice - No API key available")
            onCompletion(false)
            return
        }

        PreyHTTPClient.sharedInstance.sendDataToPrey(
            username, password: "x", params: nil, messageId: nil,
            httpMethod: Method.GET.rawValue, endPoint: infoEndpoint,
            onCompletion: PreyHTTPResponse.checkResponse(RequestType.infoDevice, preyAction: nil, onCompletion: onCompletion)
        )
    }
}
