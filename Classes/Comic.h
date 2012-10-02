//
//  Comic.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/1/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kMinComicNumber 1

@interface Comic : NSManagedObject {
}

+ (Comic *)comic; // use this, not init/etc.

+ (void)deleteAllComics; // for total recreation from scratch
+ (NSArray *)allComics; // use sparingly!!
+ (NSArray *)comicsWithImages;
+ (NSArray *)comicsWithoutImages;

+ (Comic *)lastKnownComic; // highest numbered comic that has been fetched
+ (NSArray *)comicsMissingTranscripts; // transcripts seem to lag, update them

+ (Comic *)comicNumbered:(NSInteger)comicNumber;

- (void)saveImageData:(NSData *)imageData;
- (BOOL)downloaded;
+ (NSEntityDescription *)entityDescription;
- (void)deleteImage;
- (NSString *)websiteURL;
+ (void)synchronizeDownloadedImages;

@property(nonatomic, strong, readonly) UIImage *image;
@property(nonatomic, strong, readwrite) NSNumber *loading;
@property(nonatomic, strong, readwrite) NSString *imageURL;
@property(nonatomic, strong, readwrite) NSString *name;
@property(nonatomic, strong, readwrite) NSString *titleText;
@property(nonatomic, strong, readwrite) NSString *transcript;
@property(nonatomic, strong, readwrite) NSNumber *number;

@end
