//
//  RDCameraManager.h
//  RDVECore
//
//  Created by 周晓林 on 16/4/8.
//  Copyright © 2016年 Solaren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <Accelerate/Accelerate.h>
#import "RDCameraFile.h"

@interface RDFilter : NSObject

typedef enum {
    kRDFilterType_YuanShi = 0,        // 原始
    kRDFilterType_HeiBai,             // 黑白
    kRDFilterType_SuiYue,             // 岁月
    kRDFilterType_FanXiang,           // 反向
    kRDFilterType_BianYuan,           // 边缘
    kRDFilterType_NiuQu,              // 扭曲
    kRDFilterType_Turn,               // 反转
    kRDFilterType_SLBP,               // SLBP
    kRDFilterType_Sketch,             // 素描
    kRDFilterType_DistortingMirror,   // 哈哈镜
    kRDFilterType_ACV,                // acv滤镜
    kRDFilterType_LookUp              // lookup滤镜
} RDFilterType;

typedef NS_ENUM(NSInteger, RDCameraSwipeDirection) {
    kRDCameraSwipeDirectionNone    = -1,
    kRDCameraSwipeDirectionLeft    = 0,
    kRDCameraSwipeDirectionRight   = 1,
    kRDCameraSwipeDirectionUp      = 2,
    kRDCameraSwipeDirectionDown    = 3,
};

/**滤镜类型
 */
@property (nonatomic,assign)RDFilterType type;

/**滤镜名称
 */
@property (nonatomic,copy  )NSString *name;

/**滤镜资源地址
 */
@property (nonatomic,copy  )NSString *filterPath;

/**滤镜强度，kRDFilterType_LookUp时有效,默认为1.0
 */
@property (nonatomic, assign)float intensity;

/**网络封面地址
 */
@property (nonatomic,copy  )NSString *netCover;
/**网络滤镜资源地址
 */
@property (nonatomic,copy  )NSString *netFile;

/**滤镜acv地址
 */
@property (nonatomic,copy  )NSString *acvPath       DEPRECATED_MSG_ATTRIBUTE("Use filterPath instead.");

@end

@class RDGPUImageFilter;
@class RDGPUImageVideoCamera;
@class RDGPUImageView;

@protocol RDCameraManagerDelegate <NSObject>
@optional

/** 摄像头捕获帧回调，可对帧进行处理
 */
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/** 滑动切换到的当前滤镜Index
 */
- (void) sendFilterIndex:(NSInteger) index;

/** 聚焦时回调
 */
- (void) tapTheScreenFocus;

/** 启用预览(startCamera)后回调。
 *  可用于收到此回调前，界面上录制相关按钮不可用。
 */
- (void) cameraScreenDid;

/** 当前录制时间
 */
- (void) currentTime:(float) time;

/** 滑动录制预览视图开始
 *  @params swipDirection 滑动方向
 */
- (void) swipeScreenBegin:(RDCameraSwipeDirection)swipDirection;

/** 滑动录制预览视图中
 *  @param percent  滑动动预览视图中的位置
 *  @param swipDirection 滑动方向
 */
- (void) swipeScreenChanging:(float)percent swipDirection:(RDCameraSwipeDirection)swipDirection;

/** 滑动录制预览视图结束
 *  @params swipDirection 滑动方向
 */
- (void) swipeScreenChangeEnd:(RDCameraSwipeDirection)swipDirection;

/** 相机水印回调，实时添加图片等
 *  @params view    在此view上添加
 *  @params time    当前录制总时间
 */
- (void)waterMarkProcessingCompletionBlockWithView:(UIView *)view withTime:(float)time;
/** 已经录制的时间
 */
- (float ) recordTime;

/** 录制开始
 */
- (void) movieRecordBegin;

/** 录制取消
 */
- (void) movieRecordCancel;

/** 录制结束
 */
- (void) movieRecordingCompletion:(NSURL *) videoUrl;

/** 录制失败
 */
- (void) movieRecordFailed:(NSError *)error;

/** 多格录制时，为处理多格音频同步问题，而截取掉的时长
 */
- (void) movieFileTrimTime:(float)trimTime;

- (void) refresFinsishState;
@end

typedef NS_ENUM(NSInteger,BeautifyState) {
    BeautifyStateNormal,
    BeautifyStateSeleted,
};

typedef NS_ENUM(NSInteger, CameraDirection) {
    kUP,
    kDOWN,
    kLEFT,
    kRIGHT
};

