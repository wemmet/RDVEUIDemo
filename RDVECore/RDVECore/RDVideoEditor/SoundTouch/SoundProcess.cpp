#include "SoundProcess.h"
#include <algorithm>
#include <cmath>
#include "CubicSpline.h"
#include <stdlib.h>
#include "SoundTouchDLL.h"
#pragma comment ( lib, "SoundTouchDll.lib" )

CSoundProcess::CSoundProcess()
{
	m_bProcessing		= true;
	m_bUseSoundTouch	= false;
	m_pEqSpline			= nullptr;
	m_pEqFftReal		= nullptr;
	m_pEqFftImag		= nullptr;
	m_pPowerSpectrum	= nullptr;
	m_pNosieSpectrum	= nullptr;
	m_iNosieWindows		= 0;
	m_hSoundTouch		= nullptr;
	memset( m_arrChannel, 0, sizeof( m_arrChannel ) );
	memset( &m_sOverlayAdd, 0, sizeof( m_sOverlayAdd ) );
	memset( &m_sOverlayMul, 0, sizeof( m_sOverlayAdd ) );
	CloseSound();

	return;
}

CSoundProcess::~CSoundProcess()
{
}

bool CSoundProcess::OpenSound( ESampleBits eSampleFormat, uint32_t nSamplesPerSec, uint32_t nChannels )
{
	if ( m_bProcessing ) return false;
	if ( eSampleFormat < eSampleBit8i || eSampleFormat > eSampleBit32f ||
		nSamplesPerSec <= 0 || nSamplesPerSec > 96000 ||
		nChannels <= 0 || nChannels > MAX_PCM_CHANNEL_COUNT )
	{
		return false;
	}
	m_iWaveBufAlloc		= nSamplesPerSec * 5;
	m_iWaveTopCopy		= 0;
	//m_iWaveTopEcho		= 0;
	m_uEqDoneSample	= 0;
	for ( int32_t i = 0; i < nChannels; ++i )
	{
		m_arrChannel[i].pCopyBuf	= (float*)malloc( m_iWaveBufAlloc * sizeof( float ) );
		memset( m_arrChannel[i].pCopyBuf, 0, m_iWaveBufAlloc * sizeof( float ) );
		m_arrChannel[i].pEchoBuf	= (float*)malloc( m_iWaveBufAlloc * sizeof( float ) );
		memset( m_arrChannel[i].pEchoBuf, 0, m_iWaveBufAlloc * sizeof( float ) );
		for ( int32_t r = 0; r < 2; ++r )
		{
			m_arrChannel[i].pReverbBuf[r]	= (float*)malloc( m_iWaveBufAlloc * sizeof( float ) );
			memset( m_arrChannel[i].pReverbBuf[r], 0, m_iWaveBufAlloc * sizeof( float ) );
		}
	}

	m_fOutWindowNearest	= 0.015;
	if ( nChannels > 2 || ( eSampleFormat != eSampleBit16i && eSampleFormat != eSampleBit32f ) )
	{
		m_cResampTouch.BeginResample( eSampleBit32f, nSamplesPerSec, nChannels );
		m_cResampTouch.SetInput( eSampleFormat, nSamplesPerSec, nChannels );
	}
	BeginResample( eSampleFormat, nSamplesPerSec, nChannels );

	m_pEqSpline	= (float*)malloc( m_iOutWindowSample * sizeof( float ) );
	memset( m_pEqSpline, 0, m_iOutWindowSample * sizeof( float ) );
	m_pEqFftReal	= (float*)malloc( m_iOutWindowSample * sizeof( float ) );
	memset( m_pEqFftReal, 0, m_iOutWindowSample * sizeof( float ) );
	m_pEqFftImag	= (float*)malloc( m_iOutWindowSample * sizeof( float ) );
	memset( m_pEqFftImag, 0, m_iOutWindowSample * sizeof( float ) );

	m_pPowerSpectrum	= (float*)malloc( m_iOutWindowSample * sizeof( float ) );
	memset( m_pPowerSpectrum, 0, m_iOutWindowSample * sizeof( float ) );
	m_pNosieSpectrum	= (float*)malloc( m_iOutWindowSample * sizeof( float ) );
	memset( m_pNosieSpectrum, 0, m_iOutWindowSample * sizeof( float ) );

	m_bProcessing		= true;
	return true;
}

void CSoundProcess::CloseSound()
{
	if ( m_bProcessing )
	{
		int32_t		channelCount	= m_fmtOutput.nChannels;
		EndResample();
		m_cResampTouch.EndResample();
		CloseSoundTouch();
		m_bProcessing		= false;
		m_bUseSoundTouch	= false;
		for ( int32_t i = 0; i < channelCount; ++i )
		{
			if ( m_arrChannel[i].pCopyBuf ) free( m_arrChannel[i].pCopyBuf );
			if ( m_arrChannel[i].pEchoBuf ) free( m_arrChannel[i].pEchoBuf );
			for ( int32_t r = 0; r < 2; ++r )
				if ( m_arrChannel[i].pReverbBuf[r] ) free( m_arrChannel[i].pReverbBuf[r] );
		}
		memset( m_arrChannel, 0, sizeof( m_arrChannel ) );
		m_iWaveBufAlloc		= 0;
		m_iWaveTopCopy		= 0;
		//m_iWaveTopEcho		= 0;
		m_uCopyedSample		= 0;
		m_uEqDoneSample		= 0;

		memset( m_arrEcho, 0, sizeof( m_arrEcho ) );
		memset( m_arrReverb, 0, sizeof( m_arrReverb ) );
		m_bUseEcho			= false;
		m_uReverbCount		= 0;
		CloseOverlayAdd();
		CloseOverlayMul();
		m_iFifoSample		= 0;
		m_iFifoDone			= 0;


		memset( m_arrEqual, 0, sizeof( m_arrEqual ) );
		m_uEqualCount		= 0;
		if ( m_pEqSpline ) free( m_pEqSpline );
		m_pEqSpline			= nullptr;
		if ( m_pEqFftReal ) free( m_pEqFftReal );
		m_pEqFftReal		= nullptr;
		if ( m_pEqFftImag ) free( m_pEqFftImag );
		m_pEqFftImag		= nullptr;

		if ( m_pPowerSpectrum ) free( m_pPowerSpectrum );
		m_pPowerSpectrum		= nullptr;
		if ( m_pNosieSpectrum ) free( m_pNosieSpectrum );
		m_pNosieSpectrum		= nullptr;

		m_fNoiseCancelling		= 0.0f;
		m_iNosieWindows			= 0;
	}
}

