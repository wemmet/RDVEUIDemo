//
//  Mp4Container.cpp
//  MP4v2
//
//  Created by 周晓林 on 2017/9/13.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#include "Mp4Container.hpp"
#include <stdio.h>
CBaseContainer* CreateMp4Container()
{
    return new CMp4Container;
}

CMp4Container::CMp4Container( void )
{
    m_hMP4            = NULL;
    m_uTimeScale    = 90000;
    m_bIsSubsection = false;
    m_bIsClose = true;
    
    for ( int i = 0; i < 3; i++ )
    {
        m_nal[i].p_payload = NULL;
    }
    
    m_TrackVideoId    = 0;
    m_TrackAudioId    = 0;
    
#if _MP4WRITE_CACHE_MAX_SIZE
    m_uCacheMax        = _MP4WRITE_CACHE_MAX_SIZE;
    m_pWriteCache    = 0;
    m_pWriteCache2    = NULL;
    m_uCacheSize    = 0;
    m_pThreadWrite    = NULL;
    m_pCacheList    = NULL;
    m_pCacheList2    = NULL;
#endif
}

CMp4Container::~CMp4Container(void)
{
}

bool CMp4Container::OpenFile( const char* szFilePath, int64_t iSplitSize )
{
    m_csWrite.lock();
    m_iSplitSize    = iSplitSize >= 0 ? iSplitSize : 0;
    m_bIsSubsection    = m_iSplitSize ? true : false;
    if(  m_iSplitSize > 0 ) m_CstrFilePath.append( szFilePath );
    m_hMP4    = MP4Create(szFilePath , 0 );
    if ( m_hMP4 )
    {
        m_bOpened    = true;
    }
    m_csWrite.unlock();
    
#if _MP4WRITE_CACHE_MAX_SIZE
    m_pWriteCache    = new uint8_t[m_uCacheMax];
    m_pWriteCache2    = new uint8_t[m_uCacheMax];
    m_uCacheSize    = 0;
    m_pCacheList    = new vector<SMp4Write*>;
    m_pCacheList2    = new vector<SMp4Write*>;
    
    m_prom    = promise<bool>();
    m_futu    = m_prom.get_future();
    m_pThreadWrite    = new thread( ThreadWrite, this );
#endif
    return m_bOpened;
}
//
//bool CMp4Container::SetParam( x264_param_t *p_param, SAudioParams* pAudFmt )
//{
//    if ( !MP4SetTimeScale( m_hMP4, m_uTimeScale ) )
//    {
//        return false;
//    }
//    MP4SetVideoProfileLevel( m_hMP4, 0x7F );    //0x0F?
//    MP4SetAudioProfileLevel( m_hMP4, 0x0F );
//    if ( p_param )
//    {
//    }
//
//    if ( pAudFmt )
//    {
//        m_sAudioParams    = *pAudFmt;
//    }
//    return true;
//}
//
bool CMp4Container::WriteHeaders( x264_nal_t *p_nal )
{
    if( m_bIsSubsection )
    {
        for ( int i = 0; i < 3 ; i++ )
        {
            m_bIsSubsection = false;
            m_nal[i].i_ref_idc = p_nal[i].i_ref_idc;
            m_nal[i].i_type = p_nal->i_type;
            m_nal[i].b_long_startcode = p_nal[i].b_long_startcode;
            m_nal[i].i_first_mb = p_nal[i].i_first_mb;
            m_nal[i].i_last_mb = p_nal[i].i_last_mb;
            m_nal[i].i_payload = p_nal[i].i_payload;
            
            void * dp = realloc( m_nal[i].p_payload, p_nal[i].i_payload+1 );
            if ( !dp )
            {
                return false;
            }
            
            m_nal[i].p_payload = (uint8_t*)dp;
            memset( m_nal[i].p_payload, 0, p_nal[i].i_payload+1 );
            memcpy( m_nal[i].p_payload, p_nal[i].p_payload, p_nal[i].i_payload );
            
            m_nal[i].i_padding = p_nal[i].i_padding;
        }
    }
    bool    bRet    = false;
    //SYSTEMTIME    sTime;
    //GetLocalTime( &sTime );
    //FILETIME    fTime;
    //SystemTimeToFileTime( &sTime, &fTime );
    m_csWrite.lock();
    MP4SetTimeScale( m_hMP4, m_uTimeScale );
    if ( m_videoParams.bHasVideo )
    {
        if ( p_nal && m_videoParams.eCodec == VC_H264 )
        {
            int sps_size = 0;
            int pps_size = 0;
            int sei_size = 0;
            uint8_t *sps = NULL;
            uint8_t *pps = NULL;
            uint8_t *sei = NULL;
            extractSpsPps( p_nal, sps_size, pps_size, sei_size, sps, pps, sei );
            
            m_TrackVideoId    = MP4AddH264VideoTrack( m_hMP4, m_uTimeScale,
                                                     uint64_t( m_uTimeScale / m_videoParams.fFrameRate ),
                                                     m_videoParams.iWidth, m_videoParams.iHeight,
                                                     sps[1],
                                                     sps[2],
                                                     sps[3],
                                                     3 );
            MP4SetVideoProfileLevel( m_hMP4, 1 );
            MP4AddH264SequenceParameterSet( m_hMP4, m_TrackVideoId, sps, sps_size );
            MP4AddH264PictureParameterSet( m_hMP4, m_TrackVideoId, pps, pps_size );
            bRet    = true;
        }
        else
        {
            uint32_t    uCodec    = MP4_INVALID_VIDEO_TYPE;
            if ( m_videoParams.eCodec == VC_XVID )
                uCodec    = MP4_MPEG4_VIDEO_TYPE;
            else if ( m_videoParams.eCodec == VC_DIVX )
                uCodec    = MP4_MPEG4_VIDEO_TYPE;
            else if ( m_videoParams.eCodec == VC_MPG1 )
                uCodec    = MP4_MPEG1_VIDEO_TYPE;
            else if ( m_videoParams.eCodec == VC_MPG2 )
                uCodec    = MP4_MPEG2_VIDEO_TYPE;
            else
                return false;
            m_TrackVideoId    = MP4AddVideoTrack( m_hMP4, m_uTimeScale,
                                                 uint64_t( m_uTimeScale / m_videoParams.fFrameRate ),
                                                 m_videoParams.iWidth, m_videoParams.iHeight, uCodec );
            MP4SetVideoProfileLevel( m_hMP4, 1 );
            bRet    = true;
        }
    }
    
    if ( m_audioParams.bHasAudio )
    {
        uint32_t    uAudioType    = MP4_INVALID_AUDIO_TYPE;
        switch ( m_audioParams.eCodec )
        {
            case AC_AAC:
                uAudioType    = MP4_MPEG4_AUDIO_TYPE;
                break;
            case AC_PCM:
                uAudioType    = MP4_PCM16_BIG_ENDIAN_AUDIO_TYPE;
                break;
            case AC_MP3:
                uAudioType    = MP4_MP3_AUDIO_TYPE;
                break;
            case AC_AC3:
                uAudioType    = 0x2000; // MP4_AC3_AUDIO_TYPE;
                break;
            case AC_DTS:
                uAudioType    = MP4_PRIVATE_AUDIO_TYPE;
                break;
            case AC_MP2AAC:
                uAudioType    = MP4_MPEG2_AAC_AUDIO_TYPE;
                break;
        }
        
        m_TrackAudioId    = MP4AddAudioTrack( m_hMP4, m_audioParams.nSamplesPerSec,
                                             m_audioParams.uEncSamples / m_audioParams.nChannels, uAudioType );
        MP4SetAudioProfileLevel( m_hMP4, 2 );
        if ( m_audioParams.wESConfigSize ) MP4SetTrackESConfiguration( m_hMP4, m_TrackAudioId, m_audioParams.chMp3Info, m_audioParams.wESConfigSize );
        bRet    = true;
    }
    
    m_csWrite.unlock();
    m_bHeadWriteDone    = true;
    return bRet;
}

