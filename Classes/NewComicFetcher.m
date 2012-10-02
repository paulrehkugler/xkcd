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

- (void)fetchNewComic:(NSInteger)comicNumber;

@property(nonatomic, strong, readwrite) NSOperationQueue *fetchQueue;
@property(nonatomic, strong, readwrite) NSMutableArray *comicsToInsert;
@property(nonatomic, assign, readwrite) NSInteger nComicsUpdating;

@end

#pragma mark -

@implementation NewComicFetcher

@synthesize delegate;
@synthesize fetchQueue;
@synthesize comicsToInsert;
@synthesize nComicsUpdating;

- (id)init {
  if(self = [super init]) {
    self.fetchQueue = [[NSOperationQueue alloc] init];
    self.comicsToInsert = [NSMutableArray arrayWithCapacity:25];
    self.nComicsUpdating = 0;
  }
  return self;
}

- (void)fetchNewComic:(NSInteger)comicNumber {
  TLDebugLog(@"Starting fetch of comic %i", comicNumber);
  FetchComicFromWeb *fetchOperation = [[FetchComicFromWeb alloc] initWithComicNumber:comicNumber
                                                                     completionTarget:self
                                                                               action:@selector(didCompleteFetchOperation:)];
  fetchOperation.updating = NO;
  [fetchQueue addOperation:fetchOperation];
}

- (void)fetch {
  Comic *lastKnownComic = [Comic lastKnownComic];
  if(lastKnownComic) {
    NSInteger comicToFetch = [lastKnownComic.number integerValue] + 1;    
    [self fetchNewComic:comicToFetch];
  } else {
#if RECREATE_FROM_SCRATCH
    TLDebugLog(@"RECREATE_FROM_SCRATCH: Fetching comic 1");
    [Comic deleteAllComics];
    [self fetchNewComic:1];
#else
    [delegate newComicFetcher:self
             didFailWithError:[NSError errorWithDomain:kXkcdErrorDomain
                                                  code:kXkcdErrorCodeCouldNotFindLastComic
                                              userInfo:nil]];
#endif
  }
}

- (void)updateComicsMissingTranscripts {
  for(Comic *comicWithoutTranscript in [Comic comicsMissingTranscripts]) {
    TLDebugLog(@"Starting update of comic %i", comicWithoutTranscript.number.integerValue);
    FetchComicFromWeb *fetchOperation = [[FetchComicFromWeb alloc] initWithComicNumber:comicWithoutTranscript.number.integerValue
                                                                      completionTarget:self
                                                                                action:@selector(didCompleteFetchOperation:)];
    fetchOperation.updating = YES;
    [fetchQueue addOperation:fetchOperation];
    self.nComicsUpdating++;
  }
}

- (void)insertComics {
  for(FetchComicFromWeb *fetchOperation in self.comicsToInsert) {
    Comic *newComic = [Comic comic];
    newComic.number = @(fetchOperation.comicNumber);
    newComic.name = fetchOperation.comicName;
    newComic.titleText = fetchOperation.comicTitleText;
    newComic.imageURL = fetchOperation.comicImageURL;
    newComic.transcript = fetchOperation.comicTranscript;
    [delegate newComicFetcher:self didFetchComic:newComic];
  }
  [self.comicsToInsert removeAllObjects];
}

- (void)didCompleteFetchOperation:(FetchComicFromWeb *)fetchOperation {
  if(fetchOperation.updating) {
    if(fetchOperation.got404 || fetchOperation.error) {
      // Network fail? Change in API?
      [fetchQueue cancelAllOperations];
      self.nComicsUpdating = 0;
      TLDebugLog(@"Sending newComicFetcher:didFailWithError:");
      [delegate newComicFetcher:self didFailWithError:fetchOperation.error];
    } else if(fetchOperation.comicName && fetchOperation.comicTitleText &&
              fetchOperation.comicImageURL && fetchOperation.comicTranscript) {
      Comic *existingComic = [Comic comicNumbered:fetchOperation.comicNumber];
      TLDebugLog(@"Updating existing comic %@", existingComic);
      // Update immediately, no need to queue
      existingComic.name = fetchOperation.comicName;
      existingComic.titleText = fetchOperation.comicTitleText;
      existingComic.imageURL = fetchOperation.comicImageURL;
      existingComic.transcript = fetchOperation.comicTranscript;
      [delegate newComicFetcher:self didUpdateComic:existingComic];
      self.nComicsUpdating--;
      if(self.nComicsUpdating == 0) {
        TLDebugLog(@"Sending newComicFetcherDidFinishUpdatingAllComics:");
        [delegate newComicFetcherDidFinishUpdatingAllComics:self];
      }
    }
  } else {
    if(fetchOperation.got404) {
      // all done!
      [self insertComics];
      TLDebugLog(@"Sending newComicFetcherDidFinishFetchingAllComics:");
      [delegate newComicFetcherDidFinishFetchingAllComics:self];
    } else if(fetchOperation.error) {
      // Network fail? Change in API?
      [self insertComics];
      TLDebugLog(@"Sending newComicFetcher:didFailWithError:");
      [delegate newComicFetcher:self didFailWithError:fetchOperation.error];
    } else if(fetchOperation.comicName && fetchOperation.comicTitleText &&
              fetchOperation.comicImageURL && fetchOperation.comicTranscript) {
      // New comic -- queue it and keep going
      TLDebugLog(@"Queueing new comic %i", fetchOperation.comicNumber);
      [self.comicsToInsert addObject:fetchOperation];
      [self fetchNewComic:(fetchOperation.comicNumber + 1)];
      if(fetchOperation.comicNumber % 25 == 0) {
        [self insertComics];
      }
    } else {
      // wtf?
      [self insertComics];
    }
  }
}

@end
