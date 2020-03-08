//
//  NSMutableArray+Safety.m
//  xkcd
//
//  Created by Paul Rehkugler on 3/8/20.
//

#import "NSMutableArray+Safety.h"

@implementation NSMutableArray (Safety)

- (void)safelyAddObject:(id)object {
    if (object) {
        [self addObject:object];
    }
}

@end
