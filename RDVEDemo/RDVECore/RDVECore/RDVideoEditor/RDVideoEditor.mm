//
//  RDVideoEditor.m
//  RDVECore
//
//  Created by 周晓林 on 2017/5/8.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#define USE_SOUNDTOUCH //使用soundtouch及回音
//#define USE_FIXCHANNEL //使用resample统一处理
//#define USE_SPEEX
//#define USE_WEBRTC
#define MAXBUFFERWIDTH 640 //最大buffer大小
#define MAXCHANNELNUM 6 //最大声道数

#import "RDVideoEditor.h"
#import "RDVideoCompositor.h"
#import "RDVideoCompositorInstruction.h"
#import <Accelerate/Accelerate.h>
#include "RDTPCircularBuffer.h"
#import "RDRecordHelper.h"

#ifdef USE_SOUNDTOUCH
#include "SoundFilter.h"
#include "SoundTouchDLL.h"
#endif

#ifdef USE_SPEEX
#include "SpeexAllHeaders.h"
#endif

#ifdef USE_WEBRTC //Libs/DeNoise文件夹下
#include "noise_suppression.h"
#include "signal_processing_library.h"
#endif
// 支持多场景 一个场景支持最多x个素材，则要加入2x个轨道
// 2k+1 奇轨道 2k+2 偶轨道  每一个轨道组都在同样的时间段中
//


/*
 * 音轨参数类  由VVAsset或者RDMusic生成
 */
@interface AudioFilter :NSObject
@property (nonatomic, assign) float volume; //音量
@property (nonatomic, assign) float pitch; //音调
@property (nonatomic, assign) RDAudioFilterType type; // 音频滤镜类型
@end
@implementation AudioFilter

@end

typedef struct AVAudioTapProcessorContext {
    Boolean supportedTapProcessingFormat;
    Boolean isNonInterleaved;
    Float64 sampleRate;
    Float64 channelsPerFrame;
    AudioUnit audioUnit;
    Float64 sampleCount;
    float volume;
    float currentPitch;
    AudioFilter *filter;
        
//    void* handle;
    void* handles[MAXCHANNELNUM];//20190118 wuxiaoxia 有几个声道就应该创建几个，最多有6个声道
    
    RDAudioFilterType currentType;
    
#ifdef USE_FIXCHANNEL
    void* resampleHandle122;
    void* resampleHandle221;
#endif
#ifdef USE_SPEEX
    void* resampleHandle32f216i;
    SpeexPreprocessState* st;
    void* resampleHandle16i232f;
#endif
    
#ifdef USE_WEBRTC
    void* resampleHandle44100to32000;
    void* resampleHandle32000to44100;
    NsHandle* pNsInstWebRtc;
    int nNsLevel;
    int filter_state1[6];
    int filter_state12[6];
    int Synthesis_state1[6];
    int Synthesis_state12[6];
#endif
    
    
} AVAudioTapProcessorContext;



@interface RDVideoEditor()

{
    CMTimeRange *passThroughTimeRange;
    CMTimeRange *transitionTimeRange;
    NSMutableDictionary<NSString* ,AVMutableAudioMixInputParameters*>* mixInputParametersDic;
    
}

@end

@implementation RDVideoEditor
// MTAudioProcessingTap callbacks.  在多轨道下仍旧不稳定
// 这个不稳定是因为AVPlayerItem被过早释放，而MTAudioProcessingTapRef中的回调函数依旧在运行
#pragma mark - MTAudioProcessingTap Callbacks


static void tap_InitCallback(MTAudioProcessingTapRef tap, void *clientInfo, void **tapStorageOut)
{
    
    NSLog(@"%d %s %@ %p",__LINE__,__func__,[NSThread currentThread],tap);
#ifdef USE_SOUNDTOUCH

    AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext*)calloc(1, sizeof(AVAudioTapProcessorContext));
    
    // Initialize MTAudioProcessingTap context.
    context->supportedTapProcessingFormat = false;
    context->isNonInterleaved = false;
    context->sampleRate = NAN;
    context->audioUnit = NULL;
    context->sampleCount = 0.0f;
    
    context->filter = (__bridge AudioFilter*)clientInfo;
    
    context->volume = context->filter.volume;
    context->currentPitch = context->filter.pitch;
    *tapStorageOut = context;
#endif
}

static void tap_FinalizeCallback(MTAudioProcessingTapRef tap)
{
    NSLog(@"%d %s %@ %p",__LINE__,__func__,[NSThread currentThread],tap);
    
#ifdef USE_SOUNDTOUCH
    AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(tap);
    AudioFilter *THIS = context->filter;
    
    for (int i = 0; i < MAXCHANNELNUM; i++) {
        void *handle = context->handles[i];
        if (handle) {
            if (THIS.type == RDAudioFilterTypeCustom
                || (THIS.type >= RDAudioFilterTypeBoy && THIS.type <= RDAudioFilterTypeCartoonQuick)) {
                soundtouch_destroyInstance(handle);
            }
            else if (THIS.type >= RDAudioFilterTypeEcho) {
                apiSoundFilterClose(handle);
            }
        }
    }
#ifdef USE_FIXCHANNEL
    apiSoundResampleClose(context->resampleHandle122);
    apiSoundResampleClose(context->resampleHandle221);
#endif
#ifdef USE_SPEEX
    if (context->st) {
        speex_preprocess_state_destroy(context->st);
    }
    apiSoundResampleClose(context->resampleHandle16i232f);
    apiSoundResampleClose(context->resampleHandle32f216i);
#endif
#ifdef USE_WEBRTC
    if (context->pNsInstWebRtc) {
        WebRtcNs_Free(context->pNsInstWebRtc);
    }
    apiSoundResampleClose(context->resampleHandle32000to44100);
    apiSoundResampleClose(context->resampleHandle44100to32000);
#endif
    
    context->filter = NULL;
    free(context);
#endif
}

static void tap_PrepareCallback(MTAudioProcessingTapRef tap, CMItemCount maxFrames, const AudioStreamBasicDescription *processingFormat)
{
    NSLog(@"%d %s %@ %p %ld",__LINE__,__func__,[NSThread currentThread],tap,maxFrames);
    
    NSLog(@"samplerate: %f channel:%d bits:%d",processingFormat->mSampleRate,processingFormat->mChannelsPerFrame,processingFormat->mBitsPerChannel);
    
#ifdef USE_SOUNDTOUCH
    
    AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(tap);
    
    // Store sample rate for -setCenterFrequency:.
    context->sampleRate = processingFormat->mSampleRate;
    context->channelsPerFrame = processingFormat->mChannelsPerFrame;
    context->supportedTapProcessingFormat = true;
    
    if (processingFormat->mFormatID != kAudioFormatLinearPCM)
    {
        NSLog(@"Unsupported audio format ID for audioProcessingTap. LinearPCM only.");
        context->supportedTapProcessingFormat = false;
    }
    
    if (!(processingFormat->mFormatFlags & kAudioFormatFlagIsFloat))
    {
        NSLog(@"Unsupported audio format flag for audioProcessingTap. Float only.");
        context->supportedTapProcessingFormat = false;
    }
    
    if (processingFormat->mFormatFlags & kAudioFormatFlagIsNonInterleaved)
    {
        context->isNonInterleaved = true;
    }
    
    AudioFilter *THIS = (AudioFilter*)context->filter;
    
    for (int i = 0; i < processingFormat->mChannelsPerFrame; i++) {
        if (THIS.type == RDAudioFilterTypeCustom
            || (THIS.type >= RDAudioFilterTypeBoy && THIS.type <= RDAudioFilterTypeCartoonQuick)) {
            context->handles[i] = soundtouch_createInstance();
            soundtouch_setChannels(context->handles[i], 1);//20190118 wuxiaoxia 每次传给soundtouch的是一个声道的数据，所以应设置为1,否则有噪音
            soundtouch_setSampleRate(context->handles[i], processingFormat->mSampleRate);
        }else if (THIS.type >= RDAudioFilterTypeEcho) {
            context->handles[i] = apiSoundFilterCreate();
            apiSoundFilterSetAttr(context->handles[i], 1, processingFormat->mSampleRate);//20190118 wuxiaoxia 每次传给soundtouch的是一个声道的数据，所以应设置为1(第二个参数),否则有噪音
            
            apiSoundFilterNoiseCancelling(context->handles[i], 0.0);
        }
    }
    
#ifdef USE_FIXCHANNEL
    context->resampleHandle221 = apiSoundResampleCreate();
    apiSoundResampleSetAttrInputAndOutput(context->resampleHandle221, eSampleBit32f, processingFormat->mChannelsPerFrame, processingFormat->mSampleRate, eSampleBit32f, 1, processingFormat->mSampleRate);
    
    context->resampleHandle122 = apiSoundResampleCreate();
    apiSoundResampleSetAttrInputAndOutput(context->resampleHandle122, eSampleBit32f, 1, processingFormat->mSampleRate, eSampleBit32f, processingFormat->mChannelsPerFrame, processingFormat->mSampleRate);
#endif
    
#ifdef USE_SPEEX
    context->resampleHandle32f216i = apiSoundResampleCreate();
    apiSoundResampleSetAttrInputAndOutput(context->resampleHandle32f216i, eSampleBit32f, processingFormat->mChannelsPerFrame, processingFormat->mSampleRate, eSampleBit16i, 1, processingFormat->mSampleRate);
    
    context->resampleHandle16i232f = apiSoundResampleCreate();
    apiSoundResampleSetAttrInputAndOutput(context->resampleHandle16i232f, eSampleBit16i, 1, processingFormat->mSampleRate, eSampleBit32f, processingFormat->mChannelsPerFrame, processingFormat->mSampleRate);
#endif
    
#ifdef USE_WEBRTC
    context->resampleHandle44100to32000 = apiSoundResampleCreate();
    apiSoundResampleSetAttrInputAndOutput(context->resampleHandle44100to32000, eSampleBit32f, processingFormat->mChannelsPerFrame, processingFormat->mSampleRate, eSampleBit32f, processingFormat->mChannelsPerFrame, 32000);
    context->resampleHandle32000to44100 = apiSoundResampleCreate();
    apiSoundResampleSetAttrInputAndOutput(context->resampleHandle32000to44100, eSampleBit32f, processingFormat->mChannelsPerFrame, 32000, eSampleBit32f, processingFormat->mChannelsPerFrame, processingFormat->mSampleRate);
    
#endif
    context->currentType = THIS.type;
    context->currentPitch = THIS.pitch;
    for (int i = 0; i < processingFormat->mChannelsPerFrame; i++) {
        switch (THIS.type) {
            case RDAudioFilterTypeBoy:
                soundtouch_setPitch(context->handles[i], 0.8);
                break;
            case RDAudioFilterTypeGirl:
                soundtouch_setPitch(context->handles[i], 1.27);
                break;
            case RDAudioFilterTypeMonster:
                soundtouch_setPitch(context->handles[i], 0.6);
                break;
            case RDAudioFilterTypeCartoon:
                soundtouch_setPitch(context->handles[i], 0.45);
                break;
            case RDAudioFilterTypeCartoonQuick:
                soundtouch_setPitch(context->handles[i], 0.55);
                break;
            case RDAudioFilterTypeEcho:
                apiSoundFilterSetEcho(context->handles[i]);
                break;
            case RDAudioFilterTypeReverb:
                apiSoundFilterSetReverb(context->handles[i]);
                break;
            case RDAudioFilterTypeRoom:
            {
                SRDReverbOption echoParam[4] = {0};
                SRDReverbOption reverbParam[2] = {0};
                echoParam[0].fDelaySecond = 0.02f;
                echoParam[0].fAttenuation = 0.40f;
                
                
                reverbParam[0].fDelaySecond = 0.03f;
                reverbParam[0].fAttenuation = 0.20f;
                
                apiSoundFilterSetEchoAndReverb(context->handles[i], echoParam, reverbParam);
                
            }
                break;
            case RDAudioFilterTypeDance:
            {
                SRDReverbOption echoParam[4] = {0};
                SRDReverbOption reverbParam[2] = {0};
                echoParam[0].fDelaySecond = 0.02f;
                echoParam[0].fAttenuation = 0.20f;
                echoParam[1].fDelaySecond = 0.04f;
                echoParam[1].fAttenuation = 0.06f;
                
                reverbParam[0].fDelaySecond = 0.02f;
                reverbParam[0].fAttenuation = 0.25f;
                
                apiSoundFilterSetEchoAndReverb(context->handles[i], echoParam, reverbParam);
                
            }
                break;
            case RDAudioFilterTypeKTV:
            {
                SRDReverbOption echoParam[4] = {0};
                SRDReverbOption reverbParam[2] = {0};
                echoParam[0].fDelaySecond = 0.02f;
                echoParam[0].fAttenuation = 0.30f;
                echoParam[1].fDelaySecond = 0.04f;
                echoParam[1].fAttenuation = 0.06f;
                reverbParam[0].fDelaySecond = 0.02f;
                reverbParam[0].fAttenuation = 0.15f;
                reverbParam[1].fDelaySecond = 0.05f;
                reverbParam[1].fAttenuation = 0.30f;
                
                apiSoundFilterSetEchoAndReverb(context->handles[i], echoParam, reverbParam);
                
            }
                break;
            case RDAudioFilterTypeFactory:
            {
                SRDReverbOption echoParam[4] = {0};
                SRDReverbOption reverbParam[2] = {0};
                echoParam[0].fDelaySecond = 0.15f;
                echoParam[0].fAttenuation = 0.20f;
                echoParam[1].fDelaySecond = 0.30f;
                echoParam[1].fAttenuation = 0.10f;
                echoParam[2].fDelaySecond = 0.45f;
                echoParam[2].fAttenuation = 0.05f;
                echoParam[3].fDelaySecond = 0.60f;
                echoParam[3].fAttenuation = 0.01f;
                
                reverbParam[0].fDelaySecond = 0.06f;
                reverbParam[0].fAttenuation = 0.70f;
                reverbParam[1].fDelaySecond = 0.28f;
                reverbParam[1].fAttenuation = 0.33f;
                
                apiSoundFilterSetEchoAndReverb(context->handles[i], echoParam, reverbParam);
                
            }
                break;
            case RDAudioFilterTypeArena:
            {
                SRDReverbOption echoParam[4] = {0};
                SRDReverbOption reverbParam[2] = {0};
                echoParam[0].fDelaySecond = 0.20f;
                echoParam[0].fAttenuation = 0.50f;
                echoParam[1].fDelaySecond = 0.40f;
                echoParam[1].fAttenuation = 0.45f;
                echoParam[2].fDelaySecond = 0.60f;
                echoParam[2].fAttenuation = 0.40f;
                echoParam[3].fDelaySecond = 0.80f;
                echoParam[3].fAttenuation = 0.35f;
                
                reverbParam[0].fDelaySecond = 0.07f;
                reverbParam[0].fAttenuation = 0.38f;
                reverbParam[1].fDelaySecond = 0.17f;
                reverbParam[1].fAttenuation = 0.75f;
                
                apiSoundFilterSetEchoAndReverb(context->handles[i], echoParam, reverbParam);
                
            }
                break;
            case RDAudioFilterTypeElectri:
            {
                SRDReverbOption echoParam[4] = {0};
                SRDReverbOption reverbParam[2] = {0};
                echoParam[0].fDelaySecond = 0.02f;
                echoParam[0].fAttenuation = 0.20f;
                echoParam[1].fDelaySecond = 0.04f;
                echoParam[1].fAttenuation = 0.06f;
                reverbParam[0].fDelaySecond = 0.02f;
                reverbParam[0].fAttenuation = 0.25f;
                
                apiSoundFilterSetEchoAndReverb(context->handles[i], echoParam, reverbParam);
                
            }
                break;
            case RDAudioFilterTypeCustom:
                soundtouch_setPitch(context->handles[i], THIS.pitch);
                break;
            default:
                break;
        }
    }
#endif
}

