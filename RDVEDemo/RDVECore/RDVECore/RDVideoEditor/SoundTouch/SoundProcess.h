#pragma once
#include <stdint.h>
#include "SoundResample.h"


class CSoundProcess : public CSoundResample
{
public:
	CSoundProcess();
	~CSoundProcess();

	//开始。打开音频处理。
	//设置的PCM音频数据格式。采样格式、采样率、声道数和多声道的位置mask。
	//参数：eSampleFormat	音频数据的采样格式，位数。
	//		nSamplesPerSec	每秒的采样数。
	//		nChannels		声道数, 1 到 MAX_PCM_CHANNEL_COUNT。
	//备注：必须调用本函数后，才能调用其它函数。
	bool OpenSound( ESampleBits eSampleFormat, uint32_t nSamplesPerSec, uint32_t nChannels = 2 );

	//结束。音频处理结束。
	void CloseSound();


	//输入音频数据
	//参数：pWaveData		PCM音频数据。格式必须与 OpenSound 设置的格式一致。
	//		iSampleCount	输入数据的采样数，每个采样包含所有声道。
	//返回：成功返回 true，失败返回 false。
	bool PutInput( const void* pWaveData, int32_t iSampleCount );

	//取得处理完成的音频数据
	//参数：pWaveData		返回的PCM音频数据
	//		iSamplesMax		pWaveData 缓冲区能容纳的最大采样数，每个采样包含所有声道的数据。
	//						如果此参数为 0，则忽略 pWaveData，并且函数返回当前可以获得的采样数。
	//返回：实际获取到的完成处理的采样数，可以为 0。
	//		返回 -1 表示失败。
	int32_t	GetOutput( void* pWaveData, int32_t iSamplesMax );

	//把所有还没有处理完成的数据置为已经处理的状态。
	//然后可以调用 GetOutput 得到它们。
	//只有在所有的音频已经输入完成，需要关闭重采样器时，才需要调用这个函数。
	//调用 Flush() 后，不要再输入音频数据。
	//返回：缓冲区中可以获得的采样数量。
	int32_t Flush();

	//开启、关闭去噪功能。
	//参数：fRatio			去噪的比例。0~1之间。不能大于 1，否则是增加噪声。
	//						当值为 0 时，将不启用去噪的功能。
	//备注：去噪会对声音造成损失。
	bool NoiseCancelling( float fRatio = 1.0f );


	//设置变声模式
	//参数：fTempo	节拍，声音变长不变调。
	//		fPitch	音调
	//		fRate	速度
	//备注：参数都是大于 0 的浮点数。1 为声音不变。小于等于 0 都是无效参数。
	//返回：是否设置成功。如果参数无效导致的失败，则保持之前的设置。
	bool SetSoundTouch( float fTempo, float fPitch, float fRate );
	void CloseSoundTouch();

	struct SReverbOption
	{
		struct
		{
			float fDelaySecond;	//延迟的时间，秒数。大于 0 并小于等于 1 的值。
			float fAttenuation; //衰减系数。大于 0 并小于 1 的值。
		}echo[4],reverb[2];
	};
	//设置回声和混响
	//参数：pReverb		回声和混响的延时及衰减。
	//					回声最多4个，如果某顶的延时或衰减小于等于0，则表示这一顶不起作用。
	//					混响最多2个，如果某顶的延时或衰减小于等于0，则表示这一顶不起作用。
	//返回：如果所有项目都参数都是无效的，则返回 false，设置成功返回 true
	bool SetReverb( const SReverbOption* pReverb );
	void CloseReverb();