typedef NS_ENUM(NSInteger, VideoRecordStatus) {
    VideoRecordStatusBegin,
    VideoRecordStatusPause,
    VideoRecordStatusCancel,
    VideoRecordStatusResume,
    VideoRecordStatusEnd,
    VideoRecordStatusUnknown,
};

typedef NS_ENUM(NSUInteger, RDCameraFillMode) {
    kRDCameraFillModeStretch,
    kRDCameraFillModeScaleAspectFit,
    kRDCameraFillModeScaleAspectFill
};

@interface RDCameraManager : NSObject

/** 录制预览视图
 */
@property (nonatomic , strong) RDGPUImageView *cameraScreen;

/** 摄像头显示方式。默认kRDCameraFillModeScaleAspectFit
 */
@property (nonatomic , assign) RDCameraFillMode fillMode;

/** 左右滑动录制预览视图时，是否切换滤镜。默认为YES(可切换)
 *  使用该功能时，须所有滤镜资源都在本地，不能是网络资源
 */
@property (nonatomic, assign) BOOL swipeScreenIsChangeFilter;

/** 前后置摄像头
 */
@property (nonatomic , assign) AVCaptureDevicePosition position;

/** 闪光灯模式
 */
@property (nonatomic , assign) AVCaptureTorchMode flashMode;

/** 防抖
 */
@property (nonatomic , assign) BOOL enableAntiShake;

/** 是否正在录制
 */
@property (nonatomic , readonly) BOOL isRecording;

/** 录制状态
 */
@property (nonatomic , assign) VideoRecordStatus recordStatus;

/** 美颜状态
 */
@property (nonatomic , assign) BeautifyState beautifyState;

/** 视频预览分辨率
 */
@property (nonatomic , assign) CGSize cameraSize;

/** 录制视频输出分辨率
 */
@property (nonatomic , assign) CGSize outputSize;

/** 录制视频码率
 */
@property (nonatomic , assign) int bitrate;

/** 录制视频帧率
 */
@property (nonatomic , assign) int fps;

/** 关键帧 如果设置为1 每帧都是关键帧
 */
 @property (nonatomic , assign) int keyFps;

/** 录制音频通道数   默认为：1
 */
@property (nonatomic , assign) int audioChannelNumbers;

/** 录制是否静音(不录制声音)  默认为：NO
 */
@property (nonatomic , assign) BOOL isMute;

/** 录制视频方式：YES:正方形   NO:全屏
 */
@property (nonatomic , assign) BOOL mode;

/** 锐动美颜  美白参数 0.0 - 1.0 默认 0.0
 */
@property (nonatomic, assign) float brightness;
/** 锐动美颜  磨皮参数 0.0 - 1.0 默认0.5
 */
@property (nonatomic, assign) float blur;

/** 摄像头方向，默认为kUP
 */
@property (nonatomic , assign) CameraDirection cameraDirection;

/** 用于处理多格子录制音频同步问题
 *  录制前音频播放器时间,播放器播放前设置
 */
@property (nonatomic , assign) CMTime audioTime_beforePlay;
/** 停止录制时音频播放器时间,调用stopRecording前设置
 */
@property (nonatomic , assign) CMTime audioTime_stopPlay;

/** 设置录制文件路径，默认为Documents/videos
 */
@property (nonatomic , strong) NSString *tempVideoFolderPath;

/** 设置Mask资源路径，可实现不规则显示
 *  改变录制预览视图位置大小后，都需要重新设置
 */
@property (nonatomic , copy) NSString *maskPath;

@property (nonatomic , weak) id<RDCameraManagerDelegate> delegate;


/**  初始化对象
 *
 *  @param appkey          在锐动SDK官网(http://www.rdsdk.com/ )中注册的应用Key。
 *  @param appsecret       在锐动SDK官网(http://www.rdsdk.com/ )中注册的应用秘钥。
 *  @param licenceKey      在锐动SDK官网(http://www.rdsdk.com/ )中注册的licenceKey。
 *  @param resultFailBlock 初始化失败的回调［error：初始化失败的错误码］
 */
- (instancetype) initWithAPPKey:(NSString *)appkey
                      APPSecret:(NSString *)appsecret
                     LicenceKey:(NSString *)licenceKey
                     resultFail:(void (^)(NSError *error))resultFailBlock;

- (instancetype) initWithAPPKey:(NSString *)appkey
                      APPSecret:(NSString *)appsecret
                     resultFail:(void (^)(NSError *error))resultFailBlock;

