//
//  OnboardingView.m
//  Prey
//
//  Created by Javier Cala Uribe on 16/6/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

#import "OnboardingView.h"
#import "OnboardingSubView.h"
#import "Constants.h"
#import "SignUpVC.h"
#import "SignInVC.h"

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
        posYiPhoneBtn = (IS_IPHONE5) ? 0 : -90;
    }
    
    UIImageView *bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:bgImage]];
    bg.frame = CGRectMake(0, 0, widthScreen, heightScreen);
    [self.view addSubview:bg];
    
    [self initScrollViewAndPageControl];
    [self initButtons];
}

- (void)viewDidUnload
{
    UIScrollView  *tmpScrollControl = (UIScrollView*) [self.view viewWithTag:kTagViewScroll];
    tmpScrollControl = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)callSignInView
{
    UIScrollView  *tmpScrollControl = (UIScrollView*) [self.view viewWithTag:kTagViewScroll];
    tmpScrollControl.delegate = nil;
    
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    SignInVC *nextController;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        if (IS_IPHONE5)
            nextController = [[SignInVC alloc] initWithNibName:@"SignInVC-iPhone-568h" bundle:nil];
        else
            nextController = [[SignInVC alloc] initWithNibName:@"SignInVC-iPhone" bundle:nil];
    }
    else
        nextController = [[SignInVC alloc] initWithNibName:@"SignInVC-iPad" bundle:nil];
    
    [appDelegate.viewController setViewControllers:[NSArray arrayWithObjects:nextController, nil] animated:NO];
}

