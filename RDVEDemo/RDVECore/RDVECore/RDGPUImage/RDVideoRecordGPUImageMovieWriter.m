//
//  RDVideoRecordGPUImageMovieWriter.m
//  RDVEUISDK
//
//  Created by 周晓林 on 16/4/8.
//
//

#import "RDVideoRecordGPUImageMovieWriter.h"

@interface RDVideoRecordGPUImageMovieWriter()
{
    int32_t _currentFrame;
    CMTime _timeOffset;
    CMTime _audioTimestamp;
    CMTime _videoTimestamp;
    // flags
    struct {
        unsigned int previewRunning:1;
        unsigned int changingModes:1;
        unsigned int readyForAudio:1;
        unsigned int readyForVideo:1;
        unsigned int recording:1;
        unsigned int isPaused:1;
        unsigned int interrupted:1;
        unsigned int videoWritten:1;
    } __block _flags;
}
@end
@implementation RDVideoRecordGPUImageMovieWriter
- (float)getProgress{
    if (self.maxFrames > 0) {
        return (float)_currentFrame / self.maxFrames;
    }
    return 0;
}

- (void)startRecording{
    self.started = YES;
    _flags.recording = YES;
    _currentFrame = 0;
    
    [super startRecording];
    NSLog(@"%s",__func__);
    
    
    
}

- (BOOL)isPaused{
    return _flags.isPaused;
}

- (void)pauseRecording
{
    if (!self.assetWriter) {
        NSLog(@"assetWriter unavailable to stop");
        return;
    }
    
    NSLog(@"%s",__func__);
    
    _flags.isPaused = YES;
    _flags.interrupted = YES;
}

- (void)resumeRecording
{
    if (!self.assetWriter) {
        NSLog(@"assetWriter unavailable to resume");
        return;
    }
    
    NSLog(@"%s",__func__);
    
    _flags.isPaused = NO;
}

