#include "SoundResample.h"
#include <algorithm> 
#include <stdlib.h>
CSoundResample::CSoundResample()
{
	m_bResampleing	= true;
	m_fOutWindowNearest	= 0.1f;
	EndResample();
}


CSoundResample::~CSoundResample()
{
	EndResample();
}

bool CSoundResample::BeginResample( ESampleBits eSampleFormat, uint32_t nSamplesPerSec, uint32_t nChannels, uint32_t uChannelMask )
{
	if ( m_bResampleing ) return false;
	if ( eSampleFormat < eSampleBit8i || eSampleFormat > eSampleBit32f ||
		nSamplesPerSec <= 0 || nSamplesPerSec > 96000 ||
		nChannels <= 0 || nChannels > MAX_PCM_CHANNEL_COUNT )
	{
		return false;
	}
	m_fmtOutput.eSampleBits		= eSampleFormat;
	m_fmtOutput.nSamplesPerSec	= nSamplesPerSec;
	m_fmtOutput.nChannels		= nChannels;
	m_fmtOutput.nBlockAlign		= bytesPerSamples( eSampleFormat ) * nChannels;
	m_fmtOutput.uChannelMask	= uChannelMask == 0 ? getDefaultChannelLayout( nChannels ) : uChannelMask;

	int32_t	iDifference	= 0x7FFFFFFF;
	m_uOutWindowPower	= 0;
	m_iOutWindowSample	= m_fOutWindowNearest * nSamplesPerSec;
	for ( int32_t i = 0; i < 24; ++i )
	{
		if ( abs( m_iOutWindowSample - ( 1 << i ) ) < iDifference )
		{
			iDifference	= abs( m_iOutWindowSample - ( 1 << i ) );
			m_uOutWindowPower	= i;
		}
	}
	m_iOutWindowSample	= 1 << m_uOutWindowPower;
	m_uOutWindowBytes	= m_iOutWindowSample * m_fmtOutput.nChannels * sizeof( float );

	m_bLimitVolumeOverflow	= false;
	m_fOutputVolume		= 1.0f;
	m_fRealVolume		= 0.0f;
	m_fCurrentVolume	= 1.0f;
	m_fTargetVolume		= 1.0f;
	m_fIncrementVolume	= 0.0f;
	m_iVolumeStatistic	= nSamplesPerSec / 10;
	m_iVolumeSampleInd	= 0;
	m_iLimitSample		= nSamplesPerSec / 2;
	m_iLimitSampleInd	= 0;

	ResetInput();
	m_bResampleing	= true;
	return true;
}

void CSoundResample::EndResample()
{
	if ( m_bResampleing )
	{
		m_bResampleing	= false;
		memset( &m_fmtOutput, 0, sizeof( SWaveFormat ) );
		memset( m_fmtInput, 0, sizeof( m_fmtInput ) );
		m_iOutWindowSample	= 0;
		m_uOutWindowPower	= 0;
		m_uOutWindowBytes	= 0;
		m_uFirstSample		= 0;
		m_uDoneOffset		= 0;
		for ( auto i = m_vOutWaveCache.begin(); i != m_vOutWaveCache.end(); ++i )
		{
			if ( *i ) free( *i );
		}
		m_vOutWaveCache.clear();
		for ( auto i = m_vOutBufPool.begin(); i != m_vOutBufPool.end(); ++i )
		{
			if ( *i ) free( *i );
		}
		m_vOutBufPool.clear();
	}

}

bool CSoundResample::SetInput( ESampleBits eSampleFormat, uint32_t nSamplesPerSec, uint32_t nChannels, int32_t iInputIndex, uint32_t uChannelMask )
{
	if ( !m_bResampleing ) return false;
	if ( eSampleFormat < eSampleBit8i || eSampleFormat > eSampleBit32f ||
		nSamplesPerSec <= 0 || nSamplesPerSec > 96000 ||
		nChannels <= 0 || nChannels > MAX_PCM_CHANNEL_COUNT ||
		iInputIndex < 0 || iInputIndex >= MAX_INPUT_SOUND_COUNT )
	{
		return false;
	}
	uint64_t	uDoneSample	= getDoneSampleCount();
	memset( m_fmtInput + iInputIndex, 0, sizeof( SWaveInput ) );
	m_fmtInput[iInputIndex].eSampleBits		= eSampleFormat;
	m_fmtInput[iInputIndex].nSamplesPerSec	= nSamplesPerSec;
	m_fmtInput[iInputIndex].nChannels		= nChannels;
	m_fmtInput[iInputIndex].nBlockAlign		= bytesPerSamples( eSampleFormat ) * nChannels;
	m_fmtInput[iInputIndex].uChannelMask	= uChannelMask == 0 ? getDefaultChannelLayout( nChannels ) : uChannelMask;
	m_fmtInput[iInputIndex].bEnabled		= true;
	m_fmtInput[iInputIndex].fVolumeOpt		= 1.0f;
	m_fmtInput[iInputIndex].uInpSamples		= nSamplesPerSec * uDoneSample / m_fmtOutput.nSamplesPerSec;
	m_fmtInput[iInputIndex].uResamples		= uDoneSample;
	setChannelMapping( iInputIndex );
	resetMixChannelVolume( iInputIndex );
	return true;
}

bool CSoundResample::ResetInput( int32_t iInputIndex )
{
	if ( iInputIndex < 0 || iInputIndex >= MAX_INPUT_SOUND_COUNT )
	{
		return false;
	}
	memset( m_fmtInput + iInputIndex, 0, sizeof( SWaveInput ) );
	if ( iInputIndex == 0 )
	{
		uint64_t	uDoneSample	= getDoneSampleCount();
		memset( m_fmtInput, 0, sizeof( SWaveInput ) );
		memcpy( m_fmtInput, &m_fmtOutput, sizeof( SWaveFormat ) );
		m_fmtInput[0].bEnabled	= true;
		m_fmtInput[0].fVolumeOpt	= 1.0f;
		m_fmtInput[0].uInpSamples	= uDoneSample;
		m_fmtInput[0].uResamples	= uDoneSample;
		setChannelMapping( 0 );
		resetMixChannelVolume( 0 );
	}
	return true;
}

