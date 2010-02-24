//
//  ComicListViewController.m
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 8/25/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import "ComicListViewController.h"
#import "Comic.h"
#import "UIViewController_TLCommon.h"
#import "NewComicFetcher.h"
#import "xkcdAppDelegate.h"
#import "FlurryAPI.h"
#import "XkcdErrorCodes.h"
#import "SingleComicViewController.h"
#import "SingleComicImageFetcher.h"
#import "CGGeometry_TLCommon.h"
#import "LorenRefreshView.h"

#define kTableViewBackgroundColor [UIColor colorWithRed:0.69f green:0.737f blue:0.80f alpha:0.5f]
#define kRefreshTriggerOffset 65.0f
#define kDuringRefreshContentOffset 80.0f
#define kRefreshContentOffsetAnimationDuration 0.2f
#define kReturnToNormalContentOffsetAnimationDuration 0.3f

#pragma mark -

static UIImage *downloadImage = nil;

#pragma mark -

@interface ComicListViewController ()

- (NSFetchedResultsController *)fetchedResultsControllerWithSearchString:(NSString *)searchString cacheName:(NSString *)cacheName;
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
- (void)setSearchBarTableHeader;
- (void)deleteAllComicImages;
- (void)downloadAllComicImages;
- (NSFetchedResultsController *)fetchedResultsControllerForTableView:(UITableView *)aTableView;
- (void)showRefreshAnimation;
- (void)didStartRefreshing;
- (void)didFinishRefreshing;

@property(nonatomic, retain, readwrite) UITableView *tableView;
@property(nonatomic, retain, readwrite) NewComicFetcher *fetcher;
@property(nonatomic, retain, readwrite) SingleComicImageFetcher *imageFetcher;
@property(nonatomic, retain, readwrite) NSFetchedResultsController *fetchedResultsController;
@property(nonatomic, retain, readwrite) NSFetchedResultsController *searchFetchedResultsController;
@property(nonatomic, retain, readwrite) UISearchDisplayController *searchController;
@property(nonatomic, retain, readwrite) NSString *savedSearchTerm;
@property(nonatomic, assign, readwrite) BOOL searchWasActive;
@property(nonatomic, retain, readwrite) TLModalActivityIndicatorView *modalSpinner;
@property(nonatomic, retain, readwrite) LorenRefreshView *refreshHeaderView;
@property(nonatomic, assign, readwrite) BOOL shouldCheckForRefreshGesture;
@property(nonatomic, assign, readwrite) BOOL refreshing;

@end

#pragma mark -

@implementation ComicListViewController

@synthesize tableView;
@synthesize fetcher;
@synthesize imageFetcher;
@synthesize fetchedResultsController;
@synthesize searchFetchedResultsController;
@synthesize searchController;
@synthesize savedSearchTerm;
@synthesize searchWasActive;
@synthesize requestedLaunchComic;
@synthesize modalSpinner;
@synthesize refreshHeaderView;
@synthesize shouldCheckForRefreshGesture;
@synthesize refreshing;

+ (void)initialize {
  if([self class] == [ComicListViewController class]) {
    if(!downloadImage) {
      downloadImage = [UIImage imageNamed:@"glyphish_download.png"];
      [downloadImage retain];
    }
  }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
    self.title = NSLocalizedString(@"xkcd", @"Title of main view");
  }
  return self;
}

- (void)loadView {
  [super loadView];
  
  self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  
  UIBarButtonItem *systemItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                               target:self
                                                                               action:@selector(systemAction:)
                                  ] autorelease];
  self.navigationItem.leftBarButtonItem = systemItem;

  self.navigationItem.rightBarButtonItem = self.editButtonItem;
  self.navigationItem.rightBarButtonItem.target = self;
  self.navigationItem.rightBarButtonItem.action = @selector(edit:);

#if GENERATE_DEFAULT_PNG
  self.navigationItem.leftBarButtonItem.enabled = NO;
  self.navigationItem.rightBarButtonItem.enabled = NO;
#endif
  
  self.tableView = [[[UITableView alloc] initWithFrame:CGRectZeroWithSize(self.view.bounds.size)] autorelease];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.tableView.backgroundColor = kTableViewBackgroundColor;
  
  [self.view addSubview:self.tableView];
  
  [self setSearchBarTableHeader];

	self.refreshHeaderView = [[[LorenRefreshView alloc] initWithFrame:CGRectMake(0.0f, -self.view.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height)] autorelease];
	[self.tableView addSubview:refreshHeaderView];
}

