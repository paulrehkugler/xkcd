//
//  ComicImageViewDelegate.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/1/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

@protocol ComicImageViewDelegate<NSObject>

- (void)zoomOutWithTouch:(UITouch *)touch;

@end
