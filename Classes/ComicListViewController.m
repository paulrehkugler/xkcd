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
#import "StatusBarController.h"
#import "SingleComicViewController.h"
#import "SingleComicImageFetcher.h"
#import "CGGeometry_TLCommon.h"

#pragma mark -

#define kStatusBarHeight 30.0f

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

@property(nonatomic, retain, readwrite) UITableView *tableView;
@property(nonatomic, retain, readwrite) NewComicFetcher *fetcher;
@property(nonatomic, retain, readwrite) SingleComicImageFetcher *imageFetcher;
@property(nonatomic, retain, readwrite) NSFetchedResultsController *fetchedResultsController;
@property(nonatomic, retain, readwrite) NSFetchedResultsController *searchFetchedResultsController;
@property(nonatomic, retain, readwrite) StatusBarController *statusBarController;
@property(nonatomic, retain, readwrite) NSTimer *statusBarAnimationTimer;
@property(nonatomic, retain, readwrite) UISearchDisplayController *searchController;
@property(nonatomic, retain, readwrite) NSString *savedSearchTerm;
@property(nonatomic, assign, readwrite) BOOL searchWasActive;
@property(nonatomic, retain, readwrite) TLModalActivityIndicatorView *modalSpinner;

@end

#pragma mark -

@implementation ComicListViewController

@synthesize tableView;
@synthesize fetcher;
@synthesize imageFetcher;
@synthesize fetchedResultsController;
@synthesize searchFetchedResultsController;
@synthesize statusBarController;
@synthesize statusBarAnimationTimer;
@synthesize searchController;
@synthesize savedSearchTerm;
@synthesize searchWasActive;
@synthesize requestedLaunchComic;
@synthesize modalSpinner;

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

  UIBarButtonItem *editItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                             target:self
                                                                             action:@selector(edit:)
                                ] autorelease];
  self.navigationItem.rightBarButtonItem = editItem;

#if GENERATE_DEFAULT_PNG
  self.navigationItem.leftBarButtonItem.enabled = NO;
  self.navigationItem.rightBarButtonItem.enabled = NO;
#endif
  
  self.tableView = [[[UITableView alloc] initWithFrame:CGRectZeroWithSize(self.view.bounds.size)] autorelease];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  
  [self.view addSubview:self.tableView];
  
  CGFloat navigationBarHeight = self.navigationController.navigationBar.bounds.size.height;
  CGRect statusBarFrame = CGRectMake(0.0f,
                                     self.view.bounds.size.height - navigationBarHeight - kStatusBarHeight,
                                     self.view.bounds.size.width,
                                     kStatusBarHeight);
  self.statusBarController = [[[StatusBarController alloc] initWithStatusBarFrame:statusBarFrame] autorelease];
  [self.statusBarController hide];
  [self.view addSubview:self.statusBarController.statusBar];

  [self setSearchBarTableHeader];
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

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
  [self.searchController.searchResultsTableView deselectRowAtIndexPath:[self.searchController.searchResultsTableView indexPathForSelectedRow] animated:NO];
  [self reloadAllData];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
  [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  self.statusBarController.statusBar.hidden = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
  [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
  self.statusBarController.statusBar.hidden = NO;
  CGRect statusBarFrame = CGRectMake(0.0f,
                                     self.view.bounds.size.height - kStatusBarHeight,
                                     self.view.bounds.size.width,
                                     kStatusBarHeight);
  [self.statusBarController setStatusBarFrame:statusBarFrame];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
  return [AppDelegate rotate] ? (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown)
                              : (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidUnload {
  self.searchWasActive = [self.searchDisplayController isActive];
  self.savedSearchTerm = self.searchDisplayController.searchBar.text;
  self.tableView = nil;
  self.statusBarController = nil;
  [self.statusBarAnimationTimer invalidate];
  self.statusBarAnimationTimer = nil;
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
  
  [statusBarAnimationTimer invalidate];
  [statusBarAnimationTimer release];
  statusBarAnimationTimer = nil;
  
  [statusBarController release];
  statusBarController = nil;
  
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
  if(self.tableView.editing) {
    [self doneEditing:nil];
  }
  self.statusBarController.messageLabel.text = NSLocalizedString(@"Updating...", @"Status bar message when fetching new comics");
  [self.statusBarController startSpinner];
  [self.statusBarController showAnimated];
  [self.fetcher fetch];
}

- (void)fetchImageForComic:(Comic *)comic {
  BOOL openAfterDownloadPreferenceSet = [AppDelegate openAfterDownload];
  BOOL isLaunchComic = (self.requestedLaunchComic && ([comic.number integerValue] == self.requestedLaunchComic));

  if(isLaunchComic) {
    self.requestedLaunchComic = 0;      
  }  

  [self.imageFetcher fetchImageForComic:comic openAfterDownload:(openAfterDownloadPreferenceSet || isLaunchComic)];
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
    [sheet addButtonWithTitle:NSLocalizedString(@"Email the developer", @"Action sheet title")
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
  [self.tableView setEditing:YES animated:YES];
  [self.tableView setContentOffset:
   CGPointByAddingYOffset(self.tableView.contentOffset, -self.tableView.tableHeaderView.bounds.size.height)];
  self.tableView.tableHeaderView = nil;
  UIBarButtonItem *doneItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                             target:self
                                                                             action:@selector(doneEditing:)
                                ] autorelease];
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
  UIBarButtonItem *refresh = [UIBarButtonItem barButtonSystemItem:UIBarButtonSystemItemRefresh
                                                           target:self
                                                           action:@selector(checkForNewComics)];
  NSArray *toolbarItems = [NSArray arrayWithObjects:
                           downloadAll,
                           deleteAll,
                           [UIBarButtonItem flexibleSpaceBarButtonItem],
                           refresh,
                           nil];
  [self setToolbarItems:toolbarItems animated:YES];
  self.navigationItem.leftBarButtonItem.enabled = NO;
  self.navigationItem.rightBarButtonItem = doneItem;
}

- (void)doneEditing:(UIBarButtonItem *)sender {
  [self.tableView setEditing:NO animated:YES];
  [self setSearchBarTableHeader];
  [self.tableView setContentOffset:
   CGPointByAddingYOffset(self.tableView.contentOffset, self.tableView.tableHeaderView.bounds.size.height)];
  UIBarButtonItem *editItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                             target:self
                                                                             action:@selector(edit:)
                                ] autorelease];
  [self.navigationController setToolbarHidden:YES animated:YES];
  
  self.navigationItem.leftBarButtonItem.enabled = YES;
  self.navigationItem.rightBarButtonItem = editItem;  
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
  [self.statusBarController stopSpinner];
  self.statusBarController.messageLabel.text = NSLocalizedString(@"Updated", @"Status bar message indicated all new comics have been downloaded");
  [self.statusBarAnimationTimer invalidate];
  self.statusBarAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:2.0f
                                                                  target:self.statusBarController
                                                                selector:@selector(hideAnimated)
                                                                userInfo:nil repeats:NO];
}

