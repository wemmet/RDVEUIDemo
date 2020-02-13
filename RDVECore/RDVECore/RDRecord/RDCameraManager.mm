//
//  RDCameraManager.m
//  RDVEUISDK
//
//  Created by 周晓林 on 16/4/8.
//
//

//已经失效
//#define AUDIOUNIT
//#define AUDIO_RECORD
//#define AUDIORECORDER //单独录制音频

#import "RDRecordHelper.h"
#import "RDCameraManager.h"
#import "RDGPUImageFilterPipeline.h"
#import "RDGPUImageCropFilter.h"
#import "RDGPUImageStillCamera.h"
#import "RDGPUImageView.h"
#import "RDVideoRecordGPUImageMovieWriter.h"
#import "RDGPUImageTEffectFilter.h"
#import "RDGPUImagePicture.h"
#import "RDGPUImageToneCurveFilter.h"
#import "RDGPUImageGrayscaleFilter.h"
#import "RDRecordGPUImageSketchFilter.h"
#import "RDRecordGPUImageStretchDistortionFilter.h"
#import "RDRecordGPUImageThresholdedNonMaximumSuppressionFilter.h"
#import "RDUFilterGroup.h" // 亮度 曝光度 饱和度 锐度 色温 合并filter
#import "RDLookupFilter.h"
#import "RDMaskFilter.h"
#import "RDGPUImageMaskFilter.h"
#import "RDGPUImageUIElement.h"
#include "SpeexAllHeaders.h"
#include "CAStreamBasicDescription.h"
#import "RDGPUImageAlphaBlendFilter.h"
#import "RDGPUImageCameraMVEffectFilter.h"
#ifdef AUDIORECORDER
#import "AudioRecorder.h"
#endif

#define USEINSERTTIMERANGE 0
#define iPhone4s ([[UIScreen mainScreen] bounds].size.height == 480 || [[UIScreen mainScreen] bounds].size.width == 480)
#define LASTIPHONE_5 [UIScreen mainScreen].bounds.size.width>320
//#define iPhone_XS (([[UIScreen mainScreen] bounds].size.height == 812.0 && [[UIScreen mainScreen] bounds].size.width == 375.0) || ([[UIScreen mainScreen] bounds].size.height == 375.0 && [[UIScreen mainScreen] bounds].size.width == 812.0))
//#define iPhone_XR (([[UIScreen mainScreen] bounds].size.height == 896.0 && [[UIScreen mainScreen] bounds].size.width == 414.0) || ([[UIScreen mainScreen] bounds].size.height == 414.0 && [[UIScreen mainScreen] bounds].size.width == 896.0))
#define iPhone_X (  (([[UIScreen mainScreen] bounds].size.height == 812.0 && [[UIScreen mainScreen] bounds].size.width == 375.0) || ([[UIScreen mainScreen] bounds].size.height == 375.0 && [[UIScreen mainScreen] bounds].size.width == 812.0))   ||   (([[UIScreen mainScreen] bounds].size.height == 896.0 && [[UIScreen mainScreen] bounds].size.width == 414.0) || ([[UIScreen mainScreen] bounds].size.height == 414.0 && [[UIScreen mainScreen] bounds].size.width == 896.0))  )

CGFloat const gestureMinimumTranslation = 20.0;

@implementation RDFilter

- (instancetype)init {
    if (self = [super init]) {
        _intensity = 1.0;
    }
    return self;
}

@end

typedef void (^ ProgressBlock)(NSNumber *prencent);
typedef void (^ CallBlock)();
typedef void (^ RDTakePhotoCompletionHandler)(UIImage* image);

@interface RDCameraManager ()<CAAnimationDelegate,AVAudioPlayerDelegate,RDGPUImageVideoCameraDelegate, RDGPUImageMovieWriterDelegate>
{
    NSTimer                 *_exportTimer;
    AVAssetExportSession    * exporter;
    ProgressBlock            _progressBlock;
    AVAudioPlayer           *_audioPlayer;
    BOOL                     _enableCameraWaterMark;
    BOOL                     _isPlaying;
    CGRect                   _frame;
    CALayer                 *_focusLayer;
    //美颜
    RDGPUImageBeautifyFilter        * beauty;
    BOOL                    _enableRdBeauty;
    
    RDGPUImageFilterPipeline* _filterPipeline;
    RDGPUImageFilterPipeline* _beatyPipeline;
    RDGPUImageCropFilter    * _cropFilter;
    RDUFilterGroup* uFilterGroup;
//    RDMaskFilter *maskFilter;
    RDGPUImageMaskFilter *maskFilter;
    RDGPUImagePicture *maskPicture;
    
    RDGPUImageUIElement *newUIElement;
    RDGPUImageAlphaBlendFilter *newAlphaBlendFilter;
//    UIView * watermarkView;
    
    NSURL           * videoURL;
    UIView          * hideView;
    
    BOOL            _isFront;
    CMTime          diffRecordTime;
    CMTime          startRecordTime;
    double          starthandpanTime;
    double          endhandpanTime;
    CGPoint         _beginHandPanPoint;
    
    BOOL            isFirstEnter;
    
    AVAssetWriter   *_assetWriter;
    CallBlock        _cancelBlock;
    ProgressBlock    _progressReverseBlock;
    AVAssetReader   *_reverseReader;
    AVAssetWriterInput *_writerInput;
    AVAssetReaderTrackOutput*_readerOutput;
    AVAssetWriterInputPixelBufferAdaptor *_pixelBufferAdaptor;
    float            _lastReverseProgress;
    float            _lastReverseWriteProgress;
    BOOL             _cancelExport;
    BOOL             _witeTrackInsertEnd;
    
    double _startTime;
    int oldIndex;
    int currentIndex;
    BOOL beginTeffect;
    RDGPUImageTEffectFilter* tEffectFilter; // 效果切换滤镜
    RDGPUImageOutput<RDGPUImageInput>* oldFilter;
    RDGPUImageOutput<RDGPUImageInput>* newFilter;
    
    RDGPUImageCropFilter* cropFilterT;
    
    BOOL            _disableTakePhoto;
    
    UIDeviceOrientation deviceOrientation;
    
#ifdef AUDIOUNIT
    AUGraph auGraph;
    AudioUnit converterAudioUnit;
    AudioUnit delayAudioUnit;
    AudioChannelLayout *currentRecordingChannelLayout;
#ifdef AUDIO_RECORD
    ExtAudioFileRef             extAudioFile;
    CFURLRef _outputFile;

#endif
    
    AudioStreamBasicDescription currentInputASBD;
    AudioStreamBasicDescription graphOutputASBD;
    AudioBufferList *currentInputAudioBufferList;
    AUOutputBL *outputBufferList;
    
    double                        currentSampleTime;
    BOOL                        didSetUpAudioUnits;
#endif
    
    SpeexPreprocessState* st;
    UIPanGestureRecognizer *pan;
    RDCameraSwipeDirection swipeDirection;
    //MV
//    RDGPUImageOutput<RDGPUImageInput>* mvFilter;
    RDGPUImageCameraMVEffectFilter* mvFilter;
    //拍照 20190711 使用GPUImage的capturePhotoAsImageProcessedUpToFilter方法拍照时，使用第三方sdk渲染滤镜的情况会有问题，故采用buffer转UIImage的方法来实现
    BOOL isTakePhoto;
    RDTakePhotoCompletionHandler takePhotoCompletionHandler;
    UIImageOrientation photoOrientation;
}
/** 已经录制完成的分段视频总时长
  */
@property (nonatomic, assign) float      allRecordTime;
@property (nonatomic, strong) UIView  *watermarkLayer;
@property (nonatomic, strong) UIView  *watermarkView;
@property (nonatomic, strong) UIView  *watermarkBackView;
@property (nonatomic, assign) BOOL sdkDisabled; //sdk是否禁用
@property (nonatomic , strong) NSMutableDictionary* videoSettings;

@property (nonatomic , strong) NSDictionary* audioSettings;

@property (nonatomic , strong) NSMutableArray<RDGPUImageOutput<RDGPUImageInput> *> *filters;
@property (nonatomic , strong) NSMutableArray<RDFilter*> *gFilters;

@property (nonatomic , strong) RDGPUImageVideoCamera *camera;

@property (nonatomic , strong) RDVideoRecordGPUImageMovieWriter* movieWriter;
@property (nonatomic, assign) BOOL faceThinking;
@property (nonatomic, strong) CIDetector *faceDetector;
@property (nonatomic, strong) UIView *leftEyeView;
@property (nonatomic, strong) UIView *rightEyeView;
@property (nonatomic, strong) UIView *mouthView;
@property (nonatomic, strong) UIView *faceView;

//设置输出图像格式，默认为YES
//YES:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
//NO:kCVPixelFormatType_32BGRA
@property(nonatomic, assign) BOOL captureAsYUV;

/** 暂停录制
 */
- (void) pauseRecording;

/** 继续录制
 */
- (void) resumeRecording;

@end


@implementation RDCameraManager

static double handpanMinTime = 0.3;
//static double handpanMinTime = 0.3;
+(CGSize)defaultMatchSize{
    return [RDRecordHelper  matchSize];
}

double radians(float degrees) {
    return ( degrees * 3.14159265 ) / 180.0;
}


- (instancetype)initWithAPPKey:(NSString *)appkey
                     APPSecret:(NSString *)appsecret
                    resultFail:(void (^)(NSError *))resultFailBlock
{
    self = [super init];
    if (self) {
        void (^initFailureBlock)(NSError *error)=^(NSError *error){
            if (resultFailBlock) {
                resultFailBlock(error);
            }
        };
        //检查授权
        _sdkDisabled = NO;
        [RDRecordHelper checkPermissions:appkey
                               appsecret:appsecret
                              LicenceKey:nil
                                 appType:1
                                 success:^{
                                     _sdkDisabled = NO;
                                 } resultFailBlock:^(NSError *error) {
                                     _sdkDisabled = YES;
                                     if(initFailureBlock){
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             initFailureBlock(error);
                                             
                                         });
                                     }
                                 }];
    }
    return self;
}

- (instancetype)initWithAPPKey:(NSString *)appkey
                     APPSecret:(NSString *)appsecret
                    LicenceKey:(NSString *)licenceKey
                    resultFail:(void (^)(NSError *))resultFailBlock
{
    self = [super init];
    if (self) {
        void (^initFailureBlock)(NSError *error)=^(NSError *error){
            if (resultFailBlock) {
                resultFailBlock(error);
            }
        };
        //检查授权
        _sdkDisabled = NO;
        [RDRecordHelper checkPermissions:appkey
                               appsecret:appsecret
                              LicenceKey:licenceKey
                                 appType:1
                                 success:^{
                                     _sdkDisabled = NO;
                                 } resultFailBlock:^(NSError *error) {
                                     _sdkDisabled = YES;
                                     if(initFailureBlock){
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             initFailureBlock(error);
                                             
                                         });
                                     }
                                 }];
    }
    return self;
}

- (void) prepareRecordWithFrame:(CGRect)frame
                      superview:(UIView *)superview
                        bitrate: (int) bitrate
                            fps: (int) fps
                           mode: (BOOL) mode
                     cameraSize: (CGSize)cameraSize
                     outputSize: (CGSize)outputSize
                        isFront:(BOOL) isFront
                          faceU:(BOOL) faceU
                   captureAsYUV:(BOOL) isCaptureAsYUV
               disableTakePhoto:(BOOL) disableTakePhoto{
    [self prepareRecordWithFrame:frame superview:superview bitrate:bitrate fps:fps isSquareRecord:mode cameraSize:cameraSize outputSize:outputSize isFront:isFront captureAsYUV:isCaptureAsYUV disableTakePhoto:disableTakePhoto enableCameraWaterMark:NO enableRdBeauty:!faceU];
}

- (void) prepareRecordWithFrame:(CGRect)frame
                      superview:(UIView *)superview
                        bitrate: (int) bitrate
                            fps: (int) fps
                           mode: (BOOL) mode
                    cameraSize: (CGSize)cameraSize
                     outputSize: (CGSize)outputSize
                        isFront:(BOOL) isFront
                          faceU:(BOOL) faceU
                   captureAsYUV:(BOOL) isCaptureAsYUV
               disableTakePhoto:(BOOL) disableTakePhoto
              enableCameraWaterMark:(BOOL)enableCameraWaterMark
{
    [self prepareRecordWithFrame:frame superview:superview bitrate:bitrate fps:fps isSquareRecord:mode cameraSize:cameraSize outputSize:outputSize isFront:isFront captureAsYUV:isCaptureAsYUV disableTakePhoto:disableTakePhoto enableCameraWaterMark:enableCameraWaterMark enableRdBeauty:!faceU];
}

- (void)prepareRecordWithFrame:(CGRect)frame
                     superview:(UIView *)superview
                       bitrate:(int)bitrate
                           fps:(int)fps
                isSquareRecord:(BOOL)isSquareRecord
                    cameraSize:(CGSize)cameraSize
                    outputSize:(CGSize)outputSize
                       isFront:(BOOL)isFront
                  captureAsYUV:(BOOL)isCaptureAsYUV
              disableTakePhoto:(BOOL)disableTakePhoto
         enableCameraWaterMark:(BOOL)enableCameraWaterMark
                enableRdBeauty:(BOOL)enableRdBeauty
{
    _frame = frame;
    _enableCameraWaterMark = enableCameraWaterMark;
    NSLog(@"%@",NSStringFromCGRect(frame));
    _keyFps = 0;
    _bitrate = bitrate;
    _fps = fps;
    _mode = isSquareRecord;
    self.cameraSize = cameraSize;
    self.outputSize = outputSize;
    _isFront = isFront;
    _cameraDirection = kUP;
    startRecordTime = kCMTimeInvalid;
    _swipeScreenIsChangeFilter = YES;
    _captureAsYUV = isCaptureAsYUV;
    _disableTakePhoto = disableTakePhoto;
    _enableRdBeauty = enableRdBeauty;
    [superview addSubview:self.cameraScreen];
    
    [self setup:isSquareRecord];
#ifdef AUDIOUNIT
    [self initAudioGraph];
#endif
    addCount = 0;
    isFirstEnter = YES;
    
#ifdef AUDIORECORDER
    [[AudioRecorder shareManager] prepareRecord];
#endif
}

#ifdef AUDIOUNIT

- (BOOL) initAudioGraph{
    
#ifdef AUDIO_RECORD
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *destinationFilePath = [NSString stringWithFormat: @"%@/AudioRecording.aif", documentsDirectory];
    _outputFile = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)destinationFilePath, kCFURLPOSIXPathStyle, false);
#endif
    
    AUNode delayNode;
    AUNode converterNode;
    
    // create a new AUGraph
    OSStatus err = NewAUGraph(&auGraph);
    if (err) { printf("NewAUGraph Failed! %ld %08X %4.4s\n", (long)err, (unsigned int)err, (char*)&err); return NO; }
    
    // delay effect
    CAComponentDescription delay_EffectAudioUnitDescription(kAudioUnitType_Effect, kAudioUnitSubType_Delay, kAudioUnitManufacturer_Apple);
    
    // converter
    CAComponentDescription converter_desc(kAudioUnitType_FormatConverter, kAudioUnitSubType_AUConverter, kAudioUnitManufacturer_Apple);
    
    // add nodes to graph
    err = AUGraphAddNode(auGraph, &delay_EffectAudioUnitDescription, &delayNode);
    if (err) { printf("AUGraphNewNode 2 result %lu %4.4s\n", (unsigned long)err, (char*)&err); return NO; }
    
    err = AUGraphAddNode(auGraph, &converter_desc, &converterNode);
    if (err) { printf("AUGraphNewNode 3 result %lu %4.4s\n", (unsigned long)err, (char*)&err); return NO; }
    
    // connect a node's output to a node's input
    // au converter -> delay
    
    err = AUGraphConnectNodeInput(auGraph, converterNode, 0, delayNode, 0);
    if (err) { printf("AUGraphConnectNodeInput result %lu %4.4s\n", (unsigned long)err, (char*)&err); return NO; }
    
    // open the graph -- AudioUnits are open but not initialized (no resource allocation occurs here)
    err = AUGraphOpen(auGraph);
    if (err) { printf("AUGraphOpen result %ld %08X %4.4s\n", (long)err, (unsigned int)err, (char*)&err); return NO; }
    
    // grab audio unit instances from the nodes
    err = AUGraphNodeInfo(auGraph, converterNode, NULL, &converterAudioUnit);
    if (err) { printf("AUGraphNodeInfo result %ld %08X %4.4s\n", (long)err, (unsigned int)err, (char*)&err); return NO; }
    
    err = AUGraphNodeInfo(auGraph, delayNode, NULL, &delayAudioUnit);
    if (err) { printf("AUGraphNodeInfo result %ld %08X %4.4s\n", (long)err, (unsigned int)err, (char*)&err); return NO; }
    
    // Set a callback on the converter audio unit that will supply the audio buffers received from the capture audio data output
    AURenderCallbackStruct renderCallbackStruct;
    renderCallbackStruct.inputProc = PushCurrentInputBufferIntoAudioUnit;
    renderCallbackStruct.inputProcRefCon = (__bridge void*)self;
    
    err = AUGraphSetNodeInputCallback(auGraph, converterNode, 0, &renderCallbackStruct);
    if (err) { printf("AUGraphSetNodeInputCallback result %ld %08X %4.4s\n", (long)err, (unsigned int)err, (char*)&err); return NO; }
    
    AudioUnitSetParameter(delayAudioUnit, kDelayParam_DelayTime, kAudioUnitScope_Global, 0, 0.0, 0);
    return YES;
    
}

- (AudioBufferList *)currentInputAudioBufferList
{
    return currentInputAudioBufferList;
}

static OSStatus PushCurrentInputBufferIntoAudioUnit(void *                            inRefCon,
                                                    AudioUnitRenderActionFlags *    ioActionFlags,
                                                    const AudioTimeStamp *            inTimeStamp,
                                                    UInt32                            inBusNumber,
                                                    UInt32                            inNumberFrames,
                                                    AudioBufferList *                ioData)
{
    
    NSLog(@"%d %s",__LINE__,__func__);
    
    RDCameraManager *self = (__bridge RDCameraManager *)inRefCon;
    
    
    
    
    AudioBufferList *currentInputAudioBufferList = [self currentInputAudioBufferList];
    UInt32 bufferIndex, bufferCount = currentInputAudioBufferList->mNumberBuffers;
    
    if (bufferCount != ioData->mNumberBuffers) return kAudioFormatUnknownFormatError;
    
    // Fill the provided AudioBufferList with the data from the AudioBufferList output by the audio data output
    for (bufferIndex = 0; bufferIndex < bufferCount; bufferIndex++) {
        ioData->mBuffers[bufferIndex].mDataByteSize = currentInputAudioBufferList->mBuffers[bufferIndex].mDataByteSize;
        ioData->mBuffers[bufferIndex].mData = currentInputAudioBufferList->mBuffers[bufferIndex].mData;
        ioData->mBuffers[bufferIndex].mNumberChannels = currentInputAudioBufferList->mBuffers[bufferIndex].mNumberChannels;
    }
    
    return noErr;
}
#endif

- (void)setEnableAntiShake:(BOOL)enableAntiShake{
    _enableAntiShake = enableAntiShake;
    self.camera.enableAntiShake = enableAntiShake;
}

- (void)refreshRecordTime{
    if([_delegate respondsToSelector:@selector(recordTime)]){
        _allRecordTime = [_delegate recordTime];
    }
    diffRecordTime = kCMTimeZero;
}

