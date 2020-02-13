 
#include "FreeTransform.h"


CFreeTransform::CFreeTransform()
{
	m_changed	= false;
}


CFreeTransform::~CFreeTransform()
{
}

void CFreeTransform::setImage( const uint8_t* buffer, int32_t width, int32_t height, int32_t pitch )
{
	m_imgOrg.create( (Pixel32*)buffer, width, height, pitch );
	m_sourRect	= GRect();
	m_changed	= true;
}

void CFreeTransform::setSourRect( int32_t left, int32_t top, int32_t width, int32_t height )
{
	m_sourRect.setRect( left, top, width, height );
	m_changed	= true;
}

void CFreeTransform::setMapLeftTop( float x, float y )
{
	m_vector[0].setPos( x, y );
	m_changed	= true;
}

void CFreeTransform::setMapLeftBottom( float x, float y )
{
	m_vector[3].setPos( x, y );
	m_changed	= true;
}

void CFreeTransform::setMapRightTop( float x, float y )
{
	m_vector[1].setPos( x, y );
	m_changed	= true;
}

void CFreeTransform::setMapRightBottom( float x, float y )
{
	m_vector[2].setPos( x, y );
	m_changed	= true;
}

const uint8_t * CFreeTransform::transform( int32_t * width, int32_t * height, int32_t * pitch )
{
	if ( m_sourRect.isEmpty() ) return nullptr;
	if ( m_changed )
	{
		m_destRect	= calcBoundRect( m_vector );
		if ( m_destRect.isEmpty() ) return nullptr;
		m_imgTran.create( nullptr, m_destRect.width(), m_destRect.height() );
		if ( m_sourRect.isEmpty() )
		{
			Scenograph( m_imgOrg.width, m_imgOrg.height, (uint8_t*)m_imgOrg.pixel( 0, 0 ),
				m_imgOrg.pitch, m_imgTran.width, m_imgTran.height, (uint8_t*)m_imgTran.pixel( 0, 0 ), m_imgTran.pitch );
		}
		else
		{
			Scenograph( m_sourRect.width(), m_sourRect.height(), (uint8_t*)m_imgOrg.pixel( m_sourRect.left(), m_sourRect.top() ),
				m_imgOrg.pitch, m_imgTran.width, m_imgTran.height, (uint8_t*)m_imgTran.pixel( 0, 0 ), m_imgTran.pitch );

		}
	}
	if ( width ) *width = m_imgTran.width;
	if ( height ) *height = m_imgTran.height;
	if ( pitch ) *pitch = m_imgTran.pitch;
	return (uint8_t*)m_imgTran.imgBuf;
}

GRect CFreeTransform::calcBoundRect( const GPointF vector[4] )
{
	float	left	= 9999999.0f;
	float	top		= 9999999.0f;
	float	right	= -9999999.0f;
	float	bottom	= -9999999.0f;
	for ( int32_t i = 0; i < 4; ++i )
	{
		if ( vector[i].x() < left ) left =  vector[i].x();
		if ( vector[i].y() < top ) top =  vector[i].y();
		if ( vector[i].x() > right ) right =  vector[i].x();
		if ( vector[i].y() > bottom ) bottom =  vector[i].y();
	}
	left	= floorf( left );
	top		= floorf( top );
	right	= ceilf( right );
	bottom	= ceilf( bottom );
	return GRect( left, top, right - left, bottom - top );
}


bool CFreeTransform::CalcIntersectPoint( float poA_x1, float poA_y1, float poA_x2, float poA_y2,
	float poB_x1, float poB_y1, float poB_x2, float poB_y2,
	float* pRetX, float* pRetY )
{
	float	a1, b1, c1, a2, b2, c2, m;

	a1	= poA_y2 - poA_y1;
	b1	= poA_x1 - poA_x2;
	c1	= ( poA_x2 - poA_x1 ) * poA_y1 - ( poA_y2 - poA_y1 ) * poA_x1;

	if ( b1 < 0 )
	{
		a1	*= -1;
		b1	*= -1;
		c1	*= -1;
	}
	else if ( b1 == 0 && a1 < 0 )
	{
		a1	*= -1;
		c1	*= -1;
	}

	a2	= poB_y2 - poB_y1;
	b2	= poB_x1 - poB_x2;
	c2	= ( poB_x2 - poB_x1 ) * poB_y1 - ( poB_y2 - poB_y1 ) * poB_x1;

	if ( b2 < 0 )
	{
		a2	*= -1;
		b2	*= -1;
		c2	*= -1;
	}
	else if ( b2 == 0 && a2 < 0 )
	{
		a2	*= -1;
		c2	*= -1;
	}


	m	= a1 * b2 - a2 * b1;
	if ( m == 0 )
	{
		return false;
	}
	if ( pRetX ) *pRetX	= ( c2 * b1 - c1 * b2 ) / m;
	if ( pRetY ) *pRetY	= ( c1 * a2 - c2 * a1 ) / m;
	return true;
}

