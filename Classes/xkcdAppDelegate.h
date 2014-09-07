//
//  xkcdAppDelegate.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 8/25/09.
//  Copyright Treeline Labs 2009. All rights reserved.
//

#define GENERATE_DEFAULT_PNG 0

#define AppDelegate ((xkcdAppDelegate *)[UIApplication sharedApplication].delegate)

extern NSString * const UserAgent;

@class ComicListViewController;

@interface xkcdAppDelegate : NSObject<UIApplicationDelegate>

- (void)save;

- (BOOL)rotate;
- (BOOL)downloadNewComics;
- (BOOL)openZoomedOut;
- (BOOL)openAfterDownload;

@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSString *)applicationDocumentsDirectory;

@property (nonatomic) IBOutlet UIWindow *window;

@end

