//
//  RDLOTInterpolatorCallback.m
//  RDLottie
//
//  Created by brandon_withrow on 1/5/18.
//  Copyright © 2018 Airbnb. All rights reserved.
//

#import "RDLOTInterpolatorCallback.h"
#import "CGGeometry+RDLOTAdditions.h"

@implementation RDLOTFloatInterpolatorCallback

+ (instancetype _Nonnull)withFromFloat:(CGFloat)fromFloat toFloat:(CGFloat)toFloat {
  RDLOTFloatInterpolatorCallback *interpolator = [[self alloc] init];
  interpolator.fromFloat = fromFloat;
  interpolator.toFloat = toFloat;
  return interpolator;
}
- (CGFloat)floatValueForFrame:(CGFloat)currentFrame startKeyframe:(CGFloat)startKeyframe endKeyframe:(CGFloat)endKeyframe interpolatedProgress:(CGFloat)interpolatedProgress startValue:(CGFloat)startValue endValue:(CGFloat)endValue currentValue:(CGFloat)interpolatedValue {
  return RDLOT_RemapValue(self.currentProgress, 0, 1, self.fromFloat, self.toFloat);
}

@end

@implementation RDLOTPointInterpolatorCallback

+ (instancetype _Nonnull)withFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint {
  RDLOTPointInterpolatorCallback *interpolator = [[self alloc] init];
  interpolator.fromPoint = fromPoint;
  interpolator.toPoint = toPoint;
  return interpolator;
}
- (CGPoint)pointForFrame:(CGFloat)currentFrame startKeyframe:(CGFloat)startKeyframe endKeyframe:(CGFloat)endKeyframe interpolatedProgress:(CGFloat)interpolatedProgress startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint currentPoint:(CGPoint)interpolatedPoint {
  return RDLOT_PointInLine(self.fromPoint, self.toPoint, self.currentProgress);
}

@end

@implementation RDLOTSizeInterpolatorCallback

+ (instancetype)withFromSize:(CGSize)fromSize toSize:(CGSize)toSize {
  RDLOTSizeInterpolatorCallback *interpolator = [[self alloc] init];
  interpolator.fromSize = fromSize;
  interpolator.toSize = toSize;
  return interpolator;
}

- (CGSize)sizeForFrame:(CGFloat)currentFrame startKeyframe:(CGFloat)startKeyframe endKeyframe:(CGFloat)endKeyframe interpolatedProgress:(CGFloat)interpolatedProgress startSize:(CGSize)startSize endSize:(CGSize)endSize currentSize:(CGSize)interpolatedSize {
  CGPoint from = CGPointMake(self.fromSize.width, self.fromSize.height);
  CGPoint to = CGPointMake(self.toSize.width, self.toSize.height);
  CGPoint returnPoint = RDLOT_PointInLine(from, to, self.currentProgress);
  return CGSizeMake(returnPoint.x, returnPoint.y);
}

@end
