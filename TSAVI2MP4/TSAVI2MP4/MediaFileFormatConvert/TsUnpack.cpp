//
//  TsUnpack.cpp
//  MP4v2
//
//  Created by 周晓林 on 2017/9/13.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#include "TsUnpack.hpp"
#include <math.h>
CTsUnpack::CTsUnpack(void)
{
    m_iPacketLen	= 188;
    m_progNumber	= 0;
    m_elePID_Video	= 0;
    m_elePID_Audio	= 0;
}

CTsUnpack::~CTsUnpack(void)
{
}
void Echo(float g){
    printf(">>>>%f\n",g);
}
bool CTsUnpack::OnUnpack( uint64_t uSize )
{
   
    
    uint8_t*			pPacket	= Read( m_iPacketLen * 2 );
    uint8_t				uData	= m_iPacketLen;
    TS_Packet_Header	sHead;
    
    m_progNumber	= 0;
    m_elePID_Video	= 0;
    m_elePID_Audio	= 0;
    
    while ( uData && ( pPacket[0] != 0x47 || pPacket[m_iPacketLen] != 0x47 ) )
    {
        ++pPacket;
        --uData;
    }
    if ( uData == 0 ) return false;
    
    Seek( m_iPacketLen - uData );
    pPacket	= Read( m_iPacketLen );
    uData	= m_iPacketLen;
    do
    {
        
        
        sHead.sync_byte						= pPacket[0];
        sHead.transport_error_indicator		= pPacket[1] >> 7;
        sHead.payload_unit_start_indicator	= ( pPacket[1] >> 6 ) & 1;
        sHead.transport_priority			= ( pPacket[1] >> 5 ) & 1;
        sHead.PID							= ( pPacket[1] & 0x1F ) << 8 | pPacket[2];
        sHead.transport_scrambling_control	= pPacket[3] >> 6;
        sHead.adaptation_field_control		= ( pPacket[3] >> 4 ) & 3;
        sHead.continuity_counter			= pPacket[3] & 0xF;
        uData	-= 4;
        pPacket	+= 4;
        if ( sHead.transport_error_indicator == 0 && ( sHead.adaptation_field_control & 1 ) )
        {
            if ( sHead.adaptation_field_control & 2 )
            {
                uData	-= pPacket[0] + 1;
                pPacket	+= pPacket[0] + 1;
            }
            
            switch ( sHead.PID )
            {
                case 0x0000:	//PAT
                    if ( sHead.payload_unit_start_indicator )
                    {
                        uData	-= pPacket[0] + 1;
                        pPacket	+= pPacket[0] + 1;
                    }
                    AnalysePAT( pPacket );
                    break;
                case 0x0001:	//CAT
                    break;
                case 0x0002:	//TSDT
                    break;
                case 0x0012:	//EIT,ST
                    break;
                case 0x0013:	//RST,ST
                    break;
                case 0x0014:	//TDT,TOT,ST
                    break;
                default:
                    if ( m_programs.find( sHead.PID ) != m_programs.end() )
                    {
                        if ( sHead.payload_unit_start_indicator )
                        {
                            uData	-= pPacket[0] + 1;
                            pPacket	+= pPacket[0] + 1;
                        }
                        AnalysePMT( pPacket, sHead.PID );
                    }
                    else if ( m_elePID_Video == sHead.PID || m_elePID_Audio == sHead.PID )
                    {
                        map<uint32_t, TS_MAP_STREAM>::iterator	item	= m_streams.find( sHead.PID );
                        if ( item != m_streams.end() )
                        {
                            if ( sHead.payload_unit_start_indicator )
                                item->second.uPesPending	= 0;
                            AnalysePES( pPacket, item->second, uData );
                        }
                    }
            }
        }
        pPacket		= Read( m_iPacketLen );
        uData		= m_iPacketLen;
    } while ( pPacket && pPacket[0] == 0x47 );
    
    for ( map<uint32_t, TS_MAP_STREAM>::iterator i = m_streams.begin(); i != m_streams.end(); ++i )
    {
       // if ( i->second.uDataSize )	AnalyseES( i->second );
        if ( i->second.pDataBuf ) free( i->second.pDataBuf );
    }
    m_streams.clear();
    m_programs.clear();
    return true;
}

