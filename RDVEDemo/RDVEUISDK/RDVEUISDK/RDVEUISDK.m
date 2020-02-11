//
//  RDVEUISDK.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2017/7/15.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDVEUISDK.h"
#import "RDRecordViewController.h"
#import "RDEditVideoViewController.h"
#import "RDNextEditVideoViewController.h"
#import "RDTrimVideoViewController.h"
#import "RDMainViewController.h"
#import "RDCloudMusicViewController.h"
#import "RDLocalMusicViewController.h"
#import "RD_RDReachabilityLexiu.h"
#import "RDStoryRecordViewController.h"
#import "RDDyRecordViewController.h"
#import "PictureMovieViewController.h"
#import "AudioFilterViewController.h"
#import "ShapedAssetViewController.h"
#import "AETemplateMovieViewController.h"
#import "AEHomeViewController.h"
#import "RDDraftViewController.h"
#import "QuikViewController.h"
#import "RDDraftManager.h"
#import "RDTextAnimateViewController.h"
#import "CropViewController.h"
#import "RDCustomDrawViewController.h"
#import "RDMultiDifferentViewController.h"
#import "RDCompressViewController.h"
#import "RDReverseViewController.h"
#import "RDTransitionViewController.h"
#import "RDAdjustViewController.h"
#import "ChangeSpeedVideoViewController.h"
#import "RDVoiceFXViewController.h"
#import "RDDubViewController.h"
#import "RDCoverViewController.h"

#import "RDSpecialEffectsViewController.h"
#import "RDFilterViewController.h"
#import "RDSubtitleViewController.h"
#import "RDStickerViewController.h"
#import "RDDewatermarkViewController.h"
#import "RDDoodleViewController.h"
#import "RDCollageViewController.h"

//导出音频
#import "RDExtractAudioViewController.h"
#import "RDCompressVideoViewController.h"

#import "RDTextToSpeechViewController.h"

@interface RDVEUISDK()<RDRecordViewDelegate> {

    PhotoPathCancelBlock _photoPathCancelBlock;
    ChangeFaceCancelBlock _changeFaceCancelBlock;
    AddFinishCancelBlock _addFinishCancelBlock;
    
    SuccessCancelBlock  _successCancelBlock;
    FailCancelBlock     _failCancelBlock;
    
    
}

@property (strong,nonatomic)RDTrimVideoViewController   *trimVideoVC;
@property (copy,nonatomic)NSString                      *appkey;
@property (copy,nonatomic)NSString                      *licenceKey;
@property (copy,nonatomic)NSString                      *appsecret;
@property (strong,nonatomic)RDVECore *compressVECore;
@property (copy,nonatomic)NSString                      *outPath;
@property (assign,nonatomic)float                        videoAverageBitRate;

/** 界面主颜色，默认为黄色
 */
@property (nonatomic,strong) UIColor *mainColor;

@end

@implementation RDVEUISDK

- (void)setLanguage:(SUPPORTLANGUAGE)language {
    _language = language;
    switch (language) {
        case CHINESE:
            [[NSUserDefaults standardUserDefaults] setObject:@"zh-Hans" forKey:kRDLanguage];
            break;
            
        case ENGLISH:
            [[NSUserDefaults standardUserDefaults] setObject:@"en" forKey:kRDLanguage];
            break;
            
        default:
            break;
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark- 片段编辑
- (void)setEditConfiguration:(EditConfiguration *)editConfiguration{
    //向导设置默认关闭
    _editConfiguration.enableWizard                           = editConfiguration.enableWizard;
    _editConfiguration.supportFileType                        = editConfiguration.supportFileType;
    _editConfiguration.defaultSelectAlbum                     = editConfiguration.defaultSelectAlbum;
    _editConfiguration.mediaCountLimit                        = editConfiguration.mediaCountLimit;
    _editConfiguration.mediaMinCount                          = editConfiguration.mediaMinCount;
    _editConfiguration.enableAlbumCamera                      = editConfiguration.enableAlbumCamera;
    _editConfiguration.clickAlbumCameraBlackBlock             = [editConfiguration.clickAlbumCameraBlackBlock copy];
    //片段编辑预设
    _editConfiguration.enableTextTitle                 = editConfiguration.enableTextTitle;
    _editConfiguration.enableSingleMediaAdjust         = editConfiguration.enableSingleMediaAdjust;
    _editConfiguration.enableSingleSpecialEffects      = editConfiguration.enableSingleSpecialEffects;
    _editConfiguration.enableSingleMediaFilter         = editConfiguration.enableSingleMediaFilter;
    _editConfiguration.enableTrim                      = editConfiguration.enableTrim;
    _editConfiguration.enableReplace    = editConfiguration.enableReplace;
    _editConfiguration.enableTransparency = editConfiguration.enableTransparency;
    _editConfiguration.enableSplit                     = editConfiguration.enableSplit;
    _editConfiguration.enableEdit                      = editConfiguration.enableEdit;
    _editConfiguration.enableCollage                   = editConfiguration.enableCollage;
    _editConfiguration.enableSpeedcontrol              = editConfiguration.enableSpeedcontrol;
    _editConfiguration.enableCopy                      = editConfiguration.enableCopy;
    _editConfiguration.enableSort                      = editConfiguration.enableSort;
    _editConfiguration.enableTransition                = editConfiguration.enableTransition;
    _editConfiguration.enableImageDurationControl      = editConfiguration.enableImageDurationControl;
    _editConfiguration.enableProportion                = editConfiguration.enableProportion ;
    _editConfiguration.enableReverseVideo              = editConfiguration.enableReverseVideo;
    _editConfiguration.proportionType                  = editConfiguration.proportionType;
    _editConfiguration.enableRotate                      = editConfiguration.enableRotate;
    _editConfiguration.enableMirror                      = editConfiguration.enableMirror;
    _editConfiguration.enableFlipUpAndDown                      = editConfiguration.enableFlipUpAndDown;
    _editConfiguration.enableVolume                      = editConfiguration.enableVolume;
    _editConfiguration.enableAnimation = editConfiguration.enableAnimation;
    
    _editConfiguration.enableBeauty = editConfiguration.enableBeauty;
    //编辑导出预设
    _editConfiguration.enableMV                 = editConfiguration.enableMV;
    _editConfiguration.enableEffectsVideo       = editConfiguration.enableEffectsVideo;
    _editConfiguration.enableDewatermark        = editConfiguration.enableDewatermark;
    _editConfiguration.enableSubtitle           = editConfiguration.enableSubtitle;
    _editConfiguration.enableAIRecogSubtitle    = editConfiguration.enableAIRecogSubtitle;
    _editConfiguration.enableEffect             = editConfiguration.enableEffect;
    _editConfiguration.enableSticker            = editConfiguration.enableSticker;
    _editConfiguration.enableFilter             = editConfiguration.enableFilter;
    _editConfiguration.enableDubbing            = editConfiguration.enableDubbing;
    _editConfiguration.enableMusic              = editConfiguration.enableMusic;
    _editConfiguration.enableSoundEffect        = editConfiguration.enableSoundEffect;
    _editConfiguration.enableLocalMusic         = editConfiguration.enableLocalMusic;
    _editConfiguration.enableFragmentedit       = editConfiguration.enableFragmentedit;
    _editConfiguration.enableBackgroundEdit     = editConfiguration.enableBackgroundEdit;
    _editConfiguration.enablePicZoom            = editConfiguration.enablePicZoom;
    _editConfiguration.enableCover              = editConfiguration.enableCover;
    _editConfiguration.enableDoodle             = editConfiguration.enableDoodle;
    _editConfiguration.dubbingType                 = editConfiguration.dubbingType;
    _editConfiguration.mvResourceURL               = [editConfiguration.mvResourceURL copy];
    _editConfiguration.musicResourceURL            = [editConfiguration.musicResourceURL copy];
    _editConfiguration.cloudMusicResourceURL       = [editConfiguration.cloudMusicResourceURL copy];
    _editConfiguration.soundMusicResourceURL       = [editConfiguration.soundMusicResourceURL copy];
    _editConfiguration.soundMusicTypeResourceURL   = [editConfiguration.soundMusicTypeResourceURL copy];
    //截取视频预设
    _editConfiguration.defaultSelectMinOrMax      = editConfiguration.defaultSelectMinOrMax;
    _editConfiguration.presentAnimated            = editConfiguration.presentAnimated;
    _editConfiguration.dissmissAnimated           = editConfiguration.dissmissAnimated;
    _editConfiguration.defaultSelectMinOrMax          = editConfiguration.defaultSelectMinOrMax;
    _editConfiguration.trimDuration_OneSpecifyTime    = editConfiguration.trimDuration_OneSpecifyTime;
    _editConfiguration.trimMinDuration_TwoSpecifyTime = editConfiguration.trimMinDuration_TwoSpecifyTime;
    _editConfiguration.trimMaxDuration_TwoSpecifyTime = editConfiguration.trimMaxDuration_TwoSpecifyTime;
    _editConfiguration.trimExportVideoType            = editConfiguration.trimExportVideoType;
}

- (void)setExportConfiguration:(ExportConfiguration *)exportConfiguration{
    
    _exportConfiguration.outputVideoMaxDuration   = exportConfiguration.outputVideoMaxDuration;
    _exportConfiguration.inputVideoMaxDuration   = exportConfiguration.inputVideoMaxDuration;

    //设置视频片尾和码率
    _exportConfiguration.endPicDisabled     = exportConfiguration.endPicDisabled;
    _exportConfiguration.endPicUserName     = exportConfiguration.endPicUserName;
    _exportConfiguration.endPicDuration     = exportConfiguration.endPicDuration;
    _exportConfiguration.endPicFadeDuration = exportConfiguration.endPicFadeDuration;
    _exportConfiguration.endPicImagepath    = exportConfiguration.endPicImagepath;
    _exportConfiguration.videoBitRate       = exportConfiguration.videoBitRate;
    //设置水印是否可用
    _exportConfiguration.waterDisabled      = exportConfiguration.waterDisabled;
    _exportConfiguration.waterText          = exportConfiguration.waterText;
    _exportConfiguration.waterImage         = exportConfiguration.waterImage;
    _exportConfiguration.waterPosition      = exportConfiguration.waterPosition;
}

- (void)setCameraConfiguration:(CameraConfiguration *)cameraConfiguration{
    
    _cameraConfiguration.cameraCaptureDevicePosition        = cameraConfiguration.cameraCaptureDevicePosition;
    _cameraConfiguration.cameraRecordSizeType               = cameraConfiguration.cameraRecordSizeType;
    _cameraConfiguration.cameraRecord_Type                  = cameraConfiguration.cameraRecord_Type;
    _cameraConfiguration.cameraRecordOrientation            = cameraConfiguration.cameraRecordOrientation;
    _cameraConfiguration.cameraSquare_MaxVideoDuration      = cameraConfiguration.cameraSquare_MaxVideoDuration;
    _cameraConfiguration.cameraNotSquare_MaxVideoDuration   = cameraConfiguration.cameraNotSquare_MaxVideoDuration;
    _cameraConfiguration.cameraMinVideoDuration             = cameraConfiguration.cameraMinVideoDuration;
    _cameraConfiguration.cameraOutputSize                   = cameraConfiguration.cameraOutputSize;
    _cameraConfiguration.cameraFrameRate                    = cameraConfiguration.cameraFrameRate;
    _cameraConfiguration.cameraBitRate                      = cameraConfiguration.cameraBitRate;
    _cameraConfiguration.cameraCollocationPosition          = cameraConfiguration.cameraCollocationPosition;
    _cameraConfiguration.cameraOutputPath                   = cameraConfiguration.cameraOutputPath;
    _cameraConfiguration.cameraModelType                    = cameraConfiguration.cameraModelType;
    _cameraConfiguration.cameraWriteToAlbum                 = cameraConfiguration.cameraWriteToAlbum;
    _cameraConfiguration.enableFaceU                        = cameraConfiguration.enableFaceU;
    _cameraConfiguration.faceUURL                           = cameraConfiguration.faceUURL;
    _cameraConfiguration.enableNetFaceUnity                 = cameraConfiguration.enableNetFaceUnity;
    _cameraConfiguration.cameraEnterPhotoAlbumCallblackBlock= cameraConfiguration.cameraEnterPhotoAlbumCallblackBlock;
    _cameraConfiguration.hiddenPhotoLib                     = cameraConfiguration.hiddenPhotoLib;
    _cameraConfiguration.faceUBeautyParams                  = cameraConfiguration.faceUBeautyParams;
    _cameraConfiguration.cameraMV                           = cameraConfiguration.cameraMV;
    _cameraConfiguration.cameraVideo                        = cameraConfiguration.cameraVideo;
    _cameraConfiguration.cameraPhoto                        = cameraConfiguration.cameraPhoto;
    _cameraConfiguration.cameraMV_MinVideoDuration          = cameraConfiguration.cameraMV_MinVideoDuration;
    _cameraConfiguration.cameraMV_MaxVideoDuration          = cameraConfiguration.cameraMV_MaxVideoDuration;
    
    _cameraConfiguration.enableUseMusic                    = cameraConfiguration.enableUseMusic;
    _cameraConfiguration.musicInfo                          = cameraConfiguration.musicInfo;
    
    _cameraConfiguration.enableFilter                       = cameraConfiguration.enableFilter;
    _cameraConfiguration.enabelCameraWaterMark              = cameraConfiguration.enabelCameraWaterMark;
    _cameraConfiguration.cameraWaterMarkHeaderDuration      = cameraConfiguration.cameraWaterMarkHeaderDuration;
    _cameraConfiguration.cameraWaterMarkEndDuration         = cameraConfiguration.cameraWaterMarkEndDuration;
}

- (id)mutableCopyWithZone:(NSZone *)zone{
    RDVEUISDK *copy = [[self class] allocWithZone:zone];
    
    copy.delegate               = _delegate;
    copy.exportConfiguration    = [_exportConfiguration copy];
    copy.editConfiguration      = [_editConfiguration copy];
    copy.cameraConfiguration    = [_cameraConfiguration copy];
    copy.addVideosAndImagesCallbackBlock = [_addVideosCallbackBlock copy];
    copy.addVideosCallbackBlock = [_addVideosCallbackBlock copy];
    copy.addImagesCallbackBlock = [_addImagesCallbackBlock copy];
    copy.recordSizeType         = _recordSizeType;
    copy.recordOrientation      = _recordOrientation;
    copy.deviceOrientation      = _deviceOrientation;
    copy.orientationLock        = _orientationLock;
    copy.rd_CutVideoReturnType  = _rd_CutVideoReturnType;
    
    
//    copy.endWaterPicDisabled    = _endWaterPicDisabled;
//    copy.endWaterPicUserName    = _endWaterPicUserName;
//    if(_editConfiguration.trimMode == TRIMMODESPECIFYTIME_ONE){
//        copy.minDuration            = _editConfiguration.trimDuration_OneSpecifyTime;
//        copy.maxDuration            = _editConfiguration.trimDuration_OneSpecifyTime;
//        
//    }else if(_editConfiguration.trimMode == TRIMMODESPECIFYTIME_TWO){
//        copy.minDuration            = _editConfiguration.trimMinDuration_TwoSpecifyTime;
//        copy.maxDuration            = _editConfiguration.trimMaxDuration_TwoSpecifyTime;
//    }else{
//        copy.minDuration            = _minDuration;
//        copy.maxDuration            = _maxDuration;
//    }
//    
//    copy.defaultSelectMinOrMax  = _defaultSelectMinOrMax; //default kRDCutSelectDefaultMin
    
    copy.trimVideoVC    = _trimVideoVC;
    copy.appkey         = _appkey;
    copy.licenceKey     = _licenceKey;
    copy.appsecret      = _appsecret;
    copy.outPath        = _outPath;
    copy.videoAverageBitRate = _videoAverageBitRate;
    return copy;
}

- (id)copyWithZone:(NSZone *)zone{
    RDVEUISDK *copy = [[self class] allocWithZone:zone];
    
    copy.delegate               = _delegate;
    copy.exportConfiguration    = [_exportConfiguration copy];
    copy.editConfiguration      = [_editConfiguration copy];
    copy.cameraConfiguration    = [_cameraConfiguration copy];
    copy.addVideosAndImagesCallbackBlock = [_addVideosCallbackBlock copy];
    copy.addVideosCallbackBlock = [_addVideosCallbackBlock copy];
    copy.addImagesCallbackBlock = [_addImagesCallbackBlock copy];
    copy.recordSizeType         = _recordSizeType;
    copy.recordOrientation      = _recordOrientation;
    copy.deviceOrientation      = _deviceOrientation;
    copy.orientationLock        = _orientationLock;
    copy.rd_CutVideoReturnType  = _rd_CutVideoReturnType;
    
//    copy.endWaterPicDisabled    = _endWaterPicDisabled;
//    copy.endWaterPicUserName    = _endWaterPicUserName;
//    if(_editConfiguration.trimMode == TRIMMODESPECIFYTIME_ONE){
//        copy.minDuration            = _editConfiguration.trimDuration_OneSpecifyTime;
//        copy.maxDuration            = _editConfiguration.trimDuration_OneSpecifyTime;
//        
//    }else if(_editConfiguration.trimMode == TRIMMODESPECIFYTIME_TWO){
//        copy.minDuration            = _editConfiguration.trimMinDuration_TwoSpecifyTime;
//        copy.maxDuration            = _editConfiguration.trimMaxDuration_TwoSpecifyTime;
//    }else{
//        copy.minDuration            = _minDuration;
//        copy.maxDuration            = _maxDuration;
//    }
//    copy.defaultSelectMinOrMax  = _defaultSelectMinOrMax; //default kRDCutSelectDefaultMin
    
    copy.trimVideoVC    = _trimVideoVC;
    copy.appkey         = _appkey;
    copy.licenceKey     = _licenceKey;
    copy.appsecret      = _appsecret;
    copy.outPath        = _outPath;
    copy.videoAverageBitRate = _videoAverageBitRate;
    return copy;
}

/*
 截取界面设置
 */

- (void)setMaxDuration:(float)maxDuration{
    _editConfiguration.trimMaxDuration_TwoSpecifyTime = maxDuration;
}

- (void)setMinDuration:(float)minDuration{
    _editConfiguration.trimMinDuration_TwoSpecifyTime = minDuration;
}

- (void)setDefaultSelectMinOrMax:(RDdefaultSelectCutMinOrMax)defaultSelectMinOrMax{
    _editConfiguration.defaultSelectMinOrMax = defaultSelectMinOrMax;
}
//---------
/*
 录制界面设置
 */

- (void)setRecordSizeType:(RecordVideoSizeType)recordSizeType{
    _cameraConfiguration.cameraRecordSizeType = recordSizeType;
}

- (void)setRecordOrientation:(RecordVideoOrientation)recordOrientation{
    _cameraConfiguration.cameraRecordOrientation =  recordOrientation;
}

//-------

/*
 导出设置
 */

- (void)setEndWaterPicDisabled:(BOOL)endWaterPicDisabled{
    if(endWaterPicDisabled){
        _exportConfiguration.endPicDisabled = true;
    }else{
        _exportConfiguration.endPicDisabled = false;
    }
}

- (void)setEndWaterPicUserName:(NSString *)endWaterPicUserName{
    _exportConfiguration.endPicUserName = endWaterPicUserName;
}

/**
 *  设置视频输出码率
 *
 *  @param videoAverageBitRate  码率单位（M）
 */

- (void)setOutPutVideoAverageBitRate:(float)videoAverageBitRate
{
    _exportConfiguration.videoBitRate = videoAverageBitRate;
}

/**
 *  添加文字水印
 *
 *  @param waterString 文字内容
 *  @param waterRect   水印在视频中的位置
 */
-(void)addTextWater:(NSString *)waterString waterRect:(CGRect)waterRect{
    _exportConfiguration.waterDisabled = false;
    _exportConfiguration.waterText = waterString;
    _exportConfiguration.waterImage = nil;
}

/**
 *  添加图片水印
 *
 *  @param waterImage 水印图片
 *  @param waterRect  水印在视频中的位置
 */
-(void)addImageWater:(UIImage *)waterImage waterRect:(CGRect)waterRect{
    _exportConfiguration.waterDisabled = false;
    _exportConfiguration.waterImage = waterImage;
    _exportConfiguration.waterText = nil;
}
- (instancetype)initWithAPPKey:(NSString *)appkey
                     APPSecret:(NSString *)appsecret
                    resultFail:(RdVEFailBlock)resultFailBlock{
    return [self initWithAPPKey:appkey APPSecret:appsecret LicenceKey:@"" resultFail:resultFailBlock];
}
- (instancetype)initWithAPPKey:(NSString *)appkey
                     APPSecret:(NSString *)appsecret
                    LicenceKey:(NSString *)licenceKey
                    resultFail:(RdVEFailBlock)resultFailBlock{
    self = [super init];
    if (self) {
        
        //清除临时缓存
        NSString *path = NSTemporaryDirectory();
        NSString *folderPath = [path stringByAppendingPathComponent:@"videos"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:folderPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:folderPath error:nil];
        }
        
        _appkey = appkey;
        _licenceKey = licenceKey;
        _appsecret = appsecret;
        _defaultSelectMinOrMax = kRDDefaultSelectCutMin;
        
        _exportConfiguration = [[ExportConfiguration alloc]init];
        
        _editConfiguration = [[EditConfiguration alloc] init];
        
        _cameraConfiguration = [[CameraConfiguration alloc] init];
        
        self.mainColor = UIColorFromRGB(0xffd500);
        
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *error = nil;
        if(![fm fileExistsAtPath:kRDDraftDirectory]){
            [fm createDirectoryAtPath:kRDDraftDirectory withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if ([fm fileExistsAtPath:kMusicFolder_old]) {
            [fm removeItemAtPath:kMusicFolder_old error:nil];
        }
        if ([fm fileExistsAtPath:kThemeMVPath_old]) {
            [fm removeItemAtPath:kThemeMVPath_old error:nil];
        }
        
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(deleteExtraFiles) object:nil];
        [self performSelectorInBackground:@selector(deleteExtraFiles) withObject:nil];
//        NSString *path = [[NSBundle mainBundle] pathForResource:@"微软雅黑Bold" ofType:@"ttf"];
//        NSString *fontName = [RDHelpClass customFontWithPath:path fontName:nil];
//        [RDHelpClass getColor:@"38a6fa"];
    }
    
    return self;
}

//删除多余文件
- (void)deleteExtraFiles {
    dispatch_async(dispatch_get_main_queue(), ^{
        __block NSArray <RDDraftInfo *>*draftList = [[RDDraftManager sharedManager] getALLDraftVideosInfo];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSFileManager *fm = [NSFileManager defaultManager];
            if (draftList.count == 0) {
                if ([fm fileExistsAtPath:kCoverFolder]) {
                    [fm removeItemAtPath:kCoverFolder error:nil];
                }
                if ([fm fileExistsAtPath:kDoodleFolder]) {
                    [fm removeItemAtPath:kDoodleFolder error:nil];
                }
                if ([fm fileExistsAtPath:kCurrentFrameTextureFolder]) {
                    [fm removeItemAtPath:kCurrentFrameTextureFolder error:nil];
                }
            }else {
                NSArray <NSString *>*covers = [fm contentsOfDirectoryAtPath:kCoverFolder error:nil];
                NSArray <NSString *>*doodles = [fm contentsOfDirectoryAtPath:kDoodleFolder error:nil];
                NSArray <NSString *>*currentFrames = [fm contentsOfDirectoryAtPath:kCurrentFrameTextureFolder error:nil];
                [covers enumerateObjectsUsingBlock:^(NSString * _Nonnull file, NSUInteger idx, BOOL * _Nonnull stop) {
                    __block BOOL isDraftFile = NO;
                    [draftList enumerateObjectsUsingBlock:^(RDDraftInfo * _Nonnull draft, NSUInteger idx1, BOOL * _Nonnull stop1) {
                        if ([file.lastPathComponent isEqualToString:draft.coverFile.contentURL.lastPathComponent]) {
                            isDraftFile = YES;
                            *stop1 = YES;
                        }
                    }];
                    if (!isDraftFile) {
                        [fm removeItemAtPath:[kCoverFolder stringByAppendingPathComponent:file] error:nil];
                    }
                }];
                [doodles enumerateObjectsUsingBlock:^(NSString * _Nonnull file, NSUInteger idx, BOOL * _Nonnull stop) {
                    __block BOOL isDraftFile = NO;
                    [draftList enumerateObjectsUsingBlock:^(RDDraftInfo * _Nonnull draft, NSUInteger idx1, BOOL * _Nonnull stop1) {
                        [draft.doodles enumerateObjectsUsingBlock:^(RDCaptionRangeViewFile * _Nonnull rangeViewFile, NSUInteger idx2, BOOL * _Nonnull stop2) {
                            if ([file.lastPathComponent isEqualToString:rangeViewFile.doodle.vvAsset.url.lastPathComponent]) {
                                isDraftFile = YES;
                                *stop2 = YES;
                                *stop1 = YES;
                            }
                        }];
                    }];
                    if (!isDraftFile) {
                        [fm removeItemAtPath:[kDoodleFolder stringByAppendingPathComponent:file] error:nil];
                    }
                }];
                [currentFrames enumerateObjectsUsingBlock:^(NSString * _Nonnull file, NSUInteger idx, BOOL * _Nonnull stop) {
                    __block BOOL isDraftFile = NO;
                    [draftList enumerateObjectsUsingBlock:^(RDDraftInfo * _Nonnull draft, NSUInteger idx1, BOOL * _Nonnull stop1) {
                        [draft.filterArray enumerateObjectsUsingBlock:^(RDDraftEffectFilterItem * _Nonnull filterEffect, NSUInteger idx2, BOOL * _Nonnull stop2) {
                            if ([file.lastPathComponent isEqualToString:filterEffect.currentFrameTexturePath.lastPathComponent]) {
                                isDraftFile = YES;
                                *stop2 = YES;
                                *stop1 = YES;
                            }
                        }];
                    }];
                    if (!isDraftFile) {
                        [fm removeItemAtPath:[kCurrentFrameTextureFolder stringByAppendingPathComponent:file] error:nil];
                    }
                }];
            }
        });
    });
}

