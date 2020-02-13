//
//  RDVECore.m
//  RDVECore
//
//  Created by 周晓林 on 2017/5/8.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//
#import "lame.h"
#import "RDVECore.h"
#import "RDVideoEditor.h"
#import "RDVideoRenderer.h"
#import "RDGPUImageView.h"
#import "RDGPUImageMovie.h"
#import "RDGPUImageMovieComposition.h"
#import "RDGPUImageMovieWriter.h"
#import "RDGPUImageDYFilter.h"
#import "RDGPUImageFilterPipeline.h"
#import "RDGPUImageHeartbeatFilter.h"
#import "RDGPUImageDazzledFilter.h"
#import "RDGPUImageSoulstuffFilter.h"
#import "RDGPUImageSpotlightsFilter.h"
#import "RDGPUimageEmptyFilter.h"
#import "RDCameraManager.h"
#import "RDGPUImageToneCurveFilter.h"
#import "RDRecordHelper.h"
#import "PPMovieWriter.h"
#import "PPMovie.h"
#import "RDGPUImageAlphaBlendFilter.h"
#import "RDGPUImageUIElement.h"
#import "RDGPUImageCropFilter.h"
#import "RDGaussianBlurFilter.h"
#import "RDGPUImagePicture.h"
#import "RDColorInvertFilter.h"
#import "RDStretchDistortionFilter.h"
#import "RDGPUImageToneCurveFilter.h"
#import "RDGPUImageGrayscaleFilter.h"
#import "RDRecordGPUImageSketchFilter.h"
#import "RDRecordGPUImageStretchDistortionFilter.h"
#import "RDRecordGPUImageThresholdedNonMaximumSuppressionFilter.h"
#import "RDMVFileEditor.h"
#import "RDLookupFilter.h"
#import "RDGPUImageScreenBlendFilter.h"
#import "RDGPUImageChromaKeyBlendFilter.h"
#import "RDGPUImageHardLightBlendFilter.h"
#import "RDMVFilter.h"
#import "RDNTFilter.h"
#import "RDUFilterGroup.h"
#import "RDCaptionLayer.h"
#import "RDLottie.h"
#import "RDGPUImageOutput.h"
#import "RDMosaicFilter.h"
#import <Photos/Photos.h>
#import "RDGPUImageGaussianBlurDYFilter.h"
#import "RDPrivateObject.h"
#include <map>
#import "RDQuadsRender.h"
#import "RDGPUImageDewatermark.h"
#import "RDAEVideoImageInfo.h"
#include "RDGifEncoderImp.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define kAnimationRepeatFolder @"others"

typedef void (^ ExportProgressBlock)(float progress);
typedef void (^ ExportSuccessBlock)();
typedef void (^ ExportFailBlock)(NSError *error);
typedef int (*GetInterpolationHandlerFn) (float* percent);

@interface RDAEVideoComposition : NSObject

@property (nonatomic,strong) NSURL                      *url;
@property (nonatomic,assign) UIImageOrientation         imageOrientation;
@property (nonatomic,assign) CMTimeRange                timeRange;
@property (nonatomic,strong) AVAssetReader              *reverseReader;
@property (nonatomic,assign) Float64                    oldSampleFrameTime;
@property (nonatomic,strong) AVAssetReaderTrackOutput   *readerOutput;
@property (nonatomic,strong) AVMutableComposition       *videoURLComposition;
@property (nonatomic,assign) BOOL                       videoCopyNextSampleBufferFinish;

@end
@implementation RDAEVideoComposition
@end

@interface RDVECore()<RDRendererPlayerDelegate, RDLOTChangeImageDelegate>
{
    
    BOOL _cancelGetImage;
    PPMovieWriter* writer;
    PPMovie* exportMovie;
    CMTime startTime;
    CMTime endTime;
    CMTime cTime;
    NSMutableArray<FilterAttribute*>* filterAttributeArray;
    RDVideoRealTimeFilterType currentFilterType;
    BOOL    _cancelExport;//取消导出倒序
    ///滤镜层  应当固定滤镜层  输出时不要实时切换滤镜
    RDGPUImageDYFilter* dyFilter;
    RDGPUImageOutput<RDGPUImageInput>* gFilter; // 视频全局滤镜
    NSMutableArray <RDFilter *>* gFilters; // 滤镜
    NSInteger gFilterIndex;
    
    NSMutableArray<RDGPUImageOutput<RDGPUImageInput> *>* globalFilters;
    
    //倒序
    AVAssetWriter   *_assetWriter;
    AVAssetReader   *_reverseReader;
    AVAssetWriterInput *_writerInput;
    Float64          _oldSampleFrameTime;
    AVAssetReaderTrackOutput*_readerOutput;
    AVAssetWriterInputPixelBufferAdaptor *_pixelBufferAdaptor;
    void (^_progressReverseBlock)(NSNumber *prencent);
    void (^_cancelReverseBlock)();
    float _lastReverseProgress;
    float _lastReverseWriteProgress;
//    RDScene* originScene;
    NSMutableArray *originScenes;
    CGSize originVideoSize;
    int originFps;
    AVAssetExportSession* exporter;
    NSTimer *_exportTimer;
    void (^_progressTrimBlock)(NSNumber *prencent);
    
    BOOL                      isExporting;
    NSURL                   * exporterURL;
    CGSize                    exportSize;
    float                     exportBitrate;
    int                       exportAudioBitRate;
    int                       exportAudioChannelNumbers;
    NSArray<AVMetadataItem*>* exportMetadata;
    ExportProgressBlock       exportProgressBlock;
    ExportSuccessBlock        exportSuccessBlock;
    ExportFailBlock           exportFailBlock;
    float                     lastProgress;
    BOOL                      isCancelExporting;
    RDGPUImageAlphaBlendFilter *_blendWaterFilter;
    RDGPUImageUIElement* uiElementWaterInput;
    
    CALayer* suplayer;
    CALayer* subtitleEffectlayer;
    CALayer* customDrawLayer;
    RDGPUImageAlphaBlendFilter *newAlphaBlendFilter;
    RDGPUImageUIElement*newUIElement;
    RDGaussianBlurFilter* gaosiFilter;
    RDMosaicFilter *mosaicFilter;
    RDGPUImageDewatermark *dewatermarkFilter;
    RDGPUImageGaussianBlurDYFilter *blurFilter;
    RDGPUImageAlphaBlendFilter *endLogoAlphaBlendFilter;
    RDGPUImageUIElement*endLogoUIElement;
    RDQuadsRender *quadsRender;//非矩形滤镜
    
    NSMutableArray<RDVideoRenderer*> *mvRendererArray;
    NSMutableArray<RDGPUImageFilter*> *normalShaderArray;
    NSMutableArray<RDGPUImageFilter*> *mvShaderArray;
    NSMutableArray<RDGPUImageMovie*> *mvMovieArray;
    
    NSMutableArray<RDEditorObject*> *mvEditorArray;
    
    NSMutableArray<VVMovieEffect*>* movieEffects;
    NSMutableArray<PPMovie*> *exportMovieArray;
    NSMutableArray<RDGPUImageFilter*> *exportMVFilterArray;
    
    
    RDGPUImageFilter* bridgeFilter;
    RDGPUImageFilter* bridgeFilter2;
    RDGPUImageFilter* bridgeFilter3;
    NSInteger globalFilterIndex;
    
    void (^ exportCancelBlock)();
    NSMutableArray      *mvArray;
    
    
    float _videoDuration;
    NSInteger renderCanPlay;
    NSMutableArray *renders;
    
    NSMutableArray  *captionLayerArray;
    CALayer         *currentLayer;
    std::map<int,GetInterpolationHandlerFn> m_mapInterpolationHandles;
    
    
    NSString* m_appkey;
    NSString* m_appsecret;
    NSString* m_licenceKey;
//    NSLock* lock;
    NSString                        *rdJsonPath;
    NSDictionary                    *rdJsonDic;
    RDJsonAnimation                 *rdJsonAnimation;
    RDLOTAnimationView              *animationView;
    CALayer                         *jsonMVEffectLayer;
    NSMutableArray <RDJsonAnimation *> *jsonMVEffects;
    NSMutableArray <RDLOTAnimationView *> *jsonMVEffectViews;
    NSMutableArray <RDLOTAnimatedSourceInfo*>*animationImageArray;
    NSMutableArray <RDLOTAnimatedSourceInfo*>*notReplaceableImageArray;
    NSMutableArray <RDLOTAnimatedSourceInfo*>*textImageArray;
    NSMutableArray <RDLOTAnimatedSourceInfo*>*variableImageArray;
    NSMutableArray                  *animationImageArray_prev;
    NSMutableArray                  *animationTextImageArray;
    NSString                        *imageFolder;
    int                              animationPlayCount;//AE播放次数，默认为1
    BOOL                            isRefreshAnimationImages;   //刷新动画图片
    BOOL                            isClipAnimationImages;      //裁切动画图片
    NSMutableArray<RDAEVideoImageInfo *> *animationVideoArray;       //视频截图要替换的动画图片
    NSMutableArray<RDAEVideoImageInfo *> *animationGifArray;       //Gif要替换的动画图片
    float                           exportTime;
    NSString                        *prevAnimationImageName;
    CMTime                          prevBufferTime;
    CMTime                          currentBufferTime;
    UIImage                         *prevAnimationImage;
    NSMutableArray<RDAEVideoComposition *> *compositionArray;
    BOOL                            getScreenshotFinish;
    NSMutableArray                  *animationLayerArray;
    CGSize                          animationImageSize;
    CGSize                          animationImageSize_prev;
    BOOL                            mvUseSourceBuffer;
    RDGIFHANDLE                     gifHandle;
    NSTimer                         *exportGifTimer;
    void (^exportGifProgressHandler)(float progress);
    UIColor                         *backGroundColor;
    
    
}

@property (nonatomic, assign) BOOL sdkDisabled; //sdk是否禁用
@property (nonatomic,strong) RDVideoEditor* editor;
@property (nonatomic,strong) RDVideoRenderer* renderer;
@property (nonatomic,strong) RDGPUImageView* preview;
@property (nonatomic,strong) RDGPUImageView* preview1;

@property (nonatomic,strong) RDGPUImageMovie* movie;
@property (nonatomic,strong) RDGPUImageFilterPipeline* filterPipeline;

@property (nonatomic,assign) RDVideoRealTimeFilterType realTimeFilterType;

@property (nonatomic,strong) RDGPUImageFilterPipeline* mvPipeline;

@property (nonatomic , strong) CALayer * doodleLayer;
@property (nonatomic , strong) NSMutableArray <RDDoodleLayer *> * doodleLayers;


@property (nonatomic , strong) CALayer * watermarkLayer;
@property (nonatomic , strong) CATextLayer * watermarkTextLayer;
@property (nonatomic , strong) CALayer * endLogomarkLayer;
@property (nonatomic, assign) float     showDuration;
@property (nonatomic, assign) float     fadeDuration;
@property (nonatomic, assign) float     maxVideoDuration;//视频导出的最大时长

/** 实时改变单个媒体的音量
 */
- (void) setVVAssetVolume:(float)volume asset:(VVAsset *) asset;

/** 实时改变配乐音量
 */
- (void) setMusicVolume:(float) volume music:(RDMusic *) music;

/** 水印，支持视频/图片
 *  可用于片尾水印，与watermarkArray互不影响
 */
@property (nonatomic, strong) RDWatermark *endlogoWatermark;

@end

@implementation RDVECore


- (id)copyWithZone:(NSZone *)zone{
    RDVECore *copy = [[[self class] allocWithZone:zone] init];
    copy.shouldRepeat = _shouldRepeat;
    copy.frame = _frame;
    copy.isRealTime = _isRealTime;
    copy.delegate = _delegate;
    copy.editor = _editor;
    copy.renderer = _renderer;
    copy.preview = _preview;
    copy.movie = _movie;
    copy.mvPipeline = _mvPipeline;
    copy.filterPipeline = _filterPipeline;
    copy.realTimeFilterType = _realTimeFilterType;
    //copy.blendView = _blendView;
    //copy.watermarkView = _watermarkView;
    
    return copy;
    
}


- (id)mutableCopyWithZone:(NSZone *)zone{
    RDVECore *copy = [[[self class] allocWithZone:zone] init];
    copy.shouldRepeat = _shouldRepeat;
    copy.frame = _frame;
    copy.isRealTime = _isRealTime;
    copy.delegate = _delegate;
    copy.editor = _editor;
    copy.renderer = _renderer;
    copy.preview = _preview;
    copy.movie = _movie;
    copy.mvPipeline = _mvPipeline;
    copy.filterPipeline = _filterPipeline;
    copy.realTimeFilterType = _realTimeFilterType;
    //copy.blendView = _blendView;
    //copy.watermarkView = _watermarkView;
    
    return copy;
}

- (void)tapgesture:(UITapGestureRecognizer *)gesture{
    NSLog(@"tapgesture");
    if([_delegate respondsToSelector:@selector(tapPlayerView)]){
        [_delegate tapPlayerView];
    }
}

- (void)setFrame:(CGRect)frame {
    _frame = frame;
    _preview.frame = frame;
//    _preview.mybounds = CGRectMake(0, 0, _frame.size.width, _frame.size.height);

}

- (id)init{
    return nil;
}

int RDAccelerateDecelerateInterpolator(float* percent)
{
    float fInput = *percent;
    *percent = (float) (cos((fInput + 1.0f) * M_PI) / 2.0f) + 0.5f;
    return 1;
}

int RDAccelerateInterpolator(float* percent)
{
    float fInput = *percent;
#define FACTOR  1.0f
#define DOUBLE_FACTOR  FACTOR*2
    if (FACTOR == 1.0f)
    {
        *percent = fInput * fInput;
    }
    else
    {
        *percent = (float) pow(fInput, DOUBLE_FACTOR);
    }
#undef FACTOR
#undef DOUBLE_FACTOR
    return 1;
}

int RDDecelerateInterpolator(float* percent)
{
    float fInput = *percent;
    //    if (mFactor == 1.0f) {
    *percent = (float) (1.0f - (1.0f - fInput) * (1.0f - fInput));
    //            } else {
    //                result = (float)(1.0f - pow((1.0f - input), 2 * mFactor));
    //            }
    return 1;
}

int RDCycleInterpolator(float* percent)
{
    float fInput = *percent;
    *percent = (float) (sin(2 * 0.5f * M_PI * fInput));
    return 1;
}
int RDLinearInterpolator(float* percent){
    return 1;
}

- (void)setCaptions:(NSMutableArray<RDCaption *> *)captions{
    _captions = captions;
    if (!captionLayerArray) {
        captionLayerArray = [NSMutableArray array];
    }else{
        [captionLayerArray makeObjectsPerformSelector:@selector(clean)];
        [captionLayerArray removeAllObjects];
    }
    
    for (RDCaption* ppCaption in captions) {
        RDCaptionLayer* caption = [[RDCaptionLayer alloc] initWithCaption:ppCaption videoSize:_editor.videoSize];
        [captionLayerArray addObject:caption];
        for (RDCaptionCustomAnimate* position in ppCaption.animate) {
            if (position.path) {
                [position generate];
            }
        }
    }
}

- (instancetype) initWithAPPKey:(NSString *)appkey
                      APPSecret:(NSString *)appsecret
                      videoSize:(CGSize)size
                            fps:(int)fps
                     resultFail:(void (^)(NSError *error))resultFailBlock
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
        m_appkey = appkey;
        m_appsecret = appsecret;
        __weak typeof(self) weakSelf = self;
        [RDRecordHelper checkPermissions:appkey
                               appsecret:appsecret
                              LicenceKey:nil
                                 appType:1
                                 success:^{
                                     _sdkDisabled = NO;
                                 } resultFailBlock:^(NSError *error) {
                                     _sdkDisabled = YES;
                                     _shouldRepeat = NO;
                                     if (_isPlaying) {
                                         [weakSelf pause];
                                     }
                                     if(initFailureBlock){
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             initFailureBlock(error);
                                         });
                                     }
                                 }];
        [self setupWithVideoSize:size fps:fps];
    }
    return self;
}

- (instancetype)initWithAPPKey:(NSString *)appkey
                     APPSecret:(NSString *)appsecret
                    LicenceKey:(NSString *)licenceKey
                     videoSize:(CGSize)size
                           fps:(int)fps
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
        m_appkey = appkey;
        m_appsecret = appsecret;
        m_licenceKey = licenceKey;
        __weak typeof(self) weakSelf = self;
        [RDRecordHelper checkPermissions:appkey
                               appsecret:appsecret
                              LicenceKey:licenceKey
                                 appType:1
                                 success:^{
                                     _sdkDisabled = NO;
                                 } resultFailBlock:^(NSError *error) {
                                     _sdkDisabled = YES;
                                     _shouldRepeat = NO;
                                     if (_isPlaying) {
                                         [weakSelf pause];
                                     }
                                     if(initFailureBlock){
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             initFailureBlock(error);
                                         });
                                     }
                                 }];
        [self setupWithVideoSize:size fps:fps];
    }
    return self;
}

- (int)getSDKVersion {
    //120:新增去水印、自定义转场、解密转场及特效脚本
    //124:新增转场特效：可控制动画循环周期时长cycleDuration
    //125:支持竖排字幕
    //126:贴纸支持apng
    //127:媒体支持gif
    //128:支持定格特效    20190828
    //129:更新贴纸配置文件规则，添加字段sizeW控制显示幅度    20190918
    //130:AE模板支持高斯和色调(颜色映射) 20190927
    //131:修复AE模板(酷炫卡点14)颜色映射的bug 20191018
    //132:AE配置文件修改：(1)ver:2 (2)不可替换图片命名不再为background，Replaceable开头以外的都为不可替换
    //133:AE模板支持边角定位、贝塞尔    20191114
    //134:AE模板支持径向模糊、定向模糊   20191202
    //135:修复AE模板(模糊卡点)模糊过渡生硬的问题 //20191213
    return [RDVECore getSDKVersion];
}
+ (int)getSDKVersion {
    return 135;
}

- (void)setupWithVideoSize:(CGSize)size fps:(int)fps {
#if 0
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
#else   //20190729 wuxiaoxia 处于UIApplicationWillResignActiveNotification这个状态(如下拉通知栏、上拉快捷栏、双击home键的情况)还是可以导出，只有真正切到后台时才停止导出
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
#endif
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMVLottieTime:) name:@"refreshMVLottieTime" object:nil];
    
//    lock = [[NSLock alloc] init];
    
    m_mapInterpolationHandles[AnimationInterpolationTypeLinear] = &RDLinearInterpolator;
    m_mapInterpolationHandles[AnimationInterpolationTypeAccelerateDecelerate] = &RDAccelerateDecelerateInterpolator;
    m_mapInterpolationHandles[AnimationInterpolationTypeAccelerate] = &RDAccelerateInterpolator;
    m_mapInterpolationHandles[AnimationInterpolationTypeDecelerate] = &RDDecelerateInterpolator;
    m_mapInterpolationHandles[AnimationInterpolationTypeCycle] = &RDCycleInterpolator;
    
//    mvMovieArray = [NSMutableArray array];
//    mvRendererArray = [NSMutableArray array];
//    mvShaderArray = [NSMutableArray array];
//    mvEditorArray = [NSMutableArray array];
    
    exportMovieArray = [NSMutableArray array];
//    exportMVFilterArray = [NSMutableArray array];
    filterAttributeArray = [NSMutableArray array];
    backGroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    globalFilterIndex = -1;
    
    currentFilterType = RDVideoRealTimeFilterTypeNone;
    startTime = kCMTimeZero;
    endTime = kCMTimeZero;
    _playRate = 1.0;
    
    _animationFolderPath = [NSTemporaryDirectory() stringByAppendingString:@"RDMVAnimate/"];
    
    size = [self correctSize:size];
    originVideoSize = size;
    originFps = fps;
    _editor = [[RDVideoEditor alloc] init];
    _editor.fps = fps;
    if (fps > 24 && [RDRecordHelper isLowDevice]) {
        _editor.fps = 24;//fps;//20190126 节省内存，导出时再设置为originFps
    }
    _editor.videoSize = size;
    
    _renderer = [[RDVideoRenderer alloc] init];
    _movie = [[RDGPUImageMovie alloc] initWithVideoRenderer:_renderer];
    
    _preview = [[RDGPUImageView alloc] init];
    _preview.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapgesture:)];
    [_preview addGestureRecognizer:tap];
    
    _renderer.editor = _editor;
    _renderer.playDelegate = self;
    _renderer.isMain = YES;
    
    if(!suplayer){
        suplayer = [CALayer layer];
        suplayer.backgroundColor = [UIColor clearColor].CGColor;
        suplayer.frame = CGRectMake(0, 0, size.width, size.height);
    }
    customDrawLayer = [CALayer layer];
    customDrawLayer.backgroundColor = [UIColor clearColor].CGColor;
    customDrawLayer.frame = suplayer.bounds;
    [suplayer addSublayer:customDrawLayer];
    
    if(!subtitleEffectlayer){
        subtitleEffectlayer = [CALayer layer];
        subtitleEffectlayer.backgroundColor = [UIColor clearColor].CGColor;
        subtitleEffectlayer.frame = CGRectMake(0, 0, size.width, size.height);
    }
    //字幕、特效
    [suplayer addSublayer:subtitleEffectlayer];
    
    [self refreshFilters];
}

- (CGSize)correctSize:(CGSize)size {
    float w,h,w1,h1,w2,h2;
    w = floorf(size.width);
    h = floorf(size.height);
    w1 = w + fmod(w, 4);
    h1 = h + fmod(h, 4);
    
    CGSize size1 = CGSizeMake(w1, h1);
    w2 = w - fmod(w, 4);
    h2 = h - fmod(h, 4);
    
    CGSize size2 = CGSizeMake(w2, h2);
    
    //20190304 选择最接近原始比例的，不然会有黑边
    float ratio = size.width / size.height;
    float diffRatio1 = size1.width / size1.height - ratio;
    float diffRatio2 = size2.width / size2.height - ratio;
    if (fabsf(diffRatio1) <= fabsf(diffRatio2)) {
//        NSLog(@"111%s%@1:%@2:%@", __func__, NSStringFromCGSize(size), NSStringFromCGSize(size1), NSStringFromCGSize(size2));
        return size1;
    }
//    NSLog(@"222%s%@1:%@2:%@", __func__, NSStringFromCGSize(size), NSStringFromCGSize(size1), NSStringFromCGSize(size2));
    return size2;
}

- (void)refreshFilters {
    [_filterPipeline removeAllFilters];
    _filterPipeline = nil;
    [_mvPipeline removeAllFilters];
    _mvPipeline = nil;
    
    [_movie removeAllTargets];
    [mosaicFilter removeAllTargets];
    [dewatermarkFilter removeAllTargets];
    [dyFilter removeAllTargets];
    [blurFilter removeAllTargets];
    [newAlphaBlendFilter removeAllTargets];
    [gFilter removeAllTargets];
    [quadsRender removeAllTargets];
    [gaosiFilter removeAllTargets];
    [endLogoAlphaBlendFilter removeAllTargets];
    [bridgeFilter removeAllTargets];
    [bridgeFilter2 removeAllTargets];
    [bridgeFilter3 removeAllTargets];
    
    newAlphaBlendFilter = [[RDGPUImageAlphaBlendFilter alloc] init];
    newAlphaBlendFilter.mix = 1.0;
    
    newUIElement = [[RDGPUImageUIElement alloc] initWithLayer:suplayer];
    [newUIElement addTarget:newAlphaBlendFilter atTextureLocation:1];
    
    mosaicFilter = [[RDMosaicFilter alloc] initWithImagePath:nil];
    if (_mosaics) {
        mosaicFilter.mosaics = _mosaics;
    }
    dewatermarkFilter = [[RDGPUImageDewatermark alloc] init];
    if (_dewatermarks) {
        dewatermarkFilter.watermark = _dewatermarks;
    }
    blurFilter = [[RDGPUImageGaussianBlurDYFilter alloc] init];
    bridgeFilter = [[RDGPUImageFilter alloc] init];
//    dyFilter = [[RDGPUImageDYFilter alloc] init];
    gFilter = [[RDGPUImageFilter alloc] init];
    quadsRender = [[RDQuadsRender alloc] init];
    if (_nonRectangleCaptions) {
        quadsRender.captionLight = _nonRectangleCaptions;
    }
    if (isExporting) {
#if 1
        NSMutableArray *filterArray = [NSMutableArray array];
        gFilterIndex = -1;
        if (_doodleLayers.count > 0
            || _captions.count > 0
            || _endLogomarkLayer
            || _mosaics.count > 0
            || jsonMVEffectLayer
            || (animationView && movieEffects.count == 0))
        {
            [filterArray addObject:mosaicFilter];
        }
        if (_dewatermarks.count > 0) {
            [filterArray addObject:dewatermarkFilter];
        }
        __block BOOL isHasBlur = NO;
        if (!animationView) {
            [originScenes enumerateObjectsUsingBlock:^(RDScene *  _Nonnull scene, NSUInteger idx1, BOOL * _Nonnull stop1) {
                [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx2, BOOL * _Nonnull stop2) {
                    for (int j = 0; j<asset.animate.count; j++) {
                        VVAssetAnimatePosition* from = asset.animate[j];
                        VVAssetAnimatePosition* to;
                        if (j == asset.animate.count - 1) {
                            to = asset.animate[j];
                        }else {
                            to = asset.animate[j+1];
                        }
                        if (from.blur && to.blur) {
                            isHasBlur = YES;
                            break;
                            *stop2 = YES;
                            *stop1 = YES;
                        }
                    }
                }];
            }];
        }
        if (isHasBlur || _blurs.count > 0) {
            [filterArray addObject:blurFilter];
        }
        if (jsonMVEffectLayer
            || (animationView && movieEffects.count == 0))
       {
           [filterArray addObject:newAlphaBlendFilter];
       }
        if (globalFilterIndex > 0) {
            [filterArray addObject:gFilter];
            gFilterIndex = filterArray.count - 1;
        }
        if (_nonRectangleCaptions.count > 0) {
            [filterArray addObject:quadsRender];
        }
        if (!animationView
            && (_doodleLayers.count > 0
                || _captions.count > 0
                || _endLogomarkLayer))
        {
            [filterArray addObject:newAlphaBlendFilter];
        }
        if (_endLogomarkLayer) {
            endLogoAlphaBlendFilter = [[RDGPUImageAlphaBlendFilter alloc] init];
            endLogoAlphaBlendFilter.mix = 1.0;
            
            endLogoUIElement = [[RDGPUImageUIElement alloc] initWithLayer:_endLogomarkLayer];
            [endLogoUIElement addTarget:endLogoAlphaBlendFilter atTextureLocation:1];
            
            gaosiFilter = [[RDGaussianBlurFilter alloc] init];
            gaosiFilter.blurPasses=0.8f;
            gaosiFilter.blurRadiusInPixels=0.0f;
            
            [filterArray addObject:gaosiFilter];
            [filterArray addObject:endLogoAlphaBlendFilter];
        }
#else
        if (_endLogomarkLayer) {
            endLogoAlphaBlendFilter = [[RDGPUImageAlphaBlendFilter alloc] init];
            endLogoAlphaBlendFilter.mix = 1.0;
            
            endLogoUIElement = [[RDGPUImageUIElement alloc] initWithLayer:_endLogomarkLayer];
            [endLogoUIElement addTarget:endLogoAlphaBlendFilter atTextureLocation:1];
            
            gaosiFilter = [[RDGaussianBlurFilter alloc] init];
            gaosiFilter.blurPasses=0.8f;
            gaosiFilter.blurRadiusInPixels=0.0f;
            
            [filterArray addObject:gaosiFilter];
            [filterArray addObject:endLogoAlphaBlendFilter];
        }
        if (rdJsonAnimation) {
            if (_endLogomarkLayer) {
                filterArray = @[mosaicFilter,dewatermarkFilter,blurFilter,newAlphaBlendFilter,gFilter,gaosiFilter,endLogoAlphaBlendFilter];
            }else {
                filterArray = @[mosaicFilter,dewatermarkFilter,blurFilter,newAlphaBlendFilter,gFilter];
            }
            gFilterIndex = 4;
        }else {
            if (_endLogomarkLayer) {
                filterArray = @[mosaicFilter,dewatermarkFilter,blurFilter,gFilter,quadsRender,newAlphaBlendFilter,gaosiFilter,endLogoAlphaBlendFilter];
            }else {
                filterArray = @[mosaicFilter,dewatermarkFilter,blurFilter,gFilter,quadsRender,newAlphaBlendFilter];
            }
            gFilterIndex = 3;
        }
#endif
        self.filterPipeline = [[RDGPUImageFilterPipeline alloc] initWithOrderedFilters:filterArray input:exportMovie output:writer];
    }else {
        NSArray *filterArray;
        if (rdJsonAnimation) {
            filterArray = @[mosaicFilter,dewatermarkFilter,blurFilter,newAlphaBlendFilter,gFilter];
            gFilterIndex = 4;
        }else {
            filterArray = @[mosaicFilter,dewatermarkFilter,blurFilter,gFilter,quadsRender,newAlphaBlendFilter];
            gFilterIndex = 3;
        }
        self.filterPipeline = [[RDGPUImageFilterPipeline alloc] initWithOrderedFilters:filterArray input:_movie output:bridgeFilter];
        [bridgeFilter addTarget:_preview];
    }
    __weak typeof(self) weakSelf = self;
    mosaicFilter.frameProcessingCompletionBlock = ^(RDGPUImageOutput *output, CMTime currentTime) {
        [weakSelf filterRealTimeEffect:currentTime];
        [weakSelf uiElementUpdate:currentTime];
    };
    if (globalFilterIndex > 0) {
        [self setGlobalFilter:globalFilterIndex];
    }
}
- (void)setAeJsonMVEffects:(NSMutableArray <RDJsonAnimation *> *)effects{
    jsonMVEffects = effects;
    
    [[RDLOTAnimationCache sharedCache] clearCache];
    
    if(jsonMVEffectLayer){
        [jsonMVEffectLayer removeFromSuperlayer];
        
    }
    if(effects.count==0 || !effects){
        jsonMVEffectLayer = nil;
        [jsonMVEffectViews removeAllObjects];
        jsonMVEffectViews = nil;
        return;
    }
    jsonMVEffectLayer = [[CALayer alloc] init];
    jsonMVEffectLayer.backgroundColor = [UIColor clearColor].CGColor;//[[UIColor redColor] colorWithAlphaComponent:0.5].CGColor;//
    jsonMVEffectLayer.frame = CGRectMake(0, 10, suplayer.bounds.size.width + 10, suplayer.bounds.size.height + 10);//
    jsonMVEffectLayer.position = CGPointMake(suplayer.bounds.size.width/2.0, suplayer.bounds.size.height/2.0);
    jsonMVEffectLayer.masksToBounds = YES;
    jsonMVEffectLayer.backgroundColor = [UIColor clearColor].CGColor;
    [suplayer insertSublayer:jsonMVEffectLayer atIndex:0];
    //[suplayer addSublayer:jsonMVEffectLayer];
    jsonMVEffectViews = [NSMutableArray array];
    
    if(jsonMVEffectViews){
        [jsonMVEffectViews enumerateObjectsUsingBlock:^(RDLOTAnimationView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj.layer removeFromSuperlayer];
        }];
    }
    //[jsonMVEffectLayer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    __block float duration = 0;
    float wid = MAX(originVideoSize.width, originVideoSize.height) + 10;
    [effects enumerateObjectsUsingBlock:^(RDJsonAnimation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"path:%@",obj.jsonPath);
        RDLOTAnimationView *jsonMVEffectView = nil;
        if(obj.name.length>0){
            jsonMVEffectView = [RDLOTAnimationView animationNamed:obj.name];
        }else{
            jsonMVEffectView = [RDLOTAnimationView animationWithFilePath:obj.jsonPath];
        }
        if(obj.isJson1V1){
            jsonMVEffectView.frame = CGRectMake((self->jsonMVEffectLayer.frame.size.width - wid)/2.0, (self->jsonMVEffectLayer.frame.size.height - wid)/2.0, wid, wid);
            jsonMVEffectView.layer.frame = CGRectMake((self->jsonMVEffectLayer.frame.size.width - wid)/2.0, (self->jsonMVEffectLayer.frame.size.height - wid)/2.0, wid, wid);
            jsonMVEffectView.layer.position = CGPointMake(CGRectGetWidth(suplayer.bounds)/2.0, CGRectGetHeight(suplayer.bounds)/2.0);
        }else{
            jsonMVEffectView.frame = self->jsonMVEffectLayer.bounds;
            jsonMVEffectView.layer.frame = self->jsonMVEffectLayer.bounds;
            jsonMVEffectView.layer.position = CGPointMake(CGRectGetWidth(jsonMVEffectView.bounds)/2.0, CGRectGetHeight(jsonMVEffectView.bounds)/2.0);
        }
        jsonMVEffectView.contentMode = UIViewContentModeScaleAspectFit;
        jsonMVEffectView.layer.opacity = 0;
        jsonMVEffectView.isRepeat = obj.isRepeat;
        jsonMVEffectView.ispiantou = obj.ispiantou;
        jsonMVEffectView.ispianwei = obj.ispianwei;
//        jsonMVEffectView.delegate = self;
        jsonMVEffectView.spanValue = (obj.ispiantou ? -0.1 : 2);//arc4random()%1+1.5;
        jsonMVEffectView.startTime += duration;
        duration +=(jsonMVEffectView.animationDuration + jsonMVEffectView.spanValue);
        
        [self->jsonMVEffectViews addObject:jsonMVEffectView];
        [self->jsonMVEffectLayer addSublayer:jsonMVEffectView.layer];
//        [jsonMVEffectLayer addSubview:jsonMVEffectView.layer];
    }];
}

- (NSArray<RDAESourceInfo *> *)getAESourceInfoWithJosnPath:(NSString *)jsonPath {
    if ([jsonPath isEqualToString:rdJsonPath] && _aeSourceInfo.count > 0) {
        return _aeSourceInfo;
    }
    rdJsonPath = jsonPath;
    NSData *jsonData = [[NSData alloc] initWithContentsOfFile:jsonPath];
    NSMutableDictionary *configDic = [RDRecordHelper parseDataFromJSONData:jsonData];
    jsonData = nil;
    return [self getAESourceInfoWithJosnDic:configDic];
}

- (NSArray<RDAESourceInfo *> *)getAESourceInfoWithJosnDic:(NSDictionary *)jsonDic {
    BOOL isSameAnimation = NO;
    if (rdJsonDic && jsonDic) {
        NSData *jsonData_new = [NSJSONSerialization dataWithJSONObject:jsonDic options:0 error:0];
        NSString *dataStr_new = [[NSString alloc] initWithData:jsonData_new encoding:NSUTF8StringEncoding];
        
        NSData *jsonData_old = [NSJSONSerialization dataWithJSONObject:rdJsonDic options:0 error:0];
        NSString *dataStr_old = [[NSString alloc] initWithData:jsonData_old encoding:NSUTF8StringEncoding];
        if ([dataStr_new isEqual:dataStr_old]) {
            isSameAnimation = YES;
        }
    }
    if (isSameAnimation) {
        return _aeSourceInfo;
    }
    animationView.delegate = nil;
    [animationView.layer removeFromSuperlayer];
    animationView = nil;
    rdJsonDic = jsonDic;
    if (_aeSourceInfo) {
        [_aeSourceInfo removeAllObjects];
    }else {
        _aeSourceInfo = [NSMutableArray array];
    }
    float version = [jsonDic[@"ver"] floatValue];
    animationView = [RDLOTAnimationView animationFromJSON:jsonDic rootDirectory:_animationFolderPath version:version];
    animationView.frame = suplayer.bounds;
    animationView.contentMode = UIViewContentModeScaleAspectFit;
    [animationView.imageItems enumerateObjectsUsingBlock:^(RDLOTAnimatedSourceInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.name.length > 0 && ![obj.typeName hasPrefix:@"background"]) {
            RDAESourceInfo *info = [RDAESourceInfo new];
            info.name = obj.typeName;
            if (version <= 1.0) {
                if ([obj.typeName hasPrefix:@"background"]) {
                    info.type = RDAESourceType_Irreplaceable;
                }else if ([obj.typeName hasPrefix:@"ReplaceableText"]) {
                    info.type = RDAESourceType_ReplaceableText;
                }else if ([obj.typeName hasPrefix:@"ReplaceableVideoOrPic"]) {
                    info.type = RDAESourceType_ReplaceableVideoOrPic;
                }else {
                    info.type = RDAESourceType_ReplaceablePic;
                }
            }else {
                if ([obj.typeName hasPrefix:@"ReplaceableText"]) {
                    info.type = RDAESourceType_ReplaceableText;
                }else if ([obj.typeName hasPrefix:@"ReplaceableVideoOrPic"]) {
                    info.type = RDAESourceType_ReplaceableVideoOrPic;
                }else if ([obj.typeName hasPrefix:@"ReplaceablePic"]) {
                    info.type = RDAESourceType_ReplaceablePic;
                }else {
                    info.type = RDAESourceType_Irreplaceable;
                }
            }
            info.size = CGSizeMake(obj.width, obj.height);
            int inFrame = obj.inFrame;
            info.startTime = inFrame/animationView.sceneModel.framerate.floatValue;
            float duration;
#if 0
            int outFrame = obj.outFrame;
            if (idx+1 <= animationView.variableImageItems.count - 1) {
                RDLOTAnimatedSourceInfo *nextImageFrameSourceInfo = [animationView.variableImageItems objectAtIndex:idx+1];
                int nextInFrame = nextImageFrameSourceInfo.inFrame;
                if (nextInFrame < outFrame && nextInFrame > 0) {
                    duration = (nextInFrame - inFrame)/animationView.sceneModel.framerate.floatValue;
                }else {
                    duration = (outFrame - inFrame)/animationView.sceneModel.framerate.floatValue;
                }
            }else {
                duration = (outFrame - inFrame)/animationView.sceneModel.framerate.floatValue;
            }
#else
            duration = obj.totalFrame/animationView.sceneModel.framerate.floatValue;
#endif
            info.duration = duration;
            if (info.type != RDAESourceType_Irreplaceable) {
                [_aeSourceInfo addObject:info];
            }
        }
    }];
    return _aeSourceInfo;
}