bool CTsUnpack::AnalysePAT( uint8_t* pPacket )
{
    TS_PAT		sPat;
    sPat.table_id					= pPacket[0];
    sPat.section_syntax_indicator	= pPacket[1] >> 7;
    sPat.zero						= ( pPacket[1] >> 6 ) & 1;
    sPat.reserved_1					= ( pPacket[1] >> 4 ) & 3;
    sPat.section_length				= ( ( pPacket[1] & 0x0F ) << 8 ) | pPacket[2];
    sPat.transport_stream_id		= ( pPacket[3] << 8 ) | pPacket[4];
    sPat.reserved_2					= pPacket[5] >> 6;
    sPat.version_number				= ( pPacket[5] >> 1 ) & 0x1F;
    sPat.current_next_indicator		= pPacket[5] & 1;
    sPat.section_number				= pPacket[6];
    sPat.last_section_number		= pPacket[7];
    sPat.CRC_32						= *( (uint32_t*)(pPacket + sPat.section_length - 1 ) );
    
    pPacket		+= 8;
    int32_t		iCount	= int32_t( sPat.section_length + 3 - 12 ) / 4;
    for ( int32_t i = 0; i < iCount; ++i )
    {
        TS_PAT_PROGRAM	sProg;
        sProg.program_number		= pPacket[0] << 8 | pPacket[1];
        sProg.reserved_3			= pPacket[2] >> 5;
        sProg.program_map_PID		= ( pPacket[2] & 0x1F ) << 8 | pPacket[3];
        if ( sProg.program_number )
        {
            m_programs[sProg.program_map_PID]	= sProg;
        }
        pPacket	+= 4;
    }
    return true;
}

bool CTsUnpack::AnalysePMT( uint8_t* pPacket, uint32_t uMapID )
{
    TS_PMT		sPmt;
    sPmt.table_id					= pPacket[0];
    sPmt.section_syntax_indicator	= pPacket[1] >> 7;
    sPmt.zero						= ( pPacket[1] >> 6 ) & 1;
    sPmt.reserved_1					= ( pPacket[1] >> 4 ) & 3;
    sPmt.section_length				= ( ( pPacket[1] & 0x0F ) << 8 ) | pPacket[2];
    sPmt.program_number				= ( pPacket[3] << 8 ) | pPacket[4];
    sPmt.reserved_2					= pPacket[5] >> 6;
    sPmt.version_number				= ( pPacket[5] >> 1 ) & 0x1F;
    sPmt.current_next_indicator		= pPacket[5] & 1;
    sPmt.section_number				= pPacket[6];
    sPmt.last_section_number		= pPacket[7];
    
    sPmt.reserved_3					= pPacket[8] >> 5;
    sPmt.PCR_PID					= ( pPacket[8] & 0x1F ) << 8 | pPacket[9];
    sPmt.reserved_4					= pPacket[10] >> 4;
    sPmt.program_info_length		= ( ( pPacket[10] & 0x0F ) << 8 ) | pPacket[11];
    sPmt.CRC_32						= *( (uint32_t*)(pPacket + sPmt.section_length - 1 ) );
    
    int32_t		iPos	= 12 + sPmt.program_info_length;
    int32_t		iCount	= int32_t( sPmt.section_length + 3 - iPos - 4 ) / 5;
    pPacket	+= iPos;
    for ( int32_t i = 0; i < iCount; ++i )
    {
        TS_MAP_STREAM	sStream;
        memset( &sStream, 0, sizeof( sStream ) );
        sStream.stream_type			= pPacket[0];
        sStream.reserved_5			= pPacket[1] >> 5;
        sStream.elementary_PID		= ( pPacket[1] & 0x1F ) << 8 | pPacket[2];
        sStream.reserved_5			= pPacket[3] >> 4;
        sStream.ES_info_length		= ( ( pPacket[3] & 0x0F ) << 8 ) | pPacket[4];
        
        sStream.program_map_PID		= uMapID;
        sStream.program_number		= sPmt.program_number;
        
        map<uint32_t, TS_MAP_STREAM>::iterator	item = m_streams.find( sStream.elementary_PID );
        
        if ( item == m_streams.end() )
        {
            sStream.eType		= GetStreamType( sStream.stream_type, sStream.eVideoCodec, sStream.eAudioCodec );
            sStream.uPesPending	= 0;
            m_streams[sStream.elementary_PID]	= sStream;
            if ( m_elePID_Video == 0 && sStream.eType == eMedTypeVideo && sStream.eVideoCodec == CBaseContainer::VC_H264 )
            {
                m_elePID_Video	= sStream.elementary_PID;
                m_progNumber	= sStream.program_number;
            }
            if ( m_elePID_Video && m_elePID_Audio == 0 )
            {
                for ( map<uint32_t, TS_MAP_STREAM>::iterator i = m_streams.begin(); i != m_streams.end(); ++i )
                {
                    if ( i->second.program_number == m_progNumber &&
                        i->second.eType == eMedTypeAudio && i->second.eAudioCodec == CBaseContainer::AC_AAC )
                    {
                        m_elePID_Audio	= i->first;
                        break;
                    }
                }
            }
            
        }
        pPacket	+= 5;
    }
    return true;
}


