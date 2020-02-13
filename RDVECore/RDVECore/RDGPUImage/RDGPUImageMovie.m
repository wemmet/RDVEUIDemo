#import "RDGPUImageMovie.h"
#import "RDGPUImageMovieWriter.h"
#import "RDGPUImageFilter.h"
#import "RDGPUImageColorConversion.h"


@interface RDGPUImageMovie () <AVPlayerItemOutputPullDelegate,RDVideoRendererDelegate>
{
    BOOL audioEncodingIsFinished, videoEncodingIsFinished;
    RDGPUImageMovieWriter *synchronizedMovieWriter;
    AVAssetReader *reader;
    AVPlayerItemVideoOutput *playerItemOutput;
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    CADisplayLink *displayLink;
#else
    CVDisplayLinkRef displayLink;
#endif
    CMTime previousFrameTime, processingFrameTime;
    CFAbsoluteTime previousActualFrameTime;
    BOOL keepLooping;

    GLuint luminanceTexture, chrominanceTexture;

    RDGLProgram *yuvConversionProgram;
    GLint yuvConversionPositionAttribute, yuvConversionTextureCoordinateAttribute;
    GLint yuvConversionLuminanceTextureUniform, yuvConversionChrominanceTextureUniform;
    GLint yuvConversionMatrixUniform;
    const GLfloat *_preferredConversion;
    
    BOOL isFullYUVRange;

    int imageBufferWidth, imageBufferHeight;
}

- (void)processAsset;

@end

@implementation RDGPUImageMovie

@synthesize url = _url;
@synthesize asset = _asset;
@synthesize runBenchmark = _runBenchmark;
@synthesize playAtActualSpeed = _playAtActualSpeed;
@synthesize delegate = _delegate;
@synthesize shouldRepeat = _shouldRepeat;

#pragma mark -
#pragma mark Initialization and teardown
- (id)initWithComposition:(AVComposition*)compositon
      andVideoComposition:(AVVideoComposition*)videoComposition
              andAudioMix:(AVAudioMix*)audioMix {
    if (!(self = [super init]))
    {
        return nil;
    }
    
    [self yuvConversionSetup];
    
    self.compositon = compositon;
    self.videoComposition = videoComposition;
    self.audioMix = audioMix;
    
    return self;
}
- (id)initWithURL:(NSURL *)url;
{
    if (!(self = [super init])) 
    {
        return nil;
    }

    [self yuvConversionSetup];

    self.url = url;
    self.asset = nil;

    return self;
}

- (id)initWithAsset:(AVAsset *)asset;
{
    if (!(self = [super init])) 
    {
      return nil;
    }
    
    [self yuvConversionSetup];

    self.url = nil;
    self.asset = asset;

    return self;
}

- (id)initWithPlayerItem:(AVPlayerItem *)playerItem;
{
    if (!(self = [super init]))
    {
        return nil;
    }

    [self yuvConversionSetup];

    self.url = nil;
    self.asset = nil;
    self.playerItem = playerItem;

    return self;
}
- (id)initWithVideoRenderer:(RDVideoRenderer *)renderer;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    [self yuvConversionSetup];
    
    self.renderer = renderer;
    _renderer.delegate = self;
    return self;
}
- (void)yuvConversionSetup;
{
    if ([RDGPUImageContext supportsFastTextureUpload])
    {
        rdRunSynchronouslyOnVideoProcessingQueue(^{
            [RDGPUImageContext useImageProcessingContext];

            _preferredConversion = kRDColorConversion709;
            isFullYUVRange       = YES;
            yuvConversionProgram = [[RDGPUImageContext sharedImageProcessingContext] programForVertexShaderString:kRDGPUImageVertexShaderString fragmentShaderString:kRDGPUImageYUVFullRangeConversionForLAFragmentShaderString];

            if (!yuvConversionProgram.initialized)
            {
                [yuvConversionProgram addAttribute:@"position"];
                [yuvConversionProgram addAttribute:@"inputTextureCoordinate"];

                if (![yuvConversionProgram link])
                {
                    NSString *progLog = [yuvConversionProgram programLog];
                    NSLog(@"Program link log: %@", progLog);
                    NSString *fragLog = [yuvConversionProgram fragmentShaderLog];
                    NSLog(@"Fragment shader compile log: %@", fragLog);
                    NSString *vertLog = [yuvConversionProgram vertexShaderLog];
                    NSLog(@"Vertex shader compile log: %@", vertLog);
                    yuvConversionProgram = nil;
                    NSAssert(NO, @"Filter shader link failed");
                }
            }

            yuvConversionPositionAttribute = [yuvConversionProgram attributeIndex:@"position"];
            yuvConversionTextureCoordinateAttribute = [yuvConversionProgram attributeIndex:@"inputTextureCoordinate"];
            yuvConversionLuminanceTextureUniform = [yuvConversionProgram uniformIndex:@"luminanceTexture"];
            yuvConversionChrominanceTextureUniform = [yuvConversionProgram uniformIndex:@"chrominanceTexture"];
            yuvConversionMatrixUniform = [yuvConversionProgram uniformIndex:@"colorConversionMatrix"];

            [RDGPUImageContext setActiveShaderProgram:yuvConversionProgram];

            glEnableVertexAttribArray(yuvConversionPositionAttribute);
            glEnableVertexAttribArray(yuvConversionTextureCoordinateAttribute);
        });
    }
}

