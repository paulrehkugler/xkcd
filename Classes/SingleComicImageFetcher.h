//
//  SingleComicImageFetcher.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/2/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SingleComicImageFetcherDelegate.h"

@interface SingleComicImageFetcher : NSObject {
@private
  id<SingleComicImageFetcherDelegate> delegate;
  NSOperationQueue *fetchQueue;
}

- (void)fetchImageForComic:(Comic *)comic;

@property(nonatomic, assign, readwrite) id<SingleComicImageFetcherDelegate> delegate;

@end
