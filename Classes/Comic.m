//
//  Comic.m
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/1/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import "Comic.h"
#import "xkcdAppDelegate.h"
#import "FlurryAPI.h"

#pragma mark -

#define kAttributeNumber @"number"
#define kAttributeImageURL @"imageURL"
#define kAttributeLoading @"loading"
#define kAttributeName @"name"
#define kAttributeDownloaded @"downloaded"
#define kAttributeTitleText @"titleText"

#pragma mark -

static NSEntityDescription *comicEntityDescription = nil;

#pragma mark -

@interface Comic ()

- (NSString *)imagePath;

@property(nonatomic, retain, readwrite) NSNumber *downloaded;

@end

#pragma mark -

@implementation Comic

@dynamic name;
@dynamic titleText;
@dynamic imageURL;
@dynamic downloaded;
@dynamic number;
@dynamic loading;

+ (void)initialize {
  if([self class] == [Comic class]) {
    if(!comicEntityDescription) {
      comicEntityDescription = [NSEntityDescription entityForName:@"Comic" inManagedObjectContext:AppDelegate.managedObjectContext];
      [comicEntityDescription retain];
    }
  }
}

+ (Comic *)comic {
  Comic *comic = [[[Comic alloc] initWithEntity:comicEntityDescription insertIntoManagedObjectContext:AppDelegate.managedObjectContext] autorelease];
  comic.downloaded = [NSNumber numberWithBool:NO];
  return comic;
}

+ (Comic *)lastKnownComic {
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:comicEntityDescription];
  
  NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:kAttributeNumber ascending:NO] autorelease];
  NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
  [request setSortDescriptors:sortDescriptors];
  
  [request setFetchLimit:1];
  
  NSError *error = nil;
  NSArray *array = [AppDelegate.managedObjectContext executeFetchRequest:request error:&error];
  
  Comic *lastKnownComic = nil;
  if(error || !array || [array count] == 0) {
    [FlurryAPI logError:@"Fetch fail" message:[NSString stringWithFormat:@"Couldn't find last comic, error: %@", error] exception:nil];
  } else {
    lastKnownComic = [array objectAtIndex:0];
  }
  return lastKnownComic;
}

+ (Comic *)comicNumbered:(NSInteger)comicNumber {
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:comicEntityDescription];
  
  NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:kAttributeNumber @" = %@", [NSNumber numberWithInteger:comicNumber]];
  request.predicate = searchPredicate;

  [request setFetchLimit:1];
  
  NSError *error = nil;
  NSArray *array = [AppDelegate.managedObjectContext executeFetchRequest:request error:&error];
  
  Comic *comic = nil;
  if(error || !array || [array count] == 0) {
    [FlurryAPI logError:@"Fetch fail"
                message:[NSString stringWithFormat:@"Couldn't find comic numbered %i, error: %@", comicNumber, error]
              exception:nil];
  } else {
    comic = [array objectAtIndex:0];
  }
  return comic;
}

+ (NSArray *)allComics {
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:comicEntityDescription];

  NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:kAttributeNumber ascending:NO] autorelease];
  NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
  [request setSortDescriptors:sortDescriptors];
  
  NSError *error = nil;
  NSArray *allComics = [AppDelegate.managedObjectContext executeFetchRequest:request
                                                                   error:&error];
  
  return allComics;
}

+ (NSArray *)comicsWithImages {
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:comicEntityDescription];
  
  NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:kAttributeDownloaded @" = %@", [NSNumber numberWithBool:YES]];
  request.predicate = searchPredicate;

  NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:kAttributeNumber ascending:YES] autorelease];
  NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
  [request setSortDescriptors:sortDescriptors];
  
  NSError *error = nil;
  NSArray *comics = [AppDelegate.managedObjectContext executeFetchRequest:request
                                                                    error:&error];
  
  return comics;
}

+ (NSArray *)comicsWithoutImages {
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:comicEntityDescription];
  
  NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:kAttributeDownloaded @" = %@", [NSNumber numberWithBool:NO]];
  request.predicate = searchPredicate;
  
  NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:kAttributeNumber ascending:YES] autorelease];
  NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
  [request setSortDescriptors:sortDescriptors];
  
  NSError *error = nil;
  NSArray *comics = [AppDelegate.managedObjectContext executeFetchRequest:request
                                                                    error:&error];
  
  return comics;  
}

- (void)deleteImage {
  NSError *deleteError = nil;
  [[NSFileManager defaultManager] removeItemAtPath:self.imagePath
                                             error:&deleteError];
  if(deleteError && ([deleteError code] != NSFileNoSuchFileError)) {
    [FlurryAPI logError:@"Delete fail"
                message:[NSString stringWithFormat:@"Error %@: %@", deleteError, deleteError.userInfo]
              exception:nil];
  }
  self.downloaded = [NSNumber numberWithBool:NO];
}

- (void)saveImageData:(NSData *)imageData {
  [imageData writeToFile:self.imagePath atomically:YES];
  self.downloaded = [NSNumber numberWithBool:YES];
}

+ (NSEntityDescription *)entityDescription {
  return comicEntityDescription;
}

- (NSString *)websiteURL {
  return [NSString stringWithFormat:@"http://xkcd.com/%i", [self.number integerValue]];
}

#pragma mark -
#pragma mark Properties

- (NSString *)imagePath {
  NSInteger comicNumber = [[self valueForKey:kAttributeNumber] integerValue];
  return [AppDelegate.applicationDocumentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%i.imagedata", comicNumber]];  
}

- (UIImage *)image {
  return [UIImage imageWithContentsOfFile:self.imagePath];
}

- (BOOL)hasBeenDownloaded {
  NSNumber *storedDownloadedValue = [self valueForKey:kAttributeDownloaded];
  BOOL hasBeenDownloaded;
  if(storedDownloadedValue == nil) {
    // First time -- check on disk, and then store that for the future
    NSFileManager *fileManager = [NSFileManager defaultManager];
    hasBeenDownloaded = [fileManager fileExistsAtPath:self.imagePath];
    self.downloaded = [NSNumber numberWithBool:hasBeenDownloaded];
  } else {
    hasBeenDownloaded = [storedDownloadedValue boolValue];
  }
  return hasBeenDownloaded;
}

@end
