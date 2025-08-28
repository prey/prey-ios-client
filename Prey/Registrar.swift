//
//  Registrar.swift
//  Prey
//
//  Created by Pato Jofre on 28/08/2025.
//  Copyright © 2025 Prey, Inc. All rights reserved.
//

import Foundation
import UIKit

class NotificationTokenRegistrar {
    private static let suiteName = "group.com.prey.ios"
    private static let tokenKey = "APNSTokenHex"

    // Persist APNs token early
    static func store(tokenHex: String) {
        if let suite = UserDefaults(suiteName: suiteName) {
            suite.set(tokenHex, forKey: tokenKey)
            suite.synchronize()
            PreyLogger("📣 TOKEN REGISTER: stored APNs token for later registration")
        }
    }

    // Send token if API key is available
    static func sendIfPossible() {
        guard let suite = UserDefaults(suiteName: suiteName),
              let tokenHex = suite.string(forKey: tokenKey) else {
            return
        }
        guard let username = PreyConfig.sharedInstance.userApiKey else {
            return
        }

        // Rebuild device info payload similar to original registration
        let preyDevice = PreyDevice()
        let firmwareInfo: [String: String] = [
            "model_name": preyDevice.model ?? "",
            "vendor_name": preyDevice.vendor ?? "",
        ]
        let processorInfo: [String: String] = [
            "speed": preyDevice.cpuSpeed ?? "",
            "cores": preyDevice.cpuCores ?? "",
            "model": preyDevice.cpuModel ?? "",
        ]
        let specs: [String: Any] = [
            "processor_info": processorInfo,
            "firmware_info": firmwareInfo,
        ]
        let params: [String: Any] = [
            "notification_id": tokenHex,
            "specs": specs,
            "device_name": UIDevice.current.name
        ]

        PreyNetworkRetry.sendDataWithBackoff(
            username: username,
            password: "x",
            params: params,
            messageId: nil,
            httpMethod: Method.POST.rawValue,
            endPoint: dataDeviceEndpoint,
            tag: "TOKEN REGISTER",
            maxAttempts: 5,
            nonRetryStatusCodes: [401]
        ) { success in
            if success {
                PreyLogger("📣 TOKEN REGISTER: ✅ Successfully registered APNs token (deferred)")
            } else {
                PreyLogger("📣 TOKEN REGISTER: ❌ Failed to register APNs token (final)")
            }
        }
    }
}


class LocationPushRegistrar {
    private static let suiteName = "group.com.prey.ios"
    private static let tokenKey = "LocationPushToken"

    // Persist token early; available to app and extension
    static func store(tokenHex: String) {
        if let suite = UserDefaults(suiteName: suiteName) {
            suite.set(tokenHex, forKey: tokenKey)
            suite.synchronize()
            PreyLogger("📣 LOCATION-PUSH: stored token for later registration")
        }
    }

    // Send token if both token and API key are available
    static func sendIfPossible() {
        guard let suite = UserDefaults(suiteName: suiteName),
              let tokenHex = suite.string(forKey: tokenKey) else {
            return
        }
        guard let apiKey = PreyConfig.sharedInstance.userApiKey else {
            return
        }
        let params: [String: Any] = [
            "notification_id_extra": tokenHex
        ]
        PreyNetworkRetry.sendDataWithBackoff(
            username: apiKey,
            password: "x",
            params: params,
            messageId: nil,
            httpMethod: Method.POST.rawValue,
            endPoint: dataDeviceEndpoint,
            tag: "LOCATION-PUSH REGISTER",
            maxAttempts: 5,
            nonRetryStatusCodes: [401]
        ) { success in
            if success {
                PreyLogger("📣 LOCATION-PUSH REGISTER: ✅ Token registered after auth")
            } else {
                PreyLogger("📣 LOCATION-PUSH REGISTER: ❌ Failed to register token after auth")
            }
        }
    }
}

