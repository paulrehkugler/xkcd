//
//  LorenRefreshView.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 2/21/10.
//

// Inspired/borrowed/adapted from Loren Brichter's Tweetie 2, http://github.com/enormego/EGOTableViewPullRefresh,
// and http://www.drobnik.com/touch/2009/12/how-to-make-a-pull-to-reload-tableview-just-like-tweetie-2/

#import <UIKit/UIKit.h>

typedef enum {
  RefreshViewStateReleaseToReload,
  RefreshViewStatePullToReload,
  RefreshViewStateLoading
} RefreshViewState;

@interface LorenRefreshView : UIView {
@private
	UILabel *statusLabel;
	UIImageView *arrowImageView;
	UIActivityIndicatorView *spinner;
  
	BOOL flipped;
}

- (void)flipArrowAnimated:(BOOL)animated;
- (void)setSpinnerAnimating:(BOOL)shouldBeAnimating;
- (void)setState:(RefreshViewState)newState;

@property(nonatomic, assign, readonly) BOOL flipped;

@end