bool CTsUnpack::AnalysePES( uint8_t* pPacket, TS_MAP_STREAM& sStream, uint8_t uSize )
{
    if ( sStream.uPesPending == 0 )
    {
        TS_PES		sPes;
        
        sPes.packet_start_code_prefix	= pPacket[0] << 16 | pPacket[1] << 8 | pPacket[2];
        sPes.stream_id					= pPacket[3];
        sPes.PES_packet_length			= pPacket[4] << 8 | pPacket[5];
        
        sPes.fix_bit					= pPacket[6] >> 6;
        sPes.PES_scrambling_control		= ( pPacket[6] >> 4 ) & 3;
        sPes.PES_priority				= ( pPacket[6] >> 3 ) & 1;
        sPes.data_alignment_indicator	= ( pPacket[6] >> 2 ) & 1;
        sPes.copyright					= ( pPacket[6] >> 1 ) & 1;
        sPes.original_or_copy			= pPacket[6] & 1;
        
        sPes.PTS_DTS_flags				= pPacket[7] >> 6;
        sPes.ESCR_flag					= ( pPacket[7] >> 5 ) & 1;
        sPes.ES_rate_flag				= ( pPacket[7] >> 4 ) & 1;
        sPes.DSM_trick_mode_flag		= ( pPacket[7] >> 3 ) & 1;
        sPes.additional_copy_info_flag	= ( pPacket[7] >> 2 ) & 1;
        sPes.PES_CRC_flag				= ( pPacket[7] >> 1 ) & 1;
        sPes.PES_extension_flag			= pPacket[7] & 1;
        
        sPes.PES_header_data_length		= pPacket[8];
        
        if ( sPes.packet_start_code_prefix == 1 )
        {
            if ( sStream.uDataSize ) AnalyseES( sStream );
            uint32_t	uHeadSize	= sPes.PES_header_data_length + 9;
            sStream.uPesPending		= sPes.PES_packet_length ? sPes.PES_packet_length + 6 - uHeadSize : 0;
            
            uSize	-= uHeadSize;
            pPacket	+= uHeadSize;
            if ( sStream.pDataBuf == NULL )
            {
                sStream.pDataBuf	= (uint8_t*)malloc( 1024 * 1024 * 10 );
                sStream.uDataSize	= 0;
            }
        }
    }
    
    if ( sStream.uPesPending )
    {
        uSize	= min( (uint32_t)uSize, sStream.uPesPending - sStream.uDataSize );
    }
    memcpy( sStream.pDataBuf + sStream.uDataSize, pPacket, uSize );
    sStream.uDataSize	+= uSize;
    return true;
}

