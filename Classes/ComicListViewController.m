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
#import "SearchBarTableViewCell.h"
#import "SingleComicViewController.h"
#import "SingleComicImageFetcher.h"
#import "CGGeometry_TLCommon.h"

#pragma mark -

#define kStatusBarHeight 30.0f

#pragma mark -

static UIImage *downloadImage = nil;

#pragma mark -

@interface ComicListViewController ()

- (void)setFetchedResultsControllerWithSearchString:(NSString *)searchString;
- (Comic *)comicAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)aTableView;
- (void)viewComic:(Comic *)comic;
- (void)reloadAllData;
- (void)fetchImageForComic:(Comic *)comic;
- (void)systemAction:(UIBarButtonItem *)sender;
- (void)checkForNewComics;
- (void)emailDeveloper;
- (void)goToAppStore;  

@property(nonatomic, retain, readwrite) UITableView *tableView;
@property(nonatomic, retain, readwrite) NewComicFetcher *fetcher;
@property(nonatomic, retain, readwrite) SingleComicImageFetcher *imageFetcher;
@property(nonatomic, retain, readwrite) NSFetchedResultsController *fetchedResultsController;
@property(nonatomic, retain, readwrite) StatusBarController *statusBarController;
@property(nonatomic, retain, readwrite) NSTimer *statusBarAnimationTimer;
@property(nonatomic, retain, readwrite) UISearchDisplayController *searchController;
@property(nonatomic, retain, readwrite) NSString *savedSearchTerm;
@property(nonatomic, assign, readwrite) BOOL searchWasActive;

@end

#pragma mark -

@implementation ComicListViewController

@synthesize tableView;
@synthesize fetcher;
@synthesize imageFetcher;
@synthesize fetchedResultsController;
@synthesize statusBarController;
@synthesize statusBarAnimationTimer;
@synthesize searchController;
@synthesize savedSearchTerm;
@synthesize searchWasActive;
@synthesize requestedLaunchComic;

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
  
  UIBarButtonItem *systemItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                               target:self
                                                                               action:@selector(systemAction:)
                                  ] autorelease];
  self.navigationItem.leftBarButtonItem = systemItem;
//  self.navigationItem.leftBarButtonItem.enabled = NO; // for making Default.png
  
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
}


- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setFetchedResultsControllerWithSearchString:self.savedSearchTerm]; // normally nil
  
  if(self.savedSearchTerm)
	{
    [self.searchDisplayController setActive:self.searchWasActive];
    [self.searchDisplayController.searchBar setText:self.savedSearchTerm];    
    self.savedSearchTerm = nil;
  }
  
  [self reloadAllData];
  @try {
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
  }
  @catch (NSException *e) {
    [FlurryAPI logError:@"Scroll error" message:nil exception:e];
  }
  
  // Set up new comic fetcher
  self.fetcher = [[[NewComicFetcher alloc] init] autorelease];
  self.fetcher.delegate = self;  
  
  [self checkForNewComics];

  // Set up image fetcher, for the future
  self.imageFetcher = [[[SingleComicImageFetcher alloc] init] autorelease];
  self.imageFetcher.delegate = self;
  
  if(self.requestedLaunchComic) {
    NSInteger lastKnownComicNumber = [[Comic lastKnownComic].number integerValue];
    if(lastKnownComicNumber >= self.requestedLaunchComic) {
      @try {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(lastKnownComicNumber - self.requestedLaunchComic + 1) // 1 for search bar
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
  self.statusBarController.statusBar.hidden = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
  self.statusBarController.statusBar.hidden = NO;
  CGRect statusBarFrame = CGRectMake(0.0f,
                                     self.view.bounds.size.height - kStatusBarHeight,
                                     self.view.bounds.size.width,
                                     kStatusBarHeight);
  [self.statusBarController setStatusBarFrame:statusBarFrame];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
  return [AppDelegate rotate] ? YES : (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidUnload {
  self.searchWasActive = [self.searchDisplayController isActive];
  self.savedSearchTerm = [self.searchDisplayController.searchBar text];
  self.tableView = nil;
  self.statusBarController = nil;
  self.fetchedResultsController = nil;
  self.fetcher = nil;
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
  
  [savedSearchTerm release];
  savedSearchTerm = nil;
  
  [statusBarAnimationTimer invalidate];
  [statusBarAnimationTimer release];
  statusBarAnimationTimer = nil;
  
  [statusBarController release];
  statusBarController = nil;
  
  [super dealloc];
}

- (void)setFetchedResultsControllerWithSearchString:(NSString *)searchString {
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
                                                                                                          cacheName:@"ComicsCache"]
                                                           autorelease];
  aFetchedResultsController.delegate = self;
  self.fetchedResultsController = aFetchedResultsController;
  
  NSError *fetchError = nil;
  BOOL success = [self.fetchedResultsController performFetch:&fetchError];
  if(!success) {
    [FlurryAPI logError:@"List fetch failed" message:[NSString stringWithFormat:@"Error: %@", fetchError] exception:nil];
  }  
}

- (Comic *)comicAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)aTableView {
  NSInteger adjustedRow = aTableView == self.tableView ? indexPath.row - 1 : indexPath.row; // adjust for search bar if not searching
  NSIndexPath *adjustedIndexPath = [NSIndexPath indexPathForRow:adjustedRow inSection:indexPath.section];
  return [self.fetchedResultsController objectAtIndexPath:adjustedIndexPath];
}

- (void)viewComic:(Comic *)comic {
  SingleComicViewController *singleComicViewController = [[[SingleComicViewController alloc] initWithComic:comic] autorelease];
  [self.navigationController pushViewController:singleComicViewController animated:YES];
}

- (void)checkForNewComics {
  self.statusBarController.messageLabel.text = NSLocalizedString(@"Updating...", @"Status bar message when fetching new comics");
  [self.statusBarController startSpinner];
  [self.statusBarController showAnimated];
  [self.fetcher fetch];  
}

- (void)fetchImageForComic:(Comic *)comic {
  [self.imageFetcher fetchImageForComic:comic];
  [self reloadAllData];
}

- (void)reloadAllData {
  if([self.searchController isActive]) {
    [self.searchController.searchResultsTableView reloadData];    
  } else {
    [self.tableView reloadData];
  }
}

- (void)systemAction:(UIBarButtonItem *)sender {
  UIActionSheet *systemActionSheet = [[[UIActionSheet alloc] initWithTitle:nil
                                                                  delegate:self
                                                         cancelButtonTitle:nil
                                                    destructiveButtonTitle:nil
                                                         otherButtonTitles:nil]
                                      autorelease];
  
  [systemActionSheet addButtonWithTitle:NSLocalizedString(@"Check for new comics", @"Action sheet item to check for new comics")];
  if([MFMailComposeViewController canSendMail]) {
    [systemActionSheet addButtonWithTitle:NSLocalizedString(@"Email the developer", @"Action sheet item to email developer")];    
  }
  [systemActionSheet addButtonWithTitle:NSLocalizedString(@"Leave App Store review", @"Action sheet item to leave review")];
  [systemActionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"Action sheet title to cancel action")];
  systemActionSheet.cancelButtonIndex = systemActionSheet.numberOfButtons - 1;
  [systemActionSheet showInView:self.view];
}

#pragma mark -
#pragma mark NewComicFetcherDelegate methods

- (void)newComicFetcher:(NewComicFetcher *)fetcher didFetchComic:(Comic *)comic {
  [self reloadAllData];
  [AppDelegate save]; // write new comic to disk so that CoreData can clear its memory as needed
  if([AppDelegate downloadNewComics]) {
    [self fetchImageForComic:comic];
  }
}

