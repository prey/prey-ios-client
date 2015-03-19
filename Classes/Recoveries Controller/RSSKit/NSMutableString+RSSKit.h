//
// NSMutableString+RSSKit.h
// RSSKit
//
// Created by Árpád Goretity on 11/11/2011.
// Licensed under a CreativeCommons Attribution 3.0 Unported License
//

#import <Foundation/Foundation.h>


@interface NSMutableString (RSSKit)
- (void) appendPathComponent:(NSString *)path;
- (void) deleteLastPathComponent;
@end

