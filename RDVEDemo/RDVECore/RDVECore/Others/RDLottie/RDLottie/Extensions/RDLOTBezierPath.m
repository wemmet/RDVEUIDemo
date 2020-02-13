//
//  RDLOTBezierPath.m
//  RDLottie
//
//  Created by brandon_withrow on 7/20/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTBezierPath.h"
#import "CGGeometry+RDLOTAdditions.h"

typedef struct RDLOT_Subpath RDLOT_Subpath;
typedef void(^RDLOTBezierPathEnumerationHandler)(const CGPathElement *element);

struct RDLOT_Subpath {
  CGPathElementType type;
  CGFloat length;
  CGPoint endPoint;
  CGPoint controlPoint1;
  CGPoint controlPoint2;
  RDLOT_Subpath *nextSubpath;
};

@interface RDLOTBezierPath ()
@property (nonatomic, readonly) RDLOT_Subpath *headSubpath;
@end

@implementation RDLOTBezierPath {
  RDLOT_Subpath *headSubpath_;
  RDLOT_Subpath *tailSubpath_;
  CGPoint subpathStartPoint_;
  CGFloat *_lineDashPattern;
  NSInteger _lineDashCount;
  CGFloat _lineDashPhase;
  CGMutablePathRef _path;
}

// MARK - Lifecycle

+ (instancetype)pathWithCGPath:(CGPathRef)path {
  RDLOTBezierPath *returnPath = [RDLOTBezierPath newPath];
  [returnPath setWithCGPath:path];
  return returnPath;
}

+ (instancetype)newPath {
  return [[RDLOTBezierPath alloc] init];
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    _length = 0;
    headSubpath_ = NULL;
    tailSubpath_ = NULL;
    _path = CGPathCreateMutable();
    _lineWidth = 1;
    _lineCapStyle = kCGLineCapButt;
    _lineJoinStyle = kCGLineJoinMiter;
    _miterLimit = 10;
    _flatness = 0.6;
    _usesEvenOddFillRule = NO;
    _lineDashPattern = NULL;
    _lineDashCount = 0;
    _lineDashPhase = 0;
    _cacheLengths = NO;
  }
  return self;
}

- (void)dealloc {
  [self removeAllSubpaths];
  if (_path) CGPathRelease(_path);
}

- (id)copyWithZone:(NSZone *)zone {
  RDLOTBezierPath *copy = [[self class] new];
  
  copy.cacheLengths = self.cacheLengths;
  copy.lineWidth = self.lineWidth;
  copy.lineCapStyle = self.lineCapStyle;
  copy.lineJoinStyle = self.lineJoinStyle;
  copy.miterLimit = self.miterLimit;
  copy.flatness = self.flatness;
  copy.usesEvenOddFillRule = self.usesEvenOddFillRule;
  
  [copy RDLOT_appendPath:self];
  
  return copy;
}

// MARK - Subpaths List

- (void)removeAllSubpaths {
  RDLOT_Subpath *node = headSubpath_;
  while (node) {
    RDLOT_Subpath *nextNode = node->nextSubpath;
    node->nextSubpath = NULL;
    free(node);
    node = nextNode;
  }
  headSubpath_ = NULL;
  tailSubpath_ = NULL;
}

- (void)addSubpathWithType:(CGPathElementType)type
                    length:(CGFloat)length
                  endPoint:(CGPoint)endPoint
             controlPoint1:(CGPoint)controlPoint1
             controlPoint1:(CGPoint)controlPoint2 {
  RDLOT_Subpath *subPath = (RDLOT_Subpath *)malloc(sizeof(RDLOT_Subpath));
  subPath->type = type;
  subPath->length = length;
  subPath->endPoint = endPoint;
  subPath->controlPoint1 = controlPoint1;
  subPath->controlPoint2 = controlPoint2;
  subPath->nextSubpath = NULL;
  if (tailSubpath_ == NULL) {
    headSubpath_ = subPath;
    tailSubpath_ = subPath;
  } else {
    tailSubpath_->nextSubpath = subPath;
    tailSubpath_ = subPath;
  }
}

// MARK Getters Setters

- (CGPoint)currentPoint {
  CGPoint previousPoint = tailSubpath_ ? tailSubpath_->endPoint : CGPointZero;
  return previousPoint;
}

- (CGPathRef)CGPath {
  return _path;
}

- (RDLOT_Subpath *)headSubpath {
  return headSubpath_;
}

