//
//  SaveToPhotosActivity.m
//

#import "SaveToPhotosActivity.h"
#import "NSArray+Filtering.h"

@interface SaveToPhotosActivity ()

@property(nonatomic, strong) NSArray *imagesToSave;

@end


@implementation SaveToPhotosActivity

@synthesize imagesToSave;

- (NSString *)activityType {
  return @"com.treelinelabs.xkcdapp.save_to_photos";
}

- (NSString *)activityTitle {
  return @"Save to Photos";
}

- (UIImage *)activityImage {
  return [UIImage imageNamed:@"blueArrow.png"];  // TODO: Needs image here
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
  return [activityItems containsObjectOfKindOfClass:[UIImage class]];
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
  self.imagesToSave = [activityItems objectsOfKindOfClass:[UIImage class]];
}

- (void)performActivity {
  savedImageCount = 0;
  errorCount = 0;
  for(UIImage *image in self.imagesToSave) {
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
  }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
  savedImageCount++;
  if(error) {
    errorCount++;
  }
  if(savedImageCount == self.imagesToSave.count) {
    BOOL success = (errorCount == 0);
    [self activityDidFinish:success];
  }
}

@end