static void tap_UnprepareCallback(MTAudioProcessingTapRef tap)
{
    NSLog(@"%d %s %@ %p",__LINE__,__func__,[NSThread currentThread],tap);
    
}

static void tap_ProcessCallback(MTAudioProcessingTapRef tap, CMItemCount numberFrames, MTAudioProcessingTapFlags flags, AudioBufferList *bufferListInOut, CMItemCount *numberFramesOut, MTAudioProcessingTapFlags *flagsOut)
{
//    NSLog(@"%d %s %@ %p",__LINE__,__func__,[NSThread currentThread],tap);
    
    //    int nf = 4096;
    OSStatus status = MTAudioProcessingTapGetSourceAudio(tap,
                                       numberFrames,
                                       bufferListInOut,
                                       flagsOut,
                                       NULL,
                                       numberFramesOut);
    if (status != 0) {
        NSLog(@"OSStatus:%d", status);
        return;
    }
#ifdef USE_SOUNDTOUCH
    
    AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(tap);
    
    if (!context) {
        return;
    }
    
    // Skip processing when format not supported.
    if (context->supportedTapProcessingFormat != true)
    {
        NSLog(@"Unsupported tap processing format.");
        return;
    }
    AudioFilter *THIS = (AudioFilter*)context->filter;
    
    if (context->currentType != THIS.type || context->currentPitch != THIS.pitch) {
        for (int i = 0; i < context->channelsPerFrame; i++) {
//            NSLog(@"%d %s %p",__LINE__,__func__,tap);
            if (context->handles[i]) {
                if (context->currentType == RDAudioFilterTypeCustom
                    || (context->currentType >= RDAudioFilterTypeBoy && context->currentType <= RDAudioFilterTypeCartoonQuick )) {
                    soundtouch_destroyInstance(context->handles[i]);
                }
                else if (context->currentType >= RDAudioFilterTypeEcho) {
                    apiSoundFilterClose(context->handles[i]);
                }
            }
            if (THIS.type == RDAudioFilterTypeCustom
                     || (THIS.type >= RDAudioFilterTypeBoy && THIS.type <= RDAudioFilterTypeCartoonQuick)) {
                context->handles[i] = soundtouch_createInstance();
                soundtouch_setChannels(context->handles[i], 1);
                soundtouch_setSampleRate(context->handles[i], context->sampleRate);
            }
            else if (THIS.type >= RDAudioFilterTypeEcho) {
                context->handles[i] = apiSoundFilterCreate();
                apiSoundFilterSetAttr(context->handles[i], 1, context->sampleRate);
            }
        }
        if (!context || !THIS) {
            return;
        }
//        NSLog(@"%s current:%.2f filter:%.2f %p", __func__, context->currentPitch, THIS.pitch, tap);
        context->currentType = THIS.type;
        context->currentPitch = THIS.pitch;
        for (int i = 0; i < context->channelsPerFrame; i++) {
            if (!context || !THIS) {
                return;
            }
//            NSLog(@"%d %s %p",__LINE__,__func__,tap);
            switch (THIS.type) {
                case RDAudioFilterTypeBoy:
                    soundtouch_setPitch(context->handles[i], 0.8);
                    break;
                case RDAudioFilterTypeGirl:
                    soundtouch_setPitch(context->handles[i], 1.27);
                    break;
                case RDAudioFilterTypeMonster:
                    soundtouch_setPitch(context->handles[i], 0.6);
                    break;
                case RDAudioFilterTypeCartoon:
                    soundtouch_setPitch(context->handles[i], 0.45);
                    break;
                case RDAudioFilterTypeCartoonQuick:
                    soundtouch_setPitch(context->handles[i], 0.55);
                    break;
                case RDAudioFilterTypeEcho:
                    apiSoundFilterSetEcho(context->handles[i]);
                    break;
                case RDAudioFilterTypeReverb:
                    apiSoundFilterSetReverb(context->handles[i]);
                    break;
                case RDAudioFilterTypeRoom:
                {
                    SRDReverbOption echoParam[4] = {0};
                    SRDReverbOption reverbParam[2] = {0};
                    echoParam[0].fDelaySecond = 0.02f;
                    echoParam[0].fAttenuation = 0.40f;
                    reverbParam[0].fDelaySecond = 0.03f;
                    reverbParam[0].fAttenuation = 0.20f;
                    
                    apiSoundFilterSetEchoAndReverb(context->handles[i], echoParam, reverbParam);
                }
                    break;
                case RDAudioFilterTypeDance:
                {
                    SRDReverbOption echoParam[4] = {0};
                    SRDReverbOption reverbParam[2] = {0};
                    echoParam[0].fDelaySecond = 0.02f;
                    echoParam[0].fAttenuation = 0.20f;
                    echoParam[1].fDelaySecond = 0.04f;
                    echoParam[1].fAttenuation = 0.06f;
                    reverbParam[0].fDelaySecond = 0.02f;
                    reverbParam[0].fAttenuation = 0.25f;
                    
                    apiSoundFilterSetEchoAndReverb(context->handles[i], echoParam, reverbParam);
                }
                    break;
                case RDAudioFilterTypeKTV:
                {
                    SRDReverbOption echoParam[4] = {0};
                    SRDReverbOption reverbParam[2] = {0};
                    echoParam[0].fDelaySecond = 0.02f;
                    echoParam[0].fAttenuation = 0.30f;
                    echoParam[1].fDelaySecond = 0.04f;
                    echoParam[1].fAttenuation = 0.06f;
                    reverbParam[0].fDelaySecond = 0.02f;
                    reverbParam[0].fAttenuation = 0.15f;
                    reverbParam[1].fDelaySecond = 0.05f;
                    reverbParam[1].fAttenuation = 0.30f;
                    
                    apiSoundFilterSetEchoAndReverb(context->handles[i], echoParam, reverbParam);
                }
                    break;
                case RDAudioFilterTypeFactory:
                {
                    SRDReverbOption echoParam[4] = {0};
                    SRDReverbOption reverbParam[2] = {0};
                    echoParam[0].fDelaySecond = 0.15f;
                    echoParam[0].fAttenuation = 0.20f;
                    echoParam[1].fDelaySecond = 0.30f;
                    echoParam[1].fAttenuation = 0.10f;
                    echoParam[2].fDelaySecond = 0.45f;
                    echoParam[2].fAttenuation = 0.05f;
                    echoParam[3].fDelaySecond = 0.60f;
                    echoParam[3].fAttenuation = 0.01f;
                    reverbParam[0].fDelaySecond = 0.06f;
                    reverbParam[0].fAttenuation = 0.70f;
                    reverbParam[1].fDelaySecond = 0.28f;
                    reverbParam[1].fAttenuation = 0.33f;
                    
                    apiSoundFilterSetEchoAndReverb(context->handles[i], echoParam, reverbParam);
                }
                    break;
                case RDAudioFilterTypeArena:
                {
                    SRDReverbOption echoParam[4] = {0};
                    SRDReverbOption reverbParam[2] = {0};
                    echoParam[0].fDelaySecond = 0.20f;
                    echoParam[0].fAttenuation = 0.50f;
                    echoParam[1].fDelaySecond = 0.40f;
                    echoParam[1].fAttenuation = 0.45f;
                    echoParam[2].fDelaySecond = 0.60f;
                    echoParam[2].fAttenuation = 0.40f;
                    echoParam[3].fDelaySecond = 0.80f;
                    echoParam[3].fAttenuation = 0.35f;
                    reverbParam[0].fDelaySecond = 0.07f;
                    reverbParam[0].fAttenuation = 0.38f;
                    reverbParam[1].fDelaySecond = 0.17f;
                    reverbParam[1].fAttenuation = 0.75f;
                    
                    apiSoundFilterSetEchoAndReverb(context->handles[i], echoParam, reverbParam);
                }
                    break;
                case RDAudioFilterTypeElectri:
                {
                    SRDReverbOption echoParam[4] = {0};
                    SRDReverbOption reverbParam[2] = {0};
                    echoParam[0].fDelaySecond = 0.02f;
                    echoParam[0].fAttenuation = 0.20f;
                    echoParam[1].fDelaySecond = 0.04f;
                    echoParam[1].fAttenuation = 0.06f;
                    reverbParam[0].fDelaySecond = 0.02f;
                    reverbParam[0].fAttenuation = 0.25f;
                    
                    apiSoundFilterSetEchoAndReverb(context->handles[i], echoParam, reverbParam);
                }
                    break;
                case RDAudioFilterTypeCustom:
                    soundtouch_setPitch(context->handles[i], THIS.pitch);
                    NSLog(@"pitch:%.2f", THIS.pitch);
                    break;
                default:
                    break;
            }
        }
    }
    
    
    for (UInt32 i = 0; i < bufferListInOut->mNumberBuffers; i++)
    {
        if (!context || !THIS) {
            return;
        }
//        NSLog(@"%d %s %p filter:%@",__LINE__,__func__,tap, THIS);
        AudioBuffer *pBuffer = &bufferListInOut->mBuffers[i];
        UInt32 cSamples = (UInt32)numberFrames * (context->isNonInterleaved ? 1 : pBuffer->mNumberChannels);
        Float32 *pData = (Float32 *)pBuffer->mData;
        
        if (pData) {
            // 加速库 改变声音
            cblas_saxpy(cSamples, -1.0 + context->volume, pData, 1, pData, 1);
            if (context->volume > 0.0) {
                if (THIS.type == RDAudioFilterTypeCustom
                         || (THIS.type >= RDAudioFilterTypeBoy && THIS.type <= RDAudioFilterTypeCartoonQuick)) {
                    soundtouch_putSamples(context->handles[i], pData, (int)numberFrames);
                    numberFrames = soundtouch_receiveSamples(context->handles[i], pData, (uint)numberFrames);
                }
                else if(THIS.type >= RDAudioFilterTypeEcho){
                    apiSoundFilterPushBuff(context->handles[i], pData, (int)numberFrames);
                    numberFrames = apiSoundFilterGetBuff(context->handles[i], pData, (int)numberFrames);
                }
#ifdef USE_WEBRTC
                apiSoundResamplePushBuff(context->resampleHandle44100to32000, pData, numberFrames);
                float* pdata = (float*)malloc(sizeof(float) * numberFrames);
                numberFrames = apiSoundResampleGetBuff(context->resampleHandle44100to32000, pdata, numberFrames);
                
#if 0
                if (!context->pNsInstWebRtc)
                {
                    int ret = WebRtcNs_Create(&context->pNsInstWebRtc);
                    if (0 != ret)
                    {
                        //
                    }
                    
                    ret = WebRtcNs_Init(context->pNsInstWebRtc,numberFrames);
                    if (0 != ret)
                    {
                        
                    }
                    
                    ret = WebRtcNs_set_policy(context->pNsInstWebRtc,context->nNsLevel);//0,1,2,3
                    if (0 != ret)
                    {
                        
                    }
                }
                short shInL[160],shInH[160];
                short shOutL[160] = {0},shOutH[160] = {0};
                
                //首先需要使用滤波函数将音频数据分高低频，以高频和低频的方式传入降噪函数内部
                WebRtcSpl_AnalysisQMF(pData,320,shInL,shInH,context->filter_state1,context->filter_state12);
                
                //将需要降噪的数据以高频和低频传入对应接口，同时需要注意返回数据也是分高频和低频
                if (0 == WebRtcNs_Process(context->pNsInstWebRtc ,shInL  ,shInH ,shOutL , shOutH))
                {
                    short shBufferOut[320];
                    //如果降噪成功，则根据降噪后高频和低频数据传入滤波接口，然后用将返回的数据写入文件
                    WebRtcSpl_SynthesisQMF(shOutL,shOutH,160,shBufferOut,context->Synthesis_state1,context->Synthesis_state12);
                    memcpy(pData,shBufferOut,320*sizeof(short));
                }
#endif
                apiSoundResamplePushBuff(context->resampleHandle32000to44100, pdata, numberFrames);
                numberFrames = apiSoundResampleGetBuff(context->resampleHandle32000to44100, pData, numberFrames);
                //
                free(pdata);
#endif
                
#ifdef USE_SPEEX
                short* pdata = (short*)malloc(sizeof(short) * numberFrames);
                memset(pdata, 0, numberFrames);
                apiSoundResamplePushBuff(context->resampleHandle32f216i, pData, numberFrames);
                
                numberFrames = apiSoundResampleGetBuff(context->resampleHandle32f216i, pdata, numberFrames);
#if 0
                if (numberFrames%512 == 0) {
                    NSLog(@"%ld",numberFrames);
                    int blockCount = 1;
                    
                    int sizeInBlock = numberFrames/blockCount;
                    
                    if (!context->st ) {
                        context->st = speex_preprocess_state_init(sizeInBlock, context->sampleRate);//初始化
                        int denoise = 1;
                        int noiseSuppress = -25;
                        speex_preprocess_ctl(context->st, SPEEX_PREPROCESS_SET_DENOISE, &denoise); //降噪
                        speex_preprocess_ctl(context->st, SPEEX_PREPROCESS_SET_NOISE_SUPPRESS, &noiseSuppress); //设置噪声的dB
                    }
                    for (int i = 0; i<blockCount ; i++) {
                        speex_preprocess_run(context->st, pdata + sizeInBlock * i);
                    }
                }
#endif
                apiSoundResamplePushBuff(context->resampleHandle16i232f, pdata, numberFrames);
                numberFrames = apiSoundResampleGetBuff(context->resampleHandle16i232f, pData, numberFrames);
                //
                free(pdata);
#endif
            }
        }
        *numberFramesOut = numberFrames;
    }
    
#endif
//    NSLog(@"%s finished %p",__func__,tap);
}

