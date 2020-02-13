#import "RDGPUImageMovieWriter.h"

#import "RDGPUImageContext.h"
#import "RDGLProgram.h"
#import "RDGPUImageFilter.h"

NSString *const kRDGPUImageColorSwizzlingFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate).bgra;
 }
);

typedef void (^ RecordFinishBlock)();

@interface RDGPUImageMovieWriter ()
{
    GLuint movieFramebuffer, movieRenderbuffer;
    
    RDGLProgram *colorSwizzlingProgram;
    GLint colorSwizzlingPositionAttribute, colorSwizzlingTextureCoordinateAttribute;
    GLint colorSwizzlingInputTextureUniform;

    RDGPUImageFramebuffer *firstInputFramebuffer;
    
    BOOL discont;
    CMTime startTime, previousFrameTime, previousAudioTime;
    CMTime offsetTime;
    
    dispatch_queue_t audioQueue, videoQueue;
    BOOL audioEncodingIsFinished, videoEncodingIsFinished;

    RecordFinishBlock recordFinishBlock;
}

// Movie recording
- (void)initializeMovieWithOutputSettings:(NSMutableDictionary *)outputSettings;

// Frame rendering
- (void)createDataFBO;
- (void)destroyDataFBO;
- (void)setFilterFBO;

- (void)renderAtInternalSizeUsingFramebuffer:(RDGPUImageFramebuffer *)inputFramebufferToUse;

@end

@implementation RDGPUImageMovieWriter

@synthesize hasAudioTrack = _hasAudioTrack;
@synthesize encodingLiveVideo = _encodingLiveVideo;
@synthesize shouldPassthroughAudio = _shouldPassthroughAudio;
@synthesize completionBlock;
@synthesize failureBlock;
@synthesize videoInputReadyCallback;
@synthesize audioInputReadyCallback;
@synthesize enabled;
@synthesize shouldInvalidateAudioSampleWhenDone = _shouldInvalidateAudioSampleWhenDone;
@synthesize paused = _paused;
@synthesize movieWriterContext = _movieWriterContext;
@synthesize delegate = _delegate;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithMovieURL:(NSURL *)newMovieURL size:(CGSize)newSize;
{
    return [self initWithMovieURL:newMovieURL size:newSize fileType:AVFileTypeQuickTimeMovie outputSettings:nil];
}

- (id)initWithMovieURL:(NSURL *)newMovieURL size:(CGSize)newSize fileType:(NSString *)newFileType outputSettings:(NSMutableDictionary *)outputSettings;
{
    if (!(self = [super init]))
    {
		return nil;
    }

    _shouldInvalidateAudioSampleWhenDone = NO;
    
    self.enabled = YES;
    alreadyFinishedRecording = NO;
    videoEncodingIsFinished = NO;
    audioEncodingIsFinished = NO;

    discont = NO;
    videoSize = newSize;
    movieURL = newMovieURL;
    fileType = newFileType;
    startTime = kCMTimeInvalid;
    _encodingLiveVideo = [[outputSettings objectForKey:@"EncodingLiveVideo"] isKindOfClass:[NSNumber class]] ? [[outputSettings objectForKey:@"EncodingLiveVideo"] boolValue] : YES;
    previousFrameTime = kCMTimeNegativeInfinity;
    previousAudioTime = kCMTimeNegativeInfinity;
    inputRotation = kRDGPUImageNoRotation;

    
    //_movieWriterContext = [[RDGPUImageContext alloc] init];
//    [_movieWriterContext useSharegroup:[[[RDGPUImageContext sharedImageProcessingContext] context] sharegroup]];
//
    _movieWriterContext = [RDGPUImageContext sharedImageProcessingContext];
    rdRunSynchronouslyOnContextQueue(_movieWriterContext, ^{
        [_movieWriterContext useAsCurrentContext];
        
        if ([RDGPUImageContext supportsFastTextureUpload])
        {
            colorSwizzlingProgram = [_movieWriterContext programForVertexShaderString:kRDGPUImageVertexShaderString fragmentShaderString:kRDGPUImagePassthroughFragmentShaderString];
        }
        else
        {
            colorSwizzlingProgram = [_movieWriterContext programForVertexShaderString:kRDGPUImageVertexShaderString fragmentShaderString:kRDGPUImageColorSwizzlingFragmentShaderString];
        }
        
        if (!colorSwizzlingProgram.initialized)
        {
            [colorSwizzlingProgram addAttribute:@"position"];
            [colorSwizzlingProgram addAttribute:@"inputTextureCoordinate"];
            
            if (![colorSwizzlingProgram link])
            {
                NSString *progLog = [colorSwizzlingProgram programLog];
                NSLog(@"Program link log: %@", progLog);
                NSString *fragLog = [colorSwizzlingProgram fragmentShaderLog];
                NSLog(@"Fragment shader compile log: %@", fragLog);
                NSString *vertLog = [colorSwizzlingProgram vertexShaderLog];
                NSLog(@"Vertex shader compile log: %@", vertLog);
                colorSwizzlingProgram = nil;
                NSAssert(NO, @"Filter shader link failed");
            }
        }        
        
        colorSwizzlingPositionAttribute = [colorSwizzlingProgram attributeIndex:@"position"];
        colorSwizzlingTextureCoordinateAttribute = [colorSwizzlingProgram attributeIndex:@"inputTextureCoordinate"];
        colorSwizzlingInputTextureUniform = [colorSwizzlingProgram uniformIndex:@"inputImageTexture"];
        
        [_movieWriterContext setContextShaderProgram:colorSwizzlingProgram];
        
        glEnableVertexAttribArray(colorSwizzlingPositionAttribute);
        glEnableVertexAttribArray(colorSwizzlingTextureCoordinateAttribute);
    });
        
    [self initializeMovieWithOutputSettings:outputSettings];

    return self;
}