bool CMp4Container::WriteFrame( uint8_t *p_nal, uint32_t i_size, int64_t i_pts, int64_t i_dts )
{
    bool    bRet    = false;
    m_csWrite.lock();
    if ( m_hMP4 && m_videoParams.bHasVideo )
    {
        if ( !m_bHeadWriteDone )
        {
            if ( m_videoParams.eCodec == VC_H264 )
                m_bHeadWriteDone    = extractHead( p_nal, i_size );
            else
                m_bHeadWriteDone    = WriteHeaders( NULL );
        }
        CBaseContainer::WriteFrame( p_nal, i_size, i_pts, i_dts );
        uint64_t    iDuration    = uint64_t( double( m_iLastFrameId - m_iPrevFrameId ) * m_dTimeBase * m_uTimeScale );
        bool        bIsKeyFrame    = true;
        if ( m_videoParams.eCodec == VC_H264 )
        {
            bIsKeyFrame    = ( m_eFrameType == NAL_SLICE_IDR ) ? true : false;
            if ( m_videoParams.bAnnexb == false )
            {
                MyMP4WriteSample( m_hMP4, m_TrackVideoId, p_nal, i_size, iDuration, 0, bIsKeyFrame );
            }
            else
            {
                uint8_t*    pFrame    = NULL;
                uint8_t*    pData    = p_nal;
                uint8_t*    pEnd    = p_nal + i_size;
                uint8_t        eType    = 0;
                uint32_t    uSize    = 0;
                while ( pData < pEnd )
                {
                    if ( pData[0] == 0 && pData[1] == 0 )
                    {
                        if ( pData[2] == 1 )
                        {
                            if ( pFrame ) uSize    = pData - pFrame;
                            pData    += 3;
                        }
                        else if ( pData[2] == 0 && pData[3] == 1 )
                        {
                            if ( pFrame ) uSize    = pData - pFrame;
                            pData    += 4;
                        }
                        else
                        {
                            ++pData;
                            continue;
                        }
                        if ( pFrame )
                        {
                            m_eFrameType    = nal_unit_type_e( pFrame[0] & 0x0F );
                            bIsKeyFrame    = ( m_eFrameType == NAL_SLICE_IDR ) ? true : false;
                            if ( m_eFrameType == NAL_SLICE || m_eFrameType == NAL_SLICE_IDR )
                            {
                                putBE32( uSize );
                                appendData( pFrame, uSize );
                                MyMP4WriteSample( m_hMP4, m_TrackVideoId, m_pCache, m_uCurPos, iDuration, 0, bIsKeyFrame );
                            }
                            else if ( m_eFrameType != NAL_AUD &&
                                     m_eFrameType != NAL_SPS &&
                                     m_eFrameType != NAL_PPS &&
                                     m_eFrameType != NAL_SEI )
                            {
                                putBE32( uSize );
                                appendData( pFrame, uSize );
                                MyMP4WriteSample( m_hMP4, m_TrackVideoId, m_pCache, m_uCurPos, 0, 0, bIsKeyFrame );
                            }
                            else
                            {
                                //putBE32( uSize );
                                //appendData( pFrame, uSize );
                                //MyMP4WriteSample( m_hMP4, m_TrackVideoId, m_pCache, m_uCurPos, 0, 0, bIsKeyFrame );
                            }
                            m_iTotal += m_uCurPos;
                            m_uCurPos    = 0;
                        }
                        pFrame    = pData;
                        eType    = pData[0];
                        continue;
                    }
                    ++pData;
                }
                if ( pFrame && pData != pFrame )
                {
                    uSize    = pData - pFrame;
                    m_eFrameType    = nal_unit_type_e( pFrame[0] & 0x0F );
                    bIsKeyFrame    = ( m_eFrameType == NAL_SLICE_IDR ) ? true : false;
                    putBE32( uSize );
                    appendData( pFrame, uSize );
                    if ( m_eFrameType == NAL_SLICE || m_eFrameType == NAL_SLICE_IDR )
                    {
                        MyMP4WriteSample( m_hMP4, m_TrackVideoId, m_pCache, m_uCurPos, iDuration, 0, bIsKeyFrame );
                    }
                    else if ( m_eFrameType != NAL_AUD &&
                             m_eFrameType != NAL_SPS &&
                             m_eFrameType != NAL_PPS &&
                             m_eFrameType != NAL_SEI )
                    {
                        MyMP4WriteSample( m_hMP4, m_TrackVideoId, m_pCache, m_uCurPos, 0, 0, bIsKeyFrame );
                    }
                    m_iTotal += m_uCurPos;
                    m_uCurPos    = 0;
                }
            }
        }
        else
        {
            MyMP4WriteSample( m_hMP4, m_TrackVideoId, p_nal, i_size, iDuration, 0, bIsKeyFrame );
        }
        
        if( m_iSplitSize > 0 )
        {
            if( bIsKeyFrame )
            {
                m_I_Space_AverageSize.StatisticsDataSize( i_size, true);
                if( m_iSplitSize <= (m_iTotal + m_I_Space_AverageSize.AverageValue()) )
                {
                    //ÕºœÒ ˝æ›
                    if( m_I_FrameData.p_nal != NULL )
                    {
                        delete []  m_I_FrameData.p_nal;
                        m_I_FrameData.p_nal = NULL;
                    }
                    m_I_FrameData.p_nal = new uint8_t[i_size+1];
                    memset( m_I_FrameData.p_nal, 0, i_size+1 );
                    memcpy( m_I_FrameData.p_nal, p_nal, i_size );
                    
                    m_I_FrameData.i_dts = i_dts;
                    m_I_FrameData.i_pts = i_pts;
                    m_I_FrameData.i_size = i_size;
                    Subsection();
                }
            }
            m_I_Space_AverageSize.StatisticsDataSize( i_size );
        }
        bRet    = true;
    }
    m_csWrite.unlock();
    return bRet;
}

