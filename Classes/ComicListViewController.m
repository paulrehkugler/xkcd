//
//  ComicListViewController.m
//

#import "ComicListViewController.h"
#import "Comic.h"
#import "NewComicFetcher.h"
#import "xkcdAppDelegate.h"
#import "XkcdErrorCodes.h"
#import "SingleComicViewController.h"
#import "SingleComicImageFetcher.h"
#import "CGGeometry_TLCommon.h"
#import "LambdaSheet.h"
#import "UIBarButtonItem_TLCommon.h"
#import "UIActivityIndicatorView_TLCommon.h"
#import "UITableView_TLCommon.h"
#import "UIAlertView_TLCommon.h"
#import "FAQViewController.h"
#import "TLMacros.h"
#import "UIImage+EXIFCompensation.h"

#define kTableViewBackgroundColor [UIColor colorWithRed:0.69f green:0.737f blue:0.80f alpha:0.5f]
#define kUserDefaultsSavedTopVisibleComicKey @"topVisibleComic"

#pragma mark -

static UIImage *downloadImage = nil;

#pragma mark -

@interface ComicListViewController ()

- (NSFetchedResultsController *)fetchedResultsControllerWithSearchString:(NSString *)searchString;
- (void)setFetchedResultsController;
- (void)setSearchFetchedResultsControllerWithSearchString:(NSString *)searchString;
- (Comic *)comicAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)aTableView;
- (void)viewComic:(Comic *)comic;
- (void)reloadAllData;
- (void)fetchImageForComic:(Comic *)comic;
- (void)checkForNewComics;
- (void)downloadAll:(UIBarButtonItem *)sender;
- (void)deleteAll:(UIBarButtonItem *)sender;
- (void)edit:(UIBarButtonItem *)sender;
- (void)doneEditing:(UIBarButtonItem *)sender;
- (void)addSearchBarTableHeader;
- (void)addRefreshControl;
- (void)addNavigationBarButtons;
- (void)scrollToComicAtIndexPath:(NSIndexPath *)indexPath;
- (void)deleteAllComicImages;
- (void)downloadAllComicImages;
- (NSFetchedResultsController *)fetchedResultsControllerForTableView:(UITableView *)aTableView;
- (void)didStartRefreshing;
- (void)didFinishRefreshing;
- (UITableView *)activeTableView;
- (UITableView *)tableViewForFetchedResultsController:(NSFetchedResultsController *)controller;
- (void)saveScrollPosition;
- (void)restoreScrollPosition;

// Action sheet actions
- (void)emailDeveloper;

@property (nonatomic) NewComicFetcher *fetcher;
@property (nonatomic) SingleComicImageFetcher *imageFetcher;
@property (nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) NSFetchedResultsController *searchFetchedResultsController;
@property (nonatomic) UISearchDisplayController *searchController;

@end

#pragma mark -

@implementation ComicListViewController