- (void)dealloc;
{
    
    NSLog(@"%s",__func__);
    [self destroyDataFBO];

#if !OS_OBJECT_USE_OBJC
    if( audioQueue != NULL )
    {
        dispatch_release(audioQueue);
    }
    if( videoQueue != NULL )
    {
        dispatch_release(videoQueue);
    }
#endif
}

#pragma mark -
#pragma mark Movie recording
#define VIDEO_TIMESCALE 600 //NSEC_PER_SEC//(iPhone4s ? 15 : 24)

- (void)initializeMovieWithOutputSettings:(NSDictionary *)outputSettings;
{
    _isRecording = NO;
    
    self.enabled = YES;
    NSError *error = nil;
    assetWriter = [[AVAssetWriter alloc] initWithURL:movieURL fileType:fileType error:&error];
    if (error != nil)
    {
        NSLog(@"Error: %@", error);
        if (failureBlock) 
        {
            failureBlock(error);
        }
        else 
        {
            if(self.delegate && [self.delegate respondsToSelector:@selector(movieRecordingFailedWithError:)])
            {
                [self.delegate movieRecordingFailedWithError:error];
            }
        }
    }
    
    // Set this to make sure that a functional movie is produced, even if the recording is cut off mid-stream. Only the last second should be lost in that case.
    assetWriter.movieFragmentInterval = CMTimeMakeWithSeconds(1, VIDEO_TIMESCALE);//kCMTimeInvalid;//
    //20170515 emmet
    assetWriter.movieTimeScale = VIDEO_TIMESCALE;

    // use default output settings if none specified
    if (outputSettings == nil) 
    {
        NSMutableDictionary *settings = [[NSMutableDictionary alloc] init];
        [settings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
        [settings setObject:[NSNumber numberWithInt:videoSize.width] forKey:AVVideoWidthKey];
        [settings setObject:[NSNumber numberWithInt:videoSize.height] forKey:AVVideoHeightKey];
        outputSettings = settings;
    }
    // custom output settings specified
    else 
    {
		__unused NSString *videoCodec = [outputSettings objectForKey:AVVideoCodecKey];
		__unused NSNumber *width = [outputSettings objectForKey:AVVideoWidthKey];
		__unused NSNumber *height = [outputSettings objectForKey:AVVideoHeightKey];
		
		NSAssert(videoCodec && width && height, @"OutputSettings is missing required parameters.");
        
        if( [outputSettings objectForKey:@"EncodingLiveVideo"] ) {
            NSMutableDictionary *tmp = [outputSettings mutableCopy];
            [tmp removeObjectForKey:@"EncodingLiveVideo"];
            outputSettings = tmp;
        }
    }
    
    /*
    NSDictionary *videoCleanApertureSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSNumber numberWithInt:videoSize.width], AVVideoCleanApertureWidthKey,
                                                [NSNumber numberWithInt:videoSize.height], AVVideoCleanApertureHeightKey,
                                                [NSNumber numberWithInt:0], AVVideoCleanApertureHorizontalOffsetKey,
                                                [NSNumber numberWithInt:0], AVVideoCleanApertureVerticalOffsetKey,
                                                nil];

    NSDictionary *videoAspectRatioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithInt:3], AVVideoPixelAspectRatioHorizontalSpacingKey,
                                              [NSNumber numberWithInt:3], AVVideoPixelAspectRatioVerticalSpacingKey,
                                              nil];

    NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] init];
    [compressionProperties setObject:videoCleanApertureSettings forKey:AVVideoCleanApertureKey];
    [compressionProperties setObject:videoAspectRatioSettings forKey:AVVideoPixelAspectRatioKey];
    [compressionProperties setObject:[NSNumber numberWithInt: 2000000] forKey:AVVideoAverageBitRateKey];
    [compressionProperties setObject:[NSNumber numberWithInt: 16] forKey:AVVideoMaxKeyFrameIntervalKey];
    [compressionProperties setObject:AVVideoProfileLevelH264Main31 forKey:AVVideoProfileLevelKey];
    
    [outputSettings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
    */
     
    assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
    assetWriterVideoInput.expectsMediaDataInRealTime = _encodingLiveVideo;
    assetWriterVideoInput.mediaTimeScale = VIDEO_TIMESCALE;
    // You need to use BGRA for the video in order to get realtime encoding. I use a color-swizzling shader to line up glReadPixels' normal RGBA output with the movie input's BGRA.
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,
                                                           [NSNumber numberWithInt:videoSize.width], kCVPixelBufferWidthKey,
                                                           [NSNumber numberWithInt:videoSize.height], kCVPixelBufferHeightKey,
                                                           nil];
//    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey,
//                                                           nil];
        
    assetWriterPixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:assetWriterVideoInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    [assetWriter addInput:assetWriterVideoInput];
}

- (void)setEncodingLiveVideo:(BOOL) value
{
    _encodingLiveVideo = value;
    if (_isRecording) {
        NSAssert(NO, @"Can not change Encoding Live Video while recording");
    }
    else
    {
        @try {
            assetWriterVideoInput.expectsMediaDataInRealTime = _encodingLiveVideo;
            assetWriterAudioInput.expectsMediaDataInRealTime = _encodingLiveVideo;
        } @catch (NSException *exception) {
            
        } @finally {
        }
    }
}