- (void)dealloc
{
    _renderer.delegate = nil;
    [playerItemOutput setDelegate:nil queue:nil];
    
    NSLog(@"%s",__func__);

}

#pragma mark -


#pragma mark RendererDelegate
- (void)willOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer time:(CMTime)time{
    
    [self processMovieFrame:pixelBuffer withSampleTime:time];
    
    
    

    
}
/**
 *  读取下一帧
 *
 *  @return 返回还可以读取下一帧
 */
- (BOOL)renderNextFrame {
    AVAssetReaderOutput *readerVideoTrackOutput = nil;
//    AVAssetReaderOutput *readerAudioTrackOutput = nil;
    
    audioEncodingIsFinished = YES;
    for( AVAssetReaderOutput *output in reader.outputs ) {
        if( [output.mediaType isEqualToString:AVMediaTypeAudio] ) {
            audioEncodingIsFinished = NO;
//            readerAudioTrackOutput = output;
        }
        else if( [output.mediaType isEqualToString:AVMediaTypeVideo] ) {
            readerVideoTrackOutput = output;
        }
    }

    __unsafe_unretained typeof(self) weakSelf = self;
    if (reader.status == AVAssetReaderStatusReading && (!_shouldRepeat || keepLooping))
    {
        
        return [weakSelf readNextVideoFrameFromOutput:readerVideoTrackOutput];
    }
    
    if (reader.status == AVAssetWriterStatusCompleted || videoEncodingIsFinished) {
        //NSLog(@"movie: %@ reading is done", self.filterName);
        if(reader){
            [reader cancelReading];
            reader = nil;
        }
        [weakSelf endProcessing];
    }
    return NO;
}

#pragma mark Movie processing

- (void)enableSynchronizedEncodingUsingMovieWriter:(RDGPUImageMovieWriter *)movieWriter;
{
    synchronizedMovieWriter = movieWriter;
    movieWriter.encodingLiveVideo = NO;
}

- (void)startProcessing
{
    if( self.playerItem ) {
        [self processPlayerItem];
        return;
    }
    if(self.url == nil)
    {
      [self processAsset];
      return;
    }
    
    if (_shouldRepeat) keepLooping = YES;
    
    previousFrameTime = kCMTimeZero;
    previousActualFrameTime = CFAbsoluteTimeGetCurrent();
  
    NSDictionary *inputOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *inputAsset = [[AVURLAsset alloc] initWithURL:self.url options:inputOptions];
    
    RDGPUImageMovie __block *blockSelf = self;
    
    [inputAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler: ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *error = nil;
            AVKeyValueStatus tracksStatus = [inputAsset statusOfValueForKey:@"tracks" error:&error];
            if (tracksStatus != AVKeyValueStatusLoaded)
            {
                return;
            }
            blockSelf.asset = inputAsset;
            [blockSelf processAsset];
            blockSelf = nil;
        });
    }];
}

