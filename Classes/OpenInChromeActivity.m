//
//  OpenInChromeActivity.m
//  xkcd
//

#import "OpenInChromeActivity.h"

@implementation OpenInChromeActivity

- (NSString *)activityType {
  return @"com.treelinelabs.xkcdapp.open_in_chrome";
}

- (NSString *)activityTitle {
  return @"Open in Chrome";
}

- (UIImage *)activityImage {
  return [UIImage imageNamed:@"blueArrow.png"];  // TODO: Needs image here
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
  if(![super canPerformWithActivityItems:activityItems]) {
    return NO;
  }

  return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome://"]];
}

- (void)performActivity {
  // adapted from https://developers.google.com/chrome/mobile/docs/ios-links

  NSURL *inputURL = self.urlToOpen;
  NSString *scheme = inputURL.scheme;

  // Replace the URL Scheme with the Chrome equivalent.
  NSString *chromeScheme = nil;
  if ([scheme isEqualToString:@"http"]) {
    chromeScheme = @"googlechrome";
  } else if ([scheme isEqualToString:@"https"]) {
    chromeScheme = @"googlechromes";
  }

  // Proceed only if a valid Google Chrome URI Scheme is available.
  if (chromeScheme) {
    NSString *absoluteString = [inputURL absoluteString];
    NSRange rangeForScheme = [absoluteString rangeOfString:@":"];
    NSString *urlNoScheme = [absoluteString substringFromIndex:rangeForScheme.location];
    NSString *chromeURLString = [chromeScheme stringByAppendingString:urlNoScheme];
    NSURL *chromeURL = [NSURL URLWithString:chromeURLString];

    // Open the URL with Chrome.
     [[UIApplication sharedApplication] openURL:chromeURL];
  }

  [self activityDidFinish:YES];
}

@end