- (void)setJsonAnimation:(RDJsonAnimation *)jsonAnimation {
    BOOL isSameAnimation = NO;
    if (jsonAnimation.jsonDictionary && rdJsonAnimation.jsonDictionary) {
        NSData *jsonData_new = [NSJSONSerialization dataWithJSONObject:jsonAnimation.jsonDictionary options:0 error:0];
        NSString *dataStr_new = [[NSString alloc] initWithData:jsonData_new encoding:NSUTF8StringEncoding];
        
        NSData *jsonData_old = [NSJSONSerialization dataWithJSONObject:rdJsonAnimation.jsonDictionary options:0 error:0];
        NSString *dataStr_old = [[NSString alloc] initWithData:jsonData_old encoding:NSUTF8StringEncoding];
        if ([dataStr_new isEqual:dataStr_old]) {
            isSameAnimation = YES;
        }
    }
    if (([jsonAnimation.jsonPath isEqualToString:rdJsonAnimation.jsonPath] || isSameAnimation)
        && animationView.cacheEnable) {
        return;
    }
    imageFolder = nil;
    animationPlayCount = 1;
    mvUseSourceBuffer = NO;
    [animationLayerArray enumerateObjectsUsingBlock:^(CALayer *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.contents = nil;
    }];
    [animationLayerArray removeAllObjects];
    animationLayerArray = nil;
    animationLayerArray = [NSMutableArray array];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSString *tempImageFoler = [NSTemporaryDirectory() stringByAppendingString:@"RDMVAnimateImagesTemp"];
    if (![fileManager removeItemAtPath:imageFolder error:&error]) {
        NSLog(@"删除文件夹失败:%@", error);
        return;
    }
    if([fileManager fileExistsAtPath:tempImageFoler]){
        if (![fileManager removeItemAtPath:tempImageFoler error:&error]) {
            NSLog(@"删除文件夹失败:%@", error);
            return;
        }
    }
    rdJsonAnimation = jsonAnimation;
    if (jsonAnimation) {
        isRefreshAnimationImages = YES;
        NSError *error = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if(![fileManager fileExistsAtPath:_animationFolderPath]){
            if (![fileManager createDirectoryAtPath:_animationFolderPath withIntermediateDirectories:YES attributes:nil error:&error]) {
                NSLog(@"创建文件夹失败:%@", error);
                return;
            }
        }
        if (rdJsonAnimation.jsonPath.length > 0) {
            [self getAESourceInfoWithJosnPath:rdJsonAnimation.jsonPath];
        }else if (rdJsonAnimation.jsonDictionary) {
            [self getAESourceInfoWithJosnDic:rdJsonAnimation.jsonDictionary];
        }
        animationView.imagesCount = originScenes.count + jsonAnimation.textSourceArray.count;
        animationView.isRepeat = rdJsonAnimation.isRepeat;
        animationView.delegate = self;
        animationImageArray = animationView.imageItems;
        notReplaceableImageArray = animationView.notReplaceableItems;
        textImageArray = animationView.textItems;
        variableImageArray = animationView.variableImageItems;
        if (rdJsonAnimation.isRepeat) {
            float count = originScenes.count/(float)(variableImageArray.count);
            animationPlayCount = ceilf(count);
            NSLog(@"count:%.2f animationPlayCount:%d", count, animationPlayCount);
            if (animationPlayCount < 1) {
                animationPlayCount = 1;
            }
        }
        _animationSize = animationView.sceneModel.compBounds.size;
        if (CGSizeEqualToSize(_animationSize, CGSizeZero)) {
            _animationSize = originVideoSize;
        }
        float imageWidth = [animationView.variableImageItems firstObject].width;
        float imageHeight = [animationView.variableImageItems firstObject].height;
        animationImageSize = CGSizeMake(imageWidth, imageHeight);
        if (CGSizeEqualToSize(CGSizeZero, animationImageSize_prev) || !CGSizeEqualToSize(animationImageSize_prev, animationImageSize) || !animationView.cacheEnable)
        {
            animationImageSize_prev = animationImageSize;
            isClipAnimationImages = YES;
        }else {
            isClipAnimationImages = NO;
        }
        if (rdJsonAnimation.jsonPath.length > 0 || rdJsonAnimation.jsonDictionary) {
            [self performSelectorInBackground:@selector(copySelectedFilesToTempDir) withObject:nil];
        }else {
            isRefreshAnimationImages = NO;
            isClipAnimationImages = NO;
        }
        [self setAnimationScene];
        [self setEditorVideoSize:_animationSize];
    }else {
        rdJsonDic = nil;
        rdJsonPath = nil;
        animationView.delegate = nil;
        [animationView.layer removeFromSuperlayer];
        animationView = nil;
        [_editor setLottieView:nil];
        [_aeSourceInfo removeAllObjects];
        _aeSourceInfo = nil;
        _animationSize = CGSizeZero;
        _editor.animationVideoMusics = nil;
        [self setScenes:originScenes];
        [self setEditorVideoSize:originVideoSize];
    }
    [self build];
    [self refreshFilters];
}

- (void)setAnimationScene {
    for (int i = 0; i< compositionArray.count; i++) {
        RDAEVideoComposition *videoComposition = [compositionArray objectAtIndex:i];
        if (videoComposition.reverseReader.status == AVAssetReaderStatusReading)
        {
            [videoComposition.reverseReader cancelReading];
            videoComposition.reverseReader = nil;
            videoComposition.oldSampleFrameTime = 0;
        }
        videoComposition.videoCopyNextSampleBufferFinish = TRUE;
    }
    getScreenshotFinish = TRUE;
    __block CMTime totalDuration;
    if (rdJsonAnimation.backgroundSourceArray.count > 0) {
        NSMutableArray *scenes = [NSMutableArray array];
        NSMutableArray *musicArray = [NSMutableArray array];
        [rdJsonAnimation.backgroundSourceArray enumerateObjectsUsingBlock:^(RDJsonAnimationBGSource * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            RDScene *scene = [[RDScene alloc] init];
            VVAsset* vvasset = [[VVAsset alloc] init];
            vvasset.identifier = obj.identifier;
            if ([obj.path hasPrefix:@"assets-library"]) {
                vvasset.url = [NSURL URLWithString:obj.path];
            }else {
                vvasset.url = [NSURL fileURLWithPath:obj.path];
            }
            vvasset.type = obj.type;
            if (vvasset.type == RDAssetTypeVideo) {
                vvasset.videoActualTimeRange = [RDRecordHelper getActualTimeRange:vvasset.url];
            }
            vvasset.fillType = obj.fillType;
            vvasset.videoFillType = obj.videoFillType;
            totalDuration = obj.timeRange.duration;
            if (rdJsonAnimation.textSourceArray.count > 0
                && [rdJsonAnimation.textSourceArray lastObject].startTime != -1
                && [rdJsonAnimation.textSourceArray lastObject].duration != -1
                && [rdJsonAnimation.textSourceArray lastObject].duration != 0)
            {
                totalDuration = CMTimeMakeWithSeconds([rdJsonAnimation.textSourceArray lastObject].startTime + [rdJsonAnimation.textSourceArray lastObject].duration, TIMESCALE);
                if (obj.type == RDAssetTypeImage) {
                    vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
                }else {
                    CMTime sourceDuration = [AVURLAsset assetWithURL:vvasset.url].duration;
                    if (CMTimeCompare(CMTimeAdd(obj.timeRange.start, totalDuration), sourceDuration) == 1) {
                        vvasset.isRepeat = YES;
                    }
                    vvasset.timeRange = obj.timeRange;
                    vvasset.timeRangeInVideo = CMTimeRangeMake(obj.timeRangeInVideo.start, totalDuration);
                }
            }else {
                if (CMTimeGetSeconds(CMTimeAdd(obj.timeRangeInVideo.start, obj.timeRange.duration)) > animationView.imagesDuration + animationView.endDuration) {
                    totalDuration = CMTimeMakeWithSeconds(animationView.imagesDuration + animationView.endDuration - CMTimeGetSeconds(obj.timeRangeInVideo.start), TIMESCALE);
                    vvasset.timeRange = CMTimeRangeMake(obj.timeRange.start, totalDuration);
                    if (CMTimeCompare(obj.timeRangeInVideo.duration, obj.timeRange.duration) == 1) {
                        obj.timeRangeInVideo = CMTimeRangeMake(obj.timeRangeInVideo.start, obj.timeRange.duration);
                    }
                }else {
                    totalDuration = obj.timeRange.duration;
                    vvasset.timeRange = obj.timeRange;
                }
            }
            if (rdJsonAnimation.isRepeat && animationPlayCount > 1) {
                vvasset.isRepeat = YES;
                if (CMTimeRangeEqual(vvasset.timeRangeInVideo, kCMTimeRangeZero) || CMTimeRangeEqual(vvasset.timeRangeInVideo, kCMTimeRangeInvalid)) {
                    vvasset.timeRangeInVideo = CMTimeRangeMake(kCMTimeZero, CMTimeMultiply(totalDuration, animationPlayCount));
                }else {
                    vvasset.timeRangeInVideo = CMTimeRangeMake(vvasset.timeRangeInVideo.start, CMTimeMultiply(vvasset.timeRangeInVideo.duration, animationPlayCount));
                }
            }
            vvasset.startTimeInScene = obj.timeRangeInVideo.start;
            vvasset.crop = obj.crop;
            vvasset.volume = obj.volume;
            vvasset.isRepeat = obj.isRepeat;
            vvasset.timeRangeInVideo = obj.timeRangeInVideo;
            if (vvasset.type == RDAssetTypeVideo && CGRectEqualToRect(vvasset.crop, CGRectMake(0, 0, 0.5, 1.0))) {
                mvUseSourceBuffer = YES;
            }else {
                mvUseSourceBuffer = NO;
            }
            [scene.vvAsset addObject:vvasset];
            [scenes addObject:scene];
            if (obj.music) {
                [musicArray addObject:obj.music];
            }
        }];
        _editor.animationBGMusics = musicArray;
        _editor.scenes = scenes;
    }else if (rdJsonAnimation.bgSourceArray.count > 0) {
        [rdJsonAnimation.bgSourceArray enumerateObjectsUsingBlock:^(RDScene * _Nonnull scene, NSUInteger idx, BOOL * _Nonnull stop) {
            [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull vvasset, NSUInteger idx1, BOOL * _Nonnull stop1) {
                totalDuration = vvasset.timeRange.duration;
                if (rdJsonAnimation.textSourceArray.count > 0
                    && [rdJsonAnimation.textSourceArray lastObject].startTime != -1
                    && [rdJsonAnimation.textSourceArray lastObject].duration != -1
                    && [rdJsonAnimation.textSourceArray lastObject].duration != 0)
                {
                    totalDuration = CMTimeMakeWithSeconds([rdJsonAnimation.textSourceArray lastObject].startTime + [rdJsonAnimation.textSourceArray lastObject].duration, TIMESCALE);
                    if (vvasset.type == RDAssetTypeImage) {
                        vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
                    }else {
                        CMTime sourceDuration = [AVURLAsset assetWithURL:vvasset.url].duration;
                        if (CMTimeCompare(CMTimeAdd(vvasset.timeRange.start, totalDuration), sourceDuration) == 1) {
                            vvasset.isRepeat = YES;
                        }
                        vvasset.timeRangeInVideo = CMTimeRangeMake(vvasset.timeRangeInVideo.start, totalDuration);
                    }
                }else {
                    if (CMTimeGetSeconds(CMTimeAdd(vvasset.timeRangeInVideo.start, vvasset.timeRange.duration)) > animationView.imagesDuration + animationView.endDuration) {
                        totalDuration = CMTimeMakeWithSeconds(animationView.imagesDuration + animationView.endDuration - CMTimeGetSeconds(vvasset.timeRangeInVideo.start), TIMESCALE);
                        vvasset.timeRange = CMTimeRangeMake(vvasset.timeRange.start, totalDuration);
                        if (CMTimeCompare(vvasset.timeRangeInVideo.duration, vvasset.timeRange.duration) == 1) {
                            vvasset.timeRangeInVideo = CMTimeRangeMake(vvasset.timeRangeInVideo.start, vvasset.timeRange.duration);
                        }
                    }
                }
                if (rdJsonAnimation.isRepeat && animationPlayCount > 1) {
                    vvasset.isRepeat = YES;
                    if (CMTimeRangeEqual(vvasset.timeRangeInVideo, kCMTimeRangeZero) || CMTimeRangeEqual(vvasset.timeRangeInVideo, kCMTimeRangeInvalid)) {
                        vvasset.timeRangeInVideo = CMTimeRangeMake(kCMTimeZero, CMTimeMultiply(totalDuration, animationPlayCount));
                    }else {
                        totalDuration = vvasset.timeRange.duration;
                        vvasset.timeRangeInVideo = CMTimeRangeMake(vvasset.timeRangeInVideo.start, CMTimeMultiply(vvasset.timeRangeInVideo.duration, animationPlayCount));
                    }
                }
                if (vvasset.type == RDAssetTypeVideo && CGRectEqualToRect(vvasset.crop, CGRectMake(0, 0, 0.5, 1.0))) {
                    mvUseSourceBuffer = YES;
                }else {
                    mvUseSourceBuffer = NO;
                }
            }];
        }];
        _editor.scenes = rdJsonAnimation.bgSourceArray;
    }else {
        NSMutableArray *scenes = [NSMutableArray array];
        RDScene *scene = [[RDScene alloc] init];
        NSString *bgVideoPath = [[NSBundle mainBundle] pathForResource:@"RDVECore.bundle/black" ofType:@"mp4"];
        VVAsset* vvasset = [[VVAsset alloc] init];
        vvasset.url = [NSURL fileURLWithPath:bgVideoPath];
        vvasset.type         = RDAssetTypeVideo;
        if (rdJsonAnimation.textSourceArray.count > 0
            && [rdJsonAnimation.textSourceArray lastObject].startTime != -1
            && [rdJsonAnimation.textSourceArray lastObject].duration != -1
            && [rdJsonAnimation.textSourceArray lastObject].duration != 0)
        {
            vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds([rdJsonAnimation.textSourceArray lastObject].startTime + [rdJsonAnimation.textSourceArray lastObject].duration, TIMESCALE));
        }else {
            vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(animationView.imagesDuration + animationView.endDuration, TIMESCALE));
        }
        totalDuration = vvasset.timeRange.duration;
        if (rdJsonAnimation.isRepeat && animationPlayCount > 1) {
            vvasset.isRepeat = YES;
            vvasset.timeRangeInVideo = CMTimeRangeMake(kCMTimeZero, CMTimeMultiply(vvasset.timeRange.duration, animationPlayCount));
        }
        [scene.vvAsset addObject:vvasset];
        [scenes addObject:scene];
        _editor.scenes = scenes;
    }
    prevAnimationImage = nil;
    prevAnimationImageName = nil;
    prevBufferTime = kCMTimeInvalid;
    [animationVideoArray removeAllObjects];
    animationVideoArray = nil;
    animationVideoArray = [NSMutableArray array];
    [animationGifArray removeAllObjects];
    animationGifArray = nil;
    animationGifArray = [NSMutableArray array];
    
    [compositionArray removeAllObjects];
    compositionArray = nil;
    compositionArray = [NSMutableArray array];
    
    __weak typeof(self) weakSelf = self;
    __block NSMutableArray *videoMusicArray = [NSMutableArray array];
    [originScenes enumerateObjectsUsingBlock:^(RDScene *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        __strong typeof(self) strongSelf = weakSelf;
        if (idx == animationView.variableImageItems.count && strongSelf->animationPlayCount == 1) {
            *stop = YES;
        }else {
            VVAsset *asset = [obj.vvAsset firstObject];
            
            NSInteger count = idx/animationView.variableImageItems.count;
            NSInteger index = idx - count*animationView.variableImageItems.count;
            CMTime startDuration = CMTimeMultiply(totalDuration, (int)count);
            
            RDLOTAnimatedSourceInfo *imageFrameSourceInfo = [animationView.variableImageItems objectAtIndex:index];
            int inFrame = imageFrameSourceInfo.inFrame;
            float startTime = inFrame/animationView.sceneModel.framerate.floatValue;
            float duration;
#if 0
            int outFrame = imageFrameSourceInfo.outFrame;
            if (index+1 <= animationView.variableImageItems.count - 1) {
                RDLOTAnimatedSourceInfo *nextImageFrameSourceInfo = [animationView.variableImageItems objectAtIndex:index+1];
                int nextInFrame = nextImageFrameSourceInfo.inFrame;
                if (nextInFrame < outFrame && nextInFrame > 0) {
                    duration = (nextInFrame - inFrame)/animationView.sceneModel.framerate.floatValue;
                }else {
                    duration = (outFrame - inFrame)/animationView.sceneModel.framerate.floatValue;
                }
            }else {
                duration = (outFrame - inFrame)/animationView.sceneModel.framerate.floatValue;
            }
#else
            duration = imageFrameSourceInfo.totalFrame/animationView.sceneModel.framerate.floatValue;
#endif
            
            RDAEVideoImageInfo *videoInfo = [[RDAEVideoImageInfo alloc] init];
            videoInfo.imageName = imageFrameSourceInfo.name;
            videoInfo.startTime = startTime + CMTimeGetSeconds(startDuration);
            videoInfo.duration = duration;
            videoInfo.crop = asset.crop;
            videoInfo.timeRange = asset.timeRange;
            videoInfo.size = CGSizeMake(imageFrameSourceInfo.width, imageFrameSourceInfo.height);
            videoInfo.url = asset.url;
            videoInfo.filterType = asset.filterType;
            videoInfo.filterUrl = asset.filterUrl;
            if ((idx == strongSelf->originScenes.count - 1 || index == animationView.variableImageItems.count - 1) && animationView.hasEndImage) {
                RDLOTAnimatedSourceInfo *prevSourceInfo = [animationView.imageItems objectAtIndex:animationView.imageItems.count - 2];
                int inFrame = prevSourceInfo.inFrame;
                float startTime = inFrame/animationView.sceneModel.framerate.floatValue;
#if 0
                int outFrame = prevSourceInfo.outFrame;
                float duration = (outFrame - inFrame)/animationView.sceneModel.framerate.floatValue;
#else
                duration = prevSourceInfo.totalFrame/animationView.sceneModel.framerate.floatValue;
#endif
                videoInfo.imageName = prevSourceInfo.name;
                videoInfo.startTime = startTime + CMTimeGetSeconds(startDuration);
                videoInfo.duration = duration;
            }
            if (asset.type == RDAssetTypeVideo) {
#if 0
                videoInfo.screenshotArray = [NSMutableArray array];
                [self getAnimationScreenshotFromVideoInfo:videoInfo];
                [strongSelf->animationVideoArray addObject:videoInfo];
#else
                if (CMTimeRangeEqual(asset.videoActualTimeRange, kCMTimeRangeZero) || CMTimeRangeEqual(asset.videoActualTimeRange, kCMTimeRangeInvalid)) {
                    asset.videoActualTimeRange = [RDVECore getActualTimeRange:asset.url];
                }
                if (CMTimeCompare(asset.timeRange.start, asset.videoActualTimeRange.start) == -1) {
                    asset.timeRange = CMTimeRangeMake(asset.videoActualTimeRange.start, asset.timeRange.duration);
                }
                if (CMTimeCompare(CMTimeAdd(asset.timeRange.start, asset.timeRange.duration), asset.videoActualTimeRange.duration) == 1) {
                    asset.timeRange = CMTimeRangeMake(asset.timeRange.start, CMTimeSubtract(asset.videoActualTimeRange.duration, asset.timeRange.start));
                }
                [strongSelf->animationVideoArray addObject:videoInfo];
                RDAEVideoComposition* videoCompostion = [[RDAEVideoComposition alloc] init];
                videoCompostion.url = asset.url;

                AVAsset *avAsset = [AVAsset assetWithURL:asset.url];
                if ([[avAsset tracksWithMediaType:AVMediaTypeVideo] count] > 0) {
                    AVAssetTrack* clipVideoTrack = [[avAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
                    CGAffineTransform t = clipVideoTrack.preferredTransform;
                    if((t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0) || (t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0)) {//竖屏
                        videoCompostion.imageOrientation = UIImageOrientationRight;
                    }else if (t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0) {//横屏
                        videoCompostion.imageOrientation = UIImageOrientationDown;
                    }
                }
                avAsset = nil;
                float timeRangeStart = CMTimeGetSeconds(asset.timeRange.start);
                float timeRangeDuration = CMTimeGetSeconds(asset.timeRange.duration);
                videoCompostion.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(timeRangeStart+timeRangeDuration, TIMESCALE));
                videoCompostion.videoURLComposition = [self buildVideoForFileURL:asset.url timeRange:videoCompostion.timeRange];
                if (videoCompostion.videoURLComposition) {
                    [self createReverseReaderWithPixelFormat32BGRA:videoCompostion timeRange:asset.timeRange];
                    videoCompostion.videoCopyNextSampleBufferFinish = TRUE;
                    [strongSelf->compositionArray addObject:videoCompostion];
                }
#endif
                RDMusic *music = [RDMusic new];
                music.identifier = asset.identifier;
                music.url = asset.url;
                music.clipTimeRange = CMTimeRangeMake(asset.timeRange.start, CMTimeMakeWithSeconds(duration, TIMESCALE));
                music.effectiveTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(videoInfo.startTime, TIMESCALE), music.clipTimeRange.duration);
                music.isRepeat = NO;
                music.volume = asset.volume;
                [videoMusicArray addObject:music];
            }else if (asset.url) {
                NSURL *url = asset.url;
                if ([RDRecordHelper isSystemPhotoUrl:url]) {
                    PHAsset* phAsset =[[PHAsset fetchAssetsWithALAssetURLs:@[url] options:nil] objectAtIndex:0];
                    if ([[phAsset valueForKey:@"uniformTypeIdentifier"] isEqualToString:@"com.compuserve.gif"]) {
                        
                        CGSize targetSize;
                        if (CGRectEqualToRect(asset.crop, CGRectMake(0, 0, 1.0, 1.0))) {
                            float imageSizePro = imageFrameSourceInfo.width/imageFrameSourceInfo.height;
                            float width;
                            if (imageSizePro == 1.0) {
                                width = MIN(rdJsonAnimation.targetImageMaxSize, MIN(phAsset.pixelWidth, phAsset.pixelHeight));
                                targetSize = CGSizeMake(width, width);
                            }else if (imageSizePro > 1.0) {
                                width = MIN(rdJsonAnimation.targetImageMaxSize, phAsset.pixelWidth);
                                targetSize = CGSizeMake(width, width/imageSizePro);
                            }else {
                                width = MIN(rdJsonAnimation.targetImageMaxSize, phAsset.pixelHeight);
                                targetSize = CGSizeMake(width*imageSizePro, width);
                            }
                        }else {
                            targetSize = CGSizeMake(rdJsonAnimation.targetImageMaxSize, rdJsonAnimation.targetImageMaxSize);
                        }
                        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
                        option.synchronous = YES;
                        option.resizeMode = PHImageRequestOptionsResizeModeExact;
                        [[PHImageManager defaultManager] requestImageDataForAsset:phAsset
                                                                          options:option
                                                                    resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                                                                        videoInfo.gifDurationArray = [NSMutableArray array];
                                                                        videoInfo.gifImage = [self imageWithGifData:imageData durationArray:videoInfo.gifDurationArray targetSize:targetSize maxSize:rdJsonAnimation.targetImageMaxSize crop:asset.crop];
                                                                    }];
                        if (videoInfo.gifImage.images.count > 1) {
                            [strongSelf->animationGifArray addObject:videoInfo];
                        }else {
                            videoInfo = nil;
                        }
                    }else {
                        videoInfo = nil;
                    }
                } else {
                    CGSize targetSize = CGSizeMake(imageFrameSourceInfo.width, imageFrameSourceInfo.height);
                    NSData *data = [NSData dataWithContentsOfURL:url];
                    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
                    size_t count = CGImageSourceGetCount(source);
                    data = nil;
                    if (count > 1) {
                        videoInfo.gifDurationArray = [NSMutableArray array];
                        videoInfo.gifImage = [self imageWithGifData:data durationArray:videoInfo.gifDurationArray targetSize:targetSize maxSize:rdJsonAnimation.targetImageMaxSize crop:asset.crop];
                        [strongSelf->animationGifArray addObject:videoInfo];
                    }else {
                        videoInfo = nil;
                    }
                }
            }
        }
    }];
    _editor.animationVideoMusics = videoMusicArray;
}

- (UIImage *)imageWithGifData:(NSData *)data
                durationArray:(NSMutableArray *)durationArray
                   targetSize:(CGSize)targetSize
                      maxSize:(float)maxSize
                         crop:(CGRect)crop
{
    if (!data) {
        return nil;
    }
    UIImage *image;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    size_t count = CGImageSourceGetCount(source);
    if (count <= 1) {
        image = [[UIImage alloc] initWithData:data];
    }else {
        NSMutableArray *images = [NSMutableArray array];
        NSTimeInterval duration = 0.0f;
        for (size_t i = 0; i < count; i++) {
            CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, i, NULL);
            CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
            CGSize size = imageSize;
            if (MAX(size.width, size.height) > maxSize) {
                if (imageSize.width >= imageSize.height) {
                    float width = MIN(maxSize, imageSize.width);
                    size = CGSizeMake(width, width / (imageSize.width / imageSize.height));
                }else {
                    float height = MIN(maxSize, imageSize.height);
                    size = CGSizeMake(height * (imageSize.width / imageSize.height), height);
                }
            }
            
            BOOL hasAlpha = [self CGImageContainsAlpha:imageRef];
            // iOS prefer BGRA8888 (premultiplied) or BGRX8888 bitmapInfo for screen rendering, which is same as `UIGraphicsBeginImageContext()` or `- [CALayer drawInContext:]`
            // Though you can use any supported bitmapInfo (see: https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_context/dq_context.html#//apple_ref/doc/uid/TP30001066-CH203-BCIBHHBB ) and let Core Graphics reorder it when you call `CGContextDrawImage`
            // But since our build-in coders use this bitmapInfo, this can have a little performance benefit
            CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
            bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
            CGContextRef context = CGBitmapContextCreate(nil, size.width, size.height, 8, 4*size.width, [self colorSpaceGetDeviceRGB], bitmapInfo);
            if (!context) {
                return NULL;
            }
            // Apply transform
            CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), imageRef); // The rect is bounding box of CGImage, don't swap width & height
            CGImageRef sourceImageRef = CGBitmapContextCreateImage(context);
            CGContextRelease(context);
            CGImageRelease(imageRef);
            
            UIImage *image;
            if (CGRectEqualToRect(crop, CGRectMake(0, 0, 1, 1))) {
                float imageSizePro = targetSize.width/targetSize.height;
                if (imageSizePro != size.width / size.height) {
                    float x,y,w,h;
                    if (imageSizePro == 1.0) {
                        w = MIN(size.width, size.height);
                        h = w;
                    }else if (imageSizePro > 1.0) {
                        w = size.width;
                        h = w/imageSizePro;
                        if (h > size.height) {
                            h = size.height;
                            w = h*imageSizePro;
                        }
                    }else {
                        h = size.height;
                        w = h*imageSizePro;
                        if (w > size.width) {
                            w = size.width;
                            h = w / imageSizePro;
                        }
                    }
                    x = fabs(size.width - w)/2.0;
                    y = fabs(size.height - h)/2.0;
                    CGRect rect = CGRectMake(x, y, w, h);
                    
                    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
                    CGImageRelease(sourceImageRef);
                    image = [UIImage imageWithCGImage:newImageRef scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
                    CGImageRelease(newImageRef);
                }else {
                    image = [UIImage imageWithCGImage:sourceImageRef scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
                    CGImageRelease(sourceImageRef);
                }
            }else {
                CGRect rect = CGRectMake(size.width * crop.origin.x, size.height * crop.origin.y, size.width * crop.size.width, size.height * crop.size.height);
                CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
                CGImageRelease(sourceImageRef);
                image = [UIImage imageWithCGImage:newImageRef scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
                CGImageRelease(newImageRef);
            }
            if (image) {
                [images addObject:image];
                duration += [RDRecordHelper frameDurationAtIndex:i source:source];
                [durationArray addObject:[NSNumber numberWithFloat:duration]];
            }else {
                NSLog(@"%d", __LINE__);
            }
        }
        NSLog(@"durationArray:%d images:%d", durationArray.count, images.count);
        image = [UIImage animatedImageWithImages:images duration:duration];
    }
    if (source) {
        CFRelease(source);
    }
    return image;
}

- (BOOL)CGImageContainsAlpha:(CGImageRef)cgImage {
    if (!cgImage) {
        return NO;
    }
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(cgImage);
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    return hasAlpha;
}

- (CGColorSpaceRef)colorSpaceGetDeviceRGB {
    static CGColorSpaceRef colorSpace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colorSpace = CGColorSpaceCreateDeviceRGB();
    });
    return colorSpace;
}

- (void)setAnimationView {
    [animationView refreshLayerContents];
    if (rdJsonAnimation.textSourceArray.count > 0) {
        __block NSMutableArray *inOutFrames = [NSMutableArray array];
        [rdJsonAnimation.textSourceArray enumerateObjectsUsingBlock:^(RDJsonText * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.startTime >= 0 && obj.duration > 0) {
                RDLOTAnimatedSourceInfo *info = [RDLOTAnimatedSourceInfo new];
                info.inFrame = obj.startTime * animationView.sceneModel.framerate.intValue;
                if (obj.duration != -1) {
                    info.outFrame = info.inFrame + obj.duration  * animationView.sceneModel.framerate.intValue;
                }
                [inOutFrames addObject:info];
            }
        }];
        if (inOutFrames.count > 0) {
            animationView.cacheEnable = NO;
            [animationView refreshLayerInOutFrame:inOutFrames];
        }
    }
    isRefreshAnimationImages = NO;
    
    if (movieEffects.count > 0) {
        if (rdJsonAnimation.backgroundSourceArray.count == 0 && rdJsonAnimation.bgSourceArray.count == 0) {
            animationView.isBlackVideo = YES;
        }
        animationView.animationPlayCount = animationPlayCount;
        [_editor setLottieView:animationView];
    }else {
        [suplayer insertSublayer:animationView.layer atIndex:0];
    }
    if (_status == kRDVECoreStatusReadyToPlay) {
        if (_delegate && [_delegate respondsToSelector:@selector(statusChanged:status:)]) {
            [_delegate statusChanged:self status:_status];
        }else if (_delegate && [_delegate respondsToSelector:@selector(statusChanged:)]) {
            [_delegate statusChanged:_status];
        }
    }
}

