//
//  TLModalActivityIndicatorView.m
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 9/10/09.
//

#import "TLModalActivityIndicatorView.h"
#import "CGGeometry_TLCommon.h"

#define kModalSize 160.0f
#define kCornerRadius 20.0f
#define kLabelHeight 30.0f
#define kLabelFont [UIFont fontWithName:@"Helvetica" size:18.0f]
#define kModalColor [UIColor colorWithWhite:0.3 alpha:0.8]
#define kStartingScale 1.8f
#define kAnimationDuration 0.25f

#pragma mark -

@interface TLModalActivityIndicatorView ()

@property (nonatomic) UIActivityIndicatorView *spinner;

@end


#pragma mark -

@implementation TLModalActivityIndicatorView

- (instancetype)initWithText:(NSString *)text {
	if (self = [super initWithFrame:CGRectZero]) {
		UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
		CGSize keyWindowSize = keyWindow.bounds.size;
		CGPoint keyWindowCenter = CGPointMake(keyWindowSize.width / 2.0f, keyWindowSize.height / 2.0f);
		
		self.frame = CGRectZeroWithSize(keyWindowSize);
		self.backgroundColor = [UIColor clearColor];
		
		CALayer *backgroundLayer = [CALayer layer];
		backgroundLayer.cornerRadius = kCornerRadius;
		backgroundLayer.masksToBounds = YES;
		backgroundLayer.bounds = CGRectMake(0.0f, 0.0f, kModalSize, kModalSize);
		backgroundLayer.position = keyWindowCenter;
		backgroundLayer.backgroundColor = kModalColor.CGColor;
		
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(keyWindowCenter.x - kModalSize / 2.0f,
																   keyWindowCenter.y + kModalSize / 2.0f - kLabelHeight,
																   kModalSize,
																   kLabelHeight)];
		label.text = text;
		label.textColor = [UIColor whiteColor];
		label.backgroundColor = [UIColor clearColor];
		label.font = kLabelFont;
		label.textAlignment = NSTextAlignmentCenter;
		_spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectZero];
		_spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
		[_spinner sizeToFit];
		[_spinner startAnimating];
		
		_spinner.center = keyWindowCenter;
		
		[self.layer addSublayer:backgroundLayer];
		[self addSubview:label];
		[self addSubview:_spinner];
		
		self.transform = CGAffineTransformMakeScale(kStartingScale, kStartingScale);
	}
	return self;
}

- (void)show {
	[[UIApplication sharedApplication].keyWindow addSubview:self];
	[UIView beginAnimations:@"modalSpinner" context:NULL];
	self.transform = CGAffineTransformIdentity;
	[UIView setAnimationDuration:kAnimationDuration];
	[UIView commitAnimations];
}

- (void)dismiss {
	[self removeFromSuperview];
}


@end
