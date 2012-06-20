//
//  NSArray+Filtering.h
//  xkcd
//
//  Created by Josh Bleecher Snyder on 6/19/12.
//
//

#import <Foundation/Foundation.h>

typedef BOOL (^ObjectTestBlock)(id obj);

@interface NSArray (Filtering)

- (BOOL)containsObjectPassingTest:(ObjectTestBlock)test;
- (NSArray *)objectsPassingTest:(ObjectTestBlock)test;

- (BOOL)containsObjectOfKindOfClass:(Class)cls;
- (NSArray *)objectsOfKindOfClass:(Class)cls;

@end