- (NSString *)toHexRGB {
    CGColorRef color = _mainColor.CGColor;
    size_t count = CGColorGetNumberOfComponents(color);
    const CGFloat *components = CGColorGetComponents(color);
    
    static NSString *stringFormat = @"%02x%02x%02x";
    
    if (count == 2) {
        // Grayscale
        NSUInteger grey = (NSUInteger)(components[0] * (CGFloat)255);
        return [NSString stringWithFormat:stringFormat, grey, grey, grey];
    }
    else if (count == 4) {
        // RGB
        return [NSString stringWithFormat:stringFormat,
                (NSUInteger)(components[0] * (CGFloat)255),
                (NSUInteger)(components[1] * (CGFloat)255),
                (NSUInteger)(components[2] * (CGFloat)255)];
    }
    
    // Unsupported color space
    return nil;
}

- (void)setMainColor:(UIColor *)mainColor {
    _mainColor = mainColor;
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:_mainColor];
    [[NSUserDefaults standardUserDefaults]setObject:colorData forKey:@"kRDMainColor"];
}

#pragma mark- 打开相册
/**打开相册
 *@param albumType 视频，图片，视频+图片
 */
- (BOOL)onRdVEAlbumWithSuperController:(UIViewController *)viewController
                            albumType:(ALBUMTYPE)albumType
                            callBlock:(OnAlbumCallbackBlock) callbackBlock
                          cancelBlock:(RdVECancelBlock) cancelBlock{
    BOOL suc = [RDHelpClass createSaveTmpFileFolder];
    if(!suc){
        return NO;
    }
    
    [self setCameraConfigurationSetting:nil];
    
    
    RDMainViewController            *mainView;
    mainView                           = [[RDMainViewController alloc] init];
    mainView.editConfig = _editConfiguration;
    mainView.cameraConfig = _cameraConfiguration;
    mainView.exportConfig = _exportConfiguration;
    mainView.needPush                  = YES;
    mainView.minCountLimit = _editConfiguration.mediaMinCount;
    mainView.onAlbumCallbackBlock   = callbackBlock;
    if(_editConfiguration.supportFileType == SUPPORT_ALL){
        if(_editConfiguration.defaultSelectAlbum == RDDEFAULTSELECTALBUM_IMAGE){
            mainView.showPhotos = YES;
        }
    }
    mainView.cancelBlock = ^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            if(cancelBlock){
                cancelBlock();
            }
        });
    };
    
    RDNavigationViewController *nav;
    nav = [[RDNavigationViewController alloc] initWithRootViewController:mainView];
    nav.statusBarHidden        = [UIApplication sharedApplication].statusBarHidden;
    nav.rdVeUiSdkDelegate            = _delegate;
    nav.appKey                 = _appkey;
    nav.licenceKey             = _licenceKey;
    nav.appSecret              = _appsecret;
    nav.videoAverageBitRate        = _exportConfiguration.videoBitRate;
    nav.editConfiguration            = _editConfiguration;
    nav.exportConfiguration          = _exportConfiguration;
    nav.cameraConfiguration          = _cameraConfiguration;
    if(albumType == kONLYALBUMIMAGE){
        nav.editConfiguration.supportFileType  = ONLYSUPPORT_IMAGE;
    }else if(albumType == kONLYALBUMVIDEO){
        nav.editConfiguration.supportFileType  = ONLYSUPPORT_VIDEO;
    }else{
        nav.editConfiguration.supportFileType  = SUPPORT_ALL;
    }
    nav.cameraConfiguration        = _cameraConfiguration;
    
    [self presentViewController:viewController nav:nav];
    
    return YES;
}

- (void)enterAlbumWithSuperController:(UIViewController *)viewController callBlock:(void(^)(NSString *path))callBlock cancelBlock:(void(^)(void))cancelBlock{
    
    BOOL suc = [RDHelpClass createSaveTmpFileFolder];
    if(!suc){
        return;
    }
    
    RDMainViewController            *mainView;
    mainView              = [[RDMainViewController alloc] init];
    mainView.editConfig = _editConfiguration;
    mainView.cameraConfig = _cameraConfiguration;
    mainView.exportConfig = _exportConfiguration;
    mainView.needPush     = YES;
    mainView.rdVECallbackBlock = ^(NSString *path){
        dispatch_async(dispatch_get_main_queue(), ^{
            [viewController dismissViewControllerAnimated:(self->_editConfiguration.dissmissAnimated ? YES : NO) completion:nil];
            callBlock(path);
        });
    };
    if(_editConfiguration.supportFileType == SUPPORT_ALL){
        if(_editConfiguration.defaultSelectAlbum == RDDEFAULTSELECTALBUM_IMAGE){
            mainView.showPhotos = YES;
        }
    }
    RDNavigationViewController *nav;
    nav                        = [[RDNavigationViewController alloc] initWithRootViewController:mainView];
    nav.statusBarHidden        = [UIApplication sharedApplication].statusBarHidden;
    nav.rdVeUiSdkDelegate            = _delegate;
    nav.appKey                 = _appkey;
    nav.licenceKey             = _licenceKey;
    nav.appSecret              = _appsecret;
    nav.folderType             = kFolderNone;
    nav.videoAverageBitRate        = _exportConfiguration.videoBitRate;
    nav.edit_functionLists         = [self getEdit_FuncationLists];
    nav.editConfiguration          = _editConfiguration;
    nav.cameraConfiguration        = _cameraConfiguration;
    nav.exportConfiguration        = _exportConfiguration;
    
    
    nav.cameraConfiguration        = _cameraConfiguration;
    [viewController presentViewController:nav animated:_editConfiguration.presentAnimated completion:nil];
}

#pragma mark- 截取视频
- (void)trimVideoWithSuperController:(UIViewController *)viewController
                     controllerTitle:(NSString *) title
                     backgroundColor:(UIColor  *) backgroundColor
                   cancelButtonTitle:(NSString *) cancelButtonTitle
              cancelButtonTitleColor:(UIColor  *) cancelButtonTitleColor
         cancelButtonBackgroundColor:(UIColor  *) cancelButtonBackgroundColor
                    otherButtonTitle:(NSString *) otherButtonTitle
               otherButtonTitleColor:(UIColor  *) otherButtonTitleColor
          otherButtonBackgroundColor:(UIColor  *) otherButtonBackgroundColor
                            urlAsset:(AVURLAsset *) urlAsset
                          outputPath:(NSString *) outputVideoPath
                       callbackBlock:(RdVE_TrimAssetCallbackBlock) callbackBlock
                            failback:(RdVEFailBlock       ) failback
                              cancel:(RdVECancelBlock     ) cancelBlock{
    if(outputVideoPath.length == 0){
        NSDictionary *userInfo= [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(RDLocalizedString(@"没有视频输出地址", nil), nil),@"message", nil];
        NSError *error = [NSError errorWithDomain:RDUISDKCustomErrorDomain code:RDUISDKErrorCode_NillOutputPath userInfo:userInfo];
        failback(error);
        return;
    }
    
    if(!urlAsset){
        NSDictionary *userInfo= [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"没有视频源", nil),@"message", nil];
        NSError *error = [NSError errorWithDomain:RDUISDKCustomErrorDomain code:RDUISDKErrorCode_NillInput userInfo:userInfo];
        failback(error);
        return;
    }
    
    __block RDNavigationViewController *nav;
    RDTrimVideoViewController *trimVideoVC  = [[RDTrimVideoViewController alloc] init];
    trimVideoVC.defaultSelectMinOrMax       = _editConfiguration.defaultSelectMinOrMax;
    trimVideoVC.trimType                    = _editConfiguration.trimMode;
    trimVideoVC.trimDuration_OneSpecifyTime     = _editConfiguration.trimDuration_OneSpecifyTime;
    trimVideoVC.trimMinDuration_TwoSpecifyTime  = _editConfiguration.trimMinDuration_TwoSpecifyTime;
    trimVideoVC.trimMaxDuration_TwoSpecifyTime  = _editConfiguration.trimMaxDuration_TwoSpecifyTime;
    trimVideoVC.cancelButtonTitleColor      = cancelButtonTitleColor;
    trimVideoVC.cancelButtonBackgroundColor = cancelButtonBackgroundColor;
    trimVideoVC.cancelButtonTitle           = cancelButtonTitle;
    trimVideoVC.otherButtonTitleColor       = otherButtonTitleColor;
    trimVideoVC.otherButtonBackgroundColor  = otherButtonBackgroundColor;
    trimVideoVC.otherButtonTitle            = otherButtonTitle;
    trimVideoVC.customTitle                 = title;
    trimVideoVC.customBackgroundColor       = backgroundColor;
    trimVideoVC.trimFile                    = nil;
    trimVideoVC.trimVideoAsset              = urlAsset;
    trimVideoVC.outputFilePath              = outputVideoPath;
    trimVideoVC.editVideoSize               = CGSizeZero;
    trimVideoVC.rd_CutVideoReturnType       = _rd_CutVideoReturnType;
    trimVideoVC.trimExportVideoType         = _editConfiguration.trimExportVideoType;
    _trimVideoVC = trimVideoVC;
    trimVideoVC.trimCallbackBlock = ^(RDCutVideoReturnType cutType,AVURLAsset *asset,CMTime startTime,CMTime endTime,CGRect cropRect){
        dispatch_async(dispatch_get_main_queue(), ^{
            _trimVideoVC = nil;
            callbackBlock(cutType,asset,startTime,endTime,cropRect);
            nav = nil;
        });
    };
    
    trimVideoVC.failback         = ^(NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
            _trimVideoVC = nil;
            failback(error);
            nav = nil;
        });
    };
    
    trimVideoVC.cancelBlock      = ^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            _trimVideoVC = nil;
            cancelBlock();
            nav = nil;
        });
    };

    nav                            = [[RDNavigationViewController alloc] initWithRootViewController:trimVideoVC];
    nav.statusBarHidden            = [UIApplication sharedApplication].statusBarHidden;
    nav.rdVeUiSdkDelegate          = _delegate;
    nav.appKey                     = _appkey;
    nav.licenceKey                 = _licenceKey;
    nav.appSecret                  = _appsecret;
    nav.outPath                    = outputVideoPath;
    
    [self presentViewController:viewController nav:nav];
}

- (void)trimVideoWithSuperController:(UIViewController *)viewController
                     controllerTitle:(NSString *) title
                     backgroundColor:(UIColor  *) backgroundColor
                   cancelButtonTitle:(NSString *) cancelButtonTitle
              cancelButtonTitleColor:(UIColor  *) cancelButtonTitleColor
         cancelButtonBackgroundColor:(UIColor  *) cancelButtonBackgroundColor
                    otherButtonTitle:(NSString *) otherButtonTitle
               otherButtonTitleColor:(UIColor  *) otherButtonTitleColor
          otherButtonBackgroundColor:(UIColor  *) otherButtonBackgroundColor
                           assetPath:(NSString *) assetPath
                          outputPath:(NSString *) outputVideoPath
                       callbackBlock:(RdVE_TrimVideoPathCallbackBlock) callbackBlock
                            failback:(RdVEFailBlock       ) failback
                              cancel:(RdVECancelBlock     ) cancelBlock{
    if(assetPath.length == 0){
        NSDictionary *userInfo= [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"没有视频源", nil),@"message", nil];
        NSError *error = [NSError errorWithDomain:RDUISDKCustomErrorDomain code:RDUISDKErrorCode_NillInput userInfo:userInfo];
        failback(error);
        return;
    }
    
    if(outputVideoPath.length == 0){
        NSDictionary *userInfo= [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"没有视频输出地址", nil),@"message", nil];
        NSError *error = [NSError errorWithDomain:RDUISDKCustomErrorDomain code:RDUISDKErrorCode_NillOutputPath userInfo:userInfo];
        failback(error);
        return;
    }
    
    __block RDNavigationViewController *nav;
    RDTrimVideoViewController *trimVideoVC  = [[RDTrimVideoViewController alloc] init];
    trimVideoVC.defaultSelectMinOrMax       = _editConfiguration.defaultSelectMinOrMax;
    trimVideoVC.trimType                    = _editConfiguration.trimMode;
    trimVideoVC.trimDuration_OneSpecifyTime     = _editConfiguration.trimDuration_OneSpecifyTime;
    trimVideoVC.trimMinDuration_TwoSpecifyTime  = _editConfiguration.trimMinDuration_TwoSpecifyTime;
    trimVideoVC.trimMaxDuration_TwoSpecifyTime  = _editConfiguration.trimMaxDuration_TwoSpecifyTime;
    trimVideoVC.cancelButtonTitleColor      = cancelButtonTitleColor;
    trimVideoVC.cancelButtonBackgroundColor = cancelButtonBackgroundColor;
    trimVideoVC.cancelButtonTitle           = cancelButtonTitle;
    trimVideoVC.otherButtonTitleColor       = otherButtonTitleColor;
    trimVideoVC.otherButtonBackgroundColor  = otherButtonBackgroundColor;
    trimVideoVC.otherButtonTitle            = otherButtonTitle;
    trimVideoVC.customTitle                 = title;
    trimVideoVC.customBackgroundColor       = backgroundColor;
    trimVideoVC.trimFile                    = nil;
    trimVideoVC.trimVideoAsset              = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:assetPath] options:nil];
    trimVideoVC.outputFilePath              = outputVideoPath;
    trimVideoVC.editVideoSize               = CGSizeZero;
    trimVideoVC.rd_CutVideoReturnType       = _rd_CutVideoReturnType;
    trimVideoVC.trimExportVideoType         = _editConfiguration.trimExportVideoType;
    _trimVideoVC = trimVideoVC;
    trimVideoVC.callbackBlock = ^(RDCutVideoReturnType cutType,NSString *videoPath,CMTime startTime,CMTime endTime,CGRect cropRect){
        dispatch_async(dispatch_get_main_queue(), ^{
            _trimVideoVC = nil;
            callbackBlock(cutType,videoPath,startTime,endTime,cropRect);
            nav = nil;
        });
    };
    
    trimVideoVC.failback         = ^(NSError *error){
        _trimVideoVC = nil;
        failback(error);
        nav = nil;
    };
    
    trimVideoVC.cancelBlock      = ^(){
        _trimVideoVC = nil;
        cancelBlock();
        nav = nil;
    };

    nav                            = [[RDNavigationViewController alloc] initWithRootViewController:trimVideoVC];
    nav.statusBarHidden            = [UIApplication sharedApplication].statusBarHidden;
    nav.rdVeUiSdkDelegate          = _delegate;
    nav.appKey                     = _appkey;
    nav.licenceKey                 = _licenceKey;
    nav.appSecret                  = _appsecret;
    nav.outPath                    = outputVideoPath;
    [self presentViewController:viewController nav:nav];
}

