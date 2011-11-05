//
//  NSFileManager_TLCommon.m
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 9/8/09.
//

#import "NSFileManager_TLCommon.h"

@implementation NSFileManager (TLCommon)

+ (NSString *)applicationDocumentsDirectory {
  NSArray *documentsDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = nil;
  if([documentsDirectories count] > 0) {
    documentsDirectory = [documentsDirectories objectAtIndex:0];    
  }
  return documentsDirectory;
}

@end
