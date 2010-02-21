//
//  TestNSString_HTML.m
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 2/18/10.
//  Copyright 2010 AdCru. All rights reserved.
//

#import "TestNSString_HTML.h"
#import "NSString_HTML.h"

@implementation TestNSString_HTML

- (void)testStringByCleaningHTML {
  NSDictionary *htmlAndCleanedStrings = [NSDictionary dictionaryWithObjectsAndKeys:
                                         @"hi", @"<span>hi</span>",
                                         @"good > bad", @"good &gt; bad",
                                         @"\"quote\"", @"&quot;quote&quot;",
                                         @"clichés", @"clich&eacute;s",
                                         @"House of Pancakes", @"<span style=\"color: #0000ED\">House</span> of Pancakes",
                                         @"bad > worse", @"bad > worse",
                                         nil];
  for(NSString *snippet in htmlAndCleanedStrings) {
    NSString *cleaned = [htmlAndCleanedStrings objectForKey:snippet];
    STAssertEqualObjects([NSString stringByCleaningHTML:snippet], cleaned, @"Snippet '%@' should result in clean string '%@'.", snippet, cleaned);
  }
}

@end
