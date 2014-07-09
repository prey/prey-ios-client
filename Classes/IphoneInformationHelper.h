//
//  IphoneInformationHelper.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 30/09/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import <Foundation/Foundation.h>


@interface IphoneInformationHelper : NSObject {
		NSString *name;
		NSString *type;
		NSString *os;
		NSString *version;
		NSString *macAddress;	
        NSString *vendor;
        NSString *model;
        NSString *uuid;
	}
	
	@property (nonatomic) NSString *name;
	@property (nonatomic) NSString *type;
	@property (nonatomic) NSString *os;
	@property (nonatomic) NSString *version;
	@property (nonatomic) NSString *macAddress;
    @property (nonatomic) NSString *vendor;
    @property (nonatomic) NSString *model;
    @property (nonatomic) NSString *uuid;

+(IphoneInformationHelper*) initializeWithValues;

@end
