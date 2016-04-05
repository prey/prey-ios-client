//
//  PreyStoreManager.m
//  Prey
//
//  Created by Javier Cala Uribe on 7/7/15.
//  Copyright (c) 2015 Fork Ltd. All rights reserved.
//

#import "PreyStoreManager.h"
#import "PreyStoreProduct.h"
#import "SFHFKeychainUtils.h"

@implementation PreyStoreManager

#pragma mark Init

+ (PreyStoreManager*)instance
{
    static PreyStoreManager *instance = nil;
    static dispatch_once_t onceToken = 0;
    
    dispatch_once(&onceToken, ^{
        instance = [[PreyStoreManager alloc] init];
        instance.purchasableObjects = [NSMutableArray array];
        [instance requestProductData];
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:instance];
    });

    return instance;
}



- (void)requestProductData
{
    NSMutableSet *products = [[NSMutableSet alloc] init];
    [products addObjectsFromArray:[NSArray arrayWithObjects:kSubscription1Year, nil]];
    
    self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:products];
    self.productsRequest.delegate = self;
    [self.productsRequest start];
    
    PreyLogMessage(@"PreyStore Manager", 10, @"Start SKProductsRequest");
}

- (void)buyFeature:(NSString*)featureId onComplete:(void (^)(NSString*, NSData*, NSArray*))completionBlock
       onCancelled:(void (^)(void))cancelBlock
{
    self.onTransactionCompleted = completionBlock;
    self.onTransactionCancelled = cancelBlock;
    
    [self addToQueue:featureId];
}

- (void)addToQueue:(NSString*)productId
{
    if ([SKPaymentQueue canMakePayments])
    {
        NSArray   *allIds = [self.purchasableObjects valueForKey:@"productIdentifier"];
        NSUInteger  index = [allIds indexOfObject:productId];
        
        if (index == NSNotFound) return;
        
        SKProduct *thisProduct = [self.purchasableObjects objectAtIndex:index];
        SKPayment *payment = [SKPayment paymentWithProduct:thisProduct];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
    else
    {
        [self showAlertWithTitle:NSLocalizedString(@"In-App Purchasing disabled", @"")
                         message:NSLocalizedString(@"Check your parental control settings and try again later", @"")];
    }
}

- (void)showAlertWithTitle:(NSString*)title message:(NSString*)message
{    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)restorePreviousTransactionsOnComplete:(void (^)(void))completionBlock onError:(void (^)(NSError*))errorBlock
{
    self.onRestoreCompleted = completionBlock;
    self.onRestoreFailed = errorBlock;
    
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}


#pragma mark Delegate SKProductsRequest

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    PreyLogMessage(@"PreyStore Manager", 10, @"DidReceiveResponse SKProductsRequest");
    
    [self.purchasableObjects addObjectsFromArray:response.products];
    
#ifdef DEBUG
    for (int i=0;i<[self.purchasableObjects count];i++)
    {
        SKProduct *product = [self.purchasableObjects objectAtIndex:i];
        NSLog(@"Feature: %@, Cost: %f, ID: %@",[product localizedTitle], [[product price] doubleValue], [product productIdentifier]);
    }
    
    for (NSString *invalidProduct in response.invalidProductIdentifiers)
        NSLog(@"Problem in iTunes connect configuration for product: %@", invalidProduct);
#endif
    
    self.productsRequest = nil;
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    PreyLogMessage(@"PreyStore Manager", 10, @"didFailWithError SKProductsRequest : %@",error);
    
    self.productsRequest = nil;
}


- (void)requestDidFinish:(SKRequest *)request
{
    PreyLogMessage(@"PreyStore Manager", 10, @"requestDidFinish SKProductsRequest");
}

