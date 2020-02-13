//
//  RDLOTRenderGroup.m
//  RDLottie
//
//  Created by brandon_withrow on 6/27/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTRenderGroup.h"
#import "RDLOTModels.h"
#import "RDLOTPathAnimator.h"
#import "RDLOTFillRenderer.h"
#import "RDLOTStrokeRenderer.h"
#import "RDLOTNumberInterpolator.h"
#import "RDLOTTransformInterpolator.h"
#import "RDLOTCircleAnimator.h"
#import "RDLOTRoundedRectAnimator.h"
#import "RDLOTTrimPathNode.h"
#import "RDLOTShapeStar.h"
#import "RDLOTPolygonAnimator.h"
#import "RDLOTPolystarAnimator.h"
#import "RDLOTShapeGradientFill.h"
#import "RDLOTGradientFillRender.h"
#import "RDLOTRepeaterRenderer.h"
#import "RDLOTShapeRepeater.h"
#import "RDLOTEffectGroup.h"
#import "RDLOTEffectDistortion.h"
#import "RDLOTEffectDistortionRender.h"
#import "RDLOTEffectBlur.h"
#import "RDLOTEffectTint.h"
#import "RDLOTEffectBlurRender.h"
#import "RDLOTEffectTintRender.h"

@implementation RDLOTRenderGroup {
  RDLOTAnimatorNode *_rootNode;
  RDLOTBezierPath *_outputPath;
  RDLOTBezierPath *_localPath;
  BOOL _rootNodeHasUpdate;
  RDLOTNumberInterpolator *_opacityInterpolator;
  RDLOTTransformInterpolator *_transformInterolator;
}

- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode * _Nullable)inputNode
                                   contents:(NSArray * _Nonnull)contents
                                    keyname:(NSString * _Nullable)keyname {
  self = [super initWithInputNode:inputNode keyName:keyname];
  if (self) {
    _containerLayer = [CALayer layer];
//    _containerLayer.bounds = CGRectMake(0, 0, 800 , 1400);
    _containerLayer.actions = @{@"transform": [NSNull null],
                                @"opacity": [NSNull null]};
    [self buildContents:contents Layer:nil];
  }
  return self;
}

- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode * _Nullable)inputNode
                                  contents:(NSArray * _Nonnull)contents
                                   keyname:(NSString * _Nullable)keyname
                                     Layer:(CALayer* _Nonnull)layer{
    
    self = [super initWithInputNode:inputNode keyName:keyname];
    if (self) {
        _containerLayer = [CALayer layer];
        _containerLayer.actions = @{@"transform": [NSNull null],
                                    @"opacity": [NSNull null]};
        [self buildContents:contents Layer:layer];
    }
    return self;
}

- (NSDictionary *)valueInterpolators {
  if (_opacityInterpolator && _transformInterolator) {
    return @{@"Opacity" : _opacityInterpolator,
             @"Position" : _transformInterolator.positionInterpolator,
             @"Scale" : _transformInterolator.scaleInterpolator,
             @"Rotation" : _transformInterolator.scaleInterpolator,
             @"Anchor Point" : _transformInterolator.anchorInterpolator,
             // Deprecated
             @"Transform.Opacity" : _opacityInterpolator,
             @"Transform.Position" : _transformInterolator.positionInterpolator,
             @"Transform.Scale" : _transformInterolator.scaleInterpolator,
             @"Transform.Rotation" : _transformInterolator.scaleInterpolator,
             @"Transform.Anchor Point" : _transformInterolator.anchorInterpolator
             };
  }
  return nil;
}

