//
//  NotificationGenerator.m
//  xkcd
//
//  Created by Paul Rehkugler on 5/31/13.
//
//

#import "NotificationGenerator.h"
#import "NSDate+MWFUtils.h"

@implementation NotificationGenerator

+ (void) clearAppBadge
{
  // TODO: figure out how to do this
}

+ (void) generateNextNotification {
  
  UILocalNotification *localNotif = [[UILocalNotification alloc] init];

  localNotif.fireDate = ((NSDate *)[NSDate now]).nextMondayWednesdayOrFriday;

  // Notification details
  localNotif.alertBody = @"A new xkcd comic is available.";
  localNotif.alertAction = @"View";
  
  localNotif.soundName = UILocalNotificationDefaultSoundName;
  localNotif.applicationIconBadgeNumber = 1;

  // Schedule the notification
  [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
  
}

@end
