//
//  xkcdAppDelegate.m
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 8/25/09.
//  Copyright Treeline Labs 2009. All rights reserved.
//

#import "xkcdAppDelegate.h"
#import "FlurryAPI.h"
#import "ComicListViewController.h"
#import "NSString_HTML.h"

#define kUserDefaultsRotateKey @"rotate"
#define kUserDefaultsOpenZoomedOutKey @"zoomed_out"
#define kUserDefaultsAutodownloadKey @"autodownload"
#define kUserDefaultsOpenAfterDownloadKey @"autoopen"
#define kUserDefaultsTwitterClientKey @"twitter_client"

#pragma mark -

static NSString *applicationDocumentsDirectory = nil;

#pragma mark -

@interface xkcdAppDelegate ()

@property(nonatomic, retain, readwrite) UINavigationController *navigationController;
@property(nonatomic, retain, readwrite) ComicListViewController *listViewController;
@property(nonatomic, retain, readonly) NSUserDefaults *userDefaults;

@end

#pragma mark -

@implementation xkcdAppDelegate

@synthesize navigationController;
@synthesize listViewController;
@synthesize window;

#pragma mark -
#pragma mark Application lifecycle

void uncaughtExceptionHandler(NSException *exception) {
  [FlurryAPI logError:@"Uncaught" message:@"Oops" exception:exception];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
  [FlurryAPI startSession:@"HSR3B7WRFPVLI93FPEQH"];

  self.listViewController = [[[ComicListViewController alloc] initWithNibName:nil bundle:nil] autorelease];

  BOOL canLaunchApplication = YES;
  if(launchOptions) {
    NSURL *launchURL = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
    if([launchURL scheme] != @"xkcd") {
      canLaunchApplication = NO;
    }
    NSInteger launchedComic = [[launchURL host] integerValue];
    if(launchedComic > 0) {
      listViewController.requestedLaunchComic = launchedComic;
    }
    [FlurryAPI logEvent:@"launched via url" withParameters:launchOptions];
  }

  self.navigationController = [[[UINavigationController alloc] initWithRootViewController:self.listViewController] autorelease];
  [window addSubview:self.navigationController.view];
  [window makeKeyAndVisible];

  return canLaunchApplication;
}

/**
 applicationWillTerminate: saves changes in the application's managed object context before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application {
  NSError *error;
  if(managedObjectContext != nil) {
    if([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
      [FlurryAPI logError:@"Save error during termination"
                  message:[NSString stringWithFormat:@"Unresolved error %@, %@", error, [error userInfo]]
                exception:nil];
			exit(-1);  // Fail
    } 
  }
}

#pragma mark -
#pragma mark UserDefaults access

- (BOOL)rotate {
  if(![[self.userDefaults dictionaryRepresentation] objectForKey:kUserDefaultsRotateKey]) {
    [self.userDefaults setBool:YES forKey:kUserDefaultsRotateKey];
    [self.userDefaults synchronize];
  }
  return [self.userDefaults boolForKey:kUserDefaultsRotateKey];
}

- (BOOL)openZoomedOut {
  if(![[self.userDefaults dictionaryRepresentation] objectForKey:kUserDefaultsOpenZoomedOutKey]) {
    [self.userDefaults setBool:NO forKey:kUserDefaultsOpenZoomedOutKey];
    [self.userDefaults synchronize];
  }
  return [self.userDefaults boolForKey:kUserDefaultsOpenZoomedOutKey];
}

- (BOOL)downloadNewComics {
  if(![[self.userDefaults dictionaryRepresentation] objectForKey:kUserDefaultsAutodownloadKey]) {
    [self.userDefaults setBool:NO forKey:kUserDefaultsAutodownloadKey];
    [self.userDefaults synchronize];
  }
  return [self.userDefaults boolForKey:kUserDefaultsAutodownloadKey];
}

- (BOOL)openAfterDownload {
  if(![[self.userDefaults dictionaryRepresentation] objectForKey:kUserDefaultsOpenAfterDownloadKey]) {
    [self.userDefaults setBool:YES forKey:kUserDefaultsOpenAfterDownloadKey];
    [self.userDefaults synchronize];
  }
  return [self.userDefaults boolForKey:kUserDefaultsOpenAfterDownloadKey];
}

- (NSInteger)twitterClient {
  if(![[self.userDefaults dictionaryRepresentation] objectForKey:kUserDefaultsTwitterClientKey]) {
    [self.userDefaults setInteger:kTwitterClientAutodetect forKey:kUserDefaultsTwitterClientKey];
    [self.userDefaults synchronize];
  }  
  NSInteger client = [self.userDefaults integerForKey:kUserDefaultsTwitterClientKey];
  if(client == kTwitterClientAutodetect) {
    // attempt to autodetect
    UIApplication *application = [UIApplication sharedApplication];
    if([application canOpenURL:[NSURL URLWithString:@"tweetie:///post?message=test"]]) {
      client = kTwitterClientTweetie;
    } else if([application canOpenURL:[NSURL URLWithString:@"twitterfon:///message?test"]]) {
      client = kTwitterClientTwitterFon;
    } else if([application canOpenURL:[NSURL URLWithString:@"twitterrific:///post?message=test"]]) {
      client = kTwitterClientTwitterrific;
    } else if([application canOpenURL:[NSURL URLWithString:@"twit:///post?message=test"]]) {
      client = kTwitterClientTwittelator;
    } else {
      client = kTwitterClientTwitterCom;
    }
  }
  return client;
}

- (NSUserDefaults *)userDefaults {
  if(!userDefaults) {
    userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults retain];
    [userDefaults synchronize];
  }
  return userDefaults;
}

#pragma mark -
#pragma mark Saving

/**
 Performs the save action for the application, which is to send the save:
 message to the application's managed object context.
 */
