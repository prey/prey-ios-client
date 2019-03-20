//
//  PreyHTTPClient.swift
//  Prey
//
//  Created by Javier Cala Uribe on 2/12/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit

class PreyHTTPClient : NSObject, URLSessionDataDelegate, URLSessionTaskDelegate {
    
    // MARK: Properties
    
    static let sharedInstance = PreyHTTPClient()
    fileprivate override init() {
    }
    
    // Define delay to request
    let delayRequest = 7.0
    
    // Define retry request for statusCode 503
    let retryRequest = 10
    
    // Array for receive data : (session : Data)
    var requestData              = [URLSession : Data]()

    // Array for onCompletion request : (session : onCompletion)
    var requestCompletionHandler = [URLSession : ((Data?, URLResponse?, Error?) -> Void)]()
    
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

    // Define URLSessionConfiguration
    func getSessionConfig(_ authString: String, messageId: String?, endPoint: String) -> URLSessionConfiguration {
        
        let sessionConfig = URLSessionConfiguration.default
        
        var additionalHeader :[AnyHashable: Any] = ["User-Agent" : userAgent, "Content-Type" : "application/json", "Authorization" : authString]
        
        // Check if exist MessageId for action group
        if let msg = messageId {
            additionalHeader["X-Prey-State"]            = "PROCESSED"
            additionalHeader["X-Prey-Device-Id"]        = PreyConfig.sharedInstance.deviceKey
            additionalHeader["X-Prey-Correlation-Id"]   = msg
        }
        
        // Check if endpoint is event
        if endPoint == eventsDeviceEndpoint {
            additionalHeader["X-Prey-Status"]           = Battery.sharedInstance.getHeaderPreyStatus()
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
        let sessionConfig   = getSessionConfig(userAuthorization, messageId:msgId, endPoint:endPoint)
        let session         = URLSession(configuration:sessionConfig, delegate:self, delegateQueue:nil)
        
        // Set Endpoint
        guard let requestURL = URL(string:URLControlPanel + endPoint) else {
            return
        }
        var request  = URLRequest(url:requestURL)
        request.timeoutInterval = timeoutIntervalRequest

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
            
            if let imgData = img.pngData() {
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
        
        // Add onCompletion to array
        requestCompletionHandler.updateValue(onCompletion, forKey: session)
        
        // Prepare request
        sendRequest(session, request: request)
    }
    
    // SignUp/LogIn User to Control Panel
    func userRegisterToPrey(_ username: String, password: String, params: [String: Any]?, messageId msgId:String?, httpMethod: String, endPoint: String, onCompletion:@escaping (_ dataRequest: Data?, _ responseRequest:URLResponse?, _ error:Error?)->Void) {
        
        // Encode username and pwd
        let userAuthorization = encodeAuthorization(NSString(format:"%@:%@", username, password) as String)
        
        // Set session Config
        let sessionConfig   = getSessionConfig(userAuthorization, messageId:msgId, endPoint:endPoint)
        let session         = URLSession(configuration:sessionConfig, delegate:self, delegateQueue:nil)
        
        // Set Endpoint
        guard let requestURL = URL(string: URLControlPanel + endPoint) else {
            return
        }

        var request = URLRequest(url:requestURL)
        request.timeoutInterval = timeoutIntervalRequest
        
        // Set params
        if let parameters = params {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options:JSONSerialization.WritingOptions.prettyPrinted)
            } catch let error as NSError{
                PreyConfig.sharedInstance.reportError(error)
                PreyLogger("params error: \(error.localizedDescription)")
            }
        }

        request.httpMethod  = httpMethod
        
        // Add onCompletion to array
        requestCompletionHandler.updateValue(onCompletion, forKey: session)
        
        // Prepare request
        sendRequest(session, request: request)
    }

    // SignUp/LogIn User to Control Panel
    func sendFileToPrey(_ username: String, password: String, file: Data, messageId msgId:String?, httpMethod: String, endPoint: String, onCompletion:@escaping (_ dataRequest: Data?, _ responseRequest:URLResponse?, _ error:Error?)->Void) {
        
        // Encode username and pwd
        let userAuthorization = encodeAuthorization(NSString(format:"%@:%@", username, password) as String)
        
        // Set session Config
        let sessionConfig   = getSessionConfig(userAuthorization, messageId:msgId, endPoint:endPoint)
        let session         = URLSession(configuration:sessionConfig, delegate:self, delegateQueue:nil)
        
        // Set Endpoint
        guard let requestURL = URL(string:endPoint) else {
            return
        }
        
        var request = URLRequest(url:requestURL)
        request.timeoutInterval = timeoutIntervalRequest
        
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBodyStream = InputStream(data: file)
        request.httpMethod  = httpMethod
        
        // Add onCompletion to array
        requestCompletionHandler.updateValue(onCompletion, forKey: session)
        
        // Prepare request
        sendRequest(session, request: request)
    }
    
    // Prepare URLSessionDataTask
    func sendRequest(_ session: URLSession, request: URLRequest) {
        let task = session.dataTask(with: request)
        // Send Request
        task.resume()
    }
    
    // Delay dispatch function
    func delay(_ delay:Double, closure:@escaping ()->()) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }
    
    // Check error to retry request
    func checkToRetryRequest(err: Error) -> Bool {
        switch (err as NSError).code {
        case NSURLErrorSecureConnectionFailed, NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorCannotFindHost, NSURLErrorTimedOut:
            return true
        default:
            return false
        }
    }
    
    // MARK: URLSession Delegates
    
    // URLSessionTaskDelegate : didCompleteWithError
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        // Retry for statusCode == 503
        if let httpURLResponse = task.response as? HTTPURLResponse {
            if (httpURLResponse.statusCode == 503) && (task.taskIdentifier < retryRequest) {
                guard let request = task.originalRequest else {
                    return
                }
                delay(delayRequest) { self.sendRequest(session, request: request) }
                return
            }
        }
        // Retry for error cases
        if let err = error {
            if checkToRetryRequest(err: err) && (task.taskIdentifier < retryRequest) {
                guard let request = task.originalRequest else {
                    return
                }
                delay(delayRequest) { self.sendRequest(session, request: request) }
                return
            }
        }
        
        DispatchQueue.main.async {
            // Go to completionHandler
            if let onCompletion = self.requestCompletionHandler[session] {
                onCompletion(self.requestData[session], task.response, error)
            }
            // Delete value for sessionKey
            self.requestData.removeValue(forKey:session)
            self.requestCompletionHandler.removeValue(forKey:session)
            
            // Cancel session
            session.invalidateAndCancel()
        }
    }
    
    // URLSessionDataDelegate : dataTask didReceive Data
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // Save Data on array
        DispatchQueue.main.async {
            self.requestData.updateValue(data, forKey: session)
        }
    }
    
    // URLSessionDataDelegate : dataTask didReceive Response
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
    }
    
    // URLSessionDelegate didReceive challenge
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(
            .useCredential,
            URLCredential(trust: challenge.protectionSpace.serverTrust!)
        )
    }
}
