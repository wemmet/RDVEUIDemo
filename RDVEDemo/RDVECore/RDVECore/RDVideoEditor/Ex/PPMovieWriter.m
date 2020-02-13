#import "PPMovieWriter.h"
#import "RDGPUImageContext.h"
#import "RDGLProgram.h"
#import "RDGPUImageFilter.h"
#import "PPMovieManager.h"
#import "sys/utsname.h"
#import "PPMovie.h"
#include <sys/stdio.h>
#define WAITEAUDIOWRITED 0 //20170515 emmet  1 等待音频写完在写视频 ，0 音频 视频一起写
#define AVDELTA 0.5
NSString *const kPPColorSwizzlingFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate).bgra;
 }
);


@interface PPMovieWriter ()
{
    GLuint movieFramebuffer, movieRenderbuffer;
    
    RDGLProgram *colorSwizzlingProgram;
    GLint colorSwizzlingPositionAttribute, colorSwizzlingTextureCoordinateAttribute;
    GLint colorSwizzlingInputTextureUniform;

    RDGPUImageFramebuffer *firstInputFramebuffer;
    
    CMTime startTime, previousFrameTime, previousAudioTime;

    dispatch_queue_t audioQueue, videoQueue;
    BOOL audioEncodingIsFinished, videoEncodingIsFinished;

    BOOL isRecording;
    
    NSArray<AVMetadataItem*> *videoMetadata;
    float       _currenttime;
    float       _totalVideoDuration;
    void(^rd_exportprogress)(NSNumber* percent);
    
    //BOOL    kickOffAudioRuning;
    //BOOL    kickOffVideoRuning;
    int         _audioBitRate;
    int         _audioChannelNumbers;
}


@property(nonatomic, strong) AVAssetReader *assetAudioReader;
@property(nonatomic, strong) AVAssetReaderAudioMixOutput *assetAudioReaderTrackOutput;

/**
 *  @author Beijing Ruidong iOS Multimedia Team
 *
 *  Austin
 */
//@property(nonatomic, assign) dispatch_group_t recordingDispatchGroup;
@property(nonatomic,strong) dispatch_group_t recordingDispatchGroup;

@property(nonatomic, assign) BOOL audioFinished, videoFinished, isFrameRecieved,isFirstFrameBlackPicture;
@property(nonatomic, copy)  void (^onFramePixelBufferReceived)(CMTime, CVPixelBufferRef);

// Movie recording
- (void)initializeMovieWithOutputSettings:(NSMutableDictionary *)outputSettings;

// Frame rendering
- (void)createDataFBO;
- (void)destroyDataFBO;
- (void)setFilterFBO;

- (void)renderAtInternalSizeUsingFramebuffer:(RDGPUImageFramebuffer *)inputFramebufferToUse;

@end

@implementation PPMovieWriter

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

- (id)initWithMovieURL:(NSURL *)newMovieURL
                  size:(CGSize)newSize
                movies:(NSArray *)movies
              metadata:(NSArray<AVMetadataItem*> *)metadata
      videoMaxDuration:(float) videoMaxDuration
   videoAverageBitRate:(float)videoAverageBitRate
          audioBitRate:(int)audioBitRate
   audioChannelNumbers:(int)audioChannelNumbers
         totalDuration:(float)totalDuration
              progress:(void(^)(NSNumber* percent))progress
{
    if(videoAverageBitRate == 0){
        videoAverageBitRate = 4;//4400000;
    }
    if (audioBitRate == 0) {
        audioBitRate = 128000;
    }else {
        audioBitRate = audioBitRate*1000;
    }
    _audioBitRate = audioBitRate;
    _audioChannelNumbers = audioChannelNumbers;
    _videoMaxDuration = videoMaxDuration;
    _currenttime = 0;
    _totalVideoDuration = totalDuration;
    rd_exportprogress = progress;
    NSDictionary *dic = @
    {
        /*
      AVVideoWidthKey: @(videoSize.width),
      AVVideoHeightKey: @(videoSize.height),
      */
        //TODO emmet 20160325
    AVVideoCodecKey: AVVideoCodecH264,
    AVVideoWidthKey: @(newSize.width),
    AVVideoHeightKey: @(newSize.height),
    AVVideoCompressionPropertiesKey: @
        {
        AVVideoAverageBitRateKey: @(videoAverageBitRate * 1000 * 1000),
        
        //AVVideoProfileLevelKey: AVVideoProfileLevelH264High40,
        //由于极录客的延迟视频画面变化太快，采用 AVVideoProfileLevelH264High40 码率过小时编码器压缩失败，当提高码率(10M)时也可以解决该问题 20170106//AVVideoProfileLevelH264BaselineAutoLevel
//        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,//20190415 这样设置AE模板“充电爱心”会导出不了
        AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel,
        },
    };
    //20170419 fix dead store value
    //NSString * strModelName  = [UIDevice currentDevice].model;
    //NSInteger  modeVersion   = [[UIDevice currentDevice].systemVersion integerValue];
    
    struct utsname systemInfo;//获取设备型号
    uname(&systemInfo);
    NSString * strModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    if([@"iPhone3,1" isEqualToString:strModel]){
        return [self initWithMovieURL:newMovieURL size:newSize fileType:AVFileTypeMPEG4 outputSettings:nil movies:movies metadata:metadata];
    }else{
        return [self initWithMovieURL:newMovieURL size:newSize fileType:AVFileTypeMPEG4 outputSettings:dic movies:movies metadata:metadata];

    }

}

