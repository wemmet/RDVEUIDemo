//
//  RDLOTLayer.h
//  RDLottieAnimator
//
//  Created by Brandon Withrow on 12/14/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDLOTPlatformCompat.h"
#import "RDLOTKeyframe.h"

@class RDLOTShapeGroup;
@class RDLOTMask;
@class RDLOTAsset;
@class RDLOTAssetGroup;
@class RDLOTEffectGroup;


typedef enum : NSInteger {
  RDLOTLayerTypePrecomp,
  RDLOTLayerTypeSolid,
  RDLOTLayerTypeImage,
  RDLOTLayerTypeNull,
  RDLOTLayerTypeShape,
  RDLOTLayerTypeUnknown
} RDLOTLayerType;

typedef enum : NSInteger {
  RDLOTMatteTypeNone,
  RDLOTMatteTypeAdd,
  RDLOTMatteTypeInvert,
  RDLOTMatteTypeUnknown
} RDLOTMatteType;

NS_ASSUME_NONNULL_BEGIN

@interface RDLOTLayer : NSObject

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary
              withAssetGroup:(RDLOTAssetGroup * _Nullable)assetGroup
               withFramerate:(NSNumber *)framerate
               withFrameSize:(CGSize) frameSize;

@property (nonatomic, readonly) NSString *layerName;
@property (nonatomic, readonly, nullable) NSString *referenceID;
@property (nonatomic, readonly) NSNumber *layerID;
@property (nonatomic, readonly) RDLOTLayerType layerType;
@property (nonatomic, readonly, nullable) NSNumber *parentID;
@property (nonatomic, readonly) NSNumber *startFrame;
@property (nonatomic, readonly) NSNumber *inFrame;
@property (nonatomic, readonly) NSNumber *outFrame;
@property (nonatomic, readonly) NSNumber *timeStretch;
@property (nonatomic, readonly) CGRect layerBounds;

@property (nonatomic, readonly, nullable) NSArray<RDLOTShapeGroup *> *shapes;
@property (nonatomic, readonly, nullable) NSArray<RDLOTMask *> *masks;

@property (nonatomic, readonly, nullable) NSNumber *layerWidth;
@property (nonatomic, readonly, nullable) NSNumber *layerHeight;
@property (nonatomic, readonly, nullable) UIColor *solidColor;
@property (nonatomic, readonly, nullable) RDLOTAsset *imageAsset;

@property (nonatomic, readonly) RDLOTKeyframeGroup *opacity;
@property (nonatomic, readonly, nullable) RDLOTKeyframeGroup *timeRemapping;
@property (nonatomic, readonly) RDLOTKeyframeGroup *rotation;
@property (nonatomic, readonly, nullable) RDLOTKeyframeGroup *position;

@property (nonatomic, readonly, nullable) RDLOTKeyframeGroup *positionX;
@property (nonatomic, readonly, nullable) RDLOTKeyframeGroup *positionY;

@property (nonatomic, readonly) RDLOTKeyframeGroup *anchor;
@property (nonatomic, readonly) RDLOTKeyframeGroup *scale;

@property (nonatomic, readonly) RDLOTMatteType matteType;

@property (nonatomic, readonly, nullable) NSArray<RDLOTEffectGroup *> *effects;//2019.09.11 xiachunlin

- (void)refreshInFrame:(NSNumber *)newInFrame outFrame:(NSNumber *)newOutFrame;

@end

NS_ASSUME_NONNULL_END