- (AVAssetReader*)createAssetReader
{
    NSError *error = nil;
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:self.asset error:&error];

    NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
    if ([RDGPUImageContext supportsFastTextureUpload]) {
        [outputSettings setObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        isFullYUVRange = YES;
    }
    else {
        [outputSettings setObject:@(kCVPixelFormatType_32BGRA) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        isFullYUVRange = NO;
    }
    
    // Maybe set alwaysCopiesSampleData to NO on iOS 5.0 for faster video decoding
    AVAssetReaderTrackOutput *readerVideoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:[[self.asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] outputSettings:outputSettings];
    readerVideoTrackOutput.alwaysCopiesSampleData = NO;
    [assetReader addOutput:readerVideoTrackOutput];

    NSArray *audioTracks = [self.asset tracksWithMediaType:AVMediaTypeAudio];
    BOOL shouldRecordAudioTrack = (([audioTracks count] > 0) && (self.audioEncodingTarget != nil) );
    AVAssetReaderTrackOutput *readerAudioTrackOutput = nil;

    if (shouldRecordAudioTrack)
    {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
        [self.audioEncodingTarget setShouldInvalidateAudioSampleWhenDone:YES];
#else
#warning Missing OSX implementation
#endif
        
        // This might need to be extended to handle movies with more than one audio track
        AVAssetTrack* audioTrack = [audioTracks objectAtIndex:0];
        readerAudioTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:nil];
        readerAudioTrackOutput.alwaysCopiesSampleData = NO;
        [assetReader addOutput:readerAudioTrackOutput];
    }

    return assetReader;
}


- (AVAssetReader*) createAssetReader_mix{
    
    NSError *error = nil;
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:self.compositon error:&error];
    
    NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
    if ([RDGPUImageContext supportsFastTextureUpload]) {
        [outputSettings setObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        isFullYUVRange = YES;
    }
    else {
        [outputSettings setObject:@(kCVPixelFormatType_32BGRA) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        isFullYUVRange = NO;
    }
    AVAssetReaderVideoCompositionOutput *readerVideoOutput = [AVAssetReaderVideoCompositionOutput assetReaderVideoCompositionOutputWithVideoTracks:[_compositon tracksWithMediaType:AVMediaTypeVideo]
                                                                                                                                     videoSettings:outputSettings];
#if ! TARGET_IPHONE_SIMULATOR
    if( [_videoComposition isKindOfClass:[AVMutableVideoComposition class]] )
        [(AVMutableVideoComposition*)_videoComposition setRenderScale:1.0];
#endif
    readerVideoOutput.videoComposition = self.videoComposition;
    readerVideoOutput.alwaysCopiesSampleData = NO;
    [assetReader addOutput:readerVideoOutput];
    
    NSArray *audioTracks = [_compositon tracksWithMediaType:AVMediaTypeAudio];
    BOOL shouldRecordAudioTrack = (([audioTracks count] > 0) && (self.audioEncodingTarget != nil) );
    AVAssetReaderAudioMixOutput *readerAudioOutput = nil;
    
    if (shouldRecordAudioTrack)
    {
        [self.audioEncodingTarget setShouldInvalidateAudioSampleWhenDone:YES];
        
        NSDictionary* audioSettings = @{
                                        AVFormatIDKey:[NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM]
                                        };
        readerAudioOutput = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:audioTracks audioSettings:audioSettings];
        readerAudioOutput.audioMix = self.audioMix;
        readerAudioOutput.alwaysCopiesSampleData = NO;
        [assetReader addOutput:readerAudioOutput];
    }
    
    return assetReader;

}