#pragma mark 初始化
- (void)setup:(BOOL) mode
{
    _audioTime_beforePlay = kCMTimeZero;
    _audioTime_stopPlay = kCMTimeZero;
    deviceOrientation = UIDeviceOrientationPortrait;
    [self setFlashMode:AVCaptureTorchModeOff];
    self.recordStatus = VideoRecordStatusUnknown;
    if(_bitrate ==0){
        _bitrate = 2 * 1000 * 1000;
    }
    if(_fps == 0){
        _fps = 30;
    }
    
    if(_keyFps == 0){
        _keyFps = _fps;
    }
    _audioChannelNumbers = 1;
//    self.beautifyState = BeautifyStateNormal;
//    if (mode) {
//        CGSize matchSize = [RDRecordHelper matchSize];
//
//        
//        CGFloat max = MAX(matchSize.height, matchSize.width);
//        CGFloat min = MIN(matchSize.height, matchSize.width);
//        
//        CGFloat offset = (max - min)/max/2.;
//        CGFloat center = min / max;
//        
//        _cropFilter = [[RDGPUImageCropFilter alloc] initWithCropRegion:CGRectMake(offset, 0.0, center, 1.0)];
//
//
//
//    }else{
    
    CGSize matchSize = [RDRecordHelper matchSize];
    float flag = MIN(MIN(matchSize.width, matchSize.height),MIN(_cameraSize.width, _cameraSize.height));
    if(_cameraSize.width>_cameraSize.height){
        _cameraSize = CGSizeMake(flag * _cameraSize.width/_cameraSize.height, flag);
    }else{
        _cameraSize = CGSizeMake(flag, flag * _cameraSize.height/_cameraSize.width);
    }
#if 0
    CGSize recordSize = _cameraSize;
    
    CGFloat ratey = MIN(recordSize.width/matchSize.width, 1.);
    CGFloat ratex = MIN(recordSize.height/matchSize.height, 1.);
    
    if (matchSize.height <= recordSize.height && matchSize.width <= recordSize.width) {
        float sx = matchSize.height / recordSize.height;
        float sy = matchSize.width / recordSize.width;
        recordSize.height *= MIN(sx, sy);
        recordSize.width *= MIN(sx, sy);
        
    }
    
    CGRect cropRect = CGRectMake((1. - ratex)/2., (1. - ratey)/2., 1.0 * ratex, 1.0 * ratey);
#else   //20181207 wuxiaoxia 改变输出分辨率，不改变预览分辨率
    CGRect cropRect = CGRectMake(0, 0, 1, 1);
#endif
    _cropFilter = [[RDGPUImageCropFilter alloc] initWithCropRegion:cropRect];

//    }

    [self configureAnEmptyPipeline];
    
    RDFilter* filter = [RDFilter new];
    filter.type = kRDFilterType_ACV;
    filter.filterPath = [[NSBundle mainBundle] pathForResource:@"RDVECore.bundle/滤镜_正常" ofType:@"acv"];
    [self addFilters:[NSArray arrayWithObject:filter]];
    
    if(!_watermarkView){
        _watermarkView = [[UIView alloc] init];
        _watermarkView.backgroundColor = [UIColor clearColor];
        [_watermarkBackView addSubview:_watermarkView];
        
        _watermarkLayer = [[UIView alloc] initWithFrame:_frame];
        _watermarkLayer.backgroundColor = [UIColor clearColor];
        [_watermarkView addSubview:_watermarkLayer];
        
        if (_cameraDirection == kUP/*_isPortrait*/) {
            
            CGAffineTransform transform =CGAffineTransformMakeRotation(-M_PI/2);
            if(iPhone_X){
                _watermarkBackView.frame = CGRectMake(0, 0, 736, 414);
                _watermarkLayer.frame = _watermarkBackView.frame;
                _watermarkView.frame = CGRectMake(0, 0, _frame.size.height,  _frame.size.height * 16.0/9.0);//(_frame.size.height * 16.0/9.0 - _frame.size.height)/2.0
                float p = (_watermarkBackView.frame.size.width - _watermarkBackView.frame.size.height)/2.0;
                transform = CGAffineTransformTranslate(transform, p, p);

            }else{
                _watermarkView.frame = CGRectMake(0, 0, _frame.size.height, _frame.size.width);
                float p = ([UIScreen mainScreen].bounds.size.height - [UIScreen mainScreen].bounds.size.width)/2.0;
                transform = CGAffineTransformTranslate(transform, p, p);
                
            }
            
            [_watermarkView setTransform:transform];
            
        }
        else if (_cameraDirection == kDOWN/*_isPortrait*/) {
            _watermarkView.frame = CGRectMake(0, 0, _frame.size.height, _frame.size.width);
            CGAffineTransform transform =CGAffineTransformMakeRotation(-M_PI/2);
            
            float p = ([UIScreen mainScreen].bounds.size.height - [UIScreen mainScreen].bounds.size.width)/2.0;
            transform = CGAffineTransformTranslate(transform, p, p);
            //            if([UIScreen mainScreen].bounds.size.width < 375.0){
            //                transform = CGAffineTransformTranslate(transform, 80, 80);
            //            }else{
            //                transform = CGAffineTransformTranslate(transform, 161, 161);
            //            }
            [_watermarkView setTransform:transform];
        }
        else if (_cameraDirection == kRIGHT/*_isPortrait*/) {
            _watermarkView.frame = _frame;
            CGAffineTransform transform =CGAffineTransformMakeRotation(0);
            [_watermarkView setTransform:transform];
        }
    }
}

- (void)setMusic:(NSURL *)musicUrl{

    NSError *playerError;
    @try {
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:musicUrl error:&playerError];
        NSLog(@"%@",[playerError description]);
    }
    @catch (NSException *exception) {
        
    }
    @finally {
        if(_audioPlayer){
            //AVURLAsset *urlAsset=[[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:musicPath] options:nil];
            NSLog(@"%@",musicUrl);
            NSLog(@"playerError:%@",playerError);
            _audioPlayer.delegate=self;
            _audioPlayer.enableRate = YES;
            _audioPlayer.rate = 1.0;
            [_audioPlayer prepareToPlay];
            _isPlaying = NO;

        }
        
    }
    
}

- (void)playMusic:(float)rate{

    _isPlaying = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_audioPlayer play];
    });
}

- (void)pauseMusic{
    _isPlaying = NO;
    [_audioPlayer pause];
}

- (void)stopMusic{
    _isPlaying = NO;
    [_audioPlayer stop];
}

- (void) changeMode:(BOOL) mode cameraScreenFrame:(CGRect)frame
{
    _mode = mode;
    _frame = frame;
    
//    _cameraScreen.frame = frame;
//    if (mode) {
//        CGSize matchSize = [RDRecordHelper matchSize];
//        
//        
//        CGFloat max = MAX(matchSize.height, matchSize.width);
//        CGFloat min = MIN(matchSize.height, matchSize.width);
//        
//        CGFloat offset = (max - min)/max/2.;
//        CGFloat center = min / max;
//
//        offset = frame.origin.x / min;
//        _cropFilter.cropRegion = CGRectMake(offset, 0.0, center, 1.0);
        
        
//        CGSize matchSize = [RDRecordHelper matchSize];
//        
//        CGSize recordSize = _outputSize;
//        
//        if (matchSize.height <= recordSize.height && matchSize.width <= recordSize.width) {
//            float sx = matchSize.height / recordSize.height;
//            float sy = matchSize.width / recordSize.width;
//            recordSize.height *= MIN(sx, sy);
//            recordSize.width *= MIN(sx, sy);
//            
//        }
//        CGFloat max = MAX(matchSize.height, matchSize.width);
//        CGFloat min = MIN(matchSize.height, matchSize.width);
//        
//        CGFloat offset = (max - min)/max/2.;
//        CGFloat center = min / max;
//
//        
//        CGFloat ratey = MIN(recordSize.width/matchSize.width, 1.);
//        CGFloat ratex = MIN(recordSize.height/matchSize.height, 1.);
//        
//        
//        
//        CGRect cropRect = CGRectMake((1. - ratex)/2., (1. - ratey)/2., 1.0 * ratex, 1.0 * ratey);
//        
//        _cropFilter.cropRegion = cropRect;
//
//        
//    }else{
    
//        CGSize matchSize = [RDRecordHelper matchSize];
//        
//        CGSize recordSize = _outputSize;
//        
//        if (matchSize.height <= recordSize.height && matchSize.width <= recordSize.width) {
//            float sx = matchSize.height / recordSize.height;
//            float sy = matchSize.width / recordSize.width;
//            recordSize.height *= MIN(sx, sy);
//            recordSize.width *= MIN(sx, sy);
//
//        }
//        
//        
//        CGFloat ratey = MIN(recordSize.width/matchSize.width, 1.);
//        CGFloat ratex = MIN(recordSize.height/matchSize.height, 1.);
//        
//        
//        
//        CGRect cropRect = CGRectMake((1. - ratex)/2., (1. - ratey)/2., 1.0 * ratex, 1.0 * ratey);
//        
//        _cropFilter.cropRegion = cropRect;
//    }
    
}


- (void) configureAnEmptyPipeline{
    if (_beatyPipeline == nil) {
        
        [_camera addTarget:_cropFilter];
        
        if(_enableCameraWaterMark){
            if(iPhone_X){
                _watermarkBackView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 736, 414)];
            }else{
                _watermarkBackView = [[UIView alloc] initWithFrame:_frame];
            }
            _watermarkBackView.backgroundColor = [UIColor clearColor];
            
            newUIElement = [[RDGPUImageUIElement alloc] initWithView:_watermarkBackView];
            newAlphaBlendFilter = [[RDGPUImageAlphaBlendFilter alloc] init];
            newAlphaBlendFilter.mix = 1.0;
            
            [newUIElement addTarget:newAlphaBlendFilter atTextureLocation:1];
            _beatyPipeline = [[RDGPUImageFilterPipeline alloc] initWithOrderedFilters:@[newAlphaBlendFilter] input:self.camera output:_cropFilter];
        
        }else{
            _beatyPipeline = [[RDGPUImageFilterPipeline alloc] initWithOrderedFilters:@[] input:self.camera output:_cropFilter];
        }
        tEffectFilter = [[RDGPUImageTEffectFilter alloc] init];
    }
}
- (void) updateCropRegion: (float) rate
{
    
    CGRect cropRect;
    if (_mode) {
        CGFloat offset = (_cameraSize.height - _cameraSize.width *rate)/_cameraSize.height/2.;
        CGFloat center = _cameraSize.width / _cameraSize.height;
        
        cropRect = CGRectMake(offset , (1. - rate)/2., center * rate, 1.0 * rate);
        
        
    }else{
        NSLog(@"%f",rate);
        CGSize matchSize = [RDRecordHelper matchSize];
        
        CGSize recordSize = _cameraSize;
        
        CGFloat ratey = MIN(recordSize.width/matchSize.width, 1.);
        CGFloat ratex = MIN(recordSize.height/matchSize.height, 1.);
        
        
        
        cropRect = CGRectMake((1. - rate * ratex)/2., (1. - rate * ratey)/2., 1.0 * ratex * rate, 1.0 * ratey * rate);
        
        
        //        cropRect = CGRectMake((1. - rate)/2., (1. - rate)/2., 1.0 * rate, 1.0 * rate);
        
    }
    _cropFilter.cropRegion = cropRect;
}
#pragma mark 启用预览
- (void)startCamera{

    [self.camera startCameraCapture];
    
    
    if (isFirstEnter) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * TIMESCALE)), dispatch_get_main_queue(), ^{
            if (_delegate) {
                if([_delegate respondsToSelector:@selector(cameraScreenDid)]){
                    [_delegate cameraScreenDid];
                }
            }
        });
        isFirstEnter = NO;
    }
    
}
#pragma mark 关闭预览
- (void)stopCamera{
    [self.camera stopCameraCapture];
}

#pragma mark 声音设置

- (NSDictionary *)audioSettings{
    if (!_audioSettings) {
        AudioChannelLayout channelLayout;
        memset(&channelLayout, 0, sizeof(AudioChannelLayout));
        if (_audioChannelNumbers <= 0) {
            _audioChannelNumbers = 1;
        }
        if (_audioChannelNumbers == 1) {
            channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
        }else {
            _audioChannelNumbers = 2;
            channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
        }
        /*6plus编码音频 不支持AVEncoderAudioQualityKey、AVSampleRateConverterAudioQualityKey，必须包含AVFormatIDKey、AVSampleRateKey和AVNumberOfChannelsKey三个Key的设置，如果AVNumberOfChannelsKey 大于2，还必须设置AVChannelLayoutKey*/
        _audioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                               [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                               [ NSNumber numberWithInt: _audioChannelNumbers ], AVNumberOfChannelsKey,
                               [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
                               [ NSData dataWithBytes: &channelLayout length: sizeof( channelLayout ) ], AVChannelLayoutKey,
                               [ NSNumber numberWithInt: 128000], AVEncoderBitRateKey,
//                          [NSNumber numberWithInt:AVAudioQualityHigh], AVEncoderAudioQualityKey,
                               nil];
    }
    return _audioSettings;
}

#pragma mark 视频设置
- (NSMutableDictionary *)videoSettings : (CGSize) size{
    if (!_videoSettings) {
        NSMutableDictionary* videoSettings  = [[NSMutableDictionary alloc] init];;
        [videoSettings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
        [videoSettings setObject:[NSNumber numberWithInteger:size.width] forKey:AVVideoWidthKey];
        [videoSettings setObject:[NSNumber numberWithInteger:size.height] forKey:AVVideoHeightKey];
        _videoSettings = videoSettings;
    }
    return _videoSettings;
}



- (NSDictionary *)getVideoOutputSetting:(CGSize )videoSize{

    NSDictionary *videoCleanApertureSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSNumber numberWithInt:videoSize.height], AVVideoCleanApertureWidthKey,
                                                [NSNumber numberWithInt:videoSize.width], AVVideoCleanApertureHeightKey,
                                                [NSNumber numberWithInt:10], AVVideoCleanApertureHorizontalOffsetKey,
                                                [NSNumber numberWithInt:10], AVVideoCleanApertureVerticalOffsetKey,
                                                nil];
    
    NSDictionary *codecSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInt:_bitrate], AVVideoAverageBitRateKey,//960000 码率
                                   [NSNumber numberWithInt:_fps], AVVideoExpectedSourceFrameRateKey,
                                   [NSNumber numberWithInt:_keyFps/*设置关键帧 _fps*/],AVVideoMaxKeyFrameIntervalKey, //帧率
                                   videoCleanApertureSettings, AVVideoCleanApertureKey,
                                   [NSNumber numberWithBool:YES],AVVideoAllowFrameReorderingKey,
                                   AVVideoProfileLevelH264Baseline41,AVVideoProfileLevelKey,
                                   nil];
    
    
    NSDictionary *videoOutputSettings;
    if (_mode) {
        videoOutputSettings= [NSDictionary dictionaryWithObjectsAndKeys:
                              AVVideoCodecH264, AVVideoCodecKey,
                              codecSettings,AVVideoCompressionPropertiesKey,
                              [NSNumber numberWithInt:videoSize.width], AVVideoWidthKey,
                              [NSNumber numberWithInt:videoSize.width], AVVideoHeightKey,
                              nil];

    }else{
       
        
        videoOutputSettings= [NSDictionary dictionaryWithObjectsAndKeys:
                              AVVideoCodecH264, AVVideoCodecKey,
                              codecSettings,AVVideoCompressionPropertiesKey,
                              [NSNumber numberWithInt:videoSize.height], AVVideoWidthKey,
                              [NSNumber numberWithInt:videoSize.width], AVVideoHeightKey,
                              nil];

    }
    return videoOutputSettings;
}

#pragma mark 录制
- (RDVideoRecordGPUImageMovieWriter *)movieWriter{
    if (!_movieWriter) {
        NSLog(@"%s",__func__);
        NSString *path = [self getfilePathStringWithSuffix:@""];
        if(path.length == 0){
            NSLog(@"保存路径出错");
            return nil;
        }
        videoURL = [NSURL fileURLWithPath:path];
        NSDictionary* outputSettings;
        CGSize writerSize = _outputSize;//CGSizeMake(_outputSize.width *0.5, _outputSize.height *0.5);
        
        if (_cameraDirection == kUP || _cameraDirection == kDOWN/*_isPortrait*/) {
            writerSize = CGSizeMake(_outputSize.height, _outputSize.width);
            //writerSize = CGSizeMake(_outputSize.height *0.5, _outputSize.width *0.5);
            
        }
        
        if (_mode) {
//            outputSettings = [self getVideoOutputSetting:[RDRecordHelper matchSize]];
            //20181207 wuxiaoxia 按照设置的输出分辨率
            outputSettings = [self getVideoOutputSetting:CGSizeMake(MIN(writerSize.width, writerSize.height), MIN(writerSize.width, writerSize.height))];
        }else{
            outputSettings = [self getVideoOutputSetting:writerSize];
        }
        
        RDVideoRecordGPUImageMovieWriter* movieWriter = [[RDVideoRecordGPUImageMovieWriter alloc] initWithMovieURL:videoURL size:CGSizeMake(writerSize.height, writerSize.width) fileType:AVFileTypeMPEG4 outputSettings:outputSettings];

        
        movieWriter.assetWriter.movieFragmentInterval = kCMTimeInvalid;
        movieWriter.encodingLiveVideo = YES;
#ifdef AUDIORECORDER
        [movieWriter setHasAudioTrack:NO audioSettings:self.audioSettings];
#else
        if (!_isMute) {
            [movieWriter setHasAudioTrack:YES audioSettings:self.audioSettings];
        }
#endif
        if (_cameraDirection == kUP/*_isPortrait*/) {
            [movieWriter setInputRotation:kRDGPUImageRotateRight atIndex:0];
            
        }
        else if (_cameraDirection == kDOWN/*_isPortrait*/) {
            [movieWriter setInputRotation:kRDGPUImageRotateLeft atIndex:0];
        }
        else if (_cameraDirection == kRIGHT/*_isPortrait*/) {
            [movieWriter setInputRotation:kRDGPUImageRotate180 atIndex:0];
        }
        movieWriter.delegate = self;
        
        
        _movieWriter = movieWriter;
        
        movieWriter = nil;
    }
    return _movieWriter;
}

#pragma mark 摄像头 -  按具体机器适配Preset
- (RDGPUImageVideoCamera *)camera {
    
    if (!_camera) {
        if (_disableTakePhoto) {
            RDGPUImageVideoCamera *camera;
            
            if (_isFront) {
                camera= [[RDGPUImageVideoCamera alloc]
                         initWithSessionPreset:[RDRecordHelper sessionPreset]
                         cameraPosition:AVCaptureDevicePositionFront
                         captureAsYUV:_captureAsYUV];
                _position = AVCaptureDevicePositionFront;
            }else{
                camera= [[RDGPUImageVideoCamera alloc]
                         initWithSessionPreset:[RDRecordHelper sessionPreset]
                         cameraPosition:AVCaptureDevicePositionBack
                         captureAsYUV:_captureAsYUV];
                _position = AVCaptureDevicePositionBack;
            }
            _camera = camera;
        }else{
            RDGPUImageStillCamera *camera;
            
            if (_isFront) {
                camera= [[RDGPUImageStillCamera alloc]
                         initWithSessionPreset:[RDRecordHelper sessionPreset]
                         cameraPosition:AVCaptureDevicePositionFront
                         captureAsYUV:_captureAsYUV];
                _position = AVCaptureDevicePositionFront;
                
            }else{
                camera= [[RDGPUImageStillCamera alloc]
                         initWithSessionPreset:[RDRecordHelper sessionPreset]
                         cameraPosition:AVCaptureDevicePositionBack
                         captureAsYUV:_captureAsYUV];
                _position = AVCaptureDevicePositionBack;
            }
            _camera = camera;
        }
        [_camera setFrameRate:30];
        [self setDeviceOrientation:deviceOrientation];
#if 0   //20191209 这样设置后，前置摄像头获取到的帧还没有镜像，叠加上faceU的贴图后，会将贴图再做镜像，导致贴图上的字反了，如faceU的“ARALE”
        _camera.horizontallyMirrorFrontFacingCamera = YES;
#else
        if (_position == AVCaptureDevicePositionFront) {
            _camera.videoCaptureConnection.videoMirrored = YES;
        }
#endif
        _camera.horizontallyMirrorRearFacingCamera = NO;
        _camera.delegate = self;
        if (!_isMute) {
            [_camera addAudioInputsAndOutputs];
        }
    }
    return _camera;
}