+ (void)initialize {
	if ([self class] == [ComicListViewController class]) {
		if (!downloadImage) {
			downloadImage = [[UIImage imageNamed:@"download"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		}
	}
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
	if (self = [super initWithStyle:style]) {
		self.title = NSLocalizedString(@"xkcd", @"Title of main view");
	}
	return self;
}

- (void)addSearchBarTableHeader {
	UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
	searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[searchBar sizeToFit];
	searchBar.placeholder = NSLocalizedString(@"Search xkcd", @"Search bar placeholder text");
	searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	searchBar.delegate = self;
	self.tableView.tableHeaderView = searchBar;
}

- (void)addRefreshControl {
	UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
	[refreshControl addTarget:self action:@selector(checkForNewComics) forControlEvents:UIControlEventValueChanged];
	
	self.refreshControl = refreshControl;
}

- (void)addNavigationBarButtons {
	UIBarButtonItem *systemItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
																				target:self
																				action:@selector(systemAction:)
								   ];
	self.navigationItem.leftBarButtonItem = systemItem;
	
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.navigationItem.rightBarButtonItem.target = self;
	self.navigationItem.rightBarButtonItem.action = @selector(edit:);
	
#if GENERATE_DEFAULT_PNG
	self.navigationItem.leftBarButtonItem.enabled = NO;
	self.navigationItem.rightBarButtonItem.enabled = NO;
#endif
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[self addRefreshControl];
	[self addNavigationBarButtons];
	[self addSearchBarTableHeader];
	[self setFetchedResultsController];
	
	[self reloadAllData];
	[self scrollToComicAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	
	// Set up new comic fetcher
	if (!self.fetcher) {
		self.fetcher = [[NewComicFetcher alloc] init];
		self.fetcher.delegate = self;
	}
	
	// Set up image fetcher, for the future
	if (!self.imageFetcher) {
		self.imageFetcher = [[SingleComicImageFetcher alloc] init];
		self.imageFetcher.delegate = self;
	}
	
	[self checkForNewComics];
	
	if (self.requestedLaunchComic) {
		NSIndexPath *indexPath = [self indexPathForComicNumbered:self.requestedLaunchComic];
		if (indexPath) {
			[self scrollToComicAtIndexPath:indexPath];
			Comic *launchComic = [Comic comicNumbered:self.requestedLaunchComic];
			[self viewComic:launchComic];
		}
		self.requestedLaunchComic = 0;
	}
	else {
		[self restoreScrollPosition];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.navigationController setToolbarHidden:YES animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	[self.searchController.searchResultsTableView deselectRowAtIndexPath:[self.searchController.searchResultsTableView indexPathForSelectedRow] animated:NO];
	[self reloadAllData]; // TODO: Is this necessary?
}

- (void)dealloc {
	_fetcher.delegate = nil;
	
	_imageFetcher.delegate = nil;
	
	_searchController.searchBar.delegate = nil;
	_searchController.delegate = nil;
	_searchController.searchResultsDataSource = nil;
	_searchController.searchResultsDelegate = nil;
}

- (void)scrollToComicAtIndexPath:(NSIndexPath *)indexPath {
	@try {
		[self.tableView scrollToRowAtIndexPath:indexPath
							  atScrollPosition:UITableViewScrollPositionTop
									  animated:NO];
	} @catch (NSException *e) {
		NSLog(@"Scroll error");
	}
}

- (NSFetchedResultsController *)fetchedResultsControllerWithSearchString:(NSString *)searchString {
	// Set up table data fetcher
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	fetchRequest.entity = [Comic entityDescription];
	if (searchString) {
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@ OR titleText CONTAINS[cd] %@ OR transcript CONTAINS[cd] %@ OR number = %@",
								  searchString, searchString, searchString, @([searchString integerValue])];
	}
	fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"number" ascending:NO]];
	
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																								managedObjectContext:AppDelegate.managedObjectContext
																								  sectionNameKeyPath:nil
																										   cacheName:nil];
	aFetchedResultsController.delegate = self;
	return aFetchedResultsController;
}

- (void)setFetchedResultsController {
	self.fetchedResultsController = [self fetchedResultsControllerWithSearchString:nil];
	
	NSError *fetchError = nil;
	BOOL success = [self.fetchedResultsController performFetch:&fetchError];
	if (!success) {
		NSLog(@"List fetch failed");
	}
}

- (void)setSearchFetchedResultsControllerWithSearchString:(NSString *)searchString {
	self.searchFetchedResultsController = [self fetchedResultsControllerWithSearchString:searchString];
	
	NSError *fetchError = nil;
	BOOL success = [self.searchFetchedResultsController performFetch:&fetchError];
	if (!success) {
		NSLog(@"Search list fetch failed");
	}
}

- (void)viewComic:(Comic *)comic {
	SingleComicViewController *singleComicViewController = [[SingleComicViewController alloc] initWithComic:comic];
	[self.navigationController pushViewController:singleComicViewController animated:YES];
}

- (void)checkForNewComics {
	[self didStartRefreshing];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[self.fetcher fetch];
}

- (void)fetchImageForComic:(Comic *)comic {
	BOOL openAfterDownloadPreferenceSet = [AppDelegate openAfterDownload];
	BOOL isLaunchComic = (self.requestedLaunchComic && ([comic.number integerValue] == self.requestedLaunchComic));
	
	if (isLaunchComic) {
		self.requestedLaunchComic = 0;
	}
	
	BOOL openAfterDownload = openAfterDownloadPreferenceSet || isLaunchComic;
	[self.imageFetcher fetchImageForComic:comic context:@(openAfterDownload)];
}

- (void)reloadAllData {
	[self.activeTableView reloadData];
}

