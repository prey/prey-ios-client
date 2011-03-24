//
//  FakeWebView.h
//  Prey
//
//  Created by Carlos Yaconi on 23/03/2011.
//  Copyright 2011 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBProgressHUD.h"

@interface FakeWebView : UIWebView <UIWebViewDelegate, MBProgressHUDDelegate> {
    MBProgressHUD *HUD;
    NSString *spinnerText;
}

- (void) openUrl: (NSString *) url showingLoadingText: (NSString *) spinnerText;
@end
