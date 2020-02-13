//
//  RDLOTAnimationView
//  RDLottieAnimator
//
//  Created by Brandon Withrow on 12/14/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "RDLOTAnimationView.h"
#import "RDLOTPlatformCompat.h"
#import "RDLOTModels.h"
#import "RDLOTHelpers.h"
#import "RDLOTAnimationView_Internal.h"
#import "RDLOTAnimationCache.h"
#import "RDLOTCompositionContainer.h"

static NSString * const kCompContainerAnimationKey = @"play";
#define kBackground @"background"
#define kReplaceableText @"ReplaceableText"

@interface RDLOTAnimationView()<RDLOTChangeLayerContentsDelegate>
{
    NSString            * prevName;
}

@end

@implementation RDLOTAnimationView {
  RDLOTCompositionContainer *_compContainer;
  NSNumber *_playRangeStartFrame;
  NSNumber *_playRangeEndFrame;
  CGFloat _playRangeStartProgress;
  CGFloat _playRangeEndProgress;
  NSBundle *_bundle;
  CGFloat _animationProgress;
  // Properties for tracking automatic restoration of animation.
  BOOL _shouldRestoreStateWhenAttachedToWindow;
  RDLOTAnimationCompletionBlock _completionBlockToRestoreWhenAttachedToWindow;
    NSMutableArray *imageNameArray;
    NSMutableArray *imageNameArray1;
    NSMutableArray <RDLOTAnimatedSourceInfo*>*inOutFrameArray;
    NSInteger refreshInOutFrameIndex;
    int oldEndTime;
}

# pragma mark - Convenience Initializers

+ (nonnull instancetype)animationNamed:(nonnull NSString *)animationName {
  return [self animationNamed:animationName inBundle:[NSBundle mainBundle]];
}

+ (nonnull instancetype)animationNamed:(nonnull NSString *)animationName inBundle:(nonnull NSBundle *)bundle {
  RDLOTComposition *comp = [RDLOTComposition animationNamed:animationName inBundle:bundle];
  return [[self alloc] initWithModel:comp inBundle:bundle];
}

+ (nonnull instancetype)animationFromJSON:(nonnull NSDictionary *)animationJSON {
    return [self animationFromJSON:animationJSON inBundle:[NSBundle mainBundle]];
}

+ (nonnull instancetype)animationFromJSON:(nullable NSDictionary *)animationJSON inBundle:(nullable NSBundle *)bundle {
  RDLOTComposition *comp = [RDLOTComposition animationFromJSON:animationJSON inBundle:bundle];
  return [[self alloc] initWithModel:comp inBundle:bundle];
}

+ (instancetype)animationFromJSON:(NSDictionary *)animationJSON rootDirectory:(NSString *)rootDirectory version:(float)version  {
    RDLOTComposition *comp = [RDLOTComposition animationFromJSON:animationJSON inBundle:nil];
    comp.rootDirectory = rootDirectory;
    return [[self alloc] initWithModel:comp inBundle:nil version:version];
}

+ (nonnull instancetype)animationWithFilePath:(nonnull NSString *)filePath {
  RDLOTComposition *comp = [RDLOTComposition animationWithFilePath:filePath];
  return [[self alloc] initWithModel:comp inBundle:[NSBundle mainBundle]];
}

+ (instancetype)animationWithFilePath:(NSString *)filePath rootDirectory:(NSString *)rootDirectory version:(float)version {
    RDLOTComposition *comp = [RDLOTComposition animationWithFilePath:filePath];
    comp.rootDirectory = rootDirectory;
    return [[self alloc] initWithModel:comp inBundle:nil version:version];
}

# pragma mark - Initializers

- (instancetype)initWithContentsOfURL:(NSURL *)url {
  self = [self initWithFrame:CGRectZero];
  if (self) {
    _startTime = 0;
    RDLOTComposition *laScene = [[RDLOTAnimationCache sharedCache] animationForKey:url.absoluteString];
    if (laScene) {
      laScene.cacheKey = url.absoluteString;
      [self _initializeAnimationContainer];
      [self _setupWithSceneModel:laScene];
    } else {
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSData *animationData = [NSData dataWithContentsOfURL:url];
        if (!animationData) {
          return;
        }
        NSError *error;
        NSDictionary  *animationJSON = [NSJSONSerialization JSONObjectWithData:animationData
                                                                       options:0 error:&error];
        if (error || !animationJSON) {
          return;
        }
        
        RDLOTComposition *laScene = [[RDLOTComposition alloc] initWithJSON:animationJSON withAssetBundle:[NSBundle mainBundle]];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
          [[RDLOTAnimationCache sharedCache] addAnimation:laScene forKey:url.absoluteString];
          laScene.cacheKey = url.absoluteString;
          [self _initializeAnimationContainer];
          [self _setupWithSceneModel:laScene];
        });
      });
    }
  }
  return self;
}

- (instancetype)initWithModel:(RDLOTComposition *)model inBundle:(NSBundle *)bundle {
  self = [self initWithFrame:model.compBounds];
  if (self) {
    _bundle = bundle;
    _startTime = 0;
    [self _initializeAnimationContainer];
    [self _setupWithSceneModel:model];
  }
  return self;
}

- (instancetype)initWithModel:(RDLOTComposition *)model inBundle:(NSBundle *)bundle version:(float)version {
  self = [self initWithFrame:model.compBounds];
  if (self) {
    _bundle = bundle;
    _startTime = 0;
      _configVer = version;
    [self _initializeAnimationContainer];
    [self _setupWithSceneModel:model];
  }
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self _commonInit];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self _commonInit];
  }
  return self;
}

# pragma mark - Inspectables

- (void)setAnimation:(NSString *)animationName {
    
    _animation = animationName;
    
    [self setAnimationNamed:animationName];
    
}

# pragma mark - Internal Methods

#if TARGET_OS_IPHONE || TARGET_OS_SIMULATOR

- (void)_initializeAnimationContainer {
  self.clipsToBounds = YES;
}

#else

- (void)_initializeAnimationContainer {
  self.wantsLayer = YES;
}

#endif

- (void)_commonInit {
  _animationSpeed = 1;
  _animationProgress = 0;
  _loopAnimation = NO;
  _autoReverseAnimation = NO;
  _playRangeEndFrame = nil;
  _playRangeStartFrame = nil;
  _playRangeEndProgress = 0;
  _playRangeStartProgress = 0;
}

- (void)_setupWithSceneModel:(RDLOTComposition *)model {
  if (_sceneModel) {
    [self _removeCurrentAnimationIfNecessary];
    [self _callCompletionIfNecessary:NO];
    [_compContainer removeFromSuperlayer];
    _compContainer = nil;
    _sceneModel = nil;
    [self _commonInit];
  }
  
  _sceneModel = model;
  _compContainer = [[RDLOTCompositionContainer alloc] initWithModel:nil inLayerGroup:nil withLayerGroup:_sceneModel.layerGroup withAssestGroup:_sceneModel.assetGroup withEndFrame:model.endFrame];
  [self.layer addSublayer:_compContainer];
  [self _restoreState];
  [self setNeedsLayout];
    NSLog(@"framerate:%d", [_sceneModel.framerate intValue]);
    
    prevName = nil;
    imageNameArray1 = [NSMutableArray array];
    _sourceInfoArray = [NSMutableArray array];
    _variableImageItems = [NSMutableArray array];
    _imageItems = [NSMutableArray array];
    imageNameArray = [NSMutableArray array];
    _textItems = [NSMutableArray array];
    _notReplaceableItems = [NSMutableArray array];
    [self getImageItems];
}

- (void)getImageItems {
    [imageNameArray removeAllObjects];
    [_imageItems removeAllObjects];
    [_variableImageItems removeAllObjects];
    [_textItems removeAllObjects];
    [_notReplaceableItems removeAllObjects];
    
    [self getFramesArray:_compContainer.childLayers currentLayer:nil];
    [_imageItems sortUsingComparator:^NSComparisonResult(RDLOTAnimatedSourceInfo* _Nonnull obj1, RDLOTAnimatedSourceInfo* _Nonnull obj2) {
        int outFrame1 = obj1.inFrame;
        int outFrame2 = obj2.inFrame;
        if (outFrame1 > outFrame2) {// obj1排后面
            return NSOrderedDescending;
        } else { // obj1排前面
            return NSOrderedAscending;
        }
    }];
//    NSLog(@"_imageItems:%@", _imageItems);
    [imageNameArray removeAllObjects];
    imageNameArray = nil;
    
    WeakSelf(self);
    [_imageItems enumerateObjectsUsingBlock:^(RDLOTAnimatedSourceInfo*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.name.length > 0) {
            StrongSelf(self);
            if (strongSelf.configVer <= 1.0) {
                if ([obj.typeName hasPrefix:kBackground]) {
                    [strongSelf->_notReplaceableItems addObject:obj];
                }else if ([obj.typeName hasPrefix:kReplaceableText]) {
                    [strongSelf->_textItems addObject:obj];
                }else {
                    [strongSelf->_variableImageItems addObject:obj];
                }
            }else {
                if ([obj.typeName hasPrefix:kReplaceableText]) {
                    [strongSelf->_textItems addObject:obj];
                }else if ([obj.typeName hasPrefix:@"Replaceable"]) {
                    [strongSelf->_variableImageItems addObject:obj];
                }else {
                    [strongSelf->_notReplaceableItems addObject:obj];
                }
            }
        }
    }];
}

