//
//  RestHttpUser.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 18-03-10.
//  Copyright 2010 Fork Ltd.. All rights reserved.
//

#import "PreyRestHttp.h"

@interface PreyRestHttpV2 : PreyRestHttp

+ (void)checkGeofenceZones:(NSInteger)reload withBlock:(void (^)(NSHTTPURLResponse *response, NSError *error))block;


@end
