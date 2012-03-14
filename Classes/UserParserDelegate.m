//
//  UserParserDelegate.m
//  Prey
//
//  Created by Diego Torres on 3/14/12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import "UserParserDelegate.h"

@interface UserParserDelegate ()
@property (nonatomic) enum UserProfileNode currentNode;
@property (nonatomic, retain) User *user;

@end

@implementation UserParserDelegate

@synthesize currentNode, user;


- (NSString*)parseRequest:(NSData *)request forUser:(User*)user parseError:(NSError **)err {
    self.user = user;
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
	return self.user.apiKey;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict 
{
	if ([elementName isEqualToString:@"key"]) 
		self.currentNode = UserProfileNodeKey;
    else if ([elementName isEqualToString:@"pro_account"])
        self.currentNode = UserProfileNodeProAccount;
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	self.currentNode = UserProfileNodeUnknown;
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    
	if (currentNode == UserProfileNodeKey) {
        self.user.apiKey = string;
    } else if (currentNode == UserProfileNodeProAccount) {
        self.user.pro = [string isEqualToString:@"true"];
    }
}

- (void) dealloc {
    [user release];
	[super dealloc];
}

@end
