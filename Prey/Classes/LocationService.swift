import Foundation
import CoreLocation
import UIKit

// Centralized location service owning a single CLLocationManager
// Delivers updates to registered LocationDelegate observers
class LocationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationService()
    private override init() { super.init() }

    private let manager = CLLocationManager()
    private var delegates: [LocationDelegate] = []
    private(set) var lastLocation: CLLocation?

    // Optimized configuration for security/tracking app
    private let optimalDistanceFilter: CLLocationDistance = 10.0 // Más preciso para tracking de seguridad

    private var isStarted = false
    func isRunning() -> Bool { isStarted }

    // Watchdog anti-inactividad (solo background)
    private var watchdogTimer: DispatchSourceTimer?
    private var lastNudgeAt: Date?
    private var lastRestartAt: Date?
    private var restartWindowStart: Date?
    private var restartsInWindow: Int = 0
    private let inactivityThreshold: TimeInterval = 180 // 3 min sin updates
    private let postNudgeWait: TimeInterval = 120       // 2 min tras nudge antes de reiniciar
    private let restartCooldown: TimeInterval = 600     // 10 min entre reinicios
    private let restartWindow: TimeInterval = 3600      // ventana 1 hora
    private let maxRestartsPerHour: Int = 3

    // MARK: Public API
    func addDelegate(_ delegate: LocationDelegate) {
        if !delegates.contains(where: { $0 === delegate }) { delegates.append(delegate) }
    }

    func removeDelegate(_ delegate: LocationDelegate) {
        delegates.removeAll { $0 === delegate }
    }

    func getLastLocation() -> CLLocation? { lastLocation }

    func startBackgroundTracking() {
        configureIfNeeded()
        configureBatteryOptimizedSettings()
        manager.allowsBackgroundLocationUpdates = true
        manager.startMonitoringSignificantLocationChanges()
        manager.startUpdatingLocation()
        startWatchdogIfNeeded()
    }

    // Temporary high-accuracy foreground burst
    func startForegroundHighAccuracyBurst() {
        configureIfNeeded()
        configureBatteryOptimizedSettings()
        manager.allowsBackgroundLocationUpdates = true
        // Use single optimized configuration
        manager.startUpdatingLocation()
        // Foreground no necesita watchdog; se activará al volver a background
    }

    func requestOneShot(_ completion: @escaping (CLLocation?) -> Void) {
        configureIfNeeded()
        
        // Verificar permisos antes de proceder
        if !ensurePermissions() {
            completion(nil)
            return
        }
        
        // Use existing last if very recent
        if let last = lastLocation, abs(last.timestamp.timeIntervalSinceNow) < 10 {
            completion(last); return
        }
        // Use a one-shot requestLocation
        oneShotCompletion = completion
        manager.requestLocation()
    }

    // MARK: Internal
    private var oneShotCompletion: ((CLLocation?) -> Void)?

    private func configureIfNeeded() {
        guard !isStarted else { return }
        isStarted = true
        DispatchQueue.main.async {
            self.manager.requestAlwaysAuthorization()
        }
        manager.delegate = self
        // Configuración optimizada para app de seguridad/tracking
        manager.activityType = .other // Más versátil que otherNavigation
        manager.pausesLocationUpdatesAutomatically = false // Nunca pausar para seguridad
        manager.desiredAccuracy = kCLLocationAccuracyBest // Máxima precisión disponible
        manager.distanceFilter = optimalDistanceFilter // 10m para balance precisión/batería
        
        // Asegurar significant changes esté siempre activo como respaldo
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            manager.startMonitoringSignificantLocationChanges()
        }
    }

    // Removed adaptive parameters - using single optimized configuration

    private func configureBatteryOptimizedSettings() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        let isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        if batteryLevel < 0.10 || isLowPowerMode { // Solo con batería críticamente baja
            // Para app de seguridad, mantener funcionalidad incluso con batería baja
            manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            manager.distanceFilter = 20 // Aumentar threshold para ahorrar batería
            PreyLogger("LocationService: Critical battery mode - reduced accuracy to preserve tracking", level: .info)
        } else {
            // Configuración normal con máxima precisión
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.distanceFilter = optimalDistanceFilter
        }
    }
    
    private func ensurePermissions() -> Bool {
        let status = manager.authorizationStatus
        if status != .authorizedAlways && status != .authorizedWhenInUse {
            PreyLogger("Location permission lost: \(status.rawValue)", level: .error)
            return false
        }
        return true
    }

    // MARK: Watchdog anti-inactividad
    private func startWatchdogIfNeeded() {
        if watchdogTimer != nil { return }
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        timer.schedule(deadline: .now() + 60, repeating: 60, leeway: .seconds(10))
        timer.setEventHandler { [weak self] in
            self?.watchdogTick()
        }
        watchdogTimer = timer
        timer.resume()
    }

    private func watchdogTick() {
        // Solo en background
        var isBG = false
        DispatchQueue.main.sync { isBG = UIApplication.shared.applicationState == .background }
        if !isBG { return }

        // Condiciones de batería/ahorro
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        let lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        if batteryLevel >= 0 && batteryLevel < 0.20 { return }
        if lowPower { return }

        // Si hay update reciente, nada que hacer
        let now = Date()
        if let last = lastLocation, now.timeIntervalSince(last.timestamp) < inactivityThreshold { return }

        // Intento 1: nudge con requestLocation si no se ha hecho recientemente
        if let nudgeAt = lastNudgeAt {
            // Esperar ventana post-nudge antes de reiniciar si sigue sin datos
            if now.timeIntervalSince(nudgeAt) < postNudgeWait { return }
        } else {
            // Enviar nudge
            DispatchQueue.main.async { [weak self] in
                self?.manager.requestLocation()
            }
            lastNudgeAt = now
            PreyLogger("LocationService: Watchdog nudge (requestLocation)", level: .info)
            return
        }

        // Intento 2: reinicio controlado del manager con cooldown y límite por hora
        if let lastR = lastRestartAt, now.timeIntervalSince(lastR) < restartCooldown { return }
        if let windowStart = restartWindowStart {
            if now.timeIntervalSince(windowStart) >= restartWindow {
                restartWindowStart = now; restartsInWindow = 0
            }
        } else { restartWindowStart = now }
        guard restartsInWindow < maxRestartsPerHour else { return }

        restartsInWindow += 1
        lastRestartAt = now
        lastNudgeAt = nil // reset ciclo
        PreyLogger("LocationService: Watchdog restart (\(restartsInWindow)/\(maxRestartsPerHour) in window)", level: .info)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.manager.stopUpdatingLocation()
            // breve pausa y restart
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.configureBatteryOptimizedSettings()
                self.manager.startUpdatingLocation()
            }
        }
    }

    private func persistToAppGroup(_ location: CLLocation) {
        if let userDefaults = UserDefaults(suiteName: "group.com.prey.ios") {
            let dict: [String: Any] = [
                "lng": location.coordinate.longitude,
                "lat": location.coordinate.latitude,
                "alt": location.altitude,
                "accuracy": location.horizontalAccuracy,
                "method": "native",
                "timestamp": Date().timeIntervalSince1970
            ]
            userDefaults.set(dict, forKey: "lastLocation")
        }
    }

    // MARK: CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { oneShotCompletion?(nil); oneShotCompletion = nil; return }
        // Basic validation
        guard CLLocationCoordinate2DIsValid(loc.coordinate),
              !(loc.coordinate.latitude == 0 && loc.coordinate.longitude == 0) else { 
            PreyLogger("LocationService: Invalid coordinates received", level: .error)
            return 
        }
        
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        PreyLogger("LocationService: lat=\(loc.coordinate.latitude) lon=\(loc.coordinate.longitude) speed=\(loc.speed) acc=\(loc.horizontalAccuracy) battery=\(batteryLevel)", level: .info)
        
        lastLocation = loc
        persistToAppGroup(loc)
        // Deliver to observers
        for d in delegates { d.didReceiveLocationUpdate(loc) }
        // Fulfill one-shot if pending
        if let c = oneShotCompletion { oneShotCompletion = nil; c(loc) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let nsError = error as NSError
        PreyLogger("LocationService error: \(error.localizedDescription) domain=\(nsError.domain) code=\(nsError.code)", level: .error)
        
        // Reintentar en casos específicos
        if nsError.code == CLError.locationUnknown.rawValue {
            // Continuar intentando
            PreyLogger("LocationService: Location unknown, continuing to try...", level: .info)
            return
        } else if nsError.code == CLError.denied.rawValue {
            // Problema de permisos - notificar con ubicación vacía
            PreyLogger("LocationService: Permission denied, notifying delegates", level: .error)
            for d in delegates { d.didReceiveLocationUpdate(CLLocation()) }
        }
        
        if let c = oneShotCompletion { oneShotCompletion = nil; c(nil) }
    }
}