- (void)setSearchBarTableHeader {
  UISearchBar *searchBar = [[[UISearchBar alloc] initWithFrame:CGRectZero] autorelease];
  [searchBar sizeToFit];
  searchBar.placeholder = NSLocalizedString(@"Search xkcd", @"Search bar placeholder text");
  searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
  searchBar.delegate = self;
  self.tableView.tableHeaderView = searchBar;  
}


- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setFetchedResultsController];
  
  if(self.savedSearchTerm) {
    [self setSearchFetchedResultsControllerWithSearchString:self.savedSearchTerm];
    [self.searchDisplayController setActive:self.searchWasActive];
    [self.searchDisplayController.searchBar setText:self.savedSearchTerm];    
    self.savedSearchTerm = nil;
  }
  
  [self reloadAllData];
  @try {
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
  }
  @catch (NSException *e) {
    [FlurryAPI logError:@"Scroll error" message:nil exception:e];
  }
  
  // Set up new comic fetcher
  if(!self.fetcher) {
    self.fetcher = [[[NewComicFetcher alloc] init] autorelease];
    self.fetcher.delegate = self;      
  }
  
  [self checkForNewComics];

  // Set up image fetcher, for the future
  if(!self.imageFetcher) {
    self.imageFetcher = [[[SingleComicImageFetcher alloc] init] autorelease];
    self.imageFetcher.delegate = self;    
  }
  
  if(self.requestedLaunchComic) {
    NSInteger lastKnownComicNumber = [[Comic lastKnownComic].number integerValue];
    if(lastKnownComicNumber >= self.requestedLaunchComic) {
      @try {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(lastKnownComicNumber - self.requestedLaunchComic)
                                                                  inSection:0]
         atScrollPosition:UITableViewScrollPositionTop
         animated:NO];
      }
      @catch (NSException *e) {
        NSLog(@"scroll fail %@", e);
        [FlurryAPI logError:@"Launch comic scroll error" message:nil exception:e];
      }
      
      Comic *launchComic = [Comic comicNumbered:self.requestedLaunchComic];
      if([launchComic hasBeenDownloaded]) {
        [self viewComic:launchComic];
        self.requestedLaunchComic = 0;
      } else {
        [self fetchImageForComic:launchComic];
      }
    }
  }
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationController setToolbarHidden:YES animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
  [self.searchController.searchResultsTableView deselectRowAtIndexPath:[self.searchController.searchResultsTableView indexPathForSelectedRow] animated:NO];
  [self reloadAllData];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
  [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
  [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
  return [AppDelegate rotate] ? (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown)
                              : (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidUnload {
  self.searchWasActive = [self.searchDisplayController isActive];
  self.savedSearchTerm = self.searchDisplayController.searchBar.text;
  self.refreshHeaderView = nil;
  self.tableView = nil;
}

- (void)dealloc {
  fetcher.delegate = nil;
  [fetcher release];
  fetcher = nil;
  
  imageFetcher.delegate = nil;
  [imageFetcher release];
  imageFetcher = nil;
  
  searchController.searchBar.delegate = nil;
  searchController.delegate = nil;
  searchController.searchResultsDataSource = nil;
  searchController.searchResultsDelegate = nil;
  [searchController release];
  searchController = nil;
  
  tableView.delegate = nil;
  tableView.dataSource = nil;
  [tableView release];
  tableView = nil;
  
  [fetchedResultsController release];
  fetchedResultsController = nil;
  
  [searchFetchedResultsController release];
  searchFetchedResultsController = nil;
  
  [savedSearchTerm release];
  savedSearchTerm = nil;
  
  [refreshHeaderView release], refreshHeaderView = nil;
  
  [super dealloc];
}

- (NSFetchedResultsController *)fetchedResultsControllerWithSearchString:(NSString *)searchString cacheName:(NSString *)cacheName {
  // Set up table data fetcher
  NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
  [fetchRequest setEntity:[Comic entityDescription]];
  if(searchString) {
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@ OR titleText CONTAINS[cd] %@ OR number = %@", searchString, searchString, [NSNumber numberWithInteger:[searchString integerValue]]];
    fetchRequest.predicate = searchPredicate;
  }
  NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"number" ascending:NO] autorelease];
  NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
  [fetchRequest setSortDescriptors:sortDescriptors];
  
  NSFetchedResultsController *aFetchedResultsController = [[[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:AppDelegate.managedObjectContext
                                                                                                 sectionNameKeyPath:nil
                                                                                                          cacheName:cacheName]
                                                           autorelease];
  aFetchedResultsController.delegate = self;
  return aFetchedResultsController;
}

- (void)setFetchedResultsController {
  
  self.fetchedResultsController = [self fetchedResultsControllerWithSearchString:nil cacheName:@"comicsCache"];
  
  NSError *fetchError = nil;
  BOOL success = [self.fetchedResultsController performFetch:&fetchError];
  if(!success) {
    [FlurryAPI logError:@"List fetch failed"
                message:[NSString stringWithFormat:@"Error %@: %@", fetchError, fetchError.userInfo]
              exception:nil];
  }  
}

- (void)setSearchFetchedResultsControllerWithSearchString:(NSString *)searchString {
  self.searchFetchedResultsController = [self fetchedResultsControllerWithSearchString:searchString cacheName:@"searchComicsCache"];
  
  NSError *fetchError = nil;
  BOOL success = [self.searchFetchedResultsController performFetch:&fetchError];
  if(!success) {
    [FlurryAPI logError:@"Search list fetch failed"
                message:[NSString stringWithFormat:@"Error %@: %@", fetchError, fetchError.userInfo]
              exception:nil];
  }  
}

- (void)viewComic:(Comic *)comic {
  SingleComicViewController *singleComicViewController = [[[SingleComicViewController alloc] initWithComic:comic] autorelease];
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

  if(isLaunchComic) {
    self.requestedLaunchComic = 0;      
  }  

  [self.imageFetcher fetchImageForComic:comic context:[NSNumber numberWithBool:(openAfterDownloadPreferenceSet || isLaunchComic)]];
}

- (void)reloadAllData {
  if([self.searchController isActive]) {
    [self.searchController.searchResultsTableView reloadData];    
  } else {
    [self.tableView reloadData];
  }
}

- (void)systemAction:(UIBarButtonItem *)sender {
  TLActionSheetController *sheet = [[[TLActionSheetController alloc] initWithTitle:nil] autorelease];
  if([MFMailComposeViewController canSendMail]) {
    [sheet addButtonWithTitle:NSLocalizedString(@"Email the app developer", @"Action sheet title")
                       target:self
                       action:@selector(emailDeveloper)];
  }
  [sheet addButtonWithTitle:NSLocalizedString(@"Write App Store review", @"Action sheet title")
                     target:self
                     action:@selector(goToAppStore)];
  [sheet addCancelButton];
  [sheet showInView:self.view];
}

- (void)edit:(UIBarButtonItem *)sender {
  [self setEditing:YES animated:YES];
  [self.tableView setEditing:YES animated:YES];
  [self.tableView setContentOffset:
   CGPointByAddingYOffset(self.tableView.contentOffset, -self.tableView.tableHeaderView.bounds.size.height)];
  self.tableView.tableHeaderView = nil;
  self.navigationItem.rightBarButtonItem.action = @selector(doneEditing:);
  [self.navigationController setToolbarHidden:NO animated:YES];
  UIBarButtonItem *downloadAll = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Download all", @"Button")
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(downloadAll:)]
                                  autorelease];
  UIBarButtonItem *deleteAll = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Delete all", @"Button")
                                                                 style:UIBarButtonItemStyleBordered
                                                                target:self
                                                                action:@selector(deleteAll:)]
                                  autorelease];
  NSArray *toolbarItems = [NSArray arrayWithObjects:
                           deleteAll,
                           [UIBarButtonItem flexibleSpaceBarButtonItem],
                           downloadAll,
                           nil];
  [self setToolbarItems:toolbarItems animated:YES];
  self.navigationItem.leftBarButtonItem.enabled = NO;
}

