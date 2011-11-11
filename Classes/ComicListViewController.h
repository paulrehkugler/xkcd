//
//  ComicListViewController.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 8/25/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NewComicFetcherDelegate.h"
#import "SingleComicImageFetcherDelegate.h"
#import "TLModalActivityIndicatorView.h"

@class NewComicFetcher;
@class SingleComicImageFetcher;
@class LorenRefreshView;

@interface ComicListViewController : UIViewController <
  UITableViewDataSource,
  UITableViewDelegate,
  NewComicFetcherDelegate,
  NSFetchedResultsControllerDelegate,
  UISearchBarDelegate,
  UISearchDisplayDelegate,
  SingleComicImageFetcherDelegate,
  UIActionSheetDelegate,
  MFMailComposeViewControllerDelegate
> {
@private
  UITableView *tableView;
  NSFetchedResultsController *fetchedResultsController;
  NSFetchedResultsController *searchFetchedResultsController;
  NewComicFetcher *fetcher;
  SingleComicImageFetcher *imageFetcher;
  UISearchDisplayController *searchController;
  
  // The saved state of the search UI if a memory warning removed the view.
  NSString *savedSearchTerm;
  BOOL searchWasActive;

  NSInteger requestedLaunchComic;

  TLModalActivityIndicatorView *modalSpinner;

  // Pull-to-refresh
  LorenRefreshView *refreshHeaderView;
	BOOL shouldCheckForRefreshGesture;
	BOOL refreshing;
}

@property(nonatomic, strong, readonly) UITableView *tableView;
@property(nonatomic, assign, readwrite) NSInteger requestedLaunchComic;

@end
