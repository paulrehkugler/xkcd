//
//  ComicImageView.m
//
//  Created by Josh Snyder
//

#import "ComicImageView.h"

#define kTouchAndHoldThreshold 0.5f

#pragma mark -

@interface ComicImageView ()

@property(nonatomic, retain, readwrite) NSTimer *touchAndHoldTimer;

@end


#pragma mark -

@implementation ComicImageView

@synthesize titleText;
@synthesize delegate;
@synthesize touchAndHoldTimer;

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
  if([touch tapCount] < 2) {
    [self.touchAndHoldTimer invalidate];
    self.touchAndHoldTimer = [NSTimer scheduledTimerWithTimeInterval:kTouchAndHoldThreshold
                                                              target:self
                                                            selector:@selector(showTitleText:)
                                                            userInfo:nil
                                                             repeats:NO];    
  } else {
    [self.delegate zoomOutWithTouch:touch];
  }
  [self.nextResponder touchesBegan:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.touchAndHoldTimer invalidate];
  self.touchAndHoldTimer = nil;
  [self.nextResponder touchesCancelled:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.touchAndHoldTimer invalidate];
  self.touchAndHoldTimer = nil;
  [self.nextResponder touchesEnded:touches withEvent:event];
}

- (void)dealloc {
  [touchAndHoldTimer invalidate];
  [touchAndHoldTimer release];
  touchAndHoldTimer = nil;
  
  delegate = nil;
  
  [titleText release];
  titleText = nil;
  
  [super dealloc];
}

@end
