//
//  SingleComicImageFetcher.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/2/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

@import Foundation;

#import "SingleComicImageFetcherDelegate.h"

@interface SingleComicImageFetcher : NSObject

- (void)fetchImageForComic:(Comic *)comic context:(id)context;
- (void)fetchImagesForAllComics;
- (BOOL)downloadingAll;
- (void)cancelDownloadAll;

@property (nonatomic, weak) id<SingleComicImageFetcherDelegate> delegate;

@end
