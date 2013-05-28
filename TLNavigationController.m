//
//  TLNavigationController.m
//  xkcd
//
//  Created by Paul Rehkugler on 5/28/13.
//
//

#import "TLNavigationController.h"
#import "xkcdAppDelegate.h"


@interface TLNavigationController ()

@end

@implementation TLNavigationController

- (NSUInteger)supportedInterfaceOrientations {
    return [AppDelegate rotate] ? UIInterfaceOrientationMaskAllButUpsideDown : UIInterfaceOrientationMaskPortrait;
}

@end
