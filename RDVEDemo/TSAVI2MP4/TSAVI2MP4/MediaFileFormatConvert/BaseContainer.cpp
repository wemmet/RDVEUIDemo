//
//  BaseContainer.cpp
//  MP4v2
//
//  Created by 周晓林 on 2017/9/13.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#include "BaseContainer.hpp"
CI_Space_AverageSize::CI_Space_AverageSize( void )
{
    m_CurrentValue = 0;
    m_MaxDataSize = 0;
    
}

CI_Space_AverageSize::~CI_Space_AverageSize( void )
{
    
}

void CI_Space_AverageSize::Clear()
{
    //m_ValueDataSizeArray.clear();
    m_CurrentValue = 0;
    m_MaxDataSize = 0;
}

void CI_Space_AverageSize::StatisticsDataSize( int iValue, bool bIskeyFrame )
{
    if( bIskeyFrame ){
        m_CurrentValue += iValue;
        if( m_MaxDataSize < m_CurrentValue )
            m_MaxDataSize = m_CurrentValue;
        //m_ValueDataSizeArray.append( m_CurrentValue );
        m_CurrentValue = iValue;
    }
    else{
        m_CurrentValue += iValue;
    }
}

int CI_Space_AverageSize::AverageValue()
{
    return m_MaxDataSize;
    /*int iValueArray[3] = {0,0,0};
     int iD_valueArray[3] = {0,0,0};
     
     int  count = m_ValueDataSizeArray.count;
     for( int i = 0; i < count; i++ )
     {
     }*/
}

CBaseContainer::CBaseContainer(void)
{
    memset( &m_videoParams, 0, sizeof( m_videoParams ) );
    memset( &m_audioParams, 0, sizeof( m_audioParams ) );
    m_iDelayFrames	= 0;
    m_dTimeBase		= 0;
    m_iLastFrameId	= 0;
    m_iPrevFrameId	= 0;
    m_eFrameType	= NAL_UNKNOWN;
    m_iSplitSize	= 0;
    m_VolumeNumber  = 0;
    m_I_FrameData.p_nal = NULL;
    m_ns = 0;
    
    m_hFaac				= 0;
    m_uFaacInputSamples	= 0;
    m_uFaacInputDone	= 0;
    m_uFaacMaxOutBytes	= 0;
    m_pFaacInputBuffer	= NULL;
    m_pFaacOutputBuffer	= NULL;
    m_bAacEncodeing		= false;
    InitContainerValue();
}

void CBaseContainer::InitContainerValue()
{
    m_I_Space_AverageSize.Clear();
    
    m_pCache	= NULL;
    m_uCurPos	= 0;
    m_uCurMax	= 0;
    m_iTotal	= 0;
    
    m_iVideoStartDts		= 0;
    m_iAudioStartDts		= 0;
    m_iInitDelta	= 0;
    m_iCurrDts		= 0;
    m_iCurrCts		= 0;
    
    m_iVideoFrameNum	= 0;
    m_iAudioFrameNum	= 0;
    m_iLastAudioDts		= 0;
    m_bDtsCompress	= false;
    m_bHeadWriteDone= false;
    
    m_bOpened		= false;
}

CBaseContainer::~CBaseContainer(void)
{
    if ( m_pCache )
    {
        free( m_pCache );
        m_pCache	= NULL;
    }
    if ( m_pFaacInputBuffer ) delete[]m_pFaacInputBuffer;
    if ( m_pFaacOutputBuffer ) delete[]m_pFaacOutputBuffer;
}

unsigned long AacMaxBitrate( unsigned long sampleRate )
{
    /*
     *  Maximum of 6144 bit for a channel
     */
    return (unsigned long)( 6144.0 * (double)sampleRate / (double)1024 + .5 );
}

