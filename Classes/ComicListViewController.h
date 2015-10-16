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
MFMailComposeViewControllerDelegate,
UIScrollViewDelegate
>

@property (nonatomic) NSInteger requestedLaunchComic;

- (NSIndexPath *)indexPathForComicNumbered:(NSInteger)comicNumber;

@end
