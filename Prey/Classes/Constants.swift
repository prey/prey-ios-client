//
//  Constants.swift
//  Prey
//
//  Created by Javier Cala Uribe on 14/03/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit

@available(iOS, deprecated=1.0, message="I'm not deprecated, please ***FIXME**")
func FIXME()
{
}

// Definition of URLs
#if DEBUG
public let URLControlPanel: String = "https://control.preyhq.com/api/v2"
#else
public let URLControlPanel: String = "https://solid.preyproject.com/api/v2"
#endif

// Endpoint for Token
public let tokenEndpoint: String = "/get_token.json"

// Endpoint for LogIn
public let logInEndpoint: String = "/profile.json"

// Endpoint for SignUp
public let signUpEndpoint: String = "/signup.json"

// Endpoint for Add Devices
public let devicesEndpoint: String = "/devices.json"

// Endpoint for Device Data 
public let dataDeviceEndpoint: String = NSString(format:"/devices/%@/data",(PreyConfig.sharedInstance.deviceKey!)) as String

// Endpoint for Report Data
public let reportDataDeviceEndpoint: String = NSString(format:"/devices/%@/reports",(PreyConfig.sharedInstance.deviceKey!)) as String

// Endpoint for Response Data
public let responseDeviceEndpoint: String = NSString(format:"/devices/%@/response",(PreyConfig.sharedInstance.deviceKey!)) as String

// Endpoint for Events Data
public let eventsDeviceEndpoint: String = NSString(format:"/devices/%@/events",(PreyConfig.sharedInstance.deviceKey!)) as String

// Endpoint for Geofencing Data
public let geofencingEndpoint: String = NSString(format:"/devices/%@/geofencing.json",(PreyConfig.sharedInstance.deviceKey!)) as String

// Endpoint for Device Actions
public let actionsDeviceEndpoint: String = NSString(format:"/devices/%@.json",(PreyConfig.sharedInstance.deviceKey!)) as String


// Http method definitions
public enum Method: String {
    case GET  = "GET"
    case POST = "POST"
}

// Def type device
public let IS_IPAD: Bool = (UIDevice.currentDevice().userInterfaceIdiom != UIUserInterfaceIdiom.Phone)

// Number of Reload for Connection
public let reloadConnection: Int = 5

// Delay for Reload connection
public let delayTime: Double = 2

// Email RegExp
public let emailRegExp = "\\b([a-zA-Z0-9%_.+\\-]+)@([a-zA-Z0-9.\\-]+?\\.[a-zA-Z]{2,21})\\b"

// Validate email expression
public func isInvalidEmail(userEmail: String, withPattern: String) -> Bool {

    var isInvalid = true
    let regex: NSRegularExpression

    do {
        regex = try NSRegularExpression(pattern:withPattern, options:NSRegularExpressionOptions.CaseInsensitive)
        let textRange  = NSMakeRange(0, userEmail.characters.count)
        let matchRange = regex.rangeOfFirstMatchInString(userEmail, options:NSMatchingOptions.ReportProgress, range:textRange)
        
        if (matchRange.location != NSNotFound) {
            isInvalid = false
        }
    } catch let error as NSError {
        print("error RegEx: \(error.localizedDescription)")
    }

    return isInvalid
}


// Display error alert
public func displayErrorAlert(alertMessage: String, titleMessage:String) {
    /*
    let alertView : UIAlertView = UIAlertView(
    
    let alert = UIAlertController(title: "Alert", message: "Message", preferredStyle: UIAlertControllerStyle.Alert)
    alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.Default, handler: nil))
    //self.presentViewController(alert, animated: true, completion: nil)
    */
    //if #available(iOS 7.0, *) {}
    dispatch_async(dispatch_get_main_queue()) {
        let alert       = UIAlertView()
        alert.title     = titleMessage
        alert.message   = alertMessage
        alert.addButtonWithTitle("OK".localized)
        alert.show()
    }
}
