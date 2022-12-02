//
//  PreyProtocol.swift
//  Prey
//
//  Created by Javier Cala Uribe on 30/06/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation

// Prey Instructions struct
enum kInstruction: String {
    case target, command, options, cmd
}

// Prey actions definitions
enum kAction: String {
    case location, report, alarm, alert, geofencing, detach, camouflage, ping, tree, fileretrieval, triggers, user_activated
}

// Prey options definitions
enum kOptions: String {
    case exclude, interval, messageID, device_job_id, path, user, name, size, file_id, port, trigger_id
    case MESSAGE    = "alert_message" // Alert options
    case IDLOCAL    = "url"           // Alert options
}

// Prey options exclude definitions
enum kExclude: String {
    case picture, screenshot, access_points_list, location
}

// Prey status definitions
enum kStatus: String {
    case started, stopped
}

// Prey command definitions
enum kCommand: String {
    case start, stop, get, start_location_aware
}

// Prey location params
enum kLocation: String {
    case lng, lat, alt, accuracy, method
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
    case status, target, command, reason
}

// Prey trigger type:repeat_time
enum kInfoRepeatTime: String {
    case days_of_week, hour, minute, second, until
}

// Prey trigger type:range_time
enum kInfoRangetTime: String {
    case from, until
}

// Prey trigger type:repeat_range_time
enum kInfoRepeatRangetTime: String {
    case days_of_week, hour_from, hour_until, until
}

// Definition of URLs
#if DEBUG
    public let URLControlPanel      : String = "https://control.preyhq.com/api/v2"
    public let URLForgotPanel       : String = "https://panel.preyhq.com/forgot?embeddable=true"
    public let URLSessionPanel      : String = "https://panel.preyhq.com/login_mobile"
    public let fileRetrievalEndpoint: String = "https://panel.preyhq.com/upload/upload"
    public let URLCloseAccount      : String = "https://panel.preyhq.com/settings/account"
#else
    public let URLControlPanel      : String = "https://solid.preyproject.com/api/v2"
    public let URLForgotPanel       : String = "https://panel.preyproject.com/forgot?embeddable=true"
    public let URLSessionPanel      : String = "https://panel.preyproject.com/login_mobile"
    public let fileRetrievalEndpoint: String = "https://solid.preyproject.com/upload/upload"
    public let URLCloseAccount      : String = "https://panel.preyproject.com/settings/account"
#endif

public let URLHelpPrey              : String = "http://help.preyproject.com"

public let URLTermsPrey             : String = "http://preyproject.com/terms"

public let URLPrivacyPrey           : String = "http://preyproject.com/privacy"

// Endpoint for Token
public let tokenEndpoint            : String = "/get_token.json"

// Endpoint for LogIn
public let logInEndpoint            : String = "/profile.json"

// Endpoint for SignUp
public let signUpEndpoint           : String = "/signup.json"

// Endpoint for Add Devices
public let devicesEndpoint          : String = "/devices.json"

// Endpoint for Email Validation
public let emailValidationEndpoint  : String = "/users/verify.json"

// Endpoint for Resend Email Validation
public let resendEmailValidationEndpoint : String = "/users/verify_email.json"

// Endpoint for Subscriptions Receipt
public let subscriptionEndpoint     : String = "/subscriptions/receipt"

// Endpoint for Device Status
public var statusDeviceEndpoint : String {return String(format:"/devices/%@/status.json",(PreyConfig.sharedInstance.getDeviceKey()))}

// Endpoint for Device Location Aware
public var locationAwareEndpoint : String {return String(format:"/devices/%@/location.json",(PreyConfig.sharedInstance.getDeviceKey()))}

// Endpoint for Device Data
public var dataDeviceEndpoint : String {return String(format:"/devices/%@/data",(PreyConfig.sharedInstance.getDeviceKey()))}

// Endpoint for Report Data
public var reportDataDeviceEndpoint : String {return String(format:"/devices/%@/reports",(PreyConfig.sharedInstance.getDeviceKey()))}

// Endpoint for Response Data
public var responseDeviceEndpoint : String {return String(format:"/devices/%@/response",(PreyConfig.sharedInstance.getDeviceKey()))}

// Endpoint for Events Data
public var eventsDeviceEndpoint : String {return String(format:"/devices/%@/events",(PreyConfig.sharedInstance.getDeviceKey()))}

// Endpoint for Geofencing Data
public var geofencingEndpoint : String {return String(format:"/devices/%@/geofencing.json",(PreyConfig.sharedInstance.getDeviceKey()))}

// Endpoint for Trigger
public var triggerEndpoint : String {return String(format:"/devices/%@/triggers.json",(PreyConfig.sharedInstance.getDeviceKey()))}

// Endpoint for Device Actions
public var actionsDeviceEndpoint : String {return String(format:"/devices/%@.json",(PreyConfig.sharedInstance.getDeviceKey()))}

// Endpoint for Delete Device
public var deleteDeviceEndpoint : String {return String(format:"/devices/%@",(PreyConfig.sharedInstance.getDeviceKey()))}

public var infoEndpoint : String {return String(format:"/devices/%@/info.json",(PreyConfig.sharedInstance.getDeviceKey()))}

// Http method definitions
public enum Method: String {
    case GET, POST, PUT, DELETE
}

