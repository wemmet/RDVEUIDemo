
// #import "RDPlayer.h"
#import "PPMovie.h"
#import "RDGPUImageFilter.h"
#import "RDGPUImageVideoCamera.h"
#import "PPMovieManager.h"
#import "RDTPCircularBuffer+AudioBufferList.h"

#define kOutputBus 0 //0 的时候发音 1的时候录音？
#define  AUDIOSAMPLERATE 44100 //音频采样率
#define sizeForSeconds(seconds) sizeof(float) * 44100 * seconds //缓存音频

RDTPCircularBuffer tpCircularBuffer1;

Float64 audioSampleTime;

BOOL gfullCircularBuffer;

void checkAudioStatus(int status);

static OSStatus playbackCallback(void                       *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp       *inTimeStamp,
                                 UInt32                     inBusNumber,
                                 UInt32                     inNumberFrames,
                                 AudioBufferList            *ioData);

void checkAudioStatus(int status)
{
    if (status)
    {
        printf("Status not 0! %d\n", status);
        //		exit(1);
    }
}
#if 1
static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData)
{
    
    UInt32 ioLengthInFrames = inNumberFrames;
    
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate			= AUDIOSAMPLERATE/*emmet20161125 44100.00*/;
    audioFormat.mFormatID			= kAudioFormatLinearPCM;
    audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioFormat.mFramesPerPacket	= 1;
    audioFormat.mChannelsPerFrame	= 2;
    audioFormat.mBitsPerChannel		= 16;
    audioFormat.mBytesPerPacket		= 4;
    audioFormat.mBytesPerFrame		= 4;
    
    AudioTimeStamp outTimestamp;
    
    UInt32 retVal = RDTPCircularBufferPeek(&tpCircularBuffer1, &outTimestamp, &audioFormat);
    if (audioSampleTime==0) {
        audioSampleTime=inTimeStamp->mSampleTime;
    }
#if 0
    NSLog (@"audio frame:%.3f",(inTimeStamp->mSampleTime-audioSampleTime)/AUDIOSAMPLERATE);
    currentTime=CMTimeMakeWithSeconds((inTimeStamp->mSampleTime-audioSampleTime)/AUDIOSAMPLERATE, 24);
    NSLog (@"retVal:%.3f",inNumberFrames/AUDIOSAMPLERATE);
#endif
    if (retVal <= 1024*10)
    {
        gfullCircularBuffer=NO;
    }
    if (retVal > 0)
    {
        RDTPCircularBufferDequeueBufferListFrames(&tpCircularBuffer1,
                                                &ioLengthInFrames,
                                                ioData,
                                                &outTimestamp,
                                                &audioFormat);
    }
    if (retVal==0)
    {
        return 1 ;
    }
    
    
    return noErr;
}
#else



#endif
@interface PPMovie () <AVPlayerItemOutputPullDelegate>
{
    
    AVAssetReaderVideoCompositionOutput *readerVideoOutput;
    AVAssetReaderAudioMixOutput *readerAudioOutput;//20161209
    
    BOOL audioEncodingIsFinished, videoEncodingIsFinished;
    BOOL copyNextSampleBufferFinish;
    RDGPUImageMovieWriter *synchronizedMovieWriter;
    //AVAssetReader *reader;
    AVAssetReader *seekReader;
    AVAssetReader *_playReader;
    AVPlayerItemVideoOutput *playerItemOutput;

    CADisplayLink *displayLink;
    CMTime previousFrameTime, processingFrameTime,audioPreviousTime;
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
    
    AVAssetReaderOutput *readerVideoTrackOutput;
    
    AVAssetReaderOutput *seekReaderVideoTrackOutput;
    
    AudioComponentInstance     audioUnit;
//    RDTPCircularBuffer tpCircularBuffer1;
//    
//    Float64 audioSampleTime;
//    
//    BOOL gfullCircularBuffer;
    
    
    BOOL                       bOver;
    BOOL                       isPlaying;
    BOOL                       bPaused;
    NSLock                      *readerLock;//解决mv滤镜切换时崩溃的bug
    CMTimeRange                readerTimeRange;
    CMTimeRange                totalTimeRange;
    CMTimeRange                stopTimeRange;
    
    CMTime                     currentTime;
    CMTime                     lastSeekTime;
    float syncTime;  // 画面同步时间
    BOOL seekDone;
    dispatch_queue_t syncQueue;
    dispatch_semaphore_t seekSemaphore;
    
}

- (void)processAsset;

@end

@implementation PPMovie

@synthesize url = _url;
@synthesize asset = _asset;
@synthesize runBenchmark = _runBenchmark;
@synthesize playAtActualSpeed = _playAtActualSpeed;
@synthesize delegate = _delegate;
@synthesize shouldRepeat = _shouldRepeat;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithURL:(NSURL *)url;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    [self yuvConversionSetup];
    
    self.url = url;
    self.asset = nil;
    self.isCall = NO;
    self.videoCopyNextSampleBufferFinish = TRUE;
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
    self.isCall = NO;
    self.videoCopyNextSampleBufferFinish = TRUE;
    syncQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    seekSemaphore = dispatch_semaphore_create(0);
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

    
    self.isCall = NO;

//    [self initAudio];
    
    readerLock = [[NSLock alloc]init];
    
    // add
    stopTimeRange   = kCMTimeRangeInvalid;
    readerTimeRange = kCMTimeRangeInvalid;
    totalTimeRange  = kCMTimeRangeInvalid;
    currentTime     = kCMTimeZero;
    seekDone        = YES;
    self.videoCopyNextSampleBufferFinish = TRUE;

    
    return self;
}

- (id)initWithComposition:(AVComposition*)compositon
      andVideoComposition:(AVVideoComposition*)videoComposition
              andAudioMix:(AVAudioMix*)audioMix{
    if (!(self = [super init]))
    {
        return nil;
    }
    lastSeekTime = kCMTimeZero;
    _audioSampleRate = 0;
    [self yuvConversionSetup];
    
    self.compositon       = compositon;
    self.videoComposition = videoComposition;
    self.audioMix         = audioMix;
    self.videoCopyNextSampleBufferFinish = TRUE;
    
    
//    [self initAudio];
    
    readerLock = [[NSLock alloc]init];
    self.isCall = NO;

    // add
    stopTimeRange   = kCMTimeRangeInvalid;
    readerTimeRange = kCMTimeRangeInvalid;
    totalTimeRange  = kCMTimeRangeInvalid;
    currentTime     = kCMTimeZero;
    seekDone        = YES;
    
    return self;
}