- (void)buildContents:(NSArray *)contents Layer:(CALayer*)layer {
  RDLOTAnimatorNode *previousNode = nil;
  RDLOTShapeTransform *transform;
  for (id item in contents) {
    if ([item isKindOfClass:[RDLOTShapeFill class]]) {
      RDLOTFillRenderer *fillRenderer = [[RDLOTFillRenderer alloc] initWithInputNode:previousNode
                                                                       shapeFill:(RDLOTShapeFill *)item];
      [self.containerLayer insertSublayer:fillRenderer.outputLayer atIndex:0];
      previousNode = fillRenderer;
    } else if ([item isKindOfClass:[RDLOTShapeStroke class]]) {
      RDLOTStrokeRenderer *strokRenderer = [[RDLOTStrokeRenderer alloc] initWithInputNode:previousNode
                                                                          shapeStroke:(RDLOTShapeStroke *)item];
      [self.containerLayer insertSublayer:strokRenderer.outputLayer atIndex:0];
      previousNode = strokRenderer;
    } else if ([item isKindOfClass:[RDLOTShapePath class]]) {
      RDLOTPathAnimator *pathAnimator = [[RDLOTPathAnimator alloc] initWithInputNode:previousNode
                                                                       shapePath:(RDLOTShapePath *)item];
      previousNode = pathAnimator;
    } else if ([item isKindOfClass:[RDLOTShapeRectangle class]]) {
      RDLOTRoundedRectAnimator *rectAnimator = [[RDLOTRoundedRectAnimator alloc] initWithInputNode:previousNode
                                                                                shapeRectangle:(RDLOTShapeRectangle *)item];
      previousNode = rectAnimator;
    } else if ([item isKindOfClass:[RDLOTShapeCircle class]]) {
      RDLOTCircleAnimator *circleAnimator = [[RDLOTCircleAnimator alloc] initWithInputNode:previousNode
                                                                           shapeCircle:(RDLOTShapeCircle *)item];
      previousNode = circleAnimator;
    } else if ([item isKindOfClass:[RDLOTShapeGroup class]]) {
      RDLOTShapeGroup *shapeGroup = (RDLOTShapeGroup *)item;
      RDLOTRenderGroup *renderGroup = [[RDLOTRenderGroup alloc] initWithInputNode:previousNode contents:shapeGroup.items keyname:shapeGroup.keyname Layer:layer];
      [self.containerLayer insertSublayer:renderGroup.containerLayer atIndex:0];
      previousNode = renderGroup;
    } else if ([item isKindOfClass:[RDLOTShapeTransform class]]) {
      transform = (RDLOTShapeTransform *)item;
    } else if ([item isKindOfClass:[RDLOTShapeTrimPath class]]) {
      RDLOTTrimPathNode *trim = [[RDLOTTrimPathNode alloc] initWithInputNode:previousNode trimPath:(RDLOTShapeTrimPath *)item];
      previousNode = trim;
    } else if ([item isKindOfClass:[RDLOTShapeStar class]]) {
      RDLOTShapeStar *star = (RDLOTShapeStar *)item;
      if (star.type == RDLOTPolystarShapeStar) {
        RDLOTPolystarAnimator *starAnimator = [[RDLOTPolystarAnimator alloc] initWithInputNode:previousNode shapeStar:star];
        previousNode = starAnimator;
      }
      if (star.type == RDLOTPolystarShapePolygon) {
        RDLOTPolygonAnimator *polygonAnimator = [[RDLOTPolygonAnimator alloc] initWithInputNode:previousNode shapePolygon:star];
        previousNode = polygonAnimator;
      }
    } else if ([item isKindOfClass:[RDLOTShapeGradientFill class]]) {
      RDLOTGradientFillRender *gradientFill = [[RDLOTGradientFillRender alloc] initWithInputNode:previousNode shapeGradientFill:(RDLOTShapeGradientFill *)item];
      previousNode = gradientFill;
      [self.containerLayer insertSublayer:gradientFill.outputLayer atIndex:0];
    } else if ([item isKindOfClass:[RDLOTShapeRepeater class]]) {
      RDLOTRepeaterRenderer *repeater = [[RDLOTRepeaterRenderer alloc] initWithInputNode:previousNode shapeRepeater:(RDLOTShapeRepeater *)item];
      previousNode = repeater;
      [self.containerLayer insertSublayer:repeater.outputLayer atIndex:0];
    }
    else if([item isKindOfClass:[RDLOTEffectGroup class]]){

        RDLOTEffectGroup *effectGroup = (RDLOTEffectGroup *)item;
        RDLOTRenderGroup *renderGroup = [[RDLOTRenderGroup alloc] initWithInputNode:previousNode contents:effectGroup.items keyname:effectGroup.keyname Layer:layer];
        [self.containerLayer insertSublayer:renderGroup.containerLayer atIndex:0];
        previousNode = renderGroup;

    }
    else if([item isKindOfClass:[RDLOTEffectTint class]]){

        //色调
        RDLOTEffectTintRender *effect = [[RDLOTEffectTintRender alloc] initWithInputNode:previousNode
                                                                            Effect:(RDLOTEffectTint*)item
                                                                           calayer:layer];
        if(effect)
        {
            [self.containerLayer insertSublayer:effect.outputLayer atIndex:0];
            previousNode = effect;
        }

    }
    else if([item isKindOfClass:[RDLOTEffectBlur class]]){

        //模糊
        RDLOTEffectBlurRender *effect = [[RDLOTEffectBlurRender alloc] initWithInputNode:previousNode
                                                                            Effect:(RDLOTEffectBlur*)item
                                                                           calayer:layer];
        if(effect)
        {
            [self.containerLayer insertSublayer:effect.outputLayer atIndex:0];
            previousNode = effect;
        }

    }
    else if([item isKindOfClass:[RDLOTEffectDistortion class]]){

        //扭曲
        RDLOTEffectDistortionRender *distortion = [[RDLOTEffectDistortionRender alloc] initWithInputNode:previousNode
                                                                                              Effect:(RDLOTEffectDistortion*)item
                                                                                             calayer:layer];
        if(distortion)
        {
            if (distortion.outputLayer.contents)
                [self.containerLayer insertSublayer:distortion.outputLayer atIndex:0];
            
            previousNode = distortion;
        }
        

    }

  }
  if (transform) {
    _opacityInterpolator = [[RDLOTNumberInterpolator alloc] initWithKeyframes:transform.opacity.keyframes];
      _transformInterolator = [[RDLOTTransformInterpolator alloc] initWithPosition:transform.position.keyframes
                                                                          rotation:transform.rotation.keyframes
                                                                            anchor:transform.anchor.keyframes
                                                                             scale:transform.scale.keyframes];
  }
  _rootNode = previousNode;
}

