#include "ReviewRequest.h"

static NSString * const KeyReviewed = @"ReviewRequestReviewedForVersion";
static NSString * const KeyDontAsk = @"ReviewRequestDontAsk";
static NSString * const KeyNextTimeToAsk = @"ReviewRequestNextTimeToAsk";
static NSString * const KeySessionCountSinceLastAsked = @"ReviewRequestSessionCountSinceLastAsked";


@interface ReviewRequestDelegate : NSObject < UIAlertViewDelegate >
{
}

@end

@implementation ReviewRequestDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

	switch (buttonIndex)
	{
	case 0: // remind me later
	{
		const double nextTime = CFAbsoluteTimeGetCurrent() + 60*60*23; // check again in 23 hours
		[defaults setDouble:nextTime forKey:KeyNextTimeToAsk];
		break;
	}
	
	case 1: // rate it now
	{
		NSString* version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
		[defaults setValue:version forKey:KeyReviewed];

		NSString* iTunesLink = @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=456755037";
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
		break;
	}
	
	case 2: // don't ask again
    {
		[defaults setBool:true forKey:KeyDontAsk];
		break;
    }
	default:
		break;
	}

	[defaults setInteger:0 forKey:KeySessionCountSinceLastAsked];
	[self release];
}


@end



bool ReviewRequest::ShouldAskForReview()
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults boolForKey:KeyDontAsk])
		return false;

	NSString* version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
	NSString* reviewedVersion = [defaults stringForKey:KeyReviewed];
	if ([reviewedVersion isEqualToString:version])
		return false;

	const double currentTime = CFAbsoluteTimeGetCurrent();
	if ([defaults objectForKey:KeyNextTimeToAsk] == nil)
	{
		const double nextTime = currentTime + 60*60*23*1;  // 1 days (minus 2 hours)
		[defaults setDouble:nextTime forKey:KeyNextTimeToAsk];
		return false;
	}
	
	const double nextTime = [defaults doubleForKey:KeyNextTimeToAsk];
	if (currentTime < nextTime)
		return false;

	return true;
}


bool ReviewRequest::ShouldAskForReviewAtLaunch()
{
	if (!ShouldAskForReview())
		return false;
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	const int count = [defaults integerForKey:KeySessionCountSinceLastAsked];
	[defaults setInteger:count+1 forKey:KeySessionCountSinceLastAsked];
	
	if (count < 12)
		return false;

	return true;
}



void ReviewRequest::AskForReview()
{
	ReviewRequestDelegate* delegate = [[ReviewRequestDelegate alloc] init];
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Enjoying Prey?" 
					message:@"If so, please rate this update with 5 stars on the App Store so we can keep the free updates coming."						  
					delegate:delegate cancelButtonTitle:@"Remind me later" otherButtonTitles:@"Yes, rate it!", @"Don't ask again", nil];
	[alert show];
	[alert release];
}