bool CBaseContainer::SetParam( SVideoParams *pVidParams, SAudioParams* pAudParams )
{
    m_csWrite.lock();
    memset( &m_videoParams, 0, sizeof( m_videoParams ) );
    memset( &m_audioParams, 0, sizeof( m_audioParams ) );
    m_iDelayFrames	= 0;
    m_dTimeBase		= 0;
    m_iLastFrameId	= 0;
    m_iPrevFrameId	= 0;
    m_eFrameType	= NAL_UNKNOWN;
    
    if ( pVidParams && pVidParams->bHasVideo
        && pVidParams->iWidth > 0 && pVidParams->iHeight > 0
        && pVidParams->fFrameRate > 0 )
    {
        m_videoParams		= *pVidParams;
        m_dTimeBase = 1.0 / m_videoParams.fFrameRate;
        m_iDelayFrames = m_videoParams.iBFrames ? ( m_videoParams.iBFramePyramid ? 2 : 1 ) : 0;
    }
    else
    {
        memset( &m_videoParams, 0, sizeof( m_videoParams ) );
    }
    
    if ( pAudParams && pAudParams->bHasAudio
        && pAudParams->nChannels && pAudParams->nSamplesPerSec )
    {
        m_audioParams		= *pAudParams;
        if ( m_audioParams.eCodec == AC_PCM )
        {
            m_hFaac	= faacEncOpen( m_audioParams.nSamplesPerSec, m_audioParams.nChannels, &m_uFaacInputSamples, &m_uFaacMaxOutBytes );
            if ( m_hFaac )
            {
                faacEncConfigurationPtr	pFaacCfg	= faacEncGetCurrentConfiguration( m_hFaac );
                if ( m_audioParams.iBitrate == 0 ) m_audioParams.iBitrate	= 96;
                switch( m_audioParams.nBitsPerSample )
                {
                    case 16:
                        m_audioParams.nFaacInputBits	= FAAC_INPUT_16BIT;
                        break;
                    case 24:
                        m_audioParams.nFaacInputBits	= FAAC_INPUT_24BIT;
                        break;
                    case 32:
                        m_audioParams.nFaacInputBits	= FAAC_INPUT_32BIT;
                        break;
                    default:
                        m_audioParams.nFaacInputBits	= FAAC_INPUT_FLOAT;
                        m_audioParams.nBitsPerSample	= 32;
                        break;
                }
                m_audioParams.eCodec	= AC_AAC;
                pFaacCfg->mpegVersion	= MPEG4;
                pFaacCfg->aacObjectType	= LOW;
                pFaacCfg->bitRate		= m_audioParams.iBitrate * 1024 / m_audioParams.nChannels;
                pFaacCfg->bitRate		= min( pFaacCfg->bitRate, AacMaxBitrate( m_audioParams.nSamplesPerSec ) );
                pFaacCfg->allowMidside	= 0;
                //pFaacCfg->quantqual		= 50;
                pFaacCfg->outputFormat	= m_audioParams.bUseAdts ? 1 : 0;
                pFaacCfg->inputFormat	= m_audioParams.nFaacInputBits;
                if ( !faacEncSetConfiguration( m_hFaac, pFaacCfg ) )
                {
                    faacEncClose( m_hFaac );
                    m_hFaac	= 0;
                }
                else
                {
                    uint8_t*		pDeocderInfo	= NULL;
                    unsigned long	uDecoderSize	= 0;
                    m_audioParams.wESConfigSize	= 2;
                    faacEncGetDecoderSpecificInfo( m_hFaac, &pDeocderInfo, &uDecoderSize );
                    if ( uDecoderSize == 2 )
                    {
                        memcpy( &m_audioParams.chAacDecoderInfo, pDeocderInfo, uDecoderSize );
                    }
                    
                    m_audioParams.uEncSamples		= m_uFaacInputSamples;
                    m_uFaacInputDone	= 0;
                    m_bAacEncodeing		= false;
                    if ( m_pFaacInputBuffer ) delete[]m_pFaacInputBuffer;
                    if ( m_pFaacOutputBuffer ) delete[]m_pFaacOutputBuffer;
                    m_pFaacInputBuffer	= new uint8_t[m_uFaacInputSamples * m_audioParams.nBitsPerSample / 8];
                    m_pFaacOutputBuffer	= new uint8_t[m_audioParams.uEncSamples * m_audioParams.nBitsPerSample / 8];
                }
            }
        }
    }
    else
    {
        memset( &m_audioParams, 0, sizeof( m_audioParams ) );
    }
    m_csWrite.unlock();
    return ( m_videoParams.bHasVideo || m_audioParams.bHasAudio ) ? true : false;
}

