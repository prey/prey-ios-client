//
//  PreyDeployment.h
//  Prey
//
//  Created by Javier Cala Uribe on 21/11/13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CongratulationsController.h"

@interface PreyDeployment : NSObject

- (BOOL)isCorrect;
- (CongratulationsController*)returnViewController;

@end
