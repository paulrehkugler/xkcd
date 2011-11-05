//
//  TLLoadingView.h
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 10/18/09.
//

#import <UIKit/UIKit.h>

// sets up a view that displays a spinner and has a loading label, centered within it

// normal usage:
// init with frame
// change label, spinner, view properties as desired; they default to (somewhat) reasonable values
// call -setNeedsLayout after changing values to get everything re-aligned perfectly

@interface TLLoadingView : UIView {
@private
  UILabel *label;
  UIActivityIndicatorView *spinner;
}

@property(nonatomic, retain, readonly) UILabel *label;
@property(nonatomic, retain, readonly) UIActivityIndicatorView *spinner;

@end