bool CSoundProcess::PutInput( const void * pWaveData, int32_t iSampleCount )
{
	if ( !m_bProcessing || nullptr == pWaveData || 0 >= iSampleCount ) return false;
	if ( m_bUseSoundTouch )
	{
		if ( m_hSoundTouch )
		{
			if ( m_fmtInput->eSampleBits == eSampleBit16i )
			{
				soundtouch_putSamples_i16( m_hSoundTouch, (const short*)pWaveData, iSampleCount );
				short	wavBuf[512];
				iSampleCount	= soundtouch_receiveSamples_i16( m_hSoundTouch, wavBuf, sizeof( wavBuf ) / sizeof( short ) / m_fmtInput->nChannels );
				while ( iSampleCount > 0 )
				{
					CSoundResample::PutInput( wavBuf, iSampleCount );
					iSampleCount	= soundtouch_receiveSamples_i16( m_hSoundTouch, wavBuf, sizeof( wavBuf ) / sizeof( short ) / m_fmtInput->nChannels );
				}
			}
			else
			{
				soundtouch_putSamples( m_hSoundTouch, (const float*)pWaveData, iSampleCount );
				float	wavBuf[512];
				iSampleCount	= soundtouch_receiveSamples( m_hSoundTouch, wavBuf, sizeof( wavBuf ) / sizeof( float ) / m_fmtInput->nChannels );
				while ( iSampleCount > 0 )
				{
					CSoundResample::PutInput( wavBuf, iSampleCount );
					iSampleCount	= soundtouch_receiveSamples( m_hSoundTouch, wavBuf, sizeof( wavBuf ) / sizeof( float ) / m_fmtInput->nChannels );
				}
			}
		}
		else
		{
			m_cResampTouch.PutInput( pWaveData, iSampleCount );
			int32_t	iDoneSample	= int32_t( m_cResampTouch.m_fmtInput->uResamples );
			for ( auto i = m_cResampTouch.m_vOutWaveCache.begin(); i != m_cResampTouch.m_vOutWaveCache.end(); ++i )
			{
				int32_t	iGet	= min( iDoneSample, m_cResampTouch.m_iOutWindowSample );
				for ( int32_t c = 0; c < m_fmtOutput.nChannels; ++c )
				{
					soundtouch_putSamples( m_arrChannel[c].hSoundTouch, *i + c * m_cResampTouch.m_iOutWindowSample, iGet );
				}
				iDoneSample	-= iGet;
				m_cResampTouch.m_vOutBufPool.push_back( *i );
			}
			m_cResampTouch.m_vOutWaveCache.clear();
			m_cResampTouch.m_fmtInput->uResamples	= 0;
			m_cResampTouch.m_fmtInput->uInpSamples	= 0;

			iSampleCount	= soundtouch_numSamples( m_arrChannel[0].hSoundTouch );
			while ( iSampleCount )
			{
				int32_t	iOffset	= 0;
				float*	pPreBuf	= nullptr;
				float*	pWindow	= getCacheBuf( m_fmtInput[0], iOffset, &pPreBuf );
				int32_t	iGet	= min( m_iOutWindowSample - iOffset, iSampleCount );
				for ( int32_t c = 0; c < m_fmtOutput.nChannels; ++c )
				{
					iGet	= soundtouch_receiveSamples( m_arrChannel[c].hSoundTouch,
						pWindow + iOffset + c * m_iOutWindowSample, iGet );
				}
				m_fmtInput->uResamples	+= iGet;
				m_fmtInput->uInpSamples	+= iGet;
				iSampleCount	-= iGet;
				callSoundProcess( pWindow, iOffset, iGet, pPreBuf );
			}
		}
	}
	else
	{
		CSoundResample::PutInput( pWaveData, iSampleCount );
	}
	return true;
}

int32_t CSoundProcess::GetOutput( void * pWaveData, int32_t iSamplesMax )
{
	return CSoundResample::GetOutput( pWaveData, iSamplesMax );
}

int32_t CSoundProcess::Flush()
{
	CloseEqualizer();
	return CSoundResample::Flush();
}

bool CSoundProcess::NoiseCancelling( float fRatio )
{
	if ( !m_bProcessing ) return false;
	//如果之前是不去噪，就需要把循环缓冲队列清空出一个窗口的长度。
	if ( m_fNoiseCancelling != fRatio && m_fNoiseCancelling == 0.0f )
	{
		int32_t	iHalfWindow	= m_iOutWindowSample / 2;
		int32_t	iTop	= m_iWaveTopCopy;
		for ( int32_t c = 0; c < m_fmtOutput.nChannels; ++c )
		{
			float*	pCopy	= m_arrChannel[c].pCopyBuf;
			for ( int32_t i = 0; i < iHalfWindow; ++i )
			{
				float	fRewnd	= 0.5f * ( 1.0f + cos( ( 2.0f * M_PI * i ) / ( m_iOutWindowSample - 1 ) ) );
				pCopy[( iTop++ ) % m_iWaveBufAlloc] *= fRewnd;
			}
			for ( int32_t i = 0; i < iHalfWindow; ++i )
			{
				pCopy[( iTop++ ) % m_iWaveBufAlloc] = 0.0f;
			}
		}
	}
	m_fNoiseCancelling	= fRatio;
	return true;
}

