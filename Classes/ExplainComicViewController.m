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
@property (nonatomic, strong) ExplainXkcdContentFetcher *explanationFetcher;
@property (nonatomic, strong) TLLoadingView *loadingView;
@property (nonatomic, strong) UIWebView *explanationView;

@end

@implementation ExplainComicViewController

- (id)initWithComic:(Comic *)comic
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _comic = comic;
        self.title = NSLocalizedString(@"Explanation", @"Title of the view for Explain XKCD content");
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
    self.explanationView = [[UIWebView alloc] initWithFrame:self.view.frame];
    self.explanationView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.explanationView.backgroundColor = [UIColor whiteColor];
    [self.explanationView loadHTMLString:self.comic.explanation baseURL:[NSURL URLWithString:@"http://www.explainxkcd.com"]];
    [self.view addSubview:self.explanationView];
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
    self.explanationFetcher = nil;
    [self.loadingView removeFromSuperview];
    [self displayExplanation];
}

- (void)explainXkcdContentFetcher:(ExplainXkcdContentFetcher *)fetcher didFailOnComic:(Comic *)comic
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
