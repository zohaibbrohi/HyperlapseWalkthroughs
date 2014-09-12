//
//  OnboardingContentViewController.m
//  Onboard
//
//  Created by Mike on 8/17/14.
//  Copyright (c) 2014 Mike Amaral. All rights reserved.
//

#import "OnboardingContentViewController.h"
#import <AVFoundation/AVFoundation.h>

static NSString * const kDefaultOnboardingFont = @"Helvetica-Light";

#define DEFAULT_TEXT_COLOR [UIColor whiteColor];

static CGFloat const kContentWidthMultiplier = 0.9;
static CGFloat const kDefaultImageViewSize = 100;
static CGFloat const kDefaultTopPadding = 60;
static CGFloat const kDefaultUnderIconPadding = 30;
static CGFloat const kDefaultUnderTitlePadding = 30;
static CGFloat const kDefaultBottomPadding = 0;
static CGFloat const kDefaultTitleFontSize = 20;
static CGFloat const kDefaultBodyFontSize = 28;

static CGFloat const kActionButtonHeight = 50;
static CGFloat const kMainPageControlHeight = 35;

@interface OnboardingContentViewController ()
@property (nonatomic, strong) AVPlayer *avplayer;
@property (strong, nonatomic) UIView *movieView;
@end

@implementation OnboardingContentViewController

- (id)initWithTitle:(NSString *)title body:(NSString *)body videoName:(NSString *)vName buttonText:(NSString *)buttonText action:(dispatch_block_t)action {
    self = [super init];
    // hold onto the passed in parameters, and set the action block to an empty block
    // in case we were passed nil, so we don't have to nil-check the block later before
    // calling
    _titleText = title;
    _body = body;
    //_image = image;
    _moviePath = [[NSBundle mainBundle] pathForResource:vName ofType:@"mp4"];
    _buttonText = buttonText;
    _actionHandler = action ?: ^{};
    
    // setup the initial default properties
    self.iconSize = kDefaultImageViewSize;
    self.fontName = kDefaultOnboardingFont;
    self.titleFontSize = kDefaultTitleFontSize;
    self.bodyFontSize = kDefaultBodyFontSize;
    self.topPadding = kDefaultTopPadding;
    self.underIconPadding = kDefaultUnderIconPadding;
    self.underTitlePadding = kDefaultUnderTitlePadding;
    self.bottomPadding = kDefaultBottomPadding;
    self.titleTextColor = DEFAULT_TEXT_COLOR;
    self.bodyTextColor = DEFAULT_TEXT_COLOR;
    self.buttonTextColor = DEFAULT_TEXT_COLOR;
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"viewDidLoad");
    // now that the view has loaded we can generate the content
    [self generateView];
    
    [self playBackgroundVideo];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.avplayer pause];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.avplayer play];
}

- (void)generateView {
    // we want our background to be clear so we can see through it to the image provided
    self.view.backgroundColor = [UIColor clearColor];
    
    // do some calculation for some common values we'll need, namely the width of the view,
    // the center of the width, and the content width we want to fill up, which is some
    // fraction of the view width we set in the multipler constant
    CGFloat viewWidth = CGRectGetWidth(self.view.frame);
    CGFloat horizontalCenter = viewWidth / 2;
    CGFloat contentWidth = viewWidth * kContentWidthMultiplier;
    
    
    // create the image view with the appropriate image, size, and center in on screen
    UIImageView *imageView = [[UIImageView alloc] initWithImage:_image];
    [imageView setFrame:CGRectMake(horizontalCenter - (self.iconSize / 2), self.topPadding, self.iconSize, self.iconSize)];
    //[self.view addSubview:imageView];
    
    
    self.movieView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 568)];
    [self.movieView setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.movieView];
    
    // create and configure the main text label sitting underneath the icon with the provided padding
    UILabel *mainTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(imageView.frame) - 90, contentWidth, 0)];
    mainTextLabel.text = _titleText;
    mainTextLabel.textColor = self.titleTextColor;
    mainTextLabel.font = [UIFont fontWithName:self.fontName size:self.titleFontSize];
    mainTextLabel.numberOfLines = 0;
    mainTextLabel.textAlignment = NSTextAlignmentCenter;
    [mainTextLabel sizeToFit];
    mainTextLabel.center = CGPointMake(horizontalCenter, mainTextLabel.center.y);
    [self.view addSubview:mainTextLabel];
    
    // create and configure the sub text label
    UILabel *subTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(mainTextLabel.frame) + self.underTitlePadding, contentWidth, 0)];
    subTextLabel.text = _body;
    subTextLabel.textColor = self.bodyTextColor;
    subTextLabel.font = [UIFont fontWithName:self.fontName size:self.bodyFontSize];
    subTextLabel.numberOfLines = 0;
    subTextLabel.textAlignment = NSTextAlignmentCenter;
    [subTextLabel sizeToFit];
    subTextLabel.center = CGPointMake(horizontalCenter, subTextLabel.center.y);
    [self.view addSubview:subTextLabel];
    
    // create the action button if we were given button text
    if (_buttonText) {
        UIButton *actionButton = [[UIButton alloc] initWithFrame:CGRectMake((CGRectGetMaxX(self.view.frame) / 2) - (contentWidth / 2), CGRectGetMaxY(self.view.frame) - kMainPageControlHeight - kActionButtonHeight - self.bottomPadding, contentWidth, kActionButtonHeight)];
        actionButton.titleLabel.font = [UIFont systemFontOfSize:24];
        [actionButton setTitle:_buttonText forState:UIControlStateNormal];
        [actionButton setTitleColor:self.buttonTextColor forState:UIControlStateNormal];
        [actionButton addTarget:self action:@selector(handleButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:actionButton];
    }
}

- (void)playBackgroundVideo {
    NSURL *movieURL = [NSURL fileURLWithPath:_moviePath];
    
    AVAsset *avAsset = [AVAsset assetWithURL:movieURL];
    AVPlayerItem *avPlayerItem =[[AVPlayerItem alloc]initWithAsset:avAsset];
    self.avplayer = [[AVPlayer alloc]initWithPlayerItem:avPlayerItem];
    AVPlayerLayer *avPlayerLayer =[AVPlayerLayer playerLayerWithPlayer:self.avplayer];
    [avPlayerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [avPlayerLayer setFrame:self.view.frame];
    [self.movieView.layer addSublayer:avPlayerLayer];
    
    //Not affecting background music playing
    NSError *sessionError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&sessionError];
    [[AVAudioSession sharedInstance] setActive:YES error:&sessionError];
    
    [self.avplayer seekToTime:kCMTimeZero];
    [self.avplayer setVolume:0.0f];
    [self.avplayer setActionAtItemEnd:AVPlayerActionAtItemEndNone];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[self.avplayer currentItem]];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}

#pragma mark - action button callback

- (void)handleButtonPressed {
    // simply call the provided action handler
    _actionHandler();
}

@end