- (void)setIsMute:(BOOL)isMute {
    _isMute = isMute;
    if (_isMute) {
        [_camera removeAudioInputsAndOutputs];
    }else {
        [_camera addAudioInputsAndOutputs];
    }
}

//20190410 wuxiaoxia 解决faceU的一个道具5kgTfgsfEUq9sxsPBwSErD 不能全屏的bug，视频方向要与设置方向一致才能全屏
- (void)setDeviceOrientation:(UIDeviceOrientation)orientation {
    deviceOrientation = orientation;
    if (_position == AVCaptureDevicePositionBack) {
        switch (orientation) {
            case UIDeviceOrientationLandscapeLeft:
                _camera.outputImageOrientation = UIInterfaceOrientationLandscapeRight;
                [_camera.videoCaptureConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
                break;
            case UIDeviceOrientationLandscapeRight:
                _camera.outputImageOrientation = UIInterfaceOrientationLandscapeLeft;
                [_camera.videoCaptureConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                _camera.outputImageOrientation = UIInterfaceOrientationPortrait;
                [_camera.videoCaptureConnection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
                break;
                
            default:
                _camera.outputImageOrientation = UIInterfaceOrientationPortraitUpsideDown;
                [_camera.videoCaptureConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
                break;
        }
    }else {
        switch (orientation) {
            case UIDeviceOrientationLandscapeLeft:
                _camera.outputImageOrientation = UIInterfaceOrientationLandscapeRight;
                [_camera.videoCaptureConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
                break;
            case UIDeviceOrientationLandscapeRight:
                _camera.outputImageOrientation = UIInterfaceOrientationLandscapeLeft;
                [_camera.videoCaptureConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
                break;
                
            default:
#if 0   //20191209 这样设置后，前置摄像头获取到的帧还没有镜像，叠加上faceU的贴图后，会将贴图再做镜像，导致贴图上的字反了，如faceU的“ARALE”
                _camera.outputImageOrientation = UIInterfaceOrientationPortrait;
#else
                _camera.outputImageOrientation = UIInterfaceOrientationPortraitUpsideDown;
#endif
                [_camera.videoCaptureConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
                break;
        }
    }
}

#pragma mark 音频处理
#ifdef AUDIOUNIT
- (void) willOutputAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    OSStatus err = noErr;
    
    // Get the sample buffer's AudioStreamBasicDescription which will be used to set the input format of the audio unit and ExtAudioFile
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    CAStreamBasicDescription sampleBufferASBD(*CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription));
    if (kAudioFormatLinearPCM != sampleBufferASBD.mFormatID) { NSLog(@"Bad format or bogus ASBD!"); return; }
    
    if ((sampleBufferASBD.mChannelsPerFrame != currentInputASBD.mChannelsPerFrame) || (sampleBufferASBD.mSampleRate != currentInputASBD.mSampleRate)) {
        NSLog(@"AVCaptureAudioDataOutput Audio Format:");
        sampleBufferASBD.Print();
        /*
         Although in iOS AVCaptureAudioDataOutput as of iOS 6 will output 16-bit PCM only by default, the sample rate will depend on the hardware and the
         current route and whether you've got any 30-pin audio microphones plugged in and so on. By default, you'll get mono and AVFoundation will request 44.1 kHz,
         but if the audio route demands a lower sample rate, AVFoundation will deliver that instead. Some 30-pin devices present a stereo stream,
         in which case AVFoundation will deliver stereo. If there is a change for input format after initial setup, the audio units receiving the buffers needs
         to be reconfigured with the new format. This also must be done when a buffer is received for the first time.
         */
        currentInputASBD = sampleBufferASBD;
        currentRecordingChannelLayout = (AudioChannelLayout *)CMAudioFormatDescriptionGetChannelLayout(formatDescription, NULL);
        
        if (didSetUpAudioUnits) {
            // The audio units were previously set up, so they must be uninitialized now
            err = AUGraphUninitialize(auGraph);
            NSLog(@"AUGraphUninitialize failed (%ld)", (long)err);
            
            if (outputBufferList) delete outputBufferList;
            outputBufferList = NULL;
        } else {
            didSetUpAudioUnits = YES;
        }
        
        
        // set the input stream format, this is the format of the audio for the converter input bus
        err = AudioUnitSetProperty(converterAudioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &currentInputASBD, sizeof(currentInputASBD));
        
        if (noErr == err) {
            CAStreamBasicDescription outputFormat(currentInputASBD.mSampleRate, currentInputASBD.mChannelsPerFrame, CAStreamBasicDescription::kPCMFormatFloat32, false);
            NSLog(@"AUGraph Output Audio Format:");
            outputFormat.Print();
            
            graphOutputASBD = outputFormat;
            
            // in an au graph, each nodes output stream format (including sample rate) needs to be set explicitly
            // this stream format is propagated to its destination's input stream format
            
            // set the output stream format of the converter
            err = AudioUnitSetProperty(converterAudioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &graphOutputASBD, sizeof(graphOutputASBD));
            if (noErr == err)
                // set the output stream format of the delay
                err = AudioUnitSetProperty(delayAudioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &graphOutputASBD, sizeof(graphOutputASBD));
        }
        
        // Initialize the graph
        if (noErr == err)
            err = AUGraphInitialize(auGraph);
        
        if (noErr != err) {
            NSLog(@"Failed to set up audio units (%ld)", (long)err);
            
            didSetUpAudioUnits = NO;
            bzero(&currentInputASBD, sizeof(currentInputASBD));
        }
        
        CAShow(auGraph);
    }
    
    CMItemCount numberOfFrames = CMSampleBufferGetNumSamples(sampleBuffer); // corresponds to the number of CoreAudio audio frames
    
    // In order to render continuously, the effect audio unit needs a new time stamp for each buffer
    // Use the number of frames for each unit of time continuously incrementing
    currentSampleTime += (double)numberOfFrames;
    
    AudioTimeStamp timeStamp;
    memset(&timeStamp, 0, sizeof(AudioTimeStamp));
    timeStamp.mSampleTime = currentSampleTime;
    timeStamp.mFlags |= kAudioTimeStampSampleTimeValid;
    
    AudioUnitRenderActionFlags flags = 0;
    
    // Create an output AudioBufferList as the destination for the AU rendered audio
    if (NULL == outputBufferList) {
        outputBufferList = new AUOutputBL(graphOutputASBD, numberOfFrames);
    }
    outputBufferList->Prepare(numberOfFrames);
    
    /*
     Get an audio buffer list from the sample buffer and assign it to the currentInputAudioBufferList instance variable.
     The the audio unit render callback called PushCurrentInputBufferIntoAudioUnit can access this value by calling the
     currentInputAudioBufferList method.
     */
    
    // CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer requires a properly allocated AudioBufferList struct
    currentInputAudioBufferList = CAAudioBufferList::Create(currentInputASBD.mChannelsPerFrame);
    
    size_t bufferListSizeNeededOut;
    CMBlockBufferRef blockBufferOut = nil;
    
    err = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer,
                                                                  &bufferListSizeNeededOut,
                                                                  currentInputAudioBufferList,
                                                                  CAAudioBufferList::CalculateByteSize(currentInputASBD.mChannelsPerFrame),
                                                                  kCFAllocatorSystemDefault,
                                                                  kCFAllocatorSystemDefault,
                                                                  kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                                                                  &blockBufferOut);
    
    if (noErr == err) {
        // Tell the effect audio unit to render -- This will synchronously call PushCurrentInputBufferIntoAudioUnit, which will
        // feed currentInputAudioBufferList into the effect audio unit
        err = AudioUnitRender(delayAudioUnit, &flags, &timeStamp, 0, numberOfFrames, outputBufferList->ABL());
        if (err) {
            // kAudioUnitErr_TooManyFramesToProcess may happen on a route change if CMSampleBufferGetNumSamples
            // returns more than 1024 (the default) number of samples. This is ok and on the next cycle this error should not repeat
            NSLog(@"AudioUnitRender failed! (%ld)", err);
        }
        
        CFRelease(blockBufferOut);
        CAAudioBufferList::Destroy(currentInputAudioBufferList);
        currentInputAudioBufferList = NULL;
    } else {
        NSLog(@"CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer failed! (%ld)", (long)err);
    }
    
    if (noErr == err) {
        @synchronized(self) {
            
            
//            if (self.movieWriter.isRecording) {
//                [self.movieWriter processAudioBuffer:sampleBuffer];
//            }
            

//            if (self.movieWriter.isRecording) {
            
//                CMItemCount timingCount;
//                CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, 0, nil, &timingCount);
//                CMSampleTimingInfo *pInfo = (CMSampleTimingInfo *)malloc(sizeof(CMSampleTimingInfo));
//                CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, timingCount, pInfo, &timingCount);
//
//
//                CMSampleBufferRef audioSampleBuffer = NULL;
//
//
//
//                OSStatus error = CMSampleBufferCreate(kCFAllocatorDefault, NULL, true, NULL, NULL, formatDescription, numberOfFrames, 1, pInfo, 0, NULL, &audioSampleBuffer);
//                if (error != noErr) {
//                    NSLog(@"%d %d>>>>>>>>>>\n\n\n",__LINE__,error);
//                }
//                error = CMSampleBufferSetDataBufferFromAudioBufferList(audioSampleBuffer, kCFAllocatorDefault, kCFAllocatorDefault, 0, outputBufferList->ABL());
//
//                if (error != noErr) {
//                    NSLog(@"%d %d>>>>>>>>>>\n\n\n",__LINE__,error);
//                }

            
//                CMSampleBufferSetDataBufferFromAudioBufferList(sampleBuffer, kCFAllocatorDefault, kCFAllocatorDefault, 0, outputBufferList->ABL());
                
//                [self.movieWriter processAudioBuffer:sampleBuffer];
//            }
            
#ifdef AUDIO_RECORD
            if (extAudioFile) {
                //AudioBufferList -> CMSampleBufferRef

                err = ExtAudioFileWriteAsync(extAudioFile, numberOfFrames, outputBufferList->ABL());
            }
#endif
            
        }// @synchronized
        if (err) {
            NSLog(@"ExtAudioFileWriteAsync failed! (%ld)", (long)err);
        }
    }
    
}
#endif

#pragma mark 视频处理
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    if (newUIElement) {
        [newUIElement update];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(_cameraDirection == kUP || _cameraDirection == kDOWN){
                if(iPhone_X){
                    _watermarkLayer.frame = CGRectMake(0, 0, _watermarkBackView.frame.size.height, _watermarkBackView.frame.size.width);
                }else{
                    _watermarkLayer.frame = CGRectMake(0, 0, _frame.size.height, _frame.size.width);
                }
            }else{
                _watermarkLayer.frame = CGRectMake(0, 0, _watermarkBackView.frame.size.width, _watermarkBackView.frame.size.height);
            }
            [_watermarkLayer.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            
            [_watermarkView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            if([_delegate respondsToSelector:@selector(waterMarkProcessingCompletionBlockWithView:withTime:)]){
                [_delegate waterMarkProcessingCompletionBlockWithView:_watermarkLayer withTime:_allRecordTime + CMTimeGetSeconds(diffRecordTime)];
            }
            [_watermarkView addSubview:_watermarkLayer];
        });
    }
    if (_isRecording) {
        
        
        CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
        if (CMTimeCompare(startRecordTime, kCMTimeInvalid) == 0) {
            startRecordTime = CMTimeSubtract(currentSampleTime, CMTimeMake(20, 600));
            //            NSLog(@"startRecordTime:%f", CMTimeGetSeconds(startRecordTime));
            //            NSLog(@"%f",CMTimeGetSeconds(currentSampleTime));
        }
        diffRecordTime = CMTimeSubtract(currentSampleTime, startRecordTime);
        if (mvFilter) {
            mvFilter.currentTime = diffRecordTime;
        }
        if (_delegate && !_sdkDisabled) {
            if ([_delegate respondsToSelector:@selector(currentTime:)]) {
                [_delegate currentTime:CMTimeGetSeconds(diffRecordTime)];
            }
        }
        //_watermarkLayer.text = [NSString stringWithFormat:@"%f",(CMTimeGetSeconds(diffRecordTime) + _allRecordTime)];
    }
    if (_delegate && [_delegate respondsToSelector:@selector(willOutputSampleBuffer:)]) {
        [_delegate willOutputSampleBuffer:sampleBuffer];
    }
    if (isTakePhoto && takePhotoCompletionHandler) {
        isTakePhoto = NO;
        CVPixelBufferRef photoPixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:photoPixelBuffer];
        CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}];
        CGImageRef videoImage = [context createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(photoPixelBuffer), CVPixelBufferGetHeight(photoPixelBuffer))];
        UIImage *image = [UIImage imageWithCGImage:videoImage];
        CGImageRelease(videoImage);
        
        if (photoOrientation != UIImageOrientationUp) {
            image = [self image:image rotation:photoOrientation];
        }
        if (newUIElement) {
            UIGraphicsBeginImageContextWithOptions(_watermarkView.bounds.size, NO, 1.0);
            CGContextRef ctx = UIGraphicsGetCurrentContext();
            [_watermarkView.layer renderInContext:ctx];
            UIImage* watermarkImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            if (image.size.width > image.size.height) {
                watermarkImage = [self image:watermarkImage rotation:UIImageOrientationRight];
            }
            if (!CGSizeEqualToSize(image.size, watermarkImage.size)) {
                watermarkImage = [RDRecordHelper resizeImage:watermarkImage toSize:image.size];
            }
            image = [RDRecordHelper addImage:image withImage:watermarkImage];
        }
        RDGPUImagePicture* stillImageSource = [[RDGPUImagePicture alloc] initWithImage:image];
        [stillImageSource addTarget:newFilter];
        [newFilter useNextFrameForImageCapture];

        __weak typeof(self) weakSelf = self;
        [stillImageSource processImageWithCompletionHandler:^{
            __strong typeof(self) strongSelf = weakSelf;
            UIImage *currentFilteredVideoFrame = [strongSelf->newFilter imageFromCurrentFramebuffer];
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf->takePhotoCompletionHandler(currentFilteredVideoFrame);
            });
        }];
    }
}

#pragma mark 设置对焦图片
- (void)setfocus{

    if (!_focusLayer) {
        
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focus:)];
        [self.cameraScreen addGestureRecognizer:tap];
        

    }
    UIView* focusView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
    focusView.center = self.cameraScreen.center;
    focusView.backgroundColor = [UIColor clearColor];
    focusView.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1].CGColor;
    focusView.layer.borderWidth = 1;
    focusView.layer.cornerRadius = 35;
    focusView.alpha = 1;
    
    UIView* focusView1 = [[UIView alloc] initWithFrame:CGRectMake(6, 6, 58, 58)];
    focusView1.backgroundColor = [UIColor clearColor];
    focusView1.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1].CGColor;
    focusView1.layer.borderWidth = 2;
    focusView1.layer.cornerRadius = 29;
    focusView1.alpha = 1;
    [focusView addSubview:focusView1];
    
    [self.cameraScreen addSubview:focusView];
    
    CALayer * layer = focusView.layer;
    layer.hidden = YES;
    [self.cameraScreen.layer addSublayer:layer];
    _focusLayer = layer;
}
#pragma mark 感光
- (void) exposure:(CGFloat) iso
{
   
        NSError *error;
        if ([self.camera.inputCamera lockForConfiguration:&error]) {
            
            CGFloat minISO = self.camera.inputCamera.activeFormat.minISO;
            CGFloat maxISO = self.camera.inputCamera.activeFormat.maxISO;
            
            CGFloat currentISO = (maxISO - minISO) * iso + minISO;
            
            [self.camera.inputCamera setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:currentISO completionHandler:nil];
            
            [self.camera.inputCamera unlockForConfiguration];
            
        } else {
            NSLog(@"ERROR = %@", error);
        }
}


- (void) zoom:(CGFloat) zoom
{
    NSError *error;
    if ([self.camera.inputCamera lockForConfiguration:&error]) {
        [self.camera.inputCamera rampToVideoZoomFactor:zoom withRate:50];
        [self.camera.inputCamera unlockForConfiguration];
    } else {
        NSLog(@"ERROR = %@", error);
    }
}
#pragma mark 对焦

