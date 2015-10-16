//
//  TestBrokenUnicodeFixer.m
//

@import XCTest;
#import "NSData+BrokenUnicodeJSON.h"

#define CDATASTR(s) [NSData dataWithBytes:s length:sizeof(s)]

@interface TestBrokenUnicodeFixer : XCTestCase

@end

@implementation TestBrokenUnicodeFixer

- (void)assertDictionaryEntriesAreFixedCorrectly:(NSDictionary *)testCases {
	for (NSData *inputData in testCases) {
		NSData *expectedOutput = testCases[inputData];
		XCTAssertTrue([expectedOutput isKindOfClass:[NSData class]], @"Expected to get NSData object");
		XCTAssertEqualObjects([inputData dataByFixingFuckedUpUnicodeInJSON], expectedOutput,
							  @"Input '%@' should result in output '%@'.",
							  [[NSString alloc] initWithData:inputData encoding:NSUTF8StringEncoding],
							  [[NSString alloc] initWithData:expectedOutput encoding:NSUTF8StringEncoding]);
	}
}

- (void)testCleanData {
	[self assertDictionaryEntriesAreFixedCorrectly:@{
													 CDATASTR("abcd"): CDATASTR("abcd"),
													 }];
}

- (void)testKnownBrokenData {
	[self assertDictionaryEntriesAreFixedCorrectly:@{
													 CDATASTR("Erd\\u00c5\\u0091s"): CDATASTR("Erdős"),
													 CDATASTR("Beyonc\\u00c3\\u00a9"): CDATASTR("Beyoncé"),
													 CDATASTR("Nazg\\u00c8\\u0097l"): CDATASTR("Nazgȗl"),
													 CDATASTR("E\\u00c3\\u00a4rendil"): CDATASTR("Eärendil"),
													 }];
}

- (void)testEdgeCases {
	[self assertDictionaryEntriesAreFixedCorrectly:@{
													 CDATASTR(""): CDATASTR(""),
													 CDATASTR("\\u00c5\\u0091"): CDATASTR("ő"),
													 CDATASTR("\\u00c5\\u0091\\u00c5\\u0091"): CDATASTR("őő"),
													 CDATASTR("\\u00x5\\u009p"): CDATASTR("\\u00x5\\u009p"),
													 CDATASTR("\\u00x5\\u009p\\u00c5\\u0091"): CDATASTR("\\u00x5\\u009pő"),
													 CDATASTR("\\u00x5\\u009p\\u00c5\\u0091\\u00x5\\u009p"): CDATASTR("\\u00x5\\u009pő\\u00x5\\u009p"),
													 CDATASTR("\\u009"): CDATASTR("\\u009"),
													 CDATASTR("\\u00"): CDATASTR("\\u00"),
													 }];
}

@end