bool CSoundProcess::SetSoundTouch( float fTempo, float fPitch, float fRate )
{
	if ( !m_bProcessing ) return false;
	if ( fTempo < 0.0f || fPitch < 0.0f || fRate < 0.0f )
		return false;
	if ( fTempo != 1.0f || fPitch != 1.0f || fRate != 1.0f )
	{
		m_bUseSoundTouch	= true;
		if ( m_fmtInput->nChannels <= 2 && ( m_fmtInput->eSampleBits == eSampleBit16i || m_fmtInput->eSampleBits == eSampleBit32f ) )
		{
			if ( nullptr == m_hSoundTouch )
			{
				m_hSoundTouch	= soundtouch_createInstance();
				if ( nullptr == m_hSoundTouch )
				{
					m_bUseSoundTouch	= false;
					return false;
				}
				soundtouch_setChannels( m_hSoundTouch, m_fmtInput->nChannels );
				soundtouch_setSampleRate( m_hSoundTouch, m_fmtInput->nSamplesPerSec );
			}
			soundtouch_setTempo( m_hSoundTouch, fTempo );
			soundtouch_setPitch( m_hSoundTouch, fPitch );
			soundtouch_setRate( m_hSoundTouch, fRate );
		}
		else
		{
			for ( int32_t i = 0; i < m_fmtOutput.nChannels; ++i )
			{
				if ( nullptr == m_arrChannel[i].hSoundTouch )
				{
					m_arrChannel[i].hSoundTouch	= soundtouch_createInstance();
					if ( nullptr == m_arrChannel[i].hSoundTouch )
					{
						m_bUseSoundTouch	= false;
						return false;
					}
					soundtouch_setChannels( m_arrChannel[i].hSoundTouch, 1 );
					soundtouch_setSampleRate( m_arrChannel[i].hSoundTouch, m_fmtOutput.nSamplesPerSec );
				}
				soundtouch_setTempo( m_arrChannel[i].hSoundTouch, fTempo );
				soundtouch_setPitch( m_arrChannel[i].hSoundTouch, fPitch );
				soundtouch_setRate( m_arrChannel[i].hSoundTouch, fRate );
			}
		}

	}
	else
	{
		//如果声音设置为完全不变，就不需要使用 SoundTouch
		m_bUseSoundTouch	= false;
		for ( int32_t i = 0; i < m_fmtOutput.nChannels; ++i )
		{
			if ( m_arrChannel[i].hSoundTouch )
			{
				soundtouch_destroyInstance( m_arrChannel[i].hSoundTouch );
				m_arrChannel[i].hSoundTouch	= nullptr;
			}
		}
		if ( m_hSoundTouch )
		{
			soundtouch_destroyInstance( m_hSoundTouch );
			m_hSoundTouch	= nullptr;
		}
	}

	return true;
}

void CSoundProcess::CloseSoundTouch()
{
	SetSoundTouch( 1.0f, 1.0f, 1.0f );
}

bool CSoundProcess::SetReverb( const SReverbOption* pReverb )
{
	if ( !m_bProcessing ) return false;
	m_bUseEcho		= false;
	m_uReverbCount	= 0;
	for ( int32_t i = 0; i < 4; ++i )
	{
		if ( pReverb->echo[i].fAttenuation <= 0.0f || pReverb->echo[i].fDelaySecond <= 0.0f )
		{
			m_arrEcho[i].fAttenuation	= 0.0f;
			m_arrEcho[i].fDelay			= 0.0f;
			m_arrEcho[i].iForward		= 0;
		}
		else
		{
			m_arrEcho[i].fAttenuation	= pReverb->echo[i].fAttenuation;
			m_arrEcho[i].fDelay			= pReverb->echo[i].fDelaySecond;
			m_arrEcho[i].iForward		= int32_t( m_fmtOutput.nSamplesPerSec * m_arrEcho[i].fDelay );
			m_bUseEcho					= true;
		}
	}
	for ( int32_t i = 0; i < 2; ++i )
	{
		if ( pReverb->reverb[i].fAttenuation > 0.0f && pReverb->reverb[i].fDelaySecond > 0.0f )
		{
			m_arrReverb[m_uReverbCount].fAttenuation	= pReverb->reverb[i].fAttenuation;
			m_arrReverb[m_uReverbCount].fDelay			= pReverb->reverb[i].fDelaySecond;
			m_arrReverb[m_uReverbCount].iForward		= int32_t( m_fmtOutput.nSamplesPerSec * m_arrReverb[m_uReverbCount].fDelay );
			++m_uReverbCount;
		}
	}

	return true;
}

void CSoundProcess::CloseReverb()
{
	m_bUseEcho		= false;
	m_uReverbCount	= 0;
	memset( m_arrEcho, 0, sizeof( m_arrEcho ) );
	memset( m_arrReverb, 0, sizeof( m_arrReverb ) );
}

bool CSoundProcess::SetOverlayAdd( ESampleBits eSampleFormat, uint32_t nSamplesPerSec, const void * pWaveData, uint32_t uSampleCount, float fVolume, float fWaitSecond )
{
	if ( !m_bProcessing || nullptr == pWaveData || 0 == uSampleCount || fWaitSecond < 0.0f ) return false;
	CSoundResample	resamp;
	if ( !resamp.BeginResample( eSampleBit32f, m_fmtOutput.nSamplesPerSec, 1 )
		|| !resamp.SetInput( eSampleFormat, nSamplesPerSec, 1 ) )
	{
		return false;
	}
	resamp.PutInput( pWaveData, uSampleCount );
	m_sOverlayAdd.iSampleCount	= resamp.Flush();
	m_sOverlayAdd.pWaveBuf		= (float*)realloc( m_sOverlayAdd.pWaveBuf, m_sOverlayAdd.iSampleCount * sizeof( float ) );
	resamp.GetOutput( m_sOverlayAdd.pWaveBuf, m_sOverlayAdd.iSampleCount );
	m_sOverlayAdd.iSampleTop	= 0;
	m_sOverlayAdd.fVolume		= fVolume;
	m_sOverlayAdd.iTotCount		= fWaitSecond * m_fmtOutput.nSamplesPerSec + m_sOverlayAdd.iSampleCount;
	fVolume	= abs( fVolume );
	for ( int32_t i = 0; i < m_sOverlayAdd.iSampleCount; ++i )
		m_sOverlayAdd.pWaveBuf[i]	*= fVolume;
	return true;
}