bool CMp4Container::WriteAudio( int64_t dts, uint8_t *pData, uint32_t iSize )
{
    bool    bRet    = true;
    m_csWrite.lock();
    if ( m_hMP4 && m_audioParams.bHasAudio )
    {
        if ( !m_bHeadWriteDone )
        {
            if ( m_videoParams.eCodec == VC_H264 )
                return false;
            else
                m_bHeadWriteDone    = WriteHeaders( NULL );
        }
        if ( CBaseContainer::WriteAudio( dts, pData, iSize ) )
        {
            bRet    = MyMP4WriteSample( m_hMP4, m_TrackAudioId, pData, iSize );
            m_iTotal += iSize;
            m_I_Space_AverageSize.StatisticsDataSize( iSize );
        }
    }
    m_csWrite.unlock();
    return bRet;
}

bool CMp4Container::CloseFile()
{
    bool    bRet    = false;
    
#if _MP4WRITE_CACHE_MAX_SIZE
    m_muSwapCache.lock();
    m_prom.set_value( false );
    m_muSwapCache.unlock();
    
    if ( m_pThreadWrite )
    {
        m_pThreadWrite->join();
        delete m_pThreadWrite;
        m_pThreadWrite    = NULL;
        delete    m_pCacheList;
        delete    m_pCacheList2;
        m_pCacheList    = NULL;
        m_pCacheList2    = NULL;
        
        delete    []m_pWriteCache;
        delete    []m_pWriteCache2;
        m_pWriteCache    = NULL;
        m_pWriteCache2    = NULL;
        m_uCacheSize    = 0;
    }
#endif
    
    m_csWrite.lock();
    if ( m_hMP4 )
    {
        MP4Close( m_hMP4 );
        m_hMP4    = 0;
        m_uTimeScale = 90000;
        m_TrackVideoId    = 0;
        m_TrackAudioId    = 0;
        bRet    = true;
        
    }
    
    if( m_bIsClose )
    {
        if( m_I_FrameData.p_nal != NULL )
        {
            delete []  m_I_FrameData.p_nal;
            m_I_FrameData.p_nal = NULL;
        }
        for ( int  i = 0; i < 3; i++ )
        {
            free( m_nal[i].p_payload );
            
        }
    }
    else
        m_bIsClose = true;
    
    
    m_csWrite.unlock();
    CBaseContainer::CloseFile();
    return bRet;
}