- (void)focus:(UITapGestureRecognizer *)tap {
    if (_delegate) {
        if([_delegate respondsToSelector:@selector(tapTheScreenFocus)]){
            [_delegate tapTheScreenFocus];
        }
    }
    CGPoint touchPoint = [tap locationInView:tap.view];
    
    NSLog(@"touchPoint %f %f",touchPoint.x,touchPoint.y);
    
    [self layerAnimationWithPoint:touchPoint];
    touchPoint = CGPointMake(touchPoint.x / tap.view.bounds.size.width, touchPoint.y / tap.view.bounds.size.height);
    //if(_isRecording){
        if ([self.camera.inputCamera isFocusPointOfInterestSupported] && [self.camera.inputCamera isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            NSError *error;
            if ([self.camera.inputCamera lockForConfiguration:&error]) {
                [self.camera.inputCamera setFocusPointOfInterest:touchPoint];
                
                [self.camera.inputCamera setFocusMode:AVCaptureFocusModeAutoFocus];
                
                if([self.camera.inputCamera isExposurePointOfInterestSupported] && [self.camera.inputCamera isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
                {
                    [self.camera.inputCamera setExposurePointOfInterest:touchPoint];
                    [self.camera.inputCamera setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                }
                
                [self.camera.inputCamera unlockForConfiguration];
                
            } else {
                NSLog(@"ERROR = %@", error);
            }
        }
        //talker 前置摄像头增加曝光调整 20180408
        else  if([self.camera.inputCamera isExposurePointOfInterestSupported] && [self.camera.inputCamera isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
        {
            NSError *error;
            if ([self.camera.inputCamera lockForConfiguration:&error]) {
                
                [self.camera.inputCamera setExposurePointOfInterest:touchPoint];
                [self.camera.inputCamera setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                [self.camera.inputCamera unlockForConfiguration];
                
            }
            else {
                NSLog(@"ERROR = %@", error);
            }
        }
    //}
}

#pragma mark 对焦动画
- (void)layerAnimationWithPoint:(CGPoint)point {
    if (_focusLayer) {
        //20180410 wuxiaoxia 可连续点击
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(focusLayerNormal) object:nil];

        CALayer *focusLayer = _focusLayer;
        focusLayer.hidden = NO;
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [focusLayer setPosition:point];
        focusLayer.transform = CATransform3DMakeScale(2.0f,2.0f,1.0f);
        [CATransaction commit];
        

        CABasicAnimation *animation = [ CABasicAnimation animationWithKeyPath: @"transform" ];
        animation.toValue = [ NSValue valueWithCATransform3D: CATransform3DMakeScale(1.0f,1.0f,1.0f)];
        animation.duration = 0.3f;
        animation.repeatCount = 1;
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeForwards;
        [focusLayer addAnimation: animation forKey:@"animation"];
        [self performSelector:@selector(focusLayerNormal) withObject:nil afterDelay:1.3f];
    }
}

#pragma mark 拍照
- (void) takePhoto:(UIImageOrientation)orientation block:(void(^)(UIImage* image)) func
{
    if (_sdkDisabled) {
        return;
    }
    if (_disableTakePhoto) {
        NSLog(@"Please set property disableTakePhoto NO");
        return;
    }
#if 0
    photoOrientation = UIImageOrientationDown;
    if (orientation == 0) {
        photoOrientation = UIImageOrientationRight;
    }else if (orientation == 1){
        photoOrientation = UIImageOrientationUp;
    }else if (orientation == 2){
        photoOrientation = UIImageOrientationDown;
    }
#else
    if (photoOrientation == UIImageOrientationUp
        && _camera.cameraPosition == AVCaptureDevicePositionFront
        && deviceOrientation != UIDeviceOrientationPortrait) {
        photoOrientation = UIImageOrientationDown;
    }
#endif
#if 1
    isTakePhoto = YES;
    takePhotoCompletionHandler = func;
#else
//    _cropFilter.cropRegion = CGRectMake(0, 0, value);
    __weak typeof(self) weakSelf = self;
    [(RDGPUImageStillCamera*)self.camera capturePhotoAsImageProcessedUpToFilter:_cropFilter withOrientation:photoOrientation withCompletionHandler:^(UIImage *processedImage, NSError *error) {
        if (error) {
            NSLog(@"%@",error);
        }else{
            __strong typeof(self) strongSelf = weakSelf;
            NSLog(@"拍到 %d",orientation);
            if (photoOrientation != UIImageOrientationUp) {
                processedImage = [strongSelf normalizedImage:processedImage];
            }
            RDGPUImagePicture* stillImageSource = [[RDGPUImagePicture alloc] initWithImage:processedImage];
            [stillImageSource addTarget:strongSelf->newFilter];
            [strongSelf->newFilter useNextFrameForImageCapture];

            [stillImageSource processImageWithCompletionHandler:^{
                UIImage *currentFilteredVideoFrame = [strongSelf->newFilter imageFromCurrentFramebuffer];
                dispatch_async(dispatch_get_main_queue(), ^{
                    func(currentFilteredVideoFrame);
                });
            }];
        }
    }];
#endif
}

//处理照片方向
- (UIImage *)normalizedImage:(UIImage *)image{
    @autoreleasepool {
        if (nil == image) {
            return nil;
        }
        CGSize size = image.size;
        UIGraphicsBeginImageContext(size);
        CGRect rect = CGRectMake(0, 0, size.width, size.height);
        [image drawInRect:rect];
        UIImage *newing = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        image = nil;
        return newing;
    }
}

#pragma mark - 图片旋转方法
- (UIImage *)image:(UIImage *)image rotation:(UIImageOrientation)orientation
{
         long double rotate = 0.0;
         CGRect rect;
         float translateX = 0;
         float translateY = 0;
         float scaleX = 1.0;
         float scaleY = 1.0;
    
         switch (orientation) {
             case UIImageOrientationLeft:
                 rotate = M_PI_2;
                 rect = CGRectMake(0, 0, image.size.height, image.size.width);
                 translateX = 0;
                 translateY = -rect.size.width;
                 scaleY = rect.size.width/rect.size.height;
                 scaleX = rect.size.height/rect.size.width;
                 break;
             case UIImageOrientationRight:
                 rotate = 3 * M_PI_2;
                 rect = CGRectMake(0, 0, image.size.height, image.size.width);
                 translateX = -rect.size.height;
                 translateY = 0;
                 scaleY = rect.size.width/rect.size.height;
                 scaleX = rect.size.height/rect.size.width;
                 break;
             case UIImageOrientationDown:
                 rotate = M_PI;
                 rect = CGRectMake(0, 0, image.size.width, image.size.height);
                 translateX = -rect.size.width;
                 translateY = -rect.size.height;
                 break;
             default:
                 rotate = 0.0;
                 rect = CGRectMake(0, 0, image.size.width, image.size.height);
                 translateX = 0;
                 translateY = 0;
                 break;
         }
    
         UIGraphicsBeginImageContext(rect.size);
         CGContextRef context = UIGraphicsGetCurrentContext();
    
         //做CTM变换
         CGContextTranslateCTM(context, 0.0, rect.size.height);
         CGContextScaleCTM(context, 1.0, -1.0);
         CGContextRotateCTM(context, rotate);
         CGContextTranslateCTM(context, translateX, translateY);
         CGContextScaleCTM(context, scaleX, scaleY);
    
         //绘制图片
         CGContextDrawImage(context, CGRectMake(0, 0, rect.size.width, rect.size.height), image.CGImage);
    
         UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    
         return newPic;
     }
#pragma mark 录制
- (int ) assetWriterStatus;
{
    return     _movieWriter.assetWriter.status;
}

- (BOOL)isHeadsetPluggedIn {
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones])
            return YES;
    }
    return NO;
}

- (void)setaudioTime_beforePlay:(CMTime)audioTime_beforePlay {
    _audioTime_beforePlay = audioTime_beforePlay;
#ifdef AUDIORECORDER
    [[AudioRecorder shareManager] startRecord];
#endif
}


- (void) beginRecording{

    if([_delegate respondsToSelector:@selector(recordTime)]){
        _allRecordTime = [_delegate recordTime];
    }else{
        _allRecordTime = 0;
    }
    if (_sdkDisabled) {
        return;
    }
    _recordStatus = VideoRecordStatusBegin;
    startRecordTime = kCMTimeInvalid;
    //20171027 wuxiaoxia 修复bug：刷新播放器后，再录制不能录制声音，因为RDVideoRenderer.m中设置为了kAudioSessionCategory_MediaPlayback
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error = nil;
    //20180313 wuxiaoxia 修复bug：多格子录制前，插上耳机，选择一首音乐录制，切换成极慢方式录制后，音乐变成外放
    if ([self isHeadsetPluggedIn]) {
        [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    }else {
        [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    }
    [audioSession setActive:YES error:nil];
#if 1   //20191120 修复bug:iOS13录制时，没插耳机的情况，音乐播放是听筒播放而不是外放
    BOOL suc = [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
#else
    BOOL suc = [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];    
#endif
    if(!suc){
        NSLog(@"AVAudioSession setCategory failed:%@", error);
    }
    
#ifdef AUDIO_RECORD
    OSErr err = kAudioFileUnspecifiedError;
    @synchronized(self) {
        if (!extAudioFile) {
            /*
             Start recording by creating an ExtAudioFile and configuring it with the same sample rate and
             channel layout as those of the current sample buffer.
             */
            
            // recording format is the format of the audio file itself
            CAStreamBasicDescription recordingFormat(currentInputASBD.mSampleRate, currentInputASBD.mChannelsPerFrame, CAStreamBasicDescription::kPCMFormatInt16, true);
            recordingFormat.mFormatFlags |= kAudioFormatFlagIsBigEndian;
            
            NSLog(@"Recording Audio Format:");
            recordingFormat.Print();
            
            err = ExtAudioFileCreateWithURL(_outputFile,
                                            kAudioFileAIFFType,
                                            &recordingFormat,
                                            currentRecordingChannelLayout,
                                            kAudioFileFlags_EraseFile,
                                            &extAudioFile);
            if (noErr == err)
                // client format is the output format from the delay unit
                err = ExtAudioFileSetProperty(extAudioFile, kExtAudioFileProperty_ClientDataFormat, sizeof(graphOutputASBD), &graphOutputASBD);
            
            if (noErr != err) {
                if (extAudioFile) ExtAudioFileDispose(extAudioFile);
                extAudioFile = NULL;
            }
        }
    } // @synchronized
#endif
    
//    RDGPUImageCropFilter* cropFilter;
#if 1
    if (_mode) {
        CGSize matchSize = [RDRecordHelper matchSize];
        
        CGFloat max = MAX(matchSize.height, matchSize.width);
        CGFloat min = MIN(matchSize.height, matchSize.width);
        
        CGFloat center = min / max;
        CGFloat offset = _frame.origin.x/min;
        
        cropFilterT = [[RDGPUImageCropFilter alloc] initWithCropRegion:CGRectMake(offset, 0.0, center, 1.0)];
    }else{
#if 0
        CGSize matchSize = [RDRecordHelper matchSize];

        CGSize recordSize = _outputSize;

        CGFloat ratey = MIN(recordSize.width/matchSize.width, 1.);
        CGFloat ratex = MIN(recordSize.height/matchSize.height, 1.);

        if (matchSize.height <= recordSize.height && matchSize.width <= recordSize.width) {
            float sx = matchSize.height / recordSize.height;
            float sy = matchSize.width / recordSize.width;
            recordSize.height *= MIN(sx, sy);
            recordSize.width *= MIN(sx, sy);
        }
        CGRect cropRect = CGRectMake((1. - ratex)/2., (1. - ratey)/2., 1.0 * ratex, 1.0 * ratey);

        cropFilterT = [[RDGPUImageCropFilter alloc] initWithCropRegion:cropRect];
#else
        if (_maskPath.length > 0 || _fillMode == kRDCameraFillModeScaleAspectFill) {
            cropFilterT = [[RDGPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0, 0, 1, 1)];
        }else {
            CGSize matchSize = [RDRecordHelper matchSize];
            
            if (matchSize.width/matchSize.height != _outputSize.width/_outputSize.height) {
                CGFloat rateX = MIN(1.0, (matchSize.width/(_outputSize.width/_outputSize.height))/matchSize.height);
                CGFloat rateY = MIN(1.0, (matchSize.height*rateX*(_outputSize.width/_outputSize.height))/matchSize.width);
                CGRect cropRect = CGRectMake((1. - rateX)/2., (1. - rateY)/2., 1.0 * rateX, 1.0 * rateY);
                
                cropFilterT = [[RDGPUImageCropFilter alloc] initWithCropRegion:cropRect];
            }else {
                cropFilterT = [[RDGPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0, 0, 1, 1)];
            }
        }
#endif
    }
    _movieWriter.encodingLiveVideo = YES;
    
    if(_enableCameraWaterMark){
        [newFilter addTarget:newAlphaBlendFilter atTextureLocation:0];
        [newUIElement addTarget:newAlphaBlendFilter];
        [newAlphaBlendFilter addTarget:self.movieWriter];
    }
    
    [newFilter addTarget:cropFilterT];
    [cropFilterT addTarget:self.movieWriter];
#else   //20170913 wuxiaoxia setup中已经裁剪过了
    [newFilter addTarget:self.movieWriter];
#endif
#ifndef AUDIORECORDER
    if (!_isMute) {
        self.camera.audioEncodingTarget = self.movieWriter;
    }
#endif
    [self.movieWriter startRecording];
    
    
}
- (void) pauseRecording{
//    _recordStatus = VideoRecordStatusPause;
//    [self.movieWriter pauseRecording];
}
- (void) resumeRecording{
//    _recordStatus = VideoRecordStatusResume;
//    [self.movieWriter resumeRecording];
    
}
- (void) stopRecording{
    _recordStatus = VideoRecordStatusEnd;
    
    NSLog(@"%s",__func__);
//    _camera.audioEncodingTarget = nil;
    if(_enableCameraWaterMark){
        [newFilter removeTarget:newAlphaBlendFilter];
        [newUIElement removeTarget:newAlphaBlendFilter];
        [newAlphaBlendFilter removeTarget:_movieWriter];
    }
#if 1
    [newFilter removeTarget:cropFilterT];
    [cropFilterT removeTarget:_movieWriter];
#else
    [newFilter removeTarget:_movieWriter];
#endif
    
#ifdef AUDIO_RECORD
    OSStatus err = kAudioFileNotOpenError;
    @synchronized(self) {
        if (extAudioFile) {
            // Close the file by disposing the ExtAudioFile
            err = ExtAudioFileDispose(extAudioFile);
            extAudioFile = NULL;
        }
    } // @synchronized
    AudioUnitReset(delayAudioUnit, kAudioUnitScope_Global, 0);
#endif
    
    __weak typeof(self) weakSelf = self;
    [self.movieWriter finishRecordingWithCompletionHandler:^{
#ifdef AUDIORECORDER
        [[AudioRecorder shareManager]  audioRecorderStop];
#endif
        _isRecording = NO;
        startRecordTime = kCMTimeInvalid;
        //emmet 20181219 屏蔽一下这句代码是为了解决（点击暂停录制时画面闪黑）的问题，但是屏蔽下面这句代码后音频录制会出问题，录制二十几段后会出现音频的status一直是正在写入。
        weakSelf.camera.audioEncodingTarget = nil;
        NSLog(@"结束后回调");
#if 0
        if(weakSelf.delegate && !_sdkDisabled){
            NSLog(@"%s",__func__);
            if (weakSelf.movieWriter.assetWriter.status == AVAssetWriterStatusFailed) {
                if([weakSelf.delegate respondsToSelector:@selector(movieRecordFailed:)]){
                    NSError *error = weakSelf.movieWriter.assetWriter.error;
                    [weakSelf.delegate movieRecordFailed:error];
                }
            }else {
                if([weakSelf.delegate respondsToSelector:@selector(movieRecordingCompletion:)]){
                    [weakSelf.delegate movieRecordingCompletion:videoURL];
                }
            }
        }
#else //20180418 为了解决多格录制时,多个格子的音频对不齐的bug
        if(weakSelf.delegate && !_sdkDisabled){
            NSLog(@"%s",__func__);
            if (weakSelf.movieWriter.assetWriter.status == AVAssetWriterStatusFailed) {
                if([weakSelf.delegate respondsToSelector:@selector(movieRecordFailed:)]){
                    NSError *error = weakSelf.movieWriter.assetWriter.error;
                    [weakSelf.delegate movieRecordFailed:error];
                }
            }else {
                AVURLAsset *asset = [AVURLAsset assetWithURL:videoURL];
                if (CMTimeCompare(_audioTime_stopPlay, kCMTimeZero) == 1) {
                    CMTime duration = asset.duration;
#ifndef AUDIORECORDER
//                    NSLog(@"asset.duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, asset.duration)));
                    CMTime videoDuration = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0].timeRange.duration;
                    NSLog(@"assetVideoTrack duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, videoDuration)));
                    CMTime audioDuration = kCMTimeZero;
                    if ([asset tracksWithMediaType:AVMediaTypeAudio].count > 0) {
                        audioDuration = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0].timeRange.duration;
                        NSLog(@"audioDuration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, audioDuration)));
                    }
                    float videoAudioDiff = CMTimeGetSeconds(CMTimeSubtract(videoDuration, audioDuration));
                    NSLog(@">>>>>>>>>>>video audio diff:%f", videoAudioDiff);
                    NSLog(@"duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, duration)));
#endif
                    float diffTime = CMTimeGetSeconds(CMTimeSubtract(duration, CMTimeSubtract(_audioTime_stopPlay, _audioTime_beforePlay)));
                    float playDuration = CMTimeGetSeconds(CMTimeSubtract(_audioTime_stopPlay, _audioTime_beforePlay));
                    NSLog(@"diffTime:%f ------:%f _audioTime_beforePlay:%f _audioTime_stopPlay:%f", diffTime, playDuration, CMTimeGetSeconds(_audioTime_beforePlay), CMTimeGetSeconds(_audioTime_stopPlay));
                    if (diffTime > 0 && playDuration > 0) {
                        CMTimeRange trimTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(diffTime, TIMESCALE), CMTimeMakeWithSeconds(playDuration, TIMESCALE));
                        
                        if (CMTimeCompare(trimTimeRange.duration, asset.duration) == 1) {
                            trimTimeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
                        }else if (CMTimeCompare(CMTimeAdd(trimTimeRange.start, trimTimeRange.duration), asset.duration) == 1) {
                            trimTimeRange = CMTimeRangeMake(trimTimeRange.start, CMTimeSubtract(asset.duration, trimTimeRange.start));
                        }
                        NSLog(@"trimTimeRange:%@ duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, trimTimeRange.start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, trimTimeRange.duration)));
                        if ([weakSelf.delegate respondsToSelector:@selector(movieFileTrimTime:)]) {
                            [weakSelf.delegate movieFileTrimTime:CMTimeGetSeconds(trimTimeRange.start)];
                        }
                        NSString *trimPath = [self getfilePathStringWithSuffix:@""];
#ifndef AUDIORECORDER
                        [weakSelf trimVideoWithVideoUrl:videoURL
                                              outputUrl:[NSURL fileURLWithPath:trimPath]
                                          trimTimeRange:trimTimeRange
                                          progressBlock:nil
                                          callbackBlock:^(NSURL *trimVideoUrl) {
                                              unlink([videoURL.path UTF8String]);
                                              if([weakSelf.delegate respondsToSelector:@selector(movieRecordingCompletion:)]){
                                                  [weakSelf.delegate movieRecordingCompletion:[NSURL fileURLWithPath:trimPath]];
                                              }
                                          } fail:^(NSError *error) {
                                              unlink([trimPath UTF8String]);
                                              NSLog(@"%@",error);
                                              if([weakSelf.delegate respondsToSelector:@selector(movieRecordFailed:)]){
                                                  [weakSelf.delegate movieRecordFailed:error];
                                              }
                                          }];
#else
                        [weakSelf mergeVideoAndAudio:videoURL
                                           outputUrl:[NSURL fileURLWithPath:trimPath]
                                       trimTimeRange:trimTimeRange
                                       progressBlock:nil
                                       callbackBlock:^(NSURL *trimVideoUrl) {
                                           unlink([videoURL.path UTF8String]);
                                           if([weakSelf.delegate respondsToSelector:@selector(movieRecordingCompletion:)]){
                                               [weakSelf.delegate movieRecordingCompletion:[NSURL fileURLWithPath:trimPath]];
                                           }
                                       } fail:^(NSError *error) {
                                           unlink([trimPath UTF8String]);
                                           NSLog(@"%@",error);
                                           if([weakSelf.delegate respondsToSelector:@selector(movieRecordFailed:)]){
                                               [weakSelf.delegate movieRecordFailed:error];
                                           }
                                       }];
#endif
                    }else {
#ifndef AUDIORECORDER
                        if ([weakSelf.delegate respondsToSelector:@selector(movieFileTrimTime:)]) {
                            [weakSelf.delegate movieFileTrimTime:0.0];
                        }
                        if([weakSelf.delegate respondsToSelector:@selector(movieRecordingCompletion:)]){
                            [weakSelf.delegate movieRecordingCompletion:videoURL];
                        }
#else
                        NSString *trimPath = [self getfilePathStringWithSuffix:@""];
                        [weakSelf mergeVideoAndAudio:videoURL
                                           outputUrl:[NSURL fileURLWithPath:trimPath]
                                       trimTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0.05, 600), asset.duration)
                                       progressBlock:nil
                                       callbackBlock:^(NSURL *trimVideoUrl) {
                                           unlink([videoURL.path UTF8String]);
                                           if([weakSelf.delegate respondsToSelector:@selector(movieRecordingCompletion:)]){
                                               [weakSelf.delegate movieRecordingCompletion:[NSURL fileURLWithPath:trimPath]];
                                           }
                                       } fail:^(NSError *error) {
                                           unlink([trimPath UTF8String]);
                                           NSLog(@"%@",error);
                                           if([weakSelf.delegate respondsToSelector:@selector(movieRecordFailed:)]){
                                               [weakSelf.delegate movieRecordFailed:error];
                                           }
                                       }];
#endif
                    }
                }else {
#ifndef AUDIORECORDER
                    if ([weakSelf.delegate respondsToSelector:@selector(movieFileTrimTime:)]) {
                        [weakSelf.delegate movieFileTrimTime:0.0];
                    }
                    if([weakSelf.delegate respondsToSelector:@selector(movieRecordingCompletion:)]){
                        [weakSelf.delegate movieRecordingCompletion:videoURL];
                    }
#else
                    NSString *trimPath = [self getfilePathStringWithSuffix:@""];
                    [weakSelf mergeVideoAndAudio:videoURL
                                       outputUrl:[NSURL fileURLWithPath:trimPath]
                                   trimTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                   progressBlock:nil
                                   callbackBlock:^(NSURL *trimVideoUrl) {
                                       unlink([videoURL.path UTF8String]);
                                       if([weakSelf.delegate respondsToSelector:@selector(movieRecordingCompletion:)]){
                                           [weakSelf.delegate movieRecordingCompletion:[NSURL fileURLWithPath:trimPath]];
                                       }
                                   } fail:^(NSError *error) {
                                       unlink([trimPath UTF8String]);
                                       NSLog(@"%@",error);
                                       if([weakSelf.delegate respondsToSelector:@selector(movieRecordFailed:)]){
                                           [weakSelf.delegate movieRecordFailed:error];
                                       }
                                   }];
#endif
                }
            }
        }
#endif
       
        self->_movieWriter = nil;
    }];
}


#pragma mark 输出视图
- (void)setVideoViewFrame:(CGRect)rect{
    _frame = rect;
    [self.cameraScreen setFrame:rect];
//    [self.cameraScreen setMybounds:CGRectMake(0, 0, rect.size.width, rect.size.height)];
}

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
- (void)setCameraScreenMode:(BOOL)mode top:(BOOL) isTop
{
    _mode = mode;
    if (mode) {
        _cameraScreen.fillMode = kRDGPUImageFillModePreserveAspectRatio;
        CGFloat len = (_frame.size.height - _frame.size.width)/2. - 44. - (isTop?44. + 5:0.);
        
        _cameraScreen.frame = CGRectMake(0.-len, 0., _frame.size.height, _frame.size.width);
//        _cameraScreen.mybounds = CGRectMake(0, 0, _frame.size.height, _frame.size.width);
        if (!hideView) {
            hideView = [[UIView alloc] init];
            hideView.frame = CGRectMake((_frame.size.height + _frame.size.width)/2., 0, _frame.size.width, _frame.size.width);
            hideView.backgroundColor = UIColorFromRGB(0x19181d);
            
            [_cameraScreen addSubview:hideView];
        }
        
    }else{
        
        _cameraScreen.fillMode = kRDGPUImageFillModePreserveAspectRatio;
        
        _cameraScreen.frame = CGRectMake(0, 0, _frame.size.height, _frame.size.width);
//        _cameraScreen.mybounds = CGRectMake(0, 0, _frame.size.height, _frame.size.width);

        if (hideView) {
            [hideView removeFromSuperview];
            hideView = nil;
        }
        
    }
}

- (RDGPUImageView *)cameraScreen {
    if (!_cameraScreen) {
        RDGPUImageView *cameraScreen = [[RDGPUImageView alloc] init];
        //cameraScreen.fillMode = kRDGPUImageFillModePreserveAspectRatio;
        cameraScreen.frame = _frame;
        _cameraScreen = cameraScreen;
//        [self setCameraScreenMode:_mode top:NO];
        UIPinchGestureRecognizer* recognizerPinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
        [_cameraScreen addGestureRecognizer:recognizerPinch];
        
#if 0
        UISwipeGestureRecognizer* recognizerRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeFilter:)];
        recognizerRight.direction = UISwipeGestureRecognizerDirectionUp;
        [_cameraScreen addGestureRecognizer:recognizerRight];
        
        UISwipeGestureRecognizer* recognizerLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeFilter:)];
        recognizerLeft.direction = UISwipeGestureRecognizerDirectionDown;
        [_cameraScreen addGestureRecognizer:recognizerLeft];

#endif
        pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [_cameraScreen setUserInteractionEnabled:YES];
        [_cameraScreen addGestureRecognizer:pan];
    }
    return _cameraScreen;
}

- (void)setUIfilter{
    
    //（这句代码总是不断的调用很影响性能，通过查找资料修改如下）
    
    //        __unsafe_unretained RDGPUImageUIElement *weakOverlay = uiElement;
    
    //        [filter disableSecondFrameCheck];//这样只是在需要更新水印的时候检查更新就不会调用很多次
    //        rdRunAsynchronouslyOnVideoProcessingQueue(^{
    //            [weakOverlay update];
    //        });
    
    //        当然这样写因为GPUImage框架也有些不完善的地方调用update会崩溃，解决办法见：https://github.com/BradLarson/GPUImage/issues/2211
    //
    //        同时如果你觉得水印不够清晰你可以修改着色的语言，重写着色算法
    //
    //        重写blend的着色语言如下：
    
    //        NSString *const kGPUImageDissolveBlendFragmentShaderString = SHADER_STRING
    //
    //        (
    //
    //         uniform sampler2D inputImageTexture;
    //
    //         uniform sampler2D inputImageTexture2;
    //
    //         uniform mediump int type;
    //
    //         // varying highp vec2 anyTexCoord;
    //
    //         varying highp vec2 textureCoordinate;
    //         )
}

- (void)setFillMode:(RDCameraFillMode)fillMode {
    if (fillMode == kRDCameraFillModeScaleAspectFill) {
        [self refreshCropFilter];
    }
    _fillMode = fillMode;
    self.cameraScreen.fillMode = (RDGPUImageFillModeType)fillMode;
}

- (void) handlePan: (UIPanGestureRecognizer *)gesture{
    if (_isRecording) {
        return;
    }
    CGPoint translation = [gesture translationInView:gesture.view];
    CGPoint currentPoint = [gesture locationInView:_cameraScreen];
    if(gesture.state == UIGestureRecognizerStateBegan){
        swipeDirection = kRDCameraSwipeDirectionNone;
        _beginHandPanPoint = currentPoint;
        beginTeffect = YES;
        starthandpanTime = CFAbsoluteTimeGetCurrent();
        if (starthandpanTime - endhandpanTime<handpanMinTime) {
            return;
        }
        
    }else if(gesture.state == UIGestureRecognizerStateChanged){
        if (starthandpanTime - endhandpanTime<handpanMinTime) {
            return;
        }
        swipeDirection = [self determineCameraDirectionIfNeeded:translation];
//        NSLog(@"swipeDirection:%ld", (long)swipeDirection);
        if (swipeDirection == kRDCameraSwipeDirectionNone || swipeDirection == kRDCameraSwipeDirectionUp || swipeDirection == kRDCameraSwipeDirectionDown) {
            if(_delegate && [_delegate respondsToSelector:@selector(swipeScreenBegin:)]){
                [_delegate swipeScreenBegin:swipeDirection];
            }
            return;
        }
        float value = fabs(currentPoint.y - _beginHandPanPoint.y)/(_cameraScreen.frame.size.height);
        if (!beginTeffect) {
            if (swipeDirection == kRDCameraSwipeDirectionRight) {
                value = 1.0 - value;
            }
            if (_swipeScreenIsChangeFilter) {
                [self setTeffectChange:value];
            }
            if(_delegate && [_delegate respondsToSelector:@selector(swipeScreenChanging:swipDirection:)]){
                [_delegate swipeScreenChanging:value swipDirection:swipeDirection];
            }
        }else {
            if (swipeDirection == kRDCameraSwipeDirectionLeft) {
                if(!_isRecording){ // && currentIndex>0
                    if (_swipeScreenIsChangeFilter) {
                        currentIndex+=1;
                        if (currentIndex>_gFilters.count-1) {
                            currentIndex = 0;
                        }
                        [self setTeffectBegin:currentIndex orient:0];
                    }
                    if(_delegate && [_delegate respondsToSelector:@selector(swipeScreenBegin:)]){
                        [_delegate swipeScreenBegin:swipeDirection];
                    }
                }
            }else if(!_isRecording){// && currentIndex<(_filters.count-1)
                if (_swipeScreenIsChangeFilter) {
                    currentIndex -= 1;
                    if (currentIndex<0) {
                        currentIndex = (int)(_gFilters.count)-1;
                    }
                    [self setTeffectBegin:currentIndex orient:1];
                }
                if(_delegate && [_delegate respondsToSelector:@selector(swipeScreenBegin:)]){
                    [_delegate swipeScreenBegin:swipeDirection];
                }
            }
        }
    }
    else if(gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled || gesture.state == UIGestureRecognizerStateFailed){
        if (swipeDirection == kRDCameraSwipeDirectionNone || swipeDirection == kRDCameraSwipeDirectionUp || swipeDirection == kRDCameraSwipeDirectionDown) {
            if(_delegate && [_delegate respondsToSelector:@selector(swipeScreenChangeEnd:)]){
                [_delegate swipeScreenChangeEnd:swipeDirection];
            }
            return;
        }
        if (!_swipeScreenIsChangeFilter) {
            if(_delegate && [_delegate respondsToSelector:@selector(swipeScreenChangeEnd:)]){
                [_delegate swipeScreenChangeEnd:swipeDirection];
            }
            return;
        }
        float value = fabs(currentPoint.y-_beginHandPanPoint.y)/(_cameraScreen.frame.size.height);
        if (swipeDirection == kRDCameraSwipeDirectionRight) {
            value = 1.0 - value;
        }
        endhandpanTime = CFAbsoluteTimeGetCurrent();
        if((endhandpanTime - starthandpanTime < handpanMinTime)){
            if (swipeDirection == kRDCameraSwipeDirectionRight) {
                if (currentIndex<0) {
                    currentIndex = (int)(_gFilters.count)-1;
                }
                NSLog(@"%d结束 当前序号 %d  %f",__LINE__,currentIndex,value);
                [self tEffectFrom:value to:0.0];
            }else {
                if (currentIndex>_gFilters.count-1) {
                    currentIndex = 0;
                }
                NSLog(@"%d结束 当前序号 %d  %f",__LINE__,currentIndex,value);
                [self tEffectFrom:value to:1.0];
            }
        }else {
            if (swipeDirection == kRDCameraSwipeDirectionLeft) {
                if (value >= 0.5) {
                    // currentIndex
                    // value -> 1
                    NSLog(@"%d结束 当前序号 %d  %f",__LINE__,currentIndex,value);
                    [self tEffectFrom:value to:1.0];
                }else{
                    // currentIndex -1
                    // ->0
                    currentIndex -= 1;
                    if (currentIndex<0) {
                        currentIndex = (int)(_gFilters.count)-1;
                    }
                    NSLog(@"%d结束 当前序号 %d  %f",__LINE__,currentIndex,value);
                    [self tEffectFrom:value to:0.0];
                }
            }else {
                if (value >= 0.5) {
                    // currentIndex + 1
                    // value的值应当从 -> 1
                    currentIndex+=1;
                    if (currentIndex>_gFilters.count-1) {
                        currentIndex = 0;
                    }
                    NSLog(@"%d结束 当前序号 %d  %f",__LINE__,currentIndex,value);
                    [self tEffectFrom:value to:1.0];
                }else{
                    // currentIdnex
                    // value ->0                    
                    NSLog(@"%d结束 当前序号 %d  %f",__LINE__,currentIndex,value);
                    [self tEffectFrom:value to:0.0];
                }
            }
        }
    }
}

// This method will determine whether the direction of the user's swipe

- (RDCameraSwipeDirection)determineCameraDirectionIfNeeded:(CGPoint)translation
{
    if (swipeDirection != kRDCameraSwipeDirectionNone)
        return swipeDirection;
    
    // determine if horizontal swipe only if you meet some minimum velocity
    if (fabs(translation.x) > gestureMinimumTranslation)
    {
        BOOL gestureHorizontal = NO;
        if (translation.y ==0.0)
            gestureHorizontal = YES;
        else
            gestureHorizontal = (fabs(translation.x / translation.y) >5.0);
        
        if (gestureHorizontal)
        {
            if (translation.x >0.0)
                return kRDCameraSwipeDirectionDown;
            else
                return kRDCameraSwipeDirectionUp;
        }
    }    
    // determine if vertical swipe only if you meet some minimum velocity
    else if (fabs(translation.y) > gestureMinimumTranslation)
    {
        BOOL gestureVertical = NO;
        if (translation.x ==0.0)
            gestureVertical = YES;
        else
            gestureVertical = (fabs(translation.y / translation.x) >5.0);
        
        if (gestureVertical)
        {
            if (translation.y >0.0)
                return kRDCameraSwipeDirectionLeft;
            else
                return kRDCameraSwipeDirectionRight;
        }
    }
    return swipeDirection;
}

- (void) tEffectFrom:(float) from to:(float) to{
    
    if(self.filters.count == 0 ){
        return;
    }
    __block float beginTime = from;
    __block float endTime = to;
   
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 0.01 * TIMESCALE, 0.0 * NSEC_PER_SEC);

    if (from<to) {
       
        dispatch_source_set_event_handler(timer, ^{
            tEffectFilter.value = beginTime;
            beginTime += 0.03;
            
            if(_delegate){
                if([_delegate respondsToSelector:@selector(swipeScreenChanging:swipDirection:)]){
                    [_delegate swipeScreenChanging:beginTime swipDirection:swipeDirection];
                }
            }
            if (beginTime>endTime) {
                dispatch_source_cancel(timer);

                if([[NSFileManager defaultManager] fileExistsAtPath:_gFilters[currentIndex].filterPath]){
                    [self setFilterAtIndex:currentIndex];
                }
//                if(![_filters[currentIndex] isKindOfClass:[NSArray class]]){
//                    [self setFilterAtIndex:currentIndex];
//                }
                if(_delegate){
                    if([_delegate respondsToSelector:@selector(sendFilterIndex:)]){
                        [_delegate sendFilterIndex:(int)currentIndex];
                    }
                    
                    if([_delegate respondsToSelector:@selector(swipeScreenChangeEnd:)]){
                        [_delegate swipeScreenChangeEnd:swipeDirection];
                    }
                }
            }
        
        });
    }else{
        dispatch_source_set_event_handler(timer, ^{
            tEffectFilter.value = beginTime;
            beginTime -= 0.03;
            if(_delegate){
                if([_delegate respondsToSelector:@selector(swipeScreenChanging:swipDirection:)]){
                    [_delegate swipeScreenChanging:beginTime swipDirection:swipeDirection];
                }
            }
            if (beginTime<endTime) {
                dispatch_source_cancel(timer);
                
                if([[NSFileManager defaultManager] fileExistsAtPath:_gFilters[currentIndex].filterPath]){
                    [self setFilterAtIndex:currentIndex];
                }
                
//                if(![_filters[currentIndex] isKindOfClass:[NSArray class]]){
//                    [self setFilterAtIndex:currentIndex];
//                }
                if(_delegate){
                    if([_delegate respondsToSelector:@selector(sendFilterIndex:)]){
                        [_delegate sendFilterIndex:(int)currentIndex];
                    }
                    
                    if([_delegate respondsToSelector:@selector(swipeScreenChangeEnd:)]){
                        [_delegate swipeScreenChangeEnd:swipeDirection];
                    }
                }
            }
            
        });
    }
    
    dispatch_resume(timer);
}

