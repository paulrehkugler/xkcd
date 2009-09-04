//
//  TwitterDotComViewController.m
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/3/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import "TwitterDotComViewController.h"
#import "xkcdAppDelegate.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "CGGeometry_TLCommon.h"

#define kCopyTweetButtonText NSLocalizedString(@"Copy tweet", @"Button text to copy tweet to clipboard")

#pragma mark -

@interface TwitterDotComViewController () 

- (void)dismiss;
- (void)copyTweet;
- (void)didPressCopyTweetButton;

@property(nonatomic, retain, readwrite) NSString *tweet;
@property(nonatomic, retain, readwrite) UIWebView *webView;

@end

#pragma mark -

@implementation TwitterDotComViewController

@synthesize tweet;
@synthesize webView;

- (id)initWithTweet:(NSString *)aTweet {
  if(self = [super initWithNibName:nil bundle:nil]) {
    self.tweet = aTweet;
    self.title = NSLocalizedString(@"twitter.com", @"Title of twitter.com view");
  }
  return self;
}

- (void)loadView {
  [super loadView];
  
  self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
  self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:kCopyTweetButtonText
                                                                            style:UIBarButtonItemStyleBordered
                                                                           target:self
                                                                           action:@selector(didPressCopyTweetButton)]
                                           autorelease];
  self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self
                                                                                          action:@selector(dismiss)]
                                            autorelease];
  
  CGRect webViewFrame = self.view.bounds;
  self.webView = [[[UIWebView alloc] initWithFrame:webViewFrame] autorelease];
  self.webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  
  self.webView.delegate = self;
  
  [self.view addSubview:self.webView];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://m.twitter.com/"]]];
  [self copyTweet];
  
  NSString *firstUsePath = [AppDelegate.applicationDocumentsDirectory stringByAppendingPathComponent:@"first_twitter_use"];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  BOOL firstUse = ![fileManager fileExistsAtPath:firstUsePath];
  if(firstUse) {
    UIAlertView *firstUseAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"How to", @"Title of twitter.com how to alert")
                                                             message:NSLocalizedString(@"A tweet has been copied to the clipboard; touch and hold in a text area to paste. You can re-copy the tweet to the clipboard by pressing the \"Copy tweet\" button.", @"Body of twitter.com how to alert")
                                                            delegate:nil
                                                   cancelButtonTitle:nil
                                                   otherButtonTitles:NSLocalizedString(@"Ok", @"Button to accept twitter.com how to alert"),
                                   nil]
                                  autorelease];
    [firstUseAlert show];
    [fileManager createFileAtPath:firstUsePath contents:nil attributes:nil];
  }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
  return [AppDelegate rotate] ? YES : (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidUnload {
  self.webView = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)dealloc {
  [tweet release];
  tweet = nil;
    
  webView.delegate = nil;
  [webView release];
  webView = nil;
  
  [super dealloc];
}

- (void)dismiss {
  [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void)copyTweet {
  UIPasteboard *generalPasteboard = [UIPasteboard generalPasteboard];
  [generalPasteboard setValue:self.tweet forPasteboardType:(NSString *)kUTTypeUTF8PlainText];
}

- (void)didPressCopyTweetButton {
  [self copyTweet];
  self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"Copied!", @"Button text to indicate successful copying");
  [self.navigationItem.leftBarButtonItem performSelector:@selector(setTitle:) withObject:kCopyTweetButtonText afterDelay:2];
}


#pragma mark -
#pragma mark UIWebViewDelegate methods

- (void)webViewDidStartLoad:(UIWebView *)webView {
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)webView:(UIWebView *)localWebView didFailLoadWithError:(NSError *)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  
  BOOL shouldShowAlert = NO;
  NSString *alertMessage = nil;
  
  switch([error code]) {
    case NSURLErrorCancelled:;
      shouldShowAlert = NO;
      break;
    case NSURLErrorTimedOut:;
    case NSURLErrorCannotConnectToHost:;
    case NSURLErrorNetworkConnectionLost:;
    case NSURLErrorResourceUnavailable:;
    case NSURLErrorNotConnectedToInternet:;
    case NSURLErrorCannotLoadFromNetwork:;
      shouldShowAlert = YES;
      alertMessage = NSLocalizedString(@"Couldn't connect to twitter.", @"Message when page load failed due to non-connectivity");
      break;
    case NSURLErrorSecureConnectionFailed:;
    case NSURLErrorServerCertificateHasBadDate:;
    case NSURLErrorServerCertificateUntrusted:;
    case NSURLErrorServerCertificateHasUnknownRoot:;
    case NSURLErrorServerCertificateNotYetValid:;
      shouldShowAlert = YES;
      alertMessage = NSLocalizedString(@"Secure connection failed.", @"Generic message for security / certificate failures");
      break;
    case NSURLErrorCannotCreateFile:;
    case NSURLErrorCannotOpenFile:;
    case NSURLErrorCannotCloseFile:;
    case NSURLErrorCannotWriteToFile:;
    case NSURLErrorCannotRemoveFile:;
    case NSURLErrorCannotMoveFile:;
    case NSURLErrorFileDoesNotExist:;
    case NSURLErrorFileIsDirectory:;
    case NSURLErrorUnknown:;
    case NSURLErrorHTTPTooManyRedirects:;
    case NSURLErrorCannotFindHost:;
    case NSURLErrorDNSLookupFailed:;
    case NSURLErrorRedirectToNonExistentLocation:;
    case NSURLErrorBadServerResponse:;
    case NSURLErrorZeroByteResource:;
    case NSURLErrorUserCancelledAuthentication:;
    case NSURLErrorClientCertificateRejected:;
    case NSURLErrorUserAuthenticationRequired:;
    case NSURLErrorNoPermissionsToReadFile:;
    case NSURLErrorDownloadDecodingFailedMidStream:;
    case NSURLErrorDownloadDecodingFailedToComplete:;
    case NSURLErrorBadURL:;
    case NSURLErrorUnsupportedURL:;
    case NSURLErrorDataLengthExceedsMaximum:;
    default:;
      shouldShowAlert = YES;
      alertMessage = NSLocalizedString(@"Couldn't load twitter.", @"Generic message when page load failed");
      break;
  }
  
  if(shouldShowAlert) {
    UIAlertView *failAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Whoops", @"Title when page load failed")
                                                         message:alertMessage
                                                        delegate:nil
                                               cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok button for when page load failed")
                                               otherButtonTitles:nil]
                              autorelease];
    [failAlert show];
  }
  
}

@end