// MARK - External

- (void)RDLOT_moveToPoint:(CGPoint)point {
  subpathStartPoint_ = point;
  [self addSubpathWithType:kCGPathElementMoveToPoint length:0 endPoint:point controlPoint1:CGPointZero controlPoint1:CGPointZero];
  CGPathMoveToPoint(_path, NULL, point.x, point.y);
}

- (void)RDLOT_addLineToPoint:(CGPoint)point {
  CGFloat length = 0;
  if (_cacheLengths) {
    length = RDLOT_PointDistanceFromPoint(self.currentPoint, point);
    _length = _length + length;
  }
  [self addSubpathWithType:kCGPathElementAddLineToPoint length:length endPoint:point controlPoint1:CGPointZero controlPoint1:CGPointZero];
  CGPathAddLineToPoint(_path, NULL, point.x, point.y);
}

- (void)RDLOT_addCurveToPoint:(CGPoint)point
              controlPoint1:(CGPoint)cp1
              controlPoint2:(CGPoint)cp2 {
  CGFloat length = 0;
  if (_cacheLengths) {
    length = RDLOT_CubicLengthWithPrecision(self.currentPoint, point, cp1, cp2, 5);
    _length = _length + length;
  }
  [self addSubpathWithType:kCGPathElementAddCurveToPoint length:length endPoint:point controlPoint1:cp1 controlPoint1:cp2];
  CGPathAddCurveToPoint(_path, NULL, cp1.x, cp1.y, cp2.x, cp2.y, point.x, point.y);
}

- (void)RDLOT_closePath {
  CGFloat length = 0;
  if (_cacheLengths) {
    length = RDLOT_PointDistanceFromPoint(self.currentPoint, subpathStartPoint_);
    _length = _length + length;
  }
  [self addSubpathWithType:kCGPathElementCloseSubpath length:length endPoint:subpathStartPoint_ controlPoint1:CGPointZero controlPoint1:CGPointZero];
  CGPathCloseSubpath(_path);
}

- (void)_clearPathData {
  _length = 0;
  subpathStartPoint_ = CGPointZero;
  CGPathRelease(_path);
  _path = CGPathCreateMutable();
}

- (void)RDLOT_removeAllPoints {
  [self removeAllSubpaths];
  [self _clearPathData];
}

- (BOOL)containsPoint:(CGPoint)point {
  return CGPathContainsPoint(_path, NULL, point, _usesEvenOddFillRule);
}

- (BOOL)isEmpty {
  return CGPathIsEmpty(_path);
}

- (CGRect)bounds {
  return CGPathGetBoundingBox(_path);
}

- (void)RDLOT_applyTransform:(CGAffineTransform)transform {
  CGMutablePathRef mutablePath = CGPathCreateMutable();
  CGPathAddPath(mutablePath, &transform, _path);
  CGPathRelease(_path);
  _path = mutablePath;
}

- (void)RDLOT_appendPath:(RDLOTBezierPath *)bezierPath {
  CGPathAddPath(_path, NULL, bezierPath.CGPath);
  
  RDLOT_Subpath *nextSubpath = bezierPath.headSubpath;
  while (nextSubpath) {
    CGFloat length = 0;
    if (self.cacheLengths) {
      if (bezierPath.cacheLengths) {
        length = nextSubpath->length;
      } else {
        // No previous length data, measure.
        if (nextSubpath->type == kCGPathElementAddLineToPoint) {
          length = RDLOT_PointDistanceFromPoint(self.currentPoint, nextSubpath->endPoint);
        } else if (nextSubpath->type == kCGPathElementAddCurveToPoint) {
          length = RDLOT_CubicLengthWithPrecision(self.currentPoint, nextSubpath->endPoint, nextSubpath->controlPoint1, nextSubpath->controlPoint2, 5);
        } else if (nextSubpath->type == kCGPathElementCloseSubpath) {
          length = RDLOT_PointDistanceFromPoint(self.currentPoint, nextSubpath->endPoint);
        }
      }
    }
    _length = _length + length;
    [self addSubpathWithType:nextSubpath->type
                      length:length
                    endPoint:nextSubpath->endPoint
               controlPoint1:nextSubpath->controlPoint1
               controlPoint1:nextSubpath->controlPoint2];
    
    nextSubpath = nextSubpath->nextSubpath;
  }
}