- (void) swipeFilter: (UISwipeGestureRecognizer *) recognizer{
    
    NSLog(@"%s",__func__);
#if 0
    switch (recognizer.direction) {
        case UISwipeGestureRecognizerDirectionUp:
        {
#if 1
            if(!_isRecording){ // && currentIndex>0
                [self setFilterAtIndex:(currentIndex>0? (currentIndex - 1) : (_filters.count-1))];
                if(_delegate){
                    if([_delegate respondsToSelector:@selector(sendFilterIndex:)]){
                        [_delegate sendFilterIndex:(int)currentIndex];
                    }
                }
            }
            
#else
            if(_delegate){
                if([_delegate respondsToSelector:@selector(sendTagVideoOrPhoto:)]){
                    [_delegate sendTagVideoOrPhoto:1];
                }
            }
#endif
        }
            break;
        case UISwipeGestureRecognizerDirectionDown:
            
        {
#if 1
            if(!_isRecording){// && currentIndex<(_filters.count-1)
                [self setFilterAtIndex:(currentIndex<(_filters.count-1)? (currentIndex + 1) : 0)];
                
                if(_delegate){
                    if([_delegate respondsToSelector:@selector(sendFilterIndex:)]){
                        [_delegate sendFilterIndex:(int)currentIndex];
                    }
                }
            }
#else
            if(_delegate){
                if([_delegate respondsToSelector:@selector(sendTagVideoOrPhoto:)]){
                    [_delegate sendTagVideoOrPhoto:0];
                }
            }
#endif
        }
            break;
        default:
            break;
    }
#endif
}
static int addCount = 1.0;
-(void)pinch:(UIPinchGestureRecognizer *)recognizer{
    
    if (recognizer.scale > 1.0) {
        addCount ++ ;
    }else{
        addCount --;
    }
    if (addCount > 50) {
        addCount = 50;
    }
    if (addCount <0) {
        addCount = 0;
    }
    CGFloat rate = 1.0 + addCount / 50. * 2.0;
    NSLog(@"count %d",addCount);
//    [self updateCropRegion:rate];
    [self zoom:rate];
    
    
}


#pragma mark 摄像头位置
- (void)setPosition:(AVCaptureDevicePosition)position {
    _position = position;
    addCount = 0;

    switch (position) {
        case AVCaptureDevicePositionBack: {
            
            if (self.camera.cameraPosition != AVCaptureDevicePositionBack) {
                [self.camera pauseCameraCapture];
                [_movieWriter pauseRecording];//20170327 不调用pauseRecording，录制的时候不断地切换摄像头，录制完成后，录制时间与编辑界面显示时间不一致
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.camera rotateCamera];
                    //20191021 需要先设置好Orientation，再resumeCameraCapture，否则前后摄像头切换时，会先横屏再竖屏
                    if (deviceOrientation != UIDeviceOrientationUnknown) {
                        [self setDeviceOrientation:deviceOrientation];
                    }
                    [self.camera resumeCameraCapture];
                    [_movieWriter resumeRecording];
                });
            }
            
        }
            
            break;
        case AVCaptureDevicePositionFront: {
            if (self.camera.cameraPosition != AVCaptureDevicePositionFront) {
                [self.camera pauseCameraCapture];
                [_movieWriter pauseRecording];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.camera rotateCamera];
                    _camera.videoCaptureConnection.videoMirrored = YES;
                    //20191021 需要先设置好Orientation，再resumeCameraCapture，否则前后摄像头切换时，会先横屏再竖屏
                    if (deviceOrientation != UIDeviceOrientationUnknown) {
                        [self setDeviceOrientation:deviceOrientation];
                    }
                    [self.camera resumeCameraCapture];
                    [_movieWriter resumeRecording];
                });
            }
        }
            
            break;
        default:
            break;
    }
}

- (void) animationCamera {
    
    CATransition *animation = [CATransition animation];
    animation.delegate = self;
    animation.duration = .5f;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.subtype = kCATransitionFromRight;
    [self.cameraScreen.layer addAnimation:animation forKey:nil];
    
}

- (void)setBrightness:(float)brightness{
    beauty.brightness = 1.0 + brightness;
}
- (void)setBlur:(float)blur{
    beauty.intensity = blur;
}
#pragma mark 录制状态
- (void)setRecordStatus:(VideoRecordStatus)recordStatus{
    _recordStatus = recordStatus;
    switch (recordStatus) {
        case VideoRecordStatusBegin:
            [self beginRecording];
            break;
        case VideoRecordStatusPause:
        case VideoRecordStatusCancel:
            [self pauseRecording];
            break;
        case VideoRecordStatusResume:
            [self resumeRecording];
            break;
        case VideoRecordStatusEnd:
            [self stopRecording];
            
        default:
            break;
    }
}
#pragma mark 闪光灯
- (void)setFlashMode:(AVCaptureTorchMode)flashMode {
    _flashMode = flashMode;
    if (![self.camera.inputCamera isTorchModeSupported:flashMode]) {
        return;
    }
    switch (flashMode) {
        case AVCaptureTorchModeOff: {
            [self.camera.inputCamera lockForConfiguration:nil];
            [self.camera.inputCamera setTorchMode:AVCaptureTorchModeOff];
            [self.camera.inputCamera unlockForConfiguration];
        }
            
            break;
        case AVCaptureTorchModeOn: {
            [self.camera.inputCamera lockForConfiguration:nil];
            [self.camera.inputCamera setTorchMode:AVCaptureTorchModeOn];
            [self.camera.inputCamera unlockForConfiguration];
        }
            break;
            
        default:
            break;
    }
}
#pragma mark 移除滤镜组
- (void)removeFilters{

    [self.camera removeAllTargets];
}
- (NSArray *)getFilters{
    return nil;//_filters;
}
#pragma mark 添加滤镜组
- (void)addFilters:(NSArray <RDFilter *>  *)filters {
    if (_swipeScreenIsChangeFilter) {
        [self refreshFilters:filters];
    }
    _gFilters = [filters mutableCopy];
    if(filters.count>0){
        [self setFilterAtIndex:currentIndex];
    }
}

