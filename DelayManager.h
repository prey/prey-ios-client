//
//  DelayManager.h
//  Prey
//
//  Created by Carlos Yaconi on 01/03/2011.
//  Copyright 2011 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DelayManager : NSObject <UIPickerViewDelegate, UIPickerViewDataSource>{
	NSArray *delayNames;
	NSArray *delayKeys;
	NSDictionary *delayValues;
	UIPickerView *delayPicker;
}

- (NSString *) currentDelay;
- (void) showDelayPickerOnView:(UIView *)view fromTableView:(UITableView *)tableView;
- (void) hideDelayPickerOnView:(UIView *)view fromTableView:(UITableView *)tableView;
@property (nonatomic, retain) NSDictionary *delayValues;

@end