- (void)copySelectedFilesToTempDir {
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:_animationFolderPath]){
        if (![fileManager createDirectoryAtPath:_animationFolderPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"创建文件夹失败:%@", error);
            return;
        }
    }
    
    if (variableImageArray.count > 0) {
        imageFolder = [NSString stringWithFormat:@"%@%@", _animationFolderPath, [variableImageArray firstObject].directoryName];
    }else {
        imageFolder = [NSString stringWithFormat:@"%@%@", _animationFolderPath, [textImageArray firstObject].directoryName];
    }
    NSString *tempImageFoler = [NSTemporaryDirectory() stringByAppendingString:@"RDMVAnimateImagesTemp"];
    if(![fileManager fileExistsAtPath:imageFolder]){
        if (![fileManager createDirectoryAtPath:imageFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"创建文件夹失败:%@", error);
            return;
        }
    }else if (isClipAnimationImages) {
        if (![fileManager removeItemAtPath:imageFolder error:&error]) {
            NSLog(@"删除文件夹失败:%@", error);
            return;
        }
        if (![fileManager createDirectoryAtPath:imageFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"创建文件夹失败:%@", error);
            return;
        }
    }else {
        if([fileManager fileExistsAtPath:tempImageFoler]){
            if (![fileManager removeItemAtPath:tempImageFoler error:&error]) {
                NSLog(@"删除文件夹失败:%@", error);
                return;
            }
        }
        if (![fileManager moveItemAtPath:imageFolder toPath:tempImageFoler error:&error]) {
            NSLog(@"移动文件夹失败:%@", error);
            return;
        }
        if (![fileManager createDirectoryAtPath:imageFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"创建文件夹失败:%@", error);
            return;
        }
    }
    if (rdJsonAnimation.isRepeat && animationPlayCount > 1) {
        if (![fileManager createDirectoryAtPath:[imageFolder stringByAppendingPathComponent:kAnimationRepeatFolder] withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"创建文件夹失败:%@", error);
            return;
        }
    }
    if (!animationImageArray_prev) {
        animationImageArray_prev = [NSMutableArray array];
    }else if (isClipAnimationImages) {
        [animationImageArray_prev removeAllObjects];
    }
    if (!animationTextImageArray) {
        animationTextImageArray = [NSMutableArray array];
    }else if (isClipAnimationImages) {
        [animationTextImageArray removeAllObjects];
    }
    
    [notReplaceableImageArray enumerateObjectsUsingBlock:^(RDLOTAnimatedSourceInfo* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *imageName = obj.name;
        NSString *imagePath = [NSString stringWithFormat:@"%@%@", imageFolder, imageName];
        __block NSError *error = nil;
        if ([fileManager fileExistsAtPath:imagePath]) {
            if (![fileManager removeItemAtPath:imagePath error:&error]) {
                NSLog(@"删除文件失败:%@", error);
            }
        }
        error = nil;
        [rdJsonAnimation.nonEditableImagePathArray enumerateObjectsUsingBlock:^(NSString*  _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
            if ([obj1.lastPathComponent.stringByDeletingPathExtension isEqualToString:[obj.typeName stringByDeletingPathExtension]]) {
                if (![fileManager copyItemAtPath:obj1 toPath:imagePath error:&error]) {
                    NSLog(@"移动文件失败:%@", error);
                }
                *stop1 = YES;
            }
        }];
    }];
    __weak typeof(self) weakSelf = self;
    __block BOOL isClipImage = isClipAnimationImages;
    dispatch_async(dispatch_get_main_queue(), ^{
    [rdJsonAnimation.textSourceArray enumerateObjectsUsingBlock:^(RDJsonText * _Nonnull jsonText, NSUInteger idx, BOOL * _Nonnull stop) {
        __strong typeof(self) strongSelf = weakSelf;
        if (idx == strongSelf->textImageArray.count && !strongSelf->rdJsonAnimation.isRepeat) {
            *stop = YES;
        }
        int index;
        NSInteger count = idx/strongSelf->textImageArray.count;
        if (strongSelf->rdJsonAnimation.isRepeat) {
            if (idx < strongSelf->textImageArray.count) {
                index = idx;
            }else {
                index = idx - (int)(count*strongSelf->textImageArray.count);
            }
        }else {
            index = idx;
        }
        RDLOTAnimatedSourceInfo *soureInfo = strongSelf->textImageArray[index];
        NSString *imageName = soureInfo.name;
        NSString *imagePath = [NSString stringWithFormat:@"%@%@", imageFolder, imageName];
        if (idx >= strongSelf->textImageArray.count) {
            imagePath = [NSString stringWithFormat:@"%@others/%@%d.%@", imageFolder, [imageName stringByDeletingPathExtension], count, imageName.pathExtension];
//            NSLog(@"i:%d count:%d index:%d textPath:%@", idx, count, index, imagePath);
        }
        __block NSError *error = nil;
        if ([fileManager fileExistsAtPath:imagePath]) {
            if (![fileManager removeItemAtPath:imagePath error:&error]) {
                NSLog(@"删除文件失败:%@", error);
            }
        }
        error = nil;
        if (jsonText.imagePath.length > 0 && [jsonText.imagePath.lastPathComponent.stringByDeletingPathExtension isEqualToString:[soureInfo.typeName stringByDeletingPathExtension]])
        {
            if (jsonText.text.length > 0) {
                if (isClipImage) {
                    [animationTextImageArray addObject:[imagePath lastPathComponent]];
                    UIImage *image = [weakSelf getTextImage:jsonText];
                    NSData *data = UIImagePNGRepresentation(image);
                    if (![data writeToFile:imagePath atomically:YES]) {
                        NSLog(@"写入文件错误：%@", imagePath);
                    }
                }else {
                    if (idx < animationTextImageArray.count) {
                        NSString *imagePath_from = [NSString stringWithFormat:@"%@/%@", tempImageFoler,[animationTextImageArray objectAtIndex:idx]];
                        if ([fileManager fileExistsAtPath:imagePath_from]) {
                            if (![fileManager moveItemAtPath:imagePath_from toPath:imagePath error:&error]) {
                                NSLog(@"移动文件夹失败:%@", error);
                            }else {
                                [animationTextImageArray replaceObjectAtIndex:idx withObject:[imagePath lastPathComponent]];
                            }
                        }else {
                            [animationTextImageArray addObject:[imagePath lastPathComponent]];
                            UIImage *image = [weakSelf getTextImage:jsonText];
                            NSData *data = UIImagePNGRepresentation(image);
                            [data writeToFile:imagePath atomically:YES];
                        }
                    }else {
                        [animationTextImageArray addObject:[imagePath lastPathComponent]];
                        UIImage *image = [weakSelf getTextImage:jsonText];
                        NSData *data = UIImagePNGRepresentation(image);
                        if (![data writeToFile:imagePath atomically:YES]) {
                            NSLog(@"写入文件错误：%@", imagePath);
                        }
                    }
                }
            }
            else if (jsonText.imagePath.length > 0) {
                if (![fileManager copyItemAtPath:jsonText.imagePath toPath:imagePath error:&error]) {
                    NSLog(@"移动文件失败:%@", error);
                }
            }
        }else {
            if (isClipImage) {
                [animationTextImageArray addObject:[imagePath lastPathComponent]];
                UIImage *image = [weakSelf getTextImage:jsonText];
                NSData *data = UIImagePNGRepresentation(image);
                if (![data writeToFile:imagePath atomically:YES]) {
                    NSLog(@"写入文件错误：%@", imagePath);
                }
            }else {
                if (idx < animationTextImageArray.count) {
                    NSString *imagePath_from = [NSString stringWithFormat:@"%@/%@", tempImageFoler,[animationTextImageArray objectAtIndex:idx]];
                    if ([fileManager fileExistsAtPath:imagePath_from]) {
                        if (![fileManager moveItemAtPath:imagePath_from toPath:imagePath error:&error]) {
                            NSLog(@"移动文件夹失败:%@", error);
                        }else {
                            [animationTextImageArray replaceObjectAtIndex:idx withObject:[imagePath lastPathComponent]];
                        }
                    }else {
                        [animationTextImageArray addObject:[imagePath lastPathComponent]];
                        UIImage *image = [weakSelf getTextImage:jsonText];
                        NSData *data = UIImagePNGRepresentation(image);
                        [data writeToFile:imagePath atomically:YES];
                    }
                }else {
                    [animationTextImageArray addObject:[imagePath lastPathComponent]];
                    UIImage *image = [weakSelf getTextImage:jsonText];
                    NSData *data = UIImagePNGRepresentation(image);
                    if (![data writeToFile:imagePath atomically:YES]) {
                        NSLog(@"写入文件错误：%@", imagePath);
                    }
                }
            }
        }
    }];
    });
    for (int i = 0; i < originScenes.count; i++) {
        @autoreleasepool {
            if (i == variableImageArray.count && !rdJsonAnimation.isRepeat) {
                break;
            }
            int index;
            int count = i/variableImageArray.count;
            if (rdJsonAnimation.isRepeat) {
                if (i < variableImageArray.count) {
                    index = i;
                }else {
                    index = i - (int)(count*variableImageArray.count);
                }
            }else {
                index = i;
            }
            error = nil;
            RDScene *scene = [originScenes objectAtIndex:i];
            VVAsset *vvAsset = [scene.vvAsset firstObject];
            RDLOTAnimatedSourceInfo *imageSourceInfo = [variableImageArray objectAtIndex:index];
            NSString *imageName = imageSourceInfo.name;
            CGSize animateImageSize = CGSizeMake(imageSourceInfo.width, imageSourceInfo.height);
            if (animationView.endDuration > 0 && i == originScenes.count - 1) {
                imageName = imageSourceInfo.name;
                if (animationView.lastReplacableInfo.inFrame / animationView.sceneModel.framerate.floatValue == animationView.endStartTime + animationView.imagesDuration) {
                    imageName = animationView.lastReplacableInfo.name;
                }
                animateImageSize = CGSizeMake(animationView.lastReplacableInfo.width, animationView.lastReplacableInfo.height);
            }
            NSString *imagePath = [NSString stringWithFormat:@"%@%@", imageFolder, imageName];
            if (i >= variableImageArray.count) {
                imagePath = [NSString stringWithFormat:@"%@others/%@%d.%@", imageFolder, [imageName stringByDeletingPathExtension], count, imageName.pathExtension];
//                NSLog(@"i:%d count:%d index:%d imagePath:%@", i, count, index, imagePath);
            }
            if ([fileManager fileExistsAtPath:imagePath]) {
                if (![fileManager removeItemAtPath:imagePath error:&error]) {
                    NSLog(@"删除文件夹失败:%@", error);
                    continue;
                }
            }
            if (!vvAsset.url) {
                continue;
            }
            if (isClipAnimationImages) {
                [animationImageArray_prev addObject:[imagePath lastPathComponent]];
                UIImage *image = [self getImageFromUrl:vvAsset.url crop:vvAsset.crop animateImageSize:animateImageSize];
                if (!image) {
                    continue;
                }
                if (vvAsset.filterType != VVAssetFilterEmpty) {
                    RDFilter* filter = [RDFilter new];
                    if (vvAsset.filterType == VVAssetFilterACV) {
                        filter.type = kRDFilterType_ACV;
                    }else {
                        filter.type = kRDFilterType_LookUp;
                    }
                    filter.filterPath = vvAsset.filterUrl.path;
                    image = [RDVECore getFilteredImage:image filter:filter];
                }
                NSData *data = UIImagePNGRepresentation(image);
                if (![data writeToFile:imagePath atomically:YES]) {
                    NSLog(@"写入文件错误：%@", imagePath);
                }
            }else {
                if (i < animationImageArray_prev.count) {
                    NSString *imagePath_from = [NSString stringWithFormat:@"%@/%@", tempImageFoler,[animationImageArray_prev objectAtIndex:index]];
                    if ([fileManager fileExistsAtPath:imagePath_from]) {
                        if (![fileManager moveItemAtPath:imagePath_from toPath:imagePath error:&error]) {
                            NSLog(@"移动文件夹失败:%@", error);
                        }else {
                            [animationImageArray_prev replaceObjectAtIndex:i withObject:[imagePath lastPathComponent]];
                        }
                    }else {
                        NSLog(@"no image.................%@", imagePath_from);
                        [animationImageArray_prev addObject:[imagePath lastPathComponent]];
                        UIImage *image = [self getImageFromUrl:vvAsset.url crop:vvAsset.crop animateImageSize:animateImageSize];
                        NSData *data = UIImagePNGRepresentation(image);
                        [data writeToFile:imagePath atomically:YES];
                    }
                }else {
                    [animationImageArray_prev addObject:[imagePath lastPathComponent]];
                    UIImage *image = [self getImageFromUrl:vvAsset.url crop:vvAsset.crop animateImageSize:animateImageSize];
                    NSData *data = UIImagePNGRepresentation(image);
                    if (![data writeToFile:imagePath atomically:YES]) {
                        NSLog(@"写入文件错误：%@", imagePath);
                    }
                }
            }
        }
    }
    isClipAnimationImages = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setAnimationView];
    });
}

- (UIImage *)getTextImage:(RDJsonText *)textSource {
    @autoreleasepool {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, textSource.size.width, textSource.size.height)];
        
        UIFont *font = label.font;
        CGSize size = [textSource.text sizeWithAttributes:@{NSFontAttributeName:font}];
        __block NSInteger lines = (NSInteger)(size.height / font.lineHeight);
        float fontSize = textSource.fontSize;
        float width = label.bounds.size.width - textSource.edgeInsets.left - textSource.edgeInsets.right;
        float height = label.bounds.size.height - textSource.edgeInsets.top - textSource.edgeInsets.bottom;
        
        if (textSource.fontName.length == 0) {
            textSource.fontName = font.fontName;
        }else {
            BOOL isRegistered = NO;
            NSArray* familys = [UIFont familyNames];
            for (NSString *family in familys) {
                NSArray* fonts = [UIFont fontNamesForFamilyName:family];
                for (NSString *font in fonts) {
                    if ([textSource.fontName isEqualToString:font]) {
                        isRegistered = YES;
                        break;
                    }
                }
                if (isRegistered) {
                    break;
                }
            }
            if (!isRegistered) {
                textSource.fontName = font.fontName;
            }
        }
        if (textSource.isVerticalText && lines > 1) {//竖排多列
            label.backgroundColor = [UIColor clearColor];
            lines = 0;
            NSMutableArray *textArray = [NSMutableArray array];
            NSString *tempStr = textSource.text;
            NSString *maxStr = @"";
            while ([tempStr rangeOfString:@"\n"].location != NSNotFound) {
                NSRange range = [tempStr rangeOfString:@"\n"];
                NSString *s = [tempStr substringToIndex:range.location];
                if (s.length > maxStr.length) {
                    maxStr = s;
                }
                NSMutableString *str = [NSMutableString string];
                [s enumerateSubstringsInRange:NSMakeRange(0, s.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:
                ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                    lines++;
                    if (substringRange.location + substringRange.length == s.length) {
                        [str insertString:substring atIndex:str.length];
                    }else {
                        [str insertString:[substring stringByAppendingString:@"\n"] atIndex:str.length];
                    }
                }];
                [textArray addObject:str];
                tempStr = [tempStr substringFromIndex:range.location + range.length];
            }
            NSMutableString *str = [NSMutableString string];
            [tempStr enumerateSubstringsInRange:NSMakeRange(0, tempStr.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:
            ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                lines++;
                if (substringRange.location + substringRange.length == tempStr.length) {
                    [str insertString:substring atIndex:str.length];
                }else {
                    [str insertString:[substring stringByAppendingString:@"\n"] atIndex:str.length];
                }
            }];
            [textArray addObject:str];
            if (tempStr.length > maxStr.length) {
                maxStr = tempStr;
            }
            width = width/(float)lines;
            if (fontSize == 0.0) {
                label.lineBreakMode = NSLineBreakByCharWrapping;
                
                NSMutableString *sizeStr = [NSMutableString string];
                [maxStr enumerateSubstringsInRange:NSMakeRange(0, maxStr.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:
                ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                    if (substringRange.location + substringRange.length == maxStr.length) {
                        [sizeStr insertString:substring atIndex:str.length];
                    }else {
                        [sizeStr insertString:[substring stringByAppendingString:@"\n"] atIndex:str.length];
                    }
                }];
                for (int i = width; i > 5; i--) {
                    CGSize size_w = [sizeStr boundingRectWithSize:CGSizeMake(width, MAXFLOAT)
                                                      options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                   attributes:@{NSFontAttributeName : [UIFont fontWithName:textSource.fontName size:i]}
                                                      context:nil].size;
                    CGSize size_h = [sizeStr boundingRectWithSize:CGSizeMake(MAXFLOAT, height)
                                                      options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                   attributes:@{NSFontAttributeName : [UIFont fontWithName:textSource.fontName size:i]}
                                                      context:nil].size;
                    if (size_w.height <= height && size_h.width <= width) {
                        fontSize = i;
                        break;
                    }
                }
            }else {
                if (textSource.fontName.length > 0) {
                    label.font = [UIFont fontWithName:textSource.fontName size:fontSize];
                }else {
                    label.font = [UIFont systemFontOfSize:fontSize];
                }
                label.adjustsFontSizeToFitWidth = YES;
            }
            [textArray enumerateObjectsUsingBlock:^(NSMutableString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                RDCaptionLabel *lbl = [[RDCaptionLabel alloc] initWithFrame:CGRectMake(textSource.edgeInsets.left + idx*width, textSource.edgeInsets.top, width, height)];
                lbl.text = obj;
                lbl.textColor = [textSource.textColor colorWithAlphaComponent:textSource.alpha];
                lbl.txtColor = textSource.textColor;
                lbl.textAlignment = (NSTextAlignment)textSource.textAlignment;
                lbl.edgeInsets = textSource.edgeInsets;
                lbl.numberOfLines = obj.length;
                lbl.font = [UIFont fontWithName:textSource.fontName size:fontSize];
                if (textSource.strokeWidth > 0.0) {
                    lbl.strokeWidth = textSource.strokeWidth;
                    lbl.strokeColor = [textSource.strokeColor colorWithAlphaComponent:textSource.strokeAlpha];
                }
                lbl.isBold = textSource.isBold;
                if (textSource.isItalic) {
                    CGAffineTransform matrix = CGAffineTransformMake(1, 0, tanf(15 * (CGFloat)M_PI / 180), 1, 0, 0);//设置倾斜角度。
                    UIFontDescriptor *desc = [UIFontDescriptor fontDescriptorWithName:textSource.fontName matrix:matrix];
                    lbl.font = [UIFont fontWithDescriptor:desc size:fontSize];
                }
                if (textSource.isShadow) {
                    lbl.shadowColor = textSource.shadowColor;
                    lbl.shadowOffset = textSource.shadowOffset;
                }else {
                    lbl.shadowColor = [UIColor clearColor];
                    lbl.shadowOffset = CGSizeMake(0, 0);
                }
                [lbl sizeToFit];
                [label addSubview:lbl];
            }];
            
            UIGraphicsBeginImageContextWithOptions(label.bounds.size, NO, 1.0);
            CGContextRef ctx = UIGraphicsGetCurrentContext();
            [label.layer renderInContext:ctx];
            UIImage* textImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            return textImage;
        }else {
            RDCaptionLabel *label = [[RDCaptionLabel alloc] initWithFrame:CGRectMake(0, 0, textSource.size.width, textSource.size.height)];
            label.backgroundColor = [UIColor clearColor];
            label.text = textSource.text;
            label.textColor = [textSource.textColor colorWithAlphaComponent:textSource.alpha];
            label.txtColor = label.textColor;
            label.textAlignment = (NSTextAlignment)textSource.textAlignment;
            label.edgeInsets = textSource.edgeInsets;
            
            if (fontSize == 0.0) {
                if (textSource.isVerticalText) {
                    label.textAlignment = NSTextAlignmentCenter;
                    NSMutableString * str = [NSMutableString string];
                    lines = 0;
                    [label.text enumerateSubstringsInRange:NSMakeRange(0, label.text.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:
                    ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                        lines++;
                        if (substringRange.location + substringRange.length == label.text.length) {
                            [str insertString:substring atIndex:str.length];
                        }else {
                            [str insertString:[substring stringByAppendingString:@"\n"] atIndex:str.length];
                        }
                    }];
                    label.text = str;
                    for (int i = width; i > 5; i--) {
                        CGSize size_w = [str boundingRectWithSize:CGSizeMake(width, MAXFLOAT)
                                                          options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                       attributes:@{NSFontAttributeName : [UIFont fontWithName:textSource.fontName size:i]}
                                                          context:nil].size;
                        CGSize size_h = [str boundingRectWithSize:CGSizeMake(MAXFLOAT, height)
                                                          options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                       attributes:@{NSFontAttributeName : [UIFont fontWithName:textSource.fontName size:i]}
                                                          context:nil].size;
                        if (size_w.height + textSource.strokeWidth*2.0 <= height && size_h.width + textSource.strokeWidth*2.0 <= width) {
                            fontSize = i;
                            label.font = [UIFont fontWithName:textSource.fontName size:i];
                            break;
                        }
                    }
                }else {
                    for (int i = height/lines; i > 5; i--) {
                        CGSize size_w = [label.text boundingRectWithSize:CGSizeMake(width, MAXFLOAT)
                                                                 options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                              attributes:@{NSFontAttributeName : [UIFont fontWithName:textSource.fontName size:i]} context:nil].size;
                        CGSize size_h = [label.text boundingRectWithSize:CGSizeMake(MAXFLOAT, height)
                                                                 options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                              attributes:@{NSFontAttributeName : [UIFont fontWithName:textSource.fontName size:i]} context:nil].size;
                        if (size_w.height + textSource.strokeWidth*2.0 <= height && size_h.width + textSource.strokeWidth*2.0 <= width) {
                            //                        NSLog(@"******%d: w:%.2f h:%.2f size_w:%@ size_h:%@", i, width, height, NSStringFromCGSize(size_w), NSStringFromCGSize(size_h));
                            fontSize = i;
                            label.font = [UIFont fontWithName:textSource.fontName size:i];
                            break;
                        }
                    }
                }
            }else {
                if (textSource.isVerticalText) {
                    NSMutableString * str = [NSMutableString string];
                    lines = 0;
                    [label.text enumerateSubstringsInRange:NSMakeRange(0, label.text.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:
                    ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                        lines++;
                        if (substringRange.location + substringRange.length == label.text.length) {
                            [str insertString:substring atIndex:str.length];
                        }else {
                            [str insertString:[substring stringByAppendingString:@"\n"] atIndex:str.length];
                        }
                    }];
                    label.text = str;
                }
                if (textSource.fontName.length > 0) {
                    label.font = [UIFont fontWithName:textSource.fontName size:fontSize];
                }else {
                    label.font = [UIFont systemFontOfSize:fontSize];
                }
                label.adjustsFontSizeToFitWidth = YES;
            }
            if (textSource.strokeWidth > 0.0) {
                label.strokeWidth = textSource.strokeWidth;
                label.strokeColor = [textSource.strokeColor colorWithAlphaComponent:textSource.strokeAlpha];
            }
            label.isBold = textSource.isBold;
            if (textSource.isItalic) {
                CGAffineTransform matrix = CGAffineTransformMake(1, 0, tanf(15 * (CGFloat)M_PI / 180), 1, 0, 0);//设置倾斜角度。
                UIFontDescriptor *desc = [UIFontDescriptor fontDescriptorWithName:textSource.fontName matrix:matrix];
                label.font = [UIFont fontWithDescriptor:desc size:fontSize];
            }
            if (textSource.isShadow) {
                label.shadowColor = textSource.shadowColor;
                label.shadowOffset = textSource.shadowOffset;
            }else {
                label.shadowColor = [UIColor clearColor];
                label.shadowOffset = CGSizeMake(0, 0);
            }
            label.numberOfLines = lines;
            
            UIGraphicsBeginImageContextWithOptions(label.bounds.size, NO, 1.0);
            CGContextRef ctx = UIGraphicsGetCurrentContext();
            [label.layer renderInContext:ctx];
            UIImage* textImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            return textImage;
        }
    }
}

- (void)setAETextStartTime:(float)startTime duration:(float)duration identifier:(NSString *)identifier {
    __block int oldInFrame = -1;
    __block int nextInFrame = -1;
    __block int prevInFrame = -1;
    [rdJsonAnimation.textSourceArray enumerateObjectsUsingBlock:^(RDJsonText * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.identifier isEqualToString:identifier]) {
            if (obj.startTime != -1) {
                oldInFrame = obj.startTime * animationView.sceneModel.framerate.intValue;
                if (idx > 0) {
                    RDJsonText *prevText = [rdJsonAnimation.textSourceArray objectAtIndex:idx - 1];
                    if (prevText.startTime != -1) {
                        prevInFrame = prevText.startTime * animationView.sceneModel.framerate.intValue;
                    }
                }
                if (idx != rdJsonAnimation.textSourceArray.count - 1) {
                    RDJsonText *nextText = [rdJsonAnimation.textSourceArray objectAtIndex:idx + 1];
                    if (nextText.startTime != -1) {
                        nextInFrame = nextText.startTime * animationView.sceneModel.framerate.intValue;
                    }
                }
            }
            obj.startTime = startTime;
            obj.duration = duration;
            *stop = YES;
        }
    }];
    int newInFrame = startTime * animationView.sceneModel.framerate.intValue;
    int newOutFrame = newInFrame + duration * animationView.sceneModel.framerate.intValue;
    [animationView refreshOldInFrame:oldInFrame prevInFrame:prevInFrame nextInFrame:nextInFrame newInFrame:newInFrame newOutFrame:newOutFrame];
}

- (void)setAETextContent:(RDJsonText *)contentText {
    NSString *imageFolder = [NSString stringWithFormat:@"%@%@", _animationFolderPath, [animationView.textItems firstObject].directoryName];
    
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:imageFolder]){
        if (![fileManager createDirectoryAtPath:imageFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"创建文件夹失败:%@", error);
            return;
        }
    }
    __weak typeof(self) weakSelf = self;
    [animationView.textItems enumerateObjectsUsingBlock:^(RDLOTAnimatedSourceInfo* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *imageName = obj.name;
        NSString *imagePath = [NSString stringWithFormat:@"%@%@", imageFolder, imageName];
        __block NSError *error = nil;
        if ([fileManager fileExistsAtPath:imagePath]) {
            if (![fileManager removeItemAtPath:imagePath error:&error]) {
                NSLog(@"删除文件失败:%@", error);
            }
        }
        error = nil;
        RDJsonText *jsonText = rdJsonAnimation.textSourceArray[idx];
        if ([jsonText.imagePath.lastPathComponent.stringByDeletingPathExtension isEqualToString:[obj.typeName stringByDeletingPathExtension]])
        {
            UIImage *image = [weakSelf getTextImage:jsonText];
            NSData *data = UIImagePNGRepresentation(image);
            if (![data writeToFile:imagePath atomically:YES]) {
                NSLog(@"写入文件错误：%@", imagePath);
            }
        }
    }];
}

- (UIImage *) getImageFromUrl:(NSURL *)url crop:(CGRect)crop animateImageSize:(CGSize)animateImageSize {
    if (CGRectEqualToRect(crop, CGRectMake(0, 0, 1.0, 1.0))) {
        float imageSizePro = animateImageSize.width/animateImageSize.height;
        __block UIImage* image;
        if([RDRecordHelper isSystemPhotoUrl:url]){
            PHAsset* asset = [[PHAsset fetchAssetsWithALAssetURLs:@[url] options:nil] objectAtIndex:0];
            
            float width;
            CGSize size;
            if (imageSizePro == 1.0) {
                width = MIN(rdJsonAnimation.targetImageMaxSize, MIN(asset.pixelWidth, asset.pixelHeight));
                size = CGSizeMake(width, width);
            }else if (imageSizePro > 1.0) {
                width = MIN(rdJsonAnimation.targetImageMaxSize, asset.pixelWidth);
                size = CGSizeMake(width, width/imageSizePro);
            }else {
                width = MIN(rdJsonAnimation.targetImageMaxSize, asset.pixelHeight);
                size = CGSizeMake(width*imageSizePro, width);
            }
            
            PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
            option.synchronous = YES;
            option.resizeMode = PHImageRequestOptionsResizeModeExact;
            option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            
            [[PHImageManager defaultManager] requestImageForAsset:asset
                                                       targetSize:size
                                                      contentMode:PHImageContentModeAspectFill//PHImageContentModeAspectFit
                                                          options:option
                                                    resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                        image = result;
                                                    }];
        }else {
            UIImage *originalImage = [UIImage imageWithContentsOfFile:url.path];
            originalImage = [RDRecordHelper fixOrientation:originalImage];
            CGSize size = originalImage.size;
            if (MAX(size.width, size.height) > rdJsonAnimation.targetImageMaxSize) {
                if (originalImage.size.width >= originalImage.size.height) {
                    float width = MIN(rdJsonAnimation.targetImageMaxSize, originalImage.size.width);
                    size = CGSizeMake(width, width / (originalImage.size.width / originalImage.size.height));
                }else {
                    float height = MIN(rdJsonAnimation.targetImageMaxSize, originalImage.size.height);
                    size = CGSizeMake(height * (originalImage.size.width / originalImage.size.height), height);
                }
                image = [self resizeImage:originalImage toSize:size];
            }else {
                image = originalImage;
            }
            
            if (imageSizePro != size.width / size.height) {
                float x,y,w,h;
                if (imageSizePro == 1.0) {
                    w = MIN(size.width, size.height);
                    h = w;
                }else if (imageSizePro > 1.0) {
                    w = size.width;
                    h = w/imageSizePro;
                    if (h > size.height) {
                        h = size.height;
                        w = h*imageSizePro;
                    }
                }else {
                    h = size.height;
                    w = h*imageSizePro;
                    if (w > size.width) {
                        w = size.width;
                        h = w / imageSizePro;
                    }
                }
                x = fabs(size.width - w)/2.0;
                y = fabs(size.height - h)/2.0;
                CGRect rect = CGRectMake(x, y, w, h);
                
                CGImageRef sourceImageRef = [image CGImage];
                CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
                image = [UIImage imageWithCGImage:newImageRef];
                CGImageRelease(newImageRef);
            }
        }
        return image;
    }
    __block UIImage* image;
    if([RDRecordHelper isSystemPhotoUrl:url]){
        PHAsset* asset = [[PHAsset fetchAssetsWithALAssetURLs:@[url] options:nil] objectAtIndex:0];
        
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.synchronous = YES;
        option.resizeMode = PHImageRequestOptionsResizeModeExact;
        option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        
        [[PHImageManager defaultManager] requestImageForAsset:asset
                                                   targetSize:CGSizeMake(rdJsonAnimation.targetImageMaxSize, rdJsonAnimation.targetImageMaxSize)
                                                  contentMode:PHImageContentModeAspectFit
                                                      options:option
                                                resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                    CGSize size = result.size;
                                                    CGRect rect = CGRectMake(size.width * crop.origin.x, size.height * crop.origin.y, size.width * crop.size.width, size.height * crop.size.height);
                                                    CGImageRef sourceImageRef = [result CGImage];
                                                    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
                                                    image = [UIImage imageWithCGImage:newImageRef];
                                                    CGImageRelease(newImageRef);
                                                }];
    }else {
        UIImage *originalImage = [UIImage imageWithContentsOfFile:url.path];
        originalImage = [RDRecordHelper fixOrientation:originalImage];
        CGSize size = originalImage.size;
        if (MAX(size.width, size.height) > rdJsonAnimation.targetImageMaxSize) {
            if (originalImage.size.width >= originalImage.size.height) {
                float width = MIN(rdJsonAnimation.targetImageMaxSize, originalImage.size.width);
                size = CGSizeMake(width, width / (originalImage.size.width / originalImage.size.height));
            }else {
                float height = MIN(rdJsonAnimation.targetImageMaxSize, originalImage.size.height);
                size = CGSizeMake(height * (originalImage.size.width / originalImage.size.height), height);
            }
            image = [self resizeImage:originalImage toSize:size];
        }else {
            image = originalImage;
        }
        
        CGRect rect = CGRectMake(size.width * crop.origin.x, size.height * crop.origin.y, size.width * crop.size.width, size.height * crop.size.height);
        CGImageRef sourceImageRef = [image CGImage];
        CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
        image = [UIImage imageWithCGImage:newImageRef];
        CGImageRelease(newImageRef);
    }
    return image;
}

- (void) currentBufferTime:(CMTime)bufferTime {
    if (movieEffects.count == 0) {
        currentBufferTime = bufferTime;
    }
    if ([_delegate respondsToSelector:@selector(progressCurrentTime:customDrawLayer:)]) {
        [_delegate progressCurrentTime:bufferTime customDrawLayer:customDrawLayer];
    }
}

- (void)refreshMVLottieTime:(NSNotification *)notification {
    currentBufferTime = [notification.object CMTimeValue];
}

- (void)changeLayerImage:(CALayer *)layer layerName:(NSString *)layerName {
//    double time_start = CACurrentMediaTime();
#if 0
//    NSLog(@"currentBufferTime:%@ prevBufferTime:%@ layerName:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, isExporting ? CMTimeMake(exportTime*_editor.fps, _editor.fps) : currentBufferTime)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, prevBufferTime)), layerName);
    if (!animationView) {
        return;
    }
    __block RDAEVideoImageInfo *currentImageInfo;
    [animationVideoArray enumerateObjectsUsingBlock:^(RDAEVideoImageInfo*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!animationView) {
            *stop = YES;
        }
        else if ([obj.imageName isEqualToString:layerName]) {
            currentImageInfo = obj;
            *stop = YES;
        }
    }];
    if (!currentImageInfo) {
        return;
    }
    float currentTime;
    if (isExporting) {
        currentTime = exportTime;
    }else {
        currentTime = CMTimeGetSeconds(currentBufferTime);
    }
    CMTime time;
    if (animationView.hasEndImage && currentTime > animationView.imagesDuration) {
        time = CMTimeMake((currentTime - animationView.imagesDuration + CMTimeGetSeconds(currentImageInfo.timeRange.start))*_editor.fps, _editor.fps);
    }else {
        time = CMTimeMake((currentTime - currentImageInfo.startTime + CMTimeGetSeconds(currentImageInfo.timeRange.start))*_editor.fps, _editor.fps);
    }
    layer.contents = nil;
    [animationLayerArray addObject:layer];
    for (int i = 0; i < currentImageInfo.screenshotArray.count; i++) {
        RDAEScreenshotInfo *info = currentImageInfo.screenshotArray[i];
        if (i < currentImageInfo.screenshotArray.count -1) {
            RDAEScreenshotInfo *nextInfo = currentImageInfo.screenshotArray[i + 1];
            if (CMTimeCompare(info.screenshotTime, time) >=0 && CMTimeCompare(time, nextInfo.screenshotTime) <= 0) {
//                NSLog(@"time:%@ %@ %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, time)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, info.screenshotTime)), info);
//                layer.contents = (__bridge id _Nullable)info.screenshot;//iloveu表白宫格会崩？
                layer.contents = (__bridge id _Nullable)info.screenshotImage.CGImage;
                break;
            }
        }else {
//            layer.contents = (__bridge id _Nullable)info.screenshot;
            layer.contents = (__bridge id _Nullable)info.screenshotImage.CGImage;
        }
    }
#else
    @autoreleasepool {
        if (!animationView) {
            return;
        }
//        double time_start1 = CACurrentMediaTime();
        float currentTime;
        if (isExporting) {
            currentTime = exportTime;
        }else {
            currentTime = CMTimeGetSeconds(currentBufferTime);
        }
//        NSLog(@"currentBufferTime:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentBufferTime)));
        int playCount = ceilf(currentTime/(animationView.imagesDuration + animationView.endDuration)) - 1;
        if (playCount < 0) {
            playCount = 0;
        }
        __block RDAEVideoImageInfo *currentImageInfo;
        [animationVideoArray enumerateObjectsUsingBlock:^(RDAEVideoImageInfo*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!animationView) {
                *stop = YES;
            }
            else if ([obj.imageName isEqualToString:layerName] && currentTime >= obj.startTime && currentTime <= obj.startTime + obj.duration) {
//                NSLog(@"idx:%lu currentBufferTime:%@", (unsigned long)idx, CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentBufferTime)));
                currentImageInfo = obj;
                *stop = YES;
            }
        }];
        __block RDAEVideoImageInfo *currentGifInfo;
        [animationGifArray enumerateObjectsUsingBlock:^(RDAEVideoImageInfo*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!animationView) {
                *stop = YES;
            }
            else if ([obj.imageName isEqualToString:layerName] && currentTime >= obj.startTime && currentTime <= obj.startTime + obj.duration) {
                currentGifInfo = obj;
                *stop = YES;
            }
        }];
        if (!currentImageInfo && animationPlayCount == 1 && !currentGifInfo) {
            return;
        }
//        NSLog(@"currentBufferTime:%@ prevBufferTime:%@ layerName:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, isExporting ? CMTimeMake(exportTime*_editor.fps, _editor.fps) : currentBufferTime)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, prevBufferTime)), layerName);
        [animationLayerArray addObject:layer];
        if (currentImageInfo) {
            layer.contents = nil;
            if (isExporting && [prevAnimationImageName isEqualToString:layerName]
                && (CMTimeCompare(prevBufferTime, CMTimeMake(exportTime*_editor.fps, _editor.fps)) == 0
                    || exportTime + 3/(float)_editor.fps >= _videoDuration)) {//20190909 导出时，已经导出结束了，就不能再截图了，否则会导致[assetWriterVideoInput markAsFinished]时卡住
                layer.contents = (__bridge id _Nullable)(prevAnimationImage.CGImage);
//                NSLog(@"prevBufferTime:%@ exportTime:%f _videoDuration:%f", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, prevBufferTime)), exportTime, _videoDuration);
            }
            else if (!isExporting && CMTimeCompare(prevBufferTime, kCMTimeInvalid) != 0 && CMTimeCompare(prevBufferTime, currentBufferTime) == 0 && [prevAnimationImageName isEqualToString:layerName]) {
//                NSLog(@"????????");
                layer.contents = (__bridge id _Nullable)(prevAnimationImage.CGImage);
            }
            else {
                float animationTime;
                if (animationView.hasEndImage && currentTime > animationView.imagesDuration) {
                    animationTime = currentTime - animationView.imagesDuration + CMTimeGetSeconds(currentImageInfo.timeRange.start);
                }else {
                    animationTime = currentTime - currentImageInfo.startTime + CMTimeGetSeconds(currentImageInfo.timeRange.start);
                }
//                NSLog(@"changeLayer 耗时1：%lf",CACurrentMediaTime() - time_start1);
                if (CMTimeCompare(CMTimeMakeWithSeconds(animationTime, TIMESCALE), currentImageInfo.actualTimeRange.duration) == 1) {
//                    NSLog(@"ScreenshotTime:%f prevBufferTime:%@", animationTime, CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, prevBufferTime)));
                    prevAnimationImageName = layerName;
                    if (isExporting) {
                        prevBufferTime = CMTimeMake(exportTime*_editor.fps, _editor.fps);
                    }else {
                        prevBufferTime = currentBufferTime;
                    }
                    if (animationView.layer.superlayer || movieEffects.count > 0) {
                        layer.contents = (__bridge id _Nullable)(prevAnimationImage.CGImage);
                    }
                }else {
                    prevAnimationImage = nil;
                    UIImage *image = [self getScreenshotFromVideoURL:currentImageInfo.url atTime:CMTimeMakeWithSeconds(animationTime, TIMESCALE) crop:currentImageInfo.crop imageSize:currentImageInfo.size];
                    if(image) {
                        if (currentImageInfo.filterType != VVAssetFilterEmpty) {
                            RDFilter* filter = [RDFilter new];
                            if (currentImageInfo.filterType == VVAssetFilterACV) {
                                filter.type = kRDFilterType_ACV;
                            }else {
                                filter.type = kRDFilterType_LookUp;
                            }
                            filter.filterPath = currentImageInfo.filterUrl.path;
                            image = [RDVECore getFilteredImage:image filter:filter];
                        }
                        prevAnimationImage = image;
                    }
                    prevAnimationImageName = layerName;
                    if (isExporting) {
                        prevBufferTime = CMTimeMake(exportTime*_editor.fps, _editor.fps);
                    }else {
                        prevBufferTime = currentBufferTime;
                    }
                    
                    if (animationView.layer.superlayer || movieEffects.count > 0) {
                        layer.contents = (__bridge id _Nullable)(image.CGImage);
                    }
                }
            }
        }else if (rdJsonAnimation.isRepeat && !currentGifInfo) {
            __block RDLOTAnimatedSourceInfo *sourceInfo;
            __block BOOL isBackground = NO;
            [animationImageArray enumerateObjectsUsingBlock:^(RDLOTAnimatedSourceInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.name isEqualToString:layerName]) {
                    if (obj.directoryName.length > 0) {
                        if ([obj.typeName rangeOfString:@"end" options:NSCaseInsensitiveSearch].location == NSNotFound) {//不可替换图片
                            isBackground = YES;
                        }else {
                            sourceInfo = obj;
                        }
                    }
                    *stop = YES;
                }
            }];
            if (sourceInfo) {
                NSString *imagePath;
                if (playCount == 0) {
                    imagePath = [NSString stringWithFormat:@"%@%@", imageFolder, layerName];
                }else {
                    imagePath = [NSString stringWithFormat:@"%@%@/%@%d.%@", imageFolder, kAnimationRepeatFolder, [layerName stringByDeletingPathExtension], playCount, layerName.pathExtension];
                }
                UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
                layer.contents = nil;
                if (image) {
                    layer.contents = (__bridge id _Nullable)(image.CGImage);
                }
            }else if (!isBackground) {
                layer.contents = nil;
            }
        }else if (currentGifInfo) {
            layer.contents = nil;
            CMTime time;
            if (animationView.hasEndImage && currentTime > animationView.imagesDuration) {
                time = CMTimeMake((currentTime - animationView.imagesDuration + CMTimeGetSeconds(currentGifInfo.timeRange.start))*_editor.fps, _editor.fps);
            }else {
                time = CMTimeMake((currentTime - currentGifInfo.startTime + CMTimeGetSeconds(currentGifInfo.timeRange.start))*_editor.fps, _editor.fps);
            }
            float animationTime = CMTimeGetSeconds(time);
            if (animationTime > currentGifInfo.gifImage.duration) {
                if (animationView.layer.superlayer || movieEffects.count > 0) {
                    layer.contents = (__bridge id _Nullable)([currentGifInfo.gifImage.images lastObject].CGImage);
                }
            }else if (animationView.layer.superlayer || movieEffects.count > 0) {
                [currentGifInfo.gifDurationArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    float duration = [obj floatValue];
                    if (duration >= animationTime) {
                        layer.contents = (__bridge id _Nullable)([currentGifInfo.gifImage.images objectAtIndex:idx].CGImage);
                        *stop = YES;
                    }
                }];
            }
        }
    }
#endif
//    NSLog(@"changeLayer 耗时3：%lf",CACurrentMediaTime() - time_start);
}

