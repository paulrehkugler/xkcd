//
//  SingleComicViewController.m
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/2/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import "SingleComicViewController.h"
#import "Comic.h"
#import "ComicImageView.h"
#import "TiledImage.h"
#import "CGGeometry_TLCommon.h"
#import "xkcdAppDelegate.h"
#import "FlurryAPI.h"
#import "TwitterDotComViewController.h"

#define kTileWidth 1024.0f
#define kTileHeight 1024.0f
#define kMaxTweetLength 140

#pragma mark -

@interface SingleComicViewController ()

- (void)systemAction:(UIBarButtonItem *)sender;
- (void)openInSafari;
- (void)email;
- (void)tweet;
- (void)openTwitterDotCom:(NSString *)tweet;

@property(nonatomic, retain, readwrite) Comic *comic;
@property(nonatomic, retain, readwrite) NSMutableArray *comicImageViews;
@property(nonatomic, retain, readwrite) UIView *contentView;
@property(nonatomic, retain, readwrite) UIScrollView *imageScroller;

@end

#pragma mark -

@implementation SingleComicViewController

@synthesize comic;
@synthesize comicImageViews;
@synthesize contentView;
@synthesize imageScroller;

- (id)initWithComic:(Comic *)comicToView {
  if(self = [super initWithNibName:nil bundle:nil]) {
    self.comic = comicToView;
    self.title = self.comic.name;
  }
  return self;
}

- (void)loadView {
  [super loadView];

  self.view.frame = CGRectMake(self.view.frame.origin.x,
                               self.view.frame.origin.y,
                               self.view.frame.size.width,
                               self.view.frame.size.height - self.navigationController.navigationBar.frame.size.height); // SO ANNOYING!

  UIBarButtonItem *systemItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                               target:self
                                                                               action:@selector(systemAction:)
                                  ] autorelease];
  self.navigationItem.rightBarButtonItem = systemItem;  
  
  // Load up the comic image/view
  UIImage *comicImage = comic.image;
  CGSize contentSize = comicImage.size;
  TiledImage *tiles = [[[TiledImage alloc] initWithImage:comicImage tileWidth:kTileWidth tileHeight:kTileHeight] autorelease];
  self.contentView = [[[UIView alloc] initWithFrame:CGRectZeroWithSize(contentSize)] autorelease];
  self.comicImageViews = [NSMutableArray arrayWithCapacity:(tiles.widthCount * tiles.heightCount)];
  for(NSUInteger x = 0; x < tiles.widthCount; ++x) {
    for(NSUInteger y = 0; y < tiles.heightCount; ++y) {
      ComicImageView *comicImageView = [[ComicImageView alloc] initWithImage:[tiles imageAtXIndex:x YIndex:y]];
      comicImageView.frame = CGRectWithXYAndSize(x * kTileWidth, y * kTileHeight, comicImageView.frame.size); // adjust origin appropriately
      comicImageView.titleText = comic.titleText;
      comicImageView.delegate = self;
      [self.comicImageViews addObject:comicImageView];
      [comicImageView release];
    }
  }
  
  // Scroll view
  self.imageScroller = [[UIScrollView alloc] initWithFrame:self.view.bounds];
  self.imageScroller.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.imageScroller.backgroundColor = [UIColor whiteColor];
  self.imageScroller.delaysContentTouches = NO;
  self.imageScroller.alwaysBounceVertical = YES;
  self.imageScroller.alwaysBounceHorizontal = YES;
  self.imageScroller.delegate = self;
  self.imageScroller.bouncesZoom = YES;
  self.imageScroller.scrollEnabled = YES;
  self.imageScroller.scrollsToTop = NO;
  [self.view addSubview:self.imageScroller];
  
  self.imageScroller.contentSize = contentSize;
  self.imageScroller.maximumZoomScale = 2;
  CGFloat xMinZoom = imageScroller.frame.size.width / contentSize.width;
  CGFloat yMinZoom = imageScroller.frame.size.height / contentSize.height;
  self.imageScroller.minimumZoomScale = (xMinZoom < yMinZoom) ? xMinZoom : yMinZoom;
  for(UIView *tileView in self.comicImageViews) {
    [self.contentView addSubview:tileView];
  }
  [self.imageScroller addSubview:self.contentView];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  if([AppDelegate openZoomedOut]) {
    [self.imageScroller setZoomScale:self.imageScroller.minimumZoomScale animated:NO];
  }  
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
  return [AppDelegate rotate] ? YES : (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidUnload {
  self.imageScroller = nil;
  self.contentView = nil;
}

- (void)dealloc {
  [comic release];
  comic = nil;
  
  [contentView release];
  contentView = nil;
  
  [comicImageViews release];
  comicImageViews = nil;
  
  [imageScroller release];
  imageScroller = nil;

  [super dealloc];
}

- (void)systemAction:(UIBarButtonItem *)sender {
  TLActionSheetController *sheet = [[[TLActionSheetController alloc] initWithTitle:nil] autorelease];
  [sheet addButtonWithTitle:NSLocalizedString(@"View on xkcd.com", @"Action sheet title")
                     target:self
                     action:@selector(openInSafari)];
  if([MFMailComposeViewController canSendMail]) {
    [sheet addButtonWithTitle:NSLocalizedString(@"Email link to this comic", @"Action sheet title")
                       target:self
                       action:@selector(email)];
  }
  [sheet addButtonWithTitle:NSLocalizedString(@"Tweet link to this comic", @"Action sheet title")
                     target:self
                     action:@selector(tweet)];   
  [sheet addCancelButton];
  [sheet showInView:self.view];
}

#pragma mark -
#pragma mark UIScrollViewDelegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
  return contentView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
}

