// Extracted and adapted from https://github.com/zoul/Lambda-Alert (MIT license)

#import "LambdaSheet.h"

@interface LambdaSheet () <UIActionSheetDelegate>

@property(strong) UIActionSheet *sheet;
@property(strong) NSMutableArray *blocks;
@property(strong) id keepInMemory;

@end

#pragma mark -

@implementation LambdaSheet

@synthesize sheet;
@synthesize blocks;
@synthesize dismissAction;
@synthesize keepInMemory;

- (id)initWithTitle:(NSString *)title {
  if((self = [super init])) {
    sheet = [[UIActionSheet alloc] initWithTitle:title
                                        delegate:self
                               cancelButtonTitle:nil
                          destructiveButtonTitle:nil
                               otherButtonTitles:nil];
    blocks = [[NSMutableArray alloc] init];
  }
  return self;
}


#pragma mark - Button management

- (void)addButtonWithTitle:(NSString *)title block:(dispatch_block_t)block {
  if(!block) {
    block = ^{};
  }

  [sheet addButtonWithTitle:title];
  dispatch_block_t block_copy = [block copy];
  [blocks addObject:block_copy];
}

- (void)addDestructiveButtonWithTitle:(NSString *)title block:(dispatch_block_t) block {
  [self addButtonWithTitle:title block:block];
  [sheet setDestructiveButtonIndex:sheet.numberOfButtons-1];
}

- (void)addCancelButton {
  [self addCancelButtonWithTitle:NSLocalizedString(@"Cancel", @"Action sheet cancel button")];
}

- (void)addCancelButtonWithTitle:(NSString *)title block:(dispatch_block_t) block {
  [self addButtonWithTitle:title block:block];
  [sheet setCancelButtonIndex:sheet.numberOfButtons-1];
}

- (void)addCancelButtonWithTitle:(NSString *)title {
  [self addCancelButtonWithTitle:title block:NULL];
}

#pragma mark - Display

- (void)showInView:(UIView *)view {
  [sheet showInView:view];
  [self setKeepInMemory:self];
}

- (void)showFromTabBar:(UITabBar *)view {
  [sheet showFromTabBar:view];
  [self setKeepInMemory:self];
}

- (void)showFromToolbar:(UIToolbar *)view {
  [sheet showFromToolbar:view];
  [self setKeepInMemory:self];
}

- (void)showFromBarButtonItem:(UIBarButtonItem *)item {
  [sheet showFromBarButtonItem:item animated:YES];
  [self setKeepInMemory:self];
}

- (void)showFromRect:(CGRect) rect inView:(UIView *)view animated:(BOOL) animated {
  [sheet showFromRect:rect inView:view animated:animated];
  [self setKeepInMemory:self];
}

- (void)dismissAnimated:(BOOL) animated {
  [sheet dismissWithClickedButtonIndex:-1 animated:animated];
}

#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
  NSParameterAssert(actionSheet == sheet);
  if (buttonIndex >= 0 && buttonIndex < [blocks count]) {
    dispatch_block_t block = [blocks objectAtIndex:buttonIndex];
    block();
  }
  if(dismissAction != NULL) {
    dismissAction();
  }
  [self setKeepInMemory:nil];
}

@end
