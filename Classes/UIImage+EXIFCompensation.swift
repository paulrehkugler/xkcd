//
//  UIImage+EXIFCompensation.swift
//  xkcd
//
//  Created by Paul Rehkugler on 1/24/16.
//
//

import UIKit

extension UIImage {

    /// The size of an image, without accounting for its EXIF orientation.
    var EXIFAgnosticSize: CGSize {
        let bitmapWidth = CGImageGetWidth(self.CGImage);
        let bitmapHeight = CGImageGetHeight(self.CGImage);

        return CGSizeMake(CGFloat(bitmapWidth), CGFloat(bitmapHeight));
    }
}
