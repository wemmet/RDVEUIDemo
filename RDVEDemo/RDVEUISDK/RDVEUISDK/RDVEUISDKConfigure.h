//
//  RDVEUISDKConfigure.h
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2017/7/15.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

/**支持的语言
 */
typedef NS_ENUM(NSInteger, SUPPORTLANGUAGE){
    CHINESE,    //中文
    ENGLISH     //英文
};

@interface RDMusicInfo : NSObject

/**使用音乐地址
 */
@property (nonatomic, strong) NSURL * _Nullable url;

/**音乐总时间范围
 */
@property (nonatomic, assign) CMTimeRange timeRange;

/**音乐截取时间范围
 */
@property (nonatomic, assign) CMTimeRange clipTimeRange;

/**音乐名称
 */
@property (nonatomic, strong) NSString *_Nullable name;

/**音量(0.0-1.0)
 */
@property (nonatomic, assign) float volume;

/**是否重复播放
 */
@property (nonatomic, assign) BOOL isRepeat;

@end

/**支持编辑的文件类型
 */
typedef NS_ENUM(NSInteger, SUPPORTFILETYPE){
    ONLYSUPPORT_VIDEO,      //仅支持视频
    ONLYSUPPORT_IMAGE,      //仅支持图片
    SUPPORT_ALL,             //支持视频和图片
};

/**视频输出方式
 */
typedef NS_ENUM(NSInteger, RDPROPORTIONTYPE){
    RDPROPORTIONTYPE_AUTO       = 0,//自动
    RDPROPORTIONTYPE_LANDSCAPE  = 1,//横
    RDPROPORTIONTYPE_SQUARE     = 2//正方形
};

/**默认选中视频还是图片
 */
typedef NS_ENUM(NSInteger, RDDEFAULTSELECTALBUM){
    
    RDDEFAULTSELECTALBUM_VIDEO,
    RDDEFAULTSELECTALBUM_IMAGE
};

/**配音方式
 */
typedef NS_ENUM(NSInteger, RDDUBBINGTYPE){
    RDDUBBINGTYPE_FIRST = 0,
    RDDUBBINGTYPE_SECOND
};

/**方向
 */
typedef NS_ENUM(NSInteger, RDDeviceOrientation){
    RDDeviceOrientationUnknown,
    RDDeviceOrientationPortrait,
    RDDeviceOrientationLandscape
};
/**截取时间模式
 */
typedef NS_ENUM(NSInteger, TRIMMODE){
    TRIMMODEAUTOTIME,           //自由截取
    TRIMMODESPECIFYTIME_ONE,    //单个时间定长截取
    TRIMMODESPECIFYTIME_TWO     //两个时间定长截取
};

/**定长截取:截取后导出视频分辨率类型
 */
typedef NS_ENUM(NSUInteger, TRIMEXPORTVIDEOTYPE) {
    TRIMEXPORTVIDEOTYPE_ORIGINAL,         //与原始一致
    TRIMEXPORTVIDEOTYPE_SQUARE,           //正方形
    TRIMEXPORTVIDEOTYPE_MIXED_ORIGINAL,   //可切换，默认为与原始一致
    TRIMEXPORTVIDEOTYPE_MIXED_SQUARE      //可切换，默认为正方形
};

/**截取之后返回的类型
 */
typedef NS_ENUM(NSInteger, RDCutVideoReturnType){
    RDCutVideoReturnTypePath,   //真实截取
    RDCutVideoReturnTypeTime,   //返回时间段
    RDCutVideoReturnTypeAuto    //动态截取
    
};
/**截取界面默认选中最大值还是最小值（定长截取才会设置）
 */
typedef NS_ENUM(NSInteger,RDdefaultSelectCutMinOrMax){
    kRDDefaultSelectCutMin,
    kRDDefaultSelectCutMax,
} ;
/**水印位置
 */
typedef NS_ENUM(NSInteger,RDWATERPOSITION){
    WATERPOSITION_LEFTTOP,
    WATERPOSITION_RIGHTTOP,
    WATERPOSITION_LEFTBOTTOM,
    WATERPOSITION_RIGHTBOTTOM
} ;

