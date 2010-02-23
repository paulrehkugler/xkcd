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

+ (NSArray *)allComics; // use sparingly!!
+ (NSArray *)comicsWithImages;
+ (NSArray *)comicsWithoutImages;

+ (Comic *)lastKnownComic; // highest numbered comic that has been fetched

+ (Comic *)comicNumbered:(NSInteger)comicNumber;

- (void)saveImageData:(NSData *)imageData;
- (BOOL)hasBeenDownloaded;
+ (NSEntityDescription *)entityDescription;
- (void)deleteImage;
- (NSString *)websiteURL;

@property(nonatomic, retain, readonly) UIImage *image;
@property(nonatomic, retain, readwrite) NSNumber *loading;
@property(nonatomic, retain, readwrite) NSString *imageURL;
@property(nonatomic, retain, readwrite) NSString *name;
@property(nonatomic, retain, readwrite) NSString *titleText;
@property(nonatomic, retain, readwrite) NSNumber *number;

@end
