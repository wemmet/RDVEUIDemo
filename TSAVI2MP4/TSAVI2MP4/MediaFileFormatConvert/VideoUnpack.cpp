//
//  VideoUnpack.cpp
//  MP4v2
//
//  Created by 周晓林 on 2017/9/13.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#include "VideoUnpack.hpp"
#include "Timer.h"
CBaseContainer* CreateMp4Container();
CVideoUnpack::CVideoUnpack(void)
{
    m_szOutFilePath	= NULL;
    m_uOutNameSize	= 0;
    m_pFileBuffer	= NULL;
    m_uBufSize		= 0;
    m_uBufAlloc		= 0;
    m_uBufOffset	= 0;
    m_uFilePos      = 0;
    m_hasAudio      = true;
    m_outFile		= CreateMp4Container();
}

CVideoUnpack::~CVideoUnpack(void)
{
    if ( m_szOutFilePath ) free( m_szOutFilePath );
    if ( m_pFileBuffer ) free( m_pFileBuffer );
}


/**
 * params:szInpFilePath 源文件路径
 * params:szOutFilePath 输出文件路径
 * params:hasAudio 是否需要音频
 */
bool CVideoUnpack::Unpack( const char* szInpFilePath, const char* szOutFilePath ,bool hasAudio)
{

  
    m_hasAudio = hasAudio;
    m_uOutNameSize	= (uint32_t)strlen( szOutFilePath );
    m_szOutFilePath	= (char*)malloc( ( m_uOutNameSize + 100 ) * 2 );
    memcpy( m_szOutFilePath, szOutFilePath, ( m_uOutNameSize + 1 ) * 2 );
    memset( &m_videoParam, 0, sizeof( m_videoParam ) );
    memset( &m_audioParam, 0, sizeof( m_audioParam ) );
    
    m_inFile.open( szInpFilePath, ios::in | ios_base::binary );
    if ( !m_inFile.is_open() )
    {
        if ( m_szOutFilePath ) free( m_szOutFilePath );
        return false;
    }
    m_inFile.seekg( 0, ios::end );
    m_uFileSize        = m_inFile.tellg();
    m_inFile.seekg( 0, ios::beg );
    
    bool    bSucc    = OnUnpack( m_uFileSize );
    
    m_outFile->CloseFile();
    
    m_inFile.close();
    if ( m_szOutFilePath ) free( m_szOutFilePath );
    m_szOutFilePath	= NULL;
    if ( m_pFileBuffer ) free( m_pFileBuffer );
    m_pFileBuffer	= NULL;
    m_uBufSize		= 0;
    m_uBufAlloc		= 0;
    m_uBufOffset	= 0;
    return bSucc;
}

uint8_t* CVideoUnpack::Read( uint32_t uSize )
{
    if ( uSize + m_uBufOffset > m_uBufSize )	//���������ݲ���
    {
        if ( m_pFileBuffer && m_uBufOffset )
        {
            m_uBufSize		-= m_uBufOffset;
            if ( m_uBufSize ) memmove( m_pFileBuffer, m_pFileBuffer + m_uBufOffset, m_uBufSize );
            m_uBufOffset	= 0;
        }
        if ( uSize > m_uBufAlloc )	//�����Ҫ�����ݳ��ȳ����˻�������С������չ������
        {
            m_uBufAlloc		= ( uSize + ( 1024 * 1024 - 1 ) ) / ( 1024 * 1024 ) * ( 1024 * 1024 );
            m_pFileBuffer	= ( uint8_t*)realloc( m_pFileBuffer, m_uBufAlloc );
            if ( m_pFileBuffer == NULL ) return NULL;
        }
        size_t	siNeed	= m_uBufAlloc - m_uBufSize;
        m_inFile.read( (char*)m_pFileBuffer + m_uBufSize, siNeed );
        size_t	siRead	= (size_t)m_inFile.gcount();
        m_uFilePos = m_inFile.tellg();
        if ( siRead == 0 ) return NULL;
        m_uBufSize	+= siRead;
    }
    m_uBufOffset	+= uSize;
    return m_pFileBuffer + m_uBufOffset - uSize;
}

bool CVideoUnpack::Seek( int64_t iSeek )
{
    m_inFile.seekg( iSeek, ios::beg );
    m_uBufOffset	= 0;
    m_uBufSize		= 0;
    return true;
}
