//
//  NSDate+MWFUtils.h
//  xkcd
//
//  Created by Paul Rehkugler on 5/31/13.
//
//

#import <Foundation/Foundation.h>

@interface NSDate (MWFUtils)

+ (NSDate *) now;

@property (readonly) NSDate *nextMondayWednesdayOrFriday;

@end