- (void)newComicFetcherDidFinishFetchingAllComics:(NewComicFetcher *)fetcher {
  [self.statusBarController stopSpinner];
  self.statusBarController.messageLabel.text = NSLocalizedString(@"Updated", @"Status bar message indicated all new comics have been downloaded");
  [self.statusBarAnimationTimer invalidate];
  self.statusBarAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:2.5f
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

- (void)singleComicImageFetcher:(SingleComicImageFetcher *)fetcher didFetchImageForComic:(Comic *)comic {
  [self reloadAllData];
  BOOL isLaunchComic = (self.requestedLaunchComic && ([comic.number integerValue] == self.requestedLaunchComic));
  BOOL openAfterDownload = [AppDelegate openAfterDownload];
  BOOL isTopViewController = self.navigationController.topViewController == self;
  
  if(isTopViewController && isLaunchComic) {
    [self viewComic:comic];
    self.requestedLaunchComic = 0;
  } else if(isTopViewController && openAfterDownload) {
    [self viewComic:comic];
  }
}

- (void)singleComicImageFetcher:(SingleComicImageFetcher *)fetcher didFailWithError:(NSError *)error onComic:(Comic *)comic {
  [self reloadAllData];
  
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
#pragma mark UITableViewDelegate and UITableViewDataSource methods

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//  return [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"blank"] autorelease]; // for making Default.png
  UITableViewCell *cell = nil;
  BOOL isSearchBar = (aTableView == self.tableView) && (indexPath.row == 0);
  if(isSearchBar) {
    // Search bar cell
    static NSString *searchCellIdentifier = @"searchBarCell";
    SearchBarTableViewCell *searchCell = (SearchBarTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:searchCellIdentifier];
    if(!searchCell) {
      searchCell = [[[SearchBarTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:searchCellIdentifier] autorelease];
    }
    searchCell.searchBar.placeholder = NSLocalizedString(@"Search xkcd", @"Search bar placeholder text");
    searchCell.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchCell.searchBar.delegate = self;
    cell = searchCell;
  } else {
    // Comic cell
    static NSString *comicCellIdentifier = @"comicCell";
    UITableViewCell *comicCell = [self.tableView dequeueReusableCellWithIdentifier:comicCellIdentifier];
    if(!comicCell) {
      comicCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:comicCellIdentifier] autorelease];
    }
    Comic *comic = [self comicAtIndexPath:indexPath inTableView:aTableView];
    comicCell.textLabel.text = [NSString stringWithFormat:@"%i. %@", [comic.number integerValue], comic.name];
    comicCell.textLabel.font = [UIFont systemFontOfSize:16];
    
    if([comic.number integerValue] == 404) {
      // Handle comic 404 specially...sigh
      comicCell.accessoryView = nil;
      comicCell.accessoryType = UITableViewCellAccessoryNone;
    } else {
      if([comic hasBeenDownloaded]) {
        comicCell.accessoryView = nil;
        comicCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      } else if([comic.loading boolValue]) {
        UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc] initWithFrame:CGRectZero] autorelease];
        [spinner sizeToFit];
        spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        [spinner startAnimating];
        comicCell.accessoryView = spinner;
      } else {
        UIImageView *downloadImageView = [[[UIImageView alloc] initWithImage:downloadImage] autorelease];
        downloadImageView.opaque = YES;
        comicCell.accessoryView = downloadImageView;
      }
    }
    
    cell = comicCell;
  }
  return cell;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  Comic *selectedComic = [self comicAtIndexPath:indexPath inTableView:aTableView];
  if([selectedComic.number integerValue] != 404) {
    if([selectedComic hasBeenDownloaded]) {
      [self viewComic:selectedComic];
    } else if(![selectedComic.loading boolValue]) {
      [self fetchImageForComic:selectedComic];
      [aTableView deselectRowAtIndexPath:indexPath animated:NO];
    }    
  } else {
    [aTableView deselectRowAtIndexPath:indexPath animated:NO];
  }
  
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
  NSArray *sections = [self.fetchedResultsController sections];
  NSUInteger numberOfRows = 0;
  if([sections count] > 0) {
    id<NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
    numberOfRows = [sectionInfo numberOfObjects];
  }
  if(aTableView == self.tableView) {
    numberOfRows++; // top row is search bar! if tableView != self.tableView, we're actively searching...
  }
  return numberOfRows;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  NSUInteger numberOfSections = [[self.fetchedResultsController sections] count];
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
  [self setFetchedResultsControllerWithSearchString:searchString];
  [self.searchDisplayController.searchResultsTableView reloadData];
  return YES;
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
  [self setFetchedResultsControllerWithSearchString:nil];
  [self.searchDisplayController.searchResultsTableView reloadData];
  [self.searchDisplayController.searchBar resignFirstResponder];
  self.searchWasActive = NO;
  self.savedSearchTerm = nil;
  [self reloadAllData];
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods and supporting actions

- (void)emailDeveloper {
  MFMailComposeViewController *emailViewController = [[MFMailComposeViewController alloc] initWithNibName:nil bundle:nil];
  emailViewController.mailComposeDelegate = self;
  [emailViewController setSubject:NSLocalizedString(@"Feedback on xkcd app", @"Subject of feedback email")];
  
  [emailViewController setToRecipients:[NSArray arrayWithObject:@"xkcdapp@treelinelabs.com"]];
  [self presentModalViewController:emailViewController animated:YES];
}

- (void)goToAppStore {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=303688284&mt=8"]];  
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  if(![MFMailComposeViewController canSendMail]) {
    if(buttonIndex > 0) {
      buttonIndex++;
    }
  }
  switch(buttonIndex) {
    case 0:;
      [FlurryAPI logEvent:@"checkForNewComics"];
      [self checkForNewComics];
      break;
    case 1:
      [FlurryAPI logEvent:@"emailDeveloper"];
      [self emailDeveloper];
      break;
    case 2:
      [FlurryAPI logEvent:@"goToAppStore"];
      [self goToAppStore];
      break;
    default:
      break;
  }
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


@end
