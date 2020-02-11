//
//  RDHelpClass.h
//  RDVEUISDK
//
//  Created by 周晓林 on 16/4/18.
//  Copyright © 2016年 周晓林. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import "RDVECore.h"
#import "RDSectorProgressView.h"

@interface RDHelpClass : NSObject

/** 压缩 相关函数
 */
+ (void)OpenZip:(NSString*)zipPath  unzipto:(NSString*)_unzipto caption:(BOOL)caption fileCount:(NSInteger)fileCount progress:(RDSectorProgressView *)progressView completionBlock:(void (^)(void))completionBlock;
+ (void)OpenZip:(NSString*)zipPath  unzipto:(NSString*)_unzipto caption:(BOOL)caption;
+ (BOOL)OpenZipp:(NSString*)zipPath  unzipto:(NSString*)_unzipto;

//+(CGPoint)solveUIWidgetFuzzyPoint:(CGPoint) oldPoint;
/**获取系统剩余空间
 */
+ (long long)freeDiskSpaceInBytes;
+ (NSString *)pathInCacheDirectory:(NSString *)fileName;
+ (NSBundle *)getBundle;
+(id)objectForData:(NSData *)data;
//NSArray、NSDictionary转为json字符串
+(NSString *)objectToJson:(id)obj;
/**加载图片
 */
+ (UIImage *)imageWithContentOfFile:(NSString *)path;
+ (UIImage *)imageWithContentOfPath:(NSString *)path;
+ (NSString *) getResourceFromBundle : (NSString *) bundleName resourceName:(NSString *)name Type : (NSString *) type;
+ (NSString *) getResourceFromBundle : (NSString *) name Type : (NSString *) type;
+ (UIImage *) getBundleImage : (NSString *) name;
+ (UIImage *) getBundleImagePNG : (NSString *) name;
//
+ (long long) fileSizeAtPath:(NSString*) filePath;
+ (NSString *) system;
+ (BOOL)isLowDevice;
/**根据时间命名文件
 */
+ (NSString *)createFilename;
/**返回录音文件保存的文件夹
 */
+ (NSString *)returnEditorVideoPath;
+ (BOOL)createVideoFolderIfNotExist;

+ (void)setView:(UIView *)view toSizeWidth:(CGFloat)width;
+ (void)setView:(UIView *)view toOriginX:(CGFloat)x;
+ (void)setView:(UIView *)view toOriginY:(CGFloat)y;
+ (void)setView:(UIView *)view toOrigin:(CGPoint)origin;

+ (NSString*)getFaceUFilePathString:(NSString *) name type:(NSString*)type;
+ (BOOL)createFaceUFolderIfNotExist;
+ (void) getFaceUImagePath:(NSString*)path name:(NSString*) name;
+ (id)updateInfomationWithJson:(NSMutableDictionary *)params andUploadUrl:(NSString *)uploadUrl;
+ (id)updateInfomation:(NSMutableDictionary *)params andUploadUrl:(NSString *)uploadUrl;
//获取素材管理后台的素材
+ (id)getNetworkMaterialWithType:(NSString *)type
                          appkey:(NSString *)appkey
                         urlPath:(NSString *)urlPath;

+ (id)getNetworkMaterialWithParams:(NSMutableDictionary *)params
                          appkey:(NSString *)appkey
                         urlPath:(NSString *)urlPath;

+(NSString *)createPostJsonURL:(NSMutableDictionary *)params;
/**颜色转图片
 */
+ (UIImage *) rdImageWithColor:(UIColor *)color cornerRadius:(CGFloat)cornerRadius;
+ (UIImage *) rdImageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)cornerRadius;
/**时间格式化
 */
+ (NSString *)timeToStringNoSecFormat:(float)time;
/**时间格式化
 */
+ (NSString *) timeFormat: (float) seconds;
/**时间格式化
 */
+ (NSString *)timeToStringFormat:(float)time;
+ (NSString *)timeToSecFormat:(float)time;
/**时间格式 （最小以秒计算）
 */
+ (NSString *)timeToStringFormat_MinSecond:(float)time;

+ (UIImage*)drawImageAddWhiteBlack:(UIImage *)image width:(float)width;
/**合成Image
 */
+ (UIImage*)drawImages:(NSMutableArray *)images size:(CGSize)size animited:(BOOL)animited;
/**判断URL是否为本地相册
 */
+ (BOOL)isSystemPhotoUrl:(NSURL *)url;
/**判断URL是视频还是图片
 */
+ (BOOL)isImageUrl:(NSURL *)url;
/**从URL获取缩率图照片
 */
