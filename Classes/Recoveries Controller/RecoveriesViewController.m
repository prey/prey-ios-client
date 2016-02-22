//
//  ViewController.m
//  Prey
//
//  Created by Javier Cala Uribe on 19/3/15.
//  Copyright (c) 2015 Javier Cala Uribe. All rights reserved.
//

#import "RecoveriesViewController.h"
#import "PostViewController.h"
#import "PreyAppDelegate.h"
#import "PostStory.h"
#import "TFHpple.h"
#import "Constants.h"

@interface RecoveriesViewController ()

@end

@implementation RecoveriesViewController

#define kTagLabelPost   20150202
#define kTagImagePost   20150101

@synthesize tableViewInfo, postArray, parser;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUD.labelText = NSLocalizedString(@"Please wait",nil);
    });
    
    parser = [[RSSParser alloc] initWithUrl:@"http://preyproject.com/blog/cat/recoveries/feed" synchronous:NO];
    parser.delegate = self;
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [parser parse];
    });
    
    
    self.screenName = @"Recoveries";
    
    self.title = NSLocalizedString(@"Recoveries", nil);
    self.view.backgroundColor = [UIColor whiteColor];

    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.navigationController setToolbarHidden:YES animated:NO];

    if (tableViewInfo != nil) [tableViewInfo reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark RSS Parser

- (void) rssParser:(RSSParser *)parser parsedFeed:(RSSFeed *)feed
{
    postArray = [[NSMutableArray alloc] initWithCapacity:0];
    for (RSSEntry *postTmp in feed.articles) {
        
        NSData *postData =  [postTmp.content dataUsingEncoding:NSUTF8StringEncoding];;
        
        TFHpple *postParser = [TFHpple hppleWithHTMLData:postData];
        
        NSString *postXpathQueryString = @"//a";
        NSArray *contributorsNodes = [postParser searchWithXPathQuery:postXpathQueryString];
        
        for (TFHppleElement *element in contributorsNodes) {
            
            for (TFHppleElement *child in element.children) {
                if ([child.tagName isEqualToString:@"img"]) {
                    @try {
                        PostStory *postStory = [[PostStory alloc] init];
                        postStory.imageMainUrl = [@"https://preyproject.com" stringByAppendingString:[child objectForKey:@"src"]];
                        postStory.title = postTmp.title;
                        
                        NSRange range = [postTmp.content rangeOfString:@"</a>"];
                        postStory.content = [postTmp.content substringFromIndex:(range.location+4)];
                        
                        //NSLog(@"Title : %@ \n", postTmp.title);
                        //NSLog(@"A: %@",postStory.imageMainUrl);
                        //NSLog(@"ORG :\n%@ ",postTmp.content);
                        //NSLog(@"TXT :\n%@",postStory.content);
                        
                        [postArray addObject:postStory];
                    }
                    @catch (NSException *e) {}
                }
            }
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:NO];
        [self loadTableView];
    });
}

- (void) rssParser:(RSSParser *)parser errorOccurred:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Error Loading Web: %@",[error description]);
        [MBProgressHUD hideHUDForView:self.view animated:NO];
        
        UIAlertView *alerta = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"We have a situation!",nil)
                                                         message:NSLocalizedString(@"Error loading web, please try again.",nil)
                                                        delegate:nil
                                               cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alerta show];
    });
}

#pragma mark Table view data source

