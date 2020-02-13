//
//  RDLOTColorInterpolator.m
//  RDLottie
//
//  Created by brandon_withrow on 7/13/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTColorInterpolator.h"
#import "RDLOTPlatformCompat.h"
#import "UIColor+RDExpanded.h"

@implementation RDLOTColorInterpolator

- (CGColorRef)colorForFrame:(NSNumber *)frame {
  CGFloat progress = [self progressForFrame:frame];
  UIColor *returnColor;

  if (progress == 0) {
    returnColor = self.leadingKeyframe.colorValue;
  } else if (progress == 1) {
    returnColor = self.trailingKeyframe.colorValue;
  } else {
    returnColor = [UIColor RDLOT_colorByLerpingFromColor:self.leadingKeyframe.colorValue toColor:self.trailingKeyframe.colorValue amount:progress];
  }
  if (self.hasDelegateOverride) {
    return [self.delegate colorForFrame:frame.floatValue
                          startKeyframe:self.leadingKeyframe.keyframeTime.floatValue
                            endKeyframe:self.trailingKeyframe.keyframeTime.floatValue
                   interpolatedProgress:progress
                             startColor:self.leadingKeyframe.colorValue.CGColor
                               endColor:self.trailingKeyframe.colorValue.CGColor
                           currentColor:returnColor.CGColor];
  }

  return returnColor.CGColor;
}

- (void)setValueDelegate:(id<RDLOTValueDelegate>)delegate {
  NSAssert(([delegate conformsToProtocol:@protocol(RDLOTColorValueDelegate)]), @"Color Interpolator set with incorrect callback type. Expected RDLOTColorValueDelegate");
  self.delegate = (id<RDLOTColorValueDelegate>)delegate;
}

- (BOOL)hasDelegateOverride {
  return self.delegate != nil;
}

@end
