//
//  RDLOTRepeaterRenderer.m
//  RDLottie
//
//  Created by brandon_withrow on 7/28/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTRepeaterRenderer.h"
#import "RDLOTTransformInterpolator.h"
#import "RDLOTNumberInterpolator.h"
#import "RDLOTHelpers.h"

@implementation RDLOTRepeaterRenderer {
  RDLOTTransformInterpolator *_transformInterpolator;
  RDLOTNumberInterpolator *_copiesInterpolator;
  RDLOTNumberInterpolator *_offsetInterpolator;
  RDLOTNumberInterpolator *_startOpacityInterpolator;
  RDLOTNumberInterpolator *_endOpacityInterpolator;
  
  CALayer *_instanceLayer;
  CAReplicatorLayer *_replicatorLayer;
  CALayer *centerPoint_DEBUG;
}

- (instancetype)initWithInputNode:(RDLOTAnimatorNode *)inputNode
                              shapeRepeater:(RDLOTShapeRepeater *)repeater {
  self = [super initWithInputNode:inputNode keyName:repeater.keyname];
  if (self) {
    _transformInterpolator = [[RDLOTTransformInterpolator alloc] initWithPosition:repeater.position.keyframes
                                                                       rotation:repeater.rotation.keyframes
                                                                         anchor:repeater.anchorPoint.keyframes
                                                                          scale:repeater.scale.keyframes];
    _copiesInterpolator = [[RDLOTNumberInterpolator alloc] initWithKeyframes:repeater.copies.keyframes];
    _offsetInterpolator = [[RDLOTNumberInterpolator alloc] initWithKeyframes:repeater.offset.keyframes];
    _startOpacityInterpolator = [[RDLOTNumberInterpolator alloc] initWithKeyframes:repeater.startOpacity.keyframes];
    _endOpacityInterpolator = [[RDLOTNumberInterpolator alloc] initWithKeyframes:repeater.endOpacity.keyframes];
    
    _instanceLayer = [CALayer layer];
    [self recursivelyAddChildLayers:inputNode];
    
    _replicatorLayer = [CAReplicatorLayer layer];
    _replicatorLayer.actions = @{@"instanceCount" : [NSNull null],
                                 @"instanceTransform" : [NSNull null],
                                 @"instanceAlphaOffset" : [NSNull null]};
    [_replicatorLayer addSublayer:_instanceLayer];
    [self.outputLayer addSublayer:_replicatorLayer];
    
    centerPoint_DEBUG = [CALayer layer];
    centerPoint_DEBUG.bounds = CGRectMake(0, 0, 20, 20);
    if (ENABLE_DEBUG_SHAPES) {
      [self.outputLayer addSublayer:centerPoint_DEBUG];
    }
  }
  return self;
}

- (NSDictionary *)valueInterpolators {
  return @{@"Copies" : _copiesInterpolator,
           @"Offset" : _offsetInterpolator,
           @"Transform.Anchor Point" : _transformInterpolator.anchorInterpolator,
           @"Transform.Position" : _transformInterpolator.positionInterpolator,
           @"Transform.Scale" : _transformInterpolator.scaleInterpolator,
           @"Transform.Rotation" : _transformInterpolator.rotationInterpolator,
           @"Transform.Start Opacity" : _startOpacityInterpolator,
           @"Transform.End Opacity" : _endOpacityInterpolator};
}

- (void)recursivelyAddChildLayers:(RDLOTAnimatorNode *)node {
  if ([node isKindOfClass:[RDLOTRenderNode class]]) {
    [_instanceLayer addSublayer:[(RDLOTRenderNode *)node outputLayer]];
  }
  if (![node isKindOfClass:[RDLOTRepeaterRenderer class]] &&
      node.inputNode) {
    [self recursivelyAddChildLayers:node.inputNode];
  }
}

- (BOOL)needsUpdateForFrame:(NSNumber *)frame {
  // TODO BW Add offset ability
  return ([_transformInterpolator hasUpdateForFrame:frame] ||
          [_copiesInterpolator hasUpdateForFrame:frame] ||
          [_startOpacityInterpolator hasUpdateForFrame:frame] ||
          [_endOpacityInterpolator hasUpdateForFrame:frame]);
}

- (void)performLocalUpdate {
  centerPoint_DEBUG.backgroundColor =  [UIColor greenColor].CGColor;
  centerPoint_DEBUG.borderColor = [UIColor lightGrayColor].CGColor;
  centerPoint_DEBUG.borderWidth = 2.f;
  
  CGFloat copies = ceilf([_copiesInterpolator floatValueForFrame:self.currentFrame]);
  _replicatorLayer.instanceCount = (NSInteger)copies;
  _replicatorLayer.instanceTransform = [_transformInterpolator transformForFrame:self.currentFrame];
  CGFloat startOpacity = [_startOpacityInterpolator floatValueForFrame:self.currentFrame];
  CGFloat endOpacity = [_endOpacityInterpolator floatValueForFrame:self.currentFrame];
  CGFloat opacityStep = (endOpacity - startOpacity) / copies;
  _instanceLayer.opacity = startOpacity;
  _replicatorLayer.instanceAlphaOffset = opacityStep;
}

@end
