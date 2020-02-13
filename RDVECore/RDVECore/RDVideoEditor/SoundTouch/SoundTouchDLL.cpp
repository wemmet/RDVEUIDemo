//////////////////////////////////////////////////////////////////////////////
///
/// SoundTouch DLL wrapper - wraps SoundTouch routines into a Dynamic Load 
/// Library interface.
///
/// Author        : Copyright (c) Olli Parviainen
/// Author e-mail : oparviai 'at' iki.fi
/// SoundTouch WWW: http://www.surina.net/soundtouch
///
////////////////////////////////////////////////////////////////////////////////
//
// $Id: SoundTouchDLL.cpp 207 2015-02-22 15:16:48Z oparviai $
//
////////////////////////////////////////////////////////////////////////////////
//
// License :
//
//  SoundTouch audio processing library
//  Copyright (c) Olli Parviainen
//
//  This library is free software; you can redistribute it and/or
//  modify it under the terms of the GNU Lesser General Public
//  License as published by the Free Software Foundation; either
//  version 2.1 of the License, or (at your option) any later version.
//
//  This library is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//  Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public
//  License along with this library; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
////////////////////////////////////////////////////////////////////////////////

#include <string.h>
#include "SoundTouchDLL.h"

using namespace std;

#include "STTypes.h"
#include "SoundTouch.h"

using namespace soundtouch;
//////////////

typedef struct
{
    long dwMagic;
    SoundTouch *pst;
} STHANDLE;

#define STMAGIC 0x1770C001

HANDLE soundtouch_createInstance()
{
    STHANDLE *tmp = new STHANDLE;
    if (tmp)
    {
        tmp->dwMagic = STMAGIC;
        tmp->pst = new SoundTouch();
        if (tmp->pst == NULL)
        {
            delete tmp;
            tmp = NULL;
        }
    }
    return (HANDLE)tmp;
}


 void  soundtouch_destroyInstance(HANDLE h)
{
    STHANDLE *sth = (STHANDLE*)h;
    if (sth->dwMagic != STMAGIC) return;

    sth->dwMagic = 0;
    if (sth->pst) delete sth->pst;
    sth->pst = NULL;
    delete sth;
}


/// Get SoundTouch library version string
const char * soundtouch_getVersionString()
{
    return SoundTouch::getVersionString();
}


/// Get SoundTouch library version string - alternative function for 
/// environments that can't properly handle character string as return value
 void  soundtouch_getVersionString2(char* versionString, int bufferSize)
{
    strncpy(versionString, SoundTouch::getVersionString(), bufferSize - 1);
    versionString[bufferSize - 1] = 0;
}


/// Get SoundTouch library version Id
 uint  soundtouch_getVersionId()
{
    return SoundTouch::getVersionId();
}

/// Sets new rate control value. Normal rate = 1.0, smaller values
/// represent slower rate, larger faster rates.
 void  soundtouch_setRate(HANDLE h, float newRate)
{
    STHANDLE *sth = (STHANDLE*)h;
    if (sth->dwMagic != STMAGIC) return;

    sth->pst->setRate(newRate);
}


/// Sets new tempo control value. Normal tempo = 1.0, smaller values
/// represent slower tempo, larger faster tempo.
 void  soundtouch_setTempo(HANDLE h, float newTempo)
{
    STHANDLE *sth = (STHANDLE*)h;
    if (sth->dwMagic != STMAGIC) return;

    sth->pst->setTempo(newTempo);
}

/// Sets new rate control value as a difference in percents compared
/// to the original rate (-50 .. +100 %)
 void  soundtouch_setRateChange(HANDLE h, float newRate)
{
    STHANDLE *sth = (STHANDLE*)h;
    if (sth->dwMagic != STMAGIC) return;

    sth->pst->setRateChange(newRate);
}

/// Sets new tempo control value as a difference in percents compared
/// to the original tempo (-50 .. +100 %)
 void  soundtouch_setTempoChange(HANDLE h, float newTempo)
{
    STHANDLE *sth = (STHANDLE*)h;
    if (sth->dwMagic != STMAGIC) return;

    sth->pst->setTempoChange(newTempo);
}

/// Sets new pitch control value. Original pitch = 1.0, smaller values
/// represent lower pitches, larger values higher pitch.
 void  soundtouch_setPitch(HANDLE h, float newPitch)
{
    STHANDLE *sth = (STHANDLE*)h;
    if (sth->dwMagic != STMAGIC) return;

    sth->pst->setPitch(newPitch);
}

/// Sets pitch change in octaves compared to the original pitch  
/// (-1.00 .. +1.00)
 void  soundtouch_setPitchOctaves(HANDLE h, float newPitch)
{
    STHANDLE *sth = (STHANDLE*)h;
    if (sth->dwMagic != STMAGIC) return;

    sth->pst->setPitchOctaves(newPitch);
}

/// Sets pitch change in semi-tones compared to the original pitch
/// (-12 .. +12)
 void  soundtouch_setPitchSemiTones(HANDLE h, float newPitch)
{
    STHANDLE *sth = (STHANDLE*)h;
    if (sth->dwMagic != STMAGIC) return;

    sth->pst->setPitchSemiTones(newPitch);
}


/// Sets the number of channels, 1 = mono, 2 = stereo
 void  soundtouch_setChannels(HANDLE h, uint numChannels)
{
    STHANDLE *sth = (STHANDLE*)h;
    if (sth->dwMagic != STMAGIC) return;

    sth->pst->setChannels(numChannels);
}

