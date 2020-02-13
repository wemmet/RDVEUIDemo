//
//  RDScene.h
//  RDVECore
//
//  Created by 周晓林 on 2017/5/11.
//  Copyright © 2017年 Solaren. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "RDCustomFilter.h"
#import "RDCustomTransition.h"

typedef NS_ENUM(NSInteger, RDAudioFilterType) {
    RDAudioFilterTypeNormal,       // 无效果
    RDAudioFilterTypeBoy,          // 男声
    RDAudioFilterTypeGirl,         // 女声
    RDAudioFilterTypeMonster,      // 怪兽
    RDAudioFilterTypeCartoon,      // 卡通
    RDAudioFilterTypeCartoonQuick, // 卡通 快
    RDAudioFilterTypeEcho,         // 回声
    RDAudioFilterTypeReverb,       // 混响
    RDAudioFilterTypeRoom,         // 室内
    RDAudioFilterTypeDance,        // 小舞台
    RDAudioFilterTypeKTV,          // KTV
    RDAudioFilterTypeFactory,      // 厂房
    RDAudioFilterTypeArena,        // 竞技场
    RDAudioFilterTypeElectri,      // 电音
    RDAudioFilterTypeCustom,       // 自定义//调整媒体的pitch实现
};

typedef NS_ENUM(NSInteger, RDVideoRealTimeFilterType) {
    RDVideoRealTimeFilterTypeNone = 0,  //无
    RDVideoRealTimeFilterTypeDazzled,   //颤抖
    RDVideoRealTimeFilterTypeSoulstuff, //灵魂出窍
    RDVideoRealTimeFilterTypeHeartbeat, //心动
    RDVideoRealTimeFilterTypeSpotlights //聚光灯
};

typedef NS_ENUM(NSInteger,  RDVideoTransitionType) {
     RDVideoTransitionTypeNone = 0,
     RDVideoTransitionTypeLeft ,        //左推
     RDVideoTransitionTypeRight,        //右推
     RDVideoTransitionTypeUp,           //上推
     RDVideoTransitionTypeDown,         //下推
     RDVideoTransitionTypeFade,         //淡入
     RDVideoTransitionTypeBlinkBlack,   //闪黑
     RDVideoTransitionTypeBlinkWhite,   //闪白
     RDVideoTransitionTypeMask,         //Mask
     RDVideoTransitionTypeBlinkWhiteInvert,       //闪白-黑白/反色-反色/黑白-黑白
     RDVideoTransitionTypeBlinkWhiteGray,         //闪白-中间白色/上下黑白-中间白色/上下原图-原图
     RDVideoTransitionTypeBulgeDistortion,        //鱼眼
     RDVideoTransitionTypeGrid,                   //九宫格
     RDVideoTransitionTypeCustom,                 //自定义转场
};

typedef NS_ENUM(NSInteger, RDAssetType) {
    RDAssetTypeVideo,
    RDAssetTypeImage
};

typedef NS_ENUM(NSInteger, RDVECoreStatus) {
    kRDVECoreStatusUnknown,
    kRDVECoreStatusWillChangeMedia,
    kRDVECoreStatusReadyToPlay,
    kRDVECoreStatusFailed
};

@class VVTransition;
@class VVAsset;

@interface RDScene : NSObject

/** 标识符
 */
@property (nonatomic,strong) NSString*  identifier;

/** 场景背景色
*/
@property (nonatomic, strong) UIColor *backgroundColor;

/** 场景背景媒体
*/
@property (nonatomic, strong) VVAsset *backgroundAsset;

/**一个场景中可有多个媒体
 */
@property (nonatomic,strong) NSMutableArray<VVAsset*>*  vvAsset;

@property (nonatomic,strong) VVTransition*  transition;

@end

@interface RDMusic : NSObject<NSCopying,NSMutableCopying>
/** 标识符 
 */
@property (nonatomic,strong) NSString*  identifier;

/**使用音乐地址
 */
@property (nonatomic, strong) NSURL *  url;

/**音乐在整个视频中的时间范围，默认为整个视频的TimeRange
 */
@property (nonatomic, assign) CMTimeRange effectiveTimeRange;

/**音乐截取时间范围
 */
@property (nonatomic, assign) CMTimeRange clipTimeRange;

/**音乐名称
 */
@property (nonatomic, strong) NSString * name;

/**音量(0.0-1.0)，默认为1.0
 */
@property (nonatomic, assign) float volume;

/**音调(大于0.0)，默认为1.0（原音），audioFilterType为RDAudioFilterTypeCustom时生效
 */
@property (nonatomic, assign) float pitch;

/**是否重复播放，默认为YES
 */
@property (nonatomic, assign) BOOL isRepeat;

/**配乐是否淡入淡出，默认为NO
 */
@property (nonatomic, assign) BOOL isFadeInOut;

/**配乐开头淡入淡出时长，默认为2.0秒
 */
@property (nonatomic, assign) float headFadeDuration;

/**配乐结尾淡入淡出时长，默认为2.0秒
 */
@property (nonatomic, assign) float endFadeDuration;

/**配乐淡入淡出时长，默认为2.0秒
 */
@property (nonatomic, assign) float fadeDuration DEPRECATED_MSG_ATTRIBUTE("Use headFadeDuration and endFadeDuration instead.");

/** 音乐滤镜
 */
@property (nonatomic, assign) RDAudioFilterType audioFilterType;

@end


typedef NS_ENUM(NSInteger, RDVideoMVEffectType) {
    RDVideoMVEffectTypeMask,        //mask视频为左右结构
    RDVideoMVEffectTypeScreen,
    RDVideoMVEffectTypeGray,
    RDVideoMVEffectTypeGreen,
    RDVideoMVEffectTypeChroma,      //可透过指定颜色
};

@interface VVMovieEffect : NSObject

/** MV路径
 */
@property (nonatomic,strong) NSURL*  url;

/** MV显示时长
 */
@property (nonatomic,assign) CMTimeRange timeRange;

/** MV类型
 */
@property (nonatomic,assign) RDVideoMVEffectType type;