- (CMTimeRange) passThroughTimeRangeAtIndex:(int) index
{
    //    CMTimeRange timeRange = self.scenes[index].passThroughTimeRange;
    return self.scenes[index].passThroughTimeRange;
}
- (CMTimeRange) transitionTimeRangeAtIndex:(int) index
{
    
    return self.scenes[index].transition.timeRange;
}
- (void)refreshTransition:(VVTransition *)transition atIndex:(NSInteger)index {
    double time = CACurrentMediaTime();
    __block CMTime nextClipStartTime = kCMTimeZero;
    __block CMTimeRange prevTransitionTimeRange = kCMTimeRangeZero;
    [self.scenes enumerateObjectsUsingBlock:^(RDScene * _Nonnull scene, NSUInteger idx, BOOL * _Nonnull stop) {
        __block CMTime sceneDuration = kCMTimeZero;
        if (idx == index) {
            scene.transition = transition;
        }
        [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx1, BOOL * _Nonnull stop1) {
            CMTime assetDuration;
            if (asset.isRepeat && !CMTimeRangeEqual(asset.timeRangeInVideo, kCMTimeRangeZero) && !CMTimeRangeEqual(asset.timeRangeInVideo, kCMTimeRangeInvalid)) {
                CMTime dur = CMTimeAdd(asset.timeRangeInVideo.duration, asset.timeRangeInVideo.start);
                dur = CMTimeMake(dur.value/asset.speed, dur.timescale);
                assetDuration = dur;
            }else {
                assetDuration = asset.duration;
            }
            if (CMTimeCompare(assetDuration, sceneDuration) == 1) {
                sceneDuration = assetDuration;
            }
            if (idx > index && asset.type == RDAssetTypeVideo) {
                NSInteger trackIndex = asset.trackID.integerValue;
                AVMutableCompositionTrack *videoTrack = self.composition.tracks[trackIndex - 1];
                AVMutableCompositionTrack *audioTrack = self.composition.tracks[trackIndex];
                CMTimeRange scaleTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeSubtract(videoTrack.timeRange.duration, assetDuration));
                NSLog(@"scaleTimeRange:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, scaleTimeRange.duration)));
                [videoTrack scaleTimeRange:scaleTimeRange toDuration:nextClipStartTime];
                NSLog(@"videoTrack:%@%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, videoTrack.timeRange.start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, videoTrack.timeRange.duration)));
                if (asset.hasAudio) {
                    [audioTrack scaleTimeRange:scaleTimeRange toDuration:nextClipStartTime];
                }
            }
        }];
        CMTime transitionDuration = CMTimeMakeWithSeconds(scene.transition.duration, TIMESCALE);
        if (idx == self.scenes.count -1) {
            transitionDuration = kCMTimeZero;
        }
        if (idx >= index) {
            passThroughTimeRange[idx] = CMTimeRangeMake(nextClipStartTime, sceneDuration);
            nextClipStartTime = CMTimeAdd(nextClipStartTime, sceneDuration);
            nextClipStartTime = CMTimeSubtract(nextClipStartTime, transitionDuration);
            NSLog(@"nextClipStartTime:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, nextClipStartTime)));
            if (idx > 0) {
                CMTime previousTransitionDuration = CMTimeMakeWithSeconds(self.scenes[idx-1].transition.duration, TIMESCALE);
                
                passThroughTimeRange[idx].start = CMTimeAdd(passThroughTimeRange[idx].start, previousTransitionDuration); // 起始时间加上前一个转场
                passThroughTimeRange[idx].duration = CMTimeSubtract(passThroughTimeRange[idx].duration,previousTransitionDuration); //持续时间减去前一个转场
            }
            if (idx+1 < [self.scenes count]) {
                passThroughTimeRange[idx].duration = CMTimeSubtract(passThroughTimeRange[idx].duration, transitionDuration);
                transitionTimeRange[idx] = CMTimeRangeMake(nextClipStartTime, transitionDuration);
            }else {
                transitionTimeRange[idx] = CMTimeRangeMake(nextClipStartTime, kCMTimeZero);
            }            
            if (idx == 0) {
                self.scenes[idx].fixedTimeRange = CMTimeRangeMake(passThroughTimeRange[idx].start, CMTimeAdd(passThroughTimeRange[idx].duration, transitionTimeRange[idx].duration));
            }else{
                self.scenes[idx].fixedTimeRange = CMTimeRangeMake(prevTransitionTimeRange.start, CMTimeAdd(prevTransitionTimeRange.duration, CMTimeAdd(passThroughTimeRange[idx].duration, transitionTimeRange[idx].duration)));
            }
//            NSLog(@"passThroughTimeRange[%d]:%@%@", idx, CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, passThroughTimeRange[idx].start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, passThroughTimeRange[idx].duration)));
//            NSLog(@"transitionTimeRange[%d]:%@%@", idx, CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, transitionTimeRange[idx].start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, transitionTimeRange[idx].duration)));
//            NSLog(@"fixedTimeRange:%@%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, self.scenes[idx].fixedTimeRange.start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, self.scenes[idx].fixedTimeRange.duration)));
            
            NSInteger instructionIndex = idx*2;
//            NSLog(@"instructionIndex:%ld", (long)instructionIndex);
            RDVideoCompositorInstruction *passThroughInstruction = self.videoComposition.instructions[instructionIndex];
            [passThroughInstruction refreshTimeRange:passThroughTimeRange[idx]];
            NSLog(@"passThroughInstruction%@:%@%@", passThroughInstruction, CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, passThroughInstruction.timeRange.start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, passThroughInstruction.timeRange.duration)));
            if (idx + 1 < self.scenes.count) {
                RDVideoCompositorInstruction *transitionInstruction = self.videoComposition.instructions[instructionIndex + 1];
                [transitionInstruction refreshTimeRange:transitionTimeRange[idx]];
                NSLog(@"transitionInstruction%@:%@%@", transitionInstruction, CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, transitionInstruction.timeRange.start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, transitionInstruction.timeRange.duration)));
            }
            prevTransitionTimeRange = transitionTimeRange[idx];
        }else {
            nextClipStartTime = CMTimeAdd(nextClipStartTime, sceneDuration);
            nextClipStartTime = CMTimeSubtract(nextClipStartTime, transitionDuration);
        }
    }];
    CMTime totalDuration = transitionTimeRange[self.scenes.count-1].start;
    CMTimeRange scaleTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(_duration, TIMESCALE));
    [[self.composition.tracks lastObject] scaleTimeRange:scaleTimeRange toDuration:totalDuration];
    [self.composition.tracks[self.composition.tracks.count - 2] scaleTimeRange:scaleTimeRange toDuration:totalDuration];
    _duration = CMTimeGetSeconds(totalDuration);
    NSLog(@"refreshTransition 耗时：%f", CACurrentMediaTime() - time);
}

- (void)refreshAssetSpeed:(float)speed {
    __block CMTime nextClipStartTime = kCMTimeZero;
    __block CMTimeRange prevTransitionTimeRange = kCMTimeRangeZero;
    [self.scenes enumerateObjectsUsingBlock:^(RDScene * _Nonnull scene, NSUInteger idx, BOOL * _Nonnull stop) {
        __block CMTime sceneDuration = kCMTimeZero;
        [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx1, BOOL * _Nonnull stop1) {
            Float64 prevScaleDur = CMTimeGetSeconds(asset.timeRange.duration) / asset.speed;
            CMTimeRange speedTimeRange = CMTimeRangeMake(CMTimeAdd(kCMTimeZero, asset.startTimeInScene), CMTimeMakeWithSeconds(prevScaleDur, TIMESCALE));
            Float64 scaleDur = CMTimeGetSeconds(asset.timeRange.duration) / speed;
            CMTime scaleTime = CMTimeMakeWithSeconds(scaleDur, TIMESCALE);
            if (scaleDur > 0) {
                NSLog(@"speedTimeRange:%@ scaleTime:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, speedTimeRange.duration)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, scaleTime)));
                [self.composition.tracks[asset.trackIndex] scaleTimeRange:speedTimeRange toDuration:scaleTime];
                [self.composition.tracks[asset.trackIndex + 1] scaleTimeRange:speedTimeRange toDuration:scaleTime];
            }
            asset.speed = speed;
            
            CMTime assetDuration;
            if (asset.isRepeat && !CMTimeRangeEqual(asset.timeRangeInVideo, kCMTimeRangeZero) && !CMTimeRangeEqual(asset.timeRangeInVideo, kCMTimeRangeInvalid)) {
                CMTime dur = CMTimeAdd(asset.timeRangeInVideo.duration, asset.timeRangeInVideo.start);
                dur = CMTimeMake(dur.value/asset.speed, dur.timescale);
                assetDuration = dur;
            }else {
                assetDuration = asset.duration;
            }
            if (CMTimeCompare(assetDuration, sceneDuration) == 1) {
                sceneDuration = assetDuration;
            }
        }];
        CMTime transitionDuration = CMTimeMakeWithSeconds(scene.transition.duration, TIMESCALE);
        if (idx == self.scenes.count -1) {
            transitionDuration = kCMTimeZero;
        }
        passThroughTimeRange[idx] = CMTimeRangeMake(nextClipStartTime, sceneDuration);
        nextClipStartTime = CMTimeAdd(nextClipStartTime, sceneDuration);
        nextClipStartTime = CMTimeSubtract(nextClipStartTime, transitionDuration);
        NSLog(@"nextClipStartTime:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, nextClipStartTime)));
        if (idx > 0) {
            CMTime previousTransitionDuration = CMTimeMakeWithSeconds(self.scenes[idx-1].transition.duration, TIMESCALE);
            
            passThroughTimeRange[idx].start = CMTimeAdd(passThroughTimeRange[idx].start, previousTransitionDuration); // 起始时间加上前一个转场
            passThroughTimeRange[idx].duration = CMTimeSubtract(passThroughTimeRange[idx].duration,previousTransitionDuration); //持续时间减去前一个转场
        }
        if (idx+1 < [self.scenes count]) {
            passThroughTimeRange[idx].duration = CMTimeSubtract(passThroughTimeRange[idx].duration, transitionDuration);
            transitionTimeRange[idx] = CMTimeRangeMake(nextClipStartTime, transitionDuration);
        }else {
            transitionTimeRange[idx] = CMTimeRangeMake(nextClipStartTime, kCMTimeZero);
        }
        if (idx == 0) {
            self.scenes[idx].fixedTimeRange = CMTimeRangeMake(passThroughTimeRange[idx].start, CMTimeAdd(passThroughTimeRange[idx].duration, transitionTimeRange[idx].duration));
        }else{
            self.scenes[idx].fixedTimeRange = CMTimeRangeMake(prevTransitionTimeRange.start, CMTimeAdd(prevTransitionTimeRange.duration, CMTimeAdd(passThroughTimeRange[idx].duration, transitionTimeRange[idx].duration)));
        }
//            NSLog(@"passThroughTimeRange[%d]:%@%@", idx, CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, passThroughTimeRange[idx].start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, passThroughTimeRange[idx].duration)));
//            NSLog(@"transitionTimeRange[%d]:%@%@", idx, CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, transitionTimeRange[idx].start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, transitionTimeRange[idx].duration)));
//            NSLog(@"fixedTimeRange:%@%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, self.scenes[idx].fixedTimeRange.start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, self.scenes[idx].fixedTimeRange.duration)));
        
        NSInteger instructionIndex = idx*2;
//            NSLog(@"instructionIndex:%ld", (long)instructionIndex);
        RDVideoCompositorInstruction *passThroughInstruction = self.videoComposition.instructions[instructionIndex];
        [passThroughInstruction refreshTimeRange:passThroughTimeRange[idx]];
        if (idx + 1 < self.scenes.count) {
            RDVideoCompositorInstruction *transitionInstruction = self.videoComposition.instructions[instructionIndex + 1];
            [transitionInstruction refreshTimeRange:transitionTimeRange[idx]];
        }
        prevTransitionTimeRange = transitionTimeRange[idx];
    }];
    CMTime totalDuration = transitionTimeRange[self.scenes.count-1].start;
    CMTimeRange scaleTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(_duration, TIMESCALE));
    [[self.composition.tracks lastObject] scaleTimeRange:scaleTimeRange toDuration:totalDuration];
    [self.composition.tracks[self.composition.tracks.count - 2] scaleTimeRange:scaleTimeRange toDuration:totalDuration];
    _duration = CMTimeGetSeconds(totalDuration);
}

