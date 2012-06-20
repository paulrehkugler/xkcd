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

+ (BOOL)canPerformWithObject:(id)obj {
  if(![obj isKindOfClass:[NSURL class]]) {
    return NO;
  }
  
  // can't (or anyway shouldn't) open mailto: or sms: in safari
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

- (void)performActivity {
  [[UIApplication sharedApplication] openURL:self.urlToOpen];
  [self activityDidFinish:YES];
}

@end
