#pragma once
#include <stdint.h>
#include <vector>
using namespace std;

#define		MAX_INPUT_SOUND_COUNT		8
#define		MAX_PCM_CHANNEL_COUNT		18

#ifndef _SPEAKER_POSITIONS_
#define _SPEAKER_POSITIONS_
// Speaker Positions for dwChannelMask in WAVEFORMATEXTENSIBLE:
#define SPEAKER_FRONT_LEFT              0x1			//前 左
#define SPEAKER_FRONT_RIGHT             0x2			//前 右
#define SPEAKER_FRONT_CENTER            0x4			//前 中
#define SPEAKER_LOW_FREQUENCY           0x8			//低音
#define SPEAKER_BACK_LEFT               0x10		//后 左
#define SPEAKER_BACK_RIGHT              0x20		//后 右
#define SPEAKER_FRONT_LEFT_OF_CENTER    0x40		//前中的左边
#define SPEAKER_FRONT_RIGHT_OF_CENTER   0x80		//前中的右边
#define SPEAKER_BACK_CENTER             0x100		//后 中
#define SPEAKER_SIDE_LEFT               0x200		//左
#define SPEAKER_SIDE_RIGHT              0x400		//右
#define SPEAKER_TOP_CENTER              0x800		//顶 中
#define SPEAKER_TOP_FRONT_LEFT          0x1000		//顶 前 左
#define SPEAKER_TOP_FRONT_CENTER        0x2000		//顶 前 中
#define SPEAKER_TOP_FRONT_RIGHT         0x4000		//顶 前 右
#define SPEAKER_TOP_BACK_LEFT           0x8000		//顶 后 左
#define SPEAKER_TOP_BACK_CENTER         0x10000		//顶 后 中
#define SPEAKER_TOP_BACK_RIGHT          0x20000		//顶 后 右

// Bit mask locations reserved for future use
#define SPEAKER_RESERVED                0x7FFC0000

// Used to specify that any possible permutation of speaker configurations
#define SPEAKER_ALL                     0x80000000
#endif // _SPEAKER_POSITIONS_
class CSoundProcess;
class CSoundResample
{
public:
	CSoundResample();
	~CSoundResample();

	enum ESampleBits
	{
		eSampleBit8i,
		eSampleBit16i,
		eSampleBit24i,
		eSampleBit32i,
		eSampleBit24In32i,
		eSampleBit32f,
	};

	//开始音频重采样。
	//设置输出的PCM音频数据格式。采样格式、采样率、声道数和多声道的位置mask。
	//参数：eSampleFormat	音频数据的采样格式，位数。
	//		nSamplesPerSec	每秒的采样数。
	//		nChannels		声道数, 1 到 MAX_PCM_CHANNEL_COUNT。
	//		uChannelMask	当超过两声道时，设置各个声道的位置。
	//						只有当输入和输出音频的声道不一样时才需要设置。通常设置为0.
	//						MASK 值的含义见本文件尾部
	//备注：必须调用本函数后，才能调用其它函数。
	//		调用本函数后，默认输入和输出的音频格式均是本函数的参数值。
	//		默认只有一个输入通道，调用 PutInput 时索引值为 0。
	bool BeginResample( ESampleBits eSampleFormat, uint32_t nSamplesPerSec, uint32_t nChannels = 2, uint32_t uChannelMask = 0 );
	void EndResample();

	//设置输入的音频数据格式。
	//当输入和输出的音频格式不一样时，或者需要把多个输入合并成一个输出时，才需要调用。
	//参数：iInputIndex			设置指定通道的输入音频的格式。从 0 开始小于 MAX_INPUT_SOUND_COUNT 的值。
	//		其它参数		和 OpenSound 一样。
	//备注：初始时只有 0 号输入通道可以使用，且格式与 OpenSound 设置的格式一样。
	//		如果要为输入设置不同的格式，或者使用多个输入合成一个声音，就调用本函数。
	bool SetInput( ESampleBits eSampleFormat, uint32_t nSamplesPerSec, uint32_t nChannels = 2, int32_t iInputIndex = 0, uint32_t uChannelMask = 0 );

	//恢复输入通道的默认状态。
	//参数：iInputIndex		恢复指定输入通道的默认状态
	//						0 号通道默认与输出格式一致，其它通道默认关闭。
	bool ResetInput( int32_t iInputIndex = 0 );

	//设置指定通道的混音时的音量
	//参数：fVolume			通常在 0 到 1 之间，但不限制。
	bool SetMixVolume( float fVolume, int32_t iInputIndex = 0 );

	//设置输出音量
	//参数：fVolume			0 到 1。
	bool SetOutVolume( float fVolume );

	//以平滑的方式限制限制音量不能超出有效的数值范围
	//声音在混音后，音量可能超出有效的数值范围，设置此限制后，会平滑处理音量的大小。
	//但有可能造成音量的不均匀，或对音质产生负面影响。
	//参数：bLimit			true 表示限制溢出。 false 表示不限制，超出范围的直接截断。
	//备注：默认不对音量进行平滑处理。
	bool SmoothVolumeOverflow( bool bLimit = true );