/** 要透过的颜色，须与视频中一致
 *  type为RDVideoMVEffectTypeChroma时有效
*/
@property (nonatomic,strong) UIColor *chromaColor;

/** MV显示透明度
 */
@property (nonatomic,assign) float alpha;
/** 是否循环播放。默认为YES
 */
@property(readwrite, nonatomic) BOOL shouldRepeat;
@end

@interface VVTransition : NSObject
/* 转场属性 描述的是 当前场景如何向后一个场景过渡
 */

/**  转场类型
 */
@property (nonatomic,assign)  RDVideoTransitionType   type;

/**  持续时间
 */
@property (nonatomic,assign) CGFloat duration;
/** 上下左右推过程中的点
 */
@property (nonatomic,strong) NSArray *positions;
/**  自定义转场
 */
@property (nonatomic,strong) RDCustomTransition* customTransition;

/**  特效灰度图地址
 */
@property (nonatomic,strong) NSURL*  maskURL;

@property (nonatomic,assign) CMTimeRange timeRange;

@end

typedef NS_ENUM(NSInteger, RDImageFillType) {
    RDImageFillTypeFull, // 全填充
    RDImageFillTypeFit,  // 适配 静止
    RDImageFillTypeAspectFill,
    RDImageFillTypeFitZoomOut, // 适配 缩小
    RDImageFillTypeFitZoomIn   // 适配 放大
};

typedef NS_ENUM(NSInteger, RDVideoFillType) {
    RDVideoFillTypeFit,  // 适配 静止
    RDVideoFillTypeFull // 全填充
};

typedef NS_ENUM(NSInteger, VVAssetFilter) {
    VVAssetFilterEmpty,
    VVAssetFilterACV,
    VVAssetFilterLookup
};

typedef NS_ENUM(NSInteger, AnimationInterpolationType) {
    AnimationInterpolationTypeLinear, // 线性(匀速)
    AnimationInterpolationTypeAccelerateDecelerate, //在动画开始结束的地方速率改变比较慢，中间加速
    AnimationInterpolationTypeAccelerate, // 加速
    AnimationInterpolationTypeDecelerate, // 减速
    AnimationInterpolationTypeCycle, 
};

typedef NS_ENUM(NSInteger, VVAssetBlendType)
{
    BLEND_GL_ZERO,
    BLEND_GL_ONE,
    BLEND_GL_SRC_ALPHA,
    BLEND_GL_ONE_MINUS_SRC_ALPHA,
    
};

typedef NS_ENUM(NSInteger, VVAssetBlendEquation)
{
    EQUATION_GL_FUNC_ADD,
};

typedef NS_ENUM(NSInteger, RDAssetBlurType) {
    RDAssetBlurNone,            // 无效果
    RDAssetBlurZoomOut,         // 渐变模糊，由中心像四周扩散
    RDAssetBlurNormal,          // 高斯模糊
    
};

@interface RDAssetBlur : NSObject

/** 设置模糊类型，现只支持RDAssetBlurNormal
 */
@property (nonatomic, assign)RDAssetBlurType type   DEPRECATED_ATTRIBUTE;

/** 设置模糊强度0.0~1.0，默认为0.5
 */
@property (nonatomic, assign)float intensity;

/** 设置在video中没有添加模糊的区域，默认为CGRectZero
 *  (0, 0)为左上角 (1, 1)为右下角
 *  该属性已废弃
 */
@property (nonatomic, assign)CGRect unblurryRect DEPRECATED_MSG_ATTRIBUTE("Use setPointsLeftTop:rightTop:rightBottom:leftBottom: instead.");

/** 设置模糊时长
 *  设置媒体动画后，该属性无效，以动画中的atTime为准
 */
@property (nonatomic, assign)CMTimeRange timeRange;


/**在video中四个顶点的坐标，可设置非矩形。
 * (0, 0)为左上角 (1, 1)为右下角
 * 默认为({0, 0},{1, 0},{1, 1},{0, 1})
 */
@property (nonatomic, readonly) NSArray *pointsArray;


/**在video中四个顶点的坐标，可设置非矩形，设置的值将赋给pointsArray属性。
 * (0, 0)为左上角 (1, 1)为右下角
 *  @param leftTop      媒体在video中的 左上角 顶点坐标
 *  @param rightTop     媒体在video中的 右上角 顶点坐标
 *  @param rightBottom  媒体在video中的 右下角 顶点坐标
 *  @param leftBottom   媒体在video中的 左下角 顶点坐标
 */
- (NSArray *)setPointsLeftTop:(CGPoint)leftTop
                     rightTop:(CGPoint)rightTop
                  rightBottom:(CGPoint)rightBottom
                   leftBottom:(CGPoint)leftBottom;

@end

@interface VVAssetAnimatePosition : NSObject

/**开始时间
 */
@property (nonatomic,assign) CGFloat atTime;

/**旋转锚点，默认CGPointMake(0.5, 0.5)
 */
@property (nonatomic,assign) CGPoint anchorPoint;

/**旋转角度
 */
@property (nonatomic,assign) CGFloat rotate;

/**在video中的位置大小，默认CGRectMake(0, 0, 1, 1)
 * (0, 0)为左上角 (1, 1)为右下角
 * rect与pointsArray只有一个有效，以最后设置的为准
 */
@property (nonatomic,assign) CGRect rect;

/**透明度(0.0~1.0)，默认1.0
 */
@property (nonatomic,assign) CGFloat opacity;

/** 亮度 ranges from -1.0 to 1.0, with 0.0 as the normal level
 */
@property (nonatomic, assign) float brightness;

/** 对比度 ranges from 0.0 to 4.0 (max contrast), with 1.0 as the normal level
 */
@property (readwrite, nonatomic) float contrast;

/** 饱和度 ranges from 0.0 (fully desaturated) to 2.0 (max saturation), with 1.0 as the normal level
 */
@property (nonatomic, assign) float saturation;

/** 暗角 ranges from 0.0  to 1.0 (max vignette), with 0.0 as the normal level
 */
@property (nonatomic, assign) float vignette;

/** 锐化 ranges from -4.0 to 4.0 (max sharpness) , with 0.0 as the normal level
 */
@property (nonatomic, assign) float sharpness;

