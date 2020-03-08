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
@property (nonatomic) NSArray<NSURL *> *comicImageURLs;
@property (nonatomic) NSData *comicImageData;
@property (nonatomic) BOOL isRetinaImage;
@property (nonatomic, weak) id target;
@property (nonatomic) SEL action;
@property (nonatomic) NSError *error;
@property (nonatomic) id context;
@property (nonatomic) NSURLSession *URLSession;

@property (nonatomic) NSUInteger currentImageURLIndex;

@end

#pragma mark -

@implementation FetchComicImageFromWeb

- (instancetype)initWithComicNumber:(NSInteger)number
                          imageURLs:(NSArray<NSURL *> *)imageURLs
                         URLSession:(NSURLSession *)session
                   completionTarget:(id)completionTarget
                             action:(SEL)completionAction
                            context:(id)aContext {
    if (self = [super init]) {
        _comicNumber = number;
        _comicImageURLs = imageURLs;
        _target = completionTarget;
        _action = completionAction;
        _context = aContext;
        _URLSession = session;
        _currentImageURLIndex = 0;
    }
    
    return self;
}

- (void)main {
    self.currentImageURLIndex = 0;
    [self requestNextImage];
}

- (void)requestNextImage {
    [self requestImage:self.comicImageURLs[self.currentImageURLIndex] completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            
            if (httpResponse.statusCode != 200 || error) {
                TLDebugLog(@"Image fetch for %@ failed with error: %@", self.comicImageURLs[self.currentImageURLIndex], self.error);

                self.currentImageURLIndex++;
                
                if (self.currentImageURLIndex < self.comicImageURLs.count) {
                    // If this failed and we have more imageURLs to use, try the next one.
                    [self requestNextImage];
                } else {
                    // If this failed and we're at the end of the list, fail the operation.
                    [self completeRequestWithComicImageData:nil error:error];
                }
            } else {
                [self completeRequestWithComicImageData:data error:nil];
            }
        }
    }];
}

- (void)requestImage:(NSURL *)imageURL completion:(void (^)(NSData *, NSURLResponse *, NSError *))completion {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:imageURL
                                                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                            timeoutInterval:180.0f];
    [request setValue:[Constants userAgent] forHTTPHeaderField:@"User-Agent"];

    TLDebugLog(@"Fetching image at %@", imageURL);

    [[self.URLSession dataTaskWithRequest:request
                       completionHandler:completion
      ] resume];
}

- (void)completeRequestWithComicImageData:(NSData *)data error:(NSError *)error {
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

- (BOOL)shouldAttemptToDownloadRetinaImage {
    // https://xkcd.com/1053/ is the first comic that shows up with a retina version
    return self.comicNumber >= 1053
        // these comics don't work via the API at all, so don't bother trying to download the retina image
        && self.comicNumber != 1663 // https://xkcd.com/1663/
        && self.comicNumber != 1608; // https://xkcd.com/1608/
}

@end
