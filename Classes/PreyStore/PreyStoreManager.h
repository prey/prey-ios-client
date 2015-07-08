//
//  PreyStoreManager.h
//  Prey
//
//  Created by Javier Cala Uribe on 7/7/15.
//  Copyright (c) 2015 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "PreyStoreConfigs.h"

@interface PreyStoreManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, strong) NSMutableArray    *purchasableObjects;
@property (nonatomic, strong) SKProductsRequest *productsRequest;

@property (nonatomic, copy) void (^onTransactionCancelled)();
@property (nonatomic, copy) void (^onTransactionCompleted)(NSString *productId, NSData* receiptData, NSArray* downloads);

@property (nonatomic, copy) void (^onRestoreFailed)(NSError* error);
@property (nonatomic, copy) void (^onRestoreCompleted)();


+ (PreyStoreManager*)instance;
- (void)buyFeature:(NSString*)featureId onComplete:(void (^)(NSString*, NSData*, NSArray*))completionBlock
       onCancelled:(void (^)(void))cancelBlock;


@end