- (void)getFramesArray:(NSArray<RDLOTLayerContainer *> *)childLayers currentLayer:(RDLOTLayer *)currentLayer {
    WeakSelf(self);
    [childLayers enumerateObjectsUsingBlock:^(RDLOTLayerContainer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[RDLOTCompositionContainer class]]) {
            RDLOTCompositionContainer *compContainer = (RDLOTCompositionContainer *)obj;
            RDLOTLayer *subCurrentLayer = compContainer.currentLayer;
            [weakSelf getFramesArray:compContainer.childLayers currentLayer:currentLayer ? currentLayer : subCurrentLayer];
        }else if ([obj isKindOfClass:[RDLOTLayerContainer class]])
        {
            StrongSelf(self);
            if (obj.layer.layerType == RDLOTLayerTypeImage) {
                obj.changedDlegate = weakSelf;
                RDLOTAsset *asset = [strongSelf->_sceneModel.assetGroup assetModelForID:obj.layer.referenceID];
                if (![strongSelf->imageNameArray containsObject:asset.imageName]) {
                    int totalFrame;
                    NSNumber *inFrame;
                    NSNumber *outFrame;
                    if (currentLayer) {
                        inFrame = [NSNumber numberWithInt:obj.inFrame.intValue + currentLayer.inFrame.intValue];
                        if (inFrame.intValue > currentLayer.outFrame.intValue) {
                            inFrame = currentLayer.inFrame;
                        }
                        outFrame = [NSNumber numberWithInt:obj.inFrame.intValue + obj.outFrame.intValue + currentLayer.inFrame.intValue];
                        if (outFrame.intValue > currentLayer.outFrame.intValue) {
                            outFrame = currentLayer.outFrame;
                        }
                        
                        NSLog(@"111 %@ inFrame:%d %d outFrame:%d %d", obj.layerName, inFrame.intValue, currentLayer.inFrame.intValue, outFrame.intValue, currentLayer.outFrame.intValue);
                        totalFrame = outFrame.intValue - inFrame.intValue;
                    }else {
                        inFrame = obj.inFrame;
                        outFrame = obj.outFrame;
                        NSLog(@"222 %@ inFrame:%d outFrame:%d", obj.layerName, obj.inFrame.intValue, obj.outFrame.intValue);
                        totalFrame = obj.outFrame.intValue - obj.inFrame.intValue;
                    }
                    RDLOTAnimatedSourceInfo *sourceInfo = [RDLOTAnimatedSourceInfo new];
                    sourceInfo.width = [obj.layer.layerWidth floatValue];
                    sourceInfo.height = [obj.layer.layerHeight floatValue];
                    sourceInfo.name = asset.imageName;
                    sourceInfo.directoryName = asset.imageDirectory;
                    sourceInfo.inFrame = inFrame.intValue;
                    sourceInfo.outFrame = outFrame.intValue;
                    sourceInfo.totalFrame = totalFrame;
                    sourceInfo.typeName = obj.layerName;
                    [strongSelf->_imageItems addObject:sourceInfo];
                    
                    [strongSelf->imageNameArray addObject:asset.imageName];
                }else {
                    [strongSelf->_imageItems enumerateObjectsUsingBlock:^(RDLOTAnimatedSourceInfo*  _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
                        if ([obj1.name isEqualToString:asset.imageName]) {
                            int prevInFrame = obj1.inFrame;
                            int prevOutFrame = obj1.outFrame;
                            int currentInFrame;
                            int currentOutFrame;
                            if (currentLayer) {
                                NSNumber *inFrame = [NSNumber numberWithInt:obj.inFrame.intValue + currentLayer.inFrame.intValue];
                                if (inFrame.intValue > currentLayer.outFrame.intValue) {
                                    inFrame = currentLayer.inFrame;
                                }
                                NSNumber *outFrame = [NSNumber numberWithInt:obj.inFrame.intValue + obj.outFrame.intValue + currentLayer.inFrame.intValue];
                                if (outFrame.intValue > currentLayer.outFrame.intValue) {
                                    outFrame = currentLayer.outFrame;
                                }
                                currentInFrame = inFrame.intValue;
                                currentOutFrame = outFrame.intValue;
                            }else {
                                currentInFrame = obj.inFrame.intValue;
                                currentOutFrame = obj.outFrame.intValue;
                            }
                            obj1.inFrame = MIN(prevInFrame, currentInFrame);
                            if (prevInFrame != currentInFrame && prevOutFrame != currentOutFrame) {
                                int totalFrame = obj1.totalFrame;
                                if (currentOutFrame > prevOutFrame) {
                                    totalFrame += currentOutFrame - MAX(prevOutFrame, currentInFrame);
                                }else if (currentOutFrame == prevOutFrame) {
                                    if (currentInFrame < prevInFrame) {
                                        totalFrame += prevInFrame - currentInFrame;
                                    }
                                }else {
                                    if (currentOutFrame <= prevInFrame) {
                                        totalFrame += currentOutFrame - currentInFrame;
                                    }else if (currentInFrame < prevInFrame) {
                                        totalFrame += prevInFrame - currentInFrame;
                                    }
                                }
                                obj1.totalFrame = totalFrame;
                            }
                        }
                    }];
                }
            }else if ([obj.layerName rangeOfString:@"end" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                RDLOTAnimatedSourceInfo *sourceInfo = [RDLOTAnimatedSourceInfo new];
                if (currentLayer) {
                    NSNumber *inFrame = [NSNumber numberWithInt:obj.inFrame.intValue + currentLayer.inFrame.intValue];
                    if (inFrame.intValue > currentLayer.outFrame.intValue) {
                        inFrame = currentLayer.inFrame;
                    }
                    NSNumber *outFrame = [NSNumber numberWithInt:obj.inFrame.intValue + obj.outFrame.intValue + currentLayer.inFrame.intValue];
                    if (outFrame.intValue > currentLayer.outFrame.intValue) {
                        outFrame = currentLayer.outFrame;
                    }
                    sourceInfo.inFrame = inFrame.intValue;
                    sourceInfo.outFrame = outFrame.intValue;
                }else {
                    sourceInfo.inFrame = obj.inFrame.intValue;
                    sourceInfo.outFrame = obj.outFrame.intValue;
                }
                sourceInfo.typeName = obj.layerName;
                [strongSelf->_imageItems addObject:sourceInfo];
            }
        }
    }];
}

- (void)refreshLayerContents:(NSString *)layerName {
    [self refreshLayerContents:_compContainer.childLayers currentLayer:nil layerName:layerName];
}

- (void)refreshLayerContents {
    [self refreshLayerContents:_compContainer.childLayers currentLayer:nil layerName:nil];
}

- (void)refreshLayerContents:(NSArray<RDLOTLayerContainer *> *)childLayers currentLayer:(RDLOTLayer *)currentLayer layerName:(NSString *)layerName {
    WeakSelf(self);
    [childLayers enumerateObjectsUsingBlock:^(RDLOTLayerContainer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[RDLOTCompositionContainer class]]) {
            RDLOTCompositionContainer *compContainer = (RDLOTCompositionContainer *)obj;
            RDLOTLayer *subCurrentLayer = compContainer.currentLayer;
            [weakSelf refreshLayerContents:compContainer.childLayers currentLayer:currentLayer ? currentLayer : subCurrentLayer layerName:layerName];
        }else if ([obj isKindOfClass:[RDLOTLayerContainer class]])
        {
            if (obj.layer.layerType == RDLOTLayerTypeImage) {
                if (layerName.length > 0) {
                    if ([layerName isEqualToString:obj.layer.layerName]) {
                        [obj _setImageForAsset:obj.layer.imageAsset];
                        *stop = YES;
                    }
                }else {
                    [obj _setImageForAsset:obj.layer.imageAsset];
                }
            }
        }
    }];
}

