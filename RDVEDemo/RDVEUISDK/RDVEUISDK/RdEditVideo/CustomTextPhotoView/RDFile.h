//
//  RDFile.h
//  RDVEUISDK
//
//  Created by emmet on 2017/6/27.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CustomTextPhotoFile.h"
#import "RDScene.h"

typedef NS_ENUM(NSInteger ,RDFileType) {
    kFILEVIDEO,
    kFILEIMAGE,
    kTEXTTITLE
};

typedef NS_ENUM(NSInteger,FileCropModeType)
{
    kCropTypeNone       = 0,
    kCropTypeOriginal,      /**< 原始 */
    kCropTypeFreedom,       /**< 自由 */
    kCropType1v1,           /**< 1v1 */
    kCropType16v9,
    kCropType9v16,
    kCropType4v3,
    kCropType3v4,
    kCropTypeFixed,         /**< 固定裁切范围 */
    kCropTypeFixedRatio,    /**< 固定比例裁切*/
};

typedef NS_ENUM(NSInteger,EditVideoSizeType){
    kAutomatic,//自动
    kLandscape,//横屏
    kVerticalscape,//竖屏
    kQuadratescape//正方形
};

typedef NS_ENUM(NSInteger,TimeFilterType)
{
    kTimeFilterTyp_None             = 0, //无
    kTimeFilterTyp_Slow             = 1, //慢动作
    kTimeFilterTyp_Repeat           = 2, //反复
    kTimeFilterTyp_Reverse          = 3, //倒序
};

typedef NS_ENUM(NSInteger,canvasType){
    KCanvasType_None                = 0, //无
    KCanvasType_Color               = 1, //场景背景颜色
    KCanvasType_Style               = 2, //场景图片样式
    KCanvasType_Blurry              = 3, //场景模糊
};


@interface RDFile : RDDraftDataModel

/**文件类型
 */
@property(nonatomic,assign)RDFileType        fileType;

/**视频 GIF 文件 缩略图保存路径 (  用于需要视频缩略图展示时加载  )
*/
@property(nonatomic,copy)NSString         *filtImagePatch;

/** 场景透明度(0.0〜1.0),默认为1.0
*/
@property(nonatomic,assign) float           backgroundAlpha;

/** 美颜(0.0〜1.0),默认为1.0
*/
@property(nonatomic,assign) float           beautyValue;

/** 场景媒体缩放倍数

 */
@property(nonatomic,assign)float            fileScale;

/** 场景背景类型
 */
@property(nonatomic,assign)canvasType       backgroundType;

/**
        场景背景 画布样式
 */
@property(nonatomic,assign) int             backgroundStyle;
/**  场景背景媒体
*/
@property(nonatomic,strong) RDFile          *BackgroundFile;
/**  场景背景模糊
*/
@property(nonatomic,assign) float           BackgroundBlurIntensity;
/**  场景背景色
*/
@property(nonatomic,strong) UIColor         *backgroundColor;
/**  添加固定旋转角度
*/
@property(nonatomic,assign) float           BackgroundRotate;

/**素材在预览中显示的百分比
 */
@property(nonatomic,assign)CGRect           rectInFile;


/** 图片是否是Gif
 */
@property(nonatomic,assign)BOOL             isGif;
/**GifData
 */
@property(nonatomic,copy  )NSData           *gifData;
/**图片显示时长
 */
@property(nonatomic,assign)CMTime           imageDurationTime;
/**文字板显示时长
 */
@property(nonatomic,assign)CMTimeRange      imageTimeRange;
/**封面在视频中的时间
 */
@property(nonatomic,assign)CMTime           coverTime;

/**视频（或图片）地址
 */
@property(nonatomic,copy  )NSURL            *contentURL;
/**视频倒序地址
 */
@property(nonatomic,copy  )NSURL            *reverseVideoURL;
/**滤镜
 */
@property(nonatomic, assign)NSInteger       filterIndex;

/**滤镜强度，VVAssetFilterLookup时有效,默认为1.0
 */
@property (nonatomic, assign)float filterIntensity;

/** 亮度 ranges from -1.0 to 1.0, with 0.0 as the normal level
 */
@property (nonatomic, assign) float         brightness;

/** 对比度 ranges from 0.0 to 4.0 (max contrast), with 1.0 as the normal level
 */
@property (readwrite, nonatomic) float      contrast;