+ (UIImage *)getFilteredImage:(UIImage *)inputImage filter:(RDFilter *)filter
{
    RDGPUImagePicture *stillImageSource = [[RDGPUImagePicture alloc] initWithImage:inputImage];
    
    RDGPUImageOutput<RDGPUImageInput> *stillImageFilter;
    if (filter.type == kRDFilterType_HeiBai) {
        stillImageFilter = [[RDGPUImageGrayscaleFilter alloc] init];
    }else if (filter.type == kRDFilterType_SLBP){
        stillImageFilter = [[RDRecordGPUImageThresholdedNonMaximumSuppressionFilter alloc] initWithPackedColorspace:YES];
        ((RDRecordGPUImageThresholdedNonMaximumSuppressionFilter*)filter).threshold = 0.01;
    }
    else if (filter.type == kRDFilterType_Sketch){
        stillImageFilter = [[RDRecordGPUImageSketchFilter alloc] init];
    }
    else if (filter.type == kRDFilterType_DistortingMirror){
        stillImageFilter = [[RDRecordGPUImageStretchDistortionFilter alloc] init];
    }
    else if (filter.type == kRDFilterType_LookUp){
        stillImageFilter = [[RDLookupFilter alloc] initWithImagePath:filter.filterPath intensity:filter.intensity];
    }
    else{
        stillImageFilter =[[RDGPUImageToneCurveFilter alloc] initWithACVData:[NSData dataWithContentsOfFile:filter.filterPath]];
    }
    [stillImageSource addTarget:stillImageFilter];
    [stillImageFilter useNextFrameForImageCapture];
    [stillImageSource processImage];
    
    UIImage*image = [stillImageFilter imageFromCurrentFramebuffer];

    return image;
}

- (void)getAnimationScreenshotFromVideoInfo:(RDAEVideoImageInfo *)info {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *timeArray = [NSMutableArray array];
        for (int i = 0; i < info.duration*rdJsonAnimation.exportFps; i+=3) {
            [timeArray addObject:[NSValue valueWithCMTime:CMTimeMake(i, rdJsonAnimation.exportFps)]];
        }
        AVURLAsset *asset = [AVURLAsset assetWithURL:info.url];
        AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        gen.appliesPreferredTrackTransform = YES;
        //如果需要精确时间
        gen.requestedTimeToleranceAfter = kCMTimeZero;
        gen.requestedTimeToleranceBefore = kCMTimeZero;
        gen.maximumSize = CGSizeMake(rdJsonAnimation.targetImageMaxSize, rdJsonAnimation.targetImageMaxSize);
        gen.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
        double time = CACurrentMediaTime();
        [gen generateCGImagesAsynchronouslyForTimes:timeArray
                                  completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
                                      if (image) {
                                          @autoreleasepool {
                                              CGFloat imageWidth = CGImageGetWidth(image);
                                              CGFloat imageHeight = CGImageGetHeight(image);
                                              float imagePro = imageWidth/imageHeight;
                                              float animationPro = info.size.width/info.size.height;
                                              CGImageRef newImageRef;
                                              if (imagePro != animationPro) {
                                                  CGRect rect;
                                                  if (CGRectEqualToRect(info.crop, CGRectMake(0, 0, 1.0, 1.0))) {
                                                      CGFloat width;
                                                      CGFloat height;
                                                      if (imageWidth*info.size.height <= imageHeight*info.size.width) {
                                                          width  = imageWidth;
                                                          height = imageWidth * info.size.height / info.size.width;
                                                      }else {
                                                          width  = imageHeight * info.size.width / info.size.height;
                                                          height = imageHeight;
                                                      }
                                                      rect = CGRectMake((imageWidth - width)/2.0, (imageHeight - height)/2.0, width, height);
                                                  }else {
                                                      rect = CGRectMake(imageWidth * info.crop.origin.x, imageHeight * info.crop.origin.y, imageWidth * info.crop.size.width, imageHeight * info.crop.size.height);
                                                  }
                                                  newImageRef = CGImageCreateWithImageInRect(image, rect);
                                              }else {
                                                  if (CGRectEqualToRect(info.crop, CGRectMake(0, 0, 1.0, 1.0))) {
                                                      newImageRef = image;
                                                  }else {
                                                      CGRect rect = CGRectMake(imageWidth * info.crop.origin.x, imageHeight * info.crop.origin.y, imageWidth * info.crop.size.width, imageHeight * info.crop.size.height);
                                                      newImageRef = CGImageCreateWithImageInRect(image, rect);
                                                  }
                                              }
                                              UIImage *shotImage = [UIImage imageWithCGImage:newImageRef];
                                              CGImageRelease(newImageRef);
                                              RDAEScreenshotInfo *screenshotInfo = [[RDAEScreenshotInfo alloc] init];
                                              screenshotInfo.screenshotTime = requestedTime;
                                              screenshotInfo.screenshotImage = shotImage;
                                              [info.screenshotArray addObject:screenshotInfo];
//                                              NSLog(@"requestedTime:%@ actualTime:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, requestedTime)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, actualTime)));
                                              if (CMTimeCompare(requestedTime, [[timeArray lastObject] CMTimeValue]) >= 0) {
                                                  NSLog(@"截图耗时：%f", CACurrentMediaTime() - time);
                                              }
                                          }
                                      }
                                  }];
    });
}
#if 0
- (UIImage *)getScreenshotFromVideoURL:(NSURL *)fileURL atTime:(CMTime)time crop:(CGRect)crop imageSize:(CGSize)imageSize
{
    @autoreleasepool {
        
        
        double startTime = CACurrentMediaTime();
        UIImage *shotImage;
        //        NSLog(@"ScreenshotTime:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, time)));
        AVURLAsset *asset = [AVURLAsset assetWithURL:fileURL];
        AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        gen.appliesPreferredTrackTransform = YES;
        //如果需要精确时间
        gen.requestedTimeToleranceAfter = kCMTimeZero;
        gen.requestedTimeToleranceBefore = kCMTimeZero;
        gen.maximumSize = CGSizeMake(1080, 1080);
        gen.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
        
        NSError *error = nil;
        CGImageRef image = [gen copyCGImageAtTime:time actualTime:nil error:&error];
        [gen cancelAllCGImageGeneration];
        gen = nil;
        asset = nil;
        
        if(error){
            NSLog(@"error:%@",error);
            error = nil;
        }
        CGFloat imageWidth = CGImageGetWidth(image);
        CGFloat imageHeight = CGImageGetHeight(image);
        float imagePro = imageWidth/imageHeight;
        float animationPro = imageSize.width/imageSize.height;
        
        if (imagePro != animationPro) {
            CGRect rect;
            if (CGRectEqualToRect(crop, CGRectMake(0, 0, 1.0, 1.0))) {
                CGFloat width;
                CGFloat height;
                if (imageWidth*imageSize.height <= imageHeight*imageSize.width) {
                    width  = imageWidth;
                    height = imageWidth * imageSize.height / imageSize.width;
                }else {
                    width  = imageHeight * imageSize.width / imageSize.height;
                    height = imageHeight;
                }
                rect = CGRectMake((imageWidth - width)/2.0, (imageHeight - height)/2.0, width, height);
            }else {
                rect = CGRectMake(imageWidth * crop.origin.x, imageHeight * crop.origin.y, imageWidth * crop.size.width, imageHeight * crop.size.height);
            }
            CGImageRef newImageRef = CGImageCreateWithImageInRect(image, rect);
            shotImage = [UIImage imageWithCGImage:newImageRef];
            CGImageRelease(newImageRef);
        }else {
            if (CGRectEqualToRect(crop, CGRectMake(0, 0, 1.0, 1.0))) {
                shotImage = [UIImage imageWithCGImage:image];
            }else {
                CGRect rect = CGRectMake(imageWidth * crop.origin.x, imageHeight * crop.origin.y, imageWidth * crop.size.width, imageHeight * crop.size.height);
                CGImageRef newImageRef = CGImageCreateWithImageInRect(image, rect);
                shotImage = [UIImage imageWithCGImage:newImageRef];
                CGImageRelease(newImageRef);
            }
        }
        CGImageRelease(image);
        
        NSLog(@"截图 耗时2222:%lf  time:%.05f",CACurrentMediaTime() - startTime,CMTimeGetSeconds(time));
        return shotImage;
        
    }
}
#else

- (UIImage* )getScreenshotFromVideoURL:(NSURL *)fileURL atTime:(CMTime)time crop:(CGRect)crop imageSize:(CGSize)imageSize {
    @autoreleasepool {
    
//        NSLog(@"getScreenshotFromVideoURL in");
        
//        double startTime = CACurrentMediaTime();
//        NSLog(@"ScreenshotTime:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, time)));
//        double time_start = CACurrentMediaTime();
        
        if(!getScreenshotFinish)
            return nil;
        RDAEVideoComposition* videoComposition = nil;
        CMTime currentSampleTime;
        Float64 currentTime = 0;
        CMSampleBufferRef sample = nil ;
        NSMutableArray *samples = [[NSMutableArray alloc] init];
        Float64 screenshotTime = (float)((int)(CMTimeGetSeconds(time)*1000))/1000.0;//保留三位有效数字，计算精确度
//        NSLog(@"screenshotTime:%@ screenshotTime:%f  fileURL:%@",CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, time)),screenshotTime,fileURL);
        
        
        for(int j = 0; j < compositionArray.count; j++)
        {
            RDAEVideoComposition *composition = [compositionArray objectAtIndex:j];
            if (fileURL == composition.url ) {
                
                if(composition.reverseReader.status != AVAssetReaderStatusReading){
                    [self createReverseReaderWithPixelFormat32BGRA:composition timeRange:CMTimeRangeMake(time,kCMTimePositiveInfinity)];

                    Float64 lastFrameTime = CMTimeGetSeconds(composition.timeRange.start) + CMTimeGetSeconds(composition.timeRange.duration);
                    lastFrameTime = (float)((int)(lastFrameTime*1000))/1000.0;//保留三位有效数字，计算精确度
//                    NSLog(@"start:%f duration:%f lastFrameTime:%f ",CMTimeGetSeconds(composition.timeRange.start),CMTimeGetSeconds(composition.timeRange.duration),lastFrameTime);
                 
                    //设置文件解码的开始时间，类似seek操作 ,优化AE模版 1080p 视频播放卡顿问题
                    if(screenshotTime  >= lastFrameTime)
                    {
                        //部分视频最后一帧黑屏
                        composition.reverseReader.timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(lastFrameTime - 1.0/(float)_editor.fps, _editor.fps),kCMTimePositiveInfinity);
                        screenshotTime = lastFrameTime - 1.0/_editor.fps;
                    }
                    else
                        composition.reverseReader.timeRange = CMTimeRangeMake(time,kCMTimePositiveInfinity);
                    [composition.reverseReader startReading];
                    videoComposition = composition;
                }
                else
                    videoComposition = composition;
            }
            else
            {
                // 不用的reader 应该及时关闭，优化AE模版 iphone6+ 同时添加多个 1080p 视频崩溃问题
                @try {
//                    [composition.reverseReader cancelReading];
                    composition.reverseReader = nil;
                } @catch (NSException *exception) {
                    NSLog(@"exception: %@",exception);
                }
            }
        }
        
        if(!videoComposition)
        {
            NSLog(@"error : do not find video videoComposition");
            return nil;
        }
        
//        NSLog(@"createReverseReaderWithPixelFormat32BGRA耗时：%lf",CACurrentMediaTime() - time_start);
//        time_start = CACurrentMediaTime();

        while(videoComposition.reverseReader.status == AVAssetReaderStatusReading ) {
            
            if(exportMovie && [exportMovie videoEncodingIsFinished]) {
                videoComposition.reverseReader = nil;
                return nil;
            }
            if(!getScreenshotFinish) {
                videoComposition.reverseReader = nil;
                return nil;
            }
            
            if(exportMovie)
                exportMovie.videoCopyNextSampleBufferFinish = FALSE;
            
            videoComposition.videoCopyNextSampleBufferFinish = FALSE;
            sample = [videoComposition.readerOutput copyNextSampleBuffer];
            videoComposition.videoCopyNextSampleBufferFinish = TRUE;
            
            if(exportMovie)
                exportMovie.videoCopyNextSampleBufferFinish = TRUE;
            
            currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sample);
            currentTime = (float)((int)(CMTimeGetSeconds(currentSampleTime)*1000))/1000.0; //保留三位有效数字，计算精确度
            
//            NSLog(@"screenshotTime:%@ currentTime:%@ time_start:%.05f time_duration:%.05f",CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, time)),CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentSampleTime)),CMTimeGetSeconds(videoComposition.timeRange.start),CMTimeGetSeconds(videoComposition.timeRange.duration));
            if(screenshotTime < 0)
                screenshotTime = videoComposition.oldSampleFrameTime;
            
            if ((currentTime - screenshotTime > 1.0/_editor.fps*2 && screenshotTime!= 0)  || !sample) {//seek 或者 播放到文件末尾

                @try {
                    videoComposition.reverseReader = nil;
                } @catch (NSException *exception) {
                    NSLog(@"exception: %@",exception);
                }

                [self createReverseReaderWithPixelFormat32BGRA:videoComposition timeRange:videoComposition.timeRange];
                [videoComposition.reverseReader startReading];
                if(sample){
                    CFRelease(sample);
                    sample = nil;
                }
                continue;
            }
            if (currentTime >= screenshotTime || fabs(currentTime - screenshotTime)<= 1.0/_editor.fps) { //播放到文件末尾，最后一帧时间无限接近截图时间
//                NSLog(@"反转截图:sample: %f screenshotTime：%f",currentTime, screenshotTime);
                
                [samples addObject:(__bridge id)sample];
                CFRelease(sample);
                sample = nil;
                
                videoComposition.oldSampleFrameTime = currentTime;
                videoComposition.reverseReader = nil;
                break;
            }
            if(sample){
                CFRelease(sample);
                sample = nil;
            }
        }
//       NSLog(@"copyNextSampleBuffer解码耗时：%lf",CACurrentMediaTime() - time_start);
//        time_start = CACurrentMediaTime();
        
        UIImage* image = nil;
        if(samples.count)
        {
            // take the image/pixel buffer from tail end of the array
            CVPixelBufferRef imageBufferRef = CMSampleBufferGetImageBuffer((__bridge CMSampleBufferRef)samples[0]);
            image = [RDRecordHelper imageFromSampleBuffer:imageBufferRef crop:crop imageSize:imageSize rotation:videoComposition.imageOrientation];
            
            [samples removeAllObjects];
            samples = nil;
        }
        else
        {
            NSLog(@"samples.count is zero");
        }
//        NSLog(@"截图 耗时:%lf",CACurrentMediaTime() - time_start);
//        NSLog(@"getScreenshotFromVideoURL out耗时:%lf",CACurrentMediaTime() - startTime);
        return image;
    }
}
    
#endif

- (UIImage *)getLottieImage {
    @autoreleasepool {
        UIGraphicsBeginImageContextWithOptions(animationView.bounds.size, YES, 0);
        [animationView.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return snapshotImage;
    }
}

- (void)setFillMode:(RDViewFillMode)fillMode {
    _fillMode = fillMode;
    _preview.fillMode = (RDGPUImageFillModeType)fillMode;
}

- (UIView *)auxViewWithCGRect:(CGRect)rect{
    if (!_preview1) {
        _preview1 = [[RDGPUImageView alloc] init];
        _preview1.backgroundColor = [UIColor clearColor];
        _preview1.userInteractionEnabled = YES;
        [bridgeFilter addTarget:_preview1];
    }
    _preview1.frame = rect;
    return (UIView*)_preview1;
}

- (CALayer* ) computeLayerToImage:(NSMutableArray<RDCaption*>*)captions withCurrentTime:(CMTime) currentTime videoSize:(CGSize) videoSize
{
    
    //currentLayer.bounds = suplayer.bounds;
    //currentLayer.position = CGPointMake(suplayer.bounds.size.width/2.0, suplayer.bounds.size.height/2.0);
    
    if (!currentLayer) {
        currentLayer = [CALayer layer];
        currentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
        currentLayer.backgroundColor = [UIColor clearColor].CGColor;//clear;
        currentLayer.masksToBounds = YES;
        CATransform3D t = currentLayer.transform;
        t = CATransform3DScale(t, 1, -1, 1);
        
        currentLayer.transform = t;
    }
    
    [currentLayer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)]; //每一帧重绘
    
    @autoreleasepool {
        float current = CMTimeGetSeconds(currentTime);
        for (int i = 0;i<captions.count ;i++) {
            RDCaption* ppCaption = captions[i];            
            CMTimeRange range = ppCaption.timeRange;
            
            float start = CMTimeGetSeconds(range.start);
            float end = CMTimeGetSeconds(range.start) + CMTimeGetSeconds(range.duration);
//            NSLog(@"字幕-->%d :%f %f %f %@",i,start,current,end, ppCaption.pText);
            if (current >= start && current <= end) {
                //NSLog(@"字幕-->%d :%f %f %f",i,start,current,end);
                RDCaptionLayer* captionLayer = [captionLayerArray objectAtIndex:i];
//                [captionLayer refresh];
                if (ppCaption.animate.count > 0) {
                    RDCaptionCustomAnimate *fromPosition;
                    RDCaptionCustomAnimate *toPosition;
                    BOOL hasAnimate = NO;
                    for (int j = 0; j < ppCaption.animate.count; j++) {
                        
                        RDCaptionCustomAnimate* _from = ppCaption.animate[j];
                        RDCaptionCustomAnimate* _to;
                        if (j == ppCaption.animate.count - 1) {
                            _to = ppCaption.animate[j];
                        }else {
                            _to = ppCaption.animate[j+1];
                        }
                        
                        //保留三位有效数字，计算精确度
                        int nTimeFrom = (int)((_from.atTime + start)*1000) ;
                        int nTimeTo = (int)((_to.atTime  + start)*1000) ;
                        BOOL isEachFrame = (fabs(1000.0/_editor.fps - abs(nTimeTo - nTimeFrom))<10) ? YES : NO;//是否每帧都有动画
                        int nCurrent =(int)(current*1000);
                        
                        if ((isEachFrame && abs(nCurrent - nTimeFrom)<50) ||(!isEachFrame && nTimeFrom <= nCurrent && nCurrent <= nTimeTo)) {
//                           NSLog(@"---> i:%d timeFrome:%d timeTo:%d currentTime:%d ",i,nTimeFrom,nTimeTo,nCurrent);
                            fromPosition = _from;
                            toPosition = _to;
                            hasAnimate = YES;
                            
//                            NSLog(@"---> count:%zd i:%d j:%d frome:%f to:%f   fTime:%d tTime:%d cTime:%d ",ppCaption.animate.count,i,j,fromPosition.fillScale,toPosition.fillScale,nTimeFrom,nTimeTo,nCurrent);
                            break;
                        }
                    }
                    if (hasAnimate) {
                        float factor = (toPosition.atTime - fromPosition.atTime)>0.0?(current - start - fromPosition.atTime) / (toPosition.atTime - fromPosition.atTime) : 0.0;
                        factor = factor > 1.0 ? 1.0 : factor;
                        float actionRotate = fromPosition.rotate + (toPosition.rotate - fromPosition.rotate)*factor + ppCaption.angle;
                        float opacity =  fromPosition.opacity + (toPosition.opacity - fromPosition.opacity) * factor;
                        float factorScale = fromPosition.scale + (toPosition.scale - fromPosition.scale) * factor;
                        
                        CGRect rect = [self CGRectMixed:fromPosition b:toPosition value:factor type:fromPosition.type];
                        //                        captionLayer.layer.frame = rect;
                        [captionLayer refreshFrame:rect];
                        
                        CATransform3D t1 = CATransform3DScale(CATransform3DIdentity, ppCaption.scale, -ppCaption.scale, 1);
                        t1 = CATransform3DRotate(t1, D2R(-actionRotate), 0, 0, 1);
                        t1 = CATransform3DScale(t1, factorScale, factorScale, 1.0);
                        captionLayer.layer.transform = t1;
                        captionLayer.layer.opacity = opacity;
//                        captionLayer.captionAlphaValue = opacity;
//                        captionLayer.pasterAlphaValue = opacity;
//                        NSLog(@"time:%f rotate:%f pointion:%@ opacity:%f scale:%f", current, actionRotate, NSStringFromCGPoint(position), opacity, factorScale);
                    }
                }else {
                    //图片淡入淡出
                    if (ppCaption.imageAnimate.isFade
                        || ppCaption.imageAnimate.type == RDCaptionAnimateTypeFadeInOut
                        || ppCaption.imageAnimate.inType == RDCaptionAnimateTypeFadeInOut
                        || ppCaption.imageAnimate.outType == RDCaptionAnimateTypeFadeInOut)
                    {
                        float inDuration = ppCaption.imageAnimate.fadeInDuration;
                        float outDuration = ppCaption.imageAnimate.fadeOutDuration;
                        if (inDuration + outDuration > CMTimeGetSeconds(range.duration)) {
                            if (outDuration > 0 && inDuration > 0) {
                                inDuration = CMTimeGetSeconds(range.duration)/2.0;
                                outDuration = CMTimeGetSeconds(range.duration)/2.0;
                            }else if (inDuration > 0) {
                                inDuration = CMTimeGetSeconds(range.duration);
                            }else {
                                outDuration = CMTimeGetSeconds(range.duration);
                            }
                        }
                        if (ppCaption.imageAnimate.isFade
                        || ppCaption.imageAnimate.type == RDCaptionAnimateTypeFadeInOut
                        || (ppCaption.imageAnimate.inType == RDCaptionAnimateTypeFadeInOut
                        && ppCaption.imageAnimate.outType == RDCaptionAnimateTypeFadeInOut)) {
                            if (current - start <= inDuration) {
                                captionLayer.pasterAlphaValue = (current - start) / inDuration * ppCaption.opacity;
                            }else if (current + outDuration > end){
                                captionLayer.pasterAlphaValue =  (end - current) / outDuration * ppCaption.opacity;
                            }else{
                                captionLayer.pasterAlphaValue =  ppCaption.opacity;
                            }
                        }else if (ppCaption.imageAnimate.inType == RDCaptionAnimateTypeFadeInOut) {
                            if (current - start <= inDuration) {
                                captionLayer.pasterAlphaValue = (current - start) / inDuration * ppCaption.opacity;
                            }else{
                                captionLayer.pasterAlphaValue =  ppCaption.opacity;
                            }
                        }else {
                            if (current + outDuration > end){
                                captionLayer.pasterAlphaValue =  (end - current) / outDuration * ppCaption.opacity;
                            }else{
                                captionLayer.pasterAlphaValue =  ppCaption.opacity;
                            }
                        }
                    }
                    //文字淡入淡出
                    if (ppCaption.textAnimate.isFade
                    || ppCaption.textAnimate.type == RDCaptionAnimateTypeFadeInOut
                    || ppCaption.textAnimate.inType == RDCaptionAnimateTypeFadeInOut
                    || ppCaption.textAnimate.outType == RDCaptionAnimateTypeFadeInOut)
                    {
                        float inDuration = ppCaption.textAnimate.fadeInDuration;
                        float outDuration = ppCaption.textAnimate.fadeOutDuration;
                        if (inDuration + outDuration > CMTimeGetSeconds(range.duration)) {
                            if (outDuration > 0 && inDuration > 0) {
                                inDuration = CMTimeGetSeconds(range.duration)/2.0;
                                outDuration = CMTimeGetSeconds(range.duration)/2.0;
                            }else if (inDuration > 0) {
                                inDuration = CMTimeGetSeconds(range.duration);
                            }else {
                                outDuration = CMTimeGetSeconds(range.duration);
                            }
                        }
                        if (ppCaption.textAnimate.isFade
                        || ppCaption.textAnimate.type == RDCaptionAnimateTypeFadeInOut
                        || (ppCaption.textAnimate.inType == RDCaptionAnimateTypeFadeInOut
                        && ppCaption.textAnimate.outType == RDCaptionAnimateTypeFadeInOut)) {
                            if (current - start <= inDuration) {
                                captionLayer.captionAlphaValue = ppCaption.textAlpha *( (current - start) / inDuration) * ppCaption.opacity;
                            }else if (current + outDuration > end){
                                captionLayer.captionAlphaValue = ppCaption.textAlpha * ((end - current) / outDuration) * ppCaption.opacity;
                            }else{
                                captionLayer.captionAlphaValue = ppCaption.textAlpha * ppCaption.opacity;
                            }
                        }else if (ppCaption.textAnimate.inType == RDCaptionAnimateTypeFadeInOut) {
                            if (current - start <= inDuration) {
                                captionLayer.captionAlphaValue = ppCaption.textAlpha *( (current - start) / inDuration) * ppCaption.opacity;
                            }else{
                                captionLayer.captionAlphaValue = ppCaption.textAlpha * ppCaption.opacity;
                            }
                        }else {
                            if (current + outDuration > end){
                                captionLayer.captionAlphaValue = ppCaption.textAlpha * ((end - current) / outDuration) * ppCaption.opacity;
                            }else{
                                captionLayer.captionAlphaValue = ppCaption.textAlpha * ppCaption.opacity;
                            }
                        }
                    }
                    //文字滚动
                    if (ppCaption.textAnimate.type == RDCaptionAnimateTypeScrollInOut
                        || ppCaption.textAnimate.inType == RDCaptionAnimateTypeScrollInOut
                        || ppCaption.textAnimate.outType == RDCaptionAnimateTypeScrollInOut)
                    {
                        float inDuration = ppCaption.textAnimate.inDuration;
                        float outDuration = ppCaption.textAnimate.outDuration;
                        if (inDuration + outDuration > CMTimeGetSeconds(range.duration)) {
                            if (outDuration > 0 && inDuration > 0) {
                                inDuration = CMTimeGetSeconds(range.duration)/2.0;
                                outDuration = CMTimeGetSeconds(range.duration)/2.0;
                            }else if (inDuration > 0) {
                                inDuration = CMTimeGetSeconds(range.duration);
                            }else {
                                outDuration = CMTimeGetSeconds(range.duration);
                            }
                        }
                        if (ppCaption.textAnimate.type == RDCaptionAnimateTypeScrollInOut
                            || (ppCaption.textAnimate.inType == RDCaptionAnimateTypeScrollInOut
                            && ppCaption.textAnimate.outType == RDCaptionAnimateTypeScrollInOut))
                        {
                            if (current - start <= inDuration) {
                                captionLayer.captionWidthProportion =  (current - start) / inDuration;
                            }else if (current + outDuration > end){
                                captionLayer.captionWidthProportion =  (end - current) / outDuration;
                            }else{
                                captionLayer.captionWidthProportion = 1.0;
                            }
                        }else if (ppCaption.textAnimate.inType == RDCaptionAnimateTypeScrollInOut) {
                            if (current - start <= inDuration) {
                                captionLayer.captionWidthProportion =  (current - start) / inDuration;
                            }else{
                                captionLayer.captionWidthProportion = 1.0;
                            }
                        }else {
                            if (current + outDuration > end){
                                captionLayer.captionWidthProportion =  (end - current) / outDuration;
                            }else{
                                captionLayer.captionWidthProportion = 1.0;
                            }
                        }
                    }
                    //文字放大
                    if (ppCaption.textAnimate.type == RDCaptionAnimateTypeScaleInOut
                        || (ppCaption.textAnimate.inType == RDCaptionAnimateTypeScaleInOut
                        && ppCaption.textAnimate.outType == RDCaptionAnimateTypeScaleInOut))
                    {
                        float inDuration = ppCaption.textAnimate.inDuration;
                        float outDuration = ppCaption.textAnimate.outDuration;
                        if (inDuration + outDuration > CMTimeGetSeconds(range.duration)) {
                            if (outDuration > 0 && inDuration > 0) {
                                inDuration = CMTimeGetSeconds(range.duration)/2.0;
                                outDuration = CMTimeGetSeconds(range.duration)/2.0;
                            }else if (inDuration > 0) {
                                inDuration = CMTimeGetSeconds(range.duration);
                            }else {
                                outDuration = CMTimeGetSeconds(range.duration);
                            }
                        }
                        CATransform3D t1 = captionLayer.captionTransform;
                        if (current - start <= inDuration) {
                            float scaleIn = ppCaption.textAnimate.scaleIn;
                            float scale = scaleIn  - (scaleIn - ppCaption.textAnimate.scaleOut) * ((current - start) / inDuration);
                            
                            t1 = CATransform3DScale(t1,  scale, scale, 1.0);
                            
                            captionLayer.captionTransform =  t1;
                        }else if (current + outDuration > end){
                            float scaleOut = ppCaption.textAnimate.scaleOut;
                            float scale = scaleOut  - (scaleOut - ppCaption.textAnimate.scaleIn) * (1.0 - (end - current) / outDuration);
                            t1 = CATransform3DScale(t1, scale, scale, 1.0);
                            captionLayer.captionTransform =  t1;
                        }
                    }else if (ppCaption.textAnimate.inType == RDCaptionAnimateTypeScaleInOut
                              || ppCaption.textAnimate.outType == RDCaptionAnimateTypeScaleInOut
                              || ppCaption.textAnimate.inType == RDCaptionAnimateTypeMove
                              || ppCaption.textAnimate.outType == RDCaptionAnimateTypeMove)
                    {
                        float inDuration = ppCaption.textAnimate.inDuration;
                        float outDuration = ppCaption.textAnimate.outDuration;
                        if (inDuration + outDuration > CMTimeGetSeconds(range.duration)) {
                            if (outDuration > 0 && inDuration > 0) {
                                inDuration = CMTimeGetSeconds(range.duration)/2.0;
                                outDuration = CMTimeGetSeconds(range.duration)/2.0;
                            }else if (inDuration > 0) {
                                inDuration = CMTimeGetSeconds(range.duration);
                            }else {
                                outDuration = CMTimeGetSeconds(range.duration);
                            }
                        }
                        CGPoint pushInPoint = ppCaption.textAnimate.pushInPoint;
                        CGPoint pushOutPoint = ppCaption.textAnimate.pushOutPoint;
                        pushInPoint = CGPointMake(pushInPoint.x*videoSize.width, pushInPoint.y*videoSize.height);
                        pushOutPoint = CGPointMake(pushOutPoint.x*videoSize.width, pushOutPoint.y*videoSize.height);
                        
                        CATransform3D t1 = captionLayer.captionTransform;
                        if (ppCaption.textAnimate.inType == RDCaptionAnimateTypeScaleInOut) {
                            if (current - start <= inDuration) {
                                float scaleIn = ppCaption.textAnimate.scaleIn;
                                float scale = scaleIn  - (scaleIn - ppCaption.textAnimate.scaleOut) * ((current - start) / inDuration);
                                
                                t1 = CATransform3DScale(t1,  scale, scale, 1.0);
                                
                                captionLayer.captionTransform =  t1;
                            }
                        }else if (ppCaption.textAnimate.inType == RDCaptionAnimateTypeMove && !CGPointEqualToPoint(pushInPoint, CGPointZero)) {
                            if (current - start <= inDuration) {
                                t1 = CATransform3DRotate(t1, ppCaption.angle / 180.0 * M_PI, 0, 0, 1);

                                t1 = CATransform3DTranslate(t1, pushInPoint.x - pushInPoint.x * ((current - start) / inDuration), pushInPoint.y - pushInPoint.y * ((current - start) / inDuration), 0);
                                t1 = CATransform3DRotate(t1, -ppCaption.angle / 180.0 * M_PI, 0, 0, 1);
                                
                                captionLayer.captionTransform = t1;
                            }
                        }else{
                            captionLayer.captionTransform = t1;
                        }
                        if (ppCaption.textAnimate.outType == RDCaptionAnimateTypeScaleInOut) {
                            if (current + outDuration > end){
                                float scaleOut = ppCaption.textAnimate.scaleOut;
                                float scale = scaleOut  - (scaleOut - ppCaption.textAnimate.scaleIn) * (1.0 - (end - current) / outDuration);
                                t1 = CATransform3DScale(t1, scale, scale, 1.0);
                                captionLayer.captionTransform =  t1;
                            }else{
                                captionLayer.captionTransform = t1;
                            }
                        }else if (ppCaption.textAnimate.outType == RDCaptionAnimateTypeMove && !CGPointEqualToPoint(pushOutPoint, CGPointZero)) {
                            if (current + outDuration > end){
                                t1 = CATransform3DRotate(t1, ppCaption.angle / 180.0 * M_PI, 0, 0, 1);

                                t1 = CATransform3DTranslate(t1, -pushOutPoint.x * (1.0 - (end - current) / outDuration), -pushOutPoint.y * (1.0 - (end - current) / outDuration), 0);
                                t1 = CATransform3DRotate(t1, -ppCaption.angle / 180.0 * M_PI, 0, 0, 1);

                                captionLayer.captionTransform = t1;
                            }
                            else{
                                captionLayer.captionTransform = t1;
                            }
                        }else{
                            captionLayer.captionTransform = t1;
                        }
                    }
                    if (ppCaption.textAnimate.type == RDCaptionAnimateTypeMove
                        || (ppCaption.textAnimate.inType == RDCaptionAnimateTypeMove
                        && ppCaption.textAnimate.outType == RDCaptionAnimateTypeMove))
                    {
                        CGPoint pushInPoint = ppCaption.textAnimate.pushInPoint;
                        CGPoint pushOutPoint = ppCaption.textAnimate.pushOutPoint;
                        pushInPoint = CGPointMake(pushInPoint.x*videoSize.width, pushInPoint.y*videoSize.height);
                        pushOutPoint = CGPointMake(pushOutPoint.x*videoSize.width, pushOutPoint.y*videoSize.height);
                        
                        float inDuration = ppCaption.textAnimate.inDuration;
                        float outDuration = ppCaption.textAnimate.outDuration;
                        if (CGPointEqualToPoint(pushInPoint, CGPointZero)) {
                            inDuration = 0.0;
                        }
                        if (CGPointEqualToPoint(pushOutPoint, CGPointZero)) {
                            outDuration = 0.0;
                        }
                        if (inDuration + outDuration > CMTimeGetSeconds(range.duration)) {
                            if (outDuration > 0 && inDuration > 0) {
                                inDuration = CMTimeGetSeconds(range.duration)/2.0;
                                outDuration = CMTimeGetSeconds(range.duration)/2.0;
                            }else if (inDuration > 0) {
                                inDuration = CMTimeGetSeconds(range.duration);
                            }else {
                                outDuration = CMTimeGetSeconds(range.duration);
                            }
                        }
                        CATransform3D t1 = captionLayer.captionTransform;
                        if (current - start <= inDuration) {
                            t1 = CATransform3DRotate(t1, ppCaption.angle / 180.0 * M_PI, 0, 0, 1);

                            t1 = CATransform3DTranslate(t1, pushInPoint.x - pushInPoint.x * ((current - start) / inDuration), pushInPoint.y - pushInPoint.y * ((current - start) / inDuration), 0);
                            t1 = CATransform3DRotate(t1, -ppCaption.angle / 180.0 * M_PI, 0, 0, 1);
                            
                            captionLayer.captionTransform = t1;
                        }
                        else if (current + outDuration > end){
                            t1 = CATransform3DRotate(t1, ppCaption.angle / 180.0 * M_PI, 0, 0, 1);

                            t1 = CATransform3DTranslate(t1, -pushOutPoint.x * (1.0 - (end - current) / outDuration), -pushOutPoint.y * (1.0 - (end - current) / outDuration), 0);
                            t1 = CATransform3DRotate(t1, -ppCaption.angle / 180.0 * M_PI, 0, 0, 1);

                            captionLayer.captionTransform = t1;
                        }
                        else{
                            captionLayer.captionTransform = t1;
                        }
                    }
                    if(ppCaption.captionImagePath.length > 0 || ppCaption.frameArray.count >0){//这里应该考虑
                        UIImage* image;
                        if (ppCaption.frameArray.count > 0) {
                            float frames_duration = ppCaption.duration; //一段动画的范围
                            int frames_count = (int)ppCaption.frameArray.count; //帧数
                            
                            float dtime = frames_duration / frames_count; // 每一张图片显示时间
                            
                            int index = (int)((current - start)/dtime) % frames_count; //
                            
                            double repetStartTime = 0;//
                            if(ppCaption.timeArray.count>1){
                                repetStartTime = [[[ppCaption.timeArray objectAtIndex:1] objectForKey:@"beginTime"] doubleValue];
                            }
                            if(current - start >= repetStartTime){
                                int notRepetStartCount = 0;
                                int notRepetStopCount = (int)ppCaption.frameArray.count;
                                for (int i=0 ;i<ppCaption.frameArray.count;i++) {
                                    NSDictionary *dic = ppCaption.frameArray[i];
                                    if([[dic objectForKey:@"time"] doubleValue] == repetStartTime){
                                        notRepetStartCount = i;
                                    }
                                    if(ppCaption.timeArray.count>2){
                                        if([[dic objectForKey:@"time"] doubleValue] == [[[ppCaption.timeArray objectAtIndex:2] objectForKey:@"beginTime"] doubleValue]){
                                            notRepetStopCount = i;
                                        }
                                    }
                                }
                                index = (int)((current - start)/dtime) % frames_count;
                                if(ppCaption.timeArray.count>1){
                                    if([[[ppCaption.timeArray objectAtIndex:0] objectForKey:@"beginTime"] doubleValue] != [[[ppCaption.timeArray objectAtIndex:1] objectForKey:@"beginTime"] doubleValue] && frames_duration <=(current - start)){
                                        if(ppCaption.timeArray.count>2){
                                            index = (index%(frames_count - notRepetStartCount - (frames_count - notRepetStopCount)) + notRepetStartCount);
                                        }else{
                                            index = (index%(frames_count - notRepetStartCount - (frames_count - notRepetStopCount)) + notRepetStartCount);
                                        }
                                    }
                                }
                            }
        //                    NSLog(@"index%d",index);
                            
                            NSString *name = [NSString stringWithFormat:@"%@%d",ppCaption.imageName,[ppCaption.frameArray[index][@"pic"] intValue]];
        //                    NSLog(@"%@ %@",name,ppCaption.pText);
                            
                            NSString* imagePath = [NSString stringWithFormat:@"%@%@",ppCaption.imageFolderPath,name];
                            if (![ppCaption.imageFolderPath hasSuffix:@"/"]) {
                                imagePath = [NSString stringWithFormat:@"%@/%@",ppCaption.imageFolderPath,name];
                            }
                            if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@.webp",imagePath]]) {
        //                        image = [UIImage rd_sd_imageWithWebP:[NSString stringWithFormat:@"%@.webp",imagePath]];
                            }else if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@.png",imagePath]]){
                                image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@.png",imagePath]];
                            }
                            imagePath = nil;
                        }else if (ppCaption.captionImagePath.length > 0) {
                            image = [UIImage imageWithContentsOfFile:ppCaption.captionImagePath];
                        }
                        if (image) {
                            UIImage *img;
                            if (isExporting) {
                                img = [RDRecordHelper fixOrientation:image];
                            }else if (MAX(image.size.width, image.size.height) > 320) {
                                //20191101 大图在性能差的设备上会卡
                                float scale = MAX(image.size.width, image.size.height)/320.0;
                                img = [UIImage imageWithCGImage:image.CGImage scale:scale orientation:UIImageOrientationUp];
                            }else {
                                img = [RDRecordHelper fixOrientation:image];
                            }
                            if (ppCaption.imageAnimate.type == RDCaptionAnimateTypeScrollInOut
                                || ppCaption.imageAnimate.inType == RDCaptionAnimateTypeScrollInOut
                                || ppCaption.imageAnimate.outType == RDCaptionAnimateTypeScrollInOut)
                            {
                                float inDuration = ppCaption.imageAnimate.inDuration;
                                float outDuration = ppCaption.imageAnimate.outDuration;
                                if (inDuration + outDuration > CMTimeGetSeconds(range.duration)) {
                                    if (outDuration > 0 && inDuration > 0) {
                                        inDuration = CMTimeGetSeconds(range.duration)/2.0;
                                        outDuration = CMTimeGetSeconds(range.duration)/2.0;
                                    }else if (inDuration > 0) {
                                        inDuration = CMTimeGetSeconds(range.duration);
                                    }else {
                                        outDuration = CMTimeGetSeconds(range.duration);
                                    }
                                }
                                if (ppCaption.imageAnimate.type == RDCaptionAnimateTypeScrollInOut
                                    || (ppCaption.imageAnimate.inType == RDCaptionAnimateTypeScrollInOut
                                    && ppCaption.imageAnimate.outType == RDCaptionAnimateTypeScrollInOut))
                                {
                                    if (current - start <= inDuration) {
                                        float widthProportion =  (current - start) / inDuration;
                                        float width;
                                        if (ppCaption.isStretch) {
                                            if (widthProportion < ppCaption.stretchRect.origin.x + ppCaption.stretchRect.size.width) {
                                                width = img.size.width * (ppCaption.stretchRect.origin.x + ppCaption.stretchRect.size.width) * img.scale;
                                            }else {
                                                width = img.size.width * widthProportion * img.scale;
                                            }
                                        }else {
                                            width = img.size.width * widthProportion * img.scale;
                                        }
                                        if (width > 0) {//解决警告：CGImageCreateWithImageProvider: invalid image size: 0 x 0.
                                            CGRect rect = CGRectMake(0, 0, width, img.size.height * img.scale);
                                            CGImageRef imageRef = CGImageCreateWithImageInRect([img CGImage], rect);
                                            captionLayer.imageRef = imageRef;
                                            CGImageRelease(imageRef);
                                        }
                                        captionLayer.pasterWidthProportion =  widthProportion;
                                    }
                                    else if (current + outDuration > end){
                                        float widthProportion =  (end - current) / outDuration;
                                        float width;
                                        if (ppCaption.isStretch) {
                                            if (widthProportion < ppCaption.stretchRect.origin.x + ppCaption.stretchRect.size.width) {
                                                width = img.size.width * (ppCaption.stretchRect.origin.x + ppCaption.stretchRect.size.width) * img.scale;
                                            }else {
                                                width = img.size.width * widthProportion * img.scale;
                                            }
                                        }else {
                                            width = img.size.width * widthProportion * img.scale;
                                        }
                                        CGRect rect = CGRectMake(0, 0, width, img.size.height * img.scale);
                                        CGImageRef imageRef = CGImageCreateWithImageInRect([img CGImage], rect);
                                        captionLayer.imageRef = imageRef;
                                        captionLayer.pasterWidthProportion =  widthProportion;
                                        CGImageRelease(imageRef);
                                    }else{
                                        captionLayer.imageRef = [img CGImage];
                                        captionLayer.pasterWidthProportion =  1.0;
                                    }
                                }else if (ppCaption.imageAnimate.inType == RDCaptionAnimateTypeScrollInOut) {
                                    if (current - start <= inDuration) {
                                        float widthProportion =  (current - start) / inDuration;
                                        float width;
                                        if (ppCaption.isStretch) {
                                            if (widthProportion < ppCaption.stretchRect.origin.x + ppCaption.stretchRect.size.width) {
                                                width = img.size.width * (ppCaption.stretchRect.origin.x + ppCaption.stretchRect.size.width) * img.scale;
                                            }else {
                                                width = img.size.width * widthProportion * img.scale;
                                            }
                                        }else {
                                            width = img.size.width * widthProportion * img.scale;
                                        }
                                        if (width > 0) {//解决警告：CGImageCreateWithImageProvider: invalid image size: 0 x 0.
                                            CGRect rect = CGRectMake(0, 0, width, img.size.height * img.scale);
                                            CGImageRef imageRef = CGImageCreateWithImageInRect([img CGImage], rect);
                                            captionLayer.imageRef = imageRef;
                                            CGImageRelease(imageRef);
                                        }
                                        captionLayer.pasterWidthProportion =  widthProportion;
                                    }else{
                                        captionLayer.imageRef = [img CGImage];
                                    }
                                }else {
                                    if (current + outDuration > end){
                                        float widthProportion =  (end - current) / outDuration;
                                        float width;
                                        if (ppCaption.isStretch) {
                                            if (widthProportion < ppCaption.stretchRect.origin.x + ppCaption.stretchRect.size.width) {
                                                width = img.size.width * (ppCaption.stretchRect.origin.x + ppCaption.stretchRect.size.width) * img.scale;
                                            }else {
                                                width = img.size.width * widthProportion * img.scale;
                                            }
                                        }else {
                                            width = img.size.width * widthProportion * img.scale;
                                        }
                                        CGRect rect = CGRectMake(0, 0, width, img.size.height * img.scale);
                                        CGImageRef imageRef = CGImageCreateWithImageInRect([img CGImage], rect);
                                        captionLayer.imageRef = imageRef;
                                        captionLayer.pasterWidthProportion =  widthProportion;
                                        CGImageRelease(imageRef);
                                    }else{
                                        captionLayer.imageRef = [img CGImage];
                                    }
                                }
                            }else {
                                captionLayer.imageRef = [img CGImage];
                            }
                            img = nil;
                        }
                        image = nil;
                        //图片放大
                        if (ppCaption.imageAnimate.type == RDCaptionAnimateTypeScaleInOut
                            || (ppCaption.imageAnimate.inType == RDCaptionAnimateTypeScaleInOut
                                && ppCaption.imageAnimate.outType == RDCaptionAnimateTypeScaleInOut))
                        {
                            float inDuration = ppCaption.imageAnimate.inDuration;
                            float outDuration = ppCaption.imageAnimate.outDuration;
                            if (inDuration + outDuration > CMTimeGetSeconds(range.duration)) {
                                if (outDuration > 0 && inDuration > 0) {
                                    inDuration = CMTimeGetSeconds(range.duration)/2.0;
                                    outDuration = CMTimeGetSeconds(range.duration)/2.0;
                                }else if (inDuration > 0) {
                                    inDuration = CMTimeGetSeconds(range.duration);
                                }else {
                                    outDuration = CMTimeGetSeconds(range.duration);
                                }
                            }
                            CATransform3D t1 = captionLayer.pasterTransform;
                            if (current - start <= inDuration) {
                                float scaleIn = ppCaption.imageAnimate.scaleIn;
                                float scale = scaleIn  - (scaleIn - ppCaption.imageAnimate.scaleOut) * ((current - start) / inDuration);
                                t1 = CATransform3DScale(t1,  scale, scale, 1.0);
                                captionLayer.pasterTransform =  t1;
                            }else if (current + outDuration > end){
                                float scaleOut = ppCaption.imageAnimate.scaleOut;
                                float scale = scaleOut  - (scaleOut - ppCaption.imageAnimate.scaleIn) * (1.0 - (end - current) / outDuration);
                                t1 = CATransform3DScale(t1, scale, scale, 1.0);
                                captionLayer.pasterTransform =  t1;
                            }
                        }else if (ppCaption.imageAnimate.inType == RDCaptionAnimateTypeScaleInOut
                                  || ppCaption.imageAnimate.outType == RDCaptionAnimateTypeScaleInOut
                                  || ppCaption.imageAnimate.inType == RDCaptionAnimateTypeMove
                                  || ppCaption.imageAnimate.outType == RDCaptionAnimateTypeMove)
                        {
                            float inDuration = ppCaption.imageAnimate.inDuration;
                            float outDuration = ppCaption.imageAnimate.outDuration;
                            if (inDuration + outDuration > CMTimeGetSeconds(range.duration)) {
                                if (outDuration > 0 && inDuration > 0) {
                                    inDuration = CMTimeGetSeconds(range.duration)/2.0;
                                    outDuration = CMTimeGetSeconds(range.duration)/2.0;
                                }else if (inDuration > 0) {
                                    inDuration = CMTimeGetSeconds(range.duration);
                                }else {
                                    outDuration = CMTimeGetSeconds(range.duration);
                                }
                            }
                            CGPoint pushInPoint = ppCaption.imageAnimate.pushInPoint;
                            CGPoint pushOutPoint = ppCaption.imageAnimate.pushOutPoint;
                            pushInPoint = CGPointMake(pushInPoint.x*videoSize.width, pushInPoint.y*videoSize.height);
                            pushOutPoint = CGPointMake(pushOutPoint.x*videoSize.width, pushOutPoint.y*videoSize.height);
                            
                            CATransform3D t1 = captionLayer.pasterTransform;
                            if (ppCaption.imageAnimate.inType == RDCaptionAnimateTypeScaleInOut) {
                                if (current - start <= inDuration) {
                                    float scaleIn = ppCaption.imageAnimate.scaleIn;
                                    float scale = scaleIn  - (scaleIn - ppCaption.imageAnimate.scaleOut) * ((current - start) / inDuration);
                                    t1 = CATransform3DScale(t1,  scale, scale, 1.0);
                                    captionLayer.pasterTransform =  t1;
                                }
                            }else if (ppCaption.imageAnimate.inType == RDCaptionAnimateTypeMove && !CGPointEqualToPoint(pushInPoint, CGPointZero)) {
                                if (current - start <= inDuration) {
                                    t1 = CATransform3DRotate(t1, ppCaption.angle / 180.0 * M_PI, 0, 0, 1);
                                    t1 = CATransform3DTranslate(t1, pushInPoint.x - pushInPoint.x * ((current - start) / inDuration), pushInPoint.y - pushInPoint.y * ((current - start) / inDuration), 0);
                                    t1 = CATransform3DRotate(t1, -ppCaption.angle / 180.0 * M_PI, 0, 0, 1);
                                    captionLayer.pasterTransform = t1;
                                }
                            }else {
                                captionLayer.pasterTransform = t1;
                            }
                            if (ppCaption.imageAnimate.outType == RDCaptionAnimateTypeScaleInOut) {
                                if (current + outDuration > end){
                                    float scaleOut = ppCaption.imageAnimate.scaleOut;
                                    float scale = scaleOut  - (scaleOut - ppCaption.imageAnimate.scaleIn) * (1.0 - (end - current) / outDuration);
                                    t1 = CATransform3DScale(t1, scale, scale, 1.0);
                                    captionLayer.pasterTransform =  t1;
                                }else {
                                    captionLayer.pasterTransform = t1;
                                }
                            }else if (ppCaption.imageAnimate.outType == RDCaptionAnimateTypeMove && !CGPointEqualToPoint(pushOutPoint, CGPointZero)) {
                                if (current + outDuration > end){
                                    t1 = CATransform3DRotate(t1, ppCaption.angle / 180.0 * M_PI, 0, 0, 1);

                                    t1 = CATransform3DTranslate(t1, - pushOutPoint.x * (1.0 - (end - current) / outDuration), - pushOutPoint.y * (1.0 - (end - current) / outDuration), 0);
                                    t1 = CATransform3DRotate(t1, -ppCaption.angle / 180.0 * M_PI, 0, 0, 1);

                                    captionLayer.pasterTransform = t1;
                                }else {
                                    captionLayer.pasterTransform = t1;
                                }
                            }else {
                                captionLayer.pasterTransform = t1;
                            }
                        }
                        if (ppCaption.imageAnimate.type == RDCaptionAnimateTypeMove
                            || (ppCaption.imageAnimate.inType == RDCaptionAnimateTypeMove
                                && ppCaption.imageAnimate.outType == RDCaptionAnimateTypeMove))
                        {
                            CGPoint pushInPoint = ppCaption.imageAnimate.pushInPoint;
                            CGPoint pushOutPoint = ppCaption.imageAnimate.pushOutPoint;
                            pushInPoint = CGPointMake(pushInPoint.x*videoSize.width, pushInPoint.y*videoSize.height);
                            pushOutPoint = CGPointMake(pushOutPoint.x*videoSize.width, pushOutPoint.y*videoSize.height);
                            
                            float inDuration = ppCaption.imageAnimate.inDuration;
                            float outDuration = ppCaption.imageAnimate.outDuration;
                            if (CGPointEqualToPoint(pushInPoint, CGPointZero)) {
                                inDuration = 0.0;
                            }
                            if (CGPointEqualToPoint(pushOutPoint, CGPointZero)) {
                                outDuration = 0.0;
                            }
                            if (inDuration + outDuration > CMTimeGetSeconds(range.duration)) {
                                if (outDuration > 0 && inDuration > 0) {
                                    inDuration = CMTimeGetSeconds(range.duration)/2.0;
                                    outDuration = CMTimeGetSeconds(range.duration)/2.0;
                                }else if (inDuration > 0) {
                                    inDuration = CMTimeGetSeconds(range.duration);
                                }else {
                                    outDuration = CMTimeGetSeconds(range.duration);
                                }
                            }
                            CATransform3D t1 = captionLayer.pasterTransform;
                            if (current - start <= inDuration) {
                                t1 = CATransform3DRotate(t1, ppCaption.angle / 180.0 * M_PI, 0, 0, 1);
                                t1 = CATransform3DTranslate(t1, pushInPoint.x - pushInPoint.x * ((current - start) / inDuration), pushInPoint.y - pushInPoint.y * ((current - start) / inDuration), 0);
                                t1 = CATransform3DRotate(t1, -ppCaption.angle / 180.0 * M_PI, 0, 0, 1);
                                captionLayer.pasterTransform = t1;
                            }
                            else if (current + outDuration > end){
                                t1 = CATransform3DRotate(t1, ppCaption.angle / 180.0 * M_PI, 0, 0, 1);

                                t1 = CATransform3DTranslate(t1, - pushOutPoint.x * (1.0 - (end - current) / outDuration), - pushOutPoint.y * (1.0 - (end - current) / outDuration), 0);
                                t1 = CATransform3DRotate(t1, -ppCaption.angle / 180.0 * M_PI, 0, 0, 1);

                                captionLayer.pasterTransform = t1;
                            }
                            else{
                                captionLayer.pasterTransform = t1;
                            }
                        }
                    }
                }
                [currentLayer addSublayer:captionLayer.layer];
            }
        }
    }
    
    return currentLayer;
    
}

