//
//  FetchComicImageFromWeb.m
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/2/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import "FetchComicImageFromWeb.h"
#import "TLMacros.h"
#import "xkcd-Swift.h"

#pragma mark -

@interface FetchComicImageFromWeb ()

@property (nonatomic) NSInteger comicNumber;
@property (nonatomic) NSURL *comicImageURL;
@property (nonatomic) NSData *comicImageData;
@property (nonatomic, weak) id target;
@property (nonatomic) SEL action;
@property (nonatomic) NSError *error;
@property (nonatomic) id context;
@property (nonatomic) NSURLSession *URLSession;

@end

#pragma mark -

@implementation FetchComicImageFromWeb

- (instancetype)initWithComicNumber:(NSInteger)number
                           imageURL:(NSURL *)imageURL
                         URLSession:(NSURLSession *)session
                   completionTarget:(id)completionTarget
                             action:(SEL)completionAction
                            context:(id)aContext {
    if(self = [super init]) {
        _comicNumber = number;
        _comicImageURL = imageURL;
        _target = completionTarget;
        _action = completionAction;
        _context = aContext;
        _URLSession = session;
    }
    return self;
}

- (void)main {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.comicImageURL
                                                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                            timeoutInterval:180.0f];
    [request setValue:[Constants userAgent] forHTTPHeaderField:@"User-Agent"];

    TLDebugLog(@"Fetching image at %@", self.comicImageURL);

    [[self.URLSession dataTaskWithRequest:request
                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                           self.comicImageData = data;
                           self.error = error;

                           if (self.error) {
                               TLDebugLog(@"Image fetch completed with error: %@", self.error);
                           }

                           if(![self isCancelled]) {
                               [self.target performSelectorOnMainThread:self.action
                                                             withObject:self
                                                          waitUntilDone:NO];
                           }
                       }
      ] resume];
}

@end
