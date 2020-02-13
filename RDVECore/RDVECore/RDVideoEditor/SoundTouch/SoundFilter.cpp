#include "SoundFilter.h"
#include "SoundProcess.h"

extern "C" SHandle apiSoundFilterCreate()
{
	CSoundProcess *pSoundProcess = new CSoundProcess;
	return (SHandle)(pSoundProcess);
}
extern "C" SHandle apiSoundResampleCreate(){
    CSoundResample *pSoundResample = new CSoundResample();
    return (SHandle)(pSoundResample);
}
extern "C" int        apiSoundResampleSetAttrInputAndOutput(SHandle hSoundResample,ESampleBits inputFormat, int inputChannels, int inputSamples, ESampleBits  outputFormat, int outputChannels, int outputSamples){
    CSoundResample *pSoundResample = (CSoundResample*)hSoundResample;
    if (!pSoundResample)
        return 0;
    
    bool bRet = pSoundResample->BeginResample((CSoundResample::ESampleBits)outputFormat, outputSamples, outputChannels);
    bRet = pSoundResample->SetInput((CSoundResample::ESampleBits)inputFormat, inputSamples, inputChannels);
    if (!bRet)
        return 0;
    else
        return 1;
}

extern "C" int	apiSoundFilterSetAttr(SHandle hSoundFilter, int channels, int samples)
{
	CSoundProcess *pSoundProcess = (CSoundProcess*)hSoundFilter;
	if (!pSoundProcess)
		return 0;
	bool bRet = pSoundProcess->OpenSound(CSoundResample::eSampleBit32f, samples, channels);
	if (!bRet)
		return 0;
	else
		return 1;
}
extern "C"     int        apiSoundFilterSetAttrInputAndOutput(SHandle hSoundFilter,ESampleBits inputFormat, int inputChannels, int inputSamples, ESampleBits  outputFormat, int outputChannels, int outputSamples){
    CSoundProcess *pSoundProcess = (CSoundProcess*)hSoundFilter;
    if (!pSoundProcess)
        return 0;
    bool bRet = pSoundProcess->OpenSound((CSoundResample::ESampleBits)outputFormat, outputSamples, outputChannels);
    bRet = pSoundProcess->SetInput((CSoundResample::ESampleBits)inputFormat, inputSamples, inputChannels);
    if (!bRet)
        return 0;
    else
        return 1;
}

extern "C" int	apiSoundFilterSetSoundTouch(SHandle hSoundFilter, double tempo, double pitch, double rate)
{
	CSoundProcess *pSoundProcess = (CSoundProcess*)hSoundFilter;
	if (!pSoundProcess)
		return 0;	
	bool bRet = pSoundProcess->SetSoundTouch(tempo,pitch,rate);
	if (!bRet)
		return 0;
	else
		return 1;
}

extern "C" int	apiSoundFilterSetEcho(SHandle hSoundFilter)
{
	CSoundProcess *pSoundProcess = (CSoundProcess*)hSoundFilter;
	if (!pSoundProcess)
		return 0;

	CSoundProcess::SReverbOption echoParam = {0};

	echoParam.echo[0].fDelaySecond = 0.20f;
	echoParam.echo[0].fAttenuation = 0.80f;
	echoParam.echo[1].fDelaySecond = 0.40f;
	echoParam.echo[1].fAttenuation = 0.40f;
	bool bRet = pSoundProcess->SetReverb(&echoParam);
	if (!bRet)
		return 0;
	else
		return 1;	
}


extern "C"  int	apiSoundFilterSetReverb(SHandle hSoundFilter)
{
	CSoundProcess *pSoundProcess = (CSoundProcess*)hSoundFilter;
	if (!pSoundProcess)
		return 0;

	CSoundProcess::SReverbOption echoParam = {0};

	echoParam.echo[0].fDelaySecond = 0.02f;
	echoParam.echo[0].fAttenuation = 0.30f;
	echoParam.echo[1].fDelaySecond = 0.04f;
	echoParam.echo[1].fAttenuation = 0.06f;

    
    
	echoParam.reverb[0].fDelaySecond = 0.07f;
	echoParam.reverb[0].fAttenuation = 0.38f;
	echoParam.reverb[1].fDelaySecond = 0.17f;
	echoParam.reverb[1].fAttenuation = 0.75f;
	bool bRet = pSoundProcess->SetReverb(&echoParam);
	if (!bRet)
		return 0;
	else
		return 1;
}