- (void)systemAction:(UIBarButtonItem *)sender {
	LambdaSheet *sheet = [[LambdaSheet alloc] initWithTitle:nil];
	if ([MFMailComposeViewController canSendMail]) {
		[sheet addButtonWithTitle:NSLocalizedString(@"Email the app developer", @"Action sheet title")
							block:^ {
								[self emailDeveloper];
							}];
	}
	[sheet addButtonWithTitle:NSLocalizedString(@"Read the FAQ", @"Action sheet title")
						block:^ {
							FAQViewController *faq = [[FAQViewController alloc] initWithNibName:nil bundle:nil];
							UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:faq];
							[self presentViewController:nav animated:YES completion:^{}];
						}];
	[sheet addButtonWithTitle:NSLocalizedString(@"Write App Store review", @"Action sheet title")
						block:^ {
							NSURL *appStoreReviewURL = [NSURL URLWithString:@"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=303688284&pageNumber=0&sortOrdering=1&type=Purple+Software&mt=8"];
							[[UIApplication sharedApplication] openURL:appStoreReviewURL];
						}];
	[sheet addButtonWithTitle:NSLocalizedString(@"Share link to this app", @"Action sheet title")
						block:^ {
							NSURL *appUrl = [NSURL URLWithString:@"http://bit.ly/xkcdapp"];
							UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[appUrl]
																												 applicationActivities:nil];
							
							[self presentViewController:activityViewController animated:YES completion:^{}];
						}];
	[sheet addCancelButton];
	[sheet showInView:self.view];
}

- (void)edit:(UIBarButtonItem *)sender {
	[self setEditing:YES animated:YES];
	[self.tableView setEditing:YES animated:YES];
	
	CGFloat searchBarHeight = self.tableView.tableHeaderView.bounds.size.height;
	[self.tableView setContentOffset:CGPointByAddingYOffset(self.tableView.contentOffset, -searchBarHeight)];
	self.tableView.tableHeaderView = nil;
	self.refreshControl = nil;
	
	self.navigationItem.rightBarButtonItem.action = @selector(doneEditing:);
	[self.navigationController setToolbarHidden:NO animated:YES];
	UIBarButtonItem *downloadAll = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Download all", @"Button")
																	style:UIBarButtonItemStylePlain
																   target:self
																   action:@selector(downloadAll:)];
	UIBarButtonItem *deleteAll = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Delete all", @"Button")
																  style:UIBarButtonItemStylePlain
																 target:self
																 action:@selector(deleteAll:)];
	deleteAll.tintColor = [UIColor redColor];
	
	UIBarButtonItem *cancelDownloadAll = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel download all", @"Button")
																		  style:UIBarButtonItemStylePlain
																		 target:self
																		 action:@selector(cancelDownloadAll:)];
	NSArray *toolbarItems = nil;
	if ([self.imageFetcher downloadingAll]) {
		toolbarItems = @[[UIBarButtonItem flexibleSpaceBarButtonItem], cancelDownloadAll];
	}
	else {
		toolbarItems = @[deleteAll, [UIBarButtonItem flexibleSpaceBarButtonItem], downloadAll];
	}
	[self setToolbarItems:toolbarItems animated:YES];
	self.navigationItem.leftBarButtonItem.enabled = NO;
}

- (void)doneEditing:(UIBarButtonItem *)sender {
	[self setEditing:NO animated:YES];
	[self.tableView setEditing:NO animated:YES];
	[self addRefreshControl];
	[self addSearchBarTableHeader];
	[self.tableView setContentOffset:
	 CGPointByAddingYOffset(self.tableView.contentOffset, self.tableView.tableHeaderView.bounds.size.height)];
	self.navigationItem.rightBarButtonItem.action = @selector(edit:);
	[self.navigationController setToolbarHidden:YES animated:YES];
	
	self.navigationItem.leftBarButtonItem.enabled = YES;
}

- (void)downloadAll:(UIBarButtonItem *)sender {
	NSString *sheetTitle = NSLocalizedString(@"Downloading all images may take up considerable space on your device.", @"Download all warning");
	LambdaSheet *sheet = [[LambdaSheet alloc] initWithTitle:sheetTitle];
	[sheet addButtonWithTitle:NSLocalizedString(@"Download all images", @"Confirm download all button")
						block:^ {
							[self downloadAllComicImages];
						}];
	[sheet addCancelButton];
	[sheet showFromToolbar:self.navigationController.toolbar];
}

- (void)cancelDownloadAll:(UIBarButtonItem *)sender {
	[self.imageFetcher cancelDownloadAll];
	[self doneEditing:nil];
	[self reloadAllData];
}

