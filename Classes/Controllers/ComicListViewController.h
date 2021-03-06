//
//  ComicListViewController.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 8/25/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

@import CoreData;
@import MessageUI;
@import UIKit;

#import "NewComicFetcherDelegate.h"
#import "SingleComicImageFetcherDelegate.h"
#import "TLModalActivityIndicatorView.h"

@class NewComicFetcher;
@class SingleComicImageFetcher;

@interface ComicListViewController : UITableViewController <NewComicFetcherDelegate, NSFetchedResultsControllerDelegate,
SingleComicImageFetcherDelegate, MFMailComposeViewControllerDelegate, UIScrollViewDelegate>

@property (nonatomic) NSInteger requestedLaunchComic;

- (NSIndexPath *)indexPathForComicNumbered:(NSInteger)comicNumber;
- (NSFetchedResultsController *)activeFetchedResultsController;

@end
