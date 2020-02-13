//
//  TsUnpack.hpp
//  MP4v2
//
//  Created by 周晓林 on 2017/9/13.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#ifndef TsUnpack_hpp
#define TsUnpack_hpp

#include "VideoUnpack.hpp"
#include <vector>
#include <map>
using namespace std;

class CTsUnpack : public CVideoUnpack
{
public:
    CTsUnpack(void);
    ~CTsUnpack(void);
protected:
    virtual bool OnUnpack( uint64_t uSize );
private:
    int32_t		m_iPacketLen;
#pragma pack(push,1)
    //http://www.cnblogs.com/tocy/p/media_container_6-mpegts.html
    struct	TS_Packet_Header // ts包头
    {
        uint32_t	sync_byte					: 8; // 同步字
        uint32_t	transport_error_indicator	: 1; // 传输错误标志
        uint32_t	payload_unit_start_indicator: 1; // 负载起始标志
        uint32_t	transport_priority			: 1; // 传输优先级标志
        uint32_t	PID							: 13;// 指示存储与分组有效负载中的数据类型
        uint32_t	transport_scrambling_control: 2; // 加扰控制标志
        uint32_t	adaptation_field_control	: 2; // 适配域控制标志
        uint32_t	continuity_counter			: 4; // 连续性计数器
        
    };
    
   
    struct	TS_PAT  // 节目关联表
    {
        uint64_t	table_id					: 8;
        uint64_t	section_syntax_indicator	: 1;
        uint64_t	zero						: 1;
        uint64_t	reserved_1					: 2;
        uint64_t	section_length				: 12;
        uint64_t	transport_stream_id			: 16;
        uint64_t	reserved_2					: 2;
        uint64_t	version_number				: 5;
        uint64_t	current_next_indicator		: 1;
        uint64_t	section_number				: 8;
        uint64_t	last_section_number			: 8;
        uint32_t	CRC_32						: 32;
    };
    struct	TS_PAT_PROGRAM
    {
        uint32_t	program_number				: 16;
        uint32_t	reserved_3					: 3;
        union{
            uint32_t	program_map_PID				: 13;
            uint32_t	network_PID					: 13;
        };
    };
    
    struct TS_PMT // 节目映射表
    {
        uint64_t	table_id					: 8;
        uint64_t	section_syntax_indicator	: 1;
        uint64_t	zero						: 1;	//0
        uint64_t	reserved_1					: 2;	//
        uint64_t	section_length				: 12;
        uint64_t	program_number				: 16;
        uint64_t	reserved_2					: 2;
        uint64_t	version_number				: 5;
        uint64_t	current_next_indicator		: 1;
        uint64_t	section_number				: 8;
        uint64_t	last_section_number			: 8;
        
        uint32_t	reserved_3					: 3;
        uint32_t	PCR_PID						: 13;
        uint32_t	reserved_4					: 4;
        uint32_t	program_info_length			: 12;
        uint32_t	CRC_32						: 32;
    };
    struct	TS_PMT_STREAM
    {
        uint64_t	stream_type					: 8;
        uint64_t	reserved_5					: 3;
        uint64_t	elementary_PID				: 13;
        uint64_t	reserved_6					: 4;
        uint64_t	ES_info_length				: 12;
    };
    //http://blog.csdn.net/cabbage2008/article/details/49848937
    //http://blog.csdn.net/u013354805/article/details/51591229
    struct TS_PES
    {
        uint32_t	packet_start_code_prefix	: 24;
        uint32_t	stream_id					: 8;
        
        uint16_t	PES_packet_length;
        
        uint8_t		fix_bit						:2;		//
        uint8_t		PES_scrambling_control		:2;		//PES
        uint8_t		PES_priority				:1;		//PES
        uint8_t		data_alignment_indicator	:1;		//
        uint8_t		copyright					:1;		//
        uint8_t		original_or_copy			:1;		//
        
        uint8_t		PTS_DTS_flags				:2;		//
        uint8_t		ESCR_flag					:1;
        uint8_t		ES_rate_flag				:1;
        uint8_t		DSM_trick_mode_flag			:1;
        uint8_t		additional_copy_info_flag	:1;
        uint8_t		PES_CRC_flag				:1;
        uint8_t		PES_extension_flag			:1;
        
