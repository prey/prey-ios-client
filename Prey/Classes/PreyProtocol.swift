//
//  PreyProtocol.swift
//  Prey
//
//  Created by Javier Cala Uribe on 30/06/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation

/// Prey Instructions struct
enum kInstruction: String {
    case target, command, options, cmd
}

/// Prey actions definitions
enum kAction: String {
    case location, detach, list_permissions, logretrieval
}

/// Prey options definitions
enum kOptions: String {
    case messageID, device_job_id, trigger_id
    case MESSAGE = "alert_message"
    case IDLOCAL = "url"
}

/// Prey status definitions
enum kStatus: String {
    case started, stopped
}

/// Prey command definitions
enum kCommand: String {
    case start, stop, get, start_location_aware
}

/// Prey location params
enum kLocation: String {
    case lng, lat, alt, accuracy, method
}

enum kPermission: String {
    case location, location_background, camera, photos, background_app_refresh, notification
}

enum kEvent: String {
    case name, info
}

/// Prey location data
enum kDataLocation: String {
    case skip_toast
}

/// Prey /Data Endpoint struct
enum kData: String {
    case status, target, command, reason
}

// Definition of URLs
#if DEBUG
    public let URLControlPanel: String = "https://solid.preyhq.com/api/v2"
    public let URLForgotPanel: String = "https://panel.preyhq.com/forgot?embeddable=true"
    public let URLSessionPanel: String = "https://panel.preyhq.com/login_mobile"
    public let fileRetrievalEndpoint: String = "https://solid.preyhq.com/upload/upload"
    public let logRetrievalEndpoint: String = "https://solid.preyhq.com/upload/log"
    public let URLCloseAccount: String = "https://panel.preyhq.com/settings/account"
    public let exceptionsUrl: String = "https://exceptions-stg.preyhq.com"
#else
    public let URLControlPanel: String = "https://solid.preyproject.com/api/v2"
    public let URLForgotPanel: String = "https://panel.preyproject.com/forgot?embeddable=true"
    public let URLSessionPanel: String = "https://panel.preyproject.com/login_mobile"
    public let fileRetrievalEndpoint: String = "https://solid.preyproject.com/upload/upload"
    public let logRetrievalEndpoint: String = "https://solid.preyproject.com/upload/log"
    public let URLCloseAccount: String = "https://panel.preyproject.com/settings/account"
    public let exceptionsUrl: String = "https://exceptions.preyproject.com"
#endif

public let URLHelpPrey: String = "http://help.preyproject.com"

public let URLTermsPrey: String = "http://preyproject.com/terms"

public let URLPrivacyPrey: String = "http://preyproject.com/privacy"

/// Endpoint for Token
public let tokenEndpoint: String = "/get_token.json"

/// Endpoint for LogIn
public let logInEndpoint: String = "/profile.json"

/// Endpoint for Add Devices
public let devicesEndpoint: String = "/devices.json"

/// Endpoint for Device Status
public var statusDeviceEndpoint: String {
    return String(format: "/devices/%@/status.json", PreyConfig.sharedInstance.getDeviceKey())
}

/// Endpoint for Device Location Aware
public var locationAwareEndpoint: String {
    return String(format: "/devices/%@/location.json", PreyConfig.sharedInstance.getDeviceKey())
}

/// Endpoint for Device Data
public var dataDeviceEndpoint: String {
    return String(format: "/devices/%@/data", PreyConfig.sharedInstance.getDeviceKey())
}

/// Endpoint for Response Data
public var responseDeviceEndpoint: String {
    return String(format: "/devices/%@/response", PreyConfig.sharedInstance.getDeviceKey())
}

/// Endpoint for Events Data
public var eventsDeviceEndpoint: String {
    return String(format: "/devices/%@/events", PreyConfig.sharedInstance.getDeviceKey())
}

/// Endpoint for Device Actions
public var actionsDeviceEndpoint: String {
    return String(format: "/devices/%@.json", PreyConfig.sharedInstance.getDeviceKey())
}

/// Endpoint for Delete Device
public var deleteDeviceEndpoint: String {
    return String(format: "/devices/%@", PreyConfig.sharedInstance.getDeviceKey())
}

public var infoEndpoint: String {
    return String(format: "/devices/%@/info.json", PreyConfig.sharedInstance.getDeviceKey())
}

/// Http method definitions
public enum Method: String {
    case GET, POST, PUT, DELETE
}