- (void)setSwipeScreenIsChangeFilter:(BOOL)swipeScreenIsChangeFilter {
    _swipeScreenIsChangeFilter = swipeScreenIsChangeFilter;
    if (_swipeScreenIsChangeFilter) {
        if (_gFilters.count > 0 && _filters.count == 0) {
            [self refreshFilters:_gFilters];
        }
    }else if (_filters.count > 0) {
        [_filters removeAllObjects];
    }
}

- (void)refreshFilters:(NSArray <RDFilter *> *)filters {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *newFilters = [NSMutableArray array];
        RDGPUImageOutput* filter;
        for (RDFilter *obj in filters) {
            if (obj.type == kRDFilterType_HeiBai) {
                filter = [[RDGPUImageGrayscaleFilter alloc] init];
            }
            else if (obj.type == kRDFilterType_SLBP){
                filter = [[RDRecordGPUImageThresholdedNonMaximumSuppressionFilter alloc] initWithPackedColorspace:YES];
                ((RDRecordGPUImageThresholdedNonMaximumSuppressionFilter*)filter).threshold = 0.01;
            }
            else if (obj.type == kRDFilterType_Sketch){
                filter = [[RDRecordGPUImageSketchFilter alloc] init];
            }
            else if (obj.type == kRDFilterType_DistortingMirror){
                filter = [[RDRecordGPUImageStretchDistortionFilter alloc] init];
            }
            else if (obj.type == kRDFilterType_LookUp){
                filter = [[RDLookupFilter alloc] initWithImagePath:obj.filterPath intensity:obj.intensity];
            }
            else{
                filter =[[RDGPUImageToneCurveFilter alloc] initWithACVData:[NSData dataWithContentsOfFile:obj.filterPath]];
            }
            if(filter){
                [newFilters addObject:filter];
            }else{
                [newFilters addObject:@[]];
            }
        }
        _filters = newFilters;
    });
}

- (void)setBeautifyState:(BeautifyState)beautifyState{
    _beautifyState = beautifyState;
    [self setFilterAtIndex:currentIndex];
}

#pragma mark 滤镜组合
float clamp(float a){
    if (a >= 1.0) {
        return 1.0;
    }else if (a <= 0.0){
        return 0.0;
    }else{
        return a;
    }
}
- (void) setTeffectBegin:(NSInteger) index orient:(int) orient{
    if(self.filters.count == 0 || index == oldIndex){
        return;
    }
//    if([_filters[index] isKindOfClass:[NSArray class] ]){
//        return;
//    }
    beginTeffect = NO;
    RDFilter *filter = _gFilters[index];
    if (filter.filterPath.length == 0 || ![[NSFileManager defaultManager] fileExistsAtPath:filter.filterPath]) {
        currentIndex = oldIndex;
        return;
    }
    currentIndex = (int)index;
    NSLog(@"当前%ld 前一个%d",(long)index,oldIndex);
    
    if (index == oldIndex) {
        newFilter = self.filters[index];
        [_cropFilter removeAllTargets];
        [_cropFilter addTarget:newFilter];
        
        [newFilter removeAllTargets];
        [newFilter addTarget:self.cameraScreen];
    }else{
        newFilter = self.filters[index];
        oldFilter = self.filters[oldIndex];
        
        [_cropFilter removeAllTargets];
        [_cropFilter addTarget:newFilter];
        [_cropFilter addTarget:oldFilter];
        
        tEffectFilter.value = 0.0;
        tEffectFilter.orient = orient;
        
        [newFilter removeAllTargets];
        [oldFilter removeAllTargets];
        
        [newFilter addTarget:tEffectFilter];
        [oldFilter addTarget:tEffectFilter];
        
        [tEffectFilter removeAllTargets];
        [tEffectFilter addTarget:self.cameraScreen];
        
        oldIndex = (int)index;
    }
}

- (void) setTeffectChange:(float) value{
    if(self.filters.count == 0 ){
        return;
    }
    tEffectFilter.value = value;
//    NSLog(@"%s",__func__);
}
- (void)resetFilter:(RDFilter *)obj AtIndex:(NSInteger)index{
    RDGPUImageOutput<RDGPUImageInput> * filter;
    if (obj.type == kRDFilterType_HeiBai) {
        filter = [[RDGPUImageGrayscaleFilter alloc] init];
        
    }else if (obj.type == kRDFilterType_SLBP){
        filter = [[RDRecordGPUImageThresholdedNonMaximumSuppressionFilter alloc] initWithPackedColorspace:YES];
        ((RDRecordGPUImageThresholdedNonMaximumSuppressionFilter*)filter).threshold = 0.01;
    }
    
    else if (obj.type == kRDFilterType_Sketch){
        filter = [[RDRecordGPUImageSketchFilter alloc] init];
        
    }else if (obj.type == kRDFilterType_DistortingMirror){
        filter = [[RDRecordGPUImageStretchDistortionFilter alloc] init];
        
    }else if (obj.type == kRDFilterType_LookUp){
        if(obj.netFile.length>0){
            filter = [[RDLookupFilter alloc] initWithImageNetPath:obj.netFile intensity:obj.intensity];
        }else{
            filter = [[RDLookupFilter alloc] initWithImagePath:obj.filterPath intensity:obj.intensity];
        }
    }
    else{
        if(obj.netFile.length>0){
            filter = [[RDGPUImageToneCurveFilter alloc] initWithACVData:[NSData dataWithContentsOfURL:[NSURL URLWithString:obj.netFile]]];
        }else{
            filter =[[RDGPUImageToneCurveFilter alloc] initWithACVData:[NSData dataWithContentsOfFile:obj.filterPath]];
        }
    }
    [_filters replaceObjectAtIndex:index withObject:filter];
}
- (void)setFilterAtIndex:(NSInteger)index {
    NSLog(@"设置滤镜");
    if(_enableRdBeauty){
        if (_beautifyState == BeautifyStateNormal) {
            if(_enableCameraWaterMark){
                [_beatyPipeline replaceAllFilters:@[newAlphaBlendFilter]];
            }else{
                [_beatyPipeline replaceAllFilters:@[]];
            }
        }else{
            if (!beauty) {
                beauty = (RDGPUImageBeautifyFilter *)[RDRecordHelper beautyFilter] ;
            }
            if(_enableCameraWaterMark){
                [_beatyPipeline replaceAllFilters:@[newAlphaBlendFilter,beauty]];
            }else{
                [_beatyPipeline replaceAllFilters:@[beauty]];
            }
        }
    }
    
    if(self.gFilters.count>index){
        RDFilter *newobj = _gFilters[index];
        RDFilter *oldobj = _gFilters[oldIndex];
        
        if(newobj.filterPath.length>0 && ![[NSFileManager defaultManager] fileExistsAtPath:newobj.filterPath]){
            return;
        }
        
        currentIndex = (int)index;
        
        if (newobj.type == kRDFilterType_HeiBai) {
            newFilter = [[RDGPUImageGrayscaleFilter alloc] init];
            
        }else if (newobj.type == kRDFilterType_SLBP){
            newFilter = [[RDRecordGPUImageThresholdedNonMaximumSuppressionFilter alloc] initWithPackedColorspace:YES];
            ((RDRecordGPUImageThresholdedNonMaximumSuppressionFilter*)newFilter).threshold = 0.01;
        }
        
        else if (newobj.type == kRDFilterType_Sketch){
            newFilter = [[RDRecordGPUImageSketchFilter alloc] init];
            
        }else if (newobj.type == kRDFilterType_DistortingMirror){
            newFilter = [[RDRecordGPUImageStretchDistortionFilter alloc] init];
            
        }else if (newobj.type == kRDFilterType_LookUp){
            if(newobj.netFile.length>0){
                if([[NSFileManager defaultManager] fileExistsAtPath:newobj.filterPath]){
                    newFilter = [[RDLookupFilter alloc] initWithImagePath:newobj.filterPath intensity:newobj.intensity];
                }else{
                    newFilter = [[RDLookupFilter alloc] initWithImageNetPath:newobj.netFile intensity:newobj.intensity];
                }
            }else{
                newFilter = [[RDLookupFilter alloc] initWithImagePath:newobj.filterPath intensity:newobj.intensity];
            }
        }
        else{
            if(newobj.netFile.length>0){
                if([[NSFileManager defaultManager] fileExistsAtPath:newobj.filterPath]){
                    newFilter =[[RDGPUImageToneCurveFilter alloc] initWithACVData:[NSData dataWithContentsOfFile:newobj.filterPath]];
                }else{
                    newFilter = [[RDGPUImageToneCurveFilter alloc] initWithACVData:[NSData dataWithContentsOfURL:[NSURL URLWithString:newobj.netFile]]];
                }
            }else{
                newFilter =[[RDGPUImageToneCurveFilter alloc] initWithACVData:[NSData dataWithContentsOfFile:newobj.filterPath]];
            }
        }
        
        if (oldobj.type == kRDFilterType_HeiBai) {
            oldFilter = [[RDGPUImageGrayscaleFilter alloc] init];
            
        }else if (oldobj.type == kRDFilterType_SLBP){
            oldFilter = [[RDRecordGPUImageThresholdedNonMaximumSuppressionFilter alloc] initWithPackedColorspace:YES];
            ((RDRecordGPUImageThresholdedNonMaximumSuppressionFilter*)oldFilter).threshold = 0.01;
        }
        
        else if (oldobj.type == kRDFilterType_Sketch){
            oldFilter = [[RDRecordGPUImageSketchFilter alloc] init];
            
        }else if (oldobj.type == kRDFilterType_DistortingMirror){
            oldFilter = [[RDRecordGPUImageStretchDistortionFilter alloc] init];
            
        }else if (oldobj.type == kRDFilterType_LookUp){
            if(oldobj.netFile.length>0){
                if([[NSFileManager defaultManager] fileExistsAtPath:oldobj.filterPath]){
                    oldFilter = [[RDLookupFilter alloc] initWithImagePath:oldobj.filterPath intensity:oldobj.intensity];
                }else{
                    oldFilter = [[RDLookupFilter alloc] initWithImageNetPath:oldobj.netFile intensity:oldobj.intensity];
                }
            }else{
                oldFilter = [[RDLookupFilter alloc] initWithImagePath:oldobj.filterPath intensity:oldobj.intensity];
            }
        }
        else{
            if(oldobj.netFile.length>0){
                if([[NSFileManager defaultManager] fileExistsAtPath:oldobj.filterPath]){
                    oldFilter =[[RDGPUImageToneCurveFilter alloc] initWithACVData:[NSData dataWithContentsOfFile:oldobj.filterPath]];
                }else{
                    oldFilter = [[RDGPUImageToneCurveFilter alloc] initWithACVData:[NSData dataWithContentsOfURL:[NSURL URLWithString:oldobj.netFile]]];
                }
            }else{
                oldFilter =[[RDGPUImageToneCurveFilter alloc] initWithACVData:[NSData dataWithContentsOfFile:oldobj.filterPath]];
            }
        }
        
        
        //newFilter = self.filters[index];
        //oldFilter = self.filters[oldIndex];
        NSLog(@"设置滤镜2");
        
        [_cropFilter removeAllTargets];
        if (mvFilter) {
            [_cropFilter addTarget:mvFilter];
            [mvFilter addTarget:newFilter];
        }else {
            [_cropFilter addTarget:newFilter];
        }
        [oldFilter removeAllTargets];
        [newFilter removeAllTargets];
        
        if (maskFilter) {
            [newFilter addTarget:maskFilter];
            [maskFilter addTarget:self.cameraScreen];
        }else {
//            [newFilter addTarget:newAlphaBlendFilter atTextureLocation:0];
//            [newUIElement addTarget:newAlphaBlendFilter];
            [newFilter addTarget:self.cameraScreen];
 
        }
        if (_isRecording) {
            if (_cameraDirection == kUP/*_isPortrait*/) {
                [_movieWriter setInputRotation:kRDGPUImageRotateRight atIndex:0];
            }
            else if (_cameraDirection == kDOWN/*_isPortrait*/) {
                [_movieWriter setInputRotation:kRDGPUImageRotateLeft atIndex:0];
            }
            else if (_cameraDirection == kRIGHT/*_isPortrait*/) {
                [_movieWriter setInputRotation:kRDGPUImageRotate180 atIndex:0];
            }
//            [newFilter addTarget:newAlphaBlendFilter atTextureLocation:1];
//            [newUIElement addTarget:newAlphaBlendFilter];
            [newFilter addTarget:cropFilterT];
            [cropFilterT addTarget:_movieWriter];
        }
        
        oldIndex = (int)index;
    }
 NSLog(@"设置滤镜3");
//    [newFilter setFrameProcessingCompletionBlock:^(RDGPUImageOutput *output, CMTime time) {
//        NSLog(@"进入:%f",CMTimeGetSeconds(time));
//
//        [newUIElement update];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if(_cameraDirection == kUP || _cameraDirection == kDOWN){
//
//                _watermarkLayer.frame = CGRectMake(0, 0, _frame.size.height, _frame.size.width);
//            }else{
//
//                _watermarkLayer.frame = _frame;
//            }
//            [_watermarkLayer.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
//
//            [_watermarkView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
//
//            if([_delegate respondsToSelector:@selector(waterMarkProcessingCompletionBlockWithView:withTime:)]){
//                [_delegate waterMarkProcessingCompletionBlockWithView:_watermarkLayer withTime:_allRecordTime + CMTimeGetSeconds(diffRecordTime)];
//            }
//
//            [_watermarkView addSubview:_watermarkLayer];
//        });
//        //[weakOverlay update];
//
//    }];
}

#pragma mark - MV
- (void)setMVEffects:(NSMutableArray<RDCameraMVEffect *> *)mvEffects {
    RDGPUImageCameraMVEffectFilter *mvEffectFilter = [[RDGPUImageCameraMVEffectFilter alloc] init];
    mvEffectFilter.fps = _fps;
    mvEffectFilter.mvEffects = mvEffects;
    mvFilter = mvEffectFilter;
    
    [_cropFilter removeAllTargets];
    if (mvFilter) {
        [_cropFilter addTarget:mvFilter];
        [mvFilter addTarget:newFilter];
    }else {
        [_cropFilter addTarget:newFilter];
    }
}

#pragma mark - 设置mask
- (void)setMaskPath:(NSString *)maskPath {
    if (maskPath) {
        [self refreshCropFilter];
        self.cameraScreen.superview.backgroundColor = [UIColor clearColor];
        [_cameraScreen removeGestureRecognizer:pan];
        
        _maskPath = maskPath;
        UIImage *maskImage = [UIImage imageWithContentsOfFile:maskPath];
        maskImage = [self rescaleImage:maskImage size:CGSizeMake(_cameraSize.width, ceilf(_cameraSize.width*(_frame.size.width/_frame.size.height)))];
        maskImage = [self generateMaskImage:maskImage];
      
#if 0   //使用RDMaskFilter时，每切换一个格子，内存就会增长2M，使用RDGPUImageMaskFilter内存不会增长
        [newFilter removeAllTargets];
        if (maskFilter) {
            [maskFilter removeAllTargets];
            maskFilter = nil;
        }
        maskFilter = [[RDMaskFilter alloc] initWithImage:maskImage];
        [newFilter addTarget:maskFilter];
        [maskFilter addTarget:self.cameraScreen];
#else
        if (maskFilter) {
            [maskFilter removeAllTargets];
            [maskPicture removeAllTargets];
            maskPicture = nil;
        }else {
            [newFilter removeAllTargets];
            maskFilter = [[RDGPUImageMaskFilter alloc] init];
            [maskFilter setBackgroundColorRed:0.0 green:0.0 blue:0.0 alpha:0.0];
            [newFilter addTarget:maskFilter];
        }
        maskPicture = [[RDGPUImagePicture alloc] initWithImage:maskImage smoothlyScaleOutput:NO];
        [maskPicture processImage];
        [maskPicture addTarget:maskFilter];
        [maskFilter addTarget:self.cameraScreen];
#endif
    }
}

- (void)refreshCropFilter {
    CGSize matchSize = [RDRecordHelper matchSize];
    CGSize recordSize = _cameraSize;
    
    CGFloat ratey = MIN(recordSize.width/matchSize.width, 1.);
    CGFloat ratex = MIN(recordSize.height/matchSize.height, 1.);
    
    CGRect cropRect = CGRectMake((1. - ratex)/2., (1. - ratey)/2., 1.0 * ratex, 1.0 * ratey);
    _cropFilter.cropRegion = cropRect;
}

- (UIImage *)generateMaskImage:(UIImage *)image {
    CGRect rect = (CGRect){CGPointZero, _cameraSize};
    
    UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRect:rect];
    roundedRect.lineWidth = 0;
    UIGraphicsBeginImageContext(rect.size);
    
    [[UIColor whiteColor] setFill];
    [roundedRect fill];
    [roundedRect stroke];
    [roundedRect addClip];
    
    CGRect imageRect = CGRectMake((rect.size.width - image.size.width)/2.0, (rect.size.height - image.size.height)/2.0, image.size.width, image.size.height);
    [image drawInRect:imageRect];
    
    UIImage *resImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return [self rotateImage:resImage orientation:UIImageOrientationLeft];
}

//压缩图片至指定尺寸
- (UIImage *)rescaleImage:(UIImage *)image size:(CGSize)size
{
    CGRect rect = (CGRect){CGPointZero, size};
    
    UIGraphicsBeginImageContext(rect.size);
    
    [image drawInRect:rect];
    
    UIImage *resImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return resImage;
}

- (UIImage*)rotateImage:(UIImage *)image orientation:(UIImageOrientation)orient
{
    CGRect bnds = CGRectZero;
    UIImage* copy = nil;
    CGContextRef ctxt = nil;
    CGImageRef imag = image.CGImage;
    CGRect rect = CGRectZero;
    CGAffineTransform tran = CGAffineTransformIdentity;
    
    rect.size.width = CGImageGetWidth(imag);
    rect.size.height = CGImageGetHeight(imag);
    
    bnds = rect;
    
    switch (orient)
    {
        case UIImageOrientationUp:
            return image;
            
        case UIImageOrientationUpMirrored:
            tran = CGAffineTransformMakeTranslation(rect.size.width, 0.0);
            tran = CGAffineTransformScale(tran, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown:
            tran = CGAffineTransformMakeTranslation(rect.size.width,
                                                    rect.size.height);
            tran = CGAffineTransformRotate(tran, M_PI);
            break;
            
        case UIImageOrientationDownMirrored:
            tran = CGAffineTransformMakeTranslation(0.0, rect.size.height);
            tran = CGAffineTransformScale(tran, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeft:
            bnds = swapWidthAndHeight(bnds);
            tran = CGAffineTransformMakeTranslation(0.0, rect.size.width);
            tran = CGAffineTransformRotate(tran, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeftMirrored:
            bnds = swapWidthAndHeight(bnds);
            tran = CGAffineTransformMakeTranslation(rect.size.height,
                                                    rect.size.width);
            tran = CGAffineTransformScale(tran, -1.0, 1.0);
            tran = CGAffineTransformRotate(tran, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRight:
            bnds = swapWidthAndHeight(bnds);
            tran = CGAffineTransformMakeTranslation(rect.size.height, 0.0);
            tran = CGAffineTransformRotate(tran, M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored:
            bnds = swapWidthAndHeight(bnds);
            tran = CGAffineTransformMakeScale(-1.0, 1.0);
            tran = CGAffineTransformRotate(tran, M_PI / 2.0);
            break;
            
        default:
            return image;
    }
    
    UIGraphicsBeginImageContext(bnds.size);
    ctxt = UIGraphicsGetCurrentContext();
    
    switch (orient)
    {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextScaleCTM(ctxt, -1.0, 1.0);
            CGContextTranslateCTM(ctxt, -rect.size.height, 0.0);
            break;
            
        default:
            CGContextScaleCTM(ctxt, 1.0, -1.0);
            CGContextTranslateCTM(ctxt, 0.0, -rect.size.height);
            break;
    }
    
    CGContextConcatCTM(ctxt, tran);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), rect, imag);
    
    copy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
        
    return copy;
}

/** 交换宽和高 */
static CGRect swapWidthAndHeight(CGRect rect)
{
    CGFloat swap = rect.size.width;
    
    rect.size.width = rect.size.height;
    rect.size.height = swap;
    
    return rect;
}

#pragma mark - RDGPUImageMovieWriterDelegate
- (void)movieRecordingBegin{
    
    _startTime = CACurrentMediaTime();
    _isRecording = YES;
    
    
    if (_delegate && !_sdkDisabled) {
        if ([_delegate respondsToSelector:@selector(movieRecordBegin)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate movieRecordBegin];
            });
        }
    }
}

- (void)movieRecordingCancelType:(int)type{
    _isRecording = NO;
    if (type == 0) {
        NSLog(@"帧缓存完整性判断失败，立即取消");
        //        [self cancelRecording];
        
        if (_delegate) {
            if ([_delegate respondsToSelector:@selector(movieRecordCancel)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate movieRecordCancel];
                });
            }
        }
    }
    
    if (type == 1) {
        //
        NSLog(@"AVAssetWriter.status == 2");
    }
    
}
/*空间不足时，会报的两个error
 Error Domain=AVFoundationErrorDomain Code=-11807 "操作停止" UserInfo={NSLocalizedRecoverySuggestion=磁盘空间不足，无法继续写文件。请删除现有视频或照片来腾出空间。, NSUnderlyingError=0x8e7e310 {Error Domain=NSPOSIXErrorDomain Code=28 "No space left on device"}, NSLocalizedDescription=操作停止}
 
 Error Domain=NSURLErrorDomain Code=-3000 "无法创建文件" UserInfo={NSUnderlyingError=0x8df1200 {Error Domain=NSOSStatusErrorDomain Code=-12143 "(null)"}, NSLocalizedDescription=无法创建文件}
 
 一帧都没有录制时，会报的error，可以忽略
 Error Domain=AVFoundationErrorDomain Code=-11800 "这项操作无法完成" UserInfo={NSUnderlyingError=0x174252900 {Error Domain=NSOSStatusErrorDomain Code=-12142 "(null)"}, NSLocalizedFailureReason=发生未知错误（-12142）, NSLocalizedDescription=这项操作无法完成}
 */
