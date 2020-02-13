//
//  RDLOTLayerContainer.m
//  RDLottie
//
//  Created by brandon_withrow on 7/18/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTLayerContainer.h"
#import "RDLOTTransformInterpolator.h"
#import "RDLOTNumberInterpolator.h"
#import "CGGeometry+RDLOTAdditions.h"
#import "RDLOTRenderGroup.h"
#import "RDLOTHelpers.h"
#import "RDLOTMaskContainer.h"
#import "RDLOTAsset.h"

#if TARGET_OS_IPHONE || TARGET_OS_SIMULATOR
#import "RDLOTCacheProvider.h"
#endif

@implementation RDLOTLayerContainer {
  RDLOTTransformInterpolator *_transformInterpolator;
  RDLOTNumberInterpolator *_opacityInterpolator;
//  NSNumber *_inFrame;
//  NSNumber *_outFrame;
  CALayer *DEBUG_Center;
  RDLOTRenderGroup *_contentsGroup;
  RDLOTMaskContainer *_maskLayer;
}

@dynamic currentFrame;

- (instancetype)initWithModel:(RDLOTLayer *)layer
                 inLayerGroup:(RDLOTLayerGroup *)layerGroup {
  self = [super init];
  if (self) {
    _wrapperLayer = [CALayer new];
    [self addSublayer:_wrapperLayer];
    DEBUG_Center = [CALayer layer];
    
    DEBUG_Center.bounds = CGRectMake(0, 0, 20, 20);
    DEBUG_Center.borderColor = [UIColor blueColor].CGColor;
    DEBUG_Center.borderWidth = 2;
    DEBUG_Center.masksToBounds = YES;
    
    if (ENABLE_DEBUG_SHAPES) {
      [_wrapperLayer addSublayer:DEBUG_Center];
    } 
    self.actions = @{@"hidden" : [NSNull null], @"opacity" : [NSNull null], @"transform" : [NSNull null]};
    _wrapperLayer.actions = [self.actions copy];
    _timeStretchFactor = @1;
    [self commonInitializeWith:layer inLayerGroup:layerGroup];
  }
  return self;
}

- (void)commonInitializeWith:(RDLOTLayer *)layer
                inLayerGroup:(RDLOTLayerGroup *)layerGroup {
  if (layer == nil) {
    return;
  }
    _layer = layer;
  _layerName = layer.layerName;
  if (layer.layerType == RDLOTLayerTypeImage ||
      layer.layerType == RDLOTLayerTypeSolid ||
      layer.layerType == RDLOTLayerTypePrecomp) {
    _wrapperLayer.bounds = CGRectMake(0, 0, layer.layerWidth.floatValue, layer.layerHeight.floatValue);
    _wrapperLayer.anchorPoint = CGPointMake(0, 0);
    _wrapperLayer.masksToBounds = YES;
    DEBUG_Center.position = RDLOT_RectGetCenterPoint(self.bounds);
  }
  
  if (layer.layerType == RDLOTLayerTypeImage) {
    [self _setImageForAsset:layer.imageAsset];
  }
  
  _inFrame = [layer.inFrame copy];
  _outFrame = [layer.outFrame copy];

  _timeStretchFactor = [layer.timeStretch copy];
  _transformInterpolator = [RDLOTTransformInterpolator transformForLayer:layer];

  if (layer.parentID) {
    NSNumber *parentID = layer.parentID;
    RDLOTTransformInterpolator *childInterpolator = _transformInterpolator;
    while (parentID != nil) {
      RDLOTLayer *parentModel = [layerGroup layerModelForID:parentID];
      RDLOTTransformInterpolator *interpolator = [RDLOTTransformInterpolator transformForLayer:parentModel];
      childInterpolator.inputNode = interpolator;
      childInterpolator = interpolator;
      parentID = parentModel.parentID;
    }
  }
  _opacityInterpolator = [[RDLOTNumberInterpolator alloc] initWithKeyframes:layer.opacity.keyframes];
  if (layer.layerType == RDLOTLayerTypeShape &&
      layer.shapes.count) {
    [self buildContents:layer.shapes];
  }

#if 0
    if(layer && _layer.effects.count && _wrapperLayer.contents)
        [self buildContents:_layer.effects];

#endif
    
  if (layer.layerType == RDLOTLayerTypeSolid) {
    _wrapperLayer.backgroundColor = layer.solidColor.CGColor;
  }
  if (layer.masks.count) {
    _maskLayer = [[RDLOTMaskContainer alloc] initWithMasks:layer.masks];
    _wrapperLayer.mask = _maskLayer;
  }
  
  NSMutableDictionary *interpolators = [NSMutableDictionary dictionary];
  interpolators[@"Opacity"] = _opacityInterpolator;
  interpolators[@"Anchor Point"] = _transformInterpolator.anchorInterpolator;
  interpolators[@"Scale"] = _transformInterpolator.scaleInterpolator;
  interpolators[@"Rotation"] = _transformInterpolator.rotationInterpolator;
  if (_transformInterpolator.positionXInterpolator &&
      _transformInterpolator.positionYInterpolator) {
    interpolators[@"X Position"] = _transformInterpolator.positionXInterpolator;
    interpolators[@"Y Position"] = _transformInterpolator.positionYInterpolator;
  } else if (_transformInterpolator.positionInterpolator) {
    interpolators[@"Position"] = _transformInterpolator.positionInterpolator;
  }

  // Deprecated
  interpolators[@"Transform.Opacity"] = _opacityInterpolator;
  interpolators[@"Transform.Anchor Point"] = _transformInterpolator.anchorInterpolator;
  interpolators[@"Transform.Scale"] = _transformInterpolator.scaleInterpolator;
  interpolators[@"Transform.Rotation"] = _transformInterpolator.rotationInterpolator;
  if (_transformInterpolator.positionXInterpolator &&
      _transformInterpolator.positionYInterpolator) {
    interpolators[@"Transform.X Position"] = _transformInterpolator.positionXInterpolator;
    interpolators[@"Transform.Y Position"] = _transformInterpolator.positionYInterpolator;
  } else if (_transformInterpolator.positionInterpolator) {
    interpolators[@"Transform.Position"] = _transformInterpolator.positionInterpolator;
  }
  _valueInterpolators = interpolators;
}