+ (UIImage *)getThumbImageWithUrl:(NSURL *)url;
/**获取全屏图
 */
+ (UIImage *)getFullScreenImageWithUrl:(NSURL *)url;

/*
 * 功能：获取视频url的其中一帧图像( isForward 为true 是表示从当前时间往前搜索 false 则反之 )
 * 参数：
        fileURL         视频地址
        time            时间点
        isForward       搜索方向
 * 返回：返回搜索到得帧图像
 */
+ (UIImage *)geScreenShotImageFromVideoURL:(NSURL *)fileURL atTime:(CMTime)time atSearchDirection:(bool) isForward;
/* 图片缩放
 */
+ (UIImage *)scaleImage:(UIImage *)image toScale:(float)scaleSize;

/**从某一个时间点获取缩率图照片
 */
+ (UIImage *)assetGetThumImage:(CGFloat)second url:(NSURL *)url urlAsset:(AVURLAsset *)urlAsset;
+ (UIImage *)getLastScreenShotImageFromVideoURL:(NSURL *)fileURL;
+ (UIImage *)getLastScreenShotImageFromVideoURL:(NSURL *)fileURL atTime:(CMTime)time;
//保存图片
+ (NSURL *)saveImage:(NSURL *)fileURL image:(UIImage *)image;
+ (NSURL *)saveImage:(NSURL *)fileURL image:(UIImage *)image atPosition:(NSString *) str;
/**图片旋转
 */
+ (UIImage *)imageRotatedByDegrees:(UIImage *)cImage rotation:(float)rotation;
/** 图片旋转裁切
 *  cropRect 默认为CGRectMake(0, 0, 1, 1)
 */
+ (UIImage *)image:(UIImage *)image rotation:(float)rotation cropRect:(CGRect)cropRect;
/**获取视频分辨率
 */
+ (CGSize )getVideoSizeForTrack:(AVURLAsset *)asset;
/**判断视频是横屏还是竖屏
 */
+ (BOOL) isVideoPortrait:(AVURLAsset *)asset;
/**获取视频旋转后的分辨率
 */
+ (CGSize)trackSize:(NSURL *)contentURL rotate:(float)rotate;
+ (CGSize)trackSize:(NSURL *)contentURL rotate:(float)rotate crop:(CGRect)crop;
/**通过字体文件路径加载字体, 适用于 ttf ，otf,ttc
 */
+ (NSMutableArray*)customFontArrayWithPath:(NSString*)path;
/**通过字体文件路径加载字体 适用于 ttf ，otf
 */
+(NSString*)customFontWithPath:(NSString*)path fontName:(NSString *)fontName;
+(NSString *)cachedMusicNameForURL:(NSURL *)aURL;

//创建保存编辑视频过程中存放生成的临时文件的文件夹
+ (BOOL)createSaveTmpFileFolder;

//获取文字板保存路径
+ (NSString *)getContentTextPhotoPath;

//根据URL的hash码为assetAudio文件命名
+(NSString *)pathAssetAudioForURL:(NSURL *)aURL;
+(NSString *)pathAssetVideoForURL:(NSURL *)aURL;
+(NSString *)deviceSysName;

//十六进制求UIColor
+(UIColor *) getColor: (NSString *) hexColor;

+ (NSString *) getVideoUUID;

//从保存到plist文件中的绝对路径获取URL
+ (NSURL *)getFileURLFromAbsolutePath:(NSString *)absolutePath;
+ (NSString *)getFileURLFromAbsolutePath_str:(NSString *)absolutePath;

//UIColor
+ (NSDictionary *)dicFromUIColor:(UIColor *)color;
+ (UIColor *)UIColorFromNSDictionary:(NSDictionary *)dic;
+ (NSDictionary *)dicFromCGSize:(CGSize)size;
+ (CGSize)CGSizeFromNSDictionary:(NSDictionary *)dic;
+ (NSDictionary *)dicFromCGRect:(CGRect)rect;
+ (CGRect)CGRectFromNSDictionary:(NSDictionary *)dic;
+ (NSDictionary *)dicFromCMTimeRange:(CMTimeRange)timeRange;
+ (CMTimeRange)CMTimeRangeFromNSDictionary:(NSDictionary *)dic;
+ (NSDictionary *)dicFromCMTime:(CMTime)time;
+ (CMTime)CMTimeFromNSDictionary:(NSDictionary *)dic;
+ (NSDictionary *)dicFromCGPoint:(CGPoint)point;
+ (CGPoint)CGPointFromNSDictionary:(NSDictionary *)dic;
+ (UIColor *)UIColorFromArray:(NSArray *)colorArray;

