
#import "CGGeometry+RDLOTAdditions.h"

const CGSize RDCGSizeMax = {CGFLOAT_MAX, CGFLOAT_MAX};
//
// Core Graphics Geometry Additions
//

// CGRectIntegral returns a rectangle with the smallest integer values for its origin and size that contains the source rectangle.
// For a rect with .origin={5, 5.5}, .size=(10, 10), it will return .origin={5,5}, .size={10, 11};
// RDLOT_RectIntegral will return {5,5}, {10, 10}.
CGRect RDLOT_RectIntegral(CGRect rect) {
  rect.origin = CGPointMake(rintf(rect.origin.x), rintf(rect.origin.y));
  rect.size = CGSizeMake(ceilf(rect.size.width), ceil(rect.size.height));
  return rect;
}

//
// Centering

// Returns a rectangle of the given size, centered at a point

CGRect RDLOT_RectCenteredAtPoint(CGPoint center, CGSize size, BOOL integral) {
  CGRect result;
  result.origin.x = center.x - 0.5f * size.width;
  result.origin.y = center.y - 0.5f * size.height;
  result.size = size;
  
  if (integral) { result = RDLOT_RectIntegral(result); }
  return result;
}

// Returns the center point of a CGRect
CGPoint RDLOT_RectGetCenterPoint(CGRect rect) {
	return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

//
// Insetting

// Inset the rectangle on a single edge

CGRect RDLOT_RectInsetLeft(CGRect rect, CGFloat inset) {
  rect.origin.x += inset;
  rect.size.width -= inset;
  return rect;
}

CGRect RDLOT_RectInsetRight(CGRect rect, CGFloat inset) {
  rect.size.width -= inset;
  return rect;
}

CGRect RDLOT_RectInsetTop(CGRect rect, CGFloat inset) {
  rect.origin.y += inset;
  rect.size.height -= inset;
  return rect;
}

CGRect RDLOT_RectInsetBottom(CGRect rect, CGFloat inset) {
  rect.size.height -= inset;
  return rect;
}

// Inset the rectangle on two edges

CGRect RDLOT_RectInsetHorizontal(CGRect rect, CGFloat leftInset, CGFloat rightInset) {
  rect.origin.x += leftInset;
  rect.size.width -= (leftInset + rightInset);
  return rect;
}

CGRect RDLOT_RectInsetVertical(CGRect rect, CGFloat topInset, CGFloat bottomInset) {
  rect.origin.y += topInset;
  rect.size.height -= (topInset + bottomInset);
  return rect;
}

// Inset the rectangle on all edges

CGRect RDLOT_RectInsetAll(CGRect rect, CGFloat leftInset, CGFloat rightInset, CGFloat topInset, CGFloat bottomInset) {
  rect.origin.x += leftInset;
  rect.origin.y += topInset;
  rect.size.width -= (leftInset + rightInset);
  rect.size.height -= (topInset + bottomInset);
  return rect;
}

//
// Framing

// Returns a rectangle of size framed in the center of the given rectangle

CGRect RDLOT_RectFramedCenteredInRect(CGRect rect, CGSize size, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + rintf(0.5f * (rect.size.width - size.width));
  result.origin.y = rect.origin.y + rintf(0.5f * (rect.size.height - size.height));
  result.size = size;
  
  if (integral) { result = RDLOT_RectIntegral(result); }
  return result;
}

// Returns a rectangle of size framed in the given rectangle and inset

CGRect RDLOT_RectFramedLeftInRect(CGRect rect, CGSize size, CGFloat inset, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + inset;
  result.origin.y = rect.origin.y + rintf(0.5f * (rect.size.height - size.height));
  result.size = size;
  
  if (integral) { result = RDLOT_RectIntegral(result); }
  return result;
}

CGRect RDLOT_RectFramedRightInRect(CGRect rect, CGSize size, CGFloat inset, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + rect.size.width - size.width - inset;
  result.origin.y = rect.origin.y + rintf(0.5f * (rect.size.height - size.height));
  result.size = size;
  
  if (integral) { result = RDLOT_RectIntegral(result); }
  return result;
}

CGRect RDLOT_RectFramedTopInRect(CGRect rect, CGSize size, CGFloat inset, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + rintf(0.5f * (rect.size.width - size.width));
  result.origin.y = rect.origin.y + inset;
  result.size = size;
  
  if (integral) { result = RDLOT_RectIntegral(result); }
  return result;
}

CGRect RDLOT_RectFramedBottomInRect(CGRect rect, CGSize size, CGFloat inset, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + rintf(0.5f * (rect.size.width - size.width));
  result.origin.y = rect.origin.y + rect.size.height - size.height - inset;
  result.size = size;
  
  if (integral) { result = RDLOT_RectIntegral(result); }
  return result;
}

CGRect RDLOT_RectFramedTopLeftInRect(CGRect rect, CGSize size, CGFloat insetWidth, CGFloat insetHeight, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + insetWidth;
  result.origin.y = rect.origin.y + insetHeight;
  result.size = size;
  
  if (integral) { result = RDLOT_RectIntegral(result); }
  return result;
}

CGRect RDLOT_RectFramedTopRightInRect(CGRect rect, CGSize size, CGFloat insetWidth, CGFloat insetHeight, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + rect.size.width - size.width - insetWidth;
  result.origin.y = rect.origin.y + insetHeight;
  result.size = size;
  
  if (integral) { result = RDLOT_RectIntegral(result); }
  return result;
}

CGRect RDLOT_RectFramedBottomLeftInRect(CGRect rect, CGSize size, CGFloat insetWidth, CGFloat insetHeight, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + insetWidth;
  result.origin.y = rect.origin.y + rect.size.height - size.height - insetHeight;
  result.size = size;
  
  if (integral) { result = RDLOT_RectIntegral(result); }
  return result;
}

CGRect RDLOT_RectFramedBottomRightInRect(CGRect rect, CGSize size, CGFloat insetWidth, CGFloat insetHeight, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + rect.size.width - size.width - insetWidth;
  result.origin.y = rect.origin.y + rect.size.height - size.height - insetHeight;
  result.size = size;
  
  if (integral) { result = RDLOT_RectIntegral(result); }
  return result;
}

// Returns a rectangle of size attached to the given rectangle

CGRect RDLOT_RectAttachedLeftToRect(CGRect rect, CGSize size, CGFloat margin, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x - size.width - margin;
  result.origin.y = rect.origin.y + rintf(0.5f * (rect.size.height - size.height));
  result.size = size;
  
  if (integral) { result = RDLOT_RectIntegral(result); }
  return result;
}

CGRect RDLOT_RectAttachedRightToRect(CGRect rect, CGSize size, CGFloat margin, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + rect.size.width + margin;
  result.origin.y = rect.origin.y + rintf(0.5f * (rect.size.height - size.height));
  result.size = size;
  
  if (integral) { result = RDLOT_RectIntegral(result); }
  return result;
}

CGRect RDLOT_RectAttachedTopToRect(CGRect rect, CGSize size, CGFloat margin, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + rintf(0.5f * (rect.size.width - size.width));
  result.origin.y = rect.origin.y - size.height - margin;
  result.size = size;
  
  if (integral) { result = RDLOT_RectIntegral(result); }
  return result;
}

CGRect RDLOT_RectAttachedTopLeftToRect(CGRect rect, CGSize size, CGFloat marginWidth, CGFloat marginHeight, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + marginWidth;
  result.origin.y = rect.origin.y - size.height - marginHeight;
  result.size = size;
  
  if (integral) { result = RDLOT_RectIntegral(result); }
  return result;
}

CGRect RDLOT_RectAttachedTopRightToRect(CGRect rect, CGSize size, CGFloat marginWidth, CGFloat marginHeight, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + rect.size.width - size.width - marginWidth;
  result.origin.y = rect.origin.y - rect.size.height - marginHeight;
  result.size = size;

  if (integral) { result = RDLOT_RectIntegral(result); }
  return result;
}

CGRect RDLOT_RectAttachedBottomToRect(CGRect rect, CGSize size, CGFloat margin, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + rintf(0.5f * (rect.size.width - size.width));
  result.origin.y = rect.origin.y + rect.size.height + margin;
  result.size = size;
  
  if (integral) { result = RDLOT_RectIntegral(result); }
  return result;
}

CGRect RDLOT_RectAttachedBottomLeftToRect(CGRect rect, CGSize size, CGFloat marginWidth, CGFloat marginHeight, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + marginWidth;
  result.origin.y = rect.origin.y + rect.size.height + marginHeight;
  result.size = size;
  
  if (integral) { result = RDLOT_RectIntegral(result); }
  return result;
}

CGRect RDLOT_RectAttachedBottomRightToRect(CGRect rect, CGSize size, CGFloat marginWidth, CGFloat marginHeight, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + rect.size.width - size.width - marginWidth;
  result.origin.y = rect.origin.y + rect.size.height + marginHeight;
  result.size = size;
  
  if (integral) { result = RDLOT_RectIntegral(result); }
  return result;
}

// Divides a rect into sections and returns the section at specified index

CGRect RDLOT_RectDividedSection(CGRect rect, NSInteger sections, NSInteger index, CGRectEdge fromEdge) {
  if (sections == 0) {
    return CGRectZero;
  }
  CGRect r = rect;
  if (fromEdge == CGRectMaxXEdge || fromEdge == CGRectMinXEdge) {
    r.size.width = rect.size.width / sections;
    r.origin.x += r.size.width * index;
  } else {
    r.size.height = rect.size.height / sections;
    r.origin.y += r.size.height * index;
  }
  return r;
}


CGRect RDLOT_RectAddRect(CGRect rect, CGRect other) {
  return CGRectMake(rect.origin.x + other.origin.x, rect.origin.y + other.origin.y,
                    rect.size.width + other.size.width, rect.size.height + other.size.height);
}

CGRect RDLOT_RectAddPoint(CGRect rect, CGPoint point) {
  return CGRectMake(rect.origin.x + point.x, rect.origin.y + point.y,
                    rect.size.width, rect.size.height);
}

CGRect RDLOT_RectAddSize(CGRect rect, CGSize size) {
  return CGRectMake(rect.origin.x, rect.origin.y,
                    rect.size.width + size.width, rect.size.height + size.height);
}

CGRect RDLOT_RectBounded(CGRect rect) {
  CGRect returnRect = rect;
  returnRect.origin = CGPointZero;
  return returnRect;
}

CGPoint RDLOT_PointAddedToPoint(CGPoint point1, CGPoint point2) {
  CGPoint returnPoint = point1;
  returnPoint.x += point2.x;
  returnPoint.y += point2.y;
  return returnPoint;
}

CGRect RDLOT_RectSetHeight(CGRect rect, CGFloat height) {
  return CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, height);
}

