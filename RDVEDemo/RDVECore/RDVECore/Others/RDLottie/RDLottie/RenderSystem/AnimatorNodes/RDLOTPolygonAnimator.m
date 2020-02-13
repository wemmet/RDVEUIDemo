//
//  RDLOTPolygonAnimator.m
//  RDLottie
//
//  Created by brandon_withrow on 7/27/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTPolygonAnimator.h"
#import "RDLOTKeyframe.h"
#import "RDLOTPointInterpolator.h"
#import "RDLOTNumberInterpolator.h"
#import "RDLOTBezierPath.h"
#import "CGGeometry+RDLOTAdditions.h"

const CGFloat kRDPOLYGON_MAGIC_NUMBER = .25f;

@implementation RDLOTPolygonAnimator {
  RDLOTNumberInterpolator *_outerRadiusInterpolator;
  RDLOTNumberInterpolator *_outerRoundnessInterpolator;
  RDLOTPointInterpolator *_positionInterpolator;
  RDLOTNumberInterpolator *_pointsInterpolator;
  RDLOTNumberInterpolator *_rotationInterpolator;
}

- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                             shapePolygon:(RDLOTShapeStar *_Nonnull)shapeStar {
  self = [super initWithInputNode:inputNode keyName:shapeStar.keyname];
  if (self) {
    _outerRadiusInterpolator = [[RDLOTNumberInterpolator alloc] initWithKeyframes:shapeStar.outerRadius.keyframes];
    _outerRoundnessInterpolator = [[RDLOTNumberInterpolator alloc] initWithKeyframes:shapeStar.outerRoundness.keyframes];
    _pointsInterpolator = [[RDLOTNumberInterpolator alloc] initWithKeyframes:shapeStar.numberOfPoints.keyframes];
    _rotationInterpolator = [[RDLOTNumberInterpolator alloc] initWithKeyframes:shapeStar.rotation.keyframes];
    _positionInterpolator = [[RDLOTPointInterpolator alloc] initWithKeyframes:shapeStar.position.keyframes];
  }
  return self;
}

- (NSDictionary *)valueInterpolators {
  return @{@"Points" : _pointsInterpolator,
           @"Position" : _positionInterpolator,
           @"Rotation" : _rotationInterpolator,
           @"Outer Radius" : _outerRadiusInterpolator,
           @"Outer Roundness" : _outerRoundnessInterpolator};
}

- (BOOL)needsUpdateForFrame:(NSNumber *)frame {
  return ([_outerRadiusInterpolator hasUpdateForFrame:frame] ||
          [_outerRoundnessInterpolator hasUpdateForFrame:frame] ||
          [_pointsInterpolator hasUpdateForFrame:frame] ||
          [_rotationInterpolator hasUpdateForFrame:frame] ||
          [_positionInterpolator hasUpdateForFrame:frame]);
}

- (void)performLocalUpdate {
  CGFloat outerRadius = [_outerRadiusInterpolator floatValueForFrame:self.currentFrame];
  CGFloat outerRoundness = [_outerRoundnessInterpolator floatValueForFrame:self.currentFrame] / 100.f;
  CGFloat points = [_pointsInterpolator floatValueForFrame:self.currentFrame];
  CGFloat rotation = [_rotationInterpolator floatValueForFrame:self.currentFrame];
  CGPoint position = [_positionInterpolator pointValueForFrame:self.currentFrame];
  
  RDLOTBezierPath *path = [[RDLOTBezierPath alloc] init];
  path.cacheLengths = self.pathShouldCacheLengths;
  CGFloat currentAngle = RDLOT_DegreesToRadians(rotation - 90);
  CGFloat anglePerPoint = (CGFloat)((2 * M_PI) / points);

  CGFloat x;
  CGFloat y;
  CGFloat previousX;
  CGFloat previousY;
  x = (CGFloat) (outerRadius * cosf(currentAngle));
  y = (CGFloat) (outerRadius * sinf(currentAngle));
  [path RDLOT_moveToPoint:CGPointMake(x, y)];
  currentAngle += anglePerPoint;
  
  double numPoints = ceil(points);
  for (int i = 0; i < numPoints; i++) {
    previousX = x;
    previousY = y;
    x = (CGFloat) (outerRadius * cosf(currentAngle));
    y = (CGFloat) (outerRadius * sinf(currentAngle));
    
    if (outerRoundness != 0) {
      CGFloat cp1Theta = (CGFloat) (atan2(previousY, previousX) - M_PI / 2.f);
      CGFloat cp1Dx = (CGFloat) cosf(cp1Theta);
      CGFloat cp1Dy = (CGFloat) sinf(cp1Theta);
      
      CGFloat cp2Theta = (CGFloat) (atan2(y, x) - M_PI / 2.f);
      CGFloat cp2Dx = (CGFloat) cosf(cp2Theta);
      CGFloat cp2Dy = (CGFloat) sinf(cp2Theta);
      
      CGFloat cp1x = outerRadius * outerRoundness * kRDPOLYGON_MAGIC_NUMBER * cp1Dx;
      CGFloat cp1y = outerRadius * outerRoundness * kRDPOLYGON_MAGIC_NUMBER * cp1Dy;
      CGFloat cp2x = outerRadius * outerRoundness * kRDPOLYGON_MAGIC_NUMBER * cp2Dx;
      CGFloat cp2y = outerRadius * outerRoundness * kRDPOLYGON_MAGIC_NUMBER * cp2Dy;
      [path RDLOT_addCurveToPoint:CGPointMake(x, y)
                  controlPoint1:CGPointMake(previousX - cp1x, previousY - cp1y)
                  controlPoint2:CGPointMake(x + cp2x, y + cp2y)];
    } else {
      [path RDLOT_addLineToPoint:CGPointMake(x, y)];
    }
    
    currentAngle += anglePerPoint;
  }
  [path RDLOT_closePath];
  [path RDLOT_applyTransform:CGAffineTransformMakeTranslation(position.x, position.y)];
  self.localPath = path;
}

@end
