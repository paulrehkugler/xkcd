//
//  ComicImageView.m
//
//  Created by Josh Snyder
//

#import "ComicImageView.h"

#define kTouchAndHoldThreshold 1

@implementation ComicImageView

@synthesize titleText;
@synthesize delegate;

- (id)initWithImage:(UIImage *)image {
  if(self = [super initWithImage:image]) {
    self.userInteractionEnabled = YES;
  }
  return self;
}

- (void)showTitleText:(NSTimer *)timer {
  UIAlertView *titleTextAlert = [[[UIAlertView alloc] initWithTitle:@""
                                                            message:self.titleText
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:NSLocalizedString(@"Ok", @"Button text to dismiss modal window displaying comic alt text"), nil
                                  ] autorelease];
  [titleTextAlert show];
  
  [touchAndHoldTimer release];
  touchAndHoldTimer = nil;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  UITouch *touch = [touches anyObject];
  if([touch tapCount] < 2) {
    [touchAndHoldTimer release];
    touchAndHoldTimer = [[NSTimer scheduledTimerWithTimeInterval:kTouchAndHoldThreshold target:self selector:@selector(showTitleText:) userInfo:nil repeats:NO] retain];    
  } else {
    [self.delegate zoomOutWithTouch:touch];
  }
  [self.nextResponder touchesBegan:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  [touchAndHoldTimer invalidate];
  [touchAndHoldTimer release];
  touchAndHoldTimer = nil;
  [self.nextResponder touchesCancelled:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [touchAndHoldTimer invalidate];
  [touchAndHoldTimer release];
  touchAndHoldTimer = nil;
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
