//
//  TLWebViewController.m
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 10/27/09.
//

#import "TLWebViewController.h"
#import "TLMacros.h"
#import "UIWebView_TLCommon.h"
#import "UIBarButtonItem_TLCommon.h"
#import "CGGeometry_TLCommon.h"
#import "UIImage_TLCommon.h"
#import "UIApplication_TLCommon.h"
#import "UIAlertView_TLCommon.h"
#import "TLMacros.h"

#pragma mark -

@interface TLWebViewController ()

- (void)refreshToolbars;
- (void)systemAction:(UIBarButtonItem *)sender;

@property(nonatomic, strong, readwrite) UIWebView *webView;
@property(nonatomic, assign, readwrite) BOOL loading;
@property(nonatomic, assign, readwrite) BOOL toolbarWasHidden;

@end


#pragma mark -

@implementation TLWebViewController

@synthesize webView;
@synthesize loading;
@synthesize toolbarWasHidden;

- (void)loadView {
  [super loadView];
  self.webView = [[UIWebView alloc] initWithFrame:CGRectZeroWithSize(self.view.bounds.size)];
  self.webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  self.webView.delegate = self;
  [self.view addSubview:self.webView];
}

- (void)loadRequest:(NSURLRequest *)request {
  [self.webView loadRequest:request];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.toolbarWasHidden = self.navigationController.toolbarHidden;
  self.navigationController.toolbarHidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  self.navigationController.toolbarHidden = self.toolbarWasHidden;
}

- (void)viewDidUnload {
  [self.webView stopLoading];
  self.webView.delegate = nil;
  self.webView = nil;
}

- (void)refreshToolbars {
  UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithName:@"web_back"]
                                                            style:UIBarButtonItemStylePlain
                                                            target:self.webView
                                                           action:@selector(goBack)];
  back.enabled = self.webView.canGoBack;

  UIBarButtonItem *forward = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithName:@"web_forward"]
                                                            style:UIBarButtonItemStylePlain
                                                           target:self.webView
                                                           action:@selector(goForward)];
  forward.enabled = self.webView.canGoForward;

  UIBarButtonSystemItem stopOrRefreshSystemItem = self.webView.loading ? UIBarButtonSystemItemStop : UIBarButtonSystemItemRefresh;
  SEL stopOrRefreshAction = self.webView.loading ? @selector(stopLoading) : @selector(reload);
  UIBarButtonItem *stopOrRefresh = [UIBarButtonItem barButtonSystemItem:stopOrRefreshSystemItem target:self.webView action:stopOrRefreshAction];
  
  UIBarButtonItem *systemAction = [UIBarButtonItem barButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(systemAction:)];
  
  NSArray *toolbarItems = [NSArray arrayWithObjects:
                           [UIBarButtonItem flexibleSpaceBarButtonItem],
                           back,
                           [UIBarButtonItem flexibleSpaceBarButtonItem],
                           forward,
                           [UIBarButtonItem fixedSpaceBarButtonItemWithWidth:(self.view.bounds.size.width / 3.0f)],
                           stopOrRefresh,
                           [UIBarButtonItem flexibleSpaceBarButtonItem],
                           systemAction,
                           [UIBarButtonItem flexibleSpaceBarButtonItem],
                           nil];

  [self setToolbarItems:toolbarItems];
  self.navigationItem.title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

- (void)systemAction:(UIBarButtonItem *)sender {
  UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[[self.webView.request URL] absoluteString]
                                                            delegate:self
                                                   cancelButtonTitle:NSLocalizedString(@"Cancel", @"Action sheet cancel button")
                                              destructiveButtonTitle:nil
                                                   otherButtonTitles:
                                 NSLocalizedString(@"Open in Safari", @"Action sheet button"),
                                 nil];
  [actionSheet showFromToolbar:self.navigationController.toolbar];
}

- (void)dealloc {
  [self setLoading:NO];
  [webView stopLoading];
  webView.delegate = nil;
  
}

#pragma mark -
#pragma mark Accessors

- (void)setLoading:(BOOL)newLoadingValue {
  if(loading != newLoadingValue) {
    if(newLoadingValue) {
      [[UIApplication sharedApplication] didStartNetworkRequest];        
    } else {
      [[UIApplication sharedApplication] didStopNetworkRequest];
    }
    [self refreshToolbars];
  }
  loading = newLoadingValue;    
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  if(buttonIndex != actionSheet.cancelButtonIndex) {    
    NSInteger adjustedIndex = buttonIndex - actionSheet.firstOtherButtonIndex;
    switch(adjustedIndex) {
      case 0:;
        [[UIApplication sharedApplication] openURL:[self.webView.request URL]];
        break;
    }
  }
}

#pragma mark -
#pragma mark UIWebViewDelegate methods

- (void)webViewDidStartLoad:(UIWebView *)aWebView {
  if(![aWebView isEqual:self.webView]) {
    TLDebugLog(@"Unexpected start webview callback from %@, self.webView is %@", aWebView, self.webView);
    return;
  }
  
  self.loading = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
  if(![aWebView isEqual:self.webView]) {
    TLDebugLog(@"Unexpected finish webview callback from %@, self.webView is %@", aWebView, self.webView);
    return;
  }
  
  self.loading = NO;
}

- (void)webView:(UIWebView *)aWebView didFailLoadWithError:(NSError *)error {
  if(![aWebView isEqual:self.webView]) {
    TLDebugLog(@"Unexpected fail webview callback from %@, self.webView is %@", aWebView, self.webView);
    return;
  }
    
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
      alertMessage = NSLocalizedString(@"Couldn't connect.", @"Message when page load failed due to non-connectivity");
      break;
    case NSURLErrorDataLengthExceedsMaximum:;
      shouldShowAlert = YES;
      alertMessage = NSLocalizedString(@"Page too big to handle.", @"Message when page load failed due to data size");
      break;
    case NSURLErrorBadURL:;
    case NSURLErrorUnsupportedURL:;
      shouldShowAlert = YES;
      alertMessage = NSLocalizedString(@"Unsupported url.", @"Message when page load failed due to bad url");
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
      shouldShowAlert = YES;
      alertMessage = NSLocalizedString(@"Can't load file urls.", @"Generic message for file errors (file errors?!)");
      break;
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
    default:;
      shouldShowAlert = YES;
      alertMessage = NSLocalizedString(@"Couldn't load that page.", @"Generic message when page load failed");
      break;
  }
  
  if(shouldShowAlert && alertMessage) {
    [UIAlertView showAlertWithTitle:NSLocalizedString(@"Whoops", @"Title when page load failed")
                            message:alertMessage];
  }
  
  self.loading = NO;
}

- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  if(![aWebView isEqual:self.webView]) {
    TLDebugLog(@"Unexpected shouldStart webview callback from %@, self.webView is %@", aWebView, self.webView);
    return NO;
  }
  
  if(![UIWebView shouldOpenURLInBrowser:[request URL]]) {
    [[UIApplication sharedApplication] openURL:[request URL]];
  }
  
  return YES;
}


@end
