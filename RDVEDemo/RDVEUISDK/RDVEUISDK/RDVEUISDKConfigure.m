//
//  RDVEUISDKConfigure.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2017/7/15.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDVEUISDKConfigure.h"

@implementation RDMusicInfo

@end

@implementation ExportConfiguration
- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _outputVideoMaxDuration = 0;
        _inputVideoMaxDuration = 0;
        //设置视频片尾和码率
        _endPicDisabled = true;
        _endPicUserName = @" ";
        _videoBitRate   = 6.0;
        _endPicDuration = 2.0;
        _endPicFadeDuration = 1.0;
        //设置水印是否可用
        _waterDisabled = true;
        _waterText = nil;
        _waterImage = nil;
        _waterPosition = WATERPOSITION_LEFTBOTTOM;
        
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    ExportConfiguration *copy   = [[[self class] allocWithZone:zone] init];
    copy.outputVideoMaxDuration   = _outputVideoMaxDuration;
    copy.inputVideoMaxDuration    = _inputVideoMaxDuration;
    //设置视频片尾和码率
    copy.endPicDisabled     = _endPicDisabled;
    copy.endPicUserName     = _endPicUserName;
    copy.endPicDuration     = _endPicDuration;
    copy.endPicFadeDuration = _endPicFadeDuration;
    copy.endPicImagepath    = _endPicImagepath;
    copy.videoBitRate       = _videoBitRate;
    //设置水印是否可用
    copy.waterDisabled      = _waterDisabled;
    copy.waterText          = _waterText;
    copy.waterImage         = _waterImage;
    copy.waterPosition      = _waterPosition;
    return copy;
}

- (id)mutableCopyWithZone:(NSZone *)zone{
    ExportConfiguration *copy   = [[[self class] allocWithZone:zone] init];
    copy.outputVideoMaxDuration   = _outputVideoMaxDuration;
    copy.inputVideoMaxDuration    = _inputVideoMaxDuration;
    //设置视频片尾和码率
    copy.endPicDisabled     = _endPicDisabled;
    copy.endPicUserName     = _endPicUserName;
    copy.endPicDuration     = _endPicDuration;
    copy.endPicFadeDuration = _endPicFadeDuration;
    copy.endPicImagepath    = _endPicImagepath;
    copy.videoBitRate       = _videoBitRate;
    //设置水印是否可用
    copy.waterDisabled      = _waterDisabled;
    copy.waterText          = _waterText;
    copy.waterImage         = _waterImage;
    copy.waterPosition      = _waterPosition;
    return copy;
    
}

- (void)setWaterText:(NSString *)waterText{
    _waterText = waterText;
    if(waterText.length>0){
        _waterImage = nil;
    }
}
- (void)setWaterImage:(UIImage *)waterImage{
    _waterImage = waterImage;
    if(waterImage){
        _waterText  = nil;
    }
}

@end

@implementation TencentCloudAIRecogConfig

- (instancetype)init {
    if (self = [super init]) {
        _appId = @"1259660397";
        _secretId = @"AKIDmOlskNuJdiY8Sqhxf8LI5wXtzpQ63K4Y";
        _secretKey = @"OXQcYEiwusa1EAqGPIxM5apoXzCBuACy";
        _serverCallbackPath = @"http://d.56show.com/filemanage2/public/filemanage/voice2text/audio2text4tencent";
    }
    return self;
}

@end

