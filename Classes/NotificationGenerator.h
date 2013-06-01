//
//  NotificationGenerator.h
//  xkcd
//
//  Created by Paul Rehkugler on 5/31/13.
//
//

#import <Foundation/Foundation.h>

@interface NotificationGenerator : NSObject

+ (void) generateNextNotification;
+ (void) clearAppBadge;

@end