- (void)cutVideoWithSuperController:(UIViewController *)viewController
                    controllerTitle:(NSString *)title
                    backgroundColor:(UIColor *)backgroundColor
                  cancelButtonTitle:(NSString *)cancelButtonTitle
             cancelButtonTitleColor:(UIColor *)cancelButtonTitleColor
        cancelButtonBackgroundColor:(UIColor *)cancelButtonBackgroundColor
                   otherButtonTitle:(NSString *) otherButtonTitle
              otherButtonTitleColor:(UIColor *) otherButtonTitleColor
         otherButtonBackgroundColor:(UIColor *)otherButtonBackgroundColor
                          assetPath:(NSString *)assetPath
                         outputPath:(NSString *)outputVideoPath
                      callbackBlock:(RdVE_TrimVideoPathCallbackBlock) callbackBlock
                           failback:(RdVEFailBlock) failback
                             cancel:(RdVECancelBlock )cancelBlock{
    if(assetPath.length == 0){
        NSDictionary *userInfo= [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"没有视频源", nil),@"message", nil];
        NSError *error = [NSError errorWithDomain:RDUISDKCustomErrorDomain code:RDUISDKErrorCode_NillInput userInfo:userInfo];
        failback(error);
        return;
    }
    
    if(outputVideoPath.length == 0){
        NSDictionary *userInfo= [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"没有视频输出地址", nil),@"message", nil];
        NSError *error = [NSError errorWithDomain:RDUISDKCustomErrorDomain code:RDUISDKErrorCode_NillOutputPath userInfo:userInfo];
        failback(error);
        return;
    }

    RDTrimVideoViewController *trimVideoVC  = [[RDTrimVideoViewController alloc] init];
    trimVideoVC.defaultSelectMinOrMax       = _editConfiguration.defaultSelectMinOrMax;
    trimVideoVC.trimType                    = TRIMMODESPECIFYTIME_TWO;
    trimVideoVC.trimDuration_OneSpecifyTime     = _editConfiguration.trimDuration_OneSpecifyTime;
    trimVideoVC.trimMinDuration_TwoSpecifyTime  = _editConfiguration.trimMinDuration_TwoSpecifyTime;
    trimVideoVC.trimMaxDuration_TwoSpecifyTime  = _editConfiguration.trimMaxDuration_TwoSpecifyTime;
    trimVideoVC.trimExportVideoType             = _editConfiguration.trimExportVideoType;
    trimVideoVC.cancelButtonTitleColor      = cancelButtonTitleColor;
    trimVideoVC.cancelButtonBackgroundColor = cancelButtonBackgroundColor;
    trimVideoVC.cancelButtonTitle           = cancelButtonTitle;
    trimVideoVC.otherButtonTitleColor       = otherButtonTitleColor;
    trimVideoVC.otherButtonBackgroundColor  = otherButtonBackgroundColor;
    trimVideoVC.otherButtonTitle            = otherButtonTitle;
    trimVideoVC.customTitle                 = title;
    trimVideoVC.customBackgroundColor       = backgroundColor;
    trimVideoVC.trimFile                    = nil;
    trimVideoVC.trimVideoAsset              = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:assetPath] options:nil];
    trimVideoVC.outputFilePath              = outputVideoPath;
    trimVideoVC.editVideoSize               = CGSizeZero;
    _trimVideoVC = trimVideoVC;
    trimVideoVC.callbackBlock = ^(RDCutVideoReturnType cutType,NSString *videoPath,CMTime startTime,CMTime endTime, CGRect cropRect){
        dispatch_async(dispatch_get_main_queue(), ^{
            _trimVideoVC = nil;
            callbackBlock(cutType,videoPath,startTime,endTime,cropRect);
            
        });
    };
    
    trimVideoVC.failback         = ^(NSError *error){
        _trimVideoVC = nil;
        failback(error);
    };
    
    trimVideoVC.cancelBlock      = ^(){
        _trimVideoVC = nil;
        cancelBlock();
    };

    trimVideoVC.rd_CutVideoReturnType = _rd_CutVideoReturnType;
    RDNavigationViewController *nav;
    nav                            = [[RDNavigationViewController alloc] initWithRootViewController:trimVideoVC];
    nav.statusBarHidden            = [UIApplication sharedApplication].statusBarHidden;
    nav.rdVeUiSdkDelegate          = _delegate;
    nav.appKey                     = _appkey;
    nav.licenceKey                 = _licenceKey;
    nav.appSecret                  = _appsecret;
    nav.outPath                    = outputVideoPath;
    
    [self presentViewController:viewController nav:nav];
}

- (void)trimVideoWithType:(RDCutVideoReturnType )type{
    [_trimVideoVC changeCutVideoReturnType:type];
}

- (void)cutVideo_withCutType:(RDCutVideoReturnType)type{
    [self trimVideoWithType:type];
}

//截取视频
-(void)Intercept:(NSString *)InPath atOutPath:(NSString *)OutPath atStartTime:(float) startTime atDurationTime:(float) DurationTime atAppkey:(NSString *)appKey  atappSecret:(NSString *)appSecret atvideoAverageBitRate:(float) videoAverageBitRate atSuccessCancelBlock:(SuccessCancelBlock)successCancelBlock atFailCancelBlock:(FailCancelBlock)failCancelBlock
{
    _failCancelBlock = failCancelBlock;
    _successCancelBlock = successCancelBlock;
    
    RDScene * scene = [[RDScene alloc] init];
    RDFile * file = [self GetFile:InPath];
    
    VVAsset*vvassetWhite = [self getVvasset:file];
    vvassetWhite.timeRange    = CMTimeRangeMake(CMTimeMakeWithSeconds( startTime , TIMESCALE), CMTimeMakeWithSeconds( DurationTime  , TIMESCALE));
    
    [scene.vvAsset addObject:vvassetWhite];
    AVURLAsset *asset;
    asset = [AVURLAsset assetWithURL:file.contentURL];
    CGSize size = [RDHelpClass getVideoSizeForTrack:asset];
    NSMutableArray * scenes = [NSMutableArray array];
    [scenes addObject:scene];
    
    RDVECore * coreSdk = [[RDVECore alloc] initWithAPPKey:appKey APPSecret:appSecret LicenceKey:_licenceKey videoSize:size fps:kEXPORTFPS resultFail:^(NSError *error) {
        NSLog(@"initSDKError:%@", error.localizedDescription);
    }];
    
    [coreSdk setScenes:scenes];
    
    [coreSdk exportMovieURL:[NSURL fileURLWithPath:OutPath] size:size bitrate:videoAverageBitRate fps:kEXPORTFPS audioBitRate:0 audioChannelNumbers:1 maxExportVideoDuration:0 progress:^(float progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"progress:%f",progress);
        });
    } success:^{
            if(self->_successCancelBlock)
            {
                self->_successCancelBlock();
            }
   
    } fail:^(NSError *error) {
        if(self->_failCancelBlock)
        {
           self-> _failCancelBlock();
        }
        NSLog(@"失败:%@",error);
    }];
}

-(VVAsset*) getVvasset:(RDFile *) file
{
    VVAsset* vvasset = [[VVAsset alloc] init];
    
    vvasset.url = file.contentURL;
    
    if(file.fileType == kFILEVIDEO){
        vvasset.type = RDAssetTypeVideo;
        vvasset.videoActualTimeRange = file.videoActualTimeRange;
        if(file.isReverse){
            vvasset.url = file.reverseVideoURL;
            if (CMTimeRangeEqual(kCMTimeRangeZero, file.reverseVideoTimeRange)) {
                vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, file.reverseDurationTime);
            }else{
                vvasset.timeRange = file.reverseVideoTimeRange;
            }
            if(CMTimeCompare(vvasset.timeRange.duration, file.reverseVideoTrimTimeRange.duration) == 1 && CMTimeGetSeconds(file.reverseVideoTrimTimeRange.duration)>0){
                vvasset.timeRange = file.reverseVideoTrimTimeRange;
            }
        }
        else{
            if (CMTimeRangeEqual(kCMTimeRangeZero, file.videoTimeRange)) {
                vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, file.videoDurationTime);
            }else{
                vvasset.timeRange = file.videoTimeRange;
            }
            if(!CMTimeRangeEqual(kCMTimeRangeZero, file.videoTrimTimeRange) && CMTimeCompare(vvasset.timeRange.duration, file.videoTrimTimeRange.duration) == 1){
                vvasset.timeRange = file.videoTrimTimeRange;
            }
        }
        vvasset.speed        = file.speed;
        vvasset.volume       = file.videoVolume;
        vvasset.videoFillType = RDVideoFillTypeFit;
    }
    
    vvasset.rotate = file.rotate;
    vvasset.isVerticalMirror = file.isVerticalMirror;
    vvasset.isHorizontalMirror = file.isHorizontalMirror;
    vvasset.crop = file.crop;
    return  vvasset;
}
-(RDFile *)GetFile:(NSString *)dir
{
    RDFile *file = [RDFile new];
    
    NSURL *url = [NSURL fileURLWithPath:dir];
    {
        //视频
        file.contentURL = url;
        file.fileType = kFILEVIDEO;
        file.videoDurationTime =[AVURLAsset assetWithURL:file.contentURL].duration;
        file.videoTimeRange = CMTimeRangeMake(kCMTimeZero,file.videoDurationTime);
        file.reverseVideoTimeRange = file.videoTimeRange;
        file.videoTrimTimeRange = kCMTimeRangeInvalid;
        file.reverseVideoTrimTimeRange = kCMTimeRangeInvalid;
        file.speedIndex = 2;
        file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
    }
    
    return  file;
}


#pragma mark- 编辑视频
- (void)editVideoWithSuperController:(UIViewController *)viewController
                            urlAsset:(AVURLAsset *)urlAsset
                       clipTimeRange:(CMTimeRange )clipTimeRange
                                crop:(CGRect)crop
                          outputPath:(NSString *)outputVideoPath
                            callback:(RdVECallbackBlock )callbackBlock
                              cancel:(RdVECancelBlock )cancelBlock
{
    [self editVideoWithSuperController:viewController
                              urlAsset:urlAsset
                         clipTimeRange:clipTimeRange
                                  crop:crop
                             musicInfo:nil
                            outputPath:outputVideoPath
                              callback:callbackBlock
                                cancel:cancelBlock];
}

- (void)editVideoWithSuperController:(UIViewController *)viewController
                            urlAsset:(AVURLAsset *)urlAsset
                       clipTimeRange:(CMTimeRange )clipTimeRange
                                crop:(CGRect)crop
                           musicInfo:(RDMusicInfo *)musicInfo
                          outputPath:(NSString *)outputVideoPath
                            callback:(RdVECallbackBlock )callbackBlock
                              cancel:(RdVECancelBlock )cancelBlock
{
    //获取每一个clip的文件信息
    NSMutableArray *fileList = [[NSMutableArray alloc] init];
    RDFile *file = [RDFile new];
    file.contentURL = urlAsset.URL;
    file.fileType = kFILEVIDEO;
    file.videoDurationTime =[AVURLAsset assetWithURL:file.contentURL].duration;
    file.videoTimeRange = clipTimeRange;
    file.reverseVideoTimeRange = clipTimeRange;
    file.videoTrimTimeRange = kCMTimeRangeInvalid;
    file.reverseVideoTrimTimeRange = kCMTimeRangeInvalid;
    file.speedIndex = 2;
    if(CGRectEqualToRect(crop, CGRectZero)){
        crop = CGRectMake(0, 0, 1, 1);
    }
    file.crop = crop;
    file.fileCropModeType = kCropTypeOriginal;
    file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
    [fileList addObject:file];
    
    RDNextEditVideoViewController  *_editor_nextViewController;
    
    _editor_nextViewController = [[RDNextEditVideoViewController alloc] init];
    _editor_nextViewController.cancelActionBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            cancelBlock();
        });
    };
    //_editor_nextViewController.exportVideoSize      = CGSizeZero;
    if(_editConfiguration.proportionType == RDPROPORTIONTYPE_LANDSCAPE){
        _editor_nextViewController.exportVideoSize       = CGSizeMake(MAX(kVIDEOWIDTH, kVIDEOHEIGHT), MIN(kVIDEOWIDTH, kVIDEOHEIGHT));
    }
    else if(_editConfiguration.proportionType == RDPROPORTIONTYPE_SQUARE){
        _editor_nextViewController.exportVideoSize       = CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);;
    }else{
        _editor_nextViewController.exportVideoSize       = CGSizeZero;
    }
    [_editor_nextViewController setFileList:fileList];
    
    if(musicInfo){
        _editor_nextViewController.musicURL = musicInfo.url;
        _editor_nextViewController.musicVolume = musicInfo.volume;
        _editor_nextViewController.musicTimeRange = musicInfo.timeRange;
    }
    
    RDNavigationViewController *nav;
    nav = [[RDNavigationViewController alloc] initWithRootViewController:_editor_nextViewController];
    nav.statusBarHidden   = [UIApplication sharedApplication].statusBarHidden;
    nav.rdVeUiSdkDelegate       = _delegate;
    nav.appKey            = _appkey;
    nav.licenceKey        = _licenceKey;
    nav.appSecret         = _appsecret;
    nav.outPath           = outputVideoPath;
    nav.callbackBlock     = ^(NSString * videoPath){
        dispatch_async(dispatch_get_main_queue(), ^{
            callbackBlock(videoPath);
        });
        
    };
    nav.appAlbumCacheName = @"";
    nav.folderType        = kFolderNone;
    nav.editConfiguration.supportFileType = ONLYSUPPORT_VIDEO;
    
    nav.videoAverageBitRate        = _exportConfiguration.videoBitRate;
    nav.edit_functionLists         = [self getEdit_FuncationLists];
    nav.editConfiguration          = _editConfiguration;
    nav.cameraConfiguration        = _cameraConfiguration;
    nav.exportConfiguration        = _exportConfiguration;
    [self presentViewController:viewController nav:nav];
}

- (void)editVideoWithSuperController:(UIViewController *)viewController
                          foldertype:(FolderType)foldertype
                   appAlbumCacheName:(NSString *)appAlbumCacheName
                           urlsArray:(NSMutableArray *)urlsArray
                          outputPath:(NSString *)outputVideoPath
                            callback:(RdVECallbackBlock )callbackBlock
                              cancel:(RdVECancelBlock )cancelBlock{
    
    [self  editVideoWithSuperController:viewController
                             foldertype:foldertype
                      appAlbumCacheName:appAlbumCacheName
                                  lists:urlsArray
                              musicInfo:nil
                             outputPath:outputVideoPath
                               callback:callbackBlock
                                 cancel:cancelBlock];
}



- (void)editVideoWithSuperController:(UIViewController *)viewController
                          foldertype:(FolderType)foldertype
                   appAlbumCacheName:(NSString *)appAlbumCacheName
                           urlsArray:(NSMutableArray *)urlsArray
                           musicInfo:(RDMusicInfo *)musicInfo
                          outputPath:(NSString *)outputVideoPath
                            callback:(RdVECallbackBlock )callbackBlock
                              cancel:(RdVECancelBlock )cancelBlock{
    
    [self  editVideoWithSuperController:viewController
                             foldertype:foldertype
                      appAlbumCacheName:appAlbumCacheName
                                  lists:urlsArray
                              musicInfo:musicInfo
                             outputPath:outputVideoPath
                               callback:callbackBlock
                                 cancel:cancelBlock];
}
- (void)editVideoWithSuperController:(UIViewController *)viewController
                          foldertype:(FolderType)foldertype
                   appAlbumCacheName:(NSString *)appAlbumCacheName
                               lists:(NSMutableArray *)lists
                          outputPath:(NSString *)outputVideoPath
                            callback:(RdVECallbackBlock )callbackBlock
                              cancel:(RdVECancelBlock )cancelBlock{
    [self  editVideoWithSuperController:viewController
                             foldertype:foldertype
                      appAlbumCacheName:appAlbumCacheName
                                  lists:lists
                              musicInfo:nil
                             outputPath:outputVideoPath
                               callback:callbackBlock
                                 cancel:cancelBlock];
}
/** 进入选择相册界面(扫描app缓存视频文件夹)
 */
