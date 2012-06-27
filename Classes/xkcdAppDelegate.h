//
//  xkcdAppDelegate.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 8/25/09.
//  Copyright Treeline Labs 2009. All rights reserved.
//

#define GENERATE_DEFAULT_PNG 0

#define AppDelegate ((xkcdAppDelegate *)[UIApplication sharedApplication].delegate)
#define kUseragent @"xkcd iPhone app (josh@treelinelabs.com; http://bit.ly/xkcdapp). Thank you for the API!"

@class ComicListViewController;

@interface xkcdAppDelegate : NSObject<UIApplicationDelegate> {
  UINavigationController *navigationController;
  ComicListViewController *listViewController;
  
  NSManagedObjectModel *managedObjectModel;
  NSManagedObjectContext *managedObjectContext;	    
  NSPersistentStoreCoordinator *persistentStoreCoordinator;
  
  NSUserDefaults *userDefaults;
  
  UIWindow *window;
}

- (void)save;

- (BOOL)rotate;
- (BOOL)downloadNewComics;
- (BOOL)openZoomedOut;
- (BOOL)openAfterDownload;

@property(nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property(nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSString *)applicationDocumentsDirectory;

@property(nonatomic, strong) IBOutlet UIWindow *window;

@end

