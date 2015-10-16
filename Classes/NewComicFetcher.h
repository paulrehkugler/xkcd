//
//  NewComicFetcher.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/1/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NewComicFetcherDelegate.h"

@interface NewComicFetcher : NSObject

- (void)fetch;

@property (nonatomic, weak) id<NewComicFetcherDelegate> delegate;

@end