- (void)deleteAll:(UIBarButtonItem *)sender {
	LambdaSheet *sheet = [[LambdaSheet alloc] initWithTitle:nil];
	[sheet addDestructiveButtonWithTitle:NSLocalizedString(@"Delete all images", @"Confirm delete all button")
								   block:^ {
									   [self deleteAllComicImages];
								   }];
	[sheet addCancelButton];
	[sheet showFromToolbar:self.navigationController.toolbar];
}

- (UITableView *)activeTableView {
	return self.searchController.active ? self.searchController.searchResultsTableView : self.tableView;
}

- (UITableView *)tableViewForFetchedResultsController:(NSFetchedResultsController *)controller {
	return [controller isEqual:self.searchFetchedResultsController] ? self.searchController.searchResultsTableView : self.tableView;
}


#pragma mark -
#pragma mark NewComicFetcherDelegate methods

- (void)newComicFetcher:(NewComicFetcher *)fetcher didFetchComic:(Comic *)comic {
	[AppDelegate save]; // write new comic to disk so that CoreData can clear its memory as needed
	if ([AppDelegate downloadNewComics]) {
		[self fetchImageForComic:comic];
	}
}

- (void)newComicFetcherDidFinishFetchingAllComics:(NewComicFetcher *)fetcher {
	[self didFinishRefreshing];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)newComicFetcher:(NewComicFetcher *)comicFetcher didFailWithError:(NSError *)error {
	if ([error.domain isEqualToString:kXkcdErrorDomain]) {
		NSLog(@"Internal error: %@", error);
	}
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[self didFinishRefreshing];
	// TODO: Show in the UI that the fetch failed? e.g. modal indication a la tweetie 2?
}

#pragma mark -
#pragma mark SingleComicImageFetcherDelegate methods

- (void)singleComicImageFetcher:(SingleComicImageFetcher *)fetcher
		  didFetchImageForComic:(Comic *)comic
						context:(id)context {
	if ([context boolValue] && (self.navigationController.topViewController == self)) { // context boolvalue == open after download
		[self viewComic:comic];
	}
}

- (void)singleComicImageFetcher:(SingleComicImageFetcher *)fetcher
			   didFailWithError:(NSError *)error
						onComic:(Comic *)comic {
	// The image fetcher throws up an alert for us...not much to do here, really...
}


#pragma mark -
#pragma mark UITableViewDelegate and UITableViewDataSource and supporting methods

- (NSIndexPath *)indexPathForComicNumbered:(NSInteger)comicNumber {
	NSInteger lastKnownComicNumber = [Comic lastKnownComic].number.integerValue;
	if (lastKnownComicNumber >= comicNumber) {
		return [NSIndexPath indexPathForRow:(lastKnownComicNumber - comicNumber) inSection:0];
	}
	return nil;
}

- (Comic *)comicAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)aTableView {
	Comic *comic = [[self fetchedResultsControllerForTableView:aTableView] objectAtIndexPath:indexPath];
	return comic;
}

- (NSFetchedResultsController *)fetchedResultsControllerForTableView:(UITableView *)aTableView {
	NSFetchedResultsController *fetchedResults = [self.tableView isEqual:aTableView] ? self.fetchedResultsController : self.searchFetchedResultsController;
	return fetchedResults;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = nil;
	
	// Comic cell
	static NSString *comicCellIdentifier = @"comicCell";
	UITableViewCell *comicCell = [self.tableView dequeueReusableCellWithIdentifier:comicCellIdentifier];
	if (!comicCell) {
		comicCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:comicCellIdentifier];
	}
	
#if GENERATE_DEFAULT_PNG
	return comicCell;
#endif
	
	Comic *comic = [self comicAtIndexPath:indexPath inTableView:aTableView];
	comicCell.textLabel.text = [NSString stringWithFormat:@"%li. %@", (long)[comic.number integerValue], comic.name];
	comicCell.textLabel.font = [UIFont systemFontOfSize:16];
	comicCell.textLabel.adjustsFontSizeToFitWidth = YES;
	
	if ([comic.number integerValue] == 404) {
		// Handle comic 404 specially...sigh
		comicCell.accessoryView = nil;
		comicCell.accessoryType = UITableViewCellAccessoryNone;
		comicCell.accessibilityHint = nil;
	}
	else {
		if (comic.downloaded) {
			comicCell.accessoryView = nil;
			comicCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			comicCell.accessibilityHint = NSLocalizedString(@"Opens the comic", @"downloaded_comic_accessibility_hint");
		}
		else if ([comic.loading boolValue] || [self.imageFetcher downloadingAll]) {
			comicCell.accessoryView = [UIActivityIndicatorView animatingActivityIndicatorViewWithStyle:UIActivityIndicatorViewStyleGray];
			comicCell.accessibilityHint = NSLocalizedString(@"Waiting for download", @"downloading_comic_accessibility_hint");
		}
		else {
			UIImageView *downloadImageView = [[UIImageView alloc] initWithImage:downloadImage];
			downloadImageView.opaque = YES;
			comicCell.accessoryView = downloadImageView;
			comicCell.accessibilityHint = NSLocalizedString(@"Downloads the comic", @"undownloaded_comic_accessibility_hint");
		}
	}
	
	comicCell.editingAccessoryView = [[UIView alloc] initWithFrame:CGRectZero];
	
	cell = comicCell;
	return cell;
}

