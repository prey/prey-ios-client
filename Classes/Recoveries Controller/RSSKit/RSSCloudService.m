//
// RSSCloudService.m
// RSSKit
//
// Created by Árpád Goretity on 21/12/2011.
// Licensed under a CreativeCommons Attribution 3.0 Unported License
//

#import "RSSCloudService.h"


@implementation RSSCloudService

@synthesize domain;
@synthesize port;
@synthesize path;
@synthesize procedure;
@synthesize protocol;

- (void) dealloc {
	self.domain = NULL;
	self.path = NULL;
	self.procedure = NULL;
	self.protocol = NULL;
	[super dealloc];
}

@end

