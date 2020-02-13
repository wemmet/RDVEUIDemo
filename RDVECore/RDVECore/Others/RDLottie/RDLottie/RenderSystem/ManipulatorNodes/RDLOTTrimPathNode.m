//
//  RDLOTTrimPathNode.m
//  RDLottie
//
//  Created by brandon_withrow on 7/21/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTTrimPathNode.h"
#import "RDLOTNumberInterpolator.h"
#import "RDLOTPathAnimator.h"
#import "RDLOTCircleAnimator.h"
#import "RDLOTRoundedRectAnimator.h"
#import "RDLOTRenderGroup.h"

@implementation RDLOTTrimPathNode {
  RDLOTNumberInterpolator *_startInterpolator;
  RDLOTNumberInterpolator *_endInterpolator;
  RDLOTNumberInterpolator *_offsetInterpolator;
  
  CGFloat _startT;
  CGFloat _endT;
  CGFloat _offsetT;
}

- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                                   trimPath:(RDLOTShapeTrimPath *_Nonnull)trimPath {
  self = [super initWithInputNode:inputNode keyName:trimPath.keyname];
  if (self) {
    inputNode.pathShouldCacheLengths = YES;
    _startInterpolator = [[RDLOTNumberInterpolator alloc] initWithKeyframes:trimPath.start.keyframes];
    _endInterpolator = [[RDLOTNumberInterpolator alloc] initWithKeyframes:trimPath.end.keyframes];
    _offsetInterpolator = [[RDLOTNumberInterpolator alloc] initWithKeyframes:trimPath.offset.keyframes];
  }
  return self;
}

- (NSDictionary *)valueInterpolators {
  return @{@"Start" : _startInterpolator,
           @"End" : _endInterpolator,
           @"Offset" : _offsetInterpolator};
}

- (BOOL)needsUpdateForFrame:(NSNumber *)frame {
  return ([_startInterpolator hasUpdateForFrame:frame] ||
          [_endInterpolator hasUpdateForFrame:frame] ||
          [_offsetInterpolator hasUpdateForFrame:frame]);
}

- (BOOL)updateWithFrame:(NSNumber *)frame
      withModifierBlock:(void (^ _Nullable)(RDLOTAnimatorNode * _Nonnull))modifier
       forceLocalUpdate:(BOOL)forceUpdate {
  BOOL localUpdate = [self needsUpdateForFrame:frame];
  [self forceSetCurrentFrame:frame];
  if (localUpdate) {
    [self performLocalUpdate];
  }
  if (self.inputNode == nil) {
    return localUpdate;
  }
  
  BOOL inputUpdated = [self.inputNode updateWithFrame:frame withModifierBlock:^(RDLOTAnimatorNode * _Nonnull inputNode) {
    if ([inputNode isKindOfClass:[RDLOTPathAnimator class]] ||
        [inputNode isKindOfClass:[RDLOTCircleAnimator class]] ||
        [inputNode isKindOfClass:[RDLOTRoundedRectAnimator class]]) {
      [inputNode.localPath trimPathFromT:self->_startT toT:self->_endT offset:self->_offsetT];
    }
    if (modifier) {
      modifier(inputNode);
    }
    
  } forceLocalUpdate:(localUpdate || forceUpdate)];
  
  return inputUpdated;
}

- (void)performLocalUpdate {
  _startT = [_startInterpolator floatValueForFrame:self.currentFrame] / 100;
  _endT = [_endInterpolator floatValueForFrame:self.currentFrame] / 100;
  _offsetT = [_offsetInterpolator floatValueForFrame:self.currentFrame] / 360;
}

- (void)rebuildOutputs {
  // Skip this step.
}

- (RDLOTBezierPath *)localPath {
  return self.inputNode.localPath;
}

/// Forwards its input node's output path forwards downstream
- (RDLOTBezierPath *)outputPath {
  return self.inputNode.outputPath;
}

@end
