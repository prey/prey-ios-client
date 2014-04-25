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

@class PhotoController;

@interface ReportModule : DataModule
{
	NSMutableDictionary *reportData;
    UIImage *picture;
    UIImage *pictureBack;
    
    NSTimer     *runReportTimer;
    NSDate      *lastExecution;
    
    PhotoController *photoController;
}

@property BOOL waitForLocation, waitForPicture;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) UIImage *picture;
@property (nonatomic, retain) UIImage *pictureBack;
@property (nonatomic, retain) NSMutableDictionary *reportData;

@property (nonatomic, retain) NSTimer   *runReportTimer;

@property (nonatomic, retain) PhotoController *photoController;

+(ReportModule *)instance;
- (void) send;
- (void) stopSendReport;
@end