- (CGRect) CGRectMixed:(RDCaptionCustomAnimate*)a  b:(RDCaptionCustomAnimate*) b value:(float) value type:(int) type{
    float v = value;
    (m_mapInterpolationHandles[type])(&v);
    CGPoint p;
    if (a.path) {
        CGPoint p2 = [a calculateWithTimeValue:v];
        p = CGPointMake(p2.x, originVideoSize.height - p2.y);
    }else{
        CGPoint p1 = calculateLinear(v, a.rect.origin, b.rect.origin);
        p = CGPointMake(p1.x*originVideoSize.width, originVideoSize.height - p1.y*originVideoSize.height);
    }
    return CGRectMake(p.x,
                      p.y,
                      (a.rect.size.width + (b.rect.size.width - a.rect.size.width) * value) * originVideoSize.width,
                      (a.rect.size.height + (b.rect.size.height - a.rect.size.height) * value) * originVideoSize.height);
}

- (void) uiElementUpdate:(CMTime) currentTime{
//    if (self.frameLayerBlock) {
//        self.frameLayerBlock(currentTime, subtitleEffectlayer);
//        // 在这里更新layer
//    }
//    NSLog(@"%s%@", __func__, CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentTime)));
    if(jsonMVEffectLayer){
        float time = CMTimeGetSeconds(currentTime);
        __block float dur = 0;
        __block float piantou = 0;
        __block float pianwei = 0;
        [jsonMVEffectViews enumerateObjectsUsingBlock:^(RDLOTAnimationView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(obj.isRepeat){
                dur += (obj.animationDuration + obj.spanValue);
            }
            if(obj.ispiantou){
                piantou += (obj.animationDuration + obj.spanValue);
            }
            if(obj.ispianwei){
                pianwei += (obj.animationDuration + obj.spanValue);
            }
        }];
        [jsonMVEffectViews enumerateObjectsUsingBlock:^(RDLOTAnimationView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            float value = MIN(MAX(time - obj.startTime, 0), obj.animationDuration)/obj.animationDuration;
            float t = time;
            if(obj.isRepeat){
                t = (time - floor(time/dur) *dur);
                if(floor(time/dur)>0){
                    t+=piantou;
                }
                value = MIN(MAX(t - obj.startTime, 0), obj.animationDuration)/obj.animationDuration;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if(t>obj.startTime && t<(obj.startTime + obj.animationDuration)){
                    obj.layer.opacity = 1.0;
                }else{
                    obj.layer.opacity = 0.0;
                }
            });
            if(value == 1){
                value = 0;
            }
//            NSLog(@"time:%f  t----->:%f  obj.start:%f   --->value:%f",time,t,obj.startTime,value);
            
            //obj.layer.opacity = (value>0.0 && value<1.0) ? 1.0 : 0.0;
            obj.animationProgress = value;
        }];
    }
    if (animationView && movieEffects.count == 0) {
        float time = CMTimeGetSeconds(currentTime);
        float animationTime = time;
        if (rdJsonAnimation.isRepeat && animationPlayCount > 1) {
            int timeInt = time * 1000000;
            int animationDurationInt = animationView.animationDuration * 1000000;
            int animationTimeInt = timeInt % animationDurationInt;
            animationTime = animationTimeInt / 1000000.0;
//            NSLog(@"time:%.2f animationDuration:%.2f animationTime:%.2f", time, animationView.animationDuration, animationTime);
        }
        if (animationView.endStartTime > 0.0 && animationTime > animationView.imagesDuration) {
            animationView.animationProgress = (animationTime + animationView.endStartTime)/animationView.animationDuration;
        }else {
            animationView.animationProgress = animationTime/animationView.animationDuration;
        }
    //        NSLog(@"time:%f animationDuration:%f imagesDuration:%f", time, animationView.animationDuration, animationView.imagesDuration);
//            NSLog(@"animationProgress:%f", animationView.animationProgress);
    }
    if (_doodleLayers.count > 0 || _captions.count > 0) {
        for (int i = 0; i<_doodleLayers.count; i ++) {
            RDDoodleLayer *layer = _doodleLayers[i];
            if(CMTimeGetSeconds(currentTime)>=CMTimeGetSeconds(layer.timeRange.start) && CMTimeGetSeconds(currentTime)<=CMTimeGetSeconds(CMTimeAdd(layer.timeRange.start, layer.timeRange.duration))){
                layer.opacity = 1.0;
            }else{
                layer.opacity = 0.0;
            }
        }
        CALayer* subLayer = [self computeLayerToImage:self.captions withCurrentTime:currentTime videoSize:_editor.videoSize];
        [subtitleEffectlayer addSublayer:subLayer];
    }
    [newUIElement update];
    if(isExporting && _endLogomarkLayer){
        [endLogoUIElement update];
        float current = CMTimeGetSeconds(currentTime);
        if((self.duration - current)<=(_fadeDuration + _showDuration)){
            gaosiFilter.blurRadiusInPixels = 8 * (((_fadeDuration + _showDuration) - (self.duration - current))/(_fadeDuration + _showDuration));
            if((self.duration - current)>=(_showDuration)){
                NSLog(@"%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentTime)));
                _endLogomarkLayer.opacity = MIN((_fadeDuration - (self.duration - current - _showDuration))/_fadeDuration, 1);
            }
        }else{
            _endLogomarkLayer.opacity = 0.0;
            gaosiFilter.blurRadiusInPixels = 0.0;
        }
    }
}

- (void) setVVAssetVolume:(float)volume asset:(VVAsset *) asset{
    asset.volume = volume;
    [_editor setVVAssetVolume:volume asset:asset];
}
- (void) setMusicVolume:(float) volume music:(RDMusic *) music{
    music.volume = volume;
    [_editor setMusicVolume:volume music:music];
}
- (void) setVolume:(float) volume identifier:(NSString*) identifier{
    [originScenes enumerateObjectsUsingBlock:^(RDScene *  _Nonnull scene, NSUInteger idx, BOOL * _Nonnull stop1) {
        [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop2) {
            if ([asset.identifier isEqualToString:identifier]) {
                asset.volume = volume;
                *stop2 = YES;
                *stop1 = YES;
            }
        }];
    }];
    [_editor.musics enumerateObjectsUsingBlock:^(RDMusic * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.identifier isEqualToString:identifier]) {
            obj.volume = volume;
            *stop = YES;
        }
    }];
    [_editor.dubbingMusics enumerateObjectsUsingBlock:^(RDMusic * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.identifier isEqualToString:identifier]) {
            obj.volume = volume;
            *stop = YES;
        }
    }];
    [_editor setVolume:volume identifier:identifier];
}

- (void)setPitch:(float)pitch identifier:(NSString *)identifier {
    [originScenes enumerateObjectsUsingBlock:^(RDScene *  _Nonnull scene, NSUInteger idx, BOOL * _Nonnull stop1) {
        [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop2) {
            if ([asset.identifier isEqualToString:identifier]) {
                asset.pitch = pitch;
                *stop2 = YES;
                *stop1 = YES;
            }
        }];
    }];
    [_editor.musics enumerateObjectsUsingBlock:^(RDMusic * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.identifier isEqualToString:identifier]) {
            obj.pitch = pitch;
            *stop = YES;
        }
    }];
    [_editor.dubbingMusics enumerateObjectsUsingBlock:^(RDMusic * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.identifier isEqualToString:identifier]) {
            obj.pitch = pitch;
            *stop = YES;
        }
    }];
    [_editor setPitch:pitch identifier:identifier];
}

- (float)setAudioFilter:(RDAudioFilterType)type identifier:(NSString *)identifier{
    float defaultPitch = 1.0;
    if (type == RDAudioFilterTypeBoy) {
        defaultPitch = 0.8;
    }else if (type == RDAudioFilterTypeGirl) {
        defaultPitch = 1.27;
    }else if (type == RDAudioFilterTypeMonster) {
        defaultPitch = 0.6;
    }else if (type == RDAudioFilterTypeCartoon) {
        defaultPitch = 0.45;
    }else if (type == RDAudioFilterTypeCartoonQuick) {
        defaultPitch = 0.55;
    }
    [originScenes enumerateObjectsUsingBlock:^(RDScene *  _Nonnull scene, NSUInteger idx, BOOL * _Nonnull stop1) {
        [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop2) {
            if ([asset.identifier isEqualToString:identifier]) {
                asset.audioFilterType = type;
                asset.pitch = defaultPitch;
                *stop2 = YES;
                *stop1 = YES;
            }
        }];
    }];
    [_editor setAudioFilter:type identifier:identifier];
    
    return defaultPitch;
}

#if 1

- (void)applicationEnterHome:(NSNotification *)notification{
    if (isExporting) {
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(resumeExport) object:nil];
        [self stopExport];
    }
}

- (void)appEnterForegroundNotification:(NSNotification *)notification{
    if (isExporting) {
        [self performSelector:@selector(resumeExport) withObject:nil afterDelay:1];
    }
}

#endif

- (void)setShouldRepeat:(BOOL)shouldRepeat{
    _shouldRepeat = shouldRepeat;
}

- (void)setPlayRate:(float)playRate {
    _playRate = playRate;
    _renderer.playRate = playRate;
}

- (UIView*) littlePreview{
    return (UIView*)_preview1;
}

#pragma mark- RDRendererPlayerDelegate
- (void)statusChanged:(RDVideoRenderer *)render statues:(RenderStatus)status {
#if 1   //20180723 wuxiaoxia 将mv与scene构建为一个虚拟视频
    _status = (RDVECoreStatus)status;
    if (_status == kRDVECoreStatusReadyToPlay && isRefreshAnimationImages) {
        return;
    }
    if (_delegate && [_delegate respondsToSelector:@selector(statusChanged:status:)]) {
        [_delegate statusChanged:self status:_status];
    }else if (_delegate && [_delegate respondsToSelector:@selector(statusChanged:)]) {
        [_delegate statusChanged:_status];
    }
#else
    render.status = status;
    _status = (RDVECoreStatus)status;
    if(status == kRenderStatusReadyToPlay){
        if(![renders containsObject:render]){
            [renders addObject:render];
        }
    }else{
        if([renders containsObject:render]){
            [renders removeObject:render];
        }
    }
    if(movieEffects.count<renders.count){
        
        for (int i = 0; i<renders.count; i++) {
            RDVideoRenderer *iRender = renders[i];
            if(iRender.status != kRenderStatusReadyToPlay){
                _status = (RDVECoreStatus)iRender.status;
            }
        }
        
        if (_delegate && [_delegate respondsToSelector:@selector(statusChanged:status:)]) {
            [_delegate statusChanged:self status:_status];
        }else if (_delegate && [_delegate respondsToSelector:@selector(statusChanged:)]) {
            [_delegate statusChanged:_status];
        }
        
    }else{
        if(status == kRenderStatusReadyToPlay){
            status = kRenderStatusWillChangeMedia;
        }
        if (_delegate && [_delegate respondsToSelector:@selector(statusChanged:status:)]) {
            [_delegate statusChanged:self status:(RDVECoreStatus)status];
        }else if (_delegate && [_delegate respondsToSelector:@selector(statusChanged:)]) {
            [_delegate statusChanged:(RDVECoreStatus)status];
        }
    }
#endif
}

- (void)playToEnd{
    [animationLayerArray enumerateObjectsUsingBlock:^(CALayer *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.contents = nil;
    }];
    [animationLayerArray removeAllObjects];
    
    if (_shouldRepeat) {
        __weak typeof(self) weakSelf = self;
        //20180524 wuxiaoxia 修改bug:设置MV的情况，有的MV在循环播放的时候只有声音,视频不动
#ifdef ForcedSeek   //20180720 wuxiaoxia seek时，timesScale与设置的帧率一致，真正seek到的时间才能与time一致
        [self seekToTime:CMTimeMake(3, _editor.fps) toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
            [weakSelf play];
        }];
#else
        [self seekToTime:kCMTimeZero toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
            [weakSelf play];
        }];
#endif
    }else {
        _isPlaying = NO;
        if(_delegate){
            if([_delegate respondsToSelector:@selector(playToEnd)]){
                [_delegate playToEnd];
            }
        }
    }
    
}

- (void)playCurrentTime:(CMTime)currentTime{
//    NSLog(@"currentTime:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentTime)));
    if (_isPlaying && _enableAudioEffect) {
        [originScenes enumerateObjectsUsingBlock:^(RDScene * _Nonnull scene, NSUInteger idx, BOOL * _Nonnull stop) {
            [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
                [self refreshAssetVolume:asset timeRange:scene.fixedTimeRange currentTime:currentTime];
            }];
        }];
        [_editor.musics enumerateObjectsUsingBlock:^(RDMusic * _Nonnull music, NSUInteger idx, BOOL * _Nonnull stop) {
            if (music.identifier.length > 0 && music.isFadeInOut && (music.headFadeDuration > 0 || music.endFadeDuration > 0)) {
                float current = CMTimeGetSeconds(currentTime);
                float start = CMTimeGetSeconds(music.effectiveTimeRange.start);
                float end = start + CMTimeGetSeconds(music.effectiveTimeRange.duration);
                if (current >= start && current <= end) {
                    float volume = music.volume;
                    if (current - start <= music.headFadeDuration) {
                        volume = music.volume *( (current - start) / music.headFadeDuration);
                    }else if (current + music.endFadeDuration > end){
                        volume = music.volume * ((end - current) / music.endFadeDuration);
                    }
                    [_editor setVolume:volume identifier:music.identifier];
                }
            }
        }];
        [_watermarkArray enumerateObjectsUsingBlock:^(RDWatermark * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self refreshAssetVolume:obj.vvAsset timeRange:obj.timeRange currentTime:currentTime];
        }];
    }
    if(self.delegate){
        if([self.delegate respondsToSelector:@selector(progressCurrentTime:)]){
            [self.delegate progressCurrentTime:currentTime];
        }else if([self.delegate respondsToSelector:@selector(progress:currentTime:)]){
            [self.delegate progress:self currentTime:currentTime];
        }
    }
}

- (void)refreshAssetVolume:(VVAsset *)asset timeRange:(CMTimeRange)timeRange currentTime:(CMTime)currentTime {
    if (asset.type == RDAssetTypeVideo
        && asset.identifier.length > 0
        && asset.volume > 0
        && (asset.audioFadeInDuration > 0 || asset.audioFadeOutDuration > 0))
    {
        float current = CMTimeGetSeconds(currentTime);
        float start = CMTimeGetSeconds(CMTimeAdd(timeRange.start, asset.startTimeInScene));
        float end = start + CMTimeGetSeconds(CMTimeMultiplyByFloat64(asset.timeRange.duration, 1.0/asset.speed));
        if (current >= start && current <= end) {
            float volume = asset.volume;
            if (current - start <= asset.audioFadeInDuration) {
                volume = asset.volume *( (current - start) / asset.audioFadeInDuration);
            }else if (current + asset.audioFadeOutDuration > end){
                volume = asset.volume * ((end - current) / asset.audioFadeOutDuration);
            }
//            NSLog(@"currentTime:%@ %@volume:%f", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentTime)), asset.identifier, volume);
            [_editor setVolume:volume identifier:asset.identifier];
        }
    }
}

- (NSMutableArray <RDScene *>*) getScenes
{
    return originScenes;
}

- (void) setScenes:(NSMutableArray<RDScene *> *) scenes
{
    originScenes = scenes;
    if (rdJsonAnimation) {
        animationView.imagesCount = originScenes.count + rdJsonAnimation.textSourceArray.count;
        [self setAnimationScene];
        if (rdJsonAnimation.jsonPath.length > 0 || rdJsonAnimation.jsonDictionary) {
            isRefreshAnimationImages = YES;
            isClipAnimationImages = YES;
            [self performSelectorInBackground:@selector(copySelectedFilesToTempDir) withObject:nil];
        }
    }else {
        _editor.scenes = scenes;
    }
}

- (NSUInteger)degressFromVideoFileWithURL:(NSURL *)url
{
    NSUInteger degress = 0;
    
    AVAsset *asset = [AVAsset assetWithURL:url];
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
        
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
            // Portrait
            degress = -270;
        }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
            // PortraitUpsideDown
            degress = -90;
        }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
            // LandscapeRight
            degress = 0;
        }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
            // LandscapeLeft
            degress = -180;
        }
    }
    
    return degress;
}

- (void) setDubbingMusics:(NSMutableArray<RDMusic*> *) musics
{
    _editor.dubbingMusics = musics;
    
}
- (void) setEditorVideoSize:(CGSize) videoSize
{
    videoSize = [self correctSize:videoSize];
    originVideoSize = videoSize;
    _editor.videoSize = videoSize;
    suplayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    animationView.frame = suplayer.bounds;
    customDrawLayer.frame = suplayer.bounds;
    subtitleEffectlayer.frame = suplayer.frame;
    currentLayer.frame = subtitleEffectlayer.frame;
    _endLogomarkLayer.frame = suplayer.frame;
}

- (void)addDyFilter:(RDVideoRealTimeFilterType)filterType{
    
    _realTimeFilterType = filterType;
}

- (void)setDyFilters:(NSMutableArray<FilterAttribute *> *)filterAttributes{
    
    filterAttributeArray = [filterAttributes mutableCopy];
}

- (void) removeDyFilterAttribute:(NSInteger)index atTime:(CMTime) currentTime
{
    if(filterAttributeArray.count>index)
        [filterAttributeArray removeObjectAtIndex:index];
    
    [self filterRefresh:currentTime];
    
}
- (void) filterRefresh:(CMTime) currentTime
{
    if (_sdkDisabled) {
        return;
    }
//    currentTime = CMTimeMake(CMTimeGetSeconds(currentTime)*_editor.fps, _editor.fps);
    if (CMTimeCompare(currentTime, _renderer.currentTime) == 0
        || CMTimeCompare(CMTimeSubtract(currentTime, _renderer.currentTime), CMTimeMake(1, _editor.fps)) == 0
        || CMTimeCompare(CMTimeSubtract(currentTime, _renderer.currentTime), CMTimeMake(-1, _editor.fps)) == 0)
    {
//        NSLog(@"%d %@", __LINE__, CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentTime)));
        [_renderer refreshCurrentFrame:currentTime completionHandler:nil];
    }else {
//        NSLog(@"????????????%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentTime)));
        [self seekToTime:currentTime toleranceTime:kCMTimeZero completionHandler:nil];
    }
}
/**刷新当前帧
*/
- (void)refreshCurrentFrame {
    if (!_isPlaying) {
        CMTime time = _renderer.currentTime;
        [_renderer refreshCurrentFrame:time completionHandler:nil];
    }
}

- (void) removeAllDyFilterAttributes{
    
    [filterAttributeArray removeAllObjects];
}

- (void) addGlobalFilters:(NSMutableArray <RDFilter *>*)filters{
    
#if 0
    NSMutableArray *newFilters = [NSMutableArray array];
    RDGPUImageOutput<RDGPUImageInput>* filter;
    for (int i = 0 ; i<filters.count; i++) {
        RDFilter *obj = filters[i];
        
        if (obj.type == kRDFilterType_YuanShi) {
            filter = [[RDGPUImageFilter alloc] init];
        }else if (obj.type == kRDFilterType_HeiBai){
            filter = [[RDGPUImageGrayscaleFilter alloc] init];
        }else if (obj.type == kRDFilterType_FanXiang){
            filter = [[RDColorInvertFilter alloc] init];
        }else if (obj.type == kRDFilterType_SuiYue){
            filter = [[RDGPUImageGrayscaleFilter alloc] init];
        }else if (obj.type == kRDFilterType_NiuQu){
            filter = [[RDStretchDistortionFilter alloc] init];
        }else if (obj.type == kRDFilterType_SLBP){
            filter = [[RDRecordGPUImageThresholdedNonMaximumSuppressionFilter alloc] initWithPackedColorspace:YES];
            ((RDRecordGPUImageThresholdedNonMaximumSuppressionFilter*)filter).threshold = 0.01;
        }
        else if (obj.type == kRDFilterType_Sketch){
            filter = [[RDRecordGPUImageSketchFilter alloc] init];
        }else if (obj.type == kRDFilterType_DistortingMirror){
            filter = [[RDRecordGPUImageStretchDistortionFilter alloc] init];
        }
        else if(obj.type == kRDFilterType_ACV){
            filter =[[RDGPUImageToneCurveFilter alloc] initWithACVData:[NSData dataWithContentsOfFile:obj.filterPath]];
        }
        else if (obj.type == kRDFilterType_LookUp){
            filter = [[RDLookupFilter alloc] initWithImagePath:obj.filterPath];
        }
        if (filter) {
            [newFilters addObject:filter];
        }else{
            [newFilters addObject:@[]];
        }
    }
    
    globalFilters = newFilters;
#else
//    globalFilters = [NSMutableArray new];
    gFilters = [filters mutableCopy];
//    [gFilters enumerateObjectsUsingBlock:^(RDFilter * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//       [globalFilters addObject: @[]];
//    }];
#endif
    
    [self setGlobalFilter:globalFilterIndex];
}
- (NSArray *) getGlobalFilters{
    return nil;//gFilters;
}
- (void)setGlobalFilter:(NSInteger)index{
#if 0
    if(globalFilters.count == 0 || index == -1){
        return;
    }
    if(![globalFilters[index] isKindOfClass:[NSArray class]]){
        
        gFilter = globalFilters[index];
        [_filterPipeline replaceFilterAtIndex:0 withFilter:gFilter];
        globalFilterIndex = index;
    }
#else
    if(gFilters.count == 0 || index == -1){
        return;
    }
    
    RDGPUImageOutput<RDGPUImageInput>* filter;
    RDFilter *obj = gFilters[index];
    
    
    if (obj.type == kRDFilterType_YuanShi) {
        filter = [[RDGPUImageFilter alloc] init];
    }else if (obj.type == kRDFilterType_HeiBai){
        filter = [[RDGPUImageGrayscaleFilter alloc] init];
    }else if (obj.type == kRDFilterType_FanXiang){
        filter = [[RDColorInvertFilter alloc] init];
    }else if (obj.type == kRDFilterType_SuiYue){
        filter = [[RDGPUImageGrayscaleFilter alloc] init];
    }else if (obj.type == kRDFilterType_NiuQu){
        filter = [[RDStretchDistortionFilter alloc] init];
    }else if (obj.type == kRDFilterType_SLBP){
        filter = [[RDRecordGPUImageThresholdedNonMaximumSuppressionFilter alloc] initWithPackedColorspace:YES];
        ((RDRecordGPUImageThresholdedNonMaximumSuppressionFilter*)filter).threshold = 0.01;
    }
    else if (obj.type == kRDFilterType_Sketch){
        filter = [[RDRecordGPUImageSketchFilter alloc] init];
    }else if (obj.type == kRDFilterType_DistortingMirror){
        filter = [[RDRecordGPUImageStretchDistortionFilter alloc] init];
    }
    else if(obj.type == kRDFilterType_ACV){
        filter =[[RDGPUImageToneCurveFilter alloc] initWithACVData:[NSData dataWithContentsOfFile:obj.filterPath]];
    }
    else if (obj.type == kRDFilterType_LookUp){
        filter = [[RDLookupFilter alloc] initWithImagePath:obj.filterPath intensity:obj.intensity];
    }
    if (filter) {
        [gFilter removeAllTargets];
        [gFilter removeOutputFramebuffer];
        gFilter = nil;
        
        gFilter = filter;
        
        [_filterPipeline replaceFilterAtIndex:gFilterIndex withFilter:gFilter];
        globalFilterIndex = index;
    }
#endif
}