CGFloat RDLOT_DegreesToRadians(CGFloat degrees) {
  return degrees * M_PI / 180;
}

CGFloat RDLOT_PointDistanceFromPoint(CGPoint point1, CGPoint point2) {
  CGFloat xDist = (point2.x - point1.x);
  CGFloat yDist = (point2.y - point1.y);
  CGFloat distance = sqrt((xDist * xDist) + (yDist * yDist));
  return distance;
}

CGFloat RDLOT_RemapValue(CGFloat value, CGFloat low1, CGFloat high1, CGFloat low2, CGFloat high2 ) {
  return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
}

CGPoint RDLOT_PointByLerpingPoints(CGPoint point1, CGPoint point2, CGFloat value) {
  CGFloat xDiff = point2.x - point1.x;
  CGFloat yDiff = point2.y - point1.y;
  CGPoint transposed = CGPointMake(fabs(xDiff), fabs(yDiff));
  CGPoint returnPoint;
  if (xDiff == 0 || yDiff == 0) {
    returnPoint.x = xDiff == 0 ? point1.x : RDLOT_RemapValue(value, 0, 1, point1.x, point2.x);
    returnPoint.y = yDiff == 0 ? point1.y : RDLOT_RemapValue(value, 0, 1, point1.y, point2.y);
  } else {
    CGFloat rx = transposed.x / transposed.y;
    CGFloat yLerp = RDLOT_RemapValue(value, 0, 1, 0, transposed.y);
    CGFloat xLerp = yLerp * rx;
    CGPoint interpolatedPoint = CGPointMake(point2.x < point1.x ? xLerp * -1 : xLerp,
                                            point2.y < point1.y ? yLerp * -1 : yLerp);
    returnPoint = RDLOT_PointAddedToPoint(point1, interpolatedPoint);
  }
  return returnPoint;
}

