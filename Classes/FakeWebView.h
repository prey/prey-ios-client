//
//  FakeWebView.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 23/03/2011.
//  Copyright 2011 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import <Foundation/Foundation.h>
#import "MBProgressHUD.h"

@interface FakeWebView : UIWebView <UIWebViewDelegate, MBProgressHUDDelegate> {
    MBProgressHUD *HUD;
    NSString *spinnerText;
}

- (void) openUrl: (NSString *) url showingLoadingText: (NSString *) spinnerText;
@end