/** 录制之前准备，用于设置录制相关参数。
 *  @param  frame           录制预览视图位置大小
 *  @param  superview       源视图控制器。如要设置Mask资源路径，则该view的背景色必须为透明色([UIColor clearColor])。
 *  @param  bitrate         录制码率
 *  @param  fps             录制帧率
 *  @param  isSquareRecord  录制视频方式：YES:正方形   NO:全屏
 *  @param  cameraSize      视频预览分辨率
 *  @param  outputSize      录制视频输出分辨率
 *  @param  isFront         是否是前置摄像头录制
 *  @param  isCaptureAsYUV  输出图像格式。YES:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange NO:kCVPixelFormatType_32BGRA
 *  @param  disableTakePhoto 是否禁用相机拍照功能
 *  @param  enableCameraWaterMark 是否启用相机水印功能
 *  @param  enableRdBeauty  是否锐动美颜功能，如已经使用faceU等其它美颜功能，则设为NO
 *  特别提醒: cameraSize,outputSize 请传入相同的宽高比,cameraSize和outputSize的宽高比不一样会导致输出视频变形
 */
- (void) prepareRecordWithFrame: (CGRect) frame
                      superview: (UIView *) superview
                        bitrate: (int) bitrate
                            fps: (int) fps
                 isSquareRecord: (BOOL) isSquareRecord
                     cameraSize: (CGSize) cameraSize
                     outputSize: (CGSize) outputSize
                        isFront: (BOOL) isFront
                   captureAsYUV: (BOOL) isCaptureAsYUV
               disableTakePhoto: (BOOL) disableTakePhoto
          enableCameraWaterMark: (BOOL) enableCameraWaterMark
                 enableRdBeauty: (BOOL) enableRdBeauty;

/** 录制之前准备，用于设置录制相关参数。
 *  @param  frame           录制预览视图位置大小
 *  @param  superview       源视图控制器。如要设置Mask资源路径，则该view的背景色必须为透明色([UIColor clearColor])。
 *  @param  bitrate         录制码率
 *  @param  fps             录制帧率
 *  @param  mode            录制视频方式：YES:正方形   NO:全屏
 *  @param  cameraSize      视频预览分辨率
 *  @param  outputSize      录制视频输出分辨率
 *  @param  isFront         是否是前置摄像头录制
 *  @param  faceU           是否使用faceU   20190906 为了方便sdk的使用，将faceU移到sdk外
 *  @param  isCaptureAsYUV  输出图像格式。YES:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange NO:kCVPixelFormatType_32BGRA
 *  @param  disableTakePhoto 是否禁用相机拍照功能
 *  特别提醒: cameraSize,outputSize 请传入相同的宽高比,cameraSize和outputSize的宽高比不一样会导致输出视频变形
 */
- (void) prepareRecordWithFrame: (CGRect) frame
                      superview: (UIView *) superview
                        bitrate: (int) bitrate
                            fps: (int) fps
                           mode: (BOOL) mode
                     cameraSize: (CGSize) cameraSize
                     outputSize: (CGSize) outputSize
                        isFront: (BOOL) isFront
                          faceU: (BOOL) faceU
                   captureAsYUV: (BOOL) isCaptureAsYUV
               disableTakePhoto: (BOOL) disableTakePhoto DEPRECATED_MSG_ATTRIBUTE("Use prepareRecordWithFrame:superview:bitrate:fps:isSquareRecord:cameraSize:outputSize:isFront:captureAsYUV:disableTakePhoto:enableCameraWaterMark: instead.");;

/** 录制之前准备，用于设置录制相关参数。
 *  @param  frame           录制预览视图位置大小
 *  @param  superview       源视图控制器。如要设置Mask资源路径，则该view的背景色必须为透明色([UIColor clearColor])。
 *  @param  bitrate         录制码率
 *  @param  fps             录制帧率
 *  @param  mode            录制视频方式：YES:正方形   NO:全屏
 *  @param  cameraSize      视频预览分辨率
 *  @param  outputSize      录制视频输出分辨率
 *  @param  isFront         是否是前置摄像头录制
 *  @param  faceU           是否使用faceU   20190906 为了方便sdk的使用，将faceU移到sdk外
 *  @param  isCaptureAsYUV  输出图像格式。YES:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange NO:kCVPixelFormatType_32BGRA
 *  @param  disableTakePhoto 是否禁用相机拍照功能
 *  @param  enableCameraWaterMark 是否启用相机水印功能
 *  特别提醒: cameraSize,outputSize 请传入相同的宽高比,cameraSize和outputSize的宽高比不一样会导致输出视频变形
 */
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
              enableCameraWaterMark:(BOOL)enableCameraWaterMark DEPRECATED_MSG_ATTRIBUTE("Use prepareRecordWithFrame:superview:bitrate:fps:isSquareRecord:cameraSize:outputSize:isFront:captureAsYUV:disableTakePhoto:enableCameraWaterMark: instead.");;

