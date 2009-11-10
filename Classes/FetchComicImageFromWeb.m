//
//  FetchComicImageFromWeb.m
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/2/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import "FetchComicImageFromWeb.h"
#import "xkcdAppDelegate.h"

#pragma mark -

@interface FetchComicImageFromWeb ()

@property(nonatomic, assign, readwrite) NSInteger comicNumber;
@property(nonatomic, retain, readwrite) NSURL *comicImageURL;
@property(nonatomic, retain, readwrite) NSData *comicImageData;
@property(nonatomic, assign, readwrite) id target;
@property(nonatomic, assign, readwrite) SEL action;
@property(nonatomic, retain, readwrite) NSError *error;
@property(nonatomic, assign, readwrite) BOOL openAfterDownload;

@end

#pragma mark -

@implementation FetchComicImageFromWeb

@synthesize comicNumber;
@synthesize comicImageURL;
@synthesize comicImageData;
@synthesize target;
@synthesize action;
@synthesize error;
@synthesize openAfterDownload;

- (id)initWithComicNumber:(NSInteger)number
                 imageURL:(NSURL *)imageURL
         completionTarget:(id)completionTarget
                   action:(SEL)completionAction
        openAfterDownload:(BOOL)shouldOpenAfterDownload {
  if(self = [super init]) {
    self.comicNumber = number;
    self.comicImageURL = imageURL;
    self.target = completionTarget;
    self.action = completionAction;
    self.openAfterDownload = shouldOpenAfterDownload;
  }
  return self;
}

- (void)main {
  NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:self.comicImageURL] autorelease];
  [request setValue:kUseragent forHTTPHeaderField:@"User-Agent"];
  NSURLResponse *response = nil;
  NSError *requestError = nil;
  self.comicImageData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&requestError];
  self.error = requestError;
  
  if(![self isCancelled]) {
    [self.target performSelectorOnMainThread:self.action withObject:self waitUntilDone:NO];
  }
}

- (void)dealloc {
  [comicImageURL release];
  comicImageURL = nil;
  
  [comicImageData release];
  comicImageData = nil;
  
  [error release];
  error = nil;
  
  target = nil;
  action = NULL;
  
  [super dealloc];
}

@end