bool CBaseContainer::extractHead( uint8_t*& p_nal, uint32_t& i_size )
{
    x264_nal_t	nal[3]	= {0};
    uint32_t	uSize	= 0;
    uint8_t*	pFrame	= NULL;
    uint8_t*	pData	= p_nal;
    uint8_t*	pEnd	= p_nal + i_size;
    nal_unit_type_e	eFrameType	= NAL_UNKNOWN;
    if ( m_videoParams.bAnnexb == false )
    {
        while( pData < pEnd )
        {
            uSize		= endianFix32( *((uint32_t*)pData) );
            if ( uSize == 0 ) break;
            eFrameType	= nal_unit_type_e( pData[4] & 0x0F );
            if ( eFrameType == NAL_SPS )
            {
                nal[0].p_payload	= pData;
                nal[0].i_payload	= uSize + 4;
            }
            else if ( eFrameType == NAL_PPS )
            {
                if ( nal[1].i_payload )
                {
                    nal[1].i_payload	+= uSize + 4;
                }
                else
                {
                    nal[1].p_payload	= pData;
                    nal[1].i_payload	= uSize + 4;
                }
            }
            else if ( eFrameType == NAL_SEI )
            {
                if ( nal[2].i_payload )
                {
                    nal[2].i_payload	+= uSize + 4;
                }
                else
                {
                    nal[2].p_payload	= pData;
                    nal[2].i_payload	= uSize + 4;
                }
            }
            else
            {
                i_size	-= pData - p_nal;
                p_nal	= pData;
                break;
            }
            pData				+= uSize + 4;
        }
    }
    else
    {
        while( pData < pEnd )
        {
            if ( pData[0] == 0 && pData[1] == 0 )
            {
                if ( pData[2] == 1 )
                {
                    uSize	= pFrame ? pData - pFrame : 0;
                    pFrame	= pData;
                    pData	+= 3;
                }
                else if ( pData[2] == 0 && pData[3] == 1 )
                {
                    uSize	= pFrame ? pData - pFrame : 0;
                    pFrame	= pData;
                    pData	+= 4;
                }
                else
                {
                    ++pData;
                    continue;
                }
                if ( uSize )
                {
                    if ( eFrameType == NAL_SPS )
                    {
                        nal[0].p_payload	= pFrame - uSize;
                        nal[0].i_payload	= uSize;
                    }
                    else if ( eFrameType == NAL_PPS )
                    {
                        if ( nal[1].i_payload )
                        {
                            nal[1].i_payload	+= uSize;
                        }
                        else
                        {
                            nal[1].p_payload	= pFrame - uSize;
                            nal[1].i_payload	= uSize;
                        }
                    }
                    else if ( eFrameType == NAL_SEI )
                    {
                        if ( nal[2].i_payload )
                        {
                            nal[2].i_payload	+= uSize;
                        }
                        else
                        {
                            nal[2].p_payload	= pFrame - uSize;
                            nal[2].i_payload	= uSize;
                        }
                    }
                }
                eFrameType	= nal_unit_type_e( pData[0] & 0x0F );
                //if ( eFrameType != NAL_SPS && eFrameType != NAL_PPS && eFrameType != NAL_SEI )
                //{
                //	i_size	-= pFrame - p_nal;
                //	p_nal	= pFrame;
                if ( nal[0].i_payload && nal[1].p_payload )
                {
                    return WriteHeaders( nal );
                }
                //	return false;
                //}
            }
            ++pData;
        }
        if ( pFrame )
        {
            uSize	= pData - pFrame;
            if ( eFrameType == NAL_SPS )
            {
                nal[0].p_payload	= pFrame;
                nal[0].i_payload	= uSize;
            }
            else if ( eFrameType == NAL_PPS )
            {
                if ( nal[1].i_payload )
                {
                    nal[1].i_payload	+= uSize;
                }
                else
                {
                    nal[1].p_payload	= pFrame;
                    nal[1].i_payload	= uSize;
                }
            }
            else if ( eFrameType == NAL_SEI )
            {
                if ( nal[2].i_payload )
                {
                    nal[2].i_payload	+= uSize;
                }
                else
                {
                    nal[2].p_payload	= pFrame;
                    nal[2].i_payload	= uSize;
                }
            }
        }
    }
    if ( nal[0].i_payload && nal[1].p_payload )
    {
        return WriteHeaders( nal );
    }
    return false;
}