bool CSoundProcess::SetOverlayMul( ESampleBits eSampleFormat, uint32_t nSamplesPerSec, const void * pWaveData, uint32_t uSampleCount, float fRatio, float fWaitSecond )
{
	if ( !m_bProcessing || nullptr == pWaveData || 0 == uSampleCount || fWaitSecond < 0.0f ) return false;
	CSoundResample	resamp;
	if ( !resamp.BeginResample( eSampleBit32f, m_fmtOutput.nSamplesPerSec, 1 )
		|| !resamp.SetInput( eSampleFormat, nSamplesPerSec, 1 ) )
	{
		return false;
	}
	resamp.PutInput( pWaveData, uSampleCount );
	m_sOverlayMul.iSampleCount	= resamp.Flush();
	m_sOverlayMul.pWaveBuf		= (float*)realloc( m_sOverlayMul.pWaveBuf, m_sOverlayMul.iSampleCount * sizeof( float ) );
	resamp.GetOutput( m_sOverlayMul.pWaveBuf, m_sOverlayMul.iSampleCount );
	m_sOverlayMul.iSampleTop	= 0;
	m_sOverlayMul.fVolume		= fRatio;
	m_sOverlayMul.iTotCount		= fWaitSecond * m_fmtOutput.nSamplesPerSec + m_sOverlayMul.iSampleCount;
	fRatio	= abs( fRatio );
	for ( int32_t i = 0; i < m_sOverlayMul.iSampleCount; ++i )
		m_sOverlayMul.pWaveBuf[i]	*= fRatio;
	return true;
}

void CSoundProcess::CloseOverlayAdd()
{
	if ( m_sOverlayAdd.pWaveBuf )
	{
		free( m_sOverlayAdd.pWaveBuf );
		m_sOverlayAdd.pWaveBuf	= nullptr;
	}
	memset( &m_sOverlayAdd, 0, sizeof( m_sOverlayAdd ) );
}

void CSoundProcess::CloseOverlayMul()
{
	if ( m_sOverlayMul.pWaveBuf )
	{
		free( m_sOverlayMul.pWaveBuf );
		m_sOverlayMul.pWaveBuf	= nullptr;
	}
	memset( &m_sOverlayMul, 0, sizeof( m_sOverlayMul ) );
}

bool CSoundProcess::SetFadeInFadeOut( float fBeginVolume, float fEndVolume, float fDuration )
{
	if ( !m_bProcessing || fDuration < 0.0f ) return false;
	m_iFifoSample	= fDuration * m_fmtOutput.nSamplesPerSec;
	m_iFifoDone		= 0;
	m_fFifoVolBeg	= fBeginVolume;
	m_fFifoVolEnd	= fEndVolume;
	return true;
}

bool CSoundProcess::SetEqualizer( const SEqualizer* pEqualizer, int32_t iCount )
{
	if ( !m_bProcessing ) return false;
	if ( nullptr == pEqualizer || iCount <= 0 || iCount > MAX_EQUALIZER_COUNT )
	{
		return false;
	}
	//对输入的频率参数从低到高排序
	memcpy( m_arrEqual, pEqualizer, sizeof( SEqualizer ) * iCount );
	for ( int32_t i = 0; i < iCount - 1; ++i )
	{
		for ( int32_t j = i + 1; i < iCount; ++i )
		{
			if ( m_arrEqual[i].fFrequency > m_arrEqual[j].fFrequency )
			{
				SEqualizer	swap	= m_arrEqual[i];
				m_arrEqual[i]	= m_arrEqual[j];
				m_arrEqual[j]	= swap;
			}
		}
	}
	//排除相同的和无效的频率设置
//    float    fMinFrequency    = m_fmtOutput.nSamplesPerSec * 1.0f / m_iOutWindowSample;
	float	fMaxFrequency	= m_fmtOutput.nSamplesPerSec * 0.5;
	for ( int32_t i = 0; i < iCount; ++i )
	{
		if ( m_arrEqual[i].fFrequency <= 0.0f/*fMinFrequency*/ || m_arrEqual[i].fFrequency > fMaxFrequency )
		{
			memmove( m_arrEqual + i, m_arrEqual + i + 1, iCount - i - 1 );
			--iCount;
			--i;
		}
		else if ( i < iCount - 1 && m_arrEqual[i].fFrequency == m_arrEqual[i + 1].fFrequency )
		{
			memmove( m_arrEqual + i, m_arrEqual + i + 1, iCount - i - 1 );
			--iCount;
			--i;
		}
		if ( m_arrEqual[i].fGain > 1.0f )	m_arrEqual[i].fGain = 1.0f;
		if ( m_arrEqual[i].fGain < -1.0f )	m_arrEqual[i].fGain	= -1.0f;
	}
	if ( 0 == iCount )
	{
		return false;
	}
	//使用三次样条曲线拟合出频率增益曲线
	CCubicSpline	spline;
	int32_t			iHalf	= m_iOutWindowSample / 2;
	for ( int32_t i = 0; i < iCount; ++i )
	{
		spline.InsertPoint( m_arrEqual[i].fFrequency * iHalf / fMaxFrequency, m_arrEqual[i].fGain );
	}
	m_pEqSpline[0]	= 0.0f;	// 0 项是直流分量，不参与增益计算。
	for ( int32_t i = 1; i < iHalf; ++i )
	{
		m_pEqSpline[i]	= spline.GetCurveValue( i );
		if ( m_pEqSpline[i] < -1.0f )	m_pEqSpline[i] = -1.0f;
		if ( m_pEqSpline[i] > 1.0f )	m_pEqSpline[i] = 1.0f;
		m_pEqSpline[m_iOutWindowSample - i]	= m_pEqSpline[i];
	}
	m_uEqualCount	= iCount;
	return true;
}

void CSoundProcess::CloseEqualizer()
{
	m_uEqualCount	= 0;
}

