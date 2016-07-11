//
//  PreyProtocol.swift
//  Prey
//
//  Created by Javier Cala Uribe on 30/06/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation

// Prey actions definitions
enum kAction: String {
    case LOCATION   = "location"
    case REPORT     = "report"
    case ALARM      = "alarm"
    case ALERT      = "alert"
    case GEOFENCING = "geofencing"
    case DETACH     = "detach"
    case CAMOUFLAGE = "camouflage"
}

// Prey status definitions
enum kStatus: String {
    case STARTED    = "started"
    case STOPPED    = "stopped"
}

// Prey command definitions
enum kCommand: String {
    case START      = "start"
    case STOP       = "stop"
    case GET        = "get"
}

// Prey alert params
enum kAlert: String {
    case MESSAGE    = "alert_message"
    case IDLOCAL    = "url"
}

// Prey location params
enum kLocation: String {
    case LONGITURE  = "lng"
    case LATITUDE   = "lat"
    case ALTITUDE   = "alt"
    case ACCURACY   = "accuracy"
    case METHOD     = "method"
}

// Prey location params
enum kReportLocation: String {
    case LONGITURE  = "geo[lng]"
    case LATITUDE   = "geo[lat]"
    case ALTITUDE   = "geo[alt]"
    case ACCURACY   = "geo[accuracy]"
    case METHOD     = "geo[method]"
}

// Prey /Data Endpoint struct
enum kData: String {
    case STATUS     = "status"
    case TARGET     = "target"
    case COMMAND    = "command"
    case REASON     = "reason"
}

// Definition of URLs
#if DEBUG
    public let URLControlPanel      : String = "https://control.preyhq.com/api/v2"
    public let URLForgotPanel       : String = "https://panel.preyhq.com/forgot?embeddable=true"
    public let URLSessionPanel      : String = "https://panel.preyhq.com/session"
#else
    public let URLControlPanel      : String = "https://solid.preyproject.com/api/v2"
    public let URLForgotPanel       : String = "https://panel.preyproject.com/forgot?embeddable=true"
    public let URLSessionPanel      : String = "https://panel.preyproject.com/session"
#endif

public let URLHelpPrey              : String = "http://help.preyproject.com"

public let URLTermsPrey             : String = "http://www.preyproject.com/terms"

public let URLPrivacyPrey           : String = "http://www.preyproject.com/privacy"

// Endpoint for Token
public let tokenEndpoint            : String = "/get_token.json"

// Endpoint for LogIn
public let logInEndpoint            : String = "/profile.json"

// Endpoint for SignUp
public let signUpEndpoint           : String = "/signup.json"

// Endpoint for Add Devices
public let devicesEndpoint          : String = "/devices.json"

// Endpoint for Device Data
public let dataDeviceEndpoint       : String = NSString(format:"/devices/%@/data",(PreyConfig.sharedInstance.deviceKey!)) as String

// Endpoint for Report Data
public let reportDataDeviceEndpoint : String = NSString(format:"/devices/%@/reports",(PreyConfig.sharedInstance.deviceKey!)) as String

// Endpoint for Response Data
public let responseDeviceEndpoint   : String = NSString(format:"/devices/%@/response",(PreyConfig.sharedInstance.deviceKey!)) as String

// Endpoint for Events Data
public let eventsDeviceEndpoint     : String = NSString(format:"/devices/%@/events",(PreyConfig.sharedInstance.deviceKey!)) as String

// Endpoint for Geofencing Data
public let geofencingEndpoint       : String = NSString(format:"/devices/%@/geofencing.json",(PreyConfig.sharedInstance.deviceKey!)) as String

// Endpoint for Device Actions
public let actionsDeviceEndpoint    : String = NSString(format:"/devices/%@",(PreyConfig.sharedInstance.deviceKey!)) as String


// Http method definitions
public enum Method: String {
    case GET    = "GET"
    case POST   = "POST"
    case DELETE = "DELETE"
}