- (void)refreshLayerInOutFrame:(NSMutableArray<RDLOTAnimatedSourceInfo *> *)inOutFrames {
    oldEndTime = _sceneModel.endFrame.intValue;
    int totalTime = [inOutFrames lastObject].outFrame;
    if (totalTime > 0) {
        [_sceneModel refreshEndFrame:[NSNumber numberWithInt:totalTime]];
    }
    
    [imageNameArray removeAllObjects];
    imageNameArray = nil;
    imageNameArray = [NSMutableArray array];
    inOutFrameArray = [inOutFrames mutableCopy];
    refreshInOutFrameIndex = 0;
    [self refreshInOutFrame:_compContainer.childLayers currentLayer:nil];
    
//    NSLog(@"%@", _imageItems);
    [_compContainer refreshEndFrame:_sceneModel.endFrame];
    [self getImageItems];
//    NSLog(@"%@", _imageItems);
}

- (void)refreshInOutFrame:(NSArray<RDLOTLayerContainer *> *)childLayers currentLayer:(RDLOTLayer *)currentLayer {
    __weak typeof(self) weakSelf = self;
    [childLayers enumerateObjectsUsingBlock:^(RDLOTLayerContainer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        StrongSelf(self);
        if ([obj isKindOfClass:[RDLOTCompositionContainer class]]) {
            RDLOTCompositionContainer *compContainer = (RDLOTCompositionContainer *)obj;
            [compContainer refreshEndFrame:strongSelf->_sceneModel.endFrame];
            RDLOTLayer *subCurrentLayer = compContainer.currentLayer;
            [weakSelf refreshInOutFrame:compContainer.childLayers currentLayer:currentLayer ? currentLayer : subCurrentLayer];
        }else if ([obj isKindOfClass:[RDLOTLayerContainer class]])
        {
            if (currentLayer && ![strongSelf->imageNameArray containsObject:currentLayer.layerName]) {
                [strongSelf->imageNameArray addObject:currentLayer.layerName];
                int firstFrame;
                if (currentLayer.position) {
                    firstFrame = [currentLayer.position.keyframes firstObject].keyframeTime.intValue;
                }else {
                    firstFrame = [currentLayer.positionX.keyframes firstObject].keyframeTime.intValue;
                }
                __block NSUInteger imageIndex;
                [strongSelf->_textItems enumerateObjectsUsingBlock:^(RDLOTAnimatedSourceInfo* _Nonnull imageInfo, NSUInteger idx1, BOOL * _Nonnull stop1) {
                    int inFrame = imageInfo.inFrame;
                    if (firstFrame <= inFrame) {
                        imageIndex = idx1;
                        *stop1 = YES;
                    }
                }];
                if (imageIndex < weakSelf.textItems.count && imageIndex < strongSelf->inOutFrameArray.count) {
                    int newInFrame = [inOutFrameArray objectAtIndex:imageIndex].inFrame;
//                    int newOutFrame = [inOutFrameArray objectAtIndex:imageIndex].outFrame;
                    int newOutFrame = strongSelf->_sceneModel.endFrame.intValue;
                    BOOL isAlwaysShow = NO;
                    if (currentLayer.inFrame.intValue == 0 && currentLayer.outFrame.intValue == strongSelf->oldEndTime) {
                        isAlwaysShow = YES;
                        [currentLayer refreshInFrame:[NSNumber numberWithInt:0] outFrame:[NSNumber numberWithInt:newOutFrame]];
                    }else {
                        [currentLayer refreshInFrame:[NSNumber numberWithInt:newInFrame] outFrame:[NSNumber numberWithInt:newOutFrame]];
                    }
                    [weakSelf refreshLayerKeyFrameTime:currentLayer isAlwaysShow:isAlwaysShow];
                }
            }
            if (![strongSelf->imageNameArray containsObject:obj.layerName]) {
                int newInFrame = [strongSelf->inOutFrameArray objectAtIndex:strongSelf->refreshInOutFrameIndex].inFrame;
//                int newOutFrame = [inOutFrameArray objectAtIndex:refreshInOutFrameIndex].outFrame;
                int newOutFrame = strongSelf->_sceneModel.endFrame.intValue;
                if (obj.inFrame.intValue == 0 && obj.outFrame.intValue == strongSelf->oldEndTime) {
                    [obj refreshInFrame:[NSNumber numberWithInt:0] outFrame:[NSNumber numberWithInt:newOutFrame]];
                }else {
                    [obj refreshInFrame:[NSNumber numberWithInt:newInFrame] outFrame:[NSNumber numberWithInt:newOutFrame]];
                }
                BOOL isAlwaysShow = NO;
                if (obj.layer.inFrame.intValue == 0 && obj.layer.outFrame.intValue == strongSelf->oldEndTime) {
                    isAlwaysShow = YES;
                    [obj.layer refreshInFrame:[NSNumber numberWithInt:0] outFrame:[NSNumber numberWithInt:newOutFrame]];
                }else {
                    [obj.layer refreshInFrame:[NSNumber numberWithInt:newInFrame] outFrame:[NSNumber numberWithInt:newOutFrame]];
                }
                
                [strongSelf->imageNameArray addObject:obj.layerName];
                
                [weakSelf refreshLayerKeyFrameTime:obj.layer isAlwaysShow:isAlwaysShow];
                if (obj.layer.layerType == RDLOTLayerTypeImage && [obj.layerName hasPrefix:kReplaceableText]) {
                    strongSelf->refreshInOutFrameIndex++;
                }
                if (strongSelf->refreshInOutFrameIndex == strongSelf->inOutFrameArray.count) {
                    strongSelf->refreshInOutFrameIndex = 0;
                    *stop = YES;
                }
            }
        }
    }];
}

- (void)refreshKeyframes:(NSArray<RDLOTKeyframe *> *)keyframes
{
    WeakSelf(self);
    [keyframes enumerateObjectsUsingBlock:^(RDLOTKeyframe * _Nonnull keyframe, NSUInteger idx, BOOL * _Nonnull stop) {
        __block int diffInFrame;
        StrongSelf(self);
        [strongSelf->_textItems enumerateObjectsUsingBlock:^(RDLOTAnimatedSourceInfo*  _Nonnull imageInfo, NSUInteger idx1, BOOL * _Nonnull stop1) {
            int inFrame = imageInfo.inFrame;
            int nextInFrame;
            if (idx1 == strongSelf->_textItems.count - 1) {
                nextInFrame = inFrame;
            }else {
                nextInFrame = [strongSelf->_textItems objectAtIndex:(idx1 + 1)].inFrame;
            }
            if ((keyframe.keyframeTime.intValue >= inFrame && keyframe.keyframeTime.intValue < nextInFrame) || idx1 == strongSelf->inOutFrameArray.count) {
                int newInFrame;
                if (idx1 < inOutFrameArray.count) {
                    newInFrame = [strongSelf->inOutFrameArray objectAtIndex:idx1].inFrame;
                }else {
                    newInFrame = [strongSelf->inOutFrameArray lastObject].outFrame;
                }
                diffInFrame = newInFrame - inFrame;
                
                *stop1 = YES;
            }
        }];
        int newKeyFrameTime = keyframe.keyframeTime.intValue + diffInFrame;
        if (newKeyFrameTime > 0) {
            NSLog(@"%d keyframeTime:%d newKeyFrameTime:%d diffInFrame:%d", idx, keyframe.keyframeTime.intValue, newKeyFrameTime, diffInFrame);
            [keyframe refreshKeyFrameTime:[NSNumber numberWithInt:newKeyFrameTime]];
        }
//        NSLog(@"inTangent:%@ outTangent:%@ spatialInTangent:%@ spatialOutTangent:%@ floatValue:%f pointValue:%@ sizeValue:%@", NSStringFromCGPoint(keyframe.inTangent), NSStringFromCGPoint(keyframe.outTangent), NSStringFromCGPoint(keyframe.spatialInTangent), NSStringFromCGPoint(keyframe.spatialOutTangent), keyframe.floatValue, NSStringFromCGPoint(keyframe.pointValue), NSStringFromCGSize(keyframe.sizeValue));
    }];
}

