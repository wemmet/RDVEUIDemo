//
//  AviUnpack.cpp
//  MP4v2
//
//  Created by 周晓林 on 2017/9/14.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#include "AviUnpack.hpp"
#define min(a,b) ((a)<(b)?(a):(b))
CAviUnpack::CAviUnpack(void)
{
    memset( m_sLayer, 0, sizeof( m_sLayer ) );
    m_uRiffIndex	= 0;
    m_uTrackCount	= 0;
    m_aviTrack		= NULL;
    m_iFrameInd		= 0;
    memset( m_uTrackOfType, 0, sizeof( m_uTrackOfType ) );
}

CAviUnpack::~CAviUnpack(void)
{
    if ( m_aviTrack ) delete []m_aviTrack;
}

bool CAviUnpack::OnUnpack( uint64_t uSize )
{
    uint64_t	uRead	= AnalyseData( m_sLayer, uSize, 0 );
    m_uTrackCount	= 0;
    if ( m_aviTrack ) delete []m_aviTrack;
    m_aviTrack		= NULL;
    memset( m_uTrackOfType, 0, sizeof( m_uTrackOfType ) );
    m_uRiffIndex	= 0;
    m_iFrameInd		= 0;
    return m_outFile->isValid();
}

uint64_t CAviUnpack::AnalyseData( SRiffList* pList, uint64_t uSize, uint32_t uType )
{
#define FromHex(n)	( ((n) >= 'A' && (n) <= 'F') ? ((n) + 10 - 'A') : ( ((n) >= '0' && (n) <= '9') ? (n) - '0' : -1 ) )
    
    uint64_t	uRead	= 0;
    uint8_t*	pRead	= NULL;
    STrackInfo*	pTrack	= NULL;
    if ( uType == FCC('strl') )
    {
        pTrack	= m_aviTrack + m_uTrackCount;
        memset( pTrack, 0, sizeof( STrackInfo ) );
        ++m_uTrackCount;
    }
    else if ( uType == FCC( 'movi' ) )
    {
        if ( !m_outFile->isValid() )
        {
            if ( m_videoParam.bHasVideo == false && m_audioParam.bHasAudio == false )
            {
                return -1;
            }
            bool bOldHasAudio = m_audioParam.bHasAudio;
            m_audioParam.bHasAudio = m_hasAudio ? bOldHasAudio : false;
            m_outFile->SetParam( &m_videoParam, &m_audioParam );
            m_audioParam.bHasAudio = bOldHasAudio;
            if ( !m_outFile->OpenFile( m_szOutFilePath, 0 ) )
            {
                return -1;
            }
        }
    }
    
    while( uRead < uSize )
    {
        memset( pList, 0, sizeof( SRiffList ) );
        if ( ( pRead = Read( sizeof( uint32_t ) ) ) == NULL ) break;
        uRead			+= sizeof( uint32_t );
        pList->dwChunk	= *((uint32_t*)pRead);
        
        if ( pList->dwChunk == FCC('RIFF' ) || pList->dwChunk == FCC('LIST' ) )
        {
            if ( ( pRead = Read( sizeof( uint32_t ) ) ) == NULL ) break;
            uRead			+= sizeof( uint32_t );
            pList->dwSize	= *((uint32_t*)pRead);
            if ( pList->dwSize % 2 )
            {
                ++pList->dwSize;
            }
            
            if ( ( pRead = Read( sizeof( uint32_t ) ) ) == NULL ) break;
            uRead			+= sizeof( uint32_t );
            pList->dwType	= *((uint32_t*)pRead);
            if ( pList->dwChunk == FCC('RIFF' ) )
            {
                ++m_uRiffIndex;
                //for ( int32_t i = 0; i < m_uTrackCount; ++i )
                //{
                //	if ( m_aviTrack[i].hFile ) fclose( m_aviTrack[i].hFile );
                //}
                //m_uTrackCount	= 0;
                //if ( m_aviTrack ) delete []m_aviTrack;
                //m_aviTrack		= NULL;
                //memset( m_uTrackOfType, 0, sizeof( m_uTrackOfType ) );
            }
            uRead			+= AnalyseData( pList + 1, pList->dwSize, pList->dwType );
        }
        else
        {
            if ( ( pRead = Read( sizeof( uint32_t ) ) ) == NULL ) break;
            uRead			+= sizeof( uint32_t );
            pList->dwSize	= *((uint32_t*)pRead);
            if ( ( pRead = Read( pList->dwSize ) ) == NULL ) break;
            uRead			+= pList->dwSize;
            if ( pList->dwSize % 2 )
            {
                if ( Read( 1 ) == NULL ) break;
                ++uRead;
            }
            if ( uType == FCC('hdrl' ) && pList->dwChunk == FCC('avih' ) )
            {
                m_aviMainHead.fcc	= pList->dwChunk;
                m_aviMainHead.cb	= min( sizeof( AVIMAINHEADER ) - sizeof( uint32_t ) * 2, pList->dwSize );
                memcpy( ((uint32_t*)&m_aviMainHead ) + 2, pRead, m_aviMainHead.cb );
                m_aviTrack		= new STrackInfo[m_aviMainHead.dwStreams];
                memset( m_aviTrack, 0, sizeof( STrackInfo ) * m_aviMainHead.dwStreams );
                m_uTrackCount	= 0;
            }
            else if ( uType == FCC('strl' ) )
            {
                if ( pList->dwChunk == FCC('strh' ) )
                {
                    pTrack->aviStream.fcc	= pList->dwChunk;
                    pTrack->aviStream.cb	= min( sizeof( AVISTREAMHEADER ) - sizeof( uint32_t ) * 2, pList->dwSize );
                    memcpy( ((uint32_t*)&pTrack->aviStream ) + 2, pRead, pTrack->aviStream.cb );
                }
                else if ( pList->dwChunk == FCC('strf' ) )
                {
                    //������Ƶ BITMAPINFOHEADER ����Ƶ WAVEFORMATEX �� union �ģ����Բ���Ҫ�ֱ� copy.
                    memcpy( &pTrack->bitmapInfo, pRead, min( sizeof( SBitmapInfoHeader ), pList->dwSize ) );
                    EMediaType		eTrackType	= eMedTypeVideo;
                    CBaseContainer::EVideoCodec	eCodec	= CBaseContainer::VC_UNKNOW;
                    if ( pTrack->aviStream.fccType == streamtypeVIDEO )
                    {
                        char*	szFcc = (char*)&pTrack->aviStream.fccHandler;
                        if ( strncasecmp( szFcc, "H264", 4 ) == 0 || strncasecmp( szFcc, "X264", 4 ) == 0 )
                        {
                            eCodec	= CBaseContainer::VC_H264;
                        }
                        else if ( strncasecmp( szFcc, "xvid", 4 ) == 0 )
                        {
                            eCodec	= CBaseContainer::VC_XVID;
                        }
                        else if ( strncasecmp( szFcc, "mpg1", 4 ) == 0 )
                        {
                            eCodec	= CBaseContainer::VC_MPG1;
                        }
                        else if ( strncasecmp( szFcc, "mpg2", 4 ) == 0 )
                        {
                            eCodec	= CBaseContainer::VC_MPG2;
                        }
                        else if ( strncasecmp( szFcc, "FMP4", 4 ) == 0 )
                        {
                            eCodec	= CBaseContainer::VC_XVID;
                        }
                        if ( eCodec && m_videoParam.bHasVideo == false )
                        {
                            pTrack->bEnabled	= true;
                            m_videoParam.eCodec		= eCodec;
                            m_videoParam.bAnnexb	= true;
                            m_videoParam.bHasVideo	= true;
                            m_videoParam.fFrameRate	= float( pTrack->aviStream.dwRate ) / float( pTrack->aviStream.dwScale );
                            m_videoParam.iBFrames	= 0;
                            m_videoParam.iBFramePyramid	= 0;
                            m_videoParam.iWidth		= m_aviMainHead.dwWidth;
                            m_videoParam.iHeight	= m_aviMainHead.dwHeight;
                        }
                        eTrackType	= eMedTypeVideo;
                    }
                    else if ( pTrack->aviStream.fccType == streamtypeAUDIO )
                    {
                        bool			bAdts	= false;
                        CBaseContainer::EAudioCodec	eCodec	= CBaseContainer::AC_UNKNOW;
                        switch( pTrack->waveFormat.wFormatTag )
                        {
                            case WAVE_FORMAT_DTS:
                                eCodec	= CBaseContainer::AC_DTS;
                                break;
                            case WAVE_FORMAT_MPEG:
                                eCodec	= CBaseContainer::AC_MP3;
                                break;
                            case WAVE_FORMAT_MPEGLAYER3:
                                eCodec	= CBaseContainer::AC_MP3;
                                break;
                            case WAVE_FORMAT_MPEG_ADTS_AAC:
                            case WAVE_FORMAT_NOKIA_MPEG_ADTS_AAC:
                            case WAVE_FORMAT_VODAFONE_MPEG_ADTS_AAC:
                            case 0xFF:
                                bAdts	= true;
                            case WAVE_FORMAT_MPEG_RAW_AAC:
                            case WAVE_FORMAT_NOKIA_MPEG_RAW_AAC:
                            case WAVE_FORMAT_VODAFONE_MPEG_RAW_AAC:
                                eCodec	= CBaseContainer::AC_AAC;
                                break;
                            case WAVE_FORMAT_PCM:
                            case WAVE_FORMAT_IEEE_FLOAT:
                                eCodec	= CBaseContainer::AC_PCM;
                                break;
                            case WAVE_FORMAT_DVM:
                                eCodec	= CBaseContainer::AC_AC3;
                                break;
                            default:
                                break;
                        }
                        eTrackType	= eMedTypeAudio;
                        
                        if ( eCodec && m_audioParam.bHasAudio == false )
                        {
                            pTrack->bEnabled	= true;
                            m_audioParam.bHasAudio	= true;
                            m_audioParam.iBitrate	= 0;
                            m_audioParam.nBitsPerSample	= pTrack->waveFormat.wBitsPerSample;
                            m_audioParam.nChannels		= pTrack->waveFormat.nChannels;
                            m_audioParam.nSamplesPerSec	= pTrack->waveFormat.nSamplesPerSec;
                            m_audioParam.eCodec			= eCodec;
                            if ( eCodec == CBaseContainer::AC_AAC )
                            {
                                m_audioParam.bUseAdts		= bAdts;
                                m_audioParam.uEncSamples	= 1024 * m_audioParam.nChannels;
                                if ( pTrack->waveFormat.cbSize == 2 )
                                {
                                    m_audioParam.wESConfigSize		= pTrack->waveFormat.cbSize;
                                    memcpy( m_audioParam.chAacDecoderInfo, ( ( &pTrack->waveFormat ) + 1 ), m_audioParam.wESConfigSize );
                                }
                                else
                                {
                                    uint32_t	AAC_Sampling_Frequency_Table[16] =
                                    { 96000, 88200, 64000, 48000, 44100, 32000, 24000, 22050, 16000, 12000, 11025, 8000, 7350, 0, 0, 0 };
                                    uint32_t	uSampIndex	= 0;
                                    while ( uSampIndex < 14 )
                                    {
                                        if ( AAC_Sampling_Frequency_Table[uSampIndex] == m_audioParam.nSamplesPerSec ) break;
                                        ++uSampIndex;
                                    }
                                    if ( uSampIndex >= 14 ) uSampIndex = 4;
                                    m_audioParam.wESConfigSize	= 2;
                                    uint16_t	wAacDecoderInfo	= ( LOW ) << 11 | uSampIndex << 7 | m_audioParam.nChannels << 3;
                                    m_audioParam.chAacDecoderInfo[0]	= ( wAacDecoderInfo >> 8 );
                                    m_audioParam.chAacDecoderInfo[1]	= ( wAacDecoderInfo & 0xFF );
                                }
                            }
                            else if ( eCodec == CBaseContainer::AC_MP3 )
                            {
                                m_audioParam.wESConfigSize	= pTrack->waveFormat.cbSize;
                                memcpy( m_audioParam.chMp3Info, ( ( &pTrack->waveFormat ) + 1 ), m_audioParam.wESConfigSize );
                                m_audioParam.uEncSamples	= 1152 * m_audioParam.nChannels;	//mp3 ÿ֡��Ϊ1152���ֽ�
                            }
                            else if ( eCodec == CBaseContainer::AC_AC3 )
                            {
                                m_audioParam.wESConfigSize	= pTrack->waveFormat.cbSize;
                                memcpy( m_audioParam.chMp3Info, ( ( &pTrack->waveFormat ) + 1 ), m_audioParam.wESConfigSize );
                                m_audioParam.uEncSamples	= 1152 * m_audioParam.nChannels;	//mp3 ÿ֡��Ϊ1152���ֽ�
                            }
                            else if ( eCodec == CBaseContainer::AC_PCM )
                            {
                                if ( pTrack->waveFormat.wFormatTag == WAVE_FORMAT_IEEE_FLOAT ) m_audioParam.nBitsPerSample = 0;
                                m_audioParam.wESConfigSize	= pTrack->waveFormat.cbSize;
                                memcpy( m_audioParam.chPcmInfo, ( ( &pTrack->waveFormat ) + 1 ), m_audioParam.wESConfigSize );
                                m_audioParam.uEncSamples	= 2048;
                            }
                        }
                        
                    }
                    else if ( pTrack->aviStream.fccType == streamtypeMIDI )
                    {
                        eTrackType	= eMedTypeMidi;
                    }
                    else if ( pTrack->aviStream.fccType == streamtypeTEXT )
                    {
                        eTrackType	= eMedTypeText;
                    }
                    else
                    {
                        continue;
                    }
                    ++m_uTrackOfType[eTrackType];
                }
                else if ( pList->dwChunk == FCC('vprp' ) )
                {
                    memcpy( &pTrack->vidProperty, pRead, min( sizeof( VideoPropHeader ), pList->dwSize ) );
                }
            }
            else if ( uType == FCC('movi' ) )
            {
                uint8_t*	pBytes	= ((uint8_t*)&pList->dwChunk);
                int32_t		iStream	= ( FromHex(pBytes[0]) << 4 ) | FromHex(pBytes[1]);
                if ( iStream >= 0 && iStream < (int32_t)m_uTrackCount && m_aviTrack[iStream].bEnabled )
                {
                    pTrack	= m_aviTrack + iStream;
                    if ( pTrack->aviStream.fccType == streamtypeVIDEO )
                    {
                        ++m_iFrameInd;
                        if ( pList->dwSize ) m_outFile->WriteFrame( pRead, pList->dwSize, m_iFrameInd, m_iFrameInd );
                    }
                    else if ( pList->dwSize )
                    {
                        int64_t	iPts	= int64_t( m_iFrameInd * 1000 / m_videoParam.fFrameRate );
                        if (m_hasAudio ) m_outFile->WriteAudio( iPts, pRead, pList->dwSize );
                    }
                }
            }
        }
    }
    
    
    return uRead;
}