- (id)initWithMovieURL:(NSURL *)newMovieURL size:(CGSize)newSize fileType:(NSString *)newFileType outputSettings:(NSMutableDictionary *)outputSettings movies:(NSArray *)pMovies metadata:(NSArray *)metadata;
{
    if (!(self = [super init]))
    {
		return nil;
    }

    videoMetadata=metadata;// 视频metadata
    self.movies = pMovies;
    _shouldInvalidateAudioSampleWhenDone = NO;
    
    self.enabled = YES;
    alreadyFinishedRecording = NO;
    videoEncodingIsFinished = NO;
    audioEncodingIsFinished = NO;

    videoSize = newSize;
    movieURL = newMovieURL;
    fileType = newFileType;
    startTime = kCMTimeInvalid;
    _encodingLiveVideo = [[outputSettings objectForKey:@"EncodingLiveVideo"] isKindOfClass:[NSNumber class]] ? [[outputSettings objectForKey:@"EncodingLiveVideo"] boolValue] : YES;
    previousFrameTime = kCMTimeNegativeInfinity;
    previousAudioTime = kCMTimeNegativeInfinity;
    inputRotation = kRDGPUImageNoRotation;
    
    _movieWriterContext = [RDGPUImageContext sharedImageProcessingContext];//20170414 wuxiaoxia 修改bug：反复导出，内存会持续增长
//    _movieWriterContext = [[RDGPUImageContext alloc] init];
//    [_movieWriterContext useSharegroup:[[[RDGPUImageContext sharedImageProcessingContext] context] sharegroup]];

    rdRunSynchronouslyOnContextQueue(_movieWriterContext, ^{
        [_movieWriterContext useAsCurrentContext];
        
        if ([RDGPUImageContext supportsFastTextureUpload])
        {
            colorSwizzlingProgram = [_movieWriterContext programForVertexShaderString:kRDGPUImageVertexShaderString fragmentShaderString:kRDGPUImagePassthroughFragmentShaderString];
        }
        else
        {
            colorSwizzlingProgram = [_movieWriterContext programForVertexShaderString:kRDGPUImageVertexShaderString fragmentShaderString:kPPColorSwizzlingFragmentShaderString];
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

- (void)releasecanshu{
    @try {
        rd_exportprogress = nil;
        self.audioProcessingCallback = nil;
        self.audioInputReadyCallback = nil;
        self.videoInputReadyCallback = nil;
        self.completionBlock = nil;
        self.failureBlock = nil;
        self.movies = nil;
        self.movieWriterContext = nil;
        self.assetAudioReader = nil;
        self.assetAudioReaderTrackOutput = nil;
        if (self.recordingDispatchGroup) {
            self.recordingDispatchGroup = nil;
        }
        self.onFramePixelBufferReceived= nil;
        
    } @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    } @finally {
        
    }
    
}
- (void)dealloc;
{
    //
    
    
    NSLog(@"%s:PPMovieWriter is dealloced ",__func__);
    @try {
        [self destroyDataFBO];
    } @catch (NSException *exception) {
        NSLog(@"exception:%@",exception);
    }

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
    isRecording = NO;
    
    self.enabled = YES;
    NSError *error = nil;
    assetWriter = [[AVAssetWriter alloc] initWithURL:movieURL fileType:fileType error:&error];
    


    
    
    if(videoMetadata.count>0){
        assetWriter.metadata= videoMetadata;
    }
    if (error != nil)
    {
        NSLog(@"Error: %@", error);
        if (failureBlock) 
        {
            failureBlock(error);
        }
        else 
        {
            if(_delegate){
                if([_delegate respondsToSelector:@selector(movieRecordingFailedWithError:)])
                {
                    [_delegate movieRecordingFailedWithError:error];
                }
            }
        }
    }
    
    // Set this to make sure that a functional movie is produced, even if the recording is cut off mid-stream. Only the last second should be lost in that case.
    assetWriter.movieFragmentInterval = CMTimeMakeWithSeconds(1, VIDEO_TIMESCALE);//kCMTimeInvalid;//
    //20170515 emmet 
    assetWriter.movieTimeScale = VIDEO_TIMESCALE;
    assetWriter.shouldOptimizeForNetworkUse = YES;//开启网络优化
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
		NSString *videoCodec = [outputSettings objectForKey:AVVideoCodecKey];
		NSNumber *width = [outputSettings objectForKey:AVVideoWidthKey];
		NSNumber *height = [outputSettings objectForKey:AVVideoHeightKey];
		
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
        
    self.assetWriterPixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:assetWriterVideoInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    [assetWriter addInput:assetWriterVideoInput];
}

- (void)setEncodingLiveVideo:(BOOL) value
{
    _encodingLiveVideo = value;
    if (isRecording) {
        NSAssert(NO, @"Can not change Encoding Live Video while recording");
    }
    else
    {
        assetWriterVideoInput.expectsMediaDataInRealTime = _encodingLiveVideo;
        assetWriterAudioInput.expectsMediaDataInRealTime = _encodingLiveVideo;
    }
}

#pragma mark setupAssetWriter
- (void)setupAudioAssetReader {
#if 1
    NSLog(@"****%s,line:%d",__func__,__LINE__);
    PPMovie *movie =self.movies[0];
    self.assetAudioReader = [AVAssetReader assetReaderWithAsset:movie.compositon error:nil];
    NSLog(@"****%s,line:%d",__func__,__LINE__);
    NSArray *audioTracks = [movie.compositon tracksWithMediaType:AVMediaTypeAudio];
    BOOL shouldRecordAudioTrack = ([audioTracks count] > 0);
    
    for (int i =0; i<audioTracks.count; i++) {
        AVMutableCompositionTrack *track = audioTracks[i];
        NSArray *segments = track.segments;
        NSLog(@"segments[%d]:%@",i,segments);
    }
    if (shouldRecordAudioTrack)
    {
//        Float64 audioSampleRate = [[AVAudioSession sharedInstance] currentHardwareSampleRate];//正在通话时，获取到的值为16000,会导致导出失败
        
        NSMutableDictionary *audioOutputSettings = [NSMutableDictionary dictionary];
        [audioOutputSettings setObject:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
        [audioOutputSettings setObject:[NSNumber numberWithFloat:44100/*wuxiaoxia20161230 */] forKey:AVSampleRateKey];
//        [audioOutputSettings setObject:[NSNumber numberWithFloat:(audioSampleRate==0 ? 44100 : audioSampleRate)/*emmet20161125 */] forKey:AVSampleRateKey];
        [audioOutputSettings setObject:[NSNumber numberWithInt:_audioChannelNumbers] forKey:AVNumberOfChannelsKey];
        //          [audioOutputSettings setObject:[NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)] forKey:AVChannelLayoutKey];
        [audioOutputSettings setObject:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
        [audioOutputSettings setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
        [audioOutputSettings setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
        [audioOutputSettings setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsNonInterleaved];
        
        self.assetAudioReaderTrackOutput = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:audioTracks audioSettings:audioOutputSettings];
//        self.assetAudioReaderTrackOutput = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:audioTracks audioSettings:nil;
        self.assetAudioReaderTrackOutput.audioMix = movie.audioMix;
        self.assetAudioReaderTrackOutput.alwaysCopiesSampleData = NO;
        [self.assetAudioReader addOutput:self.assetAudioReaderTrackOutput];
    }

    
#else
    NSMutableArray *audioTracks = [NSMutableArray array];

    for(PPMovie *movie in self.movies){
        AVAsset *asset = movie.asset;
        if(asset){
            NSArray *_audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
            if(_audioTracks.count > 0){
                [audioTracks addObject:_audioTracks.firstObject];
            }
        }
    }

    NSLog(@"audioTracks: %@", audioTracks);

    AVMutableComposition* mixComposition = [AVMutableComposition composition];

    for(AVAssetTrack *track in audioTracks){
        if(![track isKindOfClass:[NSNull class]]){
            //NSLog(@"track url: %@ duration: %.2f", track.asset, CMTimeGetSeconds(track.asset.duration));
            AVMutableCompositionTrack *compositionCommentaryTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio

                                                                                                preferredTrackID:kCMPersistentTrackID_Invalid];
            [compositionCommentaryTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, track.asset.duration)
                                                ofTrack:track
                                                 atTime:kCMTimeZero error:nil];
        }
    }

    self.assetAudioReader = [AVAssetReader assetReaderWithAsset:mixComposition error:nil];
    self.assetAudioReaderTrackOutput =
            [[AVAssetReaderAudioMixOutput alloc] initWithAudioTracks:[mixComposition tracksWithMediaType:AVMediaTypeAudio]
                                                       audioSettings:nil];

    [self.assetAudioReader addOutput:self.assetAudioReaderTrackOutput];
#endif
}

- (NSDictionary *)audioSettings{
    NSLog(@"****%s,line:%d",__func__,__LINE__);
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    if (_audioChannelNumbers == 1) {
        channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    }else {
        channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    }
//    Float64 audioSampleRate = [[AVAudioSession sharedInstance] currentHardwareSampleRate];//正在通话时，获取到的值为16000,会导致导出失败
    NSLog(@"****%s,line:%d",__func__,__LINE__);
    NSDictionary *audioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                   [ NSNumber numberWithInt: _audioChannelNumbers], AVNumberOfChannelsKey,
                                   [ NSNumber numberWithFloat:44100], AVSampleRateKey,
//                                   [ NSNumber numberWithInt:AVAudioQualityMax], AVEncoderAudioQualityKey,

                                   
                                   [ NSData dataWithBytes:&channelLayout length: sizeof( AudioChannelLayout ) ], AVChannelLayoutKey,
                                   //                                   [ NSNumber numberWithInt: 32000 ], AVEncoderBitRateKey,
                                   [ NSNumber numberWithInt: _audioBitRate ], AVEncoderBitRateKey,//比特率
                                   nil];
    NSLog(@"****%s,line:%d",__func__,__LINE__);
    return audioSettings;
}


- (void)setupAudioAssetWriter{
    /**
     *  @author Beijing Ruidong iOS Multimedia Team
     *
     *  by Austin fix this issue
     */
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wdeprecated-declarations"
//    double preferredHardwareSampleRate = [[AVAudioSession sharedInstance] currentHardwareSampleRate];
//#pragma clang diagnostic pop
    
//    double preferredHardwareSampleRate = [[AVAudioSession sharedInstance] currentHardwareSampleRate];
#if 1 // use costom
    NSDictionary *audioOutputSettings =[self audioSettings];
#else

    AudioChannelLayout acl;
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
#endif
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

    NSLog(@"****%s,line:%d        \n audioOutputSettings:%@",__func__,__LINE__,audioOutputSettings);
    //assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:nil];
    assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
    //20170515 emmet  Cannot set a non-default media time scale on an asset writer input with media type AVMediaTypeAudio'
    //assetWriterAudioInput.mediaTimeScale = VIDEO_TIMESCALE;
    NSLog(@"****%s,line:%d",__func__,__LINE__);
    [assetWriter addInput:assetWriterAudioInput];
    assetWriterAudioInput.expectsMediaDataInRealTime = _encodingLiveVideo;
    NSLog(@"****%s,line:%d",__func__,__LINE__);
}


- (void)startRecording;
{
    NSLog(@"****%s,line:%d",__func__,__LINE__);
    __unsafe_unretained typeof(self) weakSelf = self;
    dispatch_group_wait([PPMovieManager shared].readingAllReadyDispatchGroup,DISPATCH_TIME_FOREVER);
    NSLog(@"****%s,line:%d",__func__,__LINE__);
    //等待直到完成
    dispatch_group_notify([PPMovieManager shared].readingAllReadyDispatchGroup, dispatch_get_main_queue(), ^{
        NSLog(@"****%s,line:%d",__func__,__LINE__);
        [weakSelf setupAudioAssetReader];
        [weakSelf setupAudioAssetWriter];
        NSLog(@"****%s,line:%d",__func__,__LINE__);

        BOOL aduioReaderStartSuccess = [weakSelf.assetAudioReader startReading];
        if(!aduioReaderStartSuccess){
            return;
        }
        alreadyFinishedRecording = NO;
        isRecording = YES;

        startTime = kCMTimeInvalid;
        [weakSelf.assetWriter startWriting];
        [weakSelf.assetWriter startSessionAtSourceTime:kCMTimeZero];
        NSLog(@"****%s,line:%d",__func__,__LINE__);
        [weakSelf kickoffRecording];
    });
}

                                            
- (void)kickoffRecording {
    NSLog(@"****%s,line:%d",__func__,__LINE__);

    //20170516 talker
    _currentAudioSampleTime=kCMTimeZero;
    _currentVideoSampleTime=kCMTimeZero;
    
    // If the asset reader and writer both started successfully, create the dispatch group where the reencoding will take place and start a sample-writing session.
    self.recordingDispatchGroup = dispatch_group_create();
    _audioFinished = NO;
    self.videoFinished = NO;
    __unsafe_unretained typeof(self) weakSelf = self;
    //kickOffAudioRuning = NO;
    //kickOffVideoRuning = NO;
    //[NSThread detachNewThreadSelector:@selector(changeExportProgress) toTarget:weakSelf withObject:nil];
    NSLog(@"****%s,line:%d",__func__,__LINE__);

    [self kickOffAudioWriting];
    [self kickOffVideoWriting];
    NSLog(@"****%s,line:%d",__func__,__LINE__);

    //[NSThread detachNewThreadSelector:@selector(kickOffAudioWriting) toTarget:self withObject:nil];
    
    //[NSThread detachNewThreadSelector:@selector(kickOffVideoWriting) toTarget:self withObject:nil];
    
    // Set up the notification that the dispatch group will send when the audio and video work have both finished.
    dispatch_group_notify(self.recordingDispatchGroup, [PPMovieManager shared].mainSerializationQueue, ^{
        
//        while(!(kickOffAudioRuning&&kickOffVideoRuning)){
//            usleep(300000);
//        }
//        weakSelf.videoFinished = NO;
//        weakSelf.audioFinished = NO;
        @try {
            if(weakSelf.assetWriter.status == AVAssetWriterStatusCancelled){
                if(weakSelf.failureBlock){
                    weakSelf.failureBlock(nil);
                }
                [weakSelf releasecanshu];
            }else{
                [weakSelf.assetWriter finishWritingWithCompletionHandler:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //20170615 添加中断操作
                        if(weakSelf.assetWriter.status == AVAssetWriterStatusFailed || _cancelReading){
                            if(weakSelf.failureBlock){
                                NSLog(@"weakSelf.assetWriter.error:%@",[weakSelf.assetWriter.error description]);
                                weakSelf.failureBlock(weakSelf.assetWriter.error);
                            }
                        }
                        else{
                            NSLog(@"导出视频完成后回调-->completionBlock:%@",completionBlock);
                            if(weakSelf.completionBlock){
                                //RDRunSynchronouslyOnVideoProcessingQueue(^{
                                //glFinish(); //talker 161129 test black screen problem
                                // });
                                
                                weakSelf.completionBlock();
                                //[weakSelf performSelector:@selector(releasecanshu) withObject:nil afterDelay:0.5];//20170317 解决不释放的bug
                            }
                        }
                        [weakSelf releasecanshu];
                    });
                    
                }];
            }
            
        } @catch (NSException *exception) {
            NSLog(@"->%s--> exception:%@",__func__,exception);
            if(weakSelf.failureBlock){
                weakSelf.failureBlock(nil);
            }
            [weakSelf releasecanshu];
        }
    });


}

