//
//  RDLOTLayerContainer.h
//  RDLottie
//
//  Created by brandon_withrow on 7/18/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTPlatformCompat.h"
#import "RDLOTLayer.h"
#import "RDLOTLayerGroup.h"
#import "RDLOTKeypath.h"
#import "RDLOTValueDelegate.h"

@class RDLOTValueCallback;

@protocol RDLOTChangeLayerContentsDelegate <NSObject>

- (void)changeLayerContents:(CALayer *)layer layerName:(NSString *)layerName;

@end

@interface RDLOTLayerContainer : CALayer

- (instancetype _Nonnull)initWithModel:(RDLOTLayer * _Nullable)layer
                 inLayerGroup:(RDLOTLayerGroup * _Nullable)layerGroup;

@property (nonatomic,  readonly, strong, nullable) NSString *layerName;
@property (nonatomic,  readonly, strong, nullable) NSNumber *inFrame;   //20180814 wuxiaoxia lottie
@property (nonatomic,  readonly, strong, nullable) NSNumber *outFrame;  //20180814 wuxiaoxia lottie
@property (nonatomic,  readonly, strong, nullable) RDLOTLayer *layer;     //20180814 wuxiaoxia lottie
@property (nonatomic, nullable) NSNumber *currentFrame;
@property (nonatomic, readonly, nonnull) NSNumber *timeStretchFactor;
@property (nonatomic, assign) CGRect viewportBounds;
@property (nonatomic, readonly, nonnull) CALayer *wrapperLayer;
@property (nonatomic, readonly, nonnull) NSDictionary *valueInterpolators;
@property (nonatomic, weak) id<RDLOTChangeLayerContentsDelegate> changedDlegate;

- (void)_setImageForAsset:(RDLOTAsset *)asset;
- (void)displayWithFrame:(NSNumber * _Nonnull)frame;
- (void)displayWithFrame:(NSNumber * _Nonnull)frame forceUpdate:(BOOL)forceUpdate;

- (void)searchNodesForKeypath:(RDLOTKeypath * _Nonnull)keypath;

- (void)setValueDelegate:(id<RDLOTValueDelegate> _Nonnull)delegate
              forKeypath:(RDLOTKeypath * _Nonnull)keypath;

- (void)refreshInFrame:(NSNumber *)newInFrame outFrame:(NSNumber *)newOutFrame;

- (void)clear;

@end
