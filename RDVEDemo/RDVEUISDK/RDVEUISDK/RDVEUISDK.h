//
//  RDVEUISDK.h
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2017/7/15.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "RDVEUISDKConfigure.h"

@interface RDVEUISDK : NSObject<NSMutableCopying,NSCopying>

NS_ASSUME_NONNULL_BEGIN
@property (nonatomic,weak) id <RDVEUISDKDelegate> delegate;
/**   视频导出设置
 */
@property (nonatomic,strong) ExportConfiguration     *exportConfiguration;
/**   编辑设置
 */
@property (nonatomic,strong) EditConfiguration        * editConfiguration;
/**  拍摄功能设置
 */
@property (nonatomic,strong) CameraConfiguration    * cameraConfiguration;
/**  语言设置
 */
@property (nonatomic,assign) SUPPORTLANGUAGE language;

/**相册选择视频完成回调
 */
@property (nonatomic,copy)RdVEAddVideosAndImagesCallbackBlock addVideosAndImagesCallbackBlock;
@property (nonatomic,copy)RdVEAddVideosCallbackBlock addVideosCallbackBlock;
@property (nonatomic,copy)RdVEAddImagesCallbackBlock addImagesCallbackBlock;

@property (assign, nonatomic) RecordVideoSizeType recordSizeType;
@property (assign, nonatomic) RecordVideoOrientation recordOrientation;

@property (assign, nonatomic) UIInterfaceOrientation deviceOrientation;
@property (assign, nonatomic) BOOL                   orientationLock;

/** 自定义截取返回方式(先设置此参数再调截取函数)
 */
@property(nonnull, copy) void (^rd_CutVideoReturnType)(RDCutVideoReturnType*);

/**  截取完成回调
 *
 *  cutType         :截取方式
 *  asset/videoPath :截取后文件(路径)
 *  startTime       :截取开始时间
 *  endTime         :截取结束时间
 *  cropRect        :裁剪视频区域 如裁剪为原始比例时，cropRect为CGRectMake(0, 0, 1, 1)
 *
 */
typedef void (^RdVE_TrimAssetCallbackBlock)(RDCutVideoReturnType cutType,AVURLAsset *asset,CMTime startTime,CMTime endTime, CGRect cropRect);
typedef void (^RdVE_TrimVideoPathCallbackBlock)(RDCutVideoReturnType cutType,NSString * videoPath,CMTime startTime,CMTime endTime, CGRect cropRect);

#pragma mark- 初始化SDK
/**  初始化对象
 *
 *  @param appkey          appkey description
 *  @param appsecret       appsecret description
 *  @param resultFailBlock 返回错误信息
 */
- (instancetype) initWithAPPKey:(NSString *)appkey
                      APPSecret:(NSString *)appsecret
                     LicenceKey:(NSString *)licenceKey
                     resultFail:(RdVEFailBlock )resultFailBlock;
/**  初始化对象
 *
 *  @param appkey          appkey description
 *  @param appsecret       appsecret description
 *  @param resultFailBlock 返回错误信息
 */
- (instancetype) initWithAPPKey:(NSString *)appkey
                      APPSecret:(NSString *)appsecret
                     resultFail:(RdVEFailBlock )resultFailBlock;



#pragma mark - 打开相册
/**选择视频或图片
 * @param viewController  源控制器
 * @param albumType 选择相册类型（仅选图片，仅选视频，两者皆可）
 * @param callbackBlock 相册选择完成返回一个NSURL数组 NSMutableArray <NSURL *> *List
 * @param cancelBlock 取消选择相册资源
 */
- (BOOL)onRdVEAlbumWithSuperController:(UIViewController *)viewController
                            albumType:(ALBUMTYPE)albumType
                            callBlock:(OnAlbumCallbackBlock) callbackBlock
                          cancelBlock:(RdVECancelBlock) cancelBlock;



#pragma mark- 截取视频
/**  截取视频 通过传入视频对象 AVUrlAsset
 *  @param viewController               源控制器
 *  @param title                        导航栏标题
 *  @param backgroundColor              背景色
 *  @param cancelButtonTitle            取消按钮文字
 *  @param cancelButtonTitleColor       取消按钮标题颜色
 *  @param cancelButtonBackgroundColor  取消按钮背景色
 *  @param otherButtonTitle             完成按钮文字
 *  @param otherButtonTitleColor        完成按钮标题颜色
 *  @param otherButtonBackgroundColor   完成按钮背景色
 *  @param urlAsset                     数据源
 *  @param outputVideoPath              视频输出路径
 *  @param callbackBlock                截取完成回调
 *  @param failback                     截取失败回调
 *  @param cancelBlock                  取消截取回调
 
 */
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
                              cancel:(RdVECancelBlock     ) cancelBlock;