- (void)loadTableView
{
    // Load images
    for (PostStory *postStory in postArray) {
        dispatch_queue_t bgQueue = dispatch_queue_create("Image queue", DISPATCH_QUEUE_SERIAL);
        dispatch_async(bgQueue, ^{
            NSData      *imgData    = [NSData dataWithContentsOfURL:[NSURL URLWithString:postStory.imageMainUrl]];
            
            if (imgData) {
                UIImage *image = [UIImage imageWithData:imgData];
                if (image) {
                    postStory.image = image;
                }
            }
        });
    }
    
    // TableView Config
    tableViewInfo = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    [tableViewInfo setBackgroundView:nil];
    [tableViewInfo setBackgroundColor:[UIColor colorWithRed:(200/255.f) green:(200/255.f) blue:(200/255.f) alpha:.3]];
    [tableViewInfo setSeparatorColor:[UIColor colorWithRed:(240/255.f) green:(243/255.f) blue:(247/255.f) alpha:1]];
    tableViewInfo.rowHeight  = (IS_IPAD) ? 500 : 280;
    tableViewInfo.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, tableViewInfo.bounds.size.width, 0.01f)];
    tableViewInfo.delegate   = self;
    tableViewInfo.dataSource = self;
    
    [self.view addSubview:tableViewInfo];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    switch (section)
    {
        case 0:
            return (postArray) ? [postArray count] : 1;
            break;
    }
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];
        
        CGRect frameLabel = (IS_IPAD) ? CGRectMake(50,420,418,70) : CGRectMake(10,210,cell.frame.size.width-20,50);
        UILabel *titlePost = [[UILabel alloc] initWithFrame:frameLabel];
        titlePost.tag  = kTagLabelPost;
        titlePost.textAlignment = UITextAlignmentLeft;
        titlePost.numberOfLines = 2;
        if (IS_OS_6_OR_LATER) titlePost.adjustsLetterSpacingToFitWidth = YES;        
        titlePost.adjustsFontSizeToFitWidth = YES;
        CGFloat fontSize = (IS_IPAD) ? 36 : 16;
        titlePost.font = [UIFont fontWithName:@"Roboto-Regular" size:fontSize];
        titlePost.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:titlePost];
        
        CGRect frameImage = (IS_IPAD) ? CGRectMake(0, 0, 518, 420) : CGRectMake(0, 0, 320, 210);
        UIImageView *tmpImage = [[UIImageView alloc] initWithFrame:frameImage];
        tmpImage.tag = kTagImagePost;
        tmpImage.contentMode = UIViewContentModeScaleAspectFill;
        tmpImage.clipsToBounds = YES;
        [cell.contentView addSubview:tmpImage];
    }

    UIImageView *tmpImg = (UIImageView*)[cell.contentView viewWithTag:kTagImagePost];
    tmpImg.image = nil;
    
    switch ([indexPath section]) {
        case 0:
            
            for (int i=0; i < [postArray count]; i++)
            {
                if ([indexPath row] == i) {
                    PostStory   *postStory  = [postArray objectAtIndex:indexPath.row];
                    UILabel    *tmpLabel = (UILabel*)[cell.contentView viewWithTag:kTagLabelPost];
                    tmpLabel.text = postStory.title;
                    
                    UIImageView *tmpImg = (UIImageView*)[cell.contentView viewWithTag:kTagImagePost];
                    if (postStory.image) {
                        tmpImg.image = postStory.image;
                    }
                    else
                    {
                        dispatch_queue_t bgQueueImg = dispatch_queue_create("Img queue", DISPATCH_QUEUE_SERIAL);
                        dispatch_async(bgQueueImg, ^{
                            NSData      *imgData    = [NSData dataWithContentsOfURL:[NSURL URLWithString:postStory.imageMainUrl]];
                            
                            if (imgData) {
                                UIImage *image = [UIImage imageWithData:imgData];
                                if (image) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        
                                        if (self != nil) {
                                            UITableViewCell *updateCell = [tableView cellForRowAtIndexPath:indexPath];
                                            if (updateCell != nil)
                                            {
                                                UIImageView *tmpImg = (UIImageView*)[updateCell.contentView viewWithTag:kTagImagePost];
                                                tmpImg.image = image;
                                            }
                                        }
                                    });
                                }
                            }
                        });
                    }
                }
            }
    }
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch ([indexPath section]) {
        case 0:
            
            for (int i=0; i < [postArray count]; i++)
            {
                if ([indexPath row] == i)
                {
                    PostViewController *postViewController = [[PostViewController alloc] init];
                    PostStory   *postStory  = [postArray objectAtIndex:indexPath.row];
                    postViewController.titlePost.text = postStory.title;
                    postViewController.imagePost.image = (postStory.image) ? postStory.image : nil;
                    int fontSize = (IS_IPAD) ? 24 : 14;
                    postStory.content = [NSString stringWithFormat:@"<span style=\"font-family: %@; font-size: %i\"> %@ </span>",
                                         @"OpenSans",fontSize, postStory.content];
                    
                    [postViewController.contentView loadHTMLString:postStory.content baseURL:nil];

                    postViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
                    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
                    [appDelegate.viewController setNavigationBarHidden:NO animated:NO];
                    [appDelegate.viewController pushViewController:postViewController animated:YES];
                }
            }
            break;
    }
}

@end
