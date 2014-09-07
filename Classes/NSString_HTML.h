//
//  NSString_HTML.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 2/17/10.
//

@import Foundation;

@interface NSString (HTML)

+ (NSString *)stringByCleaningHTML:(NSString *)HTMLSnippet;

@end
