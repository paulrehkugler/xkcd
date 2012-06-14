//
//  TestNSString_HTML.m
//

#import "TestNSString_HTML.h"
#import "NSString_HTML.h"

@implementation TestNSString_HTML

- (void)testStringByCleaningHTML {
  NSDictionary *htmlAndCleanedStrings = @{
    @"<span>hi</span>": @"hi",
    @"good &gt; bad": @"good > bad",
    @"&quot;quote&quot;": @"\"quote\"",
    @"clich&eacute;s": @"clichés",
    @"<span style=\"color: #0000ED\">House</span> of Pancakes": @"House of Pancakes",
    @"bad > worse": @"bad > worse",
    @"I Accidentally <noun>": @"I Accidentally <noun>",
    @"<3": @"<3",
    @"<>": @"<>",
    @"RSS&M": @"RSS&M",
    @"(or \\;;\"\\''{\\<<[' this mouseover text": @"(or \\;;\"\\''{\\<<[' this mouseover text"
  };

  for(NSString *snippet in htmlAndCleanedStrings) {
    NSString *cleaned = [htmlAndCleanedStrings objectForKey:snippet];
    STAssertEqualObjects([NSString stringByCleaningHTML:snippet], cleaned, @"Snippet '%@' should result in clean string '%@'.", snippet, cleaned);
  }
}

@end