- (void)editVideoWithSuperController:(UIViewController *)viewController
                          foldertype:(FolderType)foldertype
                   appAlbumCacheName:(NSString *)appAlbumCacheName
                               lists:(NSMutableArray *)lists
                           musicInfo:(RDMusicInfo *)musicInfo
                          outputPath:(NSString *)outputVideoPath
                            callback:(RdVECallbackBlock )callbackBlock
                              cancel:(RdVECancelBlock )cancelBlock
{
    if(foldertype == kFolderNone)
        appAlbumCacheName = @"";
    RDNavigationViewController *nav;
    
    [self setCameraConfigurationSetting:nil];
    if(_deviceOrientation == UIInterfaceOrientationUnknown){
        _deviceOrientation = UIInterfaceOrientationPortrait;
    }
    BOOL suc = [RDHelpClass createSaveTmpFileFolder];
    if(!suc){
        return;
    }
    
    for (int i = 0;i<lists.count;i++) {
        
        if(![lists[i] isKindOfClass:[NSURL class]]){
            id asset = lists[i];
            if(_editConfiguration.supportFileType == ONLYSUPPORT_IMAGE){
                if([asset isKindOfClass:[AVURLAsset class]]){
                    [lists removeObject:asset];
                }
            }
            if(_editConfiguration.supportFileType == ONLYSUPPORT_VIDEO){
                if(![asset isKindOfClass:[AVURLAsset class]]){
                    [lists removeObject:asset];
                }
            }
        }
    }
    
    if(!outputVideoPath || outputVideoPath.length ==0){
        outputVideoPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/exportVideoFile.mp4"];
        
    }
    if(!lists || lists.count == 0){
            RDMainViewController            *mainView;
            mainView              = [[RDMainViewController alloc] init];
            mainView.editConfig = _editConfiguration;
            mainView.cameraConfig = _cameraConfiguration;
            mainView.exportConfig = _exportConfiguration;
            mainView.onAlbumCallbackBlock = nil;
            mainView.rdVECallbackBlock = callbackBlock;
            mainView.needPush = YES;
            if(_editConfiguration.supportFileType == SUPPORT_ALL){
                if(_editConfiguration.defaultSelectAlbum == RDDEFAULTSELECTALBUM_IMAGE){
                    mainView.showPhotos = YES;
                }
            }
            mainView.cancelBlock  = ^(){
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"%s",__func__);
                    cancelBlock();
                });
            };
        nav = [[RDNavigationViewController alloc] initWithRootViewController:mainView];
        nav.statusBarHidden   = [UIApplication sharedApplication].statusBarHidden;
        nav.rdVeUiSdkDelegate       = _delegate;
        nav.appKey            = _appkey;
        nav.licenceKey        = _licenceKey;
        nav.appSecret         = _appsecret;
        nav.folderType         = foldertype;
        nav.appAlbumCacheName  = appAlbumCacheName;
        nav.outPath           = outputVideoPath;
        nav.callbackBlock     = ^(NSString * videoPath){
            dispatch_async(dispatch_get_main_queue(), ^{
                callbackBlock(videoPath);
            });
        };
        
        nav.appAlbumCacheName = appAlbumCacheName;
        nav.folderType        = foldertype;
        nav.editConfiguration.supportFileType = _editConfiguration.supportFileType;
        nav.videoAverageBitRate        = _exportConfiguration.videoBitRate;
        nav.edit_functionLists         = [self getEdit_FuncationLists];
        nav.editConfiguration          = _editConfiguration;
        nav.cameraConfiguration        = _cameraConfiguration;
        nav.exportConfiguration        = _exportConfiguration;
        [self presentViewController:viewController nav:nav];
        lists = nil;
    }
    else{
        NSMutableArray *transitionArray = [RDHelpClass getTransitionArray];
        //获取每一个clip的文件信息
        NSMutableArray *fileList = [[NSMutableArray alloc] init];
        for (int i = 0 ;i < lists.count;i++) {
            RDFile *file = [RDFile new];
            
            if([lists[i] isKindOfClass:[NSURL class]]){
                
                NSURL *url = lists[i];
                if([RDHelpClass isImageUrl:url]){
                    //图片
                    file.contentURL = url;
                    file.fileType = kFILEIMAGE;
                    file.imageDurationTime = CMTimeMakeWithSeconds(3, TIMESCALE);
                    file.speedIndex = 1;
                    file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
                }else{
                    //视频
                    file.contentURL = url;
                    file.fileType = kFILEVIDEO;
                    AVURLAsset * asset = [AVURLAsset assetWithURL:file.contentURL];
                    CMTime duration = asset.duration;
                    file.videoDurationTime = duration;
                    file.videoTimeRange = CMTimeRangeMake(kCMTimeZero,file.videoDurationTime);
                    file.reverseVideoTimeRange = file.videoTimeRange;
                    file.speedIndex = 2;
                    file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
                }
            }else{
                if([lists[i]  isKindOfClass:[AVURLAsset class]]){
                    file.contentURL = ((AVURLAsset *)lists[i]).URL;
                    file.fileType = kFILEVIDEO;
                    file.videoDurationTime =[AVURLAsset assetWithURL:file.contentURL].duration;
                    file.videoTimeRange = CMTimeRangeMake(kCMTimeZero,file.videoDurationTime);
                    file.reverseVideoTimeRange = file.videoTimeRange;
                    file.speedIndex = 2;
                    file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
                }
                else{
                    file.contentURL = ((AVURLAsset *)lists[i]).URL;
                    file.fileType = kFILEIMAGE;
                    file.imageDurationTime = CMTimeMakeWithSeconds(3, TIMESCALE);
                    file.speedIndex = 1;
                    file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
                }
            }
            [fileList addObject:file];
        }
        [self setRandomTransition:fileList];
        RDEditVideoViewController       *_editorViewController;
        RDNextEditVideoViewController  *_editor_nextViewController;
        
        if(_editConfiguration.enableWizard&& _editConfiguration.enableFragmentedit){
            
            _editorViewController                       = [[RDEditVideoViewController alloc] init];
            _editorViewController.cancelBlock           = ^(){
                dispatch_async(dispatch_get_main_queue(), ^{
                    cancelBlock();
                });
            };
            _editorViewController.fileList           = [fileList mutableCopy];
            _editorViewController.isVague = YES;
            if(musicInfo){
                _editorViewController.musicURL = musicInfo.url;
                _editorViewController.musicVolume = musicInfo.volume;
                _editorViewController.musicTimeRange = musicInfo.timeRange;
            }
            nav = [[RDNavigationViewController alloc] initWithRootViewController:_editorViewController];
            
        }
        else{
            _editor_nextViewController = [[RDNextEditVideoViewController alloc] init];
            _editor_nextViewController.cancelActionBlock = ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    cancelBlock();
                });
            };
            //_editor_nextViewController.exportVideoSize       = CGSizeZero;
            
            if(_editConfiguration.proportionType == RDPROPORTIONTYPE_LANDSCAPE){
                _editor_nextViewController.exportVideoSize       = CGSizeMake(MAX(kVIDEOWIDTH, kVIDEOHEIGHT), MIN(kVIDEOWIDTH, kVIDEOHEIGHT));
            }
            else if(_editConfiguration.proportionType == RDPROPORTIONTYPE_SQUARE){
                _editor_nextViewController.exportVideoSize       = CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
            }else{
                _editor_nextViewController.exportVideoSize       = CGSizeZero;
            }
            
            
            [_editor_nextViewController setFileList:fileList];
            if(musicInfo){
                _editor_nextViewController.musicURL = musicInfo.url;
                _editor_nextViewController.musicVolume = musicInfo.volume;
                _editor_nextViewController.musicTimeRange = musicInfo.timeRange;
            }
            nav = [[RDNavigationViewController alloc] initWithRootViewController:_editor_nextViewController];
            
        }
        [lists removeAllObjects];
        lists = nil;
        nav.statusBarHidden   = [UIApplication sharedApplication].statusBarHidden;
        nav.rdVeUiSdkDelegate = _delegate;
        nav.appKey            = _appkey;
        nav.licenceKey        = _licenceKey;
        nav.appSecret         = _appsecret;
        nav.outPath           = outputVideoPath;
        nav.callbackBlock     = ^(NSString * videoPath){
            dispatch_async(dispatch_get_main_queue(), ^{
                callbackBlock(videoPath);
            });
            
        };
        
        nav.appAlbumCacheName = appAlbumCacheName;
        nav.folderType        = foldertype;
        switch (_editConfiguration.supportFileType) {
                
            case ONLYSUPPORT_VIDEO:
                nav.editConfiguration.supportFileType = ONLYSUPPORT_VIDEO;
                break;
            case ONLYSUPPORT_IMAGE:
                nav.editConfiguration.supportFileType = ONLYSUPPORT_IMAGE;
                break;
            case SUPPORT_ALL:
                nav.editConfiguration.supportFileType = SUPPORT_ALL;
                break;
            default:
                break;
        }
        nav.videoAverageBitRate            = _exportConfiguration.videoBitRate;
        nav.edit_functionLists         = [self getEdit_FuncationLists];
        nav.editConfiguration          = _editConfiguration;
        nav.cameraConfiguration        = _cameraConfiguration;
        nav.exportConfiguration        = _exportConfiguration;
        
        [self presentViewController:viewController nav:nav];
    }
}
//单场景多媒体编辑视频
- (void)editVideoWithSuperController_SingleSceneMultimedia:(UIViewController *)viewController
                          foldertype:(FolderType)foldertype
                   appAlbumCacheName:(NSString *)appAlbumCacheName
                               lists:(NSMutableArray *)lists
                          outputPath:(NSString *)outputVideoPath
                            callback:(RdVECallbackBlock )callbackBlock
                              cancel:(RdVECancelBlock )cancelBlock
{
    if(foldertype == kFolderNone)
        appAlbumCacheName = @"";
    RDNavigationViewController *nav;
    
    [self setCameraConfigurationSetting:nil];
    if(_deviceOrientation == UIInterfaceOrientationUnknown){
        _deviceOrientation = UIInterfaceOrientationPortrait;
    }
    BOOL suc = [RDHelpClass createSaveTmpFileFolder];
    if(!suc){
        return;
    }
    
    for (int i = 0;i<lists.count;i++) {
        
        if(![lists[i] isKindOfClass:[NSURL class]]){
            id asset = lists[i];
            if(_editConfiguration.supportFileType == ONLYSUPPORT_IMAGE){
                if([asset isKindOfClass:[AVURLAsset class]]){
                    [lists removeObject:asset];
                }
            }
            if(_editConfiguration.supportFileType == ONLYSUPPORT_VIDEO){
                if(![asset isKindOfClass:[AVURLAsset class]]){
                    [lists removeObject:asset];
                }
            }
        }
    }
    
    if(!outputVideoPath || outputVideoPath.length ==0){
        outputVideoPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/exportVideoFile.mp4"];
        
    }
        
        //获取每一个clip的文件信息
        NSMutableArray *fileList = [[NSMutableArray alloc] init];
        for (int i = 0 ;i < lists.count;i++) {
            RDFile *file = [RDFile new];
            
            if([lists[i] isKindOfClass:[NSURL class]]){
                
                NSURL *url = lists[i];
                if([RDHelpClass isImageUrl:url]){
                    //图片
                    file.contentURL = url;
                    file.fileType = kFILEIMAGE;
                    file.imageDurationTime = CMTimeMakeWithSeconds(3, TIMESCALE);
                    file.speedIndex = 1;
                    file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
                }else{
                    //视频
                    file.contentURL = url;
                    file.fileType = kFILEVIDEO;
                    file.videoDurationTime =[AVURLAsset assetWithURL:file.contentURL].duration;
                    file.videoTimeRange = CMTimeRangeMake(kCMTimeZero,file.videoDurationTime);
                    file.reverseVideoTimeRange = file.videoTimeRange;
                    file.speedIndex = 2;
                    file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
                }
            }else{
                if([lists[i]  isKindOfClass:[AVURLAsset class]]){
                    file.contentURL = ((AVURLAsset *)lists[i]).URL;
                    file.fileType = kFILEVIDEO;
                    file.videoDurationTime =[AVURLAsset assetWithURL:file.contentURL].duration;
                    file.videoTimeRange = CMTimeRangeMake(kCMTimeZero,file.videoDurationTime);
                    file.reverseVideoTimeRange = file.videoTimeRange;
                    file.speedIndex = 2;
                    file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
                }
                else{
                    file.contentURL = ((AVURLAsset *)lists[i]).URL;
                    file.fileType = kFILEIMAGE;
                    file.imageDurationTime = CMTimeMakeWithSeconds(3, TIMESCALE);
                    file.speedIndex = 1;
                    file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
                }
            }
            [fileList addObject:file];
        }
        [self setRandomTransition:fileList];
        RDEditVideoViewController   *_editorViewController;
        RDNextEditVideoViewController *_editor_nextViewController;
        if(_editConfiguration.enableWizard&& _editConfiguration.enableFragmentedit){
            
            _editorViewController                       = [[RDEditVideoViewController alloc] init];
            
            _editorViewController.cancelBlock           = ^(){
                dispatch_async(dispatch_get_main_queue(), ^{
                    cancelBlock();
                });
            };
            _editorViewController.fileList           = [fileList mutableCopy];
            _editorViewController.isVague = YES;
            
            nav = [[RDNavigationViewController alloc] initWithRootViewController:_editorViewController];
            
        }
        else{
            _editor_nextViewController = [[RDNextEditVideoViewController alloc] init];
            _editor_nextViewController.isMultiMedia = true;
            _editor_nextViewController.cancelActionBlock = ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    cancelBlock();
                });
            };
            //_editor_nextViewController.exportVideoSize       = CGSizeZero;
            if(_editConfiguration.proportionType == RDPROPORTIONTYPE_LANDSCAPE){
                _editor_nextViewController.exportVideoSize       = CGSizeMake(MAX(kVIDEOWIDTH, kVIDEOHEIGHT), MIN(kVIDEOWIDTH, kVIDEOHEIGHT));
            }
            else if(_editConfiguration.proportionType == RDPROPORTIONTYPE_SQUARE){
                _editor_nextViewController.exportVideoSize       = CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
            }else{
                _editor_nextViewController.exportVideoSize       = CGSizeZero;
            }
            
            [_editor_nextViewController setFileList:fileList];
            
            nav = [[RDNavigationViewController alloc] initWithRootViewController:_editor_nextViewController];
            
        }
        [lists removeAllObjects];
        
        nav.statusBarHidden   = [UIApplication sharedApplication].statusBarHidden;
        nav.rdVeUiSdkDelegate = _delegate;
        nav.appKey            = _appkey;
        nav.licenceKey        = _licenceKey;
        nav.appSecret         = _appsecret;
        nav.outPath           = outputVideoPath;
        nav.callbackBlock     = ^(NSString * videoPath){
            dispatch_async(dispatch_get_main_queue(), ^{
                callbackBlock(videoPath);
            });
            
        };
        nav.appAlbumCacheName = appAlbumCacheName;
        nav.folderType        = foldertype;
        switch (_editConfiguration.supportFileType) {
                
            case ONLYSUPPORT_VIDEO:
                nav.editConfiguration.supportFileType = ONLYSUPPORT_VIDEO;
                break;
            case ONLYSUPPORT_IMAGE:
                nav.editConfiguration.supportFileType = ONLYSUPPORT_IMAGE;
                break;
            case SUPPORT_ALL:
                nav.editConfiguration.supportFileType = SUPPORT_ALL;
                break;
            default:
                break;
        }
        nav.videoAverageBitRate            = _exportConfiguration.videoBitRate;
        nav.edit_functionLists         = [self getEdit_FuncationLists];
        nav.editConfiguration          = _editConfiguration;
        nav.cameraConfiguration        = _cameraConfiguration;
        nav.exportConfiguration        = _exportConfiguration;
    
        nav.editConfiguration.enableFragmentedit = false;
    
        [self presentViewController:viewController nav:nav];
}

#pragma mark - 草稿箱
- (void)editDraftWithSuperController:(UIViewController *)viewController
                          outputPath:(NSString *)outputVideoPath
                            callback:(RdVECallbackBlock)callbackBlock
                            failback:(RdVEFailBlock) failback
                              cancel:(RdVECancelBlock)cancelBlock
{
    NSArray *draftList = [[RDDraftManager sharedManager] getALLDraftVideosInfo];
    if (!draftList || draftList.count == 0) {
        if (failback) {
            NSDictionary *userInfo= [NSDictionary dictionaryWithObject:RDLocalizedString(@"您还没有制作任何视频", nil) forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:RDUISDKCustomErrorDomain code:RDUISDKErrorCode_NillDraft userInfo:userInfo];
            failback(error);
        }
        return;
    }
    RDDraftViewController *draftVC = [[RDDraftViewController alloc] init];
    draftVC.cancelActionBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            cancelBlock();
        });
    };
    
    RDNavigationViewController *nav;
    nav = [[RDNavigationViewController alloc] initWithRootViewController:draftVC];
    nav.statusBarHidden   = [UIApplication sharedApplication].statusBarHidden;
    nav.rdVeUiSdkDelegate       = _delegate;
    nav.appKey            = _appkey;
    nav.licenceKey        = _licenceKey;
    nav.appSecret         = _appsecret;
    nav.outPath           = outputVideoPath;
    nav.callbackBlock     = ^(NSString * videoPath){
        dispatch_async(dispatch_get_main_queue(), ^{
            callbackBlock(videoPath);
        });
        
    };
    nav.appAlbumCacheName = @"";
    nav.folderType        = kFolderNone;
    nav.editConfiguration.supportFileType = ONLYSUPPORT_VIDEO;
    
    nav.videoAverageBitRate        = _exportConfiguration.videoBitRate;
    nav.edit_functionLists         = [self getEdit_FuncationLists];
    nav.editConfiguration          = _editConfiguration;
    nav.cameraConfiguration        = _cameraConfiguration;
    nav.exportConfiguration        = _exportConfiguration;
    [self presentViewController:viewController nav:nav];
    
}

#pragma mark - 音效处理
- (void) audioFilterWithSuperController:(UIViewController *)viewController
                              UrlsArray:(NSMutableArray *)urlsArray
                              musicPath:(NSString *)musicPath
                             outputPath:(NSString *)outputVideoPath
                               callback:(RdVECallbackBlock)callbackBlock
                                 cancel:(RdVECancelBlock)cancelBlock
{
    [self setCameraConfiguration:nil];
    
    if(_deviceOrientation == UIInterfaceOrientationUnknown){
        _deviceOrientation = UIInterfaceOrientationPortrait;
    }
    BOOL suc = [RDHelpClass createSaveTmpFileFolder];
    if(!suc){
        return;
    }
    RDNavigationViewController *nav;
    
    //获取每一个clip的文件信息
    NSMutableArray *fileList = [[NSMutableArray alloc] init];
    for (int i = 0 ;i < urlsArray.count;i++) {
        RDFile *file = [RDFile new];
        
        NSURL *url = urlsArray[i];
        if([RDHelpClass isImageUrl:url]){
            //图片
            file.contentURL = url;
            file.fileType = kFILEIMAGE;
            file.imageDurationTime = CMTimeMakeWithSeconds(3, TIMESCALE);
            file.isVerticalMirror = NO;
            file.isHorizontalMirror = NO;
            file.speed = 1;
            file.speedIndex = 1;
            file.crop = CGRectMake(0, 0, 1, 1);
            file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
        }else{
            //视频
            file.contentURL = url;
            file.fileType = kFILEVIDEO;
            file.isReverse = NO;
            file.videoDurationTime =[AVURLAsset assetWithURL:file.contentURL].duration;
            file.videoTimeRange = CMTimeRangeMake(kCMTimeZero,file.videoDurationTime);
            file.reverseVideoTimeRange = file.videoTimeRange;
            file.videoTrimTimeRange = kCMTimeRangeInvalid;
            file.reverseVideoTrimTimeRange = kCMTimeRangeInvalid;
            file.isVerticalMirror = NO;
            file.isHorizontalMirror = NO;
            file.videoVolume = 1.0;
            file.speed = 1;
            file.speedIndex = 2;
            file.rotate = 0;
            file.crop = CGRectMake(0, 0, 1, 1);
            file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
        }
        [fileList addObject:file];
    }
    
    
    AudioFilterViewController *pictureMovieVC = [[AudioFilterViewController alloc] init];
    pictureMovieVC.fileList = [fileList mutableCopy];
    pictureMovieVC.cancelBlock           = ^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            cancelBlock();
        });
    };
    nav = [[RDNavigationViewController alloc] initWithRootViewController:pictureMovieVC];
    nav.statusBarHidden   = [UIApplication sharedApplication].statusBarHidden;
    nav.rdVeUiSdkDelegate = _delegate;
    nav.appKey            = _appkey;
    nav.licenceKey        = _licenceKey;
    nav.appSecret         = _appsecret;
    nav.outPath           = outputVideoPath;
    nav.callbackBlock     = ^(NSString * videoPath){
        dispatch_async(dispatch_get_main_queue(), ^{
            callbackBlock(videoPath);
        });
        
    };
    nav.editConfiguration.supportFileType = _editConfiguration.supportFileType;
    nav.videoAverageBitRate            = _exportConfiguration.videoBitRate;
    nav.edit_functionLists         = [self getEdit_FuncationLists];
    nav.editConfiguration          = _editConfiguration;
    nav.cameraConfiguration        = _cameraConfiguration;
    nav.exportConfiguration        = _exportConfiguration;
    
    [self presentViewController:viewController nav:nav];
    
    
}
#pragma mark - 照片电影
- (void)pictureMovieWithSuperController:(UIViewController *)viewController
                              UrlsArray:(NSMutableArray *)urlsArray
                             outputPath:(NSString *)outputVideoPath
                               callback:(RdVECallbackBlock )callbackBlock
                                 cancel:(RdVECancelBlock )cancelBlock
{
    [self setCameraConfigurationSetting:nil];
    if(_deviceOrientation == UIInterfaceOrientationUnknown){
        _deviceOrientation = UIInterfaceOrientationPortrait;
    }
    BOOL suc = [RDHelpClass createSaveTmpFileFolder];
    if(!suc){
        return;
    }
    RDNavigationViewController *nav;
    //获取每一个clip的文件信息
    NSMutableArray *fileList = [[NSMutableArray alloc] init];
    for (int i = 0 ;i < urlsArray.count;i++) {
        RDFile *file = [RDFile new];
            
        NSURL *url = urlsArray[i];
        if([RDHelpClass isImageUrl:url]){
            //图片
            file.contentURL = url;
            file.fileType = kFILEIMAGE;
            file.imageDurationTime = CMTimeMakeWithSeconds(3, TIMESCALE);
            file.speedIndex = 1;
            file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
        }else{
            //视频
            file.contentURL = url;
            file.fileType = kFILEVIDEO;
            file.videoDurationTime =[AVURLAsset assetWithURL:file.contentURL].duration;
            file.videoTimeRange = CMTimeRangeMake(kCMTimeZero,file.videoDurationTime);
            file.reverseVideoTimeRange = file.videoTimeRange;
            file.speedIndex = 2;
            file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
        }
        [fileList addObject:file];
    }
    [self setRandomTransition:fileList];
    PictureMovieViewController *pictureMovieVC = [[PictureMovieViewController alloc] init];
    pictureMovieVC.fileList = [fileList mutableCopy];
    pictureMovieVC.cancelBlock           = ^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            cancelBlock();
        });
    };
    nav = [[RDNavigationViewController alloc] initWithRootViewController:pictureMovieVC];    
    nav.statusBarHidden   = [UIApplication sharedApplication].statusBarHidden;
    nav.rdVeUiSdkDelegate = _delegate;
    nav.appKey            = _appkey;
    nav.licenceKey        = _licenceKey;
    nav.appSecret         = _appsecret;
    nav.outPath           = outputVideoPath;
    nav.callbackBlock     = ^(NSString * videoPath){
        dispatch_async(dispatch_get_main_queue(), ^{
            callbackBlock(videoPath);
        });
        
    };
    nav.editConfiguration.supportFileType = _editConfiguration.supportFileType;
    nav.videoAverageBitRate            = _exportConfiguration.videoBitRate;
    nav.edit_functionLists         = [self getEdit_FuncationLists];
    nav.editConfiguration          = _editConfiguration;
    nav.cameraConfiguration        = _cameraConfiguration;
    nav.exportConfiguration        = _exportConfiguration;
    
    [self presentViewController:viewController nav:nav];
}
- (void)AETemplateMovieWithSuperController:(UIViewController *)viewController
                                 UrlsArray:(NSMutableArray *)urlsArray
                                outputPath:(NSString *)outputVideoPath
                                    isMask:(BOOL)isMask
                                  callback:(RdVECallbackBlock )callbackBlock
                                    cancel:(RdVECancelBlock )cancelBlock
{
    [self setCameraConfigurationSetting:nil];
    if(_deviceOrientation == UIInterfaceOrientationUnknown){
        _deviceOrientation = UIInterfaceOrientationPortrait;
    }
    BOOL suc = [RDHelpClass createSaveTmpFileFolder];
    if(!suc){
        return;
    }
    RDNavigationViewController *nav;
    //获取每一个clip的文件信息
    NSMutableArray *fileList = [[NSMutableArray alloc] init];
    for (int i = 0 ;i < urlsArray.count;i++) {
        RDFile *file = [RDFile new];
        
        NSURL *url = urlsArray[i];
        if([RDHelpClass isImageUrl:url]){
            //图片
            file.contentURL = url;
            file.fileType = kFILEIMAGE;
            file.imageDurationTime = CMTimeMakeWithSeconds(3, TIMESCALE);
            file.speedIndex = 1;
            file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
        }else{
            //视频
            file.contentURL = url;
            file.fileType = kFILEVIDEO;
            file.videoDurationTime =[AVURLAsset assetWithURL:file.contentURL].duration;
            file.videoTimeRange = CMTimeRangeMake(kCMTimeZero,file.videoDurationTime);
            file.reverseVideoTimeRange = file.videoTimeRange;
            file.speedIndex = 2;
            file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
        }
        [fileList addObject:file];
    }
    [self setRandomTransition:fileList];
    AETemplateMovieViewController *aeTemplateMovieVC = [[AETemplateMovieViewController alloc] init];
    aeTemplateMovieVC.fileList = [fileList mutableCopy];
    aeTemplateMovieVC.isMask = isMask;
    aeTemplateMovieVC.cancelActionBlock           = ^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            cancelBlock();
        });
    };
    nav = [[RDNavigationViewController alloc] initWithRootViewController:aeTemplateMovieVC];
    nav.statusBarHidden   = [UIApplication sharedApplication].statusBarHidden;
    nav.rdVeUiSdkDelegate = _delegate;
    nav.appKey            = _appkey;
    nav.licenceKey        = _licenceKey;
    nav.appSecret         = _appsecret;
    nav.outPath           = outputVideoPath;
    nav.callbackBlock     = ^(NSString * videoPath){
        dispatch_async(dispatch_get_main_queue(), ^{
            callbackBlock(videoPath);
        });
        
    };
    nav.editConfiguration.supportFileType = _editConfiguration.supportFileType;
    nav.videoAverageBitRate            = _exportConfiguration.videoBitRate;
    nav.edit_functionLists         = [self getEdit_FuncationLists];
    nav.editConfiguration          = _editConfiguration;
    nav.cameraConfiguration        = _cameraConfiguration;
    nav.exportConfiguration        = _exportConfiguration;
    
    [self presentViewController:viewController nav:nav];
}