/**  截取视频 通过传入路径 path
 *  @param viewController               源控制器
 *  @param title                        导航栏标题
 *  @param backgroundColor              背景色
 *  @param cancelButtonTitle            取消按钮文字
 *  @param cancelButtonTitleColor       取消按钮标题颜色
 *  @param cancelButtonBackgroundColor  取消按钮背景色
 *  @param otherButtonTitle             完成按钮文字
 *  @param otherButtonTitleColor        完成按钮标题颜色
 *  @param otherButtonBackgroundColor   完成按钮背景色
 *  @param assetPath                    数据源
 *  @param outputVideoPath              视频输出路径
 *  @param callbackBlock                截取完成回调
 *  @param failback                     截取失败回调
 *  @param cancelBlock                  取消截取回调
 
 */
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
                              cancel:(RdVECancelBlock     ) cancelBlock;


/**设置截取返回类型
 */
- (void)trimVideoWithType:(RDCutVideoReturnType )type;

/**截取视频 开始时间 总长
 */
- (void)Intercept:(NSString *)InPath
        atOutPath:(NSString *)OutPath
      atStartTime:(float) startTime
   atDurationTime:(float) DurationTime
         atAppkey:(NSString *)appKey
      atappSecret:(NSString *)appSecret
atvideoAverageBitRate:(float) videoAverageBitRate
atSuccessCancelBlock:(SuccessCancelBlock)successCancelBlock
atFailCancelBlock:(FailCancelBlock)failCancelBlock;

#pragma mark- 编辑视频
/**   编辑短视频MV
 *
 *  @param viewController    源控制器
 *  @param urlAsset          视频源
 *  @param clipTimeRange     时间段
 *  @param crop              crop范围 default ：CGRectMake(0, 0, 1, 1)
 *  @param outputVideoPath   视频输出路径
 *  @param callbackBlock     完成编辑回调
 *  @param cancelBlock       取消编辑回调
 */
- (void)editVideoWithSuperController:(UIViewController *)viewController
                            urlAsset:(AVURLAsset *)urlAsset
                       clipTimeRange:(CMTimeRange )clipTimeRange
                                crop:(CGRect)crop
                          outputPath:(NSString *)outputVideoPath
                            callback:(RdVECallbackBlock )callbackBlock
                              cancel:(RdVECancelBlock )cancelBlock;

- (void)editVideoWithSuperController:(UIViewController *)viewController
                            urlAsset:(AVURLAsset *)urlAsset
                       clipTimeRange:(CMTimeRange )clipTimeRange
                                crop:(CGRect)crop
                           musicInfo:(RDMusicInfo *)musicInfo
                          outputPath:(NSString *)outputVideoPath
                            callback:(RdVECallbackBlock )callbackBlock
                              cancel:(RdVECancelBlock )cancelBlock;

/**   编辑视频(传入URL数组)
 *
 *  @param viewController    源控制器
 *  @param foldertype        缓存文件夹类型 （Documents、Library、Temp,None)
 *  @param appAlbumCacheName 需扫描的缓存文件夹名称
 *  @param urlsArray         视频/图片路径(NSMutableArray <NSURL*>)如：相册视频 assets-library://asset/asset...
 *  @param outputVideoPath   视频输出路径
 *  @param callbackBlock     完成编辑回调
 *  @param cancelBlock       取消编辑回调
 */
- (void)editVideoWithSuperController:(UIViewController *)viewController
                          foldertype:(FolderType)foldertype
                   appAlbumCacheName:(NSString *)appAlbumCacheName
                           urlsArray:(NSMutableArray *)urlsArray
                          outputPath:(NSString *)outputVideoPath
                            callback:(RdVECallbackBlock )callbackBlock
                              cancel:(RdVECancelBlock )cancelBlock;


- (void)editVideoWithSuperController:(UIViewController *)viewController
                          foldertype:(FolderType)foldertype
                   appAlbumCacheName:(NSString *)appAlbumCacheName
                           urlsArray:(NSMutableArray *)urlsArray
                           musicInfo:(RDMusicInfo *)musicInfo
                          outputPath:(NSString *)outputVideoPath
                            callback:(RdVECallbackBlock )callbackBlock
                              cancel:(RdVECancelBlock )cancelBlock;