- (void)processAsset
{
    
    if (_compositon) {
        reader = [self createAssetReader_mix];
    }else{
        reader = [self createAssetReader];

    }
    

    AVAssetReaderOutput *readerVideoTrackOutput = nil;
    AVAssetReaderOutput *readerAudioTrackOutput = nil;

    audioEncodingIsFinished = YES;
    for( AVAssetReaderOutput *output in reader.outputs ) {
        if( [output.mediaType isEqualToString:AVMediaTypeAudio] ) {
            audioEncodingIsFinished = NO;
            readerAudioTrackOutput = output;
        }
        else if( [output.mediaType isEqualToString:AVMediaTypeVideo] ) {
            readerVideoTrackOutput = output;
        }
    }

    if ([reader startReading] == NO) 
    {
            NSLog(@"Error reading from file at URL: %@", self.url);
        return;
    }

    __unsafe_unretained RDGPUImageMovie *weakSelf = self;

    if (synchronizedMovieWriter != nil)
    {
        [synchronizedMovieWriter setVideoInputReadyCallback:^{
            BOOL success = [weakSelf readNextVideoFrameFromOutput:readerVideoTrackOutput];
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
            return success;
#endif
        }];

        [synchronizedMovieWriter setAudioInputReadyCallback:^{
            BOOL success = [weakSelf readNextAudioSampleFromOutput:readerAudioTrackOutput];
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
            return success;
#endif
        }];
        
        [synchronizedMovieWriter enableSynchronizationCallbacks];

    }
    else
    {
        while (reader.status == AVAssetReaderStatusReading && (!_shouldRepeat || keepLooping))
        {
                [weakSelf readNextVideoFrameFromOutput:readerVideoTrackOutput];

            if ( (readerAudioTrackOutput) && (!audioEncodingIsFinished) )
            {
                    [weakSelf readNextAudioSampleFromOutput:readerAudioTrackOutput];
            }

        }

        if (reader.status == AVAssetReaderStatusCompleted) {
                
            [reader cancelReading];

            if (keepLooping) {
                reader = nil;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self startProcessing];
                });
            } else {
                [weakSelf endProcessing];
            }

        }
    }
}

