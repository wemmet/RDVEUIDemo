//
//  RDVector.c
//
//  Created by kesalin@gmail.com on 12-11-26.
//  Copyright (c) 2012. http://blog.csdn.net/kesalin/. All rights reserved.
//

#include "RDVector.h"
#include <math.h>
CGPoint calculateLinear(CGFloat t, CGPoint p1, CGPoint p2){
    CGFloat mt = 1 - t;
    CGFloat x = mt * p1.x + t * p2.x;
    CGFloat y = mt * p1.y + t * p2.y;
    return CGPointMake(x, y);
}

CGPoint calculateQuad(CGFloat t, CGPoint p1, CGPoint p2, CGPoint p3){
    CGFloat mt = 1 - t;
    CGFloat mt2 = mt*mt;
    CGFloat t2 = t*t;
    
    CGFloat a = mt2;
    CGFloat b = mt*t*2;
    CGFloat c = t2;
    
    CGFloat x = a*p1.x + b*p2.x + c*p3.x;
    CGFloat y = a*p1.y + b*p2.y + c*p3.y;
    return CGPointMake(x, y);
}

CGPoint calculateCube(CGFloat t, CGPoint p1, CGPoint p2, CGPoint p3, CGPoint p4){
    CGFloat mt = 1 - t;
    CGFloat mt2 = mt*mt;
    CGFloat t2 = t*t;
    
    CGFloat a = mt2*mt;
    CGFloat b = mt2*t*3;
    CGFloat c = mt*t2*3;
    CGFloat d = t*t2;
    
    CGFloat x = a*p1.x + b*p2.x + c*p3.x + d*p4.x;
    CGFloat y = a*p1.y + b*p2.y + c*p3.y + d*p4.y;
    return CGPointMake(x, y);
}

void RDVectorCopy(RDVec3 * out, const RDVec3 * in)
{
	out->x = in->x;
	out->y = in->y;
	out->z = in->z;
}

void RDVectorAdd(RDVec3 * out, const RDVec3 * a, const RDVec3 * b)
{
	out->x = a->x + b->x;
	out->y = a->y + b->y;
	out->z = a->z + b->z;
}

void RDVectorSubtract(RDVec3 * out, const RDVec3 * a, const RDVec3 * b)
{
	out->x = a->x - b->x;
	out->y = a->y - b->y;
	out->z = a->z - b->z;
}

void RDCrossProduct(RDVec3 * out, const RDVec3 * a, const RDVec3 * b)
{
	out->x = a->y * b->z - a->z * b->y;
	out->y = a->z * b->x - a->x * b->z;
	out->z = a->x * b->y - b->y * a->x;
}

float RDDotProduct(const RDVec3 * a, const RDVec3 * b)
{
	return (a->x * b->x + a->y * b->y + a->z * b->z);
}

void RDVectorLerp(RDVec3 * out, const RDVec3 * a, const RDVec3 * b, float t)
{
	out->x = (a->x * (1 - t) + b->x * t);
	out->y = (a->y * (1 - t) + b->y * t);
	out->z = (a->z * (1 - t) + b->z * t);
}

void RDVectorScale(RDVec3 * v, float scale)
{
	v->x *= scale;
	v->y *= scale;
	v->z *= scale;
}

void RDVectorInverse(RDVec3 * v)
{
	v->x = -v->x;
	v->y = -v->y;
	v->z = -v->z;
}

void RDVectorNormalize(RDVec3 * v)
{
	float length = RDVectorLength(v);
	if (length != 0)
	{
		length = 1.0 / length;
		v->x *= length;
		v->y *= length;
		v->z *= length;
	}
}

int RDVectorCompare(const RDVec3 * a, const RDVec3 * b)
{
	if (a == b)
		return 1;

	if (a->x != b->x || a->y != b->y || a->z != b->z)
		return 0;
	return 1;
}

float RDVectorLength(const RDVec3 * in)
{
	return (float)sqrt(in->x * in->x + in->y * in->y + in->z * in->z);
}

float RDVectorLengthSquared(const RDVec3 * in)
{
	return (in->x * in->x + in->y * in->y + in->z * in->z);
}

float RDVectorDistance(const RDVec3 * a, const RDVec3 * b)
{
	RDVec3 v;
	RDVectorSubtract(&v, a, b);
	return RDVectorLength(&v);
}

float RDVectorDistanceSquared(const RDVec3 * a, const RDVec3 * b)
{
	RDVec3 v;
	RDVectorSubtract(&v, a, b);
	return (v.x * v.x + v.y * v.y + v.z * v.z);
}
