//
//  RDLOTTransformInterpolator.m
//  RDLottie
//
//  Created by brandon_withrow on 7/18/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTTransformInterpolator.h"

// TODO BW Perf update, Cache transform

@implementation RDLOTTransformInterpolator {
  RDLOTPointInterpolator *_positionInterpolator;
  RDLOTPointInterpolator *_anchorInterpolator;
  RDLOTSizeInterpolator *_scaleInterpolator;
  RDLOTNumberInterpolator *_rotationInterpolator;
  RDLOTNumberInterpolator *_positionXInterpolator;
  RDLOTNumberInterpolator *_positionYInterpolator;
}

+ (instancetype)transformForLayer:(RDLOTLayer *)layer {
  RDLOTTransformInterpolator *interpolator = nil;
  if (layer.position) {
    interpolator = [[RDLOTTransformInterpolator alloc] initWithPosition:layer.position.keyframes
                                                             rotation:layer.rotation.keyframes
                                                               anchor:layer.anchor.keyframes
                                                                scale:layer.scale.keyframes];
  } else {
    interpolator = [[RDLOTTransformInterpolator alloc] initWithPositionX:layer.positionX.keyframes
                                                             positionY:layer.positionY.keyframes
                                                              rotation:layer.rotation.keyframes
                                                                anchor:layer.anchor.keyframes
                                                                 scale:layer.scale.keyframes];
  }
  interpolator.parentKeyName = [layer.layerName copy];
  return interpolator;
}

- (instancetype)initWithPosition:(NSArray <RDLOTKeyframe *> *)position
                        rotation:(NSArray <RDLOTKeyframe *> *)rotation
                          anchor:(NSArray <RDLOTKeyframe *> *)anchor
                           scale:(NSArray <RDLOTKeyframe *> *)scale {
  self = [super init];
  if (self) {
    [self initializeWithPositionX:nil positionY:nil position:position rotation:rotation anchor:anchor scale:scale];
  }
  return self;
}

- (instancetype)initWithPositionX:(NSArray <RDLOTKeyframe *> *)positionX
                        positionY:(NSArray <RDLOTKeyframe *> *)positionY
                         rotation:(NSArray <RDLOTKeyframe *> *)rotation
                           anchor:(NSArray <RDLOTKeyframe *> *)anchor
                            scale:(NSArray <RDLOTKeyframe *> *)scale {
  self = [super init];
  if (self) {
    [self initializeWithPositionX:positionX positionY:positionY position:nil rotation:rotation anchor:anchor scale:scale];
  }
  return self;
}


- (void)initializeWithPositionX:(NSArray <RDLOTKeyframe *> *)positionX
                      positionY:(NSArray <RDLOTKeyframe *> *)positionY
                       position:(NSArray <RDLOTKeyframe *> *)position
                       rotation:(NSArray <RDLOTKeyframe *> *)rotation
                         anchor:(NSArray <RDLOTKeyframe *> *)anchor
                          scale:(NSArray <RDLOTKeyframe *> *)scale {
  
  if (position) {
    _positionInterpolator = [[RDLOTPointInterpolator alloc] initWithKeyframes:position];
  }
  if (positionY) {
    _positionYInterpolator = [[RDLOTNumberInterpolator alloc] initWithKeyframes:positionY];
  }
  if (positionX) {
    _positionXInterpolator = [[RDLOTNumberInterpolator alloc] initWithKeyframes:positionX];
  }
  _anchorInterpolator = [[RDLOTPointInterpolator alloc] initWithKeyframes:anchor];
  _scaleInterpolator = [[RDLOTSizeInterpolator alloc] initWithKeyframes:scale];
  _rotationInterpolator = [[RDLOTNumberInterpolator alloc] initWithKeyframes:rotation];
}

- (BOOL)hasUpdateForFrame:(NSNumber *)frame {
  BOOL inputUpdate = _inputNode ? [_inputNode hasUpdateForFrame:frame] : NO;
  if (inputUpdate) {
    return inputUpdate;
  }
  if (_positionInterpolator) {
    return ([_positionInterpolator hasUpdateForFrame:frame] ||
            [_anchorInterpolator hasUpdateForFrame:frame] ||
            [_scaleInterpolator hasUpdateForFrame:frame] ||
            [_rotationInterpolator hasUpdateForFrame:frame]);
  }
  return ([_positionXInterpolator hasUpdateForFrame:frame] ||
          [_positionYInterpolator hasUpdateForFrame:frame] ||
          [_anchorInterpolator hasUpdateForFrame:frame] ||
          [_scaleInterpolator hasUpdateForFrame:frame] ||
          [_rotationInterpolator hasUpdateForFrame:frame]);
}

- (CATransform3D)transformForFrame:(NSNumber *)frame {
  CATransform3D baseXform = CATransform3DIdentity;
  if (_inputNode) {
    baseXform = [_inputNode transformForFrame:frame];
  }
  CGPoint position = CGPointZero;
  if (_positionInterpolator) {
    position = [_positionInterpolator pointValueForFrame:frame];
  }
  if (_positionXInterpolator &&
      _positionYInterpolator) {
    position.x = [_positionXInterpolator floatValueForFrame:frame];
    position.y = [_positionYInterpolator floatValueForFrame:frame];
  }
  CGPoint anchor = [_anchorInterpolator pointValueForFrame:frame];
  CGSize scale = [_scaleInterpolator sizeValueForFrame:frame];
  CGFloat rotation = [_rotationInterpolator floatValueForFrame:frame];
  CATransform3D translateXform = CATransform3DTranslate(baseXform, position.x, position.y, 0);
  CATransform3D rotateXform = CATransform3DRotate(translateXform, rotation, 0, 0, 1);
  CATransform3D scaleXform = CATransform3DScale(rotateXform, scale.width, scale.height, 1);
  CATransform3D anchorXform = CATransform3DTranslate(scaleXform, -1 * anchor.x, -1 * anchor.y, 0);
//    NSLog(@"Name:%@ frame:%d position:%@ rotation:%f scale:%@ anchor:%@", _parentKeyName, frame.intValue, NSStringFromCGPoint(position), rotation, NSStringFromCGSize(scale), NSStringFromCGPoint(anchor));
  return anchorXform;
}

@end
