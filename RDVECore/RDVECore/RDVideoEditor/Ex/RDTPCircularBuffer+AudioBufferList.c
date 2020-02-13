//
//  RDTPCircularBuffer+AudioBufferList.c
//  Circular/Ring buffer implementation
//
//  Created by Michael Tyson on 20/03/2012.
//  Copyright 2012 A Tasty Pixel. All rights reserved.
//

#include "RDTPCircularBuffer+AudioBufferList.h"
#import <mach/mach_time.h>

static double __secondsToHostTicks = 0.0;

static inline long align16byte(long val) {
    if ( val & (16-1) ) {
        return val + (16 - (val & (16-1)));
    }
    return val;
}

static inline long min(long a, long b) {
    return a > b ? b : a;
}

AudioBufferList *RDTPCircularBufferPrepareEmptyAudioBufferList(RDTPCircularBuffer *buffer, int numberOfBuffers, int bytesPerBuffer, const AudioTimeStamp *inTimestamp) {
    int32_t availableBytes;
    RDTPCircularBufferABLBlockHeader *block = (RDTPCircularBufferABLBlockHeader*)RDTPCircularBufferHead(buffer, &availableBytes);
    if (!block || availableBytes < sizeof(RDTPCircularBufferABLBlockHeader)+((numberOfBuffers-1)*sizeof(AudioBuffer))+(numberOfBuffers*bytesPerBuffer) )
        return NULL;
    
    assert(!((unsigned long)block & 0xF) /* Beware unaligned accesses */);
    
    if ( inTimestamp ) {
        memcpy(&block->timestamp, inTimestamp, sizeof(AudioTimeStamp));
    } else {
        memset(&block->timestamp, 0, sizeof(AudioTimeStamp));
    }
    
    memset(&block->bufferList, 0, sizeof(AudioBufferList)+((numberOfBuffers-1)*sizeof(AudioBuffer)));
    block->bufferList.mNumberBuffers = numberOfBuffers;
    
    char *dataPtr = (char*)&block->bufferList + sizeof(AudioBufferList)+((numberOfBuffers-1)*sizeof(AudioBuffer));
    for ( int i=0; i<numberOfBuffers; i++ ) {
        // Find the next 16-byte aligned memory area
        dataPtr = (char*)align16byte((long)dataPtr);
        
        if ( (dataPtr + bytesPerBuffer) - (char*)block > availableBytes ) {
            return NULL;
        }
        
        block->bufferList.mBuffers[i].mData = dataPtr;
        block->bufferList.mBuffers[i].mDataByteSize = bytesPerBuffer;
        block->bufferList.mBuffers[i].mNumberChannels = 1;
        
        dataPtr += bytesPerBuffer;
    }
    
    // Make sure whole buffer (including timestamp and length value) is 16-byte aligned in length
    block->totalLength = (UInt32)align16byte(dataPtr - (char*)block);
    if ( block->totalLength > availableBytes ) {
        return NULL;
    }
    
    return &block->bufferList;
}

void RDTPCircularBufferProduceAudioBufferList(RDTPCircularBuffer *buffer, const AudioTimeStamp *inTimestamp) {
    int32_t availableBytes;
    RDTPCircularBufferABLBlockHeader *block = (RDTPCircularBufferABLBlockHeader*)RDTPCircularBufferHead(buffer, &availableBytes);
    
    assert(block);
    assert(!((unsigned long)block & 0xF) /* Beware unaligned accesses */);
    
    if ( inTimestamp ) {
        memcpy(&block->timestamp, inTimestamp, sizeof(AudioTimeStamp));
    }
    
    UInt32 calculatedLength = (UInt32)(((char*)block->bufferList.mBuffers[block->bufferList.mNumberBuffers-1].mData + block->bufferList.mBuffers[block->bufferList.mNumberBuffers-1].mDataByteSize) - (char*)block);

    // Make sure whole buffer (including timestamp and length value) is 16-byte aligned in length
    calculatedLength = (UInt32)align16byte(calculatedLength);
    
    assert(calculatedLength <= block->totalLength && calculatedLength <= availableBytes);
    
    block->totalLength = calculatedLength;
    
    RDTPCircularBufferProduce(buffer, block->totalLength);
}

