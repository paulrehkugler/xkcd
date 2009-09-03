//
//  FlurryAPI.h
//  Flurry iPhone Analytics Agent
//
//  Copyright 2009 Flurry, Inc. All rights reserved.
//
#import <UIKit/UIKit.h>

@class CLLocationManager;
@class CLLocation;

@interface FlurryAPI : NSObject {
}

+ (void)startSession:(NSString *)apiKey;
+ (void)logEvent:(NSString *)eventName;
+ (void)logEvent:(NSString *)eventName withParameters:(NSDictionary *)parameters;
+ (void)logError:(NSString *)errorID message:(NSString *)message exception:(NSException *)exception;

+ (void)setUserID:(NSString *)userID;
+ (void)setEventLoggingEnabled:(BOOL)value;
+ (void)setServerURL:(NSString *)url;
+ (void)setSessionReportsOnCloseEnabled:(BOOL)sendSessionReportsOnClose;

@end