#pragma mark - 草稿箱
- (void)editDraftWithSuperController:(UIViewController *)viewController
                          outputPath:(NSString *)outputVideoPath
                            callback:(RdVECallbackBlock)callbackBlock
                            failback:(RdVEFailBlock) failback
                              cancel:(RdVECancelBlock)cancelBlock;

#pragma mark - 照片电影
- (void)pictureMovieWithSuperController:(UIViewController *)viewController
                              UrlsArray:(NSMutableArray *)urlsArray
                             outputPath:(NSString *)outputVideoPath
                               callback:(RdVECallbackBlock )callbackBlock
                                 cancel:(RdVECancelBlock )cancelBlock;
#pragma mark- 多格 拼图
- (void)dogePuzzleWithSuperController:(UIViewController *)viewController
                                    UrlsArray:(NSMutableArray *)urlsArray
                                   outputPath:(NSString *)outputVideoPath
                                     callback:(RdVECallbackBlock )callbackBlock
                                       cancel:(RdVECancelBlock )cancelBlock;
#pragma mark- 多格 相册
- (BOOL)dogePuzzleOnRdVEAlbumWithSuperController:(UIViewController *)viewController
                                       albumType:(ALBUMTYPE)albumType
                                       callBlock:(OnAlbumCallbackBlock) callbackBlock
                                     cancelBlock:(RdVECancelBlock) cancelBlock;


//主题
- (void)pictureMovieWithSuperController_Theme:(UIViewController *)viewController
                                   UrlsArray:(NSMutableArray *)urlsArray
                                  outputPath:(NSString *)outputVideoPath
                                    callback:(RdVECallbackBlock )callbackBlock
                                      cancel:(RdVECancelBlock )cancelBlock;


- (void)AETemplateMovieWithSuperController:(UIViewController *)viewController
                                 UrlsArray:(NSMutableArray *)urlsArray
                                outputPath:(NSString *)outputVideoPath
                                    isMask:(BOOL)isMask
                                  callback:(RdVECallbackBlock )callbackBlock
                                    cancel:(RdVECancelBlock )cancelBlock;

- (void)AEHomeWithSuperController:(UIViewController *)viewController
                       outputPath:(NSString *)outputVideoPath
                         callback:(RdVECallbackBlock )callbackBlock
                           cancel:(RdVECancelBlock )cancelBlock;

- (void) audioFilterWithSuperController:(UIViewController *)viewController
                              UrlsArray:(NSMutableArray *)urlsArray
                              musicPath:(NSString*)musicPath
                             outputPath:(NSString*)outputVideoPath
                               callback:(RdVECallbackBlock)callbackBlock
                                 cancel:(RdVECancelBlock)cancelBlock;
#pragma mark- 录制视频

/** 录制视频 参数设置(cameraConfiguration)
 *  @param source        源视图控制器
 *  @param callbackBlock 完成录制回调(result ：0 表示MV 1表示视频)
 *  @param imagebackBlock 拍照完成回调
 *  @param cancelBlock   取消录制回调
 */

- (void)videoRecordAutoSizeWithSourceController: (UIViewController*)source
                                  callbackBlock: (RdVERecordCallbackBlock)callbackBlock
                                 imagebackBlock: (RdVECallbackBlock)imagebackBlock
                                     faileBlock: (RdVEFailBlock)failBlock
                                         cancel: (RdVECancelBlock)cancelBlock;
/** 拍摄 录制
 */
- (void)enter_RecordVideo:(UIViewController*) source
                    atTag:(NSInteger) tag
     photoPathCancelBlock:(PhotoPathCancelBlock)photoPathCancelBlock
    changeFaceCancelBlock:(ChangeFaceCancelBlock)changeFaceCancelBlock
     addFinishCancelBlock:(AddFinishCancelBlock)addFinishCancelBlock;

#pragma mark- 抖音录制
- (void)douYinRecordWithSourceController: (UIViewController*)source
                              recordType: (RDDouYinRecordType)recordType
                           callbackBlock: (RdVERecordCallbackBlock)callbackBlock
                          imagebackBlock: (RdVECallbackBlock)imagebackBlock
                              faileBlock: (RdVEFailBlock)failBlock
                                  cancel: (RdVECancelBlock)cancelBlock;

#pragma mark - 字说界面
- (void)aeTextAnimateWithSuperViewController:(UIViewController *)viewController
                                  outputPath:(NSString *)outputVideoPath
                                    callback:(RdVECallbackBlock)callbackBlock
                                      cancel:(RdVECancelBlock)cancelBlock;
