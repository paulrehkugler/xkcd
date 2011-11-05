//
//  TLSavedState.m
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 9/7/09.
//

#import "TLSavedState.h"
#import "NSFileManager_TLCommon.h"

@class TLSavedStateNotificationRecipient;

static NSMutableDictionary *state = nil;
static TLSavedStateNotificationRecipient *notificationRecipient = nil;

#pragma mark -

@interface TLSavedState ()

+ (NSString *)stateSavePath;
+ (void)saveState;

@end

#pragma mark -

@interface TLSavedStateNotificationRecipient : NSObject

- (void)didReceiveNotification:(NSNotification *)notification;

@end

#pragma mark -

@implementation TLSavedStateNotificationRecipient

- (id)init {
  if(self = [super init]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveNotification:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:[UIApplication sharedApplication]];
  }
  return self;
}

- (void)didReceiveNotification:(NSNotification *)notification {
  [TLSavedState saveState];
}

@end


#pragma mark -

@implementation TLSavedState

+ (void)initialize {
  if([self class] == [TLSavedState class]) {
    if(!state) {
      state = [NSMutableDictionary dictionaryWithContentsOfFile:[[self class] stateSavePath]];
      if(!state) {
        state = [NSMutableDictionary dictionary];
      }
      [state retain];
      if(!notificationRecipient) {
        notificationRecipient = [[TLSavedStateNotificationRecipient alloc] init];
      }
    }
  }
}

+ (id)valueForKey:(NSString *)key {
  id value = [state objectForKey:key];
  if(value == [NSNull null]) {
    value = nil;
  }
  return value;
}

+ (void)setValue:(id)value forKey:(NSString *)key {
  if(!value) {
    value = [NSNull null];
  }
  [state setObject:value forKey:key];
}

+ (BOOL)firstTimeForEvent:(NSString *)keyRepresentingEvent {
  NSString *mangledKey = [@"TLSavedStateInternal_FirstTime_" stringByAppendingString:keyRepresentingEvent];
  BOOL firstTime = ![[self valueForKey:mangledKey] boolValue];
  if(firstTime) {
    [self setValue:[NSNumber numberWithBool:YES] forKey:mangledKey];
  }
  return firstTime;
}

+ (NSString *)stateSavePath {
  NSString *savePath = [[NSFileManager applicationDocumentsDirectory] stringByAppendingPathComponent:@"tl_saved_state"];
  return savePath;
}

- (NSDictionary *)dictionaryRepresentation {
  return [[state copy] autorelease];
}

+ (void)saveState {
  [state writeToFile:[[self class] stateSavePath] atomically:YES];
}

@end