bool CFreeTransform::InitAcrossLine( float fPoStartX, float fPoStartY, float fPoEndX, float fPoEndY, float fScale, float fAcrossX, float fAcrossY, S_Line& sLine )
{
	float	fPoScale	= 0.0f;
	float	fPoReal		= 0.0f;

	sLine.fPoStartX	= fPoStartX;
	sLine.fPoStartY	= fPoStartY;
	sLine.fPoEndX	= fPoEndX;
	sLine.fPoEndY	= fPoEndY;
	//计算线段在X和Y上的映射长度。
	sLine.fLengthX	= fPoEndX - fPoStartX;
	sLine.fSignX	= sLine.fLengthX < 0.0f ? -1.0f : 1.0f;
	sLine.fLengthX	= sLine.fLengthX < 0.0f ? -sLine.fLengthX : sLine.fLengthX;
	sLine.fLengthY	= fPoEndY - fPoStartY;
	sLine.fSignY	= sLine.fLengthY < 0.0f ? -1.0f : 1.0f;
	sLine.fLengthY	= sLine.fLengthY < 0.0f ? -sLine.fLengthY : sLine.fLengthY;
	sLine.fDx		= sLine.fLengthY == 0.0f ? 0.0f : sLine.fLengthX / sLine.fLengthY;
	//计算X方向上的虚视点
	if ( sLine.fLengthX > 0.0f )
	{
		fPoScale	= fScale * sLine.fLengthX;
		fPoReal		= fAcrossX - fPoStartX;
		fPoReal		= fPoReal < 0.0f ? -fPoReal : fPoReal;
		if ( fPoScale - fPoReal > 0.1f && fPoReal > 0.0f )
		{
			sLine.iScaleTypeX	= 1;
			fPoScale			= sLine.fLengthX - fPoScale;
			fPoReal				= sLine.fLengthX - fPoReal;
			sLine.fViewHeightX	= fPoReal * ( sLine.fLengthX - fPoScale ) / ( fPoReal - fPoScale );
		}
		else if ( fPoReal - fPoScale > 0.1f )
		{
			sLine.iScaleTypeX	= 2;
			sLine.fViewHeightX	= fPoReal * ( sLine.fLengthX - fPoScale ) / ( fPoReal - fPoScale );
		}
		else
		{
			sLine.iScaleTypeX	= 0;
			sLine.fViewHeightX	= 0;
		}
	}

	//计算Y方向上的虚视点
	if ( sLine.fLengthY > 0.0f )
	{
		fPoScale	= fScale * sLine.fLengthY;
		fPoReal		= fAcrossY - fPoStartY;
		fPoReal		= fPoReal < 0 ? -fPoReal : fPoReal;
		if ( fPoScale - fPoReal > 0.1f && fPoReal > 0.0f )
		{
			sLine.iScaleTypeY	= 1;
			fPoScale			= sLine.fLengthY - fPoScale;
			fPoReal				= sLine.fLengthY - fPoReal;
			sLine.fViewHeightY	= fPoReal * ( sLine.fLengthY - fPoScale ) / ( fPoReal - fPoScale );
		}
		else if ( fPoReal - fPoScale > 0.1f )
		{
			sLine.iScaleTypeY	= 2;
			sLine.fViewHeightY	= fPoReal * ( sLine.fLengthY - fPoScale ) / ( fPoReal - fPoScale );
		}
		else
		{
			sLine.iScaleTypeY	= 0;
			sLine.fViewHeightY	= 0;
		}
	}
	return true;
}

bool CFreeTransform::CalcRealFromScale( S_Line& sLine, float fScale, float* pRetX, float* pRetY )
{
	float		fDenominator	= 0.0f;
	float		fPoReal			= 0.0f;

	if ( pRetX )
	{
		switch ( sLine.iScaleTypeX )
		{
		case 0:
			*pRetX	= sLine.fLengthX * fScale * sLine.fSignX + sLine.fPoStartX;
			break;
		case 1:
			fPoReal	= ( 1 - fScale ) * sLine.fLengthX;
			if ( fPoReal == 0.0f )
			{
				*pRetX = sLine.fPoStartX;
			}
			else
			{
				fDenominator	= sLine.fViewHeightX - sLine.fLengthX + fPoReal;
				if ( fDenominator == 0.0f ) return false;
				*pRetX	= ( sLine.fLengthX - sLine.fViewHeightX * fPoReal / fDenominator ) * sLine.fSignX + sLine.fPoStartX;
			}
			break;
		case 2:
			fPoReal	= fScale * sLine.fLengthX;
			if ( fPoReal == 0.0f )
			{
				*pRetX = sLine.fPoStartX;
			}
			else
			{
				fDenominator	= sLine.fViewHeightX - sLine.fLengthX + fPoReal;
				if ( fDenominator == 0.0f ) return false;
				*pRetX	= ( sLine.fViewHeightX * fPoReal / fDenominator ) * sLine.fSignX + sLine.fPoStartX;
			}
			break;
		}
	}

	if ( pRetY )
	{
		switch ( sLine.iScaleTypeY )
		{
		case 0:
			*pRetY	= sLine.fLengthY * fScale * sLine.fSignY + sLine.fPoStartY;
			break;
		case 1:
			fPoReal	= ( 1 - fScale ) * sLine.fLengthY;
			if ( fPoReal == 0.0f )
			{
				*pRetY = sLine.fPoStartY;
			}
			else
			{
				fDenominator	= sLine.fViewHeightY - sLine.fLengthY + fPoReal;
				if ( fDenominator == 0.0f ) return false;
				*pRetY	= ( sLine.fLengthY - sLine.fViewHeightY * fPoReal / fDenominator ) * sLine.fSignY + sLine.fPoStartY;
			}
			break;
		case 2:
			fPoReal	= fScale * sLine.fLengthY;
			if ( fPoReal == 0.0f )
			{
				*pRetY = sLine.fPoStartY;
			}
			else
			{
				fDenominator	= sLine.fViewHeightY - sLine.fLengthY + fPoReal;
				if ( fDenominator == 0.0f ) return false;
				*pRetY	= ( sLine.fViewHeightY * fPoReal / fDenominator ) * sLine.fSignY + sLine.fPoStartY;
			}
			break;
		}
	}


	return true;
}

