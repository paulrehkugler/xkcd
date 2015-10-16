//
//  UIScrollView+Helper.m
//  xkcd
//
//  Created by Paul Rehkugler on 6/1/13.
//
//

#import "UIScrollView+Helper.h"

@implementation UIScrollView (Helper)

- (void)setZoomScale:(float)scale animated:(BOOL)animated centerOnPoint:(CGPoint)point {
	// convert scroll view point to content point
	UIView *contentView = [self hitTest:point withEvent:nil];
	CGPoint contentCenter = [self convertPoint:point toView:contentView];
	
	CGFloat visibleWidth = self.frame.size.width / scale;
	CGFloat visibleHeight = self.frame.size.height / scale;
	
	// make the target content point the center of the resulting view
	CGFloat leftX = (contentCenter.x - (visibleWidth / 2));
	CGFloat topY = (contentCenter.y - (visibleHeight / 2));
	
	[self zoomToRect:CGRectMake(leftX, topY, visibleWidth, visibleHeight) animated:animated];
}

@end
