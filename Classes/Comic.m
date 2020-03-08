//
//  Comic.m
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/1/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import "Comic.h"
#import "NSArray+Filtering.h"
#import "TLMacros.h"
#import "xkcd-Swift.h"

#pragma mark -

#define kAttributeNumber @"number"
#define kAttributeImageURL @"imageURL"
#define kAttributeLoading @"loading"
#define kAttributeName @"name"
#define kAttributeTitleText @"titleText"

#pragma mark -

static NSEntityDescription *comicEntityDescription = nil;
static NSMutableSet *downloadedImages = nil;

#pragma mark -

@interface Comic ()

@property (nonatomic, readonly) NSString *imagePath;
@property (nonatomic, readonly) NSString *imageFilename;

@end

#pragma mark -

@implementation Comic

@dynamic name;
@dynamic titleText;
@dynamic transcript;
@dynamic imageURL;
@dynamic number;
@dynamic loading;
@dynamic link;

+ (void)initialize {
	if ([self class] == [Comic class]) {
		if (!comicEntityDescription) {
			comicEntityDescription = [NSEntityDescription entityForName:@"Comic" inManagedObjectContext:[CoreDataStack sharedCoreDataStack].managedObjectContext];
		}
	}
}

+ (void)synchronizeDownloadedImages {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error = nil;
	TLDebugLog(@"Starting synchronization of downloaded images");
	NSArray *allDocuments = [fileManager contentsOfDirectoryAtPath:[CoreDataStack sharedCoreDataStack].applicationsDocumentsDirectory error:&error];
	if (!error) {
		NSArray *imageDataPaths = [allDocuments objectsPassingTest:^BOOL (id obj) {
			NSString *path = (NSString *)obj;
			return [path hasSuffix:@".imagedata"];
		}];
		downloadedImages = [NSMutableSet setWithArray:imageDataPaths];
		TLDebugLog(@"Synchronized downloaded images: %lu images", downloadedImages.count);
	}
}

+ (Comic *)comic {
	Comic *comic = [[Comic alloc] initWithEntity:comicEntityDescription insertIntoManagedObjectContext:[CoreDataStack sharedCoreDataStack].managedObjectContext];
	return comic;
}

+ (Comic *)lastKnownComic {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	request.entity = comicEntityDescription;
	request.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:kAttributeNumber ascending:NO]];
	request.fetchLimit = 1;
	
	NSError *error = nil;
    CoreDataStack *coreDataStack = [CoreDataStack sharedCoreDataStack];
	NSArray *array = [coreDataStack.managedObjectContext executeFetchRequest:request error:&error];
	
	Comic *lastKnownComic = nil;
	if (error || !array || array.count == 0) {
		NSLog(@"Couldn't find last comic, error: %@", error);
	}
	else {
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
	NSArray *array = [[CoreDataStack sharedCoreDataStack].managedObjectContext executeFetchRequest:request error:&error];
	
	Comic *comic = nil;
	if (error || array.count == 0) {
		NSLog(@"Couldn't find comic numbered %li, error: %@", (long)comicNumber, error);
	}
	else {
		comic = array[0];
	}
	return comic;
}

+ (NSArray *)allComics {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	request.entity = comicEntityDescription;
	request.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:kAttributeNumber ascending:NO]];
	
	NSError *error = nil;
	NSArray *allComics = [[CoreDataStack sharedCoreDataStack].managedObjectContext executeFetchRequest:request error:&error];
	return allComics;
}

+ (NSArray *)comicsWithoutImages {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	request.entity = comicEntityDescription;
	
	// This is pretty lame, but for now, it gets the job down. Someday, fix this ugly hack.
	NSMutableSet *downloadedImageNumbers = [NSMutableSet setWithCapacity:downloadedImages.count];
	for (NSString *downloadedImageFilename in downloadedImages) {
		NSNumber *downloadedImageNumber = @([downloadedImageFilename integerValue]);
		[downloadedImageNumbers addObject:downloadedImageNumber];
	}
	
	request.predicate = [NSPredicate predicateWithFormat:@"NOT (" kAttributeNumber " IN %@)", downloadedImageNumbers];
	request.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:kAttributeNumber ascending:YES]];
	
	NSError *error = nil;
	NSArray *comics = [[CoreDataStack sharedCoreDataStack].managedObjectContext executeFetchRequest:request error:&error];
	return comics;
}

- (void)deleteImage {
	[[self class] deleteDownloadedImage:self.imageFilename];
}

+ (void)deleteAllComics {
	// No need to be efficient, this is only done during development
	for (Comic *comic in [self allComics]) {
		[[CoreDataStack sharedCoreDataStack].managedObjectContext deleteObject:comic];
	}
	[[CoreDataStack sharedCoreDataStack] save];
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
	if (error) {
		TLDebugLog(@"Error setting do-not-backup for %@: %@", path, error);
	}
}

+ (NSEntityDescription *)entityDescription {
	return comicEntityDescription;
}

- (NSString *)websiteURL {
	return [NSString stringWithFormat:@"http://xkcd.com/%li", (long)[self.number integerValue]];
}

+ (NSSet *)downloadedImages {
	return [downloadedImages copy];
}

+ (void)deleteDownloadedImage:(NSString *)imageFilename {
	NSString *imagePath = [self imagePathForImageFilename:imageFilename];
	NSLog(@"Deleting %@ (at %@)", imageFilename, imagePath);
	NSError *deleteError = nil;
	[[NSFileManager defaultManager] removeItemAtPath:imagePath error:&deleteError];
	if (!deleteError) {
		[downloadedImages removeObject:imageFilename];
	}
	if (deleteError && ([deleteError code] != NSFileNoSuchFileError)) {
		NSLog(@"Delete fail %@: %@", deleteError, deleteError.userInfo);
	}
}

+ (NSString *)imagePathForImageFilename:(NSString *)imageFilename {
	return [[CoreDataStack sharedCoreDataStack].applicationsDocumentsDirectory stringByAppendingPathComponent:imageFilename];
}

+ (BOOL)hasLargeImage:(Comic *)comic {
    // I have this hardcoded list here because these are the comics that are known to have large images.
    // Because I'm doing the CoreData migration to support the link attribute long after these comics were published,
    // checking the link attribute won't work. Most users will already have these images downloaded, but some may clear
    // out their images and redownload all of them (because I added support for large images and 2x images).
    NSArray<NSNumber *> *comicsThatHaveLargeImages = @[@1970, @1939, @1688, @1509, @1491, @1461, @1407, @1392, @1389, @1298, @1256, @1212,
                                                      @1196, @1127, @1080, @1079, @1071, @1040, @1000, @930, @850, @832, @802, @681, @657];
    if ([comicsThatHaveLargeImages containsObject:comic.number]) {
        return true;
    } else if (comic.link) {
        // All of the links for large images seem to end with _large or /large. If this comic has a link like that, we will guess at a large image
        // url and try to download it. (See: FetchComicImageFromWeb)
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\b.+([_/]large/)\\b" options:0 error:nil];
        return [regex numberOfMatchesInString:comic.link options:0 range:NSMakeRange(0, comic.link.length)] > 0;
    }
    
    return NO;
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
	return [NSString stringWithFormat:@"%li.imagedata", (long)comicNumber];
}

- (BOOL)downloaded {
	return [downloadedImages containsObject:self.imageFilename];
}

@end