- (void)doneEditing:(UIBarButtonItem *)sender {
  [self setEditing:NO animated:YES];
  [self.tableView setEditing:NO animated:YES];
  [self setSearchBarTableHeader];
  [self.tableView setContentOffset:
   CGPointByAddingYOffset(self.tableView.contentOffset, self.tableView.tableHeaderView.bounds.size.height)];
  self.navigationItem.rightBarButtonItem.action = @selector(edit:);
  [self.navigationController setToolbarHidden:YES animated:YES];
  
  self.navigationItem.leftBarButtonItem.enabled = YES;
}

- (void)downloadAll:(UIBarButtonItem *)sender {
  NSString *sheetTitle = NSLocalizedString(@"Downloading all images may take up considerable space on your device.", @"Download all warning");
  TLActionSheetController *sheet = [[[TLActionSheetController alloc] initWithTitle:sheetTitle] autorelease];
  [sheet addButtonWithTitle:NSLocalizedString(@"Download all images", @"Confirm download all button")
                     target:self
                     action:@selector(downloadAllComicImages)];
  [sheet addCancelButton];
  [sheet showFromToolbar:self.navigationController.toolbar];
}
   
- (void)deleteAll:(UIBarButtonItem *)sender {
  TLActionSheetController *sheet = [[[TLActionSheetController alloc] initWithTitle:nil] autorelease];
  [sheet addDestructiveButtonWithTitle:NSLocalizedString(@"Delete all images", @"Confirm delete all button")
                     target:self
                     action:@selector(deleteAllComicImages)];
  [sheet addCancelButton];
  [sheet showFromToolbar:self.navigationController.toolbar];
}

