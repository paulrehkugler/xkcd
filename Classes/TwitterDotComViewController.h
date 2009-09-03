//
//  TwitterDotComViewController.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/3/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TwitterDotComViewController : UIViewController<UIWebViewDelegate> {
  NSString *tweet;
  UIWebView *webView;
}

- (id)initWithTweet:(NSString *)aTweet;

@end
