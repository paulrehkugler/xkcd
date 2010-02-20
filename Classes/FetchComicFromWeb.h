//
//  FetchComicFromWeb.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/1/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FetchComicFromWeb : NSOperation {
@private
  NSInteger comicNumber;
  NSString *comicName;
  NSString *comicTitleText;
  NSString *comicImageURL;
  id target;
  SEL action;
  NSError *error;
  BOOL got404;
}

- (id)initWithComicNumber:(NSInteger)comicNumberToFetch completionTarget:(id)completionTarget action:(SEL)completionAction;

@property(nonatomic, assign, readonly) NSInteger comicNumber;
@property(nonatomic, retain, readonly) NSString *comicName;
@property(nonatomic, retain, readonly) NSString *comicTitleText;
@property(nonatomic, retain, readonly) NSString *comicImageURL;
@property(nonatomic, retain, readonly) NSError *error;
@property(nonatomic, assign, readonly) BOOL got404;

@end
