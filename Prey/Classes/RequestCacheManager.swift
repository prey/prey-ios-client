//
//  RequestCacheManager.swift
//  Prey
//
//  Created by Javier Cala Uribe on 29/4/20.
//  Copyright © 2020 Prey, Inc. All rights reserved.
//

import Foundation
import CoreData

class RequestCacheManager:NSObject {

    // MARK: Properties

    static let sharedInstance = RequestCacheManager()
    override fileprivate init() {
    }
    
    func saveRequest(_ sessionConfig: URLSessionConfiguration, _ request: URLRequest, _ error: Error) {
        
        // Init NSManagedObject type RequestCache
        let requestCache = NSEntityDescription.insertNewObject(forEntityName: "RequestCache", into: PreyCoreData.sharedInstance.managedObjectContext)

        // Check timestamp
        var req = request
        var requestTimestamp = CFAbsoluteTimeGetCurrent()
        if let reqHeader = request.allHTTPHeaderFields, let reqTimestamp = reqHeader["Prey-timestamp"], let timestamp = Double(reqTimestamp) {
            requestTimestamp = timestamp
        } else {
            req.addValue(String(requestTimestamp), forHTTPHeaderField:"Prey-timestamp")
        }
                
        // Set values on NSManageObject
        let reqData: Data = NSKeyedArchiver.archivedData(withRootObject: req)
        requestCache.setValue(reqData, forKey: "request")
        
        let sessionConfigData: Data = NSKeyedArchiver.archivedData(withRootObject: sessionConfig)
        requestCache.setValue(sessionConfigData, forKey: "session_config")

        let errorData: Data = NSKeyedArchiver.archivedData(withRootObject: error)
        requestCache.setValue(errorData, forKey: "error")

        requestCache.setValue(requestTimestamp , forKey: "timestamp")
        
        // Save CoreData
        do {
            try PreyCoreData.sharedInstance.managedObjectContext.save()
        } catch {
            PreyLogger("Couldn't save: \(error)")
        }
    }
    
    func sendRequest() {
        let requestCacheArray = PreyCoreData.sharedInstance.getCurrentRequestCache()
        guard let context = PreyCoreData.sharedInstance.managedObjectContext else {return}
        
        // Send requests
        for req in requestCacheArray {
            guard let request = req.request, let sessionConfig = req.session_config, let error = req.error, let time = req.timestamp else {
                context.delete(req)
                return
            }
            
            guard let decodedRequest = NSKeyedUnarchiver.unarchiveObject(with: request) as? URLRequest, let decodedSession = NSKeyedUnarchiver.unarchiveObject(with: sessionConfig) as? URLSessionConfiguration, let decodedError = NSKeyedUnarchiver.unarchiveObject(with: error) as? Error else {
                context.delete(req)
                return
            }
            
            // Check timestamp
            guard (time.doubleValue + 60*60*24) > CFAbsoluteTimeGetCurrent() else {
                PreyConfig.sharedInstance.reportError(decodedError)
                context.delete(req)
                return
            }
            
            // Resend requests
            // Reintentar usando la sesión compartida del HTTPClient
            let onCompletion = PreyHTTPResponse.checkResponse(RequestType.dataSend, preyAction:nil, onCompletion:{(isSuccess: Bool) in PreyLogger("Request dataSend")})
            PreyHTTPClient.sharedInstance.performRequest(decodedRequest, onCompletion: onCompletion)
            
            context.delete(req)
        }
        
        // Save CoreData
        do {
            try context.save()
        } catch {
            PreyLogger("Couldn't save: \(error)")
        }
    }
}
