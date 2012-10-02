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

@required

- (void)newComicFetcher:(NewComicFetcher *)fetcher didFetchComic:(Comic *)comic;
- (void)newComicFetcher:(NewComicFetcher *)fetcher didUpdateComic:(Comic *)comic;
- (void)newComicFetcherDidFinishFetchingAllComics:(NewComicFetcher *)fetcher;
- (void)newComicFetcherDidFinishUpdatingAllComics:(NewComicFetcher *)fetcher;
- (void)newComicFetcher:(NewComicFetcher *)fetcher didFailWithError:(NSError *)error;

@end