- (void)tableView:(UITableView *)aTableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	cell.backgroundColor = [UIColor whiteColor];
	cell.accessoryView.backgroundColor = [UIColor whiteColor];
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	Comic *selectedComic = [self comicAtIndexPath:indexPath inTableView:aTableView];
	BOOL shouldDeselect = YES;
	if ([selectedComic.number integerValue] != 404) {
		if (selectedComic.downloaded) {
			[self viewComic:selectedComic];
			shouldDeselect = NO;
		}
		else if (!([selectedComic.loading boolValue] || [self.imageFetcher downloadingAll])) {
			[self fetchImageForComic:selectedComic];
		}
	}
	
	if (shouldDeselect) {
		[aTableView deselectRowAtIndexPath:indexPath animated:NO];
	}
}

- (NSString *)tableView:(UITableView *)aTableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
	return NSLocalizedString(@"Delete", @"Delete button title");
}

- (BOOL)tableView:(UITableView *)aTableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	if (![aTableView isEqual:self.tableView]) {
		return NO;
	}
	return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (![aTableView isEqual:self.tableView]) {
		return UITableViewCellEditingStyleNone;
	}
	Comic *comic = [self comicAtIndexPath:indexPath inTableView:aTableView];
	return comic.downloaded ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)aTableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	if (![aTableView isEqual:self.tableView]) {
		return NO;
	}
	Comic *comic = [self comicAtIndexPath:indexPath inTableView:aTableView];
	return comic.downloaded;
}

- (void)tableView:(UITableView *)aTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		Comic *comic = [self comicAtIndexPath:indexPath inTableView:aTableView];
		[comic deleteImage];
		[self.tableView reloadRowAtIndexPath:indexPath withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	NSFetchedResultsController *fetchedResults = [self fetchedResultsControllerForTableView:aTableView];
	NSArray *sections = [fetchedResults sections];
	NSUInteger numberOfRows = 0;
	if ([sections count] > 0) {
		id<NSFetchedResultsSectionInfo> sectionInfo = sections[section];
		numberOfRows = [sectionInfo numberOfObjects];
	}
	return numberOfRows;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
	NSFetchedResultsController *fetchedResults = [self fetchedResultsControllerForTableView:aTableView];
	NSUInteger numberOfSections = [[fetchedResults sections] count];
	if (numberOfSections == 0) {
		numberOfSections = 1;
	}
	return numberOfSections;
}

#pragma mark -
#pragma mark UISearchBarDelegate methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
	if (!self.searchController) {
		self.searchController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
		self.searchController.searchResultsDataSource = self;
		self.searchController.searchResultsDelegate = self;
		self.searchController.delegate = self;
	}
	[self.searchController setActive:YES animated:YES];
}

#pragma mark -
#pragma mark UISearchDisplayDelegate methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
	[self setSearchFetchedResultsControllerWithSearchString:searchString];
	[self.searchDisplayController.searchResultsTableView reloadData];
	return YES;
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
	[self.searchDisplayController.searchResultsTableView reloadData];
	[self.searchDisplayController.searchBar resignFirstResponder];
	[self reloadAllData];
}

#pragma mark -
#pragma mark TLActionSheetController supporting methods

