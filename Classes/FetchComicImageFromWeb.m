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

@property (nonatomic) NSInteger comicNumber;
@property (nonatomic) NSURL *comicImageURL;
@property (nonatomic) NSData *comicImageData;
@property (nonatomic, weak) id target;
@property (nonatomic) SEL action;
@property (nonatomic) NSError *error;
@property (nonatomic) id context;

@end

#pragma mark -

@implementation FetchComicImageFromWeb

- (instancetype)initWithComicNumber:(NSInteger)number
						   imageURL:(NSURL *)imageURL
				   completionTarget:(id)completionTarget
							 action:(SEL)completionAction
							context:(id)aContext {
	if(self = [super init]) {
		_comicNumber = number;
		_comicImageURL = imageURL;
		_target = completionTarget;
		_action = completionAction;
		_context = aContext;
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
	if (self.error) {
		TLDebugLog(@"Image fetch completed with error: %@", self.error);
	}
	
	if(![self isCancelled]) {
    [self.target performSelectorOnMainThread:self.action
                                  withObject:self
                               waitUntilDone:NO];
  }
}

@end
