//
//  SingleComicViewController.m
//  xkcd
//

#import "SingleComicViewController.h"
#import "Comic.h"
#import "TiledImage.h"
#import "CGGeometry_TLCommon.h"
#import "xkcdAppDelegate.h"
#import "SingleComicImageFetcher.h"
#import "ComicListViewController.h"
#import "UIBarButtonItem_TLCommon.h"
#import "TLMersenneTwister.h"
#import "LambdaSheet.h"
#import "FCOpenInSafariActivity.h"
#import "FCOpenInChromeActivity.h"
#import "UIAlertView_TLCommon.h"
#import "UIScrollView+Helper.h"
#import "XkcdErrorCodes.h"

#define kTileWidth 1024.0f
#define kTileHeight 1024.0f

#pragma mark -

@interface SingleComicViewController ()

- (void)toggleToolbarsAnimated:(BOOL)animated;
- (void)goToPreviousComic;
- (void)goToRandomComic;
- (void)goToNextComic;
- (void)displayComicImage;
- (void)setupToolbar;
- (void)displayLoadingView;
- (void)goToComicNumbered:(NSUInteger)comicNumber;
- (void)calculateZoomScaleAndAnimate:(BOOL)animate;

@property (nonatomic) Comic *comic;
@property (nonatomic) NSMutableArray *comicImageViews;
@property (nonatomic) UIView *contentView;
@property (nonatomic) UIScrollView *imageScroller;
@property (nonatomic) UIActivityIndicatorView *loadingView;
@property (nonatomic) SingleComicImageFetcher *imageFetcher;
@property (nonatomic) BOOL hidingToolbars;

@end

#pragma mark -

@implementation SingleComicViewController

- (instancetype)initWithComic:(Comic *)comicToView {
  if (self = [super initWithNibName:nil bundle:nil]) {
    _comic = comicToView;
    self.title = [NSString stringWithFormat:@"%li. %@", (long)_comic.number.integerValue, _comic.name];
  }
  return self;
}

- (void)loadView {
	// Scroll view
	self.imageScroller = [[UIScrollView alloc] initWithFrame:CGRectZero];
	self.imageScroller.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.imageScroller.backgroundColor = [UIColor whiteColor];
	self.imageScroller.delaysContentTouches = NO;
	self.imageScroller.alwaysBounceVertical = YES;
	self.imageScroller.alwaysBounceHorizontal = YES;
	self.imageScroller.delegate = self;
	self.imageScroller.bouncesZoom = YES;
	self.imageScroller.scrollEnabled = YES;
	self.imageScroller.scrollsToTop = NO;
	
	self.view = self.imageScroller;
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	[self calculateZoomScaleAndAnimate:NO];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

  [self setupToolbar];

  if (self.comic.downloaded) {
    [self displayComicImage];    
  } else {
	  [self displayLoadingView];
	  self.imageFetcher = [[SingleComicImageFetcher alloc] init];
	  self.imageFetcher.delegate = self;
	  [self.imageFetcher fetchImageForComic:self.comic context:nil];
  }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self calculateZoomScaleAndAnimate:YES];
}

- (void)setupToolbar {
	UIBarButtonItem *systemActionItem = [UIBarButtonItem barButtonSystemItem:UIBarButtonSystemItemAction
																	  target:self
																	  action:@selector(systemAction:)];
	
	UIBarButtonItem *previousItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"previous"]
																	 style:UIBarButtonItemStylePlain
																	target:self
																	action:@selector(goToPreviousComic)];
	previousItem.accessibilityLabel = NSLocalizedString(@"Older comic", @"older_comic_accessibility_label");
	previousItem.enabled = (self.comic.number.unsignedIntegerValue != kMinComicNumber);
	
	UIBarButtonItem *randomItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"random"]
																   style:UIBarButtonItemStylePlain
																  target:self
																  action:@selector(goToRandomComic)];
	randomItem.accessibilityLabel = NSLocalizedString(@"Random comic", @"random_comic_accessibility_label");
	
	UIBarButtonItem *nextItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"next"]
																 style:UIBarButtonItemStylePlain
																target:self
																action:@selector(goToNextComic)];
	nextItem.accessibilityLabel = NSLocalizedString(@"Newer comic", @"newer_comic_accessibility_label");
	nextItem.enabled = (self.comic.number.unsignedIntegerValue != [Comic lastKnownComic].number.unsignedIntegerValue);
	
	NSArray *toolbarItems = @[systemActionItem,
							  [UIBarButtonItem flexibleSpaceBarButtonItem],
							  [UIBarButtonItem flexibleSpaceBarButtonItem],
							  [UIBarButtonItem flexibleSpaceBarButtonItem],
							  [UIBarButtonItem flexibleSpaceBarButtonItem],
							  previousItem,
							  [UIBarButtonItem flexibleSpaceBarButtonItem],
							  randomItem,
							  [UIBarButtonItem flexibleSpaceBarButtonItem],
							  nextItem];
	
	[self setToolbarItems:toolbarItems animated:NO];
	[self.navigationController setToolbarHidden:NO animated:NO];
}