        uint8_t		PES_header_data_length;
    };
#pragma pack(pop)
    /* stream_type
     0x00     ITU-T | ISO/IEC Reserved
     0x01     ISO/IEC 11172-2 Video (mpeg video v1)
     0x02     ITU-T Rec. H.262 | ISO/IEC 13818-2 Video(mpeg video v2)or ISO/IEC 11172-2 constrained parameter video stream
     
     0x03     ISO/IEC 11172-3 Audio (MPEG 1 Audio codec Layer I, Layer II and Layer III audio specifications)
     0x04     ISO/IEC 13818-3 Audio (BC Audio Codec)
     0x05     ITU-T Rec. H.222.0 | ISO/IEC 13818-1 private_sections
     0x06     ITU-T Rec. H.222.0 | ISO/IEC 13818-1 PES packets containing private data
     0x07     ISO/IEC 13522 MHEG
     0x08     ITU-T Rec. H.222.0 | ISO/IEC 13818-1 Annex A DSM-CC
     0x09     ITU-T Rec. H.222.1
     0x0A     ISO/IEC 13818-6 type A
     0x0B     ISO/IEC 13818-6 type B
     0x0C     ISO/IEC 13818-6 type C
     0x0D     ISO/IEC 13818-6 type D
     0x0E     ITU-T Rec. H.222.0 | ISO/IEC 13818-1 auxiliary
     0x0F     ISO/IEC 13818-7 Audio with ADTS transport syntax��aac��
     0x10     ISO/IEC 14496-2 Visual
     0x11     ISO/IEC 14496-3 Audio with the LATM transport syntax as defined in ISO/IEC 14496-3/Amd.1
     0x12     ISO/IEC 14496-1 SL-packetized stream or FlexMux stream carried in PES packets
     0x13     ISO/IEC 14496-1 SL-packetized stream or FlexMux stream carried in ISO/IEC 14496_sections
     0x14     ISO/IEC 13818-6 Synchronized Download Protocol
     0x15     Metadata carried in PES packets
     0x16     Metadata carried in metadata_sections
     0x17     Metadata carried in ISO/IEC 13818-6 Data Carousel
     0x18     Metadata carried in ISO/IEC 13818-6 Object Carousel
     0x19     Metadata carried in ISO/IEC 13818-6 Synchronized Download Protocol
     0x1A     IPMP stream (defined in ISO/IEC 13818-11, MPEG-2 IPMP)
     0x1B     AVC video stream as defined in ITU-T Rec. H.264 | ISO/IEC 14496-10 Video (h.264)
     0x1C     ISO/IEC 14496-3 Audio, without using any additional transport syntax, such as DST, ALS and SLS
     0x1D     ISO/IEC 14496-17 Text
     0x1E     Auxiliary video stream as defined in ISO/IEC 23002-3 (AVS)
     0x1F-0x7E ITU-T Rec. H.222.0 | ISO/IEC 13818-1 Reserved
     0x7F     IPMP stream
     0x80-0xFF User Private
     */
    //�� program_map_PID ��Ϊ key
    map<uint32_t, TS_PAT_PROGRAM>	m_programs;
    struct	TS_MAP_STREAM : public TS_PMT_STREAM
    {
        uint32_t	program_map_PID;
        uint32_t	program_number;
        uint32_t	uPesPending;
        EMediaType	eType;
        CBaseContainer::EVideoCodec	eVideoCodec;
        CBaseContainer::EAudioCodec	eAudioCodec;
        
        uint8_t*	pDataBuf;
        uint32_t	uDataSize;
    };
    map<uint32_t, TS_MAP_STREAM>	m_streams;
    uint32_t	m_progNumber;
    uint32_t	m_elePID_Video;
    uint32_t	m_elePID_Audio;
    int64_t		m_iFrameInd;
    
    bool	AnalysePAT( uint8_t* pPacket );
    bool	AnalysePMT( uint8_t* pPacket, uint32_t uMapID );
    bool	AnalysePES( uint8_t* pPacket, TS_MAP_STREAM& sStream, uint8_t uSize );
    bool	AnalyseSPS( uint8_t* pData, TS_MAP_STREAM& sStream, uint8_t uSize );
    bool	AnalyseADTS( uint8_t* pData, TS_MAP_STREAM& sStream, uint8_t uSize );
    
    bool	AnalyseES( TS_MAP_STREAM& sStream );
    
    EMediaType	GetStreamType( uint32_t uType, CBaseContainer::EVideoCodec& eVideoCodec, CBaseContainer::EAudioCodec& eAudioCodec );
    
    bool h264_decode_sps( uint8_t * buf, uint32_t nLen, int32_t &width, int32_t &height, float &fps );
    
    union	SADTS
    {
        struct
        {
            //fixed
            uint64_t	syncword : 12;	//12	0xFFF
            uint64_t	ID : 1;	//13
            uint64_t	layer : 2;	//15
            uint64_t	protection_absent : 1;	//16
            
            uint64_t	profile : 2;	//18
            uint64_t	sampling_frequency_index : 4;	//22
            uint64_t	private_bit : 1;	//23
            uint64_t	channel_configuration : 3;	//26
            uint64_t	original_copy : 1;	//27
            uint64_t	home : 1;	//28
            //uint64_t	emphasis : 2;	//30
            
            //variable
            uint64_t	copyright_identiflcation_bit : 1;	//29
            uint64_t	copyright_identiflcation_start : 1;	//30
            uint64_t	aac_frame_length : 13;	//43
            uint64_t	adts_buffer_fullness : 11;	//54
            uint64_t	num_of_raw_data_blocks_in_frame : 2;	//56
        };
        uint64_t	adts;
    }; 
};

#endif /* TsUnpack_hpp */
