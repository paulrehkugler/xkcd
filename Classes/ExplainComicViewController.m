//
//  ExplainComicViewController.m
//  xkcd
//
//  Created by Stuart McHattie on 22/06/2013.
//
//

#import "ExplainComicViewController.h"
#import "ExplainXkcdContentFetcher.h"
#import "Comic.h"
#import "TLLoadingView.h"

@interface ExplainComicViewController () <ExplainXkcdContentFetcherDelegate>

@property (nonatomic) Comic *comic;
@property(nonatomic, strong, readwrite) ExplainXkcdContentFetcher *explanationFetcher;
@property(nonatomic, strong, readwrite) TLLoadingView *loadingView;

@end

@implementation ExplainComicViewController

- (id)initWithComic:(Comic *)comic
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _comic = comic;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    if (self.comic.explanation) {
        [self displayExplanation];
    } else {
        [self displayLoadingView];
        self.explanationFetcher = [[ExplainXkcdContentFetcher alloc] init];
        self.explanationFetcher.delegate = self;
        [self.explanationFetcher fetchExplanationForComic:self.comic];
    }

}

- (void)displayExplanation
{
#warning Unimplemented
}

- (void)displayLoadingView
{
    self.loadingView = [[TLLoadingView alloc] initWithFrame:self.view.bounds];
    self.loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.loadingView setNeedsLayout];
    [self.view addSubview:self.loadingView];
}

- (void)explainXkcdContentFetcher:(ExplainXkcdContentFetcher *)fetcher didFetchExplanationForComic:(Comic *)comic
{
#warning Unimplemented
}

- (void)explainXkcdContentFetcher:(ExplainXkcdContentFetcher *)fetcher didFailWithError:(NSError *)error onComic:(Comic *)comic
{
#warning Unimplemented
}

@end