- (void)refreshLayerKeyFrameTime:(RDLOTLayer *)layer isAlwaysShow:(BOOL)isAlwaysShow
{
    NSLog(@"%@", layer.layerName);
    if (layer.position) {
        NSLog(@"position");
        if (!(isAlwaysShow && layer.position.keyframes.count == 1)) {
            [self refreshKeyframes:layer.position.keyframes];
        }
    }else {
        NSLog(@"positionX");
        if (!(isAlwaysShow && layer.positionX.keyframes.count == 1)) {
            [self refreshKeyframes:layer.positionX.keyframes];
        }
        if (!(isAlwaysShow && layer.positionY.keyframes.count == 1)) {
            NSLog(@"positionY");
            [self refreshKeyframes:layer.positionY.keyframes];
        }
    }
    if (layer.opacity) {
        NSLog(@"opacity");
        if (!(isAlwaysShow && layer.opacity.keyframes.count == 1)) {
            [self refreshKeyframes:layer.opacity.keyframes];
        }
    }
    if (layer.timeRemapping) {
        NSLog(@"timeRemapping");
        if (!(isAlwaysShow && layer.timeRemapping.keyframes.count == 1)) {
            [self refreshKeyframes:layer.timeRemapping.keyframes];
        }
    }
    if (layer.rotation) {
        NSLog(@"rotation");
        if (!(isAlwaysShow && layer.rotation.keyframes.count == 1)) {
            [self refreshKeyframes:layer.rotation.keyframes];
        }
    }
    if (layer.anchor) {
        NSLog(@"anchor");
        if (!(isAlwaysShow && layer.anchor.keyframes.count == 1)) {
            [self refreshKeyframes:layer.anchor.keyframes];
        }
    }
    if (layer.scale) {
        NSLog(@"scale");
        if (!(isAlwaysShow && layer.scale.keyframes.count == 1)) {
            [self refreshKeyframes:layer.scale.keyframes];
        }
    }
}

- (void)refreshOldInFrame:(int)oldInFrame prevInFrame:(int)prevInFrame nextInFrame:(int)nextInFrame newInFrame:(int)newInFrame newOutFrame:(int)newOutFrame {
    NSLog(@"old:%d new:%d prev:%d next:%d", oldInFrame, newInFrame, prevInFrame, nextInFrame);
    if (oldInFrame == [inOutFrameArray lastObject].inFrame) {
        [_sceneModel refreshEndFrame:[NSNumber numberWithInt:newOutFrame]];
    }
    
    [imageNameArray removeAllObjects];
    imageNameArray = nil;
    imageNameArray = [NSMutableArray array];
    refreshInOutFrameIndex = 0;
    [self refreshChildLayers:_compContainer.childLayers currentLayer:nil oldInFrame:oldInFrame prevInFrame:prevInFrame nextInFrame:nextInFrame newInFrame:newInFrame newOutFrame:newOutFrame];
    
//    NSLog(@"%@", _imageItems);
    [_compContainer refreshEndFrame:_sceneModel.endFrame];
    [self getImageItems];
//    NSLog(@"%@", _imageItems);
}

- (void)refreshChildLayers:(NSArray<RDLOTLayerContainer *> *)childLayers currentLayer:(RDLOTLayer *)currentLayer oldInFrame:(int)oldInFrame prevInFrame:(int)prevInFrame nextInFrame:(int)nextInFrame newInFrame:(int)newInFrame newOutFrame:(int)newOutFrame
{
    __weak typeof(self) weakSelf = self;
    [childLayers enumerateObjectsUsingBlock:^(RDLOTLayerContainer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[RDLOTCompositionContainer class]]) {
            RDLOTCompositionContainer *compContainer = (RDLOTCompositionContainer *)obj;
            [compContainer refreshEndFrame:_sceneModel.endFrame];
            RDLOTLayer *subCurrentLayer = compContainer.currentLayer;
            [weakSelf refreshChildLayers:compContainer.childLayers currentLayer:currentLayer ? currentLayer : subCurrentLayer oldInFrame:oldInFrame prevInFrame:prevInFrame nextInFrame:nextInFrame newInFrame:newInFrame newOutFrame:newOutFrame];
        }else if ([obj isKindOfClass:[RDLOTLayerContainer class]])
        {
            if (currentLayer && ![imageNameArray containsObject:currentLayer.layerName]) {
                [imageNameArray addObject:currentLayer.layerName];
                if (oldInFrame == currentLayer.inFrame.intValue) {
                    [currentLayer refreshInFrame:[NSNumber numberWithInt:newInFrame] outFrame:[NSNumber numberWithInt:_sceneModel.endFrame.intValue]];
                }
                if ((currentLayer.inFrame.intValue >= prevInFrame && currentLayer.inFrame.intValue < newInFrame) || currentLayer.inFrame.intValue == 0) {
                    [weakSelf refreshKeyFrameTime:currentLayer oldInFrame:oldInFrame prevInFrame:prevInFrame nextInFrame:nextInFrame newInFrame:newInFrame];
                }
            }
            if (![imageNameArray containsObject:obj.layerName]) {
                if (obj.layer.layerType == RDLOTLayerTypeImage && [obj.layerName hasPrefix:kReplaceableText]) {
                    refreshInOutFrameIndex++;
                }
                if (oldInFrame == obj.inFrame.intValue) {
                    [obj refreshInFrame:[NSNumber numberWithInt:newInFrame] outFrame:[NSNumber numberWithInt:_sceneModel.endFrame.intValue]];
                    [obj.layer refreshInFrame:[NSNumber numberWithInt:newInFrame] outFrame:[NSNumber numberWithInt:_sceneModel.endFrame.intValue]];
                }
                if ((obj.inFrame.intValue >= prevInFrame && obj.inFrame.intValue < newInFrame) || obj.inFrame.intValue == 0) {
                    [weakSelf refreshKeyFrameTime:obj.layer oldInFrame:oldInFrame prevInFrame:prevInFrame nextInFrame:nextInFrame newInFrame:newInFrame];
                }
                
                [imageNameArray addObject:obj.layerName];
                if (refreshInOutFrameIndex == inOutFrameArray.count) {
                    refreshInOutFrameIndex = 0;
                    *stop = YES;
                }
            }
        }
    }];
}

- (void)refreshKeyFrameTime:(RDLOTLayer *)layer oldInFrame:(int)oldInFrame prevInFrame:(int)prevInFrame nextInFrame:(int)nextInFrame newInFrame:(int)newInFrame
{
    NSLog(@"%@", layer.layerName);
    if (layer.position) {
        NSLog(@"position");
        [self refreshKeyframes:layer.position.keyframes oldInFrame:oldInFrame prevInFrame:prevInFrame nextInFrame:nextInFrame newInFrame:newInFrame];
    }else {
        NSLog(@"positionX");
        [self refreshKeyframes:layer.positionX.keyframes oldInFrame:oldInFrame prevInFrame:prevInFrame nextInFrame:nextInFrame newInFrame:newInFrame];
        NSLog(@"positionY");
        [self refreshKeyframes:layer.positionY.keyframes oldInFrame:oldInFrame prevInFrame:prevInFrame nextInFrame:nextInFrame newInFrame:newInFrame];
    }
    if (layer.opacity) {
        NSLog(@"opacity");
        [self refreshKeyframes:layer.opacity.keyframes oldInFrame:oldInFrame prevInFrame:prevInFrame nextInFrame:nextInFrame newInFrame:newInFrame];
    }
    if (layer.timeRemapping) {
        NSLog(@"timeRemapping");
        [self refreshKeyframes:layer.timeRemapping.keyframes oldInFrame:oldInFrame prevInFrame:prevInFrame nextInFrame:nextInFrame newInFrame:newInFrame];
    }
    if (layer.rotation) {
        NSLog(@"rotation");
        [self refreshKeyframes:layer.rotation.keyframes oldInFrame:oldInFrame prevInFrame:prevInFrame nextInFrame:nextInFrame newInFrame:newInFrame];
    }
    if (layer.anchor) {
        NSLog(@"anchor");
        [self refreshKeyframes:layer.anchor.keyframes oldInFrame:oldInFrame prevInFrame:prevInFrame nextInFrame:nextInFrame newInFrame:newInFrame];
    }
    if (layer.scale) {
        NSLog(@"scale");
        [self refreshKeyframes:layer.scale.keyframes oldInFrame:oldInFrame prevInFrame:prevInFrame nextInFrame:nextInFrame newInFrame:newInFrame];
    }
}

