//
//  ErrorParserDelegate.h
//  Prey
//
//  Created by Carlos Yaconi on 01/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ErrorParserDelegate : NSObject  <NSXMLParserDelegate> {
	NSMutableArray *errors;
	BOOL areInErrorsList;
	BOOL areInErrorElement;

}
@property (nonatomic, retain) NSMutableArray *errors;

- (NSMutableArray*) parseErrors:(NSData *)request parseError:(NSError **)err;
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict;
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string;

@end
