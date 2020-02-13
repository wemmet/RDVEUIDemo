/************************************************************************/
//  RDGifEncoderImp.h
//  制作GIF
//  wind
//  Created by wind on 13-08-22.
//  Copyright (c) 2012  17rd. All rights reserved.
/************************************************************************/

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include "LZWEncoder.h"

//创建GIF制作上下文句柄
RDGIFHANDLE RDGIFEncoderCreator(void);

//设置输出画面大小
//返回值: 成功 1 其它 失败
int RDGIFEncoderSetSize(RDGIFHANDLE handle, int w, int h);

//当输入是视频文件时，设置GIF的帧率
//返回值: 成功 1 其它 失败
int RDGIFEncoderSetFps(RDGIFHANDLE handle, int fps);

//画面间隔时间 delay-微秒
//返回值: 成功 1 其它 失败
int RDGIFEncoderSetDelay(RDGIFHANDLE handle, int64_t delay);

//是否循环播放 0 false 1 true
//返回值: 成功 1 其它 失败
int RDGIFEncoderSetRepeat(RDGIFHANDLE handle,int repeat);

//开始制作GIF
//返回值: 成功 1 其它 失败
int RDGIFEncoderStart(RDGIFHANDLE handle, char *path);

//单个画面输入(宽高必须源输出size一样)
//返回值: 成功 1 其它 失败
int RDGIFEncoderAddFrame(RDGIFHANDLE handle, uint8_t* pBuff, int width, int height, int bpp);

//当输入视频文件时，获取制作GIF进度
int RDGIFEncoderGetProgress(RDGIFHANDLE handle);

//当输入视频文件时，停止制作GIF
//返回值: 成功 1 其它 失败
int RDGIFEncoderStop(RDGIFHANDLE handle);

//释放句柄
//返回值: 成功 1 其它 失败
int RDGIFEncoderFinish(RDGIFHANDLE handle);

#ifdef __cplusplus
}
#endif
