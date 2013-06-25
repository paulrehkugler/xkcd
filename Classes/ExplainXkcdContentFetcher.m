//
//  ExplainXkcdContentFetcher.m
//  xkcd
//
//  Created by Stuart McHattie on 22/06/2013.
//
//

#import "ExplainXkcdContentFetcher.h"
#import "TLMacros.h"
#import "UIAlertView_TLCommon.h"
#import "Comic.h"

#define kUserAgent @"xkcd iPhone app by Josh Snyder"
#define kExplanationDownloadFailAlertTitle NSLocalizedString(@"Whoops", @"Title of explanation download fail alert")

#pragma mark - Private NSOperation subclass

@interface FetchExplainXkcdFromWeb : NSOperation

@property(nonatomic, assign) NSInteger comicNumber;
@property(nonatomic, strong) NSURL *contentURL;
@property(nonatomic, strong) NSString *explainXkcdExplanation;
@property(nonatomic, weak) id target;
@property(nonatomic, assign) SEL action;
@property(nonatomic, strong) NSError *requestError;

@end


@implementation FetchExplainXkcdFromWeb

- (id)initWithComicNumber:(NSInteger)number
         completionTarget:(id)completionTarget
                   action:(SEL)completionAction
{
    if(self = [super init]) {
        self.comicNumber = number;
        self.target = completionTarget;
        self.action = completionAction;
        
        self.contentURL = [NSURL URLWithString:
            [NSString stringWithFormat:
                @"http://www.explainxkcd.com/wiki/index.php?title=%d", number]];
    }
    return self;
}

- (void)main
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.contentURL
                                                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                            timeoutInterval:180.0f];
    [request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
    NSURLResponse *response = nil;
    NSError *requestError = nil;
    TLDebugLog(@"Fetching Explain XKCD content at %@", self.contentURL);
    NSData *requestData = [NSURLConnection sendSynchronousRequest:request
                                                returningResponse:&response
                                                            error:&requestError];
    
    if (requestError) {
        self.requestError = requestError;
        TLDebugLog(@"Explain XKCD content fetch request failed with error: %@", self.requestError);
        [self notifyDoneGettingContent];
    }
    
    if(![self isCancelled] && !self.requestError) {
        // We got some data back, so let's get the explanation out of the HTML
        
        NSString *html = [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding];
        self.explainXkcdExplanation = [self getExplanationFromHTML:html];
    
        [self notifyDoneGettingContent];
    }
}

- (NSString *)getExplanationFromHTML:(NSString *)html
{
    // Cut off all the HTML before the explanation start
    NSRange titleRange = [html rangeOfString:@"Explanation</span></h2>\n" options:NSCaseInsensitiveSearch];
    html = [html substringFromIndex:titleRange.location + titleRange.length];
    
    // Remove tables from start of html
    while ([html hasPrefix:@"<table"]) {
        NSRange tableEnd = [html rangeOfString:@"</table>" options:NSCaseInsensitiveSearch];
        html = [html substringFromIndex:tableEnd.location + tableEnd.length];
    }
    
    // Remove HTML from after the explanation
    NSRange explainEnd = [html rangeOfString:@"\n<h2><span class=\"editsection\">" options:NSCaseInsensitiveSearch];
    html = [html substringToIndex:explainEnd.location];
    
    return html;
}

- (void)notifyDoneGettingContent
{
    [self.target performSelectorOnMainThread:self.action
                                  withObject:self
                               waitUntilDone:NO];
}

- (void)dealloc
{
    self.contentURL = nil;
    self.explainXkcdExplanation = nil;
    self.requestError = nil;
    self.target = nil;
    self.action = NULL;
}

@end


# pragma mark - Interface and implementation for fetcher class

@interface ExplainXkcdContentFetcher ()


@property(nonatomic, strong, readwrite) NSOperationQueue *fetchQueue;

@end


@implementation ExplainXkcdContentFetcher

-(id)init
{
    if(self = [super init]) {
        self.fetchQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

-(void)dealloc
{
    [self.fetchQueue cancelAllOperations];
}

-(void)fetchExplanationForComic:(Comic *)comic
{
    FetchExplainXkcdFromWeb *fetchOperation = [[FetchExplainXkcdFromWeb alloc] initWithComicNumber:[comic.number integerValue]
                                                                                  completionTarget:self
                                                                                            action:@selector(didCompleteFetchOperation:)];
    [self.fetchQueue addOperation:fetchOperation];
}

-(void)didCompleteFetchOperation:(FetchExplainXkcdFromWeb *)fetchOperation
{
    Comic *comic = [Comic comicNumbered:fetchOperation.comicNumber];
    if(!fetchOperation.requestError && fetchOperation.explainXkcdExplanation) {
        comic.explanation = fetchOperation.explainXkcdExplanation;
        [self.delegate explainXkcdContentFetcher:self
                     didFetchExplanationForComic:comic];
    } else {
        // Some kind of error occurred
        NSString *failAlertMessage = NSLocalizedString(@"Could not download xkcd explanation",
                                                       @"Text of error when getting xkcd explanation");
        [UIAlertView showAlertWithTitle:kExplanationDownloadFailAlertTitle
                                message:failAlertMessage];
        [self.delegate explainXkcdContentFetcher:self
                                  didFailOnComic:comic];
    }
}

@end
