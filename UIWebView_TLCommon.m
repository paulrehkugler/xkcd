//
//  UIWebView_TLCommon.m
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 10/27/09.
//

#import "UIWebView_TLCommon.h"

@implementation UIWebView (TLCommon)

// Adapted from code by Emanuele Vulcano at http://uikitplus.googlecode.com/svn/trunk/Workshop/L0URLDetection/L0URLDetection.m
+ (BOOL)shouldOpenURLInBrowser:(NSURL *)url {
	// bizarre URL schemes eg. tel: or sms: go in their own apps.
	// javascript: is there for completeness.
	// forgotten any?
	if (!([[url scheme] isEqual:@"http"] || [[url scheme] isEqual:@"https"] || [[url scheme] isEqual:@"ftp"] || [[url scheme] isEqual:@"javascript"] || [[url scheme] isEqual:@"about"] || [[url scheme] isEqual:@"data"]))
		return NO;
	
	// http-based special URLs
	if ([[url scheme] isEqual:@"http"]) {
		// iTunes Store and App Store
		if ([[url host] isEqual:@"phobos.apple.com"])
			return NO;
		
		// iTunes Store and App Store (Dec '08 new-style URLs)
		if ([[url host] isEqual:@"itunes.apple.com"] || [[url host] hasSuffix:@".itunes.apple.com"])
			return NO;
		
		// Maps
		if ([[url host] isEqual:@"maps.google.com"])
			return NO;
		
		// YouTube -- this mimics Safari's behavior of navigating to international
		// sites (eg. it.youtube.com) or m.youtube.com without launching YouTube.app.
		if (([[url host] isEqual:@"youtube.com"] || [[url host] isEqual:@"www.youtube.com"]) && ([[url path] hasPrefix:@"/v/"] || [[url path] isEqual:@"/watch"]))
			return NO;
	}
  
	// https-based special URLs:
	if ([[url scheme] isEqual:@"https"]) {
		// iTunes Store and App Store (Dec '08 new-style URLs)
		if ([[url host] isEqual:@"itunes.apple.com"] || [[url host] hasSuffix:@".itunes.apple.com"])
			return NO;
	}
	
	// everything else is kosher.
	return YES;
}

@end