	//设置声音片段叠加
	//参数：eSampleFormat	叠加的声音数据的采样格式
	//		nSamplesPerSec	叠加的声音数据的采样率
	//		pWaveData		声音数据。必须是单声道的数据。声音会同时叠加到所有的声道。
	//		fVolume			叠加的音量(加法叠加 SetOverlayAdd )。值范围通常为 0 到 1，但并不限制。
	//						如果值小于 0，将会计算原始音频的实际音量，并与参数的绝对值相乘来作为叠加时的音量。
	//		fRatio			叠加的比例(乘法叠加 SetOverlayMul )。值范围通常为 0 到 1，但并不限制。
	//						计算时会使用 fRatio 与声音片段相乘，再与原始声音相乘。
	//		fWaitSecond		完成一次叠加后，等待多少秒再进行下一次叠加。
	//返回：是否设置成功。如果参数无效导致的失败，则保持之前的设置。
	//备注：如果叠加的音频数据与原始音频的采样格式不同，会自动进行重新采样。
	//		成功调用 SetOverlayAdd、SetOverlayMul 后，会一直循环叠加指定的音频片段，
	//		直到调用 CloseOverlayAdd、CloseOverlayMul 关闭叠加。
	//		如果再次调用 SetOverlayAdd、SetOverlayMul，会替换之前设置的音频片段。
	bool SetOverlayAdd( ESampleBits eSampleFormat, uint32_t nSamplesPerSec, const void* pWaveData, uint32_t uSampleCount, float fVolume = 1.0f, float fWaitSecond = 0.0f );
	bool SetOverlayMul( ESampleBits eSampleFormat, uint32_t nSamplesPerSec, const void* pWaveData, uint32_t uSampleCount, float fRatio = 1.0f, float fWaitSecond = 0.0f );
	void CloseOverlayAdd();
	void CloseOverlayMul();

	//设置全局的音量
	//参数：fVolume			0 到 1 之间。
	bool SetOutVolume( float fVolume ) { return CSoundResample::SetOutVolume( fVolume ); }
	//设置音量超限时，是否对音量进行平滑的减小。
	//参数：bLimit		true 表示平滑超限的声音音量。false 直接截断为有效的最大值。
	//备注：默认为 false。
	bool SmoothVolumeOverflow( bool bLimit = true ) { return CSoundResample::SmoothVolumeOverflow( bLimit ); }

	//设置声音淡入淡出
	//参数：fBeginVolume	初始的音量。如果淡入，初始通常设置为 0，淡出则通常设置为 1。
	//		fEndVolume		结束的音量。如果淡入，初始通常设置为 1，淡出则通常设置为 0。
	//		fDuration		淡入淡出的持续时长，单位为秒。
	//备注：每次调用都会重新计算淡入淡出的效果，如果要中途终止，可以把 fDuration 设置为 0.
	//		淡入淡出的声音是以全局的音量为基准进行计算，
	//		只要fBeginVolume和fEndVolume的参数值不大于1，处理后的声音音量就不会大于全局音量。
	bool SetFadeInFadeOut( float fBeginVolume, float fEndVolume, float fDuration );

	struct SEqualizer
	{
		float	fFrequency;	//频率，赫兹
		float	fGain;		//增益
	};
	//设置均衡器
	//参数：fFrequencys		均衡器的频段列表。按频段的频率从低到高排列的数组。
	//						例如 10 段均衡，通常值为 32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000
	//						函数内不限制频段的值，实际的频率增益曲线将通过三次样条曲线进行拟合。
	//		fGains			频段对应的增益，值从 -1 到 1，0为不变。
	//						这个数组中的项目必须与 fFrequencys 一一对应。
	//						函数内并不限定值范围，可以设置超出 -1 到 1 的范围。
	//		iCount			频段的数量。范围为 1 到 32 个。
	bool SetEqualizer( const SEqualizer* pEqualizer, int32_t iCount );
	void CloseEqualizer();
	//取得频谱，用于显示频谱
	//bool GetFrequencySpectrum();
	//
#define FFT_FORWARD 0
#define FFT_REVERSE 1
#ifndef M_PI
#define M_PI       3.14159265358979323846   // pi
#endif
	static void fft( int dir, long m, float *x, float *y );
private:
	bool	m_bProcessing;		//处理中。
	bool	m_bUseSoundTouch;	//
	bool	m_bUseEcho;
	CSoundResample	m_cResampTouch;

