//
//  SearchBarTableViewCell.m
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/2/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import "SearchBarTableViewCell.h"

#pragma mark -

@interface SearchBarTableViewCell ()

@property(nonatomic, retain, readwrite) UISearchBar *searchBar;

@end

#pragma mark -

@implementation SearchBarTableViewCell

@synthesize searchBar;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
    self.searchBar = [[[UISearchBar alloc] initWithFrame:CGRectZero] autorelease];
    self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.searchBar sizeToFit];
    [self.contentView addSubview:self.searchBar];
  }
  return self;
}

- (void)dealloc {
  [searchBar release];
  searchBar = nil;
  
  [super dealloc];
}


@end