- (void)refreshKeyframes:(NSArray<RDLOTKeyframe *> *)keyframes oldInFrame:(int)oldInFrame prevInFrame:(int)prevInFrame nextInFrame:(int)nextInFrame newInFrame:(int)newInFrame
{
    [keyframes enumerateObjectsUsingBlock:^(RDLOTKeyframe * _Nonnull keyframe, NSUInteger idx, BOOL * _Nonnull stop) {
        if (keyframe.keyframeTime.intValue >= oldInFrame && keyframe.keyframeTime.intValue < nextInFrame) {
            int diffInFrame = newInFrame - oldInFrame;
            int newKeyFrameTime = keyframe.keyframeTime.intValue + diffInFrame;
            if (newKeyFrameTime > 0) {
                NSLog(@"%d keyframeTime:%d newKeyFrameTime:%d diffInFrame:%d", idx, keyframe.keyframeTime.intValue, newKeyFrameTime, diffInFrame);
                [keyframe refreshKeyFrameTime:[NSNumber numberWithInt:newKeyFrameTime]];
            }
        }
        
    }];
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

- (void)setImagesCount:(NSInteger)imagesCount {
    _imagesCount = imagesCount;
#if 1
    __block NSInteger firstReplacableIndex = 0;
    [_imageItems enumerateObjectsUsingBlock:^(RDLOTAnimatedSourceInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (_configVer <= 1.0) {
            if (![obj.typeName hasPrefix:kBackground]) {
                firstReplacableIndex = idx;
                *stop = YES;
            }
        }else {
            if ([obj.typeName hasPrefix:@"ReplaceablePic"] || [obj.typeName hasPrefix:@"ReplaceableVideoOrPic"]) {
                firstReplacableIndex = idx;
                *stop = YES;
            }
        }
    }];
    __block NSInteger lastReplacableIndex = _imageItems.count - 1;
    [_imageItems enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(RDLOTAnimatedSourceInfo*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (_configVer <= 1.0) {
            if (![obj.typeName hasPrefix:kBackground] && [obj.typeName rangeOfString:@"end" options:NSCaseInsensitiveSearch].location == NSNotFound) {
                _lastReplacableInfo = obj;
                lastReplacableIndex = idx;
                *stop = YES;
            }
        }else {
            if ([obj.typeName rangeOfString:@"end" options:NSCaseInsensitiveSearch].location == NSNotFound) {
                _lastReplacableInfo = obj;
                lastReplacableIndex = idx;
                *stop = YES;
            }
        }
    }];
    NSInteger allReplacableImageCount = MIN(lastReplacableIndex - firstReplacableIndex + 1, _variableImageItems.count);
    if (imagesCount > 0 && imagesCount < allReplacableImageCount) {
        RDLOTAnimatedSourceInfo *currentSourceInfo = [_variableImageItems objectAtIndex:imagesCount - 1];
        RDLOTAnimatedSourceInfo *nextSourceInfo = [_variableImageItems objectAtIndex:imagesCount];
        int lastImageOutFrame = currentSourceInfo.outFrame;
        int nextImageInFrame = nextSourceInfo.inFrame;
        if (nextImageInFrame < lastImageOutFrame && nextImageInFrame > 0) {
            _imagesDuration = nextImageInFrame/_sceneModel.framerate.floatValue;
        }else {
            _imagesDuration = lastImageOutFrame/_sceneModel.framerate.floatValue;
        }
        if (lastReplacableIndex < _imageItems.count - 1) {
            RDLOTAnimatedSourceInfo *endSourceInfo = [_imageItems objectAtIndex:lastReplacableIndex + 1];
            int inFrame = endSourceInfo.inFrame;
            if (_hasEndImage) {
                int inFrame_prev = _imageItems[lastReplacableIndex].inFrame;
                if (inFrame_prev < inFrame) {
                    inFrame = inFrame_prev;
                }
            }
            int outFrame = endSourceInfo.outFrame;
            _endDuration = (outFrame - inFrame)/_sceneModel.framerate.floatValue;
            _endStartTime = inFrame/_sceneModel.framerate.floatValue;
            if (_lastReplacableInfo.inFrame == endSourceInfo.inFrame) {
                if (imagesCount == 1) {
                    _imagesDuration = 0;
                }else {
                    currentSourceInfo = [_variableImageItems objectAtIndex:imagesCount - 2];
                    nextSourceInfo = [_variableImageItems objectAtIndex:imagesCount - 1];
                    lastImageOutFrame = currentSourceInfo.outFrame;
                    nextImageInFrame = nextSourceInfo.inFrame;
                    if (nextImageInFrame < lastImageOutFrame && nextImageInFrame > 0) {
                        _imagesDuration = nextImageInFrame/_sceneModel.framerate.floatValue;
                    }else {
                        _imagesDuration = lastImageOutFrame/_sceneModel.framerate.floatValue;
                    }
                }
            }
            if (imagesCount > 0 && imagesCount < allReplacableImageCount) {
                _endStartTime -= _imagesDuration;
            }
            NSLog(@"***********end inframe:%d outframe:%d endFrame:%d", inFrame, outFrame, _sceneModel.framerate.intValue);
        }
    }else {
        _imagesDuration = (_sceneModel.endFrame.floatValue - _sceneModel.startFrame.floatValue) / _sceneModel.framerate.floatValue;
    }
#else
    RDLOTAnimatedSourceInfo *endSourceInfo = [_imageItems lastObject];
    NSString *endName = endSourceInfo.name;
    NSInteger allImagesCount;
    if ([endName rangeOfString:@"end" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        allImagesCount = _variableImageItems.count - 1;
    }else {
        allImagesCount = _variableImageItems.count;
    }
    if (imagesCount > 0 && imagesCount < allImagesCount) {
        _hasEndImage = NO;
        __block RDLOTAnimatedSourceInfo *prevSourceInfo;
        if ([endName rangeOfString:@"end" options:NSCaseInsensitiveSearch].location != NSNotFound
            || [endSourceInfo.typeName hasPrefix:kBackground])
        {
            [_imageItems enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(RDLOTAnimatedSourceInfo*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.typeName hasPrefix:@"ReplaceablePic"] || [obj.typeName hasPrefix:@"ReplaceableVideoOrPic"]) {
                    prevSourceInfo = obj;
                    *stop = YES;
                }
            }];
            if (prevSourceInfo.outFrame == endSourceInfo.outFrame) {
                _hasEndImage = YES;
            }
        }
        RDLOTAnimatedSourceInfo *currentSourceInfo = [_variableImageItems objectAtIndex:imagesCount - 1];
        RDLOTAnimatedSourceInfo *nextSourceInfo = [_variableImageItems objectAtIndex:imagesCount];
        if (_hasEndImage && imagesCount > 1) {
            currentSourceInfo = [_variableImageItems objectAtIndex:imagesCount - 2];
            nextSourceInfo = [_variableImageItems objectAtIndex:imagesCount - 1];
        }
        int lastImageOutFrame = currentSourceInfo.outFrame;
        int nextImageInFrame = nextSourceInfo.inFrame;
        if (nextImageInFrame < lastImageOutFrame && nextImageInFrame > 0) {
            _imagesDuration = nextImageInFrame/_sceneModel.framerate.floatValue;
        }else {
            _imagesDuration = lastImageOutFrame/_sceneModel.framerate.floatValue;
        }
        if (_hasEndImage && imagesCount == 1) {
            RDLOTAnimatedSourceInfo *firstSourceInfo = [_imageItems firstObject];
            if ([firstSourceInfo.typeName hasPrefix:kBackground]) {
                RDLOTAnimatedSourceInfo *secondSourceInfo = [_imageItems objectAtIndex:1];
                int lastImageOutFrame = firstSourceInfo.outFrame;
                int nextImageInFrame = secondSourceInfo.inFrame;
                if (nextImageInFrame < lastImageOutFrame && nextImageInFrame > 0) {
                    _imagesDuration = nextImageInFrame/_sceneModel.framerate.floatValue;
                }else {
                    _imagesDuration = lastImageOutFrame/_sceneModel.framerate.floatValue;
                }
            }else {
                _imagesDuration = 0.0;
            }
        }
        if ([endName rangeOfString:@"end" options:NSCaseInsensitiveSearch].location != NSNotFound
            || [endSourceInfo.typeName hasPrefix:kBackground])
        {
            int inFrame = endSourceInfo.inFrame;
            if (_hasEndImage) {
                int inFrame_prev = prevSourceInfo.inFrame;
                if (inFrame_prev < inFrame) {
                    inFrame = inFrame_prev;
                }
            }
            int outFrame = endSourceInfo.outFrame;
            _endDuration = (outFrame - inFrame)/_sceneModel.framerate.floatValue;
            _endStartTime = inFrame/_sceneModel.framerate.floatValue - _imagesDuration;
            NSLog(@"111***********end inframe:%d outframe:%d endFrame:%d", inFrame, outFrame, _sceneModel.framerate.intValue);
        }
    }else {
        _imagesDuration = (_sceneModel.endFrame.floatValue - _sceneModel.startFrame.floatValue) / _sceneModel.framerate.floatValue;
    }
#endif
    NSLog(@"imagesDuration:%f", _imagesDuration);
}