#define MAXSOURCES  10
#if 0
- (float)duration{
    CMTime nextClipStartTime = kCMTimeZero;
    
    passThroughTimeRange = (CMTimeRange*)alloca(sizeof(CMTimeRange) * [self.scenes count]);
    transitionTimeRange = (CMTimeRange*)alloca(sizeof(CMTimeRange) * [self.scenes count]);
    
    for (int i = 0; i<self.scenes.count; i++) {
        RDScene* scene = self.scenes[i];
        
        
        CMTime transitionDuration = CMTimeMakeWithSeconds(scene.transition.duration, TIMESCALE);
        if (i == self.scenes.count -1) {
            transitionDuration = kCMTimeZero;
        }
        
        CMTime sceneDuration = kCMTimeZero;
        
        for (int i = 0; i<scene.vvAsset.count; i++) {
            VVAsset *vvAsset = scene.vvAsset[i];
            
            if (vvAsset.type == RDAssetTypeVideo) {
                if (CMTimeRangeEqual(vvAsset.actualTimeRange, kCMTimeRangeZero) || CMTimeRangeEqual(vvAsset.actualTimeRange, kCMTimeRangeInvalid)) {
                    [self refreshAssetTimeRange:vvAsset];
                }
            }
            
            CMTime assetDuration;
            if (vvAsset.isRepeat && !CMTimeRangeEqual(vvAsset.timeRangeInVideo, kCMTimeRangeZero) && !CMTimeRangeEqual(vvAsset.timeRangeInVideo, kCMTimeRangeInvalid)) {
                CMTime dur = CMTimeAdd(vvAsset.timeRangeInVideo.duration, vvAsset.timeRangeInVideo.start);
                dur = CMTimeMake(dur.value/vvAsset.speed, dur.timescale);
                assetDuration = dur;
            }else {
                assetDuration = vvAsset.duration;
            }
            if (CMTimeCompare(assetDuration, sceneDuration) == 1) {
                sceneDuration = assetDuration;
            }
        }
        NSLog(@"sceneDuration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, sceneDuration)));
        
        passThroughTimeRange[i] = CMTimeRangeMake(nextClipStartTime, sceneDuration);
        if (i>0) {
            
            CMTime previousTransitionDuration = CMTimeMakeWithSeconds(self.scenes[i-1].transition.duration, TIMESCALE);
            
            passThroughTimeRange[i].start = CMTimeAdd(passThroughTimeRange[i].start, previousTransitionDuration); // 起始时间加上前一个转场
            passThroughTimeRange[i].duration = CMTimeSubtract(passThroughTimeRange[i].duration,previousTransitionDuration); //持续时间减去前一个转场
            
        }
        if (i+1<[self.scenes count]) {
            passThroughTimeRange[i].duration = CMTimeSubtract(passThroughTimeRange[i].duration, transitionDuration);
        }
        
        nextClipStartTime = CMTimeAdd(nextClipStartTime, sceneDuration);
        nextClipStartTime = CMTimeSubtract(nextClipStartTime, transitionDuration);
//        NSLog(@"nextClipStartTime:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, nextClipStartTime)));
        if (i+1<[self.scenes count]) {
            transitionTimeRange[i] = CMTimeRangeMake(nextClipStartTime, transitionDuration);
            
        }
        
        if (i == self.scenes.count - 1) {
            transitionTimeRange[i] = CMTimeRangeMake(nextClipStartTime, kCMTimeZero);
        }
        
        
        if (i == 0) {
            self.scenes[i].fixedTimeRange = CMTimeRangeMake(passThroughTimeRange[i].start, CMTimeAdd(passThroughTimeRange[i].duration, transitionTimeRange[i].duration));
        }else{
            self.scenes[i].fixedTimeRange = CMTimeRangeMake(transitionTimeRange[i-1].start, CMTimeAdd(transitionTimeRange[i-1].duration, CMTimeAdd(passThroughTimeRange[i].duration, transitionTimeRange[i].duration)));
            
        }
    }
    float totalTime = CMTimeGetSeconds(transitionTimeRange[self.scenes.count-1].start);

    NSLog(@"%f",totalTime);
    return totalTime;
    
}
#endif
- (void)setEnableAudioEffect:(BOOL)enableAudioEffect {
    [self clearAudioTapProcessor];
//        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
//
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
//
//            dispatch_semaphore_signal(semaphore);
//        });
//
//        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    _enableAudioEffect = enableAudioEffect;
}

- (void)refreshAssetTimeRange:(VVAsset *)vvAsset {
    NSString *bgVideoPath = [[NSBundle mainBundle] pathForResource:@"RDVECore.bundle/black" ofType:@"mp4"];
    AVURLAsset *asset = [AVURLAsset assetWithURL:vvAsset.url];
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] > 0) {
        if ([asset.URL.path isEqualToString:bgVideoPath]) {
            vvAsset.videoActualTimeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
            return;
        }
        CMTimeRange actualTimeRange = vvAsset.videoActualTimeRange;
#ifdef ForcedSeek
        AVAssetTrack* clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        actualTimeRange = clipVideoTrack.timeRange;
#else
        if (CMTimeRangeEqual(actualTimeRange, kCMTimeRangeZero) || CMTimeRangeEqual(actualTimeRange, kCMTimeRangeInvalid)) {
            actualTimeRange = [RDRecordHelper getActualTimeRange:vvAsset.url];//这个方法比较耗时
            vvAsset.videoActualTimeRange = actualTimeRange;
        }
#endif
        if (CMTimeCompare(vvAsset.timeRange.start, actualTimeRange.start) == -1) {
            vvAsset.timeRange = CMTimeRangeMake(actualTimeRange.start, vvAsset.timeRange.duration);
        }
        //20171010 wuxiaoxia 修改bug:有的视频因最后几帧是空帧，播放时出现抖动或黑屏现象
        if (CMTimeCompare(CMTimeAdd(vvAsset.timeRange.start, vvAsset.timeRange.duration), actualTimeRange.duration) == 1
            && ![vvAsset.url.path isEqualToString:bgVideoPath]/*使用lottie模板时，添加的黑视频时长会超过该视频的时长*/)
        {
            vvAsset.timeRange = CMTimeRangeMake(vvAsset.timeRange.start, CMTimeSubtract(actualTimeRange.duration, vvAsset.timeRange.start));
        }
    }
}

- (void)build{
    mixInputParametersDic = [NSMutableDictionary dictionary];
    
    self.composition = [AVMutableComposition composition];
    self.videoComposition = [AVMutableVideoComposition videoComposition];
    self.audioMix = [AVMutableAudioMix audioMix];
    
    if (CGSizeEqualToSize(CGSizeZero, self.videoSize)) {
        self.videoSize = CGSizeMake(1280, 720);
    }
    self.videoComposition.customVideoCompositorClass = [RDVideoCompositor class];
    self.composition.naturalSize = self.videoSize;
    
    AVMutableCompositionTrack *compositionVideoTracks[2*MAXSOURCES];
    AVMutableCompositionTrack *compositionAudioTracks[2*MAXSOURCES];
    AVMutableAudioMixInputParameters* audioMixInputParmeters[2*MAXSOURCES];
    
    NSMutableArray *inputParameters  = [NSMutableArray array];
    double  time = CACurrentMediaTime();
    for (int i = 0; i<2*MAXSOURCES; i++) {
        compositionVideoTracks[i] = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        compositionAudioTracks[i] = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        audioMixInputParmeters[i] = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositionAudioTracks[i]];
        [inputParameters addObject:audioMixInputParmeters[i]];
    }    
    NSLog(@"0 build 耗时:%lf",CACurrentMediaTime() -time);//30ms
    time = CACurrentMediaTime();
    passThroughTimeRange = (CMTimeRange*)alloca(sizeof(CMTimeRange) * [self.scenes count]);
    transitionTimeRange = (CMTimeRange*)alloca(sizeof(CMTimeRange) * [self.scenes count]);
    
    NSString *bgVideoPath = [[NSBundle mainBundle] pathForResource:@"RDVECore.bundle/black" ofType:@"mp4"];
    CMTime nextClipStartTime = kCMTimeZero;
    // Cycle between "pass through A", "transition from A to B", "pass through B"
    
    NSMutableArray* instructions = [NSMutableArray array];
    
    NSMutableArray<NSMutableArray* >* trackIDsArray = [NSMutableArray array];
    //MARK:scenes
    NSInteger maxTrackIndex = 0;
