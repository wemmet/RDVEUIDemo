
typedef void* SHandle;


typedef struct SRDReverbOption
{
    float fDelaySecond;    //延迟的时间，秒数。大于 0 并小于等于 1 的值。
    float fAttenuation; //衰减系数。大于 0 并小于 1 的值。
}SRDReverbOption;

#ifdef __cplusplus
extern "C"
{
#endif
    enum ESampleBits
    {
        eSampleBit8i,
        eSampleBit16i,
        eSampleBit24i,
        eSampleBit32i,
        eSampleBit24In32i,
        eSampleBit32f,
    };
    
    SHandle    apiSoundFilterCreate();
    int        apiSoundFilterSetAttr(SHandle hSoundFilter, int channels, int samples);
    int        apiSoundFilterSetAttrInputAndOutput(SHandle hSoundFilter,ESampleBits inputFormat, int inputChannels, int inputSamples, ESampleBits  outputFormat, int outputChannels, int outputSamples);
    int        apiSoundFilterSetSoundTouch(SHandle hSoundFilter, double tempo, double pitch, double rate);
    int        apiSoundFilterSetEcho(SHandle hSoundFilter);
    int        apiSoundFilterSetReverb(SHandle hSoundFilter);
    int        apiSoundFilterSetEchoAndReverb(SHandle hSoundFilter,SRDReverbOption echoParam[4], SRDReverbOption reverbParam[2]);
    int        apiSoundFilterSetOverlayAdd(SHandle hSoundFilter, int nSamplesPerSec, const void* pWaveData, int uSampleCount, float fVolume, float fWaitSecond);
    int        apiSoundFilterSetOverlayMul(SHandle hSoundFilter, int nSamplesPerSec, const void* pWaveData, int uSampleCount, float fVolume, float fWaitSecond);
    int        apiSoundFilterPushBuff(SHandle hSoundFilter, void *buff, int sampleCount);
    int        apiSoundFilterGetBuff(SHandle hSoundFilter, void* buff, int sampleMaxCount);
    void       apiSoundFilterClose(SHandle hSoundFilter);
    bool       apiSoundFilterNoiseCancelling(SHandle hSoundFilter, float fRatio);
    SHandle apiSoundResampleCreate();
    int     apiSoundResampleSetAttrInputAndOutput(SHandle hSoundResample,ESampleBits inputFormat, int inputChannels, int inputSamples, ESampleBits  outputFormat, int outputChannels, int outputSamples);
    int     apiSoundResampleGetBuff(SHandle hSoundResample, void* buff, int sampleMaxCount);
    int     apiSoundResamplePushBuff(SHandle hSoundResample, void *buff, int sampleCount);
    void    apiSoundResampleClose(SHandle hSoundResample);

    
#ifdef __cplusplus
}
#endif