bool CSoundResample::SetMixVolume( float fVolume, int32_t iInputIndex )
{
	if ( !m_bResampleing ) return false;
	if ( iInputIndex < 0 || iInputIndex >= MAX_INPUT_SOUND_COUNT ) return false;
	SWaveInput&	sInp		= m_fmtInput[iInputIndex];
	if ( m_fmtInput[iInputIndex].bEnabled == false ) return false;
	m_fmtInput[iInputIndex].fVolumeOpt	= fVolume;
	resetMixChannelVolume( iInputIndex );
	return true;
}

bool CSoundResample::SetOutVolume( float fVolume )
{
	if( !m_bResampleing || fVolume < 0.0f ) return false;
	m_fOutputVolume	= fVolume;
	return true;
}

bool CSoundResample::SmoothVolumeOverflow( bool bLimit )
{
	if ( !m_bResampleing ) return false;
	m_bLimitVolumeOverflow	= bLimit;
	return true;
}

bool CSoundResample::PutInput( const void * pWaveData, int32_t iSampleCount, int32_t iInputIndex )
{
	if ( !m_bResampleing || iInputIndex < 0 || iInputIndex >= MAX_INPUT_SOUND_COUNT || !m_fmtInput[iInputIndex].bEnabled
		|| iSampleCount <= 0 || pWaveData == nullptr ) return false;
	if ( m_fmtInput[iInputIndex].nSamplesPerSec == m_fmtOutput.nSamplesPerSec )
		resampleSame( pWaveData, iSampleCount, iInputIndex );
	else if ( m_fmtInput[iInputIndex].nSamplesPerSec > m_fmtOutput.nSamplesPerSec )
		resampleNear( pWaveData, iSampleCount, iInputIndex );
	else
		resampleLine( pWaveData, iSampleCount, iInputIndex );
	return true;
}

int32_t CSoundResample::GetOutput( void * pWaveData, uint32_t nSamplesMax )
{
	if ( !m_bResampleing )	return -1;
	uint64_t	uDoneSample	= getDoneSampleCount();
	if ( nSamplesMax == 0 )
		if ( uDoneSample < m_uFirstSample || uDoneSample - m_uFirstSample < m_uDoneOffset )
			return 0;
		else
			return int32_t( uDoneSample - m_uFirstSample - m_uDoneOffset );
	else if ( nullptr == pWaveData )
		return -1;
	int32_t	iGeted	= 0;
	nSamplesMax	= min( nSamplesMax, uint32_t( uDoneSample - m_uFirstSample - m_uDoneOffset ) );
	while ( nSamplesMax && !m_vOutWaveCache.empty() )
	{
		float*	fCache	= m_vOutWaveCache.front() + m_uDoneOffset;
		int32_t	iGet	= min( nSamplesMax, m_iOutWindowSample - m_uDoneOffset );

		if ( m_bLimitVolumeOverflow )
		{
			for ( int32_t i = 0; i < iGet; ++i )
			{
				m_fCurrentVolume	+= m_fIncrementVolume;
				if ( ++m_iLimitSampleInd == m_iLimitSample )
				{
					m_fIncrementVolume	= 0.0f;
				}
				for ( int32_t c = 0; c < m_fmtOutput.nChannels; ++c )
				{
					m_fRealVolume		= max( fCache[i + c * m_iOutWindowSample], m_fRealVolume );
					fCache[i + c * m_iOutWindowSample]	*= m_fCurrentVolume * m_fOutputVolume;
				}
				if ( ++m_iVolumeSampleInd == m_iVolumeStatistic )
				{
					if ( m_fRealVolume > 1.0f )
					{
						m_fTargetVolume		= 1.0f / m_fRealVolume;
					}
					else
					{
						m_fTargetVolume	= 1.0;
					}
					m_iVolumeSampleInd	= 0;
					m_fRealVolume		= 0.0f;
					m_fIncrementVolume	= ( m_fTargetVolume - m_fCurrentVolume ) / m_iLimitSample;
					m_iLimitSampleInd	= 0;
				}
			}
		}
		else
		{
			for ( int32_t c = 0; c < m_fmtOutput.nChannels; ++c )
			{
				float*	fChannel	= fCache + c * m_iOutWindowSample;
				for ( int32_t i = 0; i < iGet; ++i )
				{
					*fChannel++	*= m_fOutputVolume;
				}
			}
		}

		switch ( m_fmtOutput.eSampleBits )
		{
		case eSampleBit8i:
		{
			uint8_t*	pOutput	= (uint8_t*)pWaveData;
			for ( int32_t i = 0; i < iGet; ++i )
			{
				for ( int32_t c = 0; c < m_fmtOutput.nChannels; ++c )
				{
					if ( fCache[c*m_iOutWindowSample] > 1.0f )
						pOutput[c]	= 127 + 128;
					else if( fCache[c*m_iOutWindowSample] < -1.0f )
						pOutput[c]	= -127 + 128;
					else
						pOutput[c]	= uint8_t( fCache[c*m_iOutWindowSample] * 127.0f + 128.0f );
				}
				pOutput	+= m_fmtOutput.nChannels;
				++fCache;
			}
			pWaveData		= pOutput;
		}
			break;
		case eSampleBit16i:
		{
			int16_t*	pOutput	= (int16_t*)pWaveData;
			for ( int32_t i = 0; i < iGet; ++i )
			{
				for ( int32_t c = 0; c < m_fmtOutput.nChannels; ++c )
				{
					if ( fCache[c*m_iOutWindowSample] > 1.0f )
						pOutput[c]	= 32767;
					else if ( fCache[c*m_iOutWindowSample] < -1.0f )
						pOutput[c]	= -32767;
					else
						pOutput[c]	= int16_t( fCache[c*m_iOutWindowSample] * 32767.0 );
				}
				pOutput	+= m_fmtOutput.nChannels;
				++fCache;
			}
			pWaveData		= pOutput;
		}
			break;
		case eSampleBit24i:
		{
			uint8_t*	pOutput	= (uint8_t*)pWaveData;
			for ( int32_t i = 0; i < iGet; ++i )
			{
				for ( int32_t c = 0; c < m_fmtOutput.nChannels; ++c )
				{
					int32_t		iSamp;
					if ( fCache[c*m_iOutWindowSample] > 1.0f )
						iSamp	= 8388607;
					else if ( fCache[c*m_iOutWindowSample] < -1.0f )
						iSamp	= -8388607;
					else
						iSamp	= int32_t( fCache[c*m_iOutWindowSample] * 8388607.0f );
					pOutput[c]		= iSamp & 0xFF;
					pOutput[c+1]	= ( iSamp >> 8 ) & 0xFF;
					pOutput[c+2]	= ( iSamp >> 16 ) & 0xFF;
				}
				pOutput	+= m_fmtOutput.nChannels * 3;
				++fCache;
			}
			pWaveData		= pOutput;
		}
			break;
		case eSampleBit32i:
		{
			int32_t*	pOutput	= (int32_t*)pWaveData;
			for ( int32_t i = 0; i < iGet; ++i )
			{
				for ( int32_t c = 0; c < m_fmtOutput.nChannels; ++c )
				{
					if ( fCache[c*m_iOutWindowSample] > 1.0f )
						pOutput[c]	= 2147483647;
					else if ( fCache[c*m_iOutWindowSample] < -1.0f )
						pOutput[c]	= -2147483647;
					else
						pOutput[c]	= int32_t( fCache[c*m_iOutWindowSample] * 2147483647.0 );
				}
				pOutput	+= m_fmtOutput.nChannels;
				++fCache;
			}
			pWaveData		= pOutput;
		}
			break;
		case eSampleBit24In32i:
		{
			int32_t*	pOutput	= (int32_t*)pWaveData;
			for ( int32_t i = 0; i < iGet; ++i )
			{
				for ( int32_t c = 0; c < m_fmtOutput.nChannels; ++c )
				{
					if ( fCache[c*m_iOutWindowSample] > 1.0f )
						pOutput[c]	= 8388607;
					else if ( fCache[c*m_iOutWindowSample] < -1.0f )
						pOutput[c]	= -8388607;
					else
						pOutput[c]	= int32_t( fCache[c*m_iOutWindowSample] * 8388607.0f );
				}
				pOutput	+= m_fmtOutput.nChannels;
				++fCache;
			}
			pWaveData		= pOutput;
		}
			break;
		case eSampleBit32f:
		{
			float*	pOutput	= (float*)pWaveData;
			for ( int32_t i = 0; i < iGet; ++i )
			{
				for ( int32_t c = 0; c < m_fmtOutput.nChannels; ++c )
				{
					pOutput[c]	= fCache[c*m_iOutWindowSample];
				}
				pOutput	+= m_fmtOutput.nChannels;
				++fCache;
			}
			pWaveData		= pOutput;

		}
			break;
		}
		nSamplesMax		-= iGet;
		m_uDoneOffset	+= iGet;
		iGeted			+= iGet;
		if ( m_uDoneOffset == m_iOutWindowSample )
		{
			m_uDoneOffset	= 0;
			m_uFirstSample	+= m_iOutWindowSample;
			if ( m_vOutBufPool.size() < 10 )
				m_vOutBufPool.push_back( m_vOutWaveCache.front() );
			else
				free( m_vOutWaveCache.front() );
			m_vOutWaveCache.erase( m_vOutWaveCache.begin() );
		}
	}
	return iGeted;
}

