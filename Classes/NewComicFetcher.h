//
//  NewComicFetcher.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/1/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NewComicFetcherDelegate.h"

@interface NewComicFetcher : NSObject {
@private
  id<NewComicFetcherDelegate> __weak delegate;
  NSOperationQueue *fetchQueue;
  NSMutableArray *comicsToInsert; // don't insert 1-by-1 -- crappy user experience -- insert in chunks
}

- (void)fetch;
- (void)updateComicsMissingTranscripts;

@property(nonatomic, weak, readwrite) id<NewComicFetcherDelegate> delegate;

@end
