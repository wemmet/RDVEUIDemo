//
//  RDLOTBlockCallback.m
//  RDLottie
//
//  Created by brandon_withrow on 12/15/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTBlockCallback.h"

@implementation RDLOTColorBlockCallback

+ (instancetype)withBlock:(RDLOTColorValueCallbackBlock)block {
  RDLOTColorBlockCallback *colorCallback = [[self alloc] init];
  colorCallback.callback = block;
  return colorCallback;
}

- (CGColorRef)colorForFrame:(CGFloat)currentFrame startKeyframe:(CGFloat)startKeyframe endKeyframe:(CGFloat)endKeyframe interpolatedProgress:(CGFloat)interpolatedProgress startColor:(CGColorRef)startColor endColor:(CGColorRef)endColor currentColor:(CGColorRef)interpolatedColor {
  return self.callback(currentFrame, startKeyframe, endKeyframe, interpolatedProgress, startColor, endColor, interpolatedColor);
}

@end

@implementation RDLOTNumberBlockCallback

+ (instancetype)withBlock:(RDLOTNumberValueCallbackBlock)block {
  RDLOTNumberBlockCallback *numberCallback = [[self alloc] init];
  numberCallback.callback = block;
  return numberCallback;
}

- (CGFloat)floatValueForFrame:(CGFloat)currentFrame startKeyframe:(CGFloat)startKeyframe endKeyframe:(CGFloat)endKeyframe interpolatedProgress:(CGFloat)interpolatedProgress startValue:(CGFloat)startValue endValue:(CGFloat)endValue currentValue:(CGFloat)interpolatedValue {
  return self.callback(currentFrame, startKeyframe, endKeyframe, interpolatedProgress, startValue, endValue, interpolatedValue);
}

@end

@implementation RDLOTPointBlockCallback

+ (instancetype)withBlock:(RDLOTPointValueCallbackBlock)block {
  RDLOTPointBlockCallback *callback = [[self alloc] init];
  callback.callback = block;
  return callback;
}

- (CGPoint)pointForFrame:(CGFloat)currentFrame startKeyframe:(CGFloat)startKeyframe endKeyframe:(CGFloat)endKeyframe interpolatedProgress:(CGFloat)interpolatedProgress startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint currentPoint:(CGPoint)interpolatedPoint {
  return self.callback(currentFrame, startKeyframe, endKeyframe, interpolatedProgress, startPoint, endPoint, interpolatedPoint);
}

@end

@implementation RDLOTSizeBlockCallback

+ (instancetype)withBlock:(RDLOTSizeValueCallbackBlock)block {
  RDLOTSizeBlockCallback *callback = [[self alloc] init];
  callback.callback = block;
  return callback;
}

- (CGSize)sizeForFrame:(CGFloat)currentFrame startKeyframe:(CGFloat)startKeyframe endKeyframe:(CGFloat)endKeyframe interpolatedProgress:(CGFloat)interpolatedProgress startSize:(CGSize)startSize endSize:(CGSize)endSize currentSize:(CGSize)interpolatedSize {
  return self.callback(currentFrame, startKeyframe, endKeyframe, interpolatedProgress, startSize, endSize, interpolatedSize);
}

@end

@implementation RDLOTPathBlockCallback

+ (instancetype)withBlock:(RDLOTPathValueCallbackBlock)block {
  RDLOTPathBlockCallback *callback = [[self alloc] init];
  callback.callback = block;
  return callback;
}

- (CGPathRef)pathForFrame:(CGFloat)currentFrame startKeyframe:(CGFloat)startKeyframe endKeyframe:(CGFloat)endKeyframe interpolatedProgress:(CGFloat)interpolatedProgress {
  return self.callback(currentFrame, startKeyframe, endKeyframe, interpolatedProgress);
}

@end