CGPoint RDLOT_PointInLine(CGPoint A, CGPoint B, CGFloat T) {
  CGPoint C;
  C.x = A.x - ((A.x - B.x) * T);
  C.y = A.y - ((A.y - B.y) * T);
  return C;
}

CGFloat RDLOT_CubicBezierGetY(CGPoint cp1, CGPoint cp2, CGFloat T) {
//       (1-x)^3 * y0 + 3*(1-x)^2 * x * y1 + 3*(1-x) * x^2 * y2 + x^3 * y3
  return 3 * powf(1.f - T, 2.f) * T * cp1.y + 3.f * (1.f - T) * powf(T, 2.f) * cp2.y + powf(T, 3.f);
}

CGPoint RDLOT_PointInCubicCurve(CGPoint start, CGPoint cp1, CGPoint cp2, CGPoint end, CGFloat T) {
  CGPoint A = RDLOT_PointInLine(start, cp1, T);
  CGPoint B = RDLOT_PointInLine(cp1, cp2, T);
  CGPoint C = RDLOT_PointInLine(cp2, end, T);
  CGPoint D = RDLOT_PointInLine(A, B, T);
  CGPoint E = RDLOT_PointInLine(B, C, T);
  CGPoint F = RDLOT_PointInLine(D, E, T);
  return F;
}

