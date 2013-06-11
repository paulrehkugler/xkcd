//
//  TLLoadingView.m
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 10/18/09.
//

#import "TLLoadingView.h"
#import "UIActivityIndicatorView_TLCommon.h"
#import "CGGeometry_TLCommon.h"

#define kDefaultLoadingText NSLocalizedString(@"Loading...", @"Default text of loading view")

#pragma mark -

@interface TLLoadingView ()

@property(nonatomic, strong, readwrite) UILabel *label;
@property(nonatomic, strong, readwrite) UIActivityIndicatorView *spinner;

@end


#pragma mark -

@implementation TLLoadingView

- (id)initWithFrame:(CGRect)frame {
  if(self = [super initWithFrame:frame]) {
    _label = [[UILabel alloc] initWithFrame:CGRectZero];
    _label.text = kDefaultLoadingText;
    _spinner = [UIActivityIndicatorView animatingActivityIndicatorViewWithStyle:UIActivityIndicatorViewStyleGray];
    [self addSubview:_label];
    [self addSubview:_spinner];
    [self setNeedsLayout];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];

  CGFloat viewHeight = self.bounds.size.height;
  CGFloat viewWidth = self.bounds.size.width;
  
  CGSize spinnerSize = self.spinner.bounds.size;
  
  CGFloat spinnerToLabelPadding = spinnerSize.width / 2.0f;
  CGFloat horizontalPadding = spinnerToLabelPadding; // required distance between left/right edge of view and spinner/label
  CGFloat maxLabelWidth = viewWidth - spinnerSize.width - horizontalPadding * 2.0f - spinnerToLabelPadding; 
  CGSize renderedLabelSize = [self.label.text sizeWithFont:self.label.font
                                         constrainedToSize:CGSizeMake(maxLabelWidth, viewHeight)
                                             lineBreakMode:self.label.lineBreakMode];
  
  CGFloat spinnerPlusLabelWidth = spinnerSize.width + spinnerToLabelPadding + renderedLabelSize.width;
  CGFloat spinnerXOffset = OffsetToCenterFloatInFloat(spinnerPlusLabelWidth, viewWidth);
  CGRect spinnerFrame = CGRectWithXYAndSize(spinnerXOffset,
                                            OffsetToCenterFloatInFloat(spinnerSize.height, viewHeight),
                                            spinnerSize);
  spinnerFrame = CGRectFlooredToNearestPixel(spinnerFrame);
  self.spinner.frame = spinnerFrame;
  CGRect labelFrame = CGRectWithXYAndSize(spinnerXOffset + spinnerSize.width + spinnerToLabelPadding,
                                          OffsetToCenterFloatInFloat(renderedLabelSize.height, viewHeight),
                                          renderedLabelSize);
  labelFrame = CGRectFlooredToNearestPixel(labelFrame);
  self.label.frame = labelFrame;
}


@end