+ (NSString *)cachedFileNameForKey:(NSString *)key;
+ (NSString *)getSubtitleCachedFilePath:(NSString *)urlPath updatetime:(NSString *)updatetime;
+ (NSString *)getFontCachedFilePath:(NSString *)urlPath updatetime:(NSString *)updatetime;
+ (NSString *)getEffectCachedFilePath:(NSString *)urlPath updatetime:(NSString *)updatetime;
+ (NSString *)getTransitionCachedFilePath:(NSString *)urlPath updatetime:(NSString *)updatetime;
+ (NSString *)pathSubtitleForURL:(NSURL *)aURL;
+ (NSString *)pathFontForURL:(NSURL *)aURL;
+ (NSString *)pathEffectForURL:(NSURL *)aURL;
+ (NSString *)pathForURL_font_WEBP:(NSString *)name extStr:(NSString *)extStr isNetMaterial:(BOOL)isNetMaterial;
+ (NSString *)pathForURL_font_WEBP_down:(NSString *)name extStr:(NSString *)extStr;
//判断是否已经缓存过这个URL
+ (BOOL) hasCachedFont_WEBP:(NSString *)name extStr:(NSString *)extStr isNetMaterial:(BOOL)isNetMaterial;
+ (NSString *)pathForURL_font:(NSString *)code url:(NSString *)fontUrl;
//获取字符串的文字域的宽
+ (float)widthForString:(NSString *)value andHeight:(float)height fontSize:(float)fontSize;
//获取字符串的文字域的高
+ (float)heightForString:(NSString *)value andWidth:(float)width fontSize:(float)fontSize;
//判断是否已经缓存过这个URL
+ (BOOL) hasCachedFont:(NSString *)code url:(NSString *)fontUrl;
//获取最长的一段
+ (NSMutableArray *)getMaxLengthStringArr:(NSString *)string fontSize:(float)fontSize;

+ (BOOL)isCameraRollAlbum:(PHAssetCollection *)metadata;

/**进入系统设置
 */
+ (void)enterSystemSetting;

+ (NSString *)keyString:(id)key;

+ (float)floatMixed:(float)a b:(float)b factor:(float)factor;

/** 刷新文字板
 *  @param currentTime      当前时间
 *  @param customDrawLayer  自绘layer
 *  @param fileList         媒体列表
 */
+ (void)refreshCustomTextLayerWithCurrentTime:(CMTime)currentTime
                              customDrawLayer:(CALayer *)customDrawLayer
                                     fileLsit:(NSArray <RDFile *>*)fileList;

+ (void)setPresentNavConfig:(RDNavigationViewController *)presentNav currentNav:(RDNavigationViewController *)currentNav;

/** 获取不重名的文件名
 *  @param  folderPath  文件夹路径
 *  @param  fileName    文件名，包含扩展名
 */
+ (NSURL *)getFileUrlWithFolderPath:(NSString *)folderPath fileName:(NSString *)fileName;

/** 获取图片
 *  @param  url             图片路径
 *  @param  crop            裁剪图片范围
 *  @param  cropImageSize   crop为CGRectZero或CGRectMake(0, 0, 1, 1)时，会按照cropImageSize裁剪图片中间部分
 */
+ (UIImage *)getImageFromUrl:(NSURL *)url crop:(CGRect)crop cropImageSize:(CGSize)cropImageSize;

/** 获取图片裁剪范围
 *  @param  imageSize   图片大小
 *  @param  videoSize   视频大小
 */
+ (CGRect)getCropWithImageSize:(CGSize)imageSize videoSize:(CGSize)videoSize;

+ (CGSize)getEditVideoSizeWithFileList:(NSArray *)fileList;

+ (BOOL)is64bit;

+ (void)setFaceUItemBtnImage:(NSString*)item name:(NSString *)name item:(UIButton *)sender;

/** 获取特效
 */
+ (NSMutableArray *)getFxArrayWithAppkey:(NSString *)appKey
                             typeUrlPath:(NSString *)typeUrlPath
                    specialEffectUrlPath:(NSString *)specialEffectUrlPath;

/** 获取有分类的素材
*/
+ (NSMutableArray *)getCategoryMaterialWithAppkey:(NSString *)appKey
                                      typeUrlPath:(NSString *)typeUrlPath
                                  materialUrlPath:(NSString *)materialUrlPath
                                     materialType:(RDcustomizationFunctionType)materialType;

+ (UIImage *) imageWithCoverColor:(UIColor *)color Alpha:(float)alpha size:(CGSize)size;