- (void)setGlobalFilterIntensity:(float)intensity {
    if ([gFilter isKindOfClass:[RDLookupFilter class]]) {
        RDLookupFilter *currentFilter = (RDLookupFilter *)gFilter;
        currentFilter.intensity = intensity;
    }
}

- (void)setIsRealTime:(BOOL)isRealTime{
    _isRealTime = isRealTime;
    if (_isRealTime && !(CMTimeGetSeconds(startTime)>0.0)) {
        startTime = cTime;
    }else{
        endTime = cTime;
        
        //20170627 wuxiaoxia 一个滤镜特效加到视频结束，按“播放”按钮后，有时startTime还是视频结束的时间
        if (CMTIME_IS_INVALID(startTime) || CMTimeCompare(endTime, startTime) < 0) {
            startTime = kCMTimeZero;
        }
        
        CMTimeRange timeRange = CMTimeRangeMake(startTime, CMTimeSubtract(endTime, startTime));
        
        FilterAttribute* attribute = [[FilterAttribute alloc] init];
        attribute.timeRange = timeRange;
        attribute.filterType = currentFilterType;
        
        [filterAttributeArray addObject:attribute];
        
        startTime = kCMTimeZero;
        
    }
    
}
- (void)setMusics:(NSMutableArray<RDMusic*> *)musics
{
    
    _editor.musics = musics;
}
- (void)buildForCapture{

    renders = [NSMutableArray array];
    double time = CACurrentMediaTime();
    [_renderer clear];
    //    _videoDuration = _editor.duration;
    _editor.enableAudioEffect = NO;
    //延迟一秒后再进行build与prepare 截图忽略音频特效  无需延迟
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [_editor build];
    [_renderer prepare];
    _videoDuration = CMTimeGetSeconds([_renderer playerItemDuration]);
    
    _preview.frame = _frame;
    //    _preview.mybounds = CGRectMake(0, 0, _frame.size.width, _frame.size.height);
//    [self seekToTime:CMTimeMake(42, TIMESCALE)];//20180119 wuxiaoxia 为了解决有的视频刚开始几帧读不出来，导致不能播放的bug
    NSLog(@"build 耗时:%lf",CACurrentMediaTime() -time);
    //    });
}
- (void)build {
    double time = CACurrentMediaTime();
    [self stop];
    _editor.enableAudioEffect = _enableAudioEffect;
    _preview.frame = _frame;

//    renders = [NSMutableArray array];
    
    [customDrawLayer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];

//    if (_enableAudioEffect) {
//
//
//
//        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
//
//
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
//
//            dispatch_semaphore_signal(semaphore);
//        });
//
//        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
//
//
//    }
    double time1 = CACurrentMediaTime();
    [_editor build];
    NSLog(@"build 耗时:%lf",CACurrentMediaTime() -time1);
    double time2 = CACurrentMediaTime();
    [_renderer prepare];
    NSLog(@"prepare 耗时:%lf",CACurrentMediaTime() -time2);
    
    if (_enableAudioEffect) {
        _videoDuration = _editor.duration;
    }else{
        _videoDuration = CMTimeGetSeconds([_renderer playerItemDuration]);
    }
//    [self seekToTime:CMTimeMake(2, _editor.fps)];//20180119 wuxiaoxia 为了解决有的视频刚开始几帧读不出来，导致不能播放的bug
//    [self seekToTime:CMTimeMake(42, TIMESCALE)];//20180605 wuxiaoxia 有的视频刚开始几帧读不出来，seek到CMTimeMake(2, originalFrameRate)才能播放，originalFrameRate为视频原帧率，为了统一改为600.//20180606 需要播放器状态为AVPlayerStatusReadyToPlay时才能seek，所以放到render里执行
    //设置背景颜色
    [_editor setVirtualVideoBgColor:backGroundColor];
    NSLog(@"build 总耗时:%lf",CACurrentMediaTime() -time);
}

- (void)setMosaics:(NSMutableArray<RDMosaic *> *)mosaics {
    _mosaics = mosaics;
    if (mosaicFilter) {
        mosaicFilter.mosaics = mosaics;
    }
}

- (void)setBlurs:(NSMutableArray<RDAssetBlur *> *)blurs {
    _blurs = blurs;
    if (blurFilter) {
        blurFilter.blurBlocks = blurs;
    }
}

- (void)setDewatermarks:(NSMutableArray<RDDewatermark *> *)dewatermarks {
    _dewatermarks = dewatermarks;
#if 1
    dewatermarkFilter.watermark = dewatermarks;
#else
    if (dewatermarkFilter) {
        if (dewatermarks.count > 0) {
            dewatermarkFilter.watermark = dewatermarks;
        }else {
            
        }
    }else if (dewatermarks.count > 0) {
        dewatermarkFilter = [[RDGPUImageDewatermark alloc] init];
        dewatermarkFilter.watermark = _dewatermarks;
        
    }
#endif
}

- (void)setNonRectangleCaptions:(NSMutableArray<RDCaptionLight *> *)nonRectangleCaptions {
    _nonRectangleCaptions = nonRectangleCaptions;
    if (quadsRender) {
        quadsRender.captionLight = nonRectangleCaptions;
    }
}

/**获取某一个素材的开始时间
 */
- (CMTimeRange) passThroughTimeRangeAtIndex:(NSInteger) index{
    if (_sdkDisabled) {
        return kCMTimeRangeInvalid;
    }
    if (animationView) {
        if (index >= variableImageArray.count) {//20181009 wuxiaoxia fix bug:demo中每个模板图片数量不一致，超出模板图片数量时崩溃
            index = variableImageArray.count - 1;
        }
        RDLOTAnimatedSourceInfo *sourceInfo = [variableImageArray objectAtIndex:index];
        CMTimeRange timeRange = CMTimeRangeMake(CMTimeMake(sourceInfo.inFrame, animationView.sceneModel.framerate.intValue), CMTimeMake(sourceInfo.outFrame, animationView.sceneModel.framerate.intValue));
        
        return timeRange;
    }
    return [_editor passThroughTimeRangeAtIndex:(int)index];
}

/**获取某一个转场的开始时间
 */
- (CMTimeRange) transitionTimeRangeAtIndex:(NSInteger) index{
    if (_sdkDisabled) {
        return kCMTimeRangeInvalid;
    }
    if (animationView) {
        return kCMTimeRangeZero;
    }
    return [_editor transitionTimeRangeAtIndex:(int)index];
}

/** 转场时长不变的情况下，实时切换转场
@abstract  In the case of the same transition duration, switch the transition in real time.
*/
- (void)refreshTransition:(VVTransition *)transition atIndex:(NSInteger)index {
    [_editor refreshTransition:transition atIndex:index];
    [_renderer playerItemDuration];
}

- (void)refreshAssetSpeed:(float)speed {
    [_editor refreshAssetSpeed:speed];
    [_renderer playerItemDuration];
}

- (AVMutableComposition *)composition{
    return _editor.composition;
}
- (AVMutableVideoComposition *)videoComposition{
    if (_editor.videoComposition.renderScale != 1.0) {
        AVMutableVideoComposition *videoComposition = [_editor.videoComposition copy];
        videoComposition.renderScale = 1.0;//AVAssetImageGenerator can't use a video composition with a renderScale other than 1.0
        return videoComposition;
    }
    return _editor.videoComposition;
}

- (void)setRealTimeFilterType:(RDVideoRealTimeFilterType)realTimeFilterType{
    _realTimeFilterType = realTimeFilterType;
}

static Float64 factorForTimeInRange(CMTime time, CMTimeRange range) /* 0.0 -> 1.0 */
{
    
    CMTime elapsed = CMTimeSubtract(time, range.start);
    return CMTimeGetSeconds(elapsed) / CMTimeGetSeconds(range.duration);
}

- (void) filterRealTimeEffect:(CMTime) currentTime{
    float time = CMTimeGetSeconds(currentTime);
//    NSLog(@"currentTime:%f", time);
    cTime = currentTime;
    
    if (_isRealTime) {
        
        currentFilterType = _realTimeFilterType;
        
    }else{
        RDVideoRealTimeFilterType maxType = RDVideoRealTimeFilterTypeNone;
        int maxR  = -1;
        for (int i = 0; i<filterAttributeArray.count; i++) {
            CMTimeRange timeRange = filterAttributeArray[i].timeRange;
            if (CMTimeRangeContainsTime(timeRange, currentTime)) {
                if (i>maxR) {
                    maxType = filterAttributeArray[i].filterType;
                    maxR = i;
                }
                
            }
        }
        currentFilterType = maxType;
    }
    
    dyFilter.type = currentFilterType;
    dyFilter.time = time;
    if (!animationView) {
        [originScenes enumerateObjectsUsingBlock:^(RDScene *  _Nonnull scene, NSUInteger idx1, BOOL * _Nonnull stop1) {
            float sceneStartTime = CMTimeGetSeconds(scene.fixedTimeRange.start);
            float sceneDuration = CMTimeGetSeconds(scene.fixedTimeRange.duration);
            if (time >= sceneStartTime && time <= sceneStartTime + sceneDuration) {
                [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx2, BOOL * _Nonnull stop2) {
                    
                    BOOL hasAnimate = NO;
                    
                    VVAssetAnimatePosition* fromPosition;
                    VVAssetAnimatePosition* toPosition;
                    float animateCurrentTime = 0;
                    RDAssetBlur *assetBlur;
                    if (asset.animate.count > 0) {
                        float tweenFactor = factorForTimeInRange(currentTime, scene.fixedTimeRange);
                        animateCurrentTime =  tweenFactor * CMTimeGetSeconds(scene.fixedTimeRange.duration);
                        
                        for (int j = 0; j<asset.animate.count; j++) {
                            
                            VVAssetAnimatePosition* _from = asset.animate[j];
                            VVAssetAnimatePosition* _to;
                            if (j == asset.animate.count - 1) {
                                _to = asset.animate[j];
                            }else {
                                _to = asset.animate[j+1];
                            }
                            
                            //保留三位有效数字，计算精确度
                            int nTimeFrom = (int)((_from.atTime + CMTimeGetSeconds(asset.startTimeInScene))*1000) ;
                            int nTimeTo = (int)((_to.atTime  + CMTimeGetSeconds(asset.startTimeInScene))*1000) ;
                            int nCurrent =(int)(animateCurrentTime*1000);
                            
                            bool isMV = (fabs(1000.0/_editor.fps - fabs(nTimeTo - nTimeFrom))<10)?true:false;//是否每帧都有动画
                            
                            if ((isMV && fabs(nCurrent - nTimeFrom)<50) ||(!isMV && nTimeFrom <= nCurrent && nCurrent <= nTimeTo)) {
                                fromPosition = _from;
                                toPosition = _to;
                                hasAnimate = YES;
                                break;
                            }
                        }
                    }
                    if (hasAnimate && fromPosition.blur && toPosition.blur) {
                        float valueT = (toPosition.atTime - fromPosition.atTime)>0.0?(animateCurrentTime - CMTimeGetSeconds(asset.startTimeInScene) - fromPosition.atTime) / (toPosition.atTime - fromPosition.atTime) : 0.0;
                        valueT = valueT>1.0?1.0:valueT;
                        float intensity =  fromPosition.blur.intensity + (toPosition.blur.intensity - fromPosition.blur.intensity) * valueT;
//                        NSLog(@"currentTime:%f fromTime:%f toTime:%f intensity:%f valueT:%f", time, fromPosition.atTime, toPosition.atTime, intensity, valueT);
                        assetBlur = [[RDAssetBlur alloc] init];
                        assetBlur.timeRange = CMTimeRangeMake(currentTime, CMTimeMake(1, _editor.fps));
                        assetBlur.type = fromPosition.blur.type;
                        assetBlur.intensity = intensity;
                        [self pointArrayMixed:assetBlur a:fromPosition.blur.pointsArray b:toPosition.blur.pointsArray value:valueT];
                        *stop2 = YES;
                    }else if (time >= sceneStartTime + CMTimeGetSeconds(asset.startTimeInScene)) {
                        RDAssetBlur *blur = asset.blur;
                        if (blur) {
                            assetBlur = asset.blur;
                            *stop2 = YES;
                        }
                    }
                    NSMutableArray *blurArray = [NSMutableArray array];
                    if (_blurs && _blurs.count > 0) {
                        [blurArray addObjectsFromArray:_blurs];
                    }
                    if (assetBlur) {
                        [blurArray addObject:assetBlur];
                    }
                    blurFilter.blurBlocks = blurArray;
                }];
            }
        }];
    }
}

- (CGRect) CGRectMixed:(CGRect)a  b:(CGRect) b value:(float) value{
    CGPoint p = calculateLinear(value, a.origin, b.origin);
    return CGRectMake(p.x,
                      p.y,
                      a.size.width + (b.size.width - a.size.width) * value,
                      a.size.height + (b.size.height - a.size.height) * value);
}

- (void)pointArrayMixed:(RDAssetBlur *)blur a:(NSArray *)a b:(NSArray *)b value:(float)value {
    CGPoint p_leftTop = calculateLinear(value, CGPointFromString(a[0]), CGPointFromString(b[0]));
    CGPoint p_rightTop = calculateLinear(value, CGPointFromString(a[1]), CGPointFromString(b[1]));
    CGPoint p_rightBottom = calculateLinear(value, CGPointFromString(a[2]), CGPointFromString(b[2]));
    CGPoint p_leftBottom = calculateLinear(value, CGPointFromString(a[3]), CGPointFromString(b[3]));
//    NSLog(@"before:%@ %@", a, b);
//    NSLog(@"after:%@%@%@%@", NSStringFromCGPoint(p_leftTop), NSStringFromCGPoint(p_rightTop), NSStringFromCGPoint(p_rightBottom), NSStringFromCGPoint(p_leftBottom));
    [blur setPointsLeftTop:p_leftTop rightTop:p_rightTop rightBottom:p_rightBottom leftBottom:p_leftBottom];
}

- (void)cancelImage{
    _cancelGetImage = YES;
    [_mvPipeline.filters enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[RDGPUImageFilter class]]){
            ((RDGPUImageFilter *)obj).hasGetMVEffectImageBlock = NO;
            ((RDGPUImageFilter *)obj).frameImageProcessingCompletionBlock = nil;
            NSLog(@"_mvPipeline.filters-->: %zd",idx);
        }
    }];
}

- (void)getImageWithTimes:(NSMutableArray *) outputTimes scale:(float) scale completionHandler:(void (^)(UIImage* image, NSInteger idx))completionHandler{
    _cancelGetImage = NO;
    if (animationView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self getImageWithTimes:outputTimes index:0 scale:scale completionHandler:^(UIImage *image, NSInteger idx) {
                if(completionHandler){
                    completionHandler (image,idx);
                }
            }];
        });
    }else {
        [self getImageWithTimes:outputTimes index:0 scale:scale completionHandler:^(UIImage *image, NSInteger idx) {
            if(completionHandler){
                completionHandler (image,idx);
            }
        }];
    }
}
- (void)getImageWithTimes:(NSMutableArray *) outputTimes index:(NSInteger)index scale:(float) scale completionHandler:(void (^)(UIImage* image, NSInteger idx))completionHandler{
    if(_cancelGetImage){
        return;
    }
    __weak typeof(self) weakSelf = self;
    NSInteger idx = index +1;
    if(customDrawLayer.sublayers.count > 0 || _captions.count > 0 || _stickers.count > 0 || _nonRectangleCaptions.count > 0){
        [self getImageWithTime:[outputTimes[index] CMTimeValue] scale:scale completionHandler:^(UIImage *image) {
            if(completionHandler){
                completionHandler (image,index);
                if(_cancelGetImage){
                    return;
                }
                if(idx<outputTimes.count){
                    [weakSelf getImageWithTimes:outputTimes index:idx scale:scale completionHandler:completionHandler];
                }
            }
        }];
    }else{
        
        [self getImageAtTime:[outputTimes[index] CMTimeValue] scale:scale completion:^(UIImage *image) {
            if(completionHandler){
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    completionHandler (image,index);
                    if(_cancelGetImage){
                        return;
                    }
                    if(idx<outputTimes.count){
                        [weakSelf getImageWithTimes:outputTimes index:idx scale:scale completionHandler:completionHandler];
                    }
                });
            }
        }];
    }
}
- (void)getImageWithTime:(CMTime) outputTime scale:(float) scale completionHandler:(void (^)(UIImage* image))completionHandler{
    if (_sdkDisabled) {
        return;
    }
    if (animationView) {
        if (completionHandler) {
            [self getAnimationViewSnapShot:outputTime scale:scale completion:completionHandler];
        }
    }else {
        __block BOOL next = YES;
        if (customDrawLayer.sublayers.count > 0 || _captions.count > 0 || _stickers.count > 0 || _nonRectangleCaptions.count > 0) {
            
            void (^blockAction)(RDGPUImageOutput *output, CMTime time) = ^(RDGPUImageOutput *output, CMTime time) {
                //                dispatch_async(dispatch_get_main_queue(), ^{//20190719 本来返回的output是正确的，但因为新开一个线程，在进入新线程前又返回一个错误的output，导致获取缩略图错误，因为本来就在主线程，故不需要新开线程
                if(_cancelGetImage || !next){
                    if(completionHandler){
                        completionHandler(nil);
                        next = NO;
                    }
                    return;
                }
                [output useNextFrameForImageCapture];
                RDGPUImageFramebuffer* frameBuffer = output.framebufferForOutput;
                CGImageRef cgImage = [frameBuffer newCGImageFromFramebufferContents];
                UIImage* resultImage = [UIImage imageWithCGImage:cgImage];
                CGImageRelease(cgImage);
                
                UIImage *newImage;
                if (resultImage) { UIGraphicsBeginImageContext(CGSizeMake(resultImage.size.width*scale,resultImage.size.height*scale));
                    [resultImage drawInRect:CGRectMake(0, 0, resultImage.size.width*scale, resultImage.size.height*scale)];
                    newImage = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                }else{
                    newImage = [_renderer getImageAtTime:outputTime scale:scale];
                }
                if(completionHandler){
                    completionHandler(newImage);
                    next = NO;
                }
                //                });
            };
            if (CMTimeCompare(outputTime, kCMTimeZero) == 0) {
                outputTime = CMTimeMake(_editor.fps/2, _editor.fps);//有的视频前几帧是黑的
            }
            newAlphaBlendFilter.hasGetMVEffectImageBlock = YES;
            newAlphaBlendFilter.frameImageProcessingCompletionBlock = blockAction;
            [_renderer seekToTime:outputTime toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
                
            }];
        }else{
            [_renderer getImageAtTime:outputTime scale:scale completion:^(UIImage *image) {
                if (completionHandler) {
                    completionHandler(image);
                }
            }];
        }
    }
}

- (UIImage*)getImageAtTime:(CMTime) outputTime scale:(float) scale{
    if (_sdkDisabled) {
        return nil;
    }
    if (animationView) {
        @autoreleasepool {
            UIImage *resultImage;
            float time = CMTimeGetSeconds(outputTime);
            if (animationView.endStartTime > 0.0 && time > animationView.imagesDuration) {
                animationView.animationProgress = (time + animationView.endStartTime)/animationView.animationDuration;
            }else {
                animationView.animationProgress = time/animationView.animationDuration;
            }
            
            UIGraphicsBeginImageContextWithOptions(animationView.bounds.size, NO, 0);
            [animationView.layer renderInContext:UIGraphicsGetCurrentContext()];
            UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            if (snapshotImage) {
                if (scale == 1.0) {
                    resultImage = snapshotImage;
                }else {
                    resultImage = [self resizeImage:snapshotImage toSize:CGSizeMake(snapshotImage.size.width*scale,snapshotImage.size.height*scale)];
                    snapshotImage = nil;
                }
            }
            if (rdJsonAnimation.backgroundSourceArray.count > 0 || rdJsonAnimation.bgSourceArray.count > 0) {
                UIImage *image2 = [_renderer getImageAtTime:outputTime scale:scale];
                if (image2) {
                    resultImage = [self addImage:image2 withImage:resultImage];
                    if (movieEffects.count > 0) {
                        UIImage *image3 = [_renderer getImageAtTime:outputTime scale:scale];
                        if (image3) {
                            resultImage = [self addImage:resultImage withImage:image3];
                        }
                    }
                }else if (movieEffects.count > 0) {
                    UIImage *image3 = [_renderer getImageAtTime:outputTime scale:scale];
                    if (image3) {
                        resultImage = [self addImage:resultImage withImage:image3];
                    }
                }
            }
            else if (movieEffects.count > 0) {
                UIImage *image2 = [_renderer getImageAtTime:outputTime scale:scale];
                if (image2) {
                    resultImage = [self addImage:resultImage withImage:image2];
                }
            }
            return resultImage;
        }
    }
    return [_renderer getImageAtTime:outputTime scale:scale];
}
- (void)getImageAtTime:(CMTime) outputTime scale:(float) scale completion:(void (^)(UIImage *image))completionHandler {
    if (_sdkDisabled) {
        return;
    }
    if (animationView) {
        if (completionHandler) {
            [self getAnimationViewSnapShot:outputTime scale:scale completion:completionHandler];
        }
    }else {
        [_renderer getImageAtTime:outputTime scale:scale completion:^(UIImage *image) {
            if (completionHandler) {
                completionHandler(image);
            }
        }];
    }
}

- (UIImage *)getCurrentFrameWithScale:(float)scale {
    return [_renderer getCurrentFrameWithScale:scale];
}

- (void)getAnimationViewSnapShot:(CMTime)outputTime scale:(float) scale completion:(void (^)(UIImage *image))completionHandler
{
    @autoreleasepool {
        float time = CMTimeGetSeconds(outputTime);
        if (animationView.endStartTime > 0.0 && time > animationView.imagesDuration) {
            animationView.animationProgress = (time + animationView.endStartTime)/animationView.animationDuration;
        }else {
            animationView.animationProgress = time/animationView.animationDuration;
        }
        UIGraphicsBeginImageContextWithOptions(animationView.bounds.size, NO, 0);//NO:透明通道不被渲染
        [animationView.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        __block UIImage *resultImage;
        if (snapshotImage) {
            if (scale == 1.0) {
                resultImage = snapshotImage;
            }else {
                resultImage = [self resizeImage:snapshotImage toSize:CGSizeMake(snapshotImage.size.width*scale,snapshotImage.size.height*scale)];
            }
        }
        if (rdJsonAnimation.backgroundSourceArray.count > 0 || rdJsonAnimation.bgSourceArray.count > 0) {
            __weak typeof(self) weakSelf = self;
            [_renderer getImageAtTime:outputTime scale:scale completion:^(UIImage *image) {
                resultImage = [weakSelf addImage:image withImage:resultImage];
                if (movieEffects.count > 0) {
                    [weakSelf getMVScreenshotImage:outputTime scale:scale completion:^(UIImage *image) {
                        resultImage = [weakSelf addImage:resultImage withImage:image];
                        if (completionHandler) {
                            completionHandler(resultImage);
                        }
                    }];
                }else if (completionHandler) {
                    completionHandler(resultImage);
                }
            }];
        }
        else if (movieEffects.count > 0) {
            __weak typeof(self) weakSelf = self;
            [self getMVScreenshotImage:outputTime scale:scale completion:^(UIImage *image) {
                resultImage = [weakSelf addImage:resultImage withImage:image];
                if (completionHandler) {
                    completionHandler(resultImage);
                }
            }];
        }
        else if (completionHandler) {
            completionHandler(resultImage);
        }
    }
}

- (void)getMVScreenshotImage:(CMTime)outputTime scale:(float) scale completion:(void (^)(UIImage *image))completionHandler
{
    if (customDrawLayer.sublayers.count > 0 || _captions.count > 0 || _stickers.count > 0 || _nonRectangleCaptions.count > 0) {
        
        void (^blockAction)(RDGPUImageOutput *output, CMTime time) = ^(RDGPUImageOutput *output, CMTime time) {
//            dispatch_async(dispatch_get_main_queue(), ^{
            
                [output useNextFrameForImageCapture];
                RDGPUImageFramebuffer* frameBuffer = output.framebufferForOutput;
                CGImageRef cgImage = [frameBuffer newCGImageFromFramebufferContents];
                UIImage* resultImage = [UIImage imageWithCGImage:cgImage];
                CGImageRelease(cgImage);
                
                UIImage *newImage;
                if (resultImage) {
                    UIGraphicsBeginImageContext(CGSizeMake(resultImage.size.width*scale,resultImage.size.height*scale));
                    [resultImage drawInRect:CGRectMake(0, 0, resultImage.size.width*scale, resultImage.size.height*scale)];
                    newImage = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                }else{
                    newImage = [_renderer getImageAtTime:outputTime scale:scale];
                }
                if(completionHandler){
                    completionHandler(newImage);
                }
//            });
        };
        if (CMTimeCompare(outputTime, kCMTimeZero) == 0) {
            outputTime = CMTimeMake(_editor.fps/2, _editor.fps);//有的视频前几帧是黑的
        }
        newAlphaBlendFilter.hasGetMVEffectImageBlock = YES;
        newAlphaBlendFilter.frameImageProcessingCompletionBlock = blockAction;
        [_renderer seekToTime:outputTime toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
            
        }];
    }else{
        [_renderer getImageAtTime:outputTime scale:scale completion:^(UIImage *image) {
            if (completionHandler) {
                completionHandler(image);
            }
        }];
    }
}

- (UIImage *)addImage:(UIImage *)image1 withImage:(UIImage *)image2 {
    @autoreleasepool {
        UIGraphicsBeginImageContext(image1.size);
        [image1 drawInRect:CGRectMake(0, 0, image1.size.width, image1.size.height)];
        [image2 drawInRect:CGRectMake((image1.size.width - image2.size.width)/2,(image1.size.height - image2.size.height)/2, image2.size.width, image2.size.height)];
        UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return resultingImage;
    }
}

- (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size {
    @autoreleasepool {
        UIGraphicsBeginImageContext(size);
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return resultImage;
    }
}

- (void)addGlobalFilter{
    gFilter = [[RDGPUImageToneCurveFilter alloc] initWithACVURL:nil];
    
}

+ (float)getAudioBitRate:(NSURL *)url {
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] > 0) {
        AVAssetTrack* audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        return audioTrack.estimatedDataRate;
    }
    return 0.0;
}

- (void)exportMovieURL:(NSURL*) movieURL
                  size:(CGSize) size
               bitrate:(float)bitrate
                   fps:(int)fps
          audioBitRate:(int)audioBitRate
   audioChannelNumbers:(int)audioChannelNumbers
maxExportVideoDuration:(float)maxExportVideoDuration
              progress:(void(^)(float progress))progress
               success:(void(^)())success
                  fail:(void(^)(NSError *error))fail
{
    if (_sdkDisabled) {
        return;
    }
    if(!m_appkey || m_appkey.length == 0 || ((!m_appsecret || m_appsecret.length == 0) && m_licenceKey.length == 0)){
        if (fail) {
            NSDictionary *userInfo= [NSDictionary dictionaryWithObject:@"appkey 和 appsecret 不能为空" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"com.17rd.rdvecore" code:200 userInfo:userInfo];
            NSLog(@"error:%@",error);
            fail(error);
        }
        return;
    }
    size = [self correctSize:size];
    
    lastProgress = 0.0;
    isExporting = YES;
    exporterURL = movieURL;
    exportSize = size;
    exportBitrate = bitrate;
    exportAudioBitRate = audioBitRate;
    exportMetadata = nil;
    
    if (audioChannelNumbers <= 0) {
        audioChannelNumbers = 1;
    }else if (audioChannelNumbers > 2) {
        audioChannelNumbers = 2;
    }
    exportAudioChannelNumbers = audioChannelNumbers;
    exportProgressBlock = progress;
    exportSuccessBlock = success;
    exportFailBlock = fail;
    _maxVideoDuration = MIN(MAX(maxExportVideoDuration, 0), _videoDuration);
    
    if(_maxVideoDuration <= 0){
        _maxVideoDuration = _videoDuration;
    }
    [self exportMovie];//20190821 wuxiaoxia 网络不好的情况，导出进度一直在0,改为异步检查授权
    if (m_appsecret.length == 0) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *packname = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        [params setObject:@"ios" forKey:@"os"];
        [params setObject:packname forKey:@"package"];
        
        NSDictionary *reslutDic = [RDRecordHelper checkSignaturewWithAPPKey:m_appkey appSecret:m_appsecret params:params andUploadUrl:@"http://dianbook.17rd.com/api/appverify/export"];
        dispatch_async(dispatch_get_main_queue(), ^{
#if 1   //20190821 wuxiaoxia 网络不好的情况，导出进度一直在0,改为异步检查授权
            int code = [[reslutDic objectForKey:@"code"] intValue];
            if (reslutDic && code == 2002) {//导出次数超出限制
                [self cancelExportMovie:nil];
                
                NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:[reslutDic objectForKey:@"message"]  forKey:NSLocalizedDescriptionKey];
                NSError *exportError = [NSError errorWithDomain:@"com.17rd.rdvecore" code:code userInfo:errorInfo];
                exportFailBlock(exportError);
            }
#else
            if (!reslutDic) {
                [self exportMovie];
            }else {
                int code = [[reslutDic objectForKey:@"code"] intValue];
                if (code != 2002) {
                    [self exportMovie];
                }else {
                    isExporting = NO;
                    
                    if (code == 2002) {
                        NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:[reslutDic objectForKey:@"message"]  forKey:NSLocalizedDescriptionKey];
                        NSError *exportError = [NSError errorWithDomain:@"com.17rd.rdvecore" code:code userInfo:errorInfo];
                        exportFailBlock(exportError);
                    }else {
                        exportFailBlock(nil);
                    }
                }
            }
#endif
        });
    });
}

/** metadata  设置metadata
 */
- (void)exportMovieURL:(NSURL*) movieURL
                  size:(CGSize) size
               bitrate:(float)bitrate
                   fps:(int)fps
              metadata:(NSArray<AVMetadataItem*>*) metadata
          audioBitRate:(int)audioBitRate
   audioChannelNumbers:(int)audioChannelNumbers
maxExportVideoDuration:(float)maxExportVideoDuration
              progress:(void(^)(float progress))progress
               success:(void(^)())success
                  fail:(void(^)(NSError *error))fail
{
    if (_sdkDisabled) {
        return;
    }
    if(!m_appkey || m_appkey.length == 0 || ((!m_appsecret || m_appsecret.length == 0) && m_licenceKey.length == 0)){
        if (fail) {
            NSDictionary *userInfo= [NSDictionary dictionaryWithObject:@"appkey 和 appsecret 不能为空" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"com.17rd.rdvecore" code:200 userInfo:userInfo];
            NSLog(@"error:%@",error);
            fail(error);
        }
        return;
    }
    size = [self correctSize:size];
    
    lastProgress = 0.0;
    isExporting = YES;
    exporterURL = movieURL;
    exportSize = size;
    exportBitrate = bitrate;
    exportAudioBitRate = audioBitRate;
    exportMetadata = metadata;
    
    if (audioChannelNumbers <= 0) {
        audioChannelNumbers = 1;
    }else if (audioChannelNumbers > 2) {
        audioChannelNumbers = 2;
    }
    exportAudioChannelNumbers = audioChannelNumbers;
    exportProgressBlock = progress;
    exportSuccessBlock = success;
    exportFailBlock = fail;
    _maxVideoDuration = MIN(MAX(maxExportVideoDuration, 0), _videoDuration);
    
    if(_maxVideoDuration <= 0){
        _maxVideoDuration = _videoDuration;
    }
    [self exportMovie];//20190821 wuxiaoxia 网络不好的情况，导出进度一直在0,改为异步检查授权
    if (m_appsecret.length == 0) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *packname = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        [params setObject:@"ios" forKey:@"os"];
        [params setObject:packname forKey:@"package"];
        
        NSDictionary *reslutDic = [RDRecordHelper checkSignaturewWithAPPKey:m_appkey appSecret:m_appsecret params:params andUploadUrl:@"http://dianbook.17rd.com/api/appverify/export"];
        dispatch_async(dispatch_get_main_queue(), ^{
#if 1   //20190821 wuxiaoxia 网络不好的情况，导出进度一直在0,改为异步检查授权
            int code = [[reslutDic objectForKey:@"code"] intValue];
            if (reslutDic && code == 2002) {//导出次数超出限制
                [self cancelExportMovie:nil];
                
                NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:[reslutDic objectForKey:@"message"]  forKey:NSLocalizedDescriptionKey];
                NSError *exportError = [NSError errorWithDomain:@"com.17rd.rdvecore" code:code userInfo:errorInfo];
                exportFailBlock(exportError);
            }
#else
            if (!reslutDic) {
                [self exportMovie];
            }else {
                int code = [[reslutDic objectForKey:@"code"] intValue];
                if (code != 2002) {
                    [self exportMovie];
                }else {
                    isExporting = NO;
                    if (code == 2002) {
                        NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:[reslutDic objectForKey:@"message"]  forKey:NSLocalizedDescriptionKey];
                        NSError *exportError = [NSError errorWithDomain:@"com.17rd.rdvecore" code:code userInfo:errorInfo];
                        exportFailBlock(exportError);
                    }else {
                        exportFailBlock(nil);
                    }
                }
            }
#endif
        });
    });
}

- (void)cancelExportMovie:(void(^)())cancelBlock{
    
   
    getScreenshotFinish = FALSE;
    _editor.isExporting = NO;
    [animationLayerArray enumerateObjectsUsingBlock:^(CALayer *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.contents = nil;
    }];
    [animationLayerArray removeAllObjects];
    [_mvPipeline removeAllFilters];
    _mvPipeline = nil;   
    
    [_filterPipeline removeAllFilters];
    _filterPipeline = nil;
    
    isExporting = NO;
    prevAnimationImage = nil;
    prevAnimationImageName = nil;
    prevBufferTime = kCMTimeInvalid;
    isCancelExporting = YES;
    writer.cancelReading = YES;
    [writer cancelRecording];
    //exportMovie = nil;
    if (exportMovieArray.count > 0) {
        [exportMovieArray removeAllObjects];
    }
    if (exportMVFilterArray.count > 0) {
        [exportMVFilterArray removeAllObjects];
    }
    lastProgress = 0;
    [self refreshWaterAndSubtitleEffect];
    if(cancelBlock){
        cancelBlock();
    }
    
    //writer = nil;
    [self removeEndLogoMark];
    [self removeWaterMark];
    [self setEditorWatermarksWithIsExport:NO];
    if (!CGSizeEqualToSize(_editor.videoSize, originVideoSize)) {
        [self setEditorVideoSize:originVideoSize];
        [_editor build];
    }
    [self prepare];//20170810 wuxiaoxia 需要在主线程，否则取消导出后，不能播放
    getScreenshotFinish = TRUE;
}