void CSoundProcess::AddToNosieSpectrum()
{
	int32_t			iHalf	= m_iOutWindowSample / 2;
	for ( int32_t i = 1; i <= iHalf; ++i )
	{
		if ( m_pPowerSpectrum[i] > m_pPowerSpectrum[i - 1] && m_pPowerSpectrum[i] > m_pPowerSpectrum[i + 1] )
		{
			m_pPowerSpectrum[m_iOutWindowSample - i]	= m_pPowerSpectrum[i];
		}
		else
		{
			m_pPowerSpectrum[m_iOutWindowSample - i]	= 0;
		}
	}

	int32_t	iSetp	= 16;
	int32_t	iPos0	= 0;
	int32_t	iPos1	= 0;
	float	fMax	= 0.0f;
	float	fDy		= 0.0f;
	float	fPow	= 0.0f;
	for ( int32_t i = 1; i <= iHalf; i += iSetp )
	{
		fMax	= -1.0f;
		for ( int32_t j = 0; j < iSetp; ++j )
		{
			if ( m_pPowerSpectrum[m_iOutWindowSample - i - j] > fMax )
			{
				iPos1	= i + j;
				fMax	= m_pPowerSpectrum[m_iOutWindowSample - iPos1];
			}
		}
		if ( iPos0 )
		{
			fPow = m_pPowerSpectrum[m_iOutWindowSample - iPos0];
		}
		else
		{
			fPow = fMax;
			iPos0	= 1;
		}
		fDy	= ( fMax - fPow ) / ( iPos1 - iPos0 );
		for ( int32_t j = iPos0; j < iPos1; ++j )
		{
			if ( m_iNosieWindows )
				m_pNosieSpectrum[j]	= min( m_pNosieSpectrum[j], fPow );
			else
				m_pNosieSpectrum[j]	= fPow;
			fPow	+= fDy;
		}
		iPos0	= iPos1;
	}
	++m_iNosieWindows;
}

inline void CSoundProcess::copyFromSample( uint64_t uBegin, int32_t iChannel, float* pBuffer, int32_t iLength, float * pWindow, float* pPreWindow )
{
	int32_t		iPos		= 0;
	while ( iLength )
	{
		int32_t		iWindowRemain	= int32_t( uBegin % m_iOutWindowSample );
		bool		bSameWindow		= uBegin / m_iOutWindowSample == ( m_fmtInput->uResamples - 1 ) / m_iOutWindowSample;
		int32_t		iCopy		= min( iLength, m_iOutWindowSample - iWindowRemain );
		if ( bSameWindow )
		{
			memcpy( pBuffer + iPos, pWindow + iChannel * m_iOutWindowSample + iWindowRemain, iCopy * sizeof( float ) );
		}
		else
		{
			memcpy( pBuffer + iPos, pPreWindow + iChannel * m_iOutWindowSample + iWindowRemain, iCopy * sizeof( float ) );
		}
		uBegin	+= iCopy;
		iLength	-= iCopy;
		iPos	+= iCopy;
	}
}

inline void CSoundProcess::copyToSample( uint64_t uBegin, int32_t iChannel, float* pBuffer, int32_t iLength, float * pWindow, float* pPreWindow )
{
	int32_t		iPos		= 0;
	while ( iLength )
	{
		int32_t		iWindowRemain	= int32_t( uBegin % m_iOutWindowSample );
		bool		bSameWindow		= uBegin / m_iOutWindowSample == ( m_fmtInput->uResamples - 1 ) / m_iOutWindowSample;
		int32_t		iCopy		= min( iLength, m_iOutWindowSample - iWindowRemain );
		if ( bSameWindow )
		{
			memcpy( pWindow + iChannel * m_iOutWindowSample + iWindowRemain, pBuffer + iPos, iCopy * sizeof( float ) );
		}
		else
		{
			memcpy( pPreWindow + iChannel * m_iOutWindowSample + iWindowRemain, pBuffer + iPos, iCopy * sizeof( float ) );
		}
		uBegin	+= iCopy;
		iLength	-= iCopy;
		iPos	+= iCopy;
	}
}