/** 色温 ranges from -1.0 to 1.0 (max whiteBalance) , with 0.0 as the normal level
 */
@property (nonatomic, assign) float whiteBalance;

/**动画类型
 */
@property (nonatomic,assign) AnimationInterpolationType type;

/**轨迹
 */
@property (nonatomic,strong) UIBezierPath*  path;

/** 内容放大 fillScale必须大于或等于1.0,默认为1.0
 */
@property (nonatomic,assign) CGFloat fillScale;

/** 设置模糊效果
 */
@property (nonatomic, strong) RDAssetBlur *blur;

/**视频(或图片)裁剪范围。默认为CGRectMake(0, 0, 1, 1)
 */
@property (nonatomic,assign) CGRect crop;

/**在video中四个顶点的坐标，可设置非矩形。
 * (0, 0)为左上角 (1, 1)为右下角
 * rect与pointsArray只有一个有效，以最后设置的为准
 */
@property (nonatomic, readonly) NSArray *pointsArray;

/** 是否使用rect，默认为YES
 *  YES:使用rect   NO:使用pointsArray
 */
@property (nonatomic, readonly) BOOL isUseRect;

/**在video中四个顶点的坐标，可设置非矩形，设置的值将赋给pointsArray属性。
 * (0, 0)为左上角 (1, 1)为右下角
 *  @param leftTop      媒体在video中的 左上角 顶点坐标
 *  @param rightTop     媒体在video中的 右上角 顶点坐标
 *  @param rightBottom  媒体在video中的 右下角 顶点坐标
 *  @param leftBottom   媒体在video中的 左下角 顶点坐标
 *
 * rect与pointsArray只有一个有效，以最后设置的为准
 */
- (NSArray *)setPointsLeftTop:(CGPoint)leftTop
                     rightTop:(CGPoint)rightTop
                  rightBottom:(CGPoint)rightBottom
                   leftBottom:(CGPoint)leftBottom;



                             
@end

typedef NS_ENUM(NSInteger, RDBlendType) {
    RDBlendNormal,          //常规贴图
    RDBlendChromaColor,     //指定颜色透明
    RDBlendAIChromaColor,   //智能解析图像，自动颜色透明
    RDBlendDark,            //变暗
    RDBlendScreen,          //滤色
    RDBlendOverlay,         //叠加
    RDBlendMultiply,        //正片叠底
    RDBlendLighten,         //变亮
    RDBlendHardLight,       //强光
    RDBlendSoftLight,       //柔光
    RDBlendLinearBurn,      //线性加深
    RDBlendColorBurn,       //颜色加深
    RDBlendColorDodge,      //颜色减淡
};

@interface VVAsset : NSObject

/** 标识符
 */
@property (nonatomic,strong) NSString*  identifier;
/**  资源地址 图片  视频
 */
@property (nonatomic,strong) NSURL*  url;

/**  资源类型 图片 或者 视频
 */
@property (nonatomic,assign) RDAssetType      type;

/**  图片填充类型
 *   设置顶点坐标(pointsInVideoArray)时，需设置为RDImageFillTypeFull
 */
@property (nonatomic,assign) RDImageFillType  fillType;

/**  视频填充类型，默认为RDVideoFillTypeFit
 */
@property (nonatomic,assign) RDVideoFillType  videoFillType;

/** 资源显示时间段  开始 与 持续时间
 *  图片设置持续时间  视频可以指定时间段
 */
@property (nonatomic,assign) CMTimeRange      timeRange;

/** 视频实际时长，去掉片头和片尾的黑帧
@abstract  Tthe actual duration of the video, remove the black frame from the beginning and end of the video.
*/
@property (nonatomic,assign) CMTimeRange videoActualTimeRange;

/**  在场景中开始时间
 */
@property (nonatomic,assign) CMTime startTimeInScene;

/** 是否重复播放，默认为NO
 *  设置为YES时，必须同时设置timeRangeInVideo
 */
@property (nonatomic, assign) BOOL isRepeat;

/** 在整个视频中的持续时间范围
 *  只在isRepeat为YES时有效
 */
@property (nonatomic ,assign) CMTimeRange timeRangeInVideo;

/**  播放速度 作用在图片段只会表现为播放时间改变 作用在视频上可以加速或者减速
 */
@property (nonatomic,assign) float            speed;

/**  音量  默认为1.0
 */
@property (nonatomic,assign) float            volume;

/** 音量淡入时长，默认为0秒
 */
@property (nonatomic, assign) float audioFadeInDuration;

/** 音量淡出时长，默认为0秒
 */
@property (nonatomic, assign) float audioFadeOutDuration;

/**音调(大于0.0)，默认为1.0（原音），audioFilterType为RDAudioFilterTypeCustom时生效
 */
@property (nonatomic, assign) float pitch;

/**视频(或图片)裁剪范围。默认为CGRectMake(0, 0, 1, 1)
 * 设置媒体动画后，该属性无效，以动画中的crop为准
 */
@property (nonatomic,assign) CGRect           crop;

/**视频(或图片)旋转角度 -360 < x < 360
 */
@property (nonatomic,assign) double           rotate;

/**是否上下镜像
 */
@property (nonatomic,assign) BOOL             isVerticalMirror;

/**是否左右镜像
 */
@property (nonatomic,assign) BOOL             isHorizontalMirror;

/**在video中的范围。默认为CGRectMake(0, 0, 1, 1)
 * (0, 0)为左上角 (1, 1)为右下角
 * rectInVideo与pointsInVideoArray只有一个有效，以最后设置的为准
 * 设置媒体动画后，该属性及pointsInVideoArray属性均无效，以动画中的rect或pointsArray值为准
 */
@property (nonatomic, assign) CGRect           rectInVideo;

/** 视频(或图片)透明度(0.0〜1.0),默认为1.0
 */
@property (nonatomic,assign) float alpha;

/** 显示时长
 */
@property (nonatomic, readonly) CMTime duration;

/** 亮度 ranges from -1.0 to 1.0, with 0.0 as the normal level
 *  设置媒体动画后，该属性无效，以动画中的brightness值为准
 */
@property (nonatomic, assign) float brightness;