- (void)emailDeveloper {
	MFMailComposeViewController *emailViewController = [[MFMailComposeViewController alloc] initWithNibName:nil bundle:nil];
	emailViewController.mailComposeDelegate = self;
	emailViewController.subject = [NSString stringWithFormat:NSLocalizedString(@"Feedback on xkcd app (version %@)", @"Subject of feedback email"),
								   [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"]];
	emailViewController.toRecipients = @[@"feedback@xkcdapp.com"];
	
	[self presentViewController:emailViewController animated:YES completion:^{}];
	
	[UIAlertView showAlertWithTitle:NSLocalizedString(@"Do me a favor?", @"Alert title")
							message:NSLocalizedString(@"Take a look at the FAQ before emailing. Thanks!", @"Alert body")];
}

- (void)downloadAllComicImages {
	[self.imageFetcher fetchImagesForAllComics];
	[self doneEditing:nil];
	[self reloadAllData]; // so that all the spinners start up
}

- (void)deleteAllComicImages {
	[self doneEditing:nil];
	
	TLModalActivityIndicatorView *modalSpinner = [[TLModalActivityIndicatorView alloc] initWithText:NSLocalizedString(@"Deleting...", @"Modal spinner text")];
	[modalSpinner show];
	
	NSSet *downloadedImages = [Comic downloadedImages];
	
	dispatch_queue_t deletionQueue = dispatch_queue_create("com.treelinelabs.xkcd.delete_images", NULL);
	dispatch_async(deletionQueue, ^{
		// delete each comic, one by one
		for (NSString *downloadedImage in downloadedImages) {
			// for each one, yield to the main thread, to keep the ui responsive (don't flood)
			dispatch_sync(dispatch_get_main_queue(), ^{
				[Comic deleteDownloadedImage:downloadedImage];
			});
		}
		
		// done doing work
		dispatch_async(dispatch_get_main_queue(), ^{
			// reflect the deletions in the UI
			[self reloadAllData];
			[modalSpinner dismiss];
		});
	});
}

#pragma mark -
#pragma mark MFMailComposeViewControllerDelegate methods

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[controller dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	UITableView *tableViewToUpdate = [self tableViewForFetchedResultsController:controller];
	[tableViewToUpdate beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex:(NSUInteger)sectionIndex
	 forChangeType:(NSFetchedResultsChangeType)type {
	
	UITableView *tableViewToUpdate = [self tableViewForFetchedResultsController:controller];
	
	switch(type) {
		case NSFetchedResultsChangeInsert:;
			[tableViewToUpdate insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
							 withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeDelete:;
			[tableViewToUpdate deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
							 withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeMove:
		case NSFetchedResultsChangeUpdate:
			break;
	}
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath
	 forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath {
	
	UITableView *tableViewToUpdate = [self tableViewForFetchedResultsController:controller];
	
	switch(type) {
		case NSFetchedResultsChangeInsert:;
			[tableViewToUpdate insertRowsAtIndexPaths:@[newIndexPath]
									 withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:;
			[tableViewToUpdate deleteRowsAtIndexPaths:@[indexPath]
									 withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeUpdate:;
			[tableViewToUpdate reloadRowAtIndexPath:indexPath withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeMove:;
			[tableViewToUpdate deleteRowsAtIndexPaths:@[indexPath]
									 withRowAnimation:UITableViewRowAnimationFade];
			[tableViewToUpdate reloadSections:[NSIndexSet indexSetWithIndex:newIndexPath.section]
							 withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
	
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	UITableView *tableViewToUpdate = [self tableViewForFetchedResultsController:controller];
	
	[tableViewToUpdate endUpdates];
}

#pragma mark -
#pragma mark Pull to refresh methods

- (void)didStartRefreshing {
	[self.refreshControl beginRefreshing];
}

- (void)didFinishRefreshing {
	[self.refreshControl endRefreshing];
}

#pragma mark -
#pragma mark Scroll position saving/restoring

- (void)saveScrollPosition {
	NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
	if (visibleIndexPaths.count > 0) {
		NSIndexPath *topIndexPath = visibleIndexPaths[0];
		Comic *topComic = [self comicAtIndexPath:topIndexPath inTableView:self.tableView];
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults setInteger:topComic.number.integerValue forKey:kUserDefaultsSavedTopVisibleComicKey];
		[userDefaults synchronize];
	}
}

- (void)restoreScrollPosition {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSInteger topVisibleComic = [userDefaults integerForKey:kUserDefaultsSavedTopVisibleComicKey];
	[self scrollToComicAtIndexPath:[self indexPathForComicNumbered:topVisibleComic]];
}


#pragma mark -
#pragma mark UIScrollViewDelegate methods

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if ([self.activeTableView isEqual:self.tableView]) {
		if (!decelerate) {
			[self saveScrollPosition];
		}
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	if ([self.activeTableView isEqual:self.tableView]) {
		[self saveScrollPosition];
	}
}

@end
