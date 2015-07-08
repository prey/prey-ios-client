//
//  PreyStoreProduct.m
//  Prey
//
//  Created by Javier Cala Uribe on 8/7/15.
//  Copyright (c) 2015 Fork Ltd. All rights reserved.
//

#import "PreyStoreProduct.h"
#import "NSData+MKBase64.h"
#import "PreyRestHttp.h"


static void (^onReviewRequestVerificationSucceeded)();
static void (^onReviewRequestVerificationFailed)();

@implementation PreyStoreProduct

- (id)initWithProductId:(NSString*)aProductId  receiptData:(NSData*)aReceipt
{
    if ((self = [super init]))
    {
        self.productId = aProductId;
        self.receipt = aReceipt;
    }
    return self;
}

- (void)verifyReceiptOnComplete:(void (^)(void))completionBlock onError:(void (^)(NSError*))errorBlock
{
    self.onReceiptVerificationSucceeded = completionBlock;
    self.onReceiptVerificationFailed = errorBlock;
    
    NSString *receiptDataString = [self.receipt base64EncodedString];
    
    [PreyRestHttp checkTransaction:5 withString:receiptDataString
                         withBlock:^(NSHTTPURLResponse *response, NSError *error)
     {
         if ( (!error) && (self.onReceiptVerificationSucceeded) )
         {
             self.onReceiptVerificationSucceeded();
             self.onReceiptVerificationSucceeded = nil;
         }
         else
         {
             if (self.onReceiptVerificationFailed)
             {
                 self.onReceiptVerificationFailed(error);
                 self.onReceiptVerificationFailed = nil;
             }
         }
     }];
}

@end
