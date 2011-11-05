//
//  TLActionSheetController.h
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 11/10/09.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class TLActionSheet;

@interface TLActionSheetController : NSObject<UIActionSheetDelegate> {
@private
  TLActionSheet *actionSheet;
  NSMutableArray *invocations;
}

- (id)initWithTitle:(NSString *)aTitle;

- (void)addButtonWithTitle:(NSString *)aTitle invocation:(NSInvocation *)anInvocation;
- (void)addButtonWithTitle:(NSString *)aTitle target:(id)aTarget action:(SEL)anAction;

- (void)addCancelButton;
- (void)addCancelButtonWithInvocation:(NSInvocation *)anInvocation;
- (void)addCancelButtonWithTarget:(id)aTarget action:(SEL)anAction;

- (void)addCancelButtonWithTitle:(NSString *)aTitle invocation:(NSInvocation *)anInvocation;
- (void)addCancelButtonWithTitle:(NSString *)aTitle target:(id)aTarget action:(SEL)anAction;

- (void)addDestructiveButtonWithTitle:(NSString *)aTitle invocation:(NSInvocation *)anInvocation;
- (void)addDestructiveButtonWithTitle:(NSString *)aTitle target:(id)aTarget action:(SEL)anAction;

- (void)showInView:(UIView *)view;
- (void)showFromTabBar:(UITabBar *)tabBar;
- (void)showFromToolbar:(UIToolbar *)toolbar;

@property(nonatomic, retain, readonly) TLActionSheet *actionSheet;

@end
