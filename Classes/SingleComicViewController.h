//
//  SingleComicViewController.h
//  xkcd
//

#import <UIKit/UIKit.h>
#import "SingleComicImageFetcherDelegate.h"

@class Comic;
@class SingleComicImageFetcher;

@interface SingleComicViewController : UIViewController <UIScrollViewDelegate, SingleComicImageFetcherDelegate>

- (id)initWithComic:(Comic *)comicToView;

@property(nonatomic, strong, readonly) Comic *comic;

@end
