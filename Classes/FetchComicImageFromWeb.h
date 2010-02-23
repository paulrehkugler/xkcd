//
//  FetchComicImageFromWeb.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/2/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FetchComicImageFromWeb : NSOperation {
@private
  NSInteger comicNumber;
  NSURL *comicImageURL;
  NSData *comicImageData;
  id target;
  SEL action;
  NSError *error;
  id context;
}

- (id)initWithComicNumber:(NSInteger)number
                 imageURL:(NSURL *)imageURL
         completionTarget:(id)completionTarget
                   action:(SEL)completionAction
                  context:(id)context;

@property(nonatomic, retain, readonly) NSData *comicImageData;
@property(nonatomic, assign, readonly) NSInteger comicNumber;
@property(nonatomic, retain, readonly) NSError *error;
@property(nonatomic, retain, readonly) id context;

@end
