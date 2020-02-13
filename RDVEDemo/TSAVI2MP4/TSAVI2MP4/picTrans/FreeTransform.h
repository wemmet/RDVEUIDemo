#pragma once
#include <stdint.h>
#include  <stdlib.h>
#include  <string.h>
#include <math.h>
#include "GRect.h"
#include "GPoint.h"
#include "GSize.h"

class CFreeTransform
{
public:
	CFreeTransform();
	~CFreeTransform();
	//设置原图像的相关信息，要求32位的像素格式。
	void setImage( const uint8_t* buffer, int32_t width, int32_t height, int32_t pitch );

	//设置只使用原图像的指定区域。
	//默认使用整个图像
	void setSourRect( int32_t left, int32_t top, int32_t width, int32_t height );

	//设置拉伸图像的4个角到指定的坐标。
	void setMapLeftTop( float x, float y );
	void setMapLeftBottom( float x, float y );
	void setMapRightTop( float x, float y );
	void setMapRightBottom( float x, float y );

	//计算拉伸后的图像。
	//返回的是拉伸后的图像。矩形的图像框住了设置的4个角的坐标。
	//width, height, pitch 分别返回拉伸后的图像的宽度、高度、每行字节数。
	const uint8_t* transform( int32_t* width, int32_t* height, int32_t* pitch );
	//得到框住4个角坐标的矩形区域，也就是拉伸后的图像应该贴在哪个区域。
	GRect bound() { return m_destRect; }
private:
	template <class pixel_t>
	class CImage
	{
	public:
		int32_t		width;
		int32_t		height;
		int32_t		pitch;
		int32_t		allocBytes;
		int8_t		bytesPerPixel;
		bool		useExternal;
		pixel_t*	imgBuf;
		GRect		rtImage;
		CImage()
		{
			width = height = pitch = bytesPerPixel = allocBytes = 0;
			useExternal = false; imgBuf = NULL;
		}
		~CImage()
		{
			clear();
		}
		bool create( pixel_t* _imgBuf, int32_t _width, int32_t _height, int32_t _pitch = 0, bool _useExternal = false )
		{
			if ( _height <= 0 || _height <= 0 ) return false;
			if ( _imgBuf == NULL && _useExternal ) return false;
			if ( _useExternal )
			{
				if ( _pitch <= 0 ) _pitch = ( sizeof( pixel_t ) * _width + 3 ) / 4 * 4;
				pitch = _pitch;
				imgBuf = _imgBuf;
			}
			else
			{
				int32_t		pitchTmp	= int32_t( sizeof( pixel_t ) * _width );
				pitchTmp	= pitchTmp > _pitch ? pitchTmp : _pitch;
                if (_pitch<=0)_pitch=pitchTmp;
				if ( pitchTmp * _height > allocBytes )
				{
					pixel_t*	imgTmp		= new pixel_t[pitchTmp * _height];
					if ( nullptr == imgTmp ) return false;
					clear();
					allocBytes	= pitchTmp * _height;
					imgBuf	= imgTmp;
				}
				pitch	= pitchTmp;
				if ( _imgBuf )
				{
					for ( int32_t y = 0; y < _height; ++y )
					{
						memcpy( ((uint8_t*)imgBuf) + y * pitch, ((uint8_t*)_imgBuf) + y * _pitch, pitch );
					}
				}
				else
				{
					memset( imgBuf, 0, pitch * _height );
				}
			}
			width = _width;
			height = _height;
			bytesPerPixel = sizeof( pixel_t );
			useExternal = _useExternal;
			rtImage	= GRect( 0, 0, width, height );
			return true;
		}
		void clear()
		{
			if ( !useExternal && imgBuf )
				delete[]imgBuf;
			width = height = pitch = bytesPerPixel = allocBytes = 0;
			useExternal = false; imgBuf = NULL;
		}
		inline pixel_t* pixel( int32_t x, int32_t y )
		{
			return (pixel_t*)( ( (uint8_t*)( imgBuf + x ) ) + y * pitch );
		}
		inline pixel_t* pixelEx( int32_t x, int32_t y )
		{
			int32_t	xd	= abs( x ) % ( width * 2 - 2 );
			x	= xd - ( ( ( xd + 1 ) % width ) * ( xd / width * 2 ) );
			int32_t	yd	= abs( y ) % ( height * 2 - 2 );
			y	= yd - ( ( ( yd + 1 ) % height ) * ( yd / height * 2 ) );
			return (pixel_t*)( ( (uint8_t*)( imgBuf + x ) ) + y * pitch );
		}
		int32_t byteCount() { return pitch * height; }
		bool isVaild() { return width && height; }

	};

	struct Pixel32
	{
		uint8_t	b;
		uint8_t	g;
		uint8_t	r;
		uint8_t	a;
		Pixel32( uint8_t _b = 0, uint8_t _g = 0, uint8_t _r = 0, uint8_t _a = 0 )
		{
			b = _b; g = _g; r = _r; a = _a;
		}
	};

	CImage<Pixel32>	m_imgOrg;
	CImage<Pixel32>	m_imgTran;
	GRect			m_sourRect;
	GRect			m_destRect;
	GPointF			m_vector[4];
	bool			m_changed;
	GRect calcBoundRect( const GPointF vector[4] );

	struct	S_Line
	{
		float	fPoStartX;
		float	fPoStartY;
		float	fPoEndX;
		float	fPoEndY;
		float	fSignX;
		float	fSignY;
		float	fLengthX;
		float	fLengthY;
		float	fDx;
		float	fViewHeightX;
		float	fViewHeightY;
		int32_t	iScaleTypeX;
		int32_t	iScaleTypeY;
	};

	bool CalcIntersectPoint( float poA_x1, float poA_y1, float poA_x2, float poA_y2,
		float poB_x1, float poB_y1, float poB_x2, float poB_y2,
		float* pRetX, float* pRetY );
	bool InitAcrossLine( float fPoStartX, float fPoStartY, float fPoEndX, float fPoEndY, float fScale, float fAcrossX, float fAcrossY, S_Line& sLine );
	bool CalcRealFromScale( S_Line& sLine, float fScale, float* pRetX, float* pRetY );
	float CalcScaleFromRealX( S_Line& sLine, float fX );
	float CalcScaleFromRealY( S_Line& sLine, float fY );
	bool Scenograph( int32_t iSourWidth, int32_t iSourHeight, uint8_t* lpSourBuf, int32_t iSourPitch,
		int32_t iDestWidth, int32_t iDestHeight, uint8_t* lpDestBuf, int32_t iDestPitch );
};