- (void)changeLayerContents:(CALayer *)layer layerName:(NSString *)layerName {
    if (_delegate && [_delegate respondsToSelector:@selector(changeLayerImage:layerName:)]) {
        [_delegate changeLayerImage:layer layerName:layerName];
    }
}

- (void)_restoreState {
  if (_isAnimationPlaying) {
    _isAnimationPlaying = NO;
    if (_playRangeStartFrame && _playRangeEndFrame) {
      [self playFromFrame:_playRangeStartFrame toFrame:_playRangeEndFrame withCompletion:self.completionBlock];
    } else if (_playRangeEndProgress != _playRangeStartProgress) {
      [self playFromProgress:_playRangeStartProgress toProgress:_playRangeEndProgress withCompletion:self.completionBlock];
    } else {
      [self playWithCompletion:self.completionBlock];
    }
  } else {
    self.animationProgress = _animationProgress;
  }
}

- (void)_removeCurrentAnimationIfNecessary {
  _isAnimationPlaying = NO;
  [_compContainer removeAllAnimations];
  _compContainer.shouldRasterize = _shouldRasterizeWhenIdle;
}

- (CGFloat)_progressForFrame:(NSNumber *)frame {
  if (!_sceneModel) {
    return 0;
  }
  return ((frame.floatValue - _sceneModel.startFrame.floatValue) / (_sceneModel.endFrame.floatValue - _sceneModel.startFrame.floatValue));
}

- (NSNumber *)_frameForProgress:(CGFloat)progress {
  if (!_sceneModel) {
    return @0;
  }
  return @(((_sceneModel.endFrame.floatValue - _sceneModel.startFrame.floatValue) * progress) + _sceneModel.startFrame.floatValue);
}

- (BOOL)_isSpeedNegative {
  // If the animation speed is negative, then we're moving backwards.
  return _animationSpeed >= 0;
}

# pragma mark - Completion Block

- (void)_callCompletionIfNecessary:(BOOL)complete {
  if (self.completionBlock) {
    RDLOTAnimationCompletionBlock completion = self.completionBlock;
    self.completionBlock = nil;
    completion(complete);
  }
}

# pragma mark - External Methods

- (void)setAnimationNamed:(nonnull NSString *)animationName {
  RDLOTComposition *comp = [RDLOTComposition animationNamed:animationName];

  [self _initializeAnimationContainer];
  [self _setupWithSceneModel:comp];
}

- (void)setAnimationFromJSON:(nonnull NSDictionary *)animationJSON {
  RDLOTComposition *comp = [RDLOTComposition animationFromJSON:animationJSON];

  [self _initializeAnimationContainer];
  [self _setupWithSceneModel:comp];
}

# pragma mark - External Methods - Model

- (void)setSceneModel:(RDLOTComposition *)sceneModel {
  [self _setupWithSceneModel:sceneModel];
}

# pragma mark - External Methods - Play Control

- (void)play {
  if (!_sceneModel) {
    _isAnimationPlaying = YES;
    return;
  }
  [self playFromFrame:_sceneModel.startFrame toFrame:_sceneModel.endFrame withCompletion:nil];
}

- (void)playWithCompletion:(RDLOTAnimationCompletionBlock)completion {
  if (!_sceneModel) {
    _isAnimationPlaying = YES;
    self.completionBlock = completion;
    return;
  }
  [self playFromFrame:_sceneModel.startFrame toFrame:_sceneModel.endFrame withCompletion:completion];
}

- (void)playToProgress:(CGFloat)progress withCompletion:(nullable RDLOTAnimationCompletionBlock)completion {
  [self playFromProgress:0 toProgress:progress withCompletion:completion];
}

- (void)playFromProgress:(CGFloat)fromStartProgress
              toProgress:(CGFloat)toEndProgress
          withCompletion:(nullable RDLOTAnimationCompletionBlock)completion {
  if (!_sceneModel) {
    _isAnimationPlaying = YES;
    self.completionBlock = completion;
    _playRangeStartProgress = fromStartProgress;
    _playRangeEndProgress = toEndProgress;
    return;
  }
  [self playFromFrame:[self _frameForProgress:fromStartProgress]
              toFrame:[self _frameForProgress:toEndProgress]
       withCompletion:completion];
}

- (void)playToFrame:(nonnull NSNumber *)toFrame
     withCompletion:(nullable RDLOTAnimationCompletionBlock)completion {
  [self playFromFrame:_sceneModel.startFrame toFrame:toFrame withCompletion:completion];
}

- (void)playFromFrame:(nonnull NSNumber *)fromStartFrame
              toFrame:(nonnull NSNumber *)toEndFrame
       withCompletion:(nullable RDLOTAnimationCompletionBlock)completion {
  if (_isAnimationPlaying) {
    return;
  }
  _playRangeStartFrame = fromStartFrame;
  _playRangeEndFrame = toEndFrame;
  if (completion) {
    self.completionBlock = completion;
  }
  if (!_sceneModel) {
    _isAnimationPlaying = YES;
    return;
  }

  BOOL playingForward = ((_animationSpeed > 0) && (toEndFrame.floatValue > fromStartFrame.floatValue))
    || ((_animationSpeed < 0) && (fromStartFrame.floatValue > toEndFrame.floatValue));

  CGFloat leftFrameValue = MIN(fromStartFrame.floatValue, toEndFrame.floatValue);
  CGFloat rightFrameValue = MAX(fromStartFrame.floatValue, toEndFrame.floatValue);

  NSNumber *currentFrame = [self _frameForProgress:_animationProgress];

  currentFrame = @(MAX(MIN(currentFrame.floatValue, rightFrameValue), leftFrameValue));

  if (currentFrame.floatValue == rightFrameValue && playingForward) {
    currentFrame = @(leftFrameValue);
  } else if (currentFrame.floatValue == leftFrameValue && !playingForward) {
    currentFrame = @(rightFrameValue);
  }
  _animationProgress = [self _progressForFrame:currentFrame];
  
  CGFloat currentProgress = _animationProgress * (_sceneModel.endFrame.floatValue - _sceneModel.startFrame.floatValue);
  CGFloat skipProgress;
  if (playingForward) {
    skipProgress = currentProgress - leftFrameValue;
  } else {
    skipProgress = rightFrameValue - currentProgress;
  }
  NSTimeInterval offset = MAX(0, skipProgress) / _sceneModel.framerate.floatValue;
//  if (!self.window) {
  if (!self.window && !self.layer.superlayer) {//20180607 wuxiaoxia 把self.layer添加到CALayer也可以播放
    _shouldRestoreStateWhenAttachedToWindow = YES;
    _completionBlockToRestoreWhenAttachedToWindow = self.completionBlock;
    self.completionBlock = nil;
  } else {
    NSTimeInterval duration = (ABS(toEndFrame.floatValue - fromStartFrame.floatValue) / _sceneModel.framerate.floatValue);
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"currentFrame"];
    animation.speed = _animationSpeed;
    animation.fromValue = fromStartFrame;
    animation.toValue = toEndFrame;
    animation.duration = duration;
    animation.fillMode = kCAFillModeBoth;
    animation.repeatCount = _loopAnimation ? HUGE_VALF : 1;
    animation.autoreverses = _autoReverseAnimation;
    animation.delegate = self;
    animation.removedOnCompletion = NO;
    if (offset != 0) {
      CFTimeInterval currentTime = CACurrentMediaTime();
      CFTimeInterval currentLayerTime = [self.layer convertTime:currentTime fromLayer:nil];
      animation.beginTime = currentLayerTime - (offset * 1 / _animationSpeed);
    }
    [_compContainer addAnimation:animation forKey:kCompContainerAnimationKey];
    _compContainer.shouldRasterize = NO;
  }
  _isAnimationPlaying = YES;
}

#pragma mark - Other Time Controls

- (void)stop {
  _isAnimationPlaying = NO;
  if (_sceneModel) {
    [self setProgressWithFrame:_sceneModel.startFrame callCompletionIfNecessary:YES];
  }
}

- (void)pause {
  if (!_sceneModel ||
      !_isAnimationPlaying) {
    _isAnimationPlaying = NO;
    return;
  }
  NSNumber *frame = [_compContainer.presentationLayer.currentFrame copy];
  [self setProgressWithFrame:frame callCompletionIfNecessary:YES];
}