- (void)buildContents:(NSArray *)contents {
  _contentsGroup = [[RDLOTRenderGroup alloc] initWithInputNode:nil contents:contents keyname:_layerName Layer:_wrapperLayer];
  [_wrapperLayer addSublayer:_contentsGroup.containerLayer];
}

- (void)refreshContents:(NSArray *)contents {
    if (_contentsGroup) {
        [_contentsGroup refreshContents:_wrapperLayer];
    }else {
        [self buildContents:contents];
    }
}

#if TARGET_OS_IPHONE || TARGET_OS_SIMULATOR

- (void)_setImageForAsset:(RDLOTAsset *)asset {
  if (asset.imageName) {
    UIImage *image;
    if (asset.rootDirectory.length > 0) {
      NSString *rootDirectory  = asset.rootDirectory;
      if (asset.imageDirectory.length > 0) {
        rootDirectory = [rootDirectory stringByAppendingPathComponent:asset.imageDirectory];
      }
      NSString *imagePath = [rootDirectory stringByAppendingPathComponent:asset.imageName];
        
      id<RDLOTImageCache> imageCache = [RDLOTCacheProvider imageCache];
      if (imageCache) {
        image = [imageCache imageForKey:imagePath];
        if (!image) {
#if 1
            NSData *data = [NSData dataWithContentsOfFile:imagePath];
            image = [UIImage imageWithData:data];
            data = nil;
#else
          image = [UIImage imageWithContentsOfFile:imagePath];
#endif
          [imageCache setImage:image forKey:imagePath];
        }
      } else {
#if 1
          NSData *data = [NSData dataWithContentsOfFile:imagePath];
          image = [UIImage imageWithData:data];
          data = nil;
#else
          image = [UIImage imageWithContentsOfFile:imagePath];
#endif
      }
    } else {
        NSString *imagePath = [asset.assetBundle pathForResource:asset.imageName ofType:nil];
#if 1
        NSData *data = [NSData dataWithContentsOfFile:imagePath];
        image = [UIImage imageWithData:data];
        data = nil;
#else
        image = [UIImage imageWithContentsOfFile:imagePath];
#endif
        if(!image) {
            image = [UIImage imageNamed:asset.imageName inBundle: asset.assetBundle compatibleWithTraitCollection:nil];
        }
    }
    
    if (image) {
        
#if 0

        UIImage *uiImage = image;
        CIImage * inputImg = [[CIImage alloc] initWithImage:uiImage];
        CIFilter * filter = [CIFilter filterWithName:@"CIColorInvert"];
        // 设置滤镜属性值为默认值
        [filter setDefaults];
        // 设置输入图像
        [filter setValue:inputImg forKey:@"inputImage"];
        // 获取输出图像
        CIImage * outputImg = [filter valueForKey:@"outputImage"];
        CIContext * context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}];
        CGImageRef cgImg = [context createCGImage:outputImg fromRect:outputImg.extent];
        UIImage *resultImg = [UIImage imageWithCGImage:cgImg];
        CGImageRelease(cgImg);
//        self.outputLayer.contents = (__bridge id _Nullable)(resultImg.CGImage);
        _wrapperLayer.contents = (__bridge id _Nullable)(resultImg.CGImage);

//        _wrapperLayer.contents = (__bridge id _Nullable)(image.CGImage);
//        if(_layer.effects.count )
//            [self buildContents:_layer.effects];
#else
        BOOL isRefresh = _wrapperLayer.contents;
      _wrapperLayer.contents = (__bridge id _Nullable)(image.CGImage);
        if(_layer.effects.count) {
            if (isRefresh) {
                [self refreshContents:_layer.effects];
            }else {
              [self buildContents:_layer.effects];
            }
        }
#endif
        
    } else {
      NSLog(@"%s: Warn: image not found: %@", __PRETTY_FUNCTION__, asset.imageName);
    }
  }
}

