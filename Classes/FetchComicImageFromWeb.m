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
@property (nonatomic) NSURL *potentialRetinaImageURL;
@property (nonatomic) NSData *comicImageData;
@property (nonatomic) BOOL isRetinaImage;
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
        
        if ([self shouldAttemptToDownloadRetinaImage]) {
            NSString *originalImageURL = self.comicImageURL.absoluteString;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\b(.+)(\\.\\w+)\\b" options:0 error:nil];
            NSString *potentialRetinaImageURLString = [regex stringByReplacingMatchesInString:originalImageURL options:0 range:NSMakeRange(0, originalImageURL.length) withTemplate:@"$1_2x$2"];
            _potentialRetinaImageURL = [[NSURL alloc] initWithString:potentialRetinaImageURLString];
        }
    }
    return self;
}

- (void)main {
    if (self.potentialRetinaImageURL) {
        [self requestRetinaImage];
    }
}

- (void)requestRetinaImage {
    [self requestImage:self.potentialRetinaImageURL completion:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            TLDebugLog(@"Retina image fetch failed with error: %@", self.error);
            TLDebugLog(@"Requesting non-retina image for comic %li", (long)self.comicNumber);

            [self requestNonRetinaImage];
        } else {
            self.isRetinaImage = YES;
            [self completeRequestWithComicImageData:data error:nil];
        }
    }];
}

- (void) requestNonRetinaImage {
    [self requestImage:self.comicImageURL completion:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [self completeRequestWithComicImageData:data error:error];
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
    return _comicNumber >= 1053; // https://xkcd.com/1053/ is the first comic that shows up with a retina version
}

@end
