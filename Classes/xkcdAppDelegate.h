//
//  xkcdAppDelegate.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 8/25/09.
//  Copyright Treeline Labs 2009. All rights reserved.
//

#define GENERATE_DEFAULT_PNG 0

#define AppDelegate ((xkcdAppDelegate *)[UIApplication sharedApplication].delegate)
#define kUseragent @"xkcd iPhone app (josh@treelinelabs.com; http://bit.ly/rZtDq). I can haz API?"

#define kTwitterClientAutodetect 0
#define kTwitterClientTwitterCom 1
#define kTwitterClientTweetie 2
#define kTwitterClientTwitterFon 3
#define kTwitterClientTwitterrific 4
#define kTwitterClientTwittelator 5

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
- (NSInteger)twitterClient;

@property(nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property(nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property(nonatomic, readonly) NSString *applicationDocumentsDirectory;

@property(nonatomic, retain) IBOutlet UIWindow *window;

@end

