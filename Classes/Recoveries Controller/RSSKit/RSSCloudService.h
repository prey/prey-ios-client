//
// RSSCloudService.h
// RSSKit
//
// Created by Árpád Goretity on 21/12/2011.
// Licensed under a CreativeCommons Attribution 3.0 Unported License
//

#import <Foundation/Foundation.h>


@interface RSSCloudService: NSObject {
	NSString *domain;
	int port;
	NSString *path;
	NSString *procedure;
	NSString *protocol;
}

@property (nonatomic, retain) NSString *domain;
@property (nonatomic, assign) int port;
@property (nonatomic, retain) NSString *path;
@property (nonatomic, retain) NSString *procedure;
@property (nonatomic, retain) NSString *protocol;

@end