/**水印位置
 */
typedef NS_ENUM(NSInteger, RDDouYinRecordType){
    RDDouYinRecordType_Story, //随拍
    RDDouYinRecordType_Record,  //录制
};

typedef NS_ENUM(NSInteger, RDSingleFunctionType){
    RDSingleFunctionType_Transcoding    = 0,    //转码
    RDSingleFunctionType_Reverse,               //倒放
    RDSingleFunctionType_Crop,                  //裁剪
    RDSingleFunctionType_Intercept,             //截取
    RDSingleFunctionType_Compress,              //压缩
    RDSingleFunctionType_Transition,            //转场
    RDSingleFunctionType_Adjust,                //调色
    RDSingleFunctionType_Speed,                 //变速
    RDSingleFunctionType_VoiceFX,               //变声
    RDSingleFunctionType_Dubbing,               //配音
    RDSingleFunctionType_ClipEditing,           //片段编辑
    RDSingleFunctionType_Cover,                 //封面
    RDSingleFunctionType_Caption,               //字幕
    RDSingleFunctionType_Sticker,               //贴纸
    RDSingleFunctionType_Filter,                //滤镜
    RDSingleFunctionType_Effect,                //特效
    RDSingleFunctionType_Dewatermark,           //去水印
    RDSingleFunctionType_Collage,               //画中画
    RDSingleFunctionType_Doodle,                //涂鸦
    
};

@interface ExportConfiguration : NSObject<NSMutableCopying,NSCopying>

#pragma mark- 设置视频水印和码率

NS_ASSUME_NONNULL_BEGIN
/** 设置视频输出最大时长 (单位是秒) 不限制则传0，默认不限制
 */
@property (nonatomic,assign)long int   outputVideoMaxDuration;
/** 设置视频输入最大时长 (单位是秒) 不限制则传0，默认不限制
 */
@property (nonatomic,assign)long int   inputVideoMaxDuration;
/** 是否禁用片尾
 */
@property (nonatomic,assign)bool    endPicDisabled;
/** 片尾显示的用户名
 */
@property (nonatomic,copy)NSString * _Nullable endPicUserName;
/** 片尾显示时长（不包括淡入时长）
 */
@property (nonatomic,assign)float    endPicDuration;
/** 片尾淡入时长
 */
@property (nonatomic,assign)float    endPicFadeDuration;
/** 片尾显示的图片路径
 */
@property (nonatomic,copy)NSString * _Nullable endPicImagepath;
/** 是否禁用水印
 */
@property (nonatomic,assign)bool     waterDisabled;
/** 文字水印
 */
@property (nonatomic,copy,nullable)NSString *waterText;
/** 图片水印
 */
@property (nonatomic,strong,nullable)UIImage *waterImage;
/** 显示位置
 */
@property (nonatomic,assign)RDWATERPOSITION  waterPosition;

/** 设置视频输出码率 (单位是兆,默认是6M),建议设置大于1M，导出和压缩都生效
 */
@property (nonatomic,assign)float   videoBitRate;
/**压缩视频分辨率（调用压缩视频接口生效）
 */
@property (nonatomic,assign)CGSize  condenseVideoResolutionRatio;

NS_ASSUME_NONNULL_END
@end

/** 腾讯云AI识别账号配置
 */
@interface TencentCloudAIRecogConfig : NSObject
NS_ASSUME_NONNULL_BEGIN

/** 在腾讯云注册账号的 AppId
 */
@property (nonatomic, strong) NSString *appId;

/** 在腾讯云注册账号 AppId 对应的 SecretId
 */
@property (nonatomic, strong) NSString *secretId;

/** 在腾讯云注册账号 AppId 对应的 SecretKey
 */
@property (nonatomic, strong) NSString *secretKey;

/** 自行搭建的用于接收识别结果的服务器地址， 长度小于2048字节
 */
@property (nonatomic, strong) NSString *serverCallbackPath;

NS_ASSUME_NONNULL_END
@end

@interface EditConfiguration : NSObject<NSMutableCopying,NSCopying>

/** 向导模式 如果需要自己删除一些功能 则需启用此参数  default false
 */
