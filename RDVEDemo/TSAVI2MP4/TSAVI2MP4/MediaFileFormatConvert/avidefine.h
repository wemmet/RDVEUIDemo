//
//  avidefine.h
//  MP4v2
//
//  Created by 周晓林 on 2017/9/14.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#ifndef avidefine_h
#define avidefine_h

#include <stdint.h>

typedef uint32_t	FourCC;         /* a four character code */

#if !defined NUMELMS
#define NUMELMS(aa) (sizeof(aa)/sizeof((aa)[0]))
#endif


#pragma pack(push,2)
//#pragma pack(2)

#define FCC(ch4) ((((uint32_t)(ch4) & 0xFF) << 24) |     \
(((uint32_t)(ch4) & 0xFF00) << 8) |    \
(((uint32_t)(ch4) & 0xFF0000) >> 8) |  \
(((uint32_t)(ch4) & 0xFF000000) >> 24))

typedef struct _riffchunk {
    FourCC fcc;
    uint32_t  cb;
} RIFFCHUNK, * LPRIFFCHUNK;
typedef struct _rifflist {
    FourCC fcc;
    uint32_t  cb;
    FourCC fccListType;
} RIFFLIST, * LPRIFFLIST;

#define RIFFROUND(cb) ((cb) + ((cb)&1))
#define RIFFNEXT(pChunk) (LPRIFFCHUNK)((LPBYTE)(pChunk) \
+ sizeof(RIFFCHUNK) \
+ RIFFROUND(((LPRIFFCHUNK)pChunk)->cb))


//
// ==================== avi header structures ===========================
//

// main header for the avi file (compatibility header)
//
#define ckidMAINAVIHEADER FCC('avih')
typedef struct _avimainheader {
    FourCC fcc;                    // 'avih'
    uint32_t  cb;                     // size of this structure -8
    uint32_t  dwMicroSecPerFrame;     // frame display rate (or 0L)
    uint32_t  dwMaxBytesPerSec;       // max. transfer rate
    uint32_t  dwPaddingGranularity;   // pad to multiples of this size; normally 2K.
    uint32_t  dwFlags;                // the ever-present flags
#define AVIF_HASINDEX        0x00000010 // Index at end of file?
#define AVIF_MUSTUSEINDEX    0x00000020
#define AVIF_ISINTERLEAVED   0x00000100
#define AVIF_TRUSTCKTYPE     0x00000800 // Use CKType to find key frames
#define AVIF_WASCAPTUREFILE  0x00010000
#define AVIF_COPYRIGHTED     0x00020000
    uint32_t  dwTotalFrames;          // # frames in first movi list
    uint32_t  dwInitialFrames;
    uint32_t  dwStreams;
    uint32_t  dwSuggestedBufferSize;
    uint32_t  dwWidth;
    uint32_t  dwHeight;
    uint32_t  dwReserved[4];
} AVIMAINHEADER;

#define ckidODML          FCC('odml')
#define ckidAVIEXTHEADER  FCC('dmlh')
typedef struct _aviextheader {
    FourCC  fcc;                    // 'dmlh'
    uint32_t   cb;                     // size of this structure -8
    uint32_t   dwGrandFrames;          // total number of frames in the file
    uint32_t   dwFuture[61];           // to be defined later
} AVIEXTHEADER;

//
// structure of an AVI stream header riff chunk
//
#define ckidSTREAMLIST   FCC('strl')

#ifndef ckidSTREAMHEADER
#define ckidSTREAMHEADER FCC('strh')
#endif
typedef struct _avistreamheader {
    FourCC fcc;          // 'strh'
    uint32_t  cb;           // size of this structure - 8
    
    FourCC fccType;      // stream type codes
    
#ifndef streamtypeVIDEO
#define streamtypeVIDEO FCC('vids')
#define streamtypeAUDIO FCC('auds')
#define streamtypeMIDI  FCC('mids')
#define streamtypeTEXT  FCC('txts')
#endif
    
    FourCC fccHandler;
    uint32_t  dwFlags;
#define AVISF_DISABLED          0x00000001
#define AVISF_VIDEO_PALCHANGES  0x00010000
    
    uint16_t  wPriority;
    uint16_t  wLanguage;
    uint32_t  dwInitialFrames;
    uint32_t  dwScale;
    uint32_t  dwRate;       // dwRate/dwScale is stream tick rate in ticks/sec
    uint32_t  dwStart;
    uint32_t  dwLength;
    uint32_t  dwSuggestedBufferSize;
    uint32_t  dwQuality;
    uint32_t  dwSampleSize;
    struct {
        short int left;
        short int top;
        short int right;
        short int bottom;
    }   rcFrame;
} AVISTREAMHEADER;


