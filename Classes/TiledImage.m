//
//  TiledImage.m
//
//  Created by Josh Snyder
//

#import "TiledImage.h"

#define TILE_INDEX(xIndex, yIndex) (xIndex + yIndex * widthCount);

@implementation TiledImage

@synthesize widthCount, heightCount, tileWidth, tileHeight;

- (id)initWithImage:(UIImage *)imageToTile tileWidth:(NSUInteger)width tileHeight:(NSUInteger)height {
  if(self = [super init]) {
    tileWidth = width;
    tileHeight = height;
    CGSize imageSize = imageToTile.size;
    NSUInteger imageWidth = round(imageSize.width);
    NSUInteger imageHeight = round(imageSize.height);
    widthCount = imageWidth / tileWidth + (imageWidth % tileWidth == 0 ? 0 : 1);
    heightCount = imageHeight / tileHeight + (imageHeight % tileHeight == 0 ? 0 : 1);
    NSUInteger numberOfTiles = widthCount * heightCount;
    tiles = [[NSMutableArray alloc] initWithCapacity:widthCount * heightCount];
    for(NSUInteger i = 0; i < numberOfTiles; ++i) {
      [tiles addObject:[NSNull null]];
    }
    sourceImage = imageToTile;
    // according to the docs, CGImageCreateWithImageInRect retains this anyway...since we're relying on this to do lazy loads of tiles, go ahead and enforce it here as well
    [sourceImage retain];
  }
  return self;
}

- (UIImage *)imageAtXIndex:(NSUInteger)xIndex YIndex:(NSUInteger)yIndex {
  if(xIndex >= widthCount || yIndex >= heightCount) {
    NSLog(@"Requested out of bounds image: (%i,%i) doesn't exist -- max is (%i, %i)", xIndex, yIndex, widthCount, heightCount);
    return nil;
  }
  NSUInteger tileIndex = TILE_INDEX(xIndex, yIndex);
  id currentTile = [tiles objectAtIndex:tileIndex];
  if(currentTile != [NSNull null]) {
    // Been loaded already, return it
    return currentTile;
  } else {
    // Load the tile into memory
    CGRect tileRect = CGRectMake(xIndex * tileWidth, yIndex * tileHeight, tileWidth, tileHeight);
    CGImageRef tileCGImage = CGImageCreateWithImageInRect(sourceImage.CGImage, tileRect);
    UIImage *newTile = [UIImage imageWithCGImage:tileCGImage];
    CFRelease(tileCGImage);
    [tiles replaceObjectAtIndex:tileIndex withObject:newTile];
    return newTile;
  }
}

- (NSArray *)allTiles {
  // Cycle over all indices to force loading them into memory, then just return a pointer to tiles
  for(NSUInteger x = 0; x < widthCount; ++x) {
    for(NSUInteger y = 0; y < heightCount; ++y) {
      [self imageAtXIndex:x YIndex:y];
    }
  }
  return tiles;
}

- (void)dealloc {
  [tiles release];
  tiles = nil;

  [sourceImage release];
  sourceImage = nil;
  
  [super dealloc];
}

@end