void CSoundProcess::callSoundProcess( float * pWindow, int32_t iOffset, int32_t iLength, float* pPreWindow )
{
	int32_t		iHalfWindow		= m_iOutWindowSample / 2;

	//如果使用了去噪，第一步就要处理。否则在计算其它效果时，会造成二次污染。
//	if ( m_fNoiseCancelling != 0.0f )
	{
		while ( m_uCopyedSample + m_iOutWindowSample <= m_fmtInput->uResamples )
		{
			for ( int32_t c = 0; c < m_fmtOutput.nChannels; ++c )
			{
				int32_t		iWaveTopCopy	= m_iWaveTopCopy;
				copyFromSample( m_uCopyedSample, c, m_pEqFftReal, m_iOutWindowSample, pWindow, pPreWindow );
				memset( m_pEqFftImag, 0, m_iOutWindowSample * sizeof( float ) );
				fft( FFT_FORWARD, m_uOutWindowPower, m_pEqFftReal, m_pEqFftImag );
				//计算出 频率-能量谱
				float	fSum		= 0.0f;
				for ( int32_t i = 1; i <= iHalfWindow; ++i )
				{
					m_pPowerSpectrum[i]	= sqrt( m_pEqFftReal[i] * m_pEqFftReal[i] + m_pEqFftImag[i] * m_pEqFftImag[i] );
					fSum		+= m_pPowerSpectrum[i];
				}
				//把 频谱 加入到噪声样本
				if ( m_iNosieWindows < 100 && fSum != 0.0f )
				{
					AddToNosieSpectrum();
				}
				//如果有噪声样本，并且要去噪，就进行去噪的计算
				if ( m_iNosieWindows && m_fNoiseCancelling != 0.0f )
				{
					float	fSub	= 0.0f;
					for ( int32_t i = 1; i <= iHalfWindow; ++i )
					{
						//计算当前能量谱中与噪声谱中对应频率应该减少的值
						float	fFractional	= min( m_pNosieSpectrum[i], m_pPowerSpectrum[i] ) * m_fNoiseCancelling;
						//减少的数量在当前能量谱中的比值，用1减去它得到要保留的比值。
						float	fScale		= 1.0f - fFractional / m_pPowerSpectrum[i];
						fSub	+= fFractional;		//统计累计减少的能量数量，稍后用于更新 fft 实部第 0 项。
						m_pEqFftReal[i]	*= fScale;
						m_pEqFftReal[m_iOutWindowSample - i] *= fScale;
						m_pEqFftImag[i]	*= fScale;
						m_pEqFftImag[m_iOutWindowSample - i] *= fScale;
					}
					m_pEqFftReal[0]	*= ( 1.0f - fSub / fSum );	// 0 项是直流量，也就是音频数据中正值减去负值剩下的。
					m_pEqFftImag[0]	= 0;
					//去噪完成，更新数据到循环缓存队列。
					fft( FFT_REVERSE, m_uOutWindowPower, m_pEqFftReal, m_pEqFftImag );
					int32_t	iCopy	= min( m_iWaveBufAlloc - iWaveTopCopy, m_iOutWindowSample );
					float*	pCopy	= m_arrChannel[c].pCopyBuf + m_iWaveTopCopy;
					//因为循环缓存队列当前位置到尾部可能容不下一个 window，所以分成两次存入
					for ( int32_t i = 0; i < iCopy; ++i )
					{
						float	fRewnd	= 0.5f * ( 1.0f - cos( ( 2.0f * M_PI * i ) / ( m_iOutWindowSample - 1 ) ) );
						pCopy[i]	= pCopy[i] + fRewnd * m_pEqFftReal[i];
					}
					pCopy	= m_arrChannel[c].pCopyBuf - iCopy;
					for ( int32_t i = iCopy; i < m_iOutWindowSample; ++i )
					{
						float	fRewnd	= 0.5f * ( 1.0f - cos( ( 2.0f * M_PI * i ) / ( m_iOutWindowSample - 1 ) ) );
						pCopy[i]	= pCopy[i] + fRewnd * m_pEqFftReal[i];
					}
					//因为数据是与 cos曲线相乘后再以半个 window 为步长进行叠加，
					//所以存入降噪后的音频后，把循环缓存队列当前位置之后清空半个 window，
					iWaveTopCopy	= ( iWaveTopCopy + m_iOutWindowSample ) % m_iWaveBufAlloc;
					iCopy	= min( m_iWaveBufAlloc - iWaveTopCopy, iHalfWindow );
					pCopy	= m_arrChannel[c].pCopyBuf;
					memset( pCopy + iWaveTopCopy, 0, iCopy * sizeof( float ) );
					memset( pCopy, 0, ( iHalfWindow - iCopy ) * sizeof( float ) );
				}
				else if ( iWaveTopCopy == m_iWaveTopCopy )
				{
					int32_t		iCopy	= min( m_iWaveBufAlloc - iWaveTopCopy, iHalfWindow );
					copyFromSample( m_uCopyedSample, c, m_arrChannel[c].pCopyBuf + iWaveTopCopy, iCopy, pWindow, pPreWindow );
					copyFromSample( m_uCopyedSample + iCopy, c, m_arrChannel[c].pCopyBuf, iHalfWindow - iCopy, pWindow, pPreWindow );
				}
			}
			//接下来，进行声音叠加、回声、混响等等的效果计算。
			soundProcessOverlay( iHalfWindow );
			soundProcessEcho( iHalfWindow );
			soundProcessFifo( iHalfWindow );

			m_uCopyedSample	+= iHalfWindow;
			m_iWaveTopCopy	= ( m_iWaveTopCopy + iHalfWindow ) % m_iWaveBufAlloc;
		}
	}
	//else
	//{
	//	int32_t		iDatLen	= m_fmtInput->uResamples - m_uCopyedSample;
	//	int32_t		iCopy	= min( m_iWaveBufAlloc - m_iWaveTopCopy, iDatLen );
	//	for ( int32_t c = 0; c < m_fmtOutput.nChannels; ++c )
	//	{
	//		copyFromSample( m_uCopyedSample, c, m_arrChannel[c].pCopyBuf + m_iWaveTopCopy, iCopy, pWindow, pPreWindow );
	//		copyFromSample( m_uCopyedSample + iCopy, c, m_arrChannel[c].pCopyBuf, iDatLen - iCopy, pWindow, pPreWindow );
	//	}
	//	//接下来，进行声音叠加、回声、混响等等的效果计算。
	//	soundProcessOverlay( iDatLen );
	//	soundProcessEcho( iDatLen );
	//	soundProcessFifo( iDatLen );

	//	m_uCopyedSample	+= iDatLen;
	//	m_iWaveTopCopy	= ( m_iWaveTopCopy + iDatLen ) % m_iWaveBufAlloc;
	//}

	int32_t		iProc	= int32_t( m_uCopyedSample - m_uEqDoneSample );
	int32_t		iTop	= ( m_iWaveTopCopy - iProc + m_iWaveBufAlloc ) % m_iWaveBufAlloc;
	//均衡器
	if ( m_uEqualCount )
	{
		while ( m_uEqDoneSample + m_iOutWindowSample <= m_uCopyedSample )
		{
			int32_t		iCopy	= min( m_iWaveBufAlloc - iTop, m_iOutWindowSample );
			int32_t		iTop2	= ( iTop + iHalfWindow ) % m_iWaveBufAlloc;
			int32_t		iCopy2	= min( m_iWaveBufAlloc - iTop2, iHalfWindow );
			for ( int32_t c = 0; c < m_fmtOutput.nChannels; ++c )
			{
				copyToSample( m_uEqDoneSample + iHalfWindow, c, m_arrChannel[c].pCurrentCopy + iTop2, iCopy2, pWindow, pPreWindow );
				copyToSample( m_uEqDoneSample + iHalfWindow + iCopy2, c, m_arrChannel[c].pCurrentCopy, iHalfWindow - iCopy2, pWindow, pPreWindow );
				//复制一个窗口的音频数据。因为窗口在循环缓冲区的顶部可能距缓冲区长度不足一个窗口，所以要分成两部分复制。
				memcpy( m_pEqFftReal, m_arrChannel[c].pCurrentCopy + iTop, iCopy * sizeof( float ) );
				memcpy( m_pEqFftReal + iCopy, m_arrChannel[c].pCurrentCopy, ( m_iOutWindowSample - iCopy ) * sizeof( float ) );
				memset( m_pEqFftImag, 0, m_iOutWindowSample * sizeof( float ) );
				fft( FFT_FORWARD, m_uOutWindowPower, m_pEqFftReal, m_pEqFftImag );
				for ( int32_t i = 1; i <= iHalfWindow; ++i )
				{
					m_pEqFftReal[i] *= m_pEqSpline[i];
					m_pEqFftReal[m_iOutWindowSample - i] *= m_pEqSpline[i];
					m_pEqFftImag[i] *= m_pEqSpline[i];
					m_pEqFftImag[m_iOutWindowSample - i] *= m_pEqSpline[i];
				}
				fft( FFT_REVERSE, m_uOutWindowPower, m_pEqFftReal, m_pEqFftImag );

				uint64_t	uBegin		= m_uEqDoneSample;
				int32_t		iDataLen	= m_iOutWindowSample;
				int32_t		iOffset		= 0;
				while ( iDataLen )
				{
					int32_t		iWindowRemain	= int32_t( uBegin % m_iOutWindowSample );
					bool		bSameWindow		= uBegin / m_iOutWindowSample == ( m_fmtInput->uResamples - 1 ) / m_iOutWindowSample;
					int32_t		iOverLen		= min( iDataLen, m_iOutWindowSample - iWindowRemain );
					float*		pOutput			= ( bSameWindow ? pWindow : pPreWindow ) + c * m_iOutWindowSample + iWindowRemain;	
					for ( int32_t i = 0; i < iOverLen; ++i )
					{
						pOutput[i]	+= m_pEqFftReal[i + iOffset] * 0.5f * ( 1.0f - cos( ( 2.0f * M_PI * ( i + iOffset ) ) / ( m_iOutWindowSample - 1 ) ) );
					}
					uBegin		+= iOverLen;
					iDataLen	-= iOverLen;
					iOffset		+= iOverLen;
				}
			}

			iTop			= ( iTop + iHalfWindow ) % m_iWaveBufAlloc;
			m_uEqDoneSample	+= iHalfWindow;
		}
	}
	else
	{
		int32_t		iCopy	= min( m_iWaveBufAlloc - iTop, iProc );
		for ( int32_t c = 0; c < m_fmtOutput.nChannels; ++c )
		{
			copyToSample( m_uEqDoneSample, c, m_arrChannel[c].pCurrentCopy + iTop, iCopy, pWindow, pPreWindow );
			copyToSample( m_uEqDoneSample + iCopy, c, m_arrChannel[c].pCurrentCopy, iProc - iCopy, pWindow, pPreWindow );
		}
		m_uEqDoneSample	= m_uCopyedSample;
	}
}