- (void)setAnimationProgress:(CGFloat)animationProgress {
  if (!_sceneModel) {
    _animationProgress = animationProgress;
    return;
  }
  [self setProgressWithFrame:[self _frameForProgress:animationProgress] callCompletionIfNecessary:YES];
}

- (void)setProgressWithFrame:(nonnull NSNumber *)currentFrame {
  [self setProgressWithFrame:currentFrame callCompletionIfNecessary:YES];
}

- (void)setProgressWithFrame:(nonnull NSNumber *)currentFrame callCompletionIfNecessary:(BOOL)callCompletion {
  [self _removeCurrentAnimationIfNecessary];

  if (_shouldRestoreStateWhenAttachedToWindow) {
    _shouldRestoreStateWhenAttachedToWindow = NO;

    self.completionBlock = _completionBlockToRestoreWhenAttachedToWindow;
    _completionBlockToRestoreWhenAttachedToWindow = nil;
  }

  _animationProgress = [self _progressForFrame:currentFrame];

  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  _compContainer.currentFrame = currentFrame;
//    NSLog(@"currentFrame:%d", currentFrame.intValue);
  [_compContainer setNeedsDisplay];
  [CATransaction commit];
  if (callCompletion) {
    [self _callCompletionIfNecessary:NO];
  }
}

- (void)setLoopAnimation:(BOOL)loopAnimation {
  _loopAnimation = loopAnimation;
  if (_isAnimationPlaying && _sceneModel) {
    NSNumber *frame = [_compContainer.presentationLayer.currentFrame copy];
    [self setProgressWithFrame:frame callCompletionIfNecessary:NO];
    [self playFromFrame:_playRangeStartFrame toFrame:_playRangeEndFrame withCompletion:self.completionBlock];
  }
}

- (void)setAnimationSpeed:(CGFloat)animationSpeed {
  _animationSpeed = animationSpeed;
  if (_isAnimationPlaying && _sceneModel) {
    NSNumber *frame = [_compContainer.presentationLayer.currentFrame copy];
    [self setProgressWithFrame:frame callCompletionIfNecessary:NO];
    [self playFromFrame:_playRangeStartFrame toFrame:_playRangeEndFrame withCompletion:self.completionBlock];
  }
}

- (void)forceDrawingUpdate {
  [self _layoutAndForceUpdate];
}

# pragma mark - External Methods - Idle Rasterization

- (void)setShouldRasterizeWhenIdle:(BOOL)shouldRasterize {
  _shouldRasterizeWhenIdle = shouldRasterize;
  if (!_isAnimationPlaying) {
    _compContainer.shouldRasterize = _shouldRasterizeWhenIdle;
  }
}

# pragma mark - External Methods - Cache

- (void)setCacheEnable:(BOOL)cacheEnable {
  _cacheEnable = cacheEnable;
  if (!self.sceneModel.cacheKey) {
    return;
  }
  if (cacheEnable) {
    [[RDLOTAnimationCache sharedCache] addAnimation:_sceneModel forKey:self.sceneModel.cacheKey];
  } else {
    [[RDLOTAnimationCache sharedCache] removeAnimationForKey:self.sceneModel.cacheKey];
  }
}

# pragma mark - External Methods - Interactive Controls

- (void)setValueDelegate:(id<RDLOTValueDelegate> _Nonnull)delegate
              forKeypath:(RDLOTKeypath * _Nonnull)keypath {
  [_compContainer setValueDelegate:delegate forKeypath:keypath];
  [self _layoutAndForceUpdate];
}

- (nullable NSArray *)keysForKeyPath:(nonnull RDLOTKeypath *)keypath {
  return [_compContainer keysForKeyPath:keypath];
}

- (CGPoint)convertPoint:(CGPoint)point
         toKeypathLayer:(nonnull RDLOTKeypath *)keypath {
  [self _layoutAndForceUpdate];
  return [_compContainer convertPoint:point toKeypathLayer:keypath withParentLayer:self.layer];
}

- (CGRect)convertRect:(CGRect)rect
       toKeypathLayer:(nonnull RDLOTKeypath *)keypath {
  [self _layoutAndForceUpdate];
  return [_compContainer convertRect:rect toKeypathLayer:keypath withParentLayer:self.layer];
}

- (CGPoint)convertPoint:(CGPoint)point
       fromKeypathLayer:(nonnull RDLOTKeypath *)keypath {
  [self _layoutAndForceUpdate];
  return [_compContainer convertPoint:point fromKeypathLayer:keypath withParentLayer:self.layer];
}

- (CGRect)convertRect:(CGRect)rect
     fromKeypathLayer:(nonnull RDLOTKeypath *)keypath {
  [self _layoutAndForceUpdate];
  return [_compContainer convertRect:rect fromKeypathLayer:keypath withParentLayer:self.layer];
}

#if TARGET_OS_IPHONE || TARGET_OS_SIMULATOR

- (void)addSubview:(nonnull RDLOTView *)view
    toKeypathLayer:(nonnull RDLOTKeypath *)keypath {
  [self _layoutAndForceUpdate];
  CGRect viewRect = view.frame;
  RDLOTView *wrapperView = [[RDLOTView alloc] initWithFrame:viewRect];
  view.frame = view.bounds;
  view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [wrapperView addSubview:view];
  [self addSubview:wrapperView];
  [_compContainer addSublayer:wrapperView.layer toKeypathLayer:keypath];
}

- (void)maskSubview:(nonnull RDLOTView *)view
     toKeypathLayer:(nonnull RDLOTKeypath *)keypath {
  [self _layoutAndForceUpdate];
  CGRect viewRect = view.frame;
  RDLOTView *wrapperView = [[RDLOTView alloc] initWithFrame:viewRect];
  view.frame = view.bounds;
  view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [wrapperView addSubview:view];
  [self addSubview:wrapperView];
  [_compContainer maskSublayer:wrapperView.layer toKeypathLayer:keypath];
}


#else

- (void)addSubview:(nonnull RDLOTView *)view
    toKeypathLayer:(nonnull RDLOTKeypath *)keypath {
  [self _layout];
  CGRect viewRect = view.frame;
  RDLOTView *wrapperView = [[RDLOTView alloc] initWithFrame:viewRect];
  view.frame = view.bounds;
  view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  [wrapperView addSubview:view];
  [self addSubview:wrapperView];
  [_compContainer addSublayer:wrapperView.layer toKeypathLayer:keypath];
}

- (void)maskSubview:(nonnull RDLOTView *)view
     toKeypathLayer:(nonnull RDLOTKeypath *)keypath {
  [self _layout];
  CGRect viewRect = view.frame;
  RDLOTView *wrapperView = [[RDLOTView alloc] initWithFrame:viewRect];
  view.frame = view.bounds;
  view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  [wrapperView addSubview:view];
  [self addSubview:wrapperView];
  [_compContainer maskSublayer:wrapperView.layer toKeypathLayer:keypath];
}

#endif

# pragma mark - Semi-Private Methods

- (CALayer * _Nullable)layerForKey:(NSString * _Nonnull)keyname {
  return _compContainer.childMap[keyname];
}

- (NSArray * _Nonnull)compositionLayers {
  return _compContainer.childLayers;
}

# pragma mark - Getters and Setters

- (CGFloat)animationDuration {
  if (!_sceneModel) {
    return 0;
  }
  CAAnimation *play = [_compContainer animationForKey:kCompContainerAnimationKey];
  if (play) {
    return play.duration;
  }
  return (_sceneModel.endFrame.floatValue - _sceneModel.startFrame.floatValue) / _sceneModel.framerate.floatValue;
}

- (CGFloat)animationProgress {
  if (_isAnimationPlaying &&
      _compContainer.presentationLayer) {
    CGFloat activeProgress = [self _progressForFrame:[(RDLOTCompositionContainer *)_compContainer.presentationLayer currentFrame]];
    return activeProgress;
  }
  return _animationProgress;
}

# pragma mark - Overrides

#if TARGET_OS_IPHONE || TARGET_OS_SIMULATOR

