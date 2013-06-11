//
//  NSDate+MWFUtils.m
//  xkcd
//
//  Created by Paul Rehkugler on 5/31/13.
//
//  With inspiration from
//  NSDate-Extensions: https://github.com/erica/NSDate-Extensions
//

#import "NSDate+MWFUtils.h"

#define AllDateComponents (NSYearCalendarUnit| NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekCalendarUnit |  NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSWeekdayCalendarUnit | NSWeekdayOrdinalCalendarUnit)
#define kDayTimeInterval 86400
#define kXkcdUploadBufferTimeInterval 7200  // 2 hour buffer from midnight - is this enough?
#define kGMTOffsetInterval 18000

@implementation NSDate (MWFUtils)

- (NSDate *) nextMondayWednesdayOrFriday {

  // start off the return date as this date at midnight
  NSDateComponents *retDateComponents = [[NSCalendar currentCalendar] components: AllDateComponents fromDate:self];
  retDateComponents.second = 0;
  retDateComponents.hour = 0;
  retDateComponents.minute = 0;
  retDateComponents.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
  
  NSDate *retDate = [[NSCalendar currentCalendar] dateFromComponents:retDateComponents];
  
  // bump this up from midnight by our offsets
  retDate = [retDate dateByAddingTimeInterval:kXkcdUploadBufferTimeInterval + kGMTOffsetInterval];
  
  // get the components out of the current time
  NSDateComponents *components = [[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:self];
	
  int weekday = components.weekday - 1;   // zero index these weekdays for sanity
  
  int daysTilMonday = (8 - weekday) % 7;    // sunday is zero, monday is 1 (8 to keep this positive)
  
  if (daysTilMonday > 0 && daysTilMonday <= 3) {    // if today's not monday, and monday is the next MWF
    return [retDate dateByAddingTimeInterval:kDayTimeInterval * daysTilMonday];
  }
  
  int daysTilWednesday = (10 - weekday) % 7;
  
  if (daysTilWednesday > 0 && daysTilWednesday <= 2 ) {
    return [retDate dateByAddingTimeInterval:kDayTimeInterval * daysTilWednesday];
  }
  
  int daysTilFriday = (12 - weekday) % 7;
  
  return [retDate dateByAddingTimeInterval:kDayTimeInterval * daysTilFriday];
}

@end
