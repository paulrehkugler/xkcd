//
//  FetchedAndJumpToResultsController.h
//  xkcd
//
//  Created by Paul Rehkugler on 6/1/13.
//
//

#import <CoreData/CoreData.h>

@interface FetchedAndJumpToResultsController : NSFetchedResultsController

- (BOOL) hasJumpTo;

@property (nonatomic, readonly) int rowCount;

@end