//
// structure of an AVI stream format chunk
//
#ifndef ckidSTREAMFORMAT
#define ckidSTREAMFORMAT FCC('strf')
#endif
//
// avi stream formats are different for each stream type
//
// BITMAPINFOHEADER for video streams
// WAVEFORMATEX or PCMWAVEFORMAT for audio streams
// nothing for text streams
// nothing for midi streams


#pragma warning(disable:4200)
//
// structure of old style AVI index
//
#define ckidAVIOLDINDEX FCC('idx1')
typedef struct _avioldindex {
    FourCC  fcc;        // 'idx1'
    uint32_t   cb;         // size of this structure -8
    struct _avioldindex_entry {
        uint32_t   dwChunkId;
        uint32_t   dwFlags;
        
#ifndef AVIIF_LIST
#define AVIIF_LIST       0x00000001
#define AVIIF_KEYFRAME   0x00000010
#endif
        
#define AVIIF_NO_TIME    0x00000100
#define AVIIF_COMPRESSOR 0x0FFF0000  // unused?
        uint32_t   dwOffset;    // offset of riff chunk header for the data
        uint32_t   dwSize;      // size of the data (excluding riff header size)
    } aIndex[];          // size of this array
} AVIOLDINDEX;


//
// ============ structures for timecode in an AVI file =================
//

#ifndef TIMECODE_DEFINED
#define TIMECODE_DEFINED

// defined
// timecode time structure
//
typedef union _timecode {
    struct {
        uint16_t   wFrameRate;
        uint16_t   wFrameFract;
        int32_t   cFrames;
    };
    uint64_t  qw;
} TIMECODE;

#endif // TIMECODE_DEFINED

#define TIMECODE_RATE_30DROP 0   // this MUST be zero

// struct for all the SMPTE timecode info
//
typedef struct _timecodedata {
    TIMECODE time;
    uint32_t    dwSMPTEflags;
    uint32_t    dwUser;
} TIMECODEDATA;

// dwSMPTEflags masks/values
//
#define TIMECODE_SMPTE_BINARY_GROUP 0x07
#define TIMECODE_SMPTE_COLOR_FRAME  0x08

//
// ============ structures for new style AVI indexes =================
//

// index type codes
//
#define AVI_INDEX_OF_INDEXES       0x00
#define AVI_INDEX_OF_CHUNKS        0x01
#define AVI_INDEX_OF_TIMED_CHUNKS  0x02
#define AVI_INDEX_OF_SUB_2FIELD    0x03
#define AVI_INDEX_IS_DATA          0x80

// index subtype codes
//
#define AVI_INDEX_SUB_DEFAULT     0x00

// INDEX_OF_CHUNKS subtype codes
//
#define AVI_INDEX_SUB_2FIELD      0x01

// meta structure of all avi indexes
//
typedef struct _avimetaindex {
    FourCC fcc;
    uint32_t   cb;
    uint16_t   wLongsPerEntry;
    uint8_t   bIndexSubType;
    uint8_t   bIndexType;
    uint32_t  nEntriesInUse;
    uint32_t  dwChunkId;
    uint32_t  dwReserved[3];
    uint32_t  adwIndex[];
} AVIMETAINDEX;

#define STDINDEXSIZE 0x4000
#define NUMINDEX(wLongsPerEntry) ((STDINDEXSIZE-32)/4/(wLongsPerEntry))
#define NUMINDEXFILL(wLongsPerEntry) ((STDINDEXSIZE/4) - NUMINDEX(wLongsPerEntry))

// structure of a super index (INDEX_OF_INDEXES)
//
#define ckidAVISUPERINDEX FCC('indx')
typedef struct _avisuperindex {
    FourCC   fcc;               // 'indx'
    uint32_t     cb;                // size of this structure
    uint16_t     wLongsPerEntry;    // ==4
    uint8_t     bIndexSubType;     // ==0 (frame index) or AVI_INDEX_SUB_2FIELD
    uint8_t     bIndexType;        // ==AVI_INDEX_OF_INDEXES
    uint32_t    nEntriesInUse;     // offset of next unused entry in aIndex
    uint32_t    dwChunkId;         // chunk ID of chunks being indexed, (i.e. RGB8)
    uint32_t    dwReserved[3];     // must be 0
    struct _avisuperindex_entry {
        uint64_t qwOffset;    // 64 bit offset to sub index chunk
        uint32_t    dwSize;       // 32 bit size of sub index chunk
        uint32_t    dwDuration;   // time span of subindex chunk (in stream ticks)
    } aIndex[NUMINDEX(4)];
} AVISUPERINDEX;
#define Valid_SUPERINDEX(pi) (*(uint32_t *)(&((pi)->wLongsPerEntry)) == (4 | (AVI_INDEX_OF_INDEXES << 24)))

