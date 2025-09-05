//
//  Registrar.swift
//  Prey
//
//  Created by Pato Jofre on 28/08/2025.
//  Copyright © 2025 Prey, Inc. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Shared Token Registration Validator
class TokenRegistrationValidator {
    private static let cacheDuration: TimeInterval = 3600.0 // 1 hour
    static func shouldSendToken(
        tokenHex: String,
        suite: UserDefaults,
        lastValueKey: String,
        lastSentKey: String,
        logPrefix: String
    ) -> Bool {
        if let lastToken = suite.string(forKey: lastValueKey),
           let lastSent = suite.object(forKey: lastSentKey) as? Date {
            let elapsed = Date().timeIntervalSince(lastSent)
            if lastToken == tokenHex && elapsed < cacheDuration { return false }
        }
        return true
    }
    static func recordSuccessfulSend(
        tokenHex: String,
        suite: UserDefaults,
        lastValueKey: String,
        lastSentKey: String
    ) {
        suite.set(Date(), forKey: lastSentKey)
        suite.set(tokenHex, forKey: lastValueKey)
        suite.synchronize()
    }
}

class NotificationTokenRegistrar {
    private static let suiteName = "group.com.prey.ios"
    private static let tokenKey = "APNSTokenHex"
    private static let lastSentKey = "APNSTokenLastSent"
    private static let lastValueKey = "APNSTokenLastValue"
    static func store(tokenHex: String) {
        if let suite = UserDefaults(suiteName: suiteName) {
            suite.set(tokenHex, forKey: tokenKey)
            suite.synchronize()
            PreyLoggerInfo("TOKEN REGISTER: stored APNs token \(String(tokenHex))")
            if PreyConfig.sharedInstance.userApiKey != nil { sendIfPossible() }
        }
    }
    static func sendIfPossible(source: String = "unspecified") {
        guard let suite = UserDefaults(suiteName: suiteName), let tokenHex = suite.string(forKey: tokenKey) else { return }
        guard let username = PreyConfig.sharedInstance.userApiKey else { return }
        PreyLogger("TOKEN REGISTER: invoked (source=\(source))")
        guard TokenRegistrationValidator.shouldSendToken(
            tokenHex: tokenHex,
            suite: suite,
            lastValueKey: lastValueKey,
            lastSentKey: lastSentKey,
            logPrefix: "TOKEN REGISTER"
        ) else { return }
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
            tag: "TOKEN REGISTER(\(source))",
            maxAttempts: 5,
            nonRetryStatusCodes: [401]
        ) { success in
            if success {
                PreyLoggerInfo("TOKEN REGISTER: ✅ Successfully registered APNs token (deferred)")
                TokenRegistrationValidator.recordSuccessfulSend(
                    tokenHex: tokenHex,
                    suite: suite,
                    lastValueKey: lastValueKey,
                    lastSentKey: lastSentKey
                )
            } else {
                PreyLoggerError("TOKEN REGISTER: ❌ Failed to register APNs token (final)")
            }
        }
    }
}

class LocationPushRegistrar {
    private static let suiteName = "group.com.prey.ios"
    private static let tokenKey = "LocationPushToken"
    private static let lastSentKey = "LocationPushTokenLastSent"
    private static let lastValueKey = "LocationPushTokenLastValue"
    static func store(tokenHex: String) {
        if let suite = UserDefaults(suiteName: suiteName) {
            suite.set(tokenHex, forKey: tokenKey)
            suite.synchronize()
            PreyLogger("LOCATION-PUSH: stored token \(String(tokenHex))")
            if PreyConfig.sharedInstance.userApiKey != nil { sendIfPossible(source: "store") }
        }
    }
    static func sendIfPossible(source: String = "unspecified") {
        guard let suite = UserDefaults(suiteName: suiteName), let tokenHex = suite.string(forKey: tokenKey) else { return }
        guard let apiKey = PreyConfig.sharedInstance.userApiKey else { return }
        PreyLogger("LOCATION-PUSH REGISTER: invoked (source=\(source))")
        guard TokenRegistrationValidator.shouldSendToken(
            tokenHex: tokenHex,
            suite: suite,
            lastValueKey: lastValueKey,
            lastSentKey: lastSentKey,
            logPrefix: "LOCATION-PUSH REGISTER"
        ) else { return }
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
            tag: "LOCATION-PUSH REGISTER(\(source))",
            maxAttempts: 5,
            nonRetryStatusCodes: [401]
        ) { success in
            if success {
                PreyLoggerInfo("LOCATION-PUSH REGISTER: ✅ Token registered after auth")
                TokenRegistrationValidator.recordSuccessfulSend(
                    tokenHex: tokenHex,
                    suite: suite,
                    lastValueKey: lastValueKey,
                    lastSentKey: lastSentKey
                )
            } else {
                PreyLoggerError("LOCATION-PUSH REGISTER: ❌ Failed to register token after auth")
            }
        }
    }
}