- (void)AEHomeWithSuperController:(UIViewController *)viewController
                       outputPath:(NSString *)outputVideoPath
                         callback:(RdVECallbackBlock)callbackBlock
                           cancel:(RdVECancelBlock)cancelBlock
{
    [self setCameraConfigurationSetting:nil];
    if(_deviceOrientation == UIInterfaceOrientationUnknown){
        _deviceOrientation = UIInterfaceOrientationPortrait;
    }
    BOOL suc = [RDHelpClass createSaveTmpFileFolder];
    if(!suc){
        return;
    }
    RDNavigationViewController *nav;
    AEHomeViewController *aeHomeVC = [[AEHomeViewController alloc] init];
    aeHomeVC.cancelActionBlock           = ^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            cancelBlock();
        });
    };
    nav = [[RDNavigationViewController alloc] initWithRootViewController:aeHomeVC];
    nav.statusBarHidden   = [UIApplication sharedApplication].statusBarHidden;
    nav.rdVeUiSdkDelegate = _delegate;
    nav.appKey            = _appkey;
    nav.licenceKey        = _licenceKey;
    nav.appSecret         = _appsecret;
    nav.outPath           = outputVideoPath;
    nav.callbackBlock     = ^(NSString * videoPath){
        dispatch_async(dispatch_get_main_queue(), ^{
            callbackBlock(videoPath);
        });
        
    };
    nav.editConfiguration.supportFileType = _editConfiguration.supportFileType;
    nav.videoAverageBitRate            = _exportConfiguration.videoBitRate;
    nav.edit_functionLists         = [self getEdit_FuncationLists];
    nav.editConfiguration          = _editConfiguration;
    nav.cameraConfiguration        = _cameraConfiguration;
    nav.exportConfiguration        = _exportConfiguration;
    
    [self presentViewController:viewController nav:nav];
}

#pragma mark- 多格 拼图
/**打开相册
 *@param albumType 视频，图片，视频+图片
 */
- (BOOL)dogePuzzleOnRdVEAlbumWithSuperController:(UIViewController *)viewController
                             albumType:(ALBUMTYPE)albumType
                             callBlock:(OnAlbumCallbackBlock) callbackBlock
                           cancelBlock:(RdVECancelBlock) cancelBlock{
    BOOL suc = [RDHelpClass createSaveTmpFileFolder];
    if(!suc){
        return NO;
    }
    
    [self setCameraConfigurationSetting:nil];
    
    
    RDMainViewController            *mainView;
    mainView                           = [[RDMainViewController alloc] init];
    mainView.editConfig = _editConfiguration;
    mainView.cameraConfig = _cameraConfiguration;
    mainView.exportConfig = _exportConfiguration;
    mainView.minCountLimit = 2;
    mainView.needPush                  = YES;
    mainView.onAlbumCallbackBlock   = callbackBlock;
    if(_editConfiguration.supportFileType == SUPPORT_ALL){
        if(_editConfiguration.defaultSelectAlbum == RDDEFAULTSELECTALBUM_IMAGE){
            mainView.showPhotos = YES;
        }
    }
    mainView.cancelBlock = ^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            if(cancelBlock){
                cancelBlock();
            }
        });
    };
    
    RDNavigationViewController *nav;
    nav = [[RDNavigationViewController alloc] initWithRootViewController:mainView];
    nav.statusBarHidden        = [UIApplication sharedApplication].statusBarHidden;
    nav.rdVeUiSdkDelegate            = _delegate;
    nav.appKey                 = _appkey;
    nav.licenceKey             = _licenceKey;
    nav.appSecret              = _appsecret;
    nav.videoAverageBitRate        = _exportConfiguration.videoBitRate;
    nav.editConfiguration            = _editConfiguration;
    nav.exportConfiguration          = _exportConfiguration;
    nav.cameraConfiguration          = _cameraConfiguration;
    if(albumType == kONLYALBUMIMAGE){
        nav.editConfiguration.supportFileType  = ONLYSUPPORT_IMAGE;
    }else if(albumType == kONLYALBUMVIDEO){
        nav.editConfiguration.supportFileType  = ONLYSUPPORT_VIDEO;
    }else{
        nav.editConfiguration.supportFileType  = SUPPORT_ALL;
    }
    nav.cameraConfiguration        = _cameraConfiguration;
    
    [self presentViewController:viewController nav:nav];
    
    return YES;
}
- (void)dogePuzzleWithSuperController:(UIViewController *)viewController
                            UrlsArray:(NSMutableArray *)urlsArray
                           outputPath:(NSString *)outputVideoPath
                             callback:(RdVECallbackBlock )callbackBlock
                               cancel:(RdVECancelBlock )cancelBlock
{
    [self setCameraConfigurationSetting:nil];
    if(_deviceOrientation == UIInterfaceOrientationUnknown){
        _deviceOrientation = UIInterfaceOrientationPortrait;
    }
    BOOL suc = [RDHelpClass createSaveTmpFileFolder];
    if(!suc){
        return;
    }
    RDNavigationViewController *nav;
    //获取每一个clip的文件信息
    NSMutableArray *fileList = [[NSMutableArray alloc] init];
    for (int i = 0 ;i < urlsArray.count;i++) {
        RDFile *file = [RDFile new];
        
        NSURL *url = urlsArray[i];
        if([RDHelpClass isImageUrl:url]){
            //图片
            if ([RDHelpClass isSystemPhotoUrl:url]) {
                PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
                option.synchronous = YES;
                option.resizeMode = PHImageRequestOptionsResizeModeExact;
                
                PHAsset* asset =[[PHAsset fetchAssetsWithALAssetURLs:@[url] options:nil] objectAtIndex:0];
                if ([[asset valueForKey:@"uniformTypeIdentifier"] isEqualToString:@"com.compuserve.gif"]) {
                    __block float duration = 0;
                    [[PHImageManager defaultManager] requestImageDataForAsset:asset
                                                                      options:option
                                                                resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                                                                    if (imageData && ![info[@"PHImageResultIsDegradedKey"] boolValue]) {
                                                                        file.gifData = imageData;
                                                                        duration = [RDVECore isGifWithData:imageData];
                                                                    }
                                                                }];
                    file.isGif = YES;
                    file.imageDurationTime = CMTimeMakeWithSeconds(duration, TIMESCALE);
                    file.speedIndex = 2;
                }else {
                    file.imageDurationTime = CMTimeMakeWithSeconds(3, TIMESCALE);
                    file.speedIndex = 1;
                }
            }else {
                float duration = [RDVECore isGifWithData:[NSData dataWithContentsOfURL:url]];
                if (duration > 0) {
                    file.isGif = YES;
                    file.imageDurationTime = CMTimeMakeWithSeconds(duration, TIMESCALE);
                    file.speedIndex = 2;
                }else {
                    file.imageDurationTime = CMTimeMakeWithSeconds(3, TIMESCALE);
                    file.speedIndex = 1;
                }
            }            
            file.contentURL = url;
            file.fileType = kFILEIMAGE;
            file.isVerticalMirror = NO;
            file.isHorizontalMirror = NO;
            file.speed = 1;
            file.crop = CGRectMake(0, 0, 1, 1);
            file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
        }else{
            //视频
            file.contentURL = url;
            file.fileType = kFILEVIDEO;
            file.isReverse = NO;
            file.videoDurationTime =[AVURLAsset assetWithURL:file.contentURL].duration;
            file.videoTimeRange = CMTimeRangeMake(kCMTimeZero,file.videoDurationTime);
            file.reverseVideoTimeRange = file.videoTimeRange;
            file.videoTrimTimeRange = kCMTimeRangeInvalid;
            file.reverseVideoTrimTimeRange = kCMTimeRangeInvalid;
            file.isVerticalMirror = NO;
            file.isHorizontalMirror = NO;
            file.videoVolume = 1.0;
            file.speed = 1;
            file.speedIndex = 2;
            file.rotate = 0;
            file.crop = CGRectMake(0, 0, 1, 1);
            file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
        }
        [fileList addObject:file];
    }
    
    RDMultiDifferentViewController *pictureMovieVC = [[RDMultiDifferentViewController alloc] init];
    pictureMovieVC.fileList = [fileList mutableCopy];
    pictureMovieVC.cancelBlock           = ^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            cancelBlock();
        });
    };
    
    if(_editConfiguration.proportionType == RDPROPORTIONTYPE_LANDSCAPE){
        pictureMovieVC.exportVideoSize       = CGSizeMake(MAX(kVIDEOWIDTH, kVIDEOHEIGHT), MIN(kVIDEOWIDTH, kVIDEOHEIGHT));
    }
    else if(_editConfiguration.proportionType == RDPROPORTIONTYPE_SQUARE){
        pictureMovieVC.exportVideoSize       = CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
    }else{
        pictureMovieVC.exportVideoSize       = CGSizeZero;
    }
    
    
    nav = [[RDNavigationViewController alloc] initWithRootViewController:pictureMovieVC];
    nav.statusBarHidden   = [UIApplication sharedApplication].statusBarHidden;
    nav.rdVeUiSdkDelegate = _delegate;
    nav.appKey            = _appkey;
    nav.licenceKey        = _licenceKey;
    nav.appSecret         = _appsecret;
    nav.outPath           = outputVideoPath;
    nav.callbackBlock     = ^(NSString * videoPath){
        dispatch_async(dispatch_get_main_queue(), ^{
            callbackBlock(videoPath);
        });
        
    };
    nav.editConfiguration.supportFileType = _editConfiguration.supportFileType;
    nav.videoAverageBitRate            = _exportConfiguration.videoBitRate;
    nav.edit_functionLists         = [self getEdit_FuncationLists];
    nav.editConfiguration          = _editConfiguration;
    nav.cameraConfiguration        = _cameraConfiguration;
    nav.exportConfiguration        = _exportConfiguration;
    
    [self presentViewController:viewController nav:nav];
}

#pragma mark-主题
- (void)pictureMovieWithSuperController_Theme:(UIViewController *)viewController
                                   UrlsArray:(NSMutableArray *)urlsArray
                                  outputPath:(NSString *)outputVideoPath
                                    callback:(RdVECallbackBlock )callbackBlock
                                      cancel:(RdVECancelBlock )cancelBlock
{
    [self setCameraConfigurationSetting:nil];
    if(_deviceOrientation == UIInterfaceOrientationUnknown){
        _deviceOrientation = UIInterfaceOrientationPortrait;
    }
    BOOL suc = [RDHelpClass createSaveTmpFileFolder];
    if(!suc){
        return;
    }
    RDNavigationViewController *nav;
    //获取每一个clip的文件信息
    NSMutableArray *fileList = [[NSMutableArray alloc] init];
    for (int i = 0 ;i < urlsArray.count;i++) {
        RDFile *file = [RDFile new];
        
        NSURL *url = urlsArray[i];
        if([RDHelpClass isImageUrl:url]){
            //图片
            file.contentURL = url;
            file.fileType = kFILEIMAGE;
            file.imageDurationTime = CMTimeMakeWithSeconds(3, TIMESCALE);
            file.speedIndex = 1;
            file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
        }else{
            //视频
            file.contentURL = url;
            file.fileType = kFILEVIDEO;
            file.videoDurationTime =[AVURLAsset assetWithURL:file.contentURL].duration;
            file.videoTimeRange = CMTimeRangeMake(kCMTimeZero,file.videoDurationTime);
            file.reverseVideoTimeRange = file.videoTimeRange;
            file.speedIndex = 2;
            file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
        }
        [fileList addObject:file];
    }
    [self setRandomTransition:fileList];
    
    QuikViewController *pictureMovieVC = [[QuikViewController alloc] init];
    pictureMovieVC.fileList = [fileList mutableCopy];
    pictureMovieVC.cancelBlock           = ^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            cancelBlock();
        });
    };

    nav = [[RDNavigationViewController alloc] initWithRootViewController:pictureMovieVC];
    nav.statusBarHidden   = [UIApplication sharedApplication].statusBarHidden;
    nav.rdVeUiSdkDelegate = _delegate;
    nav.appKey            = _appkey;
    nav.licenceKey        = _licenceKey;
    nav.appSecret         = _appsecret;
    nav.outPath           = outputVideoPath;
    nav.callbackBlock     = ^(NSString * videoPath){
        dispatch_async(dispatch_get_main_queue(), ^{
            callbackBlock(videoPath);
        });

    };
    nav.editConfiguration.supportFileType = _editConfiguration.supportFileType;
    nav.videoAverageBitRate            = _exportConfiguration.videoBitRate;
    nav.edit_functionLists         = [self getEdit_FuncationLists];
    nav.editConfiguration          = _editConfiguration;
    nav.cameraConfiguration        = _cameraConfiguration;
    nav.exportConfiguration        = _exportConfiguration;

    [self presentViewController:viewController nav:nav];
}


#pragma mark- ===================以下方法已经过期了============
- (void)editVideoWithSuperController:(UIViewController *)viewController
                          foldertype:(FolderType)foldertype
                   appAlbumCacheName:(NSString *)appAlbumCacheName
                              assets:(NSMutableArray *)assets
                          outputPath:(NSString *)outputVideoPath
                            callback:(RdVECallbackBlock )callbackBlock
                              cancel:(RdVECancelBlock )cancelBlock{
    
    [self  editVideoWithSuperController:viewController
                             foldertype:foldertype
                      appAlbumCacheName:appAlbumCacheName
                                  lists:assets
                             outputPath:outputVideoPath
                               callback:callbackBlock
                                 cancel:cancelBlock];
    
}

- (void)editVideoWithSuperController:(UIViewController *)viewController
                          foldertype:(FolderType)foldertype
                   appAlbumCacheName:(NSString *)appAlbumCacheName
                              assets:(NSMutableArray *)assets
                          imagePaths:(NSMutableArray *)imagePaths
                          outputPath:(NSString *)outputVideoPath
                            callback:(RdVECallbackBlock )callbackBlock
                              cancel:(RdVECancelBlock )cancelBlock{
    
    [assets addObjectsFromArray:imagePaths];
    
    [self editVideoWithSuperController:viewController foldertype:foldertype appAlbumCacheName:appAlbumCacheName assets:assets  outputPath:outputVideoPath callback:callbackBlock cancel:cancelBlock];
}


/**进入选择相册界面(不扫描app缓存视频文件夹)
 */
- (void)editVideoWithSuperController:(UIViewController *)viewController
                              assets:(NSMutableArray *)assets
                          outputPath:(NSString *)outputVideoPath
                            callback:(RdVECallbackBlock )callbackBlock
                              cancel:(RdVECancelBlock )cancelBlock
{
    [self editVideoWithSuperController:viewController foldertype:kFolderNone appAlbumCacheName:@"" assets:assets outputPath:outputVideoPath callback:callbackBlock cancel:^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"%s",__func__);
            cancelBlock();
        });
        
    }];
}
#pragma mark- ================================================

- (void)setCameraConfigurationSetting:(RDRecordViewController *)rdVideoRecordVC{
    if(_cameraConfiguration.faceUURL.length>0 && _cameraConfiguration.enableFaceU && _cameraConfiguration.enableNetFaceUnity){
        if(rdVideoRecordVC)
            rdVideoRecordVC.faceUURLString = _cameraConfiguration.faceUURL;
    }
    
    rdVideoRecordVC.delegate = self;
    rdVideoRecordVC.captureAsYUV = _cameraConfiguration.captureAsYUV;
    rdVideoRecordVC.enableUseMusic = _cameraConfiguration.enableUseMusic;
    if (rdVideoRecordVC.enableUseMusic) {
        rdVideoRecordVC.musicInfo = (RDMusic *)_cameraConfiguration.musicInfo;
    }
    
    if(_cameraConfiguration.cameraRecordSizeType == RecordVideoTypeMixed){
        if(_cameraConfiguration.cameraSquare_MaxVideoDuration>0){
            _cameraConfiguration.cameraMinVideoDuration = MIN(_cameraConfiguration.cameraMinVideoDuration, _cameraConfiguration.cameraSquare_MaxVideoDuration);
        }
        
        if(_cameraConfiguration.cameraNotSquare_MaxVideoDuration>0){
            _cameraConfiguration.cameraMinVideoDuration = MIN(_cameraConfiguration.cameraMinVideoDuration, _cameraConfiguration.cameraNotSquare_MaxVideoDuration);
        }
        if(rdVideoRecordVC)
            rdVideoRecordVC.minRecordDuration = _cameraConfiguration.cameraMinVideoDuration;
        
    }else{
        if(rdVideoRecordVC){
            if(_cameraConfiguration.cameraRecordSizeType == RecordVideoTypeSquare && _cameraConfiguration.cameraSquare_MaxVideoDuration>0){
                
                rdVideoRecordVC.minRecordDuration = MIN(_cameraConfiguration.cameraMinVideoDuration, _cameraConfiguration.cameraSquare_MaxVideoDuration);
                
            }else if(_cameraConfiguration.cameraRecordSizeType == RecordVideoTypeNotSquare && _cameraConfiguration.cameraNotSquare_MaxVideoDuration>0){
                rdVideoRecordVC.minRecordDuration = MIN(_cameraConfiguration.cameraMinVideoDuration, _cameraConfiguration.cameraNotSquare_MaxVideoDuration);
                
            }else{
                rdVideoRecordVC.minRecordDuration = _cameraConfiguration.cameraMinVideoDuration;
            }
        }
    }
    if(rdVideoRecordVC){
        rdVideoRecordVC.cameraMV = _cameraConfiguration.cameraMV;
        rdVideoRecordVC.cameraVideo = _cameraConfiguration.cameraVideo;
        rdVideoRecordVC.cameraPhoto = _cameraConfiguration.cameraPhoto;
        rdVideoRecordVC.MVRecordMinDuration = MIN(_cameraConfiguration.cameraMV_MinVideoDuration, _cameraConfiguration.cameraMV_MaxVideoDuration);
        rdVideoRecordVC.MVRecordMaxDuration = _cameraConfiguration.cameraMV_MaxVideoDuration;
        rdVideoRecordVC.needFilter = _cameraConfiguration.enableFilter;
    }
}