#define RDLOTViewContentMode UIViewContentMode
#define RDLOTViewContentModeScaleToFill UIViewContentModeScaleToFill
#define RDLOTViewContentModeScaleAspectFit UIViewContentModeScaleAspectFit
#define RDLOTViewContentModeScaleAspectFill UIViewContentModeScaleAspectFill
#define RDLOTViewContentModeRedraw UIViewContentModeRedraw
#define RDLOTViewContentModeCenter UIViewContentModeCenter
#define RDLOTViewContentModeTop UIViewContentModeTop
#define RDLOTViewContentModeBottom UIViewContentModeBottom
#define RDLOTViewContentModeLeft UIViewContentModeLeft
#define RDLOTViewContentModeRight UIViewContentModeRight
#define RDLOTViewContentModeTopLeft UIViewContentModeTopLeft
#define RDLOTViewContentModeTopRight UIViewContentModeTopRight
#define RDLOTViewContentModeBottomLeft UIViewContentModeBottomLeft
#define RDLOTViewContentModeBottomRight UIViewContentModeBottomRight

- (CGSize)intrinsicContentSize {
  if (!_sceneModel) {
    return CGSizeMake(UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric);
  }
  return _sceneModel.compBounds.size;
}

- (void)didMoveToSuperview {
  [super didMoveToSuperview];
  if (self.superview == nil) {
    [self _callCompletionIfNecessary:NO];
  }
}

- (void)dealloc {
    NSLog(@"%s", __func__);
    _sceneModel = nil;
    [_compContainer removeAllAnimations];
    [_compContainer removeFromSuperlayer];
    [_compContainer clear];
    _compContainer = nil;
    [self.layer.sublayers enumerateObjectsUsingBlock:^(__kindof CALayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.contents = nil;
        [obj removeFromSuperlayer];
    }];
    [self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
  // When this view or its superview is leaving the screen, e.g. a modal is presented or another
  // screen is pushed, this method will get called with newWindow value set to nil - indicating that
  // this view will be detached from the visible window.
  // When a view is detached, animations will stop - but will not automatically resumed when it's
  // re-attached back to window, e.g. when the presented modal is dismissed or another screen is
  // pop.
  if (newWindow) {
    // The view is being re-attached, resume animation if needed.
    if (_shouldRestoreStateWhenAttachedToWindow) {
      _shouldRestoreStateWhenAttachedToWindow = NO;

      _isAnimationPlaying = YES;
      _completionBlock = _completionBlockToRestoreWhenAttachedToWindow;
      _completionBlockToRestoreWhenAttachedToWindow = nil;

      [self performSelector:@selector(_restoreState) withObject:nil afterDelay:0];
    }
  } else {
    // The view is being detached, capture information that need to be restored later.
    if (_isAnimationPlaying) {
        [self pause];
      _shouldRestoreStateWhenAttachedToWindow = YES;
      _completionBlockToRestoreWhenAttachedToWindow = _completionBlock;
      _completionBlock = nil;
    }
  }
}

- (void)didMoveToWindow {
    _compContainer.rasterizationScale = self.window.screen.scale;
}

- (void)setContentMode:(RDLOTViewContentMode)contentMode {
  [super setContentMode:contentMode];
  [self setNeedsLayout];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  [self _layout];
}

#else

- (void)viewDidMoveToWindow {
    _compContainer.rasterizationScale = self.window.screen.backingScaleFactor;
}
    
- (void)setCompletionBlock:(RDLOTAnimationCompletionBlock)completionBlock {
    if (completionBlock) {
      _completionBlock = ^(BOOL finished) {
        dispatch_async(dispatch_get_main_queue(), ^{ completionBlock(finished); });
      };
    }
    else {
      _completionBlock = nil;
    }
}

- (void)setContentMode:(RDLOTViewContentMode)contentMode {
  _contentMode = contentMode;
  [self setNeedsLayout];
}

- (void)setNeedsLayout {
  self.needsLayout = YES;
}

- (BOOL)isFlipped {
  return YES;
}

- (BOOL)wantsUpdateLayer {
  return YES;
}

- (void)layout {
  [super layout];
  [self _layout];
}

#endif

- (void)_layoutAndForceUpdate {
  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  [self _layout];
  [_compContainer displayWithFrame:_compContainer.currentFrame forceUpdate:YES];
  [CATransaction commit];
}

- (void)_layout {
  CGPoint centerPoint = RDLOT_RectGetCenterPoint(self.bounds);
  CATransform3D xform;

  if (self.contentMode == RDLOTViewContentModeScaleToFill) {
    CGSize scaleSize = CGSizeMake(self.bounds.size.width / self.sceneModel.compBounds.size.width,
            self.bounds.size.height / self.sceneModel.compBounds.size.height);
    xform = CATransform3DMakeScale(scaleSize.width, scaleSize.height, 1);
  } else if (self.contentMode == RDLOTViewContentModeScaleAspectFit) {
    CGFloat compAspect = self.sceneModel.compBounds.size.width / self.sceneModel.compBounds.size.height;
    CGFloat viewAspect = self.bounds.size.width / self.bounds.size.height;
    BOOL scaleWidth = compAspect > viewAspect;
    CGFloat dominantDimension = scaleWidth ? self.bounds.size.width : self.bounds.size.height;
    CGFloat compDimension = scaleWidth ? self.sceneModel.compBounds.size.width : self.sceneModel.compBounds.size.height;
    CGFloat scale = dominantDimension / compDimension;
    xform = CATransform3DMakeScale(scale, scale, 1);
  } else if (self.contentMode == RDLOTViewContentModeScaleAspectFill) {
    CGFloat compAspect = self.sceneModel.compBounds.size.width / self.sceneModel.compBounds.size.height;
    CGFloat viewAspect = self.bounds.size.width / self.bounds.size.height;
    BOOL scaleWidth = compAspect < viewAspect;
    CGFloat dominantDimension = scaleWidth ? self.bounds.size.width : self.bounds.size.height;
    CGFloat compDimension = scaleWidth ? self.sceneModel.compBounds.size.width : self.sceneModel.compBounds.size.height;
    CGFloat scale = dominantDimension / compDimension;
    xform = CATransform3DMakeScale(scale, scale, 1);
  } else {
    xform = CATransform3DIdentity;
  }

  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  _compContainer.transform = CATransform3DIdentity;
  _compContainer.bounds = _sceneModel.compBounds;
  _compContainer.viewportBounds = _sceneModel.compBounds;
  _compContainer.transform = xform;
  _compContainer.position = centerPoint;
  [CATransaction commit];
}

# pragma mark - CAANimationDelegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)complete {
  if ([_compContainer animationForKey:kCompContainerAnimationKey] == anim &&
      [anim isKindOfClass:[CABasicAnimation class]]) {
    CABasicAnimation *playAnimation = (CABasicAnimation *)anim;
    NSNumber *frame = _compContainer.presentationLayer.currentFrame;
    if (complete) {
      // Set the final frame based on the animation to/from values. If playing forward, use the
      // toValue otherwise we want to end on the fromValue.
      frame = [self _isSpeedNegative] ? (NSNumber *)playAnimation.toValue : (NSNumber *)playAnimation.fromValue;
    }
    [self _removeCurrentAnimationIfNecessary];
    [self setProgressWithFrame:frame callCompletionIfNecessary:NO];
    [self _callCompletionIfNecessary:complete];
  }
}

# pragma mark - DEPRECATED

- (void)addSubview:(nonnull RDLOTView *)view
      toLayerNamed:(nonnull NSString *)layer
    applyTransform:(BOOL)applyTransform {
  NSLog(@"%s: Function is DEPRECATED. Please use addSubview:forKeypathLayer:", __PRETTY_FUNCTION__);
  RDLOTKeypath *keypath = [RDLOTKeypath keypathWithString:layer];
  if (applyTransform) {
    [self addSubview:view toKeypathLayer:keypath];
  } else {
    [self maskSubview:view toKeypathLayer:keypath];
  }
}

- (CGRect)convertRect:(CGRect)rect
         toLayerNamed:(NSString *_Nullable)layerName {
  NSLog(@"%s: Function is DEPRECATED. Please use convertRect:forKeypathLayer:", __PRETTY_FUNCTION__);
  RDLOTKeypath *keypath = [RDLOTKeypath keypathWithString:layerName];
  return [self convertRect:rect toKeypathLayer:keypath];
}

- (void)setValue:(nonnull id)value
      forKeypath:(nonnull NSString *)keypath
         atFrame:(nullable NSNumber *)frame {
  NSLog(@"%s: Function is DEPRECATED and no longer functional. Please use setValueCallback:forKeypath:", __PRETTY_FUNCTION__);
}

- (void)logHierarchyKeypaths {
  NSArray *keypaths = [self keysForKeyPath:[RDLOTKeypath keypathWithString:@"**"]];
  for (NSString *keypath in keypaths) {
    NSLog(@"%@", keypath);
  }
}

@end