//    BOOL isNeedSetScale = NO;
    for (int i = 0; i<self.scenes.count; i++) {
        NSLog(@"sceneIndex:%d", i);
        RDScene* scene = self.scenes[i];
        CMTime sceneDuration = kCMTimeZero;
        for (VVAsset *vasset in scene.vvAsset) {
            CMTime assetDuration;
            if (vasset.isRepeat && !CMTimeRangeEqual(vasset.timeRangeInVideo, kCMTimeRangeZero) && !CMTimeRangeEqual(vasset.timeRangeInVideo, kCMTimeRangeInvalid)) {
                CMTime dur = CMTimeAdd(vasset.timeRangeInVideo.duration, vasset.timeRangeInVideo.start);
                dur = CMTimeMake(dur.value/vasset.speed, dur.timescale);
                assetDuration = dur;
            }else {
                assetDuration = vasset.duration;
            }
            if (CMTimeCompare(assetDuration, sceneDuration) == 1) {
                sceneDuration = assetDuration;
            }
        }
        NSMutableArray* trackIDs = [NSMutableArray array];
        NSInteger trackIndex = i%2 - 2;//20180706 wuxiaoxia fix bug:多场景多媒体的情况，添加转场不能播放，原因是同一个track两个视频有重叠的部分
        if (self.scenes.count == 1) {
            trackIndex = -1;
        }
        if (scene.backgroundAsset && scene.backgroundAsset.type == RDAssetTypeVideo) {
            VVAsset *vasset = scene.backgroundAsset;
            for (VVAssetAnimatePosition* position in vasset.animate) {
                if (position.path) {
                    [position generate];
                }
            }
            if (vasset.type == RDAssetTypeVideo){
                [self refreshAssetTimeRange:vasset];
                if (CMTimeCompare(vasset.timeRange.duration, sceneDuration) == 1) {
                    vasset.timeRange = CMTimeRangeMake(vasset.timeRange.start, sceneDuration);
                }
                trackIndex = 0;
                vasset.trackIndex = trackIndex;
                [self addVideoAsset:vasset videoTrack:compositionVideoTracks[trackIndex] audioTrack:compositionAudioTracks[trackIndex] startTime:nextClipStartTime];
                [trackIDs addObject:[NSNumber numberWithInt:compositionVideoTracks[trackIndex].trackID]];
            }
        }
        //MARK:vvAsset
        for (int j = 0; j<scene.vvAsset.count; j++) {
            NSLog(@"vvAssetIndex:%d", j);
            VVAsset* vasset = scene.vvAsset[j];
            for (VVAssetAnimatePosition* position in vasset.animate) {
                if (position.path) {
                    [position generate];
                }
            }
//            if (vasset.type == RDAssetTypeImage) {
//                vasset.last = CMTimeGetSeconds(vasset.timeRange.start)/CMTimeGetSeconds(sceneDuration);
//            }
            if (vasset.type == RDAssetTypeVideo){
                [self refreshAssetTimeRange:vasset];
            }
            if (vasset.type == RDAssetTypeImage) {
                continue;
            }
            if (self.scenes.count == 1) {
                trackIndex ++;
            }else {
                trackIndex+=2;//20180706 wuxiaoxia fix bug:多场景多媒体的情况，添加转场不能播放，原因是同一个track两个视频有重叠的部分
            }
            if(trackIndex>=2*MAXSOURCES){//20181009 emmet 轨道数组索引越界
                trackIndex = 0;
            }
            NSLog(@"******trackIndex = 【 %zd 】",trackIndex);
            if (trackIndex > maxTrackIndex) {
                maxTrackIndex = trackIndex;
            }
            
            // 放入相应轨道中  按照sceneTime1循环放入
            // sceneTime1根据sceneTime与当前媒体对象的速度计算出来 sceneTime1 = sceneTime * speed
            vasset.trackIndex = trackIndex;
            [self addVideoAsset:vasset videoTrack:compositionVideoTracks[trackIndex] audioTrack:compositionAudioTracks[trackIndex] startTime:nextClipStartTime];
            [trackIDs addObject:[NSNumber numberWithInt:compositionVideoTracks[trackIndex].trackID]];
            
        }
        NSLog(@"2 build 耗时:%lf",CACurrentMediaTime() -time);
        time = CACurrentMediaTime();
        CMTime transitionDuration = CMTimeMakeWithSeconds(scene.transition.duration, TIMESCALE);
        if (i == self.scenes.count -1) {
            transitionDuration = kCMTimeZero;
        }
        passThroughTimeRange[i] = CMTimeRangeMake(nextClipStartTime, sceneDuration);
        if (i>0) {
            
            CMTime previousTransitionDuration = CMTimeMakeWithSeconds(self.scenes[i-1].transition.duration, TIMESCALE);
            
            passThroughTimeRange[i].start = CMTimeAdd(passThroughTimeRange[i].start, previousTransitionDuration); // 起始时间加上前一个转场
            passThroughTimeRange[i].duration = CMTimeSubtract(passThroughTimeRange[i].duration,previousTransitionDuration); //持续时间减去前一个转场
            
        }
        if (i+1<[self.scenes count]) {
            passThroughTimeRange[i].duration = CMTimeSubtract(passThroughTimeRange[i].duration, transitionDuration);
        }
        
        nextClipStartTime = CMTimeAdd(nextClipStartTime, sceneDuration);
        nextClipStartTime = CMTimeSubtract(nextClipStartTime, transitionDuration);
        //        NSLog(@"nextClipStartTime:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, nextClipStartTime)));
        if (i+1<[self.scenes count]) {
            transitionTimeRange[i] = CMTimeRangeMake(nextClipStartTime, transitionDuration);
        }
        if (i == self.scenes.count - 1) {
            transitionTimeRange[i] = CMTimeRangeMake(nextClipStartTime, kCMTimeZero);
        }
        
        if (i == 0) {
            self.scenes[i].fixedTimeRange = CMTimeRangeMake(passThroughTimeRange[i].start, CMTimeAdd(passThroughTimeRange[i].duration, transitionTimeRange[i].duration));
        }else{
            self.scenes[i].fixedTimeRange = CMTimeRangeMake(transitionTimeRange[i-1].start, CMTimeAdd(transitionTimeRange[i-1].duration, CMTimeAdd(passThroughTimeRange[i].duration, transitionTimeRange[i].duration)));            
        }
        NSLog(@"passThroughTimeRange[%d]:%@%@\n\n", i, CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault,passThroughTimeRange[i].start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, passThroughTimeRange[i].duration)));
        NSLog(@"transitionTimeRange[%d]:%@%@\n\n", i, CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault,transitionTimeRange[i].start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, transitionTimeRange[i].duration)));
        
        [trackIDsArray addObject:trackIDs];
    }
    
    for (int i = 0; i<self.scenes.count; i++) {
        RDScene* scene = self.scenes[i];
        for (int j = 0; j<scene.vvAsset.count; j++) {
            VVAsset* vasset = scene.vvAsset[j];
            if (vasset.hasAudio) {
                NSInteger trackIndex = vasset.trackIndex;
                NSLog(@"trackIndex %ld   volume:%f",(long)trackIndex,vasset.volume);
                
                AVMutableAudioMixInputParameters* mixParameter =audioMixInputParmeters[trackIndex];
                mixParameter.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmTimeDomain;//20190528 设置为AVAudioTimePitchAlgorithmVarispeed，视频变速后，音调没有调整
                mixParameter.trackID = compositionAudioTracks[trackIndex].trackID;
                if (vasset.audioFadeInDuration > 0.0 || vasset.audioFadeOutDuration > 0.0) {
                    if (vasset.audioFadeInDuration > 0.0) {
                        CMTimeRange fadeInTimeRange = CMTimeRangeMake(scene.fixedTimeRange.start, CMTimeMakeWithSeconds(vasset.audioFadeInDuration, TIMESCALE));
                        if (vasset.audioFadeInDuration > CMTimeGetSeconds(scene.fixedTimeRange.duration)) {
                            vasset.audioFadeInDuration = CMTimeGetSeconds(scene.fixedTimeRange.duration);
                            fadeInTimeRange = scene.fixedTimeRange;
                            [mixParameter setVolumeRampFromStartVolume:0.1 toEndVolume:vasset.volume timeRange:fadeInTimeRange];
                        }else {
                            [mixParameter setVolume:vasset.volume atTime:CMTimeAdd(scene.fixedTimeRange.start, CMTimeMakeWithSeconds(vasset.audioFadeInDuration, TIMESCALE))];
                            [mixParameter setVolumeRampFromStartVolume:0.1 toEndVolume:vasset.volume timeRange:fadeInTimeRange];
                        }
                    }else {
                        [mixParameter setVolume:vasset.volume atTime:scene.fixedTimeRange.start];
                    }
                    if (vasset.audioFadeOutDuration > 0.0) {
                        if (vasset.audioFadeOutDuration > CMTimeGetSeconds(scene.fixedTimeRange.duration)) {
                            vasset.audioFadeOutDuration = CMTimeGetSeconds(scene.fixedTimeRange.duration);
                        }
                        CMTimeRange fadeOutTimeRange = CMTimeRangeMake(CMTimeSubtract(CMTimeAdd(scene.fixedTimeRange.start, scene.fixedTimeRange.duration), CMTimeMakeWithSeconds(vasset.audioFadeOutDuration, TIMESCALE)), CMTimeMakeWithSeconds(vasset.audioFadeOutDuration, TIMESCALE));
                        CMTime fadeOutStart = CMTimeAdd(scene.fixedTimeRange.start, CMTimeMakeWithSeconds(vasset.audioFadeInDuration, TIMESCALE));
                        if (CMTimeCompare(fadeOutTimeRange.start, fadeOutStart) == -1) {
                            fadeOutTimeRange = CMTimeRangeMake(fadeOutStart, fadeOutTimeRange.duration);
                        }
                        [mixParameter setVolumeRampFromStartVolume:vasset.volume toEndVolume:0.1 timeRange:fadeOutTimeRange];
                    }
                }else {
                    if (_enableAudioEffect) {
                        // solaren 在实时调整中，需要将音量设置为1.0
                        [self checkVolumeRatioInTimeRange:scene.fixedTimeRange originalVolume:1.0 audioMix:mixParameter];
                    }else{
                        [self checkVolumeRatioInTimeRange:scene.fixedTimeRange originalVolume:vasset.volume audioMix:mixParameter];
                    }
                }
                vasset.mixParameter = mixParameter;
                if (vasset.identifier.length > 0) {
                    [mixInputParametersDic setObject:mixParameter forKey:vasset.identifier];
                }
                if(_enableAudioEffect){
                    if (mixParameter) {
                        MTAudioProcessingTapCallbacks callbacks;
                        callbacks.version = kMTAudioProcessingTapCallbacksVersion_0;
                        
                        AudioFilter* filter = [[AudioFilter alloc] init];
                        filter.type = vasset.audioFilterType;
                        filter.volume = vasset.volume;
                        filter.pitch = vasset.pitch;
                        
                        callbacks.clientInfo = (__bridge void*)filter;
                        callbacks.init = tap_InitCallback;
                        callbacks.finalize = tap_FinalizeCallback;
                        callbacks.prepare = tap_PrepareCallback;
                        callbacks.unprepare = tap_UnprepareCallback;
                        callbacks.process = tap_ProcessCallback;
                        MTAudioProcessingTapRef audioProcessingTap;
                        
                        if (noErr == MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PreEffects, &audioProcessingTap)) {
                            mixParameter.audioTapProcessor = audioProcessingTap;
//                            CFRelease(audioProcessingTap);
                        }
                    }
                }
            }
        }
    }
    
    for (int i = 0; i<self.scenes.count; i++) {
        self.scenes[i].passThroughTimeRange = passThroughTimeRange[i];
        self.scenes[i].transition.timeRange = transitionTimeRange[i];
    }
    
    CMTime totalDuration = transitionTimeRange[self.scenes.count-1].start;
    _duration = CMTimeGetSeconds(totalDuration);
    //MARK:watermark
    maxTrackIndex++;
    NSInteger collageTrackIndex = maxTrackIndex;
    NSMutableArray *watermarkTrackIDArray = [NSMutableArray array];
    for (RDWatermark *watermark in self.watermarks) {
        if (watermark.vvAsset.url) {
            AVURLAsset *asset = [AVURLAsset assetWithURL:watermark.vvAsset.url];
            NSArray* videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            if ([videoTracks count] > 0) {
                if (CMTimeCompare(watermark.timeRange.start, kCMTimeZero) == -1) {
                    watermark.timeRange = CMTimeRangeMake(kCMTimeZero, watermark.timeRange.duration);
                }
                if (CMTimeCompare(watermark.timeRange.start, totalDuration) == 1) {
                    continue;
                }
                if (CMTimeCompare(watermark.timeRange.start, CMTimeMake(3, self.fps)) == 0) {
                    watermark.timeRange = CMTimeRangeMake(kCMTimeZero, watermark.timeRange.duration);
                }
                if (CMTimeCompare(CMTimeAdd(watermark.timeRange.start, watermark.timeRange.duration), totalDuration) == 1) {
                    watermark.timeRange = CMTimeRangeMake(watermark.timeRange.start, CMTimeSubtract(totalDuration, watermark.timeRange.start));
                }
                AVMutableCompositionTrack* videoCompositionTrack = compositionVideoTracks[collageTrackIndex];
                AVMutableCompositionTrack* audioCompositionTrack = compositionAudioTracks[collageTrackIndex];
                
                watermark.vvAsset.trackIndex = collageTrackIndex;
                NSLog(@"collage trackIndex:%ld", (long)collageTrackIndex);
                AVAssetTrack* videoTrack = [videoTracks objectAtIndex:0];
                watermark.vvAsset.transform = videoTrack.preferredTransform;
                NSLog(@"collageVideoTrackDuration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, videoTrack.timeRange.duration)));
                [self refreshAssetTimeRange:watermark.vvAsset];
                CMTimeRange assetTimeRange = watermark.vvAsset.timeRange;
                if (CMTimeCompare(assetTimeRange.duration, watermark.timeRange.duration) == 1) {
                    assetTimeRange = CMTimeRangeMake(watermark.vvAsset.timeRange.start, watermark.timeRange.duration);
                }
                NSLog(@"after timeRange:%@%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, assetTimeRange.start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, assetTimeRange.duration)));
                CMTime watermarkTime = assetTimeRange.duration;
                CMTime remainingDuration = watermark.timeRange.duration;
                
                NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
                AVAssetTrack* audioTrack;
                if (audioTracks.count > 0) {
                    audioTrack = [audioTracks objectAtIndex:0];
                    if (_enableAudioEffect ? YES : watermark.vvAsset.volume > 0) {
                        watermark.vvAsset.hasAudio = YES;
                    }
                }
                if(watermark.isRepeat){
                    CMTime beginTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(watermark.timeRange.start), TIMESCALE);
                    while (CMTimeCompare(watermarkTime, remainingDuration) == -1) {
                        [videoCompositionTrack insertTimeRange:assetTimeRange ofTrack:videoTrack atTime:beginTime error:nil];
                        if (watermark.vvAsset.hasAudio) {
                            [audioCompositionTrack insertTimeRange:assetTimeRange ofTrack:audioTrack atTime:beginTime error:nil];
                        }
                        NSLog(@"watermark beginTime:%@ duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, beginTime)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, watermarkTime)));
                        remainingDuration = CMTimeSubtract(remainingDuration, watermarkTime);
                        beginTime = CMTimeAdd(beginTime, watermarkTime);
                    }
                    if (CMTimeCompare(remainingDuration, kCMTimeZero) == 1) {
                        BOOL suc = [videoCompositionTrack insertTimeRange:CMTimeRangeMake(assetTimeRange.start, remainingDuration) ofTrack:videoTrack atTime:beginTime error:nil];
                        if (watermark.vvAsset.hasAudio) {
                            suc = [audioCompositionTrack insertTimeRange:CMTimeRangeMake(assetTimeRange.start, remainingDuration) ofTrack:audioTrack atTime:beginTime error:nil];
                        }
                        NSLog(@"watermark last beginTime:%@ duration:%@ total:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, beginTime)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, remainingDuration)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, CMTimeAdd(beginTime, remainingDuration))));
                    }
                }else{
                    [videoCompositionTrack insertTimeRange:assetTimeRange ofTrack:videoTrack atTime:watermark.timeRange.start error:nil];
                    if (watermark.vvAsset.hasAudio) {
                        [audioCompositionTrack insertTimeRange:assetTimeRange ofTrack:audioTrack atTime:watermark.timeRange.start error:nil];
                    }
//                    NSLog(@"watermark last beginTime:%@ duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, watermark.timeRange.start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, assetTimeRange.duration)));
                }
                if (videoCompositionTrack.trackID >= 33) {
                    
                }
                watermark.vvAsset.trackID = [NSNumber numberWithInt:videoCompositionTrack.trackID];
                [watermarkTrackIDArray addObject:[NSNumber numberWithInt:videoCompositionTrack.trackID]];
                
                if (watermark.vvAsset.hasAudio) {
                    AVMutableAudioMixInputParameters* mixParameter = audioMixInputParmeters[collageTrackIndex];
                    mixParameter.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmTimeDomain;//20190528 设置为AVAudioTimePitchAlgorithmVarispeed，视频变速后，音调没有调整
                    mixParameter.trackID = audioCompositionTrack.trackID;
                    if (watermark.vvAsset.audioFadeInDuration > 0.0 || watermark.vvAsset.audioFadeOutDuration > 0.0) {
                        if (watermark.vvAsset.audioFadeInDuration > 0.0) {
                            CMTimeRange fadeInTimeRange = CMTimeRangeMake(watermark.timeRange.start, CMTimeMakeWithSeconds(watermark.vvAsset.audioFadeInDuration, TIMESCALE));
                            if (watermark.vvAsset.audioFadeInDuration > CMTimeGetSeconds(watermark.timeRange.duration)) {
                                watermark.vvAsset.audioFadeInDuration = CMTimeGetSeconds(watermark.timeRange.duration);
                                fadeInTimeRange = watermark.timeRange;
                                [mixParameter setVolumeRampFromStartVolume:0.1 toEndVolume:watermark.vvAsset.volume timeRange:fadeInTimeRange];
                            }else {
                                [mixParameter setVolume:watermark.vvAsset.volume atTime:CMTimeAdd(watermark.timeRange.start, CMTimeMakeWithSeconds(watermark.vvAsset.audioFadeInDuration, TIMESCALE))];
                                [mixParameter setVolumeRampFromStartVolume:0.1 toEndVolume:watermark.vvAsset.volume timeRange:fadeInTimeRange];
                            }
                        }else {
                            [mixParameter setVolume:watermark.vvAsset.volume atTime:watermark.timeRange.start];
                        }
                        if (watermark.vvAsset.audioFadeOutDuration > 0.0) {
                            if (watermark.vvAsset.audioFadeOutDuration > CMTimeGetSeconds(watermark.timeRange.duration)) {
                                watermark.vvAsset.audioFadeOutDuration = CMTimeGetSeconds(watermark.timeRange.duration);
                            }
                            CMTimeRange fadeOutTimeRange = CMTimeRangeMake(CMTimeSubtract(CMTimeAdd(watermark.timeRange.start, watermark.timeRange.duration), CMTimeMakeWithSeconds(watermark.vvAsset.audioFadeOutDuration, TIMESCALE)), CMTimeMakeWithSeconds(watermark.vvAsset.audioFadeOutDuration, TIMESCALE));
                            CMTime fadeOutStart = CMTimeAdd(watermark.timeRange.start, CMTimeMakeWithSeconds(watermark.vvAsset.audioFadeInDuration, TIMESCALE));
                            if (CMTimeCompare(fadeOutTimeRange.start, fadeOutStart) == -1) {
                                fadeOutTimeRange = CMTimeRangeMake(fadeOutStart, fadeOutTimeRange.duration);
                            }
                            [mixParameter setVolumeRampFromStartVolume:watermark.vvAsset.volume toEndVolume:0.1 timeRange:fadeOutTimeRange];
                        }
                    }else {
                        if (_enableAudioEffect) {
                            // solaren 在实时调整中，需要将音量设置为1.0
                            [self checkVolumeRatioInTimeRange:watermark.timeRange originalVolume:1.0 audioMix:mixParameter];
                        }else{
                            [self checkVolumeRatioInTimeRange:watermark.timeRange originalVolume:watermark.vvAsset.volume audioMix:mixParameter];
                        }
                    }
                    watermark.vvAsset.mixParameter = mixParameter;
                    if (watermark.vvAsset.identifier.length > 0) {
                        [mixInputParametersDic setObject:mixParameter forKey:watermark.vvAsset.identifier];
                    }
                    if(_enableAudioEffect){
                        if (mixParameter) {
                            MTAudioProcessingTapCallbacks callbacks;
                            callbacks.version = kMTAudioProcessingTapCallbacksVersion_0;
                            
                            AudioFilter* filter = [[AudioFilter alloc] init];
                            filter.type = watermark.vvAsset.audioFilterType;
                            filter.volume = watermark.vvAsset.volume;
                            filter.pitch = watermark.vvAsset.pitch;
                            
                            callbacks.clientInfo = (__bridge void*)filter;
                            callbacks.init = tap_InitCallback;
                            callbacks.finalize = tap_FinalizeCallback;
                            callbacks.prepare = tap_PrepareCallback;
                            callbacks.unprepare = tap_UnprepareCallback;
                            callbacks.process = tap_ProcessCallback;
                            MTAudioProcessingTapRef audioProcessingTap;
                            
                            if (noErr == MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PreEffects, &audioProcessingTap)) {
                                mixParameter.audioTapProcessor = audioProcessingTap;
//                                CFRelease(audioProcessingTap);
                            }
                        }
                    }
                }
#if 0
                if (collageTrackIndex == maxTrackIndex) {
                    collageTrackIndex++;
                }else {
                    collageTrackIndex = maxTrackIndex;
                }
#else
                collageTrackIndex++;
                if(collageTrackIndex >= 2*MAXSOURCES){
                    collageTrackIndex = 0;
                }
#endif
            }else if (watermark.vvAsset.type == RDAssetTypeImage) {
                watermark.vvAsset.last = CMTimeGetSeconds(watermark.vvAsset.startTimeInScene)/CMTimeGetSeconds(watermark.vvAsset.duration);
            }
        }
    }
    
    AVURLAsset *bgVideoAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:bgVideoPath]];
    AVMutableCompositionTrack* compositionbgVideoTracks =[self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    {
        AVAssetTrack* clipVideoTrack = [[bgVideoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        
        CMTimeRange timeRangeInAsset = CMTimeRangeMake(kCMTimeZero, totalDuration);
        
        [compositionbgVideoTracks insertTimeRange:timeRangeInAsset
                                          ofTrack:clipVideoTrack
                                           atTime:kCMTimeZero
                                            error:nil];
        
    }
    NSLog(@"totalDuration: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, totalDuration)));
    
    [self addMusics:self.dubbingMusics inputParameters:inputParameters totalDuration:totalDuration nextClipStartTime:nextClipStartTime];
    [self addMusics:self.musics inputParameters:inputParameters totalDuration:totalDuration nextClipStartTime:nextClipStartTime];
    [self addMusics:self.animationVideoMusics inputParameters:inputParameters totalDuration:totalDuration nextClipStartTime:nextClipStartTime];
    [self addMusics:self.animationBGMusics inputParameters:inputParameters totalDuration:totalDuration nextClipStartTime:nextClipStartTime];
    {
        AVURLAsset * bgmusicAsset = bgVideoAsset;
        CMTimeRange musicTimeRange = CMTimeRangeMake(kCMTimeZero, bgVideoAsset.duration);
        
        if ([[bgmusicAsset tracksWithMediaType:AVMediaTypeAudio] count]> 0) {
            
            AVMutableCompositionTrack* bgmusicCompositionTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            NSArray *bgmusicTracks = [bgmusicAsset tracksWithMediaType:AVMediaTypeAudio];
            if(bgmusicTracks.count>0){
                AVAssetTrack* musicTrack = [bgmusicTracks  objectAtIndex:0];
                
                CMTime beginTime = kCMTimeZero;
                
                if(CMTimeCompare(musicTimeRange.duration, totalDuration) == -1){
                    [bgmusicCompositionTrack insertTimeRange:musicTimeRange
                                                     ofTrack:musicTrack
                                                      atTime:beginTime error:nil];
                    [bgmusicCompositionTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, musicTimeRange.duration) toDuration:nextClipStartTime];
                    
                }else{
                    [bgmusicCompositionTrack insertTimeRange:CMTimeRangeMake(musicTimeRange.start, totalDuration)
                                                     ofTrack:musicTrack
                                                      atTime:beginTime error:nil];
                }
                
                AVMutableAudioMixInputParameters* bgmixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:bgmusicCompositionTrack];
                bgmixParameters.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmSpectral;
                bgmixParameters.trackID = bgmusicCompositionTrack.trackID;
                [bgmixParameters setVolume:1.0 atTime:kCMTimeZero];
                
                [inputParameters addObject:bgmixParameters];
            }
        }
    }
    NSMutableArray* mvTrackArray = [NSMutableArray array];
    //MARK:MV
    for (int i = 0; i<self.movieEffects.count; i++) {
        VVMovieEffect* movieEffect = self.movieEffects[i];
        NSURL* mvURL = movieEffect.url;
        
        if (mvURL) {
            
            AVURLAsset* mvAsset = [AVURLAsset assetWithURL:mvURL];
            
            NSArray* mvTracks = [mvAsset tracksWithMediaType:AVMediaTypeVideo];
            if ([mvTracks count] > 0) {
                
                CMTime totalTimeLocal = totalDuration;
                AVMutableCompositionTrack* compositionMVTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
//                    float mvTime = CMTimeGetSeconds(mvAsset.duration);
                AVAssetTrack* mvTrack = [mvTracks objectAtIndex:0];
                CMTime mvTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(mvTrack.timeRange.duration), TIMESCALE);
                NSLog(@"mvTime:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, mvTime)));
                if(movieEffect.shouldRepeat){
                    CMTime beginTime = kCMTimeZero;
//                        while (mvTime < totalTimeLocal) {
                    while (CMTimeCompare(mvTime, totalTimeLocal) == -1) {
                        [compositionMVTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, mvTime) ofTrack:mvTrack atTime:beginTime error:nil];
                        totalTimeLocal = CMTimeSubtract(totalTimeLocal, mvTime);
                        beginTime = CMTimeAdd(beginTime, mvTime);
//                            NSLog(@"mvBeginTime:%@ totalTimeLocal:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, beginTime)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, totalTimeLocal)));
                    }
                    
                    NSLog(@"mvBeginTime:%@ totalTimeLocal:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, beginTime)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, totalTimeLocal)));
                    [compositionMVTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, totalTimeLocal) ofTrack:mvTrack atTime:beginTime error:nil];
                }else{
                    CMTimeRange timerange = movieEffect.timeRange;
                    if (CMTimeCompare(totalTimeLocal, mvTime) >= 0) {
                        timerange = CMTimeRangeMake(timerange.start, mvTime);
                    }else {
                        timerange = CMTimeRangeMake(timerange.start, totalTimeLocal);
                    }
                    [compositionMVTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, timerange.duration) ofTrack:mvTrack atTime:movieEffect.timeRange.start error:nil];
                }
                
                movieEffect.trackID = [NSNumber numberWithInt:compositionMVTrack.trackID];
                [mvTrackArray addObject:[NSNumber numberWithInt:compositionMVTrack.trackID]];
            }
        }
    }
    for (int i = 0; i<self.scenes.count; i++) {
        if (i >= 0) {
            NSMutableArray* array = [NSMutableArray array];
            [array addObjectsFromArray:trackIDsArray[i]];
            [array addObject:[NSNumber numberWithInt:compositionbgVideoTracks.trackID]];
            [array addObjectsFromArray:mvTrackArray];
            [array addObjectsFromArray:watermarkTrackIDArray];
            
            RDVideoCompositorInstruction* videoInstruction= [[RDVideoCompositorInstruction alloc] initTransitionWithSourceTrackIDs:array forTimeRange:passThroughTimeRange[i]];
            videoInstruction.scene = self.scenes[i];
            videoInstruction.customType = RDCustomTypePassThrough;
            videoInstruction.mvEffects = self.movieEffects;
            videoInstruction.watermarks = self.watermarks;
            videoInstruction.customFilterArray = self.customFilterArray;
            videoInstruction.isExporting = _isExporting;
            [instructions addObject:videoInstruction];
        }
        if (i+1<self.scenes.count) {
            NSMutableArray* array = [NSMutableArray array];
            [array addObjectsFromArray:trackIDsArray[i]];
            [array addObjectsFromArray:trackIDsArray[i+1]];
            [array addObject:[NSNumber numberWithInt:compositionbgVideoTracks.trackID]];
            [array addObjectsFromArray:mvTrackArray];
            [array addObjectsFromArray:watermarkTrackIDArray];
            
            RDVideoCompositorInstruction* videoInstruction= [[RDVideoCompositorInstruction alloc] initTransitionWithSourceTrackIDs:array forTimeRange:transitionTimeRange[i]];
            videoInstruction.customType = RDCustomTypeTransition;
            videoInstruction.previosScene = self.scenes[i];
            videoInstruction.nextScene = self.scenes[i+1];
            videoInstruction.mvEffects = self.movieEffects;
            videoInstruction.watermarks = self.watermarks;
            videoInstruction.customFilterArray = self.customFilterArray;
            videoInstruction.isExporting = _isExporting;
            [instructions addObject:videoInstruction];
        }
    }
    
    self.videoComposition.instructions = instructions;
    self.audioMix.inputParameters = inputParameters;
    self.videoComposition.frameDuration = CMTimeMake(1, self.fps);
    self.videoComposition.renderSize = self.videoSize;
    NSLog(@"editor:%@", self.videoComposition.instructions);
