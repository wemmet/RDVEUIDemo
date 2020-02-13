//
//  RDLOTPointInterpolator.m
//  RDLottie
//
//  Created by brandon_withrow on 7/12/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTPointInterpolator.h"
#import "CGGeometry+RDLOTAdditions.h"

@implementation RDLOTPointInterpolator

- (CGPoint)pointValueForFrame:(NSNumber *)frame {
  CGFloat progress = [self progressForFrame:frame];
  CGPoint returnPoint;
  if (progress == 0) {
    returnPoint = self.leadingKeyframe.pointValue;
  } else if (progress == 1) {
    returnPoint = self.trailingKeyframe.pointValue;
  } else if (!CGPointEqualToPoint(self.leadingKeyframe.spatialOutTangent, CGPointZero) ||
             !CGPointEqualToPoint(self.trailingKeyframe.spatialInTangent, CGPointZero)) {
    // Spatial Bezier path
    CGPoint outTan = RDLOT_PointAddedToPoint(self.leadingKeyframe.pointValue, self.leadingKeyframe.spatialOutTangent);
    CGPoint inTan = RDLOT_PointAddedToPoint(self.trailingKeyframe.pointValue, self.trailingKeyframe.spatialInTangent);
    returnPoint = RDLOT_PointInCubicCurve(self.leadingKeyframe.pointValue, outTan, inTan, self.trailingKeyframe.pointValue, progress);
  } else {
    returnPoint = RDLOT_PointInLine(self.leadingKeyframe.pointValue, self.trailingKeyframe.pointValue, progress);
  }
  if (self.hasDelegateOverride) {
    return [self.delegate pointForFrame:frame.floatValue
                          startKeyframe:self.leadingKeyframe.keyframeTime.floatValue
                            endKeyframe:self.trailingKeyframe.keyframeTime.floatValue
                   interpolatedProgress:progress
                             startPoint:self.leadingKeyframe.pointValue
                               endPoint:self.trailingKeyframe.pointValue
                           currentPoint:returnPoint];
  }
  return returnPoint;
}

- (BOOL)hasDelegateOverride {
  return self.delegate != nil;
}

- (void)setValueDelegate:(id<RDLOTValueDelegate>)delegate {
  NSAssert(([delegate conformsToProtocol:@protocol(RDLOTPointValueDelegate)]), @"Point Interpolator set with incorrect callback type. Expected RDLOTPointValueDelegate");
  self.delegate = (id<RDLOTPointValueDelegate>)delegate;
}

@end