- (id)initWithComposition:(AVComposition*)compositon
      andVideoComposition:(AVVideoComposition*)videoComposition
              andAudioMix:(AVAudioMix*)audioMix audioSampleRate:(NSInteger)audioSampleRate{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    [self yuvConversionSetup];
    _audioSampleRate = AUDIOSAMPLERATE;
    lastSeekTime = kCMTimeZero;
    
    //self.audioSampleRate = audioSampleRate;
    
    self.compositon       = compositon;
    self.videoComposition = videoComposition;
    self.audioMix         = audioMix;

    
    self.isCall = NO;

//    [self initAudio];
    
    readerLock = [[NSLock alloc]init];
    
    // add
    stopTimeRange   = kCMTimeRangeInvalid;
    readerTimeRange = kCMTimeRangeInvalid;
    totalTimeRange  = kCMTimeRangeInvalid;
    currentTime     = kCMTimeZero;
    seekDone        = YES;
    self.videoCopyNextSampleBufferFinish = TRUE;
    
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

- (void)audioClearUp{
    NSLog(@"clean up audio buffer");
    RDTPCircularBufferCleanup(&tpCircularBuffer1);
    //[self uninitAudio];
}

- (void)dealloc
{
    NSLog(@"pp movie delloc");
    // Moved into endProcessing
    //if (self.playerItem && (displayLink != nil))
    //{
    //    [displayLink invalidate]; // remove from all run loops
    //    displayLink = nil;
    //}
    //20170510 emmet 先AudioUnitUninitialize再清空buffer，否则会崩溃
    [self uninitAudio]; ;//20170414 wuxiaoxia bug:每次进入一个界面播放视频，退出该界面后内存就会增加
    
    //[self uninitAudio];
    [readerLock lock];
    if (_playReader) {
        if(_playReader.status == AVAssetReaderStatusReading)
            [_playReader cancelReading];
        _playReader = nil;
    }
    [readerLock unlock];
    //    RDTPCircularBufferCleanup(&tpCircularBuffer1);
    
}

#pragma mark -
#pragma mark Movie processing

- (void)enableSynchronizedEncodingUsingMovieWriter:(RDGPUImageMovieWriter *)movieWriter;
{
    synchronizedMovieWriter = movieWriter;
    movieWriter.encodingLiveVideo = NO;
}

- (BOOL) isStoping
{
    return  isPlaying;
}

- (BOOL) isStarted
{
    return isPlaying;
}

- (BOOL)playWithTime:(CMTime )time{
    
    
    //NSLog(@"-->%s",__func__);
    [self endProcessing];
    if (_compositon) {
        totalTimeRange=CMTimeRangeMake(kCMTimeZero, _compositon.duration);
    }
    
    if (CMTimeCompare(time, totalTimeRange.duration)==0) {
        time=CMTimeSubtract(time, CMTimeMake(1, 24));
    }
    currentTime=time;
    stopTimeRange.start=time;
    
    if (CMTimeRangeEqual(_cutTimeRange, kCMTimeRangeInvalid)) {
        stopTimeRange.duration=CMTimeSubtract(totalTimeRange.duration, currentTime);
    }else {
        if (CMTimeCompare(currentTime, _cutTimeRange.start) == 0) {
            stopTimeRange.duration = _cutTimeRange.duration;
        }else {
            stopTimeRange.duration = CMTimeSubtract(_cutTimeRange.duration, CMTimeSubtract(currentTime, _cutTimeRange.start));
        }
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(seekSyncProcessAsset:) object:nil];
    
    audioSampleTime=0;
    isPlaying=YES;
    RDTPCircularBufferClear(&tpCircularBuffer1);
    [self startProcessing];
    return YES;
}

- (BOOL) play
{
    //NSLog(@"-->:%s ",__func__);
    if (isPlaying) {
        [self pause];
    }
//    RDTPCircularBufferInit(&tpCircularBuffer1, sizeForSeconds(40));//20170414 wuxiaoxia 优化内存：play时初始化，pause/stop时清空
    while (!seekDone || seekReader.status == AVAssetReaderStatusReading) {
        if(!seekReader){
            break;
        }
        if(seekReader.status == AVAssetReaderStatusReading){
            //  [seekReader cancelReading];
            //  seekReader = nil;
            //  seekDone = YES;
            usleep(200000);
            break;
        }
        
        NSLog(@"等待Seek完成:%ld",(long)seekReader.status);
        usleep(200000);
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(seekSyncProcessAsset:) object:nil];
    
    stopTimeRange.start=currentTime;
    if (CMTimeRangeEqual(_cutTimeRange, kCMTimeRangeInvalid)) {
        stopTimeRange.duration = CMTimeSubtract(totalTimeRange.duration, currentTime);
    }else {
        if (CMTimeCompare(currentTime, _cutTimeRange.start) == 0) {
            stopTimeRange.duration = _cutTimeRange.duration;
        }else {
            stopTimeRange.duration = CMTimeSubtract(_cutTimeRange.duration, CMTimeSubtract(currentTime, _cutTimeRange.start));
        }
    }
    audioSampleTime=0;
    isPlaying=YES;
    RDTPCircularBufferClear(&tpCircularBuffer1);
    [self startProcessing];
    return YES;
}

- (BOOL) pause
{
    // 取消同步进度条操作
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(seekSyncProcessAsset:) object:nil];
    isPlaying = NO;
    if (_playReader)
    {
        
        videoEncodingIsFinished = YES;
        audioEncodingIsFinished = YES;
        [readerLock lock];
        if(_playReader.status == AVAssetReaderStatusReading){
            @try {
                 [_playReader cancelReading];
            } @catch (NSException *exception) {
                
            }
        }
           
        _playReader=nil;
        [readerLock unlock];
    }
    if (_bAudio) {
        [self stopPlayingAudio];
    }
    if (synchronizedMovieWriter != nil)
    {
        [synchronizedMovieWriter setVideoInputReadyCallback:^{return NO;}];
        [synchronizedMovieWriter setAudioInputReadyCallback:^{return NO;}];
    }
    return YES;
}

- (CMTime)currentTime{
    return currentTime;
}

- (void)refresh{
    // add
    stopTimeRange   = kCMTimeRangeInvalid;
    readerTimeRange = kCMTimeRangeInvalid;
    totalTimeRange  = kCMTimeRangeInvalid;
    currentTime     = kCMTimeZero;
    seekDone        = YES;
    
}

- (void)preparePlayer{
    
    //return; //20161209
    //NSLog(@"%s _rdeader:%@",__func__,_reader);
    //[readerLock unlock];
  
    if (_compositon) {
        if(seekReader){
            NSLog(@"seekReader.status:%ld",(long)seekReader.status);
        }
        if(_playReader){
            NSLog(@"_playReader.status:%ld",(long)_playReader.status);
        }
        _playReader = [self createCommonReader_mix];
        _playReader.timeRange=CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(10, 600));
    }else{
        _playReader = [self createAssetReader];
    }
    
    for( AVAssetReaderOutput *output in _playReader.outputs ) {
        //NSLog(@"----.%@",output.mediaType);
        if( [output.mediaType isEqualToString:AVMediaTypeVideo] ) {
            readerVideoTrackOutput = output;
        }
    }
    if (CMTimeRangeEqual(stopTimeRange, kCMTimeRangeInvalid)) {
        previousFrameTime = kCMTimeZero;
        previousActualFrameTime = CFAbsoluteTimeGetCurrent();
    }else{
        readerTimeRange=stopTimeRange;
        if (_playAtActualSpeed) {
            _playReader.timeRange=readerTimeRange;
        }
        previousFrameTime = kCMTimeZero;
        previousActualFrameTime = CFAbsoluteTimeGetCurrent()-CMTimeGetSeconds(readerTimeRange.start);
    }
    if ([_playReader startReading] == NO)
    {
        NSLog(@"preparePlayer reader startReading error: %@", [_playReader.error description]);
        if(_playReader.status == AVAssetReaderStatusReading)
            [_playReader cancelReading];
        if(seekReader.status == AVAssetReaderStatusReading)
            [seekReader cancelReading];
        _playReader = nil;
        seekReader = nil;
        return;
    }
    CMSampleBufferRef sampleBufferRef = [readerVideoTrackOutput copyNextSampleBuffer];
    if (sampleBufferRef)
    {
        __unsafe_unretained PPMovie *weakSelf = self;
        rdRunSynchronouslyOnVideoProcessingQueue(^{
            @autoreleasepool {
                [weakSelf processMovieFrame:sampleBufferRef];
                CMSampleBufferInvalidate(sampleBufferRef);
#if ! TARGET_IPHONE_SIMULATOR
                CFRelease(sampleBufferRef);
#endif
                seekDone = YES;
            }
        });
    }
    if(_playReader.status == AVAssetReaderStatusReading)
        [_playReader cancelReading];
    _playReader = nil;
}
#pragma mark - seek同步画面
- (void)seekToTime:(CMTime)time sync:(BOOL)isSync
{
    
    if(_allowEnter){ // reader.status
        if(isSync){
            [self pause];
            
            // solaren - seek崩溃  ? 冲突
            
            if(seekReader && seekReader.status == AVAssetReaderStatusReading){
                @try {
//                    [readerLock lock];
                    [seekReader cancelReading]; // ？
//                    seekReader = nil;
//
//                    [readerLock unlock];
                    
                } @catch (NSException *exception) {
                    NSLog(@"exception:%@",exception);
                }
            }
        }
        _allowEnter = NO;
    }
    
    
    NSLog(@"-->%s isSync:%d",__func__,isSync);
    if(CMTimeCompare(lastSeekTime, time) == 0 && CMTimeGetSeconds(time) !=0){
        if(_delegate){
            if([_delegate respondsToSelector:@selector(syncToTimeDone)]){
                [_delegate syncToTimeDone];
            }
        }
        if(!isSync)
            return;
    }
    lastSeekTime = time;
    if (CMTimeCompare(time, totalTimeRange.duration)>=0) {
        time=CMTimeSubtract(time, CMTimeMake(1, 30));
    }
    currentTime=time;
    stopTimeRange.start=time;
    
    if (CMTimeRangeEqual(_cutTimeRange, kCMTimeRangeInvalid)) {
        stopTimeRange.duration=CMTimeSubtract(totalTimeRange.duration, currentTime);
    }else {
        if (CMTimeCompare(currentTime, _cutTimeRange.start) == 0) {
            stopTimeRange.duration = _cutTimeRange.duration;
        }else {
            stopTimeRange.duration = CMTimeSubtract(_cutTimeRange.duration, CMTimeSubtract(currentTime, _cutTimeRange.start));
        }
    }
    
    if (isSync) {
        if(seekReader.status == AVAssetReaderStatusReading){
            @try {
                
                [seekReader cancelReading];

            } @catch (NSException *exception) {
                NSLog(@"exception:%@",exception);
            }
            seekDone = YES;
        }
//        while (!seekDone) {
//            NSLog(@"等待Seek完成2");
//            //usleep(200000);
//            [NSThread sleepForTimeInterval:0.2];
//        }
    }
    
    // 同步画面 问题
    seekDone = NO;
    //__unsafe_unretained PPMovie *weakSelf = self;
    //rdRunAsynchronouslyOnVideoProcessingQueue(^{
        // 同步画面还有一定的问题
        [self seekSyncProcessAsset:isSync];
    //});
}

