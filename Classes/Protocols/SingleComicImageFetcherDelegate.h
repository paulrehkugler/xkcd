//
//  SingleComicImageFetcherDelegate.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/1/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

@class Comic;
@class SingleComicImageFetcher;

@protocol SingleComicImageFetcherDelegate<NSObject>

- (void)singleComicImageFetcher:(SingleComicImageFetcher *)fetcher didFetchImageForComic:(Comic *)comic context:(id)context;
- (void)singleComicImageFetcher:(SingleComicImageFetcher *)fetcher didFailWithError:(NSError *)error onComic:(Comic *)comic;

@end
