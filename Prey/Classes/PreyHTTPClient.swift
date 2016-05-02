//
//  PreyHTTPClient.swift
//  Prey
//
//  Created by Javier Cala Uribe on 2/12/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit

class PreyHTTPClient {
    
    // MARK: Properties
    
    static let sharedInstance = PreyHTTPClient()
    private init() {
    }
    
    // Define UserAgent
    var userAgent : String {
        let systemVersion = UIDevice.currentDevice().systemVersion
        let appVersion    = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as! String
        return "Prey/\(appVersion) (iOS \(systemVersion))"
    }

    // Define NSURLSessionConfiguration
    func getSessionConfig(authString: String) -> NSURLSessionConfiguration {
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.HTTPAdditionalHeaders = ["User-Agent" : userAgent, "Content-Type" : "application/json", "Authorization" : authString]
        return sessionConfig
    }

    // Encode Authorization for HTTP Header
    func encodeAuthorization(authString: String) -> String {
        let userAuthorizationData   = authString.dataUsingEncoding(NSUTF8StringEncoding)
        let encodedCredential       = userAuthorizationData!.base64EncodedStringWithOptions([])
        return "Basic \(encodedCredential)"
    }
    
    // Define CompletionHandler
    func getCompletionHandler(withCompletion:(dataRequest: NSData?, responseRequest: NSURLResponse?, error: NSError?) -> Void) -> (NSData?, NSURLResponse?, NSError?) -> Void {

        let completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void = { (data, response, error) in
            withCompletion(dataRequest:data, responseRequest:response, error:error)
        }
        return completionHandler
    }

    
    // MARK: Requests to Prey API
    
    // SignUp/LogIn User to Control Panel
    func userRegisterToPrey(username: String, password: String, params: [String: AnyObject]?, httpMethod: String, endPoint: String, onCompletion:(dataRequest: NSData?, responseRequest:NSURLResponse?, error:NSError?)->Void) {
        
        // Encode username and pwd
        let userAuthorization = encodeAuthorization(NSString(format:"%@:%@", username, password) as String)
        
        // Set session Config
        let sessionConfig   = getSessionConfig(userAuthorization)
        let session         = NSURLSession(configuration: sessionConfig)
        
        // Set Endpoint
        let requestURL      = NSURL(string: URLControlPanel.stringByAppendingString(endPoint))
        let request         = NSMutableURLRequest(URL:requestURL!)
        
        // Set params
        if params != nil  {
            do {
                request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(params!, options:NSJSONWritingOptions.PrettyPrinted)
            } catch let error as NSError{
                print("params error: \(error.localizedDescription)")
            }
        }

        request.HTTPMethod  = httpMethod
        
        // Prepare Request to Send
        let task = session.dataTaskWithRequest(request, completionHandler:getCompletionHandler(onCompletion))
        
        // Send Request
        task.resume()
    }
}