#if 0
    if (isNeedSetScale) {
        NSString* machine = [RDRecordHelper system];
        if ([machine hasPrefix:@"iPhone"]) {
            if ([machine compare:@"iPhone8" options:NSCaseInsensitiveSearch] == NSOrderedAscending) {
                self.videoComposition.renderScale = 0.5;//20190123 wuxiaoxia 解决1080P视频占内存大的问题
            }
        }
    }
#endif
    [instructions removeAllObjects];
    [inputParameters removeAllObjects];
    instructions = nil;
    inputParameters = nil;
    NSLog(@"videoEditor.fps:%d",self.fps);
}

- (void)setVirtualVideoBgColor:(UIColor *)bgColor {
    [self.videoComposition.instructions enumerateObjectsUsingBlock:^(RDVideoCompositorInstruction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.virtualVideoBgColor = bgColor;
    }];
}

- (void)setIsExporting:(BOOL)isExporting {
    _isExporting = isExporting;
    [self.videoComposition.instructions enumerateObjectsUsingBlock:^(RDVideoCompositorInstruction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.isExporting = isExporting;
    }];
}

- (void)setLottieView:(UIView *)lottieView {
    [self.videoComposition.instructions enumerateObjectsUsingBlock:^(RDVideoCompositorInstruction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.lottieView = lottieView;
    }];
}

