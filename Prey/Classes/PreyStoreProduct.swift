//
//  PreyStoreProduct.swift
//  Prey
//
//  Created by Javier Cala Uribe on 15/07/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation

class PreyStoreProduct {
    
    
    // MARK: Properties
    
    var onReceiptVerificationSucceeded  : [() -> Void] = []
    var onReceiptVerificationFailed     : [() -> Void] = []

    var receipt                         : Data
    var productId                       : String
    
    
    // MARK: Methods
    
    
    // Init with productId
    init(initWithProductId id:String, receiptData:Data) {

        self.productId = id
        self.receipt   = receiptData
    }
    
    // Verify receipt on complete
    func verifyReceiptOnComplete(_ onComplete:@escaping ()->Void, onError:@escaping () -> Void) {
        
        onReceiptVerificationSucceeded.append(onComplete)
        onReceiptVerificationFailed.append(onError)
     
        let receiptDataString = receipt.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
     
        let params:[String: String] = ["receipt-data" : receiptDataString]
        
        if let username = PreyConfig.sharedInstance.userApiKey {

            PreyHTTPClient.sharedInstance.sendDataToPrey(username, password:"x", params:params, messageId:nil, httpMethod:Method.POST.rawValue, endPoint:subscriptionEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.subscriptionReceipt, preyAction:nil, onCompletion:{(isSuccess: Bool) in
                
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