@property (assign, nonatomic)bool enableWizard;
/** 编辑视频所支持的文件类型 (default all)
 */
@property (assign, nonatomic)SUPPORTFILETYPE supportFileType;

#pragma mark-相册界面
/** 默认选中视频还是图片
 */
@property (nonatomic,assign) RDDEFAULTSELECTALBUM defaultSelectAlbum;

/**选择视频和图片的最大张数
 */
@property (nonatomic,assign) int mediaCountLimit;

/**选择视频和图片的最小数
 */
@property (nonatomic,assign) int mediaMinCount;

/**启用相册相机 (default true)
 */
@property (nonatomic,assign) bool enableAlbumCamera;
/**点击相册界面相机按钮回调
 */
@property (nonatomic,copy,nullable) void(^clickAlbumCameraBlackBlock)(void);

#pragma mark- 设置截取界面
/** 截取时间模式
 */
@property (nonatomic,assign) TRIMMODE trimMode;
/** 单个时间定长截取：截取时间 默认15s
 */
@property (nonatomic,assign) float trimDuration_OneSpecifyTime;
/** 两个时间定长截取：偏小截取时间 默认12s
 */
@property (nonatomic,assign) float trimMinDuration_TwoSpecifyTime;
/** 两个时间定长截取：偏大截取时间 默认30s
 */
@property (nonatomic,assign) float trimMaxDuration_TwoSpecifyTime;
/** 两个时间定长截取：默认选中小值还是大值
 */
@property (nonatomic,assign) RDdefaultSelectCutMinOrMax  defaultSelectMinOrMax;

/** 定长截取时，截取后视频分辨率类型 默认TRIMVIDEOTYPE_ORIGINAL
 *  自由截取时，始终为TRIMVIDEOTYPE_ORIGINAL，该设置无效
 */
@property (nonatomic,assign) TRIMEXPORTVIDEOTYPE trimExportVideoType;

#pragma mark- 设置视频编辑界面
/**单个媒体特效
  */
@property (nonatomic,assign) bool enableSingleSpecialEffects;
/** 单个媒体调色
 */
@property (nonatomic,assign) bool enableSingleMediaAdjust;
/** 单个媒体滤镜 (default true)
 */
@property (nonatomic,assign) bool enableSingleMediaFilter;
/** 截取 (default true)
 */
@property (nonatomic,assign) bool enableTrim;
/** 分割 (default true)
 */
@property (nonatomic,assign) bool enableSplit;
/** 裁切 (default true)
 */
@property (nonatomic,assign) bool enableEdit;
/** 变速 (default true)
 */
@property (nonatomic,assign) bool enableSpeedcontrol;
/** 复制 (default true)
 */
@property (nonatomic,assign) bool enableCopy;
/** 调整顺序 (default true)
 */
@property (nonatomic,assign) bool enableSort;
/** 调整视频比例 (default true)
 */
@property (nonatomic,assign) bool enableProportion;

/** 调整图片显示时长 (default true)
 */
@property (nonatomic,assign) bool enableImageDurationControl;
/** 旋转 (default true)
 */
@property (nonatomic,assign) bool enableRotate;
/** 镜像 (default true)
 */
@property (nonatomic,assign) bool enableMirror;
/** 上下翻转 (default true)
 */
@property (nonatomic,assign) bool enableFlipUpAndDown;
/** 转场 (default true)
 */
@property (nonatomic,assign) bool enableTransition;
/** 音量 (default true)
 */
@property (nonatomic,assign) bool enableVolume;
/** 美颜 (default true)
 */
@property (nonatomic,assign) bool enableBeauty;
/** 动画  (default true)
 */
@property (nonatomic,assign) bool enableAnimation;
/** 替换  (default true)
 */
@property (nonatomic,assign) bool enableReplace;
/** 透明度 (default true)
 */
@property (nonatomic,assign) bool enableTransparency;

/** 文字板 (default true)
 */
@property (nonatomic,assign) bool enableTextTitle;
/** 默认视频输出方式（自动，横屏，1 ：1）
 */
@property (nonatomic,assign) RDPROPORTIONTYPE  proportionType;
/** 倒放 (default true)
 */