float CFreeTransform::CalcScaleFromRealX( S_Line& sLine, float fX )
{
	float	fScale		= 0.0f;

	if ( sLine.iScaleTypeX == 0 )
	{
		fScale	= ( fX - sLine.fPoStartX ) * sLine.fSignX;
	}
	else if ( sLine.iScaleTypeX == 1 )
	{
		fScale	= ( sLine.fPoEndX - fX ) * sLine.fSignX;
		fScale	= sLine.fLengthX - fScale * ( sLine.fViewHeightX - sLine.fLengthX ) / ( sLine.fViewHeightX - fScale );
	}
	else if ( sLine.iScaleTypeX == 2 )
	{
		fScale	= ( fX - sLine.fPoStartX ) * sLine.fSignX;
		fScale	= fScale * ( sLine.fViewHeightX - sLine.fLengthX ) / ( sLine.fViewHeightX - fScale );
	}
	fScale	= fScale / sLine.fLengthX;
	return fScale;
}

float CFreeTransform::CalcScaleFromRealY( S_Line& sLine, float fY )
{
	float	fScale		= 0.0f;

	if ( sLine.iScaleTypeY == 0 )
	{
		fScale	= ( fY - sLine.fPoStartY ) * sLine.fSignY;
	}
	else if ( sLine.iScaleTypeY == 1 )
	{
		fScale	= ( sLine.fPoEndY - fY ) * sLine.fSignY;
		fScale	= sLine.fLengthY - fScale * ( sLine.fViewHeightY - sLine.fLengthY ) / ( sLine.fViewHeightY - fScale );
	}
	else if ( sLine.iScaleTypeY == 2 )
	{
		fScale	= ( fY - sLine.fPoStartY ) * sLine.fSignY;
		fScale	= fScale * ( sLine.fViewHeightY - sLine.fLengthY ) / ( sLine.fViewHeightY - fScale );
	}
	fScale	= fScale / sLine.fLengthY;
	return fScale;
}

