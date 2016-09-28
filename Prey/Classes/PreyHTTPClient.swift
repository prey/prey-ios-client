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
    fileprivate init() {
    }
    
    // Encoding Character
    struct EncodingCharacters {
        static let CRLF = "\r\n"
    }

    // Define UserAgent
    var userAgent : String {
        let systemVersion = UIDevice.current.systemVersion
        let appVersion    = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        return "Prey/\(appVersion) (iOS \(systemVersion))"
    }

    // Define NSURLSessionConfiguration
    func getSessionConfig(_ authString: String, messageId: String?) -> URLSessionConfiguration {
        
        let sessionConfig = URLSessionConfiguration.default
        
        var additionalHeader :[AnyHashable: Any] = ["User-Agent" : userAgent, "Content-Type" : "application/json", "Authorization" : authString]
        
        // Check if exist MessageId for action group
        if let msg = messageId {
            additionalHeader["X-Prey-State"]            = "PROCESSED"
            additionalHeader["X-Prey-Device-Id"]        = PreyConfig.sharedInstance.deviceKey
            additionalHeader["X-Prey-Correlation-Id"]   = msg
        }
        
        sessionConfig.httpAdditionalHeaders = additionalHeader
        
        return sessionConfig
    }

    // Encode Authorization for HTTP Header
    func encodeAuthorization(_ authString: String) -> String {
        guard let userAuthorizationData = authString.data(using: String.Encoding.utf8) else {
            return "Basic 3rr0r"
        }
        let encodedCredential = userAuthorizationData.base64EncodedString(options: [])
        return "Basic \(encodedCredential)"
    }
    
    
    // MARK: Requests to Prey API
    
    // Send Report Data to Control Panel
    func sendDataReportToPrey(_ username: String, password: String, params:NSMutableDictionary, images:NSMutableDictionary, messageId msgId:String?, httpMethod: String, endPoint: String, onCompletion:@escaping (_ dataRequest: Data?, _ responseRequest:URLResponse?, _ error:Error?)->Void) {
        
        // Encode username and pwd
        let userAuthorization = encodeAuthorization(NSString(format:"%@:%@", username, password) as String)
        
        // Set session Config
        let sessionConfig   = getSessionConfig(userAuthorization, messageId:msgId)
        let session         = URLSession(configuration: sessionConfig)
        
        // Set Endpoint
        guard let requestURL = URL(string:URLControlPanel + endPoint) else {
            return
        }
        var request  = URLRequest(url:requestURL)

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
        for (key, value) in images {
            
            guard let img = value as? UIImage else {
                return
            }
            
            if let imgData = UIImagePNGRepresentation(img) {
                bodyRequest.appendString("--\(boundary)\(EncodingCharacters.CRLF)")
                bodyRequest.appendString("Content-Disposition:form-data; name=\"\(key)\"; filename=\"\(key).jpg\"\(EncodingCharacters.CRLF)")
                bodyRequest.appendString("Content-Type: \(mimetype)\(EncodingCharacters.CRLF)\(EncodingCharacters.CRLF)")
                bodyRequest.append(imgData)
                bodyRequest.appendString(EncodingCharacters.CRLF)
            }
        }
        
        // End HTTPBody
        bodyRequest.appendString("--\(boundary)--\(EncodingCharacters.CRLF)")
        
        request.httpBody    = bodyRequest as Data
        request.httpMethod  = httpMethod
        
        // Prepare Request to Send
        let task = session.dataTask(with: request, completionHandler:onCompletion)
        
        // Send Request
        task.resume()
    }
    
    // SignUp/LogIn User to Control Panel
    func userRegisterToPrey(_ username: String, password: String, params: [String: Any]?, messageId msgId:String?, httpMethod: String, endPoint: String, onCompletion:@escaping (_ dataRequest: Data?, _ responseRequest:URLResponse?, _ error:Error?)->Void) {
        
        // Encode username and pwd
        let userAuthorization = encodeAuthorization(NSString(format:"%@:%@", username, password) as String)
        
        // Set session Config
        let sessionConfig   = getSessionConfig(userAuthorization, messageId:msgId)
        let session         = URLSession(configuration: sessionConfig)
        
        // Set Endpoint
        guard let requestURL = URL(string: URLControlPanel + endPoint) else {
            return
        }

        var request = URLRequest(url:requestURL)
        
        // Set params
        if let parameters = params {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options:JSONSerialization.WritingOptions.prettyPrinted)
            } catch let error as NSError{
                PreyLogger("params error: \(error.localizedDescription)")
            }
        }

        request.httpMethod  = httpMethod
        
        let task = session.dataTask(with:request, completionHandler:onCompletion)
        
        // Send Request
        task.resume()
    }
}