void CBaseContainer::extractSpsPps( x264_nal_t p_nal[3], int& sps_size, int& pps_size, int& sei_size, uint8_t* &sps, uint8_t* &pps, uint8_t* &sei )
{
    if ( m_videoParams.bAnnexb == false )
    {
        if ( p_nal[0].i_payload > 4 )
        {
            sps_size = p_nal[0].i_payload - 4;
            sps = p_nal[0].p_payload + 4;
        }
        if ( p_nal[1].i_payload > 4 )
        {
            pps_size = p_nal[1].i_payload - 4;
            pps = p_nal[1].p_payload + 4;
        }
        if ( p_nal[2].i_payload > 4 )
        {
            sei_size = p_nal[2].i_payload - 4;
            sei = p_nal[2].p_payload + 4;
        }
    }
    else
    {
        if ( p_nal[0].i_payload > 3 )
        {
            if ( p_nal[0].p_payload[0] == 0 && p_nal[0].p_payload[1] == 0 && p_nal[0].p_payload[2] == 1 )
            {
                sps_size = p_nal[0].i_payload - 3;
                sps = p_nal[0].p_payload + 3;
            }
            else
            {
                sps_size = p_nal[0].i_payload - 4;
                sps = p_nal[0].p_payload + 4;
            }
        }
        if ( p_nal[1].i_payload > 3 )
        {
            if ( p_nal[1].p_payload[0] == 0 && p_nal[1].p_payload[1] == 0 && p_nal[1].p_payload[2] == 1 )
            {
                pps_size = p_nal[1].i_payload - 3;
                pps = p_nal[1].p_payload + 3;
            }
            else
            {
                pps_size = p_nal[1].i_payload - 4;
                pps = p_nal[1].p_payload + 4;
            }
        }
        if ( p_nal[2].i_payload > 3 )
        {
            if ( p_nal[2].p_payload[0] == 0 && p_nal[2].p_payload[1] == 0 && p_nal[2].p_payload[2] == 1 )
            {
                sei_size = p_nal[2].i_payload - 3;
                sei = p_nal[2].p_payload + 3;
            }
            else
            {
                sei_size = p_nal[2].i_payload - 4;
                sei = p_nal[2].p_payload + 4;
            }
        }
    }
}

bool CBaseContainer::WriteFrame( uint8_t *p_nal, uint32_t i_size, int64_t i_pts, int64_t i_dts )
{
#define convert_timebase_ms( timestamp, timebase ) (int64_t)((timestamp) * (timebase) * 1000 + 0.5)
    
    m_eFrameType	= NAL_UNKNOWN;
    
    if ( m_videoParams.eCodec == VC_H264 )
    {
        if ( m_videoParams.bAnnexb == false )
        {
            m_eFrameType	= nal_unit_type_e( p_nal[4] & 0x0F );
        }
        else
        {
            if ( p_nal[0] == 0 && p_nal[1] == 0 )
            {
                if ( p_nal[2] == 1 )
                {
                    m_eFrameType	= nal_unit_type_e( p_nal[3] & 0x0F );
                }
                else if ( p_nal[2] == 0 && p_nal[3] == 1 )
                {
                    m_eFrameType	= nal_unit_type_e( p_nal[4] & 0x0F );
                }
                else
                {
                    return false;
                }
            }
        }
        
        if ( 0 == m_iVideoFrameNum ) //��ȡ��һ֡��ʵ��ʱ��
        {
            //if ( NAL_SLICE_IDR != m_eFrameType && NAL_AUD != m_eFrameType ) return false;
            m_iVideoStartDts	= i_dts;
            //if( !m_bDtsCompress && m_iVideoStartDts )
            //	x264_cli_log( "flv", X264_LOG_INFO, "initial delay %"PRId64" ms\n",
            //	convert_timebase_ms( p_picture->i_pts + p_flv->i_delay_time, p_flv->d_timebase ) );
        }
        
    }
    
    int64_t dts;
    int64_t cts;
    
    if ( m_bDtsCompress )
    {
        if ( m_iVideoFrameNum == 1 )
            m_iInitDelta = convert_timebase_ms( i_dts - m_iVideoStartDts, m_dTimeBase );
        dts = m_iVideoFrameNum > m_iDelayFrames
        ? convert_timebase_ms( i_dts, m_dTimeBase )
        : m_iVideoFrameNum * m_iInitDelta / (m_iDelayFrames + 1);
        cts = convert_timebase_ms( i_pts, m_dTimeBase );
    }
    else
    {
        dts = convert_timebase_ms( i_dts - m_iVideoStartDts, m_dTimeBase );
        cts = convert_timebase_ms( i_pts - m_iVideoStartDts, m_dTimeBase );
    }
    
    //if ( m_iVideoFrameNum )
    //{
    //	if( m_iCurrDts == dts )
    //		x264_cli_log( "flv", X264_LOG_WARNING, "duplicate DTS %"PRId64" generated by rounding\n"
    //		"               decoding framerate cannot exceed 1000fps\n", dts );
    //	if( m_iPrevCts == cts )
    //		x264_cli_log( "flv", X264_LOG_WARNING, "duplicate CTS %"PRId64" generated by rounding\n"
    //		"               composition framerate cannot exceed 1000fps\n", cts );
    //}
    m_iPrevFrameId	= m_iLastFrameId;
    m_iLastFrameId	= i_pts - m_iVideoStartDts;
    m_iCurrDts = dts;
    m_iCurrCts = cts;
    m_iVideoFrameNum++;
    return true;
}

