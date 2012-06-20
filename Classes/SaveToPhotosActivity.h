//
//  SaveToPhotosActivity.h
//

#import <UIKit/UIKit.h>

@interface SaveToPhotosActivity : UIActivity {
@private
  NSArray *imagesToSave;
  NSUInteger savedImageCount;
  NSUInteger errorCount;
}

@end