/** 设置设备当前方向
 */
- (void)setDeviceOrientation:(UIDeviceOrientation)orientation;

- (void)refreshRecordTime;
/**使用音乐路径
 */
- (void)setMusic:(NSURL *)musicUrl;

/** 播放音乐  rate（极慢:1.0/3.0 慢:1.0/2.0 正常:1.0 快:2.0 极快:3.0） 
 */
- (void)playMusic:(float)rate;

/** 暂停音乐
 */
- (void)pauseMusic;

/** 停止播放音乐
 */
- (void)stopMusic;

/** 启用预览
 */
- (void) startCamera;

/** 关闭预览
 */
- (void) stopCamera;

/** 开始录制
 */
- (void) beginRecording;

/** 停止录制
 */
- (void) stopRecording;

/** 设置对焦图片
 */
- (void) setfocus;

/** 设置截取比例 0.0 ~ 1.0 默认1.0
 */
- (void) updateCropRegion: (float) rate;

/** 设置录制预览视图位置大小
 */
- (void) setVideoViewFrame:(CGRect ) rect;

/** 添加滤镜组
 */
- (void) addFilters:(NSArray <RDFilter *> *) filters;
- (NSArray *)getFilters;
/** 设置滤镜
 */
- (void) setFilterAtIndex:(NSInteger ) index;
- (void)resetFilter:(RDFilter *)obj AtIndex:(NSInteger)index;
/** 移除滤镜组
 */
- (void) removeFilters;
/** MV特效
 */
- (void)setMVEffects:(NSMutableArray <RDCameraMVEffect *> *)mvEffects;

/** 拍照
 */
- (void) takePhoto:(UIImageOrientation)orientation block:(void(^)(UIImage* image)) func;

/** 聚焦
 */
- (void) focus:(UITapGestureRecognizer *)tap;

/**曝光(0.0~1.0)
 */
- (void) exposure:(CGFloat) iso;

/** 焦距
 */
- (void) zoom:(CGFloat) zoom;

/** 切换录制视频方式
 *  @parma mode:YES:正方形   NO:全屏
 *  @parma frame:录制预览视图位置大小
 */
- (void) changeMode:(BOOL) mode cameraScreenFrame:(CGRect)frame;

/** 录制完成后移除
 */
- (void) deleteItems;

/** 获取录制状态
 */
- (int ) assetWriterStatus;
/** 合并录制文件
 */
- (void)mergeAndExportVideosAtFileURLs:(NSArray<RDCameraFile *> *)fileArray
                              progress:(void(^)(NSNumber *progress))progressBlock
                                finish:(void(^)(NSURL *videourl))finish
                                  fail:(void(^)(NSError *error))fail
                                cancel:(void(^)(void))cancel;

/** 取消合并
 */
- (void)cancelMerge;

/** 获取录制文件保存路径
 */
- (NSString *)getVideoSaveFileFolderString;

/** 倒序
 *params: url           视频源地址
 *params: outputUrl     输出路径
 *params: timeRange     倒序时间范围
 *params: progressBlock 倒序进度回调
 *params: callbackBlock 结束回调
 *params: failBlock     失败回调
 */
- (void)exportReverseVideo:(NSURL *)url
                  outputUrl:(NSURL *)outputUrl
                  timeRange:(CMTimeRange)timeRange
              progressBlock:(void (^)(NSNumber *prencent))progressBlock
             callbackBlock:(void(^)(void))callbackBlock
                      fail:(void(^)(void))failBlock;

/** 获取录制视频分辨率
 */
+ (CGSize)defaultMatchSize;

/** 获取带滤镜的缩略图
 */
+ (void) returnImageWith:(UIImage *)inputImage
                  Filter:(RDFilter *)obj
   withCompletionHandler:(void (^)(UIImage *processedImage))block;

@end