/// Sets sample rate.
 void  soundtouch_setSampleRate(HANDLE h, uint srate)
{
    STHANDLE *sth = (STHANDLE*)h;
    if (sth->dwMagic != STMAGIC) return;

    sth->pst->setSampleRate(srate);
}

/// Flushes the last samples from the processing pipeline to the output.
/// Clears also the internal processing buffers.
//
/// Note: This function is meant for extracting the last samples of a sound
/// stream. This function may introduce additional blank samples in the end
/// of the sound stream, and thus it's not recommended to call this function
/// in the middle of a sound stream.
 void  soundtouch_flush(HANDLE h)
{
    STHANDLE *sth = (STHANDLE*)h;
    if (sth->dwMagic != STMAGIC) return;

    sth->pst->flush();
}

/// Adds 'numSamples' pcs of samples from the 'samples' memory position into
/// the input of the object. Notice that sample rate _has_to_ be set before
/// calling this function, otherwise throws a runtime_error exception.
 void  soundtouch_putSamples(HANDLE h, 
        const SAMPLETYPE *samples,  ///< Pointer to sample buffer.
        unsigned int numSamples                         ///< Number of samples in buffer. Notice
                                                ///< that in case of stereo-sound a single sample
                                                ///< contains data for both channels.
        )
{
    STHANDLE *sth = (STHANDLE*)h;
    if (sth->dwMagic != STMAGIC) return;

    sth->pst->putSamples(samples, numSamples);
}

 void  soundtouch_putSamples_i16(HANDLE h,
        const short *samples,       ///< Pointer to sample buffer.
        unsigned int numSamples     ///< Number of sample frames in buffer. Notice
                                    ///< that in case of multi-channel sound a single 
                                    ///< sample frame contains data for all channels.
)
 {
    STHANDLE *sth = (STHANDLE*)h;
    if (sth->dwMagic != STMAGIC) return;

    sth->pst->putSamples((SAMPLETYPE *)samples, numSamples);
 }

/// Clears all the samples in the object's output and internal processing
/// buffers.
 void  soundtouch_clear(HANDLE h)
{
    STHANDLE *sth = (STHANDLE*)h;
    if (sth->dwMagic != STMAGIC) return;

    sth->pst->clear();
}

/// Changes a setting controlling the processing system behaviour. See the
/// 'SETTING_...' defines for available setting ID's.
/// 
/// \return 'TRUE' if the setting was succesfully changed
 bool  soundtouch_setSetting(HANDLE h, 
                int settingId,   ///< Setting ID number. see SETTING_... defines.
                int value        ///< New setting value.
                )
{
    STHANDLE *sth = (STHANDLE*)h;
    if (sth->dwMagic != STMAGIC) return false;

    return sth->pst->setSetting(settingId, value);
}

/// Reads a setting controlling the processing system behaviour. See the
/// 'SETTING_...' defines for available setting ID's.
///
/// \return the setting value.
 int  soundtouch_getSetting(HANDLE h, 
                          int settingId    ///< Setting ID number, see SETTING_... defines.
                )
{
    STHANDLE *sth = (STHANDLE*)h;
    if (sth->dwMagic != STMAGIC) return -1;

    return sth->pst->getSetting(settingId);
}


/// Returns number of samples currently unprocessed.
 uint  soundtouch_numUnprocessedSamples(HANDLE h)
{
    STHANDLE *sth = (STHANDLE*)h;
    if (sth->dwMagic != STMAGIC) return 0;

    return sth->pst->numUnprocessedSamples();
}


/// Adjusts book-keeping so that given number of samples are removed from beginning of the 
/// sample buffer without copying them anywhere. 
///
/// Used to reduce the number of samples in the buffer when accessing the sample buffer directly
/// with 'ptrBegin' function.
 uint  soundtouch_receiveSamples(HANDLE h, 
                               SAMPLETYPE *outBuffer, ///< Buffer where to copy output samples.
                        uint maxSamples                    ///< How many samples to receive at max.
                        )
{
    STHANDLE *sth = (STHANDLE*)h;
    if (sth->dwMagic != STMAGIC) return 0;

    if (outBuffer)
    {
        return sth->pst->receiveSamples(outBuffer, maxSamples);
    }
    else
    {
        return sth->pst->receiveSamples(maxSamples);
    }
}

unsigned int  soundtouch_receiveSamples_i16(HANDLE h,
        short *outBuffer,           ///< Buffer where to copy output samples.
        unsigned int maxSamples     ///< How many samples to receive at max.
)
{
    STHANDLE *sth = (STHANDLE*)h;
    if (sth->dwMagic != STMAGIC) return 0;

    if (outBuffer)
    {
        return sth->pst->receiveSamples((SAMPLETYPE *)outBuffer, maxSamples);
    }
    else
    {
        return sth->pst->receiveSamples(maxSamples);
    }
}

/// Returns number of samples currently available.
 uint  soundtouch_numSamples(HANDLE h)
{
    STHANDLE *sth = (STHANDLE*)h;
    if (sth->dwMagic != STMAGIC) return 0;

    return sth->pst->numSamples();
}


/// Returns nonzero if there aren't any samples available for outputting.
 int  soundtouch_isEmpty(HANDLE h)
{
    STHANDLE *sth = (STHANDLE*)h;
    if (sth->dwMagic != STMAGIC) return -1;

    return sth->pst->isEmpty();
}
