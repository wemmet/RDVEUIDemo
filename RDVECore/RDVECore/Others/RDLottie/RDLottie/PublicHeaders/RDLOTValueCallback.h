//
//  RDLOTValueCallback.h
//  RDLottie
//
//  Created by brandon_withrow on 12/15/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "RDLOTValueDelegate.h"

/*!
 @brief RDLOTColorValueCallback is a container for a CGColorRef. This container is a RDLOTColorValueDelegate that always returns the colorValue property to its animation delegate.
 @discussion RDLOTColorValueCallback is used in conjunction with RDLOTAnimationView setValueDelegate:forKeypath to set a color value of an animation property.
 */

@interface RDLOTColorValueCallback : NSObject <RDLOTColorValueDelegate>

+ (instancetype _Nonnull)withCGColor:(CGColorRef _Nonnull)color NS_SWIFT_NAME(init(color:));

@property (nonatomic, nonnull) CGColorRef colorValue;

@end

/*!
 @brief RDLOTNumberValueCallback is a container for a CGFloat value. This container is a RDLOTNumberValueDelegate that always returns the numberValue property to its animation delegate.
 @discussion RDLOTNumberValueCallback is used in conjunction with RDLOTAnimationView setValueDelegate:forKeypath to set a number value of an animation property.
 */

@interface RDLOTNumberValueCallback : NSObject <RDLOTNumberValueDelegate>

+ (instancetype _Nonnull)withFloatValue:(CGFloat)numberValue NS_SWIFT_NAME(init(number:));

@property (nonatomic, assign) CGFloat numberValue;

@end

/*!
 @brief RDLOTPointValueCallback is a container for a CGPoint value. This container is a RDLOTPointValueDelegate that always returns the pointValue property to its animation delegate.
 @discussion RDLOTPointValueCallback is used in conjunction with RDLOTAnimationView setValueDelegate:forKeypath to set a point value of an animation property.
 */

@interface RDLOTPointValueCallback : NSObject <RDLOTPointValueDelegate>

+ (instancetype _Nonnull)withPointValue:(CGPoint)pointValue;

@property (nonatomic, assign) CGPoint pointValue;

@end

/*!
 @brief RDLOTSizeValueCallback is a container for a CGSize value. This container is a RDLOTSizeValueDelegate that always returns the sizeValue property to its animation delegate.
 @discussion RDLOTSizeValueCallback is used in conjunction with RDLOTAnimationView setValueDelegate:forKeypath to set a size value of an animation property.
 */

@interface RDLOTSizeValueCallback : NSObject <RDLOTSizeValueDelegate>

+ (instancetype _Nonnull)withPointValue:(CGSize)sizeValue NS_SWIFT_NAME(init(size:));

@property (nonatomic, assign) CGSize sizeValue;

@end

/*!
 @brief RDLOTPathValueCallback is a container for a CGPathRef value. This container is a RDLOTPathValueDelegate that always returns the pathValue property to its animation delegate.
 @discussion RDLOTPathValueCallback is used in conjunction with RDLOTAnimationView setValueDelegate:forKeypath to set a path value of an animation property.
 */

@interface RDLOTPathValueCallback : NSObject <RDLOTPathValueDelegate>

+ (instancetype _Nonnull)withCGPath:(CGPathRef _Nonnull)path NS_SWIFT_NAME(init(path:));

@property (nonatomic, nonnull) CGPathRef pathValue;

@end