- (void)seekToTime:(CMTime)time sync:(BOOL)isSync callback:(void(^)())callbackBlock{
    
    if (CMTimeCompare(time, totalTimeRange.duration)==0) {
        time=CMTimeSubtract(time, CMTimeMake(1, 30));
    }
    currentTime=time;
    stopTimeRange.start=time;
    if (CMTimeRangeEqual(_cutTimeRange, kCMTimeRangeInvalid)) {
        stopTimeRange.duration=CMTimeSubtract(totalTimeRange.duration, currentTime);
    }else {
        if (CMTimeCompare(currentTime, _cutTimeRange.start) == 0) {
            stopTimeRange.duration = _cutTimeRange.duration;
        }else {
            stopTimeRange.duration = CMTimeSubtract(_cutTimeRange.duration, CMTimeSubtract(currentTime, _cutTimeRange.start));
        }
    }
    if (!seekDone) {
        NSLog(@"等待Seek");
        return;
    }
    // 同步画面
    if(isSync){
        seekDone = NO;
        __unsafe_unretained PPMovie *weakSelf = self;
        //rdRunAsynchronouslyOnVideoProcessingQueue(^{
        // 同步画面还有一定的问题
        
        [weakSelf seekSyncProcessAsset:isSync];
        if(callbackBlock){
            callbackBlock();
        }
        //});
    }
}

- (void)seekSyncProcessAsset:(BOOL)isSync
{
    NSLog(@">>>>>>>>>>>> %s %d",__func__,__LINE__);
    [self pause];
    while(seekReader && seekReader.status != AVAssetReaderStatusReading){
        [NSThread sleepForTimeInterval:0.2];
    }
    

    if (_compositon) {
        
        if(_playReader){
            NSLog(@"_playReader.status:%ld",(long)_playReader.status);
        }
        if(seekReader){
            NSLog(@"seekReader.status:%ld",(long)seekReader.status);
        }
        seekReader = [self createCommonReader_mix];
    }else{
        seekReader = [self createAssetReader];
    }
    
    //20170516 emmet seekReader = nil 时 没必要执行之后的操作
    if(!seekReader){
        return;
    }
    
    
    for( AVAssetReaderOutput *output in seekReader.outputs ) {
        if( [output.mediaType isEqualToString:AVMediaTypeVideo] ) {
            seekReaderVideoTrackOutput = output;
        }
    }
    if (CMTimeRangeEqual(stopTimeRange, kCMTimeRangeInvalid)) {
        previousFrameTime = kCMTimeZero;
        previousActualFrameTime = CFAbsoluteTimeGetCurrent();
    }else{
        readerTimeRange=stopTimeRange;
        if (_playAtActualSpeed) {
            seekReader.timeRange=readerTimeRange;
        }
        previousFrameTime = kCMTimeZero;
        previousActualFrameTime = CFAbsoluteTimeGetCurrent()-CMTimeGetSeconds(readerTimeRange.start);
    }
    //20170516 emmet readerTimeRange 大于 _compositon.duration 没必要执行seek
    if(CMTimeCompare(readerTimeRange.start,_compositon.duration) == 1){
        [seekReader cancelReading];
        seekReader = nil;
        return;
    }
    BOOL startReading = YES;
    @try {
        startReading =  [seekReader startReading];
    } @catch (NSException *exception) {
        NSLog(@"exception:%@",exception);
    }
    if ( startReading == NO)
    {
        NSLog(@"seek startReading error: %@", [seekReader.error description]);
        if(_delegate){
            if([_delegate respondsToSelector:@selector(syncToTimeDone)]){
                [_delegate syncToTimeDone];
            }
        }
        if(seekReader.status == AVAssetReaderStatusReading)
            [seekReader cancelReading];
        seekReader = nil;
        seekReaderVideoTrackOutput = nil;
        seekDone = YES;
        return;
    }
    //    NSLog(@"--->copyNextSampleBuffer;");
    
    
    CMSampleBufferRef sampleBufferRef;
    // 可能卡住 ？？？
    NSLog(@"--->seekReaderVideoTrackOutput copyNextSampleBuffer before");
    sampleBufferRef = [seekReaderVideoTrackOutput copyNextSampleBuffer];
    NSLog(@"--->seekReaderVideoTrackOutput copyNextSampleBuffer after");
    
    if (sampleBufferRef)
    {
        __unsafe_unretained PPMovie *weakSelf = self;
        rdRunSynchronouslyOnVideoProcessingQueue(^{
            @autoreleasepool {
                [weakSelf processMovieFrame:sampleBufferRef];
                CMSampleBufferInvalidate(sampleBufferRef);
                seekDone = YES;
                
                CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBufferRef);
                
                NSLog(@"---->seekTime:%f seekReader.start:%f",CMTimeGetSeconds(currentSampleTime),CMTimeGetSeconds(seekReader.timeRange.start));
                
                
#if ! TARGET_IPHONE_SIMULATOR
                CFRelease(sampleBufferRef);
#endif
                if(seekReader.status == AVAssetReaderStatusReading)
                    [seekReader cancelReading];
                seekReader = nil;
                
                seekReaderVideoTrackOutput = nil;
                if(weakSelf.delegate){
                    if([weakSelf.delegate respondsToSelector:@selector(syncToTimeDone)]){
                        [weakSelf.delegate syncToTimeDone];
                    }
                }
                if(isSync){
                    NSLog(@"[self.delegate seektimesyncBlock]");
                    if(weakSelf.delegate){
                        if([weakSelf.delegate respondsToSelector:@selector(seektimesyncBlock)]){
                            [weakSelf.delegate seektimesyncBlock];
                        }
                    }
                }
            }
        });
    }else{
        seekDone = YES;
        if(seekReader.status == AVAssetReaderStatusReading)
            [seekReader cancelReading];
        seekReader = nil;
        readerVideoOutput = nil;
        readerAudioOutput = nil;
        if(_delegate){
            if([_delegate respondsToSelector:@selector(syncToTimeDone)]){
                [_delegate syncToTimeDone];
            }
        }
        if(isSync){
            if(_delegate){
                if([_delegate respondsToSelector:@selector(seektimesyncBlock)]){
                    [_delegate seektimesyncBlock];
                }
            }
        }
        //NSLog(@"seekDone = YES;");
    }
    //seekReader = nil;
    //[seekReader cancelReading];
}