- (void)startRecording;
{
    
    
    if (assetWriter.status != AVAssetWriterStatusCompleted && assetWriter.status != AVAssetWriterStatusWriting) {
        alreadyFinishedRecording = NO;
        startTime = kCMTimeInvalid;
        rdRunSynchronouslyOnContextQueue(_movieWriterContext, ^{
            if (audioInputReadyCallback == NULL && assetWriter.status != AVAssetWriterStatusWriting)
            {
                [assetWriter startWriting];
            }
        });
        _isRecording = YES;
        
    }else{
        if (_delegate) {
            if ([_delegate respondsToSelector:@selector(movieRecordingCancelType:)]) {
                [_delegate movieRecordingCancelType:1];
            }
        }
    }
    
//    alreadyFinishedRecording = NO;
//    startTime = kCMTimeInvalid;
//    rdRunSynchronouslyOnContextQueue(_movieWriterContext, ^{
//        if (audioInputReadyCallback == NULL)
//        {
//            if(assetWriter.status != AVAssetWriterStatusWriting){
//               isRecording = [assetWriter startWriting];
//            }
//        }
//    });
    
    //20170617 emmet
    //isRecording = YES;
	//    [assetWriter startSessionAtSourceTime:kCMTimeZero];
}

- (void)startRecordingInOrientation:(CGAffineTransform)orientationTransform;
{
	assetWriterVideoInput.transform = orientationTransform;

	[self startRecording];
}

- (void)cancelRecording;
{
    if (assetWriter.status == AVAssetWriterStatusCompleted)
    {
        return;
    }
    
    _isRecording = NO;
    rdRunSynchronouslyOnContextQueue(_movieWriterContext, ^{
        alreadyFinishedRecording = YES;

        if( assetWriter.status == AVAssetWriterStatusWriting && ! videoEncodingIsFinished )
        {
            videoEncodingIsFinished = YES;
            [assetWriterVideoInput markAsFinished];
        }
        if( assetWriter.status == AVAssetWriterStatusWriting && ! audioEncodingIsFinished )
        {
            audioEncodingIsFinished = YES;
            [assetWriterAudioInput markAsFinished];
        }
        [assetWriter cancelWriting];
    });
}

- (void)finishRecording;
{
    [self finishRecordingWithCompletionHandler:NULL];
}

- (void)finishRecordingWithCompletionHandler:(void (^)(void))handler;
{
    recordFinishBlock = handler;
    rdRunSynchronouslyOnContextQueue(_movieWriterContext, ^{
        _isRecording = NO;
        
        if (assetWriter.status == AVAssetWriterStatusCompleted || assetWriter.status == AVAssetWriterStatusCancelled || assetWriter.status == AVAssetWriterStatusUnknown)
        {
            if (handler)
                rdRunAsynchronouslyOnContextQueue(_movieWriterContext, handler);
            return;
        }
#if 0 //20180418 录制时，总会出现音频比视频短的情况，为解决这个问题，结束录制先只结束视频(markAsFinished)，音频录制到与视频最后一帧时间戳一致时再结束(markAsFinished)
        if( assetWriter.status == AVAssetWriterStatusWriting && ! videoEncodingIsFinished )
        {
            NSLog(@"assetWriterVideoInput markAsFinished");
            videoEncodingIsFinished = YES;
            [assetWriterVideoInput markAsFinished];
        }
        if( assetWriter.status == AVAssetWriterStatusWriting && ! audioEncodingIsFinished )
        {
            NSLog(@"assetWriterAudioInput markAsFinished");
            audioEncodingIsFinished = YES;
            [assetWriterAudioInput markAsFinished];
        }
#if (!defined(__IPHONE_6_0) || (__IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_6_0))
        // Not iOS 6 SDK
        [assetWriter finishWriting];
        if (handler)
            rdRunAsynchronouslyOnContextQueue(_movieWriterContext,handler);
#else
        // iOS 6 SDK
        if ([assetWriter respondsToSelector:@selector(finishWritingWithCompletionHandler:)]) {
            // Running iOS 6
            [assetWriter finishWritingWithCompletionHandler:(handler ?: ^{ })];
        }
        else {
            // Not running iOS 6
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [assetWriter finishWriting];
#pragma clang diagnostic pop
            if (handler)
                rdRunAsynchronouslyOnContextQueue(_movieWriterContext, handler);
        }
#endif
#else
        if( assetWriter.status == AVAssetWriterStatusWriting && ! videoEncodingIsFinished )
        {
            NSLog(@"assetWriterVideoInput markAsFinished");
            videoEncodingIsFinished = YES;
            [assetWriterVideoInput markAsFinished];
            if (!_hasAudioTrack) {
                if ([assetWriter respondsToSelector:@selector(finishWritingWithCompletionHandler:)]) {
                    // Running iOS 6
                    @try {
                        [assetWriter finishWritingWithCompletionHandler:(recordFinishBlock ?: ^{ })];
                    } @catch (NSException *exception) {
                        NSLog(@"exception:%@",exception);
                    } @finally {
                        
                    }
                }
                else {
                    // Not running iOS 6
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                    [assetWriter finishWriting];
#pragma clang diagnostic pop
                    if (recordFinishBlock)
                        rdRunAsynchronouslyOnContextQueue(_movieWriterContext, recordFinishBlock);
                }
            }
        }
#endif
    });
}

