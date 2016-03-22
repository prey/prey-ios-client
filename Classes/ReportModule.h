//
//  ReportModule.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 14/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "DataModule.h"

@interface ReportModule : DataModule
{
	NSMutableDictionary *reportData;
    UIImage *picture;
    UIImage *pictureBack;
    
    NSTimer     *runReportTimer;
    NSDate      *lastExecution;
}

@property BOOL waitForLocation, waitForPicture;
@property (nonatomic) NSString *url;
@property (nonatomic) UIImage *picture;
@property (nonatomic) UIImage *pictureBack;
@property (nonatomic) NSMutableDictionary *reportData;
@property (nonatomic) NSTimer   *runReportTimer;

+ (ReportModule *)instance;
- (void)send;
- (void)stop;

@end