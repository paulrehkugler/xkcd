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

@property(nonatomic, retain, readwrite) NSOperationQueue *fetchQueue;

@end

#pragma mark -

@implementation SingleComicImageFetcher

@synthesize fetchQueue;
@synthesize delegate;

- (id)init {
  if(self = [super init]) {
    self.fetchQueue = [[[NSOperationQueue alloc] init] autorelease];
  }
  return self;
}

- (void)fetchImageForComic:(Comic *)comic {
  if(comic.imageURL) {
    NSURL *comicImageURL = [NSURL URLWithString:comic.imageURL];
    FetchComicImageFromWeb *fetchOperation = [[[FetchComicImageFromWeb alloc] initWithComicNumber:[comic.number integerValue]
                                                                                         imageURL:comicImageURL
                                                                                 completionTarget:self
                                                                                           action:@selector(didCompleteFetchOperation:)]
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

- (void)didCompleteFetchOperation:(FetchComicImageFromWeb *)fetchOperation {
  Comic *comic = [Comic comicNumbered:fetchOperation.comicNumber];
  comic.loading = [NSNumber numberWithBool:NO];
  if(!fetchOperation.error && fetchOperation.comicImageData) {
    [comic saveImageData:fetchOperation.comicImageData];
    [[self retain] autorelease];
    [self.delegate singleComicImageFetcher:self didFetchImageForComic:comic];
  } else {
    [[self retain] autorelease];
    [self.delegate singleComicImageFetcher:self didFailWithError:fetchOperation.error onComic:comic];
  }
}

- (void)dealloc {
  [fetchQueue release];
  fetchQueue = nil;
  
  [super dealloc];
}

@end
