//
//  BaseContainer.hpp
//  MP4v2
//
//  Created by 周晓林 on 2017/9/13.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#ifndef BaseContainer_hpp
#define BaseContainer_hpp

#include <stdint.h>
#include <stdlib.h>
#include <mm_malloc.h>
#include <array>
#include <string>
#include <vector>
#include <mutex>
#include <fstream>
using namespace std;
#include "faac.h"
class CI_Space_AverageSize
{
public:
    CI_Space_AverageSize( void );
    virtual ~CI_Space_AverageSize( void );
    
    int AverageValue();//�ؼ�֡������ݴ�С��ƽ��ֵ
    void StatisticsDataSize( int iValue, bool bIskeyFrame = false );//���ݴ�Сͳ��
    void Clear();
protected:
    //GListT< int > m_ValueDataSizeArray;//�ؼ�֡������ݴ�С�����鼯��
    int m_CurrentValue;//��ǰ���ݴ�С
    
    int m_MaxDataSize;//������ݴ�С
};

class CBaseContainer
{
public:
    CBaseContainer(void);
    virtual ~CBaseContainer(void);
    string m_CstrFilePath;//��Ƶ�ļ������ַ
    
    CI_Space_AverageSize m_I_Space_AverageSize;//����ͳ��
    int m_VolumeNumber;//�־���
    bool isValid() { return m_bOpened; }
    virtual bool OpenFile( const char* szFilePath, int64_t iSplitSize )
    {
        if ( m_bOpened ) return false;
        m_csWrite.lock();
        m_fileHeads.clear();
        m_iSplitSize	= iSplitSize >= 0 ? iSplitSize : 0;
        if(  m_iSplitSize > 0 ) m_CstrFilePath.append( (char*)szFilePath );
        m_outFile.open( szFilePath, ios::out | ios_base::trunc | ios_base::binary );
        m_csWrite.unlock();
        m_bOpened	= m_outFile.is_open();
        return m_bOpened;
    }
    
#pragma pack(1)
    enum nal_unit_type_e
    {
        NAL_UNKNOWN     = 0,
        NAL_SLICE       = 1,
        NAL_SLICE_DPA   = 2,
        NAL_SLICE_DPB   = 3,
        NAL_SLICE_DPC   = 4,
        NAL_SLICE_IDR   = 5,    /* ref_idc != 0 */
        NAL_SEI         = 6,    /* ref_idc == 0 */
        NAL_SPS         = 7,
        NAL_PPS         = 8,
        NAL_AUD         = 9,
        NAL_EOSEQ       = 10,
        NAL_EOSTREAM    = 11,
        NAL_FILLER      = 12,
        /* ref_idc == 0 for 6,9,10,11,12 */
    };
    
    enum EVideoCodec
    {
        VC_UNKNOW,
        VC_H264,
        VC_XVID,
        VC_DIVX,
        VC_MPG1,
        VC_MPG2,
    };
    
    struct	SVideoParams
    {
        bool		bHasVideo;
        EVideoCodec	eCodec;
        //EVideoEncoder	eEncoder;		//��ǰѡ��ı�����
        //EVideoRateMode	eRateMode;		//���ʿ��Ʒ�ʽ
        //EVideoProfile	eProfile[4];
        //EVideoPreset	ePreset[4];
        //bool		bVfr;
        bool		bAnnexb;
        //bool		bMaxSpeed;		//����ٶ�, x264����Ϊ���̱߳��룬��b_sliced_threadsΪ0��ͼ�����ź�תYUVʹ�ö��߳�
        //bool		bLowLatency;	//���ӳ�
        int32_t		iWidth;			//��Ƶ�Ŀ��(��������������)
        int32_t		iHeight;		//��Ƶ�ĸ߶�(��������������)
        //int32_t		iWidthSet;		//��Ƶ�Ŀ��(���õ�)
        //int32_t		iHeightSet;		//��Ƶ�ĸ߶�(���õ�)
        float		fFrameRate;		//��Ƶ��֡��
        //EVideoCSP	eVideoCSP;		//��Ƶ����ɫ�ռ�
        //int32_t		iBitrate;
        //int32_t		iBitrateMax;
        //int32_t		iVbvBuffer;
        //int32_t		iGopMax;
        //int32_t		iGopMin;
        //int32_t		iRefFrames;
        int32_t		iBFrames;
        int32_t		iBFramePyramid;
    };
    enum	EAudioInSamples		//������Ƶ�Ĳ���Ƶ��
    {
        Aud_Inp_Samp_11025	= 11025,		//11Khz
        Aud_Inp_Samp_22050	= 22050,		//22Khz
        Aud_Inp_Samp_44100	= 44100,		//44Khz
        Aud_Inp_Samp_48000	= 48000		//48Khz
    };
    
    //��Ƶ��������
    enum	EAudioCodec
    {
        AC_UNKNOW,
        
        AC_AAC,
        AC_PCM,
        AC_MP3,
        
        AC_AC3,
        AC_DTS,
        AC_MP2AAC
    };
    
