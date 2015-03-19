//
// RSSParser.m
// RSSKit
//
// Created by Árpád Goretity on 01/11/2011.
// Licensed under a CreativeCommons Attribution 3.0 Unported License
//

#import "RSSParser.h"
#import "NSMutableString+RSSKit.h"


@implementation RSSParser

@synthesize delegate;
@synthesize url;
@synthesize synchronous;

- (id) initWithUrl:(NSString *)theUrl synchronous:(BOOL)sync {
	self = [super init];
	self.url = theUrl;
	self.synchronous = sync;
	if (self.synchronous) {
		NSURL *contentUrl = [[NSURL alloc] initWithString:self.url];
		xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:contentUrl];
		[contentUrl release];
		[xmlParser setDelegate:self];
	}
	return self;
}

- (id) initWithUrl:(NSString *)theUrl {
	self = [self initWithUrl:theUrl synchronous:NO];
	return self;
}

- (id) init {
	self = [self initWithUrl:NULL];
	return self;
}

- (void) dealloc {
	[xmlParser setDelegate:NULL];
	[xmlParser release];
	self.url = NULL;
	[super dealloc];
}

// self

- (void) parse {
	if (!self.synchronous) {
		NSURL *contentUrl = [[NSURL alloc] initWithString:self.url];
		xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:contentUrl];
		[contentUrl release];
		[xmlParser setDelegate:self];
	}
	[xmlParser parse];
}

// NSXMLParserDelegate

- (void) parserDidStartDocument:(NSXMLParser *)parser {
	feed = [[RSSFeed alloc] init];
	tagStack = [[NSMutableArray alloc] init];
	tagPath = [[NSMutableString alloc] initWithString:@"/"];
}

- (void) parserDidEndDocument:(NSXMLParser *)parser {
	[tagStack release];
	[tagPath release];
	if ([delegate respondsToSelector:@selector(rssParser:parsedFeed:)]) {
		[delegate rssParser:self parsedFeed:feed];
	}
	[feed release];
}

- (void) parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)error {
	[tagStack release];
	[tagPath release];
	[feed release];
	if ([delegate respondsToSelector:@selector(rssParser:errorOccurred:)]) {
		[delegate rssParser:self errorOccurred:error];
	}
}

- (void) parser:(NSXMLParser *)parser didStartElement:(NSString *)element namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributes {
	// decide type of the feed based on its root element
	if ([element isEqualToString:@"rss"]) {
		feed.type = RSSFeedTypeRSS;
	} else if ([element isEqualToString:@"feed"]) {
		feed.type = RSSFeedTypeAtom;
	} else if ([element isEqualToString:@"item"] || [element isEqualToString:@"entry"]) {
		// or, if it's an article summary tag, create an article object
		entry = [[RSSEntry alloc] init];
	}
	// prepare to successively receive characters
	// then push element onto stack
	NSMutableDictionary *context = [[NSMutableDictionary alloc] init];
	[context setObject:attributes forKey:@"attributes"];
	NSMutableString *text = [[NSMutableString alloc] init];
	[context setObject:text forKey:@"text"];
	[text release];
	[tagStack addObject:context];
	[context release];
	[tagPath appendPathComponent:element];
}

