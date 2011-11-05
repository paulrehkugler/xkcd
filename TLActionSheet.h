//
//  TLActionSheet.h
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 10/30/09.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TLActionSheet : UIActionSheet {
@private
  id userInfo;
}

@property(nonatomic, retain, readwrite) id userInfo;

@end
