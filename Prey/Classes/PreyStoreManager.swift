//
//  PreyStoreManager.swift
//  Prey
//
//  Created by Javier Cala Uribe on 14/07/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import StoreKit

class PreyStoreManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {

    
    // MARK: Singleton
    
    static let sharedInstance   = PreyStoreManager()
    override fileprivate init() {
    }

    // MARK: Properties
    
    var purchasableObjects      = [SKProduct]()

    var productsRequest         :SKProductsRequest!
    
    var onTransactionCancelled  : [() -> Void] = []
    
    var onTransactionCompleted  : [(_ productId:String, _ receiptData:Data) -> Void] = []
    
    var onRestoreFailed         : [(_ error:Error) -> Void] = []
    
    var onRestoreCompleted      : [() -> Void] = []
    
    
    // MARK: Methods
    
    // Request Product Data
    func requestProductData() {
        
        var products = Set<String>()
        products.insert(subscription1Year)
    
        // Set productsRequest
        productsRequest             = SKProductsRequest(productIdentifiers:products)
        productsRequest.delegate    = self
        productsRequest.start()
        
        // Add Transaction Observer
        SKPaymentQueue.default().add(self)
    }
    
    // BuyFeature
    func buyFeature(_ featureId:String, onComplete:@escaping (_ productId:String, _ receiptData:Data) -> Void, onCancelled:@escaping () -> Void) {
        
        guard SKPaymentQueue.canMakePayments() else {
            displayErrorAlert("Check your parental control settings and try again later".localized,
                              titleMessage:"In-App Purchasing disabled".localized)
            return
        }

        onTransactionCompleted.append(onComplete)
        onTransactionCancelled.append(onCancelled)
        

        for product in purchasableObjects {
            if product.productIdentifier == featureId {
                let payment     = SKPayment(product:product)
                SKPaymentQueue.default().add(payment)
            }
        }
    }
    
    
    // MARK: Transaction Methods
    
    // CompleteTransaction
    func completeTransaction(_ transaction:SKPaymentTransaction) {

        guard let storeURL = Bundle.main.appStoreReceiptURL else {
            onTransactionCancelled.first?()
            return
        }
        
        guard let storeData = try? Data(contentsOf: storeURL) else {
            onTransactionCancelled.first?()
            return
        }
        
        provideContent(transaction.payment.productIdentifier, forReceipt:storeData)

        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    // FailedTransaction
    func failedTransaction(_ transaction:SKPaymentTransaction) {
        PreyLogger("Failed transaction")
        
        SKPaymentQueue.default().finishTransaction(transaction)

        onTransactionCancelled.first?()
    }
    
    // RestoreTransaction
    func restoreTransaction(_ transaction:SKPaymentTransaction) {
        
        guard let storeURL = Bundle.main.appStoreReceiptURL else {
            onTransactionCancelled.first?()
            return
        }
        
        guard let storeData = try? Data(contentsOf: storeURL) else {
            onTransactionCancelled.first?()
            return
        }

        guard let originalTransaction = transaction.original else {
            onTransactionCancelled.first?()
            return
        }
        
        provideContent(originalTransaction.payment.productIdentifier, forReceipt:storeData)

        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    // ProvideContent
    func provideContent(_ productIdentifier:String, forReceipt data:Data) {

        let product = PreyStoreProduct(initWithProductId:productIdentifier, receiptData:data)

        // Verify receipt
        product.verifyReceiptOnComplete({() in
            // Success
            self.savePurchaseOfProduct(productIdentifier, withReceipt:data)
            self.onTransactionCompleted.first?(productIdentifier, data)
            }, onError:{() in
            // Error
            self.onTransactionCancelled.first?()
        })
    }
    
    // Save purchase
    func savePurchaseOfProduct(_ productIdentifier:String, withReceipt data:Data) {
        UserDefaults.standard.set(true, forKey:productIdentifier)
    }
    
    // Check is feature purchased
    class func isFeaturePurchased(_ productIdentifier:String) -> Bool {
        return UserDefaults.standard.bool(forKey: productIdentifier)
    }
    
    
    // MARK: SKPaymentTransactinObserver
    
    // UpdteTransactions
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        PreyLogger("updatedTransactions SKPaymentQueue")
        
        for transaction in transactions {
            switch transaction.transactionState {

            case .purchasing :
                PreyLogger("Purchasing")

            case .purchased :
                PreyLogger("Purchased")
                completeTransaction(transaction)

            case .failed :
                PreyLogger("Failed")
                failedTransaction(transaction)
            
            case .restored :
                PreyLogger("Restored")
                restoreTransaction(transaction)
            
            case .deferred :
                PreyLogger("Deferred")
                
            @unknown default:
                PreyLogger("Unknown")
            }
        }
    }
 
    // restoreCompletedTransactionsFailedWithError
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        PreyLogger("restoreCompletedTransactionsFailedWithError SKPaymentQueue")
        
        onRestoreFailed.first?(error)
        onRestoreFailed.removeAll()
    }
    
    // restoreCompletedTransactions
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        PreyLogger("paymentQueueRestoreCompletedTransactionsFinished SKPaymentQueue")
        
        onRestoreCompleted.first?()
        onRestoreCompleted.removeAll()
    }
    
    // removedTransactions
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        PreyLogger("removedTransactions SKPaymentQueue")
    }
    
    // MARK: SKProductsRequest
    
    // DidReceiveResponse
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        PreyLogger("DidReceiveResponse SKProductsRequest")
        
        // Add object to purchableObjects from response
        purchasableObjects = response.products
        
        #if DEBUG
            for product in purchasableObjects {
                PreyLogger("Feature: \(product.localizedTitle), Cost: \(product.price.doubleValue)")
            }
        #endif
        
        // Reset productsRequest
        productsRequest = nil
    }
    
    // RequestDidFinish
    func requestDidFinish(_ request: SKRequest) {
        PreyLogger("RequestDidFinish SKProductsRequest")
    }
    
    // DidFailWithError
    func request(_ request: SKRequest, didFailWithError error: Error) {
        PreyLogger("DidFailWithError SKProductRequest: \(error.localizedDescription)")
        productsRequest = nil
    }
}
