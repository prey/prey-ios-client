import UserNotifications
import CoreLocation
import Prey
import Firebase

class PreyLocationPushServiceExtension: UNNotificationServiceExtension, CLLocationPushServiceExtension {
    
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        FirebaseApp.configure()
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
    }
    
    func didReceiveLocationPushPayload(_ payload: [String : Any], completion: @escaping (CLLocation?) -> Void) {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestLocation()
    }
}

extension PreyLocationPushServiceExtension: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        
        // Send location to Prey server
        let params:[String: Any] = [
            kLocation.lng.rawValue: location.coordinate.longitude,
            kLocation.lat.rawValue: location.coordinate.latitude,
            kLocation.alt.rawValue: location.altitude,
            kLocation.accuracy.rawValue: location.horizontalAccuracy,
            kLocation.method.rawValue: "native_push"
        ]
        
        let locParam:[String: Any] = [
            kAction.location.rawValue: params,
            kDataLocation.skip_toast.rawValue: true
        ]
        
        PreyHTTPClient.sharedInstance.userRegisterToPrey(
            PreyConfig.sharedInstance.userApiKey ?? "",
            password: "x",
            params: locParam,
            messageId: nil,
            httpMethod: Method.POST.rawValue,
            endPoint: dataDeviceEndpoint,
            onCompletion: PreyHTTPResponse.checkResponse(RequestType.dataSend, preyAction: nil) { success in
                PreyLogger("Location Push Send: \(success)")
            })
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        PreyLogger("Location Push Service Error: \(error.localizedDescription)")
    }
}
