//
//  Comic.m
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/1/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import "Comic.h"
#import "NSArray+Filtering.h"
#import "NSMutableArray+Safety.h"
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

+ (BOOL)hasLinkedToImage:(Comic *)comic {
    // I have this hardcoded list here because these are the comics that are known to have image URLs in their link field.
    // Because I'm doing the CoreData migration to support the link attribute long after these comics were published,
    // checking the link attribute won't work. Most users will already have these images downloaded, but some may clear
    // out their images and redownload all of them (because I added support for huge images, large images, and 2x images).
    NSArray<NSNumber *> *comicsThatHaveLinkedToImages = @[@273, @256];
    
    if ([comicsThatHaveLinkedToImages containsObject:comic.number]) {
        return YES;
    } else if (comic.link) {
        // All of the links for linked-to images seem to end with .png. If this comic has a link like that, we will use that URL
        // to try to download it. (See: -imageURLs computed property below)
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\b.+(\\.png)\\b" options:0 error:nil];
        return [regex numberOfMatchesInString:comic.link options:0 range:NSMakeRange(0, comic.link.length)] > 0;
    }
    
    return NO;
}

+ (BOOL)potentiallyHasHugeImage:(Comic *)comic {
    // I have this hardcoded list here because these are the comics that are known to have huge images.
    // Because I'm doing the CoreData migration to support the link attribute long after these comics were published,
    // checking the link attribute won't work. Most users will already have these images downloaded, but some may clear
    // out their images and redownload all of them (because I added support for huge images, large images, and 2x images).
    NSArray<NSNumber *> *comicsThatHaveHugeImages = @[@980];
    if ([comicsThatHaveHugeImages containsObject:comic.number]) {
        return YES;
    } else if (comic.link) {
        // All of the links for huge images seem to end with /huge. If this comic has a link like that, we will guess at a huge image
        // url and try to download it. (See: -imageURLs computed property below)
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\b.+(/huge/)\\b" options:0 error:nil];
        return [regex numberOfMatchesInString:comic.link options:0 range:NSMakeRange(0, comic.link.length)] > 0;
    }
    
    return NO;
}

+ (BOOL)potentiallyHasLargeImage:(Comic *)comic {
    // I have this hardcoded list here because these are the comics that are known to have large images.
    // Because I'm doing the CoreData migration to support the link attribute long after these comics were published,
    // checking the link attribute won't work. Most users will already have these images downloaded, but some may clear
    // out their images and redownload all of them (because I added support for large images and 2x images).
    NSArray<NSNumber *> *comicsThatHaveLargeImages = @[@1970, @1939, @1688, @1509, @1491, @1461, @1407, @1392, @1389, @1298, @1256, @1212,
                                                      @1196, @1127, @1080, @1079, @1071, @1040, @1000, @930, @850, @832, @802, @681, @657];
    if ([comicsThatHaveLargeImages containsObject:comic.number]) {
        return YES;
    } else if (comic.link) {
        // All of the links for large images seem to end with _large or /large. If this comic has a link like that, we will guess at a large image
        // url and try to download it. (See: -imageURLs computed property below)
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\b.+([_/]large/)\\b" options:0 error:nil];
        return [regex numberOfMatchesInString:comic.link options:0 range:NSMakeRange(0, comic.link.length)] > 0;
    }
    
    return NO;
}

+ (BOOL)potentiallyHasRetinaImage:(Comic *)comic {
    NSUInteger comicNumber = comic.number.unsignedIntegerValue;
    // https://xkcd.com/1053/ is the first comic that shows up with a retina version
    return comicNumber >= 1053
        // these comics don't work via the API at all, so don't bother trying to download the retina image
        && comicNumber != 1663 // https://xkcd.com/1663/
        && comicNumber != 1608; // https://xkcd.com/1608/
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

- (NSURL *)linkedToImageURL {
    if (self.link) {
        return [[NSURL alloc] initWithString:self.link];
    }
    // These two cases are hardcoded for people that downloaded the comic before link was parsed into CoreData.
    else if ([self.number isEqualToNumber:@273]) {
        return [[NSURL alloc] initWithString:@"https://imgs.xkcd.com/comics/electromagnetic_spectrum.png"];
    }
    else if ([self.number isEqualToNumber:@256]) {
        return [[NSURL alloc] initWithString:@"https://imgs.xkcd.com/comics/online_communities.png"];
    }
    
    return nil;
}

- (NSURL *)potentialHugeImageURL {
    NSString *originalImageURL = self.imageURL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\b(.+)(\\.\\w+)\\b" options:0 error:nil];

    // This takes URLs that look like https://imgs.xkcd.com/comics/money.png and converts them to https://imgs.xkcd.com/comics/money_huge.png
    NSString *potentialLargeImageURLString = [regex stringByReplacingMatchesInString:originalImageURL options:0 range:NSMakeRange(0, originalImageURL.length) withTemplate:@"$1_huge$2"];
    return [[NSURL alloc] initWithString:potentialLargeImageURLString];
}

- (NSURL *)potentialLargeImageURL {
    NSString *originalImageURL = self.imageURL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\b(.+)(\\.\\w+)\\b" options:0 error:nil];

    // This takes URLs that look like https://imgs.xkcd.com/comics/movie_narrative_charts.png and converts them to https://imgs.xkcd.com/comics/movie_narrative_charts_large.png
    NSString *potentialLargeImageURLString = [regex stringByReplacingMatchesInString:originalImageURL options:0 range:NSMakeRange(0, originalImageURL.length) withTemplate:@"$1_large$2"];
    return [[NSURL alloc] initWithString:potentialLargeImageURLString];
}

- (NSURL *)potentialRetinaImageURL {
    NSString *originalImageURL = self.imageURL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\b(.+)(\\.\\w+)\\b" options:0 error:nil];
    
    // This takes URLs that look like https://imgs.xkcd.com/comics/business_greetings.png and converts them to https://imgs.xkcd.com/comics/business_greetings_2x.png
    NSString *potentialRetinaImageURLString = [regex stringByReplacingMatchesInString:originalImageURL options:0 range:NSMakeRange(0, originalImageURL.length) withTemplate:@"$1_2x$2"];
    return [[NSURL alloc] initWithString:potentialRetinaImageURLString];
}

- (NSArray<NSURL *> *)imageURLs {
    if (!self.imageURL) {
        return nil;
    }
    
    NSMutableArray<NSURL *> *imageURLs = [[NSMutableArray alloc] init];
    
    if ([Comic hasLinkedToImage:self]) {
        [imageURLs safelyAddObject:self.linkedToImageURL];
    }
    
    if ([Comic potentiallyHasHugeImage:self]) {
        [imageURLs safelyAddObject:[self potentialHugeImageURL]];
    }
    
    if ([Comic potentiallyHasLargeImage:self]) {
        [imageURLs safelyAddObject:[self potentialLargeImageURL]];
    }
    
    if ([Comic potentiallyHasRetinaImage:self]) {
        [imageURLs safelyAddObject:[self potentialRetinaImageURL]];
    }
    
    [imageURLs addObject:[[NSURL alloc] initWithString:self.imageURL]];
    
    return [imageURLs copy];
}

@end
