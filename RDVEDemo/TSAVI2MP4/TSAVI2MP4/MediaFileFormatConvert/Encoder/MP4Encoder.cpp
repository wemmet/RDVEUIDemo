//
//  MP4Encoder.cpp
//  VideoCoreDemo
//
//  Created by 周晓林 on 2017/9/13.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#include "MP4Encoder.hpp"
//#include "sps_decode.h"
#include <string.h>
#include "sps_pps_parser.hpp"
#include <stdio.h>
//#include <Windows.h>
#include <sys/time.h>

static double audio_tick_gap = (1024000.0) / (48000.0);
static double video_tick_gap = (1000.0 + 1.0) / 30.0;
static int sps_wt = 0; //确保sps已经 MP4AddH264SequenceParameterSet
static int pps_wt = 0; //确保pps已经 MP4AddH264PictureParameterSet

#define BUFFER_SIZE     (1024*1024)
#define FRAME_FRATE     (30)
#define TIME_SCALE      (90000)

unsigned int GetTickCount(){
    struct timeval tv;
    if (gettimeofday(&tv, 0)) {
        return 0;
    }
    return (int)(tv.tv_sec*1000)+(tv.tv_usec/1000);
}

MP4Encoder::MP4Encoder(void)
: m_videoId(NULL),
m_nWidth(0),
m_nHeight(0),
m_nTimeScale(TIME_SCALE),
m_nFrameRate(FRAME_FRATE)
{
    m_hMp4File = NULL;
    m_audioId = NULL;
}

MP4Encoder::~MP4Encoder(void)
{
    if (m_hMp4File != NULL)
    {
        MP4Close(m_hMp4File);
        m_hMp4File = NULL;
    }
}

bool MP4Encoder::MP4FileOpen(const char *pFileName, int width, int height, int timeScale/* = 90000*/, int frameRate/* = 25*/)
{
    if (pFileName == NULL)
    {
        return false;
    }
    // create mp4 file
    m_hMp4File = MP4Create(pFileName);
    if (m_hMp4File == MP4_INVALID_FILE_HANDLE)
    {
        printf("ERROR:Open file fialed.\n");
        return false;
    }
    m_nWidth = width;
    m_nHeight = height;
    m_nTimeScale = TIME_SCALE;
    m_nFrameRate = FRAME_FRATE;
    MP4SetTimeScale(m_hMp4File, m_nTimeScale);
    
    return true;
}

bool MP4Encoder::Write264Metadata(MP4FileHandle hMp4File, LPMP4ENC_Metadata lpMetadata)
{
    m_videoId = MP4AddH264VideoTrack
    (hMp4File,
     m_nTimeScale,
     m_nTimeScale / m_nFrameRate,
     m_nWidth, // width
     m_nHeight,// height
     lpMetadata->Sps[1], // sps[1] AVCProfileIndication
     lpMetadata->Sps[2], // sps[2] profile_compat
     lpMetadata->Sps[3], // sps[3] AVCLevelIndication
     3);           // 4 bytes length before each NAL unit
    
    if (m_videoId == MP4_INVALID_TRACK_ID)
    {
        printf("add video track failed.\n");
        return false;
    }
    MP4SetVideoProfileLevel(hMp4File, 0x03); //  Simple Profile @ Level 3
    
    // write sps
    MP4AddH264SequenceParameterSet(hMp4File, m_videoId, lpMetadata->Sps, lpMetadata->nSpsLen);
    
    // write pps
    MP4AddH264PictureParameterSet(hMp4File, m_videoId, lpMetadata->Pps, lpMetadata->nPpsLen);
    
    return true;
}

