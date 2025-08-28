import Foundation

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

