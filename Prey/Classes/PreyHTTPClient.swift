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
    
    // Shared default session (HTTP/2/3, keep‑alive)
    private lazy var sharedSession: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.waitsForConnectivity = true
        cfg.allowsCellularAccess = true
        cfg.timeoutIntervalForRequest = 30.0
        cfg.timeoutIntervalForResource = 45.0
        cfg.httpMaximumConnectionsPerHost = 2
        cfg.allowsExpensiveNetworkAccess = true
        cfg.allowsConstrainedNetworkAccess = true
        return URLSession(configuration: cfg, delegate: self, delegateQueue: nil)
    }()

    // Background session for uploads (reports)
    private lazy var backgroundSession: URLSession = {
        let identifier = (Bundle.main.bundleIdentifier ?? "com.prey.ios") + ".uploads"
        let cfg = URLSessionConfiguration.background(withIdentifier: identifier)
        cfg.waitsForConnectivity = true
        cfg.isDiscretionary = false
        cfg.sessionSendsLaunchEvents = true
        cfg.allowsCellularAccess = true
        cfg.allowsExpensiveNetworkAccess = true
        cfg.allowsConstrainedNetworkAccess = true
        cfg.httpMaximumConnectionsPerHost = 2
        cfg.timeoutIntervalForRequest = 60.0
        cfg.timeoutIntervalForResource = 300.0
        return URLSession(configuration: cfg, delegate: self, delegateQueue: nil)
    }()

    // Per-task state
    private let stateQueue = DispatchQueue(label: "prey.httpclient.state")
    private var dataByTask = [ObjectIdentifier: NSMutableData]()
    private var completionByTask = [ObjectIdentifier: (Data?, URLResponse?, Error?) -> Void]()
    private var retryByTask = [ObjectIdentifier: Int]()
    private var fileByTask = [ObjectIdentifier: URL]()

    // Background completion handler bridged from AppDelegate
    private var backgroundCompletionHandler: (() -> Void)?
    func registerBackgroundCompletionHandler(_ handler: @escaping () -> Void) { backgroundCompletionHandler = handler }
    
    
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

    // Apply per-request headers (move dynamic headers from session to request)
    private func applyHeaders(_ request: inout URLRequest, authString: String, messageId: String?, endPoint: String, contentType: String?) {
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(contentType ?? "application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authString, forHTTPHeaderField: "Authorization")
        if let msg = messageId {
            request.setValue("PROCESSED", forHTTPHeaderField: "X-Prey-State")
            request.setValue(PreyConfig.sharedInstance.deviceKey, forHTTPHeaderField: "X-Prey-Device-Id")
            request.setValue(msg, forHTTPHeaderField: "X-Prey-Correlation-Id")
        } else if let deviceKey = PreyConfig.sharedInstance.deviceKey {
            request.setValue(deviceKey, forHTTPHeaderField: "X-Prey-Device-Id")
        }
        if endPoint == eventsDeviceEndpoint {
            let status = Battery.sharedInstance.getHeaderPreyStatus()
            if let d = try? JSONSerialization.data(withJSONObject: status, options: []), let s = String(data: d, encoding: .utf8) {
                request.setValue(s, forHTTPHeaderField: "X-Prey-Status")
            }
        }
        var isBG = false
        if Thread.isMainThread { isBG = UIApplication.shared.applicationState == .background }
        else { DispatchQueue.main.sync { isBG = UIApplication.shared.applicationState == .background } }
        request.networkServiceType = isBG ? .background : .default
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
        
        // Set Endpoint
        guard let requestURL = URL(string:URLControlPanel + endPoint) else {
            return
        }
        var request  = URLRequest(url:requestURL)
        request.timeoutInterval = timeoutIntervalRequest

        // HTTP Header boundary
        let boundary = String(format: "prey.boundary-%08x%08x", arc4random(), arc4random())
        
        // Define the multipart request type and headers
        let multipartType = "multipart/form-data; boundary=\(boundary)"
        applyHeaders(&request, authString: userAuthorization, messageId: msgId, endPoint: endPoint, contentType: multipartType)
        
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
        
        request.httpMethod  = httpMethod
        // Persist multipart to file and upload via background session
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("prey-report-\(UUID().uuidString).tmp")
        do { try (bodyRequest as Data).write(to: tmp, options: .atomic) } catch {
            onCompletion(nil, nil, error); return
        }
        startUploadTask(request, fromFile: tmp, completion: onCompletion)
    }
    
    // SignUp/LogIn User to Control Panel
    func userRegisterToPrey(_ username: String, password: String, params: [String: Any]?, messageId msgId:String?, httpMethod: String, endPoint: String, onCompletion:@escaping (_ dataRequest: Data?, _ responseRequest:URLResponse?, _ error:Error?)->Void) {
        
        // Encode username and pwd
        let userAuthorization = encodeAuthorization(NSString(format:"%@:%@", username, password) as String)
        
        // Set Endpoint
        guard let requestURL = URL(string: URLControlPanel + endPoint) else {
            return
        }

        var request = URLRequest(url:requestURL)
        request.timeoutInterval = timeoutIntervalRequest
        applyHeaders(&request, authString: userAuthorization, messageId: msgId, endPoint: endPoint, contentType: nil)
        
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
        
        // Start on shared session
        startTask(request, completion: onCompletion)
    }

    // Uploads files
    func sendFileToPrey(_ username: String, password: String, file: Data, messageId msgId:String?, httpMethod: String, endPoint: String, onCompletion:@escaping (_ dataRequest: Data?, _ responseRequest:URLResponse?, _ error:Error?)->Void) {
        
        // Encode username and pwd
        let userAuthorization = encodeAuthorization(NSString(format:"%@:%@", username, password) as String)
        
        // Set Endpoint
        guard let requestURL = URL(string:endPoint) else {
            return
        }
       
        var request = URLRequest(url:requestURL)
        request.timeoutInterval = timeoutIntervalRequest
        applyHeaders(&request, authString: userAuthorization, messageId: msgId, endPoint: endPoint, contentType: "application/octet-stream")
        request.httpBodyStream = InputStream(data: file)
        request.httpMethod  = httpMethod
        startTask(request, completion: onCompletion)
    }
    
    // Start URLSessionDataTask with per-task state
    private func startTask(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let task = sharedSession.dataTask(with: request)
        let key = ObjectIdentifier(task)
        stateQueue.async {
            self.dataByTask[key] = NSMutableData()
            self.completionByTask[key] = completion
            self.retryByTask[key] = 0
        }
        task.resume()
    }

    // Start background upload task
    private func startUploadTask(_ request: URLRequest, fromFile fileURL: URL, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let task = backgroundSession.uploadTask(with: request, fromFile: fileURL)
        let key = ObjectIdentifier(task)
        stateQueue.async {
            self.dataByTask[key] = NSMutableData()
            self.completionByTask[key] = completion
            self.retryByTask[key] = 0
            self.fileByTask[key] = fileURL
        }
        task.resume()
    }

    // Public wrapper for arbitrary URLRequest
    func performRequest(_ request: URLRequest, onCompletion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        startTask(request, completion: onCompletion)
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
        // Retry 503 with backoff per task
        if let httpURLResponse = task.response as? HTTPURLResponse, httpURLResponse.statusCode == 503, let request = task.originalRequest {
            let key = ObjectIdentifier(task)
            var attempt = 0
            stateQueue.sync { attempt = (self.retryByTask[key] ?? 0) + 1 }
            if attempt <= retryRequest {
                stateQueue.async { self.retryByTask[key] = attempt }
                let backoff = min(pow(2.0, Double(attempt)), 60.0)
                let jitter = Double.random(in: 0...0.5)
                delay(backoff + jitter) { self.retryTask(task, with: request) }
            }
            return
        }
        // Retry transient errors with backoff per task
        if let err = error, checkToRetryRequest(err: err), let request = task.originalRequest {
            let key = ObjectIdentifier(task)
            var attempt = 0
            stateQueue.sync { attempt = (self.retryByTask[key] ?? 0) + 1 }
            if attempt <= retryRequest {
                stateQueue.async { self.retryByTask[key] = attempt }
                let backoff = min(pow(2.0, Double(attempt)), 60.0)
                let jitter = Double.random(in: 0...0.5)
                delay(backoff + jitter) { self.retryTask(task, with: request) }
            }
            return
        }
        // Normal completion: call completion and cleanup
        let key = ObjectIdentifier(task)
        var completion: ((Data?, URLResponse?, Error?) -> Void)?
        var dataOut: Data?
        stateQueue.sync {
            completion = self.completionByTask[key]
            dataOut = self.dataByTask[key] as Data?
        }
        DispatchQueue.main.async {
            completion?(dataOut, task.response, error)
            self.stateQueue.async {
                self.dataByTask.removeValue(forKey: key)
                self.completionByTask.removeValue(forKey: key)
                self.retryByTask.removeValue(forKey: key)
                if let fileURL = self.fileByTask.removeValue(forKey: key) { try? FileManager.default.removeItem(at: fileURL) }
            }
        }
    }
    
    // URLSessionDataDelegate : dataTask didReceive Data
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let key = ObjectIdentifier(dataTask)
        stateQueue.async {
            let buf = self.dataByTask[key] ?? NSMutableData()
            buf.append(data)
            self.dataByTask[key] = buf
        }
    }
    
    // URLSessionDataDelegate : dataTask didReceive Response
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
    }
    
    // URLSessionDelegate didReceive challenge
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else {return}
        completionHandler(
            .useCredential,
            URLCredential(trust: serverTrust)
        )
    }

    // Metrics (protocol h2/h3, bytes)
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        if let t = metrics.transactionMetrics.last, let url = t.request.url?.absoluteString {
            PreyLogger("Network metrics -> URL: \(url), sent: \(task.countOfBytesSent)B, recv: \(task.countOfBytesReceived)B, protocol: \(t.networkProtocolName ?? "unknown")")
        }
    }

    // Background events done
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async { self.backgroundCompletionHandler?(); self.backgroundCompletionHandler = nil }
    }

    // Retry helper: new task preserving completion and attempt count
    private func retryTask(_ oldTask: URLSessionTask, with request: URLRequest) {
        let oldKey = ObjectIdentifier(oldTask)
        var completion: ((Data?, URLResponse?, Error?) -> Void)?
        var attempt = 0
        stateQueue.sync {
            completion = self.completionByTask[oldKey]
            attempt = self.retryByTask[oldKey] ?? 0
        }
        let newTask = sharedSession.dataTask(with: request)
        let newKey = ObjectIdentifier(newTask)
        stateQueue.async {
            self.dataByTask[newKey] = NSMutableData()
            if let c = completion { self.completionByTask[newKey] = c }
            self.retryByTask[newKey] = attempt
            self.dataByTask.removeValue(forKey: oldKey)
            self.completionByTask.removeValue(forKey: oldKey)
            self.retryByTask.removeValue(forKey: oldKey)
        }
        newTask.resume()
    }
}