- (void)seekToTime:(CMTime)time
{
    
    [self seekToTime:time sync:YES];
}

- (void)startProcessing//开始解码
{
    
    [self endProcessing];
    gfullCircularBuffer = NO;
    
//    NSLog(@"%s",__func__);
    __block typeof(self) weakSelf = self;
    
    isPlaying=YES;
    
    videoEncodingIsFinished = NO;
    audioEncodingIsFinished = NO;
    
    if( self.playerItem ) {
//        NSLog(@"self.playerItem?????????");
        [self processPlayerItem];
        return;
    }
    // 输出分支
    if (!_forPlayback) {
        currentTime = kCMTimeZero;
        processingFrameTime = kCMTimeZero;
        dispatch_group_enter([PPMovieManager shared].readingAllReadyDispatchGroup);
    }
    // 是否需要重复
    if (_shouldRepeat){
        keepLooping = YES;
    }
    
    if(self.url == nil)
    {
        if (_forPlayback) {//emmet20161123
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                [weakSelf processAsset];
            });
            
            
        }else{
            [weakSelf processAsset];
        }
        return;
    }
    
    NSDictionary *inputOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *inputAsset = [[AVURLAsset alloc] initWithURL:self.url options:inputOptions];
    
    
    [inputAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler: ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSError *error = nil;
            AVKeyValueStatus tracksStatus = [inputAsset statusOfValueForKey:@"tracks" error:&error];
            if (tracksStatus != AVKeyValueStatusLoaded)
            {
                return;
            }
            weakSelf.asset = inputAsset;
            if (_forPlayback) {
                [weakSelf processAsset];
            }else{
                [weakSelf processAsset];
            }
        });
    }];
    inputOptions = nil;
}
//创建解码会话
- (AVAssetReader*)createAssetReader
{
    NSError *error = nil;
    if(!self.asset){
        return nil;
    }
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:self.asset error:&error];
    if(error){
        NSLog(@"createAssetReader--> error : %@",error);
    }
    NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
    if ([RDGPUImageContext supportsFastTextureUpload]) {
        [outputSettings setObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        isFullYUVRange = YES;
    }
    else {
        [outputSettings setObject:@(kCVPixelFormatType_32BGRA) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        isFullYUVRange = NO;
    }
    
    readerVideoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:[[self.asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] outputSettings:outputSettings];
    readerVideoTrackOutput.alwaysCopiesSampleData = NO;
    [assetReader addOutput:readerVideoTrackOutput];
    
    NSArray *audioTracks = [self.asset tracksWithMediaType:AVMediaTypeAudio];
    BOOL shouldRecordAudioTrack = (([audioTracks count] > 0) && (self.audioEncodingTarget != nil) );
    if (_forPlayback) {
        shouldRecordAudioTrack = (([audioTracks count] > 0))&&_bAudio;
        //NSLog(@"add audio track");
    }
    AVAssetReaderTrackOutput *readerAudioTrackOutput = nil;
//    for(AVAssetTrack *audioTrack in audioTracks){
        //NSLog(@"audioTrack timeRange: %lld, %lld", audioTrack.timeRange.start.value, audioTrack.timeRange.duration.value);
//    }
    if (shouldRecordAudioTrack)
    {
        [self.audioEncodingTarget setShouldInvalidateAudioSampleWhenDone:YES];
        
        AVAssetTrack* audioTrack = [audioTracks objectAtIndex:0];
        readerAudioTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:nil];
        readerAudioTrackOutput.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmTimeDomain;//20190528 设置为AVAudioTimePitchAlgorithmVarispeed，视频变速后，音调没有调整
        readerAudioTrackOutput.alwaysCopiesSampleData = NO;
        [assetReader addOutput:readerAudioTrackOutput];
    }
    
    return assetReader;
}

