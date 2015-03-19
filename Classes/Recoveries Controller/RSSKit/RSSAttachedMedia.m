//
// RSSAttachedMedia.m
// RSSKit
//
// Created by Árpád Goretity on 21/12/2011.
// Licensed under a CreativeCommons Attribution 3.0 Unported License
//

#import "RSSAttachedMedia.h"


@implementation RSSAttachedMedia

@synthesize url;
@synthesize length;
@synthesize type;

- (void) dealloc {
	self.url = NULL;
	self.type = NULL;
	[super dealloc];
}

@end