#pragma mark Delegate SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    PreyLogMessage(@"PreyStore Manager", 10, @"updatedTransactions SKPaymentQueue");
    
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                
                [self completeTransaction:transaction];
                
                break;
                
            case SKPaymentTransactionStateFailed:
                
                [self failedTransaction:transaction];
                
                break;
                
            case SKPaymentTransactionStateRestored:
                
                [self restoreTransaction:transaction];
                
            default:
                break;
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    PreyLogMessage(@"PreyStore Manager", 10, @"restoreCompletedTransactionsFailedWithError SKPaymentQueue");
   
    if (self.onRestoreFailed)
        self.onRestoreFailed(error);

    self.onRestoreFailed = nil;
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    PreyLogMessage(@"PreyStore Manager", 10, @"paymentQueueRestoreCompletedTransactionsFinished SKPaymentQueue");

    if (self.onRestoreCompleted)
        self.onRestoreCompleted();
    
    self.onRestoreCompleted = nil;
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
    PreyLogMessage(@"PreyStore Manager", 10, @"removedTransactions SKPaymentQueue");
}

#pragma mark Transaction Methods

- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
    [self provideContent:transaction.payment.productIdentifier
              forReceipt:transaction.transactionReceipt
           hostedContent:nil];
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    NSLog(@"Failed transaction: %@", [transaction description]);
    NSLog(@"error: %@", transaction.error);
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    if (self.onTransactionCancelled)
        self.onTransactionCancelled();
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
    [self provideContent:transaction.originalTransaction.payment.productIdentifier
              forReceipt:transaction.transactionReceipt
           hostedContent:nil];
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)provideContent:(NSString*)productIdentifier forReceipt:(NSData*)receiptData hostedContent:(NSArray*)hostedContent
{
    PreyStoreProduct *thisProduct = [[PreyStoreProduct alloc] initWithProductId:productIdentifier receiptData:receiptData];
    
    [thisProduct verifyReceiptOnComplete:^
     {
         [self rememberPurchaseOfProduct:productIdentifier withReceipt:receiptData];
         
         if(self.onTransactionCompleted)
             self.onTransactionCompleted(productIdentifier, receiptData, hostedContent);
     }
                                     onError:^(NSError* error)
     {
         if (self.onTransactionCancelled)
             self.onTransactionCancelled(productIdentifier);
         else
             NSLog(@"The receipt could not be verified");
     }];
}

- (void)rememberPurchaseOfProduct:(NSString*)productIdentifier withReceipt:(NSData*)receiptData
{
    [PreyStoreManager setObject:[NSNumber numberWithBool:YES] forKey:productIdentifier];
    [PreyStoreManager setObject:receiptData forKey:[NSString stringWithFormat:@"%@-receipt", productIdentifier]];
}

#pragma mark Class Methods

+ (BOOL)isFeaturePurchased:(NSString*)featureId
{
    return [[PreyStoreManager numberForKey:featureId] boolValue];
}

+ (NSNumber*)numberForKey:(NSString*)key
{
    return [NSNumber numberWithInt:[[PreyStoreManager objectForKey:key] intValue]];
}

+ (id)objectForKey:(NSString*)key
{
    NSError *error = nil;
    id password = [SFHFKeychainUtils getPasswordForUsername:key andServiceName:@"PreyStore" error:&error];
    if(error) NSLog(@"%@", error);
    
    return password;
}

+ (void)setObject:(id)object forKey:(NSString*)key
{
    if (object)
    {
        NSString *objectString = nil;

        if ([object isKindOfClass:[NSData class]])
            objectString = [[NSString alloc] initWithData:object encoding:NSUTF8StringEncoding];
        
        if ([object isKindOfClass:[NSNumber class]])
            objectString = [(NSNumber*)object stringValue];
        
        NSError *error = nil;
        [SFHFKeychainUtils storeUsername:key andPassword:objectString forServiceName:@"PreyStore" updateExisting:YES error:&error];
        if(error) NSLog(@"%@", error);
    }
    else
    {
        NSError *error = nil;
        [SFHFKeychainUtils deleteItemForUsername:key andServiceName:@"PreyStore" error:&error];
        if(error) NSLog(@"%@", error);
    }
}

- (BOOL)removeAllKeychainData
{
    NSUInteger itemCount = self.purchasableObjects.count;
    NSError *error;
    
    //loop through all the saved keychain data and remove it
    for (int i = 0; i < itemCount; i++ ) {
        [SFHFKeychainUtils deleteItemForUsername:[self.purchasableObjects objectAtIndex:i] andServiceName:@"PreyStore" error:&error];
    }
    if (!error) {
        return YES;
    }
    else {
        return NO;
    }
}


@end
