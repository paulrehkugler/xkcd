//
//  NotificationGenerator.m
//  xkcd
//
//  Created by Paul Rehkugler on 5/31/13.
//
//

#import "NotificationGenerator.h"
#import "NSDate+MWFUtils.h"

@interface NotificationGenerator(private)

+ (BOOL) scheduledLocalNotificationsContainNotification:(UILocalNotification *)aLocalNotif;

@end

@implementation NotificationGenerator

+ (void) clearAppBadge {
  [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

+ (void) generateNextNotification {
    
  UILocalNotification *localNotif = [[UILocalNotification alloc] init];

  localNotif.fireDate = ((NSDate *)[NSDate date]).nextMondayWednesdayOrFriday;

  NSLog(@"%@", localNotif.fireDate);
  // Notification details
  localNotif.alertBody = @"A new comic is available.";
  localNotif.alertAction = @"View";
  
  localNotif.soundName = UILocalNotificationDefaultSoundName;
  localNotif.applicationIconBadgeNumber = 1;

  if (![NotificationGenerator scheduledLocalNotificationsContainNotification:localNotif])
  {
    // Schedule the notification
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
  }
}

+ (BOOL) scheduledLocalNotificationsContainNotification:(UILocalNotification *)aLocalNotif {
  return [[[UIApplication sharedApplication] scheduledLocalNotifications] containsObject:aLocalNotif];
}

@end
