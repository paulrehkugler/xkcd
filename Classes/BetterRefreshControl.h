//
//  UIRefreshControl+Utils.h
//  xkcd
//
//  Created by Paul Rehkugler on 6/1/13.
//
//

#import <UIKit/UIKit.h>

typedef enum {
  UIRefreshControlUtilsStateInactive,
  UIRefreshControlUtilsStateActive
} UIRefreshControlUtilsState;

@interface BetterRefreshControl : UIRefreshControl

- (void) attributedTitle:(NSAttributedString *)title forRefreshState:(UIRefreshControlUtilsState)state;

@property (nonatomic, readonly) UIRefreshControlUtilsState refreshState;

@end