/** 对比度 ranges from 0.0 to 4.0 (max contrast), with 1.0 as the normal level
 *  设置媒体动画后，该属性无效，以动画中的contrast值为准
 */
@property (readwrite, nonatomic) float contrast;

/** 饱和度 ranges from 0.0 (fully desaturated) to 2.0 (max saturation), with 1.0 as the normal level
 *  设置媒体动画后，该属性无效，以动画中的saturation值为准
*/
@property (nonatomic, assign) float saturation;


/** 暗角 ranges from 0.0 to 1.0 , with 0.0 as the normal level
 *  设置媒体动画后，该属性无效，以动画中的vignette值为准
 */
@property (nonatomic, assign) float vignette;

/** 锐化 ranges from -4.0 to 4.0 , with 0.0 as the normal level
 *  设置媒体动画后，该属性无效，以动画中的sharpness值为准
 */
@property (nonatomic, assign) float sharpness;

/** 色温 ranges from -1.0 to 1.0 , with 0.0 as the normal level
 *  设置媒体动画后，该属性无效，以动画中的whiteBalance值为准
 */
@property (nonatomic, assign) float whiteBalance;

/** 滤镜类型
 */
@property (nonatomic , assign) VVAssetFilter filterType;

/**滤镜资源地址
 */
@property (nonatomic , strong)  NSURL*   filterUrl;

/**滤镜强度，VVAssetFilterLookup时有效,默认为1.0
 */
@property (nonatomic, assign)float filterIntensity;

/**mask资源地址，可实现不规则媒体显示
 * 设置不规则mask后，rotate属性只支持90的倍数
 */
@property (nonatomic , strong) NSURL*  maskURL;


/**mosaic资源地址，可实现马赛克显示
 */
@property (nonatomic , strong) NSURL*  mosaicURL;

/**mosaic显示区域（矩形）
 */
@property (nonatomic , assign) CGRect rectMosaic;

/**mosaic旋转角度
 */
@property (nonatomic , assign) float mosaicAngle;


/** 媒体动画组
 */
@property (nonatomic, strong) NSArray<VVAssetAnimatePosition*>*  animate;

/** 音乐滤镜
 */
@property (nonatomic, assign) RDAudioFilterType audioFilterType;

/**设置混合参数
 * 设置源因子，默认为：BLEND_GL_SRC_ALPHA
 */
@property (nonatomic, assign) VVAssetBlendType srcFactor;

/**设置混合参数
 * 设置目标因子，默认为：BLEND_GL_ONE_MINUS_SRC_ALPHA
 */
@property (nonatomic, assign) VVAssetBlendType dstFactor;

/**设置混合参数
 * 设置混合模式，默认为：EQUATION_GL_FUNC_ADD
 */
@property (nonatomic, assign) VVAssetBlendEquation blendModel;

/** 设置模糊效果
 *  设置媒体动画后，该属性无效，以动画中的blur为准
 */
@property (nonatomic, strong) RDAssetBlur *blur;

/** 设置模糊强度0.0~1.0，默认为0.0
 *  blur是对整个视频有效，而该属性仅对单个媒体有效
 */
@property (nonatomic, assign) float blurIntensity;

/** 设置媒体边框模糊效果，默认为NO
 */
@property (nonatomic, assign) BOOL isBlurredBorder;

/**在video中四个顶点的坐标，可设置非矩形。
 * (0, 0)为左上角 (1, 1)为右下角
 * rectInVideo与pointsInVideoArray只有一个有效，以最后设置的为准
 * 设置媒体动画后，该属性及rectInVideo属性均无效，以动画中的rect或pointsArray值为准
 */
@property (nonatomic, readonly) NSArray *pointsInVideoArray;

/** 是否使用rectInVideo，默认为YES
 *  YES:使用rectInVideo   NO:使用pointsInVideoArray
 */
@property (nonatomic, readonly) BOOL isUseRect;

/**在video中四个顶点的坐标，可设置非矩形，设置的值将赋给pointsInVideoArray属性。
 * (0, 0)为左上角 (1, 1)为右下角
 *  @param leftTop      媒体在video中的 左上角 顶点坐标
 *  @param rightTop     媒体在video中的 右上角 顶点坐标
 *  @param rightBottom  媒体在video中的 右下角 顶点坐标
 *  @param leftBottom   媒体在video中的 左下角 顶点坐标
 *
 * rectInVideo与pointsInVideoArray只有一个有效，以最后设置的为准
 * 设置媒体动画后，该属性及rectInVideo属性均无效，以动画中的rect或pointsArray值为准
 */
- (NSArray *)setPointsInVideoLeftTop:(CGPoint)leftTop
                            rightTop:(CGPoint)rightTop
                         rightBottom:(CGPoint)rightBottom
                          leftBottom:(CGPoint)leftBottom;

/**设置媒体自定义滤镜。
 */
@property (nonatomic, strong) RDCustomFilter* customFilter;

/**美颜磨皮，0.0~1.0,默认为0.0
 */
@property (nonatomic, assign) float beautyBlurIntensity;

/**美颜亮肤，0.0~1.0,默认为0.0
 */
@property (nonatomic, assign) float beautyBrightIntensity;

/**美颜红润，0.0~1.0,默认为0.0
 */
@property (nonatomic, assign) float beautyToneIntensity;

/** 要透过的颜色，须与视频或者图片中一致，RDBlendType 需要设置为 RDBlendChromaColor 否则无效
*/
@property (nonatomic,strong) UIColor *chromaColor;

/** 混合模式
*/
@property (nonatomic, assign) RDBlendType blendType;

@end



// Mask 用于异形
@interface MaskAsset : NSObject
// Mask类型  图片--灰度图 视频
@property (nonatomic , assign) RDAssetType type;// 视频Mask 图片Mask
// mask资源地址
@property (nonatomic , strong) NSURL*  url;
// Mask持续时间
@property (nonatomic , assign) CMTimeRange timeRange; // 时间段
// 当mask为视频时 是否重复
@property (nonatomic , assign) BOOL isRepeat;// 在视频上是否重复
@end

@interface FilterAttribute : NSObject

/**滤镜特效类型
 */
