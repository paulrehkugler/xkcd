//
//  SearchBarTableViewCell.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/2/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SearchBarTableViewCell : UITableViewCell {
@private
  UISearchBar *searchBar;
}

@property(nonatomic, retain, readonly) UISearchBar *searchBar;

@end
