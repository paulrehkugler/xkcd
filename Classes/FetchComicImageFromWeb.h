//
//  FetchComicImageFromWeb.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/2/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FetchComicImageFromWeb : NSOperation

- (id)initWithComicNumber:(NSInteger)number
                 imageURL:(NSURL *)imageURL
         completionTarget:(id)completionTarget
                   action:(SEL)completionAction
                  context:(id)context;

@property(nonatomic, strong, readonly) NSData *comicImageData;
@property(nonatomic, assign, readonly) NSInteger comicNumber;
@property(nonatomic, strong, readonly) NSError *error;
@property(nonatomic, strong, readonly) id context;

@end
