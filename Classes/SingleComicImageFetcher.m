//
//  SingleComicImageFetcher.m
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/2/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import "SingleComicImageFetcher.h"
#import "FetchComicImageFromWeb.h"
#import "Comic.h"
#import "XkcdErrorCodes.h"

#pragma mark -

@interface SingleComicImageFetcher ()

- (void)didCompleteFetchOperation:(FetchComicImageFromWeb *)fetchOperation;
- (void)enqueueMoreDownloadAllComics;

@property(nonatomic, retain, readwrite) NSOperationQueue *fetchQueue;
@property(nonatomic, retain, readwrite) NSMutableArray *comicsRemainingDuringDownloadAll;

@end

#pragma mark -

@implementation SingleComicImageFetcher

@synthesize fetchQueue;
@synthesize delegate;
@synthesize comicsRemainingDuringDownloadAll;

- (id)init {
  if(self = [super init]) {
    self.fetchQueue = [[[NSOperationQueue alloc] init] autorelease];
  }
  return self;
}

- (void)fetchImageForComic:(Comic *)comic openAfterDownload:(BOOL)openAfterDownload {
  if(comic.imageURL) {
    NSURL *comicImageURL = [NSURL URLWithString:comic.imageURL];
    FetchComicImageFromWeb *fetchOperation = [[[FetchComicImageFromWeb alloc] initWithComicNumber:[comic.number integerValue]
                                                                                         imageURL:comicImageURL
                                                                                 completionTarget:self
                                                                                           action:@selector(didCompleteFetchOperation:)
                                                                                openAfterDownload:openAfterDownload]
                                              autorelease];
    comic.loading = [NSNumber numberWithBool:YES];
    [fetchQueue addOperation:fetchOperation];
  } else {
    [[self retain] autorelease];
    [self.delegate singleComicImageFetcher:self
                          didFailWithError:[NSError errorWithDomain:kXkcdErrorDomain
                                                               code:kXkcdErrorCodeBlankImageURL
                                                           userInfo:nil]
                                   onComic:comic];
  }
}

- (void)fetchImagesForAllComics {
  // don't start afresh if there's a download-all ongoing!
  if(!self.comicsRemainingDuringDownloadAll) {
    self.comicsRemainingDuringDownloadAll = [[[Comic comicsWithoutImages] mutableCopy] autorelease];
    [self.fetchQueue addObserver:self
                      forKeyPath:@"operations"
                         options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                         context:NULL];
    [self enqueueMoreDownloadAllComics];
  }
}

- (void)enqueueMoreDownloadAllComics {
  NSUInteger comicsRemainingCount = [self.comicsRemainingDuringDownloadAll count];
  if(comicsRemainingCount == 0) {
    // done!
    self.comicsRemainingDuringDownloadAll = nil;
    [fetchQueue removeObserver:self forKeyPath:@"operations"];    
  } else {
    // not done...start another
    Comic *comic = [self.comicsRemainingDuringDownloadAll lastObject];
    [self fetchImageForComic:comic openAfterDownload:NO];
    [self.comicsRemainingDuringDownloadAll removeLastObject];
  }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if((self.fetchQueue == object) && [keyPath isEqualToString:@"operations"]) {
    NSUInteger oldOperationCount = [[change objectForKey:NSKeyValueChangeOldKey] count];
    NSUInteger newOperationCount = [[change objectForKey:NSKeyValueChangeNewKey] count];
    if(newOperationCount < oldOperationCount) {
      [self performSelectorOnMainThread:@selector(enqueueMoreDownloadAllComics)
                             withObject:nil
                          waitUntilDone:NO];
    }
  }
}

- (BOOL)downloadingAll {
  return (self.comicsRemainingDuringDownloadAll != nil);
}

- (void)didCompleteFetchOperation:(FetchComicImageFromWeb *)fetchOperation {
  Comic *comic = [Comic comicNumbered:fetchOperation.comicNumber];
  comic.loading = [NSNumber numberWithBool:NO];
  if(!fetchOperation.error && fetchOperation.comicImageData) {
    [comic saveImageData:fetchOperation.comicImageData];
    [[self retain] autorelease];
    [self.delegate singleComicImageFetcher:self
                     didFetchImageForComic:comic
                         openAfterDownload:fetchOperation.openAfterDownload];
  } else {
    [[self retain] autorelease];
    [self.delegate singleComicImageFetcher:self
                          didFailWithError:fetchOperation.error
                                   onComic:comic];
  }
}

- (void)dealloc {
  if(comicsRemainingDuringDownloadAll) {
    [fetchQueue removeObserver:self forKeyPath:@"operations"];    
  }

  [fetchQueue release];
  fetchQueue = nil;
  
  [comicsRemainingDuringDownloadAll release];
  comicsRemainingDuringDownloadAll = nil;
  
  [super dealloc];
}

@end
