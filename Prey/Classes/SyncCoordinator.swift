import Foundation
import UIKit

/// Centralized sync entry points for key lifecycle events
enum SyncReason: String {
    case postLogin
    case appUpgrade
}

class SyncCoordinator {
    /// Override point for tests so the Location Push monitoring start
    /// can be observed without touching UIApplication or CLLocationManager.
    /// Production path resolves the AppDelegate on the main thread.
    static var startLocationPushMonitoring: () -> Void = {
        DispatchQueue.main.async {
            (UIApplication.shared.delegate as? AppDelegate)?.startMonitoringLocationPushes()
        }
    }

    static func performPostAuthOrUpgradeSync(reason: SyncReason) {
        // Ensure we have an API key
        guard PreyConfig.sharedInstance.isRegistered, PreyConfig.sharedInstance.userApiKey != nil else { return }

        // 1) Register tokens if needed (APNs + Location Push)
        NotificationTokenRegistrar.sendIfPossible(source: reason.rawValue)
        LocationPushRegistrar.sendIfPossible(source: reason.rawValue)

        // 2) Kick off LocationPush monitoring now that we have a deviceKey.
        // On a fresh attach the earlier `startMonitoringLocationPushes()`
        // calls at launch were gated out (isRegistered was false), so the
        // registration token was never requested — meaning the sendIfPossible
        // above would have skipped with "no token stored yet". This call
        // makes iOS issue the token; its arrival handler persists it and
        // POSTs it to the backend.
        startLocationPushMonitoring()

        // 3) Kick off device status check (throttled, with backoff inside)
        PreyModule.sharedInstance.requestStatusDevice(context: "SyncCoordinator-\(reason.rawValue)") { _ in }

        // 4) Refresh device info (GET, idempotent with backoff)
        PreyDevice.infoDevice { isSuccess in
            PreyLogger("SyncCoordinator(\(reason.rawValue)) - infoDevice: \(isSuccess)")
        }

        // 5) Prompt user to upgrade to Always location if only WhenInUse
        DeviceAuth.sharedInstance.promptUpgradeToAlwaysIfNeeded()
    }
}
