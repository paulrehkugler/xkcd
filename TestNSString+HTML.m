//
//  TestNSString+HTML.m
//  xkcd
//
//  Created by Paul Rehkugler on 9/7/14.
//
//

@import UIKit;
@import XCTest;

#import "NSString_HTML.h"

@interface TestNSString_HTML : XCTestCase

@end

@implementation TestNSString_HTML

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

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
    
    for (NSString *snippet in htmlAndCleanedStrings) {
        NSString *cleaned = htmlAndCleanedStrings[snippet];
        XCTAssertEqualObjects([NSString stringByCleaningHTML:snippet], cleaned, @"Snippet '%@' should result in clean string '%@'.", snippet, cleaned);
    }
}

@end