- (void)refreshContents:(CALayer*)layer {
    if([_rootNode isKindOfClass:[RDLOTEffectTintRender class]]){

        //色调
        RDLOTEffectTintRender *effect = (RDLOTEffectTintRender *)_rootNode;
        if(effect)
        {
            [effect refreshContents:layer];
        }
    }
    else if([_rootNode isKindOfClass:[RDLOTEffectBlurRender class]]){

        //模糊
        RDLOTEffectBlurRender *effect = (RDLOTEffectBlurRender *)_rootNode;
        if(effect)
        {
            [effect refreshContents:layer];
        }
    }
    else if ([_rootNode isKindOfClass:[RDLOTEffectDistortionRender class]]) {
        RDLOTEffectDistortionRender *distortion = (RDLOTEffectDistortionRender *)_rootNode;
        if(distortion)
        {
            [distortion refreshContents:layer];
        }
    }
    else if ([_rootNode isKindOfClass:[RDLOTRenderGroup class]]) {
        RDLOTRenderGroup *group = (RDLOTRenderGroup *)_rootNode;
        [group refreshContents:layer];
    }
}

- (BOOL)needsUpdateForFrame:(NSNumber *)frame {
  return ([_opacityInterpolator hasUpdateForFrame:frame] ||
          [_transformInterolator hasUpdateForFrame:frame] ||
          _rootNodeHasUpdate);

}