bool CFreeTransform::Scenograph( int32_t iSourWidth, int32_t iSourHeight, uint8_t* lpSourBuf, int32_t iSourPitch,
	int32_t iDestWidth, int32_t iDestHeight, uint8_t* lpDestBuf, int32_t iDestPitch )
{
	float	fCrossPointX	= 0.0f;
	float	fCrossPointY	= 0.0f;
	float	fAcrossPointX	= 0.0f;
	float	fAcrossPointY	= 0.0f;
	float	fPointAX		= 0.0f;
	float	fPointAY		= 0.0f;
	float	fPointBX		= 0.0f;
	float	fPointBY		= 0.0f;
	float	fStartX			= 0.0f;
	float	fEndX			= 0.0f;

	S_Line	sLineAcross02	= { 0 };
	S_Line	sLineAcross13	= { 0 };
	S_Line	sFoulLine[4]	= { 0 };	//线0=p0~p1；线1=p1~02；线2=p3~02；线3=p0~p3；
	S_Line	sLineMid		= { 0 };
	S_Line	sLineCur		= { 0 };
	int		iLineLeft		= 0;
	int		iLineRight		= 0;
	int		iX				= 0;
	int		iY				= 0;
	int		iEndX			= 0;
	int		iSX		= 0, iSY		= 0;

	uint8_t*	lpSourPixel		= NULL;
	uint8_t*	lpDestPixel		= NULL;

	struct
	{
		float	fX;
		float	fY;
		float	fcx;
		float	fDx;
		int		iInd;
	}sPointLine[5]			= { 0 };
	int		iCount			= 0;
	int		iIndex			= 0;

	if ( iSourWidth <= 0 || iSourHeight <= 0 || iDestWidth <= 0 || iDestHeight <= 0 ) return false;
	GPointF		poDestLst[4];
	for ( int i = 0; i < 4; ++i )
	{
		poDestLst[i] = m_vector[i] - m_destRect.topLeft();
	}
	GRect	rtBound		= calcBoundRect( poDestLst );

	//
	//iSourPitch	= iSourPitch ? iSourPitch : iSourWidth * 4;
	//iDestPitch	= iDestPitch ? iDestPitch : iDestWidth * 4;
	//
	//iSourWidth--;
	//iSourHeight--;

	//iDestWidth	= rtBound.right() - rtBound.left();
	//iDestHeight	= rtBound.bottom() - rtBound.top();

	//计算四边形两条对角线的交点
	CalcIntersectPoint( poDestLst[0].x(), poDestLst[0].y(), poDestLst[2].x(), poDestLst[2].y(), poDestLst[1].x(), poDestLst[1].y(), poDestLst[3].x(), poDestLst[3].y(), &fCrossPointX, &fCrossPointY );
	//根据四边形两条对角线的交点，分别计算出对应的虚视点等信息。
	InitAcrossLine( poDestLst[0].x(), poDestLst[0].y(), poDestLst[2].x(), poDestLst[2].y(), 0.5f, fCrossPointX, fCrossPointY, sLineAcross02 );
	InitAcrossLine( poDestLst[1].x(), poDestLst[1].y(), poDestLst[3].x(), poDestLst[3].y(), 0.5f, fCrossPointX, fCrossPointY, sLineAcross13 );
	//计算四条边线上的虚视点
	CalcRealFromScale( sLineAcross02, 0.25f, &fPointAX, &fPointAY );
	CalcRealFromScale( sLineAcross13, 0.75f, &fPointBX, &fPointBY );

	CalcIntersectPoint( fPointAX, fPointAY, fPointBX, fPointBY, poDestLst[0].x(), poDestLst[0].y(), poDestLst[1].x(), poDestLst[1].y(), &fAcrossPointX, &fAcrossPointY );
	InitAcrossLine( poDestLst[0].x(), poDestLst[0].y(), poDestLst[1].x(), poDestLst[1].y(), 0.25f, fAcrossPointX, fAcrossPointY, sFoulLine[0] );

	CalcIntersectPoint( fPointAX, fPointAY, fPointBX, fPointBY, poDestLst[3].x(), poDestLst[3].y(), poDestLst[2].x(), poDestLst[2].y(), &fAcrossPointX, &fAcrossPointY );
	InitAcrossLine( poDestLst[3].x(), poDestLst[3].y(), poDestLst[2].x(), poDestLst[2].y(), 0.25f, fAcrossPointX, fAcrossPointY, sFoulLine[2] );

	CalcRealFromScale( sLineAcross13, 0.25f, &fPointBX, &fPointBY );

	CalcIntersectPoint( fPointAX, fPointAY, fPointBX, fPointBY, poDestLst[1].x(), poDestLst[1].y(), poDestLst[2].x(), poDestLst[2].y(), &fAcrossPointX, &fAcrossPointY );
	InitAcrossLine( poDestLst[1].x(), poDestLst[1].y(), poDestLst[2].x(), poDestLst[2].y(), 0.25f, fAcrossPointX, fAcrossPointY, sFoulLine[1] );

	CalcIntersectPoint( fPointAX, fPointAY, fPointBX, fPointBY, poDestLst[0].x(), poDestLst[0].y(), poDestLst[3].x(), poDestLst[3].y(), &fAcrossPointX, &fAcrossPointY );
	InitAcrossLine( poDestLst[0].x(), poDestLst[0].y(), poDestLst[3].x(), poDestLst[3].y(), 0.25f, fAcrossPointX, fAcrossPointY, sFoulLine[3] );

	//挑选并计算出四边形的中位线
	fPointAX	= 0.0f;
	for ( iIndex = 0; iIndex < 4; ++iIndex )
	{
		if ( sFoulLine[iIndex].fLengthY == 1.0f )
		{
			iCount	= iIndex;
			break;
		}
		else if ( sFoulLine[iIndex].fLengthX / sFoulLine[iIndex].fLengthY > fPointAX )
		{
			fPointAX	= sFoulLine[iIndex].fLengthX / sFoulLine[iIndex].fLengthY;
			iCount	= iIndex;
		}
	}
	if ( iCount == 0 || iCount == 2 ) { iIndex = 0; iCount = 2; iLineLeft = 3; iLineRight = 1; }
	if ( iCount == 1 || iCount == 3 ) { iIndex = 3; iCount = 1; iLineLeft = 0; iLineRight = 2; }
	CalcRealFromScale( sFoulLine[iIndex], 0.5f, &fPointAX, &fPointAY );
	CalcRealFromScale( sFoulLine[iCount], 0.5f, &fPointBX, &fPointBY );
	InitAcrossLine( fPointAX, fPointAY, fPointBX, fPointBY, 0.5f, fCrossPointX, fCrossPointY, sLineMid );



	//使用扫描线方式填充
	for ( iY = rtBound.top(); iY <= rtBound.bottom(); ++iY )
	{
		//检查当前高度的水平扫描线与各边的交点
		iCount	= 0;
		for ( iIndex = 0; iIndex < 4; ++iIndex )
		{
			sPointLine[iCount].fY	= ( iY - sFoulLine[iIndex].fPoStartY ) * sFoulLine[iIndex].fSignY;
			if ( sPointLine[iCount].fY >= 0.0f && sPointLine[iCount].fY <= sFoulLine[iIndex].fLengthY && sFoulLine[iIndex].fLengthY > 0.0f )
			{
				sPointLine[iCount].fX	= sPointLine[iCount].fY * sFoulLine[iIndex].fLengthX / sFoulLine[iIndex].fLengthY;
				sPointLine[iCount].fcx	= ( sFoulLine[iIndex].fSignX * sFoulLine[iIndex].fPoStartX + sPointLine[iCount].fX ) * sFoulLine[iIndex].fSignX;
				sPointLine[iCount].iInd	= iIndex;
				sPointLine[iCount].fDx	= sFoulLine[iIndex].fDx;
				iCount++;
			}
		}
		//按水平扫描线与边线交点的 x 从小到大排序
		for ( iIndex = 0; iIndex < iCount - 1; ++iIndex )
		{
			for ( int i2 = iIndex + 1; i2 < iCount; ++i2 )
			{
				if ( sPointLine[iIndex].fcx > sPointLine[i2].fcx )
				{
					sPointLine[4]	= sPointLine[iIndex];
					sPointLine[iIndex]	= sPointLine[i2];
					sPointLine[i2]	= sPointLine[4];
				}
				else if ( sPointLine[iIndex].fcx == sPointLine[i2].fcx )
				{
					if ( iCount > 2 )
					{
						for ( int i3 = i2; i3 < iCount - 1; ++i3 )
						{
							sPointLine[i3]	= sPointLine[i3 + 1];
						}
						--iCount;
						--i2;
					}
					else
					{
						if ( sFoulLine[sPointLine[iIndex].iInd].fPoStartX == sPointLine[iIndex].fcx )
						{
							if ( ( sFoulLine[sPointLine[i2].iInd].fPoStartX == sPointLine[iIndex].fcx && sFoulLine[sPointLine[iIndex].iInd].fPoEndX > sFoulLine[sPointLine[i2].iInd].fPoEndX ) ||
								( sFoulLine[sPointLine[i2].iInd].fPoEndX == sPointLine[iIndex].fcx && sFoulLine[sPointLine[iIndex].iInd].fPoEndX > sFoulLine[sPointLine[i2].iInd].fPoStartX ) )
							{
								sPointLine[4]	= sPointLine[iIndex];
								sPointLine[iIndex]	= sPointLine[i2];
								sPointLine[i2]	= sPointLine[4];
							}
						}
						else if ( sFoulLine[sPointLine[iIndex].iInd].fPoEndX == sPointLine[iIndex].fcx )
						{
							if ( ( sFoulLine[sPointLine[i2].iInd].fPoStartX == sPointLine[iIndex].fcx && sFoulLine[sPointLine[iIndex].iInd].fPoStartX > sFoulLine[sPointLine[i2].iInd].fPoEndX ) ||
								( sFoulLine[sPointLine[i2].iInd].fPoEndX == sPointLine[iIndex].fcx && sFoulLine[sPointLine[iIndex].iInd].fPoStartX > sFoulLine[sPointLine[i2].iInd].fPoStartX ) )
							{
								sPointLine[4]	= sPointLine[iIndex];
								sPointLine[iIndex]	= sPointLine[i2];
								sPointLine[i2]	= sPointLine[4];
							}
						}
					}
				}
			}
		}
		//填充一行
		for ( iIndex = 0; iIndex < iCount; iIndex += 2 )
		{
			//计算过四边形的扫描线在原始图像上的切线位置
			if ( sPointLine[iIndex].iInd == iLineLeft )
			{
				fPointAX	= sPointLine[iIndex].fcx;
			}
			else if ( sPointLine[iIndex + 1].iInd == iLineLeft )
			{
				fPointAX	= sPointLine[iIndex + 1].fcx;
			}
			else
			{
				CalcIntersectPoint( sFoulLine[iLineLeft].fPoStartX, sFoulLine[iLineLeft].fPoStartY, sFoulLine[iLineLeft].fPoEndX, sFoulLine[iLineLeft].fPoEndY, 0.0f, (float)iY, 100.0f, (float)iY, &fPointAX, NULL );
			}
			fPointAY	= (float)iY;

			if ( sPointLine[iIndex].iInd == iLineRight )
			{
				fPointBX	= sPointLine[iIndex].fcx;
			}
			else if ( sPointLine[iIndex + 1].iInd == iLineRight )
			{
				fPointBX	= sPointLine[iIndex + 1].fcx;
			}
			else
			{
				CalcIntersectPoint( sFoulLine[iLineRight].fPoStartX, sFoulLine[iLineRight].fPoStartY, sFoulLine[iLineRight].fPoEndX, sFoulLine[iLineRight].fPoEndY, 0.0f, (float)iY, 100.0f, (float)iY, &fPointBX, NULL );
			}
			fPointBY	= (float)iY;

			CalcIntersectPoint( sLineMid.fPoStartX, sLineMid.fPoStartY, sLineMid.fPoEndX, sLineMid.fPoEndY, 0.0f, (float)iY, 100.0f, (float)iY, &fAcrossPointX, &fAcrossPointY );
			InitAcrossLine( fPointAX, fPointAY, fPointBX, fPointBY, 0.5f, fAcrossPointX, fAcrossPointY, sLineCur );

			if ( sLineCur.fLengthX < 0.5f ) continue;

			if ( iLineLeft == 0 )
			{
				if ( sFoulLine[iLineLeft].fLengthX > sFoulLine[iLineLeft].fLengthY )
				{
					fPointAX	= CalcScaleFromRealX( sFoulLine[iLineLeft], fPointAX ) * iSourWidth;
				}
				else
				{
					fPointAX	= CalcScaleFromRealY( sFoulLine[iLineLeft], fPointAY ) * iSourWidth;
				}
				fPointAY	= 0;

				if ( sFoulLine[iLineRight].fLengthX > sFoulLine[iLineRight].fLengthY )
				{
					fPointBX	= CalcScaleFromRealX( sFoulLine[iLineRight], fPointBX ) * iSourWidth;
				}
				else
				{
					fPointBX	= CalcScaleFromRealY( sFoulLine[iLineRight], fPointBY ) * iSourWidth;
				}
				fPointBY	= (float)iSourHeight;
			}
			else
			{
				if ( sFoulLine[iLineLeft].fLengthX > sFoulLine[iLineLeft].fLengthY )
				{
					fPointAY	= CalcScaleFromRealX( sFoulLine[iLineLeft], fPointAX ) * iSourHeight;
				}
				else
				{
					fPointAY	= CalcScaleFromRealY( sFoulLine[iLineLeft], fPointAY ) * iSourHeight;
				}
				fPointAX	= 0;

				if ( sFoulLine[iLineRight].fLengthX > sFoulLine[iLineRight].fLengthY )
				{
					fPointBY	= CalcScaleFromRealX( sFoulLine[iLineRight], fPointBX ) * iSourHeight;
				}
				else
				{
					fPointBY	= CalcScaleFromRealY( sFoulLine[iLineRight], fPointBY ) * iSourHeight;
				}
				fPointBX	= (float)iSourWidth;
			}

			float	fScale		= 0.0f;
			float	fScaleW		= fPointBX - fPointAX;
			float	fScaleH		= fPointBY - fPointAY;

			//
			//fStartX	= sPointLine[iIndex].fcx - sPointLine[iIndex].fDx;
			//fEndX	= ( fStartX - sFoulLine[sPointLine[iIndex].iInd].fPoStartX ) * sFoulLine[sPointLine[iIndex].iInd].fSignX;
			//fStartX	= fEndX < 0.0f ? sFoulLine[sPointLine[iIndex].iInd].fPoStartX : ( fEndX > sFoulLine[sPointLine[iIndex].iInd].fLengthX ? sFoulLine[sPointLine[iIndex].iInd].fPoEndX : fStartX );
			//fEndX	= ceilf( sPointLine[iIndex].fcx );
			//iX		= (int)floor( fStartX );
			//

			//iEndX		= (int)fEndX;
			//if ( fStartX != fEndX && iEndX > rtDest.left )
			//{
			//	fAcrossPointX	= CalcScaleFromRealX( sLineCur, sPointLine[iIndex].fcx ) * fScaleW + fPointAX;
			//	fAcrossPointY	= CalcScaleFromRealX( sLineCur, sPointLine[iIndex].fcx ) * fScaleH + fPointAY;
			//	if ( fAcrossPointX <= -1.0f || fAcrossPointY <= -1.0f || fAcrossPointX >= iSourWidth + 1.0f || fAcrossPointY >= iSourHeight + 1.0f ) continue;

			//	lpDestPixel	= lpDestBuf + iY * iDestPitch + iX * 4;
			//	lpSourPixel	= lpSourBuf + int( fAcrossPointY ) * iSourPitch + int( fAcrossPointX ) * 4;
			//	fEndX	= ( float( iX + 1 ) < sPointLine[iIndex].fcx ? float( iX + 1 ) : sPointLine[iIndex].fcx ) - fStartX;
			//	fStartX	= 0.0f;
			//	fCrossPointX	= fEndX;
			//	for ( ; iX < iEndX; ++iX )
			//	{
			//		fCrossPointX	= ( fStartX + fEndX ) * fCrossPointX / ( sPointLine[iIndex].fDx * 2 ) + ( iX == iEndX - 1 ? float( iEndX ) - sPointLine[iIndex].fcx : 0.0f );

			//		if ( iX >= rtDest.left && iX < rtDest.right )
			//		{
			//			BYTE	bA	= BYTE(fCrossPointX	* lpSourPixel[3]);

			//			lpDestPixel[0]	= ( bA * ( lpSourPixel[0] - lpDestPixel[0] ) + ( lpDestPixel[0] << 8 ) ) >> 8;
			//			lpDestPixel[1]	= ( bA * ( lpSourPixel[1] - lpDestPixel[1] ) + ( lpDestPixel[1] << 8 ) ) >> 8;
			//			lpDestPixel[2]	= ( bA * ( lpSourPixel[2] - lpDestPixel[2] ) + ( lpDestPixel[2] << 8 ) ) >> 8;
			//			lpDestPixel[3]	= bA + ( ( ( 256 - bA  ) * lpDestPixel[3] ) >> 8 );
			//		}
			//		lpDestPixel		+= 4;

			//		fCrossPointX	= ( sPointLine[iIndex].fDx - fEndX ) >= 1.0f ? 1.0f : sPointLine[iIndex].fDx - fEndX;
			//		fStartX			= fEndX;
			//		fEndX			+= fCrossPointX;
			//	}
			//}
			iX		= (int)ceilf( sPointLine[iIndex].fcx );
			iX		= iX < rtBound.left() ? rtBound.left() : iX;
			iEndX	= (int)floor( sPointLine[iIndex + 1].fcx );
			iEndX	= iEndX < rtBound.right() - 1 ? iEndX : rtBound.right() - 1;
			lpDestPixel	= lpDestBuf + iY * iDestPitch + iX * 4;

			if ( sLineCur.iScaleTypeX == 0 )
			{
				for ( ; iX <= iEndX; ++iX )
				{
					fScale	= ( iX - sLineCur.fPoStartX ) * sLineCur.fSignX;
					iSX	= int32_t( fScale * fScaleW / sLineCur.fLengthX + fPointAX );
					iSY	= int32_t( fScale * fScaleH / sLineCur.fLengthX + fPointAY );
					iSX	= iSX < 0 ? 0 : iSX > iSourWidth ? iSourWidth : iSX;
					iSY	= iSY < 0 ? 0 : iSY > iSourHeight ? iSourHeight : iSY;
					lpSourPixel	= lpSourBuf + iSY * iSourPitch + iSX * 4;
					lpDestPixel[0]	= ( lpSourPixel[3] * ( lpSourPixel[0] - lpDestPixel[0] ) + ( lpDestPixel[0] << 8 ) ) >> 8;
					lpDestPixel[1]	= ( lpSourPixel[3] * ( lpSourPixel[1] - lpDestPixel[1] ) + ( lpDestPixel[1] << 8 ) ) >> 8;
					lpDestPixel[2]	= ( lpSourPixel[3] * ( lpSourPixel[2] - lpDestPixel[2] ) + ( lpDestPixel[2] << 8 ) ) >> 8;
					lpDestPixel[3]	= lpSourPixel[3] + ( ( ( 256 - lpSourPixel[3] ) * lpDestPixel[3] ) >> 8 );

					lpDestPixel	+= 4;
				}
			}
			else if ( sLineCur.iScaleTypeX == 1 )
			{
				for ( ; iX <= iEndX; ++iX )
				{
					fScale	= ( sLineCur.fPoEndX - iX ) * sLineCur.fSignX;
					fScale	= sLineCur.fLengthX - fScale * ( sLineCur.fViewHeightX - sLineCur.fLengthX ) / ( sLineCur.fViewHeightX - fScale );
					//fAcrossPointX	= fScale * fScaleW / sLineCur.fLengthX + fPointAX;
					//fAcrossPointY	= fScale * fScaleH / sLineCur.fLengthX + fPointAY;
					iSX	= int32_t( fScale * fScaleW / sLineCur.fLengthX + fPointAX );
					iSY	= int32_t( fScale * fScaleH / sLineCur.fLengthX + fPointAY );
					iSX	= iSX < 0 ? 0 : iSX > iSourWidth ? iSourWidth : iSX;
					iSY	= iSY < 0 ? 0 : iSY > iSourHeight ? iSourHeight : iSY;
					lpSourPixel	= lpSourBuf + iSY * iSourPitch + iSX * 4;

					lpDestPixel[0]	= ( lpSourPixel[3] * ( lpSourPixel[0] - lpDestPixel[0] ) + ( lpDestPixel[0] << 8 ) ) >> 8;
					lpDestPixel[1]	= ( lpSourPixel[3] * ( lpSourPixel[1] - lpDestPixel[1] ) + ( lpDestPixel[1] << 8 ) ) >> 8;
					lpDestPixel[2]	= ( lpSourPixel[3] * ( lpSourPixel[2] - lpDestPixel[2] ) + ( lpDestPixel[2] << 8 ) ) >> 8;
					lpDestPixel[3]	= lpSourPixel[3] + ( ( ( 256 - lpSourPixel[3] ) * lpDestPixel[3] ) >> 8 );

					lpDestPixel	+= 4;
				}
			}
			else if ( sLineCur.iScaleTypeX == 2 )
			{
				for ( ; iX <= iEndX; ++iX )
				{
					fScale	= ( iX - sLineCur.fPoStartX ) * sLineCur.fSignX;
					fScale	= fScale * ( sLineCur.fViewHeightX - sLineCur.fLengthX ) / ( sLineCur.fViewHeightX - fScale );
					iSX	= int32_t( fScale * fScaleW / sLineCur.fLengthX + fPointAX );
					iSY	= int32_t( fScale * fScaleH / sLineCur.fLengthX + fPointAY );
					iSX	= iSX < 0 ? 0 : iSX > iSourWidth ? iSourWidth : iSX;
					iSY	= iSY < 0 ? 0 : iSY > iSourHeight ? iSourHeight : iSY;
					lpSourPixel	= lpSourBuf + iSY * iSourPitch + iSX * 4;

					lpDestPixel[0]	= ( lpSourPixel[3] * ( lpSourPixel[0] - lpDestPixel[0] ) + ( lpDestPixel[0] << 8 ) ) >> 8;
					lpDestPixel[1]	= ( lpSourPixel[3] * ( lpSourPixel[1] - lpDestPixel[1] ) + ( lpDestPixel[1] << 8 ) ) >> 8;
					lpDestPixel[2]	= ( lpSourPixel[3] * ( lpSourPixel[2] - lpDestPixel[2] ) + ( lpDestPixel[2] << 8 ) ) >> 8;
					lpDestPixel[3]	= lpSourPixel[3] + ( ( ( 256 - lpSourPixel[3] ) * lpDestPixel[3] ) >> 8 );

					lpDestPixel	+= 4;
				}
			}

			//fEndX	= sPointLine[iIndex + 1].fcx + sPointLine[iIndex + 1].fDx;
			//fStartX	= ( fEndX - sFoulLine[sPointLine[iIndex + 1].iInd].fPoStartX ) * sFoulLine[sPointLine[iIndex + 1].iInd].fSignX;
			//fEndX	= fStartX < 0.0f ? sFoulLine[sPointLine[iIndex + 1].iInd].fPoStartX : ( fStartX > sFoulLine[sPointLine[iIndex + 1].iInd].fLengthX ? sFoulLine[sPointLine[iIndex + 1].iInd].fPoEndX : fEndX );
			//iEndX	= (int)ceilf( fEndX );
			//iEndX	= iEndX < rtDest.right - 1 ? iEndX : rtDest.right - 1;

			//if ( iX <= iEndX )
			//{
			//	fAcrossPointX	= CalcScaleFromRealX( sLineCur, sPointLine[iIndex+1].fcx ) * fScaleW + fPointAX;
			//	fAcrossPointY	= CalcScaleFromRealX( sLineCur, sPointLine[iIndex+1].fcx ) * fScaleH + fPointAY;
			//	if ( fAcrossPointX <= -1.0f || fAcrossPointY <= -1.0f || fAcrossPointX >= iSourWidth + 1.0f || fAcrossPointY >= iSourHeight + 1.0f ) continue;

			//	lpSourPixel	= lpSourBuf + int( fAcrossPointY ) * iSourPitch + int( fAcrossPointX ) * 4;
			//	fCrossPointY	= sPointLine[iIndex + 1].fcx + 1.0f - float( iX );
			//	fCrossPointX	= sPointLine[iIndex + 1].fDx < 1.0f - fCrossPointY ? sPointLine[iIndex + 1].fDx : 1.0f - fCrossPointY;
			//	fStartX			= sPointLine[iIndex + 1].fDx;
			//	fEndX			= fStartX - fCrossPointX;
			//	for ( ; iX <= iEndX; ++iX )
			//	{
			//		fCrossPointX	= ( fStartX + fEndX ) * fCrossPointX / ( sPointLine[iIndex + 1].fDx * 2 ) + fCrossPointY;
			//		BYTE	bA	= BYTE(fCrossPointX	* lpSourPixel[3]);

			//		lpDestPixel[0]	= ( bA * ( lpSourPixel[0] - lpDestPixel[0] ) + ( lpDestPixel[0] << 8 ) ) >> 8;
			//		lpDestPixel[1]	= ( bA * ( lpSourPixel[1] - lpDestPixel[1] ) + ( lpDestPixel[1] << 8 ) ) >> 8;
			//		lpDestPixel[2]	= ( bA * ( lpSourPixel[2] - lpDestPixel[2] ) + ( lpDestPixel[2] << 8 ) ) >> 8;
			//		lpDestPixel[3]	= bA + ( ( ( 256 - bA  ) * lpDestPixel[3] ) >> 8 );


			//		lpDestPixel		+= 4;

			//		fCrossPointY	= 0.0f;
			//		fCrossPointX	= fEndX >= 1.0f ? 1.0f : fEndX;
			//		fStartX			= fEndX;
			//		fEndX			-= fCrossPointX;
			//	}
			//}

		}
	}


	return true;
}

