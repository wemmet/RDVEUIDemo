//
//  RDLOTEffectDistortion.h
//  RDLottieAnimator
//
//  Created by xiachunlin Withrow on 2019/10/12.
//  Copyright © 2019 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDLOTKeyframe.h"

@interface RDLOTEffectDistortion : NSObject

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary withFrameSize:(CGSize) frameSize;

@property (nonatomic, readonly) NSString *keyName;
@property (nonatomic, readonly) NSString *keyMatchName;
@property (nonatomic, readonly) int keyType;
@property (nonatomic, readonly) float radius;
@property (nonatomic, readonly) float scale;
@property (nonatomic, readonly) CGPoint center;
@property (nonatomic, readonly) CGSize frameSize;
@property (nonatomic, readonly) bool invalidSpatialInTangent;
@property (nonatomic, readonly) bool invalidSpatialOutTangent;
@property (nonatomic, readonly) RDLOTKeyframeGroup *distortion;

@end
