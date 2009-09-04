//
//  NewComicFetcher.m
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/1/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import "NewComicFetcher.h"
#import "FetchComicFromWeb.h"
#import "Comic.h"
#import "XkcdErrorCodes.h"

#pragma mark -

@interface NewComicFetcher ()

- (void)fetchComic:(NSInteger)comicNumber;

@property(nonatomic, retain, readwrite) NSOperationQueue *fetchQueue;

@end

#pragma mark -

@implementation NewComicFetcher

@synthesize delegate;
@synthesize fetchQueue;

- (id)init {
  if(self = [super init]) {
    self.fetchQueue = [[[NSOperationQueue alloc] init] autorelease];
  }
  return self;
}

- (void)fetchComic:(NSInteger)comicNumber {
  FetchComicFromWeb *fetchOperation = [[[FetchComicFromWeb alloc] initWithComicNumber:comicNumber
                                                                     completionTarget:self
                                                                               action:@selector(didCompleteFetchOperation:)]
                                       autorelease];
  [fetchQueue addOperation:fetchOperation];
}

- (void)fetch {
  Comic *lastKnownComic = [Comic lastKnownComic];
  if(lastKnownComic) {
    NSInteger comicToFetch = [lastKnownComic.number integerValue] + 1;    
    [self fetchComic:comicToFetch];
  } else {
    [[self retain] autorelease];
    [delegate newComicFetcher:self
             didFailWithError:[NSError errorWithDomain:kXkcdErrorDomain
                                                  code:kXkcdErrorCodeCouldNotFindLastComic
                                              userInfo:nil]];
  }
}

- (void)didCompleteFetchOperation:(FetchComicFromWeb *)fetchOperation {
  if(fetchOperation.error) {
    // Network fail?
    [[self retain] autorelease];
    [delegate newComicFetcher:self didFailWithError:fetchOperation.error];
  } else if(fetchOperation.comicName && fetchOperation.comicTitleText && fetchOperation.comicImageURL) {
    // Got a comic -- store it and keep going
    Comic *newComic = [Comic comic];
    newComic.number = [NSNumber numberWithInteger:fetchOperation.comicNumber];
    newComic.name = fetchOperation.comicName;
    newComic.titleText = fetchOperation.comicTitleText;
    newComic.imageURL = fetchOperation.comicImageURL;
    [[self retain] autorelease];
    [delegate newComicFetcher:self didFetchComic:newComic];
    [self fetchComic:(fetchOperation.comicNumber + 1)];    
  } else {
    // Parse failure -- we're done!
    [[self retain] autorelease];
    [delegate newComicFetcherDidFinishFetchingAllComics:self];
  }
}

- (void)dealloc {
  [fetchQueue release];
  fetchQueue = nil;
  
  delegate = nil;
  
  [super dealloc];
}

@end