- (void)displayComicImage {
	// Load up the comic image/view
	UIImage *comicImage = self.comic.image;
	CGSize contentSize = comicImage.exifAgnosticSize;
	TiledImage *tiles = [[TiledImage alloc] initWithImage:comicImage tileWidth:kTileWidth tileHeight:kTileHeight];
	self.contentView = [[UIView alloc] initWithFrame:CGRectZeroWithSize(contentSize)];
	self.comicImageViews = [NSMutableArray arrayWithCapacity:(tiles.widthCount * tiles.heightCount)];
	for (NSUInteger x = 0; x < tiles.widthCount; ++x) {
		for (NSUInteger y = 0; y < tiles.heightCount; ++y) {
			UIImageView *comicImageView = [[UIImageView alloc] initWithImage:[tiles imageAtXIndex:x YIndex:y]];
			comicImageView.frame = CGRectWithXYAndSize(x * kTileWidth, y * kTileHeight, comicImageView.frame.size); // adjust origin appropriately
			[self.comicImageViews addObject:comicImageView];
		}
	}
	
	for (UIView *tileView in self.comicImageViews) {
		[self.contentView addSubview:tileView];
	}
	[self.imageScroller addSubview:self.contentView];
	
	if ([AppDelegate openZoomedOut]) {
		[self.imageScroller setZoomScale:self.imageScroller.minimumZoomScale animated:NO];
	}
	
	UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showTitleText:)];
	longPress.minimumPressDuration = 0.5f;
	[self.view addGestureRecognizer:longPress];
	
	UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDetectDoubleTap:)];
	doubleTap.numberOfTapsRequired = 2;
	[self.view addGestureRecognizer:doubleTap];
	
	UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDetectSingleTap:)];
	[singleTap requireGestureRecognizerToFail:doubleTap];
	[self.view addGestureRecognizer:singleTap];
	
	self.view.isAccessibilityElement = YES;
	self.view.accessibilityHint = nil;
	
	if (self.comic.transcript.length == 0) {
		self.view.accessibilityLabel = @"Transcript not available";
		NSLog(@"Missing transcript for comic %li", (long)self.comic.number.integerValue);
	} else {
		self.view.accessibilityLabel = self.comic.transcript; // TODO: Clean up the transcript some for a more pleasant listening experience
	}
}

- (void) calculateZoomScaleAndAnimate:(BOOL)animate {
	CGSize contentSize = self.comic.image.exifAgnosticSize;
	self.imageScroller.contentSize = contentSize;
	self.imageScroller.maximumZoomScale = 2;
	CGFloat xMinZoom = self.imageScroller.frame.size.width / contentSize.width;
	CGFloat yMinZoom = (self.imageScroller.frame.size.height - (self.navigationController.navigationBar.frame.size.height + self.navigationController.toolbar.frame.size.height)) / contentSize.height;
	self.imageScroller.minimumZoomScale = (xMinZoom < yMinZoom) ? xMinZoom : yMinZoom;
	if (self.imageScroller.zoomScale < self.imageScroller.minimumZoomScale) {
		[self.imageScroller setZoomScale:self.imageScroller.minimumZoomScale animated:animate];
	}
}

- (void)displayLoadingView {
	self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[self.view addSubview:self.loadingView];
	[self.loadingView startAnimating];
	self.loadingView.translatesAutoresizingMaskIntoConstraints = NO;
	NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:self.loadingView
															   attribute:NSLayoutAttributeCenterX
															   relatedBy:NSLayoutRelationEqual
																  toItem:self.view
															   attribute:NSLayoutAttributeCenterX
															  multiplier:1.0
																constant:0];
	NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:self.loadingView
															   attribute:NSLayoutAttributeCenterY
															   relatedBy:NSLayoutRelationEqual
																  toItem:self.view
															   attribute:NSLayoutAttributeCenterY
															  multiplier:1.0
																constant:0];
	[self.view addConstraint:centerX];
	[self.view addConstraint:centerY];
}

- (void)toggleToolbarsAnimated:(BOOL)animated {
	self.hidingToolbars = !self.navigationController.toolbarHidden;
	[self.navigationController setToolbarHidden:self.hidingToolbars animated:animated];
	[self.navigationController setNavigationBarHidden:self.hidingToolbars animated:animated];
	[self setNeedsStatusBarAppearanceUpdate];
}

- (BOOL)prefersStatusBarHidden {
	return self.hidingToolbars
	|| self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact;
}

