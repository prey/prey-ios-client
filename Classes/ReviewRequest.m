//
//  ReviewRequest.m
//  Prey-iOS
//
//  Created by Javier Cala Uribe on 11/09/2014.
//  Copyright 2011 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//
#include "ReviewRequest.h"
#include "Constants.h"

#define APP_ID 456755037

static NSString *const iOS7AppStoreURLFormat = @"itms-apps://itunes.apple.com/app/id%d";
static NSString *const iOSAppStoreURLFormat = @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%d";
static NSString * const KeyReviewed = @"ReviewRequestReviewedForVersion";
static NSString * const KeyDontAsk = @"ReviewRequestDontAsk";
static NSString * const KeyNextTimeToAsk = @"ReviewRequestNextTimeToAsk";
static NSString * const KeySessionCountSinceLastAsked = @"ReviewRequestSessionCountSinceLastAsked";

@implementation ReviewRequest

+ (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

	switch (buttonIndex)
	{
	case 0: // remind me later
	{
		const double nextTime = CFAbsoluteTimeGetCurrent() + 60*60*23*30; // check again in 23 hours
		[defaults setDouble:nextTime forKey:KeyNextTimeToAsk];
		break;
	}
	
	case 1: // rate it now
	{
		NSString* version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
		[defaults setValue:version forKey:KeyReviewed];

        NSString *iTunesLink;
        if (IS_OS_7_OR_LATER)
            iTunesLink = [NSString stringWithFormat:iOS7AppStoreURLFormat,APP_ID];
        else
            iTunesLink = [NSString stringWithFormat:iOSAppStoreURLFormat, APP_ID];
		
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
}

+ (bool)shouldAskForReview
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

    if ([defaults boolForKey:@"SendReport"])
        return false;
    
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

+ (bool)shouldAskForReviewAtLaunch
{
	if (![self shouldAskForReview])
		return false;
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	const int count = (int)[defaults integerForKey:KeySessionCountSinceLastAsked];
	[defaults setInteger:count+1 forKey:KeySessionCountSinceLastAsked];
	
	if (count < 12)
		return false;

	return true;
}

+ (void)askForReview
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Rate us", nil)
                                                    message:NSLocalizedString(@"Give us ★★★★★ on the App Store if you like Prey.", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Remind me later", nil)
                                          otherButtonTitles:NSLocalizedString(@"Yes, rate Prey!", nil), nil];
	[alert show];
}

@end