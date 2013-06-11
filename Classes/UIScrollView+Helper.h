//
//  UIScrollView+Helper.h
//  xkcd
//
//  Created by Paul Rehkugler on 6/1/13.
//
//

#import <UIKit/UIKit.h>

@interface UIScrollView (Helper)

- (void) setZoomScale:(float)scale animated:(BOOL)animated centerOnPoint:(CGPoint)point;

@end
