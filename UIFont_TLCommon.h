//
//  UIFont_TLCommon.h
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 10/11/09.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// stupid, you say? well, it makes autocomplete work! and i am that lazy. and it prevents string typos,
// which a compiler won't catch...and i never remember the "oblique/italics" thing...

@interface UIFont (TLCommon)

+ (UIFont *)helveticaWithSize:(CGFloat)size;
+ (UIFont *)helveticaBoldWithSize:(CGFloat)size;
+ (UIFont *)helveticaItalicWithSize:(CGFloat)size;
+ (UIFont *)helveticaBoldItalicWithSize:(CGFloat)size;

@end
