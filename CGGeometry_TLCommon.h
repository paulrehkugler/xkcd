//
//  CGGeometry_TLCommon.h
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 8/31/09.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static inline CGRect CGRectZeroWithSize(CGSize size) {
	return CGRectMake(0.0f, 0.0f, size.width, size.height);
}

static inline CGRect CGRectZeroWithSquareSize(CGFloat size) {
	return CGRectMake(0.0f, 0.0f, size, size);
}

static inline CGRect CGRectZeroWithWidthAndHeight(CGFloat width, CGFloat height) {
	return CGRectMake(0.0f, 0.0f, width, height);
}

static inline CGRect CGRectWithOriginAndSize(CGPoint origin, CGSize size) {
	return CGRectMake(origin.x, origin.y, size.width, size.height);
}

static inline CGRect CGRectWithOriginAndSquareSize(CGPoint origin, CGFloat size) {
	return CGRectMake(origin.x, origin.y, size, size);
}

static inline CGRect CGRectWithXYAndSize(CGFloat xOrigin, CGFloat yOrigin, CGSize size) {
	return CGRectMake(xOrigin, yOrigin, size.width, size.height);
}

static inline CGRect CGRectWithXYAndSquareSize(CGFloat xOrigin, CGFloat yOrigin, CGFloat size) {
	return CGRectMake(xOrigin, yOrigin, size, size);
}

static inline CGRect CGRectWithCenterAndSize(CGPoint center, CGSize size) {
	return CGRectMake(center.x - size.width / 2.0f, center.y - size.height / 2.0f, size.width, size.height);
}

static inline CGRect CGRectWithCenterAndSquareSize(CGPoint center, CGFloat size) {
	return CGRectMake(center.x - size / 2.0f, center.y - size / 2.0f, size, size);
}

static inline CGSize CGSizeMakeSquare(CGFloat widthAndHeight) {
	return CGSizeMake(widthAndHeight, widthAndHeight);
}

static inline CGRect CGRectByAddingXOffset(CGRect originalRect, CGFloat xOffset) {
	return CGRectWithXYAndSize(originalRect.origin.x + xOffset, originalRect.origin.y, originalRect.size);
}

static inline CGRect CGRectByAddingYOffset(CGRect originalRect, CGFloat yOffset) {
	return CGRectWithXYAndSize(originalRect.origin.x, originalRect.origin.y + yOffset, originalRect.size);
}

static inline CGRect CGRectByAddingXAndYOffset(CGRect originalRect, CGFloat xOffset, CGFloat yOffset) {
	return CGRectWithXYAndSize(originalRect.origin.x + xOffset, originalRect.origin.y + yOffset, originalRect.size);
}

static inline CGRect CGRectByAddingWidth(CGRect originalRect, CGFloat additionalWidth) {
	return CGRectMake(originalRect.origin.x, originalRect.origin.y, originalRect.size.width + additionalWidth, originalRect.size.height);
}

static inline CGRect CGRectByAddingHeight(CGRect originalRect, CGFloat additionalHeight) {
	return CGRectMake(originalRect.origin.x, originalRect.origin.y, originalRect.size.width, originalRect.size.height + additionalHeight);
}

static inline CGRect CGRectByAddingWidthAndHeight(CGRect originalRect, CGFloat additionalWidth, CGFloat additionalHeight) {
	return CGRectMake(originalRect.origin.x, originalRect.origin.y, originalRect.size.width + additionalWidth, originalRect.size.height + additionalHeight);
}

static inline CGSize CGSizeByAddingHeight(CGSize originalSize, CGFloat extraHeight) {
	return CGSizeMake(originalSize.width, originalSize.height + extraHeight);
}

static inline CGSize CGSizeByAddingWidth(CGSize originalSize, CGFloat extraWidth) {
	return CGSizeMake(originalSize.width + extraWidth, originalSize.height);
}

static inline CGPoint CGPointByAddingXOffset(CGPoint originalPoint, CGFloat xOffset) {
	return CGPointMake(originalPoint.x + xOffset, originalPoint.y);
}

static inline CGPoint CGPointByAddingYOffset(CGPoint originalPoint, CGFloat yOffset) {
	return CGPointMake(originalPoint.x, originalPoint.y + yOffset);
}

static inline CGFloat SquaredDistanceBetweenPoints(CGPoint p1, CGPoint p2) {
	CGFloat deltaX = p1.x - p2.x;
	CGFloat deltaY = p1.y - p2.y;
	return (deltaX * deltaX) + (deltaY * deltaY);
}

static inline CGFloat DistanceBetweenPoints(CGPoint p1, CGPoint p2) {
	return sqrt(SquaredDistanceBetweenPoints(p1, p2));
}

static inline CGPoint CenterOfRect(CGRect rect) {
	return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

static inline double AngleBetweenPoints(CGPoint p, CGPoint q) {
	CGPoint deltaVector = CGPointMake(p.x - q.x, p.y - q.y);
	double angle = atan(deltaVector.y / deltaVector.x) + (deltaVector.x < 0 ? M_PI : 0);
	return angle;
}

static inline CGPoint MidpointBetweenPoints(CGPoint p, CGPoint q) {
	return CGPointMake((p.x + q.x) / 2.0f, (p.y + q.y) / 2.0f);
}

static inline CGPoint PointMinusPoint(CGPoint p, CGPoint q) {
	return CGPointMake(p.x - q.x, p.y - q.y);
}

static inline CGPoint PointPlusPoint(CGPoint p, CGPoint q) {
	return CGPointMake(p.x + q.x, p.y + q.y);
}

static inline CGFloat OffsetToCenterFloatInFloat(CGFloat smallerValue, CGFloat largerValue) {
	return (largerValue - smallerValue) / 2.0f;
}

static inline CGRect CenteredRectInRectWithSize(CGRect rectToCenterIn, CGSize sizeOfCenteredRect) {
	return CGRectWithXYAndSize(rectToCenterIn.origin.x + OffsetToCenterFloatInFloat(sizeOfCenteredRect.width, rectToCenterIn.size.width),
							   rectToCenterIn.origin.y + OffsetToCenterFloatInFloat(sizeOfCenteredRect.height, rectToCenterIn.size.height),
							   sizeOfCenteredRect);
}

static inline CGSize ScaledSize(CGSize originalSize, CGFloat scalingFactor) {
	return CGSizeMake(originalSize.width * scalingFactor, originalSize.height * scalingFactor);
}

static inline CGRect CGRectRoundedToNearestPixel(CGRect rect) {
	return CGRectMake(roundf(rect.origin.x),
					  roundf(rect.origin.y),
					  roundf(rect.size.width),
					  roundf(rect.size.height));
}

static inline CGRect CGRectFlooredToNearestPixel(CGRect rect) {
	return CGRectMake(floorf(rect.origin.x),
					  floorf(rect.origin.y),
					  floorf(rect.size.width),
					  floorf(rect.size.height));
}
