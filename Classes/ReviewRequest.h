//
//  ReviewRequest.h
//  Prey-iOS
//
//  Created by Javier Cala Uribe on 11/09/2014.
//  Copyright 2011 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import <Foundation/Foundation.h>


@interface ReviewRequest : NSObject <UIAlertViewDelegate>{
    
}

+ (bool)shouldAskForReview;
+ (bool)shouldAskForReviewAtLaunch;
+ (void)askForReview;

@end
