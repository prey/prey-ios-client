//
// NSMutableString+RSSKit.m
// RSSKit
//
// Created by Árpád Goretity on 11/11/2011.
// Licensed under a CreativeCommons Attribution 3.0 Unported License
//

#import "NSMutableString+RSSKit.h"


@implementation NSMutableString (RSSKit)

- (void) appendPathComponent:(NSString *)path {
	NSString *tmp = [self stringByAppendingPathComponent:path];
	[self setString:tmp];
}

- (void) deleteLastPathComponent {
	NSString *tmp = [self stringByDeletingLastPathComponent];
	[self setString:tmp];
}

@end

