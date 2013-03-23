//
//  Report.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 14/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h> 
#import "ASIFormDataRequest.h"

@interface Report : NSObject {
	NSMutableArray *modules;
	NSMutableDictionary *reportData;
    UIImage *picture;
}

@property (nonatomic, retain) NSMutableArray *modules;
@property BOOL waitForLocation, waitForPicture;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) UIImage *picture;
@property (nonatomic, retain) NSMutableDictionary *reportData;

- (void) send;
- (NSMutableDictionary *) getReportData;
- (void) fillReportData:(ASIFormDataRequest*) request;
@end
