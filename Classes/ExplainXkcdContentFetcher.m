//
//  ExplainXkcdContentFetcher.m
//  xkcd
//
//  Created by Stuart McHattie on 22/06/2013.
//
//

#import "ExplainXkcdContentFetcher.h"
#import "xkcdAppDelegate.h"
#import "TLMacros.h"
#import "UIAlertView_TLCommon.h"
#import "Comic.h"

#define kExplanationDownloadFailAlertTitle NSLocalizedString(@"Whoops", @"Title of explanation download fail alert")

#pragma mark - Private NSOperation subclass

@interface FetchExplainXkcdFromWeb : NSOperation

@property(nonatomic, assign) NSInteger comicNumber;
@property(nonatomic, strong) NSURL *contentURL;
@property(nonatomic, strong) NSString *explainXkcdExplanation;
@property(nonatomic, weak) id target;
@property(nonatomic, assign) SEL action;
@property(nonatomic, strong) NSError *requestError;
@property(nonatomic, strong) NSError *jsonError;

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
                @"http://www.explainxkcd.com/wiki/api.php?format=json&action=query&prop=revisions&rvprop=content&redirects&titles=%d", number]];
    }
    return self;
}

- (void)main
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.contentURL
                                                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                            timeoutInterval:180.0f];
    [request setValue:kUseragent forHTTPHeaderField:@"User-Agent"];
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
        // Try to parse the returned data as JSON
        NSError *jsonError = nil;
        NSDictionary *jsonContent = [NSJSONSerialization JSONObjectWithData:requestData
                                                               options:0
                                                                 error:&jsonError];
        
        if (jsonError) {
            self.jsonError = jsonError;
            TLDebugLog(@"Explain XKCD content fetch JSON data was invalid: %@", self.jsonError);
            [self notifyDoneGettingContent];
        }
        
        // We have some proper content so let's get the bit we want!
        // The content is under the key path query.pages.pageID.revisions[0].* but we don't know what pageID is yet
        // We assume there's only one page in the returned JSON
        NSDictionary *page = [[[jsonContent valueForKeyPath:@"query.pages"] allValues] lastObject];
        NSArray *revisions = [page objectForKey:@"revisions"];
        NSString *revisionContent = [[revisions lastObject] objectForKey:@"*"];
        self.explainXkcdExplanation = [self parseRevisionContent:revisionContent];
    
        [self notifyDoneGettingContent];
    }
}

- (NSString *)parseRevisionContent:(NSString *)content
{
    NSRange startOfExplanation = [content rangeOfString:@"==Explanation==\n" options:NSCaseInsensitiveSearch];
    NSRange endOfExplanation = [content rangeOfString:@"\n\n==Transcript==" options:NSCaseInsensitiveSearch];
    return [content substringWithRange:NSMakeRange(startOfExplanation.location + startOfExplanation.length,
                                                   endOfExplanation.location - (startOfExplanation.location + startOfExplanation.length))];
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
    self.jsonError = nil;
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
    if(!fetchOperation.requestError && !fetchOperation.jsonError && fetchOperation.explainXkcdExplanation) {
        comic.explanation = fetchOperation.explainXkcdExplanation;
        [self.delegate explainXkcdContentFetcher:self
                     didFetchExplanationForComic:comic];
    } else {
        // Some kind of error occurred
        NSString *failAlertMessage = NSLocalizedString(@"Could not download xkcd explanation",
                                                       @"Text of error when getting xkcd explanation");
        [UIAlertView showAlertWithTitle:kExplanationDownloadFailAlertTitle
                                message:failAlertMessage];
    }
}

@end