@property (nonatomic,assign) RDVideoRealTimeFilterType filterType;
@property (nonatomic,assign) CMTimeRange timeRange;

@end

#pragma mark - RDCaptionAnimate 字幕动画

/** 动画类型
 *  RDCaptionAnimateTypeMove时，需设置属性pushInPoint、pushOutPoint
 *  RDCaptionAnimateTypeScaleInOut时，需设置属性scaleIn、scaleOut
 */
typedef NS_ENUM(NSInteger, RDCaptionAnimateType) {
    RDCaptionAnimateTypeNone,               //无
    RDCaptionAnimateTypeMove,               //移动
    RDCaptionAnimateTypeScaleInOut,         //缩放入出
    RDCaptionAnimateTypeScrollInOut,        //滚动入出
    RDCaptionAnimateTypeFadeInOut,          //淡入淡出
};

@interface RDCaptionAnimate : NSObject

/**是否淡入淡出，默认YES
 */
@property (nonatomic, assign) BOOL isFade;

/**淡入时长，默认为1.0
 */
@property (nonatomic, assign) float fadeInDuration;

/**淡出时长，默认为1.0
 */
@property (nonatomic, assign) float fadeOutDuration;

/**动画类型
 */
@property (nonatomic, assign) RDCaptionAnimateType type;

/**进入时动画类型
 * 设置type后，该属性无效
*/
@property (nonatomic, assign) RDCaptionAnimateType inType;

/**消失时动画类型
 * 设置type后，该属性无效
*/
@property (nonatomic, assign) RDCaptionAnimateType outType;

/**动画进入时展示时长，默认为2.0
 */
@property (nonatomic, assign) float inDuration;

/**动画消失时展示时长，默认为2.0
 */
@property (nonatomic, assign) float outDuration;

/**推入点，动画类型为RDCaptionAnimateTypeMove时有效(CGPointMake(0, 0)〜CGPointMake(1, 1))。默认为CGPointZero
 * 以字幕center为基准，相对于实际视频size的移动Point
 */
@property (nonatomic, assign) CGPoint pushInPoint;

/**推出点，动画类型为RDCaptionAnimateTypeMove时有效(CGPointMake(0, 0)〜CGPointMake(1, 1))。默认为CGPointZero
 * 以字幕center为基准，相对于实际视频size的移动Point
 */
@property (nonatomic, assign) CGPoint pushOutPoint;

/**动画类型为RDCaptionAnimateTypeScaleInOut时有效，设置进入时的放大/缩小倍数(0.0~1.0)。
 * 默认为0.0。效果为进入时，字幕从0.5倍，在duration内逐渐放大到scaleOut倍。
 */
@property (nonatomic, assign) float scaleIn;

/**动画类型为RDCaptionAnimateTypeScaleInOut时有效，设置消失时的放大/缩小倍数(0.0~1.0)。
 * 默认为1.0。效果为消失时，字幕从1.0倍，在duration内逐渐缩小到scaleIn倍再消失。
 */
@property (nonatomic, assign) float scaleOut;

@end

/** 可设置字幕每帧的动画
 */
@interface RDCaptionCustomAnimate : NSObject

/**开始时间
 */
@property (nonatomic,assign) CGFloat atTime;

/**旋转角度
 */
@property (nonatomic,assign) CGFloat rotate;

/**字幕位置，默认为CGRectZero
 */
@property (nonatomic ,assign) CGRect rect;

/**透明度(0.0~1.0)，默认1.0
 */
@property (nonatomic,assign) CGFloat opacity;

/**动画类型
 */
@property (nonatomic,assign) AnimationInterpolationType type;

/**轨迹
 */
@property (nonatomic,strong) UIBezierPath*  path;

/** 字幕缩放大小，默认1.0
 */
@property (nonatomic,assign) CGFloat scale;

@end

#pragma mark - RDCaption

//字幕类型
typedef NS_ENUM(NSInteger, RDCaptionType) {
    RDCaptionTypeHasText = 0,   //带文字
    RDCaptionTypeNoText         //不带文字
};

//字幕对齐方式
typedef NS_ENUM(NSInteger, RDCaptionTextAlignment) {
    RDCaptionTextAlignmentLeft = 0,
    RDCaptionTextAlignmentCenter,
    RDCaptionTextAlignmentRight
};

//贴纸类型
typedef NS_ENUM(NSInteger, RDStickerType) {
    RDStickerType_None = 0, //无
    RDStickerType_Pixelate, //马赛克
};

@interface RDDoodle :NSObject

@property (nonatomic,copy)NSString *path;

@property (nonatomic,assign)CMTimeRange timeRange;


@end

@interface RDDoodleLayer : CALayer

@property (nonatomic,copy)NSString *path;

@property (nonatomic,assign)CMTimeRange timeRange;

@end

@interface RDCaption : NSObject

/**字幕背景色，默认无
 */
@property (nonatomic ,strong) UIColor *  backgroundColor;

/**字幕时间范围
 */
@property (nonatomic ,assign) CMTimeRange timeRange;

/**字幕旋转角度
 * 设置字幕动画组后，该属性无效，以动画中的rotate值为准
 */
@property (nonatomic ,assign) float angle;

/**字幕缩放大小，默认为1.0
 * 设置字幕动画组后，该属性无效，以动画中的scale值为准
 */
@property (nonatomic ,assign) float scale;

/**透明度(0.0~1.0)，默认1.0
 * 设置字幕动画组后，该属性无效，以动画中的opacity值为准
 */
@property (nonatomic,assign) CGFloat opacity;

/**字幕类型 0 带文字,1 不带文字
 */
@property (nonatomic ,assign) RDCaptionType type;

/**贴纸类型，废弃，添加马赛克请使用RDMosaic
 */
@property (nonatomic ,assign) RDStickerType stickerType DEPRECATED_ATTRIBUTE;

/** 字幕图片路径
 *   单张图片的情况，只设置该属性即可
 */
@property (nonatomic ,copy) NSString * captionImagePath;

/** 字幕图片文件夹路径
 *  多张图片的情况，与imageName、timeArray及frameArray配合使用
 */
@property (nonatomic ,copy) NSString * imageFolderPath;

