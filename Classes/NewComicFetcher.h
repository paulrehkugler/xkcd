//
//  NewComicFetcher.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/1/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NewComicFetcherDelegate.h"

#define kInsertChunkSize 25  // when [comicsToInsert count] reaches kInsertChunkSize, comics will be inserted

@interface NewComicFetcher : NSObject
  
- (void)fetch;

@property(nonatomic, weak, readwrite) id<NewComicFetcherDelegate> delegate;

@end
