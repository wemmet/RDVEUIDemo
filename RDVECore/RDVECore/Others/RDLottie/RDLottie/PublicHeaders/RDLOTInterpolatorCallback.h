//
//  RDLOTInterpolatorCallback.h
//  RDLottie
//
//  Created by brandon_withrow on 12/15/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "RDLOTValueDelegate.h"

/*!
 @brief RDLOTPointInterpolatorCallback is a container for a CGPointRef. This container is a RDLOTPointValueDelegate that will return the point interpolated at currentProgress between fromPoint and toPoint. Externally changing currentProgress will change the point of the animation.
 @discussion RDLOTPointInterpolatorCallback is used in conjunction with RDLOTAnimationView setValueDelegate:forKeypoint to set a point value of an animation property.
 */

@interface RDLOTPointInterpolatorCallback : NSObject <RDLOTPointValueDelegate>

+ (instancetype _Nonnull)withFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint NS_SWIFT_NAME(init(from:to:));

@property (nonatomic) CGPoint fromPoint;
@property (nonatomic) CGPoint toPoint;

/*!
 @brief As currentProgess changes from 0 to 1 the point sent to the animation view is interpolated between fromPoint and toPoint.
 */

@property (nonatomic, assign) CGFloat currentProgress;

@end

/*!
 @brief RDLOTSizeInterpolatorCallback is a container for a CGSizeRef. This container is a RDLOTSizeValueDelegate that will return the size interpolated at currentProgress between fromSize and toSize. Externally changing currentProgress will change the size of the animation.
 @discussion RDLOTSizeInterpolatorCallback is used in conjunction with RDLOTAnimationView setValueDelegate:forKeysize to set a size value of an animation property.
 */

@interface RDLOTSizeInterpolatorCallback : NSObject <RDLOTSizeValueDelegate>

+ (instancetype _Nonnull)withFromSize:(CGSize)fromSize toSize:(CGSize)toSize NS_SWIFT_NAME(init(from:to:));

@property (nonatomic) CGSize fromSize;
@property (nonatomic) CGSize toSize;

/*!
 @brief As currentProgess changes from 0 to 1 the size sent to the animation view is interpolated between fromSize and toSize.
 */

@property (nonatomic, assign) CGFloat currentProgress;

@end

/*!
 @brief RDLOTFloatInterpolatorCallback is a container for a CGFloatRef. This container is a RDLOTFloatValueDelegate that will return the float interpolated at currentProgress between fromFloat and toFloat. Externally changing currentProgress will change the float of the animation.
 @discussion RDLOTFloatInterpolatorCallback is used in conjunction with RDLOTAnimationView setValueDelegate:forKeyfloat to set a float value of an animation property.
 */

@interface RDLOTFloatInterpolatorCallback : NSObject <RDLOTNumberValueDelegate>

+ (instancetype _Nonnull)withFromFloat:(CGFloat)fromFloat toFloat:(CGFloat)toFloat NS_SWIFT_NAME(init(from:to:));

@property (nonatomic) CGFloat fromFloat;
@property (nonatomic) CGFloat toFloat;

/*!
 @brief As currentProgess changes from 0 to 1 the float sent to the animation view is interpolated between fromFloat and toFloat.
 */

@property (nonatomic, assign) CGFloat currentProgress;

@end