- (void)addVideoAsset:(VVAsset *)vasset
           videoTrack:(AVMutableCompositionTrack *)videoTrack
           audioTrack:(AVMutableCompositionTrack *)audioTrack
            startTime:(CMTime)startTime
{
    AVURLAsset *asset = [AVURLAsset assetWithURL:vasset.url];
    CMTimeRange timeRangeInAsset = vasset.timeRange;
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] > 0) {
        NSString *bgVideoPath = [[NSBundle mainBundle] pathForResource:@"RDVECore.bundle/black" ofType:@"mp4"];
        CMTimeRange actualTimeRange;
        AVAssetTrack* clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        vasset.transform = clipVideoTrack.preferredTransform;
#ifdef ForcedSeek
        actualTimeRange = clipVideoTrack.timeRange;
#else
        actualTimeRange = vasset.videoActualTimeRange;
        if (CMTimeRangeEqual(actualTimeRange, kCMTimeRangeZero) || CMTimeRangeEqual(actualTimeRange, kCMTimeRangeInvalid)) {
            actualTimeRange = [RDRecordHelper getActualTimeRange:vasset.url];
            vasset.videoActualTimeRange = actualTimeRange;
        }
#endif
        NSLog(@"clipVideoTrack.timeRange.start: %@  duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, clipVideoTrack.timeRange.start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, clipVideoTrack.timeRange.duration)));
        if ([vasset.url.path isEqualToString:bgVideoPath] && CMTimeCompare(timeRangeInAsset.duration, actualTimeRange.duration) == 1) {
            [videoTrack insertTimeRange:actualTimeRange
                                ofTrack:clipVideoTrack
                                 atTime:CMTimeAdd(startTime, vasset.startTimeInScene)
                                  error:nil];
            timeRangeInAsset = actualTimeRange;
        }else {
            if (!vasset.isRepeat || (vasset.isRepeat && (CMTimeRangeEqual(vasset.timeRangeInVideo, kCMTimeRangeZero) || CMTimeRangeEqual(vasset.timeRangeInVideo, kCMTimeRangeInvalid)))) {
                NSError *error = nil;
                [videoTrack insertTimeRange:timeRangeInAsset
                                    ofTrack:clipVideoTrack
                                     atTime:CMTimeAdd(startTime, vasset.startTimeInScene)
                                      error:&error];
                if (error) {
                    NSLog(@"insertVideoTrackError:%@", error.localizedDescription);
                }
                if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] > 0 && (_enableAudioEffect ? YES : vasset.volume > 0)) {
                    
                    AVAssetTrack* clipAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
                    NSLog(@"clipAudioTrack.timeRange.start: %@  duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, clipAudioTrack.timeRange.start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, clipAudioTrack.timeRange.duration)));
                    [audioTrack insertTimeRange:timeRangeInAsset
                                        ofTrack:clipAudioTrack
                                         atTime:CMTimeAdd(startTime, vasset.startTimeInScene)
                                          error:nil];
                    vasset.hasAudio = YES;
                }
            }else {
                timeRangeInAsset = vasset.timeRangeInVideo;
                if (CMTimeCompare(vasset.timeRange.duration, vasset.timeRangeInVideo.duration) == 1) {
                    vasset.timeRange = CMTimeRangeMake(vasset.timeRange.start, vasset.timeRangeInVideo.duration);
                }
                AVAssetTrack* clipAudioTrack;
                if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] > 0 && (_enableAudioEffect ? YES : vasset.volume > 0)) {
                    clipAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
                    vasset.hasAudio = YES;
                }
                CMTime vassetTime = vasset.timeRange.duration;
                CMTime remainingDuration = vasset.timeRangeInVideo.duration;
                CMTime beginTime = CMTimeAdd(startTime, vasset.timeRangeInVideo.start);
                while (CMTimeCompare(vassetTime, remainingDuration) == -1) {
                    [videoTrack insertTimeRange:vasset.timeRange ofTrack:clipVideoTrack atTime:beginTime error:nil];
                    if (vasset.hasAudio) {
                        [audioTrack insertTimeRange:vasset.timeRange ofTrack:clipAudioTrack atTime:beginTime error:nil];
                    }
                    NSLog(@"vasset beginTime:%@ duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, beginTime)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, vassetTime)));
                    remainingDuration = CMTimeSubtract(remainingDuration, vassetTime);
                    beginTime = CMTimeAdd(beginTime, vassetTime);
                }
                if (CMTimeCompare(remainingDuration, kCMTimeZero) == 1) {
                    BOOL suc = [videoTrack insertTimeRange:CMTimeRangeMake(vasset.timeRange.start, remainingDuration) ofTrack:clipVideoTrack atTime:beginTime error:nil];
                    if (vasset.hasAudio) {
                        suc = [audioTrack insertTimeRange:CMTimeRangeMake(vasset.timeRange.start, remainingDuration) ofTrack:clipAudioTrack atTime:beginTime error:nil];
                    }
                    NSLog(@"vasset last beginTime:%@ duration:%@ total:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, beginTime)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, remainingDuration)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, CMTimeAdd(beginTime, remainingDuration))));
                }
            }
        }
        CGSize size = clipVideoTrack.naturalSize;
        if (CGSizeEqualToSize(size, CGSizeZero) || size.width == 0.0 || size.height == 0.0) {
            NSArray * formatDescriptions = [clipVideoTrack formatDescriptions];
            CMFormatDescriptionRef formatDescription = NULL;
            if ([formatDescriptions count] > 0) {
                formatDescription = (__bridge CMFormatDescriptionRef)[formatDescriptions objectAtIndex:0];
                if (formatDescription) {
                    size = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, false, false);
                }
            }
        }
        vasset.natureSize = size;
#if 0
        if (size.width > MAXBUFFERWIDTH || size.height > MAXBUFFERWIDTH) {
            isNeedSetScale = YES;
        }
