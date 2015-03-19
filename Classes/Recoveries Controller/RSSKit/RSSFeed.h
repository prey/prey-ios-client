//
// RSSFeed.h
// RSSKit
//
// Created by Árpád Goretity on 01/11/2011.
// Licensed under a CreativeCommons Attribution 3.0 Unported License
//

#import <Foundation/Foundation.h>
#import "RSSCloudService.h"
#import "RSSDefines.h"


@interface RSSFeed: NSObject {
	RSSFeedType type;
	NSString *title;
	NSString *description;
	NSString *url;
	NSString *date;
	NSString *author;
	NSMutableArray *articles;
	NSString *uid;
	NSString *language;
	NSString *copyright;
	NSMutableArray *categories;
	NSString *generator;
	NSTimeInterval validTime;
	NSString *iconUrl;
	RSSCloudService *cloudService;
}

@property (nonatomic, assign) RSSFeedType type;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSString *date;
@property (nonatomic, retain) NSString *author;
@property (nonatomic, retain) NSMutableArray *articles;
@property (nonatomic, retain) NSString *uid;
@property (nonatomic, retain) NSString *language;
@property (nonatomic, retain) NSString *copyright;
@property (nonatomic, retain) NSMutableArray *categories;
@property (nonatomic, retain) NSString *generator;
@property (nonatomic, assign) NSTimeInterval validTime;
@property (nonatomic, retain) NSString *iconUrl;
@property (nonatomic, retain) RSSCloudService *cloudService;


@end

