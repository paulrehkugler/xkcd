//
//  xkcdAppDelegate.m
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 8/25/09.
//  Copyright Treeline Labs 2009. All rights reserved.
//

#import "xkcdAppDelegate.h"
#import "ComicListViewController.h"
#import "NSString_HTML.h"
#import "TLMacros.h"

#define kUserDefaultsRotateKey @"rotate"
#define kUserDefaultsOpenZoomedOutKey @"zoomed_out"
#define kUserDefaultsAutodownloadKey @"autodownload"
#define kUserDefaultsOpenAfterDownloadKey @"autoopen"

#pragma mark -

static NSString *applicationDocumentsDirectory = nil;

#pragma mark -

@interface xkcdAppDelegate ()

@property(nonatomic, strong, readwrite) UINavigationController *navigationController;
@property(nonatomic, strong, readwrite) ComicListViewController *listViewController;
@property(nonatomic, strong, readonly) NSUserDefaults *userDefaults;

@end

#pragma mark -

@implementation xkcdAppDelegate

@synthesize navigationController;
@synthesize listViewController;
@synthesize window;
@dynamic applicationDocumentsDirectory;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.listViewController = [[ComicListViewController alloc] initWithNibName:nil bundle:nil];

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
  }

  self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.listViewController];
  self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
  self.navigationController.toolbar.barStyle = UIBarStyleBlackOpaque;

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

- (NSUserDefaults *)userDefaults {
  if(!userDefaults) {
    userDefaults = [NSUserDefaults standardUserDefaults];
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
  managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];    
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
    if([fileManager fileExistsAtPath:bundledPath]) {
      [fileManager copyItemAtPath:bundledPath toPath:storePath error:NULL];
    }
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
    }
  }
  return applicationDocumentsDirectory;
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
  
  
  managedObjectContext = nil;

  managedObjectModel = nil;

  persistentStoreCoordinator = nil;
  
  [userDefaults synchronize];
  userDefaults = nil;
  
}


@end