- (void)trimPathFromT:(CGFloat)fromT toT:(CGFloat)toT offset:(CGFloat)offset {
  fromT = MIN(MAX(0, fromT), 1);
  toT = MIN(MAX(0, toT), 1);
  if (fromT > toT) {
    CGFloat to = fromT;
    fromT = toT;
    toT = to;
  }
  
  offset = offset - floor(offset);
  CGFloat fromLength = fromT + offset;
  CGFloat toLength = toT + offset;
  
  if (toT - fromT == 1) {
    // Do Nothing, Full Path returned.
    return;
  }
  
  if (fromLength == toLength) {
    // Empty Path
    [self RDLOT_removeAllPoints];
    return;
  }
  
  if (fromLength >= 1) {
    fromLength = fromLength - floor(fromLength);
  }
  if (toLength > 1) {
    toLength = toLength - floor(toLength);
  }
  
  if (fromLength == 0 &&
      toLength == 1) {
    // Do Nothing. Full Path returned.
    return;
  }
  
  if (fromLength == toLength) {
    // Empty Path
    [self RDLOT_removeAllPoints];
    return;
  }
  
  CGFloat totalLength = _length;
  
  [self _clearPathData];

  RDLOT_Subpath *subpath = headSubpath_;
  headSubpath_ = NULL;
  tailSubpath_ = NULL;
  
  fromLength = fromLength * totalLength;
  toLength = toLength * totalLength;
  
  CGFloat currentStartLength = fromLength < toLength ? fromLength : 0;
  CGFloat currentEndLength = toLength;

  CGFloat subpathBeginningLength = 0;
  CGPoint currentPoint = CGPointZero;

  while (subpath) {
    
    CGFloat pathLength = subpath->length;
    if (!_cacheLengths) {
      if (subpath->type == kCGPathElementAddLineToPoint) {
        pathLength = RDLOT_PointDistanceFromPoint(currentPoint, subpath->endPoint);
      } else if (subpath->type == kCGPathElementAddCurveToPoint) {
        pathLength = RDLOT_CubicLengthWithPrecision(currentPoint, subpath->endPoint, subpath->controlPoint1, subpath->controlPoint2, 5);
      } else if (subpath->type == kCGPathElementCloseSubpath) {
        pathLength = RDLOT_PointDistanceFromPoint(currentPoint, subpath->endPoint);
      }
    }
    CGFloat subpathEndLength = subpathBeginningLength + pathLength;

    if (subpath->type != kCGPathElementMoveToPoint &&
        subpathEndLength > currentStartLength) {
      // The end of this path overlaps the current drawing region
      
      // x                    x                                 x                          x
      // ---------------ooooooooooooooooooooooooooooooooooooooooooooooooo-------------------
      // Start          |currentStartLength             currentEndLength|                End
      
      CGFloat currentSpanStartT = RDLOT_RemapValue(currentStartLength, subpathBeginningLength, subpathEndLength, 0, 1);
      CGFloat currentSpanEndT = RDLOT_RemapValue(currentEndLength, subpathBeginningLength, subpathEndLength, 0, 1);
      
      // At this point currentSpan start and end T can be less than 0 or greater than 1
      
      if (subpath->type == kCGPathElementAddLineToPoint) {
        
        if (currentSpanStartT >= 0) {
          // The current drawable span either starts with this subpath or along this subpath.
          // If this is the middle of a segment then currentSpanStartT would be less than 0
          if (currentSpanStartT > 0) {
            currentPoint = RDLOT_PointInLine(currentPoint, subpath->endPoint, currentSpanStartT);
          }
          [self RDLOT_moveToPoint:currentPoint];
          // Now we are ready to draw a line
        }
        
        CGPoint toPoint = subpath->endPoint;
        if (currentSpanEndT < 1) {
          // The end of the span is inside of the current subpath. Find it.
          toPoint = RDLOT_PointInLine(currentPoint, subpath->endPoint, currentSpanEndT);
        }
        [self RDLOT_addLineToPoint:toPoint];
        currentPoint = toPoint;
      } else if (subpath->type == kCGPathElementAddCurveToPoint) {

        CGPoint cp1, cp2, end;
        cp1 = subpath->controlPoint1;
        cp2 = subpath->controlPoint2;
        end = subpath->endPoint;
        
        if (currentSpanStartT >= 0) {
          // The current drawable span either starts with this subpath or along this subpath.
          // If this is the middle of a segment then currentSpanStartT would be less than 0
          // Beginning of a segment Move start point and calculate cp1 and 2 is necessary
          if (currentSpanStartT > 0) {
            CGPoint A = RDLOT_PointInLine(currentPoint, cp1, currentSpanStartT);
            CGPoint B = RDLOT_PointInLine(cp1, cp2, currentSpanStartT);
            CGPoint C = RDLOT_PointInLine(cp2, end, currentSpanStartT);
            CGPoint D = RDLOT_PointInLine(A, B, currentSpanStartT);
            CGPoint E = RDLOT_PointInLine(B, C, currentSpanStartT);
            CGPoint F = RDLOT_PointInLine(D, E, currentSpanStartT);
            currentPoint = F;
            cp1 = E;
            cp2 = C;
            currentSpanEndT = RDLOT_RemapValue(currentSpanEndT, currentSpanStartT, 1, 0, 1);
          }
          [self RDLOT_moveToPoint:currentPoint];
        }
        
        if (currentSpanEndT < 1) {
          CGPoint A = RDLOT_PointInLine(currentPoint, cp1, currentSpanEndT);
          CGPoint B = RDLOT_PointInLine(cp1, cp2, currentSpanEndT);
          CGPoint C = RDLOT_PointInLine(cp2, end, currentSpanEndT);
          CGPoint D = RDLOT_PointInLine(A, B, currentSpanEndT);
          CGPoint E = RDLOT_PointInLine(B, C, currentSpanEndT);
          CGPoint F = RDLOT_PointInLine(D, E, currentSpanEndT);
          cp1 = A;
          cp2 = D;
          end = F;
        }
        [self RDLOT_addCurveToPoint:end controlPoint1:cp1 controlPoint2:cp2];
      }

      if (currentSpanEndT <= 1) {
        // We have possibly reached the end.
        // Current From and To will possibly need to be reset.
        if (fromLength < toLength) {
            while (subpath) {
                RDLOT_Subpath *nextNode = subpath->nextSubpath;
                subpath->nextSubpath = NULL;
                free(subpath);
                subpath = nextNode;
            }
            break;
        } else {
          currentStartLength = fromLength;
          currentEndLength = totalLength;
          if (fromLength < (subpathBeginningLength + pathLength) &&
              fromLength > subpathBeginningLength &&
              currentSpanEndT < 1) {
            // Loop over this subpath one more time.
            // In this case the path start and end trim fall within this subpath bounds
            continue;
          }
        }
      }
    }
    currentPoint = subpath->endPoint;
    subpathBeginningLength = subpathEndLength;
    
    RDLOT_Subpath *nextNode = subpath->nextSubpath;
    subpath->nextSubpath = NULL;
    free(subpath);
    subpath = nextNode;
  }
}