- (void)movieRecordingFailedWithError:(NSError*)error {
    NSLog(@"%s:%@", __func__, error);
    if(_delegate && [_delegate respondsToSelector:@selector(movieRecordFailed:)]){
        NSError *error = _movieWriter.assetWriter.error;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate movieRecordFailed:error];
        });
    }
}

#pragma mark - AnimationDelegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    
}

#pragma mark focusLayer 回到初始化状态
- (void)focusLayerNormal {
    _focusLayer.hidden = YES;
}
#pragma mark dealloc
- (void)dealloc{
   
    currentIndex = 0;
    NSLog(@"%s",__func__);
    
#ifdef AUDIOUNIT
#ifdef AUDIO_RECORD
    if (_outputFile) { CFRelease(_outputFile); _outputFile = NULL; }
    
    if (extAudioFile)
        ExtAudioFileDispose(extAudioFile);
#endif
    
    if (auGraph) {
        if (didSetUpAudioUnits)
            AUGraphUninitialize(auGraph);
        DisposeAUGraph(auGraph);
    }
    
    if (currentInputAudioBufferList) free(currentInputAudioBufferList);
    if (outputBufferList) delete outputBufferList;
#endif
    
}

- (NSString *)getVideoSaveFileFolderString{
//    return [RDRecordHelper getVideoSaveFolderPathString];
    if (!_tempVideoFolderPath || _tempVideoFolderPath.length == 0) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        _tempVideoFolderPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"videos"];
    }
    return _tempVideoFolderPath;
}

#define degreesToRadians( degrees ) ( ( degrees ) / 180.0 * M_PI )


- (void)mergeAndExportVideosAtFileURLs:(NSArray<RDCameraFile *> *)fileArray progress:(void(^)(NSNumber *progress))progressBlock finish:(void(^)(NSURL *videourl))finish fail:(void(^)(NSError *error))fail cancel:(void(^)())cancel
{
    if (_sdkDisabled) {
        return;
    }
    _progressBlock = progressBlock;
    
    if (fileArray.count == 0) {
        return;
    }
    
    NSString *mergePath = [self getfilePathStringWithSuffix:@"merge"];
    
    if(mergePath.length == 0){
        if(fail){
            
            fail([NSError errorWithDomain:@"" code:000 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"创建文件夹失败",@"message", nil]]);
        }
        return;
    }
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack* videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack* audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    BOOL isHaveAudioTrack = NO;
    CMTime totalDuration = kCMTimeZero;
    for (int i=0;i<fileArray.count;i++) {
        RDCameraFile *camerafile = fileArray[i];
        
        NSString *videoPath = [[self getVideoSaveFileFolderString] stringByAppendingString:[NSString stringWithFormat:@"/%@",camerafile.fileName]];
        NSURL* url = [NSURL fileURLWithPath:videoPath];
        AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url options:nil];
        NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        if(videoTracks.count==0){
            continue;
        }
        
        AVAssetTrack* assetVideoTrack = [videoTracks objectAtIndex:0];
        
        CMTimeRange  insertTimeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
        NSLog(@"insertTimeRange.duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, insertTimeRange.duration)));
#if 1
        if (CMTimeCompare(assetVideoTrack.timeRange.duration, asset.duration) == -1) {
            insertTimeRange = CMTimeRangeMake(kCMTimeZero, assetVideoTrack.timeRange.duration);
            NSLog(@"video insertTimeRange.duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, insertTimeRange.duration)));
        }
        if ([asset tracksWithMediaType:AVMediaTypeAudio].count > 0) {
            AVAssetTrack* assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
            if (CMTimeCompare(assetAudioTrack.timeRange.duration, insertTimeRange.duration) == -1) {
                insertTimeRange = CMTimeRangeMake(kCMTimeZero, assetAudioTrack.timeRange.duration);
                NSLog(@"audio insertTimeRange.duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, insertTimeRange.duration)));
            }
        }
#endif
        NSError *error;
        BOOL suc = [videoTrack insertTimeRange:insertTimeRange ofTrack:assetVideoTrack atTime:totalDuration error:&error];
        if(!suc){
            NSLog(@"***video insert error:%@",error);
        }
        
        float scaleDuration = CMTimeGetSeconds(insertTimeRange.duration)/camerafile.speed;
        CMTimeRange speedTimeRange = insertTimeRange;
        speedTimeRange.start = totalDuration;
        
        [videoTrack scaleTimeRange:speedTimeRange toDuration:CMTimeMakeWithSeconds(scaleDuration, TIMESCALE)];
        
        if ([asset tracksWithMediaType:AVMediaTypeAudio].count > 0) {//20170323
            isHaveAudioTrack = YES;
            AVAssetTrack* assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
            error = nil;
            suc = [audioTrack insertTimeRange:insertTimeRange ofTrack:assetAudioTrack atTime:totalDuration error:&error];
            if(!suc){
                NSLog(@"***audio insert error:%@",error);
            }
            [audioTrack scaleTimeRange:speedTimeRange toDuration:CMTimeMakeWithSeconds(scaleDuration, TIMESCALE)];
        }
        
        
        totalDuration = CMTimeAdd(totalDuration, CMTimeMakeWithSeconds(scaleDuration, TIMESCALE));
        NSLog(@"***totalDuration:%f",CMTimeGetSeconds(totalDuration));
    }
    
    unlink([mergePath UTF8String]);
    
    NSURL* exportURL  = [NSURL fileURLWithPath:mergePath];
    
    //20170630 wuxiaoxia 如果录制的视频没有音频(快速点击录制按钮)，不能合并
    if (!isHaveAudioTrack) {
        [mixComposition removeTrack:audioTrack];
    }
    //AVAssetExportPresetPassthrough 对声音缩放有影响
    exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];//
   
    if(_exportTimer){
        [_exportTimer invalidate];
        _exportTimer = nil;
    }
    _exportTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(updateMergExportProgress) userInfo:nil repeats:YES];
    
    exporter.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.outputURL = exportURL;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (exporter.status) {
                case AVAssetExportSessionStatusCompleted:
                {
                    if(_exportTimer){
                        [_exportTimer invalidate];
                        _exportTimer = nil;
                    }
                    if(finish){
                        finish(exportURL);
                    }
                }
                    break;
                case AVAssetExportSessionStatusFailed:
                {
                    unlink([mergePath UTF8String]);
                    if(_exportTimer){
                        [_exportTimer invalidate];
                        _exportTimer = nil;
                    }
                    if(fail){
                        fail(exporter.error);
                    }
                }
                    break;
                case AVAssetExportSessionStatusExporting:
                {
                    NSLog(@"Exporting");
                }
                    break;
                case AVAssetExportSessionStatusWaiting:
                {
                    NSLog(@"Waiting");
                }
                    break;
                case AVAssetExportSessionStatusCancelled:
                {
                    unlink([mergePath UTF8String]);
                    if(_exportTimer){
                        [_exportTimer invalidate];
                        _exportTimer = nil;
                    }
                    if(cancel){
                        cancel();
                    }
                }
                    break;
                default:
                    break;
            }

        });
    }];
}

- (void)updateMergExportProgress{
    if(_progressBlock){
        _progressBlock([NSNumber numberWithFloat:exporter.progress]);
    }
}

- (void)cancelMerge{
    [exporter cancelExport];
}

- (void) deleteItems
{
    [_watermarkView removeFromSuperview];
    _watermarkView = nil;
    [_cameraScreen removeFromSuperview];
    _cameraScreen = nil;
    currentIndex = 0;
    [_filterPipeline removeAllFilters];
    [_focusLayer removeAllAnimations];//20170324 不移除，不会调用dealloc
}

#if 0
- (void)speedAndExportVideosAtFileURL:(NSURL *)url speed:(float)speed progress:(void(^)(float progress))progress finish:(void(^)(NSString *fileName, NSURL *videoUrl))finish fail:(void(^)(NSError *error))fail cancel:(void(^)())cancel
{
    if (!url) {
        return;
    }
    NSString *mergePath = [self getfilePathStringWithSuffix:@"merge"];
    
    if(mergePath.length == 0){
        if(fail){
            fail([NSError errorWithDomain:@"" code:000 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"创建文件夹失败",@"message", nil]]);
        }
        return;
    }
    
    AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack* videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack* audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    CMTime totalDuration = kCMTimeZero;
    
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    
    AVAssetTrack* assetVideoTrack = [videoTracks objectAtIndex:0];
    
    CMTimeRange  speedTimeRange       = CMTimeRangeMake(kCMTimeZero, CMTimeSubtract(asset.duration, CMTimeMake(1, _fps)));
    
    NSError *error;
    BOOL suc = [videoTrack insertTimeRange:speedTimeRange ofTrack:assetVideoTrack atTime:totalDuration error:&error];
    if(!suc){
        NSLog(@"***video insert error:%@",error);
    }
    
    float scaleDuration = CMTimeGetSeconds(asset.duration) / speed;//;
    
    speedTimeRange.start       = totalDuration;
    
    [videoTrack scaleTimeRange:speedTimeRange toDuration:CMTimeMakeWithSeconds(scaleDuration, TIMESCALE)];
    
    if ([asset tracksWithMediaType:AVMediaTypeAudio].count > 0) {//20170323
        AVAssetTrack* assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        suc = [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeSubtract(asset.duration, CMTimeMake(1, _fps))) ofTrack:assetAudioTrack atTime:totalDuration error:nil];
        if(!suc){
            NSLog(@"***audio insert error:%@",error);
        }
        
        speedTimeRange.start       = totalDuration;
        [videoTrack scaleTimeRange:speedTimeRange toDuration:CMTimeMakeWithSeconds(scaleDuration, TIMESCALE)];
    }
    
    
    totalDuration = CMTimeAdd(totalDuration, CMTimeMakeWithSeconds(scaleDuration, TIMESCALE));
    NSLog(@"***totalDuration:%f",CMTimeGetSeconds(totalDuration));
    
    unlink([mergePath UTF8String]);
    
    NSURL* exportURL  = [NSURL fileURLWithPath:mergePath];
    
    exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];//AVAssetExportPresetPassthrough
    exporter.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(scaleDuration, TIMESCALE));
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.outputURL = exportURL;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (exporter.status) {
                case AVAssetExportSessionStatusCompleted:
                {
                    if(finish){
                        finish([url lastPathComponent],exportURL);
                    }
                }
                    break;
                case AVAssetExportSessionStatusFailed:
                {
                    if(fail){
                        fail(exporter.error);
                    }
                }
                    break;
                case AVAssetExportSessionStatusExporting:
                {
                    
                }
                    break;
                case AVAssetExportSessionStatusWaiting:
                {
                    
                }
                    break;
                case AVAssetExportSessionStatusCancelled:
                {
                    if(cancel){
                        cancel();
                    }
                }
                    break;
                default:
                    break;
            }
        });
    }];
}
#endif

- (AVMutableComposition *)buildVideoForFileURL:(NSURL *)url timeRange:(CMTimeRange)timerange
{
    if (!url) {
        return nil;
    }
    AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack* videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
//    AVMutableCompositionTrack* audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    
    AVAssetTrack* assetVideoTrack = [videoTracks objectAtIndex:0];
    
    NSError *error;
    BOOL suc = [videoTrack insertTimeRange:timerange ofTrack:assetVideoTrack atTime:kCMTimeZero error:&error];
    if(!suc){
        NSLog(@"***video insert error:%@",error);
    }
    
   
//    if ([asset tracksWithMediaType:AVMediaTypeAudio].count > 0) {//20170323
//        AVAssetTrack* assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
//        suc = [audioTrack insertTimeRange:timerange ofTrack:assetAudioTrack atTime:kCMTimeZero error:nil];
//        if(!suc){
//            NSLog(@"***audio insert error:%@",error);
//        }
//        
//    }
    
    return mixComposition;

}
//- (void)setBlurLevel:(float)blurLevel{
//    if (_enableRdBeauty) {
//        beauty.texelSpacingMultiplier = blurLevel;
//    }
//
//}
//
//- (void)setColorLevel:(float)colorLevel{
//    if (_enableRdBeauty) {
//        [beauty adjustBrightness:1.0 + colorLevel * 0.19];
//    }
//}
- (void)cancelRevers{
    _cancelExport = YES;
#if USEINSERTTIMERANGE
    if(!_witeTrackInsertEnd){
        [exporter cancelExport];
    }
#endif
}

- (void)changeExportProgress:(NSNumber *)numProgress{
    if(_progressReverseBlock){
        _progressReverseBlock(numProgress);
    }
}

#if !USEINSERTTIMERANGE
- (void)exportReverseVideo:(NSURL *)url
                          outputUrl:(NSURL *)outputUrl
                          timeRange:(CMTimeRange)timeRange
                      progressBlock:(ProgressBlock)progressBlock
                      callbackBlock:(void (^)())callbackBlock
                               fail:(void (^)())failBlock
{
    if (_sdkDisabled) {
        return;
    }
    _cancelBlock = failBlock;
    _progressReverseBlock = progressBlock;
    NSError *error;
    _lastReverseProgress = 0;
    _lastReverseWriteProgress = 0;
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    NSLog(@"duration : %f",CMTimeGetSeconds(asset.duration));

    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if(tracks.count == 0){
        failBlock();
        return;
    }
    
    
    [[ NSFileManager defaultManager] removeItemAtURL:outputUrl error:&error];
    if(error){
        NSLog(@"%@",error);
        error = nil;
    }
    float fenduanDuration = 2.0;
    
    if(outputUrl.path.length == 0)
        outputUrl = [NSURL fileURLWithPath:[self getfilePathStringWithSuffix:@"reverse"]];
    
    // Initialize the reader
    AVAssetTrack *writeVideoTrack = [tracks lastObject];
   
    // Initialize the writer
    _assetWriter = [[AVAssetWriter alloc] initWithURL:outputUrl
                                             fileType:AVFileTypeMPEG4
                                                error:&error];
    NSDictionary *writeVideoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                                @(writeVideoTrack.estimatedDataRate), AVVideoAverageBitRateKey,
                                                AVVideoProfileLevelH264BaselineAutoLevel,AVVideoProfileLevelKey, //talker 2017-04-12 不加这个设置，有的视频倒放后，拖动会卡死（copyNextSampleBuffer）
                                                @(15),AVVideoMaxKeyFrameIntervalKey,
                                                nil];
    NSDictionary *writerOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                          AVVideoCodecH264, AVVideoCodecKey,
                                          [NSNumber numberWithInt:writeVideoTrack.naturalSize.width], AVVideoWidthKey,
                                          [NSNumber numberWithInt:writeVideoTrack.naturalSize.height], AVVideoHeightKey,
                                          writeVideoCompressionProps, AVVideoCompressionPropertiesKey,
                                          nil];
    _writerInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                                                     outputSettings:writerOutputSettings
                                                                   sourceFormatHint:(__bridge CMFormatDescriptionRef)[writeVideoTrack.formatDescriptions lastObject]];
    _writerInput.transform = writeVideoTrack.preferredTransform;
    [_writerInput setExpectsMediaDataInRealTime:NO];
    // Initialize an input adaptor so that we can append PixelBuffer
    _pixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:_writerInput sourcePixelBufferAttributes:nil];
    
    
    BOOL can =[_assetWriter canAddInput:_writerInput];
    if(can){
        [_assetWriter addInput:_writerInput];
    }else{
        NSLog(@"canot");
    }
    [_assetWriter startWriting];
    [_assetWriter startSessionAtSourceTime:kCMTimeZero];
    
#if 1
    NSLog(@"buildVideoForFileURL");
    
    //NSString *timestr = [NSString stringWithFormat:@"%f", (double)[[NSDate date] timeIntervalSince1970]];
    
    
    double time = CACurrentMediaTime();//[timestr doubleValue];
    
    if (CMTimeRangeEqual(timeRange, kCMTimeRangeZero)) {
        timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    }
    
    AVMutableComposition *mComposition = [self buildVideoForFileURL:url timeRange:timeRange];
    
    AVComposition *composition = mComposition;
    
    //timestr = [NSString stringWithFormat:@"%f", (double)[[NSDate date] timeIntervalSince1970]];
    
    NSLog(@"buildVideoForFileURL 耗时：start :%lf end:%lf dif:%lf",time,CACurrentMediaTime(),CACurrentMediaTime()-time);
    
//    time = CACurrentMediaTime();
    
    float totalDuration = CMTimeGetSeconds(timeRange.duration);
    
    
    
    while (totalDuration>fenduanDuration) {
        @autoreleasepool {//20170620 wuxiaoxia 必须加释放池，否则在有的设备上，倒序时会因内存崩溃
        totalDuration -=fenduanDuration;
        
        CMTimeRange itemTimeRange = CMTimeRangeMake( CMTimeAdd(CMTimeMakeWithSeconds(totalDuration, TIMESCALE),timeRange.start), CMTimeMakeWithSeconds(fenduanDuration, TIMESCALE));
        
        NSLog(@"createReverseReader");
        time = CACurrentMediaTime();
        
        [self createReverseReader:composition timeRange:itemTimeRange];
        
        
        [_reverseReader startReading];
        
        NSLog(@"createReverseReader 耗时：%lf",CACurrentMediaTime() - time);
        
        [self progressFrame:CMTimeMakeWithSeconds(CMTimeGetSeconds(CMTimeAdd(timeRange.duration,timeRange.start)) - (totalDuration+fenduanDuration), TIMESCALE) duration:fenduanDuration totalduration:CMTimeGetSeconds(timeRange.duration)];
        
        //NSLog(@"单次耗时：%f",CACurrentMediaTime() - time);
        }
    }
    
    @autoreleasepool {
    CMTimeRange difTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(0, TIMESCALE), CMTimeMakeWithSeconds(totalDuration, TIMESCALE));
    NSLog(@"createReverseReader");
    time = CACurrentMediaTime();
    
    [self createReverseReader:composition timeRange:difTimeRange];
    
    NSLog(@"createReverseReader 耗时：start :%lf end:%lf dif:%lf",time,CACurrentMediaTime(),CACurrentMediaTime()-time);

    [_reverseReader startReading];
    
    
    [self progressFrame:CMTimeMakeWithSeconds(CMTimeGetSeconds(CMTimeAdd(timeRange.duration, timeRange.start)) - (totalDuration), TIMESCALE) duration:totalDuration totalduration:CMTimeGetSeconds(timeRange.duration)];
    }

