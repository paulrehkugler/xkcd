//
//  SingleComicViewController.h
//  xkcd
//

#import <UIKit/UIKit.h>
#import "SingleComicImageFetcherDelegate.h"

@class Comic;
@class SingleComicImageFetcher;

@interface SingleComicViewController : UIViewController <UIScrollViewDelegate, SingleComicImageFetcherDelegate>

- (instancetype)initWithComic:(Comic *)comicToView;

@property (nonatomic, readonly) Comic *comic;

@end
