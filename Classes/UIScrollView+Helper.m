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

  // this works fairly well - centers are off a bit when point is far from (0,0)
  CGFloat visibleWidth = self.frame.size.width / scale;
  CGFloat visibleHeight = self.frame.size.height / scale;
  CGFloat leftX = (point.x - (visibleWidth / 2));
  CGFloat topY = (point.y - (visibleHeight / 2));

  [self zoomToRect:CGRectMake(leftX, topY, visibleWidth, visibleHeight) animated:animated];
}

@end
