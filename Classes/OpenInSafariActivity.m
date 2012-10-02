//
//  OpenInSafariActivity.m
//  xkcd
//

#import "OpenInSafariActivity.h"

#pragma mark -

@implementation OpenInSafariActivity

- (NSString *)activityType {
  return @"com.treelinelabs.xkcdapp.open_in_safari";
}

- (NSString *)activityTitle {
  return @"Open in Safari";
}

- (UIImage *)activityImage {
  return [UIImage imageNamed:@"blueArrow.png"];  // TODO: Needs image here
}

- (void)performActivity {
  [[UIApplication sharedApplication] openURL:self.urlToOpen];
  [self activityDidFinish:YES];
}

@end
