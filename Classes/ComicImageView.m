//
//  ComicImageView.m
//
//  Created by Josh Snyder
//

#import "ComicImageView.h"
#import "UIAlertView_TLCommon.h"

#define kTouchAndHoldThreshold 0.5f
#define kSingleTapThreshold 0.25f

#pragma mark -

@interface ComicImageView ()

@property(nonatomic, strong, readwrite) NSTimer *touchAndHoldTimer;
@property(nonatomic, strong, readwrite) NSTimer *singleTouchTimer;

@end


#pragma mark -

@implementation ComicImageView

@synthesize titleText;
@synthesize delegate;
@synthesize touchAndHoldTimer;
@synthesize singleTouchTimer;

- (id)initWithImage:(UIImage *)image {
  if(self = [super initWithImage:image]) {
    self.userInteractionEnabled = YES;
  }
  return self;
}

- (void)showTitleText:(NSTimer *)timer {
  [UIAlertView showAlertWithTitle:nil message:self.titleText];
  [self.touchAndHoldTimer invalidate];
  self.touchAndHoldTimer = nil;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  UITouch *touch = [touches anyObject];
  if(touch.tapCount < 2) {
    [self.touchAndHoldTimer invalidate];
    self.touchAndHoldTimer = [NSTimer scheduledTimerWithTimeInterval:kTouchAndHoldThreshold
                                                              target:self
                                                            selector:@selector(showTitleText:)
                                                            userInfo:nil
                                                             repeats:NO];    
  } else {
    [self.singleTouchTimer invalidate];
    self.singleTouchTimer = nil;
  }
  [self.nextResponder touchesBegan:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.touchAndHoldTimer invalidate];
  self.touchAndHoldTimer = nil;
  [self.singleTouchTimer invalidate];
  self.singleTouchTimer = nil;
  [self.nextResponder touchesCancelled:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  UITouch *touch = [touches anyObject];
  if(touch.tapCount < 2) {
    if(self.touchAndHoldTimer) {
      // Timer hasn't fired yet, so we're still in short-time-range; make sure this isn't a double-tap
      self.singleTouchTimer = [NSTimer scheduledTimerWithTimeInterval:kSingleTapThreshold
                                                               target:self.delegate
                                                             selector:@selector(didDetectShortSingleTap)
                                                             userInfo:nil
                                                              repeats:NO];
    }
  } else {
    [self.delegate zoomOutWithTouch:touch];
  }
  [self.touchAndHoldTimer invalidate];
  self.touchAndHoldTimer = nil;
  [self.nextResponder touchesEnded:touches withEvent:event];
}

- (void)dealloc {
  [touchAndHoldTimer invalidate];
  
  delegate = nil;
  
  
}

@end