CGFloat RDLOT_SolveCubic(CGFloat a, CGFloat b, CGFloat c, CGFloat d) {
  if (a == 0) return RDLOT_SolveQuadratic(b, c, d);
  if (d == 0) return 0;
  
  b /= a;
  c /= a;
  d /= a;
  CGFloat q = (3.0 * c - RDLOT_Squared(b)) / 9.0;
  CGFloat r = (-27.0 * d + b * (9.0 * c - 2.0 * RDLOT_Squared(b))) / 54.0;
  CGFloat disc = RDLOT_Cubed(q) + RDLOT_Squared(r);
  CGFloat term1 = b / 3.0;
  
  if (disc > 0) {
    double s = r + sqrtf(disc);
    s = (s < 0) ? - RDLOT_CubicRoot(-s) : RDLOT_CubicRoot(s);
    double t = r - sqrtf(disc);
    t = (t < 0) ? - RDLOT_CubicRoot(-t) : RDLOT_CubicRoot(t);
    
    double result = -term1 + s + t;
    if (result >= 0 && result <= 1) return result;
  } else if (disc == 0) {
    double r13 = (r < 0) ? - RDLOT_CubicRoot(-r) : RDLOT_CubicRoot(r);
    
    double result = -term1 + 2.0 * r13;
    if (result >= 0 && result <= 1) return result;
    
    result = -(r13 + term1);
    if (result >= 0 && result <= 1) return result;
  } else {
    q = -q;
    double dum1 = q * q * q;
    dum1 = acosf(r / sqrtf(dum1));
    double r13 = 2.0 * sqrtf(q);
    
    double result = -term1 + r13 * cos(dum1 / 3.0);
    if (result >= 0 && result <= 1) return result;
    
    result = -term1 + r13 * cos((dum1 + 2.0 * M_PI) / 3.0);
    if (result >= 0 && result <= 1) return result;
    
    result = -term1 + r13 * cos((dum1 + 4.0 * M_PI) / 3.0);
    if (result >= 0 && result <= 1) return result;
  }
  
  return -1;
}

CGFloat RDLOT_SolveQuadratic(CGFloat a, CGFloat b, CGFloat c) {
  CGFloat result = (-b + sqrtf(RDLOT_Squared(b) - 4 * a * c)) / (2 * a);
  if (result >= 0 && result <= 1) return result;
  
  result = (-b - sqrtf(RDLOT_Squared(b) - 4 * a * c)) / (2 * a);
  if (result >= 0 && result <= 1) return result;
  
  return -1;
}

CGFloat RDLOT_Squared(CGFloat f) { return f * f; }

CGFloat RDLOT_Cubed(CGFloat f) { return f * f * f; }

CGFloat RDLOT_CubicRoot(CGFloat f) { return powf(f, 1.0 / 3.0); }

CGFloat RDLOT_CubicBezeirInterpolate(CGPoint P0, CGPoint P1, CGPoint P2, CGPoint P3, CGFloat x) {
  CGFloat t;
  if (x == P0.x) {
    // Handle corner cases explicitly to prevent rounding errors
    t = 0;
  } else if (x == P3.x) {
    t = 1;
  } else {
    // Calculate t
    CGFloat a = -P0.x + 3 * P1.x - 3 * P2.x + P3.x;
    CGFloat b = 3 * P0.x - 6 * P1.x + 3 * P2.x;
    CGFloat c = -3 * P0.x + 3 * P1.x;
    CGFloat d = P0.x - x;
    CGFloat tTemp = RDLOT_SolveCubic(a, b, c, d);
    if (tTemp == -1) return -1;
    t = tTemp;
  }
  
  // Calculate y from t
  return RDLOT_Cubed(1 - t) * P0.y + 3 * t * RDLOT_Squared(1 - t) * P1.y + 3 * RDLOT_Squared(t) * (1 - t) * P2.y + RDLOT_Cubed(t) * P3.y;
}

CGFloat RDLOT_CubicLengthWithPrecision(CGPoint fromPoint, CGPoint toPoint, CGPoint controlPoint1, CGPoint controlPoint2, CGFloat iterations) {
  CGFloat length = 0;
  CGPoint previousPoint = fromPoint;
  iterations = ceilf(iterations);
  for (int i = 1; i <= iterations; ++i) {
    float s = (float)i  / iterations;
    
    CGPoint p = RDLOT_PointInCubicCurve(fromPoint, controlPoint1, controlPoint2, toPoint, s);
    
    length += RDLOT_PointDistanceFromPoint(previousPoint, p);
    previousPoint = p;
  }
  return length;
}

CGFloat RDLOT_CubicLength(CGPoint fromPoint, CGPoint toPoint, CGPoint controlPoint1, CGPoint controlPoint2) {
  return RDLOT_CubicLengthWithPrecision(fromPoint, toPoint, controlPoint1, controlPoint2, 20);
}

BOOL RDLOT_CGPointIsZero(CGPoint point) {
  return CGPointEqualToPoint(point, CGPointZero);
}