- (void) parser:(NSXMLParser *)parser didEndElement:(NSString *)element namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName {
	NSMutableDictionary *context = [tagStack lastObject];
	NSMutableString *text = [context objectForKey:@"text"];
	NSDictionary *attributes = [context objectForKey:@"attributes"];
	if ([tagPath isEqualToString:@"/rss/channel/title"] || [tagPath isEqualToString:@"/feed/title"]) {
		feed.title = text;
	} else if ([tagPath isEqualToString:@"/rss/channel/description"] || [tagPath isEqualToString:@"/feed/subtitle"]) {
		feed.description = text;
	} else if ([tagPath isEqualToString:@"/feed/id"]) {
		feed.uid = text;
	} else if ([tagPath isEqualToString:@"/rss/channel/link"] || [tagPath isEqualToString:@"/feed/link"]) {
		// RSS 2.0 or Atom 1.0?
			NSString *href = [attributes objectForKey:@"href"];
		if (href) {
			// Atom 1.0
			feed.url = href;
		} else {
			// RSS 2.0
			feed.url = text;
		}
	} else if ([tagPath isEqualToString:@"/rss/channel/language"]) {
		feed.language = text;
	} else if ([tagPath isEqualToString:@"/rss/channel/copyright"] || [tagPath isEqualToString:@"/feed/rights"]) {
		feed.copyright = text;
	} else if ([tagPath isEqualToString:@"/rss/channel/category"] || [tagPath isEqualToString:@"/feed/category"]) {
		// RSS 2.0 or Atom 1.0?
		NSString *term = [attributes objectForKey:@"term"];
		if (term) {
			// Atom 1.0
			[feed.categories addObject:term];
		} else {
			// RSS 2.0
			[feed.categories addObject:text];
		}
		
	} else if ([tagPath isEqualToString:@"/rss/channel/generator"] || [tagPath isEqualToString:@"/feed/generator"]) {
		feed.generator = text;
	} else if ([tagPath isEqualToString:@"/rss/channel/ttl"]) {
		feed.validTime = [text floatValue];
	} else if ([tagPath isEqualToString:@"/rss/channel/image/url"] || [tagPath isEqualToString:@"/feed/icon"]) {
		feed.iconUrl = text;
	} else if ([tagPath isEqualToString:@"/rss/channel/cloud"]) {
		RSSCloudService *cloudService = [[RSSCloudService alloc] init];
		cloudService.domain = [attributes objectForKey:@"domain"];
		cloudService.port = [[attributes objectForKey:@"port"] intValue];
		cloudService.path = [attributes objectForKey:@"path"];
		cloudService.procedure = [attributes objectForKey:@"registerProcedure"];
		cloudService.protocol = [attributes objectForKey:@"protocol"];
		feed.cloudService = cloudService;
		[cloudService release];
	} else if ([tagPath isEqualToString:@"/rss/channel/lastBuildDate"] || [tagPath isEqualToString:@"/rss/channel/dc:date"] || [tagPath isEqualToString:@"/feed/updated"]) {
		feed.date = text;
	} else if ([tagPath isEqualToString:@"/rss/channel/managingEditor"]) {
		feed.author = text;
	} else if ([tagPath isEqualToString:@"/feed/author/name"]) {
		feed.author = feed.author ? [NSString stringWithFormat:@"%@ (%@)", text, feed.author] : text;
	} else if ([tagPath isEqualToString:@"/feed/author/email"]) {
		feed.author = feed.author ? [NSString stringWithFormat:@"%@ (%@)", feed.author, text] : text;
	} else if ([tagPath isEqualToString:@"/rss/channel/item/title"] || [tagPath isEqualToString:@"/feed/entry/title"]) {
		entry.title = text;
	} else if ([tagPath isEqualToString:@"/rss/channel/item/link"] || [tagPath isEqualToString:@"/feed/entry/link"]) {
		// RSS 2.0 or Atom 1.0?
		NSString *href = [attributes objectForKey:@"href"];
		if (href) {
			// Atom 1.0
			entry.url = href;
		} else {
			// RSS 2.0
			entry.url = text;
		}
	} else if ([tagPath isEqualToString:@"/rss/channel/item/description"] || [tagPath isEqualToString:@"/feed/entry/summary"]) {
		entry.summary = text;
	} else if ([tagPath isEqualToString:@"/rss/channel/item/category"] || [tagPath isEqualToString:@"/feed/entry/category"]) {
		// RSS 2.0 or Atom 1.0?
		NSString *term = [attributes objectForKey:@"term"];
		if (term) {
			// Atom 1.0
			[entry.categories addObject:term];
		} else {
			// RSS 2.0
			[entry.categories addObject:text];
		}
	} else if ([tagPath isEqualToString:@"/rss/channel/item/comments"] || [tagPath isEqualToString:@""]) {
		entry.comments = text;
	} else if ([tagPath isEqualToString:@"/rss/channel/item/author"] || [tagPath isEqualToString:@"/feed/entry/author/name"]) {
		entry.author = text;
	} else if ([tagPath isEqualToString:@"/feed/entry/content"] || [tagPath isEqualToString:@"/rss/channel/item/content:encoded"]) {
		entry.content = text;
	} else if ([tagPath isEqualToString:@"/rss/channel/item/enclosure"]) {	
		RSSAttachedMedia *media = [[RSSAttachedMedia alloc] init];
		media.url = [attributes objectForKey:@"url"];
		media.length = [[attributes objectForKey:@"length"] intValue];
		media.type = [attributes objectForKey:@"type"];
		entry.attachedMedia = media;
		[media release];
	} else if ([tagPath isEqualToString:@"/rss/channel/item/guid"] || [tagPath isEqualToString:@"/feed/entry/id"]) {
		entry.uid = text;
	} else if ([tagPath isEqualToString:@"/rss/channel/item/pubDate"] || [tagPath isEqualToString:@"/rss/channel/item/dc:date"] || [tagPath isEqualToString:@"/feed/entry/updated"]) {
		entry.date = text;
	} else if ([tagPath isEqualToString:@"/feed/entry/rights"]) {
		entry.copyright = text;
	} else if ([tagPath isEqualToString:@"/rss/channel/item"] || [tagPath isEqualToString:@"/feed/entry"]) {
		[feed.articles addObject:entry];
		[entry release];
	}
	[tagStack removeLastObject];
	[tagPath deleteLastPathComponent];
}

- (void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	NSMutableDictionary *context = [tagStack lastObject];
	NSMutableString *text = [context objectForKey:@"text"];
	[text appendString:string];
}

- (void) parser:(NSXMLParser *)parser foundCDATA:(NSData *)data {
	NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSMutableDictionary *context = [tagStack lastObject];
	NSMutableString *text = [context objectForKey:@"text"];
	[text appendString:string];
	[string release];
}

@end