int MP4Encoder::WriteH264Data(MP4FileHandle hMp4File, const unsigned char* pData, int size)
{
    if (hMp4File == NULL)
    {
        return -1;
    }
    if (pData == NULL)
    {
        return -1;
    }
    MP4ENC_NaluUnit nalu;
    int pos = 0, len = 0;
    int wt_frame = 0;  //测试 - 单帧单Nalu发送
    
    while ((len = ReadOneNaluFromBuf(pData, size, pos, nalu)))
    {
        if (nalu.type == 0x07 && sps_wt == 0) // sps
        {
            //从sps pps中获取信息
            float fps = 0.0;
            //int ret = h264_decode_sps(nalu.data, nalu.size, &m_nWidth, &m_nHeight, &fps);
            get_bit_context buffer;
            memset(&buffer, 0, sizeof(get_bit_context));
            SPS _sps;
            buffer.buf = nalu.data + 1;
            buffer.buf_size = nalu.size - 1;
            int ret = h264dec_seq_parameter_set(&buffer, &_sps);
            m_nWidth = h264_get_width(&_sps);
            m_nHeight = h264_get_height(&_sps);
            ret = h264_get_framerate(&fps, &_sps);
            if (ret == 0)
            {
                m_nFrameRate = (double)fps;
            }
            
            video_tick_gap = (1000.0 + 1.0) / m_nFrameRate;
            // 添加h264 track
            m_videoId = MP4AddH264VideoTrack
            (hMp4File,
             m_nTimeScale,
             (double)m_nTimeScale / m_nFrameRate,
             m_nWidth,     // width
             m_nHeight,    // height
             nalu.data[1], // sps[1] AVCProfileIndication
             nalu.data[2], // sps[2] profile_compat
             nalu.data[3], // sps[3] AVCLevelIndication
             3);           // 4 bytes length before each NAL unit
            if (m_videoId == MP4_INVALID_TRACK_ID)
            {
                printf("add video track failed.\n");
                return 0;
            }
            MP4SetVideoProfileLevel(hMp4File, 1); //  Simple Profile @ Level 3
            
            MP4AddH264SequenceParameterSet(hMp4File, m_videoId, nalu.data, nalu.size);
            sps_wt = 1;
        }
        else if (nalu.type == 0x08 && pps_wt == 0) // pps
        {
            MP4AddH264PictureParameterSet(hMp4File, m_videoId, nalu.data, nalu.size);
            pps_wt = 1;
        }
        else if (nalu.type == 0x01 || nalu.type == 0x05)
        {
            int datalen = nalu.size + 4;
            unsigned char *data = new unsigned char[datalen];
            // MP4 Nalu前四个字节表示Nalu长度
            data[0] = nalu.size >> 24;
            data[1] = nalu.size >> 16;
            data[2] = nalu.size >> 8;
            data[3] = nalu.size & 0xff;
            memcpy(data + 4, nalu.data, nalu.size);
            
            bool syn = 0;
            if (nalu.type == 0x05)
            {
                syn = 1;
            }
            
            //if (!MP4WriteSample(hMp4File, m_videoId, data, datalen, MP4_INVALID_DURATION, 0, syn))
            if (!MP4WriteSample(hMp4File, m_videoId, data, datalen, 90000 / 30, 0, syn))
            {
                return 0;
            }
            delete[] data;
            wt_frame++;
        }
        
        pos += len;
        if (wt_frame > 0)
        {
            break;
        }
    }
    return pos;
}

int MP4Encoder::ReadOneNaluFromBuf(const unsigned char *buffer, unsigned int nBufferSize, unsigned int offSet, MP4ENC_NaluUnit &nalu)
{
    int i = offSet;
    while (i<nBufferSize)
    {
        if (buffer[i++] == 0x00 &&
            buffer[i++] == 0x00 &&
            buffer[i++] == 0x00 &&
            buffer[i++] == 0x01
            )
        {
            int pos = i;
            while (pos<nBufferSize)
            {
                if (buffer[pos++] == 0x00 &&
                    buffer[pos++] == 0x00 &&
                    buffer[pos++] == 0x00 &&
                    buffer[pos++] == 0x01
                    )
                {
                    break;
                }
            }
            if (pos == nBufferSize)
            {
                nalu.size = pos - i;
            }
            else
            {
                nalu.size = (pos - 4) - i;
            }
            
            nalu.type = buffer[i] & 0x1f;
            nalu.data = (unsigned char*)&buffer[i];
            return (nalu.size + i - offSet);
        }
    }
    return 0;
}

void MP4Encoder::MP4FileClose()
{
    if (m_hMp4File)
    {
        MP4Close(m_hMp4File);
        m_hMp4File = NULL;
    }
}