- (void)changeExportProgress{
    if(rd_exportprogress){
        //dispatch_group_enter(self.recordingDispatchGroup);
#if 0
        float totalDuration = _videoMaxDuration!= 0 ? _videoMaxDuration : _totalVideoDuration;
        float progress = self.videoWroteDuration/(float)totalDuration;
        
        while(progress<1){
            progress = self.videoWroteDuration/(float)totalDuration;
            NSString *moveProgress=[NSString stringWithFormat:@"%f",progress];
            NSLog(@"****导出进度:%f",progress);
            if (![moveProgress isEqualToString:@"nan"]) {
                //20170419 fix dead store value
                //float time = self.videoWroteDuration;
                //NSLog(@"exprotProgress:%f",progress);
                rd_exportprogress([NSNumber numberWithFloat:progress]);
            }
            usleep(400000);
        }
#else
        
//#if WAITEAUDIOWRITED
//        float totalDuration = (_videoMaxDuration!= 0 && _videoMaxDuration < _totalVideoDuration) ? _videoMaxDuration : _totalVideoDuration;
//        float progress = (self.audioWroteDuration*1.0/5.0 + self.videoWroteDuration/(float)totalDuration;
//
//#else
        float totalDuration = (_videoMaxDuration!= 0 && _videoMaxDuration < _totalVideoDuration) ? _videoMaxDuration : _totalVideoDuration;
        float progress = self.videoWroteDuration/ totalDuration;

//#endif
        
        NSString *moveProgress=[NSString stringWithFormat:@"%f",progress];
        NSLog(@"****导出进度:%f",progress);
        if (![moveProgress isEqualToString:@"nan"]) {
            //20170419 fix dead store value
            //float time = self.videoWroteDuration;
            //NSLog(@"exprotProgress:%f",progress);
            rd_exportprogress([NSNumber numberWithFloat:MIN(progress, 1.0)]);
        }
       // dispatch_group_leave(self.recordingDispatchGroup);
#endif
    }
    
}

