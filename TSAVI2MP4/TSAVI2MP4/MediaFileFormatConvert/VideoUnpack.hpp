//
//  VideoUnpack.hpp
//  MP4v2
//
//  Created by 周晓林 on 2017/9/13.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#ifndef VideoUnpack_hpp
#define VideoUnpack_hpp

#include <stdint.h>
#include <stdlib.h>
#include <mm_malloc.h>
#include <fstream>
using namespace std;
#include "BaseContainer.hpp"

class CVideoUnpack
{
public:
   
    bool        m_hasAudio;

    CVideoUnpack(void);
    ~CVideoUnpack(void);
    float GetProgress() { return  double( m_uFilePos ) / double( m_uFileSize ); }
    
    bool Unpack( const char* szInpFilePath, const char* szOutFilePath ,bool hasAudio);
protected:
    char*	m_szOutFilePath;
    uint32_t	m_uOutNameSize;
    CBaseContainer::SAudioParams		m_audioParam;
    CBaseContainer::SVideoParams		m_videoParam;
    CBaseContainer*	m_outFile;
    virtual bool OnUnpack( uint64_t uSize )	= 0;
    uint8_t* Read( uint32_t uSize );
    bool Seek( int64_t iSeek );
    inline uint32_t endianFix32( uint32_t x )
    {
        return ( x << 24 ) + ( ( x << 8 ) & 0xff0000 ) + ( ( x >> 8 ) & 0xff00 ) + ( x >> 24 );
    }
    enum	EMediaType
    {
        eMedTypeVideo,
        eMedTypeAudio,
        eMedTypeMidi,
        eMedTypeText
    };

private:
    ifstream    m_inFile;
    uint64_t    m_uFileSize;
    uint64_t    m_uFilePos;
    uint8_t*	m_pFileBuffer;
    uint32_t	m_uBufSize;
    uint32_t	m_uBufAlloc;
    uint32_t	m_uBufOffset;
    
};
#endif /* VideoUnpack_hpp */