int32_t CSoundResample::Flush()
{
	if ( !m_bResampleing )	return -1;
	uint64_t	uDoneSample	= getDoneSampleCount( false );
	if ( uDoneSample < m_uFirstSample || uDoneSample - m_uFirstSample < m_uDoneOffset )
		return 0;
	for ( int32_t i = 0; i < MAX_INPUT_SOUND_COUNT; ++i )
	{
		if ( m_fmtInput[i].bEnabled )
		{
			m_fmtInput[i].uResamples	= uDoneSample;
		}
	}
	return int32_t( uDoneSample - m_uFirstSample - m_uDoneOffset );
}

CSoundResample::ESampleBits CSoundResample::SampleBitsFromWaveTag( uint16_t wFormatTag, uint16_t wBitsPerSample )
{
	#define	WAVE_FORMAT_PCM			1
	#define	WAVE_FORMAT_IEEE_FLOAT	3
	ESampleBits	eFormat	= eSampleBit8i;
	switch ( wBitsPerSample )
	{
	case 8:		eFormat	= eSampleBit8i; break;
	case 16:	eFormat	= eSampleBit16i; break;
	case 24:	eFormat	= eSampleBit24i; break;
	case 32:
		if ( wFormatTag == WAVE_FORMAT_PCM )
			eFormat	= eSampleBit32i;
		else if ( wFormatTag == WAVE_FORMAT_IEEE_FLOAT )
			eFormat	= eSampleBit32f;
		break;
	}
	return eFormat;
}

float * CSoundResample::getCacheBuf( const SWaveInput & sInp, int32_t& iOffset, float** pPreWindow, float* pChannel[] )
{
	int32_t	iQueue	= ( sInp.uResamples - m_uFirstSample ) / m_iOutWindowSample;
	float*	pWindow	= nullptr;
	iOffset	= ( sInp.uResamples - m_uFirstSample ) % m_iOutWindowSample;

	if ( iQueue == m_vOutWaveCache.size() )
	{
		if ( m_vOutBufPool.empty() )
		{
			pWindow	= (float*)malloc( m_uOutWindowBytes );
			if ( nullptr == pWindow ) return nullptr;
		}
		else
		{
			pWindow	= m_vOutBufPool.back();
			m_vOutBufPool.pop_back();
		}
		memset( pWindow, 0, m_uOutWindowBytes );
		if ( pPreWindow )
		{
			*pPreWindow	= m_vOutWaveCache.empty() ? nullptr : m_vOutWaveCache.back();
		}
		m_vOutWaveCache.push_back( pWindow );


	}
	else
	{
		if ( pPreWindow )
		{
			*pPreWindow	= iQueue < 1 ? nullptr : m_vOutWaveCache.at( iQueue - 1 );
		}
		pWindow	= m_vOutWaveCache.at( iQueue );
	}
	if ( pChannel )
	{
		for ( int32_t i = 0; i < sInp.uMapCount; ++i )
		{
			pChannel[i]	= pWindow + m_iOutWindowSample * sInp.aChannelMap[i].iOutChannel;
		}
	}
	return pWindow;
}