- (void)kickOffAudioWriting{
    NSLog(@"****%s",__func__);
    dispatch_group_enter(self.recordingDispatchGroup);

    __unsafe_unretained typeof(self) weakSelf = self;

    CMTime shortestDuration = kCMTimeInvalid;

    for(PPMovie *movie in self.movies) {
        AVAsset *asset = movie.compositon;
        if(CMTIME_IS_INVALID(shortestDuration)){
            shortestDuration = asset.duration;
            NSLog(@"shortestDuration1: %.2f", CMTimeGetSeconds(shortestDuration));
            
        }else{
            if(CMTimeCompare(asset.duration, shortestDuration) == -1){
                shortestDuration = asset.duration;
                NSLog(@"shortestDuration2: %.2f", CMTimeGetSeconds(shortestDuration));
            }
        }
    }

    _cancelReading = NO;
    
    if(_audioFinished){
        return;
    }
    NSLog(@"****来了");
    [assetWriterAudioInput requestMediaDataWhenReadyOnQueue:[PPMovieManager shared].rwAudioSerializationQueue usingBlock:^{
        // Because the block is called asynchronously, check to see whether its task is complete.
        if (weakSelf.audioFinished){
            //kickOffAudioRuning = YES;
            return;
        }
        NSLog(@"%s %d", __func__, __LINE__);
        BOOL completedOrFailed = NO;
        float export_time = 0;
        // If the task isn't complete yet, make sure that the input is actually ready for more media data.
        while (assetWriterAudioInput.readyForMoreMediaData && !completedOrFailed) {
            if(_cancelReading){
                if (!audioEncodingIsFinished && assetWriterAudioInput.readyForMoreMediaData) {
                    //NSLog(@"#############%s audioEncodingIsFinished:%@", __func__, audioEncodingIsFinished ? @"YES" : @"NO");
                    audioEncodingIsFinished = YES;
                    [weakSelf->assetWriterAudioInput markAsFinished];
//                    NSLog(@"%s assetWriterAudioInput markAsFinished   ", __func__);
                }
                [weakSelf.assetAudioReader cancelReading];
                _audioFinished = YES;
                dispatch_group_leave(weakSelf.recordingDispatchGroup);
                break;
            }
#if 0  //http://blog.csdn.net/xiejiashu/article/details/51111972 ，mediaTimeScale 才是正解
            // Get the next audio sample buffer, and append it to the output file.
            CMSampleBufferRef sampleBuffer = [weakSelf.assetAudioReaderTrackOutput copyNextSampleBuffer];
            if (sampleBuffer != NULL) {
                CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
                NSLog(@"\n\n***currentSampleTime.timescale : %d ***\n\n",currentSampleTime.timescale);
                

                CMItemCount count;
                CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, 0, nil, &count);
                CMSampleTimingInfo *pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
                CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, count, pInfo, &count);
                for (CMItemCount i = 0; i < count; i++) {
                    pInfo[i].decodeTimeStamp = CMTimeMake(CMTimeGetSeconds(pInfo[i].decodeTimeStamp) * 600, 600);
                    pInfo[i].presentationTimeStamp = CMTimeMake(CMTimeGetSeconds(pInfo[i].presentationTimeStamp) * 600, 600);
                    pInfo[i].duration = CMTimeMake(CMTimeGetSeconds(pInfo[i].duration) * 600, 600);
                }
                
                CMSampleBufferRef sout;
                CMSampleBufferCreateCopyWithNewTiming(nil, sampleBuffer, count, pInfo, &sout);
                free(pInfo);

                
                currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sout);
                NSLog(@"\n\n***sout.timescale : %d ***\n\n",currentSampleTime.timescale);
                BOOL isDone = CMTimeCompare(shortestDuration, currentSampleTime) == -1;
                weakSelf.audioWroteDuration = CMTimeGetSeconds(currentSampleTime);
                BOOL success = NO;
                
                success = [assetWriterAudioInput appendSampleBuffer:sout];
                if(success){
//                    NSLog(@"suc to appendAudio at time: %.2f", CMTimeGetSeconds(currentSampleTime));
                }else{
                    NSLog(@"Failed to appendAudio at time: %.2f", CMTimeGetSeconds(currentSampleTime));
                    
                }
                //[NSThread sleepForTimeInterval:0.2];
                
                CFRelease(sampleBuffer);
                sampleBuffer = nil;
                CFRelease(sout);
                sout = nil;
                completedOrFailed = !success;
                
                if(isDone){
                    //time out mark as finish
                    completedOrFailed = YES;
                }
                if(_cancelReading){
                    dispatch_group_leave(weakSelf.recordingDispatchGroup);
                    [self.assetAudioReader cancelReading];
                }
                if(_videoMaxDuration<CMTimeGetSeconds(currentSampleTime) && _videoMaxDuration!=0){
                    [assetWriterAudioInput markAsFinished];
                    _audioFinished = YES;
                    dispatch_group_leave(weakSelf.recordingDispatchGroup);
                }
                }
#else
                
            CMSampleBufferRef sampleBuffer = [weakSelf.assetAudioReaderTrackOutput copyNextSampleBuffer];
            if (sampleBuffer != NULL) {
                CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
//                NSLog(@"\n\n***currentSampleTime.timescale : %d ***\n\n",currentSampleTime.timescale);
                BOOL isDone = CMTimeCompare(shortestDuration, currentSampleTime) == -1;
                weakSelf.audioWroteDuration = CMTimeGetSeconds(currentSampleTime);
                BOOL success = NO;
                
                success = [assetWriterAudioInput appendSampleBuffer:sampleBuffer];
                if(success){
//                    NSLog(@"suc to appendAudio at time: %.2f", CMTimeGetSeconds(currentSampleTime));
                }else{
                    NSLog(@"Failed to appendAudio at time: %.2f", CMTimeGetSeconds(currentSampleTime));
                    
                }
                
                
#if 1 //不做音视频同步
                weakSelf.currentAudioSampleTime=currentSampleTime;//talker start

                
                while (CMTimeCompare(currentSampleTime, weakSelf.currentVideoSampleTime) && !audioEncodingIsFinished && !_videoFinished)
                {
                    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
                    CMTime tDelta=CMTimeSubtract(currentSampleTime, weakSelf.currentVideoSampleTime);
                    //20170615 添加中断操作
                    if(CMTimeCompare(tDelta, CMTimeMakeWithSeconds(AVDELTA, tDelta.timescale))==-1 || _cancelReading || _videoFinished)
                    {
                        break;
                    }
                    CFAbsoluteTime sleep_time_start = CFAbsoluteTimeGetCurrent();
                    [NSThread sleepForTimeInterval:0.15];
                    float sleep_time = CFAbsoluteTimeGetCurrent() - sleep_time_start;
                    CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
                    export_time += end - start;
                    NSLog(@"audio wait video..., atime%f vtime%f sleep_time:%f export_time:%f ",CMTimeGetSeconds(currentSampleTime),CMTimeGetSeconds(weakSelf.currentVideoSampleTime),sleep_time,export_time);
                }
                //talker end
#endif
                
                
                //[NSThread sleepForTimeInterval:0.2];
                
                CFRelease(sampleBuffer);
                sampleBuffer = nil;
#endif
                
                completedOrFailed = !success;
                
                if(isDone){
                    //time out mark as finish
                    completedOrFailed = YES;
                }
                
                //20170615 添加中断操作
//                if(_cancelReading){
//                   [weakSelf.assetAudioReader cancelReading];
//                    _audioFinished = NO;
//                    dispatch_group_leave(weakSelf.recordingDispatchGroup);
//                    break;
//                }
                if(_videoMaxDuration<CMTimeGetSeconds(currentSampleTime) && _videoMaxDuration!=0){
                    [assetWriterAudioInput markAsFinished];
                    _audioFinished = YES;
                    dispatch_group_leave(weakSelf.recordingDispatchGroup);
                    break;
                }
                
                //[NSThread sleepForTimeInterval:0.2];
            }
            else {
                completedOrFailed = YES;
                
            }
            [weakSelf changeExportProgress];
            //[NSThread detachNewThreadSelector:@selector(changeExportProgress) toTarget:self withObject:nil];
            
        }//end of loop
        allowAlready = NO;
        if (completedOrFailed || !assetWriterAudioInput.readyForMoreMediaData) {
            //            NSLog(@"kickOffAudioWriting wrint done");
            // Mark the input as finished, but only if we haven't already done so, and then leave the dispatch group (since the audio work has finished).
            BOOL oldFinished = weakSelf.audioFinished;
            _audioFinished = YES;
            //kickOffAudioRuning = YES;
            if (!oldFinished) {
                if (isRecording){
                    @try {
                        //NSLog(@"#############%s assetWriterAudioInput markAsFinished   assetWriterAudioInput.readyForMoreMediaData:%@", __func__, assetWriterAudioInput.readyForMoreMediaData ? @"YES" : @"NO");
                        [assetWriterAudioInput markAsFinished];//emmet20161202
                        
                    } @catch (NSException *exception) {
                        NSLog(@"->%s--> exception:%@",__func__,exception);
                        [weakSelf.assetWriter cancelWriting];
                    }
                }
                dispatch_group_leave(weakSelf.recordingDispatchGroup);
            };
        }
    }];
}

