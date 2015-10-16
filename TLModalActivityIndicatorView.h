//
//  TLModalActivityIndicatorView.h
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 9/10/09.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface TLModalActivityIndicatorView : UIView

- (instancetype)initWithText:(NSString *)text;
- (void)show;
- (void)dismiss;

@end
