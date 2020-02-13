//
//  RDRecordHelper.h
//  RDVECore
//
//  Created by 周晓林 on 16/4/18.
//  Copyright © 2016年 周晓林. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#import <AVFoundation/AVFoundation.h>
#import "RDRecordBeautyLowFilter.h"
#import "RDRecordBeautyMediumFilter.h"
#import "RDRecordBeautyHighFilter.h"
#import "RDGPUImageBeautifyFilter.h"

@interface RDRecordHelper : NSObject
@property (nonatomic,assign) BOOL isExport;
/**检查授权
 *type 1:编辑 2:直播 3:云储存
 */
+ (id)checkSignaturewWithAPPKey:(NSString *)appkey appSecret:(NSString *)appsecret params:(NSMutableDictionary *)params andUploadUrl:(NSString *)uploadUrl;
+ (void)checkPermissions:(NSString *)appkey
               appsecret:(NSString *)appSecret
              LicenceKey:(NSString *)licenceKey
                 appType:(NSInteger)type
                 success:(void(^)(void))succeessBlock
         resultFailBlock:(void(^)(NSError *error))resultFailBlock;

+ (long long) fileSizeAtPath:(NSString*) filePath;
+ (NSString *) system;
+ (BOOL) isAsyncAudio;
+ (CGSize ) matchSize;
+ (NSString *)sessionPreset;
+ (BOOL) canFaceU;
+ (RDGPUImageBeautifyFilter *)beautyFilter;

+ (BOOL)createVideoFolderIfNotExist;
+ (NSString *)getVideoSaveFilePathString;
+ (NSString *)getRecordFilePath;
+ (NSString *)getVideoMergeFilePathString;
+ (NSString *)getVideoReversFilePathString;
+ (NSString *)getVideoSaveFolderPathString;

+ (void)setView:(UIView *)view toSizeWidth:(CGFloat)width;
+ (void)setView:(UIView *)view toOriginX:(CGFloat)x;
+ (void)setView:(UIView *)view toOriginY:(CGFloat)y;
+ (void)setView:(UIView *)view toOrigin:(CGPoint)origin;

+ (NSString*)getFaceUFilePathString:(NSString *) name type:(NSString*)type;
+ (BOOL)createFaceUFolderIfNotExist;
+ (void) getFaceUImagePath:(NSString*)path name:(NSString*) name;
+ (id)updateInfomationWithJson:(NSMutableDictionary *)params andUploadUrl:(NSString *)uploadUrl;
+(NSString *)createPostJsonURL:(NSMutableDictionary *)params;
+ (NSString *) getResourceFromBundle : (NSString *) name Type : (NSString *) type;
+ (NSString *)getSystemCureentTime;

/**判断是否为系统相册URL
 */
+ (BOOL)isSystemPhotoUrl:(NSURL *)url;

+ (BOOL)isLowDevice;

+ (BOOL)isNeedResizeBufferSize;

/// 修正图片转向
+ (UIImage *)fixOrientation:(UIImage *)aImage;

+(UIImage *)imageFromSampleBuffer:(CVPixelBufferRef)sampleBuffer crop:(CGRect)crop imageSize:(CGSize)imageSize rotation:(UIImageOrientation)orientation;

+ (UIImage *)imageFromYUVSampleBuffer:(CMSampleBufferRef)sampleBuffer;

+ (UIImage *)convertMirrorImage:(UIImage *)image;
+ (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size;
+ (UIImage *)addImage:(UIImage *)image1 withImage:(UIImage *)image2;

+ (UIImage *)imageWithGifData:(NSData *)data
                durationArray:(NSMutableArray *)durationArray
                   targetSize:(CGSize)targetSize
                      maxSize:(float)maxSize
                         crop:(CGRect)crop;
+ (float)frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source;

+ (NSString *)getUrlPath:(NSURL *)url;

+(CGImageRef)image:(CGImageRef )image rotation:(UIImageOrientation)orientation;

//解析JSONData
+(id)parseDataFromJSONData:(NSData *)data;

+ (CMTimeRange)getActualTimeRange:(NSURL *)path;

@end