- (void)kickOffVideoWriting {
    NSLog(@"****%s",__func__);
    dispatch_group_enter(self.recordingDispatchGroup);
    self.isFirstFrameBlackPicture = NO;
    self.isFrameRecieved = NO;

    __unsafe_unretained typeof(self) weakSelf = self;
    self.firstVideoFrameTime = -1;
    _onFramePixelBufferReceived = ^(CMTime frameTime, CVPixelBufferRef pixel_buffer){
        
#if 0
        //20170515 emmet 修正导出时 Timescale  http://blog.csdn.net/xiejiashu/article/details/51111972 ， mediaTimeScale 才是正解
        frameTime = CMTimeMake(CMTimeGetSeconds(frameTime) *600, 600);
#endif
        
        
        //NSLog(@"\n\nframeTime.timescale:%d***\n\n",frameTime.timescale);
        weakSelf.videoWroteDuration = CMTimeGetSeconds(frameTime);
        [weakSelf changeExportProgress];
        //[NSThread detachNewThreadSelector:@selector(changeExportProgress) toTarget:weakSelf withObject:nil];
        //NSLog(@"读取数据:%f",weakSelf.videoWroteDuration);
        
        BOOL writeSucceeded;
#if 0
        UIImage *image = [UIImage imageNamed:@"RDVEUISDK.bundle/pixel_buffer.png"];
        
        CVPixelBufferRef buffer = NULL;
        
        CVPixelBufferRef pixel_buffer = NULL;
        CVPixelBufferCreateWithBytes(kCFAllocatorDefault, finalSize.width, finalSize.height, kCVPixelFormatType_32BGRA, imageData, finalSize.width * 4, RDStillImageDataReleaseCallback, NULL, NULL, &pixel_buffer);
        
        ///AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
        //
        //                                                                                                                 sourcePixelBufferAttributes:nil];
        buffer = [self pixelBufferFromCGImage:[image CGImage]];
        
        @try{
            writeSucceeded=[weakSelf.assetWriterPixelBufferInput appendPixelBuffer:buffer
                                                              withPresentationTime:frameTime];
        }
        @catch(NSException *exception){
            NSLog(@"%@",exception);
            weakSelf.videoFinished = YES;
            weakSelf.audioFinished = YES;
            [weakSelf.assetAudioReader cancelReading];
            [weakSelf.assetWriter cancelWriting];
            dispatch_group_leave(weakSelf.recordingDispatchGroup);
            [assetWriterVideoInput markAsFinished];
            
            NSLog(@"[assetWriterVideoInput markAsFinished] %s %d",__func__,__LINE__);
            kickOffVideoRuning = YES;
            return ;
        }
#else
        @try{

            //检查当前画面数据是否为解码失败的黑屏数据
            bool black_picture = true;
            GLubyte *pixelBufferData = (GLubyte *)CVPixelBufferGetBaseAddress(pixel_buffer);
            int w = (int)(CVPixelBufferGetWidth(pixel_buffer));
           
            for (int i = 0; i<w; i++) {
//                NSLog(@"i : %d [0]:%p [1]:%p [2]:%p time:%f",i,pixelBufferData[i*4],pixelBufferData[i*4+1],pixelBufferData[i*4+2],CMTimeGetSeconds(frameTime));
                if(i<(w/2-10))
                {
                    if(pixelBufferData[i*4] != 0xff || pixelBufferData[i*4+1] != 0xff || pixelBufferData[i*4+2] != 0xff)
                    {
                        black_picture = false;
                        break;
                    }
                }
                else if(i > (w/2+10))
                {
                    if(pixelBufferData[i*4] != 0x00 || pixelBufferData[i*4+1] != 0xff || pixelBufferData[i*4+2] != 0x00)
                    {
                        black_picture = false;
                        break;
                    }
                }
            }
            
            //如果当前画面是黑屏，解码失败造成，不需要写入文件
            if(black_picture)
            {
                NSLog(@"black_picture is true");
                if(CMTimeGetSeconds(weakSelf.currentVideoSampleTime) == 0)
                    self.isFirstFrameBlackPicture = YES;
            }
            else
            {
                /*
                 如果视频第一帧解码失败，导出时候如果音频时间戳是重 0 开始，那么视频的第一帧时间戳也必须是 0 ，否则导出后画面第一帧黑屏
                 如果视频第一帧解码正常，导出的时候需要根据传入的frametime作为时间戳写入文件，否则导出提示操作无法完成
                 
                 */
                if(self.isFirstFrameBlackPicture && CMTimeGetSeconds(weakSelf.currentVideoSampleTime) == 0)
                {
                    writeSucceeded=[weakSelf.assetWriterPixelBufferInput appendPixelBuffer:pixel_buffer
                                                                      withPresentationTime:weakSelf.currentVideoSampleTime];
                }
                else
                    writeSucceeded=[weakSelf.assetWriterPixelBufferInput appendPixelBuffer:pixel_buffer
                                                                  withPresentationTime:frameTime];
                
                
                
#if 1 //不做音视频同步
                weakSelf.currentVideoSampleTime=frameTime;//talker start
                
                NSLog(@"video_time:%f audio_time:%f",CMTimeGetSeconds(weakSelf.currentVideoSampleTime),CMTimeGetSeconds(weakSelf.currentAudioSampleTime));
                
                while (CMTimeCompare(frameTime, weakSelf.currentAudioSampleTime) && !videoEncodingIsFinished && !_audioFinished)
                {
                    CMTime tDelta=CMTimeSubtract(frameTime, weakSelf.currentAudioSampleTime);
                    //20170615 添加中断操作
                    if(CMTimeCompare(tDelta, CMTimeMakeWithSeconds(AVDELTA, tDelta.timescale))==-1 || _cancelReading || _audioFinished)
                    {
                        break;
                    }
                    [NSThread sleepForTimeInterval:0.1];
                    NSLog(@"video wait audio..., vtime%f atime%f",CMTimeGetSeconds(frameTime),CMTimeGetSeconds(weakSelf.currentAudioSampleTime));
                }
                //talker end
#endif
            }
            

        }
        @catch(NSException *exception){
            NSLog(@"%@",exception);
            weakSelf.videoFinished = YES;
            weakSelf.audioFinished = YES;
            [weakSelf.assetAudioReader cancelReading];
            [weakSelf.assetWriter cancelWriting];
            dispatch_group_leave(weakSelf.recordingDispatchGroup);
            [weakSelf->assetWriterVideoInput markAsFinished];
            //NSLog(@"#############%s assetWriterVideoInput markAsFinished   assetWriterVideoInput.readyForMoreMediaData:%@", __func__, assetWriterVideoInput.readyForMoreMediaData ? @"YES" : @"NO");
            
//            NSLog(@"[assetWriterVideoInput markAsFinished] %s %d",__func__,__LINE__);
            //kickOffVideoRuning = YES;
            return ;
        }
#endif
        if(weakSelf->assetWriterVideoInput.readyForMoreMediaData)
        {
            if(writeSucceeded){
//                NSLog(@"suc to appendVideo at time: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, frameTime)));
            }else{
                NSLog(@"weakSelf.assetWriter.error:%@",[weakSelf.assetWriter.error description]);
                NSLog(@"Failed to appendVideo at time: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, frameTime)));
            }
            //if(pixel_buffer)
            //[NSThread sleepForTimeInterval:0.05];
            //20170615 添加中断操作
            if(weakSelf->_cancelReading){
                //NSLog(@"#############%s assetWriterVideoInput markAsFinished   assetWriterVideoInput.readyForMoreMediaData:%@", __func__, assetWriterVideoInput.readyForMoreMediaData ? @"YES" : @"NO");
                [weakSelf->assetWriterVideoInput markAsFinished];
                weakSelf.videoFinished = YES;
                dispatch_group_leave(weakSelf.recordingDispatchGroup);

            }
            if(_videoMaxDuration<CMTimeGetSeconds(frameTime) && _videoMaxDuration!=0){
                [weakSelf->assetWriterVideoInput markAsFinished];
                weakSelf.videoFinished = YES;
                //kickOffVideoRuning = YES;
                
                dispatch_group_leave(weakSelf.recordingDispatchGroup);
            }
        }
        else
        {
            //[NSThread sleepForTimeInterval:0.1];
        }
        
        if(weakSelf.firstVideoFrameTime == -1){
            weakSelf.firstVideoFrameTime = CMTimeGetSeconds(frameTime);
        }
        CVPixelBufferUnlockBaseAddress(pixel_buffer, 0);
        
        
        if (![RDGPUImageContext supportsFastTextureUpload])
        {
            CVPixelBufferRelease(pixel_buffer);
        }
        weakSelf.isFrameRecieved = NO;
    };

    [assetWriterVideoInput requestMediaDataWhenReadyOnQueue:[PPMovieManager shared].rwVideoSerializationQueue usingBlock:^{
        if(assetWriterAudioInput.readyForMoreMediaData){
           
#if WAITEAUDIOWRITED
            while(assetWriterAudioInput.readyForMoreMediaData){
                NSLog(@"等待音频写完");
                usleep(200000);
                if(_audioFinished){
                    break;
                }
            }
#endif
        }
        if (weakSelf.videoFinished){
            //kickOffVideoRuning = YES;
            return;
        }
        
        BOOL completedOrFailed = NO;
        while ([assetWriterVideoInput isReadyForMoreMediaData] && !completedOrFailed) {
//            NSLog(@"%s",__func__);
            if(!weakSelf.isFrameRecieved){
                weakSelf.isFrameRecieved = YES;
                for(PPMovie *movie in weakSelf.movies){
                    BOOL hasMoreFrame;
                    @try{
                        hasMoreFrame = [movie renderNextFrame];
                    }@catch(NSException *exception){
                        NSLog(@"exception:%@",exception);
                    }
                    if(!hasMoreFrame || _cancelReading){
                        completedOrFailed = YES;
                        break;
                    }
                }
//                NSLog(@"%s",__func__);
            }
            //NSLog(@"renderNextFrame 回来:%d",completedOrFailed);
            //[NSThread sleepForTimeInterval:0.1];
        }
        if(completedOrFailed){
            BOOL oldFinished = weakSelf.videoFinished;
            weakSelf.videoFinished = YES;
            //kickOffVideoRuning = YES;
            if (!oldFinished) {
                for(PPMovie *movie in weakSelf.movies){
                    [movie cancelProcessing];
                }
                @try {
//                    NSLog(@"#############%s assetWriterVideoInput markAsFinished   assetWriterVideoInput.readyForMoreMediaData:%@", __func__, assetWriterVideoInput.readyForMoreMediaData ? @"YES" : @"NO");
                    [assetWriterVideoInput markAsFinished];//emmet20161202
                } @catch (NSException *exception) {
                    NSLog(@"->%s--> exception:%@",__func__,exception);
                    [weakSelf.assetWriter cancelWriting];
                }
                dispatch_group_leave(weakSelf.recordingDispatchGroup);
            }
        }
    }];
}
                                            
- (void)startRecordingInOrientation:(CGAffineTransform)orientationTransform;
{
	assetWriterVideoInput.transform = orientationTransform;

	[self startRecording];
}

- (void)cancelRecording;
{
#if 0
    _cancelReading = YES;
    return;
#else
    NSLog(@"_assetAudioReader.status:%zd", _assetAudioReader.status);
    if (assetWriter.status == AVAssetWriterStatusCompleted || _assetAudioReader.status != AVAssetReaderStatusReading)
    {
        return;
    }
    __unsafe_unretained typeof(self) weakSelf = self;
    dispatch_group_enter(self.recordingDispatchGroup);
    
    rdRunSynchronouslyOnContextQueue(_movieWriterContext, ^{
        alreadyFinishedRecording = YES;

        if(weakSelf.assetAudioReader.status == AVAssetWriterStatusWriting && ! audioEncodingIsFinished )
        {
            if (isRecording && assetWriterAudioInput.readyForMoreMediaData){
                //NSLog(@"#############%s audioEncodingIsFinished:%@", __func__, audioEncodingIsFinished ? @"YES" : @"NO");
                audioEncodingIsFinished = YES;
                [assetWriterAudioInput markAsFinished];//emmet20161202
//                NSLog(@"%s assetWriterAudioInput markAsFinished   ", __func__);
            }
            [weakSelf.assetAudioReader cancelReading];
        }
        if( assetWriter.status == AVAssetWriterStatusWriting && ! videoEncodingIsFinished )
        {
            videoEncodingIsFinished = YES;
//            NSLog(@"#############%s assetWriterVideoInput markAsFinished   assetWriterVideoInput.readyForMoreMediaData:%@ assetWriter.status：%@", __func__, assetWriterVideoInput.readyForMoreMediaData ? @"YES" : @"NO", assetWriter.status ? @"YES" : @"NO");
            @try {
                [assetWriterVideoInput markAsFinished];//emmet20161202                
            } @catch (NSException *exception) {
                NSLog(@"->%s--> exception:%@ assetWriter.status:%d",__func__,exception, assetWriter.status);
                [weakSelf.assetWriter cancelWriting];
            }
        }
    });
    isRecording = NO;
    dispatch_group_leave(self.recordingDispatchGroup);
#endif
}

- (void)finishRecording;
{
    [self finishRecordingWithCompletionHandler:NULL];
}

- (void)finishRecordingWithCompletionHandler:(void (^)(void))handler;
{
    __unsafe_unretained typeof(self) weakSelf = self;
    rdRunSynchronouslyOnContextQueue(_movieWriterContext, ^{
        isRecording = NO;
        
        if (assetWriter.status == AVAssetWriterStatusCompleted || assetWriter.status == AVAssetWriterStatusCancelled || assetWriter.status == AVAssetWriterStatusUnknown)
        {
            if (handler)
                rdRunAsynchronouslyOnContextQueue(_movieWriterContext, handler);
            return;
        }
        if( assetWriter.status == AVAssetWriterStatusWriting && ! videoEncodingIsFinished )
        {
            videoEncodingIsFinished = YES;
            @try {
                [assetWriterVideoInput markAsFinished];//emmet20161202
                //NSLog(@"#############%s assetWriterVideoInput markAsFinished   assetWriterVideoInput.readyForMoreMediaData:%@", __func__, assetWriterVideoInput.readyForMoreMediaData ? @"YES" : @"NO");

            } @catch (NSException *exception) {
               NSLog(@"->%s--> exception:%@",__func__,exception);
               [weakSelf.assetWriter cancelWriting];
            }
        }
        if( assetWriter.status == AVAssetWriterStatusWriting && ! audioEncodingIsFinished )
        {
            audioEncodingIsFinished = YES;
            @try {
                [assetWriterAudioInput markAsFinished];//emmet20161202
                //NSLog(@"#############%s assetWriterAudioInput markAsFinished   assetWriterAudioInput.readyForMoreMediaData:%@", __func__, assetWriterAudioInput.readyForMoreMediaData ? @"YES" : @"NO");

            } @catch (NSException *exception) {
                NSLog(@"->%s--> exception:%@",__func__,exception);
                [weakSelf.assetWriter cancelWriting];
            }
        }
#if (!defined(__IPHONE_6_0) || (__IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_6_0))
        // Not iOS 6 SDK
        [assetWriter finishWriting];
        if (handler)
            RDRunAsynchronouslyOnContextQueue(_movieWriterContext,handler);
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
    });
}

- (void)processAudioBuffer:(CMSampleBufferRef)audioBuffer;
{
    if (!isRecording)
    {
        return;
    }
    
//    if (_hasAudioTrack && CMTIME_IS_VALID(startTime))
    if (_hasAudioTrack)
    {
        CFRetain(audioBuffer);

        CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(audioBuffer);
//        NSLog(@"\n\n***currentSampleTime.timescale : %d ***\n\n",currentSampleTime.timescale);
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
            if (audioBuffer != nil) {                
                CFRelease(audioBuffer);
                audioBuffer = nil;
            }
            return;
        }

        previousAudioTime = currentSampleTime;
        
        //if the consumer wants to do something with the audio samples before writing, let him.
        if (self.audioProcessingCallback) {
            //need to introspect into the opaque CMBlockBuffer structure to find its raw sample buffers.
            CMBlockBufferRef buffer = CMSampleBufferGetDataBuffer(audioBuffer);
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
                self.audioProcessingCallback(&samples, audioBufferList.mBuffers[bufferCount].mDataByteSize/2);//Fixed audioProcessingCallbacks memory leak and misuse of numSamplesInBuffer
            }
            if (buffer) {
                CFRelease(buffer);
                buffer = nil;
            }
        }
        
        NSLog(@"Recorded audio sample time: %lld, %d, %lld", currentSampleTime.value, currentSampleTime.timescale, currentSampleTime.epoch);
        void(^write)() = ^() {
            while( ! assetWriterAudioInput.readyForMoreMediaData && ! _encodingLiveVideo && ! audioEncodingIsFinished ) {
                NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:0.5];
                NSLog(@"audio waiting...");
                [[NSRunLoop currentRunLoop] runUntilDate:maxDate];
            }
//            if (!assetWriterAudioInput.readyForMoreMediaData)
            if (previousFrameTime.value >= currentSampleTime.value)//Avoid pushing old frames.
            {
                NSLog(@"Skipping invalid frame (behind previousFrameTime");
            } else if (!assetWriterAudioInput.readyForMoreMediaData)
            {
                NSLog(@"2: Had to drop an audio frame %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentSampleTime)));
            }
            else if(assetWriter.status == AVAssetWriterStatusWriting)
            {
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
            if (audioBuffer) {
                CFRelease(audioBuffer);
            }
        };
        audioBuffer = nil;
//        RDRunAsynchronouslyOnContextQueue(_movieWriterContext, write);
        if( _encodingLiveVideo )

        {
            rdRunAsynchronouslyOnContextQueue(_movieWriterContext, write);
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
        __unsafe_unretained typeof(self) weakSelf = self;
        videoQueue = dispatch_queue_create("com.sunsetlakesoftware.RD.videoReadingQueue", NULL);
        [assetWriterVideoInput requestMediaDataWhenReadyOnQueue:videoQueue usingBlock:^{
            if( _paused )
            {
                //NSLog(@"video requestMediaDataWhenReadyOnQueue paused");
                // if we don't sleep, we'll get called back almost immediately, chewing up CPU
                usleep(100000);
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
                            @try {
                                [assetWriterVideoInput markAsFinished];//emmet20161202
                                NSLog(@"[assetWriterVideoInput markAsFinished] %s %d",__func__,__LINE__);

                            } @catch (NSException *exception) {
                                NSLog(@"->%s--> exception:%@",__func__,exception);
                                [weakSelf.assetWriter cancelWriting];
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
        __unsafe_unretained typeof(self) weakSelf = self;
        audioQueue = dispatch_queue_create("com.sunsetlakesoftware.RD.audioReadingQueue", NULL);
        [assetWriterAudioInput requestMediaDataWhenReadyOnQueue:audioQueue usingBlock:^{
            if( _paused )
            {
                //NSLog(@"audio requestMediaDataWhenReadyOnQueue paused");
                // if we don't sleep, we'll get called back almost immediately, chewing up CPU
                usleep(100000);
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
                            
                            @try {
                                [assetWriterAudioInput markAsFinished];//emmet20161202
                                //NSLog(@"#############%s assetWriterAudioInput markAsFinished   assetWriterAudioInput.readyForMoreMediaData:%@", __func__, assetWriterAudioInput.readyForMoreMediaData ? @"YES" : @"NO");

                            } @catch (NSException *exception) {
                                NSLog(@"->%s--> exception:%@",__func__,exception);
                                [weakSelf.assetWriter cancelWriting];
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
        

        CVPixelBufferPoolCreatePixelBuffer (NULL, [self.assetWriterPixelBufferInput pixelBufferPool], &renderTarget);

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
    
	
	GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    @try{
        NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);

    }@catch(NSException *exception){
    
    }
}

- (void)destroyDataFBO;
{
    //20170623 emmet 修复导出过程中多次点击home键崩溃的bug
    if(!_movieWriterContext){
        movieFramebuffer = 0;
        if ([RDGPUImageContext supportsFastTextureUpload])
        {
            if (renderTexture)
            {
                CFRelease(renderTexture);
                renderTexture = nil;
            }
            if (renderTarget)
            {
                CVPixelBufferRelease(renderTarget);
                renderTarget = nil;
            }
            
        }
        return;
    }
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
                renderTexture = nil;
            }
            if (renderTarget)
            {
                CVPixelBufferRelease(renderTarget);
                renderTarget = nil;
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
#pragma mark RDInput protocol

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    //NSLog(@"%s %d",__func__,__LINE__);
    
    if (!isRecording)
    {
        [firstInputFramebuffer unlock];
        return;
    }

//    // Drop frames forced by images and other things with no time constants
//    // Also, if two consecutive times with the same value are added to the movie, it aborts recording, so I bail on that case
//    if ( (CMTIME_IS_INVALID(frameTime)) || (CMTIME_COMPARE_INLINE(frameTime, ==, previousFrameTime)) || (CMTIME_IS_INDEFINITE(frameTime)) )
//    {
//        [firstInputFramebuffer unlock];
//        return;
//    }
//
//    if (CMTIME_IS_INVALID(startTime))
//    {
//        RDRunSynchronouslyOnContextQueue(_movieWriterContext, ^{
//            if ((videoInputReadyCallback == NULL) && (assetWriter.status != AVAssetWriterStatusWriting))
//            {
//                [assetWriter startWriting];
//            }
//
//            [assetWriter startSessionAtSourceTime:frameTime];
//            startTime = frameTime;
//        });
//    }

    RDGPUImageFramebuffer *inputFramebufferForBlock = firstInputFramebuffer;
    glFinish();

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
        CVReturn status = CVPixelBufferPoolCreatePixelBuffer (NULL, [self.assetWriterPixelBufferInput pixelBufferPool], &pixel_buffer);
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


    //emmet 20161213
    
    __unsafe_unretained typeof(self) weakSelf = self;
    rdRunAsynchronouslyOnContextQueue(_movieWriterContext, ^{
        if (!assetWriterVideoInput.readyForMoreMediaData && _encodingLiveVideo)
        {
            [inputFramebufferForBlock unlock];
            NSLog(@"1: Had to drop a video frame: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, frameTime)));
            return;
        }
        
        // Render the frame with swizzled colors, so that they can be uploaded quickly as BGRA frames
        [_movieWriterContext useAsCurrentContext];
        [weakSelf renderAtInternalSizeUsingFramebuffer:inputFramebufferForBlock];
        
        CVPixelBufferRef pixel_buffer = NULL;
        
        if ([RDGPUImageContext supportsFastTextureUpload])
        {
            pixel_buffer = renderTarget;
            CVPixelBufferLockBaseAddress(pixel_buffer, 0);
        }
        else
        {
            CVReturn status = CVPixelBufferPoolCreatePixelBuffer (NULL, [self.assetWriterPixelBufferInput pixelBufferPool], &pixel_buffer);
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
        
//        NSLog(@"%s %d",__func__,__LINE__);
        if(weakSelf.onFramePixelBufferReceived){
            weakSelf.onFramePixelBufferReceived(frameTime, pixel_buffer);
        }
        
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
//    RDRunSynchronouslyOnContextQueue(_movieWriterContext, ^{
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
//    if (completionBlock)
//    {
//        if (!alreadyFinishedRecording)
//        {
//            alreadyFinishedRecording = YES;
//            completionBlock();
//        }
//    }
//    else
//    {
//        if (_delegate && [_delegate respondsToSelector:@selector(movieRecordingCompleted)])
//        {
//            [_delegate movieRecordingCompleted];
//        }
//    }
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
            }
            else
            {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                preferredHardwareSampleRate = [[AVAudioSession sharedInstance] currentHardwareSampleRate];
#pragma clang diagnostic pop
            }
#endif
            AudioChannelLayout acl;
            bzero( &acl, sizeof(acl));
//            acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
            acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
            
            audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                         [ NSNumber numberWithInt: 2 ], AVNumberOfChannelsKey,
                                         [ NSNumber numberWithFloat: 44100 ], AVSampleRateKey,
                                         [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                                         //[ NSNumber numberWithInt:AVAudioQualityLow], AVEncoderAudioQualityKey,
                                         [ NSNumber numberWithInt: _audioBitRate ], AVEncoderBitRateKey,
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
        [assetWriter addInput:assetWriterAudioInput];
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
                                            
#if 1
- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image
        {
            
            CGSize frameSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
            NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:NO], kCVPixelBufferCGImageCompatibilityKey,
                                     [NSNumber numberWithBool:NO], kCVPixelBufferCGBitmapContextCompatibilityKey,
                                     nil];
            CVPixelBufferRef pxbuffer = NULL;
            CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width,
                                                  frameSize.height,  kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                                  &pxbuffer);
            NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
            
            CVPixelBufferLockBaseAddress(pxbuffer, 0);
            void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
            
            
            CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
            CGContextRef context = CGBitmapContextCreate(pxdata, frameSize.width,
                                                         frameSize.height, 8, 4*frameSize.width, rgbColorSpace,
                                                         kCGImageAlphaNoneSkipLast);
            
            CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),  
                                                   CGImageGetHeight(image)), image); 
            CGColorSpaceRelease(rgbColorSpace); 
            CGContextRelease(context); 
            
            CVPixelBufferUnlockBaseAddress(pxbuffer, 0); 
            
            return pxbuffer; 
}
#endif

@end