+ (void)downloadIconFile:(RDAdvanceEditType)type
              editConfig:(EditConfiguration *)editConfig
                  appKey:(NSString *)appKey
               cancelBtn:(UIButton *)cancelBtn
           progressBlock:(void(^)(float progress))progressBlock
                callBack:(void(^)(NSError *error))callBack
             cancelBlock:(void(^)(void))cancelBlock;

/**计算转场时间的最大值
 */
+ (double)maxTransitionDuration:(RDFile *)prevFile nextFile:(RDFile *)nextFile;

+ (CGSize)getEditSizeWithFile:(RDFile *)file;
//语音识别
+ (id)uploadAudioWithPath:(NSString *)audioPath
                    appId:(NSString *)tencentCloudAppId
                 secretId:(NSString *)tencentCloudSecretId
                secretKey:(NSString *)tencentCloudSecretKey
       serverCallbackPath:(NSString *)serverCallbackPath;

+ (float)timeFromStr:(NSString *)timeStr;

//分类信息
+(NSDictionary *)classificationParams:( NSString * ) type atAppkey:( NSString * ) appkey atURl:( NSString * ) netMaterialTypeURL;

//控件显示动画
+(void)animateView:(UIView *) view  atUP:(bool) isUp;
//控件隐藏动画
+(void)animateViewHidden:(UIView *) view atUP:(bool) isUp atBlock:(void(^)(void))completedBlock;

/** 设置媒体动画
    @param  asset           媒体
    @param  name             动画名称
    @param  duration    动画时长
    @param  center         动画中心点，默认为(0.5, 0.5)
    @param  scale           媒体放大缩小倍数，默认为1.0
 */
+ (void)setAssetAnimationArray:(VVAsset *)asset
                          name:(NSString *)name
                      duration:(float)duration
                        center:(CGPoint)center
                         scale:(float)scale;

//素材缩略图
+(NSString *)getMaterialThumbnail:(NSURL *) fileUrl;

//多线程保存缩略图
+(void)fileImage_Save:(NSMutableArray<RDFile *> *) fileArray atProgress:(void(^)(float progress))completedBlock atReturn:(void(^)(bool isSuccess))completedReturn;

//删除素材缩略图
+(void)deleteMaterialThumbnail:(NSString *) file;


//背景画布
//组装场景背景媒体
+(VVAsset *)canvasFile:(RDFile *) file;
//根据图片地址生对应的RDFile
+(RDFile *)canvas_BackgroundPicture:(NSString *) strPatch;

#pragma mark- 适配比例 按指定比例计算素材裁剪比例
+(void)fileCrop:(RDFile *) file atfileCropModeType:(FileCropModeType) ProportionIndex atEditSize:(CGSize) editSize;

//获取转场
+ (NSMutableArray *)getTransitionArray;
//获取转场缩略图路径
+ (NSString *)getTransitionIconPath:(NSString *)typeName itemName:(NSString *)itemName;
//获取转场文件路径
+ (NSString *)getTransitionPath:(NSString *)typeName itemName:(NSString *)itemName;
//设置转场
+ (void)setTransition:(VVTransition *)transition file:(RDFile *)file;

//加载进度显示
+(UIView *)loadProgressView:(CGRect) rect;


//替换媒体 跳转相册界面
+ (void)seplace_File:(SUPPORTFILETYPE)type touchConnect:(BOOL) isTouch   navigationVidew:(RDNavigationViewController * )navigationController exportSize:(CGSize) exportSize ViewController:(UIViewController *) ViewController  callbackBlock:(void (^)(NSMutableArray *lists))callbackBlock;

//媒体转RDFile

+(RDFile *)vassetToFile:(VVAsset *) vvasset;


/**进入截取
 */
+ (void)enter_Trim:(RDFile * ) file navigationVidew:(RDNavigationViewController * )navigationController  ViewController:(UIViewController *) ViewController   callbackBlock:(void (^)(CMTimeRange timeRange))callbackBlock;

/**进入变速
 */
+ (void)enter_Speed:(RDFile * ) file navigationVidew:(RDNavigationViewController * )navigationController  ViewController:(UIViewController *) ViewController   callbackBlock:(void (^)(RDFile *file, BOOL useAllFile))callbackBlock;

/**进入裁切
 */
+ (void)enter_Edit:(RDFile * ) file navigationVidew:(RDNavigationViewController * )navigationController  ViewController:(UIViewController *) ViewController   callbackBlock:(void (^)(CGRect crop, CGRect cropRect, BOOL verticalMirror, BOOL horizontalMirror, float rotate, FileCropModeType cropModeType))callbackBlock;

+ (RDCaptionAnimateType)captionAnimateToRDCaptionAnimate:(CaptionAnimateType)type;

@end
