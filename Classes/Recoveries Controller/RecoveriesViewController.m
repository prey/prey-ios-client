//
//  ViewController.m
//  Prey
//
//  Created by Javier Cala Uribe on 19/3/15.
//  Copyright (c) 2015 Javier Cala Uribe. All rights reserved.
//

#import "RecoveriesViewController.h"
#import "PostStory.h"
#import "TFHpple.h"

@interface RecoveriesViewController ()

@end

@implementation RecoveriesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    RSSParser *parser = [[RSSParser alloc] initWithUrl:@"https://preyproject.com/feed" synchronous:NO];
    parser.delegate = self;
    [parser parse];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) rssParser:(RSSParser *)parser parsedFeed:(RSSFeed *)feed
{
    for (RSSEntry *postTmp in feed.articles) {
        
        NSLog(@"Title : %@ \n", postTmp.title);
        
        NSData *postData =  [postTmp.content dataUsingEncoding:NSUTF8StringEncoding];;
        
        TFHpple *postParser = [TFHpple hppleWithHTMLData:postData];
        
        NSString *postXpathQueryString = @"//a";
        NSArray *contributorsNodes = [postParser searchWithXPathQuery:postXpathQueryString];
        
        NSMutableArray *newPost = [[NSMutableArray alloc] initWithCapacity:0];
        for (TFHppleElement *element in contributorsNodes) {
            PostStory *postStory = [[PostStory alloc] init];
            [newPost addObject:postStory];
            
            for (TFHppleElement *child in element.children) {
                if ([child.tagName isEqualToString:@"img"]) {
                    @try {
                        postStory.imageMainUrl = [@"https://preyproject.com" stringByAppendingString:[child objectForKey:@"src"]];
                        NSLog(@"A: %@",postStory.imageMainUrl);
                    }
                    @catch (NSException *e) {}
                }
            }
        }
    }
}

- (void) rssParser:(RSSParser *)parser errorOccurred:(NSError *)error
{
    
}


@end