// struct of a standard index (AVI_INDEX_OF_CHUNKS)
//
typedef struct _avistdindex_entry {
    uint32_t dwOffset;       // 32 bit offset to data (points to data, not riff header)
    uint32_t dwSize;         // 31 bit size of data (does not include size of riff header), bit 31 is deltaframe bit
} AVISTDINDEX_ENTRY;
#define AVISTDINDEX_DELTAFRAME ( 0x80000000) // Delta frames have the high bit set
#define AVISTDINDEX_SIZEMASK   (~0x80000000)

typedef struct _avistdindex {
    FourCC   fcc;               // 'indx' or '##ix'
    uint32_t     cb;                // size of this structure
    uint16_t     wLongsPerEntry;    // ==2
    uint8_t     bIndexSubType;     // ==0
    uint8_t     bIndexType;        // ==AVI_INDEX_OF_CHUNKS
    uint32_t    nEntriesInUse;     // offset of next unused entry in aIndex
    uint32_t    dwChunkId;         // chunk ID of chunks being indexed, (i.e. RGB8)
    uint64_t qwBaseOffset;     // base offset that all index intries are relative to
    uint32_t    dwReserved_3;      // must be 0
    AVISTDINDEX_ENTRY aIndex[NUMINDEX(2)];
} AVISTDINDEX;

// struct of a time variant standard index (AVI_INDEX_OF_TIMED_CHUNKS)
//
typedef struct _avitimedindex_entry {
    uint32_t dwOffset;       // 32 bit offset to data (points to data, not riff header)
    uint32_t dwSize;         // 31 bit size of data (does not include size of riff header) (high bit is deltaframe bit)
    uint32_t dwDuration;     // how much time the chunk should be played (in stream ticks)
} AVITIMEDINDEX_ENTRY;

typedef struct _avitimedindex {
    FourCC   fcc;               // 'indx' or '##ix'
    uint32_t     cb;                // size of this structure
    uint16_t     wLongsPerEntry;    // ==3
    uint8_t     bIndexSubType;     // ==0
    uint8_t     bIndexType;        // ==AVI_INDEX_OF_TIMED_CHUNKS
    uint32_t    nEntriesInUse;     // offset of next unused entry in aIndex
    uint32_t    dwChunkId;         // chunk ID of chunks being indexed, (i.e. RGB8)
    uint64_t qwBaseOffset;     // base offset that all index intries are relative to
    uint32_t    dwReserved_3;      // must be 0
    AVITIMEDINDEX_ENTRY aIndex[NUMINDEX(3)];
    uint32_t adwTrailingFill[NUMINDEXFILL(3)]; // to align struct to correct size
} AVITIMEDINDEX;

// structure of a timecode stream
//
typedef struct _avitimecodeindex {
    FourCC   fcc;               // 'indx' or '##ix'
    uint32_t     cb;                // size of this structure
    uint16_t     wLongsPerEntry;    // ==4
    uint8_t     bIndexSubType;     // ==0
    uint8_t     bIndexType;        // ==AVI_INDEX_IS_DATA
    uint32_t    nEntriesInUse;     // offset of next unused entry in aIndex
    uint32_t    dwChunkId;         // 'time'
    uint32_t    dwReserved[3];     // must be 0
    TIMECODEDATA aIndex[NUMINDEX(sizeof(TIMECODEDATA)/sizeof(int32_t))];
} AVITIMECODEINDEX;

// structure of a timecode discontinuity list (when wLongsPerEntry == 7)
//
typedef struct _avitcdlindex_entry {
    uint32_t    dwTick;           // stream tick time that maps to this timecode value
    TIMECODE time;
    uint32_t    dwSMPTEflags;
    uint32_t    dwUser;
    char    szReelId[12];
} AVITCDLINDEX_ENTRY;

