//
//  RDLOTLayer.m
//  RDLottieAnimator
//
//  Created by Brandon Withrow on 12/14/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "RDLOTLayer.h"
#import "RDLOTAsset.h"
#import "RDLOTAssetGroup.h"
#import "RDLOTShapeGroup.h"
#import "RDLOTEffectGroup.h"
#import "RDLOTComposition.h"
#import "RDLOTHelpers.h"
#import "RDLOTMask.h"
#import "RDLOTHelpers.h"

@implementation RDLOTLayer

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary
              withAssetGroup:(RDLOTAssetGroup *)assetGroup
               withFramerate:(NSNumber *)framerate
               withFrameSize:(CGSize) frameSize{
  self = [super init];
  if (self) {
    [self _mapFromJSON:jsonDictionary
     withAssetGroup:assetGroup
     withFramerate:framerate
     withFrameSize:frameSize];
  }
  return self;
}

- (void)_mapFromJSON:(NSDictionary *)jsonDictionary
      withAssetGroup:(RDLOTAssetGroup *)assetGroup
       withFramerate:(NSNumber *)framerate
       withFrameSize:(CGSize) frameSize{

  _layerName = [jsonDictionary[@"nm"] copy];
  _layerID = [jsonDictionary[@"ind"] copy];
  
  NSNumber *layerType = jsonDictionary[@"ty"];
  _layerType = layerType.integerValue;
  
  if (jsonDictionary[@"refId"]) {
    _referenceID = [jsonDictionary[@"refId"] copy];
  }
  
  _parentID = [jsonDictionary[@"parent"] copy];
  
  if (jsonDictionary[@"st"]) {
    _startFrame = [jsonDictionary[@"st"] copy];
  }
  _inFrame = [jsonDictionary[@"ip"] copy];
  _outFrame = [jsonDictionary[@"op"] copy];

  if (jsonDictionary[@"sr"]) {
    _timeStretch = [jsonDictionary[@"sr"] copy];
  } else {
    _timeStretch = @1;
  }

  if (_layerType == RDLOTLayerTypePrecomp) {
    _layerHeight = [jsonDictionary[@"h"] copy];
    _layerWidth = [jsonDictionary[@"w"] copy];
    [assetGroup buildAssetNamed:_referenceID withFramerate:framerate];
  } else if (_layerType == RDLOTLayerTypeImage) {
    [assetGroup buildAssetNamed:_referenceID withFramerate:framerate];
    _imageAsset = [assetGroup assetModelForID:_referenceID];
    _layerWidth = [_imageAsset.assetWidth copy];
    _layerHeight = [_imageAsset.assetHeight copy];
  } else if (_layerType == RDLOTLayerTypeSolid) {
    _layerWidth = jsonDictionary[@"sw"];
    _layerHeight = jsonDictionary[@"sh"];
    NSString *solidColor = jsonDictionary[@"sc"];
    _solidColor = [UIColor RDLOT_colorWithHexString:solidColor];
  }
  
  _layerBounds = CGRectMake(0, 0, _layerWidth.floatValue, _layerHeight.floatValue);
  
  NSDictionary *ks = jsonDictionary[@"ks"];
    NSLog(@"layerName:%@", _layerName);
  NSDictionary *opacity = ks[@"o"];
  if (opacity) {
    _opacity = [[RDLOTKeyframeGroup alloc] initWithData:opacity];
    [_opacity remapKeyframesWithBlock:^CGFloat(CGFloat inValue) {
      return RDLOT_RemapValue(inValue, 0, 100, 0, 1);
    }];
      [_opacity.keyframes enumerateObjectsUsingBlock:^(RDLOTKeyframe * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
          NSLog(@"_opacity %d keyframeTime:%d", idx, obj.keyframeTime.intValue);
      }];
  }

  NSDictionary *timeRemap = jsonDictionary[@"tm"];
  if (timeRemap) {
    _timeRemapping = [[RDLOTKeyframeGroup alloc] initWithData:timeRemap];
    [_timeRemapping remapKeyframesWithBlock:^CGFloat(CGFloat inValue) {
      return inValue * framerate.doubleValue;
    }];
      [_timeRemapping.keyframes enumerateObjectsUsingBlock:^(RDLOTKeyframe * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
          NSLog(@"_timeRemapping %d keyframeTime:%d", idx, obj.keyframeTime.intValue);
      }];
  }
  
  NSDictionary *rotation = ks[@"r"];
  if (rotation == nil) {
    rotation = ks[@"rz"];
  }
  if (rotation) {
    _rotation = [[RDLOTKeyframeGroup alloc] initWithData:rotation];
    [_rotation remapKeyframesWithBlock:^CGFloat(CGFloat inValue) {
      return RDLOT_DegreesToRadians(inValue);
    }];
      [_rotation.keyframes enumerateObjectsUsingBlock:^(RDLOTKeyframe * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
          NSLog(@"_rotation %d keyframeTime:%d", idx, obj.keyframeTime.intValue);
      }];
  }
  
  NSDictionary *position = ks[@"p"];
  if ([position[@"s"] boolValue]) {
    // Separate dimensions
    _positionX = [[RDLOTKeyframeGroup alloc] initWithData:position[@"x"]];
    _positionY = [[RDLOTKeyframeGroup alloc] initWithData:position[@"y"]];
      [_positionX.keyframes enumerateObjectsUsingBlock:^(RDLOTKeyframe * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
          NSLog(@"_positionX %d keyframeTime:%d", idx, obj.keyframeTime.intValue);
      }];
      [_positionY.keyframes enumerateObjectsUsingBlock:^(RDLOTKeyframe * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
          NSLog(@"_positionY %d keyframeTime:%d", idx, obj.keyframeTime.intValue);
      }];
  } else {
    _position = [[RDLOTKeyframeGroup alloc] initWithData:position ];
      [_position.keyframes enumerateObjectsUsingBlock:^(RDLOTKeyframe * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
          NSLog(@"_position %d keyframeTime:%d", idx, obj.keyframeTime.intValue);
      }];
  }
  
  NSDictionary *anchor = ks[@"a"];
  if (anchor) {
    _anchor = [[RDLOTKeyframeGroup alloc] initWithData:anchor];
      [_anchor.keyframes enumerateObjectsUsingBlock:^(RDLOTKeyframe * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
          NSLog(@"_anchor %d keyframeTime:%d", idx, obj.keyframeTime.intValue);
      }];
  }
  
  NSDictionary *scale = ks[@"s"];
  if (scale) {
    _scale = [[RDLOTKeyframeGroup alloc] initWithData:scale];
    [_scale remapKeyframesWithBlock:^CGFloat(CGFloat inValue) {
      return RDLOT_RemapValue(inValue, -100, 100, -1, 1);
    }];
      [_scale.keyframes enumerateObjectsUsingBlock:^(RDLOTKeyframe * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
          NSLog(@"_scale %d keyframeTime:%d", idx, obj.keyframeTime.intValue);
      }];
  }
  
  _matteType = [jsonDictionary[@"tt"] integerValue];
  
  
  NSMutableArray *masks = [NSMutableArray array];
  for (NSDictionary *maskJSON in jsonDictionary[@"masksProperties"]) {
    RDLOTMask *mask = [[RDLOTMask alloc] initWithJSON:maskJSON];
    [masks addObject:mask];
  }
  _masks = masks.count ? masks : nil;
  
  NSMutableArray *shapes = [NSMutableArray array];
  for (NSDictionary *shapeJSON in jsonDictionary[@"shapes"]) {
    id shapeItem = [RDLOTShapeGroup shapeItemWithJSON:shapeJSON];
    if (shapeItem) {
      [shapes addObject:shapeItem];
    }
  }
  _shapes = shapes;
    
  NSArray *effects = jsonDictionary[@"ef"];
  NSString *name0 = jsonDictionary[@"nm"];
  if (effects.count > 0) {
    
    NSDictionary *effectNames = @{ @0: @"slider",
                                   @1: @"angle",
                                   @2: @"color",
                                   @3: @"point",
                                   @4: @"checkbox",
                                   @5: @"group",
                                   @6: @"noValue",
                                   @7: @"dropDown",
                                   @9: @"customValue",
                                   @10: @"layerIndex",
                                   @20: @"tint",
                                   @21: @"fill",
                                   @29: @"gaussian",
                                   };
      
#if 0
    for (NSDictionary *effect in effects) {
      NSNumber *typeNumber = effect[@"ty"];
      NSString *name = effect[@"nm"];
      NSString *internalName = effect[@"mn"];
      NSString *typeString = effectNames[typeNumber];
      if (typeString) {
        NSLog(@"%s: Warning: %@ effect not supported: %@ / %@", __PRETTY_FUNCTION__, typeString, internalName, name);
      }
    }
#else
      NSMutableArray *ef = [NSMutableArray array];
      for (NSDictionary *effectJson in effects) {
          NSNumber *typeNumber = effectJson[@"ty"];
          NSString *name = effectJson[@"nm"];
          NSString *internalName = effectJson[@"mn"];
          NSString *typeString = effectNames[typeNumber];
          if (typeString) {
              NSLog(@"%s: Warning: %@ effect not supported: %@ / %@", __PRETTY_FUNCTION__, typeString, internalName, name);
          }
          
          //effect
          id effectItem = [[RDLOTEffectGroup alloc] initWithJSON:effectJson withFrameSize:frameSize];
          if (effectItem)
              [ef addObject:effectItem];
      }
      _effects = ef;
      for (int x = 0;x < _effects.count;x++)
      {
          RDLOTEffectGroup* e = _effects[x];
          NSLog(@"%p x:%d name:%s ----------------------",_effects,x,[e.keyname UTF8String]);
      }
#endif
  }
}

- (NSString *)description {
    NSMutableString *text = [[super description] mutableCopy];
    [text appendFormat:@" %@ id: %d pid: %d frames: %d-%d", _layerName, (int)_layerID.integerValue, (int)_parentID.integerValue,
     (int)_inFrame.integerValue, (int)_outFrame.integerValue];
    return text;
}

- (void)refreshInFrame:(NSNumber *)newInFrame outFrame:(NSNumber *)newOutFrame {
    _inFrame = newInFrame;
    if (newOutFrame.intValue > 0) {
        _outFrame = newOutFrame;
    }
    NSLog(@"LAYER:%@ inFrame:%d outFrame:%d", self, newInFrame.intValue, newOutFrame.intValue);
}

@end
