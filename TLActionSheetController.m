//
//  TLActionSheetController.m
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 11/10/09.
//

#import "TLActionSheetController.h"
#import "TLActionSheet.h"


#pragma mark -

@interface TLActionSheetController ()

- (NSInvocation *)invocationForTarget:(id)target action:(SEL)action;

@property(nonatomic, retain, readwrite) TLActionSheet *actionSheet;
@property(nonatomic, retain, readwrite) NSMutableArray *invocations;

@end


#pragma mark -

@implementation TLActionSheetController

@synthesize actionSheet;
@synthesize invocations;

#pragma mark -
#pragma mark Lifecycle

- (id)initWithTitle:(NSString *)title {
  if(self = [super init]) {
    self.actionSheet = [[[TLActionSheet alloc] initWithTitle:title
                                                    delegate:self
                                           cancelButtonTitle:nil
                                      destructiveButtonTitle:nil
                                           otherButtonTitles:nil]
                        autorelease];
    self.actionSheet.delegate = self;
    self.invocations = [NSMutableArray array];
  }
  return self;
}

- (void)dealloc {
  actionSheet.delegate = nil;
  [actionSheet release];
  actionSheet = nil;
  
  [invocations release];
  invocations = nil;
  
  [super dealloc];
}

#pragma mark -
#pragma mark Add buttons

- (NSInvocation *)invocationForTarget:(id)target action:(SEL)action {
  NSInvocation *invocation = nil;
  if(target && action) {
    NSMethodSignature *methodSignature = [target methodSignatureForSelector:action];
    invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setTarget:target];
    [invocation setSelector:action];
    NSAssert1([methodSignature numberOfArguments] < 4, @"TLActionSheetController was given a target/action pair whose selector (%@) requires two or more arguments", NSStringFromSelector(action));
    if([methodSignature numberOfArguments] == 1) {
      [invocation setArgument:&self atIndex:2];
    }
  }
  return invocation;
}

- (void)addButtonWithTitle:(NSString *)aTitle invocation:(NSInvocation *)anInvocation {
  [self.actionSheet addButtonWithTitle:aTitle];
  id invocation = anInvocation;
  if(!invocation) {
    invocation = [NSNull null];
  }
  [self.invocations addObject:invocation];
}

- (void)addButtonWithTitle:(NSString *)aTitle target:(id)aTarget action:(SEL)anAction {
  [self addButtonWithTitle:aTitle
                invocation:[self invocationForTarget:aTarget
                                              action:anAction]];
}

- (void)addCancelButton {
  [self addCancelButtonWithInvocation:nil];
}

- (void)addCancelButtonWithInvocation:(NSInvocation *)anInvocation {
  [self addCancelButtonWithTitle:NSLocalizedString(@"Cancel", @"Action sheet title")
                      invocation:anInvocation];
}

- (void)addCancelButtonWithTarget:(id)aTarget action:(SEL)anAction {
  [self addCancelButtonWithInvocation:[self invocationForTarget:aTarget action:anAction]];
}


- (void)addCancelButtonWithTitle:(NSString *)aTitle invocation:(NSInvocation *)anInvocation {
  [self addButtonWithTitle:aTitle invocation:anInvocation];
  self.actionSheet.cancelButtonIndex = self.actionSheet.numberOfButtons - 1;
}

- (void)addCancelButtonWithTitle:(NSString *)aTitle target:(id)aTarget action:(SEL)anAction {
  [self addCancelButtonWithTitle:aTitle
                      invocation:[self invocationForTarget:aTarget
                                                    action:anAction]];  
}

- (void)addDestructiveButtonWithTitle:(NSString *)aTitle invocation:(NSInvocation *)anInvocation {
  [self addButtonWithTitle:aTitle invocation:anInvocation];
  self.actionSheet.destructiveButtonIndex = self.actionSheet.numberOfButtons - 1;
}

- (void)addDestructiveButtonWithTitle:(NSString *)aTitle target:(id)aTarget action:(SEL)anAction {
  [self addDestructiveButtonWithTitle:aTitle
                           invocation:[self invocationForTarget:aTarget
                                                         action:anAction]];    
}

#pragma mark -
#pragma mark Show

- (void)showInView:(UIView *)view {
  [self.actionSheet showInView:view];
  // Ensure that the delegate (that's us) survives until the sheet is dismissed
  [self retain];
}

- (void)showFromTabBar:(UITabBar *)tabBar {
  [self.actionSheet showFromTabBar:tabBar];
  // Ensure that the delegate (that's us) survives until the sheet is dismissed
  [self retain];
}

- (void)showFromToolbar:(UIToolbar *)toolbar {
  [self.actionSheet showFromToolbar:toolbar];
  // Ensure that the delegate (that's us) survives until the sheet is dismissed
  [self retain];
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)clickedActionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  // Make sure this was headed to the right place
  if(![clickedActionSheet isEqual:self.actionSheet]) {
    return;
  }
  
  if(buttonIndex >= 0 && buttonIndex < [self.invocations count]) {
    NSInvocation *invocation = [self.invocations objectAtIndex:buttonIndex];
    if(![invocation isEqual:[NSNull null]]) {
      [invocation invoke];
    }
  }
  
  // Sheet to be dismissed, drop our self retain
  [self autorelease];
}

@end
