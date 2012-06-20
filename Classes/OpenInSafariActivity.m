//
//  OpenInSafariActivity.m
//  xkcd
//
//  Created by Josh Bleecher Snyder on 6/19/12.
//
//

#import "OpenInSafariActivity.h"
#import "NSArray+Filtering.h"

@interface OpenInSafariActivity ()

@property(nonatomic, strong) NSURL *urlToOpen;

@end

@implementation OpenInSafariActivity

@synthesize urlToOpen;

- (NSString *)activityType {
  return @"com.treelinelabs.xkcdapp.open_in_safari";
}

- (NSString *)activityTitle {
  return @"Open in Safari";
}

- (UIImage *)activityImage {
  return [UIImage imageNamed:@"blueArrow.png"];  // TODO: Needs image here
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
  return [activityItems containsObjectOfKindOfClass:[NSURL class]];
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
  self.urlToOpen = [activityItems objectsOfKindOfClass:[NSURL class]][0];
}

- (void)performActivity {
  [[UIApplication sharedApplication] openURL:self.urlToOpen];
  [self activityDidFinish:YES];
}

@end
