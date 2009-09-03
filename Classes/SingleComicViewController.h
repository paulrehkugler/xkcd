//
//  SingleComicViewController.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/2/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ComicImageViewDelegate.h"
#import <MessageUI/MessageUI.h>

@class Comic;

@interface SingleComicViewController : UIViewController
<UIScrollViewDelegate,
UIActionSheetDelegate,
ComicImageViewDelegate,
MFMailComposeViewControllerDelegate> {
@private
  Comic *comic;
  NSMutableArray *comicImageViews;
  UIView *contentView;
  UIScrollView *imageScroller;  
}

- (id)initWithComic:(Comic *)comicToView;

@property(nonatomic, retain, readonly) Comic *comic;

@end
