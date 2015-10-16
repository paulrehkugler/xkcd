//
//  TiledImage.m
//
//  Created by Josh Snyder
//

#import "TiledImage.h"
#import "UIImage+EXIFCompensation.h"
#define TILE_INDEX(xIndex, yIndex) (xIndex + yIndex * self.widthCount);

@interface TiledImage( )

@property (nonatomic) NSUInteger widthCount;
@property (nonatomic) NSUInteger heightCount;
@property (nonatomic) NSUInteger tileWidth;
@property (nonatomic) NSUInteger tileHeight;
@property (nonatomic) UIImage *sourceImage;
@property (nonatomic) NSMutableArray *tiles;

@end

@implementation TiledImage

- (instancetype)initWithImage:(UIImage *)imageToTile tileWidth:(NSUInteger)width tileHeight:(NSUInteger)height {
	if (self = [super init]) {
		_tileWidth = width;
		_tileHeight = height;
		CGSize imageSize = imageToTile.exifAgnosticSize;
		NSUInteger imageWidth = round(imageSize.width);
		NSUInteger imageHeight = round(imageSize.height);
		_widthCount = imageWidth / _tileWidth + (imageWidth % _tileWidth == 0 ? 0 : 1);
		_heightCount = imageHeight / _tileHeight + (imageHeight % _tileHeight == 0 ? 0 : 1);
		NSUInteger numberOfTiles = _widthCount * _heightCount;
		_tiles = [[NSMutableArray alloc] initWithCapacity:_widthCount * _heightCount];
		for (NSUInteger i = 0; i < numberOfTiles; ++i) {
			[_tiles addObject:[NSNull null]];
		}
		_sourceImage = imageToTile;
		// according to the docs, CGImageCreateWithImageInRect retains this anyway...since we're relying on this to do lazy loads of tiles, go ahead and enforce it here as well
	}
	return self;
}

- (UIImage *)imageAtXIndex:(NSUInteger)xIndex YIndex:(NSUInteger)yIndex {
	if (xIndex >= self.widthCount || yIndex >= self.heightCount) {
		NSLog(@"Requested out of bounds image: (%lu,%lu) doesn't exist -- max is (%lu, %lu)", (unsigned long)xIndex, (unsigned long)yIndex, (unsigned long)self.widthCount, (unsigned long)self.heightCount);
		return nil;
	}
	NSUInteger tileIndex = TILE_INDEX(xIndex, yIndex);
	id currentTile = (self.tiles)[tileIndex];
	if (currentTile != [NSNull null]) {
		// Been loaded already, return it
		return currentTile;
	}
	else {
		// Load the tile into memory
		CGRect tileRect = CGRectMake(xIndex * self.tileWidth, yIndex * self.tileHeight, self.tileWidth, self.tileHeight);
		CGImageRef tileCGImage = CGImageCreateWithImageInRect(self.sourceImage.CGImage, tileRect);
		UIImage *newTile = [UIImage imageWithCGImage:tileCGImage];
		CFRelease(tileCGImage);
		(self.tiles)[tileIndex] = newTile;
		return newTile;
	}
}

- (NSArray *)allTiles {
	// Cycle over all indices to force loading them into memory, then just return a pointer to tiles
	for (NSUInteger x = 0; x < self.widthCount; ++x) {
		for (NSUInteger y = 0; y < self.heightCount; ++y) {
			[self imageAtXIndex:x YIndex:y];
		}
	}
	return self.tiles;
}

@end
