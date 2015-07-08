//
//  PreyStoreProduct.h
//  Prey
//
//  Created by Javier Cala Uribe on 8/7/15.
//  Copyright (c) 2015 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PreyStoreConfigs.h"

@interface PreyStoreProduct : NSObject

@property (nonatomic, copy) void (^onReceiptVerificationSucceeded)();
@property (nonatomic, copy) void (^onReceiptVerificationFailed)();

@property (nonatomic, strong) NSData *receipt;
@property (nonatomic, strong) NSString *productId;


- (void)verifyReceiptOnComplete:(void (^)(void))completionBlock onError:(void (^)(NSError*))errorBlock;
- (id)initWithProductId:(NSString*)aProductId  receiptData:(NSData*)aReceipt;


@end
