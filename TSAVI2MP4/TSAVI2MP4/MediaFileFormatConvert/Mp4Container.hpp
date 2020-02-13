//
//  Mp4Container.hpp
//  MP4v2
//
//  Created by 周晓林 on 2017/9/13.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#ifndef Mp4Container_hpp
#define Mp4Container_hpp

#include "BaseContainer.hpp"
#include <mp4v2/mp4v2.h>

#include <mutex>
#include <future>
#include <thread>
#include <functional>
using namespace std;


#define        _MP4WRITE_CACHE_MAX_SIZE    0//1024 * 1024 * 4

class CMp4Container    : public CBaseContainer
{
public:
    CMp4Container(void);
    ~CMp4Container(void);
    virtual bool OpenFile( const char* szFilePath, int64_t iSplitSize );
    virtual bool WriteHeaders( x264_nal_t *p_nal );
    virtual bool WriteFrame( uint8_t *p_nal, uint32_t i_size, int64_t i_pts, int64_t i_dts );
    virtual bool WriteAudio( int64_t dts, uint8_t *pData, uint32_t iSize );
    virtual bool CloseFile();
private:
    bool            m_bIsClose;
    void  Subsection();//µ± ”∆µ ˝æ›≥ˆ»Î¡øµΩ¥Ô∑÷æÌ¥Û–° ±£¨Ω¯––∑÷æÌ
    x264_nal_t        m_nal[3];
    bool            m_bIsSubsection;
    MP4FileHandle    m_hMP4;
    uint32_t        m_uTimeScale;
    MP4TrackId        m_TrackVideoId;
    MP4TrackId        m_TrackAudioId;
#if _MP4WRITE_CACHE_MAX_SIZE
    uint32_t        m_uCacheMax;
    uint8_t*        m_pWriteCache;
    uint32_t        m_uCacheSize;
    uint8_t*        m_pWriteCache2;
    
    struct SMp4Write
    {
        MP4TrackId    trackId;
        uint64_t    uDuration;
        uint32_t    uDataSize;
        bool        bIsKeyFrame;
        uint8_t        datas[1];
    };
    vector<SMp4Write*>*    m_pCacheList;
    vector<SMp4Write*>*    m_pCacheList2;
    
    mutex            m_muSwapCache;
    promise<bool>    m_prom;
    future<bool>    m_futu;
    thread*            m_pThreadWrite;
    static void        ThreadWrite( CMp4Container *pThis );
    bool MyMP4WriteSample(
                          MP4FileHandle  hFile,
                          MP4TrackId     trackId,
                          const uint8_t* pBytes,
                          uint32_t       numBytes,
                          MP4Duration    duration = MP4_INVALID_DURATION,
                          MP4Duration    renderingOffset = 0,
                          bool           isSyncSample = true );
#else
#define    MyMP4WriteSample    MP4WriteSample
#endif // _USE_MP4WRITE_CACHE
};


#endif /* Mp4Container_hpp */
