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
#import "UIAlertView_TLCommon.h"

#define kImageDownloadFailAlertTitle NSLocalizedString(@"Whoops", @"Title of image download fail alert")

#pragma mark -

@interface SingleComicImageFetcher ()

- (void)didCompleteFetchOperation:(FetchComicImageFromWeb *)fetchOperation;
- (void)enqueueMoreDownloadAllComics;
- (void)didFailWithError:(NSError *)error onComic:(Comic *)comic;

@property(strong) id keepInMemory;
@property(nonatomic, retain, readwrite) NSOperationQueue *fetchQueue;
@property(nonatomic, retain, readwrite) NSMutableArray *comicsRemainingDuringDownloadAll;

@end

#pragma mark -

@implementation SingleComicImageFetcher

@synthesize fetchQueue;
@synthesize delegate;
@synthesize comicsRemainingDuringDownloadAll;
@synthesize keepInMemory;

- (id)init {
  if(self = [super init]) {
    self.fetchQueue = [[[NSOperationQueue alloc] init] autorelease];
  }
  return self;
}

- (void)fetchImageForComic:(Comic *)comic context:(id)context {
  if(comic.imageURL) {
    NSURL *comicImageURL = [NSURL URLWithString:comic.imageURL];
    FetchComicImageFromWeb *fetchOperation = [[[FetchComicImageFromWeb alloc] initWithComicNumber:[comic.number integerValue]
                                                                                         imageURL:comicImageURL
                                                                                 completionTarget:self
                                                                                           action:@selector(didCompleteFetchOperation:)
                                                                                          context:context]
                                              autorelease];
    comic.loading = [NSNumber numberWithBool:YES];
    self.keepInMemory = self;
    [fetchQueue addOperation:fetchOperation];
  } else {
    [self didFailWithError:[NSError errorWithDomain:kXkcdErrorDomain
                                               code:kXkcdErrorCodeBlankImageURL
                                           userInfo:nil]
                   onComic:comic];
  }
}

- (void)fetchImagesForAllComics {
  // don't start afresh if there's a download-all ongoing!
  if(!self.comicsRemainingDuringDownloadAll) {
    self.comicsRemainingDuringDownloadAll = [[[Comic comicsWithoutImages] mutableCopy] autorelease];
    [self enqueueMoreDownloadAllComics];
  }
}

- (void)enqueueMoreDownloadAllComics {
  NSUInteger comicsRemainingCount = [self.comicsRemainingDuringDownloadAll count];
  if(comicsRemainingCount == 0) {
    // done!
    self.comicsRemainingDuringDownloadAll = nil;
  } else {
    // not done...start another
    Comic *comic = [self.comicsRemainingDuringDownloadAll lastObject];
    [self fetchImageForComic:comic context:[NSNumber numberWithBool:NO]]; // open after download: NO
    [self.comicsRemainingDuringDownloadAll removeLastObject];
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
    [self.delegate singleComicImageFetcher:self
                     didFetchImageForComic:comic
                                   context:fetchOperation.context];
  } else {
    [self didFailWithError:fetchOperation.error onComic:comic];
  }
  
  if(self.comicsRemainingDuringDownloadAll) {
    [self enqueueMoreDownloadAllComics];
  }

  self.keepInMemory = nil;
}

- (void)didFailWithError:(NSError *)error onComic:(Comic *)comic {
  // Tell the user
  if([[error domain] isEqualToString:kXkcdErrorDomain]) {
    // internal error
    NSString *failAlertMessage = [NSString stringWithFormat:NSLocalizedString(@"Could not download xkcd %i.",
                                                                              @"Text of unknown error image download fail alert"),
                                  [comic.number integerValue]];
    [UIAlertView showAlertWithTitle:kImageDownloadFailAlertTitle
                            message:failAlertMessage];
  } else {
    NSString *failAlertMessage = [NSString stringWithFormat:NSLocalizedString(@"Could not download xkcd %i -- no internet connection.",
                                                                              @"Text of image download fail alert due to connectivity"),
                                  [comic.number integerValue]];
    [UIAlertView showAlertWithTitle:kImageDownloadFailAlertTitle
                            message:failAlertMessage];
  }
  
  // Tell the delegate
  [self.delegate singleComicImageFetcher:self
                        didFailWithError:error
                                 onComic:comic];
}

- (void)dealloc {
  [fetchQueue cancelAllOperations];
  [fetchQueue release];
  fetchQueue = nil;
  
  [comicsRemainingDuringDownloadAll release];
  comicsRemainingDuringDownloadAll = nil;

  [keepInMemory release], keepInMemory = nil;
  
  [super dealloc];
}

@end