bool MP4Encoder::MP4FileWrite(int(*read_h264)(unsigned char *buf, int buf_size), int(*read_aac)(unsigned char *buf, int buf_size))
{
    //添加aac音频 -- default init, you can get config information by parsering aac data if you want
    m_audioId = MP4AddAudioTrack(m_hMp4File, 48000, 1024, MP4_MPEG4_AUDIO_TYPE); //1024??? 这里不明白为什么用1024 希望有大神解释下
    if (m_audioId == MP4_INVALID_TRACK_ID)
    {
        printf("add audio track failed.\n");
        return false;
    }
    MP4SetAudioProfileLevel(m_hMp4File, 0x2);
    uint8_t buf3[2] = { 0x11, 0x88 }; //important! AAC config infomation;  读者应该根据使用的AAC数据分析出此数据，
    MP4SetTrackESConfiguration(m_hMp4File, m_audioId, buf3, 2);
    //--------------------------------------------------------------------
    
    unsigned char *buffer = new unsigned char[BUFFER_SIZE];
    unsigned char audioBuf[1024];
    int pos = 0;
    int readlen = 0;
    int writelen = 0;
    
    //--------------------------------------------------------------------
    uint32_t audio_tick_now, video_tick_now, last_update;
    unsigned int tick = 0;
    unsigned int audio_tick = 0;
    unsigned int video_tick = 0;
    
    uint32_t tick_exp_new = 0;
    uint32_t tick_exp = 0;
    //--------------------------------------------------------------------
    
    audio_tick_now = video_tick_now = GetTickCount();
    
    /*
     尝试时间音视频间隔内去取得视频或者音频数据进行Write
     */
    while (1)
    {
        last_update = GetTickCount();
        
        //时间溢出情况处理
        if (read_h264 != NULL)
        {
            if (last_update - video_tick_now > video_tick_gap - tick_exp)
            {
                printf("now:%u last_update:%u video_tick:%d tick_exp:%d\n", video_tick_now, last_update, video_tick, tick_exp);
                video_tick += video_tick_gap;
                ///////////////////////////////////////////////
                //-- 这里针对单帧单Nalu的情况处理， 若有差异，请读者自行修改
                readlen = read_h264(buffer + pos, BUFFER_SIZE - pos);
                if (readlen <= 0 && pos == 0)
                {
                    break;
                }
                readlen += pos;
                
                //查找开始位 -- 确保存在Nalu起始位
                writelen = 0;
                for (int i = readlen; i >= 4; i--)
                {
                    if (buffer[i - 1] == 0x01 &&
                        buffer[i - 2] == 0x00 &&
                        buffer[i - 3] == 0x00 &&
                        buffer[i - 4] == 0x00
                        )
                    {
                        writelen = i - 4; //???
                        break;
                    }
                }
                
                //单个NALU
                writelen = WriteH264Data(m_hMp4File, buffer, writelen);
                if (writelen <= 0)
                {
                    break;
                }
                
                //剩余数据
                memcpy(buffer, buffer + writelen, readlen - writelen);
                pos = readlen - writelen;
                if (pos == 0)
                {
                    break;
                }
                ///////////////////////////////////////////////
                video_tick_now = GetTickCount();
            }
        }
        
        if (read_aac != NULL)
        {
            if (last_update - audio_tick_now > audio_tick_gap - tick_exp)
            {
                printf("now:%u last_update:%u audio_tick:%d tick_exp:%d\n", audio_tick_now, last_update, audio_tick, tick_exp);
                audio_tick += audio_tick_gap;
                /////////////////////////////////////////////////////
                int audio_len = read_aac(audioBuf, 1024); //get aac header if you want , so that you can get aac config info
                if (audio_len <= 0)
                {
                    break;
                }
                
                MP4WriteSample(m_hMp4File, m_audioId, audioBuf, audio_len, MP4_INVALID_DURATION, 0, 1);
                /////////////////////////////////////////////////////
                audio_tick_now = GetTickCount();
            }
        }
        
        tick_exp_new = GetTickCount();
        tick_exp = tick_exp_new - last_update;
        
        //sleep
    }
    return true;
}

bool MP4Encoder::PraseMetadata(const unsigned char* pData, int size, MP4ENC_Metadata &metadata)
{
    if (pData == NULL || size<4)
    {
        return false;
    }
    MP4ENC_NaluUnit nalu;
    int pos = 0;
    bool bRet1 = false, bRet2 = false;
    while (int len = ReadOneNaluFromBuf(pData, size, pos, nalu))
    {
        if (nalu.type == 0x07)
        {
            memcpy(metadata.Sps, nalu.data, nalu.size);
            metadata.nSpsLen = nalu.size;
            bRet1 = true;
        }
        else if (nalu.type == 0x08)
        {
            memcpy(metadata.Pps, nalu.data, nalu.size);
            metadata.nPpsLen = nalu.size;
            bRet2 = true;
        }
        pos += len;
    }
    if (bRet1 && bRet2)
    {
        return true;  
    }  
    return false;  
}
