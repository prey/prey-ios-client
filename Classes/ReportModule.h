//
//  ReportModule.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 14/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "ASIFormDataRequest.h"
#import "DataModule.h"

@interface ReportModule : DataModule
{
	NSMutableDictionary *reportData;
    UIImage *picture;
    
    NSTimer     *runReportTimer;
    NSDate      *lastExecution;
}

@property BOOL waitForLocation, waitForPicture;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) UIImage *picture;
@property (nonatomic, retain) NSMutableDictionary *reportData;

@property (nonatomic, retain) NSTimer   *runReportTimer;

+(ReportModule *)instance;
- (void) send;
- (void) stopSendReport;
- (void) fillReportData:(ASIFormDataRequest*) request;
@end