/** 饱和度 ranges from 0.0 (fully desaturated) to 2.0 (max saturation), with 1.0 as the normal level
 */
@property (nonatomic, assign) float         saturation;
/** 暗角 ranges from 0.0 to 1.0 , with 0.0 as the normal level
 */
@property (nonatomic, assign) float         vignette;

/** 锐度 ranges from -4.0 to 4.0 , with 0.0 as the normal level
 */
@property (nonatomic, assign) float         sharpness;

/** 色温 ranges from -1.0 to 1.0 , with 0.0 as the normal level
 */
@property (nonatomic, assign) float         whiteBalance;
/**播放速度
 */
@property(nonatomic,assign)double           speed;
/**当前选中的播放速度下标
 */
@property(nonatomic,assign)NSInteger        speedIndex;
/**视频音量
 */
@property(nonatomic,assign)double           videoVolume;
/** 视频音量淡入时长，默认为0秒
 */
@property(nonatomic,assign)float            audioFadeInDuration;
/** 视频音量淡出时长，默认为0秒
 */
@property(nonatomic,assign)float            audioFadeOutDuration;
/**视频时间范围
 */
@property(nonatomic,assign)CMTimeRange      videoTimeRange;
/** 视频实际时长，去掉片头和片尾的黑帧
@abstract  Tthe actual duration of the video, remove the black frame from the beginning and end of the video.
*/
@property(nonatomic,assign)CMTimeRange      videoActualTimeRange;
/**倒序视频时间范围
 */
@property(nonatomic,assign)CMTimeRange      reverseVideoTimeRange;
/**视频截取时间范围
 */
@property(nonatomic,assign)CMTimeRange      videoTrimTimeRange;
/**倒序视频截取时间范围
 */
@property(nonatomic,assign)CMTimeRange      reverseVideoTrimTimeRange;
/**视频总时长
 */
@property(nonatomic,assign)CMTime           videoDurationTime;
/**倒序视频总时长
 */
@property(nonatomic,assign)CMTime           reverseDurationTime;
/**  在场景中开始时间
 */
@property (nonatomic,assign)CMTime          startTimeInScene;
/**视频(或图片)裁剪范围
 */
@property(nonatomic,assign)CGRect           crop;
/**视频(或图片)旋转角度
 */
@property(nonatomic,assign)double           rotate;
/**是否倒序
 */
@property(nonatomic,assign)BOOL             isReverse;
/**是否上下镜像
 */
@property(nonatomic,assign)BOOL             isVerticalMirror;
/**是否左右镜像
 */
@property(nonatomic,assign)BOOL             isHorizontalMirror;
/**转场分类名称
 */
@property(nonatomic,copy  )NSString         *transitionTypeName;
/**转场名称
 */
@property(nonatomic,copy  )NSString         *transitionName;
/**转场时间
 */
@property(nonatomic,assign)double           transitionDuration;
/**转场文件
 */
@property(nonatomic,copy)NSURL              *transitionMask;
/**缩率图
 */
@property(nonatomic,strong)UIImage          *thumbImage;
/**记录裁剪框显示区域
 */
@property(nonatomic,assign)CGRect           cropRect;
/**记录裁切方式
 */
@property(nonatomic,assign)FileCropModeType fileCropModeType;

/**文字板
 */
@property(nonatomic,strong)CustomTextPhotoFile *customTextPhotoFile;

/**素材在整个视频中的显示位置
 */
@property(nonatomic,assign)CGRect           rectInScene;

/**素材在整个视频中的显示位置的中心坐标 （启用动画时 才会使用）
 */
@property(nonatomic,assign)float          rectInScale;

/** 自定义滤镜特效
 */
@property(nonatomic,assign)NSInteger customFilterIndex;
@property(nonatomic,assign)int customFilterId;
/** 自定义时间特效
 */
@property(nonatomic,assign)TimeFilterType   fileTimeFilterType;
/** 自定义时间特效 时间段
 */
@property(nonatomic,assign)CMTimeRange      fileTimeFilterTimeRange;
/** 实现自定义时间特效生成的Scene数量
 */
@property(nonatomic,assign)int timeEffectSceneCount;
/** 动画名称
*/
@property(nonatomic,strong)NSString *animationName;
/** 动画时长
*/
@property(nonatomic,assign)float animationDuration;

- (void)remove;

@end

@protocol RDFile <NSObject>

@end
