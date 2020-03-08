//
//  NSDictionary+TypeSafety.m
//  xkcd
//
//  Created by Josh Bleecher Snyder on 6/22/12.
//
//

#import "NSDictionary+TypeSafety.h"

@implementation NSDictionary (TypeSafety)

- (NSString *)stringForKey:(id)aKey {
	return (NSString *)[self objectForKey:aKey ofKindOfClass:[NSString class]];
}

- (id)objectForKey:(id)aKey ofKindOfClass:(Class)requiredClass {
	id obj = self[aKey];
	return [obj isKindOfClass:requiredClass] ? obj : nil;
}

@end