#else

- (void)_setImageForAsset:(RDLOTAsset *)asset {
  if (asset.imageName) {
    NSArray *components = [asset.imageName componentsSeparatedByString:@"."];
    NSImage *image = [NSImage imageNamed:components.firstObject];
    if (image) {
      NSWindow *window = [NSApp mainWindow];
      CGFloat desiredScaleFactor = [window backingScaleFactor];
      CGFloat actualScaleFactor = [image recommendedLayerContentsScale:desiredScaleFactor];
      id layerContents = [image layerContentsForContentsScale:actualScaleFactor];
      _wrapperLayer.contents = layerContents;
    }
  }
  
}

#endif

// MARK - Animation

+ (BOOL)needsDisplayForKey:(NSString *)key {
  if ([key isEqualToString:@"currentFrame"]) {
    return YES;
  }
  return [super needsDisplayForKey:key];
}

- (id<CAAction>)actionForKey:(NSString *)event {
  if ([event isEqualToString:@"currentFrame"]) {
    CABasicAnimation *theAnimation = [CABasicAnimation
                                      animationWithKeyPath:event];
    theAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    theAnimation.fromValue = [[self presentationLayer] valueForKey:event];
    return theAnimation;
  }
  return [super actionForKey:event];
}

- (id)initWithLayer:(id)layer {
  if (self = [super initWithLayer:layer]) {
    if ([layer isKindOfClass:[RDLOTLayerContainer class]]) {
      RDLOTLayerContainer *other = (RDLOTLayerContainer *)layer;
      self.currentFrame = [other.currentFrame copy];
    }
  }
  return self;
}

- (void)display {
  @synchronized(self) {
    RDLOTLayerContainer *presentation = self;
    if (self.animationKeys.count &&
      self.presentationLayer) {
        presentation = (RDLOTLayerContainer *)self.presentationLayer;
    }
    [self displayWithFrame:presentation.currentFrame];
  }
}

- (void)displayWithFrame:(NSNumber *)frame {
  [self displayWithFrame:frame forceUpdate:NO];
}

