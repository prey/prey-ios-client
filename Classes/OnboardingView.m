//
//  OnboardingView.m
//  Prey
//
//  Created by Javier Cala Uribe on 16/6/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

#import "OnboardingView.h"
#import "OnboardingSubView.h"
#import "DeviceAuth.h"
#import "Constants.h"

@interface OnboardingView ()

@end

@implementation OnboardingView

@synthesize widthScreen, heightScreen, posYiPhone, posYiPhoneBtn, tmpRect;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *bgImage;
    
    if (IS_IPAD) {
        widthScreen   = 768;
        heightScreen  = 1024;
        bgImage       = @"bg-welcome-iPad";
    }
    else
    {
        widthScreen   = 320;
        heightScreen  = (IS_IPHONE5) ? 568 : 480;
        bgImage       = (IS_IPHONE5) ? @"bg-welcome-iPhone5" : @"bg-welcome-iPhone";
        posYiPhone    = (IS_IPHONE5) ? 0 : -45;
        posYiPhoneBtn = (IS_IPHONE5) ? 0 : -80;
    }
    
    UIImageView *bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:bgImage]];
    bg.frame = CGRectMake(0, 0, widthScreen, heightScreen);
    [self.view addSubview:bg];
    
    [self initScrollViewAndPageControl];
    [self initButtons];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark Config UIButton