void CMp4Container::Subsection()
{
//    m_bIsClose = false;
//    CloseFile();
//    m_iLastFrameId = 0;
//    m_iPrevFrameId = 0;
//    m_VolumeNumber++;
//    
//    wchar_t*    pNewPath    = (wchar_t*)malloc( ( m_CstrFilePath.length() + 100 ) * 2 );
//    int32_t        iExName        = m_CstrFilePath.find_last_of( '.' );
//    if ( iExName > m_CstrFilePath.find_last_of( '\\' ) )
//    {
//        memcpy( pNewPath, m_CstrFilePath.c_str(), iExName * 2 );
//        _itow_s( m_VolumeNumber, pNewPath + iExName, 30, 10 );
//        wcscat_s( pNewPath, ( m_CstrFilePath.length() + 100 ) * 2, m_CstrFilePath.c_str() + iExName );
//    }
//    else
//    {
//        memcpy( pNewPath, m_CstrFilePath.c_str(), m_CstrFilePath.length() * 2 );
//        _itow_s( m_VolumeNumber, pNewPath + m_CstrFilePath.length(), 30, 10 );
//    }
//    
//    m_csWrite.lock();
//    wstring_convert<codecvt_utf8<wchar_t>> converter;
//    m_hMP4    = MP4Create( converter.to_bytes( pNewPath ).c_str(), 0 );
//    if ( m_hMP4 )
//    {
//        m_bOpened    = true;
//    }
//    free( pNewPath );
//    
//    WriteHeaders( m_nal );
//    
//    WriteFrame( m_I_FrameData.p_nal,m_I_FrameData.i_size, m_I_FrameData.i_pts, m_I_FrameData.i_dts );
//    
//    m_csWrite.unlock();
}
#if _MP4WRITE_CACHE_MAX_SIZE
bool CMp4Container::MyMP4WriteSample(
                                     MP4FileHandle  hFile,
                                     MP4TrackId     trackId,
                                     const uint8_t* pBytes,
                                     uint32_t       numBytes,
                                     MP4Duration    duration,
                                     MP4Duration    renderingOffset,
                                     bool           isSyncSample )
{
    uint32_t    uSize    = numBytes + sizeof( SMp4Write );
    if ( uSize + m_uCacheSize > m_uCacheMax )
    {
        m_muSwapCache.lock();
        vector<SMp4Write*>*   pSwapList    = m_pCacheList;
        m_pCacheList    = m_pCacheList2;
        m_pCacheList2    = pSwapList;
        uint8_t*            pSwapCache    = m_pWriteCache;
        m_pWriteCache    = m_pWriteCache2;
        m_pWriteCache2    = pSwapCache;
        m_uCacheSize    = 0;
        m_prom.set_value( true );
        m_muSwapCache.unlock();
    }
    SMp4Write*    pCache    =  (SMp4Write*)( m_pWriteCache + m_uCacheSize );
    pCache->trackId        = trackId;
    pCache->uDuration    = duration;
    pCache->uDataSize    = numBytes;
    pCache->bIsKeyFrame    = isSyncSample;
    memcpy( pCache->datas, pBytes, numBytes );
    m_uCacheSize    += uSize;
    m_pCacheList->push_back( pCache );
    return true;
}

void CMp4Container::ThreadWrite( CMp4Container *pThis )
{
    while ( pThis->m_futu.get() )
    {
        pThis->m_muSwapCache.lock();
        pThis->m_prom    = promise<bool>();
        pThis->m_futu    = pThis->m_prom.get_future();
        for ( int32_t i = 0; i < pThis->m_pCacheList2->size(); ++i )
        {
            SMp4Write*    pWrite    = pThis->m_pCacheList2->at( i );
            MP4WriteSample( pThis->m_hMP4, pWrite->trackId, pWrite->datas, pWrite->uDataSize, pWrite->uDuration, 0, pWrite->bIsKeyFrame );
        }
        pThis->m_pCacheList2->clear();
        pThis->m_muSwapCache.unlock();
    }
    
    for ( int32_t i = 0; i < pThis->m_pCacheList->size(); ++i )
    {
        SMp4Write*    pWrite    = pThis->m_pCacheList->at( i );
        MP4WriteSample( pThis->m_hMP4, pWrite->trackId, pWrite->datas, pWrite->uDataSize, pWrite->uDuration, 0, pWrite->bIsKeyFrame );
    }
}
#endif