#pragma mark - From CGPath

- (void)setWithCGPath:(CGPathRef)path {
  [self lot_enumeratePath:path elementsUsingBlock:^(const CGPathElement *element) {
    switch (element->type) {
      case kCGPathElementMoveToPoint: {
        CGPoint point = element ->points[0];
        [self RDLOT_moveToPoint:point];
        break;
      }
      case kCGPathElementAddLineToPoint: {
        CGPoint point = element ->points[0];
        [self RDLOT_addLineToPoint:point];
        break;
      }
      case kCGPathElementAddQuadCurveToPoint: {
        break;
      }
      case kCGPathElementAddCurveToPoint: {
        CGPoint point1 = element->points[0];
        CGPoint point2 = element->points[1];
        CGPoint point3 = element->points[2];
        [self RDLOT_addCurveToPoint:point3 controlPoint1:point1 controlPoint2:point2];
        break;
      }
      case kCGPathElementCloseSubpath: {
        [self RDLOT_closePath];
        break;
      }
    }
  }];
}

- (void)lot_enumeratePath:(CGPathRef)cgPath elementsUsingBlock:(RDLOTBezierPathEnumerationHandler)handler {
  void RDCGPathEnumerationCallback(void *info, const CGPathElement *element);
  CGPathApply(cgPath, (__bridge void * _Nullable)(handler), RDCGPathEnumerationCallback);
}

@end

void RDCGPathEnumerationCallback(void *info, const CGPathElement *element)
{
  RDLOTBezierPathEnumerationHandler handler = (__bridge  RDLOTBezierPathEnumerationHandler)(info);
  if (handler) {
    handler(element);
  }
}
