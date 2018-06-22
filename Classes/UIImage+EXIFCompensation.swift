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
    @objc var exifAgnosticSize: CGSize {
		if let cgImage = cgImage {
			return CGSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height));
		}
		
		return size;
    }
}