bool RDTPCircularBufferCopyAudioBufferList(RDTPCircularBuffer *buffer, const AudioBufferList *inBufferList, const AudioTimeStamp *inTimestamp, UInt32 frames, AudioStreamBasicDescription *audioDescription) {

    if ( frames == 0 )
        return true;
    
    int byteCount = inBufferList->mBuffers[0].mDataByteSize;
    if ( frames != kRDTPCircularBufferCopyAll ) {
        byteCount = frames * audioDescription->mBytesPerFrame;
        assert(byteCount <= inBufferList->mBuffers[0].mDataByteSize);
    }
    
    AudioBufferList *bufferList = RDTPCircularBufferPrepareEmptyAudioBufferList(buffer, inBufferList->mNumberBuffers, byteCount, inTimestamp);
    if ( !bufferList || bufferList->mNumberBuffers == 0)
        return false;
    
    for ( int i=0; i<bufferList->mNumberBuffers; i++ ) {
        memcpy(bufferList->mBuffers[i].mData, inBufferList->mBuffers[i].mData, byteCount);
    }
    
    RDTPCircularBufferProduceAudioBufferList(buffer, NULL);
    
    return true;
}

AudioBufferList *RDTPCircularBufferNextBufferListAfter(RDTPCircularBuffer *buffer, AudioBufferList *bufferList, AudioTimeStamp *outTimestamp) {
    int32_t availableBytes;
    void *tail = RDTPCircularBufferTail(buffer, &availableBytes);
    void *end = (char*)tail + availableBytes;
    assert((void*)bufferList > (void*)tail && (void*)bufferList < end);
    
    RDTPCircularBufferABLBlockHeader *originalBlock = (RDTPCircularBufferABLBlockHeader*)((char*)bufferList - offsetof(RDTPCircularBufferABLBlockHeader, bufferList));
    assert(!((unsigned long)originalBlock & 0xF) /* Beware unaligned accesses */);
    
    
    RDTPCircularBufferABLBlockHeader *nextBlock = (RDTPCircularBufferABLBlockHeader*)((char*)originalBlock + originalBlock->totalLength);
    if ( (void*)nextBlock >= end ) return NULL;
    assert(!((unsigned long)nextBlock & 0xF) /* Beware unaligned accesses */);
    
    if ( outTimestamp ) {
        memcpy(outTimestamp, &nextBlock->timestamp, sizeof(AudioTimeStamp));
    }
    
    return &nextBlock->bufferList;
}

void RDTPCircularBufferConsumeNextBufferListPartial(RDTPCircularBuffer *buffer, int framesToConsume, AudioStreamBasicDescription *audioFormat) {
    assert(framesToConsume >= 0);
    
    int32_t dontcare;
    RDTPCircularBufferABLBlockHeader *block = (RDTPCircularBufferABLBlockHeader*)RDTPCircularBufferTail(buffer, &dontcare);
    if ( !block )
        return;
    assert(!((unsigned long)block & 0xF)); // Beware unaligned accesses
    
    int bytesToConsume = (int)min(framesToConsume * audioFormat->mBytesPerFrame, block->bufferList.mBuffers[0].mDataByteSize);
    
    if ( bytesToConsume == block->bufferList.mBuffers[0].mDataByteSize ) {
        RDTPCircularBufferConsumeNextBufferList(buffer);
        return;
    }
    
    for ( int i=0; i<block->bufferList.mNumberBuffers; i++ ) {
        assert(bytesToConsume <= block->bufferList.mBuffers[i].mDataByteSize && (char*)block->bufferList.mBuffers[i].mData + bytesToConsume <= (char*)block+block->totalLength);
        
        block->bufferList.mBuffers[i].mData = (char*)block->bufferList.mBuffers[i].mData + bytesToConsume;
        block->bufferList.mBuffers[i].mDataByteSize -= bytesToConsume;
    }
    
    if ( block->timestamp.mFlags & kAudioTimeStampSampleTimeValid ) {
        block->timestamp.mSampleTime += framesToConsume;
    }
    if ( block->timestamp.mFlags & kAudioTimeStampHostTimeValid ) {
        if ( !__secondsToHostTicks ) {
            mach_timebase_info_data_t tinfo;
            mach_timebase_info(&tinfo);
            __secondsToHostTicks = 1.0 / (((double)tinfo.numer / tinfo.denom) * 1.0e-9);
        }

        block->timestamp.mHostTime += ((double)framesToConsume / audioFormat->mSampleRate) * __secondsToHostTicks;
    }
}

