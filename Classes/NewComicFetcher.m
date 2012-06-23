//
//  NewComicFetcher.m
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/1/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#define RECREATE_FROM_SCRATCH 0

#import "NewComicFetcher.h"
#import "FetchComicFromWeb.h"
#import "Comic.h"
#import "XkcdErrorCodes.h"
#import "TLMacros.h"

#pragma mark -

@interface NewComicFetcher ()

- (void)fetchComic:(NSInteger)comicNumber;

@property(nonatomic, strong, readwrite) NSOperationQueue *fetchQueue;

@end

#pragma mark -

@implementation NewComicFetcher

@synthesize delegate;
@synthesize fetchQueue;

- (id)init {
  if(self = [super init]) {
    self.fetchQueue = [[NSOperationQueue alloc] init];
  }
  return self;
}

- (void)fetchComic:(NSInteger)comicNumber {
  FetchComicFromWeb *fetchOperation = [[FetchComicFromWeb alloc] initWithComicNumber:comicNumber
                                                                     completionTarget:self
                                                                               action:@selector(didCompleteFetchOperation:)];
  [fetchQueue addOperation:fetchOperation];
}

- (void)fetch {
  Comic *lastKnownComic = [Comic lastKnownComic];
  if(lastKnownComic) {
    NSInteger comicToFetch = [lastKnownComic.number integerValue] + 1;    
    [self fetchComic:comicToFetch];
  } else {
#if RECREATE_FROM_SCRATCH
    TLDebugLog(@"RECREATE_FROM_SCRATCH: Fetching comic 1");
    [Comic deleteAllComics];
    [self fetchComic:1];
#else
    [delegate newComicFetcher:self
             didFailWithError:[NSError errorWithDomain:kXkcdErrorDomain
                                                  code:kXkcdErrorCodeCouldNotFindLastComic
                                              userInfo:nil]];
#endif
  }
}

- (void)didCompleteFetchOperation:(FetchComicFromWeb *)fetchOperation {
  if(fetchOperation.got404) {
    // all done!
    [delegate newComicFetcherDidFinishFetchingAllComics:self];
  } else if(fetchOperation.error) {
    // Network fail? Change in API?
    [delegate newComicFetcher:self didFailWithError:fetchOperation.error];
  } else if(fetchOperation.comicName && fetchOperation.comicTitleText && fetchOperation.comicImageURL) {
    // Got a comic -- store it and keep going
    Comic *newComic = [Comic comic];
    newComic.number = [NSNumber numberWithInteger:fetchOperation.comicNumber];
    newComic.name = fetchOperation.comicName;
    newComic.titleText = fetchOperation.comicTitleText;
    newComic.imageURL = fetchOperation.comicImageURL;
    [delegate newComicFetcher:self didFetchComic:newComic];
    [self fetchComic:(fetchOperation.comicNumber + 1)];
  } else {
    // wtf?
  }
}

- (void)dealloc {
  
  delegate = nil;
  
}

@end
