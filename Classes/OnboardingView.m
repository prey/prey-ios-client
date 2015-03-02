//
//  OnboardingView.m
//  Prey
//
//  Created by Javier Cala Uribe on 16/6/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

#import "OnboardingView.h"

@interface OnboardingView ()

@end

#define kTagButtonBack      201
#define kTagButtonNext      202

#define kTagViewScroll      101
#define kTagViewPage        102

#define kScrollHeight       568

#define kPageWidth          100
#define kPageHeight          20
#define kPagePosY           538

#define kTagViewScroll      101
#define kTagViewPage        102
#define kNumberPages          5

@implementation OnboardingView

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithRed:0.9647f green:0.9529f blue:0.8980f alpha:1.0f];
    
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
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 530, 70, 30)];
    [self configNewButton:backButton withText:@"Skip Tour" clearBackground:NO];
    backButton.tag = kTagButtonBack;
    [self.view addSubview:backButton];

    UIButton *nextButton = [[UIButton alloc] initWithFrame:CGRectMake(230, 530, 70, 30)];
    [self configNewButton:nextButton withText:@"next >" clearBackground:YES];
    nextButton.tag = kTagButtonNext;
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
    [[tmpButton titleLabel] setFont:[UIFont boldSystemFontOfSize:13]];
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
    UIButton *backButton = (UIButton*)[self.view viewWithTag:kTagButtonBack];
    UIButton *nextButton = (UIButton*)[self.view viewWithTag:kTagButtonNext];

    currentPage = (currentPage < 0) ? 0 : currentPage;
    currentPage = (currentPage > 4) ? 4 : currentPage;
    
    switch (currentPage)
    {
        case 0:
            [self configNewButton:backButton withText:@"Skip Tour" clearBackground:NO];
            [self configNewButton:nextButton withText:@"next >" clearBackground:YES];
            break;

        case 4:
            [self configNewButton:backButton withText:@"< back" clearBackground:YES];
            [self configNewButton:nextButton withText:@"Go" clearBackground:NO];
            break;

        default:
            [self configNewButton:backButton withText:@"< back" clearBackground:YES];
            [self configNewButton:nextButton withText:@"next >" clearBackground:YES];
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
    UIScrollView *tmpScrollView       = [[UIScrollView alloc] initWithFrame:CGRectMake(0,0,320,kScrollHeight)];
    tmpScrollView.backgroundColor     = [UIColor redColor];
    tmpScrollView.contentSize         = CGSizeMake(320*numberPages, kScrollHeight);
    tmpScrollView.maximumZoomScale    = 1.0;
    tmpScrollView.minimumZoomScale    = 1.0;
    tmpScrollView.clipsToBounds       = YES;
    tmpScrollView.pagingEnabled       = YES;
    tmpScrollView.delegate            = self;
    tmpScrollView.tag                 = value;
    tmpScrollView.showsHorizontalScrollIndicator = NO;
    
    
    for (int i = 0; i < numberPages; i++)
    {
        UIView *tmpView = [[UIView alloc] initWithFrame:CGRectMake(i*320, 0, 320, kScrollHeight)];
        tmpView.tag = i+300;
        [self configViewController:tmpView setNumberOfPage:i];
        [tmpScrollView addSubview:tmpView];
    }
    
    return tmpScrollView;
}

- (UIPageControl*)createPageControl:(int)numberPages tagID:(int)value
{
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    CGFloat positionX = (frame.size.width - kPageWidth )/2;
    
    UIPageControl *tmpWebPage    = [[UIPageControl alloc] init];
    tmpWebPage.frame             = CGRectMake(positionX, kPagePosY, kPageWidth, kPageHeight);
    //tmpWebPage.backgroundColor   = [UIColor colorWithRed:0.9294f green:0.9137f blue:0.8588f alpha:1.0f];
    tmpWebPage.backgroundColor   = [UIColor redColor];
    tmpWebPage.numberOfPages     = numberPages;
    tmpWebPage.currentPage       = 0;
    tmpWebPage.tag               = value;
    [tmpWebPage addTarget:self action:@selector(changePageSlide:) forControlEvents:UIControlEventValueChanged];
    
    return tmpWebPage;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    float roundedValue = round(scrollView.contentOffset.x / frame.size.width);
    
    UIPageControl *tmpPageControl = (UIPageControl*)[self.view viewWithTag:kTagViewPage];
    tmpPageControl.currentPage = roundedValue;
    
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

- (void)configViewController:(UIView*)pageView setNumberOfPage:(int)numberOfPage
{
    switch (numberOfPage)
    {
        case 0:
            pageView.backgroundColor = [UIColor colorWithRed:1.000 green:0.000 blue:0.502 alpha:1.000];
            break;
        case 1:
            pageView.backgroundColor = [UIColor colorWithRed:0.000 green:0.000 blue:0.502 alpha:1.000];
            break;
        case 2:
            pageView.backgroundColor = [UIColor colorWithRed:0.251 green:0.502 blue:0.000 alpha:1.000];
            break;
        case 3:
            pageView.backgroundColor = [UIColor orangeColor];
            break;
        case 4:
            pageView.backgroundColor = [UIColor blueColor];
            break;
    }
}

- (void)configPageView:(UIView*)pageView
{
    
    
    
    
    
}






@end
