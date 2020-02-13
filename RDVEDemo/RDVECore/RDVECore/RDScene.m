//
//  RDScene.m
//  RDVECore
//
//  Created by 周晓林 on 2017/5/11.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#import "RDScene.h"
@implementation VVMovieEffect
- (instancetype)init{
    if(self = [super init]){
        _shouldRepeat = YES;
    }
    return self;
}
@end
@implementation FilterAttribute
@end


@implementation RDScene

- (instancetype)init {
    self = [super init];
    if (self) {
        _transition = [[VVTransition alloc] init];
        _vvAsset = [NSMutableArray array];
    }
    
    return self;
}

@end


@implementation VVTransition

- (instancetype)init{
    self = [super init];
    if (self) {
        _type = RDVideoTransitionTypeNone;
        _duration = 0.0;
    }
    return self;
}

@end
@implementation RDMusic
- (instancetype)init{
    self = [super init];
    if (self) {
        _volume = 1.0;
        _pitch = 1.0;
        _isRepeat = YES;
        _effectiveTimeRange = kCMTimeRangeZero;
        _headFadeDuration = 2.0;
        _endFadeDuration = 2.0;
        _audioFilterType = RDAudioFilterTypeNormal;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    RDMusic *copy = [[[self class] allocWithZone:zone] init];
    copy.identifier = _identifier;
    copy.url = _url;
    copy.clipTimeRange = _clipTimeRange;
    copy.effectiveTimeRange = _effectiveTimeRange;
    copy.volume = _volume;
    copy.isRepeat = _isRepeat;
    copy.name = _name;
    copy.pitch = _pitch;
    copy.isFadeInOut = _isFadeInOut;
    copy.fadeDuration = _fadeDuration;
    copy.headFadeDuration = _headFadeDuration;
    copy.endFadeDuration = _endFadeDuration;
    copy.audioFilterType = _audioFilterType;
    
    return copy;
}

- (id)mutableCopyWithZone:(NSZone *)zone {    
    RDMusic *copy = [[[self class] allocWithZone:zone] init];
    copy.identifier = _identifier;
    copy.url = _url;
    copy.clipTimeRange = _clipTimeRange;
    copy.effectiveTimeRange = _effectiveTimeRange;
    copy.volume = _volume;
    copy.isRepeat = _isRepeat;
    copy.name = _name;
    copy.pitch = _pitch;
    copy.isFadeInOut = _isFadeInOut;
    copy.fadeDuration = _fadeDuration;
    copy.headFadeDuration = _headFadeDuration;
    copy.endFadeDuration = _endFadeDuration;
    copy.audioFilterType = _audioFilterType;
    
    return copy;
}

- (void)setFadeDuration:(float)fadeDuration {
    _headFadeDuration = fadeDuration;
    _endFadeDuration = fadeDuration;
}

@end

@implementation RDAssetBlur

- (instancetype)init{
    if (self = [super init]) {
        _type = RDAssetBlurNormal;
        _intensity = 0.5;
        [self setPointsLeftTop:CGPointMake(0, 0) rightTop:CGPointMake(1, 0) rightBottom:CGPointMake(1, 1) leftBottom:CGPointMake(0, 1)];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    RDAssetBlur *copy = [[[self class] allocWithZone:zone] init];
    copy.type = _type;
    copy.intensity = _intensity;
    copy.timeRange = _timeRange;
    [copy setPointsLeftTop:CGPointFromString(_pointsArray[0]) rightTop:CGPointFromString(_pointsArray[1]) rightBottom:CGPointFromString(_pointsArray[2]) leftBottom:CGPointFromString(_pointsArray[3])];
    
    return copy;
}

- (id)mutableCopyWithZone:(NSZone *)zone{
    RDAssetBlur *copy = [[[self class] allocWithZone:zone] init];
    copy.type = _type;
    copy.intensity = _intensity;
    copy.timeRange = _timeRange;
    [copy setPointsLeftTop:CGPointFromString(_pointsArray[0]) rightTop:CGPointFromString(_pointsArray[1]) rightBottom:CGPointFromString(_pointsArray[2]) leftBottom:CGPointFromString(_pointsArray[3])];
    
    return copy;
}

- (NSArray *)setPointsLeftTop:(CGPoint)leftTop rightTop:(CGPoint)rightTop rightBottom:(CGPoint)rightBottom leftBottom:(CGPoint)leftBottom
{
    _pointsArray = [NSArray arrayWithObjects:NSStringFromCGPoint(leftTop), NSStringFromCGPoint(rightTop), NSStringFromCGPoint(rightBottom), NSStringFromCGPoint(leftBottom), nil];
    return _pointsArray;
}
@end

@implementation VVAssetAnimatePosition
- (instancetype)init{
    if (self = [super init]) {
        _opacity = 1.0;
        _brightness = 0.0;
        _contrast = 1.0;
        _saturation = 1.0;
        _rotate = 0;
        _vignette = 0.0;
        _sharpness = 0.0;
        _whiteBalance = 0.0;
//        _scale = 1.0;
//        _location = CGPointMake(0, 0 );
        _rect = CGRectMake(0, 0, 1, 1);
        _crop = CGRectMake(0, 0, 1, 1);
        _anchorPoint = CGPointMake(0.5, 0.5);
        _fillScale = 1.0;
        _isUseRect = YES;
    }
    return self;
}



- (void)setRect:(CGRect)rect {
    _rect = rect;
    _isUseRect = YES;
}

- (NSArray *)setPointsLeftTop:(CGPoint)leftTop rightTop:(CGPoint)rightTop rightBottom:(CGPoint)rightBottom leftBottom:(CGPoint)leftBottom
{
    _pointsArray = @[@[@(leftTop.x), @(leftTop.y)],
                     @[@(rightTop.x), @(rightTop.y)],
                     @[@(rightBottom.x), @(rightBottom.y)],
                     @[@(leftBottom.x), @(leftBottom.y)]];
    _rect = CGRectMake(0, 0, 1, 1);
    _isUseRect = NO;
    return _pointsArray;
}

@end



@interface VVAsset()
@property (nonatomic,strong) AVURLAsset* asset;

@property (nonatomic,assign) float            maxAlphaInVideo; //灰度范围
@property (nonatomic,assign) float            minAlphaInVideo;

@property (nonatomic,assign) BOOL             isCompleteEdge;
@end

@implementation VVAsset
- (instancetype)init{
    self = [super init];
    if (self) {
        _speed = 1.0;
        _volume = 1.0;
        _pitch = 1.0;
        _isCompleteEdge = YES;
        _rectInVideo = CGRectMake(0, 0, 1, 1);
        _isUseRect = YES;
        _startTimeInScene = kCMTimeZero;
        _isRepeat = NO;
        _timeRangeInVideo = kCMTimeRangeZero;
        _videoActualTimeRange = kCMTimeRangeZero;
        _fillType = RDImageFillTypeFitZoomIn;
        _videoFillType = RDVideoFillTypeFit;
        _brightness = 0.0;
        _contrast = 1.0;
        _saturation = 1.0;
        _filterType = VVAssetFilterEmpty;
        _filterIntensity = 1.0;
        _crop = CGRectMake(0, 0, 1, 1);
        _alpha = 1.0;
        _audioFilterType = RDAudioFilterTypeNormal;
        _srcFactor = BLEND_GL_SRC_ALPHA;
        _dstFactor = BLEND_GL_ONE_MINUS_SRC_ALPHA;
        _blendModel = EQUATION_GL_FUNC_ADD;
        _blurIntensity = 0.0;
        _isBlurredBorder = NO;
        _beautyBlurIntensity = 0.0;
        _beautyToneIntensity = 0.0;
        _beautyBrightIntensity = 0.0;
        _blendType = RDBlendNormal;
        _chromaColor = nil;
    }
    return self;
}

- (void)setRotate:(double)rotate {
    _rotate = rotate;
    NSInteger value = _rotate;
    
    //如果 _rectInVideo == CGRectMake(0, 0, 1, 1)，即全屏显示，   旋转角度取值范围：  -360< x < 0
    //如果 _rectInVideo != CGRectMake(0, 0, 1, 1)，即非全屏显示， 旋转角度取值范围：  0< x < 360
    
    if (CGRectEqualToRect(_rectInVideo, CGRectMake(0, 0, 1, 1))) {
        if(value == -270 || value == 90){
            // solaren fix 90度时无法铺满全屏  因为核心中采用的是-360< x < 0 ,所以此处必须修正 否则匹配错误
            _rotate = -270;
        }
        else if(value == -90 || value == 270){
            _rotate = -90;
        }else if(value == -180 || value == 180){
            _rotate = -180;
        }else
            if (value < 0) {
            _rotate += 360;//20190429 媒体角度是负数的情况，画中画大小与设置不一致
        }
    }else  if (value < 0) {
       _rotate += 360;//20190429 媒体角度是负数的情况，画中画大小与设置不一致
   }
}

- (id)copyWithZone:(NSZone *)zone{
    VVAsset *copy = [[[self class] allocWithZone:zone] init];
    copy.identifier = _identifier;
    copy.url = _url;
    copy.type = _type;
    copy.fillType = _fillType;
    copy.customFilter = _customFilter;
    copy.videoFillType = _videoFillType;
    copy.timeRange = _timeRange;
    copy.startTimeInScene = _startTimeInScene;
    copy.isRepeat = _isRepeat;
    copy.timeRangeInVideo = _timeRangeInVideo;
    copy.videoActualTimeRange = _videoActualTimeRange;
    copy.speed = _speed;
    copy.volume = _volume;
    copy.audioFadeInDuration = _audioFadeInDuration;
    copy.audioFadeOutDuration = _audioFadeOutDuration;
    copy.crop = _crop;
    copy.rotate = _rotate;
    copy.isVerticalMirror = _isVerticalMirror;
    copy.isHorizontalMirror = _isHorizontalMirror;
    copy.rectInVideo = _rectInVideo;
    copy.alpha = _alpha;
    copy.brightness = _brightness;
    copy.contrast = _contrast;
    copy.saturation = _saturation;
    copy.vignette = _vignette;
    copy.sharpness = _sharpness;
    copy.whiteBalance = _whiteBalance;
    copy.filterType = _filterType;
    copy.filterUrl = _filterUrl;
    copy.maskURL = _maskURL;
    copy.mosaicURL = _mosaicURL;
    copy.rectMosaic = _rectMosaic;
    copy.mosaicAngle = _mosaicAngle;
    copy.animate = _animate;
    copy.audioFilterType = _audioFilterType;
    copy.srcFactor = _srcFactor;
    copy.dstFactor = _dstFactor;
    copy.blendModel = _blendModel;
    copy.blur = _blur;
    copy.blurIntensity = _blurIntensity;
    copy.isBlurredBorder = _isBlurredBorder;
    
    copy.beautyBlurIntensity = _beautyBlurIntensity;
    copy.beautyBrightIntensity = _beautyBrightIntensity;
    copy.beautyToneIntensity = _beautyToneIntensity;
    copy.blendType = _blendType;
    copy.chromaColor = _chromaColor;
    return copy;
}

- (id)mutableCopyWithZone:(NSZone *)zone{
    VVAsset *copy = [[[self class] allocWithZone:zone] init];
    copy.identifier = _identifier;
    copy.url = _url;
    copy.type = _type;
    copy.fillType = _fillType;
    copy.customFilter = _customFilter;
    copy.videoFillType = _videoFillType;
    copy.timeRange = _timeRange;
    copy.startTimeInScene = _startTimeInScene;
    copy.isRepeat = _isRepeat;
    copy.timeRangeInVideo = _timeRangeInVideo;
    copy.videoActualTimeRange = _videoActualTimeRange;
    copy.speed = _speed;
    copy.volume = _volume;
    copy.audioFadeInDuration = _audioFadeInDuration;
    copy.audioFadeOutDuration = _audioFadeOutDuration;
    copy.crop = _crop;
    copy.rotate = _rotate;
    copy.isVerticalMirror = _isVerticalMirror;
    copy.isHorizontalMirror = _isHorizontalMirror;
    copy.rectInVideo = _rectInVideo;
    copy.alpha = _alpha;
    copy.brightness = _brightness;
    copy.contrast = _contrast;
    copy.saturation = _saturation;
    copy.vignette = _vignette;
    copy.sharpness = _sharpness;
    copy.whiteBalance = _whiteBalance;
    copy.filterType = _filterType;
    copy.filterUrl = _filterUrl;
    copy.maskURL = _maskURL;
    copy.mosaicURL = _mosaicURL;
    copy.rectMosaic = _rectMosaic;
    copy.mosaicAngle = _mosaicAngle;
    copy.animate = _animate;
    copy.audioFilterType = _audioFilterType;
    copy.srcFactor = _srcFactor;
    copy.dstFactor = _dstFactor;
    copy.blendModel = _blendModel;
    copy.blur = _blur;
    copy.blurIntensity = _blurIntensity;
    copy.isBlurredBorder = _isBlurredBorder;
    
    copy.beautyBlurIntensity = _beautyBlurIntensity;
    copy.beautyBrightIntensity = _beautyBrightIntensity;
    copy.beautyToneIntensity = _beautyToneIntensity;
    copy.blendType = _blendType;
    copy.chromaColor = _chromaColor;
    return copy;
}

- (void)setRectInVideo:(CGRect)rectInVideo {
    _rectInVideo = rectInVideo;
    _isUseRect = YES;
    self.rotate = _rotate;
}

- (NSArray *)setPointsInVideoLeftTop:(CGPoint)leftTop rightTop:(CGPoint)rightTop rightBottom:(CGPoint)rightBottom leftBottom:(CGPoint)leftBottom
{
    _pointsInVideoArray = @[@[@(leftTop.x), @(leftTop.y)],
                            @[@(rightTop.x), @(rightTop.y)],
                            @[@(rightBottom.x), @(rightBottom.y)],
                            @[@(leftBottom.x), @(leftBottom.y)]];
    _rectInVideo = CGRectMake(0, 0, 1, 1);
    _isUseRect = NO;
    return _pointsInVideoArray;
}

- (AVURLAsset *)asset{
    return [AVURLAsset assetWithURL:_url];
}
#if 0   //20180522 wuxiaoxia 使用Float64类型，由于精度问题，会导致时间与track实际insert的时间差一点(如0.01秒），从而导致视频黑屏，为解决此问题使用下面的CMTime类型
- (Float64)duration{
    return CMTimeGetSeconds(CMTimeAdd(_timeRange.duration, _startTimeInScene))/_speed;
}
#else
- (CMTime)duration {
#if 0   //20180713 wuxiaoxia 使用CMTimeMultiplyByFloat64后，timescale会变成NSEC_PER_SEC，从而导致视频黑屏
    return CMTimeMultiplyByFloat64(CMTimeAdd(_timeRange.duration, _startTimeInScene), 1.0/_speed);
#else
    CMTime dur = CMTimeAdd(_timeRange.duration, _startTimeInScene);
    dur = CMTimeMake(dur.value/_speed, dur.timescale);
    return dur;
#endif
}
#endif

- (void)setCustomFilter:(RDCustomFilter *)customFilter {
    _customFilter = nil;
    _customFilter = customFilter;
}

@end
@implementation MaskAsset
@end
@implementation RDCaptionAnimate : NSObject

- (instancetype)init{
    self = [super init];
    if (self) {
        _isFade = YES;
        _fadeInDuration = 1.0;
        _fadeOutDuration = 1.0;
        _inDuration = 1.0;
        _outDuration = 1.0;
        _scaleIn = 0.0;
        _scaleOut = 1.0;
        _pushInPoint = CGPointZero;
        _pushOutPoint = CGPointZero;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    RDCaptionAnimate *copy = [[[self class] allocWithZone:zone] init];
    copy.isFade = _isFade;
    copy.fadeInDuration = _fadeInDuration;
    copy.fadeOutDuration = _fadeOutDuration;
    copy.type = _type;
    copy.inType = _inType;
    copy.outType = _outType;
    copy.inDuration = _inDuration;
    copy.outDuration = _outDuration;
    copy.pushInPoint = _pushInPoint;
    copy.pushOutPoint = _pushOutPoint;
    copy.scaleIn = _scaleIn;
    copy.scaleOut = _scaleOut;
    return copy;
}

- (id)mutableCopyWithZone:(NSZone *)zone{
    RDCaptionAnimate *copy = [[[self class] allocWithZone:zone] init];
    copy.isFade = _isFade;
    copy.fadeInDuration = _fadeInDuration;
    copy.fadeOutDuration = _fadeOutDuration;
    copy.type = _type;
    copy.inType = _inType;
    copy.outType = _outType;
    copy.inDuration = _inDuration;
    copy.outDuration = _outDuration;
    copy.pushInPoint = _pushInPoint;
    copy.pushOutPoint = _pushOutPoint;
    copy.scaleIn = _scaleIn;
    copy.scaleOut = _scaleOut;
    return copy;
}

@end

@implementation RDDoodle : NSObject

- (id)copyWithZone:(NSZone *)zone{
    RDDoodle *copy   = [[[self class] allocWithZone:zone] init];
    copy.path = _path;
    copy.timeRange = _timeRange;
    return copy;
}

- (id)mutableCopyWithZone:(NSZone *)zone{
    RDDoodle *copy   = [[[self class] allocWithZone:zone] init];
    copy.path = _path;
    copy.timeRange = _timeRange;
    return copy;
}

@end


@implementation RDDoodleLayer : CALayer

- (id)copyWithZone:(NSZone *)zone{
    RDDoodleLayer *copy   = [[[self class] allocWithZone:zone] init];
    copy.path = _path;
    copy.timeRange = _timeRange;
    return copy;
}

- (id)mutableCopyWithZone:(NSZone *)zone{
    RDDoodleLayer *copy   = [[[self class] allocWithZone:zone] init];
    copy.path = _path;
    copy.timeRange = _timeRange;
    return copy;
}

@end

@implementation RDCaptionCustomAnimate

- (instancetype)init {
    self = [super init];
    if (self) {
        _opacity = 1.0;
        _scale = 1.0;
        _rect = CGRectZero;
    }
    
    return self;
}

@end

@implementation RDCaption : NSObject

- (instancetype)init{
    self = [super init];
    if (self) {
        _backgroundColor = [UIColor clearColor];
        _strokeColor = [UIColor clearColor];
        _tAlignment = RDCaptionTextAlignmentCenter;
        _strokeColor = [UIColor blackColor];
        _tShadowColor = [UIColor blackColor];
        _tShadowOffset = CGSizeMake(0, -1);
        _textAnimate = [[RDCaptionAnimate alloc] init];
        _imageAnimate = [[RDCaptionAnimate alloc] init];
        _textAlpha = 1.0;
        _strokeAlpha = 1.0;
        _position = CGPointMake(0.5, 0.5);
        _scale = 1.0;
        _tColor = [UIColor whiteColor];
        _opacity = 1.0;
        _shadowAlpha = 1.0;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    RDCaption *copy   = [[[self class] allocWithZone:zone] init];
    copy.backgroundColor = _backgroundColor;
    copy.timeRange = _timeRange;
    copy.angle = _angle;
    copy.scale = _scale;
    copy.type = _type;
    copy.stickerType = _stickerType;
    copy.captionImagePath = _captionImagePath;
    copy.imageFolderPath = _imageFolderPath;
    copy.imageName = _imageName;
    copy.duration = _duration;
    copy.position = _position;
    copy.size = _size;
    copy.pText = _pText;
    copy.attriStr = _attriStr;
    copy.tImage = _tImage;
    copy.tFontName = _tFontName;
    copy.tFontSize = _tFontSize;
    copy.isBold = _isBold;
    copy.isItalic = _isItalic;
    copy.tAlignment = _tAlignment;
    copy.tAngle = _tAngle;
    copy.tColor = _tColor;
    copy.strokeColor = _strokeColor;
    copy.strokeWidth = _strokeWidth;
    copy.strokeAlpha = _strokeAlpha;
    copy.isShadow = _isShadow;
    copy.tShadowColor = _tShadowColor;
    copy.tShadowOffset = _tShadowOffset;
    copy.shadowAlpha = _shadowAlpha;
    copy.tFrame = _tFrame;
    copy.textAlpha = _textAlpha;
    copy.frameArray = _frameArray;
    copy.timeArray = _timeArray;
    copy.isStretch = _isStretch;
    copy.stretchRect = _stretchRect;
    copy.music = _music;
    copy.textAnimate = [_textAnimate mutableCopy];
    copy.imageAnimate = [_imageAnimate mutableCopy];
    copy.isVerticalText = _isVerticalText;
    return copy;
}

- (id)mutableCopyWithZone:(NSZone *)zone{
    RDCaption *copy   = [[[self class] allocWithZone:zone] init];
    copy.backgroundColor = _backgroundColor;
    copy.timeRange = _timeRange;
    copy.angle = _angle;
    copy.scale = _scale;
    copy.type = _type;
    copy.stickerType = _stickerType;
    copy.captionImagePath = _captionImagePath;
    copy.imageFolderPath = _imageFolderPath;
    copy.imageName = _imageName;
    copy.duration = _duration;
    copy.position = _position;
    copy.pText = _pText;
    copy.attriStr = _attriStr;
    copy.tImage = _tImage;
    copy.tFontName = _tFontName;
    copy.tFontSize = _tFontSize;
    copy.isBold = _isBold;
    copy.isItalic = _isItalic;
    copy.tAlignment = _tAlignment;
    copy.tAngle = _tAngle;
    copy.tColor = _tColor;
    copy.strokeColor = _strokeColor;
    copy.strokeWidth = _strokeWidth;
    copy.strokeAlpha = _strokeAlpha;
    copy.isShadow = _isShadow;
    copy.tShadowColor = _tShadowColor;
    copy.tShadowOffset = _tShadowOffset;
    copy.shadowAlpha = _shadowAlpha;
    copy.tFrame = _tFrame;
    copy.size = _size;
    copy.textAlpha = _textAlpha;
    copy.frameArray = _frameArray;
    copy.timeArray = _timeArray;
    copy.isStretch = _isStretch;
    copy.stretchRect = _stretchRect;
    copy.music = _music;
    copy.textAnimate = [_textAnimate mutableCopy];
    copy.imageAnimate = [_imageAnimate mutableCopy];
    copy.isVerticalText = _isVerticalText;
    return copy;
    
}

- (void)setImagePath:(NSString *)imagePath {
    _imagePath = imagePath;
    _imageFolderPath = imagePath;
}

@end

@implementation RDCaptionLightCustomAnimate

- (instancetype)init {
    self = [super init];
    if (self) {
        _opacity = 1.0;
    }
    
    return self;
}

- (NSArray *)setPointsLeftTop:(CGPoint)leftTop rightTop:(CGPoint)rightTop rightBottom:(CGPoint)rightBottom leftBottom:(CGPoint)leftBottom
{
    _pointsArray = @[@[@(leftTop.x), @(leftTop.y)],
                     @[@(rightTop.x), @(rightTop.y)],
                     @[@(rightBottom.x), @(rightBottom.y)],
                     @[@(leftBottom.x), @(leftBottom.y)]];
    return _pointsArray;
}

@end

@implementation RDCaptionLight

- (instancetype)init {
    self = [super init];
    if (self) {
        _isFade = NO;
        _fadeInDuration = 1.0;
        _fadeOutDuration = 1.0;
    }
    
    return self;
}

- (NSArray *)setPointsInVideoLeftTop:(CGPoint)leftTop rightTop:(CGPoint)rightTop rightBottom:(CGPoint)rightBottom leftBottom:(CGPoint)leftBottom
{
    _pointsInVideoArray = @[@[@(leftTop.x), @(leftTop.y)],
                            @[@(rightTop.x), @(rightTop.y)],
                            @[@(rightBottom.x), @(rightBottom.y)],
                            @[@(leftBottom.x), @(leftBottom.y)]];
    return _pointsInVideoArray;
}
- (id)copyWithZone:(NSZone *)zone{
    RDCaptionLight *copy   = [[[self class] allocWithZone:zone] init];
    copy.timeRange = _timeRange;
    copy.imagePath = _imagePath;
    copy.isFade = _isFade;
    copy.fadeInDuration = _fadeInDuration;
    copy.fadeOutDuration = _fadeOutDuration;

    return copy;
}

- (id)mutableCopyWithZone:(NSZone *)zone{
    RDCaptionLight *copy   = [[[self class] allocWithZone:zone] init];
    copy.timeRange = _timeRange;
    copy.imagePath = _imagePath;
    copy.isFade = _isFade;
    copy.fadeInDuration = _fadeInDuration;
    copy.fadeOutDuration = _fadeOutDuration;
    
    return copy;
}

@end

@implementation RDJsonText

- (instancetype)init {
    self = [super init];
    if (self) {
        _startTime = -1;
        _duration = -1;
        _textAlignment = RDCaptionTextAlignmentCenter;
        _textColor = [UIColor whiteColor];
        _alpha = 1.0;
        _strokeColor = [UIColor blackColor];
        _strokeAlpha = 1.0;
        _shadowColor = [UIColor blackColor];
        _shadowOffset = CGSizeMake(0, -1);
    }
    return self;
}

@end


@implementation RDJsonAnimationBGSource

- (instancetype)init{
    self = [super init];
    if (self) {
        _fillType = RDImageFillTypeFit;
        _videoFillType = RDVideoFillTypeFit;
        _crop = CGRectMake(0, 0, 1, 1);
        _startTimeInVideo = kCMTimeZero;
        _timeRangeInVideo = kCMTimeRangeZero;
        _volume = 1.0;
        _isRepeat = NO;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    RDJsonAnimationBGSource *copy   = [[[self class] allocWithZone:zone] init];
    copy.identifier = _identifier;
    copy.path = _path;
    copy.type = _type;
    copy.fillType = _fillType;
    copy.videoFillType = _videoFillType;
    copy.crop = _crop;
    copy.timeRange = _timeRange;
    copy.timeRangeInVideo = _timeRangeInVideo;
    copy.startTimeInVideo = _startTimeInVideo;
    copy.volume = _volume;
    copy.isRepeat = _isRepeat;
    copy.music = [_music copy];
    
    return copy;
}

- (id)mutableCopyWithZone:(NSZone *)zone{
    RDJsonAnimationBGSource *copy   = [[[self class] allocWithZone:zone] init];
    copy.identifier = _identifier;
    copy.path = _path;
    copy.type = _type;
    copy.fillType = _fillType;
    copy.videoFillType = _videoFillType;
    copy.crop = _crop;
    copy.timeRange = _timeRange;
    copy.timeRangeInVideo = _timeRangeInVideo;
    copy.startTimeInVideo = _startTimeInVideo;
    copy.volume = _volume;
    copy.isRepeat = _isRepeat;
    copy.music = [_music mutableCopy];
    
    return copy;
}

- (void)setStartTimeInVideo:(CMTime)startTimeInVideo {
    _startTimeInVideo = startTimeInVideo;
    if (CMTimeRangeEqual(_timeRangeInVideo, kCMTimeRangeZero)) {
        _timeRangeInVideo = CMTimeRangeMake(startTimeInVideo, _timeRange.duration);
    }
}

- (void)setTimeRange:(CMTimeRange)timeRange {
    _timeRange = timeRange;
    if (CMTimeCompare(_timeRangeInVideo.duration, kCMTimeZero) == 0) {
        _timeRangeInVideo = CMTimeRangeMake(_timeRangeInVideo.start, timeRange.duration);
    }
}

@end

@implementation RDJsonAnimation : NSObject

- (instancetype)init{
    self = [super init];
    if (self) {
        _exportFps = 18;
        _targetImageMaxSize = 720.0;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    RDJsonAnimation *copy   = [[[self class] allocWithZone:zone] init];
    copy.name = _name;
    copy.jsonPath = _jsonPath;
    copy.jsonDictionary = [_jsonDictionary copy];
    copy.nonEditableImagePathArray = [_nonEditableImagePathArray copy];
    copy.backgroundSourceArray = [_backgroundSourceArray copy];
    copy.bgSourceArray = [_bgSourceArray copy];
    copy.exportFps = _exportFps;
    
    return copy;
}

- (id)mutableCopyWithZone:(NSZone *)zone{
    RDJsonAnimation *copy   = [[[self class] allocWithZone:zone] init];
    copy.name = _name;
    copy.jsonPath = _jsonPath;
    copy.jsonDictionary = [_jsonDictionary mutableCopy];
    copy.nonEditableImagePathArray = [_nonEditableImagePathArray mutableCopy];
    copy.backgroundSourceArray = [_backgroundSourceArray mutableCopy];
    copy.bgSourceArray = [_bgSourceArray mutableCopy];
    copy.exportFps = _exportFps;

    return copy;
}

@end

@implementation RDAESourceInfo

- (instancetype)init{
    self = [super init];
    if (self) {
        
    }
    return self;
}

@end

@implementation RDPostion

@end

@implementation RDDewatermark

- (instancetype)init{
    self = [super init];
    if (self) {
        _timeRange = kCMTimeRangeZero;
        _rect = CGRectMake(0, 0, 1, 1);
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    RDDewatermark *copy = [[[self class] allocWithZone:zone] init];
    copy.timeRange = _timeRange;
    copy.rect = _rect;
    
    return copy;
}

- (id)mutableCopyWithZone:(NSZone *)zone{
    RDDewatermark *copy = [[[self class] allocWithZone:zone] init];
    copy.timeRange = _timeRange;
    copy.rect = _rect;
    
    return copy;
}

@end


@implementation RDWatermark

- (instancetype)init{
    self = [super init];
    if (self) {
        _timeRange = kCMTimeRangeZero;
        _isRepeat = YES;
        _vvAsset = [[VVAsset alloc] init];
        
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    RDWatermark *copy = [[[self class] allocWithZone:zone] init];
    copy.timeRange = _timeRange;
    copy.vvAsset = [_vvAsset copy];
    
    return copy;
}

- (id)mutableCopyWithZone:(NSZone *)zone{
    RDWatermark *copy = [[[self class] allocWithZone:zone] init];
    copy.timeRange = _timeRange;
    copy.vvAsset = [_vvAsset mutableCopy];
    
    return copy;
}

@end

@implementation RDMosaic

- (instancetype)init{
    self = [super init];
    if (self) {        
        _mosaicSize = 0.1;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    RDMosaic *copy = [[[self class] allocWithZone:zone] init];
    copy.timeRange = _timeRange;
    copy.mosaicSize = _mosaicSize;
    [copy setPointsLeftTop:CGPointFromString(_pointsArray[0]) rightTop:CGPointFromString(_pointsArray[1]) rightBottom:CGPointFromString(_pointsArray[2]) leftBottom:CGPointFromString(_pointsArray[3])];
    
    return copy;
}

- (id)mutableCopyWithZone:(NSZone *)zone{
    RDMosaic *copy = [[[self class] allocWithZone:zone] init];
    copy.timeRange = _timeRange;
    copy.mosaicSize = _mosaicSize;
    [copy setPointsLeftTop:CGPointFromString(_pointsArray[0]) rightTop:CGPointFromString(_pointsArray[1]) rightBottom:CGPointFromString(_pointsArray[2]) leftBottom:CGPointFromString(_pointsArray[3])];
    
    return copy;
}

- (NSArray *)setPointsLeftTop:(CGPoint)leftTop rightTop:(CGPoint)rightTop rightBottom:(CGPoint)rightBottom leftBottom:(CGPoint)leftBottom
{
    _pointsArray = [NSArray arrayWithObjects:NSStringFromCGPoint(leftTop), NSStringFromCGPoint(rightTop), NSStringFromCGPoint(rightBottom), NSStringFromCGPoint(leftBottom), nil];
    return _pointsArray;
}

@end
