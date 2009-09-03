//
//  StatusBarController.m
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/1/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import "StatusBarController.h"
#import "CGGeometry_TLCommon.h"

#pragma mark -

@interface StatusBarController ()

- (NSArray *)barButtonItems;

@property(nonatomic, retain, readwrite) UILabel *messageLabel;
@property(nonatomic, retain, readwrite) UIActivityIndicatorView *spinner;
@property(nonatomic, retain, readwrite) UIToolbar *statusBar;
@property(nonatomic, assign, readwrite) CGPoint hiddenPosition;
@property(nonatomic, assign, readwrite) CGPoint shownPosition;
@property(nonatomic, retain, readwrite) UIBarButtonItem *spinnerBarButtonItem;
@property(nonatomic, retain, readwrite) UIBarButtonItem *labelBarButtonItem;
@property(nonatomic, retain, readwrite) UIBarButtonItem *leftFlexibleSpace;
@property(nonatomic, retain, readwrite) UIBarButtonItem *rightFlexibleSpace;
@property(nonatomic, assign, readwrite) BOOL hidden;

@end

#pragma mark -

@interface SelfResizingUILabel : UILabel

@end

#pragma mark -

@implementation SelfResizingUILabel

- (void)setText:(NSString *)newText {
  [super setText:newText];
  [self sizeToFit];
}

@end

#pragma mark -

@implementation StatusBarController

@synthesize messageLabel;
@synthesize spinner;
@synthesize statusBar;
@synthesize shownPosition;
@synthesize hiddenPosition;
@synthesize spinnerBarButtonItem;
@synthesize labelBarButtonItem;
@synthesize leftFlexibleSpace;
@synthesize rightFlexibleSpace;
@synthesize hidden;

- (id)initWithStatusBarFrame:(CGRect)statusBarFrame {
  if(self = [super init]) {
    self.statusBar = [[[UIToolbar alloc] initWithFrame:statusBarFrame] autorelease];
    
    self.shownPosition = self.statusBar.layer.position;
    self.hiddenPosition = CGPointMake(self.statusBar.layer.position.x, self.statusBar.layer.position.y + self.statusBar.bounds.size.height);
    
    self.spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
    [self.spinner sizeToFit];
    self.spinner.hidesWhenStopped = YES;
    
    self.messageLabel = [[[SelfResizingUILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, self.statusBar.bounds.size.height)] autorelease];
    self.messageLabel.backgroundColor = [UIColor clearColor];
    self.messageLabel.textColor = [UIColor whiteColor];
    self.messageLabel.font = [UIFont systemFontOfSize:14.0f];

    self.leftFlexibleSpace = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                            target:nil
                                                                            action:nil]
                              autorelease];
    self.rightFlexibleSpace = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                             target:nil
                                                                             action:nil]
                               autorelease];
    
    self.spinnerBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:self.spinner] autorelease];
    self.labelBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:self.messageLabel] autorelease];
    
    self.statusBar.items = [self barButtonItems];
    self.hidden = NO;
  }
  return self;
}

- (void)setStatusBarFrame:(CGRect)newStatusBarFrame {
  [statusBar.layer removeAllAnimations];
  self.statusBar.frame = newStatusBarFrame;
  self.shownPosition = self.statusBar.layer.position;
  self.hiddenPosition = CGPointMake(self.statusBar.layer.position.x, self.statusBar.layer.position.y + self.statusBar.bounds.size.height);
  if(hidden) {
    self.statusBar.layer.position = self.hiddenPosition;
  }
}

- (NSArray *)barButtonItems {
  NSArray *barButtonItems = nil;
  if(self.spinner.isAnimating) {
    barButtonItems = [NSArray arrayWithObjects:
                      self.leftFlexibleSpace,
                      self.spinnerBarButtonItem,
                      self.labelBarButtonItem,
                      self.rightFlexibleSpace,
                      nil];
  } else {
    barButtonItems = [NSArray arrayWithObjects:
                      self.leftFlexibleSpace,
                      self.labelBarButtonItem,
                      self.rightFlexibleSpace,
                      nil];
  }
  return barButtonItems;
}

- (void)startSpinner {
  [self.spinner startAnimating];
  self.statusBar.items = [self barButtonItems];
}

- (void)stopSpinner {
  [self.spinner stopAnimating];
  self.statusBar.items = [self barButtonItems];
}

- (void)hide {
  self.statusBar.layer.position = self.hiddenPosition;
  self.hidden = YES;
}

- (void)hideAnimated {
  CABasicAnimation *hideAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
  hideAnimation.delegate = self;
  hideAnimation.toValue = [NSValue valueWithCGPoint:self.hiddenPosition];
  hideAnimation.fillMode = kCAFillModeForwards;
  hideAnimation.removedOnCompletion = NO;
  [self.statusBar.layer addAnimation:hideAnimation forKey:@"hide"];
  self.hidden = YES;
}

- (void)show {
  self.statusBar.layer.position = self.shownPosition;
  self.hidden = NO;
}

- (void)showAnimated {
  CABasicAnimation *showAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
  showAnimation.delegate = self;
  showAnimation.toValue = [NSValue valueWithCGPoint:self.shownPosition];
  showAnimation.fillMode = kCAFillModeForwards;
  showAnimation.removedOnCompletion = NO;
  [self.statusBar.layer addAnimation:showAnimation forKey:@"show"];    
  self.hidden = NO;
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)finished {
  if(finished) {
    self.statusBar.layer.position = [((CABasicAnimation *)theAnimation).toValue CGPointValue];    
    [self.statusBar.layer removeAllAnimations];
  }
}

- (void)dealloc {
  [messageLabel release];
  messageLabel = nil;
  
  [statusBar.layer removeAllAnimations];
  [statusBar release];
  statusBar = nil;

  [leftFlexibleSpace release];
  leftFlexibleSpace = nil;
  
  [rightFlexibleSpace release];
  rightFlexibleSpace = nil;
  
  [spinnerBarButtonItem release];
  spinnerBarButtonItem = nil;
  
  [labelBarButtonItem release];
  labelBarButtonItem = nil;
  
  [spinner release];
  spinner = nil;
  
  [super dealloc];
}

@end
