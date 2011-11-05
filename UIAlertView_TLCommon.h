//
//  UIAlertView_TLCommon.h
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 9/10/09.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIAlertView (TLCommon)

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;

@end
