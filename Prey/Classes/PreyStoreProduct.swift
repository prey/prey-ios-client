//
//  PreyStoreProduct.swift
//  Prey
//
//  Created by Javier Cala Uribe on 15/07/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation

class PreyStoreProduct {
    
    
    // MARK: Properties
    
    var onReceiptVerificationSucceeded  : [() -> Void] = []
    var onReceiptVerificationFailed     : [() -> Void] = []

    var receipt                         : NSData
    var productId                       : String
    
    
    // MARK: Methods
    
    
    // Init with productId
    init(initWithProductId id:String, receiptData:NSData) {

        self.productId = id
        self.receipt   = receiptData
    }
    
    // Verify receipt on complete
    func verifyReceiptOnComplete(onComplete:()->Void, onError:() -> Void) {
        
        onReceiptVerificationSucceeded.append(onComplete)
        onReceiptVerificationFailed.append(onError)
     
        let receiptDataString = receipt.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
     
        let params:[String: AnyObject] = ["receipt-data" : receiptDataString]
        
        if let username = PreyConfig.sharedInstance.userApiKey {

            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:params, httpMethod:Method.POST.rawValue, endPoint:subscriptionEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.SubscriptionReceipt, onCompletion:{(isSuccess: Bool) in
                
                guard isSuccess else {
                    self.onReceiptVerificationFailed.first?()
                    self.onReceiptVerificationFailed.removeAll()
                    return
                }
                
                self.onReceiptVerificationSucceeded.first?()
                self.onReceiptVerificationSucceeded.removeAll()
                
            }))
        } else {
            PreyLogger("Error InAppPurchase")
            self.onReceiptVerificationFailed.first?()
            self.onReceiptVerificationFailed.removeAll()
        }
    }
}