- (void)initButtons
{
    // Get Started
    tmpRect = (IS_IPAD) ? CGRectMake(259, 900, 250, 60) : CGRectMake(85, 500+posYiPhoneBtn, 150, 40);
    UIButton *startButton = [[UIButton alloc] initWithFrame:tmpRect];
    [self configNewButton:startButton withText:NSLocalizedString(@"Get Rolling",nil) clearBackground:NO];
    startButton.tag = kTagButtonStart;
    [self.view addSubview:startButton];

    
    // Back Button
    tmpRect = (IS_IPAD) ? CGRectMake(40, 950, 43, 37) : CGRectMake(20, 535+posYiPhoneBtn, 24, 21);
    UIButton *backButton = [[UIButton alloc] initWithFrame:tmpRect];
    [backButton setBackgroundImage:[UIImage imageNamed:@"arrowBack"] forState:UIControlStateNormal];
    //[self configNewButton:backButton withText:@"Skip Tour" clearBackground:NO];
    backButton.tag = kTagButtonBack;
    backButton.alpha = 0.0f;
    [backButton addTarget:self action:@selector(changeButtonItem:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];
    

    // Next Button
    tmpRect = (IS_IPAD) ? CGRectMake(685, 950, 43, 37) : CGRectMake(276, 535+posYiPhoneBtn, 24, 21);
    UIButton *nextButton = [[UIButton alloc] initWithFrame:tmpRect];
    [nextButton setBackgroundImage:[UIImage imageNamed:@"arrowNext"] forState:UIControlStateNormal];
    //[self configNewButton:nextButton withText:@"next >" clearBackground:NO];
    nextButton.tag = kTagButtonNext;
    nextButton.alpha = 0.0f;
    [nextButton addTarget:self action:@selector(changeButtonItem:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:nextButton];
}

- (void)configNewButton:(UIButton*)tmpButton withText:(NSString*)titleText clearBackground:(BOOL)isClearBackground
{
    if (isClearBackground)
    {
        [tmpButton setBackgroundColor:[UIColor clearColor]];
        tmpButton.layer.shadowColor = [UIColor clearColor].CGColor;
        tmpButton.layer.borderColor = [UIColor clearColor].CGColor;
    }
    else
    {
        [tmpButton setBackgroundColor:[UIColor colorWithRed:(23/255.f) green:(117/255.f) blue:(195/255.f) alpha:1]];
        [tmpButton setBackgroundImage:[UIImage imageNamed:@"whitegradient.png"] forState:UIControlStateNormal];
        [tmpButton setBackgroundImage:[UIImage imageNamed:@"whitegradientR.png"] forState:UIControlStateHighlighted];
        tmpButton.layer.shadowColor = [UIColor colorWithWhite:1 alpha:.4].CGColor;
        tmpButton.layer.shadowOffset = CGSizeMake(0, 1);
        tmpButton.layer.shadowOpacity = 0.7;
        tmpButton.layer.shadowRadius = 0;
        tmpButton.layer.borderColor = [UIColor colorWithRed:0 green:(90/255.f) blue:0 alpha:.4].CGColor;
        tmpButton.layer.borderWidth = 1;
        tmpButton.layer.cornerRadius = 3;
    }
    
    [tmpButton setTitle:titleText forState:UIControlStateNormal];
    [[tmpButton titleLabel] setFont:[UIFont boldSystemFontOfSize:17]];
    [[tmpButton titleLabel] setShadowColor:[UIColor colorWithWhite:0 alpha:.4]];
    [[tmpButton titleLabel] setShadowOffset:CGSizeMake(0, 1)];
    
    [tmpButton addTarget:self action:@selector(changeButtonItem:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)changeButtonItem:(UIButton *)sender
{
    UIPageControl *tmpPageControl = (UIPageControl*)[self.view viewWithTag:kTagViewPage];
    UIScrollView  *tmpScrollControl = (UIScrollView*) [self.view viewWithTag:kTagViewScroll];
    CGRect frame   = tmpScrollControl.frame;
    
    if (sender.tag == kTagButtonBack)
        frame.origin.x = frame.size.width * (tmpPageControl.currentPage - 1);
    
    else // Next Button
        frame.origin.x = frame.size.width * (tmpPageControl.currentPage + 1);

    frame.origin.y = 0;
    [tmpScrollControl scrollRectToVisible:frame animated:YES];
}

- (void)changeButtonText:(long)currentPage
{
    UIButton *backButton  = (UIButton*)[self.view viewWithTag:kTagButtonBack];
    UIButton *nextButton  = (UIButton*)[self.view viewWithTag:kTagButtonNext];
    UIButton *startButton = (UIButton*)[self.view viewWithTag:kTagButtonStart];
    UIPageControl *pageControl = (UIPageControl*)[self.view viewWithTag:kTagViewPage];
    
    currentPage = (currentPage < 0) ? 0 : currentPage;
    currentPage = (currentPage > (kNumberPages-1)) ? (kNumberPages-1) : currentPage;
    
    switch (currentPage)
    {
        case 2:
            startButton.hidden = NO;
            backButton.hidden  = NO;
            nextButton.hidden  = NO;
            pageControl.hidden = NO;
            break;
         
        case 3:
            startButton.hidden = YES;
            backButton.hidden  = YES;
            nextButton.hidden  = YES;
            pageControl.hidden = YES;
            break;
    }
}

#pragma mark Config ScrollView - PageControl

- (void)initScrollViewAndPageControl
{
    [self.view addSubview:[self createScrollView:kNumberPages  tagID:kTagViewScroll]];
    [self.view addSubview:[self createPageControl:kNumberPages tagID:kTagViewPage]];
}

- (UIScrollView*)createScrollView:(int)numberPages tagID:(int)value
{
    UIScrollView *tmpScrollView       = [[UIScrollView alloc] initWithFrame:CGRectMake(0,0,widthScreen,heightScreen)];
    //tmpScrollView.backgroundColor     = [UIColor redColor];
    tmpScrollView.contentSize         = CGSizeMake(widthScreen*numberPages, heightScreen);
    tmpScrollView.maximumZoomScale    = 1.0;
    tmpScrollView.minimumZoomScale    = 1.0;
    tmpScrollView.clipsToBounds       = YES;
    tmpScrollView.pagingEnabled       = YES;
    tmpScrollView.delegate            = self;
    tmpScrollView.tag                 = value;
    tmpScrollView.showsHorizontalScrollIndicator = NO;
    
    
    for (int i = 0; i < numberPages; i++)
    {
        OnboardingSubView *tmpSubView = [[OnboardingSubView alloc] initWithFrame:CGRectMake(i*widthScreen, 0, widthScreen, heightScreen)];
        tmpSubView.tag = i+300;
        [self configViewController:tmpSubView setNumberOfPage:i];
        [tmpScrollView addSubview:tmpSubView];
    }
    
    return tmpScrollView;
}

- (UIPageControl*)createPageControl:(int)numberPages tagID:(int)value
{
    tmpRect = (IS_IPAD) ? CGRectMake(334, 960, kPageWidth, kPageHeight) : CGRectMake(110, 538+posYiPhoneBtn, kPageWidth, kPageHeight);
    UIPageControl *tmpPageControl    = [[UIPageControl alloc] initWithFrame:tmpRect];
    //tmpPageControl.backgroundColor = [UIColor colorWithRed:0.9294f green:0.9137f blue:0.8588f alpha:1.0f];
    tmpPageControl.backgroundColor   = [UIColor clearColor];
    tmpPageControl.numberOfPages     = numberPages;
    tmpPageControl.currentPage       = 0;
    tmpPageControl.tag               = value;
    tmpPageControl.alpha             = 0.0f;
    [tmpPageControl addTarget:self action:@selector(changePageSlide:) forControlEvents:UIControlEventValueChanged];
    
    return tmpPageControl;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    float roundedValue = round(scrollView.contentOffset.x / frame.size.width);
    
    UIPageControl *tmpPageControl = (UIPageControl*)[self.view viewWithTag:kTagViewPage];
    tmpPageControl.currentPage = roundedValue;

    if ( (tmpPageControl.currentPage == 0) || (tmpPageControl.currentPage == 1) )
        [self animatePage0:scrollView.contentOffset.x];
    
    if (tmpPageControl.currentPage == 1)
        [self animatePage1:scrollView.contentOffset.x];

    if (tmpPageControl.currentPage == 2)
        [self animatePage2:scrollView.contentOffset.x];

    if (tmpPageControl.currentPage == 3)
        [self animatePage3:scrollView.contentOffset.x];

    
    [self changeButtonText:tmpPageControl.currentPage];
}

- (void)changePageSlide:(id)sender
{
    UIPageControl *tmpPageControl   = (UIPageControl*)sender;
    UIScrollView  *tmpScrollControl = (UIScrollView*) [self.view viewWithTag:kTagViewScroll];
	NSInteger pageIndex = tmpPageControl.currentPage;
    
	// update the scroll view to the appropriate page
    CGRect frame   = tmpScrollControl.frame;
    frame.origin.x = frame.size.width * pageIndex;
    frame.origin.y = 0;
    [tmpScrollControl scrollRectToVisible:frame animated:YES];
}

#pragma mark Config UIView

- (void)configViewController:(OnboardingSubView*)pageView setNumberOfPage:(int)numberOfPage
{
    switch (numberOfPage)
    {
        case 0:
            [pageView configPageView0:posYiPhone];
            break;
        case 1:
            [pageView configPageView1:posYiPhone];
            break;
        case 2:
            [pageView configPageView2:CGRectMake(0, 0, widthScreen, heightScreen)];
            break;
        case 3:
            [pageView configPageView3];
            break;
    }
}

- (void)animatePage0:(CGFloat)scrollMoveX
{
    UIButton *startButton = (UIButton*)[self.view viewWithTag:kTagButtonStart];
    UIButton *backButton  = (UIButton*)[self.view viewWithTag:kTagButtonBack];
    UIButton *nextButton  = (UIButton*)[self.view viewWithTag:kTagButtonNext];
    UIPageControl *pageControl = (UIPageControl*)[self.view viewWithTag:kTagViewPage];
    
    startButton.alpha = 1 - (scrollMoveX/320.0f);
    backButton.alpha  = nextButton.alpha = pageControl.alpha = (scrollMoveX/320.0f);
        
    [self.view endEditing:YES];
}

- (void)animatePage1:(CGFloat)scrollMoveX1
{
    if (scrollMoveX1 == widthScreen*1)
    {
        [self.view endEditing:YES];
        OnboardingSubView *currentView  = (OnboardingSubView*)[self.view viewWithTag:301];
        [currentView checkCameraAuth];
    }
}

- (void)animatePage2:(CGFloat)scrollMoveX
{
    if (scrollMoveX == widthScreen*2)
    {
        [self.view endEditing:YES];
        
        OnboardingSubView *nextView     = (OnboardingSubView*)[self.view viewWithTag:303];
        [nextView preloadView];
        
        OnboardingSubView *currentView  = (OnboardingSubView*)[self.view viewWithTag:302];
        [currentView checkConfigPage2:posYiPhone];
    }
}

- (void)animatePage3:(CGFloat)scrollMoveX
{
    if (scrollMoveX == widthScreen*3)
    {
        OnboardingSubView *currentView  = (OnboardingSubView*)[self.view viewWithTag:303];
        [currentView segmentControlAction];
    }
}


@end
