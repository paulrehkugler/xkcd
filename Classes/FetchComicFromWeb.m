//
//  FetchComicFromWeb.m
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/1/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import "FetchComicFromWeb.h"
#import "FlurryAPI.h"
#import "Comic.h"
#import "xkcdAppDelegate.h"
#import "CJSONDeserializer.h"
#import "NSString_HTML.h"

#pragma mark -

@interface FetchComicFromWeb ()

@property(nonatomic, assign, readwrite) NSInteger comicNumber;
@property(nonatomic, retain, readwrite) NSString *comicName;
@property(nonatomic, retain, readwrite) NSString *comicTitleText;
@property(nonatomic, retain, readwrite) NSString *comicImageURL;
@property(nonatomic, assign, readwrite) id target;
@property(nonatomic, assign, readwrite) SEL action;
@property(nonatomic, retain, readwrite) NSError *error;
@property(nonatomic, assign, readwrite) BOOL got404;

@end

#pragma mark -

@implementation FetchComicFromWeb

@synthesize comicNumber;
@synthesize comicName;
@synthesize comicTitleText;
@synthesize comicImageURL;
@synthesize target;
@synthesize action;
@synthesize error;
@synthesize got404;

- (id)initWithComicNumber:(NSInteger)comicNumberToFetch completionTarget:(id)completionTarget action:(SEL)completionAction {
  if(self = [super init]) {
    self.comicNumber = comicNumberToFetch;
    self.target = completionTarget;
    self.action = completionAction;
  }
  return self;
}

- (void)main {
  NSURL *comicURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.xkcd.com/%i/info.0.json", self.comicNumber]];
  if(self.comicNumber == 404) {
    // Smart ass :)
    self.comicName = @"Not found";
    self.comicTitleText = @"";
    self.comicImageURL = @"http://imgs.xkcd.com/static/xkcdLogo.png"; // anything...
  } else {
    // Parse "normally" -- god I want an API!
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:comicURL] autorelease];
    [request setValue:kUseragent forHTTPHeaderField:@"User-Agent"];
    NSHTTPURLResponse *response = nil;
    NSError *requestError = nil;
    NSData *comicData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&requestError];
    self.got404 = [response statusCode] == 404;
    if(!self.got404) {
      self.error = requestError;
      if(!requestError) {
        NSError *parseError = nil;
        NSDictionary *comicDictionary = [[CJSONDeserializer deserializer] deserializeAsDictionary:comicData error:&parseError];
        self.error = parseError;
        if(!parseError) {
          self.comicName = [NSString stringByCleaningHTML:[comicDictionary objectForKey:@"title"]];
          self.comicTitleText = [NSString stringByCleaningHTML:[comicDictionary objectForKey:@"alt"]];
          self.comicImageURL = [NSString stringByCleaningHTML:[comicDictionary objectForKey:@"img"]];
          // TODO: use link/news to detect "large version" image urls
        }
      }
    }
  }
  if(![self isCancelled]) {
    [self.target performSelectorOnMainThread:self.action withObject:self waitUntilDone:NO];
  }
}

- (void)dealloc {
  [comicName release];
  comicName = nil;
  
  [comicTitleText release];
  comicTitleText = nil;
  
  [comicImageURL release];
  comicImageURL = nil;
  
  [error release];
  error = nil;
  
  target = nil;
  action = NULL;
  
  [super dealloc];
}

@end
