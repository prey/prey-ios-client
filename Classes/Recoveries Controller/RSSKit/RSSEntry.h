//
// RSSEntry.h
// RSSKit
//
// Created by Árpád Goretity on 01/11/2011.
// Licensed under a CreativeCommons Attribution 3.0 Unported License
//

#import <Foundation/Foundation.h>
#import "RSSAttachedMedia.h"


@interface RSSEntry: NSObject {
	NSString *title;
	NSString *url;
	NSString *uid;
	NSString *date;
	NSString *summary;
	NSMutableArray *categories;
	NSString *comments;
	NSString *content;
	NSString *copyright;
	RSSAttachedMedia *attachedMedia;
	NSString *author;
}

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSString *uid;
@property (nonatomic, retain) NSString *date;
@property (nonatomic, retain) NSString *summary;
@property (nonatomic, retain) NSMutableArray *categories;
@property (nonatomic, retain) NSString *comments;
@property (nonatomic, retain) NSString *content;
@property (nonatomic, retain) NSString *copyright;
@property (nonatomic, retain) RSSAttachedMedia *attachedMedia;
@property (nonatomic, retain) NSString *author;

@end

