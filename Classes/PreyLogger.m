//
//  PreyLogger.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 28/03/2011.
//  Copyright 2011 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "PreyLogger.h"
#import "Constants.h"
#import "LoggerClient.h"


void PreyLogMessage(NSString *domain, int level, NSString *format, ...)
{

    if (SHOULD_LOG) {
        va_list args;
        va_start(args, format);
        NSString *msgString = [[NSString alloc] initWithFormat:format arguments:args];
        if (msgString != nil)
        {
            LogMessage(domain, level, @"%@",msgString);
        }
        
        va_end(args);
    }
    
}

void PreyLogMessageAndFile(NSString *domain, int level, NSString *format, ...)
{
    if (SHOULD_LOG) {
        va_list args;
        va_start(args, format);
        NSString *msgString = [[NSString alloc] initWithFormat:format arguments:args];
        if (msgString != nil)
        {
            LogMessage(domain, level, @"%@",msgString);
            NSLog(@"%@",msgString);
            [PreyLogger LogToFile:msgString];
        }
        va_end(args);
    }
    
}

@implementation PreyLogger
+ (NSString*)logFilePath {
    NSString* path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
	return [path stringByAppendingPathComponent:@"prey.log"];
}

+(void) LogToFile:(NSString*)msg{
    
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	[formatter setTimeStyle:NSDateFormatterMediumStyle];
	NSString *logMessage = [NSString stringWithFormat:@"%@ %@", [formatter stringFromDate:[NSDate date]], msg];
    
	NSString *fileName = [PreyLogger logFilePath];
	FILE * f = fopen([fileName cStringUsingEncoding:NSStringEncodingConversionAllowLossy], "at");
	fprintf(f, "%s\n", [logMessage cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
	fclose (f);
}

+ (void) clearLogFile
{
	NSString * content = @"";
	NSString * fileName = [PreyLogger logFilePath];
	[content writeToFile:fileName 
              atomically:NO 
                encoding:NSStringEncodingConversionAllowLossy 
                   error:nil];
}

+ (NSArray*) getLogArray
{
	NSString * fileName = [PreyLogger logFilePath];
	NSString *content = [NSString stringWithContentsOfFile:fileName
                                              usedEncoding:nil error:nil];
	NSMutableArray * array = (NSMutableArray *)[content componentsSeparatedByString:@"\n"];
	NSMutableArray * newArray = [[NSMutableArray alloc] init];
	for (int i = 0; i < [array count]; i++)
	{
		NSString * item = [array objectAtIndex:i];
		if ([item length])
			[newArray addObject:item];
	}
	return (NSArray*)newArray;
}

+ (NSString*) logAsText {
    NSString * fileName = [PreyLogger logFilePath];
	NSString *content = [NSString stringWithContentsOfFile:fileName
                                              usedEncoding:nil error:nil];
    return content;
}

@end
