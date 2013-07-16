//
//  Comic.m
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/1/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import "Comic.h"
#import "xkcdAppDelegate.h"
#import "NSArray+Filtering.h"
#import "TLMacros.h"

#pragma mark -

#define kAttributeNumber @"number"
#define kAttributeImageURL @"imageURL"
#define kAttributeLoading @"loading"
#define kAttributeName @"name"
#define kAttributeTitleText @"titleText"
#define kAttributeExplanation @"explanation"

#pragma mark -

static NSEntityDescription *comicEntityDescription = nil;
static NSMutableSet *downloadedImages = nil;

#pragma mark -

@interface Comic ()

@property(nonatomic, strong, readonly) NSString *imagePath;
@property(nonatomic, strong, readonly) NSString *imageFilename;

@end

#pragma mark -

@implementation Comic

@dynamic name;
@dynamic titleText;
@dynamic transcript;
@dynamic imageURL;
@dynamic number;
@dynamic loading;
@dynamic explanation;

+ (void)initialize {
  if([self class] == [Comic class]) {
    if(!comicEntityDescription) {
      comicEntityDescription = [NSEntityDescription entityForName:@"Comic" inManagedObjectContext:AppDelegate.managedObjectContext];
    }
  }
}

+ (void)synchronizeDownloadedImages {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSError *error = nil;
  TLDebugLog(@"Starting synchronization of downloaded images");
  NSArray *allDocuments = [fileManager contentsOfDirectoryAtPath:AppDelegate.applicationDocumentsDirectory error:&error];
  if(!error) {
    NSArray *imageDataPaths = [allDocuments objectsPassingTest:^BOOL (id obj) {
      NSString *path = (NSString *)obj;
      return [path hasSuffix:@".imagedata"];
    }];
    downloadedImages = [NSMutableSet setWithArray:imageDataPaths];
    TLDebugLog(@"Synchronized downloaded images: %i images", downloadedImages.count);
  }
}

+ (Comic *)comic {
  Comic *comic = [[Comic alloc] initWithEntity:comicEntityDescription insertIntoManagedObjectContext:AppDelegate.managedObjectContext];
  return comic;
}

+ (Comic *)lastKnownComic {
  NSFetchRequest *request = [[NSFetchRequest alloc] init];
  request.entity = comicEntityDescription;
  request.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:kAttributeNumber ascending:NO]];
  request.fetchLimit = 1;
  
  NSError *error = nil;
  NSArray *array = [AppDelegate.managedObjectContext executeFetchRequest:request error:&error];
  
  Comic *lastKnownComic = nil;
  if(error || !array || array.count == 0) {
    NSLog(@"Couldn't find last comic, error: %@", error);
  } else {
    lastKnownComic = array[0];
  }
  return lastKnownComic;
}

+ (Comic *)comicNumbered:(NSInteger)comicNumber {
  NSFetchRequest *request = [[NSFetchRequest alloc] init];
  request.entity = comicEntityDescription;
  
  request.predicate = [NSPredicate predicateWithFormat:kAttributeNumber @" = %@", @(comicNumber)];
  request.fetchLimit = 1;
  
  NSError *error = nil;
  NSArray *array = [AppDelegate.managedObjectContext executeFetchRequest:request error:&error];
  
  Comic *comic = nil;
  if(error || array.count == 0) {
    NSLog(@"Couldn't find comic numbered %i, error: %@", comicNumber, error);
  } else {
    comic = array[0];
  }
  return comic;
}

+ (NSArray *)allComics {
  NSFetchRequest *request = [[NSFetchRequest alloc] init];
  request.entity = comicEntityDescription;
  request.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:kAttributeNumber ascending:NO]];
  
  NSError *error = nil;
  NSArray *allComics = [AppDelegate.managedObjectContext executeFetchRequest:request error:&error];
  return allComics;
}

+ (NSArray *)comicsWithoutImages {
  NSFetchRequest *request = [[NSFetchRequest alloc] init];
  request.entity = comicEntityDescription;

  // This is pretty lame, but for now, it gets the job down. Someday, fix this ugly hack.
  NSMutableSet *downloadedImageNumbers = [NSMutableSet setWithCapacity:downloadedImages.count];
  for(NSString *downloadedImageFilename in downloadedImages) {
    NSNumber *downloadedImageNumber = @([downloadedImageFilename integerValue]);
    [downloadedImageNumbers addObject:downloadedImageNumber];
  }
  
  request.predicate = [NSPredicate predicateWithFormat:@"NOT (" kAttributeNumber " IN %@)", downloadedImageNumbers];
  request.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:kAttributeNumber ascending:YES]];
  
  NSError *error = nil;
  NSArray *comics = [AppDelegate.managedObjectContext executeFetchRequest:request error:&error];
  return comics;
}

- (void)deleteImage {
  [[self class] deleteDownloadedImage:self.imageFilename];
}

+ (void)deleteAllComics {
  // No need to be efficient, this is only done during development
  for(Comic *comic in [self allComics]) {
    [AppDelegate.managedObjectContext delete:comic];
  }
  [AppDelegate save];
}

- (void)saveImageData:(NSData *)imageData {
  NSString *path = self.imagePath;

  [imageData writeToFile:path atomically:YES];
  [downloadedImages addObject:self.imageFilename];

  // mark as iCloud do-not-backup (since it can be redownloaded as needed)
  NSURL *fileURL = [NSURL fileURLWithPath:path];
  NSError *error = nil;
  [fileURL setResourceValue:@YES
                     forKey:NSURLIsExcludedFromBackupKey
                      error:&error];
  if(error) {
    TLDebugLog(@"Error setting do-not-backup for %@: %@", path, error);
  }
}

+ (NSEntityDescription *)entityDescription {
  return comicEntityDescription;
}

- (NSString *)websiteURL {
  return [NSString stringWithFormat:@"http://xkcd.com/%i", [self.number integerValue]];
}

+ (NSSet *)downloadedImages {
  return [downloadedImages copy];
}

+ (void)deleteDownloadedImage:(NSString *)imageFilename {
  NSString *imagePath = [self imagePathForImageFilename:imageFilename];
  NSLog(@"Deleting %@ (at %@)", imageFilename, imagePath);
  NSError *deleteError = nil;
  [[NSFileManager defaultManager] removeItemAtPath:imagePath error:&deleteError];
  if(!deleteError) {
    [downloadedImages removeObject:imageFilename];
  }
  if(deleteError && ([deleteError code] != NSFileNoSuchFileError)) {
    NSLog(@"Delete fail %@: %@", deleteError, deleteError.userInfo);
  }
}

+ (NSString *)imagePathForImageFilename:(NSString *)imageFilename {
  return [AppDelegate.applicationDocumentsDirectory stringByAppendingPathComponent:imageFilename];
}

#pragma mark -
#pragma mark Properties

- (NSString *)imagePath {
  return [[self class] imagePathForImageFilename:self.imageFilename];
}

- (UIImage *)image {
  return [UIImage imageWithContentsOfFile:self.imagePath];
}

- (NSString *)imageFilename {
  NSInteger comicNumber = [[self valueForKey:kAttributeNumber] integerValue];
  return [NSString stringWithFormat:@"%i.imagedata", comicNumber];
}

- (BOOL)downloaded {
  return [downloadedImages containsObject:self.imageFilename];
}

@end