    struct	SAudioParams
    {
        bool		bHasAudio;
        bool		bUseAdts;
        EAudioCodec	eCodec;	//��Ƶ������
        EAudioInSamples	eSamples;
        int16_t		nFaacInputBits;
        int16_t		nChannels;		//��Ƶ����������0��ʾû����Ƶ��1=��������2=˫����
        int16_t		nBitsPerSample;	//��Ƶ��ԭʼλ����8λ/16λ��
        uint32_t	nSamplesPerSec;	//��Ƶ��ԭʼ������
        int32_t		iBitrate;		//��Ƶ��������ʣ�kbps��
        
        uint32_t	uEncSamples;
        uint16_t	wESConfigSize;
        union
        {
            uint8_t		chAacDecoderInfo[2];
            uint8_t		chMp3Info[100];
            uint8_t		chPcmInfo[100];
        };
        //SADTS		adts;
    };
#pragma pack()
    
    typedef struct x264_nal_t
    {
        int i_ref_idc;  /* nal_priority_e */
        int i_type;     /* nal_unit_type_e */
        int b_long_startcode;
        int i_first_mb; /* If this NAL is a slice, the index of the first MB in the slice. */
        int i_last_mb;  /* If this NAL is a slice, the index of the last MB in the slice. */
        
        /* Size of payload (including any padding) in bytes. */
        int     i_payload;
        /* If param->b_annexb is set, Annex-B bytestream with startcode.
         * Otherwise, startcode is replaced with a 4-byte size.
         * This size is the size used in mp4/similar muxing; it is equal to i_payload-4 */
        uint8_t *p_payload;
        
        /* Size of padding in bytes. */
        int i_padding;
    } x264_nal_t;
    
    virtual bool SetParam( SVideoParams *pVidParams, SAudioParams* pAudParams );
    virtual const SVideoParams& VideoParams() { return m_videoParams; }
    virtual const SAudioParams& AudioParams() { return m_audioParams; }
    virtual bool WriteHeaders( x264_nal_t *p_nal )	= 0;
    virtual bool WriteFrame( uint8_t *p_nal, uint32_t i_size, int64_t i_pts, int64_t i_dts );
    virtual bool WriteAudio( int64_t dts, uint8_t *pData, uint32_t iSize );
    virtual bool CloseFile();
public:
    static uint64_t dbl2int( double value )	{
        return *((uint64_t*)&value);
    }
    static uint16_t endianFix16( uint16_t x )
    {
        return ( x << 8 ) + ( x >> 8 );
    }
    static uint32_t endianFix32( uint32_t x )
    {
        return ( x << 24 ) + ( ( x << 8 ) & 0xff0000 ) + ( ( x >> 8 ) & 0xff00 ) + ( x >> 24 );
    }
    static uint64_t endianFix64( uint64_t x )
    {
        return endianFix32( x >> 32 ) + ( (uint64_t)endianFix32( x & 0xFFFFFFFF ) << 32 );
    }
    static void MinimumDivisor( int& i1, int& i2 )
    {
        bool	be	= true;
        int		iMaxDiv	= max( i1 / 2, i2 / 2 );
        iMaxDiv	= min( i2, min( iMaxDiv, i1 ) );
        if ( iMaxDiv == 0 ) be	= false;
        
        while( be )
        {
            be	= false;
            for ( int i = 2; i <= iMaxDiv; ++i )
            {
                if ( ( i1 % i ) == 0 && ( i2 % i ) == 0 )
                {
                    i2 /= i;
                    i1 /= i;
                    be	= true;
                    iMaxDiv	= max( i1 / 2, i2 / 2 );
                    iMaxDiv	= min( i2, min( iMaxDiv, i1 ) );
                    if ( iMaxDiv == 0 ) be	= false;
                    break;
                }
            }
        }
    }
    
    struct  structIFrameData
    {
        uint8_t * p_nal;
        uint32_t  i_size;
        int64_t   i_pts;
        int64_t   i_dts;
    };
    
    structIFrameData m_I_FrameData;//�־�ʱ����ؼ�֡��������һ����Ƶ�ļ��ĵ�һ֡Ϊ�ؼ�֡
    
protected:
    bool		m_bOpened;
    ofstream	m_outFile;
    uint8_t*	m_pCache;
    uint32_t	m_uCurPos;
    uint32_t	m_uCurMax;
    uint64_t	m_iTotal;
    
    int64_t		m_iDelayFrames;
    int64_t		m_iVideoStartDts;
    int64_t		m_iAudioStartDts;
    int64_t		m_iLastAudioDts;
    
    int64_t		m_iInitDelta;
    double		m_dTimeBase;
    int64_t		m_iCurrDts;
    int64_t		m_iCurrCts;
    int64_t		m_iPrevFrameId;
    int64_t		m_iLastFrameId;
    
    int64_t		m_iSplitSize;
    
    int64_t		m_iVideoFrameNum;
    int64_t		m_iAudioFrameNum;
    bool		m_bDtsCompress;
    bool		m_bHeadWriteDone;
    nal_unit_type_e	m_eFrameType;
    
    SVideoParams	m_videoParams;
    SAudioParams	m_audioParams;
    