bool CBaseContainer::WriteAudio( int64_t dts, uint8_t *pData, uint32_t iSize )
{
    if ( m_hFaac && false == m_bAacEncodeing )
    {
        uint32_t	iFrameSize		= m_audioParams.nBitsPerSample / 8;
        uint32_t	dwFrameCount	= iSize / iFrameSize;
        uint32_t	dwNowInput	= 0;
        m_bAacEncodeing	= true;
        while ( dwFrameCount )
        {
            uint32_t	uGet	= m_uFaacInputSamples - m_uFaacInputDone;
            uGet	= min( uGet, dwFrameCount );
            if ( m_audioParams.nFaacInputBits == FAAC_INPUT_32BIT )
            {
                int32_t*	pSamp	= (int32_t*)( m_pFaacInputBuffer + iFrameSize * m_uFaacInputDone );
                int32_t*	pInSamp	= (int32_t*)( pData );
                for ( uint32_t i = 0; i < uGet; ++i )
                {
                    pSamp[i]	= pInSamp[i] >> 8;
                }
            }
            else
            {
                memcpy( m_pFaacInputBuffer + iFrameSize * m_uFaacInputDone, pData, uGet * iFrameSize );
            }
            m_uFaacInputDone	+= uGet;
            dwFrameCount		-= uGet;
            pData	+= uGet * iFrameSize;
            if ( m_uFaacInputDone == m_uFaacInputSamples )
            {
                m_uFaacInputDone	= 0;
                iSize	= faacEncEncode( m_hFaac, (int32_t*)m_pFaacInputBuffer, m_uFaacInputSamples, m_pFaacOutputBuffer, m_uFaacMaxOutBytes );
                if ( iSize )
                {
                    int64_t	uDts	= dts + ( dwNowInput * 1000 ) / ( m_audioParams.nSamplesPerSec * m_audioParams.nChannels );
                    WriteAudio( uDts, m_pFaacOutputBuffer, iSize );
                    dwNowInput	+= m_uFaacInputSamples;
                }
            }
        }
        m_bAacEncodeing	= false;
        return false;
    }
    
    if ( m_iAudioFrameNum++ == 0 )
    {
        m_iAudioStartDts	= dts;
    }
    if ( dts < m_iLastAudioDts )
    {
        printf( "" );
    }
    m_iLastAudioDts	= dts;
    
    return true;
}

bool CBaseContainer::CloseFile()
{
    m_csWrite.lock();
    if ( m_outFile.is_open() )
    {
        flushData();
        m_outFile.close();
    }
    if ( m_pCache )
    {
        free( m_pCache );
        m_pCache	= NULL;
    }
    if ( m_hFaac )
    {
        faacEncClose( m_hFaac );
        m_hFaac	= 0;
        if ( m_pFaacInputBuffer )
        {
            delete[]m_pFaacInputBuffer;
            m_pFaacInputBuffer	= NULL;
        }
        if ( m_pFaacOutputBuffer )
        {
            delete[]m_pFaacOutputBuffer;
            m_pFaacOutputBuffer	= NULL;
        }
        m_bAacEncodeing	= false;
        m_uFaacInputDone	= 0;
    }
    InitContainerValue();
    m_csWrite.unlock();
    return true;
}