bool CTsUnpack::AnalyseES( TS_MAP_STREAM& sStream )
{
    if ( !m_outFile->isValid() )
    {
        if ( sStream.elementary_PID == m_elePID_Video && m_videoParam.bHasVideo == false )
        {
            CBaseContainer::nal_unit_type_e	eFraType	= CBaseContainer::NAL_UNKNOWN;
            uint8_t*	pStartFrame	= NULL;
            uint8_t*	pFrame	= NULL;
            uint8_t*	pData	= sStream.pDataBuf;
            uint8_t*	pEnd	= pData + sStream.uDataSize - 4;
            uint32_t	uSize	= 0;
            uint32_t	uSkip	= 0;
            while ( pData < pEnd )
            {
                if ( pData[0] == 0 && pData[1] == 0 )
                {
                    if ( pData[2] == 1 )
                    {
                        uSkip	= 3;
                    }
                    else if ( pData[2] == 0 && pData[3] == 1 )
                    {
                        uSkip	= 4;
                    }
                    else
                    {
                        ++pData;
                        continue;
                    }
                    if ( pFrame )
                    {
                        int32_t	iPrefix	= pFrame[2] == 1 ? 3 : 4;
                        eFraType	= CBaseContainer::nal_unit_type_e( pFrame[iPrefix] & 0x0F );
                        if ( eFraType == CBaseContainer::NAL_SEI || eFraType == CBaseContainer::NAL_PPS || eFraType == CBaseContainer::NAL_SPS )
                        {
                            if ( NULL == pStartFrame )	pStartFrame	= pFrame;
                            if ( eFraType == CBaseContainer::NAL_SPS )
                            {
                                uint8_t	sps[100];
                                pFrame	+= iPrefix;
                                uSize	= pData - pFrame;
                                memcpy( sps, pFrame, uSize );
                                if ( AnalyseSPS( sps, sStream, uSize ) ) break;
                            }
                        }
                    }
                    pFrame	= pData;
                    pData	+= uSkip;
                    continue;
                }
                ++pData;
            }
            if ( pFrame && pData - uSkip != pFrame && m_videoParam.bHasVideo == false )
            {
                int32_t	iPrefix	= pFrame[2] == 1 ? 3 : 4;
                eFraType	= CBaseContainer::nal_unit_type_e( pFrame[iPrefix] & 0x0F );
                if ( eFraType == CBaseContainer::NAL_SEI || eFraType == CBaseContainer::NAL_PPS || eFraType == CBaseContainer::NAL_SEI )
                {
                    if ( NULL == pStartFrame )	pStartFrame	= pFrame;
                    if ( eFraType == CBaseContainer::NAL_SPS )
                    {
                        uint8_t	sps[100];
                        pFrame	+= iPrefix;
                        uSize	= pData - pFrame;
                        memcpy( sps, pFrame, uSize );
                        AnalyseSPS( sps, sStream, uSize );
                    }
                }
            }
            if ( m_videoParam.bHasVideo == false )
            {
                sStream.uDataSize	= 0;
            }
            else if ( pStartFrame > sStream.pDataBuf )
            {
                sStream.uDataSize	-= ( pStartFrame - sStream.pDataBuf );
                memmove( sStream.pDataBuf, pStartFrame, sStream.uDataSize );
            }
        }
        else if ( sStream.elementary_PID == m_elePID_Audio && m_audioParam.bHasAudio == false )
        {
            uint8_t*	pFrame	= sStream.pDataBuf;
            if ( sStream.uDataSize > 8 && pFrame[0] == 0xFF && ( pFrame[1] >> 4 ) == 0xF )
            {
                AnalyseADTS( pFrame, sStream, sStream.uDataSize );
            }
            if ( m_audioParam.bHasAudio == false )
            {
                sStream.uDataSize	= 0;
            }
        }
        
        if ( ( 0 == m_elePID_Video || m_elePID_Video && m_videoParam.bHasVideo ) &&
            ( 0 == m_elePID_Audio || m_elePID_Audio && m_audioParam.bHasAudio ) &&
            ( m_elePID_Video || m_elePID_Audio ) )
        {
            bool bOldHasAudio = m_audioParam.bHasAudio;
            m_audioParam.bHasAudio  = m_hasAudio ? bOldHasAudio : false;
            m_outFile->SetParam( &m_videoParam, &m_audioParam );
            m_audioParam.bHasAudio  = bOldHasAudio;
            if ( !m_outFile->OpenFile( m_szOutFilePath, 0 ) )
            {
                return false;
            }
        }
    }
    
    if ( m_outFile->isValid() )
    {
        TS_MAP_STREAM&	vidStream	= m_streams[m_elePID_Video];
        if ( vidStream.uDataSize )
        {
            ++m_iFrameInd;
            m_outFile->WriteFrame( vidStream.pDataBuf, vidStream.uDataSize, m_iFrameInd, m_iFrameInd );
            vidStream.uDataSize	= 0;
        }
        TS_MAP_STREAM&	audStream	= m_streams[m_elePID_Audio];
        if ( audStream.uDataSize )
        {
            int64_t	iPts	= int64_t( m_iFrameInd * 1000 / m_videoParam.fFrameRate );
            uint8_t*	pFrame	= audStream.pDataBuf;
            while ( audStream.uDataSize )
            {
                uint32_t	uSyncword	= pFrame[0] << 4 | pFrame[1] >> 4;
                uint32_t	uID			= ( pFrame[1] >> 3 ) & 1;
                uint32_t	uLength		= ( pFrame[3] & 3 ) << 11 | pFrame[4] << 3 | pFrame[5] >> 5;
                if ( uLength <= audStream.uDataSize )
                {
                    if ( m_hasAudio ) m_outFile->WriteAudio( iPts, pFrame + 7, uLength  - 7);
                    pFrame	+= uLength;
                    audStream.uDataSize	-= uLength;
                }
                else
                {
                    if ( m_hasAudio ) memmove( audStream.pDataBuf, pFrame, audStream.uDataSize );
                    break;
                }
            }
        }
        return true;
    }
    
    return false;
}

