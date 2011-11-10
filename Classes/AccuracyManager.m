//
//  AccuracyManager.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 25/02/2011.
//  Copyright 2011 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "AccuracyManager.h"
#import "PreyConfig.h"


@implementation AccuracyManager

- (id)init {
	self = [super init];
	
	accuracyNames = [[NSArray alloc] initWithObjects:NSLocalizedString(@"Best possible",nil),
					 NSLocalizedString(@"Quite accurate",nil),
					 NSLocalizedString(@"Nearest 10 meters",nil),
					 NSLocalizedString(@"Hundreds of Meters",nil),
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
	
	accuracyData = [NSDictionary dictionaryWithObjects:accuracyNames forKeys:accuracyValues];
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
	CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    
    
	// size up the picker view to our screen and compute the start/end frame origin for our slide up animation
	//
	// compute the start frame
	
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
    
    //Creating the label.
    warningLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 64, screenRect.size.width, screenRect.origin.y + screenRect.size.height - pickerSize.height-64)];
	[view.window addSubview:warningLabel];
	//warningLabel.font = [UIFont fontWithName:@"Zapfino" size: 14.0];
	warningLabel.shadowColor = [UIColor blackColor];
    warningLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.8];
	//warningLabel.shadowOffset = CGSizeMake(1,1);
	warningLabel.textColor = [UIColor whiteColor];
    warningLabel.textAlignment = UITextAlignmentCenter; // UITextAlignmentCenter, UITextAlignmentLeft
	warningLabel.lineBreakMode = UILineBreakModeWordWrap;
	warningLabel.numberOfLines = 0; // 2 lines ; 0 - dynamical number of lines
	warningLabel.text = @"Sets the precision of the location sensor. Higher accuracy means higher battery consumption, and longer delay between reports.\nBe careful: 'Best possible' option could drain your battery in a couple of hours!";
    warningLabel.layer.borderColor = [UIColor whiteColor].CGColor;
    warningLabel.layer.borderWidth = 3.0;
    warningLabel.userInteractionEnabled = YES;
    
    //setting label start position
    CGRect labelStartRect = CGRectMake(0.0,-100,screenRect.size.width, screenRect.origin.y + screenRect.size.height - pickerSize.height-64);
	warningLabel.frame = labelStartRect;
    
    CGRect labelEndRect = CGRectMake(0,pickerRect.origin.y-warningLabel.frame.size.height, screenRect.size.width, screenRect.origin.y + screenRect.size.height - pickerSize.height-64);
	// start the slide up animation
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	
    
	// we need to perform some post operations after the animation is complete
	[UIView setAnimationDelegate:self];
	
	accPicker.frame = pickerRect;
    warningLabel.frame = labelEndRect;
	
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
	CGRect labelEndFrame = CGRectMake(0,-100,320,100);
	// start the slide down animation
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	
	// we need to perform some post operations after the animation is complete
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(slideDownDidStop)];
	warningLabel.frame = labelEndFrame;
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
    [warningLabel removeFromSuperview];
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
	//[accuracyValues release];
	//[accuracyData release];
	[accPicker release];
}
@end
