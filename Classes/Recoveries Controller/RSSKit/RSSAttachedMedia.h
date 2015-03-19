//
// RSSAttachedMedia.h
// RSSKit
//
// Created by Árpád Goretity on 21/12/2011.
// Licensed under a CreativeCommons Attribution 3.0 Unported License
//

#import <Foundation/Foundation.h>


@interface RSSAttachedMedia: NSObject {
	NSString *url;
	int length;
	NSString *type;
}

@property (nonatomic, retain) NSString *url;
@property (nonatomic, assign) int length;
@property (nonatomic, retain) NSString *type;

@end