@implementation EditConfiguration
- (instancetype)init{
    if(self = [super init]){
        //向导设置默认关闭
        _enableWizard                           = false;
        _supportFileType                        = SUPPORT_ALL;
        _defaultSelectAlbum                     = RDDEFAULTSELECTALBUM_VIDEO;
        _mediaCountLimit                         = 0;
        _enableTextTitle                 = true;
        //片段编辑预设
        _enableSingleMediaAdjust = true;
        _enableSingleSpecialEffects = true;
        _enableSingleMediaFilter         = true;
        _enableTrim                      = true;
        _enableTrim                      = true;
        _enableSplit                     = true;
        _enableReplace                  = true;
        _enableTransparency             = true;
        _enableEdit                      = true;
        _enableRotate = true;
        _enableMirror = true;
        _enableFlipUpAndDown = true;
        _enableTransition = true;
        _enableVolume = true;
        _enableSpeedcontrol              = true;
        _enableCopy                      = true;
        _enableSort                      = true;
        _enableImageDurationControl      = true;
        _enableProportion                = true;
        _enableReverseVideo              = true;
        _proportionType = RDPROPORTIONTYPE_AUTO;
        _enableAlbumCamera = true;
        _enableAnimation = true;
        _enableBeauty = true;
        
        //编辑导出预设
        _enableMV           = false;
        _enableSubtitle     = true;
        _enableAIRecogSubtitle = true;
        _tencentAIRecogConfig = [[TencentCloudAIRecogConfig alloc] init];
        _enableSticker      = true;
        _enablePicZoom = true;
        _enableBackgroundEdit = true;
        _enableFilter       = true;
        _enableEffectsVideo = true;
        _enableDubbing      = true;
        _enableMusic        = true;
        _enableSoundEffect  = true;
        _enableMosaic       = true;
        _enableWatermark    = true;
        _enableDewatermark  = true;
        _enableFragmentedit = true;
        _enableLocalMusic   = true;
        _enableCollage      = true;
        _enableCover        = true;
        _enableDoodle       = true;
        _dubbingType    = RDDUBBINGTYPE_FIRST;
        //截取视频预设
        _defaultSelectMinOrMax          = kRDDefaultSelectCutMin;
        _trimDuration_OneSpecifyTime    = 15.0;
        _trimMinDuration_TwoSpecifyTime = 12.0;
        _trimMaxDuration_TwoSpecifyTime = 30.0;
        _trimExportVideoType            = TRIMEXPORTVIDEOTYPE_ORIGINAL;
        _presentAnimated            = true;
        _dissmissAnimated           = true;
        _netMaterialTypeURL = @"http://d.56show.com/filemanage2/public/filemanage/file/typeData";
        _mvResourceURL   = @"http://dianbook.17rd.com/api/shortvideo/getmvprop3";
        _musicResourceURL= nil;//@"http://dianbook.17rd.com/api/shortvideo/getbgmusic";
        _cloudMusicResourceURL = nil;
        _newmvResourceURL = nil;
        _newmusicResourceURL = nil;
        _newartist = RDLocalizedString(@"音乐家 Jason Shaw", nil);
        _newartistHomepageTitle = @"@audionautix.com";
        _newartistHomepageUrl = @"https://audionautix.com";
        _newmusicAuthorizationTitle = RDLocalizedString(@"授权证书", nil);
        _newmusicAuthorizationUrl = @"http://d.56show.com/accredit/accredit.jpg";
        _filterResourceURL = nil;
        _subtitleResourceURL = nil;
        _effectResourceURL = nil;
        _specialEffectResourceURL = nil;
        _fontResourceURL = nil;
        _transitionURL  = nil;
        _enableMVEffect  = false;
        _enableDraft = false;
    }
    
    return self;
}
- (id)mutableCopyWithZone:(NSZone *)zone{
    EditConfiguration *copy   = [[[self class] allocWithZone:zone] init];
    //向导设置默认关闭
    copy.enableWizard                           = _enableWizard;
    copy.supportFileType                        = _supportFileType;
    copy.defaultSelectAlbum                     = _defaultSelectAlbum;
    copy.mediaCountLimit                        = _mediaCountLimit;
    copy.mediaMinCount                          = _mediaMinCount;
    copy.enableAlbumCamera                      = _enableAlbumCamera;
    copy.clickAlbumCameraBlackBlock             = _clickAlbumCameraBlackBlock;
    //片段编辑预设
    copy.enableTextTitle                 = _enableTextTitle;
    copy.enableSingleMediaAdjust         = _enableSingleMediaAdjust;
    copy.enableSingleSpecialEffects      = _enableSingleSpecialEffects;
    copy.enableSingleMediaFilter         = _enableSingleMediaFilter;
    copy.enableTrim                      = _enableTrim;
    copy.enableSplit                     = _enableSplit;
    copy.enableEdit                      = _enableEdit;
    copy.enableSpeedcontrol              = _enableSpeedcontrol;
    copy.enableCopy                      = _enableCopy;
    copy.enableSort                      = _enableSort;
    
    copy.enableRotate                      = _enableRotate;
    copy.enableMirror                      = _enableMirror;
    copy.enableFlipUpAndDown                      = _enableFlipUpAndDown;
    copy.enableTransition                      = _enableTransition;
    copy.enableVolume                      = _enableVolume;
    copy.enableAnimation = _enableAnimation;
    copy.enableBeauty = _enableBeauty;
    copy.enableImageDurationControl      = _enableImageDurationControl;
    copy.enableProportion                = _enableProportion ;
    copy.enableReverseVideo              = _enableReverseVideo;
    copy.proportionType                  = _proportionType;
    //编辑导出预设
    copy.enableMV               = _enableMV;
    copy.enableSubtitle         = _enableSubtitle;
    copy.enableAIRecogSubtitle  = _enableAIRecogSubtitle;
    copy.enableEffect           = _enableEffect;
    copy.enableSticker           = _enableSticker;
    copy.enablePicZoom    = _enablePicZoom;
    copy.enableBackgroundEdit    = _enableBackgroundEdit;
    copy.enableFilter           = _enableFilter;
    copy.enableEffectsVideo     = _enableEffectsVideo;
    copy.enableDewatermark      = _enableDewatermark;
    copy.enableWatermark        = _enableWatermark;
    copy.enableMosaic           = _enableMosaic;
    copy.enableDubbing          = _enableDubbing;
    copy.enableMusic            = _enableMusic;
    copy.enableSoundEffect      = _enableSoundEffect;
    copy.enableCollage          = _enableCollage;
    copy.enableCover            = _enableCover;
    copy.enableDoodle           = _enableDoodle;
    copy.enableFragmentedit     = _enableFragmentedit;
    copy.dubbingType                 = _dubbingType;
    copy.mvResourceURL               = _mvResourceURL;
    copy.musicResourceURL            = _musicResourceURL;
    copy.cloudMusicResourceURL       = _cloudMusicResourceURL;
    copy.soundMusicResourceURL       = _soundMusicResourceURL;
    copy.soundMusicTypeResourceURL   = _soundMusicTypeResourceURL;
    copy.enableLocalMusic            = _enableLocalMusic;
    //截取视频预设
    copy.defaultSelectMinOrMax      = _defaultSelectMinOrMax;
    copy.presentAnimated            = _presentAnimated;
    copy.dissmissAnimated           = _dissmissAnimated;
    copy.defaultSelectMinOrMax          = _defaultSelectMinOrMax;
    copy.trimDuration_OneSpecifyTime    = _trimDuration_OneSpecifyTime;
    copy.trimMinDuration_TwoSpecifyTime = _trimMinDuration_TwoSpecifyTime;
    copy.trimMaxDuration_TwoSpecifyTime = _trimMaxDuration_TwoSpecifyTime;
    copy.trimExportVideoType            = _trimExportVideoType;
    copy.newmvResourceURL               = _newmvResourceURL;
    copy.newmusicResourceURL            = _newmusicResourceURL;
    copy.newartist                      = _newartist;
    copy.newartistHomepageTitle         = _newartistHomepageTitle;
    copy.newartistHomepageUrl           = _newartistHomepageUrl;
    copy.newmusicAuthorizationTitle     = _newmusicAuthorizationTitle;
    copy.newmusicAuthorizationUrl       = _newmusicAuthorizationUrl;
    copy.filterResourceURL              = _filterResourceURL;
    copy.subtitleResourceURL            = _subtitleResourceURL;
    copy.effectResourceURL              = _effectResourceURL;
    copy.specialEffectResourceURL       = _specialEffectResourceURL;
    copy.fontResourceURL                = _fontResourceURL;
    copy.transitionURL                  = _transitionURL;
    copy.enableMVEffect                 = _enableMVEffect;
    
    return copy;
}