- (void)processPlayerItem
{
    rdRunSynchronouslyOnVideoProcessingQueue(^{
        
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [displayLink setPaused:YES];
#else
        // Suggested implementation: use CVDisplayLink http://stackoverflow.com/questions/14158743/alternative-of-cadisplaylink-for-mac-os-x
        CGDirectDisplayID   displayID = CGMainDisplayID();
        CVReturn            error = kCVReturnSuccess;
        error = CVDisplayLinkCreateWithCGDisplay(displayID, &displayLink);
        if (error)
        {
            NSLog(@"DisplayLink created with error:%d", error);
            displayLink = NULL;
        }
        CVDisplayLinkSetOutputCallback(displayLink, renderCallback, (__bridge void *)self);
        CVDisplayLinkStop(displayLink);
#endif

        dispatch_queue_t videoProcessingQueue = [RDGPUImageContext sharedContextQueue];
        NSMutableDictionary *pixBuffAttributes = [NSMutableDictionary dictionary];
        if ([RDGPUImageContext supportsFastTextureUpload]) {
            [pixBuffAttributes setObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        }
        else {
            [pixBuffAttributes setObject:@(kCVPixelFormatType_32BGRA) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        }
        playerItemOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBuffAttributes];
        [playerItemOutput setDelegate:self queue:videoProcessingQueue];

        [_playerItem addOutput:playerItemOutput];
        [playerItemOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:0.1];
    });
}

- (void)outputMediaDataWillChange:(AVPlayerItemOutput *)sender
{
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
	// Restart display link.
	[displayLink setPaused:NO];
#else
    CVDisplayLinkStart(displayLink);
#endif
}

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
- (void)displayLinkCallback:(CADisplayLink *)sender
{
	/*
	 The callback gets called once every Vsync.
	 Using the display link's timestamp and duration we can compute the next time the screen will be refreshed, and copy the pixel buffer for that time
	 This pixel buffer can then be processed and later rendered on screen.
	 */
	// Calculate the nextVsync time which is when the screen will be refreshed next.
	CFTimeInterval nextVSync = ([sender timestamp] + [sender duration]);

	CMTime outputItemTime = [playerItemOutput itemTimeForHostTime:nextVSync];

    [self processPixelBufferAtTime:outputItemTime];

}
#else
static CVReturn renderCallback(CVDisplayLinkRef displayLink,
                               const CVTimeStamp *inNow,
                               const CVTimeStamp *inOutputTime,
                               CVOptionFlags flagsIn,
                               CVOptionFlags *flagsOut,
                               void *displayLinkContext)
{
    // Sample code taken from here https://developer.apple.com/library/mac/samplecode/AVGreenScreenPlayer/Listings/AVGreenScreenPlayer_GSPlayerView_m.html
    
    RDGPUImageMovie *self = (__bridge RDGPUImageMovie *)displayLinkContext;
    AVPlayerItemVideoOutput *playerItemOutput = self->playerItemOutput;
    
    
    // The displayLink calls back at every vsync (screen refresh)
    // Compute itemTime for the next vsync
    CMTime outputItemTime = [playerItemOutput itemTimeForCVTimeStamp:*inOutputTime];
    
    [self processPixelBufferAtTime:outputItemTime];
    
    return kCVReturnSuccess;
}
#endif

- (void)processPixelBufferAtTime:(CMTime)outputItemTime {
    NSLog(@"%s %f",__func__,CMTimeGetSeconds(outputItemTime));
    
    if ([playerItemOutput hasNewPixelBufferForItemTime:outputItemTime]) {
        __unsafe_unretained RDGPUImageMovie *weakSelf = self;
        CVPixelBufferRef pixelBuffer = [playerItemOutput copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
        if( pixelBuffer )
            rdRunSynchronouslyOnVideoProcessingQueue(^{
                [weakSelf processMovieFrame:pixelBuffer withSampleTime:outputItemTime];
                CFRelease(pixelBuffer);
            });
    }
}

- (BOOL)readNextVideoFrameFromOutput:(AVAssetReaderOutput *)readerVideoTrackOutput;
{
    if (reader.status == AVAssetReaderStatusReading && ! videoEncodingIsFinished)
    {
        CMSampleBufferRef sampleBufferRef = [readerVideoTrackOutput copyNextSampleBuffer];
        if (sampleBufferRef) 
        {
            if (_playAtActualSpeed)
            {
                // Do this outside of the video processing queue to not slow that down while waiting
                CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBufferRef);
                CMTime differenceFromLastFrame = CMTimeSubtract(currentSampleTime, previousFrameTime);
                CFAbsoluteTime currentActualTime = CFAbsoluteTimeGetCurrent();
                
                CGFloat frameTimeDifference = CMTimeGetSeconds(differenceFromLastFrame);
                CGFloat actualTimeDifference = currentActualTime - previousActualFrameTime;
                
                if (frameTimeDifference > actualTimeDifference)
                {
                    usleep(1000000.0 * (frameTimeDifference - actualTimeDifference));
                }
                
                previousFrameTime = currentSampleTime;
                previousActualFrameTime = CFAbsoluteTimeGetCurrent();
            }

            __unsafe_unretained RDGPUImageMovie *weakSelf = self;
            rdRunSynchronouslyOnVideoProcessingQueue(^{
                [weakSelf processMovieFrame:sampleBufferRef];
                CMSampleBufferInvalidate(sampleBufferRef);
                CFRelease(sampleBufferRef);
            });

            return YES;
        }
        else
        {
            if (!keepLooping) {
                videoEncodingIsFinished = YES;
                if( videoEncodingIsFinished && audioEncodingIsFinished )
                    [self endProcessing];
            }
        }
    }
    else if (synchronizedMovieWriter != nil)
    {
        if (reader.status == AVAssetReaderStatusCompleted)
        {
            [self endProcessing];
        }
    }
    return NO;
}

- (BOOL)readNextAudioSampleFromOutput:(AVAssetReaderOutput *)readerAudioTrackOutput;
{
    if (reader.status == AVAssetReaderStatusReading && ! audioEncodingIsFinished)
    {
        CMSampleBufferRef audioSampleBufferRef = [readerAudioTrackOutput copyNextSampleBuffer];
        if (audioSampleBufferRef)
        {
            [self.audioEncodingTarget processAudioBuffer:audioSampleBufferRef];
            CFRelease(audioSampleBufferRef);
            return YES;
        }
        else
        {
            if (!keepLooping) {
                audioEncodingIsFinished = YES;
                if( videoEncodingIsFinished && audioEncodingIsFinished )
                    [self endProcessing];
            }
        }
    }
    else if (synchronizedMovieWriter != nil)
    {
        if (reader.status == AVAssetReaderStatusCompleted || reader.status == AVAssetReaderStatusFailed ||
            reader.status == AVAssetReaderStatusCancelled)
        {
            [self endProcessing];
        }
    }
    return NO;
}

- (void)processMovieFrame:(CMSampleBufferRef)movieSampleBuffer; 
{
//    CMTimeGetSeconds
//    CMTimeSubtract
    
    CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(movieSampleBuffer);
    CVImageBufferRef movieFrame = CMSampleBufferGetImageBuffer(movieSampleBuffer);

    processingFrameTime = currentSampleTime;
    [self processMovieFrame:movieFrame withSampleTime:currentSampleTime];
}

- (float)progress
{
    if ( AVAssetReaderStatusReading == reader.status )
    {
        float current = processingFrameTime.value * 1.0f / processingFrameTime.timescale;
        float duration = self.asset.duration.value * 1.0f / self.asset.duration.timescale;
        return current / duration;
    }
    else if ( AVAssetReaderStatusCompleted == reader.status )
    {
        return 1.f;
    }
    else
    {
        return 0.f;
    }
}

- (void)processMovieFrame:(CVPixelBufferRef)movieFrame withSampleTime:(CMTime)currentSampleTime
{
    int bufferHeight = (int) CVPixelBufferGetHeight(movieFrame);
    int bufferWidth = (int) CVPixelBufferGetWidth(movieFrame);

    CFTypeRef colorAttachments = CVBufferGetAttachment(movieFrame, kCVImageBufferYCbCrMatrixKey, NULL);
    if (colorAttachments != NULL)
    {
        if(CFStringCompare(colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_601_4, 0) == kCFCompareEqualTo)
        {
            if (isFullYUVRange)
            {
                _preferredConversion = kRDColorConversion601FullRange;
            }
            else
            {
                _preferredConversion = kRDColorConversion601;
            }
        }
        else
        {
            _preferredConversion = kRDColorConversion709;
        }
    }
    else
    {
        if (isFullYUVRange)
        {
            _preferredConversion = kRDColorConversion601FullRange;
        }
        else
        {
            _preferredConversion = kRDColorConversion601;
        }

    }
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();

    // Fix issue 1580
    [RDGPUImageContext useImageProcessingContext];
    
    if ([RDGPUImageContext supportsFastTextureUpload] && colorAttachments)
    {
        
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
        CVOpenGLESTextureRef luminanceTextureRef = NULL;
        CVOpenGLESTextureRef chrominanceTextureRef = NULL;
#else
        CVOpenGLTextureRef luminanceTextureRef = NULL;
        CVOpenGLTextureRef chrominanceTextureRef = NULL;
#endif

        //        if (captureAsYUV && [RDGPUImageContext deviceSupportsRedTextures])
        if (CVPixelBufferGetPlaneCount(movieFrame) > 0) // Check for YUV planar inputs to do RGB conversion
        {
            
            // fix issue 2221
            CVPixelBufferLockBaseAddress(movieFrame,0);
        

            if ( (imageBufferWidth != bufferWidth) && (imageBufferHeight != bufferHeight) )
            {
                imageBufferWidth = bufferWidth;
                imageBufferHeight = bufferHeight;
            }

            CVReturn err;
            // Y-plane
            glActiveTexture(GL_TEXTURE4);
            if ([RDGPUImageContext deviceSupportsRedTextures])
            {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[RDGPUImageContext sharedImageProcessingContext] coreVideoTextureCache], movieFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE, bufferWidth, bufferHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);
#else
                err = CVOpenGLTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[RDGPUImageContext sharedImageProcessingContext] coreVideoTextureCache], movieFrame, NULL, &luminanceTextureRef);
#endif
            }
            else
            {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[RDGPUImageContext sharedImageProcessingContext] coreVideoTextureCache], movieFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE, bufferWidth, bufferHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);