void CSoundResample::resetMixChannelVolume( int32_t iInputIndex )
{
	SWaveInput&	sInp		= m_fmtInput[iInputIndex];
	for ( int32_t i = 0; i < sInp.uMapCount; ++i )
	{
		sInp.aChannelMap[i].fVolumeMul =
			sInp.fVolumeOpt * sInp.aChannelMap[i].fVolumeOpt;
	}
}

void CSoundResample::setChannelMapping( int32_t iInputIndex )
{
	struct SMapSpeaker
	{
		uint32_t	uSpeakerMask;
		float		x, y, z;
	};
	//                               LOW_FREQUENCY
	//       FRONT_LEFT_OF_CENTER    FRONT_CENTER     FRONT_RIGHT_OF_CENTER
	// FRONT_LEFT                                                    FRONT_RIGHT
	//          TOP_FRONT_LEFT     TOP_FRONT_CENTER     TOP_FRONT_RIGHT
	// SIDE_LEFT                      TOP_CENTER                     SIDE_RIGHT
	//          TOP_BACK_LEFT      TOP_BACK_CENTER      TOP_BACK_RIGHT
	// BACK_LEFT                      BACK_CENTER                    BACK_RIGHT
	SMapSpeaker	spkList[]	={
		{ SPEAKER_FRONT_LEFT, -1.0f, 0.0f, 1.0f },
		{ SPEAKER_FRONT_RIGHT, 1.0f, 0.0f, 1.0f },
		{ SPEAKER_FRONT_CENTER, 0.0f, 0.0f, 1.5f },

		{ SPEAKER_LOW_FREQUENCY, 0.0f, 0.0f, 2.0f },

		{ SPEAKER_BACK_LEFT, -1.0f, 0.0f, -1.0f },
		{ SPEAKER_BACK_RIGHT, 1.0f, 0.0f, -1.0f },

		{ SPEAKER_FRONT_LEFT_OF_CENTER, -1.0f, 0.0f, 1.2f },
		{ SPEAKER_FRONT_RIGHT_OF_CENTER, 1.0f, 0.0f, 1.2f },

		{ SPEAKER_BACK_CENTER, 0.0f, 0.0f, -1.5f },

		{ SPEAKER_SIDE_LEFT, -1.0f, 0.0f, 0.0f },
		{ SPEAKER_SIDE_RIGHT, 1.0f, 0.0f, 0.0f },

		{ SPEAKER_TOP_CENTER, 0.0f, 1.0f, 0.0f },
		{ SPEAKER_TOP_FRONT_LEFT, -1.0f, 1.0f, 1.2f },
		{ SPEAKER_TOP_FRONT_CENTER, 0.0f, 1.0f, 1.4f },
		{ SPEAKER_TOP_FRONT_RIGHT, 1.0f, 1.0f, 1.2f },

		{ SPEAKER_TOP_BACK_LEFT, -1.0f, 1.0f, -1.2f },
		{ SPEAKER_TOP_BACK_CENTER, 0.0f, 1.0f, -1.4f },
		{ SPEAKER_TOP_BACK_RIGHT, 1.0f, 1.0f, -1.2f },
	};
	SWaveInput&	sInp		= m_fmtInput[iInputIndex];
	int32_t		aInpMapSpk[MAX_PCM_CHANNEL_COUNT]	={ 0 };
	int32_t		aOutMapSpk[MAX_PCM_CHANNEL_COUNT]	={ 0 };
	int32_t		iInpMapDone		= 0;
	int32_t		iOutMapDone		= 0;
	for ( int32_t i = 0; i < MAX_PCM_CHANNEL_COUNT; ++i )
	{
		if ( iInpMapDone < sInp.nChannels && ( sInp.uChannelMask == 0 || sInp.uChannelMask == SPEAKER_ALL ||
			( sInp.uChannelMask & spkList[i].uSpeakerMask ) == spkList[i].uSpeakerMask ) )
		{
			aInpMapSpk[iInpMapDone]	= i;
			iInpMapDone++;
		}
		if ( iOutMapDone < m_fmtOutput.nChannels && ( m_fmtOutput.uChannelMask == 0 || m_fmtOutput.uChannelMask == SPEAKER_ALL ||
			( m_fmtOutput.uChannelMask & spkList[i].uSpeakerMask ) == spkList[i].uSpeakerMask ) )
		{
			aOutMapSpk[iOutMapDone]	= i;
			iOutMapDone++;
		}
	}

	if ( iOutMapDone > iInpMapDone )
	{
		sInp.uMapCount	= iOutMapDone;
		for ( int32_t i = 0; i < iOutMapDone; ++i )
		{
			float	fMinDistance	= 100.0f;
			int32_t	iMapTo			= -1;
			for ( int32_t j = 0; j < iInpMapDone; ++j )
			{
				float	fx	= spkList[aOutMapSpk[i]].x - spkList[aInpMapSpk[j]].x;
				float	fy	= spkList[aOutMapSpk[i]].y - spkList[aInpMapSpk[j]].y;
				float	fz	= spkList[aOutMapSpk[i]].z - spkList[aInpMapSpk[j]].z;
				float	fDistance = fx * fx + fy * fy + fz * fz;
				if ( fDistance < fMinDistance )
				{
					fMinDistance = fDistance;
					iMapTo		= j;
				}
			}
			if ( iMapTo >= 0 )
			{
				sInp.aChannelMap[i].iOutChannel	= i;
				sInp.aChannelMap[i].iInpChannel	= iMapTo;
				sInp.aChannelMap[i].fVolumeOpt	= fMinDistance < 1.0f ? 1.0f : 1.0f / fMinDistance;
			}
		}
	}
	else
	{
		sInp.uMapCount	= iInpMapDone;
		float	aMapToVolume[MAX_PCM_CHANNEL_COUNT]	={ 0 };
		for ( int32_t i = 0; i < iInpMapDone; ++i )
		{
			float	fMinDistance	= 100.0f;
			int32_t	iMapTo			= -1;
			for ( int32_t j = 0; j < iOutMapDone; ++j )
			{
				float	fx	= spkList[aOutMapSpk[j]].x - spkList[aInpMapSpk[i]].x;
				float	fy	= spkList[aOutMapSpk[j]].y - spkList[aInpMapSpk[i]].y;
				float	fz	= spkList[aOutMapSpk[j]].z - spkList[aInpMapSpk[i]].z;
				float	fDistance = fx * fx + fy * fy + fz * fz;
				if ( fDistance < fMinDistance )
				{
					fMinDistance = fDistance;
					iMapTo		= j;
				}
			}
			if ( iMapTo >= 0 )
			{
				sInp.aChannelMap[i].iOutChannel	= iMapTo;
				sInp.aChannelMap[i].iInpChannel	= i;
				sInp.aChannelMap[i].fVolumeOpt	= fMinDistance < 1.0f ? 1.0f : 1.0f / fMinDistance;
				aMapToVolume[iMapTo]	+= sInp.aChannelMap[i].fVolumeOpt;
			}
		}
		for ( int32_t i = 0; i < iInpMapDone; ++i )
		{
			if ( aMapToVolume[sInp.aChannelMap[i].iOutChannel] > 1.0f )
				sInp.aChannelMap[i].fVolumeOpt	/= aMapToVolume[sInp.aChannelMap[i].iOutChannel];
		}
	}
}

