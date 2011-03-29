//
//  PreyLogger.h
//  Prey
//
//  Created by Carlos Yaconi on 28/03/2011.
//  Copyright 2011 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

extern void PreyLogMessage(NSString *domain, int level, NSString *format, ...);
extern void PreyLogMessageAndFile(NSString *domain, int level, NSString *format, ...);

@interface PreyLogger : NSObject {
    
}

+ (void) LogToFile:(NSString*)msg;
+ (void) clearLogFile;
+ (NSArray*) getLogArray;
+ (NSString*) logAsText;

@end