#pragma mark -
#pragma mark NewComicFetcherDelegate methods

- (void)newComicFetcher:(NewComicFetcher *)fetcher didFetchComic:(Comic *)comic {
  [AppDelegate save]; // write new comic to disk so that CoreData can clear its memory as needed
  if([AppDelegate downloadNewComics]) {
    [self fetchImageForComic:comic];
  }
}

- (void)newComicFetcherDidFinishFetchingAllComics:(NewComicFetcher *)fetcher {
  [self didFinishRefreshing];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)newComicFetcher:(NewComicFetcher *)comicFetcher didFailWithError:(NSError *)error {
  if([error.domain isEqualToString:kXkcdErrorDomain]) {
    [FlurryAPI logError:@"Internal error"
                message:[NSString stringWithFormat:@"Error: %@", error]
              exception:nil];
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
  if([context boolValue] && (self.navigationController.topViewController == self)) { // context boolvalue == open after download
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

- (Comic *)comicAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)aTableView {
  Comic *comic = [[self fetchedResultsControllerForTableView:aTableView] objectAtIndexPath:indexPath];
  return comic;
}

- (NSFetchedResultsController *)fetchedResultsControllerForTableView:(UITableView *)aTableView {
  NSFetchedResultsController *fetchedResults = (self.tableView == aTableView) ? self.fetchedResultsController : self.searchFetchedResultsController;
  return fetchedResults;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = nil;

  // Comic cell
  static NSString *comicCellIdentifier = @"comicCell";
  UITableViewCell *comicCell = [self.tableView dequeueReusableCellWithIdentifier:comicCellIdentifier];
  if(!comicCell) {
    comicCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:comicCellIdentifier] autorelease];
  }
  
#if GENERATE_DEFAULT_PNG
  return comicCell;
#endif
  
  Comic *comic = [self comicAtIndexPath:indexPath inTableView:aTableView];
  comicCell.textLabel.text = [NSString stringWithFormat:@"%i. %@", [comic.number integerValue], comic.name];
  comicCell.textLabel.font = [UIFont systemFontOfSize:16];
  comicCell.textLabel.adjustsFontSizeToFitWidth = YES;
  
  if([comic.number integerValue] == 404) {
    // Handle comic 404 specially...sigh
    comicCell.accessoryView = nil;
    comicCell.accessoryType = UITableViewCellAccessoryNone;
  } else {
    if([comic hasBeenDownloaded]) {
      comicCell.accessoryView = nil;
      comicCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if([comic.loading boolValue] || [self.imageFetcher downloadingAll]) {
      comicCell.accessoryView = [UIActivityIndicatorView animatingActivityIndicatorViewWithStyle:UIActivityIndicatorViewStyleGray];
    } else {
      UIImageView *downloadImageView = [UIImageView imageViewWithImage:downloadImage];
      downloadImageView.opaque = YES;
      comicCell.accessoryView = downloadImageView;
    }
  }

  comicCell.editingAccessoryView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  
  cell = comicCell;
  return cell;
}

- (void)tableView:(UITableView *)aTableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  cell.backgroundColor = [UIColor whiteColor];
  cell.accessoryView.backgroundColor = [UIColor whiteColor];
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  Comic *selectedComic = [self comicAtIndexPath:indexPath inTableView:aTableView];
  if([selectedComic.number integerValue] != 404) {
    if([selectedComic hasBeenDownloaded]) {
      [self viewComic:selectedComic];
    } else if(!([selectedComic.loading boolValue] || [self.imageFetcher downloadingAll])) {
      [self fetchImageForComic:selectedComic];
      [aTableView deselectRowAtIndexPath:indexPath animated:NO];
    }    
  } else {
    [aTableView deselectRowAtIndexPath:indexPath animated:NO];
  }
  
}

