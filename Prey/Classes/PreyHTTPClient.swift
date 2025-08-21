//
//  PreyHTTPClient.swift
//  Prey
//
//  Created by Javier Cala Uribe on 2/12/14.
//  Copyright (c) 2014 Prey, Inc. All rights reserved.
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
    
    // Track retry attempts per session to avoid infinite loops and battery drain
    private var requestRetryCount = [URLSession: Int]()
    
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
        
        // Configure for better background performance
        sessionConfig.waitsForConnectivity = true
        sessionConfig.allowsCellularAccess = true 
        sessionConfig.timeoutIntervalForRequest = 30.0
        sessionConfig.timeoutIntervalForResource = 45.0
        sessionConfig.httpMaximumConnectionsPerHost = 2
        
        // Set appropriate background policy based on app state
        // Fix: Check app state on main thread to avoid Main Thread Checker warning
        var isAppInBackground = false
        if Thread.isMainThread {
            isAppInBackground = UIApplication.shared.applicationState == .background
        } else {
            DispatchQueue.main.sync {
                isAppInBackground = UIApplication.shared.applicationState == .background
            }
        }
        
        if isAppInBackground {
            sessionConfig.networkServiceType = .background
        } else {
            sessionConfig.networkServiceType = .default
        }
        
        // Run actions even without Wi-Fi connection
        sessionConfig.allowsExpensiveNetworkAccess = true
        sessionConfig.allowsConstrainedNetworkAccess = true
        
        var additionalHeader :[AnyHashable: Any] = ["User-Agent" : userAgent, "Content-Type" : "application/json", "Authorization" : authString]
        
        // Check if exist MessageId for action group
        if let msg = messageId {
            additionalHeader["X-Prey-State"]            = "PROCESSED"
            additionalHeader["X-Prey-Device-Id"]        = PreyConfig.sharedInstance.deviceKey
            additionalHeader["X-Prey-Correlation-Id"]   = msg
        }
        
        // Always include device identifier in headers
        if let deviceKey = PreyConfig.sharedInstance.deviceKey {
            additionalHeader["X-Prey-Device-Id"] = deviceKey
        }
        
        // Check if endpoint is event
        if endPoint == eventsDeviceEndpoint {
            additionalHeader["X-Prey-Status"] = Battery.sharedInstance.getHeaderPreyStatus()
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
        
        // Set type to images (use JPEG to reduce payload size)
        let mimetype = "image/jpeg"
        
        // Set images on request
        for (key, value) in images {
            
            guard let img = value as? UIImage else {
                return
            }
            
            if let imgData = img.jpegData(compressionQuality: 0.7) {
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
        // Initialize retry counter for this session
        requestRetryCount[session] = 0
        
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
        // Initialize retry counter for this session
        requestRetryCount[session] = 0
        
        // Prepare request
        sendRequest(session, request: request)
    }

    // Uploads files
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
        // Initialize retry counter for this session
        requestRetryCount[session] = 0
        
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

        // Retry for statusCode == 503 with capped exponential backoff
        if let httpURLResponse = task.response as? HTTPURLResponse {
            if (httpURLResponse.statusCode == 503) {
                guard let request = task.originalRequest else { return }
                let attempt = (requestRetryCount[session] ?? 0) + 1
                if attempt <= retryRequest {
                    requestRetryCount[session] = attempt
                    let backoff = min(pow(2.0, Double(attempt)) * 1.0, 60.0) // seconds
                    let jitter = Double.random(in: 0...0.5)
                    let delaySeconds = backoff + jitter
                    PreyLogger("Retrying request (HTTP 503), attempt #\(attempt) in \(String(format: "%.1f", delaySeconds))s")
                    delay(delaySeconds) { self.sendRequest(session, request: request) }
                } else {
                    PreyLogger("Max retry attempts reached for session; will not retry (HTTP 503)")
                }
                return
            }
        }
        // Retry for transient error cases with capped exponential backoff
        if let err = error, checkToRetryRequest(err: err) {
            guard let request = task.originalRequest else { return }
            let attempt = (requestRetryCount[session] ?? 0) + 1
            if attempt <= retryRequest {
                requestRetryCount[session] = attempt
                let backoff = min(pow(2.0, Double(attempt)) * 1.0, 60.0)
                let jitter = Double.random(in: 0...0.5)
                let delaySeconds = backoff + jitter
                PreyLogger("Retrying request (error: \(err.localizedDescription)), attempt #\(attempt) in \(String(format: "%.1f", delaySeconds))s")
                delay(delaySeconds) { self.sendRequest(session, request: request) }
            } else {
                PreyLogger("Max retry attempts reached for session; will not retry (error)")
            }
            return
        }
        
        // Save on CoreData requests failed
        if let err = error, (err as NSError).domain == NSURLErrorDomain, let req = task.originalRequest, let reqUrl = req.url {
            // check endpoints
            if reqUrl.absoluteString == (URLControlPanel+locationAwareEndpoint) ||  reqUrl.absoluteString == (URLControlPanel+dataDeviceEndpoint) {

                DispatchQueue.main.async {
                    // Save request
                    RequestCacheManager.sharedInstance.saveRequest(session.configuration, req, err)
                    // Delete value for sessionKey
                    self.requestData.removeValue(forKey:session)
                    self.requestCompletionHandler.removeValue(forKey:session)
                    // Clear retry counter and cancel session
                    self.requestRetryCount.removeValue(forKey: session)
                    session.invalidateAndCancel()
                }
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
            // Clear retry counter and cancel session
            self.requestRetryCount.removeValue(forKey: session)
            session.invalidateAndCancel()
        }
    }

    // URLSessionTaskDelegate: collect basic metrics to help identify heavy endpoints
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        guard let transaction = metrics.transactionMetrics.last else { return }
        if let url = transaction.request.url?.absoluteString {
            let bytesSent = task.countOfBytesSent
            let bytesReceived = task.countOfBytesReceived
            PreyLogger("Network metrics -> URL: \(url), sent: \(bytesSent)B, recv: \(bytesReceived)B, protocol: \(transaction.networkProtocolName ?? "unknown")")
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
        guard let serverTrust = challenge.protectionSpace.serverTrust else {return}
        completionHandler(
            .useCredential,
            URLCredential(trust: serverTrust)
        )
    }
}
