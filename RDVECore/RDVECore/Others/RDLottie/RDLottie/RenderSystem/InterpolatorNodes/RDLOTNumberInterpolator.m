//
//  RDLOTNumberInterpolator.m
//  RDLottie
//
//  Created by brandon_withrow on 7/11/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTNumberInterpolator.h"
#import "CGGeometry+RDLOTAdditions.h"

@implementation RDLOTNumberInterpolator

- (CGFloat)floatValueForFrame:(NSNumber *)frame {
  CGFloat progress = [self progressForFrame:frame];
  CGFloat returnValue;
  if (progress == 0) {
    returnValue = self.leadingKeyframe.floatValue;
  } else if (progress == 1) {
    returnValue = self.trailingKeyframe.floatValue;
  } else {
    returnValue = RDLOT_RemapValue(progress, 0, 1, self.leadingKeyframe.floatValue, self.trailingKeyframe.floatValue);
  }
  if (self.hasDelegateOverride) {
    return [self.delegate floatValueForFrame:frame.floatValue
                               startKeyframe:self.leadingKeyframe.keyframeTime.floatValue
                                 endKeyframe:self.trailingKeyframe.keyframeTime.floatValue
                        interpolatedProgress:progress
                                  startValue:self.leadingKeyframe.floatValue
                                    endValue:self.trailingKeyframe.floatValue
                                currentValue:returnValue];
  }

  return returnValue;
}

- (BOOL)hasDelegateOverride {
  return self.delegate != nil;
}

- (void)setValueDelegate:(id<RDLOTValueDelegate> _Nonnull)delegate {
  NSAssert(([delegate conformsToProtocol:@protocol(RDLOTNumberValueDelegate)]), @"Number Interpolator set with incorrect callback type. Expected RDLOTNumberValueDelegate");
  self.delegate = (id<RDLOTNumberValueDelegate>)delegate;
}

@end
