//
//  IphoneInformationHelper.h
//  Prey
//
//  Created by Carlos Yaconi on 30/09/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
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
	
	@property (nonatomic,retain) NSString *name;
	@property (nonatomic,retain) NSString *type;
	@property (nonatomic,retain) NSString *os;
	@property (nonatomic,retain) NSString *version;
	@property (nonatomic,retain) NSString *macAddress;
    @property (nonatomic,retain) NSString *vendor;
    @property (nonatomic,retain) NSString *model;
    @property (nonatomic,retain) NSString *uuid;

+(IphoneInformationHelper*) initializeWithValues;

@end
