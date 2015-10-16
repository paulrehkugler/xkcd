// Extracted and adapted from https://github.com/zoul/Lambda-Alert (MIT license)

#import "LambdaSheet.h"

@interface LambdaSheet () <UIActionSheetDelegate>

@property (nonatomic) UIActionSheet *sheet;
@property (nonatomic) NSMutableArray *blocks;
@property (nonatomic) id keepInMemory;

@end

#pragma mark -

@implementation LambdaSheet

- (instancetype)initWithTitle:(NSString *)title {
	if((self = [super init])) {
		_sheet = [[UIActionSheet alloc] initWithTitle:title
											 delegate:self
									cancelButtonTitle:nil
							   destructiveButtonTitle:nil
									otherButtonTitles:nil];
		_blocks = [[NSMutableArray alloc] init];
	}
	return self;
}


#pragma mark - Button management

- (void)addButtonWithTitle:(NSString *)title block:(dispatch_block_t)block {
	if(!block) {
		block = ^{};
	}
	
	[self.sheet addButtonWithTitle:title];
	dispatch_block_t block_copy = [block copy];
	[self.blocks addObject:block_copy];
}

- (void)addDestructiveButtonWithTitle:(NSString *)title block:(dispatch_block_t) block {
	[self addButtonWithTitle:title block:block];
	[self.sheet setDestructiveButtonIndex:self.sheet.numberOfButtons-1];
}

- (void)addCancelButton {
	[self addCancelButtonWithTitle:NSLocalizedString(@"Cancel", @"Action sheet cancel button")];
}

- (void)addCancelButtonWithTitle:(NSString *)title block:(dispatch_block_t) block {
	[self addButtonWithTitle:title block:block];
	[self.sheet setCancelButtonIndex:self.sheet.numberOfButtons-1];
}

- (void)addCancelButtonWithTitle:(NSString *)title {
	[self addCancelButtonWithTitle:title block:NULL];
}

#pragma mark - Display

- (void)showInView:(UIView *)view {
	[self.sheet showInView:view];
	[self setKeepInMemory:self];
}

- (void)showFromTabBar:(UITabBar *)view {
	[self.sheet showFromTabBar:view];
	[self setKeepInMemory:self];
}

- (void)showFromToolbar:(UIToolbar *)view {
	[self.sheet showFromToolbar:view];
	[self setKeepInMemory:self];
}

- (void)showFromBarButtonItem:(UIBarButtonItem *)item {
	[self.sheet showFromBarButtonItem:item animated:YES];
	[self setKeepInMemory:self];
}

- (void)showFromRect:(CGRect) rect inView:(UIView *)view animated:(BOOL) animated {
	[self.sheet showFromRect:rect inView:view animated:animated];
	[self setKeepInMemory:self];
}

- (void)dismissAnimated:(BOOL) animated {
	[self.sheet dismissWithClickedButtonIndex:-1 animated:animated];
}

#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
	NSParameterAssert(actionSheet == self.sheet);
	if (buttonIndex >= 0 && buttonIndex < [self.blocks count]) {
		dispatch_block_t block = (self.blocks)[buttonIndex];
		block();
	}
	if(self.dismissAction != NULL) {
    self.dismissAction();
  }
  [self setKeepInMemory:nil];
}

@end
