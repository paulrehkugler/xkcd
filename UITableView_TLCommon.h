//
//  UITableView_TLCommon.h
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 9/15/09.
//

@import Foundation;
@import UIKit;

@interface UITableView (TLCommon)

- (void)reloadRowAtRow:(NSUInteger)row section:(NSUInteger)section withRowAnimation:(UITableViewRowAnimation)animation;
- (void)reloadRowAtIndexPath:(NSIndexPath *)indexPath withRowAnimation:(UITableViewRowAnimation)animation;

- (void)deleteRowsInRowRange:(NSRange)rowRange section:(NSUInteger)section withRowAnimation:(UITableViewRowAnimation)animation;

@end
