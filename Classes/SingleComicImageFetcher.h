//
//  SingleComicImageFetcher.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/2/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SingleComicImageFetcherDelegate.h"

@interface SingleComicImageFetcher : NSObject

/**
 *  Initializes a @c SingleComicImageFetcher.
 *
 *  @param session The @c NSURLSession to use when downloading the image.
 *
 *  @return An initialized @c SingleComicImageFetcher.
 */
- (instancetype)initWithURLSession:(NSURLSession *)session;

/**
 *  Fetches an image for the supplied @c Comic.
 *
 *  @param comic   The @c Comic to fetch an image for.
 *  @param context An arbitrary @c id type.
 *
 *  @note @c context is currently used as a flag to open the comic after it is downloaded.
 *  Probably want to rethink this architecture in the future.
 */
- (void)fetchImageForComic:(Comic *)comic context:(id)context;
- (void)fetchImagesForAllComics;
- (BOOL)downloadingAll;
- (void)cancelDownloadAll;

@property (nonatomic, weak) id<SingleComicImageFetcherDelegate> delegate;

@end
