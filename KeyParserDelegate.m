//
//  KeyParserDelegate.m
//  Prey
//
//  Created by Carlos Yaconi on 30/09/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "KeyParserDelegate.h"

@interface KeyParserDelegate ()
	@property (nonatomic) BOOL areInKeyNode; 
@end

@implementation KeyParserDelegate

@synthesize key,areInKeyNode;


- (NSString*) parseKey:(NSData *)request parseError:(NSError **)err {
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
	return self.key;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict 
{
	if ([elementName isEqualToString:@"key"]) 
		self.areInKeyNode = YES;
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	if ([elementName isEqualToString:@"key"]) 
		self.areInKeyNode = NO;
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if (areInKeyNode)
		self.key = string;
}

- (void) dealloc {
	[super dealloc];
	[key release];
}

@end
