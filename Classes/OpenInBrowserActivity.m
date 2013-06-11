//
//  OpenInBrowserActivity.m
//  xkcd
//

#import "OpenInBrowserActivity.h"
#import "NSArray+Filtering.h"

@implementation OpenInBrowserActivity

- (UIImage *)activityImage {
  return [UIImage imageNamed:@"globe_43.png"];
}

+ (BOOL)canPerformWithObject:(id)obj {
  if(![obj isKindOfClass:[NSURL class]]) {
    return NO;
  }

  // can't (or anyway shouldn't) open mailto: or sms: in an external browser
  NSURL *url = (NSURL *)obj;
  return [url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
  return [activityItems containsObjectPassingTest:^BOOL(id obj) {
    return [[self class] canPerformWithObject:obj];
  }];
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
  NSArray *openableUrls = [activityItems objectsPassingTest:^BOOL(id obj) {
    return [[self class] canPerformWithObject:obj];
  }];

  self.urlToOpen = openableUrls[0];
}

@end
