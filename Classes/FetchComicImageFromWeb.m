//
//  FetchComicImageFromWeb.m
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/2/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import "FetchComicImageFromWeb.h"
#import "xkcdAppDelegate.h"
#import "TLMacros.h"

#pragma mark -

@interface FetchComicImageFromWeb ()

@property(nonatomic, assign, readwrite) NSInteger comicNumber;
@property(nonatomic, strong, readwrite) NSURL *comicImageURL;
@property(nonatomic, strong, readwrite) NSData *comicImageData;
@property(nonatomic, weak, readwrite) id target;
@property(nonatomic, assign, readwrite) SEL action;
@property(nonatomic, strong, readwrite) NSError *error;
@property(nonatomic, strong, readwrite) id context;

@end

#pragma mark -

@implementation FetchComicImageFromWeb

- (id)initWithComicNumber:(NSInteger)number
                 imageURL:(NSURL *)imageURL
         completionTarget:(id)completionTarget
                   action:(SEL)completionAction
                  context:(id)aContext {
  if(self = [super init]) {
    self.comicNumber = number;
    self.comicImageURL = imageURL;
    self.target = completionTarget;
    self.action = completionAction;
    self.context = aContext;
  }
  return self;
}

- (void)main {
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.comicImageURL
                                                               cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                           timeoutInterval:180.0f];
  [request setValue:kUseragent forHTTPHeaderField:@"User-Agent"];
  NSURLResponse *response = nil;
  NSError *requestError = nil;
  TLDebugLog(@"Fetching image at %@", self.comicImageURL);
  self.comicImageData = [NSURLConnection sendSynchronousRequest:request
                                              returningResponse:&response
                                                          error:&requestError];
  self.error = requestError;
  TLDebugLog(@"Image fetch completed with error: %@", self.error);
  if(![self isCancelled]) {
    [self.target performSelectorOnMainThread:self.action
                                  withObject:self
                               waitUntilDone:NO];
  }
}

@end