- (void)newComicFetcher:(NewComicFetcher *)comicFetcher didFailWithError:(NSError *)error {
  [self.statusBarController stopSpinner];
  
  if([[error domain] isEqualToString:kXkcdErrorDomain]) {
    // internal error
    [FlurryAPI logError:@"Internal error" message:[NSString stringWithFormat:@"Error: %@", error] exception:nil];
    self.statusBarController.messageLabel.text = NSLocalizedString(@"Update failed.", @"Status bar message indicated new comics downloading failed due to internal error.");
  } else {
    self.statusBarController.messageLabel.text = NSLocalizedString(@"Update failed. No internet connection.", @"Status bar message indicated new comics downloading failed due to lack of internet connection.");
  }
  
  [self.statusBarAnimationTimer invalidate];
  self.statusBarAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:4.0f
                                                                  target:self.statusBarController
                                                                selector:@selector(hideAnimated)
                                                                userInfo:nil repeats:NO];
}

#pragma mark -
#pragma mark SingleComicImageFetcherDelegate methods

- (void)singleComicImageFetcher:(SingleComicImageFetcher *)fetcher
          didFetchImageForComic:(Comic *)comic
              openAfterDownload:(BOOL)openAfterDownload {
  if(openAfterDownload && (self.navigationController.topViewController == self)) {
    [self viewComic:comic];
  }
}

- (void)singleComicImageFetcher:(SingleComicImageFetcher *)fetcher
               didFailWithError:(NSError *)error
                        onComic:(Comic *)comic {
  if([[error domain] isEqualToString:kXkcdErrorDomain]) {
    // internal error
    [FlurryAPI logError:@"Internal error" message:[NSString stringWithFormat:@"Error: %@", error] exception:nil];
    UIAlertView *failAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Whoops", @"Title of image download fail alert")
                                                         message:[NSString stringWithFormat:NSLocalizedString(@"Could not download xkcd %i.", @"Text of unknown error image download fail alert"), [comic.number integerValue]]
                                                        delegate:nil
                                               cancelButtonTitle:nil
                                               otherButtonTitles:NSLocalizedString(@"Ok", @"Button to acknolwedge download fail alert"), nil] autorelease];
    
    [failAlert show];
  } else {
    UIAlertView *failAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Whoops", @"Title of image download fail alert")
                                                         message:[NSString stringWithFormat:NSLocalizedString(@"Could not download xkcd %i -- no internet connection.", @"Text of image download fail alert due to connectivity"), [comic.number integerValue]]
                                                        delegate:nil
                                               cancelButtonTitle:nil
                                               otherButtonTitles:NSLocalizedString(@"Ok", @"Button to acknolwedge download fail alert"), nil] autorelease];
    
    [failAlert show];
  }
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
}

- (void)goToAppStore {
  [FlurryAPI logEvent:@"goToAppStore"];

  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=303688284&mt=8"]];  
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

@end
