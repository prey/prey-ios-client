//
//  LogController.h
//  Prey
//
//  Created by Carlos Yaconi on 28/03/2011.
//  Copyright 2011 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#define DELETE_LOG_BUTTON 1
#define SEND_LOG_BUTTON 2
#define REFRESH_LOG_BUTTON 3

@interface LogController : UITableViewController<MFMailComposeViewControllerDelegate, UIActionSheetDelegate> {
    UIToolbar *toolbar;
    NSArray *logArray;
}

@end
