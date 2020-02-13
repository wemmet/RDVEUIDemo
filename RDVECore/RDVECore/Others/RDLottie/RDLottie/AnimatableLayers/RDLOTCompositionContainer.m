//
//  RDLOTCompositionContainer.m
//  RDLottie
//
//  Created by brandon_withrow on 7/18/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTCompositionContainer.h"
#import "RDLOTAsset.h"
#import "CGGeometry+RDLOTAdditions.h"
#import "RDLOTHelpers.h"
#import "RDLOTValueInterpolator.h"
#import "RDLOTAnimatorNode.h"
#import "RDLOTRenderNode.h"
#import "RDLOTRenderGroup.h"
#import "RDLOTNumberInterpolator.h"

@implementation RDLOTCompositionContainer {
  NSNumber *_frameOffset;
  CALayer *DEBUG_Center;
  NSMutableDictionary *_keypathCache;
  RDLOTNumberInterpolator *_timeInterpolator;
    NSNumber *_endFrame;
}
static NSMutableArray *framesArray;

- (instancetype)initWithModel:(RDLOTLayer *)layer
                 inLayerGroup:(RDLOTLayerGroup *)layerGroup
               withLayerGroup:(RDLOTLayerGroup *)childLayerGroup
              withAssestGroup:(RDLOTAssetGroup *)assetGroup
                 withEndFrame:(NSNumber *)endFrame
{
  self = [super initWithModel:layer inLayerGroup:layerGroup];
  if (self) {
      _endFrame = endFrame;
      _currentLayer = layer;
      if (!layer) {
          [framesArray removeAllObjects];
          framesArray = nil;
      }
    DEBUG_Center = [CALayer layer];
    
    DEBUG_Center.bounds = CGRectMake(0, 0, 20, 20);
    DEBUG_Center.borderColor = [UIColor orangeColor].CGColor;
    DEBUG_Center.borderWidth = 2;
    DEBUG_Center.masksToBounds = YES;
    if (ENABLE_DEBUG_SHAPES) {
      [self.wrapperLayer addSublayer:DEBUG_Center];
    }
    if (layer.startFrame) {
      _frameOffset = layer.startFrame;
    } else {
      _frameOffset = @0;
    }

    if (layer.timeRemapping) {
      _timeInterpolator = [[RDLOTNumberInterpolator alloc] initWithKeyframes:layer.timeRemapping.keyframes];
    }

    [self initializeWithChildGroup:childLayerGroup withAssetGroup:assetGroup];
  }
  return self;
}

- (void)initializeWithChildGroup:(RDLOTLayerGroup *)childGroup
                  withAssetGroup:(RDLOTAssetGroup *)assetGroup {
  NSMutableDictionary *childMap = [NSMutableDictionary dictionary];
  NSMutableArray *children = [NSMutableArray array];
  NSArray *reversedItems = [[childGroup.layers reverseObjectEnumerator] allObjects];
//    NSLog(@"reversedItems.count:%d", reversedItems.count);
  CALayer *maskedLayer = nil;

//  for (RDLOTLayer *layer in reversedItems) {
  for (int i = 0; i < reversedItems.count; i++) {//20180622 wuxiaoxia
    RDLOTLayer *layer = reversedItems[i];
    RDLOTAsset *asset;

    if (layer.referenceID) {
      // Get relevant Asset
      asset = [assetGroup assetModelForID:layer.referenceID];
    }

      NSLog(@"i[%d] layerName:%@ referenceID:%@ inFrame:%@ outFrame:%@", i, layer.layerName, layer.referenceID, layer.inFrame, layer.outFrame);
    RDLOTLayerContainer *child = nil;
    if (asset.layerGroup) {
//        if (layer.outFrame != _endFrame) {
//            isSubComp = YES;
//        }
      // Layer is a precomp
        NSLog(@" Layer is a precomp-------%@-------- inFrame:%@ outFrame:%@", layer.referenceID, layer.inFrame, layer.outFrame);
      RDLOTCompositionContainer *compLayer = [[RDLOTCompositionContainer alloc] initWithModel:layer inLayerGroup:childGroup withLayerGroup:asset.layerGroup withAssestGroup:assetGroup withEndFrame:_endFrame];
      child = compLayer;
    } else {
      child = [[RDLOTLayerContainer alloc] initWithModel:layer inLayerGroup:childGroup];
    }
    if (maskedLayer) {
      maskedLayer.mask = child;
      maskedLayer = nil;
    } else {
      if (layer.matteType == RDLOTMatteTypeAdd) {
        maskedLayer = child;
      }
      [self.wrapperLayer addSublayer:child];
    }
    [children addObject:child];
    if (child.layerName) {
      [childMap setObject:child forKey:child.layerName];
    }
//      if (i == reversedItems.count - 1) {
//          isSubComp = NO;
//      }
  }
  _childMap = childMap;
  _childLayers = children;
}

