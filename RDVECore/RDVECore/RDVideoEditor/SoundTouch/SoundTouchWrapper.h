//
//  SoundTouchWrapper.h
//  RDVECore
//
//  Created by 周晓林 on 2017/10/26.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#ifndef SoundTouchWrapper_h
#define SoundTouchWrapper_h
typedef struct tagSoundTouch tagSoundTouch;
#ifdef __cplusplus
extern "C"{
#endif
    
    tagSoundTouch *GetSoundTouchInstance();
    void ReleaseSoundTouchInstance(tagSoundTouch **ppInstance);
    extern void SoundTouchSetRate(tagSoundTouch* soundTouch,float newRate);
    extern void SoundTouchSetTempo(tagSoundTouch* soundTouch,float newTempo);
    extern void SoundTouchSetRateChange(tagSoundTouch* soundTouch,float newRate);
    extern void SoundTouchSetTempoChange(tagSoundTouch* soundTouch,float newTempo);
    extern void SoundTouchSetPitch(tagSoundTouch* soundTouch,float newPitch);
    extern void SoundTouchSetPitchOctaves(tagSoundTouch* soundTouch,float newPitch);
    extern void SoundTouchSetPitchSemiTonesInt(tagSoundTouch* soundTouch,int newPitch);
    extern void SoundTouchSetPitchSemiTonesFloat(tagSoundTouch* soundTouch,float newPitch);
    extern void SoundTouchSetChannels(tagSoundTouch* soundTouch,unsigned int numChannels);
    extern void SoundTouchSetSampleRate(tagSoundTouch* soundTouch,unsigned int srate);
    extern signed char SoundTouchSetSetting(tagSoundTouch* soundTouch, int settingId, int value);
    extern int SoundTouchGetSetting(tagSoundTouch* soundTouch, int settingId);
    extern void SoundTouchPutSamples(tagSoundTouch* soundTouch, float* samples, unsigned int numSamples);
    extern unsigned int SoundTouchReceiveSamples(tagSoundTouch* soundTouch, float* output, unsigned int maxSamples);
    extern unsigned int SoundTouchNumSamples(tagSoundTouch* soundTouch);
#ifdef __cplusplus
};
#endif

#endif /* SoundTouchWrapper_h */
