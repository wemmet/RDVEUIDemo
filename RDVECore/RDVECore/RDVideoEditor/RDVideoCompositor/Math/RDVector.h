//
//  RDVector.h
//
//

#ifndef __RD_VECTOR_H__
#define __RD_VECTOR_H__
#include <CoreGraphics/CGGeometry.h>
typedef struct
{
	float x;
	float y;
	float z;
} RDVec3;

typedef struct
{
	float x;
	float y;
	float z;
	float w;
} RDVec4;

typedef struct
{
	float r;
	float g;
	float b;
	float a;
} RDColor;

typedef unsigned char byte;

#ifdef __cplusplus
extern "C" {
#endif
    CGPoint calculateCube(CGFloat t, CGPoint p1, CGPoint p2, CGPoint p3, CGPoint p4);
    CGPoint calculateQuad(CGFloat t, CGPoint p1, CGPoint p2, CGPoint p3);
    CGPoint calculateLinear(CGFloat t, CGPoint p1, CGPoint p2);
void RDVectorCopy(RDVec3 * out, const RDVec3 * in);
void RDVectorAdd(RDVec3 * out, const RDVec3 * a, const RDVec3 * b);
void RDVectorSubtract(RDVec3 * out, const RDVec3 * a, const RDVec3 * b);
void RDVectorLerp(RDVec3 * out, const RDVec3 * a, const RDVec3 * b, float t);
void RDCrossProduct(RDVec3 * out, const RDVec3 * a, const RDVec3 * b);
float RDDotProduct(const RDVec3 * a, const RDVec3 * b);

float RDVectorLengthSquared(const RDVec3 * in);
float RDVectorDistanceSquared(const RDVec3 * a, const RDVec3 * b);

void RDVectorScale(RDVec3 * v, float scale);
void RDVectorNormalize(RDVec3 * v);
void RDVectorInverse(RDVec3 * v);

int RDVectorCompare(const RDVec3 * a, const RDVec3 * b);
float RDVectorLength(const RDVec3 * in);
float RDVectorDistance(const RDVec3 * a, const RDVec3 * b);

#ifdef __cplusplus
}
#endif

#endif	//__RD_VECTOR_H__
