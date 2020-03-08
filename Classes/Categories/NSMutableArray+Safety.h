//
//  NSMutableArray+Safety.h
//  xkcd
//
//  Created by Paul Rehkugler on 3/8/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableArray<T> (Safety)

- (void)safelyAddObject:(T)object;

@end

NS_ASSUME_NONNULL_END
