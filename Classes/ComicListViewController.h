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

@interface ComicListViewController : UITableViewController <
  NewComicFetcherDelegate,
  NSFetchedResultsControllerDelegate,
  UISearchBarDelegate,
  UISearchDisplayDelegate,
  SingleComicImageFetcherDelegate,
  UIActionSheetDelegate,
  MFMailComposeViewControllerDelegate,
  UIScrollViewDelegate
> {
@private
  NSFetchedResultsController *fetchedResultsController;
  NSFetchedResultsController *searchFetchedResultsController;
  NewComicFetcher *fetcher;
  SingleComicImageFetcher *imageFetcher;
  UISearchDisplayController *searchController;

  NSInteger requestedLaunchComic;

  TLModalActivityIndicatorView *modalSpinner;
}

@property(nonatomic, assign, readwrite) NSInteger requestedLaunchComic;

@end
