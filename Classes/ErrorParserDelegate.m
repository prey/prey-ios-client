//
//  ErrorParserDelegate.m
//  Prey
//
//  Created by Carlos Yaconi on 01/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "ErrorParserDelegate.h"


@implementation ErrorParserDelegate

@synthesize errors;

- (NSMutableArray*) parseErrors:(NSData *)request parseError:(NSError **)err
{
	self.errors = [[NSMutableArray alloc] init];
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:request];
	
	[parser setDelegate:self];
	
	[parser setShouldProcessNamespaces:NO]; // We don't care about namespaces
	[parser setShouldReportNamespacePrefixes:NO]; //
	[parser setShouldResolveExternalEntities:NO]; // We just want data, no other stuff
	
	[parser parse]; // Parse that data..
	
	if (err && [parser parserError]) {
		*err = [parser parserError];
	}

	[parser release];
	return self.errors;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict 
{
	if ([elementName isEqualToString:@"errors"]) 
		*areInErrorsList = YES;
	if ([elementName isEqualToString:@"error"]) 
		*areInErrorElement = YES;
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	if ([elementName isEqualToString:@"errors"]) 
		*areInErrorsList = NO;
	if ([elementName isEqualToString:@"error"]) 
		*areInErrorElement = NO;
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if (areInErrorsList && areInErrorElement)
		[errors addObject:string];
}

- (void) dealloc {
	[super dealloc];
	[errors release];
}

@end
