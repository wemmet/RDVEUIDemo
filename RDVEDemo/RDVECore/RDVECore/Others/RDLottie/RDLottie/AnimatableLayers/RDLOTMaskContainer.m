//
//  RDLOTMaskContainer.m
//  RDLottie
//
//  Created by brandon_withrow on 7/19/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTMaskContainer.h"
#import "RDLOTPathInterpolator.h"
#import "RDLOTNumberInterpolator.h"

@interface RDLOTMaskNodeLayer : CAShapeLayer

@property (nonatomic, readonly) RDLOTMask *maskNode;

- (instancetype)initWithMask:(RDLOTMask *)maskNode;
- (BOOL)hasUpdateForFrame:(NSNumber *)frame;

@end

@implementation RDLOTMaskNodeLayer {
  RDLOTPathInterpolator *_pathInterpolator;
  RDLOTNumberInterpolator *_opacityInterpolator;
  RDLOTNumberInterpolator *_expansionInterpolator;
}

- (instancetype)initWithMask:(RDLOTMask *)maskNode {
  self = [super init];
  if (self) {
    _pathInterpolator = [[RDLOTPathInterpolator alloc] initWithKeyframes:maskNode.maskPath.keyframes];
    _opacityInterpolator = [[RDLOTNumberInterpolator alloc] initWithKeyframes:maskNode.opacity.keyframes];
    _expansionInterpolator = [[RDLOTNumberInterpolator alloc] initWithKeyframes:maskNode.expansion.keyframes];
    _maskNode = maskNode;
    self.fillColor = [UIColor blueColor].CGColor;
  }
  return self;
}

- (void)updateForFrame:(NSNumber *)frame withViewBounds:(CGRect)viewBounds {
  if ([self hasUpdateForFrame:frame]) {
    RDLOTBezierPath *path = [_pathInterpolator pathForFrame:frame cacheLengths:NO];
    
    if (self.maskNode.maskMode == RDLOTMaskModeSubtract) {
      CGMutablePathRef pathRef = CGPathCreateMutable();
      CGPathAddRect(pathRef, NULL, viewBounds);
      CGPathAddPath(pathRef, NULL, path.CGPath);
      self.path = pathRef;
      self.fillRule = @"even-odd";
      CGPathRelease(pathRef);
    } else {
      self.path = path.CGPath;
    }
    
    self.opacity = [_opacityInterpolator floatValueForFrame:frame];
  }
}

- (BOOL)hasUpdateForFrame:(NSNumber *)frame {
  return ([_pathInterpolator hasUpdateForFrame:frame] ||
          [_opacityInterpolator hasUpdateForFrame:frame]);
}

@end

@implementation RDLOTMaskContainer {
  NSArray<RDLOTMaskNodeLayer *> *_masks;
}

- (instancetype)initWithMasks:(NSArray<RDLOTMask *> *)masks {
  self = [super init];
  if (self) {
    self.anchorPoint = CGPointZero;//20191120 修复蒙版显示位置错误的bug
    NSMutableArray *maskNodes = [NSMutableArray array];
    CALayer *containerLayer = [CALayer layer];
    
    for (RDLOTMask *mask in masks) {
      RDLOTMaskNodeLayer *node = [[RDLOTMaskNodeLayer alloc] initWithMask:mask];
      [maskNodes addObject:node];
      if (mask.maskMode == RDLOTMaskModeAdd ||
          mask == masks.firstObject) {
        [containerLayer addSublayer:node];
      } else {
        containerLayer.mask = node;
        CALayer *newContainer = [CALayer layer];
        [newContainer addSublayer:containerLayer];
        containerLayer = newContainer;
      }
    }
    [self addSublayer:containerLayer];
    _masks = maskNodes;

  }
  return self;
}

- (void)setCurrentFrame:(NSNumber *)currentFrame {
  if (_currentFrame == currentFrame) {
    return;
  }
  _currentFrame = currentFrame;
  
  for (RDLOTMaskNodeLayer *nodeLayer in _masks) {
    [nodeLayer updateForFrame:currentFrame withViewBounds:self.bounds];
  }
}

@end