- (AVAssetReader*)createCommonReader_mix
{
  /** 20170517 存疑 设置上推下推转场后获取buffer失败 而后创建reader失败，
   error : Error Domain=AVFoundationErrorDomain Code=-11800 "这项操作无法完成" UserInfo={NSUnderlyingError=0x170653020 {Error Domain=NSOSStatusErrorDomain Code=-12245 "(null)"}, NSLocalizedFailureReason=发生未知错误（-12245）, NSLocalizedDescription=这项操作无法完成}
   */
    NSError *error = nil;
    
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:_compositon error:&error];
    if(error){
        
        NSLog(@"createAssetReader_mix--> error : %@",error);
    }
    NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
    if ([RDGPUImageContext supportsFastTextureUpload]) {
        [outputSettings setObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        isFullYUVRange = YES;
    }
    else {
        [outputSettings setObject:@(kCVPixelFormatType_32BGRA) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        isFullYUVRange = NO;
    }
    if(!_compositon){
        return nil;
    }
    AVAssetReaderVideoCompositionOutput *readerOutput_video = [AVAssetReaderVideoCompositionOutput assetReaderVideoCompositionOutputWithVideoTracks:[_compositon tracksWithMediaType:AVMediaTypeVideo]
                                                                                                                                     videoSettings:outputSettings];
    
    
#if ! TARGET_IPHONE_SIMULATOR
    if( [_videoComposition isKindOfClass:[AVMutableVideoComposition class]] )
        [(AVMutableVideoComposition*)_videoComposition setRenderScale:1.0];
#endif
    readerOutput_video.videoComposition = _videoComposition;
    readerOutput_video.alwaysCopiesSampleData = NO;
    @try {
        [assetReader addOutput:readerOutput_video];
    } @catch (NSException *exception) {
        NSLog(@"exception:%@",exception);
    }
    NSArray *audioTracks = [_compositon tracksWithMediaType:AVMediaTypeAudio];
    BOOL shouldRecordAudioTrack = (([audioTracks count] > 0) && (self.audioEncodingTarget != nil) );
    if (_forPlayback) {
        shouldRecordAudioTrack = (([audioTracks count] > 0))&& (_bAudio);
    }
//    for(AVAssetTrack *audioTrack in audioTracks){
        //NSLog(@"audioTrack timeRange: %lld, %lld", audioTrack.timeRange.start.value, audioTrack.timeRange.duration.value/audioTrack.timeRange.duration.timescale);
//    }
    AVAssetReaderAudioMixOutput *readerOutput_audio = nil;
    if (shouldRecordAudioTrack)
    {
        [self.audioEncodingTarget setShouldInvalidateAudioSampleWhenDone:YES];
#if 1
//        AudioChannelLayout acl;
//        bzero( &acl, sizeof(acl));
        
        NSMutableDictionary *audioOutputSettings = [NSMutableDictionary dictionary];
        [audioOutputSettings setObject:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
#if 0
        [audioOutputSettings setObject:[NSNumber numberWithInt:90000] forKey:AVSampleRateKey];

#else
        [audioOutputSettings setObject:[NSNumber numberWithInt:(_audioSampleRate==0 ? AUDIOSAMPLERATE : _audioSampleRate)/*emmet20161125 44100.00*/] forKey:AVSampleRateKey];
#endif
        //[audioOutputSettings setObject: [ NSNumber numberWithFloat: preferredHardwareSampleRate ] forKey:AVSampleRateKey];
        
        [audioOutputSettings setObject:[NSNumber numberWithInt:_audioChannelNumbers] forKey:AVNumberOfChannelsKey];
        //          [audioOutputSettings setObject:[NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)] forKey:AVChannelLayoutKey];
        [audioOutputSettings setObject:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
        [audioOutputSettings setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
        [audioOutputSettings setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
        [audioOutputSettings setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsNonInterleaved];
        
        readerOutput_audio = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:audioTracks audioSettings:audioOutputSettings];
        
#else
        double preferredHardwareSampleRate = [[AVAudioSession sharedInstance] currentHardwareSampleRate];
        AudioChannelLayout acl;©
        bzero( &acl, sizeof(acl));
        acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
        
        NSDictionary *audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                             [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                             [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
                                             [ NSNumber numberWithFloat: preferredHardwareSampleRate ], AVSampleRateKey,
                                             [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                                             //[ NSNumber numberWithInt:AVAudioQualityLow], AVEncoderAudioQualityKey,
                                             [ NSNumber numberWithInt: 64000 ], AVEncoderBitRateKey,
                                             nil];
        
        
        readerAudioOutput = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:audioTracks audioSettings:audioOutputSettings];
#endif
        
        readerOutput_audio.audioMix = self.audioMix;
        readerOutput_audio.alwaysCopiesSampleData = NO;
        if ([assetReader canAddOutput:readerOutput_audio]) {
            [assetReader addOutput:readerOutput_audio];
        }
    }
    
    return assetReader;
}


- (void)processAsset
{
    
    //NSLog(@"%s _allowEnter:%d",__func__,_allowEnter);
    //防止建立两次解码
    if(_allowEnter && !keepLooping){
        return;
    }
#if 1
    
    // 等待解码器完成
    //    NSLog(@"1 reader.status:%d",reader.status);
    //    while(reader.status == AVAssetReaderStatusReading){
    //        NSLog(@"reader is reading...");
    //        [readerLock lock];
    //        [reader cancelReading];
    //        reader = nil;
    //        usleep(50000);
    //        [readerLock unlock];
    //    }
    //
    if (_playReader) {
        _playReader = nil;
        //        pause();
        //        while (_reader.status==AVAssetReaderStatusReading) {
        //
        //             usleep(50000);
        //       }
        
    }
    //NSLog(@"2 reader.status:%d,%@",_reader.status,_reader);
    //while (seekReader.status==AVAssetReaderStatusReading) {
    //[seekReader cancelReading];
    
    //NSLog(@"wait seek done");
    //usleep(50000);
    //}
    //NSLog(@"seek done");
    //NSLog(@"3 reader.status:%d",_reader.status);
#endif
    
    if (!_playReader) {
        if (_compositon) {
            if(seekReader){
                NSLog(@"seekReader.status:%ld",(long)seekReader.status);
            }
            _playReader = [self createCommonReader_mix];
        }else{
            _playReader = [self createAssetReader];
        }
        
        
    }
    
    
    AVAssetReaderOutput *readerAudioTrackOutput = nil;
    
    audioEncodingIsFinished = YES;
    for( AVAssetReaderOutput *output in _playReader.outputs ) {
        if( [output.mediaType isEqualToString:AVMediaTypeAudio] ) {
            audioEncodingIsFinished = NO;
            readerAudioTrackOutput = output;
        }
        else if( [output.mediaType isEqualToString:AVMediaTypeVideo] ) {
            readerVideoTrackOutput = output;
        }
    }
    
    if (_compositon) {
        totalTimeRange=CMTimeRangeMake(kCMTimeZero, _compositon.duration);
    }
    
    if (_forPlayback) {
        if (CMTimeRangeEqual(stopTimeRange, kCMTimeRangeInvalid)) {
            previousFrameTime = kCMTimeZero;
            previousActualFrameTime = CFAbsoluteTimeGetCurrent();
            
        }else{
            if(isnan(CMTimeGetSeconds(stopTimeRange.duration))){
                stopTimeRange.duration = CMTimeMakeWithSeconds(CMTimeGetSeconds(totalTimeRange.duration) - CMTimeGetSeconds(stopTimeRange.start), TIMESCALE);
            }
            readerTimeRange=stopTimeRange;
            if (_playAtActualSpeed) {
                if(_playReader.status != AVAssetReaderStatusReading){
                    @try {
                        _playReader.timeRange = readerTimeRange;
                    } @catch (NSException *exception) {
                        NSLog(@"exception:%@",exception);
                    }
                    
                }else{
                    //NSLog(@"set decoder timeRange cannot be called after reading has started");
                }
            }
            previousFrameTime = kCMTimeZero;
            previousActualFrameTime = CFAbsoluteTimeGetCurrent()-CMTimeGetSeconds(readerTimeRange.start);
        }
    }
    
    
    [readerLock lock];
    BOOL suc = YES;
    if(_playReader.status != AVAssetReaderStatusReading) {
        @try {
            suc = [_playReader startReading];
            
            
        } @catch (NSException *exception) {
            NSLog(@"exception:%@",exception);
        }
    }
    //  [reader cancelReading];
    //NSLog(@"4 reader.status:%d",_reader.status);
    
    if (suc == NO)
    {
        NSLog(@"reader startReading error: %@", [seekReader.error description]);
        if(_playReader.status == AVAssetReaderStatusReading)
            [_playReader cancelReading];
        _playReader = nil;
        readerVideoOutput = nil;
        readerAudioOutput = nil;
        [readerLock unlock];
        [self endProcessing];
        dispatch_group_leave([PPMovieManager shared].readingAllReadyDispatchGroup);
        return;
    }
    [readerLock unlock];
    
    __unsafe_unretained typeof(self) weakSelf = self;
    // 预览
    if (_forPlayback) {
        // 有音频播放音频数据
        if (_bAudio) {
            [weakSelf startPlayingAudio];
        }
        // 正在读取、并且不重复
        while (_playReader.status == AVAssetReaderStatusReading)// && (!_shouldRepeat || keepLooping)
        {
            if (!isPlaying) // 如果没有播放,却正在解码读视频 直接break
            {
                break;
            }

            //NSLog(@"=>%s,%d self:%@",__FUNCTION__,__LINE__,self);
            // 解码视频
            [weakSelf readNextVideoFrameFromOutput:readerVideoTrackOutput];
            //NSLog(@"==>%s,%d",__FUNCTION__,__LINE__);
        
            // 有音频信息且没有解码完就 解码音频
            if ( (readerAudioTrackOutput) && (!audioEncodingIsFinished) )
            {
                [weakSelf readNextAudioSampleFromOutput:readerAudioTrackOutput];
            }
            //NSLog(@"===>%s,%d",__FUNCTION__,__LINE__);

           
        }
        
        // 解码完成后停止播放音频数据
        if (_bAudio && !keepLooping) {
            [weakSelf stopPlayingAudio];
        }
        
        // 解码器读取完成后处理
        if (_playReader.status == AVAssetReaderStatusCompleted) {
            //NSLog(@"currentTime:%.2f----------", CMTimeGetSeconds(currentTime));
            // 如果截取视频没有设置
            if (CMTimeRangeEqual(_cutTimeRange, kCMTimeRangeInvalid)) {
                currentTime = kCMTimeZero;
                stopTimeRange = totalTimeRange;
            }else {
                // 如果截取视频范围设置了,设置当前开始时间为截取开始时间,停止时间范围为截取时间范围
                currentTime = _cutTimeRange.start;
                stopTimeRange = _cutTimeRange;
            }
            // 解码完成后释放 解码器的资源
            if(_playReader){
                if(_playReader.status == AVAssetReaderStatusReading)
                    [_playReader cancelReading];
                _playReader = nil;
                readerVideoOutput = nil;
                readerAudioOutput = nil;
            }
            // 如果需要重复播放
            if (!keepLooping) {
                [weakSelf endProcessing];
                // 通知界面播放视频结束
                if(weakSelf.delegate){
                    if ([weakSelf.delegate respondsToSelector:@selector(playerToEnd:)]) {
                        [weakSelf.delegate playerToEnd:self];
                    }
                }
            }else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf startProcessing];
                });
            }
            
        }
        else{
            if(_playReader.status == AVAssetReaderStatusFailed){
                [_playReader cancelReading];
                // 解码失败后释放 解码器的资源
                if(_playReader){
                    if(_playReader.status == AVAssetReaderStatusReading)
                        [_playReader cancelReading];
                    _playReader = nil;
                    readerVideoOutput = nil;
                    readerAudioOutput = nil;
                }
                [weakSelf endProcessing];
            }
        }
    }else{
        
        // 输出情况 配置好了解码器 发出离开信号
        dispatch_group_leave([PPMovieManager shared].readingAllReadyDispatchGroup);
    }
}


/**
 *  读取下一帧
 *
 *  @return 返回还可以读取下一帧
 */
- (BOOL)renderNextFrame {
    
    
    
    __unsafe_unretained typeof(self) weakSelf = self;
    if (_playReader.status == AVAssetReaderStatusReading && (!_shouldRepeat || keepLooping))
    {
        
        return [weakSelf readNextVideoFrameFromOutput:readerVideoTrackOutput];
    }
    
    if (_playReader.status == AVAssetWriterStatusCompleted || videoEncodingIsFinished) {
        //NSLog(@"movie: %@ reading is done", self.filterName);
        if(_playReader){
            [_playReader cancelReading];
            _playReader = nil;
        }
        [weakSelf endProcessing];
    }
    return NO;
}

/**
 *  专用于播放器渲染
 */
- (void)processPlayerItem
{
    rdRunSynchronouslyOnVideoProcessingQueue(^{
        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [displayLink setPaused:YES];
        
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
    // Restart display link.
    [displayLink setPaused:NO];
}

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
    
    if ([playerItemOutput hasNewPixelBufferForItemTime:outputItemTime]) {
        __unsafe_unretained typeof(self) weakSelf = self;
        CVPixelBufferRef pixelBuffer = [playerItemOutput copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
        if( pixelBuffer )
            rdRunSynchronouslyOnVideoProcessingQueue(^{

//                if (weakSelf.frameProcessingCompletionBlock != NULL && _isCall )
//                {
//                    NSLog(@"\n\n\nppmove---->:%@   --->\n\n",self);
//
//                    weakSelf.frameProcessingCompletionBlock(self, outputItemTime);
//                }

                [weakSelf processMovieFrame:pixelBuffer withSampleTime:outputItemTime];
                if (pixelBuffer) {
                    CFRelease(pixelBuffer);
                }
            });
        pixelBuffer = nil;
    }
}

#pragma mark - 解码视频

- (BOOL)readNextVideoFrameFromOutput:(AVAssetReaderOutput *)pReaderVideoTrackOutput;
{
    //NSLog(@"\n\n***func: %s,line%d",__func__,__LINE__);

    if (_playReader.status == AVAssetReaderStatusReading && ! videoEncodingIsFinished)
    {
        //NSLog(@"***func: %s,line:%d",__func__,__LINE__);

        if (!_playAtActualSpeed) {
            if (CMTimeCompare(CMTimeAdd(processingFrameTime, CMTimeMake(2,_videoComposition.frameDuration.timescale)), _compositon.duration)>=0) {
                //NSLog(@"the last frames return yes:%f",CMTimeGetSeconds(_compositon.duration));
                
                NSLog(@"the last frames return yes! videoEncodingIsFinished YES !_compositon.duration:%f  processingFrameTime:%f",CMTimeGetSeconds(_compositon.duration),CMTimeGetSeconds(processingFrameTime));
                while (!_videoCopyNextSampleBufferFinish) {
                    usleep(20000);
                    NSLog(@"================wait for copyNextSampleBufferFinishStatu is true");
                }
                processingFrameTime = _compositon.duration;
                videoEncodingIsFinished = YES;
                return NO;
            }
        }
        [readerLock lock];

        NSLog(@"readNextVideoFrameFromOutput:%d",__LINE__);
        //NSLog(@"        v_copyNext前");
        __block CMSampleBufferRef sampleBufferRef;
        @try {
            sampleBufferRef = [pReaderVideoTrackOutput copyNextSampleBuffer];
        } @catch (NSException *exception) {
            NSLog(@"exception:%@",[exception description]);
        }
       
        NSLog(@"readNextVideoFrameFromOutput:%d",__LINE__);
//        CMTime durationTime = CMSampleBufferGetOutputDuration(sampleBufferRef);
//        CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBufferRef);

        NSLog(@"    ismv:%d name:%@   v_copyNext后 :%f",self.isMVEffect,self.name,CMTimeGetSeconds(_exportcurrentTime));
        
        [readerLock unlock];
        
        if(_delegate){
            if(!_playAtActualSpeed && [_delegate respondsToSelector:@selector(refreshVAAnimationLayerIndex:)]){
                [_delegate refreshVAAnimationLayerIndex:processingFrameTime];
            }
        }
        
        if (sampleBufferRef)
        {
            //NSLog(@"***func: %s,line:%d",__func__,__LINE__);
            CMTime curTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBufferRef);
            _exportcurrentTime = curTime;
            /**
             *  猜测可用于实时切换滤镜等等操作
             */

//            if (self.frameProcessingCompletionBlock != NULL && _isCall)
//            {
//                
//                //NSLog(@"\n\n\nppmove---->:%@   --->\n\n",self);
//
//                self.frameProcessingCompletionBlock(self, curTime);
//            }
            /**
             *  是否根据需、要做下一步操作
             */
            //NSLog(@"***func: %s,line:%d",__func__,__LINE__);
            //20170509 emmet 添加 ppMovie:(PPMovie *)ppMove 解决进度条闪动的bug
            BOOL drop = [_delegate progressCurrentTime:curTime filter:_filterName ppMovie:self];
            //NSLog(@"***func: %s,line:%d",__func__,__LINE__);

            if(drop){
#if ! TARGET_IPHONE_SIMULATOR
                CFRelease(sampleBufferRef);
#endif
                //NSLog(@"***func: %s,line:%d",__func__,__LINE__);
                return YES; //solaren 实时滤镜的问题导致 seek显示冻结 在filterplayer界面修改返回值
            }
            
            if (_playAtActualSpeed)
            {
                CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBufferRef);
                CGFloat frameTimeDifference = CMTimeGetSeconds(currentSampleTime);
                while (1) {
                    CFAbsoluteTime currentActualTime = CFAbsoluteTimeGetCurrent();
                    CGFloat actualTimeDifference     = currentActualTime - previousActualFrameTime;
                    if (frameTimeDifference==0) {
                        break;
                    }
                    // 如果当前帧时间戳与系统时间戳大,那么sleep 5毫秒直到相等才解码做同步
                    if (frameTimeDifference>actualTimeDifference) {
                        usleep(3000);// sleep 5 毫秒
                    }else{
                        break;
                    }
                    //NSLog(@"***func: %s,line:%d",__func__,__LINE__);

                }
                currentTime       = currentSampleTime;
                previousFrameTime = currentSampleTime;
//                NSLog(@"currentTime:%f", CMTimeGetSeconds(currentTime));
                //NSLog(@"***func: %s,line:%d",__func__,__LINE__);

                if(_delegate){
                    if(_playAtActualSpeed && [_delegate respondsToSelector:@selector(refreshVAAnimationLayerIndex:)]){
                        [_delegate refreshVAAnimationLayerIndex:currentTime];
                    }
                }
            }else{
                //                CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBufferRef);
                //                [_delegate progressCurrentTime:currentSampleTime];
                //                NSLog(@"currentSampleTime_export:%f %@",CMTimeGetSeconds(currentSampleTime),self.filterName);
                //                 currentTime       = currentSampleTime;
            }
            //NSLog(@"***func: %s,line:%d",__func__,__LINE__);

            if (sampleBufferRef) {
                //NSLog(@"***func: %s,line:%d",__func__,__LINE__);
                __unsafe_unretained typeof(self) weakSelf = self;
                rdRunSynchronouslyOnVideoProcessingQueue(^{
                    //20170517 如果改成去掉自动释放池 __block 改为 __weak ,添加MV后播放过程中会崩溃
                    @autoreleasepool {
                        //NSLog(@"***func: %s,line:%d",__func__,__LINE__);
                        [weakSelf processMovieFrame:sampleBufferRef];
                        CMSampleBufferInvalidate(sampleBufferRef);
#if ! TARGET_IPHONE_SIMULATOR
                        CFRelease(sampleBufferRef);
#endif
                        sampleBufferRef = nil;
                    }
                });
                sampleBufferRef = nil;
            }
            return YES;
        }
        else
        {
            if(_playReader.error){
                //NSLog(@"***_playReader.error : %@",_playReader.error);
                [_playReader cancelReading];
                
            }
            //NSLog(@"***func: %s,line:%d",__func__,__LINE__);
            // 如果 sampleBufferRef == nil 说明解码已经完成,如果音视频都完成则结束
            if (!keepLooping) {
                //NSLog(@"***func: %s,line:%d videoEncodingIsFinished = YES",__func__,__LINE__);
                videoEncodingIsFinished = YES;
                if( videoEncodingIsFinished && audioEncodingIsFinished )
                    return NO;
            }
        }
    }
    else if (synchronizedMovieWriter != nil)
    {
        //NSLog(@"***func: %s,line:%d",__func__,__LINE__);

        if (_playReader.status == AVAssetReaderStatusCompleted)
        {
            return NO;
        }
    }
    else{
        //NSLog(@"***func: %s,line:%d",__func__,__LINE__);

        if (_playReader.status == AVAssetReaderStatusCompleted)
        {
            return NO;
        }
    }
    //NSLog(@"***func: %s,line:%d videoEncodingIsFinished:%d _playReader.status%ld",__func__,__LINE__, videoEncodingIsFinished,(long)_playReader.status);
    //AVAssetReaderStatusUnknown = 0, AVAssetReaderStatusReading, AVAssetReaderStatusCompleted, AVAssetReaderStatusFailed, AVAssetReaderStatusCancelled,
    return NO;
}


#pragma mark - 解码音频

- (BOOL)readNextAudioSampleFromOutput:(AVAssetReaderOutput *)readerAudioTrackOutput
{
    @autoreleasepool {
        //NSLog(@"in readNextAudioSampleFromOutput");
        if (gfullCircularBuffer)
        {
//            NSLog(@"in gfullCircularBuffer = YES");


            return YES;
        }
        
        if (_playReader.status == AVAssetReaderStatusReading && ! audioEncodingIsFinished)
        {
           
            //NSLog(@"previousFrameTime:%lf",CMTimeGetSeconds(audioPreviousTime));
            
            //NSLog(@"readNextAudioSampleFromOutput:%d",__LINE__);
//            NSLog(@"a_copyNext前");
            __block CMSampleBufferRef audioSampleBufferRef;
            @try {
                
                audioSampleBufferRef = [readerAudioTrackOutput copyNextSampleBuffer];
            } @catch (NSException *exception) {
                NSLog(@"出错:%@",exception);
                return NO;
            }
            
            //NSLog(@"readNextAudioSampleFromOutput:%d",__LINE__);
//            CMTime durationTime = CMSampleBufferGetOutputDuration(audioSampleBufferRef);
            CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(audioSampleBufferRef);
            
//            NSLog(@"a_copyNext后:%f",CMTimeGetSeconds(currentSampleTime));
            audioPreviousTime = currentSampleTime;
            
            if (audioSampleBufferRef)
            {
                [self.audioEncodingTarget processAudioBuffer:audioSampleBufferRef];
                
                if(_forPlayback&&_bAudio)//放入循环队列
                {
                    //                    NSLog(@"放入循环队列");
                    [self processAudioFrame:audioSampleBufferRef];
                }
                CMSampleBufferInvalidate(audioSampleBufferRef);
#if ! TARGET_IPHONE_SIMULATOR
                CFRelease(audioSampleBufferRef);
#endif
                audioSampleBufferRef = nil;
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
            if (_playReader.status == AVAssetReaderStatusCompleted || _playReader.status == AVAssetReaderStatusFailed ||
                _playReader.status == AVAssetReaderStatusCancelled)
            {
                [self endProcessing];
            }
        }
        return NO;
    }
}

- (void)processMovieFrame:(CMSampleBufferRef)movieSampleBuffer;
{
    
    CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(movieSampleBuffer);
    
  
    
    CVImageBufferRef movieFrame = CMSampleBufferGetImageBuffer(movieSampleBuffer);
    if (!_forPlayback) {
        processingFrameTime = currentSampleTime;
    }
    //NSLog(@"***func: %s,line:%d",__func__,__LINE__);
    [self processMovieFrame:movieFrame withSampleTime:currentSampleTime];
}

- (float)progress
{
    if ( AVAssetReaderStatusReading == _playReader.status )
    {
        float current = processingFrameTime.value * 1.0f / processingFrameTime.timescale;
        float duration = self.asset.duration.value * 1.0f / self.asset.duration.timescale;
        if (_compositon) {
            duration = self.compositon.duration.value * 1.0f / self.compositon.duration.timescale;
        }
        return current / duration;
    }
    else if ( AVAssetReaderStatusCompleted == _playReader.status )
    {
        return 1.f;
    }
    else
    {
        return 0.f;
    }
}

//OPENGL 绘制
- (void)processMovieFrame:(CVPixelBufferRef)movieFrame withSampleTime:(CMTime)currentSampleTime
{
    
    
    
    int bufferHeight = (int) CVPixelBufferGetHeight(movieFrame);
    int bufferWidth = (int) CVPixelBufferGetWidth(movieFrame);
    //NSLog(@"***func: %s,line:%d",__func__,__LINE__);

    CFTypeRef colorAttachments = CVBufferGetAttachment(movieFrame, kCVImageBufferYCbCrMatrixKey, NULL);
    //NSLog(@"***func: %s,line:%d",__func__,__LINE__);

    if (colorAttachments != NULL)
    {
        //NSLog(@"***func: %s,line:%d",__func__,__LINE__);

        if(CFStringCompare(colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_601_4, 0) == kCFCompareEqualTo)
        {
            //NSLog(@"***func: %s,line:%d",__func__,__LINE__);

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
    //NSLog(@"***func: %s,line:%d",__func__,__LINE__);

    // Fix issue 1580
    [RDGPUImageContext useImageProcessingContext];
    
    if ([RDGPUImageContext supportsFastTextureUpload])
    {
        CVOpenGLESTextureRef luminanceTextureRef = NULL;
        CVOpenGLESTextureRef chrominanceTextureRef = NULL;
        
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
                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[RDGPUImageContext sharedImageProcessingContext] coreVideoTextureCache], movieFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE, bufferWidth, bufferHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);
            }
            else
            {
                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[RDGPUImageContext sharedImageProcessingContext] coreVideoTextureCache], movieFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE, bufferWidth, bufferHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);
            }
            if (err)
            {
                NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            }
            
            luminanceTexture = CVOpenGLESTextureGetName(luminanceTextureRef);
            glBindTexture(GL_TEXTURE_2D, luminanceTexture);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            // UV-plane
            glActiveTexture(GL_TEXTURE5);
            if ([RDGPUImageContext deviceSupportsRedTextures])
            {
                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[RDGPUImageContext sharedImageProcessingContext] coreVideoTextureCache], movieFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, bufferWidth/2, bufferHeight/2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);
            }
            else
            {
                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[RDGPUImageContext sharedImageProcessingContext] coreVideoTextureCache], movieFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, bufferWidth/2, bufferHeight/2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);
            }
            if (err)
            {
                NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            }
            
            chrominanceTexture = CVOpenGLESTextureGetName(chrominanceTextureRef);
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
            //NSLog(@"%s %d",__func__,__LINE__);
            for (id<RDGPUImageInput> currentTarget in targets)
            {
                NSInteger indexOfObject = [targets indexOfObject:currentTarget];
                NSInteger targetTextureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
                [currentTarget newFrameReadyAtTime:currentSampleTime atIndex:targetTextureIndex];//emmet20121228
            }
            
            CVPixelBufferUnlockBaseAddress(movieFrame, 0);
            if (luminanceTextureRef) {
                CFRelease(luminanceTextureRef);
                luminanceTextureRef = nil;
            }
            if (chrominanceTextureRef) {
                CFRelease(chrominanceTextureRef);
                chrominanceTextureRef = nil;
            }
        }
        else
        {
            //NSLog(@"%s CVPixelBufferGetPlaneCount(movieFrame)<0",__func__);
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
//        CVPixelBufferRelease(movieFrame);//20181029
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

}

