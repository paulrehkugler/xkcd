//
//  NSDate+MWFUtils.h
//  xkcd
//
//  Created by Paul Rehkugler on 5/31/13.
//
//

#import <Foundation/Foundation.h>

@interface NSDate (MWFUtils)

@property (readonly) NSDate *nextMondayWednesdayOrFriday;

@end