void CSoundProcess::soundProcessOverlay( const int32_t iLength )
{
	//声音片段叠加（加法）
	if ( m_sOverlayAdd.iSampleCount )
	{
		int32_t	iSample		= iLength;
		int32_t	iTopCopy	= m_iWaveTopCopy;
		int32_t	iTopAdd		= m_sOverlayAdd.iSampleTop;
		while ( iSample )
		{
			int32_t		iProc	=	0;
			if ( iTopAdd < m_sOverlayAdd.iSampleCount )
			{
				iProc	= min( m_iWaveBufAlloc - iTopCopy, iSample );
				iProc	= min( m_sOverlayAdd.iSampleCount - iTopAdd, iProc );
				float*		pAddBuf	= m_sOverlayAdd.pWaveBuf + iTopAdd;
				for ( int32_t c = 0; c < m_fmtOutput.nChannels; ++c )
				{
					float*		pPcmBuf	= m_arrChannel[c].pCopyBuf + iTopCopy;
					if ( m_sOverlayAdd.fVolume >= 0.0f )
					{
						for ( int32_t i = 0; i < iProc; ++i )
						{
							pPcmBuf[i]	+= pAddBuf[i];
						}
					}
					else
					{
						for ( int32_t i = 0; i < iProc; ++i )
						{
							pPcmBuf[i]	+= pAddBuf[i] * m_fRealVolume;
						}
					}
				}
			}
			else
			{
				iProc	= min( m_sOverlayAdd.iTotCount - iTopAdd, iSample );
			}
			iTopCopy	= ( iTopCopy + iProc ) % m_iWaveBufAlloc;
			iTopAdd		= ( iTopAdd + iProc ) % m_sOverlayAdd.iTotCount;
			iSample		-= iProc;
		}
		m_sOverlayAdd.iSampleTop	= iTopAdd;
	}
	//声音片段叠加（乘法）
	if ( m_sOverlayMul.iSampleCount )
	{
		int32_t	iSample		= iLength;
		int32_t	iTopCopy	= m_iWaveTopCopy;
		int32_t	iTopMul		= m_sOverlayMul.iSampleTop;
		while ( iSample )
		{
			int32_t		iProc	=	0;
			if ( iTopMul < m_sOverlayMul.iSampleCount )
			{
				iProc	= min( m_iWaveBufAlloc - iTopCopy, iSample );
				iProc	= min( m_sOverlayMul.iSampleCount - iTopMul, iProc );
				float*		pMulBuf	= m_sOverlayMul.pWaveBuf + iTopMul;
				for ( int32_t c = 0; c < m_fmtOutput.nChannels; ++c )
				{
					float*		pPcmBuf	= m_arrChannel[c].pCopyBuf + iTopCopy;
					for ( int32_t i = 0; i < iProc; ++i )
					{
						pPcmBuf[i]	*= pMulBuf[i];
					}
				}
			}
			else
			{
				iProc	= min( m_sOverlayMul.iTotCount - iTopMul, iSample );
			}
			iTopCopy	= ( iTopCopy + iProc ) % m_iWaveBufAlloc;
			iTopMul		= ( iTopMul + iProc ) % m_sOverlayMul.iTotCount;
			iSample		-= iProc;
		}
		m_sOverlayMul.iSampleTop	= iTopMul;
	}
}

