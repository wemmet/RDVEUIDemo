//
//  RDLOTCompositionContainer.h
//  RDLottie
//
//  Created by brandon_withrow on 7/18/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTLayerContainer.h"
#import "RDLOTAssetGroup.h"

@interface RDLOTCompositionContainer : RDLOTLayerContainer

- (instancetype _Nonnull)initWithModel:(RDLOTLayer * _Nullable)layer
                          inLayerGroup:(RDLOTLayerGroup * _Nullable)layerGroup
                        withLayerGroup:(RDLOTLayerGroup * _Nullable)childLayerGroup
                       withAssestGroup:(RDLOTAssetGroup * _Nullable)assetGroup
                          withEndFrame:(NSNumber *)endFrame;//20180622 wuxiaoxia

- (nullable NSArray *)keysForKeyPath:(nonnull RDLOTKeypath *)keypath;

- (CGPoint)convertPoint:(CGPoint)point
         toKeypathLayer:(nonnull RDLOTKeypath *)keypath
        withParentLayer:(CALayer *_Nonnull)parent;

- (CGRect)convertRect:(CGRect)rect
       toKeypathLayer:(nonnull RDLOTKeypath *)keypath
      withParentLayer:(CALayer *_Nonnull)parent;

- (CGPoint)convertPoint:(CGPoint)point
       fromKeypathLayer:(nonnull RDLOTKeypath *)keypath
        withParentLayer:(CALayer *_Nonnull)parent;

- (CGRect)convertRect:(CGRect)rect
     fromKeypathLayer:(nonnull RDLOTKeypath *)keypath
      withParentLayer:(CALayer *_Nonnull)parent;

- (void)addSublayer:(nonnull CALayer *)subLayer
    toKeypathLayer:(nonnull RDLOTKeypath *)keypath;

- (void)maskSublayer:(nonnull CALayer *)subLayer
     toKeypathLayer:(nonnull RDLOTKeypath *)keypath;

@property (nonatomic, readonly, nonnull) NSArray<RDLOTLayerContainer *> *childLayers;
@property (nonatomic, readonly, nonnull)  NSDictionary *childMap;
@property (nonatomic, readonly) RDLOTLayer *currentLayer;//20180802 wuxiaoxia

- (void)refreshEndFrame:(NSNumber *)endFrame;

- (void)clear;

@end
