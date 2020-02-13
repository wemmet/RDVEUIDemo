
#include "CubicSpline.h"


CCubicSpline::CCubicSpline()
{
	m_bEndpointExtension	= true;
	m_bLimitValueRange		= false;
}

CCubicSpline::~CCubicSpline()
{
}

int32_t CCubicSpline::InsertPoint( float dX, float dY )
{
	if ( m_bLimitValueRange && ( dX < 0.0 || dX > 1.0 || dY < 0.0 || dY > 1.0 ) ) return -1;
	vector<SPoint>::iterator	iter	= m_poKeyPoints.begin();
	while ( iter < m_poKeyPoints.end() && dX > iter->x ) ++iter;
	if ( iter == m_poKeyPoints.end() )
	{
		iter	= m_poKeyPoints.insert( iter, SPoint( dX, dY ) );
	}
	else
	{
		if ( iter->x == dX )
		{
			iter->y	= dY;
		}
		else
		{
			iter	= m_poKeyPoints.insert( iter, SPoint( dX, dY ) );
		}
	}
	Coefficient();
	return iter - m_poKeyPoints.begin();
}

bool CCubicSpline::SetPointSharp( int32_t iIndex, bool bIsSharp )
{
	if ( iIndex < 0 || iIndex >= (int32_t)m_poKeyPoints.size() )
		return false;
	m_poKeyPoints.at( iIndex ).bSharp	= bIsSharp;
	Coefficient();
	return true;
}

bool CCubicSpline::SetPointPos( int32_t iIndex, float dX, float dY )
{
	if ( iIndex < 0 || iIndex >= (int32_t)m_poKeyPoints.size() )
		return false;
	m_poKeyPoints.at( iIndex ).x	= dX;
	m_poKeyPoints.at( iIndex ).y	= dY;
	Coefficient();
	return true;
}

bool CCubicSpline::RemovePoint( int32_t iIndex )
{
	if ( iIndex < 0 || iIndex >= (int32_t)m_poKeyPoints.size() )
		return false;
	m_poKeyPoints.erase( m_poKeyPoints.begin() + iIndex );
	Coefficient();
	return true;
}

float CCubicSpline::GetCurveValue( float dX )
{
	int32_t		n	= m_poKeyPoints.size();
	float h, d0, d1, y;
	if ( n < 2 ) return 0.0;
	if ( !m_bEndpointExtension )
	{
		if ( dX <= m_poKeyPoints.front().x )
			return m_poKeyPoints.front().y;
		else if ( dX >= m_poKeyPoints.back().x )
			return m_poKeyPoints.back().y;
	}
	vector<SPoint>::iterator	iterPre	= m_poKeyPoints.begin();
	vector<SPoint>::iterator	iterCur	= iterPre + 1;
	while ( dX > iterCur->x && iterCur + 1 != m_poKeyPoints.end() ) ++iterCur;
	iterPre	= iterCur - 1;

	h	= iterCur->x - iterPre->x;
	d0	= dX - iterPre->x;
	d1	= iterCur->x - dX;
	y	= iterPre->m * d1 * d1 * d1 / ( 6 * h )
		+ iterCur->m * d0 * d0 * d0 / ( 6 * h )
		+ ( iterPre->y - iterPre->m * h * h / 6 ) * d1 / h
		+ ( iterCur->y - iterCur->m * h * h / 6 ) * d0 / h;
	if ( m_bLimitValueRange )
	{
		if ( y < 0.0 )
			y	= 0.0;
		if ( y > 1.0 )
			y	= 1.0;
	}
	return y;
}

void CCubicSpline::SetPoints( vector<SPoint>& sPoints )
{
	m_poKeyPoints	= sPoints;
	Coefficient();
}

void CCubicSpline::Coefficient()
{

	int32_t		i	= 0;
	int32_t		n	= m_poKeyPoints.size();
	if ( n < 2 ) return;
	float*	a	= new float[n];
	float*	b	= new float[n];
	float*	c	= new float[n];
	float*	g	= new float[n];

	float	ma	= 0.0;
	float	mb	= 0.0;

	float h0, h1, f0, f1;

	b[0]	= b[n - 1] = 2;
	a[n - 1]	= c[0] = 0;

	for ( i = 1; i < n - 1; ++i )
	{
		b[i]	= 2;
		SPoint&	poCur	= m_poKeyPoints[i];
		SPoint&	poPre	= m_poKeyPoints[i-1];
		SPoint&	poNex	= m_poKeyPoints[i+1];
		if (poCur.bSharp )
		{
			g[i]	= 0;
			a[i]	= 0;
			c[i]	= 0;
		}
		else
		{
			h0	= poCur.x - poPre.x;
			h1	= poNex.x - poCur.x;
			f0	= ( poCur.y - poPre.y ) / h0;
			f1	= ( poNex.y - poCur.y ) / h1;

			a[i]	= h0 / ( h0 + h1 );
			c[i]	= h1 / ( h0 + h1 );
			g[i]	= 6.0f * ( f1 - f0 ) / ( h0 + h1 );
		}
	}
	if ( m_poKeyPoints.front().bSharp )
	{
		g[0]	= 0;
	}
	else
	{
		h0		= m_poKeyPoints[1].x -  m_poKeyPoints[0].x;
		g[0]	= 6.0f * ( ( m_poKeyPoints[1].y - m_poKeyPoints[0].y ) / h0 - ma ) / h0;
	}
	if ( m_poKeyPoints.back().bSharp )
	{
		g[i]	= 0;
	}
	else
	{
		h1		= m_poKeyPoints[i].x - m_poKeyPoints[i-1].x;
		g[i]	= 6.0f * ( mb - ( m_poKeyPoints[i].y - m_poKeyPoints[i-1].y ) / h1 ) / h1;
	}


	//追赶法求线性方程组
	float	*pB, *pD;
	pB		= new float[n];
	pD		= new float[n];
	pB[0]	= c[0] / b[0];
	for ( i = 1; i < n - 1; i++ )
	{
		pB[i]	= c[i] / ( b[i] - a[i] * pB[i - 1] );
	}
	pD[0]	= g[0] / b[0];
	for ( i = 1; i < n; i++ )
	{
		pD[i]	= ( g[i] - a[i] * pD[i - 1] ) / ( b[i] - a[i] * pB[i - 1] );
	}
	m_poKeyPoints.back().m	= pD[n - 1];
	for ( i = n - 2; i >= 0; --i )
	{
		m_poKeyPoints[i].m	= pD[i] - pB[i] * m_poKeyPoints[i+1].m;
	}
	delete[]pB;
	delete[]pD;

	delete[]a;
	delete[]b;
	delete[]c;
	delete[]g;
}
