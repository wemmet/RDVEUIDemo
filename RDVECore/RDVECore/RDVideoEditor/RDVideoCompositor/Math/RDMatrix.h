//
//  RDMatrix.h
//
//

#ifndef __RD_MATRIX_H__
#define __RD_MATRIX_H__

#include <math.h>
#include "RDVector.h"

#ifndef M_PI
#define M_PI 3.1415926535897932384626433832795f
#endif

#define DEG2RAD( a ) (((a) * M_PI) / 180.0f)
#define RAD2DEG( a ) (((a) * 180.f) / M_PI)

// angle indexes
#define	PITCH				0		// up / down
#define	YAW					1		// left / right
#define	ROLL				2		// fall over

typedef struct RDMatrix3
{
	float   m[3][3];
} RDMatrix3;

typedef struct RDMatrix4
{
	float   m[4][4];
} RDMatrix4;

#ifdef __cplusplus
extern "C" {
#endif

	unsigned int RDNextPot(unsigned int n);

	void RDMatrixCopy(RDMatrix4 * target, const RDMatrix4 * src);

	int RDMatrixInvert(RDMatrix4 * out, const RDMatrix4 * in);

    void RDMatrixTranspose(RDMatrix4 * result, const RDMatrix4 * src);
    
	void RDMatrix4ToMatrix3(RDMatrix3 * target, const RDMatrix4 * src);
    
    void RDMatrixDotVector(RDVec4 * out, const RDMatrix4 * m, const RDVec4 * v);
    void RDMatrixInitFromArray(RDMatrix4* target, const float* array);
	//
	/// multiply matrix specified by result with a scaling matrix and return new matrix in result
	/// result Specifies the input matrix.  Scaled matrix is returned in result.
	/// sx, sy, sz Scale factors along the x, y and z axes respectively
	//
	void RDMatrixScale(RDMatrix4 * result, float sx, float sy, float sz);

	//
	/// multiply matrix specified by result with a translation matrix and return new matrix in result
	/// result Specifies the input matrix.  Translated matrix is returned in result.
	/// tx, ty, tz Scale factors along the x, y and z axes respectively
	//
	void RDMatrixTranslate(RDMatrix4 * result, float tx, float ty, float tz);

	//
	/// multiply matrix specified by result with a rotation matrix and return new matrix in result
	/// result Specifies the input matrix.  Rotated matrix is returned in result.
	/// angle Specifies the angle of rotation, in degrees.
	/// x, y, z Specify the x, y and z coordinates of a vector, respectively
	//
	void RDMatrixRotate(RDMatrix4 * result, float angle, float x, float y, float z);

	//
	/// perform the following operation - result matrix = srcA matrix * srcB matrix
	/// result Returns multiplied matrix
	/// srcA, srcB Input matrices to be multiplied
	//
	void RDMatrixMultiply(RDMatrix4 * result, const RDMatrix4 *srcA, const RDMatrix4 *srcB);

	//
	//// return an identity matrix 
	//// result returns identity matrix
	//
	void RDMatrixLoadIdentity(RDMatrix4 * result);

	//
	/// multiply matrix specified by result with a perspective matrix and return new matrix in result
	/// result Specifies the input matrix.  new matrix is returned in result.
	/// fovy Field of view y angle in degrees
	/// aspect Aspect ratio of screen
	/// nearZ Near plane distance
	/// farZ Far plane distance
	//
	void RDPerspective(RDMatrix4 * result, float fovy, float aspect, float nearZ, float farZ);

	//
	/// multiply matrix specified by result with a perspective matrix and return new matrix in result
	/// result Specifies the input matrix.  new matrix is returned in result.
	/// left, right Coordinates for the left and right vertical clipping planes
	/// bottom, top Coordinates for the bottom and top horizontal clipping planes
	/// nearZ, farZ Distances to the near and far depth clipping planes.  These values are negative if plane is behind the viewer
	//
	void RDOrtho(RDMatrix4 * result, float left, float right, float bottom, float top, float nearZ, float farZ);

	//
	// multiply matrix specified by result with a perspective matrix and return new matrix in result
	/// result Specifies the input matrix.  new matrix is returned in result.
	/// left, right Coordinates for the left and right vertical clipping planes
	/// bottom, top Coordinates for the bottom and top horizontal clipping planes
	/// nearZ, farZ Distances to the near and far depth clipping planes.  Both distances must be positive.
	//
	void RDFrustum(RDMatrix4 * result, float left, float right, float bottom, float top, float nearZ, float farZ);

	void RDLookAt(RDMatrix4 * result, const RDVec3 * eye, const RDVec3 * target, const RDVec3 * up);

#ifdef __cplusplus
}
#endif

#endif // __RD_MATRIX_H__
