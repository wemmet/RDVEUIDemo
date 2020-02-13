
#import "RDLOTPlatformCompat.h"

#import <CoreGraphics/CoreGraphics.h>

//
// Core Graphics Geometry Additions
//

extern const CGSize RDCGSizeMax;

CGRect RDLOT_RectIntegral(CGRect rect);

// Centering

// Returns a rectangle of the given size, centered at a point
CGRect RDLOT_RectCenteredAtPoint(CGPoint center, CGSize size, BOOL integral);

// Returns the center point of a CGRect
CGPoint RDLOT_RectGetCenterPoint(CGRect rect);

// Insetting

// Inset the rectangle on a single edge
CGRect RDLOT_RectInsetLeft(CGRect rect, CGFloat inset);
CGRect RDLOT_RectInsetRight(CGRect rect, CGFloat inset);
CGRect RDLOT_RectInsetTop(CGRect rect, CGFloat inset);
CGRect RDLOT_RectInsetBottom(CGRect rect, CGFloat inset);

// Inset the rectangle on two edges
CGRect RDLOT_RectInsetHorizontal(CGRect rect, CGFloat leftInset, CGFloat rightInset);
CGRect RDLOT_RectInsetVertical(CGRect rect, CGFloat topInset, CGFloat bottomInset);

// Inset the rectangle on all edges
CGRect RDLOT_RectInsetAll(CGRect rect, CGFloat leftInset, CGFloat rightInset, CGFloat topInset, CGFloat bottomInset);

// Framing

// Returns a rectangle of size framed in the center of the given rectangle
CGRect RDLOT_RectFramedCenteredInRect(CGRect rect, CGSize size, BOOL integral);

// Returns a rectangle of size framed in the given rectangle and inset
CGRect RDLOT_RectFramedLeftInRect(CGRect rect, CGSize size, CGFloat inset, BOOL integral);
CGRect RDLOT_RectFramedRightInRect(CGRect rect, CGSize size, CGFloat inset, BOOL integral);
CGRect RDLOT_RectFramedTopInRect(CGRect rect, CGSize size, CGFloat inset, BOOL integral);
CGRect RDLOT_RectFramedBottomInRect(CGRect rect, CGSize size, CGFloat inset, BOOL integral);

CGRect RDLOT_RectFramedTopLeftInRect(CGRect rect, CGSize size, CGFloat insetWidth, CGFloat insetHeight, BOOL integral);
CGRect RDLOT_RectFramedTopRightInRect(CGRect rect, CGSize size, CGFloat insetWidth, CGFloat insetHeight, BOOL integral);
CGRect RDLOT_RectFramedBottomLeftInRect(CGRect rect, CGSize size, CGFloat insetWidth, CGFloat insetHeight, BOOL integral);
CGRect RDLOT_RectFramedBottomRightInRect(CGRect rect, CGSize size, CGFloat insetWidth, CGFloat insetHeight, BOOL integral);

// Divides a rect into sections and returns the section at specified index

CGRect RDLOT_RectDividedSection(CGRect rect, NSInteger sections, NSInteger index, CGRectEdge fromEdge);

// Returns a rectangle of size attached to the given rectangle
CGRect RDLOT_RectAttachedLeftToRect(CGRect rect, CGSize size, CGFloat margin, BOOL integral);
CGRect RDLOT_RectAttachedRightToRect(CGRect rect, CGSize size, CGFloat margin, BOOL integral);
CGRect RDLOT_RectAttachedTopToRect(CGRect rect, CGSize size, CGFloat margin, BOOL integral);
CGRect RDLOT_RectAttachedBottomToRect(CGRect rect, CGSize size, CGFloat margin, BOOL integral);

CGRect RDLOT_RectAttachedBottomLeftToRect(CGRect rect, CGSize size, CGFloat marginWidth, CGFloat marginHeight, BOOL integral);
CGRect RDLOT_RectAttachedBottomRightToRect(CGRect rect, CGSize size, CGFloat marginWidth, CGFloat marginHeight, BOOL integral);
CGRect RDLOT_RectAttachedTopRightToRect(CGRect rect, CGSize size, CGFloat marginWidth, CGFloat marginHeight, BOOL integral);
CGRect RDLOT_RectAttachedTopLeftToRect(CGRect rect, CGSize size, CGFloat marginWidth, CGFloat marginHeight, BOOL integral);

BOOL RDLOT_CGPointIsZero(CGPoint point);

// Combining
// Adds all values of the 2nd rect to the first rect
CGRect RDLOT_RectAddRect(CGRect rect, CGRect other);
CGRect RDLOT_RectAddPoint(CGRect rect, CGPoint point);
CGRect RDLOT_RectAddSize(CGRect rect, CGSize size);
CGRect RDLOT_RectBounded(CGRect rect);

CGPoint RDLOT_PointAddedToPoint(CGPoint point1, CGPoint point2);

CGRect RDLOT_RectSetHeight(CGRect rect, CGFloat height);

CGFloat RDLOT_PointDistanceFromPoint(CGPoint point1, CGPoint point2);
CGFloat RDLOT_DegreesToRadians(CGFloat degrees);

CGFloat RDLOT_RemapValue(CGFloat value, CGFloat low1, CGFloat high1, CGFloat low2, CGFloat high2 );
CGPoint RDLOT_PointByLerpingPoints(CGPoint point1, CGPoint point2, CGFloat value);

CGPoint RDLOT_PointInLine(CGPoint A, CGPoint B, CGFloat T);
CGPoint RDLOT_PointInCubicCurve(CGPoint start, CGPoint cp1, CGPoint cp2, CGPoint end, CGFloat T);

CGFloat RDLOT_CubicBezeirInterpolate(CGPoint P0, CGPoint P1, CGPoint P2, CGPoint P3, CGFloat x);
CGFloat RDLOT_SolveCubic(CGFloat a, CGFloat b, CGFloat c, CGFloat d);
CGFloat RDLOT_SolveQuadratic(CGFloat a, CGFloat b, CGFloat c);
CGFloat RDLOT_Squared(CGFloat f);
CGFloat RDLOT_Cubed(CGFloat f);
CGFloat RDLOT_CubicRoot(CGFloat f);

CGFloat RDLOT_CubicLength(CGPoint fromPoint, CGPoint toPoint, CGPoint controlPoint1, CGPoint controlPoint2);
CGFloat RDLOT_CubicLengthWithPrecision(CGPoint fromPoint, CGPoint toPoint, CGPoint controlPoint1, CGPoint controlPoint2, CGFloat iterations);