#else
                err = CVOpenGLTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[RDGPUImageContext sharedImageProcessingContext] coreVideoTextureCache], movieFrame, NULL, &luminanceTextureRef);
#endif
            }
            if (err)
            {
                NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            }

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
            luminanceTexture = CVOpenGLESTextureGetName(luminanceTextureRef);
#else
            luminanceTexture = CVOpenGLTextureGetName(luminanceTextureRef);
#endif
            glBindTexture(GL_TEXTURE_2D, luminanceTexture);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

            // UV-plane
            glActiveTexture(GL_TEXTURE5);
            if ([RDGPUImageContext deviceSupportsRedTextures])
            {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[RDGPUImageContext sharedImageProcessingContext] coreVideoTextureCache], movieFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, bufferWidth/2, bufferHeight/2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);
#else
                err = CVOpenGLTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[RDGPUImageContext sharedImageProcessingContext] coreVideoTextureCache], movieFrame, NULL, &chrominanceTextureRef);
#endif
            }
            else
            {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[RDGPUImageContext sharedImageProcessingContext] coreVideoTextureCache], movieFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, bufferWidth/2, bufferHeight/2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);
#else
                err = CVOpenGLTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[RDGPUImageContext sharedImageProcessingContext] coreVideoTextureCache], movieFrame, NULL, &chrominanceTextureRef);