	struct SChannel
	{
		float	fOutputDelay;	//延迟时间
		int32_t	iDelayFrame;	//延迟 Frame
		float*	pCopyBuf;		//原声的复制品
		float*	pEchoBuf;		//回声处理后的 buf。
		float*	pReverbBuf[2];	//混响处理后的 buf。
		float*	pCurrentCopy;	//指针，指向 pCopyBuf 或 pEchoBuf 或 pReverbBuf。在音频处理后，它就是处理之后的声音数据。
		void*	hSoundTouch;	//SoundTouch的句柄
	};
	SChannel	m_arrChannel[MAX_PCM_CHANNEL_COUNT];
	void*		m_hSoundTouch;	//SoundTouch的句柄(仅声道数小于等于2时)

	int32_t		m_iWaveBufAlloc;
	int32_t		m_iWaveTopCopy;		//缓存音频数据的循环队列中，当前写入数据的位置
	//int32_t		m_iWaveTopEcho;		//缓存回声效果处理后的音频数据物循环队列中，当前写入数据的位置
	uint64_t	m_uCopyedSample;	//已经缓存的采样数。（循环缓存，前面的数据丢失，这里是记录的累计数量）

	struct SReverb
	{
		float	fDelay;			//延迟时间
		float	fAttenuation;	//衰减，0~1
		int32_t	iForward;		//向前的采样数
	};
	SReverb		m_arrEcho[4];
	SReverb		m_arrReverb[2];
	uint32_t	m_uReverbCount;

	//声音叠加，加法或乘法
	struct SOverlay
	{
		float*	pWaveBuf;
		int32_t	iTotCount;
		int32_t	iSampleCount;
		int32_t	iSampleTop;
		float	fVolume;

	};
	SOverlay	m_sOverlayAdd;
	SOverlay	m_sOverlayMul;
	int32_t		m_iFifoSample;	//fade-in fade-out 淡入淡出 效果的持续采样数
	int32_t		m_iFifoDone;	//淡入淡出效果已经完成的采样数
	float		m_fFifoVolBeg;
	float		m_fFifoVolEnd;

	#define		MAX_EQUALIZER_COUNT			32
	SEqualizer	m_arrEqual[MAX_EQUALIZER_COUNT];	//均衡器的设置
	uint32_t	m_uEqualCount;	//均衡器设置的段数
	float*		m_pEqSpline;
	float*		m_pEqFftReal;	//进行 fft 变换时的实数部分
	float*		m_pEqFftImag;	//进行 fft 变换时的虚数部分
	uint64_t	m_uEqDoneSample;//已经进行过均衡器增益的采样数量
	float		m_fNoiseCancelling;	//噪声消除的比率，通常为 0 到 1
	float*		m_pPowerSpectrum;	//频率-能量谱
	float*		m_pNosieSpectrum;	//噪声的频率-能量谱
	int32_t		m_iNosieWindows;

	virtual void callSoundProcess( float* pWindow, int32_t iOffset, int32_t iLength, float* pPreWindow );
	void soundProcessOverlay( const int32_t iLength );
	void soundProcessEcho( const int32_t iLength );
	void soundProcessFifo( const int32_t iLength );
	virtual uint64_t getDoneSampleCount( bool bMin = true ) {
		return bMin ? m_uEqDoneSample : CSoundResample::getDoneSampleCount();
	}
	inline void copyFromSample( uint64_t uBegin, int32_t iChannel, float* pBuffer, int32_t iLength, float * pWindow, float* pPreWindow );
	inline void copyToSample( uint64_t uBegin, int32_t iChannel, float* pBuffer, int32_t iLength, float * pWindow, float* pPreWindow );
	void AddToNosieSpectrum();
};
