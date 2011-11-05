//
//  TLWebViewController.h
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 10/27/09.
//

#import <UIKit/UIKit.h>

@interface TLWebViewController : UIViewController<UIWebViewDelegate, UIActionSheetDelegate> {
@private
  UIWebView *webView;
  BOOL loading;
  BOOL toolbarWasHidden;
}

- (void)loadRequest:(NSURLRequest *)request;

@end