#endif
            }
            if (err)
            {
                NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            }

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
            chrominanceTexture = CVOpenGLESTextureGetName(chrominanceTextureRef);
#else
            chrominanceTexture = CVOpenGLTextureGetName(chrominanceTextureRef);
#endif
            glBindTexture(GL_TEXTURE_2D, chrominanceTexture);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

//            if (!allTargetsWantMonochromeData)
//            {
                [self convertYUVToRGBOutput];
//            }

            for (id<RDGPUImageInput> currentTarget in targets)
            {
                NSInteger indexOfObject = [targets indexOfObject:currentTarget];
                NSInteger targetTextureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
                [currentTarget setInputSize:CGSizeMake(bufferWidth, bufferHeight) atIndex:targetTextureIndex];
                [currentTarget setInputFramebuffer:outputFramebuffer atIndex:targetTextureIndex];
            }
            
            [outputFramebuffer unlock];

            for (id<RDGPUImageInput> currentTarget in targets)
            {
                NSInteger indexOfObject = [targets indexOfObject:currentTarget];
                NSInteger targetTextureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
                [currentTarget newFrameReadyAtTime:currentSampleTime atIndex:targetTextureIndex];
            }

            CVPixelBufferUnlockBaseAddress(movieFrame, 0);
            CFRelease(luminanceTextureRef);
            CFRelease(chrominanceTextureRef);
        }
        else
        {
            // TODO: Mesh this with the new framebuffer cache
//            CVPixelBufferLockBaseAddress(movieFrame, 0);
//
//            CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache, movieFrame, NULL, GL_TEXTURE_2D, GL_RGBA, bufferWidth, bufferHeight, GL_BGRA, GL_UNSIGNED_BYTE, 0, &texture);
//
//            if (!texture || err) {
//                NSLog(@"Movie CVOpenGLESTextureCacheCreateTextureFromImage failed (error: %d)", err);
//                NSAssert(NO, @"Camera failure");
//                return;
//            }
//
//            outputTexture = CVOpenGLESTextureGetName(texture);
//            //        glBindTexture(CVOpenGLESTextureGetTarget(texture), outputTexture);
//            glBindTexture(GL_TEXTURE_2D, outputTexture);
//            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//
//            for (id<RDGPUImageInput> currentTarget in targets)
//            {
//                NSInteger indexOfObject = [targets indexOfObject:currentTarget];
//                NSInteger targetTextureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
//
//                [currentTarget setInputSize:CGSizeMake(bufferWidth, bufferHeight) atIndex:targetTextureIndex];
//                [currentTarget setInputTexture:outputTexture atIndex:targetTextureIndex];
//
//                [currentTarget newFrameReadyAtTime:currentSampleTime atIndex:targetTextureIndex];
//            }
//
//            CVPixelBufferUnlockBaseAddress(movieFrame, 0);
//            CVOpenGLESTextureCacheFlush(coreVideoTextureCache, 0);
//            CFRelease(texture);
//            
//            outputTexture = 0;
        }
    }
    else
    {
        // Upload to texture
        CVPixelBufferLockBaseAddress(movieFrame, 0);
        
        outputFramebuffer = [[RDGPUImageContext sharedFramebufferCache] fetchFramebufferForSize:CGSizeMake(bufferWidth, bufferHeight) textureOptions:self.outputTextureOptions onlyTexture:YES];

        glBindTexture(GL_TEXTURE_2D, [outputFramebuffer texture]);
        // Using BGRA extension to pull in video frame data directly
        glTexImage2D(GL_TEXTURE_2D,
                     0,
                     self.outputTextureOptions.internalFormat,
                     bufferWidth,
                     bufferHeight,
                     0,
                     self.outputTextureOptions.format,
                     self.outputTextureOptions.type,
                     CVPixelBufferGetBaseAddress(movieFrame));
        
        for (id<RDGPUImageInput> currentTarget in targets)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger targetTextureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            [currentTarget setInputSize:CGSizeMake(bufferWidth, bufferHeight) atIndex:targetTextureIndex];
            [currentTarget setInputFramebuffer:outputFramebuffer atIndex:targetTextureIndex];
        }
        
        [outputFramebuffer unlock];
        
        for (id<RDGPUImageInput> currentTarget in targets)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger targetTextureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            [currentTarget newFrameReadyAtTime:currentSampleTime atIndex:targetTextureIndex];
        }
        CVPixelBufferUnlockBaseAddress(movieFrame, 0);
    }
    
    if (_runBenchmark)
    {
        CFAbsoluteTime currentFrameTime = (CFAbsoluteTimeGetCurrent() - startTime);
        NSLog(@"Current frame time : %f ms", 1000.0 * currentFrameTime);
    }
    
    
    if (self.frameProcessingCompletionBlock != NULL)
    {
        self.frameProcessingCompletionBlock(self, currentSampleTime);
    }
    if (self.frameImageProcessingCompletionBlock != NULL)
    {
        self.frameImageProcessingCompletionBlock(self, currentSampleTime);
    }
}