/**图片前缀名字
 */
@property (nonatomic ,copy) NSString * imageName;

/**动画持续时间
 */
@property (nonatomic ,assign) float duration;

/**字幕位置，默认为视频中心CGPointMake(0.5, 0.5)
 * 设置字幕动画组后，该属性无效，以动画中的rect值为准
 */
@property (nonatomic ,assign) CGPoint position;

/**字幕大小，相对于实际视频size的字幕大小(CGPointMake(0, 0)〜CGPointMake(1, 1))
 * 设置字幕动画组后，该属性无效，以动画中的rect值为准
 */
@property (nonatomic ,assign) CGSize size;

/**文字内容
 */
@property (nonatomic ,copy) NSString * pText;

/**文字内容(富文本)
 *  设置富文本后，文字颜色、字体加粗等属性均无效，以富文本的设置为准
 */
@property (nonatomic ,copy) NSMutableAttributedString * attriStr;

/** 文字图片
 */
@property (nonatomic ,strong) UIImage * tImage;

/**文字字体名称
 */
@property (nonatomic ,copy) NSString * tFontName;

/**文字字体大小
 */
@property (nonatomic ,assign) float tFontSize;

/**文字字体加粗，默认为NO
 */
@property (nonatomic ,assign) BOOL isBold;

/**文字字体斜体，默认为NO
 */
@property (nonatomic ,assign) BOOL isItalic;

/**文字对齐方式 默认为RDCaptionTextAlignmentCenter
 */
@property (nonatomic ,assign) RDCaptionTextAlignment tAlignment;

/** 文字旋转度数
 */
@property (nonatomic ,assign) float tAngle;

/**文字颜色，默认为whiteColor
 */
@property (nonatomic ,strong) UIColor * tColor;

/** 文字竖排，默认为NO
 *  仅支持一列
 *  设置富文本后，该属性无效
 */
@property (nonatomic ,assign) BOOL isVerticalText;

/**文字是否描边，默认为NO
 */
@property (nonatomic ,assign) BOOL isStroke;

/**文字描边颜色，默认黑色blackColor
 */
@property (nonatomic ,strong) UIColor *  strokeColor;

/**文字描边宽度,默认为0.0
 */
@property (nonatomic ,assign) float strokeWidth;

/** 文字描边透明度(0.0〜1.0),默认为1.0
 */
@property (nonatomic, assign) float strokeAlpha;

/**文字是否设置阴影，默认为NO
 */
@property (nonatomic ,assign) BOOL isShadow;

/**文字阴影颜色，默认黑色blackColor
 */
@property (nonatomic ,strong) UIColor *  tShadowColor;

/**文字阴影偏移量,默认为CGSizeMake(0, -1)
 */
@property (nonatomic ,assign) CGSize tShadowOffset;

/** 文字阴影透明度(0.0〜1.0),默认为1.0
 */
@property (nonatomic, assign) float shadowAlpha;

/** 文字区域
 */
@property (nonatomic ,assign) CGRect  tFrame;

/** 文字透明度(0.0〜1.0),默认为1.0
 */
@property (nonatomic ,assign) float textAlpha;

/**帧动画
 */
@property (nonatomic ,strong) NSArray * frameArray;

/**时间动画
 */
@property (nonatomic ,strong) NSArray * timeArray;

/** 字幕是否需要拉伸
 */
@property (nonatomic, assign) BOOL isStretch;

/**字幕拉伸的区域
 */
@property (nonatomic ) CGRect stretchRect;

/**音乐
 */
@property (nonatomic, strong) RDMusic * music;

/** 字幕文字动画
 *  设置字幕动画组后，该属性无效
 */
@property (nonatomic, strong) RDCaptionAnimate * textAnimate;

/**字幕背景图动画
 *  设置字幕动画组后，该属性无效
 */
@property (nonatomic, strong) RDCaptionAnimate * imageAnimate;

/** 字幕动画组
 */
@property (nonatomic, strong) NSArray<RDCaptionCustomAnimate*>* animate;

/******************************以下参数已废弃******************************/

/** 字幕图片文件路径
 */
@property (nonatomic ,copy) NSString * imagePath        DEPRECATED_MSG_ATTRIBUTE("Use imageFolderPath instead.");

/**图片数量
 */
@property (nonatomic ,assign) NSInteger imageCounts     DEPRECATED_ATTRIBUTE;

/**字幕中心坐标点比例
 */
@property (nonatomic ,assign) CGPoint captionCenter     DEPRECATED_ATTRIBUTE;

/**字幕宽度点比例
 */
@property (nonatomic ,assign) CGFloat widthProportion   DEPRECATED_ATTRIBUTE;

/** 字幕图片文件路径
 */
@property (nonatomic ,copy) NSString * path    DEPRECATED_MSG_ATTRIBUTE("Use imagePath instead.");

/**图片前缀名字
 */
@property (nonatomic ,copy) NSString * name    DEPRECATED_MSG_ATTRIBUTE("Use imageName instead.");

/**多少图片
 */
@property (nonatomic ,assign) NSInteger count           DEPRECATED_MSG_ATTRIBUTE("Use imageCounts instead.");

/**字幕区域
 */
@property (nonatomic ,assign) CGRect frame              DEPRECATED_MSG_ATTRIBUTE("Use position instead.");

/** 字幕是否需要拉伸
 */
@property (nonatomic, assign) BOOL tStretching          DEPRECATED_MSG_ATTRIBUTE("Use isStretch instead.");

/**字幕拉伸的区域
 */
@property (nonatomic ) CGRect contentsCenter            DEPRECATED_MSG_ATTRIBUTE("Use stretchRect instead.");

/**id
 */
@property (nonatomic ,assign) NSInteger pid             DEPRECATED_ATTRIBUTE;

/**字幕帧率
 */
@property (nonatomic ,assign) CGFloat fps               DEPRECATED_ATTRIBUTE;

/**文字开始时间
 */
@property (nonatomic ,assign) float  tBegin             DEPRECATED_ATTRIBUTE;

/**文字结束时间
 */
@property (nonatomic ,assign) float  tEnd               DEPRECATED_ATTRIBUTE;

