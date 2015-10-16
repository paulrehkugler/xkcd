//
//  TiledImage.h
//
//  Created by Josh Snyder
//

#import <Foundation/Foundation.h>

@interface TiledImage : NSObject

- (instancetype)initWithImage:(UIImage *)imageToTile tileWidth:(NSUInteger)width tileHeight:(NSUInteger)height;
- (UIImage *)imageAtXIndex:(NSUInteger)xIndex YIndex:(NSUInteger)yIndex;

@property (nonatomic, readonly) NSUInteger widthCount;
@property (nonatomic, readonly) NSUInteger heightCount;
@property (nonatomic, readonly) NSUInteger tileWidth;
@property (nonatomic, readonly) NSUInteger tileHeight;
@property (nonatomic, readonly) NSArray *allTiles; // a little expensive, use sparingly

@end
