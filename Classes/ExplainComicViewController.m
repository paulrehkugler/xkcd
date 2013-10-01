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

@interface ExplainComicViewController () <ExplainXkcdContentFetcherDelegate, UIWebViewDelegate>

@property (nonatomic) Comic *comic;
@property (nonatomic, strong) ExplainXkcdContentFetcher *explanationFetcher;
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;
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
    
    // Add refresh bar button item
    UIBarButtonItem *refresh = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"refresh_icon.png"]
                                                                style:UIBarButtonItemStyleBordered
                                                               target:self
                                                               action:@selector(requestExplanation)];
    self.navigationItem.rightBarButtonItem = refresh;
    
	// Do any additional setup after loading the view.
    if (self.comic.explanation) {
        [self displayExplanation];
    } else {
        [self requestExplanation];
    }

}

- (void)requestExplanation
{
    [self.explanationView removeFromSuperview];
    [self.view addSubview:self.loadingView];
    [self.explanationFetcher fetchExplanationForComic:self.comic];
}

- (void)displayExplanation
{
    NSString *headerImage = @"<p style=\"text-align: center;\"><a href=\"/wiki/index.php?title=Main_Page\" title=\"Visit the main page\"><img style=\"border: none;\" src=\"/wiki/skins/common/images/explainxkcd.png\"></a></p>";
    NSString *explanationHTML = [headerImage stringByAppendingString:self.comic.explanation];
        
    [self.explanationView loadHTMLString:explanationHTML baseURL:[NSURL URLWithString:@"http://www.explainxkcd.com"]];
    [self.explanationView setFrame:self.view.frame];
    [self.view addSubview:self.explanationView];
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

- (ExplainXkcdContentFetcher *)explanationFetcher
{
    if (!_explanationFetcher) {
        _explanationFetcher = [[ExplainXkcdContentFetcher alloc] init];
        _explanationFetcher.delegate = self;
    }
    
    return _explanationFetcher;
}


#pragma mark - Property getters

- (UIWebView *) explanationView
{
    if (!_explanationView) {
        _explanationView = [[UIWebView alloc] initWithFrame:self.view.frame];
        _explanationView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _explanationView.backgroundColor = [UIColor whiteColor];
        _explanationView.delegate = self;
    }
    
    return _explanationView;
}

- (UIActivityIndicatorView *)loadingView
{
    if (!_loadingView) {
        _loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [_loadingView startAnimating];
        _loadingView.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:_loadingView
                                                                   attribute:NSLayoutAttributeCenterX
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterX
                                                                  multiplier:1.0
                                                                    constant:0];
        NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:_loadingView
                                                                   attribute:NSLayoutAttributeCenterY
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterY
                                                                  multiplier:1.0
                                                                    constant:0];
        [self.view addConstraint:centerX];
        [self.view addConstraint:centerY];
    }

    return _loadingView;
}


#pragma mark - UIWebView delegate methods

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    return YES;
}

@end