void RDTPCircularBufferDequeueBufferListFrames(RDTPCircularBuffer *buffer, UInt32 *ioLengthInFrames, AudioBufferList *outputBufferList, AudioTimeStamp *outTimestamp, AudioStreamBasicDescription *audioFormat) {
    bool hasTimestamp = false;
    UInt32 bytesToGo = *ioLengthInFrames * audioFormat->mBytesPerFrame;
    UInt32 bytesCopied = 0;
    while ( bytesToGo > 0 ) {
        AudioBufferList *bufferList = RDTPCircularBufferNextBufferList(buffer, !hasTimestamp ? outTimestamp : NULL);
        RDTPCircularBufferABLBlockHeader *block = bufferList ? (RDTPCircularBufferABLBlockHeader*)((char*)bufferList - offsetof(RDTPCircularBufferABLBlockHeader, bufferList)) : NULL;
        hasTimestamp = true;
        if ( !bufferList )
            break;
        
        UInt32 bytesToCopy = (UInt32)min(bytesToGo, bufferList->mBuffers[0].mDataByteSize);
        
        if ( outputBufferList ) {
            for ( int i=0; i<outputBufferList->mNumberBuffers; i++ ) {
                assert(bytesCopied + bytesToCopy <= outputBufferList->mBuffers[i].mDataByteSize);
                
//                assert((char*)outputBufferList->mBuffers[i].mData + bytesCopied + bytesToCopy <= (char*)outputBufferList->mBuffers[i].mData + outputBufferList->mBuffers[i].mDataByteSize);
                assert((char*)bufferList->mBuffers[i].mData + bytesToCopy <= (char*)bufferList+(block?block->totalLength:0));
                
                memcpy((char*)outputBufferList->mBuffers[i].mData + bytesCopied, bufferList->mBuffers[i].mData, bytesToCopy);
            }
        }
        
        RDTPCircularBufferConsumeNextBufferListPartial(buffer, bytesToCopy/audioFormat->mBytesPerFrame, audioFormat);
        
        bytesToGo -= bytesToCopy;
        bytesCopied += bytesToCopy;
    }
    
    *ioLengthInFrames -= bytesToGo / audioFormat->mBytesPerFrame;
    
    if ( outputBufferList ) {
        for ( int i=0; i<outputBufferList->mNumberBuffers; i++ ) {
            outputBufferList->mBuffers[i].mDataByteSize = *ioLengthInFrames * audioFormat->mBytesPerFrame;
        }        
    }
}

static UInt32 _RDTPCircularBufferPeek(RDTPCircularBuffer *buffer, AudioTimeStamp *outTimestamp, AudioStreamBasicDescription *audioFormat, UInt32 contiguousToleranceSampleTime) {
    int32_t availableBytes;
    RDTPCircularBufferABLBlockHeader *block = (RDTPCircularBufferABLBlockHeader*)RDTPCircularBufferTail(buffer, &availableBytes);
    if ( !block )
        return 0;
    assert(!((unsigned long)block & 0xF) /* Beware unaligned accesses */);
    
    if ( outTimestamp ) {
        memcpy(outTimestamp, &block->timestamp, sizeof(AudioTimeStamp));
    }
    
    void *end = (char*)block + availableBytes;
    
    UInt32 byteCount = 0;
    
    while ( 1 ) {
        byteCount += block->bufferList.mBuffers[0].mDataByteSize;
        RDTPCircularBufferABLBlockHeader *nextBlock = (RDTPCircularBufferABLBlockHeader*)((char*)block + block->totalLength);
        if ( (void*)nextBlock >= end ||
                (contiguousToleranceSampleTime != UINT32_MAX
//                    && labs(nextBlock->timestamp.mSampleTime - (block->timestamp.mSampleTime + (block->bufferList.mBuffers[0].mDataByteSize / audioFormat->mBytesPerFrame))) > contiguousToleranceSampleTime) ) {
                 // new issue
                 && fabs(nextBlock->timestamp.mSampleTime - (block->timestamp.mSampleTime + (block->bufferList.mBuffers[0].mDataByteSize / audioFormat->mBytesPerFrame))) > contiguousToleranceSampleTime) ) {

            break;
        }
        assert(!((unsigned long)nextBlock & 0xF) /* Beware unaligned accesses */);
        block = nextBlock;
    }
    
    return byteCount / audioFormat->mBytesPerFrame;
}

UInt32 RDTPCircularBufferPeek(RDTPCircularBuffer *buffer, AudioTimeStamp *outTimestamp, AudioStreamBasicDescription *audioFormat) {
    return _RDTPCircularBufferPeek(buffer, outTimestamp, audioFormat, UINT32_MAX);
}

UInt32 RDTPCircularBufferPeekContiguous(RDTPCircularBuffer *buffer, AudioTimeStamp *outTimestamp, AudioStreamBasicDescription *audioFormat, UInt32 contiguousToleranceSampleTime) {
    return _RDTPCircularBufferPeek(buffer, outTimestamp, audioFormat, contiguousToleranceSampleTime);
}