- (void)processAudioBuffer:(CMSampleBufferRef)audioBuffer;
{
    if (!_isRecording || _paused)
    {
#if 0
        return;
#else //20180418 录制时，总会出现音频比视频短的情况，为解决这个问题，结束录制先只结束视频(markAsFinished)，音频录制到与视频最后一帧时间戳一致时再结束(markAsFinished)
        if (videoEncodingIsFinished) {
            CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(audioBuffer);
            if (CMTimeCompare(currentSampleTime, previousFrameTime) == 1 && !audioEncodingIsFinished) {
                if( assetWriter.status == AVAssetWriterStatusWriting && ! audioEncodingIsFinished )
                {
                    NSLog(@"assetWriterAudioInput markAsFinished");
                    audioEncodingIsFinished = YES;
                    [assetWriterAudioInput markAsFinished];
                }
#if (!defined(__IPHONE_6_0) || (__IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_6_0))
                // Not iOS 6 SDK
                [assetWriter finishWriting];
                if (handler)
                    rdRunAsynchronouslyOnContextQueue(_movieWriterContext,handler);
#else
                // iOS 6 SDK
                if ([assetWriter respondsToSelector:@selector(finishWritingWithCompletionHandler:)]) {
                    // Running iOS 6
                    @try {
                        [assetWriter finishWritingWithCompletionHandler:(recordFinishBlock ?: ^{ })];
                    } @catch (NSException *exception) {
                        NSLog(@"exception:%@",exception);
                    } @finally {
                        
                    }
                }
                else {
                    // Not running iOS 6
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                    [assetWriter finishWriting];
#pragma clang diagnostic pop
                    if (recordFinishBlock)
                        rdRunAsynchronouslyOnContextQueue(_movieWriterContext, recordFinishBlock);
                }
#endif
                return;
            }else if (audioEncodingIsFinished) {
                return;
            }
        }
#endif
    }
    if(_encodingLiveVideo == YES){
        if (_hasAudioTrack && CMTIME_IS_VALID(startTime)){
            goto LAB1;
        }else{
            return;
        }
    }else{
        if (_hasAudioTrack){
            goto LAB1;
        }else{
            return;
        }

    }
//    if (_hasAudioTrack && CMTIME_IS_VALID(startTime))
//    if (_hasAudioTrack)
    {
    LAB1:
        CFRetain(audioBuffer);

        CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(audioBuffer);
//        NSLog(@"%s    %f", __func__,CACurrentMediaTime());

        if (CMTIME_IS_INVALID(startTime))
        {
            rdRunSynchronouslyOnContextQueue(_movieWriterContext, ^{
                if ((audioInputReadyCallback == NULL) && (assetWriter.status != AVAssetWriterStatusWriting))
                {
                    [assetWriter startWriting];
                }
                [assetWriter startSessionAtSourceTime:currentSampleTime];
                startTime = currentSampleTime;
            });
        }

        if (!assetWriterAudioInput.readyForMoreMediaData && _encodingLiveVideo)
        {
            NSLog(@"1: Had to drop an audio frame: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentSampleTime)));
            if (_shouldInvalidateAudioSampleWhenDone)
            {
                CMSampleBufferInvalidate(audioBuffer);
            }
            CFRelease(audioBuffer);
            return;
        }
        
        if (discont) {
            discont = NO;
            
            CMTime current;
            if (offsetTime.value > 0) {
                current = CMTimeSubtract(currentSampleTime, offsetTime);
            } else {
                current = currentSampleTime;
            }
            
            CMTime offset = CMTimeSubtract(current, previousAudioTime);
            
            if (offsetTime.value == 0) {
                offsetTime = offset;
            } else {
                offsetTime = CMTimeAdd(offsetTime, offset);
            }
        }
        
        if (offsetTime.value > 0) {
            CFRelease(audioBuffer);
            audioBuffer = [self adjustTime:audioBuffer by:offsetTime];
            CFRetain(audioBuffer);
        }
        
        // record most recent time so we know the length of the pause
        currentSampleTime = CMSampleBufferGetPresentationTimeStamp(audioBuffer);


        
        previousAudioTime = currentSampleTime;
        
        //if the consumer wants to do something with the audio samples before writing, let him.
        if (self.audioProcessingCallback) {
            //need to introspect into the opaque CMBlockBuffer structure to find its raw sample buffers.
            CMBlockBufferRef buffer = CMSampleBufferGetDataBuffer(audioBuffer);
            CMItemCount numSamplesInBuffer = CMSampleBufferGetNumSamples(audioBuffer);
            AudioBufferList audioBufferList;
            
            CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(audioBuffer,
                                                                    NULL,
                                                                    &audioBufferList,
                                                                    sizeof(audioBufferList),
                                                                    NULL,
                                                                    NULL,
                                                                    kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                                                                    &buffer
                                                                    );
            
            //passing a live pointer to the audio buffers, try to process them in-place or we might have syncing issues.
            for (int bufferCount=0; bufferCount < audioBufferList.mNumberBuffers; bufferCount++) {
                SInt16 *samples = (SInt16 *)audioBufferList.mBuffers[bufferCount].mData;
                self.audioProcessingCallback(&samples, numSamplesInBuffer);

            }
        }
        
//        NSLog(@"Recorded audio sample time: %lld, %d, %lld", currentSampleTime.value, currentSampleTime.timescale, currentSampleTime.epoch);
        void(^write)() = ^() {
            while( ! assetWriterAudioInput.readyForMoreMediaData && ! _encodingLiveVideo && ! audioEncodingIsFinished ) {
                NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:0.5];
                //NSLog(@"audio waiting...");
                [[NSRunLoop currentRunLoop] runUntilDate:maxDate];
            }
            if (!assetWriterAudioInput.readyForMoreMediaData)
            {
                NSLog(@"2: Had to drop an audio frame %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentSampleTime)));
            }
            else if(assetWriter.status == AVAssetWriterStatusWriting)
            {
//                NSLog(@"appending audio buffer at time: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentSampleTime)));
                if (![assetWriterAudioInput appendSampleBuffer:audioBuffer])
                    NSLog(@"Problem appending audio buffer at time: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentSampleTime)));
                
            }
            else
            {
                //NSLog(@"Wrote an audio frame %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentSampleTime)));
            }

            if (_shouldInvalidateAudioSampleWhenDone)
            {
                CMSampleBufferInvalidate(audioBuffer);
            }
            CFRelease(audioBuffer);
        };
//        rdRunAsynchronouslyOnContextQueue(_movieWriterContext, write);
        if( _encodingLiveVideo )

        {
            write();//20180417
//            rdRunAsynchronouslyOnContextQueue(_movieWriterContext, write);
        }
        else
        {
            write();
        }
    }
}

- (void)enableSynchronizationCallbacks;
{
    if (videoInputReadyCallback != NULL)
    {
        if( assetWriter.status != AVAssetWriterStatusWriting )
        {
            [assetWriter startWriting];
        }
        __weak typeof(self) weakSelf = self;
        videoQueue = dispatch_queue_create("com.sunsetlakesoftware.RDGPUImage.videoReadingQueue", RDGPUImageDefaultQueueAttribute());
        [assetWriterVideoInput requestMediaDataWhenReadyOnQueue:videoQueue usingBlock:^{
            if( _paused )
            {
                //NSLog(@"video requestMediaDataWhenReadyOnQueue paused");
                // if we don't sleep, we'll get called back almost immediately, chewing up CPU
                usleep(10000);
                return;
            }
            //NSLog(@"video requestMediaDataWhenReadyOnQueue begin");
            while( assetWriterVideoInput.readyForMoreMediaData && ! _paused )
            {
                if( videoInputReadyCallback && ! videoInputReadyCallback() && ! videoEncodingIsFinished )
                {
                    rdRunAsynchronouslyOnContextQueue(_movieWriterContext, ^{
                        if( assetWriter.status == AVAssetWriterStatusWriting && ! videoEncodingIsFinished )
                        {
                            videoEncodingIsFinished = YES;
                            [assetWriterVideoInput markAsFinished];
                            if (!alreadyFinishedRecording && (!_hasAudioTrack || (_hasAudioTrack && audioEncodingIsFinished))) {
                                [weakSelf endProcessing];
                            }
                        }
                    });
                }
            }
            //NSLog(@"video requestMediaDataWhenReadyOnQueue end");
        }];
    }
    
    if (audioInputReadyCallback != NULL)
    {
        __weak typeof(self) weakSelf = self;
        audioQueue = dispatch_queue_create("com.sunsetlakesoftware.RDGPUImage.audioReadingQueue", RDGPUImageDefaultQueueAttribute());
        [assetWriterAudioInput requestMediaDataWhenReadyOnQueue:audioQueue usingBlock:^{
            if( _paused )
            {
                //NSLog(@"audio requestMediaDataWhenReadyOnQueue paused");
                // if we don't sleep, we'll get called back almost immediately, chewing up CPU
                usleep(10000);
                return;
            }
            //NSLog(@"audio requestMediaDataWhenReadyOnQueue begin");
            while( assetWriterAudioInput.readyForMoreMediaData && ! _paused )
            {
                if( audioInputReadyCallback && ! audioInputReadyCallback() && ! audioEncodingIsFinished )
                {
                    rdRunAsynchronouslyOnContextQueue(_movieWriterContext, ^{
                        if( assetWriter.status == AVAssetWriterStatusWriting && ! audioEncodingIsFinished )
                        {
                            audioEncodingIsFinished = YES;
                            [assetWriterAudioInput markAsFinished];
                            if (!alreadyFinishedRecording && videoEncodingIsFinished) {
                                [weakSelf endProcessing];
                            }
                        }
                    });
                }
            }
            //NSLog(@"audio requestMediaDataWhenReadyOnQueue end");
        }];
    }        
    
}

#pragma mark -
#pragma mark Frame rendering

- (void)createDataFBO;
{
    glActiveTexture(GL_TEXTURE1);
    glGenFramebuffers(1, &movieFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, movieFramebuffer);
    
    if ([RDGPUImageContext supportsFastTextureUpload])
    {
        // Code originally sourced from http://allmybrain.com/2011/12/08/rendering-to-a-texture-with-ios-5-texture-cache-api/
        

        CVPixelBufferPoolCreatePixelBuffer (NULL, [assetWriterPixelBufferInput pixelBufferPool], &renderTarget);

        /* AVAssetWriter will use BT.601 conversion matrix for RGB to YCbCr conversion
         * regardless of the kCVImageBufferYCbCrMatrixKey value.
         * Tagging the resulting video file as BT.601, is the best option right now.
         * Creating a proper BT.709 video is not possible at the moment.
         */
        CVBufferSetAttachment(renderTarget, kCVImageBufferColorPrimariesKey, kCVImageBufferColorPrimaries_ITU_R_709_2, kCVAttachmentMode_ShouldPropagate);
        CVBufferSetAttachment(renderTarget, kCVImageBufferYCbCrMatrixKey, kCVImageBufferYCbCrMatrix_ITU_R_601_4, kCVAttachmentMode_ShouldPropagate);
        CVBufferSetAttachment(renderTarget, kCVImageBufferTransferFunctionKey, kCVImageBufferTransferFunction_ITU_R_709_2, kCVAttachmentMode_ShouldPropagate);
        
        CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, [_movieWriterContext coreVideoTextureCache], renderTarget,
                                                      NULL, // texture attributes
                                                      GL_TEXTURE_2D,
                                                      GL_RGBA, // opengl format
                                                      (int)videoSize.width,
                                                      (int)videoSize.height,
                                                      GL_BGRA, // native iOS format
                                                      GL_UNSIGNED_BYTE,
                                                      0,
                                                      &renderTexture);
        
        glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
    }
    else
    {
        glGenRenderbuffers(1, &movieRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, movieRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, (int)videoSize.width, (int)videoSize.height);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, movieRenderbuffer);	
    }
    
	
	__unused GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        //判断不完整  立即结束 准备下一次
        
        if (_delegate) {
            if ([_delegate respondsToSelector:@selector(movieRecordingCancelType:)]) {
                [_delegate movieRecordingCancelType:0];
            }
        }
    }else{
        if (_delegate) {
            if ([_delegate respondsToSelector:@selector(movieRecordingBegin)]) {
                [_delegate movieRecordingBegin];
            }
        }
    }
    
    //NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
}