bool CTsUnpack::AnalyseSPS( uint8_t* pData, TS_MAP_STREAM& sStream, uint8_t uSize )
{
    int32_t	iWidth	= 0;
    int32_t	iHeight	= 0;
    float	fFps	= 0;
    bool	bSucc	= h264_decode_sps( pData, uSize, iWidth, iHeight, fFps );
    if ( bSucc )
    {
        m_videoParam.bHasVideo	= true;
        m_videoParam.eCodec		= sStream.eVideoCodec;
        m_videoParam.bAnnexb	= true;
        m_videoParam.iWidth		= iWidth;
        m_videoParam.iHeight	= iHeight;
        m_videoParam.fFrameRate	= fFps == 0.0f ? 25.0f : fFps;
    }
    return true;
}

bool CTsUnpack::AnalyseADTS( uint8_t* pData, TS_MAP_STREAM& sStream, uint8_t uSize )
{
    SADTS	adts	={ 0 };
    adts.syncword	= pData[0] << 4 | pData[1] >> 4;
    adts.ID			= ( pData[1] >> 3 ) & 1;
    adts.layer		= ( pData[1] >> 1 ) & 3;
    adts.protection_absent	= pData[1] & 1;
    
    adts.profile	= pData[2] >> 6;
    adts.sampling_frequency_index	= ( pData[2] >> 2 ) & 0xF;
    adts.private_bit	= ( pData[2] >> 1 ) & 1;
    adts.channel_configuration	= ( pData[2] & 1 ) << 2 | pData[3] >> 6;
    adts.original_copy	= ( pData[3] >> 5 ) & 1;
    adts.home		= ( pData[3] >> 4 ) & 1;
    
    adts.copyright_identiflcation_bit	= ( pData[3] >> 3 ) & 1;
    adts.copyright_identiflcation_start	= ( pData[3] >> 2 ) & 1;
    
    adts.aac_frame_length	= ( pData[3] & 3 ) << 11 | pData[4] << 3 | pData[5] >> 5;
    adts.adts_buffer_fullness	= ( pData[5] & 0x1F ) << 6 | pData[6] >> 2;
    adts.num_of_raw_data_blocks_in_frame	= pData[6] & 3;
    
    uint32_t	AAC_Sampling_Frequency_Table[16] =
    { 96000, 88200, 64000, 48000, 44100, 32000, 24000, 22050, 16000, 12000, 11025, 8000, 7350, 0, 0, 0 };
    
    m_audioParam.bHasAudio	= true;
    m_audioParam.bUseAdts	= true;
    m_audioParam.eCodec		=  CBaseContainer::AC_AAC;
    m_audioParam.nSamplesPerSec	= AAC_Sampling_Frequency_Table[adts.sampling_frequency_index];
    m_audioParam.nChannels		= adts.channel_configuration;
    m_audioParam.nBitsPerSample	= 16;
    m_audioParam.uEncSamples	= 1024 * m_audioParam.nChannels;
    m_audioParam.wESConfigSize	= 2;
    
    uint16_t	wAacDecoderInfo	= ( adts.profile + 1 ) << 11 | adts.sampling_frequency_index << 7 | adts.channel_configuration << 3;
    m_audioParam.chAacDecoderInfo[0]	= ( wAacDecoderInfo >> 8 );
    m_audioParam.chAacDecoderInfo[1]	= ( wAacDecoderInfo & 0xFF );
    
    return true;
}

