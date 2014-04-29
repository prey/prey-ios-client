//
//  StoreControllerViewController.m
//  Prey
//
//  Created by Diego Torres on 3/12/12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import "StoreControllerViewController.h"
#import "GrettingsProViewController.h"
#import "MKStoreManager.h"
#import "PreyConfig.h"
#import "GAITrackedViewController.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"

@implementation StoreControllerViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
        self.title = NSLocalizedString(@"Upgrade to Pro", nil);
    }
    return self;
}

- (void)priceButton:(UIButton *)sender
{
    HUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    HUD.delegate = self;
    HUD.labelText = NSLocalizedString(@"Loading...",nil);

    SKProduct *product = [[MKStoreManager sharedManager].purchasableObjects objectAtIndex:(sender.tag - 500)];
    
    [[MKStoreManager sharedManager] buyFeature:product.productIdentifier
                                    onComplete:^(NSString* purchasedFeature,
                                                 NSData* purchasedReceipt,
                                                 NSArray* availableDownloads)
     {
         NSLog(@"Purchased: %@", purchasedFeature);
         
         [MBProgressHUD hideHUDForView:self.navigationController.view animated:NO];
         
         [[PreyConfig instance] setPro:YES];
         [self showCongratsPro];
     }
                                   onCancelled:^
     {
         NSLog(@"User Cancelled Transaction");
         
         [MBProgressHUD hideHUDForView:self.navigationController.view animated:NO];
         
         UIAlertView *alerta = [[[UIAlertView alloc] initWithTitle:@"Notice"
                                                           message:@"Canceled transaction, please try again."
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
         [alerta show];
     }];
}

- (void)viewDidLoad
{
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Upgrade to Pro"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];

    
    UIWebView *landingWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 350)];
    self.tableView.tableHeaderView = landingWebView;
    [self.tableView setScrollEnabled:YES];
    [landingWebView setDelegate:self];    
    [landingWebView setUserInteractionEnabled:NO];
    [landingWebView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [landingWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[[NSUserDefaults standardUserDefaults] objectForKey:@"LandingURL"]]]];
    for (UIScrollView *wv in [landingWebView subviews]){
        if ([wv isKindOfClass:[UIScrollView class]]) {
            [wv setScrollEnabled:NO];
        }
    }
    
    [self.tableView setBackgroundColor:[UIColor whiteColor]];
    [self.tableView setSeparatorColor:[UIColor colorWithRed:(97/255.f) green:(61/255.f) blue:(0/255.f) alpha:.6]];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        
    [landingWebView release];
    
    [super viewDidLoad];
}


-(void)showCongratsPro
{
    GrettingsProViewController *controller;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        controller = [[GrettingsProViewController alloc] initWithNibName:@"GrettingsProViewController-iPhone" bundle:nil];
    else
        controller = [[GrettingsProViewController alloc] initWithNibName:@"GrettingsProViewController-iPad" bundle:nil];
    
    if ([self.navigationController respondsToSelector:@selector(presentViewController:animated:completion:)]) // Check iOS 5.0 or later
        [self.navigationController presentViewController:controller animated:YES completion:NULL];
    else
        [[self navigationController] presentModalViewController:controller animated:YES];

    [controller release];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[MKStoreManager sharedManager].purchasableObjects count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        [cell setBackgroundColor:[UIColor colorWithWhite:0.8 alpha:1]];
        
        [[cell layer] setShadowColor:[UIColor whiteColor].CGColor];
        [[cell layer] setShadowOffset:CGSizeMake(0, 1)];
        [[cell layer] setShadowOpacity:.6];
        [[cell layer] setShadowRadius:0];
        [[cell layer] setOpaque:YES];
        [[cell layer] setShouldRasterize:YES];
        [[cell layer] setRasterizationScale:[[UIScreen mainScreen] scale]];
        [cell setOpaque:YES];
        
        [[cell textLabel] setBackgroundColor:[UIColor clearColor]];
        [[cell textLabel] setTextColor:[UIColor colorWithRed:(97/255.f) green:(61/255.f) blue:(0/255.f) alpha:1]];
    }
    
    for (id btn in [cell subviews]) {
        if ([btn isKindOfClass:[UIButton class]]) {
            [btn removeFromSuperview];
            break;
        }
    }
    [[cell viewWithTag:3109] removeFromSuperview];
    
    // Configure the cell...
        
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
    SKProduct *product = [[MKStoreManager sharedManager].purchasableObjects objectAtIndex:indexPath.row];
    
    cell.textLabel.text = product.localizedTitle;
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:product.priceLocale];
    
    NSString *formattedString = [numberFormatter stringFromNumber:product.price];
    [numberFormatter release];

    UIButton *buyButton = [[UIButton alloc] initWithFrame:CGRectMake(230, 13, 70, 20)];
    [buyButton setTitle:formattedString forState:UIControlStateNormal];
    [buyButton setBackgroundColor:[UIColor colorWithRed:0 green:(140/255.f) blue:0 alpha:1]];
    [buyButton setBackgroundImage:[UIImage imageNamed:@"whitegradient.png"] forState:UIControlStateNormal];
    [buyButton setBackgroundImage:[UIImage imageNamed:@"whitegradientR.png"] forState:UIControlStateHighlighted];
    [[buyButton titleLabel] setFont:[UIFont boldSystemFontOfSize:13]];
    [[buyButton titleLabel] setShadowColor:[UIColor colorWithWhite:0 alpha:.4]];
    [[buyButton titleLabel] setShadowOffset:CGSizeMake(0, 1)];                
    buyButton.layer.shadowColor = [UIColor colorWithWhite:1 alpha:.4].CGColor;
    buyButton.layer.shadowOffset = CGSizeMake(0, 1);
    buyButton.layer.shadowOpacity = 0.7;
    buyButton.layer.shadowRadius = 0;
    buyButton.layer.borderColor = [UIColor colorWithRed:0 green:(90/255.f) blue:0 alpha:.4].CGColor;
    buyButton.layer.borderWidth = 1;
    buyButton.layer.cornerRadius = 3;
    buyButton.tag = indexPath.section + 500;
        
    [buyButton addTarget:self action:@selector(priceButton:) forControlEvents:UIControlEventTouchUpInside];
    [cell setAccessoryView:buyButton];

    [buyButton release];
        
    return cell;
}

#pragma mark - Web view delegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
}

- (void)dealloc
{
   [super dealloc];
}

@end