- (void)destroyDataFBO;
{
    rdRunSynchronouslyOnContextQueue(_movieWriterContext, ^{
        [_movieWriterContext useAsCurrentContext];

        if (movieFramebuffer)
        {
            glDeleteFramebuffers(1, &movieFramebuffer);
            movieFramebuffer = 0;
        }
        
        if (movieRenderbuffer)
        {
            glDeleteRenderbuffers(1, &movieRenderbuffer);
            movieRenderbuffer = 0;
        }
        
        if ([RDGPUImageContext supportsFastTextureUpload])
        {
            if (renderTexture)
            {
                
                CFRelease(renderTexture);
            }
            if (renderTarget)
            {
                CVPixelBufferRelease(renderTarget);
            }
            
        }
    });
}

- (void)setFilterFBO;
{
    if (!movieFramebuffer)
    {
        [self createDataFBO];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, movieFramebuffer);
    
    glViewport(0, 0, (int)videoSize.width, (int)videoSize.height);
}

- (void)renderAtInternalSizeUsingFramebuffer:(RDGPUImageFramebuffer *)inputFramebufferToUse;
{
    [_movieWriterContext useAsCurrentContext];
    [self setFilterFBO];
    
    [_movieWriterContext setContextShaderProgram:colorSwizzlingProgram];
    
    glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // This needs to be flipped to write out to video correctly
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    const GLfloat *textureCoordinates = [RDGPUImageFilter textureCoordinatesForRotation:inputRotation];
    
	glActiveTexture(GL_TEXTURE4);
	glBindTexture(GL_TEXTURE_2D, [inputFramebufferToUse texture]);
	glUniform1i(colorSwizzlingInputTextureUniform, 4);
    
//    NSLog(@"Movie writer framebuffer: %@", inputFramebufferToUse);
    
    glVertexAttribPointer(colorSwizzlingPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
	glVertexAttribPointer(colorSwizzlingTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glFinish();
}

#pragma mark -
#pragma mark RDGPUImageInput protocol

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    if (!_isRecording || _paused)
    {
        [firstInputFramebuffer unlock];
        return;
    }

    if (discont) {
        discont = NO;
        CMTime current;
        
        if (offsetTime.value > 0) {
            current = CMTimeSubtract(frameTime, offsetTime);
        } else {
            current = frameTime;
        }
        
        CMTime offset  = CMTimeSubtract(current, previousFrameTime);
        
        if (offsetTime.value == 0) {
            offsetTime = offset;
        } else {
            offsetTime = CMTimeAdd(offsetTime, offset);
        }
    }
    
    if (offsetTime.value > 0) {
        frameTime = CMTimeSubtract(frameTime, offsetTime);
    }
    
    // Drop frames forced by images and other things with no time constants
    // Also, if two consecutive times with the same value are added to the movie, it aborts recording, so I bail on that case
    if ( (CMTIME_IS_INVALID(frameTime)) || (CMTIME_COMPARE_INLINE(frameTime, ==, previousFrameTime)) || (CMTIME_IS_INDEFINITE(frameTime)) ) 
    {
        [firstInputFramebuffer unlock];
        return;
    }

    if (CMTIME_IS_INVALID(startTime))
    {
//        rdRunSynchronouslyOnContextQueue(_movieWriterContext, ^{//20180418 为了让音频尽快开始录制，故把第一帧的视频写入不放到队列中
            if ((videoInputReadyCallback == NULL) && (assetWriter.status != AVAssetWriterStatusWriting))
            {
                if(assetWriter.status == AVAssetWriterStatusFailed){
                    NSLog(@"assetWriter.error ：%@",assetWriter.error);
                    return;
                }
                [assetWriter startWriting];
            }
            
            [assetWriter startSessionAtSourceTime:frameTime];
            startTime = frameTime;
            NSLog(@"startTime:%f", CMTimeGetSeconds(startTime));
//        });
        {//20180418 为了让音频尽快开始录制，故把第一帧的视频写入不放到队列中
            RDGPUImageFramebuffer *inputFramebufferForBlock = firstInputFramebuffer;
            glFinish();
            
                if (!assetWriterVideoInput.readyForMoreMediaData && _encodingLiveVideo)
                {
                    [inputFramebufferForBlock unlock];
                    NSLog(@"1: Had to drop a video frame: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, frameTime)));
                    return;
                }
                
                // Render the frame with swizzled colors, so that they can be uploaded quickly as BGRA frames
                [_movieWriterContext useAsCurrentContext];
                [self renderAtInternalSizeUsingFramebuffer:inputFramebufferForBlock];
                
                CVPixelBufferRef pixel_buffer = NULL;
                
                if ([RDGPUImageContext supportsFastTextureUpload])
                {
                    pixel_buffer = renderTarget;
                    CVPixelBufferLockBaseAddress(pixel_buffer, 0);
                }
                else
                {
                    CVReturn status = CVPixelBufferPoolCreatePixelBuffer (NULL, [assetWriterPixelBufferInput pixelBufferPool], &pixel_buffer);
                    if ((pixel_buffer == NULL) || (status != kCVReturnSuccess))
                    {
                        CVPixelBufferRelease(pixel_buffer);
                        return;
                    }
                    else
                    {
                        CVPixelBufferLockBaseAddress(pixel_buffer, 0);
                        
                        GLubyte *pixelBufferData = (GLubyte *)CVPixelBufferGetBaseAddress(pixel_buffer);
                        glReadPixels(0, 0, videoSize.width, videoSize.height, GL_RGBA, GL_UNSIGNED_BYTE, pixelBufferData);
                    }
                }
                
            void(^write)(void) = ^() {
                    while( ! assetWriterVideoInput.readyForMoreMediaData && ! _encodingLiveVideo && ! videoEncodingIsFinished ) {
                        NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:0.1];
                        //            NSLog(@"video waiting...");
                        [[NSRunLoop currentRunLoop] runUntilDate:maxDate];
                    }
                    if (!assetWriterVideoInput.readyForMoreMediaData)
                    {
                        NSLog(@"2: Had to drop a video frame: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, frameTime)));
                    }
                    else if(self.assetWriter.status == AVAssetWriterStatusWriting)
                    {
//                        NSLog(@"currentFrameTime:%f", CMTimeGetSeconds(frameTime));
                        if (![assetWriterPixelBufferInput appendPixelBuffer:pixel_buffer withPresentationTime:frameTime])
                            NSLog(@"Problem appending pixel buffer at time: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, frameTime)));
                    }
                    else
                    {
                        NSLog(@"Couldn't write a frame");
                        //NSLog(@"Wrote a video frame: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, frameTime)));
                    }
                    CVPixelBufferUnlockBaseAddress(pixel_buffer, 0);
                    
                    previousFrameTime = frameTime;
                    
                    if (![RDGPUImageContext supportsFastTextureUpload])
                    {
                        CVPixelBufferRelease(pixel_buffer);
                    }
                };
                
                write();
                
                [inputFramebufferForBlock unlock];
            
            return;
        }
    }

    RDGPUImageFramebuffer *inputFramebufferForBlock = firstInputFramebuffer;
    glFinish();

    rdRunAsynchronouslyOnContextQueue(_movieWriterContext, ^{
        if (!assetWriterVideoInput.readyForMoreMediaData && _encodingLiveVideo)
        {
            [inputFramebufferForBlock unlock];
            NSLog(@"1: Had to drop a video frame: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, frameTime)));
            return;
        }
        
        // Render the frame with swizzled colors, so that they can be uploaded quickly as BGRA frames
        [_movieWriterContext useAsCurrentContext];
        [self renderAtInternalSizeUsingFramebuffer:inputFramebufferForBlock];
        
        CVPixelBufferRef pixel_buffer = NULL;
        
        if ([RDGPUImageContext supportsFastTextureUpload])
        {
            pixel_buffer = renderTarget;
            CVPixelBufferLockBaseAddress(pixel_buffer, 0);
        }
        else
        {
            CVReturn status = CVPixelBufferPoolCreatePixelBuffer (NULL, [assetWriterPixelBufferInput pixelBufferPool], &pixel_buffer);
            if ((pixel_buffer == NULL) || (status != kCVReturnSuccess))
            {
                CVPixelBufferRelease(pixel_buffer);
                return;
            }
            else
            {
                CVPixelBufferLockBaseAddress(pixel_buffer, 0);
                
                GLubyte *pixelBufferData = (GLubyte *)CVPixelBufferGetBaseAddress(pixel_buffer);
                glReadPixels(0, 0, videoSize.width, videoSize.height, GL_RGBA, GL_UNSIGNED_BYTE, pixelBufferData);
            }
        }
        
        void(^write)() = ^() {
            while( ! assetWriterVideoInput.readyForMoreMediaData && ! _encodingLiveVideo && ! videoEncodingIsFinished ) {
                NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:0.1];
                //            NSLog(@"video waiting...");
                [[NSRunLoop currentRunLoop] runUntilDate:maxDate];
            }
            if (!assetWriterVideoInput.readyForMoreMediaData)
            {
                NSLog(@"2: Had to drop a video frame: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, frameTime)));
            }
            else if(self.assetWriter.status == AVAssetWriterStatusWriting)
            {
//                NSLog(@"currentFrameTime:%f", CMTimeGetSeconds(frameTime));
                if (![assetWriterPixelBufferInput appendPixelBuffer:pixel_buffer withPresentationTime:frameTime])
                    NSLog(@"Problem appending pixel buffer at time: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, frameTime)));
            }
            else
            {
                NSLog(@"Couldn't write a frame");
                //NSLog(@"Wrote a video frame: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, frameTime)));
            }
            CVPixelBufferUnlockBaseAddress(pixel_buffer, 0);
            
            previousFrameTime = frameTime;
            
            if (![RDGPUImageContext supportsFastTextureUpload])
            {
                CVPixelBufferRelease(pixel_buffer);
            }
        };
        
        write();
        
        [inputFramebufferForBlock unlock];
    });
}

- (NSInteger)nextAvailableTextureIndex;
{
    return 0;
}

- (void)setInputFramebuffer:(RDGPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
{
    [newInputFramebuffer lock];
//    rdRunSynchronouslyOnContextQueue(_movieWriterContext, ^{
        firstInputFramebuffer = newInputFramebuffer;
//    });
}

- (void)setInputRotation:(RDGPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
    inputRotation = newInputRotation;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
}

- (CGSize)maximumOutputSize;
{
    return videoSize;
}

- (void)endProcessing 
{
    NSLog(@"record duration:%f", CMTimeGetSeconds(CMTimeSubtract(previousFrameTime, startTime)));
    if (videoEncodingIsFinished && audioEncodingIsFinished) {//[assetWriterVideoInput markAsFinished]后再返回回调
        if (completionBlock)
        {
            if (!alreadyFinishedRecording)
            {
                alreadyFinishedRecording = YES;
                completionBlock();
            }
        }
        else
        {
            if (_delegate && [_delegate respondsToSelector:@selector(movieRecordingCompleted)])
            {
                [_delegate movieRecordingCompleted];
            }
        }
    }
}

- (BOOL)shouldIgnoreUpdatesToThisTarget;
{
    return NO;
}

- (BOOL)wantsMonochromeInput;
{
    return NO;
}

- (void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue;
{
    
}

#pragma mark -
#pragma mark Accessors

- (void)setHasAudioTrack:(BOOL)newValue
{
	[self setHasAudioTrack:newValue audioSettings:nil];
}

- (void)setHasAudioTrack:(BOOL)newValue audioSettings:(NSDictionary *)audioOutputSettings;
{
    _hasAudioTrack = newValue;
    
    if (_hasAudioTrack)
    {
        if (_shouldPassthroughAudio)
        {
			// Do not set any settings so audio will be the same as passthrough
			audioOutputSettings = nil;
        }
        else if (audioOutputSettings == nil)
        {
#if 0
            AVAudioSession *sharedAudioSession = [AVAudioSession sharedInstance];
            double preferredHardwareSampleRate;
            
            if ([sharedAudioSession respondsToSelector:@selector(sampleRate)])
            {
                preferredHardwareSampleRate = [sharedAudioSession sampleRate];
                /*
                 Float64 sampleRate;
                 UInt32 propSize = sizeof(Float64);
                 AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate,
                                        &propSize,
                                        &sampleRate);
                 preferredHardwareSampleRate = sampleRate;
                 */
            }
            else
            {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                preferredHardwareSampleRate = [sharedAudioSession currentHardwareSampleRate];
                /*
                 Float64 sampleRate;
                 UInt32 propSize = sizeof(Float64);
                 AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate,
                 &propSize,
                 &sampleRate);
                 preferredHardwareSampleRate = sampleRate;
                 */
                
#pragma clang diagnostic pop
            }
            if(preferredHardwareSampleRate == 0.0){
                preferredHardwareSampleRate = 44100.0;
            }
            //ios11.0系统的设备通过 currentHardwareSampleRate 获取设备的采样率不准确
            if([[[UIDevice currentDevice] systemVersion] floatValue]>=11.0){
                preferredHardwareSampleRate = 44100.0;
            }
#else   //20171019 wuxiaoxia 录制前播放了视频后，通过[sharedAudioSession currentHardwareSampleRate]获取到的采样率会是之前播放的视频的采样率，导到不能录制，因此固定设为44100
            double preferredHardwareSampleRate = 44100.0;
#endif
            AudioChannelLayout acl;
            bzero( &acl, sizeof(acl));
//            acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
            acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
            
            audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                         [ NSNumber numberWithInt: 2 ], AVNumberOfChannelsKey,
                                         [ NSNumber numberWithFloat: preferredHardwareSampleRate ], AVSampleRateKey,
                                         [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                                         //[ NSNumber numberWithInt:AVAudioQualityLow], AVEncoderAudioQualityKey,
                                         [ NSNumber numberWithInt: 128000 ], AVEncoderBitRateKey,
                                         nil];
/*
            AudioChannelLayout acl;
            bzero( &acl, sizeof(acl));
            acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
            
            audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [ NSNumber numberWithInt: kAudioFormatMPEG4AAC ], AVFormatIDKey,
                                   [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
                                   [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
                                   [ NSNumber numberWithInt: 64000 ], AVEncoderBitRateKey,
                                   [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                                   nil];*/
        }
        
        assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
        if([assetWriter canAddInput:assetWriterAudioInput]){
            [assetWriter addInput:assetWriterAudioInput];
            
        }
        assetWriterAudioInput.expectsMediaDataInRealTime = _encodingLiveVideo;
    }
    else
    {
        // Remove audio track if it exists
    }
}

- (NSArray*)metaData {
    return assetWriter.metadata;
}

- (void)setMetaData:(NSArray*)metaData {
    assetWriter.metadata = metaData;
}
 
- (CMTime)duration {
    if( ! CMTIME_IS_VALID(startTime) )
        return kCMTimeZero;
    if( ! CMTIME_IS_NEGATIVE_INFINITY(previousFrameTime) )
        return CMTimeSubtract(previousFrameTime, startTime);
    if( ! CMTIME_IS_NEGATIVE_INFINITY(previousAudioTime) )
        return CMTimeSubtract(previousAudioTime, startTime);
    return kCMTimeZero;
}

- (CGAffineTransform)transform {
    return assetWriterVideoInput.transform;
}

- (void)setTransform:(CGAffineTransform)transform {
    assetWriterVideoInput.transform = transform;
}

- (AVAssetWriter*)assetWriter {
    return assetWriter;
}

- (void)setPaused:(BOOL)newValue {
    if (_paused != newValue) {
        _paused = newValue;
        
        if (_paused) {
            discont = YES;
        }
    }
}

- (CMSampleBufferRef)adjustTime:(CMSampleBufferRef) sample by:(CMTime) offset {
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo* pInfo = (CMSampleTimingInfo*)malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    
    for (CMItemCount i = 0; i < count; i++) {
        pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
    }
    
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    
    return sout;
}

@end