typedef struct _avitcdlindex {
    FourCC   fcc;               // 'indx' or '##ix'
    uint32_t     cb;                // size of this structure
    uint16_t     wLongsPerEntry;    // ==7 (must be 4 or more all 'tcdl' indexes
    uint8_t     bIndexSubType;     // ==0
    uint8_t     bIndexType;        // ==AVI_INDEX_IS_DATA
    uint32_t    nEntriesInUse;     // offset of next unused entry in aIndex
    uint32_t    dwChunkId;         // 'tcdl'
    uint32_t    dwReserved[3];     // must be 0
    AVITCDLINDEX_ENTRY aIndex[NUMINDEX(7)];
    uint32_t adwTrailingFill[NUMINDEXFILL(7)]; // to align struct to correct size
} AVITCDLINDEX;

typedef struct _avifieldindex_chunk {
    FourCC   fcc;               // 'ix##'
    uint32_t    cb;                // size of this structure
    uint16_t     wLongsPerEntry;    // must be 3 (size of each entry in
    // aIndex array)
    uint8_t     bIndexSubType;     // AVI_INDEX_2FIELD
    uint8_t     bIndexType;        // AVI_INDEX_OF_CHUNKS
    uint32_t    nEntriesInUse;     //
    uint32_t    dwChunkId;         // '##dc' or '##db'
    uint64_t qwBaseOffset;     // offsets in aIndex array are relative to this
    uint32_t    dwReserved3;       // must be 0
    struct _avifieldindex_entry {
        uint32_t    dwOffset;
        uint32_t    dwSize;         // size of all fields
        // (bit 31 set for NON-keyframes)
        uint32_t    dwOffsetField2; // offset to second field
    } aIndex[  ];
} AVIFIELDINDEX, * PAVIFIELDINDEX;

/* form types, list types, and chunk types */
//#define formtypeAVI             mmioFOURCC('A', 'V', 'I', ' ')
//#define listtypeAVIHEADER       mmioFOURCC('h', 'd', 'r', 'l')
//#define ckidAVIMAINHDR          mmioFOURCC('a', 'v', 'i', 'h')
//#define listtypeSTREAMHEADER    mmioFOURCC('s', 't', 'r', 'l')
//#define ckidSTREAMHEADER        mmioFOURCC('s', 't', 'r', 'h')
//#define ckidSTREAMFORMAT        mmioFOURCC('s', 't', 'r', 'f')
//#define ckidSTREAMHANDLERDATA   mmioFOURCC('s', 't', 'r', 'd')
//#define ckidSTREAMNAME		mmioFOURCC('s', 't', 'r', 'n')
//
//#define listtypeAVIMOVIE        mmioFOURCC('m', 'o', 'v', 'i')
//#define listtypeAVIRECORD       mmioFOURCC('r', 'e', 'c', ' ')
//
//#define ckidAVINEWINDEX         mmioFOURCC('i', 'd', 'x', '1')
//
///*
//** Stream types for the <fccType> field of the stream header.
//*/
//#define streamtypeVIDEO         mmioFOURCC('v', 'i', 'd', 's')
//#define streamtypeAUDIO         mmioFOURCC('a', 'u', 'd', 's')
//#define streamtypeMIDI		mmioFOURCC('m', 'i', 'd', 's')
//#define streamtypeTEXT          mmioFOURCC('t', 'x', 't', 's')
//
///* Basic chunk types */
//#define cktypeDIBbits           aviTWOCC('d', 'b')
//#define cktypeDIBcompressed     aviTWOCC('d', 'c')
//#define cktypePALchange         aviTWOCC('p', 'c')
//#define cktypeWAVEbytes         aviTWOCC('w', 'b')

/* Chunk id to use for extra chunks for padding. */
//#define ckidAVIPADDING          mmioFOURCC('J', 'U', 'N', 'K')

#pragma pack(pop)
//#pragma pack()

#pragma pack(push,1)
struct SWaveFormatEx
{
    uint16_t	wFormatTag;         /* format type */
    uint16_t	nChannels;          /* number of channels (i.e. mono, stereo...) */
    uint32_t	nSamplesPerSec;     /* sample rate */
    uint32_t	nAvgBytesPerSec;    /* for buffer estimation */
    uint16_t	nBlockAlign;        /* block size of data */
    uint16_t	wBitsPerSample;     /* number of bits per sample of mono data */
    uint16_t	cbSize;             /* the count in bytes of the size of */
    /* extra information (after cbSize) */
};
#pragma pack(pop)

struct SBitmapInfoHeader
{
    uint32_t      biSize;
    int32_t       biWidth;
    int32_t       biHeight;
    uint16_t       biPlanes;
    uint16_t       biBitCount;
    uint32_t      biCompression;
    uint32_t      biSizeImage;
    int32_t       biXPelsPerMeter;
    int32_t       biYPelsPerMeter;
    uint32_t      biClrUsed;
    uint32_t      biClrImportant;
};

