//
//  RDLOTTransformInterpolator.h
//  RDLottie
//
//  Created by brandon_withrow on 7/18/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDLOTNumberInterpolator.h"
#import "RDLOTPointInterpolator.h"
#import "RDLOTSizeInterpolator.h"
#import "RDLOTKeyframe.h"
#import "RDLOTLayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface RDLOTTransformInterpolator : NSObject

+ (instancetype)transformForLayer:(RDLOTLayer *)layer;

- (instancetype)initWithPosition:(NSArray <RDLOTKeyframe *> *)position
                        rotation:(NSArray <RDLOTKeyframe *> *)rotation
                          anchor:(NSArray <RDLOTKeyframe *> *)anchor
                           scale:(NSArray <RDLOTKeyframe *> *)scale;

- (instancetype)initWithPositionX:(NSArray <RDLOTKeyframe *> *)positionX
                        positionY:(NSArray <RDLOTKeyframe *> *)positionY
                         rotation:(NSArray <RDLOTKeyframe *> *)rotation
                           anchor:(NSArray <RDLOTKeyframe *> *)anchor
                            scale:(NSArray <RDLOTKeyframe *> *)scale;

@property (nonatomic, strong) RDLOTTransformInterpolator * inputNode;

@property (nonatomic, readonly) RDLOTPointInterpolator *positionInterpolator;
@property (nonatomic, readonly) RDLOTPointInterpolator *anchorInterpolator;
@property (nonatomic, readonly) RDLOTSizeInterpolator *scaleInterpolator;
@property (nonatomic, readonly) RDLOTNumberInterpolator *rotationInterpolator;
@property (nonatomic, readonly) RDLOTNumberInterpolator *positionXInterpolator;
@property (nonatomic, readonly) RDLOTNumberInterpolator *positionYInterpolator;
@property (nonatomic, strong, nullable) NSString *parentKeyName;

- (CATransform3D)transformForFrame:(NSNumber *)frame;
- (BOOL)hasUpdateForFrame:(NSNumber *)frame;

@end

NS_ASSUME_NONNULL_END
