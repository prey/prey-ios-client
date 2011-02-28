//
//  AccuracyManager.h
//  Prey
//
//  Created by Carlos Yaconi on 25/02/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AccuracyManager : NSObject <UIPickerViewDelegate, UIPickerViewDataSource>{
	NSArray *accuracyNames;
	NSArray *accuracyValues;
	NSDictionary *accuracyData;
	UIPickerView *accPicker;
}

- (NSString *) currentlySelectedName;
- (void) showPickerOnView:(UIView *)view fromTableView:(UITableView *)tableView;
- (void) hidePickerOnView:(UIView *)view fromTableView:(UITableView *)tableView;
@end