- (void)callSignUpView
{
    UIScrollView  *tmpScrollControl = (UIScrollView*) [self.view viewWithTag:kTagViewScroll];
    tmpScrollControl.delegate = nil;
    
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    SignUpVC *nextController;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        if (IS_IPHONE5)
            nextController = [[SignUpVC alloc] initWithNibName:@"SignUpVC-iPhone-568h" bundle:nil];
        else
            nextController = [[SignUpVC alloc] initWithNibName:@"SignUpVC-iPhone" bundle:nil];
    }
    else
        nextController = [[SignUpVC alloc] initWithNibName:@"SignUpVC-iPad" bundle:nil];
    
    [appDelegate.viewController setViewControllers:[NSArray arrayWithObjects:nextController, nil] animated:NO];
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

    
    // Prey Logo Image
    tmpRect = (IS_IPAD) ? CGRectMake(284, 40, 200, 54) : CGRectMake(110, 10, 100, 27);
    NSString *preyLogoImg = (IS_IPAD) ? @"prey-logo-txt-mono-ipad" : @"prey-logo-txt-mono";
    UIImageView *preyIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:preyLogoImg]];
    preyIcon.frame = tmpRect;
    preyIcon.tag   = kTagImagePreyLogo;
    preyIcon.alpha = 0.0f;
    [self.view addSubview:preyIcon];

    
    // Restaurant Background Image
    [self addBackgroundImage:[UIImage imageNamed:@"restaurantBg"] withTag:kTagImageRestBg];

    // Room Background Image
    [self addBackgroundImage:[UIImage imageNamed:@"roomBg"] withTag:kTagImageRoomBg];

    // Police Background Image
    NSString *bgImg = (IS_IPAD) ? @"policesBg-ipad" : @"policesBg";
    [self addBackgroundImage:[UIImage imageNamed:bgImg] withTag:kTagImagePoliceBg];

    // Room Girl Background Image
    [self addBackgroundImage:[UIImage imageNamed:@"roomGirl"] withTag:kTagImageRoomGirlBg];
    
    // Street Background Image
    [self addBackgroundImage:[UIImage imageNamed:@"streetBg"] withTag:kTagImageStreetBg];

    
    // Sign Up Button
    tmpRect = (IS_IPAD) ? CGRectMake(259, 900, 250, 60) : CGRectMake(60, 500+posYiPhoneBtn, 200, 40);
    UIButton *signupButton = [[UIButton alloc] initWithFrame:tmpRect];
    [self configNewButton:signupButton withText:NSLocalizedString(@"SIGN UP",nil) clearBackground:NO];
    signupButton.tag = kTagButtonSignup;
    signupButton.alpha = 0.0f;
    [signupButton addTarget:self action:@selector(callSignUpView) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:signupButton];

    // Sign In Button
    tmpRect = (IS_IPAD) ? CGRectMake(259, 950, 250, 60) : CGRectMake(60, 535+posYiPhoneBtn, 200, 40);
    CGFloat fontSize = (IS_IPAD) ? 16.0f : 12.0f;
    UIButton *signinButton = [[UIButton alloc] initWithFrame:tmpRect];
    [signinButton setTitle:NSLocalizedString(@"already have an account?",nil) forState:UIControlStateNormal];
    [signinButton setBackgroundColor:[UIColor clearColor]];
    [[signinButton titleLabel] setFont:[UIFont boldSystemFontOfSize:fontSize]];
    signinButton.tag = kTagButtonSignIN;
    signinButton.alpha = 0.0f;
    [signinButton addTarget:self action:@selector(callSignInView) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:signinButton];

    
    // Back Button
    tmpRect = (IS_IPAD) ? CGRectMake(40, 450, 36, 80) : CGRectMake(20, 250+posYiPhoneBtn, 18, 40);
    UIButton *backButton = [[UIButton alloc] initWithFrame:tmpRect];
    NSString *arrowImg = (IS_IPAD) ? @"arrowBack-ipad" : @"arrowBack";
    [backButton setBackgroundImage:[UIImage imageNamed:arrowImg] forState:UIControlStateNormal];
    //[self configNewButton:backButton withText:@"Skip Tour" clearBackground:NO];
    backButton.tag = kTagButtonBack;
    backButton.alpha = 0.0f;
    [backButton addTarget:self action:@selector(changeButtonItem:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];
    

    // Next Button
    tmpRect = (IS_IPAD) ? CGRectMake(685, 450, 36, 80) : CGRectMake(276, 250+posYiPhoneBtn, 18, 40);
    UIButton *nextButton = [[UIButton alloc] initWithFrame:tmpRect];
    arrowImg             = (IS_IPAD) ? @"arrowNext-ipad" : @"arrowNext";
    [nextButton setBackgroundImage:[UIImage imageNamed:arrowImg] forState:UIControlStateNormal];
    //[self configNewButton:nextButton withText:@"next >" clearBackground:NO];
    nextButton.tag = kTagButtonNext;
    nextButton.alpha = 0.0f;
    [nextButton addTarget:self action:@selector(changeButtonItem:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:nextButton];
}

- (void)addBackgroundImage:(UIImage*)image withTag:(NSInteger)tagImage
{
    tmpRect = (IS_IPAD) ? CGRectMake(0, 300, 768, 334) : CGRectMake(0, 150+posYiPhone, 320, 167);
    UIImageView *imageBg = [[UIImageView alloc] initWithImage:image];
    imageBg.frame = tmpRect;
    imageBg.tag   = tagImage;
    imageBg.alpha = 0.0f;
    [self.view insertSubview:imageBg atIndex:1];
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
    CGFloat fontSize = (IS_IPAD) ? 22.0f : 17.0f;
    [tmpButton setTitle:titleText forState:UIControlStateNormal];
    [[tmpButton titleLabel] setFont:[UIFont boldSystemFontOfSize:fontSize]];
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

        case 6:
            startButton.hidden = YES;
            backButton.hidden  = NO;
            nextButton.hidden  = NO;
            pageControl.hidden = NO;
            break;
            
        case 7:
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
    CGFloat posYiPhonePageControl = (IS_IPHONE5)? 0:-50;
    tmpRect = (IS_IPAD) ? CGRectMake(334, 660, kPageWidth, kPageHeight) : CGRectMake(110, 330+posYiPhonePageControl, kPageWidth, kPageHeight);
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

    if ( (tmpPageControl.currentPage == 3) || (tmpPageControl.currentPage == 4) )
        [self animatePage5:scrollView.contentOffset.x];

    if ( (tmpPageControl.currentPage == 4) || (tmpPageControl.currentPage == 5) )
        [self animatePage6:scrollView.contentOffset.x];

    if ( (tmpPageControl.currentPage == 5) || (tmpPageControl.currentPage == 6) )
        [self animatePage7:scrollView.contentOffset.x];

    if ( (tmpPageControl.currentPage == 6) || (tmpPageControl.currentPage == 7) )
        [self animatePage8:scrollView.contentOffset.x];

    
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
            [pageView configPageView2:posYiPhone];
            break;
        case 3:
            [pageView configPageView3:posYiPhone];
            break;
        case 4:
            [pageView configPageView4:posYiPhone];
            break;
        case 5:
            [pageView configPageView5:posYiPhone];
            break;
        case 6:
            [pageView configPageView6:posYiPhone];
            break;
        case 7:
            [pageView configPageView7:posYiPhone];
            break;
    }
}

- (void)animatePage0:(CGFloat)scrollMoveX
{
    UIButton *startButton  = (UIButton*)[self.view viewWithTag:kTagButtonStart];
    UIButton *signupButton = (UIButton*)[self.view viewWithTag:kTagButtonSignup];
    UIButton *signinButton = (UIButton*)[self.view viewWithTag:kTagButtonSignIN];
    UIButton *backButton   = (UIButton*)[self.view viewWithTag:kTagButtonBack];
    UIButton *nextButton   = (UIButton*)[self.view viewWithTag:kTagButtonNext];
    UIPageControl *pageControl = (UIPageControl*)[self.view viewWithTag:kTagViewPage];
    UIImageView   *preyLogo    = (UIImageView*)[self.view viewWithTag:kTagImagePreyLogo];
    UIImageView   *restBg      = (UIImageView*)[self.view viewWithTag:kTagImageRestBg];
    
    startButton.alpha = 1 - (scrollMoveX/320.0f);
    backButton.alpha  = nextButton.alpha = pageControl.alpha = signupButton.alpha = signinButton.alpha = (scrollMoveX/320.0f);
    restBg.alpha      = preyLogo.alpha = (scrollMoveX/320.0f);

    
    [self.view endEditing:YES];
}

