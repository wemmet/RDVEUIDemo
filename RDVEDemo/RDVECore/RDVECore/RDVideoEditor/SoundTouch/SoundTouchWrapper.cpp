//
//  SoundTouchWrapper.c
//  RDVECore
//
//  Created by 周晓林 on 2017/10/26.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#include "SoundTouchWrapper.h"
#include "SoundTouch.h"
#ifdef __cplusplus
using namespace soundtouch;
extern "C" {
#endif

    struct tagSoundTouch{
        SoundTouch soundTouch;
    };
    
    tagSoundTouch *GetSoundTouchInstance(){
        printf("%lu",sizeof(SAMPLETYPE));
        return new struct tagSoundTouch;
    }
    
    void ReleaseSoundTouchInstance(tagSoundTouch **ppInstance){
        free(*ppInstance);
        *ppInstance = 0;
    }
    
    extern void SoundTouchSetRate(tagSoundTouch* soundTouch,float newRate){
        soundTouch->soundTouch.setRate(newRate);
    }
    extern void SoundTouchSetSampleRate(tagSoundTouch* soundTouch,unsigned int srate){
        soundTouch->soundTouch.setSampleRate(srate);
    }
    extern void SoundTouchSetChannels(tagSoundTouch* soundTouch,unsigned int numChannels){
        soundTouch->soundTouch.setChannels(numChannels);
    }
    extern void SoundTouchSetTempo(tagSoundTouch* soundTouch,float newTempo){
        soundTouch->soundTouch.setTempo(newTempo);
    }
    extern void SoundTouchSetRateChange(tagSoundTouch* soundTouch,float newRate){
        soundTouch->soundTouch.setRateChange(newRate);
    }
    extern void SoundTouchSetTempoChange(tagSoundTouch* soundTouch,float newTempo){
        soundTouch->soundTouch.setTempoChange(newTempo);
    }
    extern void SoundTouchSetPitch(tagSoundTouch* soundTouch,float newPitch){
        soundTouch->soundTouch.setPitch(newPitch);
    }
    extern void SoundTouchSetPitchOctaves(tagSoundTouch* soundTouch,float newPitch){
        soundTouch->soundTouch.setPitchOctaves(newPitch);
    }
    extern void SoundTouchSetPitchSemiTonesInt(tagSoundTouch* soundTouch,int newPitch){
        soundTouch->soundTouch.setPitchSemiTones(newPitch);
    }
    extern void SoundTouchSetPitchSemiTonesFloat(tagSoundTouch* soundTouch,float newPitch){
        soundTouch->soundTouch.setPitchSemiTones(newPitch);
    }
    
    extern signed char SoundTouchSetSetting(tagSoundTouch* soundTouch, int settingId, int value){
        return soundTouch->soundTouch.setSetting(settingId, value);
    }
    extern int SoundTouchGetSetting(tagSoundTouch* soundTouch, int settingId){
        return soundTouch->soundTouch.getSetting(settingId);
    }
    extern void SoundTouchPutSamples(tagSoundTouch* soundTouch, float* samples, unsigned int numSamples){
        soundTouch->soundTouch.putSamples((SAMPLETYPE*)samples, numSamples);
    }
    extern uint SoundTouchNumSamples(tagSoundTouch* soundTouch){
        return soundTouch->soundTouch.numUnprocessedSamples();
    }
    extern unsigned int SoundTouchReceiveSamples(tagSoundTouch* soundTouch, float* output, unsigned int maxSamples){
        return soundTouch->soundTouch.receiveSamples((SAMPLETYPE*)output, maxSamples);
    }
    

   
#ifdef __cplusplus
};
#endif
