//
//  AviUnpack.hpp
//  MP4v2
//
//  Created by 周晓林 on 2017/9/14.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#ifndef AviUnpack_hpp
#define AviUnpack_hpp

#include "avidefine.h"
#include "VideoUnpack.hpp"


//
// ============ class for unpack AVI to video and audio =================
//

class CAviUnpack : public CVideoUnpack
{
public:
    CAviUnpack(void);
    ~CAviUnpack(void);
    
protected:
    virtual bool OnUnpack( uint64_t uSize );
private:
    
    struct	SRiffList
    {
        uint32_t	dwChunk;
        uint32_t	dwSize;
        uint32_t	dwType;
    };
    SRiffList	m_sLayer[8];
    uint32_t	m_uRiffIndex;
    
    struct	STrackInfo
    {
        bool				bEnabled;
        AVISTREAMHEADER		aviStream;
        union
        {
            SBitmapInfoHeader	bitmapInfo;
            SWaveFormatEx		waveFormat;
        };
        VideoPropHeader		vidProperty;
    };
    int64_t			m_iFrameInd;
    STrackInfo*		m_aviTrack;
    uint32_t		m_uTrackCount;
    uint32_t		m_uTrackOfType[4];
    
    AVIMAINHEADER	m_aviMainHead;
    
    uint64_t AnalyseData( SRiffList* pList, uint64_t uSize, uint32_t uType );
};
#endif /* AviUnpack_hpp */