uint32_t CSoundResample::getDefaultChannelLayout( int32_t iChannels )
{
	switch ( iChannels )
	{
	case 1:	// KSAUDIO_SPEAKER_MONO
		return SPEAKER_FRONT_CENTER;
	case 2:	// KSAUDIO_SPEAKER_STEREO
		return SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT;
	case 3:	// 2.1
		return SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT | SPEAKER_LOW_FREQUENCY;
	case 4:	// KSAUDIO_SPEAKER_QUAD
		return SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT | SPEAKER_BACK_LEFT | SPEAKER_BACK_RIGHT;
	case 5:	// 4.1
		return SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT |
			SPEAKER_BACK_LEFT | SPEAKER_BACK_RIGHT | SPEAKER_LOW_FREQUENCY;
	case 6:	// KSAUDIO_SPEAKER_5POINT1
		return SPEAKER_FRONT_LEFT | SPEAKER_FRONT_CENTER | SPEAKER_FRONT_RIGHT |
			SPEAKER_BACK_LEFT | SPEAKER_BACK_RIGHT | SPEAKER_LOW_FREQUENCY;
	case 7: // 6.1
		return SPEAKER_FRONT_LEFT | SPEAKER_FRONT_CENTER | SPEAKER_FRONT_RIGHT |
			SPEAKER_BACK_LEFT | SPEAKER_BACK_RIGHT | SPEAKER_BACK_CENTER | SPEAKER_LOW_FREQUENCY;
	case 8: // KSAUDIO_SPEAKER_7POINT1
		return SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT |
			SPEAKER_FRONT_CENTER | SPEAKER_LOW_FREQUENCY |
			SPEAKER_BACK_LEFT | SPEAKER_BACK_RIGHT |
			SPEAKER_FRONT_LEFT_OF_CENTER | SPEAKER_FRONT_RIGHT_OF_CENTER;
	}
	return SPEAKER_ALL;
}

uint64_t CSoundResample::getDoneSampleCount( bool bMin )
{
	uint64_t	uDoneSample	= 0;
	if ( bMin )
	{
		uDoneSample	= m_vOutWaveCache.size() * m_iOutWindowSample + m_uFirstSample;
		for ( int32_t i = 0; i < MAX_INPUT_SOUND_COUNT; ++i )
		{
			if ( m_fmtInput[i].bEnabled )
			{
				if ( m_fmtInput[i].uResamples < uDoneSample )
					uDoneSample	= m_fmtInput[i].uResamples;
			}
		}
	}
	else
	{
		for ( int32_t i = 0; i < MAX_INPUT_SOUND_COUNT; ++i )
		{
			if ( m_fmtInput[i].bEnabled )
			{
				if ( m_fmtInput[i].uResamples > uDoneSample )
					uDoneSample	= m_fmtInput[i].uResamples;
			}
		}
	}

	return uDoneSample;
}

void CSoundResample::callSoundProcess( float* pWindow, int32_t iOffset, int32_t iLength, float* pPreWindow )
{
	//if ( m_bLimitVolumeOverflow )
	//{
	//	for ( int32_t i = iOffset; i < iLength + iOffset; ++i )
	//	{
	//		m_fCurrentVolume	+= m_fIncrementVolume;
	//		if ( ++m_iLimitSampleInd == m_iLimitSample )
	//		{
	//			m_fIncrementVolume	= 0.0f;
	//		}
	//		for ( int32_t c = 0; c < m_fmtOutput.nChannels; ++c )
	//		{
	//			m_fRealVolume		= fmax( pWindow[i + c * m_iOutWindowSample], m_fRealVolume );
	//			pWindow[i + c * m_iOutWindowSample]	*= m_fCurrentVolume * m_fOutputVolume;
	//		}
	//		if ( ++m_iVolumeSampleInd == m_iVolumeStatistic )
	//		{
	//			if ( m_fRealVolume > 1.0f )
	//			{
	//				m_fTargetVolume		= 1.0f / m_fRealVolume;
	//			}
	//			else
	//			{
	//				m_fTargetVolume	= 1.0;
	//			}
	//			m_iVolumeSampleInd	= 0;
	//			m_fRealVolume		= 0.0f;
	//			m_fIncrementVolume	= ( m_fTargetVolume - m_fCurrentVolume ) / m_iLimitSample;
	//			m_iLimitSampleInd	= 0;
	//		}
	//	}
	//}
	//else
	//{
	//	for ( int32_t i = iOffset; i < iLength + iOffset; ++i )
	//	{
	//		for ( int32_t c = 0; c < m_fmtOutput.nChannels; ++c )
	//		{
	//			m_fRealVolume		= fmax( pWindow[i + c * m_iOutWindowSample], m_fRealVolume );
	//			pWindow[i + c * m_iOutWindowSample]	*= m_fOutputVolume;
	//		}
	//		if ( ++m_iVolumeSampleInd == m_iVolumeStatistic )
	//		{
	//			m_iVolumeSampleInd	= 0;
	//			m_fRealVolume		= 0.0f;
	//		}
	//	}
	//}

}

#define		GET_NEXT_CACHE_BUF	if ( ++iOutOffset == m_iOutWindowSample ){\
									sInp.uResamples	+= iOutOffset - iOutOffsetB;\
									callSoundProcess( pOutBuf, iOutOffsetB, iOutOffset - iOutOffsetB, pPreBuf );\
									pOutBuf		= getCacheBuf( sInp, iOutOffset, &pPreBuf, pOutChannel );\
									iOutOffsetB	= iOutOffset;\
									if ( nullptr == pOutBuf ) break;\
								}