- (id)copyWithZone:(NSZone *)zone{
    EditConfiguration *copy   = [[[self class] allocWithZone:zone] init];
    //向导设置默认关闭
    copy.enableWizard                           = _enableWizard;
    copy.supportFileType                        = _supportFileType;
    copy.defaultSelectAlbum                     = _defaultSelectAlbum;
    copy.mediaCountLimit                         = _mediaCountLimit;
    copy.mediaMinCount                          = _mediaMinCount;
    copy.enableAlbumCamera                      = _enableAlbumCamera;
    copy.clickAlbumCameraBlackBlock             = _clickAlbumCameraBlackBlock;
    //片段编辑预设
    copy.enableTextTitle                 = _enableTextTitle;
    copy.enableSingleMediaAdjust         = _enableSingleMediaAdjust;
    copy.enableSingleSpecialEffects      = _enableSingleSpecialEffects;
    copy.enableSingleMediaFilter         = _enableSingleMediaFilter;
    copy.enableTrim                      = _enableTrim;
    copy.enableSplit                     = _enableSplit;
    copy.enableEdit                      = _enableEdit;
    copy.enableRotate                      = _enableRotate;
    copy.enableMirror                      = _enableMirror;
    copy.enableFlipUpAndDown                      = _enableFlipUpAndDown;
    copy.enableTransition                      = _enableTransition;
    copy.enableVolume                      = _enableVolume;
    copy.enableSpeedcontrol              = _enableSpeedcontrol;
    copy.enableCopy                      = _enableCopy;
    copy.enableSort                      = _enableSort;
    copy.enableImageDurationControl      = _enableImageDurationControl;
    copy.enableProportion                = _enableProportion ;
    copy.proportionType                  = _proportionType;
    copy.enableReverseVideo              = _enableReverseVideo;
    copy.enableAnimation = _enableAnimation;
    copy.enableBeauty = _enableBeauty;
    //编辑导出预设
    copy.enableMV   = _enableMV;
    copy.enableSubtitle  = _enableSubtitle;
    copy.enableAIRecogSubtitle  = _enableAIRecogSubtitle;
    copy.enableEffect    = _enableEffect;
    copy.enableSticker   = _enableSticker;
    copy.enablePicZoom    = _enablePicZoom;
    copy.enableBackgroundEdit    = _enableBackgroundEdit;    
    copy.enableEffectsVideo     = _enableEffectsVideo;
    copy.enableDewatermark      = _enableDewatermark;
    copy.enableWatermark        = _enableWatermark;
    copy.enableMosaic           = _enableMosaic;
    copy.enableFilter    = _enableFilter;
    copy.enableDubbing   = _enableDubbing;
    copy.enableMusic     = _enableMusic;
    copy.enableSoundEffect           = _enableSoundEffect;
    copy.enableCollage               = _enableCollage;
    copy.enableCover            = _enableCover;
    copy.enableDoodle           = _enableDoodle;
    copy.enableFragmentedit          = _enableFragmentedit;
    copy.dubbingType                 = _dubbingType;
    copy.mvResourceURL               = _mvResourceURL;
    copy.musicResourceURL            = _musicResourceURL;
    copy.cloudMusicResourceURL       = _cloudMusicResourceURL;
    copy.soundMusicResourceURL       = _soundMusicResourceURL;
    copy.soundMusicTypeResourceURL   = _soundMusicTypeResourceURL;
    copy.enableLocalMusic            = _enableLocalMusic;
    //截取视频预设
    copy.defaultSelectMinOrMax      = _defaultSelectMinOrMax;
    copy.presentAnimated            = _presentAnimated;
    copy.dissmissAnimated           = _dissmissAnimated;
    copy.defaultSelectMinOrMax          = _defaultSelectMinOrMax;
    copy.trimDuration_OneSpecifyTime    = _trimDuration_OneSpecifyTime;
    copy.trimMinDuration_TwoSpecifyTime = _trimMinDuration_TwoSpecifyTime;
    copy.trimMaxDuration_TwoSpecifyTime = _trimMaxDuration_TwoSpecifyTime;
    copy.trimExportVideoType            = _trimExportVideoType;
    copy.newmvResourceURL               = _newmvResourceURL;
    copy.newmusicResourceURL            = _newmusicResourceURL;
    copy.newartist                      = _newartist;
    copy.newartistHomepageTitle         = _newartistHomepageTitle;
    copy.newartistHomepageUrl           = _newartistHomepageUrl;
    copy.newmusicAuthorizationTitle     = _newmusicAuthorizationTitle;
    copy.newmusicAuthorizationUrl       = _newmusicAuthorizationUrl;
    copy.filterResourceURL              = _filterResourceURL;
    copy.subtitleResourceURL            = _subtitleResourceURL;
    copy.effectResourceURL              = _effectResourceURL;
    copy.specialEffectResourceURL       = _specialEffectResourceURL;
    copy.fontResourceURL                = _fontResourceURL;
    copy.transitionURL                  = _transitionURL;
    copy.enableMVEffect                 = _enableMVEffect;
    
    return copy;
}

