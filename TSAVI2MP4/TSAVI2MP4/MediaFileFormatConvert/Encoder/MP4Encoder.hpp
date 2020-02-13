//
//  MP4Encoder.hpp
//  VideoCoreDemo
//
//  Created by 周晓林 on 2017/9/13.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#ifndef MP4Encoder_hpp
#define MP4Encoder_hpp

#include "mp4v2.h" // 头文件引入  关闭bitcode

// NALU单元
typedef struct _MP4ENC_NaluUnit
{
    int type;
    int size;
    unsigned char *data;
}MP4ENC_NaluUnit;

typedef struct _MP4ENC_Metadata
{
    // video, must be h264 type
    unsigned int    nSpsLen;
    unsigned char   Sps[1024];
    unsigned int    nPpsLen;
    unsigned char   Pps[1024];
    
} MP4ENC_Metadata, *LPMP4ENC_Metadata;

class MP4Encoder
{
public:
    MP4Encoder(void);
    ~MP4Encoder(void);
public:
    // open or creat a mp4 file.
    bool MP4FileOpen(const char *fileName, int width, int height, int timeScale = 90000, int frameRate = 25);
    // wirte 264 metadata in mp4 file.
    bool Write264Metadata(MP4FileHandle hMp4File, LPMP4ENC_Metadata lpMetadata);
    // wirte 264 data, data can contain  multiple frame.
    int WriteH264Data(MP4FileHandle hMp4File, const unsigned char* pData, int size);
//     close mp4 file.
    void MP4FileClose();
    // convert H264 file OR aac file to mp4 file.
    bool MP4FileWrite(int(*read_h264)(unsigned char *buf, int buf_size), int(*read_aac)(unsigned char *buf, int buf_size));
    
    // Prase H264 metamata from H264 data frame
    static bool PraseMetadata(const unsigned char* pData, int size, MP4ENC_Metadata &metadata);
private:
    // read one nalu from H264 data buffer
    static int ReadOneNaluFromBuf(const unsigned char *buffer, unsigned int nBufferSize, unsigned int offSet, MP4ENC_NaluUnit &nalu);
private:
    int m_nWidth;
    int m_nHeight;
    double m_nFrameRate;
    int m_nTimeScale;
    MP4FileHandle m_hMp4File;
    MP4TrackId m_videoId;
    MP4TrackId m_audioId;
};
#endif /* MP4Encoder_hpp */