- (void)save {
  NSError *error;
  if(![[self managedObjectContext] save:&error]) {
		// Handle error
    [FlurryAPI logError:@"Save error"
                message:[NSString stringWithFormat:@"Unresolved error %@, %@", error, [error userInfo]]
              exception:nil];
		exit(-1);  // Fail
  }
}


#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
  if (managedObjectContext != nil) {
    return managedObjectContext;
  }
	
  NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
  if(coordinator != nil) {
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: coordinator];
  }
  
  [managedObjectContext setUndoManager:nil];
  
  return managedObjectContext;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
  if (managedObjectModel != nil) {
    return managedObjectModel;
  }
  managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
  return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
  if (persistentStoreCoordinator != nil) {
    return persistentStoreCoordinator;
  }
	
  NSString *storePath = [self.applicationDocumentsDirectory stringByAppendingPathComponent: @"xkcd.sqlite"];
  TLDebugLog(@"Store path: %@", [storePath stringByReplacingOccurrencesOfString:@" " 
                                                                     withString:@"\\ "]);

  NSFileManager *fileManager = [NSFileManager defaultManager];
  if(![fileManager fileExistsAtPath:storePath]) {
    NSString *bundledPath = [[NSBundle mainBundle] pathForResource:@"xkcd" ofType:@"sqlite"];
    [fileManager copyItemAtPath:bundledPath toPath:storePath error:NULL];
  }
  
  NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
	NSError *error = nil;
  persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
  if(![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                               configuration:nil
                                                         URL:storeUrl
                                                     options:nil
                                                       error:&error]) {
    NSLog(@"Error opening store: %@", error);
  }
	
  return persistentStoreCoordinator;
}

#pragma mark -
#pragma mark Application's documents directory

/**
 Returns the path to the application's documents directory.
 Memo-ized to provide faster delete-all + download-all functionality.
 */
- (NSString *)applicationDocumentsDirectory {
  if(!applicationDocumentsDirectory) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    if(basePath) {
      applicationDocumentsDirectory = basePath;
      [applicationDocumentsDirectory retain];
    }
  }
  return applicationDocumentsDirectory;
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
  [listViewController release];
  listViewController = nil;
  
  [navigationController release];
  navigationController = nil;
  
  [managedObjectContext release];
  managedObjectContext = nil;

  [managedObjectModel release];
  managedObjectModel = nil;

  [persistentStoreCoordinator release];
  persistentStoreCoordinator = nil;
  
  [userDefaults synchronize];
  [userDefaults release];
  userDefaults = nil;
  
	[window release];
	[super dealloc];
}


@end