void CSoundResample::resampleSame( const void * pWaveData, int32_t iSampleCount, int32_t iInputIndex )
{



	SWaveInput&	sInp		= m_fmtInput[iInputIndex];
	//计算已经输入和重采样的帧在当前秒中的偏移量，单位是Sample。
//    uint32_t    uReOffset    = sInp.uResamples % m_fmtOutput.nSamplesPerSec;
	//计算将要存入的数据在输出缓冲区队列中的位置，单位是Sample。
	int32_t	iOutOffset	= 0;
	int32_t	iOutOffsetB	= 0;
	float*	pOutChannel[MAX_PCM_CHANNEL_COUNT]	={ 0 };
	float*	pPreBuf		= nullptr;
	float*	pOutBuf		= getCacheBuf( sInp, iOutOffset, &pPreBuf, pOutChannel );
	iOutOffsetB	= iOutOffset;

	uint8_t*	pInputCurr	= ( (uint8_t*)pWaveData );
	uint8_t*	pInputEnd	= pInputCurr + iSampleCount * sInp.nBlockAlign;
	switch ( sInp.eSampleBits )
	{
	case eSampleBit8i:
		while ( pInputCurr < pInputEnd )
		{
			for ( int32_t i = 0; i < sInp.uMapCount; ++i )
			{
				pOutChannel[i][iOutOffset] += ( pInputCurr[sInp.aChannelMap[i].iInpChannel] - 128 ) / 128.0f * sInp.aChannelMap[i].fVolumeMul;
			}
			GET_NEXT_CACHE_BUF;
			pInputCurr	+= sInp.nBlockAlign;
		}
	case eSampleBit16i:
		while ( pInputCurr < pInputEnd )
		{
			for ( int32_t i = 0; i < sInp.uMapCount; ++i )
			{
				pOutChannel[i][iOutOffset] += (((int16_t*)pInputCurr)[sInp.aChannelMap[i].iInpChannel]) / 32768.0f * sInp.aChannelMap[i].fVolumeMul;
			}
			GET_NEXT_CACHE_BUF;
			pInputCurr	+= sInp.nBlockAlign;
		}
		break;
	case eSampleBit24i:
		while ( pInputCurr < pInputEnd )
		{
			for ( int32_t i = 0; i < sInp.uMapCount; ++i )
			{
				uint8_t*	pSamp	= ( pInputCurr + ( sInp.aChannelMap[i].iInpChannel * 3 ) );
				int32_t		iSampC	= ( pSamp[0] << 8 ) | ( pSamp[1] << 16 ) | ( pSamp[2] << 24 );
				pOutChannel[i][iOutOffset] += iSampC / 2147483648.0f * sInp.aChannelMap[i].fVolumeMul;
			}
			GET_NEXT_CACHE_BUF;
			pInputCurr	+= sInp.nBlockAlign;
		}
		break;
	case eSampleBit32i:
		while ( pInputCurr < pInputEnd )
		{
			for ( int32_t i = 0; i < sInp.uMapCount; ++i )
			{
				pOutChannel[i][iOutOffset] += ((int32_t*)pInputCurr)[sInp.aChannelMap[i].iInpChannel] / 2147483648.0f * sInp.aChannelMap[i].fVolumeMul;
			}
			GET_NEXT_CACHE_BUF;
			pInputCurr	+= sInp.nBlockAlign;
		}
		break;
	case eSampleBit24In32i:
		while ( pInputCurr < pInputEnd )
		{
			for ( int32_t i = 0; i < sInp.uMapCount; ++i )
			{
				pOutChannel[i][iOutOffset] += ((int32_t*)pInputCurr)[sInp.aChannelMap[i].iInpChannel] / 8388608.0f * sInp.aChannelMap[i].fVolumeMul;
			}
			GET_NEXT_CACHE_BUF;
			pInputCurr	+= sInp.nBlockAlign;
		}
		break;
	case eSampleBit32f:
		while ( pInputCurr < pInputEnd )
		{
			for ( int32_t i = 0; i < sInp.uMapCount; ++i )
			{
				pOutChannel[i][iOutOffset] += ((float*)pInputCurr)[sInp.aChannelMap[i].iInpChannel] * sInp.aChannelMap[i].fVolumeMul;
			}
			GET_NEXT_CACHE_BUF;
			pInputCurr	+= sInp.nBlockAlign;
		}
	}
	sInp.uInpSamples	+= iSampleCount;
	if ( iOutOffset - iOutOffsetB )
	{
		sInp.uResamples	+= iOutOffset - iOutOffsetB;
		callSoundProcess( pOutBuf, iOutOffsetB, iOutOffset - iOutOffsetB, pPreBuf );
	}
}

