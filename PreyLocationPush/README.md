Location Push Service Extension (Client-side skeleton)

What this adds
- PreyLocationPush/Info.plist: Extension Info with principal class.
- PreyLocationPush/PreyLocationPush.entitlements: App Group + APS (dev).
- PreyLocationPush/LocationPushService.swift: Implements a short, high-accuracy fix window and writes the fix to the shared app group (group.com.prey.ios).

How to wire it in Xcode
1) Add Target:
   - File > New > Target… > Location Push Service Extension.
   - Name: PreyLocationPush. Bundle ID suffix e.g. com.prey.ios.locationpush.
   - Replace the generated Info.plist with PreyLocationPush/Info.plist (principal class is $(PRODUCT_MODULE_NAME).LocationPushService).
2) Capabilities (PreyLocationPush target):
   - Push Notifications: ON.
   - App Groups: add group.com.prey.ios.
3) Link frameworks: CoreLocation.
4) Deployment: iOS 13+.

Server requirements (summary)
- Send APNs with the HTTP/2 header `apns-push-type: location` to the app’s device token.
- Use the app’s bundle identifier as the APNs topic (verify per Apple docs for your setup).
- On receipt, iOS launches this extension even if the app is not running; the extension acquires a one-shot fix and stores it in the shared container.

Main app integration
- AppDelegate already reads `UserDefaults(suiteName: "group.com.prey.ios").lastLocation` and can post it to the server.
- Optionally, you can also post directly from the extension (see `uploadLocation` stub).

Notes
- The extension stops location immediately after the first acceptable fix or a 20s timeout to conserve battery.
- If you need to tune accuracy/timeout, adjust `desiredAccuracy`, `distanceFilter`, and the timeout window in `LocationPushService`.
