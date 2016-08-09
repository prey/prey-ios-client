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
    
    // Encoding Character
    struct EncodingCharacters {
        static let CRLF = "\r\n"
    }

    // Define UserAgent
    var userAgent : String {
        let systemVersion = UIDevice.currentDevice().systemVersion
        let appVersion    = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as! String
        return "Prey/\(appVersion) (iOS \(systemVersion))"
    }

    // Define NSURLSessionConfiguration
    func getSessionConfig(authString: String, messageId: String?) -> NSURLSessionConfiguration {
        
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        var additionalHeader :[NSObject : AnyObject] = ["User-Agent" : userAgent, "Content-Type" : "application/json", "Authorization" : authString]
        
        // Check if exist MessageId for action group
        if let msg = messageId {
            additionalHeader["X-Prey-State"]            = "processed"
            additionalHeader["X-Prey-Device-Id"]        = PreyConfig.sharedInstance.deviceKey!
            additionalHeader["X-Prey-Correlation-Id"]   = msg
        }
        
        sessionConfig.HTTPAdditionalHeaders = additionalHeader
        
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
    
    // Send Report Data to Control Panel
    func sendDataReportToPrey(username: String, password: String, params:NSMutableDictionary, images:NSMutableDictionary?, messageId msgId:String?, httpMethod: String, endPoint: String, onCompletion:(dataRequest: NSData?, responseRequest:NSURLResponse?, error:NSError?)->Void) {
        
        // Encode username and pwd
        let userAuthorization = encodeAuthorization(NSString(format:"%@:%@", username, password) as String)
        
        // Set session Config
        let sessionConfig   = getSessionConfig(userAuthorization, messageId:msgId)
        let session         = NSURLSession(configuration: sessionConfig)
        
        // Set Endpoint
        let requestURL      = NSURL(string:URLControlPanel.stringByAppendingString(endPoint))
        let request         = NSMutableURLRequest(URL:requestURL!)

        // HTTP Header boundary
        let boundary = String(format: "prey.boundary-%08x%08x", arc4random(), arc4random())
        
        // Define the multipart request type
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Set bodyRequest for HTTPBody
        let bodyRequest = NSMutableData()
        
        // Set params on request
        for (key, value) in params {
            
            bodyRequest.appendString("--\(boundary)\(EncodingCharacters.CRLF)")
            bodyRequest.appendString("Content-Disposition:form-data; name=\"\(key)\"\(EncodingCharacters.CRLF)\(EncodingCharacters.CRLF)")
            bodyRequest.appendString("\(value)")
            bodyRequest.appendString(EncodingCharacters.CRLF)
        }
        
        // Set type to images
        let mimetype = "image/png"
        
        // Set images on request
        for (key, value) in images! {
            
            bodyRequest.appendString("--\(boundary)\(EncodingCharacters.CRLF)")
            bodyRequest.appendString("Content-Disposition:form-data; name=\"\(key)\"; filename=\"\(key).jpg\"\(EncodingCharacters.CRLF)")
            bodyRequest.appendString("Content-Type: \(mimetype)\(EncodingCharacters.CRLF)\(EncodingCharacters.CRLF)")
            bodyRequest.appendData(UIImagePNGRepresentation(value as! UIImage)!)
            bodyRequest.appendString(EncodingCharacters.CRLF)
        }
        
        // End HTTPBody
        bodyRequest.appendString("--\(boundary)--\(EncodingCharacters.CRLF)")
        
        request.HTTPBody    = bodyRequest
        request.HTTPMethod  = httpMethod
        
        // Prepare Request to Send
        let task = session.dataTaskWithRequest(request, completionHandler:getCompletionHandler(onCompletion))
        
        // Send Request
        task.resume()
    }
    
    // SignUp/LogIn User to Control Panel
    func userRegisterToPrey(username: String, password: String, params: [String: AnyObject]?, messageId msgId:String?, httpMethod: String, endPoint: String, onCompletion:(dataRequest: NSData?, responseRequest:NSURLResponse?, error:NSError?)->Void) {
        
        // Encode username and pwd
        let userAuthorization = encodeAuthorization(NSString(format:"%@:%@", username, password) as String)
        
        // Set session Config
        let sessionConfig   = getSessionConfig(userAuthorization, messageId:msgId)
        let session         = NSURLSession(configuration: sessionConfig)
        
        // Set Endpoint
        let requestURL      = NSURL(string: URLControlPanel.stringByAppendingString(endPoint))
        let request         = NSMutableURLRequest(URL:requestURL!)
        
        // Set params
        if params != nil  {
            do {
                request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(params!, options:NSJSONWritingOptions.PrettyPrinted)
            } catch let error as NSError{
                PreyLogger("params error: \(error.localizedDescription)")
            }
        }

        request.HTTPMethod  = httpMethod
        
        // Prepare Request to Send
        let task = session.dataTaskWithRequest(request, completionHandler:getCompletionHandler(onCompletion))
        
        // Send Request
        task.resume()
    }
}