- (void)endProcessing;
{
    keepLooping = NO;
    [displayLink setPaused:YES];
    
    for (id<RDGPUImageInput> currentTarget in targets)
    {
        [currentTarget endProcessing];
    }
    
    if (synchronizedMovieWriter != nil)
    {
        [synchronizedMovieWriter setVideoInputReadyCallback:^{return NO;}];
        [synchronizedMovieWriter setAudioInputReadyCallback:^{return NO;}];
    }
    
    if (self.playerItem && (displayLink != nil))
    {
        [displayLink invalidate]; // remove from all run loops
        displayLink = nil;
    }
    
    //    if ([self.delegate respondsToSelector:@selector(didCompletePlayingMovie)]) {
    //        [self.delegate didCompletePlayingMovie];
    //    }
    
    /**
     *  @author Austin
     *
     *  @brief  解决播放回调后来没有生效的情况
     *
     *  @since v.1.0
     */
    //    self.delegate = nil;
    
    [readerLock lock];
    
    if (_playReader) {
        if(_playReader.status == AVAssetReaderStatusReading)
            [_playReader cancelReading];
        _playReader = nil;
    }
    [readerLock unlock];
    
    if(_forPlayback){
        audioSampleTime=0;
        bOver   =NO;
        isPlaying =NO;
    }
}