#pragma mark -
#pragma mark ComicImageViewDelegate

- (void)zoomOutWithTouch:(UITouch *)touch {
  CGFloat newZoomScale = MIN(self.imageScroller.zoomScale * 1.5, self.imageScroller.maximumZoomScale);
  [self.imageScroller setZoomScale:newZoomScale animated:YES];
}

#pragma mark -
#pragma mark Action sheet supporting actions

- (void)openInSafari {
  [FlurryAPI logEvent:@"openInSafari"];
  TLWebViewController *webViewController = (TLWebViewController *)[TLWebViewController viewController];
  [self.navigationController pushViewController:webViewController animated:YES];
  [webViewController loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[comic websiteURL]]]];
}

- (void)email {
  [FlurryAPI logEvent:@"email"];
  MFMailComposeViewController *emailViewController = [[MFMailComposeViewController alloc] initWithNibName:nil bundle:nil];
  emailViewController.mailComposeDelegate = self;
  [emailViewController setSubject:comic.name];
  
  NSString *messageBody = [NSString stringWithFormat:NSLocalizedString(@"<a href=\"%@\">%@</a><br/><br/><br/>Via the <a href=\"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=303688284&mt=8\">xkcd iPhone app</a>",
                                                                       @"Body of share comic email."), [comic websiteURL], [comic websiteURL]];
  [emailViewController setMessageBody:messageBody isHTML:YES];
  [self presentModalViewController:emailViewController animated:YES];
}

- (void)openTwitterDotCom:(NSString *)tweet {
  TwitterDotComViewController *twitterViewController = [[[TwitterDotComViewController alloc] initWithTweet:tweet] autorelease];
  UINavigationController *twitterNavigationController = [[[UINavigationController alloc] initWithRootViewController:twitterViewController] autorelease];
  [self presentModalViewController:twitterNavigationController animated:YES];
}

- (void)tweet {
  [FlurryAPI logEvent:@"tweet"];
  NSString *tweet = [NSString stringWithFormat:@"%@ (via @xkcdapp)", comic.websiteURL];
  if([tweet length] + [comic.name length] + 2 < kMaxTweetLength) { // 2 == [@": " length]
    tweet = [NSString stringWithFormat:@"%@: %@", comic.name, tweet];
  }
  NSString *encodedTweet = [tweet stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
  
  UIApplication *application = [UIApplication sharedApplication];
  
  NSInteger client = [AppDelegate twitterClient];
  switch(client) {
    case kTwitterClientTwitterCom:;
      [self openTwitterDotCom:tweet];
      break;
    case kTwitterClientTweetie:;
      NSString *tweetie = [NSString stringWithFormat:@"tweetie:///post?message=%@", encodedTweet];
      NSURL *tweetieURL = [NSURL URLWithString:tweetie];
      if([application canOpenURL:tweetieURL]) {
        [application openURL:tweetieURL];
      } else {
        [self openTwitterDotCom:tweet];
      }      
      break;
    case kTwitterClientTwitterFon:;
      NSString *twitterFon = [NSString stringWithFormat:@"twitterfon:///message?%@", encodedTweet];
      NSURL *twitterFonURL = [NSURL URLWithString:twitterFon];
      if([application canOpenURL:twitterFonURL]) {
        [application openURL:twitterFonURL];
      } else {
        [self openTwitterDotCom:tweet];
      }
      break;
    case kTwitterClientTwitterrific:;
      NSString *twitterrific = [NSString stringWithFormat:@"twitterrific:///post?message=%@", encodedTweet];
      NSURL *twitterrificURL = [NSURL URLWithString:twitterrific];
      if([application canOpenURL:twitterrificURL]) {
        [application openURL:twitterrificURL];
      } else {
        [self openTwitterDotCom:tweet];
      }
      break;
    case kTwitterClientTwittelator:;
      NSString *twittelator = [NSString stringWithFormat:@"twit:///post?message=%@", encodedTweet];
      NSURL *twittelatorURL = [NSURL URLWithString:twittelator];
      if([application canOpenURL:twittelatorURL]) {
        [application openURL:twittelatorURL];
      } else {
        [self openTwitterDotCom:tweet];
      }
      break;
    default:
      break;
  }
}

#pragma mark -
#pragma mark MFMailComposeViewControllerDelegate methods

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
  switch(result) {
    case MFMailComposeResultFailed:
      [FlurryAPI logEvent:@"comicEmailFailed"];
      break;
    case MFMailComposeResultCancelled:
      [FlurryAPI logEvent:@"comicEmailCancelled"];
      break;
    case MFMailComposeResultSaved:
      [FlurryAPI logEvent:@"comicEmailSaved"];
      break;
    case MFMailComposeResultSent:
      [FlurryAPI logEvent:@"comicEmailSent"];
      break;
    default:
      break;
  }
  
  [controller dismissModalViewControllerAnimated:YES];
}

@end