/**帧动画
 */
@property (nonatomic ,strong) NSArray * frames DEPRECATED_MSG_ATTRIBUTE("Use frameArray instead.");

/**时间动画
 */
@property (nonatomic ,strong) NSArray * times  DEPRECATED_MSG_ATTRIBUTE("Use timeArray instead.");

/***********************************************************************/

@end

/** 可设置字幕每帧的动画
 */
@interface RDCaptionLightCustomAnimate : NSObject

/**开始时间
 */
@property (nonatomic,assign) CGFloat atTime;

/**透明度(0.0~1.0)，默认1.0
 */
@property (nonatomic,assign) CGFloat opacity;

/**在video中四个顶点的坐标，可设置非矩形。
 * (0, 0)为左上角 (1, 1)为右下角
 * rect与pointsArray只有一个有效，以最后设置的为准
 */
@property (nonatomic, readonly) NSArray *pointsArray;

/**在video中四个顶点的坐标，可设置非矩形，设置的值将赋给pointsArray属性。
 * (0, 0)为左上角 (1, 1)为右下角
 *  @param leftTop      媒体在video中的 左上角 顶点坐标
 *  @param rightTop     媒体在video中的 右上角 顶点坐标
 *  @param rightBottom  媒体在video中的 右下角 顶点坐标
 *  @param leftBottom   媒体在video中的 左下角 顶点坐标
 *
 * rect与pointsArray只有一个有效，以最后设置的为准
 */
- (NSArray *)setPointsLeftTop:(CGPoint)leftTop
                     rightTop:(CGPoint)rightTop
                  rightBottom:(CGPoint)rightBottom
                   leftBottom:(CGPoint)leftBottom;

@end

/** 非矩形字幕
 */
@interface RDCaptionLight : NSObject

/** 字幕时间范围
 */
@property (nonatomic ,assign) CMTimeRange timeRange;

/** 字幕图片路径
 */
@property (nonatomic ,copy) NSString * imagePath;

/**是否淡入淡出，默认NO
 */
@property (nonatomic, assign) BOOL isFade;

/**淡入时长，默认为1.0
 */
@property (nonatomic, assign) float fadeInDuration;

/**淡出时长，默认为1.0
 */
@property (nonatomic, assign) float fadeOutDuration;

/**在video中四个顶点的坐标，可设置非矩形。
 * (0, 0)为左上角 (1, 1)为右下角
 * 设置媒体动画后，该属性无效，以动画中的pointsArray值为准
 */
@property (nonatomic, readonly) NSArray *pointsInVideoArray;

/**在video中四个顶点的坐标，可设置非矩形，设置的值将赋给pointsInVideoArray属性。
 * (0, 0)为左上角 (1, 1)为右下角
 *  @param leftTop      媒体在video中的 左上角 顶点坐标
 *  @param rightTop     媒体在video中的 右上角 顶点坐标
 *  @param rightBottom  媒体在video中的 右下角 顶点坐标
 *  @param leftBottom   媒体在video中的 左下角 顶点坐标
 *
 * 设置媒体动画后，该属性无效，以动画中的pointsArray值为准
 */
- (NSArray *)setPointsInVideoLeftTop:(CGPoint)leftTop
                            rightTop:(CGPoint)rightTop
                         rightBottom:(CGPoint)rightBottom
                          leftBottom:(CGPoint)leftBottom;

/** 字幕动画组
 */
@property (nonatomic, strong) NSArray<RDCaptionLightCustomAnimate*>* animateList;

@end

/** 动画中的文字资源
 */
@interface RDJsonText : NSObject

/**标识符,可用于实时改变文字的时间等
 */
@property (nonatomic, copy) NSString *identifier;

/**在json中的大小
 */
@property (nonatomic ,assign) CGSize size;

/** 修改文字的开始显示时间
 *  默认为-1,不修改，按照json文件中的设置显示
 *  仅对json中都是可变文字的有效
 */
@property (nonatomic, assign) float startTime;

/** 修改文字的显示时长
 *  默认为-1,不修改，按照json文件中的设置显示
 *  仅对json中都是可变文字的有效
 */
@property (nonatomic, assign) float duration;

/** 文字图片
 */
@property (nonatomic ,copy) NSString * imagePath;

/**文字内容
 *  设置该属性后，imagePath将无效
 */
@property (nonatomic ,copy) NSString * text;

/**文字对齐方式 默认为RDCaptionTextAlignmentCenter
 */
@property (nonatomic ,assign) RDCaptionTextAlignment textAlignment;

/**文字颜色，默认为whiteColor
 */
@property (nonatomic ,strong) UIColor * textColor;

/** 文字透明度(0.0〜1.0),默认为1.0
 */
@property (nonatomic ,assign) float alpha;

/** 文字竖排，默认为NO
 *  仅支持一列
 */
@property (nonatomic ,assign) BOOL isVerticalText;

/**文字字体名称
 */
@property (nonatomic ,copy) NSString * fontName;

/**文字字体大小，为0时将自适应字体大小
 */
@property (nonatomic ,assign) float fontSize;

/**文字边距
 */
@property (nonatomic ,assign) UIEdgeInsets edgeInsets;

/**文字字体加粗，默认为NO
 */
@property (nonatomic ,assign) BOOL isBold;

/**文字字体斜体，默认为NO
 */
@property (nonatomic ,assign) BOOL isItalic;

/**文字描边颜色，默认黑色blackColor
 */
@property (nonatomic ,strong) UIColor * strokeColor;

/**文字描边宽度,默认为0.0
 */
@property (nonatomic ,assign) float strokeWidth;

/** 文字描边透明度(0.0〜1.0),默认为1.0
 */
@property (nonatomic, assign) float strokeAlpha;

/**文字是否设置阴影，默认为NO
 */
@property (nonatomic ,assign) BOOL isShadow;

/**文字阴影颜色，默认黑色blackColor
 */
@property (nonatomic ,strong) UIColor * shadowColor;

/**文字阴影偏移量,默认为CGSizeMake(0, -1)
 */
@property (nonatomic ,assign) CGSize shadowOffset;

@end

/** AE生成json文件动画所需要的背景资源(视频或图片)
 */