#endif
        if (!_cancelExport) {
            [_assetWriter finishWritingWithCompletionHandler:^{
                if(callbackBlock){
                    callbackBlock();
                }
            }];
        }else{
            [_assetWriter cancelWriting];
            if(_cancelBlock){
                _cancelBlock();
            }
            
        }
        
        writeVideoTrack = nil;
        writeVideoCompressionProps = nil;
        writerOutputSettings = nil;
        _writerInput = nil;
        _pixelBufferAdaptor = nil;
}



- (void)createReverseReader:(AVComposition *)composition timeRange:(CMTimeRange )timerange{
    _lastReverseProgress = 0;
    _lastReverseWriteProgress = 0;
    _reverseReader = nil;
    NSError *error;
    _reverseReader = [[AVAssetReader alloc] initWithAsset:composition error:&error];
    AVAssetTrack *videoTrack = [[composition tracksWithMediaType:AVMediaTypeVideo] lastObject];
    NSDictionary *readerOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange], kCVPixelBufferPixelFormatTypeKey, nil];
    
    _readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack
                                                                                        outputSettings:readerOutputSettings];
    //_readerOutput.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmLowQualityZeroLatency;
    _readerOutput.alwaysCopiesSampleData = NO;
    [_reverseReader addOutput:_readerOutput];
    _reverseReader.timeRange = timerange;//;
    
}

- (void)progressFrame:(CMTime)startTime duration:(float)timeDuration totalduration:(float)totalduration{
    // read in the samples
    CMSampleBufferRef sample;
    NSMutableArray *samples = [[NSMutableArray alloc] init];
    
    double time = CACurrentMediaTime();
    
    while(!_cancelExport && _reverseReader.status == AVAssetReaderStatusReading &&(sample = [_readerOutput copyNextSampleBuffer])) {
        ;
        CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sample);
        Float64 currentTime = CMTimeGetSeconds(currentSampleTime);
        
        
        [samples addObject:(__bridge id)sample];
        float progress = currentTime/timeDuration;
        CFRelease(sample);
        sample = nil;
        if(_lastReverseProgress+0.01<=progress){
            _lastReverseProgress = progress;
            @try {
                //float exportProgress = (progress/2.0*timeDuration + CMTimeGetSeconds(startTime))/totalduration;
                //NSLog(@"反转截图:progress:%f 时间: %f ",exportProgress,currentTime);
                //[NSThread detachNewThreadSelector:@selector(changeExportProgress:) toTarget:self withObject:[NSNumber numberWithFloat:exportProgress]];
                
            } @catch (NSException *exception) {
                NSLog(@"exception:%@",exception);
            }
        }
    }
    NSLog(@"解码耗时：%lf",CACurrentMediaTime() - time);
    time = CACurrentMediaTime();
    
    NSLog(@"_reverseReader.status:%ld",(long)_reverseReader.status);
    [_reverseReader cancelReading];
    for(NSInteger i = 0; i < samples.count; i++) {
        
        CMTime presentationTime = CMTimeAdd(startTime,CMTimeMakeWithSeconds(i*(timeDuration/samples.count), TIMESCALE));
        
        
        // take the image/pixel buffer from tail end of the array
        CVPixelBufferRef imageBufferRef = CMSampleBufferGetImageBuffer((__bridge CMSampleBufferRef)samples[samples.count - i - 1]);
        
        while (!_writerInput.readyForMoreMediaData) {
            [NSThread sleepForTimeInterval:0.1];
        }
        if(_writerInput.readyForMoreMediaData){
            //NSLog(@"%f",CMTimeGetSeconds(presentationTime));
            BOOL suc =  [_pixelBufferAdaptor appendPixelBuffer:imageBufferRef withPresentationTime:presentationTime];
            if(!suc){
                NSLog(@"appendPixelBuffer fail");
            }
        }else{
            NSLog(@"readyForMoreMediaData no");
        }
        Float64 currentTime = CMTimeGetSeconds(presentationTime);
        float progress = currentTime/timeDuration;
        if(_lastReverseWriteProgress+0.01<=progress){
            _lastReverseWriteProgress = progress;
            @try {
                float exportProgress = (currentTime)/totalduration;
                NSLog(@"编码progress:%f 时间: %f ",exportProgress,currentTime);

                [NSThread detachNewThreadSelector:@selector(changeExportProgress:) toTarget:self withObject:[NSNumber numberWithFloat:exportProgress]];
            } @catch (NSException *exception) {
                NSLog(@"exception:%@",exception);
            }
        }
        if (_cancelExport) {
            break;
        }
    }
    [samples removeAllObjects];
    samples = nil;
    NSLog(@"编码码耗时：%lf",CACurrentMediaTime() - time);

    if (_cancelExport) {
        return;
    }
}


#else
- (void)exportVideoByReversingAsset:(NSURL *)url
                          outputUrl:(NSURL *)outputUrl
                      progressBlock:(ProgressBlock)progressBlock
                      callbackBlock:(void (^)(NSURL *reverUrl))callbackBlock
                               fail:(void (^)())failBlock
{
    if (_sdkDisabled) {
        return;
    }
    _cancelBlock = failBlock;
    _progressReverseBlock = progressBlock;
    _lastReverseProgress = 0;
    _lastReverseWriteProgress = 0;
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    NSLog(@"duration : %f",CMTimeGetSeconds(asset.duration));
    
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if(tracks.count == 0){
        failBlock(nil);
        return;
    }
    
    float fps = 10.0;
    
    float fenduanDuration = 1.0/fps;
    if(outputUrl.path.length==0)
        outputUrl = [NSURL fileURLWithPath:[self getfilePathStringWithSuffix:@"reverse"]];
    
    
    AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack* videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack* audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];

    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];

    float totalDuration = CMTimeGetSeconds(asset.duration);
    CMTime totalTime = kCMTimeZero;
    NSError *error;
    _witeTrackInsertEnd = YES;
    long long currentMediaTime = CACurrentMediaTime();
    
    while (totalDuration>fenduanDuration && !_cancelExport) {
        totalDuration -=fenduanDuration;
        
        CMTimeRange insertTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(totalDuration, TIMESCALE), CMTimeMakeWithSeconds(fenduanDuration, TIMESCALE));
        //CMTimeRange speedTimeRange = insertTimeRange;
        //speedTimeRange.start = totalTime;
        //CMTime speedTimeRange_duration = CMTimeMakeWithSeconds(fenduanDuration, TIMESCALE);
        
        AVAssetTrack* assetVideoTrack = [videoTracks objectAtIndex:0];
        
        BOOL suc = [videoTrack insertTimeRange:insertTimeRange ofTrack:assetVideoTrack atTime:totalTime error:&error];
        if(!suc){
            NSLog(@"***video insert error:%@ insertTimeRange-->start :%f dur:%f",error,CMTimeGetSeconds(insertTimeRange.start),CMTimeGetSeconds(insertTimeRange.duration));
        }else{
            NSLog(@"***video insert TimeRange-->start :%f dur:%f",CMTimeGetSeconds(insertTimeRange.start),CMTimeGetSeconds(insertTimeRange.duration));
            
            //[videoTrack scaleTimeRange:speedTimeRange toDuration:speedTimeRange_duration];
        }
        
        if ([asset tracksWithMediaType:AVMediaTypeAudio].count > 0) {//20170323
            AVAssetTrack* assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
            suc = [audioTrack insertTimeRange:insertTimeRange ofTrack:assetAudioTrack atTime:totalTime error:nil];
            if(!suc){
                NSLog(@"***audio insert error:%@",error);
            }
            //[audioTrack scaleTimeRange:speedTimeRange toDuration:speedTimeRange_duration];

        }
        NSLog(@"***totalDuration:%f",CMTimeGetSeconds(totalTime));
        totalTime = CMTimeAdd(totalTime, CMTimeMakeWithSeconds(fenduanDuration, TIMESCALE));
        
    }
    NSLog(@"倒序插入视频 耗时：%f ",CACurrentMediaTime() - currentMediaTime);

    _witeTrackInsertEnd = NO;
    if(_cancelExport){
        if(_cancelBlock){
            _cancelBlock();
        }
    }
    exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetPassthrough];//
    
    
    
    exporter.timeRange = CMTimeRangeMake(kCMTimeZero, totalTime);
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.outputURL = outputUrl;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (exporter.status) {
                case AVAssetExportSessionStatusCompleted:
                {
                    if(callbackBlock){
                        callbackBlock(outputUrl);
                    }
                }
                    break;
                case AVAssetExportSessionStatusFailed:
                {
                    if(failBlock){
                        failBlock(exporter.error);
                    }
                }
                    break;
                case AVAssetExportSessionStatusExporting:
                {
                    
                }
                    break;
                case AVAssetExportSessionStatusWaiting:
                {
                    
                }
                    break;
                case AVAssetExportSessionStatusCancelled:
                {
                    if(_cancelBlock){
                        _cancelBlock();
                    }
                }
                    break;
                default:
                    break;
            }
        });
    }];
    
}
#endif

- (void)trimVideoWithVideoUrl:(NSURL *)url
                    outputUrl:(NSURL *)outputUrl
                trimTimeRange:(CMTimeRange)trimTimeRange
                progressBlock:(void (^)(float progress))progressBlock
                callbackBlock:(void (^)(NSURL *trimVideoUrl))callbackBlock
                         fail:(void (^)(NSError *error))failBlock
{
    if (_sdkDisabled) {
        return;
    }
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if(tracks.count == 0){
        failBlock(nil);
        return;
    }
    if(!outputUrl || outputUrl.path.length==0) {
        NSString *outputPath = [self getfilePathStringWithSuffix:@""];
        if(outputPath.length == 0){
            if(failBlock){
                failBlock([NSError errorWithDomain:@"" code:000 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"创建文件夹失败",@"message", nil]]);
            }
            return;
        }
        outputUrl = [NSURL fileURLWithPath:outputPath];
    }
#if 1
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack* videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSError *error;
    AVAssetTrack* assetVideoTrack = [tracks objectAtIndex:0];
    BOOL suc = [videoTrack insertTimeRange:trimTimeRange ofTrack:assetVideoTrack atTime:kCMTimeZero error:&error];
    if(!suc){
        NSLog(@"***video insert error:%@",error);
    }
    if ([asset tracksWithMediaType:AVMediaTypeAudio].count > 0) {//20170323
        AVMutableCompositionTrack* audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        AVAssetTrack* assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        error = nil;
        float diff = CMTimeGetSeconds(CMTimeSubtract(assetVideoTrack.timeRange.duration, assetAudioTrack.timeRange.duration));
        if (diff > 0.1 && diff > CMTimeGetSeconds(trimTimeRange.start)) {//有时因设备性能问题，前面一段会录制不了音频
            CMTime startTime = CMTimeMakeWithSeconds(diff - CMTimeGetSeconds(trimTimeRange.start), 600);
            
            NSString *bgVideoPath = [[NSBundle mainBundle] pathForResource:@"RDVECore.bundle/black" ofType:@"mp4"];
            AVURLAsset *bgVideoAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:bgVideoPath]];
            AVAssetTrack* bgAssetAudioTrack = [[bgVideoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
            
            suc = [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, startTime) ofTrack:bgAssetAudioTrack atTime:kCMTimeZero error:&error];
            if (!suc) {
                NSLog(@"***black audio insert error:%@",error);
            }
            
            trimTimeRange = CMTimeRangeMake(kCMTimeZero, trimTimeRange.duration);
            suc = [audioTrack insertTimeRange:trimTimeRange ofTrack:assetAudioTrack atTime:startTime error:&error];
        }else {
            suc = [audioTrack insertTimeRange:trimTimeRange ofTrack:assetAudioTrack atTime:kCMTimeZero error:&error];
        }
        if(!suc){
            NSLog(@"***audio insert error:%@",error);
        }
    }
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetPassthrough];
#else
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetPassthrough];
    exporter.timeRange = trimTimeRange;
#endif
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.outputURL = outputUrl;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (exporter.status) {
                case AVAssetExportSessionStatusCompleted:
                {
                    if(callbackBlock){
                        callbackBlock(outputUrl);
                    }
                }
                    break;
                case AVAssetExportSessionStatusFailed:
                {
                    if(failBlock){
                        failBlock(exporter.error);
                    }
                }
                    break;
                case AVAssetExportSessionStatusExporting:
                {
                    if (progressBlock) {
                        progressBlock(exporter.progress);
                    }
                }
                    break;
                case AVAssetExportSessionStatusWaiting:
                {
                    
                }
                    break;
                case AVAssetExportSessionStatusCancelled:
                {
                    if(failBlock){
                        failBlock(exporter.error);
                    }
                }
                    break;
                default:
                    break;
            }
        });
    }];
}

//用于单独录制音频时，合并音频和视频
- (void)mergeVideoAndAudio:(NSURL *)videoUrl
                 outputUrl:(NSURL *)outputUrl
             trimTimeRange:(CMTimeRange)trimTimeRange
             progressBlock:(void (^)(float progress))progressBlock
             callbackBlock:(void (^)(NSURL *trimVideoUrl))callbackBlock
                      fail:(void (^)(NSError *error))failBlock
{
    if (_sdkDisabled) {
        return;
    }
    AVURLAsset *asset = [AVURLAsset assetWithURL:videoUrl];
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if(tracks.count == 0){
        failBlock(nil);
        return;
    }
    if(!outputUrl || outputUrl.path.length==0) {
        NSString *outputPath = [self getfilePathStringWithSuffix:@""];
        if(outputPath.length == 0){
            if(failBlock){
                failBlock([NSError errorWithDomain:@"" code:000 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"创建文件夹失败",@"message", nil]]);
            }
            return;
        }
        outputUrl = [NSURL fileURLWithPath:outputPath];
    }
    if (CMTimeCompare(trimTimeRange.duration, asset.duration) == 1) {
        trimTimeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    }else if (CMTimeCompare(CMTimeAdd(trimTimeRange.start, trimTimeRange.duration), asset.duration) == 1) {
        trimTimeRange = CMTimeRangeMake(trimTimeRange.start, CMTimeSubtract(asset.duration, trimTimeRange.start));
    }
    
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack* videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSError *error;
    AVAssetTrack* assetVideoTrack = [tracks objectAtIndex:0];
    NSLog(@"assetVideoTrack duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, assetVideoTrack.timeRange.duration)));
    
    NSString *recordFilePath = [RDRecordHelper getRecordFilePath];
//    NSString *mp3FilePath = [recordFilePath stringByReplacingOccurrencesOfString:@"wav" withString:@"mp3"];
    if (recordFilePath.length > 0) {
        AVURLAsset *audioAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:recordFilePath]];
        if ([audioAsset tracksWithMediaType:AVMediaTypeAudio].count > 0) {//20170323
            AVMutableCompositionTrack* audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            AVAssetTrack* assetAudioTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
            NSLog(@"assetAudioTrack duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, assetAudioTrack.timeRange.duration)));
            NSLog(@">>>>>>>>>>>>>>>video audio diff:%f", CMTimeGetSeconds(CMTimeSubtract(assetVideoTrack.timeRange.duration, assetAudioTrack.timeRange.duration)));
//            if (CMTimeCompare(trimTimeRange.start, kCMTimeZero) == 1) {
//                trimTimeRange = CMTimeRangeMake(CMTimeSubtract(trimTimeRange.start, CMTimeSubtract(assetVideoTrack.timeRange.duration, assetAudioTrack.timeRange.duration)), trimTimeRange.duration);
//                NSLog(@"trimTimeRange start:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, trimTimeRange.start)));
//            }
            error = nil;
            BOOL suc = [audioTrack insertTimeRange:trimTimeRange ofTrack:assetAudioTrack atTime:kCMTimeZero error:&error];
            if(!suc){
                NSLog(@"***audio insert error:%@",error);
            }
        }
    }
    BOOL suc = [videoTrack insertTimeRange:trimTimeRange ofTrack:assetVideoTrack atTime:kCMTimeZero error:&error];
    if(!suc){
        NSLog(@"***video insert error:%@",error);
    }
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetPassthrough];
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.outputURL = outputUrl;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (exporter.status) {
                case AVAssetExportSessionStatusCompleted:
                {
                    unlink([recordFilePath UTF8String]);
                    if(callbackBlock){
                        callbackBlock(outputUrl);
                    }
                }
                    break;
                case AVAssetExportSessionStatusFailed:
                {
                    NSLog(@"error:%@", exporter.error);
                    if(failBlock){
                        failBlock(exporter.error);
                    }
                }
                    break;
                case AVAssetExportSessionStatusExporting:
                {
                    if (progressBlock) {
                        progressBlock(exporter.progress);
                    }
                }
                    break;
                case AVAssetExportSessionStatusWaiting:
                {
                    
                }
                    break;
                case AVAssetExportSessionStatusCancelled:
                {
                    if(failBlock){
                        failBlock(exporter.error);
                    }
                }
                    break;
                default:
                    break;
            }
        });
    }];
}

+(void) returnImageWith:(UIImage *)inputImage Filter:(RDFilter *)obj withCompletionHandler:(void (^)(UIImage *processedImage))block
{
    RDGPUImagePicture* stillImageSource = [[RDGPUImagePicture alloc] initWithImage:inputImage];
    RDGPUImageOutput<RDGPUImageInput> *gpuFilter;
    if (obj.type == kRDFilterType_HeiBai) {
        gpuFilter = [[RDGPUImageGrayscaleFilter alloc] init];
        
    }else if (obj.type == kRDFilterType_SLBP){
        gpuFilter = [[RDRecordGPUImageThresholdedNonMaximumSuppressionFilter alloc] initWithPackedColorspace:YES];
        ((RDRecordGPUImageThresholdedNonMaximumSuppressionFilter*)obj).threshold = 0.01;
    }
    
    else if (obj.type == kRDFilterType_Sketch){
        
        gpuFilter = [[RDRecordGPUImageSketchFilter alloc] init];
        
    }else if (obj.type == kRDFilterType_DistortingMirror){
        
        gpuFilter = [[RDRecordGPUImageStretchDistortionFilter alloc] init];
        
    }else if (obj.type == kRDFilterType_LookUp){
        gpuFilter = [[RDLookupFilter alloc] initWithImagePath:obj.filterPath intensity:obj.intensity];
    }
    else{
        gpuFilter =[[RDGPUImageToneCurveFilter alloc] initWithACVData:[NSData dataWithContentsOfFile:obj.filterPath]];
    }
    
    [stillImageSource addTarget:gpuFilter];
    [gpuFilter useNextFrameForImageCapture];
    
    [stillImageSource processImageWithCompletionHandler:^{
        
        UIImage *currentFilteredVideoFrame = [gpuFilter imageFromCurrentFramebuffer];
                
        block(currentFilteredVideoFrame);
    }];
}

- (NSString *)getfilePathStringWithSuffix:(NSString *)suffix
{
    if (!_tempVideoFolderPath || _tempVideoFolderPath.length == 0) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        _tempVideoFolderPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"videos"];
    }
    if(![[NSFileManager defaultManager] fileExistsAtPath:_tempVideoFolderPath]){
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:_tempVideoFolderPath withIntermediateDirectories:YES attributes:nil error:&error];
        if(error){
            NSLog(@"error:%@",error);
            return nil;
        }
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmssSSS";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    NSString *fileName = [[_tempVideoFolderPath stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:[NSString stringWithFormat:@"%@.mp4", suffix]];
    
    return fileName;
}

@end