- (BOOL)updateWithFrame:(NSNumber *)frame withModifierBlock:(void (^ _Nullable)(RDLOTAnimatorNode * _Nonnull))modifier forceLocalUpdate:(BOOL)forceUpdate {
  rdIndentation_level = rdIndentation_level + 1;
    if ([_rootNode isKindOfClass:[RDLOTEffectDistortionRender class]]) {
        //20191121 因为RDLOTEffectDistortionRender中有两层layer(1、原layer 2、处理后的layer),选择的素材是视频的情况，seek的时候，如果不强制刷新，会出现两层layer同时显示的情况
        _rootNodeHasUpdate = [_rootNode updateWithFrame:frame withModifierBlock:modifier forceLocalUpdate:YES];
    }else {
        _rootNodeHasUpdate = [_rootNode updateWithFrame:frame withModifierBlock:modifier forceLocalUpdate:forceUpdate];
    }
  
  rdIndentation_level = rdIndentation_level - 1;
  BOOL update = [super updateWithFrame:frame withModifierBlock:modifier forceLocalUpdate:forceUpdate];
  return update;
}

- (void)performLocalUpdate {
  if (_opacityInterpolator) {
    self.containerLayer.opacity = [_opacityInterpolator floatValueForFrame:self.currentFrame];
  }
  if (_transformInterolator) {
    CATransform3D xform = [_transformInterolator transformForFrame:self.currentFrame];
    self.containerLayer.transform = xform;
    
    CGAffineTransform appliedXform = CATransform3DGetAffineTransform(xform);
    _localPath = [_rootNode.outputPath copy];
    [_localPath RDLOT_applyTransform:appliedXform];
  } else {
    _localPath = [_rootNode.outputPath copy];
  }
}

- (void)rebuildOutputs {
  if (self.inputNode) {
    _outputPath = [self.inputNode.outputPath copy];
    [_outputPath RDLOT_appendPath:self.localPath];
  } else {
    _outputPath = self.localPath;
  }
}

- (void)setPathShouldCacheLengths:(BOOL)pathShouldCacheLengths {
  [super setPathShouldCacheLengths:pathShouldCacheLengths];
  _rootNode.pathShouldCacheLengths = pathShouldCacheLengths;
}

- (RDLOTBezierPath *)localPath {
  return _localPath;
}

- (RDLOTBezierPath *)outputPath {
  return _outputPath;
}

- (void)searchNodesForKeypath:(RDLOTKeypath * _Nonnull)keypath {
  [self.inputNode searchNodesForKeypath:keypath];
  if ([keypath pushKey:self.keyname]) {
    // Matches self. Dig deeper.
    // Check interpolators

    if ([keypath pushKey:@"Transform"]) {
      // Matches a Transform interpolator!
      if (self.valueInterpolators[keypath.currentKey] != nil) {
        [keypath pushKey:keypath.currentKey];
        [keypath addSearchResultForCurrentPath:self];
        [keypath popKey];
      }
      [keypath popKey];
    }

    if (keypath.endOfKeypath) {
      // We have a match!
      [keypath addSearchResultForCurrentPath:self];
    }
    // Check child nodes
    [_rootNode searchNodesForKeypath:keypath];
    [keypath popKey];
  }
}

- (void)setValueDelegate:(id<RDLOTValueDelegate> _Nonnull)delegate
              forKeypath:(RDLOTKeypath * _Nonnull)keypath {
  if ([keypath pushKey:self.keyname]) {
    // Matches self. Dig deeper.
    // Check interpolators
    if ([keypath pushKey:@"Transform"]) {
      // Matches a Transform interpolator!
      RDLOTValueInterpolator *interpolator = self.valueInterpolators[keypath.currentKey];
      if (interpolator) {
        // We have a match!
        [interpolator setValueDelegate:delegate];
      }
      [keypath popKey];
    }

    // Check child nodes
    [_rootNode setValueDelegate:delegate forKeypath:keypath];

    [keypath popKey];
  }

  // Check upstream
  [self.inputNode setValueDelegate:delegate forKeypath:keypath];
}

- (void)clear {
    if ([_rootNode isKindOfClass:[RDLOTEffectDistortionRender class]]) {
        [((RDLOTEffectDistortionRender *)_rootNode) clear];
    }else if ([_rootNode isKindOfClass:[RDLOTRenderGroup class]]) {
        RDLOTRenderGroup *group = (RDLOTRenderGroup *)_rootNode;
        [group clear];
    }
}

@end