- (void)finishRecording
{
    if (!_flags.recording)
        return;
    
    if (!self.assetWriter) {
        NSLog(@"assetWriter unavailable to end");
        return;
    }
    
    if (self.assetWriter.status == AVAssetWriterStatusUnknown) {
        NSLog(@"asset writer is in an unknown state, wasn't recording");
        return;
    }
    
    _flags.recording = NO;
    _flags.isPaused = YES;
    [super finishRecording];
    NSLog(@"%s",__func__);
    
}
- (void)finishRecordingWithCompletionHandler:(void (^)(void))handler
{
    if (!_flags.recording) {
        return;
    }
    if (!self.assetWriter) {
        NSLog(@"assetWriter unavailable to end");
        return;
    }
    
    if (self.assetWriter.status == AVAssetWriterStatusUnknown) {
        NSLog(@"asset writer is in an unknown state, wasn't recording");
        if ([self.assetWriter respondsToSelector:@selector(finishWritingWithCompletionHandler:)]) {
            [self.assetWriter finishWritingWithCompletionHandler:(handler ?: ^{ })];
        }
        return;
    }
    
    _flags.recording = NO;
    _flags.isPaused = YES;
    [super finishRecordingWithCompletionHandler:handler];
}
- (void)processAudioBuffer:(CMSampleBufferRef)audioBuffer{
    if (!CMSampleBufferDataIsReady(audioBuffer)) {
        NSLog(@"sample buffer data is not ready");
        //CFRelease(audioBuffer);
        return;
    }
    //20180418 录制时，总会出现音频比视频短的情况，为解决这个问题，结束录制先只结束视频(markAsFinished)，音频录制到与视频最后一帧时间戳一致时再结束(markAsFinished)
//    if (!_flags.recording || _flags.isPaused) {
//        //CFRelease(audioBuffer);
//        return;
//    }
    // calculate the length of the interruption
    if (_flags.interrupted) {
        _flags.interrupted = NO;
        
        CMTime time = _audioTimestamp;
        // calculate the appropriate time offset
        if (CMTIME_IS_VALID(time)) {
            CMTime pTimestamp = CMSampleBufferGetPresentationTimeStamp(audioBuffer);
            if (CMTIME_IS_VALID(_timeOffset)) {
                pTimestamp = CMTimeSubtract(pTimestamp, _timeOffset);
            }
            
            CMTime offset = CMTimeSubtract(pTimestamp, _audioTimestamp);
            _timeOffset = (_timeOffset.value == 0) ? offset : CMTimeAdd(_timeOffset, offset);
            NSLog(@"new calculated offset %f valid (%d)", CMTimeGetSeconds(_timeOffset), CMTIME_IS_VALID(_timeOffset));
        } else {
            NSLog(@"invalid audio timestamp, no offset update");
        }
        
        _audioTimestamp.flags = 0;
        _videoTimestamp.flags = 0;
        
    }
    CMSampleBufferRef bufferToWrite = NULL;
    if (_timeOffset.value > 0) {
        bufferToWrite = [self _createOffsetSampleBuffer:audioBuffer withTimeOffset:_timeOffset];
        if (!bufferToWrite) {
            NSLog(@"error subtracting the timeoffset from the sampleBuffer");
        }
    } else {
        bufferToWrite = audioBuffer;
        CFRetain(bufferToWrite);
    }
    
    if (bufferToWrite && _flags.videoWritten) {
        // update the last audio timestamp
        CMTime time = CMSampleBufferGetPresentationTimeStamp(bufferToWrite);
        CMTime duration = CMSampleBufferGetDuration(bufferToWrite);
//        NSLog(@"bufferToWrite time: %@ duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, time)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, duration)));
        if (duration.value > 0)
            time = CMTimeAdd(time, duration);
        
        if (time.value > _audioTimestamp.value) {
            [super processAudioBuffer:bufferToWrite]; //pass to super
            _audioTimestamp = time;
        }else{
            NSLog(@"%s line:%d",__func__,__LINE__);
        }
        CFRelease(bufferToWrite);
    }else {
        NSLog(@"音频已来，但视频未开始写");
    }
    
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex{
    if (!_flags.recording || _flags.isPaused) {
        return;
    }
    
    if (!_flags.interrupted) {
        CMTime newTime = frameTime;
        if (_timeOffset.value > 0) {
            newTime = CMTimeSubtract(frameTime, _timeOffset);
        }
        if (newTime.value > _videoTimestamp.value) {
            [super newFrameReadyAtTime:newTime atIndex:textureIndex];
            _videoTimestamp = newTime;
            _flags.videoWritten = YES;
            _currentFrame++;
        }
    }
}


- (CMSampleBufferRef)_createOffsetSampleBuffer:(CMSampleBufferRef)sampleBuffer withTimeOffset:(CMTime)timeOffset
{
    CMItemCount itemCount;
    
    OSStatus status = CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, 0, NULL, &itemCount);
    if (status) {
        NSLog(@"couldn't determine the timing info count");
        return NULL;
    }
    
    CMSampleTimingInfo *timingInfo = (CMSampleTimingInfo *)malloc(sizeof(CMSampleTimingInfo) * (unsigned long)itemCount);
    if (!timingInfo) {
        NSLog(@"couldn't allocate timing info");
        return NULL;
    }
    
    status = CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, itemCount, timingInfo, &itemCount);
    if (status) {
        free(timingInfo);
        timingInfo = NULL;
        NSLog(@"failure getting sample timing info array");
        return NULL;
    }
    
    for (CMItemCount i = 0; i < itemCount; i++) {
        timingInfo[i].presentationTimeStamp = CMTimeSubtract(timingInfo[i].presentationTimeStamp, timeOffset);
        timingInfo[i].decodeTimeStamp = CMTimeSubtract(timingInfo[i].decodeTimeStamp, timeOffset);
    }
    
    CMSampleBufferRef outputSampleBuffer;
    CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault, sampleBuffer, itemCount, timingInfo, &outputSampleBuffer);
    
    if (timingInfo) {
        free(timingInfo);
        timingInfo = NULL;
    }
    
    return outputSampleBuffer;
}
- (UIImage *)imageFromPixBuffer:(CVPixelBufferRef)pixelBuffer{//从CVPixelBufferRef生成UIImage
//    int w = (int)CVPixelBufferGetWidth(pixelBuffer);
//    int h = (int)CVPixelBufferGetHeight(pixelBuffer);
//    int r = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
//    int bytesPerPixel = r/w;
//    
//    unsigned char *buffer = CVPixelBufferGetBaseAddress(pixelBuffer);
//    
//    UIGraphicsBeginImageContext(CGSizeMake(w, h));
//    
//    CGContextRef c = UIGraphicsGetCurrentContext();
//    
//    unsigned char* data = CGBitmapContextGetData(c);
//    if (data != NULL) {
//        int maxY = h;
//        for(int y = 0; y<maxY; y++) {
//            for(int x = 0; x<w; x++) {
//                int offset = bytesPerPixel*((w*y)+x);
//                data[offset] = buffer[offset];     // R
//                data[offset+1] = buffer[offset+1]; // G
//                data[offset+2] = buffer[offset+2]; // B
//                data[offset+3] = buffer[offset+3]; // A
//            }
//        }
//    }
//    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
//    
//    UIGraphicsEndImageContext();
//    return img;
    return nil;
}
#pragma mark dealloc
- (void)dealloc{
    NSLog(@"%s",__func__);
}
@end
