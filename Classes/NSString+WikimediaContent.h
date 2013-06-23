//
//  NSString+WikimediaContent.h
//  xkcd
//
//  Created by Stuart McHattie on 23/06/2013.
//
//

#import <Foundation/Foundation.h>

@interface NSString (WikimediaContent)

- (NSString *)htmlStringByEncodingWikimediaContent;

@end