#pragma mark - 字说
- (void)aeTextAnimateWithSuperController:(UIViewController *)viewController
                              outputPath:(NSString *)outputVideoPath
                                callback:(RdVECallbackBlock )callbackBlock
                                  cancel:(RdVECancelBlock )cancelBlock;

#pragma mark - 自绘
- (void)customDrawWithSuperController:(UIViewController *)viewController
                           outputPath:(NSString *)outputVideoPath
                             callback:(RdVECallbackBlock )callbackBlock
                               cancel:(RdVECancelBlock )cancelBlock;

#pragma mark - SmallFunctions
/** 单个媒体编辑
 *
 *  @param viewController    源控制器
 *  @param functionType      编辑类型
 *  @param urlArray          视频/图片路径如：相册视频 assets-library://asset/asset...
 *  @param outputVideoPath   视频输出路径
 *  @param callbackBlock     完成转码回调
 *  @param cancelBlock       取消转码回调
 */
- (void)singleMediaWithSuperController:(UIViewController *)viewController
                          functionType:(RDSingleFunctionType)functionType
                            outputPath:(NSString *)outputVideoPath
                              urlArray:(NSMutableArray <NSURL *>*)urlArray
                              callback:(RdVECallbackBlock)callbackBlock
                                cancel:(RdVECancelBlock)cancelBlock;

#pragma mark- 获取视频信息
/**获取视频信息 字典 width height fps bitrate
 *
 */
- (NSDictionary *) getVideoInformation:(AVURLAsset *)urlAsset;

#pragma mark- 压缩视频
/** 压缩视频 参数设置(ExportConfiguration)
 *  @param size            压缩输出分辨率
 *  @param bitrate         压缩输出比特率
 *  @param progressBlock   压缩进度回调
 *  @param callbackBlock   压缩完成回调
 *  @param failBlock       压缩失败回调
 */
- (void)compressVideoAsset:(AVURLAsset *)urlAsset
                outputPath:(NSString *)outputPath
                 startTime:(CMTime )startTime
                   endTime:(CMTime )endTime
                outputSize:(CGSize) size
             outputBitrate:(float) bitrate
                supperView:(UIViewController *)supperView
             progressBlock:(void (^)(float progress))progressBlock
             callbackBlock:(void (^)(NSString *videoPath))callbackBlock
                      fail:(void (^)(NSError *error))failBlock;
/** 取消导出
 */
- (void) compressCancel;

#pragma mark - 不规则媒体
- (void)shapedAssetWithSuperController:(UIViewController *)viewController
                              assetUrl:(NSURL *)assetUrl
                            outputPath:(NSString *)outputVideoPath
                              callback:(RdVECallbackBlock )callbackBlock
                                cancel:(RdVECancelBlock )cancelBlock;

/*
 *TODO:======================以下参数和接口不推荐使用=====================
 */

/**是否禁用片尾
 */
@property (nonatomic,assign)BOOL endWaterPicDisabled DEPRECATED_ATTRIBUTE;
/**片尾显示的用户名
 */
@property (nonatomic,copy,nonnull)NSString *endWaterPicUserName DEPRECATED_ATTRIBUTE;
/** 设置视频输出码率
 *
 *  @param videoAverageBitRate  码率(单位是M,默认是6M),建议设置大于1M
 */
- (void)setOutPutVideoAverageBitRate:(float)videoAverageBitRate DEPRECATED_ATTRIBUTE;


/**  截取视频(真正的截取，回传截取过后的视频)---->(老接口不推荐使用)
 *
 *  @param viewController  源控制器
 *  @param title           导航栏标题
 *  @param backgroundColor 背景色
 *  @param cancelButtonTitle 取消按钮文字
 *  @param cancelButtonTitleColor 取消按钮标题颜色
 *  @param cancelButtonBackgroundColor 取消按钮背景色
 *  @param otherButtonTitle  完成按钮文字
 *  @param otherButtonTitleColor  完成按钮标题颜色
 *  @param otherButtonBackgroundColor 完成按钮背景色
 *  @param assetPath       数据源
 *  @param outputVideoPath 视频输出路径
 *  @param callbackBlock   截取完成回调
 *  @param failback        截取失败回调
 *  @param cancelBlock     取消截取回调
 
 */

