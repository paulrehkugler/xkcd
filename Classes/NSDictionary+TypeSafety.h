//
//  NSDictionary+TypeSafety.h
//  xkcd
//
//  Created by Josh Bleecher Snyder on 6/22/12.
//
//

@import Foundation;

@interface NSDictionary (TypeSafety)

- (NSString *)stringForKey:(id)aKey;
- (id)objectForKey:(id)aKey ofKindOfClass:(Class)requiredClass;

@end
