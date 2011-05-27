//
//  DelayManager.m
//  Prey
//
//  Created by Carlos Yaconi on 01/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DelayManager.h"
#import "PreyConfig.h"


@implementation DelayManager
@synthesize delayValues;

- (id)init {
	self = [super init];
	
	delayNames = [[NSArray alloc] initWithObjects:
                  //NSLocalizedString(@"None: Send everything.",nil),
                  //NSLocalizedString(@"30 secs.",nil),
				  NSLocalizedString(@"2 mins.",nil),
				   NSLocalizedString(@"5 mins.",nil),
				   NSLocalizedString(@"10 mins.",nil),
				   NSLocalizedString(@"20 mins.",nil),
				   NSLocalizedString(@"45 mins.",nil),
				   NSLocalizedString(@"60 mins.",nil),
				   nil];
	delayKeys = [[NSArray alloc] initWithObjects:
                 //[NSNumber numberWithInt:0],
                 //[NSNumber numberWithInt:0.5*60],
				 [NSNumber numberWithInt:2*60],
				 [NSNumber numberWithInt:5*60],
				 [NSNumber numberWithInt:10*60],
				 [NSNumber numberWithInt:20*60],
				 [NSNumber numberWithInt:45*60],
				 [NSNumber numberWithInt:60*60],
				 nil];
	
	self.delayValues = [NSDictionary dictionaryWithObjects:delayNames forKeys:delayKeys];
	
	return self;
}



- (NSString *) currentDelay {
	PreyConfig *config = [PreyConfig instance];
	NSString *currenDelay = [delayValues objectForKey:[NSNumber numberWithInt:config.delay]];
	return currenDelay;
}


- (void) showDelayPickerOnView:(UIView *)view fromTableView:(UITableView *)tableView {
	
    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    
	delayPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 200, screenRect.size.width, 200)];
	delayPicker.delegate = self;
	delayPicker.showsSelectionIndicator = YES;
	
	PreyConfig *config = [PreyConfig instance];
	
	if (config.delay != 0) {
		NSInteger index = [delayKeys indexOfObject:[NSNumber numberWithInt:config.delay]];
		[delayPicker selectRow:index inComponent:0 animated:YES];
	}
	
	[view.window addSubview: delayPicker];
	
	// size up the picker view to our screen and compute the start/end frame origin for our slide up animation
	//
	// compute the start frame
	
	CGSize pickerSize = [delayPicker sizeThatFits:CGSizeZero];
	CGRect startRect = CGRectMake(0.0,
								  screenRect.origin.y + screenRect.size.height,
								  pickerSize.width, pickerSize.height);
	delayPicker.frame = startRect;
	
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
	
	delayPicker.frame = pickerRect;
	
	// shrink the table vertical size to make room for the date picker
	CGRect newFrame = tableView.frame;
	newFrame.size.height -= delayPicker.frame.size.height;
	tableView.frame = newFrame;
	[UIView commitAnimations];
	
}

- (void) hideDelayPickerOnView:(UIView *)view fromTableView:(UITableView *)tableView{
	CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
	CGRect endFrame = delayPicker.frame;
	endFrame.origin.y = screenRect.origin.y + screenRect.size.height;
	
	// start the slide down animation
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	
	// we need to perform some post operations after the animation is complete
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(slideDownDidStop)];
	
	delayPicker.frame = endFrame;
	[UIView commitAnimations];
	// grow the table back again in vertical size to make room for the date picker
	CGRect newFrame = tableView.frame;
	newFrame.size.height += delayPicker.frame.size.height;
	tableView.frame = newFrame;
}

- (void)slideDownDidStop
{
	[delayPicker removeFromSuperview];
}

#pragma mark -
#pragma mark Picker datasource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
	return [delayValues count];
}

#pragma mark -
#pragma mark Picker delegate
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	return [delayNames objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	PreyConfig *config = [PreyConfig instance];
	config.delay = [(NSNumber*)[delayKeys objectAtIndex:row] intValue];
}


- (void)dealloc {
    [super dealloc];
	[delayValues release];
	[delayNames release];
	[delayKeys release];
	[delayPicker release];
}

@end
