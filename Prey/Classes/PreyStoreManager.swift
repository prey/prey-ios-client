//
//  PreyStoreManager.swift
//  Prey
//
//  Created by Javier Cala Uribe on 14/07/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import StoreKit

class PreyStoreManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {

    
    // MARK: Singleton
    
    static let sharedInstance   = PreyStoreManager()
    override private init() {
    }

    // MARK: Properties
    
    let purchasableObjects      = NSMutableArray()

    var productsRequest         :SKProductsRequest!
     
    
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
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    }
    
    
    // MARK: Transaction Methods
    
    // CompleteTransaction
    func completeTransaction(transaction:SKPaymentTransaction) {

        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    // FailedTransaction
    func failedTransaction(transaction:SKPaymentTransaction) {
        print("Failed transaction: \(transaction.description)")
        
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        
        FIXME() // Add cancelled nil
    }
    
    // RestoreTransaction
    func restoreTransaction(transaction:SKPaymentTransaction) {
        
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    
    // MARK: SKPaymentTransactinObserver
    
    // UpdteTransactions
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("updatedTransactions SKPaymentQueue")
        
        for transaction in transactions {
            switch transaction.transactionState {

            case .Purchasing :
                print("Purchasing")

            case .Purchased :
                print("Purchased")
                completeTransaction(transaction)

            case .Failed :
                print("Failed")
                failedTransaction(transaction)
            
            case .Restored :
                print("Restored")
                restoreTransaction(transaction)
            
            case .Deferred :
                print("Deferred")
            }
        }
    }
 
    // restoreCompletedTransactionsFailedWithError
    func paymentQueue(queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError) {
        print("restoreCompletedTransactionsFailedWithError SKPaymentQueue")
        FIXME() // Add restoreFail nil
    }
    
    // restoreCompletedTransactions
    func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue) {
        print("paymentQueueRestoreCompletedTransactionsFinished SKPaymentQueue")
        FIXME() // Add restoreCompleted nil
    }
    
    // removedTransactions
    func paymentQueue(queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        print("removedTransactions SKPaymentQueue")
    }
    
    // MARK: SKProductsRequest
    
    // DidReceiveResponse
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        print("DidReceiveResponse SKProductsRequest")
        
        // Add object to purchableObjects from response
        purchasableObjects.addObjectsFromArray(response.products)
        
        #if DEBUG
            for product in purchasableObjects {
                print("Feature: \(product.localizedTitle), Cost: \(product.price.doubleValue)")
            }
        #endif
        
        // Reset productsRequest
        productsRequest = nil
    }
    
    // RequestDidFinish
    func requestDidFinish(request: SKRequest) {
        print("RequestDidFinish SKProductsRequest")
    }
    
    // DidFailWithError
    func request(request: SKRequest, didFailWithError error: NSError) {
        print("DidFailWithError SKProductRequest: \(error.description)")
        productsRequest = nil
    }
}