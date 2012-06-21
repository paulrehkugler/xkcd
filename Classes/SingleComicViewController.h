//
//  SingleComicViewController.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/2/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ComicImageViewDelegate.h"
#import "SingleComicImageFetcherDelegate.h"

@class Comic;
@class SingleComicImageFetcher;
@class TLLoadingView;

@interface SingleComicViewController : UIViewController <
  UIScrollViewDelegate,
  UIActionSheetDelegate,
  ComicImageViewDelegate,
  SingleComicImageFetcherDelegate
> {
@private
  Comic *comic;
  NSMutableArray *comicImageViews;
  UIView *contentView;
  UIScrollView *imageScroller;
  TLLoadingView *loadingView;
  SingleComicImageFetcher *imageFetcher;
}

- (id)initWithComic:(Comic *)comicToView;

@property(nonatomic, strong, readonly) Comic *comic;

@end