- (void)refreshEndFrame:(NSNumber *)endFrame {
    _endFrame = endFrame;
}

//  判断是否以汉字开头
- (BOOL)isChineseFirst:(NSString *)str {
    int utfCode = 0;
    void *buffer = &utfCode;
    NSRange range = NSMakeRange(0, 1);
    BOOL b = [str getBytes:buffer maxLength:2 usedLength:NULL encoding:NSUTF16LittleEndianStringEncoding options:NSStringEncodingConversionExternalRepresentation range:range remainingRange:NULL];
    if (b && (utfCode >= 0x4e00 && utfCode <= 0x9fa5)){
        return YES;
    }else{
        return NO;
    }
}

- (BOOL)checkIsChinese:(NSString *)string{
    for (int i=0; i<string.length; i++) {
        unichar ch = [string characterAtIndex:i];
        if (0x4E00 <= ch  && ch <= 0x9FA5) {
            return YES;
        }
    }
    return NO;
}

- (void)displayWithFrame:(NSNumber *)frame forceUpdate:(BOOL)forceUpdate {
  if (ENABLE_DEBUG_LOGGING) NSLog(@"-------------------- Composition Displaying Frame %@ --------------------", frame);
  [super displayWithFrame:frame forceUpdate:forceUpdate];
  NSNumber *newFrame = @((frame.floatValue  - _frameOffset.floatValue) / self.timeStretchFactor.floatValue);
  if (_timeInterpolator) {
    newFrame = @([_timeInterpolator floatValueForFrame:newFrame]);
  }
//    double time = CACurrentMediaTime();
  for (RDLOTLayerContainer *child in _childLayers) {
    [child displayWithFrame:newFrame forceUpdate:forceUpdate];
  }
//    NSLog(@"lottie 耗时:%f", CACurrentMediaTime() - time);
//  if (ENABLE_DEBUG_LOGGING) NSLog(@"-------------------- ------------------------------- --------------------");
//  if (ENABLE_DEBUG_LOGGING) NSLog(@"-------------------- ------------------------------- --------------------");
}

- (void)setViewportBounds:(CGRect)viewportBounds {
  [super setViewportBounds:viewportBounds];
  for (RDLOTLayerContainer *layer in _childLayers) {
    layer.viewportBounds = viewportBounds;
  }
}

- (void)searchNodesForKeypath:(RDLOTKeypath * _Nonnull)keypath {
  if (self.layerName != nil) {
    [super searchNodesForKeypath:keypath];
  }
  if (self.layerName == nil ||
      [keypath pushKey:self.layerName]) {
    for (RDLOTLayerContainer *child in _childLayers) {
      [child searchNodesForKeypath:keypath];
    }
    if (self.layerName != nil) {
      [keypath popKey];
    }
  }
}

- (void)setValueDelegate:(id<RDLOTValueDelegate> _Nonnull)delegate
              forKeypath:(RDLOTKeypath * _Nonnull)keypath {
  if (self.layerName != nil) {
    [super setValueDelegate:delegate forKeypath:keypath];
  }
  if (self.layerName == nil ||
      [keypath pushKey:self.layerName]) {
    for (RDLOTLayerContainer *child in _childLayers) {
      [child setValueDelegate:delegate forKeypath:keypath];
    }
    if (self.layerName != nil) {
      [keypath popKey];
    }
  }
}