- (void)cancelProcessing
{
    if (_playReader) {
        if(_playReader.status == AVAssetReaderStatusReading)
            [_playReader cancelReading];
    }
    [self endProcessing];
}

- (void)convertYUVToRGBOutput;
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
    return _playReader;
}

- (BOOL)audioEncodingIsFinished {
    return audioEncodingIsFinished;
}

- (BOOL)videoEncodingIsFinished {
    return videoEncodingIsFinished;
}


- (void)processAudioFrame:(CMSampleBufferRef)audioSampleBuffer;
{

    CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(audioSampleBuffer);
    _currentAudioSampleTime  = CMTimeGetSeconds(currentSampleTime);
    
    //        NSLog(@"process Audio Frame:%f\n",_currentAudioSampleTime );
    //   CMItemCount numSamplesInBuffer = CMSampleBufferGetNumSamples(movieSampleBuffer);
    AudioBufferList  audioBufferList;
    CMBlockBufferRef blockBuffer;
    
    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(audioSampleBuffer,
                                                            NULL,
                                                            &audioBufferList,
                                                            sizeof(audioBufferList),
                                                            NULL,
                                                            NULL,
                                                            kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                                                            &blockBuffer);
    //20170511 emmet 解决旋转后在片段编辑没声音的bug
    bool suc = true;
    if(tpCircularBuffer1.length == 0){
       suc = RDTPCircularBufferInit(&tpCircularBuffer1, sizeForSeconds(40));
    }
    
    if(!suc){
        NSLog(@"***RDTPCircularBufferInit fail***");
        return;
    }
    
    if (!RDTPCircularBufferCopyAudioBufferList(&tpCircularBuffer1, &audioBufferList, NULL, kRDTPCircularBufferCopyAll, NULL))
    {
        NSLog(@"gfullCircularBuffer=YES");
        gfullCircularBuffer=YES;
        while (!RDTPCircularBufferCopyAudioBufferList(&tpCircularBuffer1, &audioBufferList, NULL, kRDTPCircularBufferCopyAll, NULL)
               &&tpCircularBuffer1.length>0
               )
        {//&&gfullCircularBuffer
            NSLog(@"循环");
            usleep(100000);
            //sleep(0.01);
        }
    }
    else
    {
        gfullCircularBuffer=NO;
        
    }

    if (blockBuffer) {
        CFRelease(blockBuffer);
        blockBuffer = nil;
    }
}
- (void) uninitAudio
{
    if(audioUnit){
        AudioUnitUninitialize(audioUnit);
        AudioComponentInstanceDispose(audioUnit);
        audioUnit = nil;
    }
    RDTPCircularBufferCleanup(&tpCircularBuffer1);

}

