//
//  UIWebView_TLCommon.h
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 10/27/09.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIWebView (TLCommon)

+ (BOOL)shouldOpenURLInBrowser:(NSURL *)url;

@end