- (nullable NSArray *)keysForKeyPath:(nonnull RDLOTKeypath *)keypath {
  if (_keypathCache == nil) {
    _keypathCache = [NSMutableDictionary dictionary];
  }
  [self searchNodesForKeypath:keypath];
  [_keypathCache addEntriesFromDictionary:keypath.searchResults];
  return keypath.searchResults.allKeys;
}

- (CALayer *)_layerForKeypath:(nonnull RDLOTKeypath *)keypath {
  id node = _keypathCache[keypath.absoluteKeypath];
  if (node == nil) {
    [self keysForKeyPath:keypath];
    node = _keypathCache[keypath.absoluteKeypath];
  }
  if (node == nil) {
    NSLog(@"RDLOTComposition could not find layer for keypath:%@", keypath.absoluteKeypath);
    return nil;
  }
  if ([node isKindOfClass:[CALayer class]]) {
    return (CALayer *)node;
  }
  if (![node isKindOfClass:[RDLOTRenderNode class]]) {
    NSLog(@"RDLOTComposition: Keypath return non-layer node:%@ ", keypath.absoluteKeypath);
    return nil;
  }
  if ([node isKindOfClass:[RDLOTRenderGroup class]]) {
    return [(RDLOTRenderGroup *)node containerLayer];
  }
  RDLOTRenderNode *renderNode = (RDLOTRenderNode *)node;
  return renderNode.outputLayer;
}

- (CGPoint)convertPoint:(CGPoint)point
         toKeypathLayer:(nonnull RDLOTKeypath *)keypath
        withParentLayer:(CALayer *_Nonnull)parent{
  CALayer *layer = [self _layerForKeypath:keypath];
  if (!layer) {
    return CGPointZero;
  }
  return [parent convertPoint:point toLayer:layer];
}

- (CGRect)convertRect:(CGRect)rect
       toKeypathLayer:(nonnull RDLOTKeypath *)keypath
      withParentLayer:(CALayer *_Nonnull)parent{
  CALayer *layer = [self _layerForKeypath:keypath];
  if (!layer) {
    return CGRectZero;
  }
  return [parent convertRect:rect toLayer:layer];
}

- (CGPoint)convertPoint:(CGPoint)point
       fromKeypathLayer:(nonnull RDLOTKeypath *)keypath
        withParentLayer:(CALayer *_Nonnull)parent{
  CALayer *layer = [self _layerForKeypath:keypath];
  if (!layer) {
    return CGPointZero;
  }
  return [parent convertPoint:point fromLayer:layer];
}

- (CGRect)convertRect:(CGRect)rect
     fromKeypathLayer:(nonnull RDLOTKeypath *)keypath
      withParentLayer:(CALayer *_Nonnull)parent{
  CALayer *layer = [self _layerForKeypath:keypath];
  if (!layer) {
    return CGRectZero;
  }
  return [parent convertRect:rect fromLayer:layer];
}

- (void)addSublayer:(nonnull CALayer *)subLayer
     toKeypathLayer:(nonnull RDLOTKeypath *)keypath {
  CALayer *layer = [self _layerForKeypath:keypath];
  if (layer) {
    [layer addSublayer:subLayer];
  }
}

- (void)maskSublayer:(nonnull CALayer *)subLayer
      toKeypathLayer:(nonnull RDLOTKeypath *)keypath {
  CALayer *layer = [self _layerForKeypath:keypath];
  if (layer) {
    [layer.superlayer addSublayer:subLayer];
    [layer removeFromSuperlayer];
    subLayer.mask = layer;
  }
}

- (void)clear {
    [_childLayers enumerateObjectsUsingBlock:^(RDLOTLayerContainer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        NSLog(@"%@", obj);
        obj.changedDlegate = nil;
        obj.wrapperLayer.contents = nil;
        [obj removeFromSuperlayer];
        [obj clear];
    }];
}

- (void)dealloc {
//    NSLog(@"%s%@", __func__,self);
}

@end
