//
//  NSData+BrokenUnicodeJSON.h
//

#import <Foundation/Foundation.h>

@interface NSData (BrokenUnicodeJSON)

- (NSData *)dataByFixingFuckedUpUnicodeInJSON;

@end
