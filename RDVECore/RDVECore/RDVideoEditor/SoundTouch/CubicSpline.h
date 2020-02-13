#ifndef CCUBICSPLINE_H
#define CCUBICSPLINE_H
#include <vector>
using namespace std;


//三次样条
class CCubicSpline
{
public:
	CCubicSpline();
	~CCubicSpline();

	//点结构
	struct SPoint
	{
	public:
		float	x;
		float	y;
		float	m;
		bool	bSharp;		//尖锐的
		SPoint()
		{
			x	= 0.0;
			y	= 0.0;
			bSharp	= false;
			m	= 0.0;
		}
		SPoint( float dX, float dY, bool bIsSharp = false )
		{
			x	= dX;
			y	= dY;
			bSharp	= bIsSharp;
			m	= 0.0;
		}
	};
	int32_t		GetKeyPointCount() const { return m_poKeyPoints.size(); }
	SPoint	GetKeyPointInfo( int32_t iIndex ) const {	return m_poKeyPoints[iIndex]; }

	//插入点，如果设置了限制值范围，那么 dX 和 dY 的有效范围均为 0~1。
	//成功返回索引，失败返回-1。如果 dX 已经存在，则修改 y 值，并返回索引号。
	int32_t	InsertPoint( float dX, float dY );
	//设置点的状态，是平滑曲线还是尖锐的。
	bool SetPointSharp( int32_t iIndex, bool bIsSharp );
	bool SetPointPos( int32_t iIndex, float dX, float dY );
	//删除点
	bool RemovePoint( int32_t iIndex );
	//指定 x 轴上的坐标，取得曲线在 y 轴上的值。
	float GetCurveValue( float dX );

	void SetPoints( vector<SPoint>& sPoints );

	void SetEndpointProperty( bool bEndpointExtension, bool bLimitValueRange )
	{
		m_bEndpointExtension	= bEndpointExtension;
		m_bLimitValueRange		= bLimitValueRange;
	}
protected:
	bool			m_bEndpointExtension;	//端点延伸，true 表示端点向 y=0 延伸出曲线。
	bool			m_bLimitValueRange;		//把返回的值限制到 0~1 之间
	vector<SPoint>	m_poKeyPoints;
	//计算曲线的各项系数。
	void Coefficient();
};

#endif // CCUBICSPLINE_H