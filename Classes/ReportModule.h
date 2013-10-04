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
#import "Location.h"

@interface ReportModule : DataModule{

	NSMutableArray *modules;
	NSMutableDictionary *reportData;
    UIImage *picture;
    
    Location    *location;
    NSTimer     *runReportTimer;
    NSDate      *lastExecution;
}

@property (nonatomic, retain) NSMutableArray *modules;
@property BOOL waitForLocation, waitForPicture;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) UIImage *picture;
@property (nonatomic, retain) NSMutableDictionary *reportData;

@property (nonatomic, retain) Location  *location;
@property (nonatomic, retain) NSTimer   *runReportTimer;

- (void) send;
- (NSMutableDictionary *) getReportData;
- (void) fillReportData:(ASIFormDataRequest*) request;
@end