    struct CByteArray
    {
        uint8_t*	pArray;
        uint32_t	uSize;
        CByteArray( uint8_t* pBuf = NULL, uint32_t uLen = 0 )
        {
            if ( pBuf && uLen )
            {
                pArray	= (uint8_t*)malloc( uLen );
                memcpy( pArray, pBuf, uLen );
                uSize	= uLen;
            }
            else
            {
                pArray	= NULL;
                uSize	= 0;
            }
        }
        CByteArray( const CByteArray& other )
        {
            if ( other.pArray && other.uSize )
            {
                pArray	= (uint8_t*)malloc( other.uSize );
                memcpy( pArray, other.pArray, other.uSize );
                uSize	= other.uSize;
            }
            else
            {
                pArray	= NULL;
                uSize	= 0;
            }
        }
        ~CByteArray()
        {
            if ( pArray ) free( pArray );
            pArray	= NULL;
            uSize	= 0;
        }
    };
    
    vector<CByteArray>	m_fileHeads;
    recursive_mutex		m_csWrite;
    
    void putByte( uint8_t b )	{ appendData( &b, 1 ); }
    void putTag( const char* tag )	{ while( *tag ) appendData( (uint8_t*)tag++, 1 ); }
    void putBE16( uint16_t val )	{ putByte( val >> 8 ); putByte( val & 0xFF ); }
    void putBE24( uint32_t val )	{ putBE16( val >> 8 ); putByte( val & 0xFF ); }
    void putBE32( uint32_t val )	{
        putByte( ( val >> 24 ) & 0xFF );
        putByte( ( val >> 16 ) & 0xFF );
        putByte( ( val >> 8 ) & 0xFF );
        putByte( ( val ) & 0xFF );
    }
    void putBE64( uint64_t val )	{ putBE32( val >> 32 ); putBE32( val & 0xFFFFFFFF ); }
    void putLE16( uint16_t val )	{ appendData( (uint8_t*)&val, 2 ); }
    void putLE24( uint32_t val )	{ appendData( (uint8_t*)&val, 3 ); }
    void putLE32( uint32_t val )	{ appendData( (uint8_t*)&val, 4 ); }
    void putLE64( uint64_t val )	{ appendData( (uint8_t*)&val, 8 ); }
    
    
    uint32_t m_ns;
    bool appendData( const uint8_t* data, uint32_t size )
    {
        uint32_t	ns	= m_uCurPos + size;
        if ( ns > m_uCurMax )
        {
            ns	= ( ( ( ns + 127 ) / 128 ) + 1 ) * 128;
            /*if( m_pCache != NULL )
             {
             delete []  m_pCache;
             m_pCache = NULL;
             }*/
            void*	dp	= realloc( m_pCache, ns );//�ı��ڴ��С����������С���޸ģ�
            if ( !dp )
            {
                return false;
            }
            m_pCache	= (uint8_t*)dp;
            m_uCurMax	= m_ns = ns;
            /*m_pCache = new uint8_t[m_uCurMax+1];*/
            
            
        }
        //ZeroMemory( m_pCache, m_ns+1 );
        memcpy( m_pCache + m_uCurPos, data, size );//����Ƶ֡���ݴ���
        m_uCurPos	+= size;
        return true;
    }
    
    virtual bool flushData()
    {
        //������Ƶ���ݴ�����Ƶ�ļ���
        if ( m_outFile.is_open() )
        {
            if ( m_uCurPos )
            {
                m_outFile.write( (char*)m_pCache, m_uCurPos );
                
                m_iTotal	+= m_uCurPos;
                m_uCurPos	= 0;
            }
            return true;
        }
        return false;
    }
    
    void InitContainerValue();
    bool extractHead( uint8_t*& p_nal, uint32_t& i_size );
    void extractSpsPps( x264_nal_t p_nal[3], int& sps_size, int& pps_size, int& sei_size, uint8_t* &sps, uint8_t* &pps, uint8_t* &sei );
    //�־�����Ƶ�ļ�
    virtual bool SubsectionOpenFile( const char* szFilePath )
    {
        if ( m_bOpened ) return false;
        //m_csWrite.lock();
        m_outFile.open( szFilePath, ios::out | ios_base::trunc | ios_base::binary );
        //m_csWrite.unlock();
        m_bOpened	= m_outFile.is_open();
        return m_bOpened;
    }
    
    faacEncHandle	m_hFaac;				//AAC ���������
    unsigned long	m_uFaacInputSamples;	//��ʼ�� AAC ������ʱ���õ���ÿ��Ҫ���������Ƶ֡����
    unsigned long	m_uFaacInputDone;		//���������Ƶ��AAC������Ҫ���֡���ֳ�Ƭ�ϣ���ǰƬ�����е�֡��
    unsigned long	m_uFaacMaxOutBytes;		//��ʼ�� AAC ������ʱ���õ���ÿ��Ҫ�����������󳤶�
    uint8_t*		m_pFaacInputBuffer;		//���� AAC �������� Buffer
    uint8_t*		m_pFaacOutputBuffer;	//AAC �����õ������� Buffer
    bool			m_bAacEncodeing;
};
#endif /* BaseContainer_hpp */
