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
  id<ComicImageViewDelegate> delegate;
}

@property(nonatomic, retain, readwrite) NSString *titleText;
@property(nonatomic, assign, readwrite) id<ComicImageViewDelegate> delegate;

@end
