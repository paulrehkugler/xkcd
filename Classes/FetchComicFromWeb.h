//
//  FetchComicFromWeb.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/1/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FetchComicFromWeb : NSOperation

- (instancetype)initWithComicNumber:(NSInteger)comicNumberToFetch completionTarget:(id)completionTarget action:(SEL)completionAction;

@property (nonatomic, readonly) NSInteger comicNumber;
@property (nonatomic, readonly) NSString *comicName;
@property (nonatomic, readonly) NSString *comicTitleText;
@property (nonatomic, readonly) NSString *comicImageURL;
@property (nonatomic, readonly) NSString *comicTranscript;
@property (nonatomic, readonly) NSError *error;
@property (nonatomic, readonly) BOOL got404;

@end
