import UserNotifications
import CoreLocation

class PreyLocationPushServiceExtension: UNNotificationServiceExtension, CLLocationPushServiceExtension {
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
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
            "lng": location.coordinate.longitude,
            "lat": location.coordinate.latitude,
            "alt": location.altitude,
            "accuracy": location.horizontalAccuracy,
            "method": "native_push"
        ]
        
        PreyHTTPClient.sharedInstance.sendLocation(params)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        PreyLogger("Location Push Service Error: \(error.localizedDescription)")
    }
}