extern "C" int	apiSoundFilterSetEchoAndReverb(SHandle hSoundFilter,SRDReverbOption echoOption[4], SRDReverbOption reverbOption[2])
{
	CSoundProcess *pSoundProcess = (CSoundProcess*)hSoundFilter;
	if (!pSoundProcess)
		return 0;

	CSoundProcess::SReverbOption echoParam = {0};

	echoParam.echo[0].fDelaySecond = echoOption[0].fDelaySecond;
	echoParam.echo[0].fAttenuation = echoOption[0].fAttenuation;
    
	echoParam.echo[1].fDelaySecond = echoOption[1].fDelaySecond;
	echoParam.echo[1].fAttenuation = echoOption[1].fAttenuation;
    
	echoParam.echo[2].fDelaySecond = echoOption[2].fDelaySecond;
	echoParam.echo[2].fAttenuation = echoOption[2].fAttenuation;
    
	echoParam.echo[3].fDelaySecond = echoOption[3].fDelaySecond;
	echoParam.echo[3].fAttenuation = echoOption[3].fAttenuation;
	
	echoParam.reverb[0].fDelaySecond = reverbOption[0].fDelaySecond;
	echoParam.reverb[0].fAttenuation = reverbOption[0].fAttenuation;
    
	echoParam.reverb[1].fDelaySecond = reverbOption[1].fDelaySecond;
	echoParam.reverb[1].fAttenuation = reverbOption[1].fAttenuation;
	bool bRet = pSoundProcess->SetReverb(&echoParam);
	if (!bRet)
		return 0;
	else
		return 1;
}

extern "C" int	apiSoundFilterSetOverlayAdd(SHandle hSoundFilter, int nSamplesPerSec, const void* pWaveData, int uSampleCount, float fVolume, float fWaitSecond)
{
	CSoundProcess *pSoundProcess = (CSoundProcess*)hSoundFilter;
	if (!pSoundProcess)
		return -1;
	bool bRet = pSoundProcess->SetOverlayAdd(CSoundResample::eSampleBit16i,nSamplesPerSec,pWaveData,uSampleCount,fVolume,fWaitSecond);
	if (!bRet)
		return 0;
	else
		return 1;
}

extern "C" int	apiSoundFilterSetOverlayMul(SHandle hSoundFilter, int nSamplesPerSec, const void* pWaveData, int uSampleCount, float fVolume, float fWaitSecond)
{
	CSoundProcess *pSoundProcess = (CSoundProcess*)hSoundFilter;
	if (!pSoundProcess)
		return -1;
	bool bRet = pSoundProcess->SetOverlayMul(CSoundResample::eSampleBit16i,nSamplesPerSec,pWaveData,uSampleCount,fVolume,fWaitSecond);
	if (!bRet)
		return 0;
	else
		return 1;
}

extern "C" int	apiSoundFilterPushBuff(SHandle hSoundFilter, void *buff, int sampleCount)
{
	CSoundProcess *pSoundProcess = (CSoundProcess*)hSoundFilter;
	if (!pSoundProcess)
		return -1;
	bool bRet = pSoundProcess->PutInput(buff,sampleCount);
	if (!bRet)
		return 0;
	else
		return 1;
}

extern "C" int	apiSoundFilterGetBuff(SHandle hSoundFilter, void* buff, int sampleMaxCount)
{
	CSoundProcess *pSoundProcess = (CSoundProcess*)hSoundFilter;
	if (!pSoundProcess)
		return -1;
	return pSoundProcess->GetOutput(buff,sampleMaxCount);
}
extern "C" int    apiSoundResamplePushBuff(SHandle hSoundResample, void *buff, int sampleCount)
{
    CSoundResample *pSoundResample = (CSoundResample*)hSoundResample;
    if (!pSoundResample)
        return -1;
    bool bRet = pSoundResample->PutInput(buff,sampleCount);
    if (!bRet)
        return 0;
    else
        return 1;
}
extern "C"     bool apiSoundFilterNoiseCancelling(SHandle hSoundFilter, float fRatio ){
    CSoundProcess *pSoundProcess = (CSoundProcess*)hSoundFilter;
    if (!pSoundProcess)
        return -1;
    return pSoundProcess->NoiseCancelling(fRatio);
}

extern "C" int    apiSoundResampleGetBuff(SHandle hSoundResample, void* buff, int sampleMaxCount)
{
    CSoundResample *pSoundResample = (CSoundResample*)hSoundResample;
    if (!pSoundResample)
        return -1;
    return pSoundResample->GetOutput(buff,sampleMaxCount);
}
extern "C" void	apiSoundFilterClose(SHandle hSoundFilter)
{
	CSoundProcess *pSoundProcess = (CSoundProcess*)hSoundFilter;
	if (pSoundProcess)
	{
		pSoundProcess->CloseSound();
		delete pSoundProcess;
	}
}
extern "C" void    apiSoundResampleClose(SHandle hSoundResample)
{
    CSoundResample *pSoundResample = (CSoundResample*)hSoundResample;
    if (pSoundResample)
    {
        pSoundResample->EndResample();
        delete pSoundResample;
    }
}
