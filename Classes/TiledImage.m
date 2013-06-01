//
//  TiledImage.m
//
//  Created by Josh Snyder
//

#import "TiledImage.h"
#import "UIImage+EXIFCompensation.h"
#define TILE_INDEX(xIndex, yIndex) (xIndex + yIndex * self.widthCount);

@interface TiledImage( )

@property (nonatomic, assign, readwrite) NSUInteger widthCount;
@property (nonatomic, assign, readwrite) NSUInteger heightCount;
@property (nonatomic, assign, readwrite) NSUInteger tileWidth;
@property (nonatomic, assign, readwrite) NSUInteger tileHeight;
@property (nonatomic, assign, readwrite) UIImage *sourceImage;
@property (nonatomic, strong, readwrite) NSMutableArray *tiles;

@end

@implementation TiledImage

- (id)initWithImage:(UIImage *)imageToTile tileWidth:(NSUInteger)width tileHeight:(NSUInteger)height {
  if(self = [super init]) {
    self.tileWidth = width;
    self.tileHeight = height;
    CGSize imageSize = imageToTile.exifAgnosticSize;
    NSUInteger imageWidth = round(imageSize.width);
    NSUInteger imageHeight = round(imageSize.height);
    self.widthCount = imageWidth / self.tileWidth + (imageWidth % self.tileWidth == 0 ? 0 : 1);
    self.heightCount = imageHeight / self.tileHeight + (imageHeight % self.tileHeight == 0 ? 0 : 1);
    NSUInteger numberOfTiles = self.widthCount * self.heightCount;
    self.tiles = [[NSMutableArray alloc] initWithCapacity:self.widthCount * self.heightCount];
    for(NSUInteger i = 0; i < numberOfTiles; ++i) {
      [self.tiles addObject:[NSNull null]];
    }
    self.sourceImage = imageToTile;
    // according to the docs, CGImageCreateWithImageInRect retains this anyway...since we're relying on this to do lazy loads of tiles, go ahead and enforce it here as well
  }
  return self;
}

- (UIImage *)imageAtXIndex:(NSUInteger)xIndex YIndex:(NSUInteger)yIndex {
  if(xIndex >= self.widthCount || yIndex >= self.heightCount) {
    NSLog(@"Requested out of bounds image: (%i,%i) doesn't exist -- max is (%i, %i)", xIndex, yIndex, self.widthCount, self.heightCount);
    return nil;
  }
  NSUInteger tileIndex = TILE_INDEX(xIndex, yIndex);
  id currentTile = [self.tiles objectAtIndex:tileIndex];
  if(currentTile != [NSNull null]) {
    // Been loaded already, return it
    return currentTile;
  } else {
    // Load the tile into memory
    CGRect tileRect = CGRectMake(xIndex * self.tileWidth, yIndex * self.tileHeight, self.tileWidth, self.tileHeight);
    CGImageRef tileCGImage = CGImageCreateWithImageInRect(self.sourceImage.CGImage, tileRect);
    UIImage *newTile = [UIImage imageWithCGImage:tileCGImage];
    CFRelease(tileCGImage);
    [self.tiles replaceObjectAtIndex:tileIndex withObject:newTile];
    return newTile;
  }
}

- (NSArray *)allTiles {
  // Cycle over all indices to force loading them into memory, then just return a pointer to tiles
  for(NSUInteger x = 0; x < self.widthCount; ++x) {
    for(NSUInteger y = 0; y < self.heightCount; ++y) {
      [self imageAtXIndex:x YIndex:y];
    }
  }
  return self.tiles;
}

- (void)dealloc {
  self.tiles = nil;

  self.sourceImage = nil;
  
}

@end