@property (nonatomic,assign) bool enableReverseVideo;
/** 草稿 (default false)
 */
@property (nonatomic,assign) bool enableDraft;

#pragma mark- 设置高级编辑界面
/** 网络素材分类地址
 */
@property (nonatomic,copy)NSString   * _Nonnull netMaterialTypeURL;
/** Music网络资源地址 (需自己构建网络下载API)
 */
@property (nonatomic,copy)NSString    * _Nullable musicResourceURL;
/** cloudMusic网络资源地址 (需自己构建网络下载API) default nil
 */
@property (nonatomic,copy)NSString    * _Nullable cloudMusicResourceURL;
/** 音效分类网络资源地址 (需自己构建网络下载API) default nil
 */
@property (nonatomic,copy)NSString    * _Nullable soundMusicTypeResourceURL;
/** 音效分类网络资源地址 (需自己构建网络下载API) default nil
 */
@property (nonatomic,copy)NSString    * _Nullable soundMusicResourceURL;

/** 本地音乐 (default true)
 */
@property (nonatomic,assign) bool enableLocalMusic;
/** MV网络资源地址 (需自己构建网络下载API)
 */
@property (nonatomic,copy,nullable)NSString    *mvResourceURL;
/** MV网络资源地址
 */
@property (nonatomic,copy,nullable)NSString    *newmvResourceURL;
/** 音乐网络资源地址
 */
@property (nonatomic,copy,nullable)NSString    *newmusicResourceURL;
/** 音乐家
 */
@property (nonatomic,copy,nullable)NSString    *newartist;
/** 音乐家主页标题
 */
@property (nonatomic,copy,nullable)NSString    *newartistHomepageTitle;
/** 音乐家主页Url
 */
@property (nonatomic,copy,nullable)NSString    *newartistHomepageUrl;
/** 音乐授权证书标题
 */
@property (nonatomic,copy,nullable)NSString    *newmusicAuthorizationTitle;
/** 音乐授权证书Url
 */
@property (nonatomic,copy,nullable)NSString    *newmusicAuthorizationUrl;
/** 滤镜网络资源地址
 */
@property (nonatomic,copy,nullable)NSString    *filterResourceURL;
/** 字幕网络资源地址
 */
@property (nonatomic,copy,nullable)NSString    *subtitleResourceURL;
/** 贴纸网络资源地址
 */
@property (nonatomic,copy,nullable)NSString    *effectResourceURL;
/** 特效网络资源地址
 */
@property (nonatomic,copy,nullable)NSString    *specialEffectResourceURL;
/** 字体网络资源地址
 */
@property (nonatomic,copy,nullable)NSString    *fontResourceURL;
/** 转场网络资源地址
 */
@property (nonatomic,copy,nullable)NSString    *transitionURL;

/** MV (default false)
 */
@property (nonatomic,assign) bool enableMV;
/** 配乐 (default true)
 */
@property (nonatomic,assign) bool enableMusic;
/** 变声 (default true)
 */
@property (nonatomic,assign) bool enableSoundEffect;
/** 配音 (default true)
 */
@property (nonatomic,assign) bool enableDubbing;
/** 配音类型 (default 方式一(配音不放在配乐里面))
 */
@property (nonatomic,assign) RDDUBBINGTYPE dubbingType;
/** 字幕 (default true)
 */
@property (nonatomic,assign) bool enableSubtitle;
/** 字幕AI识别 (default true),enableSubtitle为true时，才生效
 *  该功能是以腾讯云为例，须设置tencentAIRecogConfig
 */
@property (nonatomic,assign) bool enableAIRecogSubtitle;
/** enableAIRecogSubtitle为true时，才生效
 */
@property (nonatomic,strong,nullable) TencentCloudAIRecogConfig *tencentAIRecogConfig;
/** 滤镜 (default true)
 */
@property (nonatomic,assign) bool enableFilter;
/** 贴纸 (default true)
 */
@property (nonatomic,assign) bool enableSticker;
@property (nonatomic,assign) bool enableEffect DEPRECATED_MSG_ATTRIBUTE("Use enableSticker instead.");
/** 特效 (default true)
 */
