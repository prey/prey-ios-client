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
    private static let lastSentKey = "APNSTokenLastSent"
    private static let lastValueKey = "APNSTokenLastValue"

    // Persist APNs token early
    static func store(tokenHex: String) {
        if let suite = UserDefaults(suiteName: suiteName) {
            suite.set(tokenHex, forKey: tokenKey)
            suite.synchronize()
            PreyLoggerInfo("📣 TOKEN REGISTER: stored APNs token for later registration")
            // If API key already exists (upgrade path), attempt immediate send
            if PreyConfig.sharedInstance.userApiKey != nil {
                sendIfPossible()
            }
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

        // Avoid re-sending if the same token was successfully sent < 5 minutes ago
        if let lastToken = suite.string(forKey: lastValueKey),
           let lastSent = suite.object(forKey: lastSentKey) as? Date {
            let elapsed = Date().timeIntervalSince(lastSent)
            if lastToken == tokenHex && elapsed < 5 * 60 {
                PreyLoggerInfo("📣 TOKEN REGISTER: Skipping send (last success \(Int(elapsed))s ago)")
                return
            }
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
                PreyLoggerInfo("📣 TOKEN REGISTER: ✅ Successfully registered APNs token (deferred)")
                // Record last successful send
                suite.set(Date(), forKey: lastSentKey)
                suite.set(tokenHex, forKey: lastValueKey)
                suite.synchronize()
            } else {
                PreyLoggerError("📣 TOKEN REGISTER: ❌ Failed to register APNs token (final)")
            }
        }
    }
}


class LocationPushRegistrar {
    private static let suiteName = "group.com.prey.ios"
    private static let tokenKey = "LocationPushToken"
    private static let lastSentKey = "LocationPushTokenLastSent"
    private static let lastValueKey = "LocationPushTokenLastValue"

    // Persist token early; available to app and extension
    static func store(tokenHex: String) {
        if let suite = UserDefaults(suiteName: suiteName) {
            suite.set(tokenHex, forKey: tokenKey)
            suite.synchronize()
            PreyLogger("📣 LOCATION-PUSH: stored token for later registration")
            // If API key already exists (upgrade path), attempt immediate send
            if PreyConfig.sharedInstance.userApiKey != nil {
                sendIfPossible()
            }
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

        // Avoid re-sending if the same token was successfully sent < 5 minutes ago
        if let lastToken = suite.string(forKey: lastValueKey),
           let lastSent = suite.object(forKey: lastSentKey) as? Date {
            let elapsed = Date().timeIntervalSince(lastSent)
            if lastToken == tokenHex && elapsed < 5 * 60 {
                PreyLoggerInfo("📣 LOCATION-PUSH REGISTER: Skipping send (last success \(Int(elapsed))s ago)")
                return
            }
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
                PreyLoggerInfo("📣 LOCATION-PUSH REGISTER: ✅ Token registered after auth")
                // Record last successful send
                suite.set(Date(), forKey: lastSentKey)
                suite.set(tokenHex, forKey: lastValueKey)
                suite.synchronize()
            } else {
                PreyLoggerError("📣 LOCATION-PUSH REGISTER: ❌ Failed to register token after auth")
            }
        }
    }
}
