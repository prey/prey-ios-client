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
	
	accuracyNames = [[NSArray alloc] initWithObjects:NSLocalizedString(@"Most accurate possible",nil),
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

- (NSInteger) pickerCount {
	return [accuracyData count];
}
- (void) setSelectedAccuracyRow:(NSInteger)value {
	PreyConfig *config = [PreyConfig instance];
	config.desiredAccuracy = [accuracyValues objectAtIndex:value];

}
- (NSString *) nameFor:(NSInteger)value {
	return [accuracyNames objectAtIndex:value];
}

- (void) showPicker:(UIPickerView *)picker onView:(UIView *)view fromTableView:(UITableView *)tableView {

	picker.showsSelectionIndicator = YES;
	
	//TODO: Seleccionar el valor por defecto que debe mostrarse en el picker!!
	//[picker selectRow:<#(NSInteger)row#> inComponent:<#(NSInteger)component#> animated:<#(BOOL)animated#>
	[view.window addSubview: picker];
	
	// size up the picker view to our screen and compute the start/end frame origin for our slide up animation
	//
	// compute the start frame
	CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
	CGSize pickerSize = [picker sizeThatFits:CGSizeZero];
	CGRect startRect = CGRectMake(0.0,
								  screenRect.origin.y + screenRect.size.height,
								  pickerSize.width, pickerSize.height);
	picker.frame = startRect;
	
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
	
	picker.frame = pickerRect;
	
	// shrink the table vertical size to make room for the date picker
	CGRect newFrame = tableView.frame;
	newFrame.size.height -= picker.frame.size.height;
	tableView.frame = newFrame;
	[UIView commitAnimations];
	
}

- (void) hidePicker:(UIPickerView *)picker onView:(UIView *)view fromTableView:(UITableView *)tableView{
	CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
	CGRect endFrame = picker.frame;
	endFrame.origin.y = screenRect.origin.y + screenRect.size.height;
	
	// start the slide down animation
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	
	// we need to perform some post operations after the animation is complete
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(slideDownDidStop:)];
	
	picker.frame = endFrame;
	[UIView commitAnimations];
	// grow the table back again in vertical size to make room for the date picker
	CGRect newFrame = tableView.frame;
	newFrame.size.height += picker.frame.size.height;
	tableView.frame = newFrame;
}

- (void)slideDownDidStop:(UIPickerView *) picker
{
	[picker removeFromSuperview];
}
	
- (NSString *) accuracyNameForValue:(NSNumber *)value {
	return (NSString *) [accuracyData objectForKey:value];
}
@end