@property (nonatomic,assign) bool enableEffectsVideo;
/** 加水印 (default true)
 */
@property (nonatomic,assign) bool enableWatermark;
/** 马赛克 (default true)
 */
@property (nonatomic,assign) bool enableMosaic;
/** 去水印 (default true)
 */
@property (nonatomic,assign) bool enableDewatermark;
/** 片段编辑 (default true)
 */
@property (nonatomic,assign) bool enableFragmentedit;

/** 图片动画 (default true)
 */
@property (nonatomic,assign) bool enablePicZoom;
/** 背景 (default true)
 */
@property (nonatomic,assign) bool enableBackgroundEdit;
/** 封面 (default true)
 */
@property (nonatomic,assign) bool enableCover;
/** 涂鸦 (default true)
 */
@property (nonatomic,assign) bool enableDoodle;

/** 进入SDK界面是否需要动画 (default true)
 */
@property (nonatomic,assign) bool presentAnimated;
/** 退出SDK界面是否需要动画 (default true)
 */
@property (nonatomic,assign) bool dissmissAnimated;
/** MVEffect (default false)
 */
@property (nonatomic,assign) bool enableMVEffect;
/** 画中画 (default true)
 */
@property (nonatomic,assign) bool enableCollage;
@end

typedef NS_ENUM(NSUInteger, RecordStatus) {
    RecordHeader = 1 << 0, // 正方形录制  only
    Recording = 1 << 1, // 非正方形录制 only
    RecordEnd = 1 << 2, // 混合 可切换
};

typedef NS_ENUM(NSUInteger, RecordVideoSizeType) {
    RecordVideoTypeSquare = 1 << 0, // 正方形录制  only
    RecordVideoTypeNotSquare = 1 << 1, // 非正方形录制 only
    RecordVideoTypeMixed = 1 << 2, // 混合 可切换
};

//此参数在非方形录制下生效
typedef NS_ENUM(NSUInteger, RecordVideoOrientation) {
    RecordVideoOrientationAuto = 1 << 0, // 横竖屏自动切换切换
    RecordVideoOrientationPortrait = 1 << 1, // 保持竖屏
    RecordVideoOrientationLeft = 1 << 2, // 保持横屏
};

typedef NS_ENUM(NSUInteger, Record_Type) {    
    RecordType_Video = 0,//录制
    RecordType_Photo = 1,//拍照
    RecordType_MVVideo = 2,//短视频MV
};

typedef NS_ENUM(NSUInteger, CameraCollocationPositionType) {
    CameraCollocationPositionTop    = 1 << 0,//顶部
    CameraCollocationPositionBottom = 1 << 1,//底部
};

typedef NS_ENUM(NSUInteger, CameraModelType) {
    CameraModel_Onlyone    = 1 << 0,//录制完成立即返回
    CameraModel_Manytimes = 1 << 1,//录制完成保存到相册并不立即返回，可多次录制或拍照
};

// faceU美颜设置
@interface RDFaceUBeautyParams : NSObject<NSCopying>

/**瘦脸 0.0~1.0     default 0.68
 */
@property (nonatomic , assign) float cheekThinning;

/**大眼 0.0~1.0     default 0.5
 */
@property (nonatomic , assign) float eyeEnlarging;

/**美白 0.0~1.0     default 0.48
 */
@property (nonatomic , assign) float colorLevel;

/**磨皮 1 2 3 4 5 6   default 3
 */
@property (nonatomic , assign) float blurLevel;

/** 瘦脸等级 0.0 ~ 1.0 默认1.0
 */
@property (nonatomic , assign) float faceShapeLevel;

/** 美型类型 (0、1、2、3) 默认：0，女神：0，网红：1，自然：2
 */
@property (nonatomic , assign) float faceShape;

@end

@interface CameraConfiguration : NSObject<NSMutableCopying,NSCopying>

/** 设置输出图像格式，默认为YES
 *  YES:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
 *  NO:kCVPixelFormatType_32BGRA
 */
@property(nonatomic, assign) bool captureAsYUV;

/** 拍摄模式 default CameraModel_Onlyone
 */