- (void)systemAction:(UIBarButtonItem *)sender {
	FCOpenInSafariActivity *safariActivity = [[FCOpenInSafariActivity alloc] init];
	FCOpenInChromeActivity *chromeActivity = [[FCOpenInChromeActivity alloc] init];
	
	NSMutableArray *activityItems = [NSMutableArray arrayWithCapacity:2];
	NSURL *comicUrl = [NSURL URLWithString:self.comic.websiteURL];
	[activityItems addObject:comicUrl];
	if (self.comic.downloaded && self.comic.image) {
		[activityItems addObject:self.comic.image];
	}
	
	UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems
																						 applicationActivities:@[safariActivity, chromeActivity]];
	activityViewController.excludedActivityTypes = @[UIActivityTypeAssignToContact];
	[self presentViewController:activityViewController animated:YES completion:^{}];
}

- (void)goToPreviousComic {
	[self goToComicNumbered:([self.comic.number unsignedIntegerValue] - 1)];
}

- (void)goToRandomComic {
	NSUInteger maxComicNumber = [[Comic lastKnownComic].number unsignedIntegerValue];
	long randNumber = [TLMersenneTwister randInt31];
	NSUInteger randomComicNumber = randNumber % (maxComicNumber - kMinComicNumber) + kMinComicNumber;
	[self goToComicNumbered:randomComicNumber];
}

- (void)goToNextComic {
	[self goToComicNumbered:([self.comic.number unsignedIntegerValue] + 1)];
}

- (void)goToComicNumbered:(NSUInteger)comicNumber {
	NSMutableArray *viewControllerStack = [self.navigationController.viewControllers mutableCopy];
	Comic *newComic = [Comic comicNumbered:comicNumber];
	SingleComicViewController *newSingleComicViewController = [[SingleComicViewController alloc] initWithComic:newComic];
	viewControllerStack[[viewControllerStack count] - 1] = newSingleComicViewController;
	[self.navigationController setViewControllers:viewControllerStack animated:NO];
	
	ComicListViewController *comicList = viewControllerStack[0];
	[comicList.tableView selectRowAtIndexPath:[comicList indexPathForComicNumbered:[newComic.number integerValue]]
									 animated:NO
							   scrollPosition:UITableViewScrollPositionMiddle];
}

#pragma mark - Gesture recognizer callbacks

- (void)didDetectDoubleTap:(UITapGestureRecognizer *)recognizer {
	CGFloat newZoomScale = 1.0f;
	if (self.imageScroller.zoomScale == self.imageScroller.minimumZoomScale) {
		newZoomScale = (self.imageScroller.minimumZoomScale * 2) > self.imageScroller.maximumZoomScale ? self.imageScroller.maximumZoomScale : (self.imageScroller.minimumZoomScale * 2);
		// zoom towards the user's double tap
		CGPoint centerPoint = [recognizer locationInView:self.imageScroller];
		NSLog(@"scale = %f, point = %@", newZoomScale, NSStringFromCGPoint(centerPoint));
		[self.imageScroller setZoomScale:newZoomScale animated:YES centerOnPoint:centerPoint];
	} else {
    newZoomScale = self.imageScroller.minimumZoomScale;
	  NSLog(@"scale = %f", newZoomScale);
    [self.imageScroller setZoomScale:newZoomScale animated:YES];
  }
}

- (void)didDetectSingleTap:(UITapGestureRecognizer *)recognizer {
  [self toggleToolbarsAnimated:YES];
}

- (void)showTitleText:(UILongPressGestureRecognizer *)recognizer {
  if (recognizer.state == UIGestureRecognizerStateBegan) {
    [UIAlertView showAlertWithTitle:nil message:self.comic.titleText];
  }
}

#pragma mark - SingleComicImageFetcherDelegate methods

- (void)singleComicImageFetcher:(SingleComicImageFetcher *)fetcher
          didFetchImageForComic:(Comic *)comic
                        context:(id)context {
  self.imageFetcher = nil;
  [self.loadingView removeFromSuperview];
  [self displayComicImage];
}

- (void)singleComicImageFetcher:(SingleComicImageFetcher *)fetcher
               didFailWithError:(NSError *)error
                        onComic:(Comic *)comic {
	// Tell the user
	NSString *localizedFormatString;
	
	if ([error.domain isEqualToString:kXkcdErrorDomain]) {
		// internal error
		localizedFormatString = NSLocalizedString(@"Could not download xkcd %i.",
												  @"Text of unknown error image download fail alert");
	}
	else {
		localizedFormatString = NSLocalizedString(@"Could not download xkcd %i -- no internet connection.",
												  @"Text of image download fail alert due to connectivity");
	}
	
	NSString *failAlertMessage = [NSString stringWithFormat:localizedFormatString, comic.number.integerValue];
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Whoops", @"Title of image download fail alert")
																			 message:failAlertMessage
																	  preferredStyle:UIAlertControllerStyleAlert];
	[alertController addAction:
	 [UIAlertAction actionWithTitle:@"Ok"
							  style:UIAlertActionStyleDefault
							handler:^(UIAlertAction * _Nonnull action) {
								[self.navigationController popViewControllerAnimated:YES];
							}]
	 ];
	
	[self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UIScrollViewDelegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
  return self.contentView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
}

@end
