//
//  UIScrollView+Helper.swift
//  xkcd
//
//  Created by Paul Rehkugler on 1/24/16.
//
//

import UIKit

extension UIScrollView {

    /**
     Sets the zoom `scale` of the scroll view, and centers it on the `centerPoint`.

     - parameter scale:       The target scale of the scroll view.
     - parameter centerPoint: The point in which the scroll view will be centered.
     - parameter animated:    Whether the zoom should be animated.
     */
    func setZoomScale(scale: CGFloat, centerPoint: CGPoint, animated: Bool) {
        // convert scroll view point to content point
        if let contentView = delegate?.viewForZoomingInScrollView?(self) {
            let contentCenter = convertPoint(centerPoint, toView:contentView)

            let visibleWidth = self.frame.width / scale
            let visibleHeight = self.frame.height / scale

            // make the target content point the center of the resulting view
            let leftX = (contentCenter.x - (visibleWidth / 2))
            let topY = (contentCenter.y - (visibleHeight / 2))

            zoomToRect(CGRect(x: leftX, y: topY, width: visibleWidth, height: visibleHeight), animated: animated)
        }
        else {
            fatalError("It is expected that UIScrollViews that are being zoomed have a delegate that responds to -viewForZoomingInScrollView:")
        }
    }
}