CTsUnpack::EMediaType CTsUnpack::GetStreamType( uint32_t uType, CBaseContainer::EVideoCodec& eVideoCodec, CBaseContainer::EAudioCodec& eAudioCodec )
{
    EMediaType	eType		= eMedTypeVideo;
    eVideoCodec			= CBaseContainer::VC_UNKNOW;
    eAudioCodec			= CBaseContainer::AC_UNKNOW;
    switch( uType )
    {
        case 0x00:		//ITU-T | ISO/IEC Reserved
            break;
        case 0x01:		//ISO/IEC 11172-2 Video (mpeg video v1)
            eVideoCodec	= CBaseContainer::VC_MPG1;
            break;
        case 0x02:		//ITU-T Rec. H.262 | ISO/IEC 13818-2 Video(mpeg video v2)or ISO/IEC 11172-2 constrained parameter video stream
            eVideoCodec	= CBaseContainer::VC_MPG2;
            break;
        case 0x03:		//ISO/IEC 11172-3 Audio (MPEG 1 Audio codec Layer I, Layer II and Layer III audio specifications)��MP3��
            eType	= eMedTypeAudio;
            eAudioCodec	= CBaseContainer::AC_MP3;
            break;
        case 0x04:		//ISO/IEC 13818-3 Audio (BC Audio Codec)
            eType	= eMedTypeAudio;
            break;
        case 0x05:		//ITU-T Rec. H.222.0 | ISO/IEC 13818-1 private_sections
            eVideoCodec	= CBaseContainer::VC_MPG2;
            break;
        case 0x06:		//ITU-T Rec. H.222.0 | ISO/IEC 13818-1 PES packets containing private data
            eVideoCodec	= CBaseContainer::VC_MPG2;
            break;
        case 0x07:		//ISO/IEC 13522 MHEG
            break;
        case 0x08:		//ITU-T Rec. H.222.0 | ISO/IEC 13818-1 Annex A DSM-CC
            eVideoCodec	= CBaseContainer::VC_MPG2;
            break;
        case 0x09:		//ITU-T Rec. H.222.1
            eVideoCodec	= CBaseContainer::VC_MPG2;
            break;
        case 0x0A:		//ISO/IEC 13818-6 type A
            break;
        case 0x0B:		//ISO/IEC 13818-6 type B
            break;
        case 0x0C:		//ISO/IEC 13818-6 type C
            break;
        case 0x0D:		//ISO/IEC 13818-6 type D
            break;
        case 0x0E:		//ITU-T Rec. H.222.0 | ISO/IEC 13818-1 auxiliary
            eVideoCodec	= CBaseContainer::VC_MPG2;
            break;
        case 0x0F:		//ISO/IEC 13818-7 Audio with ADTS transport syntax��aac��
            eType	= eMedTypeAudio;
            eAudioCodec	= CBaseContainer::AC_AAC;
            break;
        case 0x10:		//ISO/IEC 14496-2 Visual
            break;
        case 0x11:		//ISO/IEC 14496-3 Audio with the LATM transport syntax as defined in ISO/IEC 14496-3/Amd.1
            break;
        case 0x12:		//ISO/IEC 14496-1 SL-packetized stream or FlexMux stream carried in PES packets
            break;
        case 0x13:		//ISO/IEC 14496-1 SL-packetized stream or FlexMux stream carried in ISO/IEC 14496_sections
            break;
        case 0x14:		//ISO/IEC 13818-6 Synchronized Download Protocol
            break;
        case 0x15:		//Metadata carried in PES packets
            break;
        case 0x16:		//Metadata carried in metadata_sections
            break;
        case 0x17:		//Metadata carried in ISO/IEC 13818-6 Data Carousel
            break;
        case 0x18:		//Metadata carried in ISO/IEC 13818-6 Object Carousel
            break;
        case 0x19:		//Metadata carried in ISO/IEC 13818-6 Synchronized Download Protocol
            break;
        case 0x1A:		//IPMP stream (defined in ISO/IEC 13818-11, MPEG-2 IPMP)
            eVideoCodec	= CBaseContainer::VC_MPG2;
            break;
        case 0x1B:		//AVC video stream as defined in ITU-T Rec. H.264 | ISO/IEC 14496-10 Video (h.264)
            eVideoCodec	= CBaseContainer::VC_H264;
            break;
        case 0x1C:		//ISO/IEC 14496-3 Audio, without using any additional transport syntax, such as DST, ALS and SLS
            eType	= eMedTypeAudio;
            eAudioCodec	= CBaseContainer::AC_DTS;
            break;
        case 0x1D:		//ISO/IEC 14496-17 Text
            eType	= eMedTypeText;
            break;
        case 0x1E:		//Auxiliary video stream as defined in ISO/IEC 23002-3 (AVS)
            break;
    }
    return eType;
}


uint32_t Ue( uint8_t *pBuff, uint32_t nLen, uint32_t &nStartBit )
{
    //����0bit�ĸ���
    uint32_t nZeroNum = 0;
    while ( nStartBit < nLen * 8 )
    {
        if ( pBuff[nStartBit / 8] & ( 0x80 >> ( nStartBit % 8 ) ) ) //&:��λ�룬%ȡ��
        {
            break;
        }
        nZeroNum++;
        nStartBit++;
    }
    nStartBit++;
    
    
    //������
    uint32_t dwRet = 0;
    for ( uint32_t i=0; i<nZeroNum; i++ )
    {
        dwRet <<= 1;
        if ( pBuff[nStartBit / 8] & ( 0x80 >> ( nStartBit % 8 ) ) )
        {
            dwRet += 1;
        }
        nStartBit++;
    }
    return ( 1 << nZeroNum ) - 1 + dwRet;
}


