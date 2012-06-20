//
//  NSArray+Filtering.m
//  xkcd
//
//  Created by Josh Bleecher Snyder on 6/19/12.
//
//

#import "NSArray+Filtering.h"

@implementation NSArray (Filtering)

- (BOOL)containsObjectOfKindOfClass:(Class)cls {
  NSUInteger index = [self indexOfObjectPassingTest:^(id obj, NSUInteger index, BOOL *stop) {
    BOOL isCorrectKindOfClass = [obj isKindOfClass:cls];
    if(isCorrectKindOfClass) {
      *stop = isCorrectKindOfClass;
    }
    return isCorrectKindOfClass;
  }];
  
  return index != NSNotFound;
}

- (NSArray *)objectsOfKindOfClass:(Class)cls {
  NSIndexSet *indices = [self indexesOfObjectsPassingTest:^(id obj, NSUInteger index, BOOL *stop) {
    return [obj isKindOfClass:cls];
  }];

  return [self objectsAtIndexes:indices];
}

@end
