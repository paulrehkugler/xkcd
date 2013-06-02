//
//  FetchedAndJumpToResultsController.m
//  xkcd
//
//  Created by Paul Rehkugler on 6/1/13.
//
//

#import "FetchedAndJumpToResultsController.h"
#import "Comic.h"

@interface FetchedAndJumpToResultsController (private)

+ (int)numberInString:(NSString *)string;

@end

@implementation FetchedAndJumpToResultsController

// this is kindof hacky
- (id) objectAtIndexPath:(NSIndexPath *)indexPath {
  if (self.hasJumpTo) {     // need to add a "jump to"
    
    int comicNumber = [FetchedAndJumpToResultsController numberInString:self.fetchRequest.predicate.predicateFormat];
    
    if (indexPath.row > 0) {  // if this isn't the first search result
      // return the expected result, shifted down one row
      Comic *retComic = [super objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section]];
      retComic.jumpTo = NO;
      return retComic;
    }
    
    // return a "jump to" here
    Comic *jumpToComic = [Comic comicNumbered:comicNumber];
    [jumpToComic setJumpTo:YES];
    return jumpToComic;

    
  }
  // no number in the search string
  return [super objectAtIndexPath:indexPath];
}

- (BOOL) hasJumpTo {
  int comicNumber = [FetchedAndJumpToResultsController numberInString:self.fetchRequest.predicate.predicateFormat];
  return (comicNumber > 0 && ([self.fetchedObjects containsObject:[Comic comicNumbered:comicNumber]]));
}

+ (int) numberInString:(NSString *)string {
  NSString *comicNumberString;
  NSScanner *scanner = [NSScanner scannerWithString:string];
  NSCharacterSet *numbers = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
  [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
  [scanner scanCharactersFromSet:numbers intoString:&comicNumberString];
  int comicNumber = [comicNumberString integerValue];
  
  return comicNumber;
}
@end