int32_t Se( uint8_t *pBuff, uint32_t nLen, uint32_t &nStartBit )
{
    int UeVal=Ue( pBuff, nLen, nStartBit );
    double k=UeVal;
    int nValue=ceil( k / 2 );//ceil������ceil��������������С�ڸ���ʵ������С������ceil(2)=ceil(1.2)=cei(1.5)=2.00
    if ( UeVal % 2 == 0 )
        nValue=-nValue;
    return nValue;
}


uint32_t u( uint32_t BitCount, uint8_t * buf, uint32_t &nStartBit )
{
    uint32_t dwRet = 0;
    for ( uint32_t i=0; i<BitCount; i++ )
    {
        dwRet <<= 1;
        if ( buf[nStartBit / 8] & ( 0x80 >> ( nStartBit % 8 ) ) )
        {
            dwRet += 1;
        }
        nStartBit++;
    }
    return dwRet;
}

/**
 * H264��NAL��ʼ�����������
 *
 * @param buf SPS��������
 *
 * @�޷���ֵ
 */
void de_emulation_prevention( uint8_t* buf, uint32_t* buf_size )
{
    int i=0, j=0;
    uint8_t* tmp_ptr=NULL;
    unsigned int tmp_buf_size=0;
    int val=0;
    
    tmp_ptr=buf;
    tmp_buf_size=*buf_size;
    for ( i=0; i<( tmp_buf_size - 2 ); i++ )
    {
        //check for 0x000003
        val=( tmp_ptr[i] ^ 0x00 ) + ( tmp_ptr[i + 1] ^ 0x00 ) + ( tmp_ptr[i + 2] ^ 0x03 );
        if ( val == 0 )
        {
            //kick out 0x03
            for ( j=i + 2; j<tmp_buf_size - 1; j++ )
                tmp_ptr[j]=tmp_ptr[j + 1];
            
            //and so we should devrease bufsize
            ( *buf_size )--;
        }
    }
}

/**
 * ����SPS,��ȡ��Ƶͼ����ߺ�֡����Ϣ
 *
 * @param buf SPS��������
 * @param nLen SPS���ݵĳ���
 * @param width ͼ����
 * @param height ͼ��߶�
 
 * @�ɹ��򷵻�true , ʧ���򷵻�false
 */