@property (nonatomic,assign) CameraModelType              cameraModelType;
/** 是否在拍摄完成就保存到相册再返回 default false 该参数只有在 CameraModel_Onlyone 模式下才生效
 */
@property (nonatomic,assign) bool                           cameraWriteToAlbum;
/** 前/后置摄像头 default AVCaptureDevicePositionFront
 */
@property (nonatomic,assign) AVCaptureDevicePosition        cameraCaptureDevicePosition;
/** 相机的方向 default RecordVideoOrientationAuto
 */
@property (nonatomic,assign) RecordVideoOrientation         cameraRecordOrientation;
/** 相机录制大小（正方形录制，非正方形录制）
 */
@property (nonatomic,assign) RecordVideoSizeType            cameraRecordSizeType;
/** 录制视频帧率 default 30
 */
@property (nonatomic,assign) int32_t                        cameraFrameRate;
/** 录制视频码率 default 4000000
 */
@property (nonatomic,assign) int32_t                        cameraBitRate;
/** 录制还是拍照 default RecordTypeVideo
 */
@property (nonatomic,assign) Record_Type                    cameraRecord_Type;
/** 视频输出路径
 */
@property (nonatomic,copy,nullable) NSString              *cameraOutputPath;
/**录制的视频的大小 (如：{720,1280}) default CGSizeZero
 */
@property (nonatomic,assign) CGSize                         cameraOutputSize;
/** 正方形录制时配置按钮的位置（美颜，延时，摄像头切换 三个按钮的位置）
 */
@property (nonatomic,assign) CameraCollocationPositionType  cameraCollocationPosition;
/** 正方形录制最大时长(default 10 )
 */
@property (nonatomic,assign) float                          cameraSquare_MaxVideoDuration;
/**非正方形录制最大时长 (default 0 ，不限制)
 */
@property (nonatomic,assign) float                          cameraNotSquare_MaxVideoDuration;
/**录制最小时长 (default 0 ，不限制 正方形录制和长方形录制都生效)
 */
@property (nonatomic,assign) float                          cameraMinVideoDuration;
/**反复录制时长 (default 2)开发中
 */
@property (nonatomic,assign) float                          repeatRecordDuration;

/** 是否开启滤镜功能(只有在开启Faceu的时候该参数才生效)
 */
@property (nonatomic , assign) bool                         enableFilter;

/**人脸道具贴纸
 */
@property (assign, nonatomic) bool                          enableFaceU;
/**是否启用网络下载faceUnity
 */
@property (assign, nonatomic)bool                           enableNetFaceUnity;
/**人脸道具贴纸下载路径
 */
@property (copy, nonatomic,nonnull)NSString                 *faceUURL;
/** 拍摄类型:可拍摄短视频MV(default true)
 */
@property (nonatomic,assign) bool                           cameraMV;
/** 拍摄类型:可拍摄视频(default true)
 */
@property (nonatomic,assign) bool                           cameraVideo;
/** 拍摄类型:可拍摄照片(default true)
 */
@property (nonatomic,assign) bool                           cameraPhoto;
/** 短视频MV录制最小时长(default 3s )
 */
@property (nonatomic,assign) float                          cameraMV_MinVideoDuration;
/** 短视频MV录制最大时长(default 15s )
 */
@property (nonatomic,assign) float                          cameraMV_MaxVideoDuration;
/** 从相机进入相册
 */
@property (nonatomic,copy,nonnull) void(^cameraEnterPhotoAlbumCallblackBlock)( );


/** 是否隐藏相机进入相册按钮
 */
@property (nonatomic,assign) bool                           hiddenPhotoLib;

@property (nonatomic, strong) RDFaceUBeautyParams           *faceUBeautyParams;
/*是否开启使用音乐录制. 如果需要切换音乐请设置好音乐下载路径,不设置则跳转到本地音乐界面 （editConfiguration.cloudMusicResourceURL）
 */
@property (nonatomic, assign) BOOL                  enableUseMusic;
/*传入需要录制时播放的音乐
 */
@property (nonatomic, strong) RDMusicInfo          * _Nullable musicInfo;

/*是否启用相机水印
 */
@property (nonatomic, assign) BOOL              enabelCameraWaterMark;
/*片头水印时长
 */
