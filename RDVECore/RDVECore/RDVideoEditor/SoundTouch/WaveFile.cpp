
#include "WaveFile.h"
#include <cstdio>
#include <memory>
#include <stdlib.h>

//const
//class nullptr_t
//{
//public:
//    template<class T>
//    inline operator T*() const
//        { return 0; }
//
//    template<class C, class T>
//    inline operator T C::*() const
//        { return 0; }
//
//private:
//    void operator&() const;
//} nullptr = {};

bool CWaveFile::openFile( const char * szFileName )
{
	if ( m_hFile )
		return false;
	if ( szFileName == nullptr )
		return false;

	m_hFile	= fopen( szFileName, "rb" );
	if ( m_hFile == nullptr )
		return false;
	WAVEHEADER	waveHead		={ 0 };
	if ( 1 != fread( &waveHead, sizeof( WAVEHEADER ), 1, m_hFile ) )
		return false;

	DATA_BLOCK	datBlock		={ 0 };
	while ( 1 == fread( &datBlock, sizeof( DATA_BLOCK ), 1, m_hFile ) )
	{
		if ( datBlock.uDataID == MakeFourCC( 'f', 'm', 't', ' ' ) )
		{
			m_pWfxInfo	= (SWaveFormat*)realloc( m_pWfxInfo, datBlock.uDataSize + 32 );
			memset( m_pWfxInfo, 0, datBlock.uDataSize + 32 );
			if ( 1 != fread( m_pWfxInfo, datBlock.uDataSize, 1, m_hFile ) )
				return false;
		}
		else if ( datBlock.uDataID == MakeFourCC( 'd', 'a', 't', 'a' ) )
		{
			m_uWaveOffset	= ftell( m_hFile );
			fseek( m_hFile, datBlock.uDataSize, SEEK_CUR );
			m_uWaveSize		= datBlock.uDataSize;
		}
		else if ( datBlock.uDataID == MakeFourCC( 'L', 'I', 'S', 'T' ) )
		{
			fseek( m_hFile, datBlock.uDataSize, SEEK_CUR );
		}
	}
	fseek( m_hFile, m_uWaveOffset, SEEK_SET );
	m_uReadOffset	= 0;
	return m_uWaveOffset ? true : false;
}

bool CWaveFile::openFile( const char * szFileName, const SWaveFormat * pWfxInfo )
{
	if ( nullptr == pWfxInfo )
	{
		if ( !openFile( szFileName ) )
			return false;
		fclose( m_hFile );
		m_hFile	= fopen( szFileName, "ab" );
		fseek( m_hFile, m_uWaveOffset + m_uWaveSize, SEEK_SET );
	}
	else
	{
		m_hFile	= fopen( szFileName, "wb" );
		if ( m_hFile == nullptr )
			return false;
		uint32_t	uWfxSize	= sizeof( SWaveFormat ) + pWfxInfo->cbSize;
		m_pWfxInfo	= (SWaveFormat*)realloc( m_pWfxInfo, uWfxSize + 32 );
		memcpy( m_pWfxInfo, pWfxInfo, uWfxSize );
		uWfxSize	+= ( uWfxSize % 1 );
		m_uWaveOffset	= uWfxSize + sizeof( WAVEHEADER ) + sizeof( DATA_BLOCK ) * 2;
		m_uWaveSize	= 0;
		if ( !updateHead() )
			return false;
	}
	m_bIsWrite	= true;
	return true;
}

bool CWaveFile::updateHead()
{
	uint32_t	uOldTell		= ftell( m_hFile );
	uint32_t	uFileSize		= m_uWaveOffset + m_uWaveSize;
	WAVEHEADER	waveHead		={ 0 };

	waveHead.uRiff		= MakeFourCC( 'R', 'I', 'F', 'F' );
	waveHead.uSize		= uFileSize - 8;
	waveHead.uWave		= MakeFourCC( 'W', 'A', 'V', 'E' );

	fseek( m_hFile, 0, SEEK_SET );
	if ( 1 != fwrite( &waveHead, sizeof( WAVEHEADER ), 1, m_hFile ) )
		return false;

	DATA_BLOCK	datBlock		={ 0 };
	datBlock.uDataID	= MakeFourCC( 'f', 'm', 't', ' ' );
	datBlock.uDataSize	= sizeof( SWaveFormat ) + m_pWfxInfo->cbSize;
	datBlock.uDataSize	+= ( datBlock.uDataSize % 1 );
	if ( 1 != fwrite( &datBlock, sizeof( DATA_BLOCK ), 1, m_hFile ) )
		return false;
	if ( 1 != fwrite( m_pWfxInfo, datBlock.uDataSize, 1, m_hFile ) )
		return false;

	datBlock.uDataID	= MakeFourCC( 'd', 'a', 't', 'a' );
	datBlock.uDataSize	= m_uWaveSize;
	if ( 1 != fwrite( &datBlock, sizeof( DATA_BLOCK ), 1, m_hFile ) )
		return false;
	if ( uOldTell )
		fseek( m_hFile, uOldTell, SEEK_SET );

	return true;
}

void CWaveFile::closeFile()
{
	if ( m_hFile )
	{
		if ( m_bIsWrite )
		{
			updateHead();
		}
		fclose( m_hFile );
		m_hFile	= nullptr;
	}
	if ( m_pWfxInfo )
	{
		free( m_pWfxInfo );
		m_pWfxInfo	= nullptr;
	}
	m_bIsWrite	= false;
	m_uWaveOffset	= 0;
	m_uWaveSize		= 0;
	m_uReadOffset	= 0;
}

uint32_t CWaveFile::readSamples( uint32_t uCount, void * pData )
{
	if ( nullptr == m_hFile || m_bIsWrite || nullptr == pData || uCount == 0 )
		return 0;
	if ( m_uReadOffset + uCount * m_pWfxInfo->nBlockAlign > m_uWaveSize )
	{
		uCount	= ( m_uWaveSize - m_uReadOffset ) / m_pWfxInfo->nBlockAlign;
	}
	m_uReadOffset	+= uCount * m_pWfxInfo->nBlockAlign;
	return fread( pData, m_pWfxInfo->nBlockAlign, uCount, m_hFile );
}

bool CWaveFile::appendSamples( uint32_t uCount, const void * pData )
{
	if ( nullptr == m_hFile || !m_bIsWrite || ( nullptr == pData && uCount != 0 ) )
		return false;
	if ( uCount != fwrite( pData, m_pWfxInfo->nBlockAlign, uCount, m_hFile ) )
		return false;
	m_uWaveSize	+= uCount * m_pWfxInfo->nBlockAlign;
	return true;
}

bool CWaveFile::seekToSecond( double dSecond )
{
	if ( nullptr == m_hFile || m_bIsWrite || dSecond < 0 )
		return false;
	m_uReadOffset	= m_pWfxInfo->nBlockAlign * uint32_t( m_pWfxInfo->nSamplesPerSec * dSecond );
	fseek( m_hFile, m_uWaveOffset + m_uReadOffset, SEEK_SET );
	return true;
	
}