bool CTsUnpack::h264_decode_sps( uint8_t * buf, uint32_t nLen, int32_t &width, int32_t &height, float &fps )
{
    uint32_t StartBit=0;
    fps	=	0.0f;
    de_emulation_prevention( buf, &nLen );
    
    int forbidden_zero_bit=u( 1, buf, StartBit );
    int nal_ref_idc=u( 2, buf, StartBit );
    int nal_unit_type=u( 5, buf, StartBit );
    if ( nal_unit_type == 7 )
    {
        int profile_idc=u( 8, buf, StartBit );
        int constraint_set0_flag=u( 1, buf, StartBit );//(buf[1] & 0x80)>>7;  
        int constraint_set1_flag=u( 1, buf, StartBit );//(buf[1] & 0x40)>>6;  
        int constraint_set2_flag=u( 1, buf, StartBit );//(buf[1] & 0x20)>>5;  
        int constraint_set3_flag=u( 1, buf, StartBit );//(buf[1] & 0x10)>>4;  
        int reserved_zero_4bits=u( 4, buf, StartBit );
        int level_idc=u( 8, buf, StartBit );
        
        int seq_parameter_set_id=Ue( buf, nLen, StartBit );
        
        if ( profile_idc == 100 || profile_idc == 110 ||
            profile_idc == 122 || profile_idc == 144 )
        {
            int chroma_format_idc=Ue( buf, nLen, StartBit );
            if ( chroma_format_idc == 3 )
                int residual_colour_transform_flag=u( 1, buf, StartBit );
            int bit_depth_luma_minus8=Ue( buf, nLen, StartBit );
            int bit_depth_chroma_minus8=Ue( buf, nLen, StartBit );
            int qpprime_y_zero_transform_bypass_flag=u( 1, buf, StartBit );
            int seq_scaling_matrix_present_flag=u( 1, buf, StartBit );
            
            int seq_scaling_list_present_flag[8];
            if ( seq_scaling_matrix_present_flag )
            {
                for ( int i = 0; i < 8; i++ ) {
                    seq_scaling_list_present_flag[i]=u( 1, buf, StartBit );
                }
            }
        }
        int log2_max_frame_num_minus4=Ue( buf, nLen, StartBit );
        int pic_order_cnt_type=Ue( buf, nLen, StartBit );
        if ( pic_order_cnt_type == 0 )
            int log2_max_pic_order_cnt_lsb_minus4=Ue( buf, nLen, StartBit );
        else if ( pic_order_cnt_type == 1 )
        {
            int delta_pic_order_always_zero_flag=u( 1, buf, StartBit );
            int offset_for_non_ref_pic=Se( buf, nLen, StartBit );
            int offset_for_top_to_bottom_field=Se( buf, nLen, StartBit );
            int num_ref_frames_in_pic_order_cnt_cycle=Ue( buf, nLen, StartBit );
            
            int *offset_for_ref_frame=new int[num_ref_frames_in_pic_order_cnt_cycle];
            for ( int i = 0; i < num_ref_frames_in_pic_order_cnt_cycle; i++ )
                offset_for_ref_frame[i]=Se( buf, nLen, StartBit );
            delete[] offset_for_ref_frame;
        }
        int num_ref_frames=Ue( buf, nLen, StartBit );
        int gaps_in_frame_num_value_allowed_flag=u( 1, buf, StartBit );
        int pic_width_in_mbs_minus1=Ue( buf, nLen, StartBit );
        int pic_height_in_map_units_minus1=Ue( buf, nLen, StartBit );
        
        width=( pic_width_in_mbs_minus1 + 1 ) * 16;
        height=( pic_height_in_map_units_minus1 + 1 ) * 16;
        
        int frame_mbs_only_flag=u( 1, buf, StartBit );
        if ( !frame_mbs_only_flag )
            int mb_adaptive_frame_field_flag=u( 1, buf, StartBit );
        
        int direct_8x8_inference_flag=u( 1, buf, StartBit );
        int frame_cropping_flag=u( 1, buf, StartBit );
        if ( frame_cropping_flag )
        {
            int frame_crop_left_offset=Ue( buf, nLen, StartBit );
            int frame_crop_right_offset=Ue( buf, nLen, StartBit );
            int frame_crop_top_offset=Ue( buf, nLen, StartBit );
            int frame_crop_bottom_offset=Ue( buf, nLen, StartBit );
        }
        int vui_parameter_present_flag=u( 1, buf, StartBit );
        if ( vui_parameter_present_flag )
        {
            int aspect_ratio_info_present_flag=u( 1, buf, StartBit );
            if ( aspect_ratio_info_present_flag )
            {
                int aspect_ratio_idc=u( 8, buf, StartBit );
                if ( aspect_ratio_idc == 255 )
                {
                    int sar_width=u( 16, buf, StartBit );
                    int sar_height=u( 16, buf, StartBit );
                }
            }
            int overscan_info_present_flag=u( 1, buf, StartBit );
            if ( overscan_info_present_flag )
                int overscan_appropriate_flagu=u( 1, buf, StartBit );
            int video_signal_type_present_flag=u( 1, buf, StartBit );
            if ( video_signal_type_present_flag )
            {
                int video_format=u( 3, buf, StartBit );
                int video_full_range_flag=u( 1, buf, StartBit );
                int colour_description_present_flag=u( 1, buf, StartBit );
                if ( colour_description_present_flag )
                {
                    int colour_primaries=u( 8, buf, StartBit );
                    int transfer_characteristics=u( 8, buf, StartBit );
                    int matrix_coefficients=u( 8, buf, StartBit );
                }
            }
            int chroma_loc_info_present_flag=u( 1, buf, StartBit );
            if ( chroma_loc_info_present_flag )
            {
                int chroma_sample_loc_type_top_field=Ue( buf, nLen, StartBit );
                int chroma_sample_loc_type_bottom_field=Ue( buf, nLen, StartBit );
            }
            int timing_info_present_flag=u( 1, buf, StartBit );
            
            if ( timing_info_present_flag )
            {
                int num_units_in_tick=u( 32, buf, StartBit );
                int time_scale=u( 32, buf, StartBit );
                fps	=	float(time_scale) / float(num_units_in_tick);
                int fixed_frame_rate_flag=u( 1, buf, StartBit );
                //if ( fixed_frame_rate_flag )
                {
                    fps	=	fps / 2.0f;
                }
            }
        }
        return true;
    }
    else
        return false;
}
