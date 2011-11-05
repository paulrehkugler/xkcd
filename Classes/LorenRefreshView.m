//
//  LorenRefreshView.m
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 2/21/10.
//

#import "LorenRefreshView.h"
#import "UIFont_TLCommon.h"
#import "UIImageView_TLCommon.h"
#import "UIActivityIndicatorView_TLCommon.h"

#define kArrowInset 40.0f
#define kArrowFlipAnimationDuration 0.2f

#define kReleaseToReloadText NSLocalizedString(@"Release to refresh...", @"")
#define kPullToReloadText NSLocalizedString(@"Pull down to refresh...", @"")
#define kLoadingText NSLocalizedString(@"Checking for new comics...", @"")

#define kStatusLabelFontColor [UIColor colorWithRed:0.478f green:0.514f blue:0.580f alpha:1.0f]

#pragma mark -

@interface LorenRefreshView ()

@property(nonatomic, assign, readwrite) BOOL flipped;
@property(nonatomic, retain, readwrite) UILabel *statusLabel;
@property(nonatomic, retain, readwrite) UIImageView *arrowImageView;
@property(nonatomic, retain, readwrite) UIActivityIndicatorView *spinner;

@end


#pragma mark -

@implementation LorenRefreshView

@synthesize flipped;
@synthesize statusLabel;
@synthesize arrowImageView;
@synthesize spinner;

- (id)initWithFrame:(CGRect)frame {
  if(self = [super initWithFrame:frame]) {
		self.statusLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0.0f, frame.size.height - 48.0f, 320.0f, 20.0f)] autorelease];
		self.statusLabel.textAlignment = UITextAlignmentCenter;
    self.statusLabel.backgroundColor = [UIColor clearColor];
    self.statusLabel.font = [UIFont helveticaWithSize:16.0f];
    self.statusLabel.textColor = kStatusLabelFontColor;
    
		[self setState:RefreshViewStatePullToReload];
		[self addSubview:self.statusLabel];
    
    CGPoint arrowSpinnerCenter = CGPointMake(kArrowInset, frame.size.height - 38.0f);
    
    self.arrowImageView = [UIImageView imageViewWithImageNamed:@"blueArrow"];
    self.arrowImageView.center = arrowSpinnerCenter;
		self.arrowImageView.transform = CGAffineTransformMakeRotation(M_PI);
		[self addSubview:self.arrowImageView];
    
		self.spinner = [UIActivityIndicatorView animatingActivityIndicatorViewWithStyle:UIActivityIndicatorViewStyleGray];
		self.spinner.center = arrowSpinnerCenter;
		self.spinner.hidesWhenStopped = YES;
		[self addSubview:self.spinner];
    
		self.flipped = NO;
  }
  return self;
}

- (void)flipArrowAnimated:(BOOL)animated {
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:animated ? kArrowFlipAnimationDuration : 0.0];
  self.arrowImageView.transform = CGAffineTransformMakeRotation(self.flipped ? M_PI * 2.0f : M_PI);
	[UIView commitAnimations];
  
	self.flipped = !self.flipped;
}

- (void)setState:(RefreshViewState)newState {
	switch(newState) {
		case RefreshViewStateReleaseToReload:
			self.statusLabel.text = kReleaseToReloadText;
			break;
		case RefreshViewStatePullToReload:
			self.statusLabel.text = kPullToReloadText;
			break;
		case RefreshViewStateLoading:
			self.statusLabel.text = kLoadingText;
			break;
		default:
			break;
	}
}

- (void)setSpinnerAnimating:(BOOL)shouldBeAnimating {
	if(!shouldBeAnimating) {
		[self.spinner stopAnimating];
		self.arrowImageView.hidden = NO;
	} else {
		[self.spinner startAnimating];
		self.arrowImageView.hidden = YES;
		[self setState:RefreshViewStateLoading];
	}
}

- (void)dealloc {
  [statusLabel release], statusLabel = nil;
  [arrowImageView release], arrowImageView = nil;
  [spinner release], spinner = nil;

  [super dealloc];
}

@end
