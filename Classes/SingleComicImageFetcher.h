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
  id<SingleComicImageFetcherDelegate> __weak delegate;
  NSOperationQueue *fetchQueue;
  NSMutableArray *comicsRemainingDuringDownloadAll;
}

- (void)fetchImageForComic:(Comic *)comic context:(id)context;
- (void)fetchImagesForAllComics;
- (BOOL)downloadingAll;

@property(nonatomic, weak, readwrite) id<SingleComicImageFetcherDelegate> delegate;

@end