#pragma mark- 录制
- (void)videoRecordAutoSizeWithSourceController: (UIViewController*)source
                                  callbackBlock: (RdVERecordCallbackBlock)callbackBlock
                                 imagebackBlock:(RdVECallbackBlock)imagebackBlock
                                     faileBlock:(RdVEFailBlock)failBlock
                                         cancel: (RdVECancelBlock)cancelBlock{
    if(_cameraConfiguration.cameraOutputPath.length==0){
        NSDictionary *userInfo= [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"请设置拍摄视频的输出路径", nil),@"message", nil];
        NSError *error = [NSError errorWithDomain:RDUISDKCustomErrorDomain code:RDUISDKErrorCode_NillOutputPath userInfo:userInfo];
        
        NSLog(@"error:%@",error);
        failBlock(error);
        return;
    }
    RDRecordViewController *rdVideoRecordVC = [[RDRecordViewController alloc] init];
    
    [self setCameraConfigurationSetting:rdVideoRecordVC];
    
    __weak RDVEUISDK *myself = self;
    
    rdVideoRecordVC.hiddenPhotoLib = _cameraConfiguration.hiddenPhotoLib ? YES : NO;
    rdVideoRecordVC.more = (_cameraConfiguration.cameraModelType == CameraModel_Manytimes ? YES : NO);
    rdVideoRecordVC.isWriteToAlbum = _cameraConfiguration.cameraWriteToAlbum;
    
    if(_cameraConfiguration.cameraCollocationPosition == CameraCollocationPositionTop){
        rdVideoRecordVC.isSquareTop = YES;
    }else{
        rdVideoRecordVC.isSquareTop = NO;
    }
    rdVideoRecordVC.recordtype = (RecordType)_cameraConfiguration.cameraRecord_Type;
    rdVideoRecordVC.recordsizetype = (RecordSizeType)_cameraConfiguration.cameraRecordSizeType;
    [rdVideoRecordVC setPhotoPathBlock:^(NSString *path){
        dispatch_async(dispatch_get_main_queue(), ^{
            imagebackBlock(path);
        });
    }];
    
    if(!CGSizeEqualToSize(_cameraConfiguration.cameraOutputSize, CGSizeZero)){
        if(_cameraConfiguration.cameraOutputSize.width == _cameraConfiguration.cameraOutputSize.height){
            rdVideoRecordVC.recordsizetype = RecordSizeTypeSquare;
        }
        if (rdVideoRecordVC.recordsizetype == RecordVideoTypeNotSquare) {
            rdVideoRecordVC.recordorientation = (RecordOrientation)_cameraConfiguration.cameraRecordOrientation;
        }
        rdVideoRecordVC.recordSize = _cameraConfiguration.cameraOutputSize;
    }
    rdVideoRecordVC.faceU = _cameraConfiguration.enableFaceU;
    rdVideoRecordVC.MAX_VIDEO_DUR_1 = _cameraConfiguration.cameraSquare_MaxVideoDuration;
    rdVideoRecordVC.MAX_VIDEO_DUR_2 = _cameraConfiguration.cameraNotSquare_MaxVideoDuration;
    rdVideoRecordVC.videoPath = _cameraConfiguration.cameraOutputPath;
    rdVideoRecordVC.fps = _cameraConfiguration.cameraFrameRate;
    rdVideoRecordVC.bitrate = _cameraConfiguration.cameraBitRate;
    rdVideoRecordVC.cameraPosition = _cameraConfiguration.cameraCaptureDevicePosition;
    //相机水印相关设置
    rdVideoRecordVC.enableCameraWaterMark           = _cameraConfiguration.enabelCameraWaterMark;
//    rdVideoRecordVC.waterHeader                     = _cameraConfiguration.cameraWaterMarkHeader;
//    rdVideoRecordVC.waterBody                       = _cameraConfiguration.cameraWaterMarkBody;
//    rdVideoRecordVC.waterFooter                     = _cameraConfiguration.cameraWaterMarkEnd;
    rdVideoRecordVC.cameraWaterMarkHeaderDuration   = _cameraConfiguration.cameraWaterMarkHeaderDuration;
    rdVideoRecordVC.cameraWaterMarkEndDuration   = _cameraConfiguration.cameraWaterMarkEndDuration;
    rdVideoRecordVC.cameraWaterProcessingCompletionBlock = _cameraConfiguration.cameraWaterProcessingCompletionBlock;
    
    if (_cameraConfiguration.cameraRecordSizeType == RecordVideoTypeNotSquare) {
        rdVideoRecordVC.recordorientation = (RecordOrientation)_cameraConfiguration.cameraRecordOrientation;
    }
    [rdVideoRecordVC addFinishBlock:^(NSString * _Nullable videoPath, int type,RDMusic *music) {
        RDMusicInfo *musicInfo = [[RDMusicInfo alloc] init];
        musicInfo.url = music.url;
        musicInfo.volume = music.volume;
        musicInfo.timeRange = kCMTimeRangeZero;
        musicInfo.clipTimeRange = music.clipTimeRange;
        if (videoPath.length > 0) {
            if(_cameraConfiguration.cameraWriteToAlbum && _cameraConfiguration.cameraModelType != CameraModel_Manytimes){
                [[[ALAssetsLibrary alloc] init] writeVideoAtPathToSavedPhotosAlbum:[NSURL fileURLWithPath:videoPath] completionBlock:(^(NSURL *assetURL, NSError *error){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        
                        callbackBlock((type==2 ? 0 : 1),videoPath,musicInfo);
                    });
                })];
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    callbackBlock((type==2 ? 0 : 1),videoPath,musicInfo);
                });
            }
        }
    }];
    [rdVideoRecordVC addCancelBlock:^(int type, UIViewController * _Nullable vc) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(type==0){
                [vc dismissViewControllerAnimated:_editConfiguration.dissmissAnimated completion:nil];
                cancelBlock();
            }else{
                [vc dismissViewControllerAnimated:_editConfiguration.dissmissAnimated completion:nil];
                if(_cameraConfiguration.cameraEnterPhotoAlbumCallblackBlock)
                    _cameraConfiguration.cameraEnterPhotoAlbumCallblackBlock(self);
            }
        });
    }];
    
    RDNavigationViewController* nav = [[RDNavigationViewController alloc] initWithRootViewController:rdVideoRecordVC];
    nav.rdVeUiSdkDelegate = _delegate;
    nav.appKey = _appkey;
    nav.licenceKey        = _licenceKey;
    nav.appSecret = _appsecret;
    nav.edit_functionLists         = [self getEdit_FuncationLists];
    nav.editConfiguration = _editConfiguration;
    nav.cameraConfiguration = _cameraConfiguration;
    nav.exportConfiguration = _exportConfiguration;
    nav.navigationBarHidden = YES;
    [source presentViewController:nav animated:YES completion:nil];
}


- (void)videoRecordWithSourceController: (UIViewController*)source
                         cameraPosition: (AVCaptureDevicePosition )postion
                              frameRate: (int32_t) frameRate
                                bitRate: (int32_t) bitRate
                             recordSize: (CGSize) size
                            Record_Type: (Record_Type)record_Type
                             outputPath: (NSString*)outputPath
                              videoPath: (RdVECallbackBlock)callbackBlock
                                 cancel: (RdVECancelBlock)cancelBlock{
    if(_appsecret.length>0 && _appkey.length>0){
        RDRecordViewController *rdVideoRecordVC = [[RDRecordViewController alloc] init];
        if(_cameraConfiguration.cameraCollocationPosition == CameraCollocationPositionTop){
            rdVideoRecordVC.isSquareTop = YES;
        }else{
            rdVideoRecordVC.isSquareTop = NO;
        }
        
        [self setCameraConfigurationSetting:rdVideoRecordVC];
        
        rdVideoRecordVC.hiddenPhotoLib = _cameraConfiguration.hiddenPhotoLib;
        rdVideoRecordVC.recordtype = (RecordType)_cameraConfiguration.cameraRecord_Type;
        rdVideoRecordVC.recordsizetype = (RecordSizeType)_cameraConfiguration.cameraRecordSizeType;
        if (_cameraConfiguration.cameraRecordSizeType == RecordVideoTypeNotSquare) {
            rdVideoRecordVC.recordorientation = (RecordOrientation)_cameraConfiguration.cameraRecordOrientation;
        }
        
        rdVideoRecordVC.faceU = _cameraConfiguration.enableFaceU;
        rdVideoRecordVC.MAX_VIDEO_DUR_1 = _cameraConfiguration.cameraSquare_MaxVideoDuration;
        rdVideoRecordVC.MAX_VIDEO_DUR_2 = _cameraConfiguration.cameraNotSquare_MaxVideoDuration;
        rdVideoRecordVC.videoPath = _cameraConfiguration.cameraOutputPath;
        rdVideoRecordVC.fps = frameRate;
        rdVideoRecordVC.bitrate = bitRate;
        rdVideoRecordVC.recordSize = size;
        rdVideoRecordVC.cameraPosition = AVCaptureDevicePositionFront;
        
        //相机水印相关设置
        rdVideoRecordVC.enableCameraWaterMark           = _cameraConfiguration.enabelCameraWaterMark;
//        rdVideoRecordVC.waterHeader                     = _cameraConfiguration.cameraWaterMarkHeader;
//        rdVideoRecordVC.waterBody                       = _cameraConfiguration.cameraWaterMarkBody;
//        rdVideoRecordVC.waterFooter                     = _cameraConfiguration.cameraWaterMarkEnd;
        rdVideoRecordVC.cameraWaterMarkHeaderDuration   = _cameraConfiguration.cameraWaterMarkHeaderDuration;
        rdVideoRecordVC.cameraWaterMarkEndDuration   = _cameraConfiguration.cameraWaterMarkEndDuration;
        rdVideoRecordVC.cameraWaterProcessingCompletionBlock = _cameraConfiguration.cameraWaterProcessingCompletionBlock;
        
        if (_cameraConfiguration.cameraRecordSizeType == RecordVideoTypeNotSquare) {
            rdVideoRecordVC.recordorientation = (RecordOrientation)_cameraConfiguration.cameraRecordOrientation;
        }
        [rdVideoRecordVC addFinishBlock:^(NSString * _Nullable videoPath, int type,RDMusic *musicInfo) {
            callbackBlock(videoPath);
        }];
        __weak typeof(self) myself = self;
        [rdVideoRecordVC addCancelBlock:^(int type, UIViewController * _Nullable vc) {
            if(type == 0){
                [vc dismissViewControllerAnimated:myself.editConfiguration.dissmissAnimated completion:nil];
                cancelBlock();
            }else{
                [vc dismissViewControllerAnimated:myself.editConfiguration.dissmissAnimated completion:nil];
                if(myself.cameraConfiguration.cameraEnterPhotoAlbumCallblackBlock)
                    myself.cameraConfiguration.cameraEnterPhotoAlbumCallblackBlock(self);
            }
        }];
        RDNavigationViewController* nav = [[RDNavigationViewController alloc] initWithRootViewController:rdVideoRecordVC];
        nav.navigationBarHidden = YES;
        nav.appKey              = _appkey;
        nav.licenceKey          = _licenceKey;
        nav.appSecret           = _appsecret;
        nav.edit_functionLists  = [self getEdit_FuncationLists];
        nav.editConfiguration   = _editConfiguration;
        nav.cameraConfiguration = _cameraConfiguration;
        nav.exportConfiguration = _exportConfiguration;
        [source presentViewController:nav animated:YES completion:nil];

    }
}

- (void)videoRecordAutoSizeWithSourceController: (UIViewController*)source
                                 cameraPosition: (AVCaptureDevicePosition )postion
                                      frameRate: (int32_t)frameRate
                                        bitRate: (int32_t)bitRate
                                    Record_Type: (Record_Type)record_Type
                                     outputPath: (NSString*)outputPath
                                      videoPath: (RdVECallbackBlock)callbackBlock
                                         cancel: (RdVECancelBlock)cancelBlock{
    
    
    [self videoRecordWithSourceController:source cameraPosition:postion frameRate:frameRate bitRate:bitRate recordSize:CGSizeZero Record_Type:record_Type outputPath:outputPath videoPath:callbackBlock cancel:cancelBlock];
}



/** 录制方形视频(已过期)
 *
 *  @param source        源视图控制器
 *  @param postion       前/后置摄像头
 *  @param frameRate     帧率
 *  @param bitRate       码率
 *  @param record_Type   录制还是拍照
 *  @param outputPath    视频输出路径
 *  @param callbackBlock 完成录制回调
 *  @param cancelBlock   取消录制回调
 */
- (void)videoRecordWidthEqualToHeightWithSourceController: (UIViewController*)source
                                           cameraPosition: (AVCaptureDevicePosition )postion
                                                frameRate: (int32_t)frameRate
                                                  bitRate: (int32_t)bitRate
                                              Record_Type: (Record_Type)record_Type
                                               outputPath: (NSString*)outputPath
                                                videoPath: (RdVECallbackBlock)callbackBlock
                                                   cancel: (RdVECancelBlock)cancelBlock{
    
    [self videoRecordWithSourceController:source cameraPosition:postion frameRate:frameRate bitRate:bitRate recordSize:CGSizeZero Record_Type:record_Type outputPath:outputPath videoPath:callbackBlock cancel:cancelBlock];
}

/** 拍摄 录制
 */
- (void)enter_RecordVideo:(UIViewController*) view atTag:(NSInteger) tag  photoPathCancelBlock:(PhotoPathCancelBlock)photoPathCancelBlock changeFaceCancelBlock:(ChangeFaceCancelBlock)changeFaceCancelBlock addFinishCancelBlock:(AddFinishCancelBlock)addFinishCancelBlock
{
    _photoPathCancelBlock = photoPathCancelBlock;
    _changeFaceCancelBlock = changeFaceCancelBlock;
    _addFinishCancelBlock  = addFinishCancelBlock;
    
        RDRecordViewController *recordVideoVC = [[RDRecordViewController alloc] init];
        recordVideoVC.delegate = view;
        recordVideoVC.captureAsYUV = _cameraConfiguration.captureAsYUV;
        if(_cameraConfiguration.cameraOutputPath.length==0){
            NSString * exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"/recordVideoFile.mp4"];
            _cameraConfiguration.cameraOutputPath = exportPath;
        }
        recordVideoVC.videoPath = _cameraConfiguration.cameraOutputPath;
        recordVideoVC.fps = _cameraConfiguration.cameraFrameRate;
        recordVideoVC.recordSize = CGSizeZero;
        recordVideoVC.bitrate = _cameraConfiguration.cameraBitRate;
        recordVideoVC.cameraPosition = _cameraConfiguration.cameraCaptureDevicePosition;
    
        if(_cameraConfiguration.enableFaceU
           && _cameraConfiguration.enableNetFaceUnity
           && _cameraConfiguration.faceUURL.length>0){
            recordVideoVC.faceUURLString = _cameraConfiguration.faceUURL;
        }else{
            recordVideoVC.faceUURLString = nil;
        }
        recordVideoVC.faceU = _cameraConfiguration.enableFaceU;
        recordVideoVC.needFilter = _cameraConfiguration.enableFilter;
        if(tag == 1) {
            recordVideoVC.recordsizetype = RecordSizeTypeMixed;
            recordVideoVC.recordtype = RecordTypePhoto;
            recordVideoVC.cameraMV = NO;
            recordVideoVC.cameraVideo = NO;
            recordVideoVC.cameraPhoto = YES;
        }else {
            recordVideoVC.recordsizetype =(RecordSizeType)_cameraConfiguration.cameraRecordSizeType;
            recordVideoVC.recordtype = (RecordType)_cameraConfiguration.cameraRecord_Type;
            recordVideoVC.MVRecordMaxDuration =_cameraConfiguration.cameraMV_MaxVideoDuration;
            recordVideoVC.MVRecordMinDuration = _cameraConfiguration.cameraMV_MinVideoDuration;
            recordVideoVC.cameraMV = _cameraConfiguration.cameraMV;
            recordVideoVC.cameraVideo = _cameraConfiguration.cameraVideo;
    
            if(_editConfiguration.supportFileType == ONLYSUPPORT_VIDEO){
                recordVideoVC.cameraPhoto = NO;
            }else {
                recordVideoVC.cameraPhoto = _cameraConfiguration.cameraPhoto;
            }
        }
        recordVideoVC.MAX_VIDEO_DUR_1 = _cameraConfiguration.cameraSquare_MaxVideoDuration;
        recordVideoVC.MAX_VIDEO_DUR_2 = _cameraConfiguration.cameraNotSquare_MaxVideoDuration;
        recordVideoVC.more = NO;
        recordVideoVC.isSquareTop = NO;
    
        switch (_editConfiguration.supportFileType) {
            case SUPPORT_ALL:
                recordVideoVC.isWriteToAlbum = NO;
                break;
            case ONLYSUPPORT_VIDEO:
                recordVideoVC.cameraPhoto = NO;
                recordVideoVC.isWriteToAlbum = NO;
                break;
            case ONLYSUPPORT_IMAGE:
                recordVideoVC.isWriteToAlbum = NO;
    
                break;
            default:
                break;
        }
        if(_cameraConfiguration.cameraRecordSizeType == RecordVideoTypeMixed){
            if(_cameraConfiguration.cameraSquare_MaxVideoDuration>0){
                _cameraConfiguration.cameraMinVideoDuration = MIN(_cameraConfiguration.cameraMinVideoDuration,_cameraConfiguration.cameraSquare_MaxVideoDuration);
            }
    
            if(_cameraConfiguration.cameraNotSquare_MaxVideoDuration>0){
                _cameraConfiguration.cameraMinVideoDuration = MIN(_cameraConfiguration.cameraMinVideoDuration, _cameraConfiguration.cameraNotSquare_MaxVideoDuration);
            }
            recordVideoVC.minRecordDuration = _cameraConfiguration.cameraMinVideoDuration;
    
        }else{
            if(_cameraConfiguration.cameraRecordSizeType == RecordVideoTypeSquare && _cameraConfiguration.cameraSquare_MaxVideoDuration>0){
    
                recordVideoVC.minRecordDuration = MIN(_cameraConfiguration.cameraMinVideoDuration, _cameraConfiguration.cameraSquare_MaxVideoDuration);
    
            }else if(_cameraConfiguration.cameraRecordSizeType == RecordVideoTypeNotSquare && _cameraConfiguration.cameraNotSquare_MaxVideoDuration>0){
    
                recordVideoVC.minRecordDuration = MIN(_cameraConfiguration.cameraMinVideoDuration, _cameraConfiguration.cameraNotSquare_MaxVideoDuration);
            }else{
                recordVideoVC.minRecordDuration = _cameraConfiguration.cameraMinVideoDuration;
            }
        }
        recordVideoVC.hiddenPhotoLib = YES;
        recordVideoVC.recordorientation = self->_cameraConfiguration.cameraRecordOrientation;
        recordVideoVC.enableUseMusic = _cameraConfiguration.enableUseMusic;
        if (recordVideoVC.enableUseMusic) {
            recordVideoVC.musicInfo = (RDMusic *)_cameraConfiguration.musicInfo;
        }
        recordVideoVC.push = YES;
        recordVideoVC.PhotoPathBlock = ^(NSString * _Nullable path) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(self->_photoPathCancelBlock)
                    self->_photoPathCancelBlock(path);
            });
        };
        [recordVideoVC addFinishBlock:^(NSString * _Nullable videoPath, int type,RDMusic *music) {
            if(self->_addFinishCancelBlock)
                self->_addFinishCancelBlock(videoPath,type);
        }];
        [view.navigationController pushViewController:recordVideoVC animated:YES];
}

