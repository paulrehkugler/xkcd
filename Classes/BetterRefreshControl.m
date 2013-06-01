//
//  UIRefreshControl+Utils.m
//  xkcd
//
//  Created by Paul Rehkugler on 6/1/13.
//
//

#import "BetterRefreshControl.h"

@interface BetterRefreshControl()

@property (nonatomic, readwrite) UIRefreshControlUtilsState refreshState;
@property (nonatomic, readwrite) NSMutableDictionary *titles;
@property (nonatomic, readwrite) NSAttributedString *defaultTitle;

+ (id)keyForState:(UIRefreshControlUtilsState)state;

@end

@implementation BetterRefreshControl

- (id) init {
  self = [super init];
  if (self) {
    self.refreshState = UIRefreshControlUtilsStateInactive;
    self.titles = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void) attributedTitle:(NSAttributedString *)title forRefreshState:(UIRefreshControlUtilsState)state {
  [self.titles setObject:title forKey:[BetterRefreshControl keyForState:state]];
  
  // set a default title in case the user doesn't set more
  if (!self.defaultTitle || state == UIRefreshControlUtilsStateInactive) {
    self.defaultTitle = title;
  }
}

- (void) beginRefreshing {
  [super beginRefreshing];
  self.refreshState = UIRefreshControlUtilsStateActive;
}

- (void) endRefreshing {
  [super endRefreshing];
  self.refreshState = UIRefreshControlUtilsStateInactive;
}

- (void) setRefreshState:(UIRefreshControlUtilsState)state {
  if (state != self.refreshState) {
    NSAttributedString *newTitle = [self.titles objectForKey:[BetterRefreshControl keyForState:state]];
    self.attributedTitle = newTitle ? newTitle : self.defaultTitle;
  }
  _refreshState = state;
}

+ (id)keyForState:(UIRefreshControlUtilsState)state
{
  return [NSNumber numberWithInt:state];
}

@end