void CSoundResample::resampleNear( const void * pWaveData, int32_t iSampleCount, int32_t iInputIndex )
{
	SWaveInput&	sInp		= m_fmtInput[iInputIndex];
	//计算已经输入和重采样的帧在当前秒中的偏移量，单位是Sample。
	uint32_t	uInpOffset	= sInp.uInpSamples - sInp.uResamples / m_fmtOutput.nSamplesPerSec * sInp.nSamplesPerSec;
	uint32_t	uReOffset	= sInp.uResamples % m_fmtOutput.nSamplesPerSec;
	//计算将要存入的数据在输出缓冲区队列中的位置，单位是Sample。
	int32_t	iOutOffset	= 0;
	int32_t	iOutOffsetB	= 0;
	float*	pOutChannel[MAX_PCM_CHANNEL_COUNT]	={ 0 };
	float*	pPreBuf		= nullptr;
	float*	pOutBuf		= getCacheBuf( sInp, iOutOffset, &pPreBuf, pOutChannel );
	iOutOffsetB	= iOutOffset;

	uint32_t	uInpPos		= uReOffset * sInp.nSamplesPerSec / m_fmtOutput.nSamplesPerSec - uInpOffset;
	switch ( sInp.eSampleBits )
	{
	case eSampleBit8i:
		while ( uInpPos < iSampleCount )
		{
			uint8_t*	pInputCurr	= ( (uint8_t*)pWaveData ) + uInpPos * sInp.nChannels;
			for ( int32_t i = 0; i < sInp.uMapCount; ++i )
			{
				pOutChannel[i][iOutOffset] += ( pInputCurr[sInp.aChannelMap[i].iInpChannel] - 128 ) / 128.0f * sInp.aChannelMap[i].fVolumeMul;
			}
			GET_NEXT_CACHE_BUF;
			uInpPos		= (++uReOffset) * sInp.nSamplesPerSec / m_fmtOutput.nSamplesPerSec - uInpOffset;
		}
	case eSampleBit16i:
		while ( uInpPos < iSampleCount )
		{
			int16_t*	pInputCurr	= ( (int16_t*)pWaveData ) + uInpPos * sInp.nChannels;
			for ( int32_t i = 0; i < sInp.uMapCount; ++i )
			{
				pOutChannel[i][iOutOffset] += pInputCurr[sInp.aChannelMap[i].iInpChannel] / 32768.0f * sInp.aChannelMap[i].fVolumeMul;
			}
			GET_NEXT_CACHE_BUF;
			uInpPos		= ( ++uReOffset ) * sInp.nSamplesPerSec / m_fmtOutput.nSamplesPerSec - uInpOffset;
		}
		break;
	case eSampleBit24i:
		while ( uInpPos < iSampleCount )
		{
			uint8_t*	pInputCurr	= ( (uint8_t*)pWaveData ) + uInpPos * sInp.nBlockAlign;
			for ( int32_t i = 0; i < sInp.uMapCount; ++i )
			{
				int32_t		iSampC	= *( (int32_t*)( pInputCurr + ( sInp.aChannelMap[i].iInpChannel * 3 ) ) ) << 8;
				pOutChannel[i][iOutOffset] += iSampC / 2147483648.0f * sInp.aChannelMap[i].fVolumeMul;
			}
			GET_NEXT_CACHE_BUF;
			uInpPos		= ( ++uReOffset ) * sInp.nSamplesPerSec / m_fmtOutput.nSamplesPerSec - uInpOffset;
		}
		break;
	case eSampleBit32i:
		while ( uInpPos < iSampleCount )
		{
			int32_t*	pInputCurr	= ( (int32_t*)pWaveData ) + uInpPos * sInp.nChannels;
			for ( int32_t i = 0; i < sInp.uMapCount; ++i )
			{
				pOutChannel[i][iOutOffset] += pInputCurr[sInp.aChannelMap[i].iInpChannel] / 2147483648.0f * sInp.aChannelMap[i].fVolumeMul;
			}
			GET_NEXT_CACHE_BUF;
			uInpPos		= ( ++uReOffset ) * sInp.nSamplesPerSec / m_fmtOutput.nSamplesPerSec - uInpOffset;
		}
		break;
	case eSampleBit24In32i:
		while ( uInpPos < iSampleCount )
		{
			int32_t*	pInputCurr	= ( (int32_t*)pWaveData ) + uInpPos * sInp.nChannels;
			for ( int32_t i = 0; i < sInp.uMapCount; ++i )
			{
				pOutChannel[i][iOutOffset] += pInputCurr[sInp.aChannelMap[i].iInpChannel] / 8388608.0f * sInp.aChannelMap[i].fVolumeMul;
			}
			GET_NEXT_CACHE_BUF;
			uInpPos		= ( ++uReOffset ) * sInp.nSamplesPerSec / m_fmtOutput.nSamplesPerSec - uInpOffset;
		}
		break;
	case eSampleBit32f:
		while ( uInpPos < iSampleCount )
		{
			float*	pInputCurr	= ( (float*)pWaveData ) + uInpPos * sInp.nChannels;
			for ( int32_t i = 0; i < sInp.uMapCount; ++i )
			{
				pOutChannel[i][iOutOffset] += pInputCurr[sInp.aChannelMap[i].iInpChannel] * sInp.aChannelMap[i].fVolumeMul;
			}
			GET_NEXT_CACHE_BUF;
			uInpPos		= ( ++uReOffset ) * sInp.nSamplesPerSec / m_fmtOutput.nSamplesPerSec - uInpOffset;
		}
	}
	sInp.uInpSamples	+= iSampleCount;
	if ( iOutOffset - iOutOffsetB )
	{
		sInp.uResamples	+= iOutOffset - iOutOffsetB;
		callSoundProcess( pOutBuf, iOutOffsetB, iOutOffset - iOutOffsetB, pPreBuf );
	}
}

