//
//  NSArray+Filtering.m
//  xkcd
//
//  Created by Josh Bleecher Snyder on 6/19/12.
//
//

#import "NSArray+Filtering.h"

@implementation NSArray (Filtering)


- (BOOL)containsObjectPassingTest:(ObjectTestBlock)test {
	NSUInteger index = [self indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
		BOOL passesTest = test(obj);
		if (passesTest) {
			*stop = YES;
		}
		return passesTest;
	}];
	
	return index != NSNotFound;
}

- (NSArray *)objectsPassingTest:(ObjectTestBlock)test {
	NSIndexSet *indices = [self indexesOfObjectsPassingTest:^(id obj, NSUInteger index, BOOL *stop) {
		return test(obj);
	}];
	
	return [self objectsAtIndexes:indices];
}

- (BOOL)containsObjectOfKindOfClass:(Class)cls {
	return [self containsObjectPassingTest:^BOOL(id obj) {
		return [obj isKindOfClass:cls];
	}];
}

- (NSArray *)objectsOfKindOfClass:(Class)cls {
	return [self objectsPassingTest:^BOOL(id obj) {
		return [obj isKindOfClass:cls];
	}];
}

@end
