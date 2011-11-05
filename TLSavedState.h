//
//  TLSavedState.h
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 9/7/09.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Use for saving a small number of small key/value pairs across app launches.
// Values must be plist-friendly.
// Saves automatically, etc. -- all you need is what you see.
// Not thread safe, any of it.

@interface TLSavedState : NSObject

+ (id)valueForKey:(NSString *)key;
+ (void)setValue:(id)value forKey:(NSString *)key;
- (NSDictionary *)dictionaryRepresentation;

// returns YES the first time this is ever called for a particular key, and NO every subsequent time
+ (BOOL)firstTimeForEvent:(NSString *)keyRepresentingEvent;

@end
