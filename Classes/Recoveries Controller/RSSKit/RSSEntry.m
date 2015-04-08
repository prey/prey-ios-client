//
// RSSEntry.m
// RSSKit
//
// Created by Árpád Goretity on 01/11/2011.
// Licensed under a CreativeCommons Attribution 3.0 Unported License
//

#import "RSSEntry.h"


@implementation RSSEntry

@synthesize title;
@synthesize url;
@synthesize uid;
@synthesize date;
@synthesize summary;
@synthesize categories;
@synthesize comments;
@synthesize content;
@synthesize copyright;
@synthesize attachedMedia;
@synthesize author;

- (id) init {
	self = [super init];
	NSMutableArray *theCategories = [[NSMutableArray alloc] init];
	self.categories = theCategories;
	[theCategories release];
	return self;
}

- (void) dealloc {
	self.title = NULL;
	self.url = NULL;
	self.uid = NULL;
	self.date = NULL;
	self.summary = NULL;
	self.categories = NULL;
	self.comments = NULL;
	self.content = NULL;
	self.copyright = NULL;
	self.attachedMedia = NULL;
	self.author = NULL;
	[super dealloc];
}

@end