- (void)refreshWaterAndSubtitleEffect{
//    mvArray = [NSMutableArray array];
    
    currentFilterType = RDVideoRealTimeFilterTypeNone;
    startTime = kCMTimeZero;
    endTime = kCMTimeZero;
    
    if(!suplayer){
        suplayer = [CALayer layer];
        suplayer.backgroundColor = [UIColor clearColor].CGColor;
        suplayer.frame = CGRectMake(0, 0, _editor.videoSize.width, _editor.videoSize.height);
    }
    if(!subtitleEffectlayer){
        subtitleEffectlayer = [CALayer layer];
        subtitleEffectlayer.backgroundColor = [UIColor clearColor].CGColor;
        subtitleEffectlayer.frame = CGRectMake(0, 0, _editor.videoSize.width, _editor.videoSize.height);
        //字幕、特效
        [suplayer addSublayer:subtitleEffectlayer];
    }
    
    _doodleLayer.opacity = 0.0;
    _watermarkLayer.opacity = 0.0;
    _watermarkTextLayer.opacity = 0.0;
    
    [self refreshFilters];
    _endLogomarkLayer.opacity = 0.0;
    
}
+ (NSArray<AVMetadataItem*>*) assetMetadata:(NSURL*)url
{
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url options:nil];
    return asset.metadata;
}

- (void)exportMovie {
    double startTime = CACurrentMediaTime();
    for(int j = 0; j < compositionArray.count; j++)
    {
        RDAEVideoComposition *composition = [compositionArray objectAtIndex:j];
        if(composition.reverseReader.status == AVAssetReaderStatusReading){
            
            [composition.reverseReader cancelReading];
            composition.reverseReader = nil;
            composition.oldSampleFrameTime = 0;
        }
    }
    
    exportTime = 0.0;
    prevAnimationImage = nil;
    prevAnimationImageName = nil;
    prevBufferTime = kCMTimeInvalid;
    [animationLayerArray enumerateObjectsUsingBlock:^(CALayer *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.contents = nil;
    }];
    [animationLayerArray removeAllObjects];
    if (exportMovie) {
        writer = nil;
        exportMovie = nil;

    }
    NSString *folder = [exporterURL.path stringByDeletingLastPathComponent];
    if(![[NSFileManager defaultManager] fileExistsAtPath:folder]){
        [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    writer = nil;
    unlink([exporterURL.path UTF8String]);
    isCancelExporting = NO;
    NSLog(@"****%s",__func__);
    
    __weak typeof(self) weakSelf = self;
    __block typeof(self) blSelf = self;
    if (animationView && _editor.fps != rdJsonAnimation.exportFps) {
        _editor.fps = rdJsonAnimation.exportFps;
    }else {
        _editor.fps = originFps;
    }
    _editor.isExporting = YES;
    if (!CGSizeEqualToSize(_editor.videoSize, exportSize)) {
        [self setEditorVideoSize:exportSize];
    }
    //20190611 没有mv，且没有背景视频的情况，水印需要用layer的方式来添加
    //20191118 没有MV的AE模板，水印需要用layer的方式来添加。因为有的背景视频后半部分会是黑帧
    if (rdJsonAnimation
        && _logoWatermark
        && _logoWatermark.vvAsset.url
        && _logoWatermark.vvAsset.type == RDAssetTypeImage
        && movieEffects.count == 0) {
        [self addWaterMark:[UIImage imageWithContentsOfFile:_logoWatermark.vvAsset.url.path] withPoint:_logoWatermark.vvAsset.rectInVideo.origin scale:1.0];
    }
    [_editor build];
    exportMovie = [[PPMovie alloc] initWithComposition:_editor.composition
                                   andVideoComposition:_editor.videoComposition
                                           andAudioMix:_editor.audioMix];
    exportMovie.audioChannelNumbers = exportAudioChannelNumbers;
    
    [exportMovieArray addObject:exportMovie];
    
    if (mvEditorArray.count > 0) {
        for (int i = 0; i<mvEditorArray.count; i++) {
            RDMVFileEditor* mvEditor = (RDMVFileEditor*)mvEditorArray[i];
            VVMovieEffect* movieEffect = movieEffects[i];
            PPMovie* shaderPPMovie = [[PPMovie alloc] initWithComposition:mvEditor.composition andVideoComposition:mvEditor.videoComposition andAudioMix:mvEditor.audioMix];
            shaderPPMovie.audioChannelNumbers = exportAudioChannelNumbers;
            
            [exportMovieArray addObject:shaderPPMovie];
            
            if (movieEffect.type == RDVideoMVEffectTypeScreen) {
                RDGPUImageFilter* screenBlendFilter = [[RDGPUImageScreenBlendFilter alloc] init];
                [shaderPPMovie addTarget:screenBlendFilter atTextureLocation:1];
                [exportMVFilterArray addObject:screenBlendFilter];
            }
            else if (movieEffect.type == RDVideoMVEffectTypeGray){
                RDGPUImageFilter* hardLightBlendFilter = [[RDGPUImageHardLightBlendFilter alloc] init];
                [shaderPPMovie addTarget:hardLightBlendFilter atTextureLocation:1];
                [exportMVFilterArray addObject:hardLightBlendFilter];
            }
            else if (movieEffect.type ==RDVideoMVEffectTypeGreen){
                RDGPUImageFilter* chromaKeyBlendFilter = [[RDGPUImageChromaKeyBlendFilter alloc] init];
                [shaderPPMovie addTarget:chromaKeyBlendFilter atTextureLocation:0];
                [exportMVFilterArray addObject:chromaKeyBlendFilter];
            }
            else if(movieEffect.type == RDVideoMVEffectTypeMask){
                RDMVFilter* mvFilter = [[RDMVFilter alloc] init];
                [shaderPPMovie addTarget:mvFilter atTextureLocation:1];
                [exportMVFilterArray addObject:mvFilter];
            }
        }
    }
    
#if 0
    NSDictionary *videoSetting = @
    {
    AVVideoCodecKey: AVVideoCodecH264,
    AVVideoWidthKey: @(size.width),
    AVVideoHeightKey: @(size.height),
    AVVideoCompressionPropertiesKey: @
        {
        AVVideoAverageBitRateKey: @(bitrate * 1000 * 1000),
        AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel,
        },
    };
    
    NSDictionary* audioSettings = @
    {
    AVFormatIDKey: @(kAudioFormatMPEG4AAC),
    AVNumberOfChannelsKey: @2,
    AVSampleRateKey: @44100,
    AVEncoderBitRateKey: @128000,
    };
    
    
    
    //MiniPad上会崩溃？ why
    
    writer = [[RDGPUImageMovieWriter alloc] initWithMovieURL:movieURL size:size fileType:AVFileTypeMPEG4 outputSettings:videoSetting];
    [writer setHasAudioTrack:YES audioSettings:audioSettings];
    exportMovie.audioEncodingTarget = writer;
    [exportMovie enableSynchronizedEncodingUsingMovieWriter:writer];
    [exportMovie addTarget:writer];
#else
    _endLogomarkLayer.opacity = 0.0;
    NSLog(@"****%s,line:%d",__func__,__LINE__);
    writer = [[PPMovieWriter alloc] initWithMovieURL:exporterURL
                                                size:exportSize
                                              movies:[exportMovieArray copy]
                                            metadata:exportMetadata
                                    videoMaxDuration:_maxVideoDuration
                                 videoAverageBitRate:exportBitrate
                                        audioBitRate:exportAudioBitRate
                                 audioChannelNumbers:exportAudioChannelNumbers
                                       totalDuration:CMTimeGetSeconds(exportMovie.compositon.duration)
                                            progress:^(NSNumber *percent) {
//        NSLog(@"|||||||||||||||||| %f",[percent floatValue]);
        [weakSelf updateProgress:[percent floatValue]];
    }];
    NSLog(@"****%s,line:%d",__func__,__LINE__);
#endif
    [self refreshFilters];
    
    NSLog(@"****%s,line:%d",__func__,__LINE__);
    
    [writer startRecording];
    
    for (int i = 0;i<exportMovieArray.count;i++) {
        PPMovie* movie = exportMovieArray[i];
        [movie startProcessing];
    }
    //设置背景颜色
    [_editor setVirtualVideoBgColor:backGroundColor];
    
    if (animationView && movieEffects.count > 0) {
        if (rdJsonAnimation.backgroundSourceArray.count == 0 && rdJsonAnimation.bgSourceArray.count == 0) {
            animationView.isBlackVideo = YES;
        }
        animationView.animationPlayCount = animationPlayCount;
        [_editor setLottieView:animationView];
    }
    [writer setCompletionBlock:^{
        NSLog(@"导出耗时:%lf",CACurrentMediaTime() - startTime);
        [weakSelf completion];
    }];
    NSLog(@"****%s,line:%d",__func__,__LINE__);
    
    writer.failureBlock = ^(NSError *error) {
        //20170615 添加中断操作 中断不调fail
        if(blSelf->isCancelExporting){
            //[weakSelf exportCancel];
        }else{
            if(error){
                [weakSelf exportFail:error];
            }
        }
        
    };
}

- (void) completion{
    isExporting = NO;
    exportSuccessBlock();
    exportMovie.audioEncodingTarget = nil;
//    [exportMovie removeAllTargets];
//    exportMovie = nil;
    
    for (int i = 0;i<exportMovieArray.count;i++) {
        PPMovie* movie = exportMovieArray[i];
        [movie pause];
        [movie endProcessing];
        [movie removeAllTargets];
    }
    [exportMovieArray removeAllObjects];
    [exportMVFilterArray removeAllObjects];
    
    writer = nil;
    
}
- (void) progress{
    NSLog(@"%f ",exportMovie.progress);
}

- (void)stopExport{
    NSLog(@"%s",__func__);
//    [exportMovie pause];
//    [exportMovie endProcessing];
//    [exportMovie removeAllTargets];
    
    writer.cancelReading = YES;
    [writer cancelRecording];
    for (int i = 0;i< exportMovieArray.count;i++) {
        PPMovie* movie = exportMovieArray[i];
        [movie pause];
        [movie endProcessing];
        [movie removeAllTargets];
    }
    
    [exportMovieArray removeAllObjects];
    [exportMVFilterArray removeAllObjects];

    //exportMovie = nil;
}

- (void)resumeExport {
    if (_sdkDisabled) {
        return;
    }
    //20170623 emmet 修复导出多次按home键崩溃的bug （不能再stop释放 ppmove ）重新导出时释放它
    if(!writer.cancelReading){
        return;
    }
    
    
    [self exportMovie];
}
- (void)addMVEffect:(NSMutableArray<VVMovieEffect *> *)mveffects{
    [_mvPipeline removeAllFilters];
    // 修改MV效果
    movieEffects = mveffects;
    //20180723 wuxiaoxia 将mv与scene构建为一个虚拟视频
    _editor.movieEffects = mveffects;
}
- (void)removeWaterMark{
    
    _watermarkLayer.opacity = 0.0;
    _watermarkTextLayer.opacity = 0.0;
//    if(_watermarkLayer.superlayer)
//        [_watermarkLayer removeFromSuperlayer];
//    _watermarkLayer = nil;
//    if(_watermarkTextLayer.superlayer)
//        [_watermarkTextLayer removeFromSuperlayer];
//    _watermarkTextLayer = nil;
}

- (void)removeEndLogoMark{
    _endLogomarkLayer.opacity = 0.0;
    if(_endLogomarkLayer.superlayer)
        [_endLogomarkLayer removeFromSuperlayer];
    _endLogomarkLayer = nil;
//    gaosiFilter.blurRadiusInPixels = 0;
}

- (void)addDoodles:(NSMutableArray <RDDoodle *>*)doodles{
    if(!_doodleLayer){
        _doodleLayer = [CALayer layer];
        _doodleLayer.backgroundColor = [UIColor clearColor].CGColor;
        [suplayer addSublayer:_doodleLayer];
    }
    _doodleLayer.opacity = 1.0;
    if(!_doodleLayers){
        _doodleLayers = [NSMutableArray array];
    }else{
        [_doodleLayers removeAllObjects];
    }
    for (int i = 0; i< doodles.count; i++) {
        RDDoodleLayer * doodleLayer = [RDDoodleLayer layer];
        doodleLayer.backgroundColor = [UIColor clearColor].CGColor;
        RDDoodle * doodle = doodles[i];
        
        CGRect doodleRect = CGRectMake(0, 0, _editor.videoSize.width, _editor.videoSize.height);
        doodleLayer.frame = doodleRect;
        doodleLayer.position = CGPointMake(_editor.videoSize.width/2.0, _editor.videoSize.height/2.0);
        UIImage *image = [UIImage imageWithContentsOfFile:doodle.path];
        doodleLayer.contents= (id)image.CGImage;
        doodleLayer.opacity = 0.0;
        doodleLayer.path = doodle.path;
        doodleLayer.timeRange = doodle.timeRange;
        [_doodleLayers addObject:doodleLayer];
        [_doodleLayer addSublayer:doodleLayer];
    }
}

- (void) addWaterMark:(UIImage *)image withPoint:(CGPoint)point scale:(CGFloat)scale
{
    if(!_watermarkLayer){
        _watermarkLayer = [CALayer layer];
        _watermarkLayer.backgroundColor = [UIColor clearColor].CGColor;
        [suplayer addSublayer:_watermarkLayer];
    }
    CGRect waterRect = CGRectMake(_editor.videoSize.width*point.x, _editor.videoSize.height*point.y, image.size.width*scale, image.size.height*scale);
    _watermarkLayer.frame = waterRect;
    _watermarkLayer.position = CGPointMake((_editor.videoSize.width - (image.size.width*scale))*point.x + ((image.size.width*scale)/2.0), (_editor.videoSize.height - (image.size.height*scale))*point.y + ((image.size.height*scale)/2.0));
    _watermarkLayer.contents= (id)image.CGImage;
    
    _watermarkLayer.opacity = 1.0;
}

- (void) addWaterMark:(NSString *)waterText color:(UIColor *)waterColor font:(UIFont *)waterFont withPoint:(CGPoint)point{
    
    if(!waterColor){
        waterColor = [UIColor whiteColor];
    }
    
    if(!waterText){
        waterText = @"";
    }
    if(!waterFont){
        waterFont = [UIFont boldSystemFontOfSize:30];
    }
    
    if(!_watermarkTextLayer){
        _watermarkTextLayer = [CATextLayer layer];
        _watermarkTextLayer.backgroundColor = [UIColor clearColor].CGColor;
        [suplayer addSublayer:_watermarkTextLayer];
    }
    
    _watermarkTextLayer.opacity = 1.0;
    CGSize size = [waterText boundingRectWithSize:_editor.videoSize options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : waterFont} context:nil].size;
    
    CGRect waterRect = CGRectMake(_editor.videoSize.width*point.x, _editor.videoSize.height*point.y, size.width, size.height);
    _watermarkTextLayer.frame = waterRect;
    _watermarkTextLayer.position = CGPointMake((_editor.videoSize.width - size.width)*point.x + size.width/2.0, (_editor.videoSize.height - size.height)*point.y + size.height/2.0);
    
    
    NSAttributedString * attributedString;
    
    CTParagraphStyleSetting lineBreakMode;
    CTLineBreakMode lineBreak = kCTLineBreakByCharWrapping; //换行模式
    lineBreakMode.spec = kCTParagraphStyleSpecifierLineBreakMode;
    lineBreakMode.value = &lineBreak;
    lineBreakMode.valueSize = sizeof(CTLineBreakMode);
    
    //行间距
    CTParagraphStyleSetting LineSpacing;
    CGFloat spacing = 1.0;  //指定间距
    LineSpacing.spec = kCTParagraphStyleSpecifierLineSpacingAdjustment;
    LineSpacing.value = &spacing;
    LineSpacing.valueSize = sizeof(CGFloat);
    
    CTParagraphStyleSetting settings[] = {lineBreakMode,LineSpacing};
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, 2);   //第二个参数为settings的长度
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:waterText];
    [str addAttribute:NSFontAttributeName
                value:waterFont
                range:NSMakeRange(0, waterText.length)];
    [str addAttribute:NSForegroundColorAttributeName
                value:waterColor
                range:NSMakeRange(0, waterText.length)];
    
    
    [str addAttribute:(NSString *)kCTParagraphStyleAttributeName
                value:(id)paragraphStyle
                range:NSMakeRange(0, attributedString.length)];
    if([[[UIDevice currentDevice]systemVersion] floatValue]>=8.0){
        _watermarkTextLayer.string = str;//string;
    }else{
        _watermarkTextLayer.string = waterText;
    }
    NSLog(@"----------------caption str:%@",str);
    str = nil;
    
    CFStringRef fontName = (__bridge CFStringRef)waterFont.fontName;
    CGFontRef fontRef = CGFontCreateWithFontName(fontName);
    _watermarkTextLayer.fontSize = waterFont.pointSize;
    _watermarkTextLayer.font = fontRef;// (__bridge CFTypeRef _Nullable)ppCaption.tFontName;
    _watermarkTextLayer.shadowColor = waterColor.CGColor;
    _watermarkTextLayer.shadowRadius = 2;
    _watermarkTextLayer.truncationMode = @"start";
    _watermarkTextLayer.foregroundColor = waterColor.CGColor;
    _watermarkTextLayer.shadowOffset = CGSizeMake(1, 1);
    _watermarkTextLayer.alignmentMode   = @"center";
    _watermarkTextLayer.wrapped = YES;
    _watermarkTextLayer.opacity = 1.0;
    _watermarkTextLayer.contentsGravity = kCAAlignmentCenter;
    
    CGFontRelease(fontRef);//释放
    [_watermarkTextLayer performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
    CFRelease(paragraphStyle);
}

- (void)setCustomFilterArray:(NSMutableArray<RDCustomFilter *> *)customFilterArray {
    _customFilterArray = customFilterArray;
    _editor.customFilterArray = customFilterArray;
}

- (void)setWatermarkArray:(NSMutableArray<RDWatermark *> *)watermarkArray {
    _watermarkArray = watermarkArray;
    [self setEditorWatermarksWithIsExport:NO];
}

- (void)setLogoWatermark:(RDWatermark *)logoWatermark {
    _logoWatermark = logoWatermark;
    [self setEditorWatermarksWithIsExport:YES];
}

- (void)setEndlogoWatermark:(RDWatermark *)endlogoWatermark {
    _endlogoWatermark = endlogoWatermark;
    [self setEditorWatermarksWithIsExport:YES];
}

- (void)setEditorWatermarksWithIsExport:(BOOL)isExport {
    NSMutableArray *array = [NSMutableArray array];
    if (_watermarkArray.count > 0) {
        [array addObjectsFromArray:_watermarkArray];
    }
    if (isExport) {
        if (_logoWatermark) {
            [array addObject:_logoWatermark];
        }
        if (_endlogoWatermark) {
            [array addObject:_endlogoWatermark];
        }
    }
    _editor.watermarks = array;
}

- (void) addEndLogoMark:(UIImage *)logoImage userName:(NSString *)userName showDuration:(float)showDuration fadeDuration:(float)fadeDuration{
    _showDuration = showDuration;
    _fadeDuration = fadeDuration;
    UIImage *image = [self getEndLogoImage:logoImage userName:userName imageSize:_editor.videoSize];//此处没有释放？
    _endLogomarkLayer = [CALayer layer];
    _endLogomarkLayer.opacity = 0.0;
    _endLogomarkLayer.backgroundColor = [UIColor clearColor].CGColor;
    _endLogomarkLayer.frame = suplayer.frame;
    _endLogomarkLayer.contents = (id)image.CGImage;
}

- (UIImage *)getEndLogoImage:(UIImage *)logoImage userName:(NSString *)userName imageSize:(CGSize)imageSize{
    
    NSString* bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"RDVECore.bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    ;
    UIImage *dateImage = [UIImage imageWithContentsOfFile:[bundle pathForResource:[NSString stringWithFormat:@"endLogo/片尾caise_06"] ofType:@"png"]];
    UIImage *userImage = [UIImage imageWithContentsOfFile:[bundle pathForResource:[NSString stringWithFormat:@"endLogo/片尾caise_08"] ofType:@"png"]];
    UIImage *topImage = logoImage;
    
//    CGSize newImage_size = imageSize;
    
    float spanwidth = (imageSize.width<imageSize.height ? 5 : 20);
    
    CGSize imageResultSize = imageSize;//CGSizeMake(logoImage.size.width, logoImage.size.height + 20 + userImage.size.height);
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(imageResultSize.width,imageResultSize.height), NO, 0.0);
    
    CGRect logoRect = CGRectMake((imageResultSize.width - topImage.size.width)/2.0,(imageResultSize.height - topImage.size.height)/2.0 - dateImage.size.height/2.0,topImage.size.width,topImage.size.height);
    
    [topImage drawInRect:logoRect];
    [UIColorFromRGB(0xe4e4e4) set];//
    
    NSString *dateStr = [RDRecordHelper getSystemCureentTime];
    NSMutableString *mDateStr = [[NSMutableString alloc] initWithString:dateStr];
    NSMutableString *mUsernamestr;
    float fontSize =  30 ;
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    
    CGSize constraintSize = CGSizeMake(MAXFLOAT, fontSize);
    NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys: font,NSFontAttributeName,[UIColor whiteColor],NSForegroundColorAttributeName, nil];
    CGRect dateStrRect = [dateStr boundingRectWithSize:constraintSize
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                            attributes:attributes
                                               context:nil];
    
    CGRect userNameStrRect = CGRectZero;
    
    float bottomImageoriginy= logoRect.size.height  + logoRect.origin.y + 16;
    
    float height = bottomImageoriginy + (dateImage.size.height - dateStrRect.size.height)/2.0;
    
    
    if([userName isKindOfClass:[NSString class]]){
        if(userName.length>0){
            
            userNameStrRect = [userName boundingRectWithSize:constraintSize
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                  attributes:attributes
                                                     context:nil];
            
            float totalWidth = dateStrRect.size.width + userNameStrRect.size.width + dateImage.size.width + userImage.size.width + spanwidth*3.0;
            float originx = (imageResultSize.width - totalWidth)/2.0;
            
            
            [mDateStr drawInRect:CGRectMake(originx + dateImage.size.width + spanwidth,height ,dateStrRect.size.width,dateStrRect.size.height) withAttributes:attributes];
            
            mUsernamestr = [[NSMutableString alloc] initWithString:userName];
            
            [mUsernamestr drawInRect:CGRectMake(originx + dateImage.size.width + dateStrRect.size.width + userImage.size.width + spanwidth * 3.0, height,userNameStrRect.size.width,userNameStrRect.size.height) withAttributes:attributes];
        }else{
            float totalWidth = dateStrRect.size.width + dateImage.size.width + spanwidth;
            float originx = (imageResultSize.width - totalWidth)/2.0;
            
            [mDateStr drawInRect:CGRectMake(originx + dateImage.size.width + spanwidth,height ,dateStrRect.size.width,dateStrRect.size.height) withAttributes:attributes];
        }
    }else{
        float totalWidth = dateStrRect.size.width + dateImage.size.width+ spanwidth;
        float originx = (imageResultSize.width - totalWidth)/2.0;
        
        [mDateStr drawInRect:CGRectMake(originx + dateImage.size.width + spanwidth,height ,dateStrRect.size.width,dateStrRect.size.height) withAttributes:attributes];
    }
    
    
    if(userName.length>0){
        
        float totalWidth = dateStrRect.size.width + userNameStrRect.size.width + dateImage.size.width + userImage.size.width + spanwidth * 3.0;
        float originx = (imageResultSize.width - totalWidth)/2.0;
        
        
        
        [dateImage drawInRect:CGRectMake(originx ,bottomImageoriginy,dateImage.size.width,dateImage.size.height)];
        [userImage drawInRect:CGRectMake(originx+dateImage.size.width + dateStrRect.size.width + spanwidth * 2.0,bottomImageoriginy,userImage.size.width,userImage.size.height)];
    }
    else{
        float totalWidth = dateStrRect.size.width + dateImage.size.width + spanwidth;
        float originx = (imageResultSize.width - totalWidth)/2.0;
        
        [dateImage drawInRect:CGRectMake(originx,bottomImageoriginy,dateImage.size.width,dateImage.size.height)];
    }
    
    UIImage *newImage= UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    //    float pro = MAX(newBottomImage.size.width/imageSize.width, newBottomImage.size.height/imageSize.height);
    //
    //    UIGraphicsBeginImageContextWithOptions(CGSizeMake(imageSize.width, imageSize.height), NO, 0.0);
    //    CGSize bottomImage_size = CGSizeMake(newBottomImage.size.width/pro, newBottomImage.size.height/pro);
    //    float orginheight = (newImage_size.height - bottomImage_size.height)/2.0;
    //
    //    [newBottomImage drawInRect:CGRectMake((newImage_size.width - bottomImage_size.width)/2.0,orginheight,bottomImage_size.width,bottomImage_size.height)];
    //    UIImage * newImage= UIGraphicsGetImageFromCurrentImageContext();
    //    UIGraphicsEndImageContext();
    
    //[self createCacheImageFolder];
    //unlink([cachePath UTF8String]);
    
    //写入沙盒
    //NSData *writeData = UIImagePNGRepresentation(newImage);
    //BOOL suc = [writeData writeToFile:cachePath atomically:YES];
    
    mDateStr = nil;
    mUsernamestr = nil;
    topImage = nil;
    dateImage = nil;
    userImage = nil;
    attributes = nil;
    //newBottomImage = nil;
    //writeData = nil;
    //newImage = nil;
    
    return newImage;
    
    //}
}

- (void)updateProgress:(float) progress {
    
    if (progress > lastProgress) {
        lastProgress = progress;
        exportProgressBlock(progress);
    }
    
    float exportDuration = MIN(self.duration, _maxVideoDuration);
    if(exportDuration <= 0){
        exportDuration = self.duration;
    }
    exportTime = progress * exportDuration;
    if (_delegate && [_delegate respondsToSelector:@selector(progressCurrentTime:customDrawLayer:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate progressCurrentTime:CMTimeMakeWithSeconds(exportTime, _editor.fps) customDrawLayer:customDrawLayer];
        });
    }
}

- (void)exportFail:(NSError *)error {
    _editor.isExporting = NO;
    isExporting = NO;
    exportTime = 0.0;
    exportFailBlock(error);
    writer = nil;
    
    for (PPMovie* movie in exportMovieArray) {
        [movie pause];
        [movie endProcessing];
        [movie removeAllTargets];
    }
    [exportMovieArray removeAllObjects];
    [exportMVFilterArray removeAllObjects];
    [animationLayerArray enumerateObjectsUsingBlock:^(CALayer *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.contents = nil;
    }];
    [animationLayerArray removeAllObjects];
    [self removeEndLogoMark];
    [self removeWaterMark];
    [self refreshWaterAndSubtitleEffect];
    [self setEditorWatermarksWithIsExport:NO];
    if (!CGSizeEqualToSize(_editor.videoSize, originVideoSize)) {
        [self setEditorVideoSize:originVideoSize];
        [_editor build];
    }
    [self prepare];
}

-(void)exportCancel{
    _editor.isExporting = NO;
    isExporting = NO;
    writer = nil;
    exportTime = 0.0;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeEndLogoMark];
        [self removeWaterMark];
        [self refreshWaterAndSubtitleEffect];
        [self setEditorWatermarksWithIsExport:NO];
        if (!CGSizeEqualToSize(_editor.videoSize, originVideoSize)) {
            [self setEditorVideoSize:originVideoSize];
            [_editor build];
        }
        [self prepare];//20170810 wuxiaoxia 需要在主线程，否则取消导出后，不能播放
    });
}

#pragma mark- 倒序
- (void)changeExportProgress:(NSNumber *)numProgress{
    if(_progressReverseBlock){
        _progressReverseBlock(numProgress);
    }
}

+ (void)exportReverseVideo:(NSURL *)url
                 outputUrl:(NSURL *)outputUrl
                 timeRange:(CMTimeRange)timeRange
                videoSpeed:(float)speed
             progressBlock:(void (^)(NSNumber *prencent))progressBlock
             callbackBlock:(void (^)())finishBlock
                      fail:(void (^)())failBlock
                    cancel:(BOOL *)cancel{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[RDVECore alloc] exportReverseVideo:url
                                   outputUrl:outputUrl
                                   timeRange:timeRange
                                       speed:(float)speed
                               progressBlock:progressBlock
                               callbackBlock:finishBlock
                                        fail:failBlock
                                      cancel:cancel];
    });
}



- (void)exportReverseVideo:(NSURL *)url
                 outputUrl:(NSURL *)outputUrl
                 timeRange:(CMTimeRange)timeRange
                     speed:(float)speed
             progressBlock:(void (^)(NSNumber *prencent))progressBlock
             callbackBlock:(void (^)())finishBlock
                      fail:(void (^)())failBlock
                    cancel:(BOOL *)cancel
{
    if (_sdkDisabled) {
        return;
    }
    
    //    [_renderer removeTimeObserverFromPlayer];
    
    _cancelReverseBlock = failBlock;
    _progressReverseBlock = progressBlock;
    NSError *error;
    _lastReverseProgress = 0;
    _lastReverseWriteProgress = 0;
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    NSLog(@"duration : %f",CMTimeGetSeconds(asset.duration));
    if(isnan(CMTimeGetSeconds(timeRange.duration))){
        timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    }
    //矫正时间
    if(CMTimeGetSeconds(asset.duration) == 0){
        NSLog(@"文件已经不存在了:%@",url);
        failBlock();
        return;
    }
    
    if(CMTimeCompare(CMTimeAdd(timeRange.start, timeRange.duration), asset.duration) == 1){
        timeRange.duration = CMTimeSubtract(asset.duration, timeRange.start);
    }
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if(tracks.count == 0){
        failBlock();
        return;
    }
    
    if ([[ NSFileManager defaultManager] fileExistsAtPath:outputUrl.path]) {
        [[ NSFileManager defaultManager] removeItemAtURL:outputUrl error:&error];
        if(error){
            NSLog(@"%@",error);
            error = nil;
        }
    }
    
    float fenduanDuration = 1.0;
    
    if(outputUrl.path.length == 0)
        outputUrl = [NSURL fileURLWithPath:[RDRecordHelper getVideoReversFilePathString]];
    
    // Initialize the reader
    AVAssetTrack *writeVideoTrack = [tracks lastObject];
    
    // Initialize the writer
    _assetWriter = [[AVAssetWriter alloc] initWithURL:outputUrl
                                             fileType:AVFileTypeMPEG4
                                                error:&error];
    
    
    
    
    
    
#if 0
    NSDictionary *videoCleanApertureSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSNumber numberWithInt:writeVideoTrack.naturalSize.width], AVVideoCleanApertureWidthKey,
                                                [NSNumber numberWithInt:writeVideoTrack.naturalSize.height], AVVideoCleanApertureHeightKey,
                                                [NSNumber numberWithInt:10], AVVideoCleanApertureHorizontalOffsetKey,
                                                [NSNumber numberWithInt:10], AVVideoCleanApertureVerticalOffsetKey,
                                                nil];
    NSDictionary *videoAspectRatioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithInt:3], AVVideoPixelAspectRatioHorizontalSpacingKey,
                                              [NSNumber numberWithInt:3],AVVideoPixelAspectRatioVerticalSpacingKey,
                                              nil];
    
    NSDictionary *codecSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInt:960000], AVVideoAverageBitRateKey,
                                   [NSNumber numberWithInt:1],AVVideoMaxKeyFrameIntervalKey,
                                   videoCleanApertureSettings, AVVideoCleanApertureKey,
                                   videoAspectRatioSettings, AVVideoPixelAspectRatioKey,
                                   AVVideoProfileLevelH264BaselineAutoLevel, AVVideoProfileLevelKey,
                                   nil];
    NSString *targetDevice = [[UIDevice currentDevice] model];
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoScalingModeResizeAspectFill,AVVideoScalingModeKey,
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   codecSettings,AVVideoCompressionPropertiesKey,
                                   [NSNumber numberWithInt:writeVideoTrack.naturalSize.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:writeVideoTrack.naturalSize.height], AVVideoHeightKey,
                                   nil];
    _writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings sourceFormatHint:(__bridge CMFormatDescriptionRef)[writeVideoTrack.formatDescriptions lastObject]];
#else
    
    NSDictionary *writeVideoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                                @(writeVideoTrack.estimatedDataRate), AVVideoAverageBitRateKey,
                                                AVVideoProfileLevelH264BaselineAutoLevel,AVVideoProfileLevelKey, //talker 2017-04-12 不加这个设置，有的视频倒放后，拖动会卡死（copyNextSampleBuffer）
                                                @(15),AVVideoMaxKeyFrameIntervalKey,
                                                nil];
    CGSize videoSize = writeVideoTrack.naturalSize;
    if (CGSizeEqualToSize(videoSize, CGSizeZero) || videoSize.width == 0.0 || videoSize.height == 0.0) {
        NSArray * formatDescriptions = [writeVideoTrack formatDescriptions];
        CMFormatDescriptionRef formatDescription = NULL;
        if ([formatDescriptions count] > 0) {
            formatDescription = (__bridge CMFormatDescriptionRef)[formatDescriptions objectAtIndex:0];
            if (formatDescription) {
                videoSize = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, false, false);
            }
        }
    }
    NSDictionary *writerOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                          AVVideoCodecH264, AVVideoCodecKey,
                                          [NSNumber numberWithInt:videoSize.width], AVVideoWidthKey,
                                          [NSNumber numberWithInt:videoSize.height], AVVideoHeightKey,
                                          writeVideoCompressionProps, AVVideoCompressionPropertiesKey,
                                          nil];
    _writerInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                                  outputSettings:writerOutputSettings
                                                sourceFormatHint:(__bridge CMFormatDescriptionRef)[writeVideoTrack.formatDescriptions lastObject]];
#endif
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
    
    AVMutableComposition *mComposition = [self buildVideoForFileURL:url timeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)];
    
    AVComposition *composition = mComposition;
    
    //timestr = [NSString stringWithFormat:@"%f", (double)[[NSDate date] timeIntervalSince1970]];
    
    NSLog(@"buildVideoForFileURL 耗时：start :%lf end:%lf dif:%lf",time,CACurrentMediaTime(),CACurrentMediaTime()-time);
    
    //    time = CACurrentMediaTime();
    
    float start = CMTimeGetSeconds(timeRange.start);
    float totalDuration = CMTimeGetSeconds(timeRange.duration);
#if 0
    while (totalDuration>fenduanDuration) {
        totalDuration -=fenduanDuration;
        CMTimeRange itemTimeRange = CMTimeRangeMake( CMTimeAdd(CMTimeMakeWithSeconds(totalDuration, NSEC_PER_SEC),timeRange.start), CMTimeMakeWithSeconds(fenduanDuration, NSEC_PER_SEC));
        
        NSLog(@"createReverseReader");
        time = CACurrentMediaTime();
        
        [self createReverseReader:composition timeRange:itemTimeRange];
        
        
        [_reverseReader startReading];
        
        NSLog(@"createReverseReader 耗时：%lf",CACurrentMediaTime() - time);
        
        [self progressFrame:CMTimeMakeWithSeconds(CMTimeGetSeconds(CMTimeAdd(timeRange.duration,timeRange.start)) - (totalDuration+fenduanDuration), NSEC_PER_SEC) duration:fenduanDuration totalduration:CMTimeGetSeconds(timeRange.duration)];
        
        //NSLog(@"单次耗时：%f",CACurrentMediaTime() - time);
    }
    
    CMTimeRange difTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(0, NSEC_PER_SEC), CMTimeMakeWithSeconds(totalDuration, NSEC_PER_SEC));
    NSLog(@"createReverseReader");
    time = CACurrentMediaTime();
    
    [self createReverseReader:composition timeRange:difTimeRange];
    
    NSLog(@"createReverseReader 耗时：start :%lf end:%lf dif:%lf",time,CACurrentMediaTime(),CACurrentMediaTime()-time);
    
    [_reverseReader startReading];
    
    
    [self progressFrame:CMTimeMakeWithSeconds(CMTimeGetSeconds(CMTimeAdd(timeRange.duration, timeRange.start)) - (totalDuration), NSEC_PER_SEC) duration:totalDuration totalduration:CMTimeGetSeconds(timeRange.duration)];
#else
    int num = totalDuration/fenduanDuration;
    float diff = totalDuration - num*fenduanDuration;
    for (int i = 0; i < num; i++) {
        @autoreleasepool {//20170620 wuxiaoxia 必须加释放池，否则在有的设备上，倒序时会因内存崩溃
            
            float tmpStartTime = start + totalDuration - (i+1) *fenduanDuration;
            CMTimeRange itemTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(tmpStartTime, NSEC_PER_SEC), CMTimeMakeWithSeconds(fenduanDuration, NSEC_PER_SEC));
            
            time = CACurrentMediaTime();
            
            [self createReverseReader:composition timeRange:itemTimeRange];
            
            
            [_reverseReader startReading];
            
            NSLog(@"createReverseReader 耗时：%lf",CACurrentMediaTime() - time);
            
            [self progressFrame:CMTimeMakeWithSeconds(i*fenduanDuration, NSEC_PER_SEC) duration:fenduanDuration totalduration:CMTimeGetSeconds(timeRange.duration) speed:speed cancel:cancel];
            //NSLog(@"单次耗时：%f",CACurrentMediaTime() - time);
            if(cancel && *(cancel)){
                break;
            }
        }
    }
    if (diff > 0.0 && cancel && !*(cancel)) {
        @autoreleasepool {
            CMTimeRange difTimeRange = CMTimeRangeMake(timeRange.start, CMTimeMakeWithSeconds(diff, NSEC_PER_SEC));
            //        time = CACurrentMediaTime();
            
            [self createReverseReader:composition timeRange:difTimeRange];
            
            //        NSLog(@"createReverseReader 耗时：start :%lf end:%lf dif:%lf",time,CACurrentMediaTime(),CACurrentMediaTime()-time);
            
            [_reverseReader startReading];
            
            [self progressFrame:CMTimeMakeWithSeconds(totalDuration - diff, NSEC_PER_SEC) duration:diff totalduration:CMTimeGetSeconds(timeRange.duration) speed:speed cancel:cancel];
            
        }
    }