void CSoundProcess::soundProcessEcho( const int32_t iLength )
{
	for ( int32_t c = 0; c < m_fmtOutput.nChannels; ++c )
	{
		//回声
		float*	pCopy	= m_arrChannel[c].pCopyBuf;
		if ( m_bUseEcho )
		{
			int32_t	iTopCopy	= m_iWaveTopCopy;
			int32_t	iEcho0	= ( iTopCopy + m_iWaveBufAlloc - m_arrEcho[0].iForward ) % m_iWaveBufAlloc;
			int32_t	iEcho1	= ( iTopCopy + m_iWaveBufAlloc - m_arrEcho[1].iForward ) % m_iWaveBufAlloc;
			int32_t	iEcho2	= ( iTopCopy + m_iWaveBufAlloc - m_arrEcho[2].iForward ) % m_iWaveBufAlloc;
			int32_t	iEcho3	= ( iTopCopy + m_iWaveBufAlloc - m_arrEcho[3].iForward ) % m_iWaveBufAlloc;
			float*	pEcho	= m_arrChannel[c].pEchoBuf;
			for ( int32_t i = 0; i < iLength; ++i )
			{
				pEcho[iTopCopy]	= pCopy[iTopCopy]
					+ pCopy[( iEcho0++ ) % m_iWaveBufAlloc] * m_arrEcho[0].fAttenuation
					+ pCopy[( iEcho1++ ) % m_iWaveBufAlloc] * m_arrEcho[1].fAttenuation
					+ pCopy[( iEcho2++ ) % m_iWaveBufAlloc] * m_arrEcho[2].fAttenuation
					+ pCopy[( iEcho3++ ) % m_iWaveBufAlloc] * m_arrEcho[3].fAttenuation;
				iTopCopy	= ( iTopCopy + 1 ) % m_iWaveBufAlloc;
			}
			pCopy	= pEcho;
		}
		//混响
		for ( int32_t r = 0; r < m_uReverbCount; ++r )
		{
			int32_t	iTopCopy	= m_iWaveTopCopy;
			int32_t	iReverb		= ( iTopCopy + m_iWaveBufAlloc - m_arrReverb[r].iForward ) % m_iWaveBufAlloc;
			float*	pReverb		= m_arrChannel[c].pReverbBuf[r];
			float	fAttenu		= m_arrReverb[r].fAttenuation;
			for ( int32_t i = 0; i < iLength; ++i ) {
				pReverb[iTopCopy]	= -fAttenu * pCopy[iTopCopy] + pCopy[iReverb] + pReverb[iReverb] * fAttenu;
				iReverb		= ( iReverb + 1 ) % m_iWaveBufAlloc;
				iTopCopy	= ( iTopCopy + 1 ) % m_iWaveBufAlloc;
			}
			pCopy	= pReverb;
		}
		m_arrChannel[c].pCurrentCopy	= pCopy;
	}
}

void CSoundProcess::soundProcessFifo( const int32_t iLength )
{
	for ( int32_t c = 0; c < m_fmtOutput.nChannels; ++c )
	{
		float*	pCopy	= m_arrChannel[c].pCurrentCopy;
		//淡入淡出
		if ( m_iFifoSample )
		{
			float	fScale		= ( m_fFifoVolEnd - m_fFifoVolBeg ) / m_iFifoSample;
			int32_t	iTopCopy	= m_iWaveTopCopy;
			int32_t	iDatLen		= min( iLength, m_iFifoSample - m_iFifoDone );
			int32_t	iDatInd		= m_iFifoDone;
			while ( iDatLen )
			{
				int32_t	iProc	= min( m_iWaveBufAlloc - iTopCopy, iDatLen );
				pCopy	= m_arrChannel[c].pCurrentCopy + iTopCopy;
				for ( int32_t i = 0; i < iProc; ++i )
				{
					pCopy[i]	*= fScale * iDatInd + m_fFifoVolBeg;
					++iDatInd;
				}
				iDatLen		-= iProc;
				m_iFifoDone	+= iProc;
			}
			if ( m_iFifoDone == m_iFifoSample ) m_iFifoSample = 0;
		}
	}
}

//资料：
//http://blog.sina.com.cn/s/blog_640029b301010xkv.html
//Fs:采样率，Fn:采样点，Fn=(n-1)*Fs/N。
//假设FFT之后某点n用复数a+bi表示，那么这个复数的模就是An=根号a*a + b*b，相位就是Pn=atan2( b, a )。
//根据以上的结果，就可以计算出n点（n≠0，且n <= N / 2）对应的信号的表达式为：
//An / ( N / 2 )*cos( 2 * pi*Fn*t + Pn )，即2*An / N*cos( 2 * pi*Fn*t + Pn )。
//对于n=0点的信号，是直流分量，幅度即为A0 / N。
//假设采样频率为Fs，采样点数为N，做FFT之后，某
//一点n（n从0开始）表示的频率为：Fn=n * Fs / N；
//该点的模值除以N / 2就是对应该频率下的信号的幅度（对于直流信号是除以
//N）；该点的相位即是对应该频率下的信号的相位。
//原始的 DFT 代码
//for ( k=0; k<N; k++ )
//{
//	for ( n=0; n<N; n++ )
//	{
//		real[k] = real[k] + x[n] * cos( 2 * PI*k*n / N );
//		imag[k] = imag[k] – x[n] * sin( 2 * PI*k*n / N );
//	}
//}
void CSoundProcess::fft( int dir, long m, float * x, float * y )
{
	long n, i, i1, j, k, i2, l, l1, l2;
	double c1, c2, tx, ty, t1, t2, u1, u2, z;

	// Calculate the number of points
	n = 1 << m;
	//for ( i=0; i<m; i++ )
	//	n *= 2;

	// Do the bit reversal
	i2 = n >> 1;
	j = 0;
	for ( i=0; i<n - 1; i++ ) {
		if ( i < j ) {
			tx = x[i];
			ty = y[i];
			x[i] = x[j];
			y[i] = y[j];
			x[j] = (float)tx;
			y[j] = (float)ty;
		}
		k = i2;
		while ( k <= j ) {
			j -= k;
			k >>= 1;
		}
		j += k;
	}

	// Compute the FFT
	c1 = -1.0;
	c2 = 0.0;
	l2 = 1;
	for ( l=0; l<m; l++ ) {
		l1 = l2;
		l2 <<= 1;
		u1 = 1.0;
		u2 = 0.0;
		for ( j=0; j<l1; j++ ) {
			for ( i=j; i<n; i+=l2 ) {
				i1 = i + l1;
				t1 = u1 * x[i1] - u2 * y[i1];
				t2 = u1 * y[i1] + u2 * x[i1];
				x[i1] = (float)( x[i] - t1 );
				y[i1] = (float)( y[i] - t2 );
				x[i] += (float)t1;
				y[i] += (float)t2;
			}
			z =  u1 * c1 - u2 * c2;
			u2 = u1 * c2 + u2 * c1;
			u1 = z;
		}
		c2 = sqrt( ( 1.0 - c1 ) / 2.0 );
		if ( dir == FFT_FORWARD )
			c2 = -c2;
		c1 = sqrt( ( 1.0 + c1 ) / 2.0 );
	}

	// Scaling for forward transform
	if ( dir == FFT_FORWARD ) {
		for ( i=0; i<n; i++ ) {
			x[i] /= n;
			y[i] /= n;
		}
	}
}
