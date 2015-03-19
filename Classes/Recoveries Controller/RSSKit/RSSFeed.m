//
// RSSFeed.m
// RSSKit
//
// Created by Árpád Goretity on 01/11/2011.
// Licensed under a CreativeCommons Attribution 3.0 Unported License
//

#import "RSSFeed.h"


@implementation RSSFeed

@synthesize type;
@synthesize title;
@synthesize description;
@synthesize url;
@synthesize date;
@synthesize author;
@synthesize articles;
@synthesize uid;
@synthesize language;
@synthesize copyright;
@synthesize categories;
@synthesize generator;
@synthesize validTime;
@synthesize iconUrl;
@synthesize cloudService;

- (id) init {
	self = [super init];
	NSMutableArray *theArticles = [[NSMutableArray alloc] init];
	self.articles = theArticles;
	[theArticles release];
	NSMutableArray *theCategories = [[NSMutableArray alloc] init];
	self.categories = theCategories;
	[theCategories release];
	return self;
}

- (void) dealloc {
	self.title = NULL;
	self.description = NULL;
	self.url = NULL;
	self.date = NULL;
	self.author = NULL;
	self.articles = NULL;
	self.uid = NULL;
	self.language = NULL;
	self.copyright = NULL;
	self.categories = NULL;
	self.generator = NULL;
	self.iconUrl = NULL;
	self.cloudService = NULL;
	[super dealloc];
}

@end

