//
//  AccuracyManager.m
//  Prey
//
//  Created by Carlos Yaconi on 25/02/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AccuracyManager.h"
#import "PreyConfig.h"


@implementation AccuracyManager

- (id)init {
	self = [super init];
	
	accuracyNames = [[NSArray alloc] initWithObjects:NSLocalizedString(@"Best possible",nil),
					 NSLocalizedString(@"Quite accurate",nil),
					 NSLocalizedString(@"Nearest 10 meters",nil),
					 NSLocalizedString(@"Hundred of Meters",nil),
					 NSLocalizedString(@"One kilometer",nil),
					 NSLocalizedString(@"Nearest 3 kilometers",nil),
					 nil];
	accuracyValues = [[NSArray alloc] initWithObjects:[NSNumber numberWithDouble:kCLLocationAccuracyBestForNavigation],
					  [NSNumber numberWithDouble:kCLLocationAccuracyBest],
					  [NSNumber numberWithDouble:kCLLocationAccuracyNearestTenMeters],
					  [NSNumber numberWithDouble:kCLLocationAccuracyHundredMeters],
					  [NSNumber numberWithDouble:kCLLocationAccuracyKilometer],
					  [NSNumber numberWithDouble:kCLLocationAccuracyThreeKilometers],
					  nil];
	
	accuracyData = [NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Most accurate possible",nil),[NSNumber numberWithDouble:kCLLocationAccuracyBestForNavigation], 
					NSLocalizedString(@"Quite accurate",nil),[NSNumber numberWithDouble:kCLLocationAccuracyBest],
					NSLocalizedString(@"Nearest 10 meters",nil),[NSNumber numberWithDouble:kCLLocationAccuracyNearestTenMeters],
					NSLocalizedString(@"Hundred of Meters",nil),[NSNumber numberWithDouble:kCLLocationAccuracyHundredMeters],
					NSLocalizedString(@"One kilometer",nil),[NSNumber numberWithDouble:kCLLocationAccuracyKilometer],
					NSLocalizedString(@"Nearest 3 kilometers",nil),[NSNumber numberWithDouble:kCLLocationAccuracyThreeKilometers],nil];

	return self;
 }



- (NSString *) currentlySelectedName {
	PreyConfig *config = [PreyConfig instance];
	NSInteger index = [accuracyValues indexOfObject:[NSNumber numberWithDouble:config.desiredAccuracy]];
	return [accuracyNames objectAtIndex:index];
}

- (NSString *) accuracyNameForValue:(NSNumber *)value {
	return (NSString *) [accuracyData objectForKey:value];
}

- (void) showPickerOnView:(UIView *)view fromTableView:(UITableView *)tableView {
	
	accPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 200, 320, 200)];
	accPicker.delegate = self;
	accPicker.showsSelectionIndicator = YES;
	
	PreyConfig *config = [PreyConfig instance];
	
	if (config.desiredAccuracy != 0) {
		NSInteger index = [accuracyValues indexOfObject:[NSNumber numberWithDouble:config.desiredAccuracy]];
		[accPicker selectRow:index inComponent:0 animated:YES];
	}
	
	[view.window addSubview: accPicker];
	
	// size up the picker view to our screen and compute the start/end frame origin for our slide up animation
	//
	// compute the start frame
	CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
	CGSize pickerSize = [accPicker sizeThatFits:CGSizeZero];
	CGRect startRect = CGRectMake(0.0,
								  screenRect.origin.y + screenRect.size.height,
								  pickerSize.width, pickerSize.height);
	accPicker.frame = startRect;
	
	// compute the end frame
	CGRect pickerRect = CGRectMake(0.0,
								   screenRect.origin.y + screenRect.size.height - pickerSize.height,
								   pickerSize.width,
								   pickerSize.height);
	// start the slide up animation
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	
	// we need to perform some post operations after the animation is complete
	[UIView setAnimationDelegate:self];
	
	accPicker.frame = pickerRect;
	
	// shrink the table vertical size to make room for the date picker
	CGRect newFrame = tableView.frame;
	newFrame.size.height -= accPicker.frame.size.height;
	tableView.frame = newFrame;
	[UIView commitAnimations];
	
}

- (void) hidePickerOnView:(UIView *)view fromTableView:(UITableView *)tableView{
	CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
	CGRect endFrame = accPicker.frame;
	endFrame.origin.y = screenRect.origin.y + screenRect.size.height;
	
	// start the slide down animation
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	
	// we need to perform some post operations after the animation is complete
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(slideDownDidStop)];
	
	accPicker.frame = endFrame;
	[UIView commitAnimations];
	// grow the table back again in vertical size to make room for the date picker
	CGRect newFrame = tableView.frame;
	newFrame.size.height += accPicker.frame.size.height;
	tableView.frame = newFrame;
}

- (void)slideDownDidStop
{
	[accPicker removeFromSuperview];
}
	
#pragma mark -
#pragma mark Picker datasource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
	return [accuracyValues count];
}

#pragma mark -
#pragma mark Picker delegate
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	return [accuracyNames objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	PreyConfig *config = [PreyConfig instance];
	config.desiredAccuracy = [(NSNumber *)[accuracyValues objectAtIndex:row] doubleValue];
}




- (void)dealloc {
    [super dealloc];
	[accuracyNames release];
	[accuracyValues release];
	[accuracyData release];
	[accPicker release];
}
@end
