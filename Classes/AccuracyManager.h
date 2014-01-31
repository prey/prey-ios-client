//
//  AccuracyManager.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 25/02/2011.
//  Copyright 2011 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import <Foundation/Foundation.h>


@interface AccuracyManager : NSObject <UIPickerViewDelegate, UIPickerViewDataSource>{
	NSArray *accuracyNames;
	NSArray *accuracyValues;
	NSDictionary *accuracyData;
	UIPickerView *accPicker;
    UILabel *warningLabel;
}

- (NSString *) currentlySelectedName;
- (void) showPickerOnView:(UIView *)view fromTableView:(UITableView *)tableView;
- (void) hidePickerOnView:(UIView *)view fromTableView:(UITableView *)tableView;
@end