- (void)endProcessing;
{
    keepLooping = NO;
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    [displayLink setPaused:YES];
#else
    CVDisplayLinkStop(displayLink);
#endif

    for (id<RDGPUImageInput> currentTarget in targets)
    {
        [currentTarget endProcessing];
    }
    
    if (synchronizedMovieWriter != nil)
    {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
        [synchronizedMovieWriter setVideoInputReadyCallback:^{return NO;}];
        [synchronizedMovieWriter setAudioInputReadyCallback:^{return NO;}];
#else
        // I'm not sure about this, meybe setting a nil will be more appropriate then an empty block
        [synchronizedMovieWriter setVideoInputReadyCallback:^{}];
        [synchronizedMovieWriter setAudioInputReadyCallback:^{}];
#endif
    }
    
    if (self.playerItem && (displayLink != nil))
    {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
        [displayLink invalidate]; // remove from all run loops
        displayLink = nil;
#else
        CVDisplayLinkStop(displayLink);
        displayLink = NULL;
#endif
    }

    if ([self.delegate respondsToSelector:@selector(didCompletePlayingMovie)]) {
        [self.delegate didCompletePlayingMovie];
    }
    self.delegate = nil;
}

- (void)cancelProcessing
{
    if (reader) {
        [reader cancelReading];
    }
    [self endProcessing];
}

- (void)convertYUVToRGBOutput
{
    [RDGPUImageContext setActiveShaderProgram:yuvConversionProgram];
    outputFramebuffer = [[RDGPUImageContext sharedFramebufferCache] fetchFramebufferForSize:CGSizeMake(imageBufferWidth, imageBufferHeight) onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };

    static const GLfloat textureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };

	glActiveTexture(GL_TEXTURE4);
	glBindTexture(GL_TEXTURE_2D, luminanceTexture);
	glUniform1i(yuvConversionLuminanceTextureUniform, 4);

    glActiveTexture(GL_TEXTURE5);
	glBindTexture(GL_TEXTURE_2D, chrominanceTexture);
	glUniform1i(yuvConversionChrominanceTextureUniform, 5);

    glUniformMatrix3fv(yuvConversionMatrixUniform, 1, GL_FALSE, _preferredConversion);

    glVertexAttribPointer(yuvConversionPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
	glVertexAttribPointer(yuvConversionTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    
}

- (AVAssetReader*)assetReader {
    return reader;
}

- (BOOL)audioEncodingIsFinished {
    return audioEncodingIsFinished;
}

- (BOOL)videoEncodingIsFinished {
    return videoEncodingIsFinished;
}

@end
