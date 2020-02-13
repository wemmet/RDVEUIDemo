//
//  RDLOTSizeInterpolator.m
//  RDLottie
//
//  Created by brandon_withrow on 7/13/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTPlatformCompat.h"
#import "RDLOTSizeInterpolator.h"
#import "CGGeometry+RDLOTAdditions.h"

@implementation RDLOTSizeInterpolator

- (CGSize)sizeValueForFrame:(NSNumber *)frame {
  CGFloat progress = [self progressForFrame:frame];
  CGSize returnSize;
  if (progress == 0) {
    returnSize = self.leadingKeyframe.sizeValue;
  }else if (progress == 1) {
    returnSize = self.trailingKeyframe.sizeValue;
  } else {
    returnSize = CGSizeMake(RDLOT_RemapValue(progress, 0, 1, self.leadingKeyframe.sizeValue.width, self.trailingKeyframe.sizeValue.width),
                            RDLOT_RemapValue(progress, 0, 1, self.leadingKeyframe.sizeValue.height, self.trailingKeyframe.sizeValue.height));
  }
  if (self.hasDelegateOverride) {
    return [self.delegate sizeForFrame:frame.floatValue
                         startKeyframe:self.leadingKeyframe.keyframeTime.floatValue
                           endKeyframe:self.trailingKeyframe.keyframeTime.floatValue
                  interpolatedProgress:progress startSize:self.leadingKeyframe.sizeValue
                               endSize:self.trailingKeyframe.sizeValue
                           currentSize:returnSize];
  }
  return returnSize;
}

- (BOOL)hasDelegateOverride {
  return self.delegate != nil;
}

- (void)setValueDelegate:(id<RDLOTValueDelegate>)delegate {
  NSAssert(([delegate conformsToProtocol:@protocol(RDLOTSizeValueDelegate)]), @"Size Interpolator set with incorrect callback type. Expected RDLOTSizeValueDelegate");
  self.delegate = (id<RDLOTSizeValueDelegate>)delegate;
}

@end
