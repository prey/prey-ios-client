//
//  AccuracyManager.h
//  Prey
//
//  Created by Carlos Yaconi on 25/02/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AccuracyManager : NSObject {
	NSArray *accuracyNames;
	NSArray *accuracyValues;
	NSDictionary *accuracyData;
}

- (NSString *) nameFor:(NSInteger)value;
- (NSInteger) pickerCount;
- (void) setSelectedAccuracyRow:(NSInteger)value;
- (void) showPicker:(UIPickerView *)picker onView:(UIView *)view fromTableView:(UITableView *)tableView;
- (void) hidePicker:(UIPickerView *)picker onView:(UIView *)view fromTableView:(UITableView *)tableView;
@end