void CSoundResample::resampleLine( const void * pWaveData, int32_t iSampleCount, int32_t iInputIndex )
{
	SWaveInput&	sInp		= m_fmtInput[iInputIndex];
	//计算已经输入和重采样的帧在当前秒中的偏移量，单位是Sample。
	int32_t	iInpOffset	= sInp.uInpSamples - sInp.uResamples / m_fmtOutput.nSamplesPerSec * sInp.nSamplesPerSec;
	int32_t	iReOffset	= sInp.uResamples % m_fmtOutput.nSamplesPerSec;
	//计算将要存入的数据在输出缓冲区队列中的位置，单位是Sample。
	int32_t	iOutOffset	= 0;
	int32_t	iOutOffsetB	= 0;
	float*	pOutChannel[MAX_PCM_CHANNEL_COUNT]	={ 0 };
	float*	pPreBuf		= nullptr;
	float*	pOutBuf		= getCacheBuf( sInp, iOutOffset, &pPreBuf, pOutChannel );
	iOutOffsetB	= iOutOffset;

	float	fScale		= sInp.nSamplesPerSec * 1.0f / m_fmtOutput.nSamplesPerSec;
	float	fInpPos		= iReOffset * fScale + fScale * 0.5f + 0.4999999f - iInpOffset;
	int32_t	iInpPos		= (int32_t)fInpPos;
	float	fCurComponent	= 0.0f;

	switch ( sInp.eSampleBits )
	{
	case eSampleBit8i:
		while ( iInpPos < iSampleCount )
		{
			fCurComponent	= fInpPos - iInpPos;
			uint8_t*	pInputCurr	= ( (uint8_t*)pWaveData ) + iInpPos * sInp.nChannels;
			uint8_t*	pInputPrev	= iInpPos ? pInputCurr - sInp.nChannels : (uint8_t*)sInp.aLastSample;
			for ( int32_t i = 0; i < sInp.uMapCount; ++i )
			{
				pOutChannel[i][iOutOffset] += ( ( pInputCurr[sInp.aChannelMap[i].iInpChannel] - 128 ) / 128.0f * fCurComponent
					+ ( pInputPrev[sInp.aChannelMap[i].iInpChannel] - 128 ) / 128.0f * ( 1.0f - fCurComponent ) ) 
					* sInp.aChannelMap[i].fVolumeMul;
			}
			GET_NEXT_CACHE_BUF;
			fInpPos	+= fScale;
			iInpPos	= (int32_t)fInpPos;
		}
	case eSampleBit16i:
		while ( iInpPos < iSampleCount )
		{
			fCurComponent	= fInpPos - iInpPos;
			int16_t*	pInputCurr	= ( (int16_t*)pWaveData ) + iInpPos * sInp.nChannels;
			int16_t*	pInputPrev	= iInpPos ? pInputCurr - sInp.nChannels : (int16_t*)sInp.aLastSample;
			for ( int32_t i = 0; i < sInp.uMapCount; ++i )
			{
				pOutChannel[i][iOutOffset] += ( ( pInputCurr[sInp.aChannelMap[i].iInpChannel] * fCurComponent
					+ pInputPrev[sInp.aChannelMap[i].iInpChannel] * ( 1.0f - fCurComponent ) ) )
					/ 32768.0f * sInp.aChannelMap[i].fVolumeMul;
			}
			GET_NEXT_CACHE_BUF;
			fInpPos	+= fScale;
			iInpPos	= (int32_t)fInpPos;
		}
		break;
	case eSampleBit24i:
		while ( iInpPos < iSampleCount )
		{
			fCurComponent	= fInpPos - iInpPos;
			uint8_t*	pInputCurr	= ( (uint8_t*)pWaveData ) + iInpPos * sInp.nBlockAlign;
			uint8_t*	pInputPrev	= iInpPos ? pInputCurr - sInp.nBlockAlign : (uint8_t*)sInp.aLastSample;
			for ( int32_t i = 0; i < sInp.uMapCount; ++i )
			{
				int32_t		iSampC	= *( (int32_t*)(pInputCurr + ( sInp.aChannelMap[i].iInpChannel * 3 )) ) << 8;
				int32_t		iSampP	= *( (int32_t*)(pInputPrev + ( sInp.aChannelMap[i].iInpChannel * 3 )) ) << 8;
				pOutChannel[i][iOutOffset] += ( ( iSampC * fCurComponent + iSampP * ( 1.0f - fCurComponent ) ) )
					/ 2147483648.0f * sInp.aChannelMap[i].fVolumeMul;
			}
			GET_NEXT_CACHE_BUF;
			fInpPos	+= fScale;
			iInpPos	= (int32_t)fInpPos;
		}
		break;
	case eSampleBit32i:
		while ( iInpPos < iSampleCount )
		{
			fCurComponent	= fInpPos - iInpPos;
			int32_t*	pInputCurr	= ( (int32_t*)pWaveData ) + iInpPos * sInp.nChannels;
			int32_t*	pInputPrev	= iInpPos ? pInputCurr - sInp.nChannels : (int32_t*)sInp.aLastSample;
			for ( int32_t i = 0; i < sInp.uMapCount; ++i )
			{
				pOutChannel[i][iOutOffset] += ( pInputCurr[sInp.aChannelMap[i].iInpChannel] * fCurComponent
					+ pInputPrev[sInp.aChannelMap[i].iInpChannel] * ( 1.0f - fCurComponent ) )
					/ 2147483648.0f * sInp.aChannelMap[i].fVolumeMul;
			}
			GET_NEXT_CACHE_BUF;
			fInpPos	+= fScale;
			iInpPos	= (int32_t)fInpPos;
		}
		break;
	case eSampleBit24In32i:
		while ( iInpPos < iSampleCount )
		{
			fCurComponent	= fInpPos - iInpPos;
			int32_t*	pInputCurr	= ( (int32_t*)pWaveData ) + iInpPos * sInp.nChannels;
			int32_t*	pInputPrev	= iInpPos ? pInputCurr - sInp.nChannels : (int32_t*)sInp.aLastSample;
			for ( int32_t i = 0; i < sInp.uMapCount; ++i )
			{
				pOutChannel[i][iOutOffset] += ( pInputCurr[sInp.aChannelMap[i].iInpChannel] * fCurComponent
					+ pInputPrev[sInp.aChannelMap[i].iInpChannel] * ( 1.0f - fCurComponent ) )
					/ 8388608.0f * sInp.aChannelMap[i].fVolumeMul;
			}
			GET_NEXT_CACHE_BUF;
			fInpPos	+= fScale;
			iInpPos	= (int32_t)fInpPos;
		}
		break;
	case eSampleBit32f:
		while ( iInpPos < iSampleCount )
		{
			fCurComponent	= fInpPos - iInpPos;
			float*	pInputCurr	= ( (float*)pWaveData ) + iInpPos * sInp.nChannels;
			float*	pInputPrev	= iInpPos ? pInputCurr - sInp.nChannels : sInp.aLastSample;
			for ( int32_t i = 0; i < sInp.uMapCount; ++i )
			{
				pOutChannel[i][iOutOffset] += ( pInputCurr[sInp.aChannelMap[i].iInpChannel] * fCurComponent
					+ pInputPrev[sInp.aChannelMap[i].iInpChannel] * ( 1.0f - fCurComponent ) ) * sInp.aChannelMap[i].fVolumeMul;
				//pOutChannel[i][iOutOffset] += pInputCurr[sInp.aChannelMap[i].iInpChannel] * sInp.aChannelMap[i].fVolumeMul;
			}
			GET_NEXT_CACHE_BUF;
			fInpPos	+= fScale;
			iInpPos	= (int32_t)fInpPos;
		}
	}
	memcpy( sInp.aLastSample, ( (char*)pWaveData ) + ( iSampleCount - 1 ) * sInp.nBlockAlign, sInp.nBlockAlign );
	sInp.uInpSamples	+= iSampleCount;
	if ( iOutOffset - iOutOffsetB )
	{
		sInp.uResamples	+= iOutOffset - iOutOffsetB;
		callSoundProcess( pOutBuf, iOutOffsetB, iOutOffset - iOutOffsetB, pPreBuf );
	}
}