@interface RDJsonAnimationBGSource : NSObject

/** 标识符
 */
@property (nonatomic,strong) NSString*  identifier;

/** 资源文件路径
 */
@property (nonatomic, copy) NSString *path;

/**  资源类型 图片 或者 视频，默认RDAssetTypeVideo
 */
@property (nonatomic,assign) RDAssetType type;

/**  图片填充类型，默认为RDImageFillTypeFit
 */
@property (nonatomic,assign) RDImageFillType  fillType;

/**  视频填充类型，默认为RDVideoFillTypeFit
 */
@property (nonatomic,assign) RDVideoFillType  videoFillType;

/**视频(或图片)裁剪范围。默认为CGRectMake(0, 0, 1, 1)
 */
@property (nonatomic, assign) CGRect crop;

/** 资源显示时间段  开始 与 持续时间
 *  图片设置持续时间  视频可以指定时间段
 */
@property (nonatomic,assign) CMTimeRange timeRange;

/** 在整个视频中的持续时间范围
 */
@property (nonatomic ,assign) CMTimeRange timeRangeInVideo;

/**  在整个视频中的开始时间
 */
@property (nonatomic,assign) CMTime startTimeInVideo DEPRECATED_MSG_ATTRIBUTE("Use timeRangeInVideo instead.");

/**  音量  默认为1.0
 */
@property (nonatomic,assign) float volume;

/**是否重复播放，默认为NO
 */
@property (nonatomic, assign) BOOL isRepeat;

/** 配乐
 */
@property (nonatomic, strong) RDMusic *music;

@end

/** AE生成json文件动画
 */
@interface RDJsonAnimation : NSObject

/** 动画唯一名称
 */
@property (nonatomic, copy) NSString *name  DEPRECATED_ATTRIBUTE;

/** json文件路径
 */
@property (nonatomic, copy) NSString *jsonPath;

/** json文件路径字典
 *  与jsonPath二者设置其一即可，以jsonPath优先
*/
@property (nonatomic, strong) NSDictionary *jsonDictionary;

/** 动画所有固定图片路径
 */
@property (nonatomic, strong) NSArray *nonEditableImagePathArray;

/** 动画背景视频/图片
 */
@property (nonatomic, strong) NSMutableArray <RDScene *>*bgSourceArray;
@property (nonatomic, strong) NSArray <RDJsonAnimationBGSource *>*backgroundSourceArray DEPRECATED_MSG_ATTRIBUTE("Use bgSourceArray instead.");

/** 动画中所有文字资源
 *  须与json中的显示顺序一致，可通过接口getAESourceInfoWithJosnPath:获取资源的信息
 */
@property (nonatomic, strong) NSArray <RDJsonText *>*textSourceArray;

/** 导出帧率，默认为18
 */
@property (nonatomic, assign) int exportFps;

/** 动画中图片裁剪后最大宽或高，默认为720.0
 *  对于1080P的图片，设置为720会导致图片不清晰，可根据需求设置
 */
@property (nonatomic, assign) float targetImageMaxSize;

/**是否循环播放，默认为NO
 */
@property (nonatomic, assign) BOOL  isRepeat;

@property (nonatomic, assign) BOOL  ispiantou;
@property (nonatomic, assign) BOOL  ispianwei;
@property (nonatomic, assign) BOOL  isJson1V1;

@end

typedef NS_ENUM(NSInteger, RDAESourceType) {
    RDAESourceType_Irreplaceable,           //不可替换
    RDAESourceType_ReplaceableText,         //可替换文字
    RDAESourceType_ReplaceablePic,          //可替换图片
    RDAESourceType_ReplaceableVideoOrPic,   //可替换视频或图片
};

@interface RDAESourceInfo : NSObject

/** 资源名称
 */
@property (nonatomic, assign) RDAESourceType type;

/** 资源名称
 */
@property (nonatomic, strong) NSString *name;

/** 资源大小
 */
@property (nonatomic, assign) CGSize size;

/** 资源显示开始时间
 */
@property (nonatomic, assign) float startTime;

/** 资源显示时长
 */
@property (nonatomic, assign) float duration;

@end

@interface RDPostion : NSObject

@property(nonatomic,assign)float postion;
@property(nonatomic,assign)float atTime;
@end


/** 去水印
 */
@interface RDDewatermark : NSObject

/** 去水印时间范围
 */
@property (nonatomic ,assign) CMTimeRange timeRange;

/**在video中的位置大小，默认CGRectMake(0, 0, 1, 1)
 * (0, 0)为左上角 (1, 1)为右下角
 */
@property (nonatomic,assign) CGRect rect;

@end





/** 视频水印
 */
@interface RDWatermark : NSObject

/** 持续时间范围
 */
@property (nonatomic ,assign) CMTimeRange timeRange;

/** 媒体
 */
@property (nonatomic,strong) VVAsset*  vvAsset;

/**是否循环播放，默认为YES
 */
@property (nonatomic, assign) BOOL isRepeat;



@end

/** 马赛克
 */
@interface RDMosaic : NSObject

/** 时间范围
 */
@property (nonatomic ,assign) CMTimeRange timeRange;

/** 马赛克大小(0.0~1.0)，默认为0.1
 */
@property (nonatomic, assign) float mosaicSize;

/**在video中四个顶点的坐标，可设置非矩形。
 * (0, 0)为左上角 (1, 1)为右下角
 */
@property (nonatomic, readonly) NSArray *pointsArray;


/**在video中四个顶点的坐标，可设置非矩形，设置的值将赋给pointsArray属性。
 * (0, 0)为左上角 (1, 1)为右下角
 *  @param leftTop      媒体在video中的 左上角 顶点坐标
 *  @param rightTop     媒体在video中的 右上角 顶点坐标
 *  @param rightBottom  媒体在video中的 右下角 顶点坐标
 *  @param leftBottom   媒体在video中的 左下角 顶点坐标
 */
- (NSArray *)setPointsLeftTop:(CGPoint)leftTop
                     rightTop:(CGPoint)rightTop
                  rightBottom:(CGPoint)rightBottom
                   leftBottom:(CGPoint)leftBottom;

@end
