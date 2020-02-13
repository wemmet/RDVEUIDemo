//
//  RDLOTArrayInterpolator.m
//  RDLottie
//
//  Created by brandon_withrow on 7/27/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTArrayInterpolator.h"
#import "CGGeometry+RDLOTAdditions.h"

@implementation RDLOTArrayInterpolator

- (NSArray *)numberArrayForFrame:(NSNumber *)frame {
  CGFloat progress = [self progressForFrame:frame];
  if (progress == 0) {
    return self.leadingKeyframe.arrayValue;
  }
  if (progress == 1) {
    return self.trailingKeyframe.arrayValue;
  }
  NSMutableArray *returnArray = [NSMutableArray array];
  for (int i = 0; i < self.leadingKeyframe.arrayValue.count; i ++) {
    CGFloat from = [(NSNumber *)self.leadingKeyframe.arrayValue[i] floatValue];
    CGFloat to = [(NSNumber *)self.trailingKeyframe.arrayValue[i] floatValue];
    CGFloat value = RDLOT_RemapValue(progress, 0, 1, from, to);
    [returnArray addObject:@(value)];
  }
  return returnArray;
}

@end