- (void)cutVideoWithSuperController:(UIViewController *)viewController
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
                             cancel:(RdVECancelBlock     ) cancelBlock DEPRECATED_MSG_ATTRIBUTE("老接口不推荐使用");
/**偏小截取时间 默认6s
 */
@property (nonatomic,assign) float minDuration DEPRECATED_ATTRIBUTE;
/**偏大截取时间 默认12s
 */
@property (nonatomic,assign) float maxDuration DEPRECATED_ATTRIBUTE;  // 默认 12s
/**默认选中小值还是大值
 */
@property (nonatomic,assign) RDdefaultSelectCutMinOrMax  defaultSelectMinOrMax DEPRECATED_ATTRIBUTE; //default kRDCutSelectDefaultMin

- (void)cutVideo_withCutType:(RDCutVideoReturnType )type DEPRECATED_MSG_ATTRIBUTE("老接口不推荐使用");

/**   视频录制(老接口不推荐使用)
 *
 *  @param source        源视图控制器
 *  @param postion       前/后置摄像头
 *  @param frameRate     帧率
 *  @param bitRate       码率
 *  @param size          录制视频尺寸
 *  @param record_Type   录制还是拍照
 *  @param outputPath    视频输出路径
 *  @param callbackBlock 完成录制回调
 *  @param cancelBlock   取消录制回调
 */

- (void)videoRecordWithSourceController: (UIViewController*)source
                         cameraPosition: (AVCaptureDevicePosition )postion
                              frameRate: (int32_t) frameRate
                                bitRate: (int32_t) bitRate
                             recordSize: (CGSize) size
                            Record_Type: (Record_Type)record_Type
                             outputPath: (NSString*)outputPath
                              videoPath: (RdVECallbackBlock)callbackBlock
                                 cancel: (RdVECancelBlock)cancelBlock DEPRECATED_MSG_ATTRIBUTE("老接口不推荐使用");


/**   自动选择录制合适尺寸(老接口不推荐使用)
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
- (void)videoRecordAutoSizeWithSourceController: (UIViewController*)source
                                 cameraPosition: (AVCaptureDevicePosition )postion
                                      frameRate: (int32_t)frameRate
                                        bitRate: (int32_t)bitRate
                                    Record_Type: (Record_Type)record_Type
                                     outputPath: (NSString*)outputPath
                                      videoPath: (RdVECallbackBlock)callbackBlock
                                         cancel: (RdVECancelBlock)cancelBlock DEPRECATED_MSG_ATTRIBUTE("老接口不推荐使用");



/**   录制方形视频(老接口不推荐使用)
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
                                                   cancel: (RdVECancelBlock)cancelBlock DEPRECATED_MSG_ATTRIBUTE("老接口不推荐使用");

/** 添加文字水印(老接口不推荐使用)
 *
 *  @param waterString 文字内容
 *  @param waterRect   水印在视频中的位置
 */
- (void)addTextWater:(NSString *)waterString waterRect:(CGRect)waterRect NS_DEPRECATED_IOS(6_0, 7_0) DEPRECATED_MSG_ATTRIBUTE("老接口不推荐使用");

/**   添加图片水印(老接口不推荐使用)
 *
 *  @param waterImage 水印图片
 *  @param waterRect  水印在视频中的位置
 */
- (void)addImageWater:(UIImage *)waterImage waterRect:(CGRect)waterRect NS_DEPRECATED_IOS(6_0, 7_0) DEPRECATED_MSG_ATTRIBUTE("老接口不推荐使用");


/**  编辑视频
 *
 *  @param viewController  源控制器
 *  @param assets          数据视频源(video:NSMutableArray <AVURLAsset*> image: NSMutableArray <NSString*>)
 *  @param outputVideoPath 视频输出路径
 *  @param callbackBlock   完成编辑回调
 *  @param cancelBlock     取消编辑回调
 */
- (void)editVideoWithSuperController:(UIViewController *)viewController
                              assets:(NSMutableArray *)assets
                          outputPath:(NSString *)outputVideoPath
                            callback:(RdVECallbackBlock )callbackBlock
                              cancel:(RdVECancelBlock )cancelBlock DEPRECATED_MSG_ATTRIBUTE("老接口不推荐使用");

/**   编辑视频(需扫描缓存文件夹)
 *
 *  @param viewController    源控制器
 *  @param foldertype        缓存文件夹类型 （Documents、Library、Temp)
 *  @param appAlbumCacheName 需扫描的缓存文件夹名称
 *  @param assets            数据源(video:NSMutableArray <AVURLAsset*> image: NSMutableArray <NSString*>)
 *  @param outputVideoPath   视频输出路径
 *  @param callbackBlock     完成编辑回调
 *  @param cancelBlock       取消编辑回调
 */
