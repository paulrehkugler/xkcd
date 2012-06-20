//
//  NSArray+Filtering.h
//  xkcd
//
//  Created by Josh Bleecher Snyder on 6/19/12.
//
//

#import <Foundation/Foundation.h>

@interface NSArray (Filtering)

- (BOOL)containsObjectOfKindOfClass:(Class)cls;
- (NSArray *)objectsOfKindOfClass:(Class)cls;

@end