- (void)setEnableEffect:(bool)enableEffect {
    _enableSticker = enableEffect;
}

@end

@implementation RDFaceUBeautyParams

- (instancetype)init{
    if(self = [super init]){
        _cheekThinning                      = 0.68;
        _eyeEnlarging                       = 0.5;
        _colorLevel                         = 0.48;
        _blurLevel                          = 3.0;
        _faceShapeLevel                     = 1.0;
    }
    return self;
}
- (id)copyWithZone:(NSZone *)zone{
    RDFaceUBeautyParams *copy   = [[[self class] allocWithZone:zone] init];
    copy.cheekThinning                      = _cheekThinning;
    copy.eyeEnlarging                       = _eyeEnlarging;
    copy.colorLevel                         = _colorLevel;
    copy.blurLevel                          = _blurLevel;
    copy.faceShapeLevel                     = _faceShapeLevel;
    copy.faceShape                          = _faceShape;
    
    return copy;
}

@end

@implementation CameraConfiguration

- (instancetype)init{
    if(self = [super init]){
        _captureAsYUV                       = true;
        _cameraCaptureDevicePosition        = AVCaptureDevicePositionFront;
        _cameraRecordSizeType               = RecordVideoTypeMixed;
        _cameraMV                           = true;
        _cameraVideo                        = true;
        _cameraPhoto                        = true;
        _cameraRecord_Type                  = RecordType_Video;
        _cameraRecordOrientation            = RecordVideoOrientationAuto;
        _cameraSquare_MaxVideoDuration      = 10.0;
        _cameraNotSquare_MaxVideoDuration   = 0.0;
        _cameraMV_MinVideoDuration          = 3;
        _cameraMV_MaxVideoDuration          = 15;
        _repeatRecordDuration               = 2.0;
        _cameraOutputSize                   = CGSizeZero;
        _cameraFrameRate                    = 30.0;
        _cameraBitRate                      = 4.0 * 1000 * 1000;
        _cameraCollocationPosition          = CameraCollocationPositionBottom;
        _cameraOutputPath                   = @"";
        _cameraModelType                    = CameraModel_Onlyone;
        _cameraWriteToAlbum                 = false;
        _enableFaceU                        = false;
        _faceUURL = @"http://dianbook.17rd.com/api/shortvideo/getfaceprop2";
        _enableNetFaceUnity                 = false;
        _enableFilter                       = true;
        _enableUseMusic                     = false;
        _musicInfo                          = nil;
        _faceUBeautyParams                  = [[RDFaceUBeautyParams alloc] init];
        _enabelCameraWaterMark              = NO;
        _cameraWaterMarkHeaderDuration      = 0;
        _cameraWaterMarkEndDuration         = 0;
        
    }
    
    return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone{
    CameraConfiguration *copy   = [[[self class] allocWithZone:zone] init];
    copy.captureAsYUV                       = _captureAsYUV;
    copy.cameraCaptureDevicePosition        = _cameraCaptureDevicePosition;
    copy.cameraRecordSizeType               = _cameraRecordSizeType;
    copy.cameraRecord_Type                  = _cameraRecord_Type;
    copy.cameraRecordOrientation            = _cameraRecordOrientation;
    copy.cameraSquare_MaxVideoDuration      = _cameraSquare_MaxVideoDuration;
    copy.cameraNotSquare_MaxVideoDuration   = _cameraNotSquare_MaxVideoDuration;
    copy.cameraMinVideoDuration             = _cameraMinVideoDuration;
    copy.cameraOutputSize                   = _cameraOutputSize;
    copy.cameraFrameRate                    = _cameraFrameRate;
    copy.cameraBitRate                      = _cameraBitRate;
    copy.cameraCollocationPosition          = _cameraCollocationPosition;
    copy.cameraOutputPath                   = _cameraOutputPath;
    copy.cameraModelType                    = _cameraModelType;
    copy.cameraWriteToAlbum                 = _cameraWriteToAlbum;
    copy.enableFaceU                        = _enableFaceU;
    copy.faceUURL                           = _faceUURL;
    copy.enableNetFaceUnity                 = _enableNetFaceUnity;
    copy.hiddenPhotoLib                     = _hiddenPhotoLib;
    copy.enableFilter                       = _enableFilter;
    copy.enableUseMusic                     = _enableUseMusic;
    copy.musicInfo                          = _musicInfo;
    copy.faceUBeautyParams                  = [_faceUBeautyParams copy];
    copy.cameraEnterPhotoAlbumCallblackBlock= _cameraEnterPhotoAlbumCallblackBlock;
    copy.cameraMV                           = _cameraMV;
    copy.cameraVideo                        = _cameraVideo;
    copy.cameraPhoto                        = _cameraPhoto;
    copy.cameraMV_MinVideoDuration          = _cameraMV_MinVideoDuration;
    copy.cameraMV_MaxVideoDuration          = _cameraMV_MaxVideoDuration;
//    /*传入相机水印图片
//     */
//    @property (nonatomic, strong) UIImage          * cameraWaterMarkHeader;
//    /*传入相机水印图片
//     */
//    @property (nonatomic, strong) UIImage          * cameraWaterMarkBody;
//    /*传入相机水印图片
//     */
//    @property (nonatomic, strong) UIImage          * cameraWaterMarkEnd;
//    copy.cameraWaterMarkEnd                  = _cameraWaterMarkEnd;
//    copy.cameraWaterMarkHeader                  = _cameraWaterMarkHeader;
//    copy.cameraWaterMarkBody                    = _cameraWaterMarkBody;
    copy.enabelCameraWaterMark                  = _enabelCameraWaterMark;
    copy.cameraWaterMarkHeaderDuration          = _cameraWaterMarkHeaderDuration;
    copy.cameraWaterMarkEndDuration          = _cameraWaterMarkEndDuration;
    copy.cameraWaterProcessingCompletionBlock   = _cameraWaterProcessingCompletionBlock;
    return copy;
}

- (id)copyWithZone:(NSZone *)zone{
    CameraConfiguration *copy   = [[[self class] allocWithZone:zone] init];
    copy.captureAsYUV                       = _captureAsYUV;
    copy.cameraCaptureDevicePosition        = _cameraCaptureDevicePosition;
    copy.cameraRecordSizeType               = _cameraRecordSizeType;
    copy.cameraRecord_Type                  = _cameraRecord_Type;
    copy.cameraRecordOrientation            = _cameraRecordOrientation;
    copy.cameraSquare_MaxVideoDuration      = _cameraSquare_MaxVideoDuration;
    copy.cameraNotSquare_MaxVideoDuration   = _cameraNotSquare_MaxVideoDuration;
    copy.cameraMinVideoDuration             = _cameraMinVideoDuration;
    copy.cameraOutputSize                   = _cameraOutputSize;
    copy.cameraFrameRate                    = _cameraFrameRate;
    copy.cameraBitRate                      = _cameraBitRate;
    copy.cameraCollocationPosition          = _cameraCollocationPosition;
    copy.cameraOutputPath                   = _cameraOutputPath;
    copy.cameraModelType                    = _cameraModelType;
    copy.cameraWriteToAlbum                 = _cameraWriteToAlbum;
    copy.enableFaceU                        = _enableFaceU;
    copy.faceUURL                           = _faceUURL;
    copy.enableNetFaceUnity                 = _enableNetFaceUnity;
    copy.cameraEnterPhotoAlbumCallblackBlock= _cameraEnterPhotoAlbumCallblackBlock;
    copy.hiddenPhotoLib                     = _hiddenPhotoLib;
    copy.enableFilter                       = _enableFilter;
    copy.enableUseMusic                    = _enableUseMusic;
    copy.musicInfo                          = _musicInfo;
    copy.faceUBeautyParams                  = [_faceUBeautyParams copy];    
    copy.cameraMV                           = _cameraMV;
    copy.cameraVideo                        = _cameraVideo;
    copy.cameraPhoto                        = _cameraPhoto;
    copy.cameraMV_MinVideoDuration          = _cameraMV_MinVideoDuration;
    copy.cameraMV_MaxVideoDuration          = _cameraMV_MaxVideoDuration;
    
//    copy.cameraWaterMarkEnd                  = _cameraWaterMarkEnd;
//    copy.cameraWaterMarkHeader                  = _cameraWaterMarkHeader;
//    copy.cameraWaterMarkBody                    = _cameraWaterMarkBody;
    copy.enabelCameraWaterMark                  = _enabelCameraWaterMark;
    copy.cameraWaterMarkHeaderDuration          = _cameraWaterMarkHeaderDuration;
    copy.cameraWaterMarkEndDuration          = _cameraWaterMarkEndDuration;
    copy.cameraWaterProcessingCompletionBlock   = _cameraWaterProcessingCompletionBlock;
    
    return copy;
}

@end