- (void)animatePage1:(CGFloat)scrollMoveX1
{
    if (scrollMoveX1 == widthScreen*1)
    {
        [self.view endEditing:YES];
        
        OnboardingSubView *currentView2 = (OnboardingSubView*)[self.view viewWithTag:302];
        [currentView2 startAnimatePage2:posYiPhone];
    }
}

- (void)animatePage2:(CGFloat)scrollMoveX
{
    if (scrollMoveX == widthScreen*2)
    {
        [self.view endEditing:YES];
    }
}

- (void)animatePage5:(CGFloat)scrollMoveX
{
    if (scrollMoveX >= widthScreen*3)
    {
        UIImageView   *restBg      = (UIImageView*)[self.view viewWithTag:kTagImageRestBg];
        UIImageView   *roomBg      = (UIImageView*)[self.view viewWithTag:kTagImageRoomBg];
        
        CGFloat ratioScreen = widthScreen*3;
        
        restBg.alpha = 1 - ((scrollMoveX-ratioScreen)/widthScreen);
        roomBg.alpha = ((scrollMoveX-ratioScreen)/widthScreen);
    }
    
    if (scrollMoveX == widthScreen*4)
    {
        OnboardingSubView *currentView  = (OnboardingSubView*)[self.view viewWithTag:304];
        
        UIImageView *checkImage = (UIImageView*)[currentView viewWithTag:kTagDudeRoom];
        if (checkImage == nil)
            [currentView addElementsPage04:posYiPhone];
    }
}

- (void)animatePage6:(CGFloat)scrollMoveX
{
    if (scrollMoveX >= widthScreen*4)
    {
        UIImageView   *roomBg      = (UIImageView*)[self.view viewWithTag:kTagImageRoomBg];
        UIImageView   *policeBg    = (UIImageView*)[self.view viewWithTag:kTagImagePoliceBg];
        
        CGFloat ratioScreen = widthScreen*4;
        
        roomBg.alpha = 1 - ((scrollMoveX-ratioScreen)/widthScreen);
        policeBg.alpha = ((scrollMoveX-ratioScreen)/widthScreen);
    }
    
    if (scrollMoveX == widthScreen*5)
    {
        OnboardingSubView *currentView  = (OnboardingSubView*)[self.view viewWithTag:305];
        
        UIImageView *checkImage = (UIImageView*)[currentView viewWithTag:kTagPoliceRoom];
        if (checkImage == nil)
            [currentView addElementsPage05:posYiPhone];
    }
    
}

- (void)animatePage7:(CGFloat)scrollMoveX
{
    if (scrollMoveX >= widthScreen*5)
    {
        UIImageView   *policeBg    = (UIImageView*)[self.view viewWithTag:kTagImagePoliceBg];
        UIImageView   *roomGirlBg  = (UIImageView*)[self.view viewWithTag:kTagImageRoomGirlBg];
        
        CGFloat ratioScreen = widthScreen*5;
        
        policeBg.alpha   = 1 - ((scrollMoveX-ratioScreen)/widthScreen);
        roomGirlBg.alpha = ((scrollMoveX-ratioScreen)/widthScreen);
    }
    
    if (scrollMoveX == widthScreen*6)
    {
        OnboardingSubView *currentView  = (OnboardingSubView*)[self.view viewWithTag:306];
        
        UIImageView *checkImage = (UIImageView*)[currentView viewWithTag:kTagAshleyRoom];
        if (checkImage == nil)
            [currentView addElementsPage06:posYiPhone];
    }
    
}

- (void)animatePage8:(CGFloat)scrollMoveX
{
    if (scrollMoveX >= widthScreen*6)
    {
        UIImageView   *roomGirlBg  = (UIImageView*)[self.view viewWithTag:kTagImageRoomGirlBg];
        UIImageView   *streetBg    = (UIImageView*)[self.view viewWithTag:kTagImageStreetBg];
        
        CGFloat ratioScreen = widthScreen*6;
        
        roomGirlBg.alpha   = 1 - ((scrollMoveX-ratioScreen)/widthScreen);
        streetBg.alpha = ((scrollMoveX-ratioScreen)/widthScreen);
    }
    
    if (scrollMoveX == widthScreen*7)
    {
        OnboardingSubView *currentView  = (OnboardingSubView*)[self.view viewWithTag:307];
        
        UIImageView *checkImage = (UIImageView*)[currentView viewWithTag:kTagAshleyRoom];
        if (checkImage == nil)
            [currentView addElementsPage07:posYiPhone];
    }
    
}


@end
