//
//  PreyDeployment.h
//  Prey
//
//  Created by Javier Cala Uribe on 21/11/13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CongratulationsController.h"
#import "MBProgressHUD.h"

@interface PreyDeployment : NSObject {
    MBProgressHUD   *HUD;
}

+ (PreyDeployment*)instance;
- (void)runPreyDeployment;
- (void)addDeviceForApiKey:(NSString *)apiKeyUser fromQRCode:(BOOL)isFromQRCode;

@end
