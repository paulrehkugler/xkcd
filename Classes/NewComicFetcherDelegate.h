//
//  NewComicFetcherDelegate.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/1/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

@class Comic;
@class NewComicFetcher;

@protocol NewComicFetcherDelegate<NSObject>

- (void)newComicFetcher:(NewComicFetcher *)fetcher didFetchComic:(Comic *)comic;
- (void)newComicFetcherDidFinishFetchingAllComics:(NewComicFetcher *)fetcher;
- (void)newComicFetcher:(NewComicFetcher *)fetcher didFailWithError:(NSError *)error;

@end