#endif
#endif
    if (cancel && *(cancel)) {
        [_assetWriter cancelWriting];
        
    }else{
        [_assetWriter finishWritingWithCompletionHandler:^{
            if (_assetWriter.status == AVAssetWriterStatusCompleted) {
                if(finishBlock){
                    finishBlock();
                }
            }
            else
            {
                if(failBlock){
                    failBlock();
                }
            }
        }];
    }
    
    writeVideoTrack = nil;
    writeVideoCompressionProps = nil;
    writerOutputSettings = nil;
    _writerInput = nil;
    _pixelBufferAdaptor = nil;
}

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
    
    if (videoTracks.count > 0) {
        AVAssetTrack* assetVideoTrack = [videoTracks objectAtIndex:0];
        
        NSError *error;
        BOOL suc = [videoTrack insertTimeRange:timerange ofTrack:assetVideoTrack atTime:kCMTimeZero error:&error];
        if(!suc){
            NSLog(@"***video insert error:%@",error);
        }
        
        //    NSLog(@"videoTrack:start %@     duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, videoTrack.timeRange.start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, videoTrack.timeRange.duration)));
        return mixComposition;
    }
    return nil;
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
- (void)createReverseReaderWithPixelFormat32BGRA:(RDAEVideoComposition *)composition timeRange:(CMTimeRange )timerange{
    
//    NSLog(@"createReverseReaderWithPixelFormat32BGRA in ");
//    _lastReverseProgress = 0;
//    _lastReverseWriteProgress = 0;
    composition.reverseReader = nil;
    NSError *error;
    composition.reverseReader = [[AVAssetReader alloc] initWithAsset:composition.videoURLComposition error:&error];
    AVAssetTrack *videoTrack = [[composition.videoURLComposition tracksWithMediaType:AVMediaTypeVideo] lastObject];
    
    NSDictionary *readerOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil];
    
    composition.readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack
                                                               outputSettings:readerOutputSettings];
    //_readerOutput.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmLowQualityZeroLatency;
    composition.readerOutput.alwaysCopiesSampleData = NO;
    [composition.reverseReader addOutput:composition.readerOutput];
    composition.reverseReader.timeRange = timerange;//;
    BOOL statu = [composition.readerOutput supportsRandomAccess];
    [composition.readerOutput setSupportsRandomAccess:YES];
    statu = [composition.readerOutput supportsRandomAccess];
    
//     NSLog(@"createReverseReaderWithPixelFormat32BGRA out ");
    return ;
    
}

- (void)progressFrame:(CMTime)start duration:(float)timeDuration totalduration:(float)totalduration speed:(float)speed cancel:(BOOL *)cancel{
    // read in the samples
    CMSampleBufferRef sample;
    NSMutableArray *samples = [[NSMutableArray alloc] init];
    
    
    double time = CACurrentMediaTime();
    
    _oldSampleFrameTime = 0.0;
    
    while(_reverseReader.status == AVAssetReaderStatusReading &&(sample = [_readerOutput copyNextSampleBuffer])) {
        
        CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sample);
        Float64 currentTime = CMTimeGetSeconds(currentSampleTime);
        //if (currentTime - _oldSampleFrameTime > 1.0/24.0) {
        if (currentTime - _oldSampleFrameTime > 1.0/15.0) {
            //            NSLog(@"反转截图:时间: %f _oldSampleFrameTime：%f",currentTime, _oldSampleFrameTime);
            [samples addObject:(__bridge id)sample];
            _oldSampleFrameTime = currentTime;
            
        }
        //[samples addObject:(__bridge id)sample];
        CFRelease(sample);
        sample = nil;
        
        if(cancel && *(cancel)){
            break;
        }
    }
    //    NSLog(@"解码耗时：%lf",CACurrentMediaTime() - time);
    time = CACurrentMediaTime();
    
    //    NSLog(@"_reverseReader.status:%d",_reverseReader.status);
    if(_reverseReader.status == AVAssetReaderStatusReading){
        @try {
            [_reverseReader cancelReading];
        } @catch (NSException *exception) {
            NSLog(@"exception: %@",exception);
        }
    }
    for(NSInteger i = 0; i < samples.count; i++) {
        
        CMTime presentationTime = CMTimeAdd(CMTimeMakeWithSeconds(CMTimeGetSeconds(start)/speed, NSEC_PER_SEC),CMTimeMakeWithSeconds(i*(timeDuration/samples.count)/speed, NSEC_PER_SEC));
        //20170602
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
                float exportProgress = (currentTime)/(totalduration/speed);
                //                NSLog(@"编码 时间: %f ",currentTime);
                
                [NSThread detachNewThreadSelector:@selector(changeExportProgress:) toTarget:self withObject:[NSNumber numberWithFloat:exportProgress]];
            } @catch (NSException *exception) {
                NSLog(@"exception:%@",exception);
            }
        }
        if (cancel && *(cancel)) {
            break;
        }
    }
    [samples removeAllObjects];
    samples = nil;
    //    NSLog(@"编码码耗时：%lf",CACurrentMediaTime() - time);
    
    if (cancel && *(cancel)) {
        return;
    }
}

#pragma mark- 截取视频
/*截取
 *params: url           视频源地址
 *params: timeRange     截取时间范围
 *params: speed         调速
 *params: progressBlock 截取进度回调
 *params: finishBlock   结束回调
 *params: failBlock     失败回调
 *params: cancelBlock   取消截取回调
 *params: cancel        是否取消
 */
+ (void)trimVideosWithFileURL:(NSURL *)url trimTimeRange:(CMTimeRange )timeRange speed:(float)speed progressBlock:(void(^)(NSNumber *progress))progressBlock finishBlock:(void(^)(NSURL *videourl))finishBlock failBlock:(void(^)(NSError *error))failBlock cancelBlock:(void(^)())cancelBlock cancel:(BOOL *)cancel{
    [[RDVECore alloc] trimVideosWithFileURL:url
                              trimTimeRange:timeRange
                                      speed:speed
                                   progress:progressBlock
                                finishBlock:finishBlock
                                  failBlock:failBlock
                                cancelBlock:cancelBlock
                                     cancel:cancel];
}

- (void)trimVideosWithFileURL:(NSURL *)url trimTimeRange:(CMTimeRange )timeRange speed:(float)speed progress:(void(^)(NSNumber *progress))progressBlock finishBlock:(void(^)(NSURL *videourl))finishBlock failBlock:(void(^)(NSError *error))failBlock cancelBlock:(void(^)())cancelBlock cancel:(BOOL *)cancel
{
    if (_sdkDisabled) {
        return;
    }
    NSString *mergePath = [RDRecordHelper getVideoSaveFilePathString];
    
    if(mergePath.length == 0){
        if(failBlock){
            failBlock([NSError errorWithDomain:@"" code:000 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"创建文件夹失败",@"message", nil]]);
        }
        return;
    }
    
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if(videoTracks.count==0){
        if(failBlock){
            failBlock([NSError errorWithDomain:@"" code:000 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"文件路径错误",@"message", nil]]);
        }
        return;
    }
    _progressTrimBlock = progressBlock;
    
    AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack* videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack* audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAssetTrack* assetVideoTrack = [videoTracks objectAtIndex:0];
    
    CMTimeRange  insertTimeRange       = timeRange;
    if(CMTimeRangeEqual(insertTimeRange, kCMTimeRangeZero)){
        insertTimeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    }
    NSError *error;
    BOOL suc = [videoTrack insertTimeRange:insertTimeRange ofTrack:assetVideoTrack atTime:kCMTimeZero error:&error];
    if(!suc){
        NSLog(@"***video insert error:%@",error);
    }
    
    float scaleDuration = CMTimeGetSeconds(insertTimeRange.duration)/speed;
    CMTimeRange speedTimeRange = insertTimeRange;
    speedTimeRange.start = kCMTimeZero;
    
    [videoTrack scaleTimeRange:speedTimeRange toDuration:CMTimeMakeWithSeconds(scaleDuration, NSEC_PER_SEC)];
    
    if ([asset tracksWithMediaType:AVMediaTypeAudio].count > 0) {//20170323
        AVAssetTrack* assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        suc = [audioTrack insertTimeRange:CMTimeRangeMake(timeRange.start, CMTimeSubtract(timeRange.duration, CMTimeMake(1, NSEC_PER_SEC))) ofTrack:assetAudioTrack atTime:kCMTimeZero error:nil];
        if(!suc){
            NSLog(@"***audio insert error:%@",error);
        }
        [audioTrack scaleTimeRange:speedTimeRange toDuration:CMTimeMakeWithSeconds(scaleDuration, NSEC_PER_SEC)];
    }
    
    unlink([mergePath UTF8String]);
    
    NSURL* exportURL  = [NSURL fileURLWithPath:mergePath];
    
    //AVAssetExportPresetPassthrough 对声音缩放有影响
    exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];//
    
    if(_exportTimer){
        [_exportTimer invalidate];
        _exportTimer = nil;
    }
    _exportTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(updateTrimExportProgress:) userInfo:[NSNumber numberWithBool:(*cancel)] repeats:YES];
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
                    if(finishBlock){
                        finishBlock(exportURL);
                    }
                }
                    break;
                case AVAssetExportSessionStatusFailed:
                {
                    if(_exportTimer){
                        [_exportTimer invalidate];
                        _exportTimer = nil;
                    }
                    if(failBlock){
                        failBlock(exporter.error);
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
                    if(_exportTimer){
                        [_exportTimer invalidate];
                        _exportTimer = nil;
                    }
                    if(cancelBlock){
                        cancelBlock();
                    }
                }
                    break;
                default:
                    break;
            }
            
        });
    }];
}

- (void)updateTrimExportProgress:(NSNumber *)number{
    if([number boolValue]){
        [exporter cancelExport];
        [_exportTimer invalidate];
        _exportTimer = nil;
    }
    if(_progressTrimBlock){
        _progressTrimBlock ([NSNumber numberWithFloat:exporter.progress]);
    }
}

/** 截取视频的背景音乐*/
+ (void)video2audiowithtype:(AVFileType)type
                   videoUrl:(NSURL*)videoUrl
                  trimStart:(float)start
                   duration:(float)duration
           outputFolderPath:(NSString*)outputFolder
                 samplerate:(int )samplerate
                 completion:(void(^)(BOOL result,NSString*outputFilePath))completionHandle{
    int bitrate_kbps = 0;
    if(![[NSFileManager defaultManager] fileExistsAtPath:outputFolder]){
        [[NSFileManager defaultManager] createDirectoryAtPath:outputFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *path = [RDRecordHelper getUrlPath:videoUrl];
    NSString *outputFilePath = [outputFolder stringByAppendingPathComponent:[path stringByAppendingString:@".m4a"]];
    
    AVURLAsset* videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    NSArray *keys = @[@"duration",@"tracks"];
    [videoAsset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        NSError*error =nil;
        AVKeyValueStatus status = [videoAsset statusOfValueForKey:@"tracks" error:&error];
        if(status ==AVKeyValueStatusLoaded) {
            //数据加载完成
            AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
            // 2 - Video track
            //Audio Recorder
            //创建一个轨道,类型是AVMediaTypeAudio
            AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            //获取videoAsset中的音频,插入轨道
            
            float startTime = MAX(start, 0);
            float dur = duration;
            if(dur == 0){
                dur = CMTimeGetSeconds(videoAsset.duration);
            }
            float durationTime = MIN(CMTimeGetSeconds(videoAsset.duration) - startTime,dur);
            CMTimeRange timerange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);// CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, NSEC_PER_SEC), CMTimeMakeWithSeconds(durationTime, NSEC_PER_SEC));
            [firstTrack insertTimeRange:timerange ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
            if([[NSFileManager defaultManager] fileExistsAtPath:outputFilePath]){
                unlink([outputFilePath UTF8String]);
            }
            
            NSURL*url = [NSURL fileURLWithPath:outputFilePath];
            AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetAppleM4A];
            //输出为M4A音频
#if 1   //20190808 wuxiaoxia NSEC_PER_SEC有的视频会导出失败
            exporter.timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, TIMESCALE), CMTimeMakeWithSeconds(durationTime, TIMESCALE));
#else
            exporter.timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, NSEC_PER_SEC), CMTimeMakeWithSeconds(durationTime, NSEC_PER_SEC));
#endif
            exporter.outputURL=url;
            exporter.outputFileType = AVFileTypeAppleM4A;//;
            //类型和输出类型一致
            //exporter.shouldOptimizeForNetworkUse = YES;
            [exporter exportAsynchronouslyWithCompletionHandler:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (exporter.status == AVAssetExportSessionStatusCompleted) {
                        if(type == AVFileTypeMPEGLayer3 || type == AVFileTypeWAVE){
                            NSString *wavFilePath = [[outputFilePath stringByDeletingPathExtension] stringByAppendingPathExtension:@".wav"];
                            [self convetM4aToWav:[NSURL fileURLWithPath:outputFilePath] destUrl:wavFilePath completion:^(NSString *data) {
                                if(type == AVFileTypeMPEGLayer3){
                                    NSString *mp3FilePath = [[data stringByDeletingPathExtension] stringByAppendingString:@".mp3"];
                                    unlink([mp3FilePath UTF8String]);
                                    NSString *resullPath = [self audio_PCMtoMP3:data bitrate_kbps:(int)bitrate_kbps samplerate:(int )samplerate];
                                    unlink([data UTF8String]);
                                    unlink([outputFilePath UTF8String]);
                                    if(completionHandle){ completionHandle(YES,resullPath);}
                                    return;
                                }
                                unlink([outputFilePath UTF8String]);
                                if(completionHandle){ completionHandle(YES,data);}
                            }];
                            return;
                        }
                        if(completionHandle){ completionHandle(YES,outputFilePath);}
                    }else{
                        if(completionHandle){
                            completionHandle(NO,nil);
                        }
                        NSLog(@"失败了，原因是：%@",exporter.error);
                    }
                });
            }];
        }
    }];
}



#if 1  //M4a转换Mp3

+ (void)convetM4aToWav:(NSURL *)originalUrl  destUrl:(NSString *)destUrl completion:(void(^)(NSString*data))completionHandle{
    unlink([destUrl UTF8String]);
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:originalUrl options:nil];
    
    //读取原始文件信息
    NSError *error = nil;
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:songAsset error:&error];
    
    if (error) {
        NSLog (@"error: %@", error);
        if(completionHandle){
            completionHandle(nil);
        }
        return;
    }
    AVAssetTrack *soundTrack = [songAsset.tracks objectAtIndex:0];
    NSInteger nominalFrameRate = soundTrack.naturalTimeScale;
    AVAssetReaderOutput *assetReaderOutput = [AVAssetReaderAudioMixOutput
                                              assetReaderAudioMixOutputWithAudioTracks:songAsset.tracks
                                              audioSettings: nil];
    if (![assetReader canAddOutput:assetReaderOutput]) {
        NSLog (@"can't add reader output... die!");
        if(completionHandle){
            completionHandle(nil);
        }
        return;
    }
    [assetReader addOutput:assetReaderOutput];
    
    
    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:destUrl]
                                                          fileType:AVFileTypeCoreAudioFormat
                                                             error:&error];
    if (error) {
        NSLog (@"error: %@", error);
        if(completionHandle){
            completionHandle(nil);
        }
        return;
    }
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                    [NSNumber numberWithFloat:nominalFrameRate], AVSampleRateKey,
                                    [NSNumber numberWithInt:2], AVNumberOfChannelsKey,
                                    [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)], AVChannelLayoutKey,
                                    [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
                                    [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                                    [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                    [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                                    nil];
    AVAssetWriterInput *assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
                                                                              outputSettings:outputSettings];
    if ([assetWriter canAddInput:assetWriterInput]) {
        [assetWriter addInput:assetWriterInput];
    } else {
        NSLog (@"can't add asset writer input... die!");
        if(completionHandle){
            completionHandle(destUrl);
        }
        return;
    }
    
    assetWriterInput.expectsMediaDataInRealTime = NO;
    
    [assetWriter startWriting];
    [assetReader startReading];
    
    CMTime startTime = CMTimeMake (0, soundTrack.naturalTimeScale);
    [assetWriter startSessionAtSourceTime:startTime];
    
    __block UInt64 convertedByteCount = 0;
    
    dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
    [assetWriterInput requestMediaDataWhenReadyOnQueue:mediaInputQueue
                                            usingBlock: ^
     {
         while (assetWriterInput.readyForMoreMediaData) {
             CMSampleBufferRef nextBuffer = [assetReaderOutput copyNextSampleBuffer];
             if (nextBuffer) {
                 // append buffer
                 [assetWriterInput appendSampleBuffer: nextBuffer];
//                 NSLog (@"appended a buffer (%zu bytes)", CMSampleBufferGetTotalSampleSize (nextBuffer));
                 convertedByteCount += CMSampleBufferGetTotalSampleSize (nextBuffer);
             } else {
                 [assetWriterInput markAsFinished];
                 [assetWriter finishWritingWithCompletionHandler:^{
                     if(completionHandle){
                         completionHandle(destUrl);
                     }
                 }];
                 [assetReader cancelReading];
                 NSDictionary *outputFileAttributes = [[NSFileManager defaultManager]
                                                       attributesOfItemAtPath:destUrl
                                                       error:nil];
                 NSLog (@"FlyElephant %lld",[outputFileAttributes fileSize]);
                 break;
             }
         }
     }];
}

+ (NSString *)audio_PCMtoMP3:(NSString *)path bitrate_kbps:(int)bitrate_kbps samplerate:(int )samplerate
{
    
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
    
    //读取原始文件信息
    
    
    AVAssetTrack *soundTrack = [songAsset.tracks objectAtIndex:0];
    int nominalFrameRate = soundTrack.naturalTimeScale;
    
    NSString *mp3FileName = [[path lastPathComponent] stringByDeletingPathExtension];
    mp3FileName = [mp3FileName stringByAppendingString:@".mp3"];
    NSString *mp3FilePath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:mp3FileName];
    
    @try {
        int read, write;
        
        FILE *pcm = fopen([path cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE * 2];
        unsigned char mp3_buffer[MP3_SIZE ];
        
        if(bitrate_kbps == 0){
            bitrate_kbps = 128;
        }
        if(samplerate == 0){
            samplerate = nominalFrameRate;
        }
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, nominalFrameRate);//11025.0
        lame_set_out_samplerate(lame, samplerate);
        lame_set_VBR_mean_bitrate_kbps(lame,bitrate_kbps);
        lame_set_VBR(lame, vbr_abr);
        lame_init_params(lame);
        
        
        do {
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    @finally {
        return mp3FilePath;
    }
    
}
#endif
#pragma mark--

- (UIView *)view{
    return (UIView *)_preview;
}

- (void)playerMute:(BOOL)mute{
    _renderer.isMute = mute;
}

- (void)reverse{
    [_renderer reverse:CMTimeMakeWithSeconds(self.duration, TIMESCALE)];
}
- (void) play{
    if (_sdkDisabled || _status != kRDVECoreStatusReadyToPlay) {
        return;
    }
    _isPlaying = YES;
    [_renderer play];
#if 0
    if (mvRendererArray.count > 0) {
        [mvRendererArray enumerateObjectsUsingBlock:^(RDVideoRenderer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj play];
        }];
    }
#endif
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];//视频播放过程中禁止休眠
}

- (void) pause{
    _isPlaying = NO;
    [_renderer pause];
#if 0
    if (mvRendererArray.count > 0) {
        [mvRendererArray enumerateObjectsUsingBlock:^(RDVideoRenderer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj pause];
        }];
    }
#endif
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];//视频播放过程中禁止休眠
}

- (void) stop{
    double time = CACurrentMediaTime();
    _isPlaying = NO;
    _cancelGetImage = NO;
    getScreenshotFinish = FALSE;
    
    for(int j = 0; j < compositionArray.count; j++)
    {
        RDAEVideoComposition *composition = [compositionArray objectAtIndex:j];
        
        while(composition.reverseReader.status == AVAssetReaderStatusReading && !composition.videoCopyNextSampleBufferFinish){
            usleep(20000);
            NSLog(@"------------------------- videoCopyNextSampleBufferFinish wait");
        }
    }
    
    [animationLayerArray enumerateObjectsUsingBlock:^(CALayer *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.contents = nil;
    }];
    [animationLayerArray removeAllObjects];
    animationLayerArray = nil;
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_renderer clear];
#if 0
        if (mvRendererArray.count > 0) {
            [mvRendererArray enumerateObjectsUsingBlock:^(RDVideoRenderer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj clear];
                obj.playDelegate = nil;
            }];
        }
#endif
//    });

    if (exportMovie) {
        exportMovie = nil;
    }
    if (writer) {
        writer = nil;
    }
    
    getScreenshotFinish = TRUE;
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];//视频播放过程中禁止休眠
    
    //20190905 stop后要过会才能释放RDVideoCompositorRenderer，内存才能彻底释放
//    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
//        dispatch_semaphore_signal(semaphore);
//    });
//    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    NSLog(@"stop 耗时:%lf",CACurrentMediaTime() -time);
}
- (void) prepare
{
    if (rdJsonAnimation && _editor.fps != originFps) {
        _editor.fps = originFps;
        [_editor build];
    }
    [_renderer prepare];
#if 0
    if (mvRendererArray.count > 0) {
        [mvRendererArray enumerateObjectsUsingBlock:^(RDVideoRenderer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj prepare];
        }];
    }
#endif
//    [self seekToTime:CMTimeMake(42, TIMESCALE)];
    //设置背景颜色
    [_editor setVirtualVideoBgColor:backGroundColor];
//    [self refreshCurrentFrame];
    if (animationView && movieEffects.count > 0) {
        if (rdJsonAnimation.backgroundSourceArray.count == 0 && rdJsonAnimation.bgSourceArray.count == 0) {
            animationView.isBlackVideo = YES;
        }
        animationView.animationPlayCount = animationPlayCount;
        [_editor setLottieView:animationView];
    }
}
- (void) seekToTime:(CMTime)time;
{
    if (_sdkDisabled) {
        return;
    }
    [self seekToTime:time toleranceTime:kCMTimeZero completionHandler:nil];
}

- (void) seekToTime:(CMTime)time toleranceTime:(CMTime) tolerance completionHandler:(void (^)(BOOL finished))completionHandler;
{
    if (_sdkDisabled)
        return;
#ifdef ForcedSeek
    if (CMTimeCompare(time, kCMTimeZero) == 0) {
        time = CMTimeMake(3, _editor.fps);//20180720 wuxiaoxia seek时，timesScale与设置的帧率一致，真正seek到的时间才能与time一致
    }
#endif
//    time = CMTimeMake(floorf(CMTimeGetSeconds(time)*(float)_editor.fps), _editor.fps);//20180821 wuxiaoxia 消除警告：warning: error of xxxx introduced due to very low timescale
    //20200206 floorf(CMTimeGetSeconds(time)*(float)_editor.fps)这样转换会与原seek时间有误差，导致画中画不显示，故取消转换
    currentBufferTime = time;
    if (CMTimeCompare(time, _renderer.currentTime) == 0
            || CMTimeCompare(CMTimeSubtract(time, _renderer.currentTime), CMTimeMake(1, _editor.fps)) == 0
            || CMTimeCompare(CMTimeSubtract(time, _renderer.currentTime), CMTimeMake(-1, _editor.fps)) == 0)
    {
//        NSLog(@"%d %@", __LINE__, CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentTime)));
        [_renderer refreshCurrentFrame:time completionHandler:^(BOOL finished) {
            if (completionHandler) {
                completionHandler(finished);
            }
        }];
    }else {
        [_renderer seekToTime:time toleranceTime:tolerance completionHandler:^(BOOL finished) {
    //        NSLog(@"seekToTime:%@ %@", finished ? @"YES" : @"NO", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, _renderer.currentTime)));
            if(completionHandler)
                completionHandler(finished);
        }];
    }
}

- (float) duration
{
    //    return CMTimeGetSeconds([_renderer playerItemDuration]);
    return _videoDuration;
}

- (CMTime)currentTime{
    return _renderer.currentTime;
}

- (void)dealloc {
    NSLog(@"%s",__func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    for (RDAEVideoComposition *composition in compositionArray) {
        if (composition.reverseReader.status == AVAssetReaderStatusReading) {
            [composition.reverseReader cancelReading];
            composition.reverseReader = nil;
            composition.readerOutput = nil;
            composition.videoURLComposition = nil;
        }
    }
    [compositionArray removeAllObjects];
    compositionArray = nil;
    
    animationView.delegate = nil;
    [animationView.layer removeFromSuperlayer];
    animationView = nil;
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshLottieView" object:nil userInfo:nil];
    
    [animationImageArray removeAllObjects];
    animationImageArray = nil;
    
    [animationVideoArray removeAllObjects];
    animationVideoArray = nil;
    
    [animationImageArray_prev removeAllObjects];
    animationImageArray_prev = nil;
    
    [animationLayerArray enumerateObjectsUsingBlock:^(CALayer *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.contents = nil;
    }];
    [animationLayerArray removeAllObjects];
    animationLayerArray = nil;
    
    [_aeSourceInfo removeAllObjects];
    _aeSourceInfo = nil;
    
    if (exportMovie) {
//        writer = nil;
//        exportMovie = nil;
    }

    [_renderer clear];
    _renderer.playDelegate = nil;
    _renderer.delegate = nil;
    _renderer = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSString *tempImageFoler = [NSTemporaryDirectory() stringByAppendingString:@"RDMVAnimateImagesTemp"];
    if (![fileManager removeItemAtPath:imageFolder error:&error]) {
        NSLog(@"删除文件夹失败:%@", error);
        return;
    }
    if([fileManager fileExistsAtPath:tempImageFoler]){
        if (![fileManager removeItemAtPath:tempImageFoler error:&error]) {
            NSLog(@"删除文件夹失败:%@", error);
            return;
        }
    }
    if (mvRendererArray.count > 0) {
        [mvRendererArray enumerateObjectsUsingBlock:^(RDVideoRenderer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj clear];
            obj.playDelegate = nil;
        }];
        [mvRendererArray removeAllObjects];
    }
    
    [_mvPipeline removeAllFilters];
    _mvPipeline = nil;
    
    [_filterPipeline removeAllFilters];
    _filterPipeline = nil;
    
    [_movie removeAllTargets];
    [mosaicFilter removeAllTargets];
    [dewatermarkFilter removeAllTargets];
    [dyFilter removeAllTargets];
    [blurFilter removeAllTargets];
    [newAlphaBlendFilter removeAllTargets];
    [gFilter removeAllTargets];
    [quadsRender removeAllTargets];
    [gaosiFilter removeAllTargets];
    [endLogoAlphaBlendFilter removeAllTargets];
    [bridgeFilter removeAllTargets];
    [bridgeFilter2 removeAllTargets];
    [bridgeFilter3 removeAllTargets];
    
    if (exportMovieArray.count > 0) {
        [exportMovieArray removeAllObjects];
    }
    if (exportMVFilterArray.count > 0) {
        [exportMVFilterArray removeAllObjects];
    }
    
    if (filterAttributeArray) {
        [filterAttributeArray removeAllObjects];
    }
    if (globalFilters) {
        [globalFilters removeAllObjects];
    }
    if (gFilters) {
        [gFilters removeAllObjects];
    }
//    [gFilter removeAllTargets];
//    gFilter = nil;
    if (mvMovieArray.count > 0) {
        for (int i = 0;i<mvMovieArray.count;i++) {
            RDGPUImageMovie* movie = mvMovieArray[i];
            [movie removeAllTargets];
            movie = nil;
        }
        [mvMovieArray removeAllObjects];
    }
    if (mvEditorArray.count > 0) {
        for (int i = 0;i<mvEditorArray.count;i++) {
            RDMVFileEditor* editor = (RDMVFileEditor*)mvEditorArray[i];
            editor = nil;
        }
        [mvEditorArray removeAllObjects];
    }
    if (mvShaderArray.count > 0) {
        for (int i = 0; i< mvShaderArray.count; i++) {
            RDGPUImageFilter* filter = mvShaderArray[i];
            [filter removeAllTargets];
        }
        [mvShaderArray removeAllObjects];
    }
    if (movieEffects) {
        [movieEffects removeAllObjects];
    }
    if(_reverseReader.status == AVAssetReaderStatusReading){
        @try {
            [_reverseReader cancelReading];
        } @catch (NSException *exception) {
            NSLog(@"exception: %@",exception);
        }
    }
    _reverseReader = nil;
}

-(void) setBackGroundColorWithRed:(float)red
                            Green:(float)green
                             Blue:(float)blue
                            Alpha:(float)alpha
{
    //设置背景颜色
    backGroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
    [_editor setVirtualVideoBgColor:backGroundColor];
    [self refreshCurrentFrame];
}

- (void)setSceneBgColor:(UIColor *)bgColor identifier:(NSString *)identifier {
    [originScenes enumerateObjectsUsingBlock:^(RDScene * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.identifier isEqualToString:identifier]) {
            obj.backgroundColor = bgColor;
            *stop = YES;
        }
    }];
    [self refreshCurrentFrame];
}

+ (void)exportGifWithVideoUrl:(NSURL *)url
                         size:(CGSize)size
                          fps:(int)fps
                    timeRange:(CMTimeRange)timeRange
                     isRepeat:(BOOL)isRepeat
                   outputPath:(NSString *)outputPath
              progressHandler:(void (^)(float progress))progressHandler
            completionHandler:(void (^)())completionHandler
                failedHandler:(void (^)())failedHandler
                       cancel:(BOOL *)cancel
{
    [[RDVECore alloc] exportGifWithVideoUrl:url
                                       size:size
                                        fps:fps
                                  timeRange:timeRange
                                   isRepeat:isRepeat
                                 outputPath:outputPath
                            progressHandler:progressHandler
                          completionHandler:completionHandler
                              failedHandler:failedHandler
                                     cancel:cancel];
}
#if 1
- (void)exportGifWithVideoUrl:(NSURL *)url
                         size:(CGSize) size
                          fps:(int)fps
                    timeRange:(CMTimeRange)timeRange
                     isRepeat:(BOOL)isRepeat
                   outputPath:(NSString *)outputPath
              progressHandler:(void (^)(float progress))progressHandler
            completionHandler:(void (^)())completionHandler
                failedHandler:(void (^)())failedHandler
                       cancel:(BOOL *)cancel
{
    NSError *error = nil;
    AVAsset *asset = [AVURLAsset assetWithURL:url];
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] == 0) {
        if (failedHandler) {
            failedHandler();
        }
        return;
    }
    AVAssetTrack* videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVAssetReader *gifReader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
    NSDictionary *readerOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil];
    AVAssetReaderTrackOutput *readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack
                                                                          outputSettings:readerOutputSettings];
    readerOutput.alwaysCopiesSampleData = NO;
    [gifReader addOutput:readerOutput];
    gifReader.timeRange = timeRange;
    
    unlink([outputPath UTF8String]);
    exportGifProgressHandler = progressHandler;
    gifHandle = RDGIFEncoderCreator();
    RDGIFEncoderSetSize(gifHandle, size.width, size.height);
    RDGIFEncoderSetFps(gifHandle, fps);
    RDGIFEncoderSetRepeat(gifHandle, (int)isRepeat);
    char *path = const_cast<char *>([outputPath UTF8String]);
    RDGIFEncoderStart(gifHandle, path);
    
}
#else
- (void)exportGifWithVideoUrl:(NSURL *)url
                         size:(CGSize) size
                          fps:(int)fps
                    timeRange:(CMTimeRange)timeRange
                     isRepeat:(BOOL)isRepeat
                   outputPath:(NSString *)outputPath
              progressHandler:(void (^)(float progress))progressHandler
            completionHandler:(void (^)())completionHandler
                failedHandler:(void (^)())failedHandler
                       cancel:(BOOL *)cancel
{
#if 0
    {
        NSString *exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportvideo.gif"];
        [RDVECore exportGifWithVideoUrl:_fileList[0].contentURL
                                   size:CGSizeMake(540, 960)
                                    fps:24
                              timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(2, 24))
                               isRepeat:YES
                             outputPath:exportPath
                        progressHandler:^(float progress) {
                            NSLog(@"progress:%f", progress);
                        } completionHandler:^{
                            NSLog(@"导出gif成功！");
                        } failedHandler:^{
                            NSLog(@"导出gif失败！");
                        } cancel:nil];
    }
#endif
    unlink([outputPath UTF8String]);
    exportGifProgressHandler = progressHandler;
    gifHandle = RDGIFEncoderCreator();
    RDGIFEncoderSetSize(gifHandle, size.width, size.height);
    RDGIFEncoderSetFps(gifHandle, fps);
    RDGIFEncoderSetRepeat(gifHandle, (int)isRepeat);
    char *path = const_cast<char *>([outputPath UTF8String]);
    RDGIFEncoderStart(gifHandle, path);
    if (progressHandler) {
//        exportGifTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(updateExportGifProgress) userInfo:nil repeats:YES];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVURLAsset *asset = [AVURLAsset assetWithURL:url];
        CMTimeRange videoTimeRange = timeRange;
        if (CMTimeCompare(CMTimeAdd(timeRange.start, timeRange.duration), asset.duration) == 1) {
            videoTimeRange = CMTimeRangeMake(timeRange.start, CMTimeSubtract(asset.duration, timeRange.start));
        }
        int frameCount = CMTimeGetSeconds(videoTimeRange.duration) * fps;
        //两帧的时间间隔
        float increment = CMTimeGetSeconds(videoTimeRange.duration)/frameCount;
        NSMutableArray *timeArray = [NSMutableArray array];
        for (int i = 0; i < frameCount; i++) {
            float seconds = CMTimeGetSeconds(videoTimeRange.start) + increment * i;
            CMTime time = CMTimeMakeWithSeconds(seconds, fps);
            [timeArray addObject:[NSValue valueWithCMTime:time]];
        }
        NSLog(@"%@", timeArray);
        AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        gen.appliesPreferredTrackTransform = YES;
        //如果需要精确时间
        gen.requestedTimeToleranceAfter = kCMTimeZero;
        gen.requestedTimeToleranceBefore = kCMTimeZero;
        gen.maximumSize = size;
        gen.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
        [gen generateCGImagesAsynchronouslyForTimes:timeArray
                                  completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
                                      NSLog(@"requestedTime:%@ actualTime:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, requestedTime)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, actualTime)));
                                      if ((cancel && *(cancel)) || result == AVAssetImageGeneratorFailed || result == AVAssetImageGeneratorCancelled || CMTimeCompare(requestedTime, [[timeArray lastObject] CMTimeValue]) >= 0) {
                                          [gen cancelAllCGImageGeneration];
                                          RDGIFEncoderStop(gifHandle);
                                          RDGIFEncoderFinish(gifHandle);
                                          [exportGifTimer invalidate];
                                          exportGifTimer = nil;
                                          if (failedHandler && result == AVAssetImageGeneratorFailed) {
                                              failedHandler();
                                          }
                                          if (completionHandler && CMTimeCompare(requestedTime, [[timeArray lastObject] CMTimeValue]) >= 0) {
                                              completionHandler();
                                          }
                                      }
                                      else if (image) {
                                          @autoreleasepool {
                                              CFDataRef abgrData = CGDataProviderCopyData(CGImageGetDataProvider(image));
                                              uint8_t* pixelBuffer = (uint8_t *)CFDataGetBytePtr(abgrData);
                                              int length = CGImageGetHeight(image);
                                              UInt8 tmpByte = 0;
                                              for (int index = 0; index < length; index+= 4) {
                                                  tmpByte = pixelBuffer[index + 1];
                                                  pixelBuffer[index + 1] = pixelBuffer[index + 3];
                                                  pixelBuffer[index + 3] = tmpByte;
                                              }
                                              int suc = RDGIFEncoderAddFrame(gifHandle, pixelBuffer, size.width, size.height, 32);
                                              NSLog(@"suc:%d", suc);
//                                              CGImageRelease(image);
                                          }
                                      }
                                  }];
    });
}
#endif
- (void)updateExportGifProgress{
    int progress = RDGIFEncoderGetProgress(gifHandle);
    NSLog(@"%d", progress);
    exportGifProgressHandler(progress);
}

+ (float)isGifWithData:(NSData *)imageData {
    if (!imageData) {
        return 0;
    }
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
    size_t count = CGImageSourceGetCount(source);
    if (count <= 1) {
        if (source) {
            CFRelease(source);
        }
        return 0;
    }
    else {
        float duration = 0.0f;
        for (size_t i = 0; i < count; i++) {
            CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, i, NULL);
            duration += [RDRecordHelper frameDurationAtIndex:i source:source];
            CGImageRelease(imageRef);
        }
        if (source) {
            CFRelease(source);
        }
        return duration;
    }
}

+ (CMTimeRange)getActualTimeRange:(NSURL *)path {
    return [RDRecordHelper getActualTimeRange:path];
}

@end