- (NSString *)tableView:(UITableView *)aTableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
  return NSLocalizedString(@"Delete image", @"Delete button title");
}

- (BOOL)tableView:(UITableView *)aTableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  if(![aTableView isEqual:self.tableView]) {
    return NO;
  }
  return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  if(![aTableView isEqual:self.tableView]) {
    return UITableViewCellEditingStyleNone;
  }
  Comic *comic = [self comicAtIndexPath:indexPath inTableView:aTableView];
  return [comic hasBeenDownloaded] ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;  
}

- (BOOL)tableView:(UITableView *)aTableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
  if(![aTableView isEqual:self.tableView]) {
    return NO;
  }
  Comic *comic = [self comicAtIndexPath:indexPath inTableView:aTableView];
  return [comic hasBeenDownloaded];  
}

- (void)tableView:(UITableView *)aTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if(editingStyle == UITableViewCellEditingStyleDelete) {
    Comic *comic = [self comicAtIndexPath:indexPath inTableView:aTableView];
    [comic deleteImage];
    [self.tableView reloadRowAtIndexPath:indexPath withRowAnimation:UITableViewRowAnimationFade];
  }
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
  NSFetchedResultsController *fetchedResults = [self fetchedResultsControllerForTableView:aTableView];
  NSArray *sections = [fetchedResults sections];
  NSUInteger numberOfRows = 0;
  if([sections count] > 0) {
    id<NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
    numberOfRows = [sectionInfo numberOfObjects];
  }
  return numberOfRows;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
  NSFetchedResultsController *fetchedResults = [self fetchedResultsControllerForTableView:aTableView];
  NSUInteger numberOfSections = [[fetchedResults sections] count];
  if(numberOfSections == 0) {
    numberOfSections = 1;
  }
  return numberOfSections;
}

