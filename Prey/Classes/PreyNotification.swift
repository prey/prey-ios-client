//
//  PreyNotification.swift
//  Prey
//
//  Created by Javier Cala Uribe on 3/05/16.
//  Modified by Patricio Jofré on 04/08/2025.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

class PreyNotification {
    // MARK: Properties

    static let sharedInstance = PreyNotification()
    fileprivate init() {}

    // MARK: Functions

    /// Handle notification response
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        PreyLogger("Handling notification response: \(response.actionIdentifier) with userInfo: \(userInfo)")

        // Extract message from userInfo
        if let message = userInfo[kOptions.IDLOCAL.rawValue] as? String {
            PreyLogger("Show message from notification: \(message)")
        }

        // Reset badge count
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }

    /// Did Register Remote Notifications
    func didRegisterForRemoteNotificationsWithDeviceToken(_ deviceToken: Data) {
        let tokenAsString = deviceToken.reduce("") { $0 + String(format: "%02x", $1) }
        NotificationTokenRegistrar.store(tokenHex: tokenAsString)
        NotificationTokenRegistrar.sendIfPossible(source: "didRegisterForRemoteNotifications")
    }

    /// Did Receive Remote Notifications with improved completion handling
    func didReceiveRemoteNotifications(_ userInfo: [AnyHashable: Any], completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        PreyLogger("📣 PN PROCESSING: Starting to process remote notification")
        PreyLogger("📣 PN PAYLOAD: \(userInfo)")

        // Track whether we received any data to return appropriate completion result
        var receivedData = false

        // MDM enrollment push: handle silently, no user-facing notification needed.
        // Starts the local config server so the backend can push the MobileConfig.
        if let cmdPreyMDM = userInfo["preymdm"] as? NSDictionary {
            PreyLogger("📣 PN TYPE: preymdm payload detected")
            parsePayloadPreyMDMFromPushNotification(parameters: cmdPreyMDM)
            receivedData = true
        }

        if let cmdInstruction = userInfo["cmd"] as? NSArray {
            PreyLogger("📣 PN TYPE: cmd instruction payload detected with \(cmdInstruction.count) items")
            parsePayloadInfoFromPushNotification(instructionArray: cmdInstruction)
            receivedData = true
        }

        // Currently not being used
        // if let cmdArray = userInfo["instruction"] as? NSArray {
        // PreyLogger("📣 PN TYPE: instruction payload detected with \(cmdArray.count) items")
        // parsePayloadInfoFromPushNotification(instructionArray: cmdArray)
        // receivedData = true
        // }

        // APNS silent notification check (content-available = 1)
        if let aps = userInfo["aps"] as? [String: Any],
           let contentAvailable = aps["content-available"] as? Int, contentAvailable == 1 {
            PreyLogger("📣 PN TYPE: Silent notification detected with content-available=1")

            // Check for remote actions when receiving silent push notification
            checkRemoteActionsFromSilentPush { hasActions in
                if hasActions {
                    receivedData = true
                    PreyLogger("📣 PN ACTION: Remote actions retrieved and processed")
                } else {
                    PreyLogger("📣 PN ACTION: No remote actions found")
                }

                // Complete with result after async operation finishes
                let result = receivedData ? UIBackgroundFetchResult.newData : UIBackgroundFetchResult.noData
                PreyLogger("📣 PN COMPLETE: Finishing notification processing with result: \(result == .newData ? "newData" : "noData")")
                completionHandler(result)
            }
            // Don't set receivedData = true here, let the async callback handle it
        } else {
            PreyLogger("📣 PN CHECK: No content-available=1 found in aps payload")

            // Complete immediately if no silent notification
            let result = receivedData ? UIBackgroundFetchResult.newData : UIBackgroundFetchResult.noData
            PreyLogger("📣 PN COMPLETE: Finishing notification processing with result: \(result == .newData ? "newData" : "noData")")
            completionHandler(result)
        }
    }

    /// Validated payload for a preymdm enrollment push.
    struct PreyMDMPayload: Equatable {
        let token: String
        let accountId: Int
        let url: String
    }

    /// Persists a preymdm payload to the app-group suite so it survives across
    /// backgrounding, low-memory kills, and being opened from the home icon.
    /// Consumed (and cleared) by `consumePending()` on the next foreground.
    enum PendingMDMPayloadStore {
        private static let suiteName = "group.com.prey.ios"
        private static let key = "PendingPreyMDMPayload"

        static func save(_ payload: PreyMDMPayload) {
            guard let suite = UserDefaults(suiteName: suiteName) else { return }
            let dict: [String: Any] = [
                "token": payload.token,
                "account_id": payload.accountId,
                "url": payload.url
            ]
            suite.set(dict, forKey: key)
            suite.synchronize()
        }

        static func take() -> PreyMDMPayload? {
            guard let suite = UserDefaults(suiteName: suiteName),
                  let dict = suite.dictionary(forKey: key) else { return nil }
            suite.removeObject(forKey: key)
            suite.synchronize()
            return PreyNotification.parsePreyMDMPayload(dict as NSDictionary)
        }

        static func clear() {
            guard let suite = UserDefaults(suiteName: suiteName) else { return }
            suite.removeObject(forKey: key)
            suite.synchronize()
        }
    }

    /// Consume any preymdm payload persisted by an earlier push and start the
    /// enrollment server. Safe to call from `applicationDidBecomeActive`.
    func consumePendingMDMPayload() {
        guard let payload = PendingMDMPayloadStore.take() else { return }
        PreyLogger("📣 PN MDM: Consuming pending preymdm payload")
        PreyMobileConfig.sharedInstance.startService(
            authToken: payload.token,
            urlServer: payload.url,
            accountId: payload.accountId
        )
    }

    /// Pure validator for the preymdm push body. Returns nil if any required
    /// field is missing or of the wrong type. Kept static/pure so it can be
    /// unit-tested without starting the mobileconfig server.
    static func parsePreyMDMPayload(_ parameters: NSDictionary) -> PreyMDMPayload? {
        guard let token = parameters["token"] as? String, !token.isEmpty,
              let accountId = parameters["account_id"] as? Int,
              let url = parameters["url"] as? String, !url.isEmpty
        else {
            return nil
        }
        return PreyMDMPayload(token: token, accountId: accountId, url: url)
    }

    /// Decision for an incoming preymdm push.
    enum MDMDispatch: Equatable {
        /// App is `.active`; start the MobileConfig server now.
        case startImmediately
        /// App is not `.active`; payload has been persisted for
        /// `applicationDidBecomeActive` to consume.
        case deferUntilActive
    }

    /// Decide what to do with a freshly-parsed payload and update
    /// `PendingMDMPayloadStore` accordingly. Testable without touching
    /// UIApplication or the HTTP server:
    /// - Active: clear any stale pending payload so `didBecomeActive` can't
    ///   re-run the server a second time after the user returns from Safari.
    /// - Not active: persist so `didBecomeActive` picks it up later.
    static func dispatchForMDMPayload(_ payload: PreyMDMPayload, appIsActive: Bool) -> MDMDispatch {
        if appIsActive {
            PendingMDMPayloadStore.clear()
            return .startImmediately
        }
        PendingMDMPayloadStore.save(payload)
        return .deferUntilActive
    }

    /// Parse preymdm push.
    ///
    /// `PreyMobileConfig.start(data:)` calls `UIApplication.shared.open(url)`
    /// to bounce the user through Safari → Settings, which requires the app
    /// to be active. Calling it from a silent-push wakeup would half-start
    /// the HTTP server (taking port 8080) but never bring Safari forward,
    /// leaving the port held and blocking the next attempt. So in non-active
    /// states we just save the payload and let `applicationDidBecomeActive`
    /// consume it.
    func parsePayloadPreyMDMFromPushNotification(parameters: NSDictionary) {
        guard let payload = PreyNotification.parsePreyMDMPayload(parameters) else {
            PreyLogger("📣 PN MDM: Invalid preymdm payload, missing token/account_id/url")
            handlePushError("Invalid preymdm payload")
            return
        }

        switch PreyNotification.dispatchForMDMPayload(payload, appIsActive: appIsActive()) {
        case .deferUntilActive:
            PreyLogger("📣 PN MDM: App not active, deferring server start to applicationDidBecomeActive")
            return
        case .startImmediately:
            PreyMobileConfig.sharedInstance.startService(
                authToken: payload.token,
                urlServer: payload.url,
                accountId: payload.accountId
            )
        }
    }

    private func appIsActive() -> Bool {
        if Thread.isMainThread {
            return UIApplication.shared.applicationState == .active
        }
        return DispatchQueue.main.sync { UIApplication.shared.applicationState == .active }
    }

    /// Parse payload info on push notification
    func parsePayloadInfoFromPushNotification(instructionArray: NSArray) {
        PreyLogger("📣 PN PARSE: Starting to parse instruction array with \(instructionArray.count) items")

        do {
            let data = try JSONSerialization.data(withJSONObject: instructionArray, options: JSONSerialization.WritingOptions.prettyPrinted)
            if let json = String(data: data, encoding: String.Encoding.utf8) {
                PreyLogger("📣 PN PARSE: Instruction JSON: \(json)")

                // Log the first action if available for debugging
                if let firstItem = instructionArray.firstObject as? [String: Any] {
                    PreyLogger("📣 PN PARSE: First instruction item: \(firstItem)")
                }

                PreyLogger("📣 PN PARSE: Sending to parseActionsFromPanel")
                PreyModule.sharedInstance.parseActionsFromPanel(json)
                PreyLogger("📣 PN PARSE: Completed parsing actions from panel")
            } else {
                PreyLogger("📣 PN PARSE ERROR: Could not convert JSON data to string")
            }
        } catch let error as NSError {
            PreyLogger("📣 PN PARSE ERROR: JSON serialization failed: \(error.localizedDescription)")
            handlePushError("Failed to parse instruction payload: \(error.localizedDescription)")
        }
    }

    /// Helper method for handling errors from push notifications
    func handlePushError(_ error: String) {
        PreyLogger("📣 PN ERROR: 🚨 \(error)")
    }

    /// Check for remote actions when receiving silent push notification
    private func checkRemoteActionsFromSilentPush(completion: @escaping (Bool) -> Void) {
        PreyLogger("📣 PN REMOTE: Starting remote action check from silent push")

        guard let username = PreyConfig.sharedInstance.userApiKey else {
            PreyLogger("📣 PN REMOTE: No API key available for remote action check")
            completion(false)
            return
        }

        // Use PreyHTTPResponse.checkResponse for actionsDevice endpoint
        PreyHTTPClient.sharedInstance.sendDataToPrey(
            username,
            password: "x",
            params: nil,
            messageId: nil,
            httpMethod: Method.GET.rawValue,
            endPoint: actionsDeviceEndpoint,
            onCompletion: PreyHTTPResponse.checkResponse(
                RequestType.actionDevice,
                preyAction: nil,
                onCompletion: { isSuccess in
                    PreyLogger("📣 PN REMOTE: Remote action check completed with success: \(isSuccess)")

                    if isSuccess {
                        // Check if any actions were added to the action array
                        let hasActions = !PreyModule.sharedInstance.actionArray.isEmpty
                        PreyLogger("📣 PN REMOTE: Found \(PreyModule.sharedInstance.actionArray.count) actions from remote check")

                        if hasActions {
                            // Run the actions that were retrieved
                            PreyModule.sharedInstance.runAction()
                        }

                        completion(hasActions)
                    } else {
                        PreyLogger("📣 PN REMOTE: Failed to retrieve remote actions")
                        completion(false)
                    }
                }
            )
        )
    }
}