#endif
    }
    NSLog(@"startTime:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, CMTimeAdd(startTime, vasset.startTimeInScene))));
    NSLog(@"timeRangeInAsset.start: %@  duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, timeRangeInAsset.start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, timeRangeInAsset.duration)));
    
    // 根据sceneTime1中缩放回sceneTime
    
    CMTimeRange speedTimeRange = timeRangeInAsset;
    Float64 scaleDur = CMTimeGetSeconds(speedTimeRange.duration) / vasset.speed;
    CMTime scaleTime = CMTimeMakeWithSeconds(scaleDur, TIMESCALE);
    if (scaleDur > 0) {
        speedTimeRange.start = CMTimeAdd(startTime, vasset.startTimeInScene);
        [videoTrack scaleTimeRange:speedTimeRange toDuration:scaleTime];
        [audioTrack scaleTimeRange:speedTimeRange toDuration:scaleTime];
    }
    //            NSLog(@"scaleDur:%f", scaleDur);
    //            NSLog(@"speedTimeRange【%zd】 start:%@  duration:%@", j, CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, speedTimeRange.start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, speedTimeRange.duration)));
    //            NSLog(@"scaleTime:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, scaleTime)));
    NSLog(@"%@",[NSNumber numberWithInt:videoTrack.trackID]);
    
    vasset.trackID = [NSNumber numberWithInt:videoTrack.trackID];
    vasset.assetCompositionTrack = videoTrack;
}

- (void)addMusics:(NSArray <RDMusic *>*)musicArray
  inputParameters:(NSMutableArray *)inputParameters
    totalDuration:(CMTime)totalDuration
nextClipStartTime:(CMTime)nextClipStartTime
{
    __block BOOL isAnimationVideoMusics = NO;
    if (musicArray == self.animationVideoMusics) {
        isAnimationVideoMusics = YES;//20190416 ae添加视频时导出崩溃，先暂时这样改
    }
    [musicArray enumerateObjectsUsingBlock:^(RDMusic * _Nonnull music, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *dic = @{AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)};
        AVURLAsset *musicAsset =[AVURLAsset URLAssetWithURL:music.url options:dic];
//        AVURLAsset* musicAsset = [AVURLAsset assetWithURL:music.url];//20190909 对于网络素材的时间获取不准确，但设置AVURLAssetPreferPreciseDurationAndTimingKey为YES，会耗时
        NSArray *musicTracks = [musicAsset tracksWithMediaType:AVMediaTypeAudio];
        
        if ([musicTracks count] > 0 && music.volume > 0.0) {
            AVMutableCompositionTrack* musicCompositionTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            
            if (CMTimeRangeEqual(music.effectiveTimeRange, kCMTimeRangeZero) || CMTimeRangeEqual(music.effectiveTimeRange, kCMTimeRangeInvalid)) {
                music.effectiveTimeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
            }
            if(CMTimeCompare(CMTimeAdd(music.effectiveTimeRange.start, music.effectiveTimeRange.duration), nextClipStartTime) == 1) {
                music.effectiveTimeRange = CMTimeRangeMake(music.effectiveTimeRange.start, CMTimeSubtract(nextClipStartTime, music.effectiveTimeRange.start));
            }
            if(CMTimeCompare(music.clipTimeRange.duration, music.effectiveTimeRange.duration) == 1) {
                music.clipTimeRange = CMTimeRangeMake(music.clipTimeRange.start, music.effectiveTimeRange.duration);
            }
            if (CMTimeCompare(music.clipTimeRange.duration, musicAsset.duration) == 1) {
                music.clipTimeRange = CMTimeRangeMake(music.clipTimeRange.start, CMTimeSubtract(musicAsset.duration, music.clipTimeRange.start));
            }
            if(CMTimeCompare(music.clipTimeRange.duration, nextClipStartTime) == 1) {
                music.clipTimeRange = CMTimeRangeMake(music.clipTimeRange.start, nextClipStartTime);
            }
            AVAssetTrack* musicTrack = [musicTracks objectAtIndex:0];
            CMTimeRange musicTimeRange = music.clipTimeRange;
            if (CMTimeRangeEqual(music.clipTimeRange, kCMTimeRangeZero) || CMTimeRangeEqual(music.clipTimeRange, kCMTimeRangeInvalid)) {
                musicTimeRange = music.effectiveTimeRange;
            }
            CMTime beginTime = music.effectiveTimeRange.start;
            NSLog(@"musicTrack.timeRange.duration: %@  duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, musicTrack.timeRange.duration)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, musicTimeRange.duration)));
            
            CMTime totalDuration = music.effectiveTimeRange.duration;
            CMTime musicDuration = musicTimeRange.duration;
            if (music.isRepeat) {
                NSError *error = nil;
                while (CMTimeCompare(musicDuration, totalDuration) == -1) {
                    NSLog(@"beginTime:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, beginTime)));
                    BOOL suc = [musicCompositionTrack insertTimeRange:musicTimeRange
                                                   ofTrack:musicTrack
                                                    atTime:beginTime
                                                     error:&error];
                    NSLog(@"suc:%@ error:%@", suc ? @"YES" : @"NO", error);
                    totalDuration = CMTimeSubtract(totalDuration, musicDuration);
                    beginTime = CMTimeAdd(beginTime, musicTimeRange.duration);
                }
                NSLog(@"last beginTime:%@ start:%@ duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, beginTime)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, musicTimeRange.start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, totalDuration)));
                BOOL suc = [musicCompositionTrack insertTimeRange:CMTimeRangeMake(musicTimeRange.start, totalDuration)
                                               ofTrack:musicTrack
                                                atTime:beginTime
                                                 error:&error];
                NSLog(@"last suc:%@ error:%@", suc ? @"YES" : @"NO", error);
            }else {
                if (CMTimeCompare(musicDuration, totalDuration) == 1) {
                    musicTimeRange = CMTimeRangeMake(musicTimeRange.start, totalDuration);
                }
                if (CMTimeCompare(CMTimeAdd(musicTimeRange.start, musicTimeRange.duration), musicTrack.timeRange.duration) == 1) {
                    musicTimeRange = CMTimeRangeMake(musicTimeRange.start, CMTimeSubtract(musicTrack.timeRange.duration, musicTimeRange.start));
                }
                NSError *error = nil;
                BOOL suc = [musicCompositionTrack insertTimeRange:musicTimeRange
                                                          ofTrack:musicTrack
                                                           atTime:beginTime
                                                            error:nil];
                NSLog(@"no repeat suc:%@ error:%@", suc ? @"YES" : @"NO", error);
            }
            AVMutableAudioMixInputParameters* mixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:musicCompositionTrack];
            mixParameters.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmSpectral;
            mixParameters.trackID = musicCompositionTrack.trackID;
            if (music.isFadeInOut && CMTimeGetSeconds(music.effectiveTimeRange.duration) >= music.headFadeDuration + music.endFadeDuration) {
                CMTimeRange fadeInTimeRange = CMTimeRangeMake(music.effectiveTimeRange.start, CMTimeMakeWithSeconds(music.headFadeDuration, TIMESCALE));
                CMTimeRange fadeOutTimeRange = CMTimeRangeMake(CMTimeSubtract(CMTimeAdd(music.effectiveTimeRange.start, music.effectiveTimeRange.duration), CMTimeMakeWithSeconds(music.endFadeDuration, TIMESCALE)), CMTimeMakeWithSeconds(music.endFadeDuration, TIMESCALE));
                
                [mixParameters setVolume:music.volume atTime:CMTimeAdd(music.effectiveTimeRange.start, CMTimeMakeWithSeconds(music.headFadeDuration, TIMESCALE))];
                [mixParameters setVolumeRampFromStartVolume:0.1 toEndVolume:music.volume timeRange:fadeInTimeRange];
                [mixParameters setVolumeRampFromStartVolume:music.volume toEndVolume:0.1 timeRange:fadeOutTimeRange];
            }else {
                //emmet 20171031 每一个配音音轨都是独立的，只有他自己一段，所以这里只需要设置配音开始时间的音量
                [mixParameters setVolume:music.volume atTime:music.effectiveTimeRange.start];
                [mixParameters setVolumeRampFromStartVolume:music.volume toEndVolume:music.volume timeRange:music.effectiveTimeRange];
            }
            
            music.mixParameter = mixParameters;
            if (music.identifier.length > 0 && !isAnimationVideoMusics) {
                [mixInputParametersDic setObject:mixParameters forKey:music.identifier];
            }
            
            if(_enableAudioEffect && !isAnimationVideoMusics){
                if (mixParameters) {
                    
                    MTAudioProcessingTapCallbacks callbacks;
                    callbacks.version = kMTAudioProcessingTapCallbacksVersion_0;
                    
                    AudioFilter* filter=[[AudioFilter alloc] init];
                    filter.type = music.audioFilterType;
                    filter.volume = music.volume;
                    filter.pitch = music.pitch;
                    
                    callbacks.clientInfo = (__bridge void*)filter;
                    callbacks.init = tap_InitCallback;
                    callbacks.finalize = tap_FinalizeCallback;
                    callbacks.prepare = tap_PrepareCallback;
                    callbacks.unprepare = tap_UnprepareCallback;
                    callbacks.process = tap_ProcessCallback;
                    MTAudioProcessingTapRef audioProcessingTap;
                    if (noErr == MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PreEffects, &audioProcessingTap)) {
                        mixParameters.audioTapProcessor = audioProcessingTap;
//                        CFRelease(audioProcessingTap);
                    }
                }
            }
            [inputParameters addObject:mixParameters];
        }
    }];
}

#pragma mark - 配音与原音比例
- (void)checkVolumeRatioInTimeRange:(CMTimeRange )timeRange
                     originalVolume:(float )originalVolume
                           audioMix:(AVMutableAudioMixInputParameters *)mixParameters{
#if 1   //20190701
    [mixParameters setVolume:originalVolume atTime:timeRange.start];
#else
    if ( self.dubbingMusics.count == 0) {
        @try {
            [mixParameters setVolume:originalVolume atTime:timeRange.start];
            //[mixParameters setVolumeRampFromStartVolume:originalVolume toEndVolume:originalVolume timeRange:timeRange];
        } @catch (NSException *exception) {
            NSLog(@"exception:%@",exception);
        }
        return;
    }
    NSMutableArray *thisMusicRatio = [[NSMutableArray alloc]init];
    CMTime start = timeRange.start;
    CMTime end = CMTimeRangeGetEnd(timeRange);
    for(int i = 0;i<self.dubbingMusics.count; i++ ){
        RDMusic * dubbingMusic = self.dubbingMusics[i];
        CMTime iStart = dubbingMusic.effectiveTimeRange.start;
        CMTime iEnd   = CMTimeRangeGetEnd(dubbingMusic.clipTimeRange);
        
        if (CMTimeCompare(iStart, start)>=0 && CMTimeCompare(iStart, end)<=0) {
            if (CMTimeCompare(iEnd, end)<=0) {
                RDMusic *iMusic = [[RDMusic alloc] init];
                iMusic.volume = dubbingMusic.volume;
                iMusic.clipTimeRange = CMTimeRangeMake(iStart, iEnd);
                //iMusic.clipTimeRange = CMTimeRangeMake(iStart, CMTimeSubtract(iEnd, iStart));
                [thisMusicRatio addObject:iMusic];
            }else{
                RDMusic *iMusic = [[RDMusic alloc] init];
                iMusic.volume = dubbingMusic.volume;
                iMusic.clipTimeRange = CMTimeRangeMake(iStart, CMTimeSubtract(end, iStart));
                [thisMusicRatio addObject:iMusic];
            }
        }else{
            if (CMTimeCompare(iEnd, start)>=0 && CMTimeCompare(iEnd, end)<=0) {
                if (CMTimeCompare(iStart, start)>=0) {
                    // 永远不会走这里
                    RDMusic *iMusic = [[RDMusic alloc] init];
                    iMusic.volume = dubbingMusic.volume;
                    iMusic.clipTimeRange = CMTimeRangeMake(iStart, CMTimeSubtract(iEnd, iStart));
                    [thisMusicRatio addObject:iMusic];
                }else{
                    RDMusic *iMusic = [[RDMusic alloc] init];
                    iMusic.volume = dubbingMusic.volume;
                    iMusic.clipTimeRange = CMTimeRangeMake(start, CMTimeSubtract(iEnd, start));
                    [thisMusicRatio addObject:iMusic];
                }
            }else{
                if(CMTimeCompare(iEnd, end)>0 && CMTimeCompare(start, iStart)>0)
                {
                    RDMusic *iMusic = [[RDMusic alloc] init];
                    iMusic.volume = dubbingMusic.volume;
                    iMusic.clipTimeRange = CMTimeRangeMake(start, CMTimeSubtract(end, start));
                    [thisMusicRatio addObject:iMusic];
                }
            }
        }
    }
    if (thisMusicRatio.count == 0) {
        [mixParameters setVolume:originalVolume atTime:timeRange.start];
        //[mixParameters setVolumeRampFromStartVolume:originalVolume toEndVolume:originalVolume timeRange:timeRange];
    }else {
        for (int i = 0; i < thisMusicRatio.count; i++) {
            RDMusic *iMusic = thisMusicRatio[i];
            float currentRatio = (1-iMusic.volume);
            
            CMTime iStart = iMusic.clipTimeRange.start;
            CMTime iEnd = CMTimeRangeGetEnd(iMusic.clipTimeRange);
            if (i == 0 && CMTimeCompare(iStart, start)>0) {
                [mixParameters setVolume:originalVolume atTime:start];
            }
            
#if 1
            //emmet 20171031 setVolume:(float)volume atTime:(CMTime)time 连续设置三个时间点无效，换用下面这个方法 setVolumeRampFromStartVolume:toEndVolume:timeRange
            [mixParameters setVolumeRampFromStartVolume:originalVolume toEndVolume:originalVolume*currentRatio timeRange:CMTimeRangeMake(iStart, CMTimeMakeWithSeconds(0.01, NSEC_PER_SEC))];
            //配音播放完成后需设置回原来原视频轨道的音量
            [mixParameters setVolumeRampFromStartVolume:originalVolume*currentRatio toEndVolume:originalVolume timeRange:CMTimeRangeMake(CMTimeSubtract(iEnd, CMTimeMakeWithSeconds(0.01, NSEC_PER_SEC)) , CMTimeMakeWithSeconds(0.01, NSEC_PER_SEC))];
            
#else
            [mixParameters setVolume:originalVolume*currentRatio atTime:iStart];
//            [mixParameters setVolumeRampFromStartVolume:originalVolume*currentRatio toEndVolume:originalVolume*currentRatio timeRange:iMusic.clipTimeRange];
            if (CMTimeCompare(iEnd, end)<0) {
                [mixParameters setVolume:originalVolume atTime:iEnd];
            }else{
                // 保证后面原音声音片段继续有效
                [mixParameters setVolume:originalVolume atTime:iEnd];
            }
#endif
        }
    }
#endif
}

- (void) setVolume:(float) volume withAudioTapProcessor:(MTAudioProcessingTapRef) audioProcessingTap{
    if (audioProcessingTap) {
        AVAudioTapProcessorContext* context = (AVAudioTapProcessorContext*)MTAudioProcessingTapGetStorage(audioProcessingTap);
        
        context->volume = volume;
    }
    
    
}
- (void) clearAudioTapProcessor{
    self.videoComposition = nil;
    self.composition = nil;
    NSLog(@":::%d",self.audioMix.inputParameters.count);
    for (AVMutableAudioMixInputParameters* mixParameters in self.audioMix.inputParameters) {
        if (mixParameters.audioTapProcessor) {
//            NSLog(@"%d",CFGetRetainCount(mixParameters.audioTapProcessor));
            CFRelease(mixParameters.audioTapProcessor);
        }
    }
    if (mixInputParametersDic) {
        [mixInputParametersDic removeAllObjects];
        mixInputParametersDic = nil;
    }
    self.audioMix = nil;
}
- (void) setVVAssetVolume:(float)volume asset:(VVAsset *) asset
{
    [self setVolume:volume withAudioTapProcessor:asset.mixParameter.audioTapProcessor];
}

- (void) setMusicVolume:(float) volume music:(RDMusic *) music
{
    [self setVolume:volume withAudioTapProcessor:music.mixParameter.audioTapProcessor];
}
- (void) setVolume:(float) volume identifier:(NSString*) identifier
{
    
    [self setVolume:volume withAudioTapProcessor:[mixInputParametersDic objectForKey:identifier].audioTapProcessor];
}
- (void)setPitch:(float)pitch identifier:(NSString *)identifier {
    MTAudioProcessingTapRef audioProcessingTap = [mixInputParametersDic objectForKey:identifier].audioTapProcessor;
    if (audioProcessingTap) {
        AVAudioTapProcessorContext* context = (AVAudioTapProcessorContext*)MTAudioProcessingTapGetStorage(audioProcessingTap);
        context->filter.pitch = pitch;
        NSLog(@"%s new:%.2f current:%.2f filter:%.2f", __func__, pitch, context->currentPitch, context->filter.pitch);
    }
}
- (void) setAudioFilter:(RDAudioFilterType) type identifier:(NSString *)identifier
{
    MTAudioProcessingTapRef audioProcessingTap = [mixInputParametersDic objectForKey:identifier].audioTapProcessor;
    if (audioProcessingTap) {
        float defaultPitch = 1.0;
        if (type == RDAudioFilterTypeBoy) {
            defaultPitch = 0.8;
        }else if (type == RDAudioFilterTypeGirl) {
            defaultPitch = 1.27;
        }else if (type == RDAudioFilterTypeMonster) {
            defaultPitch = 0.6;
        }else if (type == RDAudioFilterTypeCartoon) {
            defaultPitch = 0.45;
        }else if (type == RDAudioFilterTypeCartoonQuick) {
            defaultPitch = 0.55;
        }
        AVAudioTapProcessorContext* context = (AVAudioTapProcessorContext*)MTAudioProcessingTapGetStorage(audioProcessingTap);
        context->filter.type = type;
        context->filter.pitch = defaultPitch;
    }
}
- (void)dealloc{
    if (_enableAudioEffect) {
        self.videoComposition = nil;
        [self clearAudioTapProcessor];
        self.audioMix = nil;
//        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
//        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
//            
//            dispatch_semaphore_signal(semaphore);
//        });
//        
//        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    
    NSLog(@"%s",__func__);
}
@end