#pragma mark- 抖音录制
- (void)douYinRecordWithSourceController: (UIViewController*)source
                              recordType: (RDDouYinRecordType)recordType
                           callbackBlock: (RdVERecordCallbackBlock)callbackBlock
                          imagebackBlock: (RdVECallbackBlock)imagebackBlock
                              faileBlock: (RdVEFailBlock)failBlock
                                  cancel: (RdVECancelBlock)cancelBlock
{
    if(_cameraConfiguration.cameraOutputPath.length==0){
        NSDictionary *userInfo= [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"请设置拍摄视频的输出路径", nil),@"message", nil];
        NSError *error = [NSError errorWithDomain:RDUISDKCustomErrorDomain code:RDUISDKErrorCode_NillOutputPath userInfo:userInfo];
        
        NSLog(@"error:%@",error);
        failBlock(error);
        return;
    }
    RDNavigationViewController* nav;
    WeakSelf(self);
    if (recordType == RDDouYinRecordType_Story) {
        RDStoryRecordViewController *storyVC = [[RDStoryRecordViewController alloc] init];
        storyVC.recordCompletionBlock = ^(NSString *outputPath) {
            if (outputPath.length > 0) {
                callbackBlock(0, outputPath, nil);
            }
        };
        storyVC.shootPhotoCompletionBlock = ^(NSString *photoPath) {
            imagebackBlock(photoPath);
        };
        storyVC.cancelBlock = ^(BOOL isEnterAlbum, UIViewController *viewController) {
            StrongSelf(self);
            if(isEnterAlbum){
                [viewController dismissViewControllerAnimated:strongSelf.editConfiguration.dissmissAnimated completion:nil];
                if(strongSelf.cameraConfiguration.cameraEnterPhotoAlbumCallblackBlock)
                    strongSelf.cameraConfiguration.cameraEnterPhotoAlbumCallblackBlock(strongSelf);
            }else{
                [viewController dismissViewControllerAnimated:strongSelf.editConfiguration.dissmissAnimated completion:nil];
                cancelBlock();
            }
        };
        nav = [[RDNavigationViewController alloc] initWithRootViewController:storyVC];
    }else {
        RDDyRecordViewController *dyRecordVC = [[RDDyRecordViewController alloc] init];
        dyRecordVC.recordCompletionBlock = ^(NSString *outputPath) {
            if (outputPath.length > 0) {
                callbackBlock(0, outputPath, nil);
            }
        };
        dyRecordVC.shootPhotoCompletionBlock = ^(NSString *photoPath) {
            imagebackBlock(photoPath);
        };
        dyRecordVC.cancelBlock = ^(BOOL isEnterAlbum, UIViewController *viewController) {
            StrongSelf(self);
            if(isEnterAlbum){
                [viewController dismissViewControllerAnimated:strongSelf.editConfiguration.dissmissAnimated completion:nil];
                if(strongSelf.cameraConfiguration.cameraEnterPhotoAlbumCallblackBlock)
                    strongSelf.cameraConfiguration.cameraEnterPhotoAlbumCallblackBlock(strongSelf);
            }else{
                [viewController dismissViewControllerAnimated:strongSelf.editConfiguration.dissmissAnimated completion:nil];
                cancelBlock();
            }
        };
        nav = [[RDNavigationViewController alloc] initWithRootViewController:dyRecordVC];
    }
    nav.appKey = _appkey;
    nav.licenceKey = _licenceKey;
    nav.appSecret = _appsecret;
    nav.edit_functionLists = [self getEdit_FuncationLists];
    nav.editConfiguration = _editConfiguration;
    nav.cameraConfiguration = _cameraConfiguration;
    nav.exportConfiguration = _exportConfiguration;
    nav.navigationBarHidden = YES;
    [source presentViewController:nav animated:YES completion:nil];
}

#pragma mark - 字说界面
- (void)aeTextAnimateWithSuperViewController:(UIViewController *)viewController
                              outputPath:(NSString *)outputVideoPath
                                callback:(RdVECallbackBlock)callbackBlock
                                  cancel:(RdVECancelBlock)cancelBlock
{
    [self setCameraConfigurationSetting:nil];
    if(_deviceOrientation == UIInterfaceOrientationUnknown){
        _deviceOrientation = UIInterfaceOrientationPortrait;
    }
    BOOL suc = [RDHelpClass createSaveTmpFileFolder];
    if(!suc){
        return;
    }
    RDNavigationViewController *nav;
    RDTextToSpeechViewController *textAnimateVC = [[RDTextToSpeechViewController alloc] init];
    textAnimateVC.cancelBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            cancelBlock();
        });
    };
    nav = [[RDNavigationViewController alloc] initWithRootViewController:textAnimateVC];
    nav.statusBarHidden   = [UIApplication sharedApplication].statusBarHidden;
    nav.rdVeUiSdkDelegate = _delegate;
    nav.appKey            = _appkey;
    nav.licenceKey        = _licenceKey;
    nav.appSecret         = _appsecret;
    nav.outPath           = outputVideoPath;
    nav.callbackBlock     = ^(NSString * videoPath){
        dispatch_async(dispatch_get_main_queue(), ^{
            callbackBlock(videoPath);
        });
        
    };
    nav.editConfiguration.supportFileType = _editConfiguration.supportFileType;
    nav.videoAverageBitRate            = _exportConfiguration.videoBitRate;
    nav.edit_functionLists         = [self getEdit_FuncationLists];
    nav.editConfiguration          = _editConfiguration;
    nav.cameraConfiguration        = _cameraConfiguration;
    nav.exportConfiguration        = _exportConfiguration;
    
    [self presentViewController:viewController nav:nav];
}

#pragma mark - 字说
- (void)aeTextAnimateWithSuperController:(UIViewController *)viewController
                              outputPath:(NSString *)outputVideoPath
                                callback:(RdVECallbackBlock)callbackBlock
                                  cancel:(RdVECancelBlock)cancelBlock
{
    [self setCameraConfigurationSetting:nil];
    if(_deviceOrientation == UIInterfaceOrientationUnknown){
        _deviceOrientation = UIInterfaceOrientationPortrait;
    }
    BOOL suc = [RDHelpClass createSaveTmpFileFolder];
    if(!suc){
        return;
    }
    RDNavigationViewController *nav;
    RDTextAnimateViewController *textAnimateVC = [[RDTextAnimateViewController alloc] init];
    textAnimateVC.cancelBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            cancelBlock();
        });
    };
    nav = [[RDNavigationViewController alloc] initWithRootViewController:textAnimateVC];
    nav.statusBarHidden   = [UIApplication sharedApplication].statusBarHidden;
    nav.rdVeUiSdkDelegate = _delegate;
    nav.appKey            = _appkey;
    nav.licenceKey        = _licenceKey;
    nav.appSecret         = _appsecret;
    nav.outPath           = outputVideoPath;
    nav.callbackBlock     = ^(NSString * videoPath){
        dispatch_async(dispatch_get_main_queue(), ^{
            callbackBlock(videoPath);
        });
        
    };
    nav.editConfiguration.supportFileType = _editConfiguration.supportFileType;
    nav.videoAverageBitRate            = _exportConfiguration.videoBitRate;
    nav.edit_functionLists         = [self getEdit_FuncationLists];
    nav.editConfiguration          = _editConfiguration;
    nav.cameraConfiguration        = _cameraConfiguration;
    nav.exportConfiguration        = _exportConfiguration;
    
    [self presentViewController:viewController nav:nav];
}

#pragma mark - 自绘
- (void)customDrawWithSuperController:(UIViewController *)viewController
                           outputPath:(NSString *)outputVideoPath
                             callback:(RdVECallbackBlock )callbackBlock
                               cancel:(RdVECancelBlock )cancelBlock
{
    RDCustomDrawViewController *customDrawVC = [[RDCustomDrawViewController alloc] init];
    customDrawVC.cancelBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            cancelBlock();
        });
    };
    RDNavigationViewController *nav = [[RDNavigationViewController alloc] initWithRootViewController:customDrawVC];
    nav.statusBarHidden   = [UIApplication sharedApplication].statusBarHidden;
    nav.rdVeUiSdkDelegate = _delegate;
    nav.appKey            = _appkey;
    nav.licenceKey        = _licenceKey;
    nav.appSecret         = _appsecret;
    nav.outPath           = outputVideoPath;
    nav.callbackBlock     = ^(NSString * videoPath){
        dispatch_async(dispatch_get_main_queue(), ^{
            callbackBlock(videoPath);
        });
    };
    nav.editConfiguration.supportFileType = _editConfiguration.supportFileType;
    nav.videoAverageBitRate            = _exportConfiguration.videoBitRate;
    nav.editConfiguration          = _editConfiguration;
    nav.cameraConfiguration        = _cameraConfiguration;
    nav.exportConfiguration        = _exportConfiguration;
    
    [self presentViewController:viewController nav:nav];
}

#pragma mark - SmallFunctions
- (void)singleMediaWithSuperController:(UIViewController *)viewController
                          functionType:(RDSingleFunctionType)functionType
                            outputPath:(NSString *)outputVideoPath
                              urlArray:(NSMutableArray <NSURL *>*)urlArray
                              callback:(RdVECallbackBlock)callbackBlock
                                cancel:(RdVECancelBlock)cancelBlock
{
    if (!urlArray || urlArray.count == 0) {
        cancelBlock();
        return;
    }
    NSMutableArray *fileArray = [NSMutableArray array];
    for (NSURL *url in urlArray) {
        RDFile *file = [RDFile new];
        file.contentURL = url;
        if([RDHelpClass isImageUrl:url]){
            //图片
            file.fileType = kFILEIMAGE;
            file.imageDurationTime = CMTimeMakeWithSeconds(3, TIMESCALE);
            file.speedIndex = 1;
        }else{
            //视频
            file.fileType = kFILEVIDEO;
            AVURLAsset * asset = [AVURLAsset assetWithURL:file.contentURL];
            CMTime duration = asset.duration;
            file.videoDurationTime = duration;
            file.videoTimeRange = CMTimeRangeMake(kCMTimeZero,file.videoDurationTime);
            file.reverseVideoTimeRange = file.videoTimeRange;
            file.speedIndex = 2;
        }
        file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
        [fileArray addObject:file];
    }
    
    RDNavigationViewController *nav;
    switch (functionType) {
        case RDSingleFunctionType_Transcoding:
        {
            RDCompressViewController *compressVC = [[RDCompressViewController alloc] init];
            compressVC.file = [fileArray firstObject];
            nav = [[RDNavigationViewController alloc] initWithRootViewController:compressVC];
        }
            break;
        case RDSingleFunctionType_Reverse:
        {
            RDReverseViewController *reverseVC = [[RDReverseViewController alloc] init];
            reverseVC.file = [fileArray firstObject];
            nav = [[RDNavigationViewController alloc] initWithRootViewController:reverseVC];
        }
            break;
        case RDSingleFunctionType_Crop:
        {
            CropViewController *cropVC = [[CropViewController alloc] init];
            cropVC.selectFile = [fileArray firstObject];
            cropVC.presentModel = YES;
            nav = [[RDNavigationViewController alloc] initWithRootViewController:cropVC];
        }
            break;
        case RDSingleFunctionType_Intercept:
        {
            RDTrimVideoViewController *trimVideoVC = [[RDTrimVideoViewController alloc] init];
            trimVideoVC.trimFile = [fileArray firstObject];
            trimVideoVC.outputFilePath = outputVideoPath;
            nav = [[RDNavigationViewController alloc] initWithRootViewController:trimVideoVC];
        }
            break;
        case RDSingleFunctionType_Transition:
        {
            RDTransitionViewController *transitionVC = [[RDTransitionViewController alloc] init];
            transitionVC.fileList = fileArray;
            nav = [[RDNavigationViewController alloc] initWithRootViewController:transitionVC];
        }
            break;
        case RDSingleFunctionType_Adjust:
        {
            RDAdjustViewController *adjustVC = [[RDAdjustViewController alloc] init];
            adjustVC.file = [fileArray firstObject];
            nav = [[RDNavigationViewController alloc] initWithRootViewController:adjustVC];
        }
            break;
        case RDSingleFunctionType_Speed:
        {
            ChangeSpeedVideoViewController *speedVC = [[ChangeSpeedVideoViewController alloc] init];
            speedVC.selectFile = [fileArray firstObject];
            nav = [[RDNavigationViewController alloc] initWithRootViewController:speedVC];
        }
            break;
        case RDSingleFunctionType_VoiceFX:
        {
            RDVoiceFXViewController *voiceFXVC = [[RDVoiceFXViewController alloc] init];
            voiceFXVC.file = [fileArray firstObject];
            nav = [[RDNavigationViewController alloc] initWithRootViewController:voiceFXVC];
        }
            break;
        case RDSingleFunctionType_Dubbing:
        {
            RDDubViewController *dubVC = [[RDDubViewController alloc] init];
            dubVC.file = [fileArray firstObject];
            nav = [[RDNavigationViewController alloc] initWithRootViewController:dubVC];
        }
            break;
        case RDSingleFunctionType_ClipEditing:
        {
            RDEditVideoViewController *clipEditVC = [[RDEditVideoViewController alloc] init];
            clipEditVC.fileList = fileArray;
            clipEditVC.isVague = YES;
            clipEditVC.cancelBlock = ^(){
                dispatch_async(dispatch_get_main_queue(), ^{
                    cancelBlock();
                });
            };
            nav = [[RDNavigationViewController alloc] initWithRootViewController:clipEditVC];
            nav.edit_functionLists = [self getEdit_FuncationLists];
        }
            break;
        case RDSingleFunctionType_Cover:
        {
            RDCoverViewController *coverVC = [[RDCoverViewController alloc] init];
            coverVC.file = [fileArray firstObject];
            nav = [[RDNavigationViewController alloc] initWithRootViewController:coverVC];
        }
            break;
        case RDSingleFunctionType_Effect:
        {
            RDSpecialEffectsViewController *coverVC = [[RDSpecialEffectsViewController alloc] init];
            coverVC.file = [fileArray firstObject];
            nav = [[RDNavigationViewController alloc] initWithRootViewController:coverVC];
        }
            break;
        case RDSingleFunctionType_Filter:
        {
            RDFilterViewController *coverVC = [[RDFilterViewController alloc] init];
            coverVC.file = [fileArray firstObject];
            nav = [[RDNavigationViewController alloc] initWithRootViewController:coverVC];
        }
            break;
        case RDSingleFunctionType_Sticker:
        {
            RDStickerViewController *coverVC = [[RDStickerViewController alloc] init];
            coverVC.file = [fileArray firstObject];
            nav = [[RDNavigationViewController alloc] initWithRootViewController:coverVC];
        }
            break;
        case RDSingleFunctionType_Caption:
        {
            RDSubtitleViewController *coverVC = [[RDSubtitleViewController alloc] init];
            coverVC.file = [fileArray firstObject];
            nav = [[RDNavigationViewController alloc] initWithRootViewController:coverVC];
        }
            break;
        case RDSingleFunctionType_Dewatermark:
        {
            RDDewatermarkViewController *coverVC = [[RDDewatermarkViewController alloc] init];
            coverVC.file = [fileArray firstObject];
            nav = [[RDNavigationViewController alloc] initWithRootViewController:coverVC];
        }
            break;
        case RDSingleFunctionType_Doodle:
        {
            RDDoodleViewController *coverVC = [[RDDoodleViewController alloc] init];
            coverVC.file = [fileArray firstObject];
            nav = [[RDNavigationViewController alloc] initWithRootViewController:coverVC];
        }
            break;
        case RDSingleFunctionType_Collage:
        {
            RDCollageViewController *coverVC = [[RDCollageViewController alloc] init];
            coverVC.file = [fileArray firstObject];
            nav = [[RDNavigationViewController alloc] initWithRootViewController:coverVC];
            
//            RDExtractAudioViewController *coverVC = [[RDExtractAudioViewController alloc] init];
//            coverVC.file = [fileArray firstObject];
//            nav = [[RDNavigationViewController alloc] initWithRootViewController:coverVC];
        }
            break;
        case RDSingleFunctionType_Compress:
        {
            RDCompressVideoViewController *coverVC = [[RDCompressVideoViewController alloc] init];
            coverVC.file = [fileArray firstObject];
            nav = [[RDNavigationViewController alloc] initWithRootViewController:coverVC];
        }
            break;
        default:
            break;
    }
    
    if (!nav) {
        cancelBlock();
        return;
    }
    if (functionType != RDSingleFunctionType_ClipEditing) {
        nav.isSingleFunc = YES;
    }    
    nav.statusBarHidden   = [UIApplication sharedApplication].statusBarHidden;
    nav.rdVeUiSdkDelegate = _delegate;
    nav.appKey            = _appkey;
    nav.licenceKey        = _licenceKey;
    nav.appSecret         = _appsecret;
    nav.outPath           = outputVideoPath;
    nav.callbackBlock     = ^(NSString * videoPath){
        callbackBlock(videoPath);
    };
    nav.cancelHandler = ^{
        cancelBlock();
    };
    nav.editConfiguration.supportFileType = _editConfiguration.supportFileType;
    nav.videoAverageBitRate            = _exportConfiguration.videoBitRate;
    nav.editConfiguration          = _editConfiguration;
    nav.cameraConfiguration        = _cameraConfiguration;
    nav.exportConfiguration        = _exportConfiguration;
    
    [self presentViewController:viewController nav:nav];
}

#pragma mark- 压缩
- (NSDictionary *) getVideoInformation:(AVURLAsset *)urlAsset
{
    AVAssetTrack *videoTrack = nil;
    
    NSArray *videoTracks = [urlAsset tracksWithMediaType:AVMediaTypeVideo];
    
    if ([videoTracks count] > 0)
        videoTrack = [videoTracks objectAtIndex:0];
    
    CGSize trackDimensions = [videoTrack naturalSize];
    if (CGSizeEqualToSize(trackDimensions, CGSizeZero) || trackDimensions.width == 0.0 || trackDimensions.height == 0.0) {
        NSArray * formatDescriptions = [videoTrack formatDescriptions];
        CMFormatDescriptionRef formatDescription = NULL;
        if ([formatDescriptions count] > 0) {
            formatDescription = (__bridge CMFormatDescriptionRef)[formatDescriptions objectAtIndex:0];
            if (formatDescription) {
                trackDimensions = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, false, false);
            }
        }
    }
    
    int width = trackDimensions.width;
    int height = trackDimensions.height;
    
    float frameRate = [videoTrack nominalFrameRate];
    float bps = [videoTrack estimatedDataRate];
    
    return @{
             @"width":@(width),
             @"height":@(height),
             @"fps":@(frameRate),
             @"bitrate":@(bps)};
    
}
- (void) compressCancel
{
    [_compressVECore cancelExportMovie:nil];
    _compressVECore = nil;
}

- (void)compressVideoAsset:(AVURLAsset *)urlAsset
                outputPath:(NSString *)outputPath
                 startTime:(CMTime )startTime
                   endTime:(CMTime )endTime
                outputSize:(CGSize) size
             outputBitrate:(float) bitrate
                supperView:(UIViewController *)supperView
             progressBlock:(void (^)(float progress))progressBlock
             callbackBlock:(void (^)(NSString *videoPath))callbackBlock
                      fail:(void (^)(NSError *error))failBlock
{
     _compressVECore= [[RDVECore alloc] initWithAPPKey:_appkey APPSecret:_appsecret LicenceKey:_licenceKey videoSize:size fps:30 resultFail:^(NSError *error) {
        if(error){
            [self compressCancel];
            failBlock(error);
        }
    }];
    
    
    
    NSMutableArray *scenes = [NSMutableArray array];
    RDScene *scene = [[RDScene alloc] init];
    
    VVAsset* vvasset = [[VVAsset alloc] init];
    vvasset.url = urlAsset.URL;    
    vvasset.type = RDAssetTypeVideo;
    vvasset.timeRange = CMTimeRangeMake(startTime, CMTimeSubtract(endTime, startTime));
    if(CMTimeGetSeconds(vvasset.timeRange.duration) == 0){
        vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, urlAsset.duration);
    }
    NSLog(@"timeRange : %f : %f ",CMTimeGetSeconds(vvasset.timeRange.start),CMTimeGetSeconds(vvasset.timeRange.duration));
    vvasset.speed        = 1;
    vvasset.volume = 1.0;
    vvasset.rotate = 0;
    vvasset.isVerticalMirror = NO;
    vvasset.isHorizontalMirror = NO;
    vvasset.crop = CGRectZero;
    [scene.vvAsset addObject:vvasset];
    [scenes addObject:scene];
    
    _compressVECore.frame = CGRectMake(0, 0, size.width, size.height);
    _compressVECore.view.frame = CGRectMake(0, 0, size.width, size.height);
    [_compressVECore setEditorVideoSize:size];
    [_compressVECore setScenes:scenes];
    
    [_compressVECore build];
    //是否添加水印
    if(!_exportConfiguration.waterDisabled){
        if(_exportConfiguration.waterImage){
            [_compressVECore addWaterMark:_exportConfiguration.waterImage withPoint:CGPointMake(1, 0) scale:1];
        }
        if(_exportConfiguration.waterText){
            [_compressVECore addWaterMark:_exportConfiguration.waterText color:nil font:nil withPoint:CGPointMake(1, 0)];
        }
    }
    //是否添加片尾
    if(!_exportConfiguration.endPicDisabled){
        
        [_compressVECore addEndLogoMark:[UIImage imageWithContentsOfFile:_exportConfiguration.endPicImagepath] userName:_exportConfiguration.endPicUserName showDuration:_exportConfiguration.endPicDuration fadeDuration:_exportConfiguration.endPicFadeDuration];
        
    }
    

    [_compressVECore exportMovieURL:[NSURL fileURLWithPath:outputPath]
                               size:size
                            bitrate:bitrate
                                fps:30
                       audioBitRate:0
                audioChannelNumbers:1
             maxExportVideoDuration:_exportConfiguration.outputVideoMaxDuration
                           progress:progressBlock success:^{
        if(callbackBlock){
            callbackBlock(outputPath);
        }
    } fail:failBlock];
    
}