- (void)editVideoWithSuperController:(UIViewController *)viewController
                          foldertype:(FolderType)foldertype
                   appAlbumCacheName:(NSString *)appAlbumCacheName
                              assets:(NSMutableArray *)assets
                          outputPath:(NSString *)outputVideoPath
                            callback:(RdVECallbackBlock )callbackBlock
                              cancel:(RdVECancelBlock )cancelBlock DEPRECATED_MSG_ATTRIBUTE("老接口不推荐使用");

/**   编辑视频(需扫描缓存文件夹)
 *
 *  @param viewController    源控制器
 *  @param foldertype        缓存文件夹类型 （Documents、Library、Temp,None)
 *  @param appAlbumCacheName 需扫描的缓存文件夹名称
 *  @param assets            视频(NSMutableArray <AVURLAsset*>)
 *  @param imagePaths        图片路径(NSMutableArray <NSString*>)
 *  @param outputVideoPath   视频输出路径
 *  @param callbackBlock     完成编辑回调
 *  @param cancelBlock       取消编辑回调
 */
- (void)editVideoWithSuperController:(UIViewController *)viewController
                          foldertype:(FolderType)foldertype
                   appAlbumCacheName:(NSString *)appAlbumCacheName
                              assets:(NSMutableArray *)assets
                          imagePaths:(NSMutableArray *)imagePaths
                          outputPath:(NSString *)outputVideoPath
                            callback:(RdVECallbackBlock )callbackBlock
                              cancel:(RdVECancelBlock )cancelBlock DEPRECATED_MSG_ATTRIBUTE("老接口不推荐使用");
/**   编辑视频(单场景多媒体 最多只能条件两个多媒体)
 *
 *  @param viewController    源控制器
 *  @param foldertype        缓存文件夹类型 （Documents、Library、Temp,None)
 *  @param appAlbumCacheName 需扫描的缓存文件夹名称
 *  @param lists             视频图片路径(NSMutableArray <AVURLAsset*>)
 *  @param outputVideoPath   视频输出路径
 *  @param callbackBlock     完成编辑回调
 *  @param cancelBlock       取消编辑回调
 */
- (void)editVideoWithSuperController_SingleSceneMultimedia:(UIViewController *)viewController
                                                foldertype:(FolderType)foldertype
                                         appAlbumCacheName:(NSString *)appAlbumCacheName
                                                     lists:(NSMutableArray *)lists
                                                outputPath:(NSString *)outputVideoPath
                                                  callback:(RdVECallbackBlock )callbackBlock
                                                    cancel:(RdVECancelBlock )cancelBlock;

//TODO:===========================================================

#pragma mark-其他
//-视频截取
+( void ) Intercept:(UIViewController *)weakSelf atFile:(NSObject *)file atUINavigationController:(UINavigationController *) nav atTrimAndRotateVideoFinishBlock:(TrimAndRotateVideoFinishBlock) trimAndRotateVideoFinishBlock;
//-图片裁剪
+( void ) Tailoring:(UIViewController *)weakSelf atFile:(NSObject *)file atUINavigationController:(UINavigationController *) nav atTrimAndRotateVideoFinishBlock:(EditVideoForOnceFinishAction) editVideoForOnceFinishAction;
//-相册编辑界面
+(void)enterNext:(BOOL) isEnableWizard atFileArray:(NSMutableArray *) FileArray atNavigationController:(UINavigationController *)NavigationController;
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
                 completion:(void(^)(BOOL result,NSString*outputFilePath))completionHandle;
//有界面
- (void)video2audiowithtype:(UIViewController *)viewController
               atAVFileType:(AVFileType)type
                   videoUrl:(NSURL*)videoUrl
           outputFolderPath:(NSString*)outputFolder
                 samplerate:(int )samplerate
                   callback:(RdVECallbackBlock )callbackBlock
                     cancel:(RdVECancelBlock )cancelBlock;


NS_ASSUME_NONNULL_END

@end

#pragma mark- config
@interface ConfigData : NSObject
@property(nonatomic,strong)EditConfiguration   * _Nullable editConfiguration;
@property(nonatomic,strong)CameraConfiguration * _Nullable cameraConfiguration;
@property(nonatomic,strong)ExportConfiguration * _Nullable exportConfiguration;

@end
