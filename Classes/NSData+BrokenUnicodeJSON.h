//
//  NSData+BrokenUnicodeJSON.h
//

@import Foundation;

@interface NSData (BrokenUnicodeJSON)

- (NSData *)dataByFixingFuckedUpUnicodeInJSON;

@end