	//输入音频数据
	//参数：pWaveData		PCM音频数据。
	//		uSampleCount	输入数据的采样数，每个采样包含所有声道。
	//		iIndex			当前输入的音频数据的通道编号。注意：是通道，不是声道。
	//返回：成功返回 true，失败返回 false。
	bool PutInput( const void* pWaveData, int32_t iSampleCount, int32_t iInputIndex = 0 );

	//取得处理完成的音频数据
	//参数：pWaveData		返回的PCM音频数据
	//		nSamplesMax		pWaveData 缓冲区能容纳的最大采样数，每个采样包含所有声道的数据。
	//						如果此参数为 0，则忽略 pWaveData，并且函数返回当前可以获得的采样数。
	//返回：实际获取到的完成处理的采样数，可以为 0。
	//		返回 -1 表示失败。
	int32_t	GetOutput( void* pWaveData, uint32_t nSamplesMax );

	//把所有还没有处理完成的数据置为已经处理的状态。
	//然后可以调用 GetOutput 得到它们。
	//只有在所有的音频已经输入完成，需要关闭重采样器时，才需要调用这个函数。
	//调用 Flush() 后，不要再输入音频数据。
	//返回：缓冲区中可以获得的采样数量。
	int32_t Flush();
	
	static ESampleBits SampleBitsFromWaveTag( uint16_t wFormatTag, uint16_t	wBitsPerSample );

protected:
	friend CSoundProcess;
	struct SChannelMap
	{
		int32_t		iInpChannel;
		int32_t		iOutChannel;
		float		fVolumeOpt;
		float		fVolumeMul;
	};
	struct SWaveFormat
	{
		ESampleBits	eSampleBits;
		uint32_t	nSamplesPerSec;
		uint16_t	nChannels;
		uint16_t	nBlockAlign;
		uint32_t	uChannelMask;

	};
	struct SWaveInput : public SWaveFormat
	{
		bool		bEnabled;
		float		fVolumeOpt;
		SChannelMap	aChannelMap[MAX_PCM_CHANNEL_COUNT];
		uint32_t	uMapCount;
		float		aLastSample[MAX_PCM_CHANNEL_COUNT];
		uint64_t	uInpSamples;	//已经输入的采样数
		uint64_t	uResamples;		//已经完成的重采样数
	};
	SWaveInput		m_fmtInput[MAX_INPUT_SOUND_COUNT];
	SWaveFormat		m_fmtOutput;
	float			m_fOutWindowNearest;	//输出窗口的近似时间
	int32_t			m_iOutWindowSample;
	int32_t			m_uOutWindowPower;		//窗口大小是2的几次方
	int32_t			m_uOutWindowBytes;
	vector<float*>	m_vOutWaveCache;
	vector<float*>	m_vOutBufPool;

	uint64_t		m_uFirstSample;		//输出缓存中，第一单元首指针的sample序号
	uint32_t		m_uDoneOffset;		//输出缓存中，第一单元已经被调用者取出的长度(sample)

	bool			m_bResampleing;
	inline uint32_t bytesPerSamples( ESampleBits eSample )
	{
		const uint32_t bytes[]	={ 1, 2, 3, 4, 4, 4 };
		return bytes[eSample];
	}

	bool			m_bLimitVolumeOverflow;	//限制音量溢出
	float			m_fRealVolume;		//当前统计片段的音量
	float			m_fCurrentVolume;	//当前实际限制的音量 0~1
	float			m_fTargetVolume;	//当前要限制到的目标音量 0~1
	float			m_fIncrementVolume;	//音量的增量，从 m_fCurrentVolume 到 m_fTargetVolume，经过每个 Sample 时，音量的变化。
	int32_t			m_iVolumeStatistic;	//统计音量的采样长度
	int32_t			m_iVolumeSampleInd;	//当前已经计算了音量的采样长度的数量
	int32_t			m_iLimitSample;		//在多少 Sample 内把音量限制到目标音量。
	int32_t			m_iLimitSampleInd;

	float			m_fOutputVolume;

	virtual void callSoundProcess( float* pWindow, int32_t iOffset, int32_t iLength, float* pPreWindow );

	float* getCacheBuf( const SWaveInput& sInp, int32_t& iOffset, float** pPreWindow = nullptr, float* pChannel[] = nullptr );

	void resetMixChannelVolume( int32_t iInputIndex );
	void setChannelMapping( int32_t iInputIndex );
	uint32_t getDefaultChannelLayout( int32_t iChannels );
	virtual uint64_t getDoneSampleCount( bool bMin = true );

	void resampleSame( const void * pWaveData, int32_t iSampleCount, int32_t iInputIndex );
	void resampleNear( const void * pWaveData, int32_t iSampleCount, int32_t iInputIndex );
	void resampleLine( const void * pWaveData, int32_t iSampleCount, int32_t iInputIndex );
};