@property (nonatomic, assign) float             cameraWaterMarkHeaderDuration;
/*片尾水印时长
 */
@property (nonatomic, assign) float             cameraWaterMarkEndDuration;
/*相机水印更新画面回调
 */
@property (nonatomic, copy) void (^cameraWaterProcessingCompletionBlock)(NSInteger type/*1:正方形录制，0：非正方形录制*/,RecordStatus status, UIView *waterMarkview ,float time);

@end

//文件夹类型
typedef NS_ENUM(NSInteger,FolderType){
    kFolderDocuments,
    kFolderLibrary,
    kFolderTemp,
    kFolderNone
};

//选择相册类型
typedef NS_ENUM(NSInteger, ALBUMTYPE){
    kALBUMALL,
    kONLYALBUMVIDEO,
    kONLYALBUMIMAGE
};

NS_ASSUME_NONNULL_BEGIN

static NSString *kFILEURL = @"kFILEURL";
static NSString *kFILEPATH = @"kFILEPATH";
static NSString *kFILETYPE = @"kFILETYPE";


typedef void(^RdVECallbackBlock) (NSString * videoPath);//编辑完成导出结束回调 //EditCompletionBloc
typedef void(^RdVERecordCallbackBlock) (int result,NSString *path,RDMusicInfo *music);

typedef void(^RdVEFailBlock) (NSError * error);
typedef void(^RdVEAddVideosAndImagesCallbackBlock) (NSMutableArray<NSURL*> * list);
/**相册选择完成返回一个URL数组
 */
typedef void(^OnAlbumCallbackBlock) (NSMutableArray <NSURL*> * urls);
typedef void(^RdVEAddVideosCallbackBlock) (NSMutableArray<NSURL*> * list);
typedef void(^RdVEAddImagesCallbackBlock) (NSMutableArray<NSURL*> * list);

//编辑取消回调
typedef void(^RdVECancelBlock) (void);   //EditCancelBlock
//编辑取消回调
typedef void(^RdVEFailBlock) (NSError * error);

//拍摄 录像使用
typedef void(^PhotoPathCancelBlock) (NSString * _Nullable path);
typedef void(^ChangeFaceCancelBlock) (int type, float value);
typedef void(^AddFinishCancelBlock) (NSString * _Nullable videoPath, int type);
//截取视频
typedef void(^SuccessCancelBlock) (void);
typedef void(^FailCancelBlock) (void);
//视频截取
typedef void(^TrimAndRotateVideoFinishBlock)(float rotate,CMTimeRange timeRange);
//图片裁剪
typedef void(^EditVideoForOnceFinishAction)(CGRect crop,CGRect cropRect,BOOL verticalMirror,BOOL horizontalMirror,float rotation, int cropmodeType);


NS_ASSUME_NONNULL_END

@protocol RDVEUISDKDelegate <NSObject>

@optional

/** 设置faceU普通道具
 */
- (void)faceUItemChanged:(NSString * _Nullable)itemPath;

NS_ASSUME_NONNULL_BEGIN

/** 设置faceU美颜参数
 */
- (void)faceUBeautyParamChanged:(RDFaceUBeautyParams *)beautyParams;

/** 销毁faceU全部道具
 */
- (void)destroyFaceU;

/*
 *录制时，摄像头捕获帧回调，可对帧进行处理
 */
- (void)willOutputCameraSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/*
 *如果需要自定义相册则需要实现此函数
 */
- (void)selectVideoAndImageResult:(UINavigationController *)nav callbackBlock:(void (^)(NSMutableArray *lists))callbackBlock;

/*
 *如果需要自定义相册则需要实现此函数（添加视频）
 */
- (void)selectVideosResult:(UINavigationController *)nav callbackBlock:(void (^)(NSMutableArray *lists))callbackBlock;

/*
 *如果需要自定义相册则需要实现此函数（添加图片）
 */
- (void)selectImagesResult:(UINavigationController *)nav callbackBlock:(void (^)(NSMutableArray *lists))callbackBlock;

- (void)saveDraftResult:(NSError *)error;

NS_ASSUME_NONNULL_END

@end
