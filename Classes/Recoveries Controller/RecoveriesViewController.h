//
//  ViewController.h
//  Prey
//
//  Created by Javier Cala Uribe on 19/3/15.
//  Copyright (c) 2015 Javier Cala Uribe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "GAITrackedViewController.h"
#import "RSSKit.h"

@interface RecoveriesViewController : GAITrackedViewController <UITableViewDataSource, UITableViewDelegate, RSSParserDelegate, MBProgressHUDDelegate>
{
    MBProgressHUD *HUD;
    UITableView *tableViewInfo;
    NSMutableArray *postArray;
}

@property (nonatomic) UITableView *tableViewInfo;
@property (nonatomic, strong) NSMutableArray *postArray;

@end