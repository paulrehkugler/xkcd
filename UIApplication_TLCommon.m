//
//  UIApplication_TLCommon.m
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 9/11/09.
//

#import "UIApplication_TLCommon.h"

static NSInteger networkRequestCount = 0;

@implementation UIApplication (TLCommon)

- (void)didStartNetworkRequest {
  if(networkRequestCount == 0) {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  }
  networkRequestCount++;
}

- (void)didStopNetworkRequest {
  networkRequestCount--;
  if(networkRequestCount == 0) {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  }
}

@end
