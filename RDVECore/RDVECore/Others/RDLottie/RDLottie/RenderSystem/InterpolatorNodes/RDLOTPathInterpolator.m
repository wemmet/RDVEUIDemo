//
//  RDLOTPathInterpolator.m
//  RDLottie
//
//  Created by brandon_withrow on 7/13/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTPathInterpolator.h"
#import "CGGeometry+RDLOTAdditions.h"

@implementation RDLOTPathInterpolator

- (RDLOTBezierPath *)pathForFrame:(NSNumber *)frame cacheLengths:(BOOL)cacheLengths {
  CGFloat progress = [self progressForFrame:frame];
  if (self.hasDelegateOverride) {
    CGPathRef callBackPath = [self.delegate pathForFrame:frame.floatValue
                                           startKeyframe:self.leadingKeyframe.keyframeTime.floatValue
                                             endKeyframe:self.trailingKeyframe.keyframeTime.floatValue
                                    interpolatedProgress:progress];
    return [RDLOTBezierPath pathWithCGPath:callBackPath];
  }

  RDLOTBezierPath *returnPath = [[RDLOTBezierPath alloc] init];
  returnPath.cacheLengths = cacheLengths;
  RDLOTBezierData *leadingData = self.leadingKeyframe.pathData;
  RDLOTBezierData *trailingData = self.trailingKeyframe.pathData;
  NSInteger vertexCount = leadingData ? leadingData.count : trailingData.count;
  BOOL closePath = leadingData ? leadingData.closed : trailingData.closed;
  CGPoint cp1 = CGPointMake(0, 0);
  CGPoint cp2, p1, cp3 = CGPointZero;
  CGPoint startPoint = CGPointMake(0, 0);
  CGPoint startInTangent = CGPointMake(0, 0);
  for (int i = 0; i < vertexCount; i++) {
    if (progress == 0) {
      cp2 = [leadingData inTangentAtIndex:i];
      p1 = [leadingData vertexAtIndex:i];
      cp3 = [leadingData outTangentAtIndex:i];
    } else if (progress == 1) {
      cp2 = [trailingData inTangentAtIndex:i];
      p1 = [trailingData vertexAtIndex:i];
      cp3 = [trailingData outTangentAtIndex:i];
    } else {
      cp2 = RDLOT_PointInLine([leadingData inTangentAtIndex:i],
                            [trailingData inTangentAtIndex:i],
                            progress);
      p1 = RDLOT_PointInLine([leadingData vertexAtIndex:i],
                           [trailingData vertexAtIndex:i],
                           progress);
      cp3 = RDLOT_PointInLine([leadingData outTangentAtIndex:i],
                            [trailingData outTangentAtIndex:i],
                            progress);
    }
    if (i == 0) {
      startPoint = p1;
      startInTangent = cp2;
      [returnPath RDLOT_moveToPoint:p1];
    } else {
      [returnPath RDLOT_addCurveToPoint:p1 controlPoint1:cp1 controlPoint2:cp2];
    }
    cp1 = cp3;
  }
  
  if (closePath) {
    [returnPath RDLOT_addCurveToPoint:startPoint controlPoint1:cp3 controlPoint2:startInTangent];
    [returnPath RDLOT_closePath];
  }

  return returnPath;
}

- (void)setValueDelegate:(id<RDLOTValueDelegate>)delegate {
  NSAssert(([delegate conformsToProtocol:@protocol(RDLOTPathValueDelegate)]), @"Path Interpolator set with incorrect callback type. Expected RDLOTPathValueDelegate");
  self.delegate = (id<RDLOTPathValueDelegate>)delegate;
}

- (BOOL)hasDelegateOverride {
  return self.delegate != nil;
}

@end
