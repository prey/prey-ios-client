//
//  PreyStoreConfigs.h
//  Prey
//
//  Created by Javier Cala Uribe on 7/7/15.
//  Copyright (c) 2015 Fork Ltd. All rights reserved.
//


#define kSubscription1Year  @"1year_personal_plan_non_renewing"


#ifndef NDEBUG
#define kReceiptValidationURL @"https://sandbox.itunes.apple.com/verifyReceipt"
#else
#define kReceiptValidationURL @"https://buy.itunes.apple.com/verifyReceipt"
#endif