typedef struct {
    uint32_t CompressedBMHeight;
    uint32_t CompressedBMWidth;
    uint32_t ValidBMHeight;
    uint32_t ValidBMWidth;
    uint32_t ValidBMXOffset;
    uint32_t ValidBMYOffset;
    uint32_t VideoXOffsetInT;
    uint32_t VideoYValidStartLine;
} VIDEO_FIELD_DESC;

typedef struct {
    uint32_t VideoFormatToken;
    uint32_t VideoStandard;
    
    uint32_t dwVerticalRefreshRate;	//����ˢ���ʣ���Ļˢ���ʣ���
    
    uint32_t dwHTotalInT;
    uint32_t dwVTotalInLines;
    
    uint32_t dwFrameAspectRatio;
    uint32_t dwFrameWidthInPixels;
    uint32_t dwFrameHeightInLines;
    
    uint32_t nbFieldPerFrame;
    VIDEO_FIELD_DESC FieldInfo/*[nbFieldPerFrame]*/;
} VideoPropHeader;

#ifndef NONEWWAVE

/* WAVE form wFormatTag IDs */
#define  WAVE_FORMAT_UNKNOWN                    0x0000 /* Microsoft Corporation */
#define	 WAVE_FORMAT_PCM						0x0001
#define  WAVE_FORMAT_ADPCM                      0x0002 /* Microsoft Corporation */
#define  WAVE_FORMAT_IEEE_FLOAT                 0x0003 /* Microsoft Corporation */
#define  WAVE_FORMAT_VSELP                      0x0004 /* Compaq Computer Corp. */
#define  WAVE_FORMAT_IBM_CVSD                   0x0005 /* IBM Corporation */
#define  WAVE_FORMAT_ALAW                       0x0006 /* Microsoft Corporation */
#define  WAVE_FORMAT_MULAW                      0x0007 /* Microsoft Corporation */
#define  WAVE_FORMAT_DTS                        0x0008 /* Microsoft Corporation */
#define  WAVE_FORMAT_DRM                        0x0009 /* Microsoft Corporation */
#define  WAVE_FORMAT_WMAVOICE9                  0x000A /* Microsoft Corporation */
#define  WAVE_FORMAT_WMAVOICE10                 0x000B /* Microsoft Corporation */
#define  WAVE_FORMAT_OKI_ADPCM                  0x0010 /* OKI */
#define  WAVE_FORMAT_DVI_ADPCM                  0x0011 /* Intel Corporation */
#define  WAVE_FORMAT_IMA_ADPCM                  (WAVE_FORMAT_DVI_ADPCM) /*  Intel Corporation */
#define  WAVE_FORMAT_MEDIASPACE_ADPCM           0x0012 /* Videologic */
#define  WAVE_FORMAT_SIERRA_ADPCM               0x0013 /* Sierra Semiconductor Corp */
#define  WAVE_FORMAT_G723_ADPCM                 0x0014 /* Antex Electronics Corporation */
#define  WAVE_FORMAT_DIGISTD                    0x0015 /* DSP Solutions, Inc. */
#define  WAVE_FORMAT_DIGIFIX                    0x0016 /* DSP Solutions, Inc. */
#define  WAVE_FORMAT_DIALOGIC_OKI_ADPCM         0x0017 /* Dialogic Corporation */
#define  WAVE_FORMAT_MEDIAVISION_ADPCM          0x0018 /* Media Vision, Inc. */
#define  WAVE_FORMAT_CU_CODEC                   0x0019 /* Hewlett-Packard Company */
#define  WAVE_FORMAT_YAMAHA_ADPCM               0x0020 /* Yamaha Corporation of America */
#define  WAVE_FORMAT_SONARC                     0x0021 /* Speech Compression */
#define  WAVE_FORMAT_DSPGROUP_TRUESPEECH        0x0022 /* DSP Group, Inc */
#define  WAVE_FORMAT_ECHOSC1                    0x0023 /* Echo Speech Corporation */
#define  WAVE_FORMAT_AUDIOFILE_AF36             0x0024 /* Virtual Music, Inc. */
#define  WAVE_FORMAT_APTX                       0x0025 /* Audio Processing Technology */
#define  WAVE_FORMAT_AUDIOFILE_AF10             0x0026 /* Virtual Music, Inc. */
#define  WAVE_FORMAT_PROSODY_1612               0x0027 /* Aculab plc */
#define  WAVE_FORMAT_LRC                        0x0028 /* Merging Technologies S.A. */
#define  WAVE_FORMAT_DOLBY_AC2                  0x0030 /* Dolby Laboratories */
#define  WAVE_FORMAT_GSM610                     0x0031 /* Microsoft Corporation */
#define  WAVE_FORMAT_MSNAUDIO                   0x0032 /* Microsoft Corporation */
#define  WAVE_FORMAT_ANTEX_ADPCME               0x0033 /* Antex Electronics Corporation */
#define  WAVE_FORMAT_CONTROL_RES_VQLPC          0x0034 /* Control Resources Limited */
#define  WAVE_FORMAT_DIGIREAL                   0x0035 /* DSP Solutions, Inc. */
#define  WAVE_FORMAT_DIGIADPCM                  0x0036 /* DSP Solutions, Inc. */
#define  WAVE_FORMAT_CONTROL_RES_CR10           0x0037 /* Control Resources Limited */
#define  WAVE_FORMAT_NMS_VBXADPCM               0x0038 /* Natural MicroSystems */
#define  WAVE_FORMAT_CS_IMAADPCM                0x0039 /* Crystal Semiconductor IMA ADPCM */
#define  WAVE_FORMAT_ECHOSC3                    0x003A /* Echo Speech Corporation */
#define  WAVE_FORMAT_ROCKWELL_ADPCM             0x003B /* Rockwell International */
#define  WAVE_FORMAT_ROCKWELL_DIGITALK          0x003C /* Rockwell International */
#define  WAVE_FORMAT_XEBEC                      0x003D /* Xebec Multimedia Solutions Limited */
#define  WAVE_FORMAT_G721_ADPCM                 0x0040 /* Antex Electronics Corporation */
#define  WAVE_FORMAT_G728_CELP                  0x0041 /* Antex Electronics Corporation */
#define  WAVE_FORMAT_MSG723                     0x0042 /* Microsoft Corporation */
#define  WAVE_FORMAT_MPEG                       0x0050 /* Microsoft Corporation */
#define  WAVE_FORMAT_RT24                       0x0052 /* InSoft, Inc. */
#define  WAVE_FORMAT_PAC                        0x0053 /* InSoft, Inc. */
#define  WAVE_FORMAT_MPEGLAYER3                 0x0055 /* ISO/MPEG Layer3 Format Tag */
#define  WAVE_FORMAT_LUCENT_G723                0x0059 /* Lucent Technologies */
#define  WAVE_FORMAT_CIRRUS                     0x0060 /* Cirrus Logic */
#define  WAVE_FORMAT_ESPCM                      0x0061 /* ESS Technology */
#define  WAVE_FORMAT_VOXWARE                    0x0062 /* Voxware Inc */
#define  WAVE_FORMAT_CANOPUS_ATRAC              0x0063 /* Canopus, co., Ltd. */
#define  WAVE_FORMAT_G726_ADPCM                 0x0064 /* APICOM */
#define  WAVE_FORMAT_G722_ADPCM                 0x0065 /* APICOM */
#define  WAVE_FORMAT_DSAT_DISPLAY               0x0067 /* Microsoft Corporation */
#define  WAVE_FORMAT_VOXWARE_BYTE_ALIGNED       0x0069 /* Voxware Inc */
#define  WAVE_FORMAT_VOXWARE_AC8                0x0070 /* Voxware Inc */
#define  WAVE_FORMAT_VOXWARE_AC10               0x0071 /* Voxware Inc */
#define  WAVE_FORMAT_VOXWARE_AC16               0x0072 /* Voxware Inc */
#define  WAVE_FORMAT_VOXWARE_AC20               0x0073 /* Voxware Inc */
#define  WAVE_FORMAT_VOXWARE_RT24               0x0074 /* Voxware Inc */
#define  WAVE_FORMAT_VOXWARE_RT29               0x0075 /* Voxware Inc */
#define  WAVE_FORMAT_VOXWARE_RT29HW             0x0076 /* Voxware Inc */
#define  WAVE_FORMAT_VOXWARE_VR12               0x0077 /* Voxware Inc */
#define  WAVE_FORMAT_VOXWARE_VR18               0x0078 /* Voxware Inc */
#define  WAVE_FORMAT_VOXWARE_TQ40               0x0079 /* Voxware Inc */
#define  WAVE_FORMAT_SOFTSOUND                  0x0080 /* Softsound, Ltd. */
#define  WAVE_FORMAT_VOXWARE_TQ60               0x0081 /* Voxware Inc */
#define  WAVE_FORMAT_MSRT24                     0x0082 /* Microsoft Corporation */
#define  WAVE_FORMAT_G729A                      0x0083 /* AT&T Labs, Inc. */
#define  WAVE_FORMAT_MVI_MVI2                   0x0084 /* Motion Pixels */
#define  WAVE_FORMAT_DF_G726                    0x0085 /* DataFusion Systems (Pty) (Ltd) */
#define  WAVE_FORMAT_DF_GSM610                  0x0086 /* DataFusion Systems (Pty) (Ltd) */
#define  WAVE_FORMAT_ISIAUDIO                   0x0088 /* Iterated Systems, Inc. */
#define  WAVE_FORMAT_ONLIVE                     0x0089 /* OnLive! Technologies, Inc. */
#define  WAVE_FORMAT_SBC24                      0x0091 /* Siemens Business Communications Sys */
#define  WAVE_FORMAT_DOLBY_AC3_SPDIF            0x0092 /* Sonic Foundry */
#define  WAVE_FORMAT_MEDIASONIC_G723            0x0093 /* MediaSonic */
#define  WAVE_FORMAT_PROSODY_8KBPS              0x0094 /* Aculab plc */
#define  WAVE_FORMAT_ZYXEL_ADPCM                0x0097 /* ZyXEL Communications, Inc. */
#define  WAVE_FORMAT_PHILIPS_LPCBB              0x0098 /* Philips Speech Processing */
#define  WAVE_FORMAT_PACKED                     0x0099 /* Studer Professional Audio AG */
#define  WAVE_FORMAT_MALDEN_PHONYTALK           0x00A0 /* Malden Electronics Ltd. */
#define  WAVE_FORMAT_RHETOREX_ADPCM             0x0100 /* Rhetorex Inc. */
#define  WAVE_FORMAT_IRAT                       0x0101 /* BeCubed Software Inc. */
#define  WAVE_FORMAT_VIVO_G723                  0x0111 /* Vivo Software */
#define  WAVE_FORMAT_VIVO_SIREN                 0x0112 /* Vivo Software */
#define  WAVE_FORMAT_DIGITAL_G723               0x0123 /* Digital Equipment Corporation */
#define  WAVE_FORMAT_SANYO_LD_ADPCM             0x0125 /* Sanyo Electric Co., Ltd. */
#define  WAVE_FORMAT_SIPROLAB_ACEPLNET          0x0130 /* Sipro Lab Telecom Inc. */
#define  WAVE_FORMAT_SIPROLAB_ACELP4800         0x0131 /* Sipro Lab Telecom Inc. */
#define  WAVE_FORMAT_SIPROLAB_ACELP8V3          0x0132 /* Sipro Lab Telecom Inc. */
#define  WAVE_FORMAT_SIPROLAB_G729              0x0133 /* Sipro Lab Telecom Inc. */
#define  WAVE_FORMAT_SIPROLAB_G729A             0x0134 /* Sipro Lab Telecom Inc. */
#define  WAVE_FORMAT_SIPROLAB_KELVIN            0x0135 /* Sipro Lab Telecom Inc. */
#define  WAVE_FORMAT_G726ADPCM                  0x0140 /* Dictaphone Corporation */
#define  WAVE_FORMAT_QUALCOMM_PUREVOICE         0x0150 /* Qualcomm, Inc. */
#define  WAVE_FORMAT_QUALCOMM_HALFRATE          0x0151 /* Qualcomm, Inc. */
#define  WAVE_FORMAT_TUBGSM                     0x0155 /* Ring Zero Systems, Inc. */
#define  WAVE_FORMAT_MSAUDIO1                   0x0160 /* Microsoft Corporation */
#define  WAVE_FORMAT_WMAUDIO2                   0x0161 /* Microsoft Corporation */
#define  WAVE_FORMAT_WMAUDIO3                   0x0162 /* Microsoft Corporation */
#define  WAVE_FORMAT_WMAUDIO_LOSSLESS           0x0163 /* Microsoft Corporation */
#define  WAVE_FORMAT_WMASPDIF                   0x0164 /* Microsoft Corporation */
#define  WAVE_FORMAT_UNISYS_NAP_ADPCM           0x0170 /* Unisys Corp. */
#define  WAVE_FORMAT_UNISYS_NAP_ULAW            0x0171 /* Unisys Corp. */
#define  WAVE_FORMAT_UNISYS_NAP_ALAW            0x0172 /* Unisys Corp. */
#define  WAVE_FORMAT_UNISYS_NAP_16K             0x0173 /* Unisys Corp. */
#define  WAVE_FORMAT_CREATIVE_ADPCM             0x0200 /* Creative Labs, Inc */
#define  WAVE_FORMAT_CREATIVE_FASTSPEECH8       0x0202 /* Creative Labs, Inc */
#define  WAVE_FORMAT_CREATIVE_FASTSPEECH10      0x0203 /* Creative Labs, Inc */
#define  WAVE_FORMAT_UHER_ADPCM                 0x0210 /* UHER informatic GmbH */
#define  WAVE_FORMAT_QUARTERDECK                0x0220 /* Quarterdeck Corporation */
#define  WAVE_FORMAT_ILINK_VC                   0x0230 /* I-link Worldwide */
#define  WAVE_FORMAT_RAW_SPORT                  0x0240 /* Aureal Semiconductor */
#define  WAVE_FORMAT_ESST_AC3                   0x0241 /* ESS Technology, Inc. */
#define  WAVE_FORMAT_GENERIC_PASSTHRU           0x0249
#define  WAVE_FORMAT_IPI_HSX                    0x0250 /* Interactive Products, Inc. */
#define  WAVE_FORMAT_IPI_RPELP                  0x0251 /* Interactive Products, Inc. */
#define  WAVE_FORMAT_CS2                        0x0260 /* Consistent Software */
#define  WAVE_FORMAT_SONY_SCX                   0x0270 /* Sony Corp. */
#define  WAVE_FORMAT_FM_TOWNS_SND               0x0300 /* Fujitsu Corp. */
#define  WAVE_FORMAT_BTV_DIGITAL                0x0400 /* Brooktree Corporation */
#define  WAVE_FORMAT_QDESIGN_MUSIC              0x0450 /* QDesign Corporation */
#define  WAVE_FORMAT_VME_VMPCM                  0x0680 /* AT&T Labs, Inc. */
#define  WAVE_FORMAT_TPC                        0x0681 /* AT&T Labs, Inc. */
#define  WAVE_FORMAT_OLIGSM                     0x1000 /* Ing C. Olivetti & C., S.p.A. */
#define  WAVE_FORMAT_OLIADPCM                   0x1001 /* Ing C. Olivetti & C., S.p.A. */
#define  WAVE_FORMAT_OLICELP                    0x1002 /* Ing C. Olivetti & C., S.p.A. */
#define  WAVE_FORMAT_OLISBC                     0x1003 /* Ing C. Olivetti & C., S.p.A. */
#define  WAVE_FORMAT_OLIOPR                     0x1004 /* Ing C. Olivetti & C., S.p.A. */
#define  WAVE_FORMAT_LH_CODEC                   0x1100 /* Lernout & Hauspie */
#define  WAVE_FORMAT_NORRIS                     0x1400 /* Norris Communications, Inc. */
#define  WAVE_FORMAT_SOUNDSPACE_MUSICOMPRESS    0x1500 /* AT&T Labs, Inc. */
#define  WAVE_FORMAT_MPEG_ADTS_AAC              0x1600 /* Microsoft Corporation */
#define  WAVE_FORMAT_MPEG_RAW_AAC               0x1601 /* Microsoft Corporation */
#define  WAVE_FORMAT_NOKIA_MPEG_ADTS_AAC        0x1608 /* Microsoft Corporation */
#define  WAVE_FORMAT_NOKIA_MPEG_RAW_AAC         0x1609 /* Microsoft Corporation */
#define  WAVE_FORMAT_VODAFONE_MPEG_ADTS_AAC     0x160A /* Microsoft Corporation */
#define  WAVE_FORMAT_VODAFONE_MPEG_RAW_AAC      0x160B /* Microsoft Corporation */
#define  WAVE_FORMAT_DVM                        0x2000 /* FAST Multimedia AG */

#if !defined(WAVE_FORMAT_EXTENSIBLE)
#define  WAVE_FORMAT_EXTENSIBLE                 0xFFFE /* Microsoft */
#endif // !defined(WAVE_FORMAT_EXTENSIBLE)

//
//  New wave format development should be based on the
//  WAVEFORMATEXTENSIBLE structure. WAVEFORMATEXTENSIBLE allows you to
//  avoid having to register a new format tag with Microsoft. However, if
//  you must still define a new format tag, the WAVE_FORMAT_DEVELOPMENT
//  format tag can be used during the development phase of a new wave
//  format.  Before shipping, you MUST acquire an official format tag from
//  Microsoft.
//
#define WAVE_FORMAT_DEVELOPMENT         (0xFFFF)

#endif /* NONEWWAVE */
#endif /* avidefine_h */
