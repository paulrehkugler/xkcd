//
//  FetchComicImageFromWeb.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/2/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FetchComicImageFromWeb : NSOperation

- (instancetype)initWithComicNumber:(NSInteger)number
						   imageURL:(NSURL *)imageURL
				   completionTarget:(id)completionTarget
							 action:(SEL)completionAction
							context:(id)context;

@property (nonatomic, readonly) NSData *comicImageData;
@property (nonatomic, readonly) NSInteger comicNumber;
@property (nonatomic, readonly) NSError *error;
@property (nonatomic, readonly) id context;

@end