- (void)displayWithFrame:(NSNumber *)frame forceUpdate:(BOOL)forceUpdate {
  NSNumber *newFrame = @(frame.floatValue / self.timeStretchFactor.floatValue);
  if (ENABLE_DEBUG_LOGGING) NSLog(@"View %@ Displaying Frame %@, with local time %@", self, frame, newFrame);
  BOOL hidden = NO;
  if (_inFrame && _outFrame) {
    hidden = (frame.floatValue < _inFrame.floatValue ||
              frame.floatValue >= _outFrame.floatValue);//20191023 将>改为>=，因为“酷炫卡点14”第五张图片显示的时候，前一张会同时显示，与预想效果不一致
  }
//    if (ENABLE_DEBUG_LOGGING) NSLog(@"%@ currentFrame:%d in:%d out:%d hidden:%@ %@", self.layerName, frame.intValue, _inFrame.intValue, _outFrame.intValue, (hidden ? @"YES" : @"NO"), _wrapperLayer.contents);
  self.hidden = hidden;
  if (hidden) {
    return;
  }
  if (_opacityInterpolator && [_opacityInterpolator hasUpdateForFrame:newFrame]) {
    self.opacity = [_opacityInterpolator floatValueForFrame:newFrame];
  }
  if (_transformInterpolator && [_transformInterpolator hasUpdateForFrame:newFrame]) {
    _wrapperLayer.transform = [_transformInterpolator transformForFrame:newFrame];
  }
  #if 1
      if (_wrapperLayer && _layer.layerType == RDLOTLayerTypeImage && _changedDlegate && [_changedDlegate respondsToSelector:@selector(changeLayerContents:layerName:)]) {
  //        NSLog(@"layerName:%@ inFrame:%@ outFrame:%@ newFrame:%@", _layer.referenceID, _layer.inFrame, _layer.outFrame, newFrame);
          [_changedDlegate changeLayerContents:_wrapperLayer layerName:_layer.imageAsset.imageName];
      }
  #endif
    
  [_contentsGroup updateWithFrame:newFrame withModifierBlock:nil forceLocalUpdate:forceUpdate];
  _maskLayer.currentFrame = newFrame;
}

- (void)setViewportBounds:(CGRect)viewportBounds {
  _viewportBounds = viewportBounds;
  if (_maskLayer) {
//    CGPoint center = RDLOT_RectGetCenterPoint(viewportBounds);
//    viewportBounds.origin = CGPointMake(-center.x, -center.y);//20191120 修复蒙版显示位置错误的bug
    _maskLayer.bounds = viewportBounds;
  }
}

- (void)searchNodesForKeypath:(RDLOTKeypath * _Nonnull)keypath {
  if (_contentsGroup == nil && [keypath pushKey:self.layerName]) {
    // Matches self.
    if ([keypath pushKey:@"Transform"]) {
      // Is a transform node, check interpolators
      RDLOTValueInterpolator *interpolator = _valueInterpolators[keypath.currentKey];
      if (interpolator) {
        // We have a match!
        [keypath pushKey:keypath.currentKey];
        [keypath addSearchResultForCurrentPath:_wrapperLayer];
        [keypath popKey];
      }
      if (keypath.endOfKeypath) {
        [keypath addSearchResultForCurrentPath:_wrapperLayer];
      }
      [keypath popKey];
    }
    if (keypath.endOfKeypath) {
      [keypath addSearchResultForCurrentPath:_wrapperLayer];
    }
    [keypath popKey];
  }
  [_contentsGroup searchNodesForKeypath:keypath];
}

- (void)setValueDelegate:(id<RDLOTValueDelegate> _Nonnull)delegate
              forKeypath:(RDLOTKeypath * _Nonnull)keypath {
  if ([keypath pushKey:self.layerName]) {
    // Matches self.
    if ([keypath pushKey:@"Transform"]) {
      // Is a transform node, check interpolators
      RDLOTValueInterpolator *interpolator = _valueInterpolators[keypath.currentKey];
      if (interpolator) {
        // We have a match!
        [interpolator setValueDelegate:delegate];
      }
      [keypath popKey];
    }
    [keypath popKey];
  }
  [_contentsGroup setValueDelegate:delegate forKeypath:keypath];
}

- (void)refreshInFrame:(NSNumber *)newInFrame outFrame:(NSNumber *)newOutFrame {
    _inFrame = newInFrame;
    if (newOutFrame.intValue > 0) {
        _outFrame = newOutFrame;
    }
    NSLog(@"%@inFrame:%d outFrame:%d", self, newInFrame.intValue, newOutFrame.intValue);
}

- (void)dealloc {
//    NSLog(@"%s%@", __func__,self);
    _wrapperLayer.contents = nil;
}

- (void)clear {
    _wrapperLayer.contents = nil;
    if (_contentsGroup) {
        [_contentsGroup clear];
    }
}

@end
