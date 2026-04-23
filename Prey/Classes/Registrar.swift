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
        logPrefix _: String
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
    static let suiteName = "group.com.prey.ios"
    static let tokenKey = "APNSTokenHex"
    static let lastSentKey = "APNSTokenLastSent"
    static let lastValueKey = "APNSTokenLastValue"

    /// Drop only the dedup cache so a re-attach re-sends the token.
    /// The APNs token itself is preserved because iOS won't re-deliver it
    /// within the same app session — removing it strands the re-attach flow
    /// with nothing to POST to the backend.
    static func clearCache() {
        guard let suite = UserDefaults(suiteName: suiteName) else { return }
        suite.removeObject(forKey: lastSentKey)
        suite.removeObject(forKey: lastValueKey)
        suite.synchronize()
    }

    static func store(tokenHex: String) {
        if let suite = UserDefaults(suiteName: suiteName) {
            suite.set(tokenHex, forKey: tokenKey)
            suite.synchronize()
            PreyLoggerInfo("TOKEN REGISTER: stored APNs token \(String(tokenHex))")
            if PreyConfig.sharedInstance.userApiKey != nil { sendIfPossible(source: "store") }
        }
    }

    static func sendIfPossible(source: String = "unspecified") {
        guard let suite = UserDefaults(suiteName: suiteName) else {
            PreyLogger("TOKEN REGISTER: skip (source=\(source)) — missing app-group suite")
            return
        }
        guard let tokenHex = suite.string(forKey: tokenKey) else {
            PreyLogger("TOKEN REGISTER: skip (source=\(source)) — no APNs token stored yet")
            return
        }
        guard let username = PreyConfig.sharedInstance.userApiKey else {
            PreyLogger("TOKEN REGISTER: skip (source=\(source)) — no userApiKey yet")
            return
        }
        guard PreyConfig.sharedInstance.isRegistered, PreyConfig.sharedInstance.deviceKey != nil else {
            PreyLogger("TOKEN REGISTER: skip (source=\(source)) — device not registered yet")
            return
        }
        PreyLogger("TOKEN REGISTER: invoked (source=\(source))")
        guard TokenRegistrationValidator.shouldSendToken(
            tokenHex: tokenHex,
            suite: suite,
            lastValueKey: lastValueKey,
            lastSentKey: lastSentKey,
            logPrefix: "TOKEN REGISTER"
        ) else {
            PreyLogger("TOKEN REGISTER: skip (source=\(source)) — dedup cache hit")
            return
        }
        let preyDevice = PreyDevice()
        let firmwareInfo: [String: String] = [
            "vendor_name": preyDevice.vendor ?? "",
            "machine_id": UIDevice.current.machineIdentifier
        ]
        let processorInfo: [String: String] = [
            "cores": preyDevice.cpuCores ?? ""
        ]
        let specs: [String: Any] = [
            "processor_info": processorInfo,
            "firmware_info": firmwareInfo
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
    static let suiteName = "group.com.prey.ios"
    static let tokenKey = "LocationPushToken"
    static let lastSentKey = "LocationPushTokenLastSent"
    static let lastValueKey = "LocationPushTokenLastValue"

    /// Drop only the dedup cache so a re-attach re-sends the token.
    /// The token itself is preserved — see `NotificationTokenRegistrar.clearCache()`.
    static func clearCache() {
        guard let suite = UserDefaults(suiteName: suiteName) else { return }
        suite.removeObject(forKey: lastSentKey)
        suite.removeObject(forKey: lastValueKey)
        suite.synchronize()
    }

    static func store(tokenHex: String) {
        if let suite = UserDefaults(suiteName: suiteName) {
            suite.set(tokenHex, forKey: tokenKey)
            suite.synchronize()
            PreyLogger("LOCATION-PUSH: stored token \(String(tokenHex))")
            if PreyConfig.sharedInstance.userApiKey != nil { sendIfPossible(source: "store") }
        }
    }

    static func sendIfPossible(source: String = "unspecified") {
        guard let suite = UserDefaults(suiteName: suiteName) else {
            PreyLogger("LOCATION-PUSH REGISTER: skip (source=\(source)) — missing app-group suite")
            return
        }
        guard let tokenHex = suite.string(forKey: tokenKey) else {
            PreyLogger("LOCATION-PUSH REGISTER: skip (source=\(source)) — no token stored yet")
            return
        }
        guard let apiKey = PreyConfig.sharedInstance.userApiKey else {
            PreyLogger("LOCATION-PUSH REGISTER: skip (source=\(source)) — no userApiKey yet")
            return
        }
        guard PreyConfig.sharedInstance.isRegistered, PreyConfig.sharedInstance.deviceKey != nil else {
            PreyLogger("LOCATION-PUSH REGISTER: skip (source=\(source)) — device not registered yet")
            return
        }
        PreyLogger("LOCATION-PUSH REGISTER: invoked (source=\(source))")
        guard TokenRegistrationValidator.shouldSendToken(
            tokenHex: tokenHex,
            suite: suite,
            lastValueKey: lastValueKey,
            lastSentKey: lastSentKey,
            logPrefix: "LOCATION-PUSH REGISTER"
        ) else {
            PreyLogger("LOCATION-PUSH REGISTER: skip (source=\(source)) — dedup cache hit")
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
