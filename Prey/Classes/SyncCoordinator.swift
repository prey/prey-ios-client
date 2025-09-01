import Foundation

// Centralized sync entry points for key lifecycle events
enum SyncReason: String {
    case postLogin = "postLogin"
    case postSignup = "postSignup"
    case appUpgrade = "appUpgrade"
}

class SyncCoordinator {
    static func performPostAuthOrUpgradeSync(reason: SyncReason) {
        // Ensure we have an API key
        guard PreyConfig.sharedInstance.isRegistered, PreyConfig.sharedInstance.userApiKey != nil else { return }

        // 1) Register tokens if needed (APNs + Location Push)
        NotificationTokenRegistrar.sendIfPossible(source: reason.rawValue)
        LocationPushRegistrar.sendIfPossible(source: reason.rawValue)

        // 2) Kick off device status check (throttled, with backoff inside)
        PreyModule.sharedInstance.requestStatusDevice(context: "SyncCoordinator-\(reason.rawValue)") { _ in }

        // 3) Refresh device info (GET, idempotent with backoff)
        PreyDevice.infoDevice { isSuccess in
            PreyLogger("SyncCoordinator(\(reason.rawValue)) - infoDevice: \(isSuccess)")
        }
    }
}

