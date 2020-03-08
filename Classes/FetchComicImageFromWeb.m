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
@property (nonatomic) NSURL *potentialLargeImageURL;
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
          attemptLargeImageDownload:(BOOL)attemptLargeImageDownload
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
        
        NSString *originalImageURL = self.comicImageURL.absoluteString;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\b(.+)(\\.\\w+)\\b" options:0 error:nil];
        
        if ([self shouldAttemptToDownloadRetinaImage]) {
            // This takes URLs that look like https://imgs.xkcd.com/comics/business_greetings.png and converts them to https://imgs.xkcd.com/comics/business_greetings_2x.png
            NSString *potentialRetinaImageURLString = [regex stringByReplacingMatchesInString:originalImageURL options:0 range:NSMakeRange(0, originalImageURL.length) withTemplate:@"$1_2x$2"];
            _potentialRetinaImageURL = [[NSURL alloc] initWithString:potentialRetinaImageURLString];
        }
        
        if (attemptLargeImageDownload) {
            // This takes URLs that look like https://imgs.xkcd.com/comics/movie_narrative_charts.png and converts them to https://imgs.xkcd.com/comics/movie_narrative_charts_large.png
            NSString *potentialLargeImageURLString = [regex stringByReplacingMatchesInString:originalImageURL options:0 range:NSMakeRange(0, originalImageURL.length) withTemplate:@"$1_large$2"];
            _potentialLargeImageURL = [[NSURL alloc] initWithString:potentialLargeImageURLString];
        }
    }
    return self;
}

- (void)main {
    if (self.potentialLargeImageURL) {
        [self requestLargeImage];
    }
    else if (self.potentialRetinaImageURL) {
        [self requestRetinaImage];
    }
    else {
        [self requestNonRetinaImage];
    }
}

- (void)requestLargeImage {
    [self requestImage:self.potentialLargeImageURL completion:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSInteger statusCode = ((NSHTTPURLResponse *) response).statusCode;
        
        if (error || (statusCode < 200 || statusCode > 299)) {
            if (self.potentialRetinaImageURL) {
                [self requestRetinaImage];
            }
            else {
                [self requestNonRetinaImage];
            }
        } else {
            TLDebugLog(@"Large image download success for comic %li", self.comicNumber);
            self.isRetinaImage = YES;
            [self completeRequestWithComicImageData:data error:nil];
        }
    }];
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
    // https://xkcd.com/1053/ is the first comic that shows up with a retina version
    return self.comicNumber >= 1053
        // these comics don't work via the API at all, so don't bother trying to download the retina image
        && self.comicNumber != 1663 // https://xkcd.com/1663/
        && self.comicNumber != 1608; // https://xkcd.com/1608/
}

@end