#pragma mark - 不规则媒体
- (void)shapedAssetWithSuperController:(UIViewController *)viewController
                              assetUrl:(NSURL *)assetUrl
                            outputPath:(NSString *)outputVideoPath
                              callback:(RdVECallbackBlock )callbackBlock
                                cancel:(RdVECancelBlock )cancelBlock
{
    [self setCameraConfigurationSetting:nil];
    if(_deviceOrientation == UIInterfaceOrientationUnknown){
        _deviceOrientation = UIInterfaceOrientationPortrait;
    }
    BOOL suc = [RDHelpClass createSaveTmpFileFolder];
    if(!suc){
        return;
    }
    ShapedAssetViewController *shapedAssetVC = [[ShapedAssetViewController alloc] init];
    shapedAssetVC.assetURL = assetUrl;
    shapedAssetVC.cancelBlock = ^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            cancelBlock();
        });
    };
    RDNavigationViewController *nav = [[RDNavigationViewController alloc] initWithRootViewController:shapedAssetVC];
    nav.statusBarHidden   = [UIApplication sharedApplication].statusBarHidden;
    nav.rdVeUiSdkDelegate = _delegate;
    nav.appKey            = _appkey;
    nav.licenceKey        = _licenceKey;
    nav.appSecret         = _appsecret;
    nav.outPath           = outputVideoPath;
    nav.callbackBlock     = ^(NSString * videoPath){
        dispatch_async(dispatch_get_main_queue(), ^{
            callbackBlock(videoPath);
        });
    };
    nav.editConfiguration.supportFileType = _editConfiguration.supportFileType;
    nav.videoAverageBitRate            = _exportConfiguration.videoBitRate;
    nav.edit_functionLists         = [self getEdit_FuncationLists];
    nav.editConfiguration          = _editConfiguration;
    nav.cameraConfiguration        = _cameraConfiguration;
    nav.exportConfiguration        = _exportConfiguration;
    
    [self presentViewController:viewController nav:nav];
}
#pragma mark-

- (NSMutableArray *)getEdit_FuncationLists{
    
    
    NSMutableArray *list = [[NSMutableArray alloc] init];
    
    //转场
    if(_editConfiguration.enableTransition)
        [list addObject:@(KTRANSITION)];
    //替换
    if(_editConfiguration.enableReplace)
        [list addObject:@(KREPLACE)];
    //截取
    if(_editConfiguration.enableTrim){
        [list addObject:@(kRDTRIM)];
    }
    //分割
    if(_editConfiguration.enableSplit){
        [list addObject:@(kRDSPLIT)];
    }
    //滤镜
    if (_editConfiguration.enableSingleMediaFilter) {
        [list addObject:@(kRDSINGLEFILTER)];
    }
    //调色
    if(_editConfiguration.enableSingleMediaAdjust ){
        [list addObject:@(KRDADJUST)];
    }
    //变速
    if(_editConfiguration.enableSpeedcontrol){
        [list addObject:@(kRDCHANGESPEED)];
    }
    if (_editConfiguration.enableImageDurationControl) {
        [list addObject:@(kRDCHANGEDURATION)];
    }
    //音量
    if (_editConfiguration.enableVolume) {
        [list addObject:@(KVOLUME)];
    }
    //美颜
    if (_editConfiguration.enableBeauty) {
        [list addObject:@(KBEAUTY)];
    }
    //动画
    if (_editConfiguration.enableAnimation) {
        [list addObject:@(KRDANIMATION)];
    }
    //透明度
    if (_editConfiguration.enableTransparency
        ) {
        [list addObject:@(KTRANSPARENCY)];
    }
    //复制
    if(_editConfiguration.enableCopy){
        [list addObject:@(kRDCOPY)];
    }
    //倒放
    if(_editConfiguration.enableReverseVideo){
        [list addObject:@(kRDREVERSEVIDEO)];
    }
    //裁切
    if(_editConfiguration.enableEdit){
        [list addObject:@(kRDEDIT)];
    }
    //旋转
    if(_editConfiguration.enableRotate)
        [list addObject:@(KROTATE)];
    //镜像
    if(_editConfiguration.enableMirror)
        [list addObject:@(KMIRROR)];
    //上下翻转
    if(_editConfiguration.enableFlipUpAndDown)
        [list addObject:@(KFLIPUPANDDOWN)];
    
    
    //文字版
    if(_editConfiguration.enableTextTitle)
    [list addObject:@(kRDTEXTTITLE)];
    
    //调序
    if(_editConfiguration.enableSort){
        [list addObject:@(kRDSORT)];
    }
    //特效
    if(_editConfiguration.enableSingleSpecialEffects ){
        [list addObject:@(KRDEFFECTS)];
    }

    if(_editConfiguration.enableWizard){
        if(!_editConfiguration.enableFragmentedit){
            return nil;
        }
    }
    return list;
}

/*
 跳转到选择相册界面
 */
- (void)presentViewController:(UIViewController *)superVC nav:(RDNavigationViewController *)nav{
    [superVC presentViewController:nav animated:(_editConfiguration.presentAnimated ? YES : NO) completion:nil];
}

- (void)dealloc{
    NSLog(@"%s",__func__);
//    _editConfiguration.mvResourceURL = nil;
//    _editConfiguration.musicResourceURL = nil;
//    _editConfiguration.cloudMusicResourceURL = nil;
    _editConfiguration.clickAlbumCameraBlackBlock = nil;
    _cameraConfiguration.cameraOutputPath = nil;
    _exportConfiguration.waterText = nil;
    _exportConfiguration.waterImage = nil;
    _addVideosAndImagesCallbackBlock = nil;
    _addVideosCallbackBlock = nil;
    _addImagesCallbackBlock = nil;
    _compressVECore = nil;
    _cameraConfiguration = nil;
    _exportConfiguration = nil;
    
    
}

#pragma mark- RDRecordViewDelegate
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (_delegate && [_delegate respondsToSelector:@selector(willOutputCameraSampleBuffer:)]) {
        [_delegate willOutputCameraSampleBuffer:sampleBuffer];
    }
}

/**改变需要播放的音乐
 */
- (void)changeMusicResult:(UINavigationController *)nav CompletionHandler:(void (^)(RDMusic * _Nullable))handler{
    if(_editConfiguration.cloudMusicResourceURL){
        RDCloudMusicViewController  *cloudMusic = [[RDCloudMusicViewController alloc] init];
        cloudMusic.selectedIndex = 0;
        cloudMusic.cloudMusicResourceURL = _editConfiguration.cloudMusicResourceURL;
        cloudMusic.selectCloudMusic = ^(RDMusic *music) {
            handler(music);
        };
        [nav pushViewController:cloudMusic animated:YES];
    }else{
        RDLocalMusicViewController *localmusic = [[RDLocalMusicViewController alloc] init];
        localmusic.selectLocalMusicBlock = ^(RDMusic *music){
            handler(music);
        };
        [nav pushViewController:localmusic animated:YES];
    }
}

- (NSString *) appVersion
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
}

+ (NSString *) build
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
}

- (void) setUpAndAddAudioAtPath:(NSURL*)assetURL toComposition:(AVMutableComposition *)composition start:(CMTime)start dura:(CMTime)dura offset:(CMTime)offset  audioMixParams:(NSMutableArray *)audioMixParams{
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil ];
    
    AVMutableCompositionTrack *track = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *sourceAudioTrack;
    @try {
        sourceAudioTrack = [[songAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        
    } @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    } @finally {
        NSError *error = nil;
        BOOL ok = NO;
        
        CMTime startTime = start;
        CMTime trackDuration = dura;
        CMTimeRange tRange = CMTimeRangeMake(startTime, trackDuration);
        
        //Set Volume
        AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
        [trackMix setVolume:1.0f atTime:startTime];
        [audioMixParams addObject:trackMix];
        
        //Insert audio into track  //offset CMTimeMake(0, 44100)
        ok = [track insertTimeRange:tRange ofTrack:sourceAudioTrack atTime:offset error:&error];
    }
}

- (void)setRandomTransition:(NSMutableArray <RDFile *> *) fileList
{
    NSMutableArray *transitionArray = [RDHelpClass getTransitionArray];
    NSMutableArray *transitionList = [NSMutableArray array];
    [transitionArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [transitionList addObjectsFromArray:obj[@"data"]];
    }];
    [fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger index = arc4random()%(transitionList.count);
        NSString *transitionName = transitionList[index];
        if ([transitionName pathExtension]) {
            transitionName = [transitionName stringByDeletingPathExtension];
        }
        __block NSString *typeName = kDefaultTransitionTypeName;
        [transitionArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj[@"data"] enumerateObjectsUsingBlock:^(id  _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
                if ([obj1 isEqualToString:transitionName]) {
                    typeName = obj[@"typeName"];
                    *stop1 = YES;
                    *stop = YES;
                }
            }];
        }];
        NSString *maskpath = [RDHelpClass getTransitionPath:typeName itemName:transitionName];
        NSURL *maskUrl = maskpath.length == 0 ? nil : [NSURL fileURLWithPath:maskpath];
        if(obj.fileType == kFILEVIDEO)
        {
            float ftime = CMTimeGetSeconds(obj.videoTimeRange.duration)/2.0;
            obj.transitionDuration = (ftime < 1.0) ? ftime : 1.0;
        }
        else {
            obj.transitionDuration = 1.0;
        }
        obj.transitionMask = maskUrl;
        obj.transitionTypeName = typeName;
        obj.transitionName = transitionName;
    }];
}

#pragma mark-视频截取
+(void)Intercept:(UIViewController *)weakSelf atFile:(NSObject *)file atUINavigationController:(UINavigationController *) nav atTrimAndRotateVideoFinishBlock:(TrimAndRotateVideoFinishBlock) trimAndRotateVideoFinishBlock
{
    RDTrimVideoViewController *trimVideoVC = [[RDTrimVideoViewController alloc] init];
    trimVideoVC.isRotateEnable = YES;
    trimVideoVC.trimFile = [(RDFile*)file copy];
    trimVideoVC.TrimAndRotateVideoFinishBlock =  trimAndRotateVideoFinishBlock;
    RDNavigationViewController *nav1 = [[RDNavigationViewController alloc] initWithRootViewController:trimVideoVC];
    nav1.edit_functionLists = ((RDNavigationViewController *)nav).edit_functionLists;
    nav1.exportConfiguration = ((RDNavigationViewController *)nav).exportConfiguration;
    nav1.editConfiguration = ((RDNavigationViewController *)nav).editConfiguration;
    nav1.cameraConfiguration = ((RDNavigationViewController *)nav).cameraConfiguration;
    nav1.outPath = ((RDNavigationViewController *)nav).outPath;
    nav1.appAlbumCacheName = ((RDNavigationViewController *)nav).appAlbumCacheName;
    nav1.appKey = ((RDNavigationViewController *)nav).appKey;
    nav1.appSecret = ((RDNavigationViewController *)nav).appSecret;
    nav1.statusBarHidden = ((RDNavigationViewController *)nav).statusBarHidden;
    nav1.folderType = ((RDNavigationViewController *)nav).folderType;
    nav1.videoAverageBitRate = ((RDNavigationViewController *)nav).videoAverageBitRate;
    nav1.waterLayerRect = ((RDNavigationViewController *)nav).waterLayerRect;
    nav1.callbackBlock = ((RDNavigationViewController *)nav).callbackBlock;
    nav1.rdVeUiSdkDelegate = ((RDNavigationViewController *)nav).rdVeUiSdkDelegate;
    [weakSelf presentViewController:nav1 animated:YES completion:nil];
}
#pragma mark-图片裁剪
+( void ) Tailoring:(UIViewController *)weakSelf atFile:(NSObject *)file atUINavigationController:(UINavigationController *) nav atTrimAndRotateVideoFinishBlock:(EditVideoForOnceFinishAction) editVideoForOnceFinishAction{
    CropViewController *cropVC = [[CropViewController alloc] init];
    cropVC.selectFile       = [(RDFile*)file copy];
    cropVC.isOnlyRotate = YES;
    cropVC.presentModel = YES;
    cropVC.editVideoForOnceFinishAction = ^(CGRect crop, CGRect cropRect, BOOL verticalMirror, BOOL horizontalMirror, float rotate, FileCropModeType cropModeType) {
        if( editVideoForOnceFinishAction )
            editVideoForOnceFinishAction(crop,cropRect,verticalMirror,horizontalMirror,rotate,(int)cropModeType);
    };
    RDNavigationViewController *nav1 = [[RDNavigationViewController alloc] initWithRootViewController:cropVC];
    nav1.edit_functionLists = ((RDNavigationViewController *)nav).edit_functionLists;
    nav1.exportConfiguration = ((RDNavigationViewController *)nav).exportConfiguration;
    nav1.editConfiguration = ((RDNavigationViewController *)nav).editConfiguration;
    nav1.cameraConfiguration = ((RDNavigationViewController *)nav).cameraConfiguration;
    nav1.outPath = ((RDNavigationViewController *)nav).outPath;
    nav1.appAlbumCacheName = ((RDNavigationViewController *)nav).appAlbumCacheName;
    nav1.appKey = ((RDNavigationViewController *)nav).appKey;
    nav1.appSecret = ((RDNavigationViewController *)nav).appSecret;
    nav1.statusBarHidden = ((RDNavigationViewController *)nav).statusBarHidden;
    nav1.folderType = ((RDNavigationViewController *)nav).folderType;
    nav1.videoAverageBitRate = ((RDNavigationViewController *)nav).videoAverageBitRate;
    nav1.waterLayerRect = ((RDNavigationViewController *)nav).waterLayerRect;
    nav1.callbackBlock = ((RDNavigationViewController *)nav).callbackBlock;
    nav1.rdVeUiSdkDelegate = ((RDNavigationViewController *)nav).rdVeUiSdkDelegate;
    [weakSelf presentViewController:nav1 animated:YES completion:nil];
}
#pragma mark-相册编辑界面
+(void)enterNext:(BOOL) isEnableWizard atFileArray:(NSMutableArray *) FileArray atNavigationController:(UINavigationController *)NavigationController
{
    if(isEnableWizard){
        RDEditVideoViewController *editVideoVC = [[RDEditVideoViewController alloc] init];
        editVideoVC.fileList = FileArray;
        editVideoVC.isVague = YES;
        editVideoVC.musicVolume = 0.5;
        editVideoVC.push = YES;
        [NavigationController pushViewController:editVideoVC animated:YES];
        
    }else{
        RDNextEditVideoViewController *nextEditVideoVC = [[RDNextEditVideoViewController alloc] init];
        nextEditVideoVC.fileList        = FileArray;
        nextEditVideoVC.musicVolume     = 0.5;
        
        if(((RDNavigationViewController *)NavigationController).editConfiguration.proportionType == RDPROPORTIONTYPE_LANDSCAPE){
            nextEditVideoVC.exportVideoSize       = CGSizeMake(MAX(kVIDEOWIDTH, kVIDEOHEIGHT), MIN(kVIDEOWIDTH, kVIDEOHEIGHT));
        }
        else if(((RDNavigationViewController *)NavigationController).editConfiguration.proportionType == RDPROPORTIONTYPE_SQUARE){
            nextEditVideoVC.exportVideoSize       = CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
        }else{
            nextEditVideoVC.exportVideoSize       = CGSizeZero;
        }
        
        [NavigationController pushViewController:nextEditVideoVC animated:YES];
    }
}
/** 从视频中提取音频
 *params: type                  输出音频类型，目前支持三种（AVFileTypeMPEGLayer3，AVFileTypeAppleM4A，AVFileTypeWAVE）
 *params: videoUrl              视频源地址
 *params: trimStart             从原始视频截取的开始时间 单位：秒 默认 0
 *params: duration              截取的持续时间 默认视频原始时长
 *params: outputFolder          输出文件存放的文件夹路径
 *params: samplerate            输出采样率
 *params: completionHandle      导出回调
 */
+ (void)video2audiowithtype:(AVFileType)type
                   videoUrl:(NSURL*)videoUrl
                  trimStart:(float)start
                   duration:(float)duration
           outputFolderPath:(NSString*)outputFolder
                 samplerate:(int )samplerate
                 completion:(void(^)(BOOL result,NSString*outputFilePath))completionHandle{
    [RDVECore video2audiowithtype:(AVFileType)type
                         videoUrl:videoUrl
                        trimStart:start
                         duration:duration
                 outputFolderPath:outputFolder
                       samplerate:samplerate
                       completion:completionHandle];
}
- (void)video2audiowithtype:(UIViewController *)viewController
               atAVFileType:(AVFileType)type
                   videoUrl:(NSURL*)videoUrl
           outputFolderPath:(NSString*)outputFolder
                 samplerate:(int )samplerate
                   callback:(RdVECallbackBlock )callbackBlock
                     cancel:(RdVECancelBlock )cancelBlock
{
    
    RDFile *file = [RDFile new];
    file.contentURL = videoUrl;
    file.fileType = kFILEVIDEO;
    file.isReverse = NO;
    AVURLAsset * asset = [AVURLAsset assetWithURL:file.contentURL];
    CMTime duration1 = asset.duration;
    file.videoDurationTime = duration1;
    file.videoTimeRange = CMTimeRangeMake(kCMTimeZero,file.videoDurationTime);
    file.reverseVideoTimeRange = file.videoTimeRange;
    file.videoTrimTimeRange = kCMTimeRangeInvalid;
    file.reverseVideoTrimTimeRange = kCMTimeRangeInvalid;
    file.videoVolume = 1.0;
    file.speedIndex = 2;
    file.isVerticalMirror = NO;
    file.isHorizontalMirror = NO;
    file.speed = 1;
    file.crop = CGRectMake(0, 0, 1, 1);
    
    RDNavigationViewController *nav;
    RDExtractAudioViewController *coverVC = [[RDExtractAudioViewController alloc] init];
    coverVC.file = file;
    coverVC.outputPath = outputFolder;
    coverVC.isExtract = YES;
    coverVC.type = type;
    coverVC.samplerate = samplerate;
    coverVC.finishAction = ^(NSString *outputPath, CMTimeRange videoTimeRange) {
        dispatch_async(dispatch_get_main_queue(), ^{
            callbackBlock(outputPath);
        });
    };
    coverVC.cancelAction = ^{
        cancelBlock();
    };
    nav = [[RDNavigationViewController alloc] initWithRootViewController:coverVC];
    
    if (!nav) {
        cancelBlock();
        return;
    }
    nav.isSingleFunc = YES;
    nav.statusBarHidden   = [UIApplication sharedApplication].statusBarHidden;
    nav.rdVeUiSdkDelegate = _delegate;
    nav.appKey            = _appkey;
    nav.licenceKey        = _licenceKey;
    nav.appSecret         = _appsecret;
    nav.outPath           = outputFolder;
    nav.callbackBlock     = ^(NSString * videoPath){
        callbackBlock(videoPath);
    };
    nav.cancelHandler = ^{
        cancelBlock();
    };
    nav.editConfiguration.supportFileType = _editConfiguration.supportFileType;
    nav.videoAverageBitRate            = _exportConfiguration.videoBitRate;
    nav.editConfiguration          = _editConfiguration;
    nav.cameraConfiguration        = _cameraConfiguration;
    nav.exportConfiguration        = _exportConfiguration;
    
    [self presentViewController:viewController nav:nav];
}


@end

#pragma mark- ConfigData

@implementation ConfigData
- (instancetype)init{
    if(self = [super init]){
        _editConfiguration = [[EditConfiguration alloc] init];
        _cameraConfiguration = [[CameraConfiguration alloc] init];
        _exportConfiguration = [[ExportConfiguration alloc] init];
    }
    return self;
}
@end
