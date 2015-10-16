//
//  TLNavigationController.m
//  xkcd
//
//  Created by Paul Rehkugler on 5/28/13.
//
//

#import "TLNavigationController.h"
#import "xkcdAppDelegate.h"


@implementation TLNavigationController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
