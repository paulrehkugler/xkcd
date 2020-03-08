//
//  UITableView_TLCommon.m
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 9/15/09.
//

#import <UIKit/UIKit.h>
#import "UITableView_TLCommon.h"

@implementation UITableView (TLCommon)

- (void)reloadRowAtRow:(NSUInteger)row section:(NSUInteger)section withRowAnimation:(UITableViewRowAnimation)animation {
	[self reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:section]]
				withRowAnimation:animation];
}

- (void)reloadRowAtIndexPath:(NSIndexPath *)indexPath withRowAnimation:(UITableViewRowAnimation)animation {
	[self reloadRowsAtIndexPaths:@[indexPath]
				withRowAnimation:animation];
}

- (void)deleteRowsInRowRange:(NSRange)rowRange section:(NSUInteger)section withRowAnimation:(UITableViewRowAnimation)animation {
	// there's got to be a better way...
	NSMutableArray *indexPathsToDelete = [NSMutableArray arrayWithCapacity:rowRange.length];
	for (NSUInteger i = 0; i < rowRange.length; i++) {
		NSIndexPath *indexPathToDelete = [NSIndexPath indexPathForRow:rowRange.location + i inSection:section];
		[indexPathsToDelete addObject:indexPathToDelete];
	}
	[self deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:animation];
}

@end
