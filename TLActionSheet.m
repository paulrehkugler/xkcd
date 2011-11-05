//
//  TLActionSheet.m
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 10/30/09.
//

#import "TLActionSheet.h"

#pragma mark -

@implementation TLActionSheet

@synthesize userInfo;

- (void)dealloc {
  [userInfo release];
  userInfo = nil;
  
  [super dealloc];
}

@end