- (void) initAudio
{
    if(audioUnit){
        return;
    }
    //tpCircularBuffer1.length = 0;
    //如果在这里调用 RDTPCircularBufferInit ，添加MV后没有声音
    //RDTPCircularBufferInit(&tpCircularBuffer1, sizeForSeconds(40));//176400*40); //...
    
    
    OSStatus status;
    // 设置话筒模式
    // kAudioSessionCategory_SoloAmbientSound 用于非以语音为主的应用，使用这个category的应用会随着静音键和屏幕关闭而静音。并且会中止其它应用播放声音
    //emmet20170112 AVAudioSessionCategoryPlayback 禁用静音按键
    //SInt32 ambient = kAudioSessionCategory_SoloAmbientSound;//;

    SInt32 ambient = kAudioSessionCategory_MediaPlayback;//;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (AudioSessionSetProperty (kAudioSessionProperty_AudioCategory, sizeof (ambient), &ambient))
    {
        //        NSLog(@"Error setting ambient property");
    }
#pragma clang diagnostic pop
    
    // Describe audio component
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Get component
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    
    // Get audio units
    status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    checkAudioStatus(status);
    
    UInt32 flag = 1;
    // Enable IO for playback
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output,
                                  kOutputBus,//inElement 0为输出端 1为输入端
                                  &flag,
                                  sizeof(flag));
    checkAudioStatus(status);
    
    // Describe format
    AudioStreamBasicDescription audioFormat;
#if 0
    audioFormat.mSampleRate			= 90000;

#else
    audioFormat.mSampleRate			= AUDIOSAMPLERATE;//(_audioSampleRate==0 ? 44100 : _audioSampleRate)/*emmet20161125 44100.00*/;

#endif
    audioFormat.mFormatID			= kAudioFormatLinearPCM;
    audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioFormat.mFramesPerPacket	= 1;
    audioFormat.mChannelsPerFrame	= 2;
    audioFormat.mBitsPerChannel		= 16;
    audioFormat.mBytesPerPacket		= 4;
    audioFormat.mBytesPerFrame		= 4;
    
    
    // Apply format
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    checkAudioStatus(status);
    
    // Set output callback
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = playbackCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Global,
                                  kOutputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    checkAudioStatus(status);
    
    // Allocate our own buffers (1 channel, 16 bits per sample, thus 16 bits per frame, thus 2 bytes per frame).
    // Practice learns the buffers used contain 512 frames, if this changes it will be fixed in processAudio.
    //tempBuffer.mNumberChannels = 1;
    //tempBuffer.mDataByteSize   = 512 * 2;
    //tempBuffer.mData           = malloc( 512 * 2 );
    
    // Initialise
    status = AudioUnitInitialize(audioUnit);
    checkAudioStatus(status);
}

- (void) startPlayingAudio
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    //emmet20170112 AVAudioSessionCategoryPlayback 禁用静音按键
    BOOL suc = [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    if(!suc){
        NSLog(@"faile");
    }
    _allowEnter = YES;
    OSStatus status = AudioOutputUnitStart(audioUnit);
    checkAudioStatus(status);
}

- (void) stopPlayingAudio
{
    _allowEnter = NO;
    OSStatus status = AudioOutputUnitStop(audioUnit);
    checkAudioStatus(status);
    RDTPCircularBufferClear(&tpCircularBuffer1);
    //屏蔽下面这句，下面这句会导致第二次播放没声音
    //RDTPCircularBufferCleanup(&tpCircularBuffer1);
    //20170511 emmet 屏蔽 [self audioClearUp]; 调用了RDTPCircularBufferClear 再调用 RDTPCircularBufferCleanup 会崩溃
    //[self audioClearUp];//20170414 wuxiaoxia bug:每次进入一个界面播放视频，退出该界面后内存就会增加
}

@end
