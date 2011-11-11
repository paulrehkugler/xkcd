//
//  ComicImageView.h
//
//  Created by Josh Snyder
//

#import <Foundation/Foundation.h>
#import "ComicImageViewDelegate.h"

@interface ComicImageView : UIImageView {
@private
  NSString *titleText;
  NSTimer *touchAndHoldTimer;
  NSTimer *singleTouchTimer;
  id<ComicImageViewDelegate> __unsafe_unretained delegate;
}

@property(nonatomic, strong, readwrite) NSString *titleText;
@property(nonatomic, unsafe_unretained, readwrite) id<ComicImageViewDelegate> delegate;

@end