#pragma mark -
#pragma mark UISearchBarDelegate methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
  if(!self.searchController) {
    self.searchController = [[[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self] autorelease];
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
  self.searchWasActive = NO;
  self.savedSearchTerm = nil;
  [self reloadAllData];
}

#pragma mark -
#pragma mark TLActionSheetController supporting methods

- (void)emailDeveloper {
  [FlurryAPI logEvent:@"emailDeveloper"];

  MFMailComposeViewController *emailViewController = [[MFMailComposeViewController alloc] initWithNibName:nil bundle:nil];
  emailViewController.mailComposeDelegate = self;
  [emailViewController setSubject:NSLocalizedString(@"Feedback on xkcd app", @"Subject of feedback email")];
  
  [emailViewController setToRecipients:[NSArray arrayWithObject:@"xkcdapp@treelinelabs.com"]];
  [self presentModalViewController:emailViewController animated:YES];

  if([TLSavedState firstTimeForEvent:@"emailDeveloper"]) {
    [UIAlertView showAlertWithTitle:NSLocalizedString(@"Just so you know", @"Alert title")
                            message:NSLocalizedString(@"This email goes to the person who wrote the iPhone app, not the person who writes the actual comics.", @"Alert body")];
  }
}

- (void)goToAppStore {
  [FlurryAPI logEvent:@"goToAppStore"];

  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=303688284&pageNumber=0&sortOrdering=1&type=Purple+Software&mt=8"]];  
}

- (void)downloadAllComicImages {
  [self.imageFetcher fetchImagesForAllComics];
  [self doneEditing:nil];
  [self reloadAllData]; // so that all the spinners start up
}

- (void)deleteAllComicImages {
  [self doneEditing:nil];
  NSArray *comicsWithImages = [Comic comicsWithImages];
  self.modalSpinner = [[[TLModalActivityIndicatorView alloc] initWithText:NSLocalizedString(@"Deleting...", @"Modal spinner text")] autorelease];
  [self.modalSpinner show];
  [self performSelectorInBackground:@selector(deleteAllComicImagesBlocking:) withObject:comicsWithImages];
}

- (void)deleteAllComicImagesBlocking:(NSArray *)comicsWithImages {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  for(Comic *comic in comicsWithImages) {
    [comic performSelectorOnMainThread:@selector(deleteImage)
                            withObject:nil
                         waitUntilDone:YES]; // wait until done to avoid flooding
  }
  [self performSelectorOnMainThread:@selector(didFinishDeletingImages)
                         withObject:nil
                      waitUntilDone:NO];
  [pool drain];
}

- (void)didFinishDeletingImages {
  [self.modalSpinner dismiss];
  self.modalSpinner = nil;
}
   
#pragma mark -
#pragma mark MFMailComposeViewControllerDelegate methods

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
  switch(result) {
    case MFMailComposeResultFailed:
      [FlurryAPI logEvent:@"devEmailFailed"];
      break;
    case MFMailComposeResultCancelled:
      [FlurryAPI logEvent:@"devEmailCancelled"];
      break;
    case MFMailComposeResultSaved:
      [FlurryAPI logEvent:@"devEmailSaved"];
      break;
    case MFMailComposeResultSent:
      [FlurryAPI logEvent:@"devEmailSent"];
      break;
    default:
      break;
  }
  
  [controller dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
  [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type {
  
  switch(type) {
    case NSFetchedResultsChangeInsert:;
      [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                    withRowAnimation:UITableViewRowAnimationFade];
      break;
    case NSFetchedResultsChangeDelete:;
      [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                    withRowAnimation:UITableViewRowAnimationFade];
      break;
  }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
  
  switch(type) {
    case NSFetchedResultsChangeInsert:;
      [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                            withRowAnimation:UITableViewRowAnimationFade];
      break;
      
    case NSFetchedResultsChangeDelete:;
      [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                            withRowAnimation:UITableViewRowAnimationFade];
      break;
      
    case NSFetchedResultsChangeUpdate:;
      [self.tableView reloadRowAtIndexPath:indexPath withRowAnimation:UITableViewRowAnimationFade];
      break;
      
    case NSFetchedResultsChangeMove:;
      [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                            withRowAnimation:UITableViewRowAnimationFade];
      [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:newIndexPath.section]
                    withRowAnimation:UITableViewRowAnimationFade];
      break;
  }
  
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
  [self.tableView endUpdates];
}

#pragma mark -
#pragma mark Pull to refresh / UIScrollViewDelegate methods

- (void)showRefreshAnimation {
  [self didStartRefreshing];

  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:kRefreshContentOffsetAnimationDuration];
  self.tableView.contentInset = UIEdgeInsetsMake(kDuringRefreshContentOffset, 0.0f, 0.0f, 0.0f);
  [UIView commitAnimations];
}

- (void)didStartRefreshing {
  self.refreshing = YES;
	[self.refreshHeaderView setSpinnerAnimating:YES];
  [self.refreshHeaderView setState:RefreshViewStateLoading];
}

- (void)didFinishRefreshing {
	self.refreshing = NO;
	[self.refreshHeaderView flipArrowAnimated:NO];

	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:kReturnToNormalContentOffsetAnimationDuration];
	[self.tableView setContentInset:UIEdgeInsetsZero];
	[self.refreshHeaderView setState:RefreshViewStatePullToReload];
	[self.refreshHeaderView setSpinnerAnimating:NO];
	[UIView commitAnimations];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	if(!self.refreshing) {
		self.shouldCheckForRefreshGesture = YES;
	}
} 

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {	
	if(self.refreshing) {
    return;
  }
    
	if(self.shouldCheckForRefreshGesture) {
		if(self.refreshHeaderView.flipped && aScrollView.contentOffset.y > -kRefreshTriggerOffset && aScrollView.contentOffset.y < 0.0f ) {
			[self.refreshHeaderView flipArrowAnimated:YES];
			[self.refreshHeaderView setState:RefreshViewStatePullToReload];
		} else if(!self.refreshHeaderView.flipped && aScrollView.contentOffset.y < -kRefreshTriggerOffset) {
			[self.refreshHeaderView flipArrowAnimated:YES];
			[self.refreshHeaderView setState:RefreshViewStateReleaseToReload];
		}
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)aScrollView willDecelerate:(BOOL)decelerate {
	if(self.refreshing) {
    return;
  }
    
	if(aScrollView.contentOffset.y <= -kRefreshTriggerOffset) {
    [self showRefreshAnimation];
    [self checkForNewComics];
	}

	self.shouldCheckForRefreshGesture = NO;
}

@end
