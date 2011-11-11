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
  id __unsafe_unretained target;
  SEL action;
  NSError *error;
  BOOL got404;
}

- (id)initWithComicNumber:(NSInteger)comicNumberToFetch completionTarget:(id)completionTarget action:(SEL)completionAction;

@property(nonatomic, assign, readonly) NSInteger comicNumber;
@property(nonatomic, strong, readonly) NSString *comicName;
@property(nonatomic, strong, readonly) NSString *comicTitleText;
@property(nonatomic, strong, readonly) NSString *comicImageURL;
@property(nonatomic, strong, readonly) NSError *error;
@property(nonatomic, assign, readonly) BOOL got404;

@end
