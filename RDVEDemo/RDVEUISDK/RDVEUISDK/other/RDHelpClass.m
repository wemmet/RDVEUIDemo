//
//  RDHelpClass.m
//  RDVEUISDK
//
//  Created by 周晓林 on 16/4/18.
//  Copyright © 2016年 周晓林. All rights reserved.
//

#import "RDHelpClass.h"
#import <sys/utsname.h>
#import <sys/mount.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#include <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import "RDFileDownloader.h"
#import <CoreText/CoreText.h>
#import "RDVECore.h"
#import "RDZipArchive.h"
#import "UIImage+RDGIF.h"

//相册
#import "RDMainViewController.h"

//变速
#import "ChangeSpeedVideoViewController.h"

//截取
#import "RDTrimVideoViewController.h"

//裁切
#import "CropViewController.h"

@implementation RDHelpClass

int MaterialThumbnail = 0;

#define VIDEO_FOLDER @"videos"
#define VIDEO_FILEIMAGE @"videos_FileImage"
#define kFOLDERIMAGES @"images"
#define IMAGE_MAX_SIZE_WIDTH 1080
#define IMAGE_MAX_SIZE_HEIGHT 1080
+ (long long) freeDiskSpaceInBytes{
    struct statfs buf;
    long long freespace = -1;
    if(statfs("/var", &buf) >= 0){
        freespace = (long long)(buf.f_bsize * buf.f_bfree);
    }
    NSLog(@"%@",[NSString stringWithFormat:@"手机剩余存储空间为：%qi MB" ,freespace/1024/1024]);
    return freespace/1024/1024;
}

+ (NSString *)pathInCacheDirectory:(NSString *)fileName{
    //获取沙盒中缓存文件目录
    NSString *cacheDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    //将传入的文件名加在目录路径后面并返回
    return [cacheDirectory stringByAppendingPathComponent:fileName];
}

+ (UIImage *)imageWithContentOfFile:(NSString *)path{
    NSString* bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"RDVEUISDK.bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    NSString *imagePath = [bundle pathForResource:[NSString stringWithFormat:@"%@@3x",path]  ofType:@"png"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    if(image){
        path = nil;
        imagePath = nil;
        bundle = nil;
        return image;
    }
    imagePath = [bundle pathForResource:[NSString stringWithFormat:@"%@@2x",path] ofType:@"png"];
    image = [UIImage imageWithContentsOfFile:imagePath];
    if(image){
        path = nil;
        imagePath = nil;
        bundle = nil;
        return image;
    }
    imagePath = [bundle pathForResource:[NSString stringWithFormat:@"%@",path] ofType:@"png"];
    image = [UIImage imageWithContentsOfFile:imagePath];
    if(image){
        path = nil;
        imagePath = nil;
        bundle = nil;
        return image;
    }
    path = nil;
    imagePath = nil;
    bundle = nil;
    return nil;
}

+ (UIImage *)imageWithContentOfPath:(NSString *)path{
   return [UIImage imageWithContentsOfFile:path];
}
+ (NSString *) getResourceFromBundle : (NSString *) bundleName resourceName:(NSString *)name Type : (NSString *) type
{
    NSString* bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.bundle",bundleName]];
    return [[NSBundle bundleWithPath:bundlePath] pathForResource:[NSString stringWithFormat:@"%@",name] ofType:type];
}

+ (NSString *) getResourceFromBundle : (NSString *) name Type : (NSString *) type
{
    NSString* bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"VideoRecord.bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    return [bundle pathForResource:[NSString stringWithFormat:@"%@",name] ofType:type];
}
+ (UIImage *) getBundleImage : (NSString *) name
{
    return [UIImage imageWithContentsOfFile:[self getResourceFromBundle:[NSString stringWithFormat:@"%@",name] Type:@"tiff"]];
}

+ (UIImage *) getBundleImagePNG : (NSString *) name
{
    return [UIImage imageWithContentsOfFile:[self getResourceFromBundle:[NSString stringWithFormat:@"%@",name] Type:@"png"]];
}



#pragma mark 读取视频文件大小
+ (long long) fileSizeAtPath:(NSString*) filePath
{
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}
#pragma make 设备型号
+ (NSString *) system
{
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

+ (BOOL)isLowDevice {
    NSString* machine = [RDHelpClass system];
    BOOL isLowDevice = NO;
    if ([machine hasPrefix:@"iPhone"]) {
        if ([machine hasPrefix:@"iPhone3"]
            || [machine hasPrefix:@"iPhone4"]
            || [machine hasPrefix:@"iPhone5"]
            || [machine hasPrefix:@"iPhone6"])
        {
            isLowDevice = YES;
        }
    }else {//iPad没有适配
        isLowDevice = YES;
    }
    
    return isLowDevice;
}

+ (NSString *)createFilename {
    NSDate *date_ = [NSDate date];
    NSDateFormatter *dateformater = [[NSDateFormatter alloc] init];
    [dateformater setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
    NSString *timeFileName = [dateformater stringFromDate:date_];
    return timeFileName;
}

+ (NSString *)returnEditorVideoPath{
    NSString *docmentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *editvideoPath = [NSString stringWithFormat:@"%@/EDITORVIDEO",docmentsPath];
    if(![[NSFileManager defaultManager] fileExistsAtPath:editvideoPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:editvideoPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return editvideoPath;
}

+ (BOOL)createVideoFolderIfNotExist
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    NSString *folderPath = [path stringByAppendingPathComponent:VIDEO_FOLDER];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = FALSE;
    BOOL isDirExist = [fileManager fileExistsAtPath:folderPath isDirectory:&isDir];
    
    if(!(isDirExist && isDir))
    {
        BOOL bCreateDir = [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
        if(!bCreateDir){
            NSLog(@"创建图片文件夹失败");
            return NO;
        }
        return YES;
    }
    return YES;
}
+ (BOOL)createFaceUFolderIfNotExist
{
    
    NSString *cacheDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    
    NSString *folderPath = [cacheDirectory stringByAppendingPathComponent:@"faceu"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = FALSE;
    BOOL isDirExist = [fileManager fileExistsAtPath:folderPath isDirectory:&isDir];
    
    if(!(isDirExist && isDir))
    {
        BOOL bCreateDir = [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
        if(!bCreateDir){
            NSLog(@"创建图片文件夹失败");
            return NO;
        }
        return YES;
    }
    return YES;
}

+ (NSString*)getFaceUFilePathString:(NSString *) name type:(NSString*)type
{
    NSString *cacheDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    NSString *path = [cacheDirectory stringByAppendingPathComponent:@"faceu"];
    NSString* fileName = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",name,type]];
    return fileName;

}

+ (void)setView:(UIView *)view toSizeWidth:(CGFloat)width
{
    CGRect frame = view.frame;
    frame.size.width = width;
    view.frame = frame;
}

+ (void)setView:(UIView *)view toOriginX:(CGFloat)x
{
    CGRect frame = view.frame;
    frame.origin.x = x;
    view.frame = frame;
}

+ (void)setView:(UIView *)view toOriginY:(CGFloat)y
{
    CGRect frame = view.frame;
    frame.origin.y = y;
    view.frame = frame;
}

+ (void)setView:(UIView *)view toOrigin:(CGPoint)origin
{
    CGRect frame = view.frame;
    frame.origin = origin;
    view.frame = frame;
}

+ (void) getFaceUImagePath:(NSString*)path name:(NSString*) name;
{
    NSURL* url = [NSURL URLWithString:path];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    NSURLSessionDownloadTask* task = [session downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSString* imgPath = [self getFaceUFilePathString:name type:@"png"];
        NSData* data = UIImagePNGRepresentation([UIImage imageWithData:[NSData dataWithContentsOfURL:location]]);
        NSFileManager* fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:imgPath]) {
            [data writeToFile:imgPath atomically:YES];
        }
        
        
    }];
    [task resume];
}
+ (id)updateInfomationWithJson:(NSMutableDictionary *)params andUploadUrl:(NSString *)uploadUrl
{
    if(!params){
        params  = [[NSMutableDictionary alloc] init];
        [params setObject:@"1" forKey:@"os"];
        [params setObject:@"2" forKey:@"product"];
        
    }
    
    uploadUrl=[NSString stringWithString:[uploadUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *url=[NSURL URLWithString:uploadUrl];
    NSString *postURL= [self createPostJsonURL:params];
    //=====
    NSData *postData = [postURL dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    //
    NSHTTPURLResponse* urlResponse = nil;
    NSError *error;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
    if(error){
        NSLog(@"error:%@",[error description]);
    }
    if(!responseData){
        return nil;
    }
    id objc = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
    if(error || !objc){
        return nil;
    }else{
        return objc;
    }
    
}
+(NSString *)createPostJsonURL:(NSMutableDictionary *)params
{	
    NSString *postString=@"{";
    for(NSString *key in [params allKeys])
    {
        NSString *value=[params objectForKey:key];
        postString=[postString stringByAppendingFormat:@"%@", [NSString stringWithFormat:@"\"%@\":\"%@\"",key,value]];
    }

    postString = [postString stringByAppendingString:@"}"];
    return postString;
}

+ (id)getNetworkMaterialWithType:(NSString *)type
                          appkey:(NSString *)appkey
                         urlPath:(NSString *)urlPath
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:type forKey:@"type"];
    if (appkey.length > 0) {
        [params setObject:appkey forKey:@"appkey"];
    }
    [params setObject:@"ios" forKey:@"os"];
    [params setObject:[NSNumber numberWithInt:[RDVECore getSDKVersion]] forKey:@"ver"];
    return [self updateInfomation:params andUploadUrl:urlPath];
}

+ (id)getNetworkMaterialWithParams:(NSMutableDictionary *)params
                            appkey:(NSString *)appkey
                           urlPath:(NSString *)urlPath
{
    if (!params) {
        params = [NSMutableDictionary dictionary];
    }
    if (appkey.length > 0) {
        [params setObject:appkey forKey:@"appkey"];
    }
    [params setObject:@"ios" forKey:@"os"];
    [params setObject:[NSNumber numberWithInt:[RDVECore getSDKVersion]] forKey:@"ver"];
    return [self updateInfomation:params andUploadUrl:urlPath];
}

+ (id)updateInfomation:(NSMutableDictionary *)params andUploadUrl:(NSString *)uploadUrl{
    @autoreleasepool {
        if(!params){
            params  = [[NSMutableDictionary alloc] init];
            [params setObject:@"1" forKey:@"os"];
            [params setObject:@"2" forKey:@"product"];
            
        }
        if(![[params allKeys] containsObject:@"os"]){
            [params setObject:@"ios" forKey:@"os"];
        }
        
        uploadUrl=[NSString stringWithString:[uploadUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSURL *url=[NSURL URLWithString:uploadUrl];
        NSString *postURL= [RDHelpClass createPostURL:params];
        //=====
        NSData *postData = [postURL dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        NSString *postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:url];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:postData];
        //
        NSHTTPURLResponse* urlResponse = nil;
        NSError *error;
        
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
        if(error){
            NSLog(@"error:%@",[error description]);
        }
        if(!responseData){
            return nil;
        }
        id obj = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
        responseData = nil;
        urlResponse = nil;
        if(error || !obj){
            error = nil;
            return nil;
        }else{
            return obj;
        }
        
    }
}

+(NSString *)createPostURL:(NSMutableDictionary *)params
{
    NSString *postString=@"";
    for(NSString *key in [params allKeys])
    {
        NSString *value=[params objectForKey:key];
        postString=[postString stringByAppendingFormat:@"%@=%@&",key,value];
    }
    if([postString length]>1)
    {
        postString=[postString substringToIndex:[postString length]-1];
    }
    return postString;
}

//以腾讯云为例，此账号为测试账号，每月测试音频时长超过30小时后，会调用失败
+ (id)uploadAudioWithPath:(NSString *)audioPath
                    appId:(NSString *)tencentCloudAppId
                 secretId:(NSString *)tencentCloudSecretId
                secretKey:(NSString *)tencentCloudSecretKey
       serverCallbackPath:(NSString *)serverCallbackPath
{
    int timestamp = [[NSDate date] timeIntervalSince1970];
    int random = [self getRandomNumber:1 to:10000];
    
    NSString *postURL = @"aai.qcloud.com/asr/v1/";
    postURL = [postURL stringByAppendingString:tencentCloudAppId];
    postURL = [postURL stringByAppendingString:[NSString stringWithFormat:@"?callback_url=%@", serverCallbackPath]];
#if 1
    int channelNum = 1;
    AVAudioPlayer* player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:audioPath] error:nil];
    if (player) {
        channelNum = player.format.channelCount;
        player = nil;
    }
    NSLog(@"音频声道数:%u", channelNum);
    postURL = [postURL stringByAppendingString:[NSString stringWithFormat:@"&channel_num=%d", channelNum]];
#else
    postURL = [postURL stringByAppendingString:@"&channel_num=1"];
#endif
    postURL = [postURL stringByAppendingString:@"&engine_model_type=8k_0"];
    postURL = [postURL stringByAppendingString:[NSString stringWithFormat:@"&expired=%d", timestamp + 3600]];
    postURL = [postURL stringByAppendingString:[NSString stringWithFormat:@"&nonce=%d", random]];
    postURL = [postURL stringByAppendingString:@"&projectid=0"];
    postURL = [postURL stringByAppendingString:@"&res_text_format=0"];
    postURL = [postURL stringByAppendingString:@"&res_type=1"];
    postURL = [postURL stringByAppendingString:[NSString stringWithFormat:@"&secretid=%@", tencentCloudSecretId]];
    postURL = [postURL stringByAppendingString:@"&source_type=1"];
    postURL = [postURL stringByAppendingString:@"&sub_service_type=0"];
    postURL = [postURL stringByAppendingString:[NSString stringWithFormat:@"&timestamp=%d", timestamp]];
    
    NSString *authorization = [self Base_HmacSha1:tencentCloudSecretKey data:[@"POST" stringByAppendingString:postURL]];
    
    //=====
    NSData *voiceData = [NSData dataWithContentsOfFile:audioPath];
    NSString *postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[voiceData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[@"https://" stringByAppendingString:postURL]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"aai.qcloud.com" forHTTPHeaderField:@"Host"];
    [request setValue:authorization forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:voiceData];
    if ([postLength integerValue] >= 5*1024*1024) {
        NSLog(@"postLength:%@", postLength);
        NSLog(@"音频数据要小于5MB");
    }
    //
    NSHTTPURLResponse* urlResponse = nil;
    NSError *error;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
    if(error){
        NSLog(@"error:%@",[error description]);
    }
    if(!responseData){
        return nil;
    }
    error = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
    responseData = nil;
    urlResponse = nil;
    if(error || !obj){
        error = nil;
        return nil;
    }else{
#if 1
        return obj;
#else
        id result = nil;
        if ([[obj objectForKey:@"code"] intValue] == 0) {
            result = [self updateInfomation:[NSMutableDictionary dictionaryWithObject:[obj objectForKey:@"requestId"] forKey:@"requestId"] andUploadUrl:@"http://d.56show.com/filemanage2/public/filemanage/voice2text/findText"];
            if ([[result objectForKey:@"code"] intValue] != 0) {
                NSLog(@"requestId:%@ errorCode:%d msg:%@", [obj objectForKey:@"requestId"], [result[@"code"] intValue], result[@"msg"]);
            }
        }
        return result;
#endif
    }
}

+(NSString *)createPostURL2:(NSMutableDictionary *)params
{
    NSString *postString = @"aai.qcloud.com/asr/v1/1259660397?";
    for(NSString *key in [params allKeys])
    {
        NSString *value=[params objectForKey:key];
        postString=[postString stringByAppendingFormat:@"%@=%@&",key,value];
    }
    if([postString length]>1)
    {
        postString=[postString substringToIndex:[postString length]-1];
    }
    return postString;
}

+ (int)getRandomNumber:(int)from to:(int)to
{
    return (int)(from + (arc4random() % (to - from + 1)));
}

//HmacSHA1加密
+(NSString *)Base_HmacSha1:(NSString *)key data:(NSString *)data{
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];
    //Sha256:
    // unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    //CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    //sha1
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC
                                          length:sizeof(cHMAC)];
    //将加密结果进行一次BASE64编码。
    NSString *hash = [HMAC base64EncodedStringWithOptions:0];
    return hash;
}

static CGFloat rdVESDKedgeSizeFromCornerRadius(CGFloat cornerRadius) {
    return cornerRadius * 2 + 1;
}

+ (UIImage *) rdImageWithColor:(UIColor *)color cornerRadius:(CGFloat)cornerRadius {
    CGFloat minEdgeSize = rdVESDKedgeSizeFromCornerRadius(cornerRadius);
    CGRect rect = CGRectMake(0, 0, minEdgeSize, minEdgeSize);
    UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius];
    roundedRect.lineWidth = 0;
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0f);
    [color setFill];
    [roundedRect fill];
    [roundedRect stroke];
    [roundedRect addClip];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(cornerRadius, cornerRadius, cornerRadius, cornerRadius)];
}

+ (UIImage *) rdImageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)cornerRadius {
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius];
    
    roundedRect.lineWidth = 0;
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0f);
    [color setFill];
    [roundedRect fill];
    [roundedRect stroke];
    [roundedRect addClip];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(cornerRadius, cornerRadius, cornerRadius, cornerRadius)];
}

+ (NSString *)timeToStringFormat:(float)time{
    @autoreleasepool {
    if(time<=0){
        time = 0;
    }
    int secondsInt  = floorf(time);
    float haomiao=time-secondsInt;
    int hour        = secondsInt/3600;
    secondsInt     -= hour*3600;
    int minutes     =(int)secondsInt/60;
    secondsInt     -= minutes * 60;
    NSString *strText;
    if(haomiao==1){
        secondsInt+=1;
        haomiao=0.f;
    }
    int diff = (int)floorf(haomiao*10);
    if (hour>0)
    {
        strText=[NSString stringWithFormat:@"%02i:%02i:%02i.%d",hour,minutes, secondsInt,diff];
    }else{
        
        strText=[NSString stringWithFormat:@"%02i:%02i.%d",minutes, secondsInt,diff];
    }
    return strText;
    }
}

+ (NSString *)timeToStringFormat_MinSecond:(float)time{
    @autoreleasepool {
    if(time<=0){
        time = 0;
    }
    int secondsInt  = floorf(time);
    float haomiao=time-secondsInt;
    int hour        = secondsInt/3600;
    secondsInt     -= hour*3600;
    int minutes     =(int)secondsInt/60;
    secondsInt     -= minutes * 60;
    NSString *strText;
    if(haomiao==1){
        secondsInt+=1;
        haomiao=0.f;
    }
    if (hour>0)
    {
        strText=[NSString stringWithFormat:@"%02i:%02i:%02i",hour,minutes, secondsInt];
    }else{
        
        strText=[NSString stringWithFormat:@"%02i:%02i",minutes, secondsInt];
    }
    return strText;
    }
}

+ (NSString *)timeToSecFormat:(float)time{
    if(time<=0){
        time = 0;
    }
    int secondsInt  = floorf(time);
    float haomiao=time-secondsInt;
    int hour        = secondsInt/3600;
    secondsInt     -= hour*3600;
    int minutes     =(int)secondsInt/60;
    secondsInt     -= minutes * 60;
    NSString *strText;
    if(haomiao==1){
        secondsInt+=1;
        haomiao=0.f;
    }
    int diff = (int)floorf(haomiao*10);
    if (hour>0)
    {
        minutes += hour*60;
    }
    secondsInt += minutes*60;
    strText=[NSString stringWithFormat:@"%02i.%d", secondsInt,diff];
    return strText;
}

+ (NSString *)timeToStringNoSecFormat:(float)time{
    if(time<=0){
        time = 0;
    }
    int secondsInt  = floorf(time);
    //    float haomiao=time-secondsInt;
    int hour        = secondsInt/3600;
    secondsInt     -= hour*3600;
    int minutes     =(int)secondsInt/60;
    secondsInt     -= minutes * 60;
    NSString *strText;
    //    if(haomiao==1){
    //        secondsInt+=1;
    //        haomiao=0.f;
    //    }
    if (hour>0)
    {
        strText=[NSString stringWithFormat:@"%02i:%02i:%02if",hour,minutes, secondsInt];
    }else{
        
        strText=[NSString stringWithFormat:@"%02i:%02i",minutes, secondsInt];
    }
    return strText;
}

+ (NSString *) timeFormat: (float) seconds {
    if(seconds<=0){
        seconds = 0;
    }
    int hours = seconds / 3600;
    int minutes = seconds / 60;
    int sec = fabs(round((int)seconds % 60));
    NSString *ch = hours <= 9 ? @"0": @"";
    NSString *cm = minutes <= 9 ? @"0": @"";
    NSString *cs = sec <= 9 ? @"0": @"";
    if (hours>=1) {
        return [NSString stringWithFormat:@"%@%i:%@%i:%@%i", ch, hours, cm, minutes, cs, sec];
    }else{
        return [NSString stringWithFormat:@"%@%i:%@%i",cm, minutes, cs, sec];
    }
}

+ (UIImage*)drawImageAddWhiteBlack:(UIImage *)image width:(float)width{
    if(image){
#if 1
        CGSize size = CGSizeMake(852 + width*2, 852 + width*2);
        UIGraphicsBeginImageContextWithOptions(size, NO, 0);
        UIGraphicsGetCurrentContext();
        [[UIColor whiteColor] set];
        UIRectFill(CGRectMake(0, 0, size.width, size.height));
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
#else
        CGSize size = CGSizeMake(image.size.width + width*2, image.size.height + width*2);
        UIGraphicsBeginImageContextWithOptions(size, NO, 0);
        UIGraphicsGetCurrentContext();
        [[UIColor whiteColor] set];
        UIRectFill(CGRectMake(0, 0, size.width, size.height));
        [image drawInRect:CGRectMake(width,width,image.size.width,image.size.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
#endif
        return newImage;
    }else{
        return nil;
    }
    
}

+ (UIImage*)drawImages:(NSMutableArray *)images size:(CGSize)size animited:(BOOL)animited{
    if(images.count>0){
        float width=0;
        float height;
        if(animited){
            height = ((UIImage *)images[0]).size.height/2;
        }else{
            height = ((UIImage *)images[0]).size.height;
        }
        for(int i=0;i<images.count;i++){
            if(animited){
                width = width + ((UIImage *)images[i]).size.width/2;
            }else{
                width = width + ((UIImage *)images[i]).size.width;
            }
        }
        size = CGSizeMake(width, height);

        UIGraphicsBeginImageContextWithOptions(size, NO, 0);
        UIGraphicsGetCurrentContext();
        float x=0;
        for (NSInteger i =0;i<images.count;i++) {
            UIImage *imagees = images[i];
            float width = imagees.size.width;
//            NSLog(@"%s : %f",__func__,imagees.size.width);
            if(animited){
                width = imagees.size.width/2;
            }
            [imagees drawInRect:CGRectMake(x,0,width,size.height)];
            x+=width;
        }
        
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return newImage;
    }else{
        return nil;
    }
    
}


#pragma mark- 20170427 =======从URL获取照片
/**判断是否为系统相册URL
 */
+ (BOOL)isSystemPhotoUrl:(NSURL *)url{
    if ([url.scheme.lowercaseString isEqualToString:@"ipod-library"]
        || [url.scheme.lowercaseString isEqualToString:@"assets-library"]){
//    if (([url.scheme.lowercaseString isEqualToString:@"ipod-library"]
//        || [url.scheme.lowercaseString isEqualToString:@"assets-library"]
//        || ![url.path containsString:@"Application"])
//        && !url.host && url.host.length == 0) {
        return YES;
    }else{
        return NO;
    }
}

/**判断URL是视频还是图片
 */
+ (BOOL)isImageUrl:(NSURL *)url{
    NSString *pathExtension = [url.pathExtension lowercaseString];
//    if([self isSystemPhotoUrl:url]){
//        pathExtension = [[[[NSString stringWithFormat:@"%@",url] componentsSeparatedByString:@"ext="] lastObject] lowercaseString];
//    }else{
//        pathExtension = [url.pathExtension lowercaseString];
//    }
    if([pathExtension isEqualToString:@"jpg"]
       || [pathExtension isEqualToString:@"jpeg"]
       || [pathExtension isEqualToString:@"png"]
       || [pathExtension isEqualToString:@"gif"]
       || [pathExtension isEqualToString:@"tiff"]
       || [pathExtension isEqualToString:@"heic"]
       ){
        return YES;
    }else{
        return NO;
    }
}

+ (UIImage *)getLastScreenShotImageFromVideoURL:(NSURL *)fileURL atTime:(CMTime)time {
    if (CMTimeCompare(time, kCMTimeZero) < 0) {
        return nil;
    }
    @autoreleasepool {
        AVURLAsset *asset = [AVURLAsset assetWithURL:fileURL];
        AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        gen.appliesPreferredTrackTransform = YES;
        //如果需要精确时间
        gen.requestedTimeToleranceAfter = kCMTimeZero;
        gen.requestedTimeToleranceBefore = kCMTimeZero;
        
        NSError *error = nil;
        CGImageRef image = [gen copyCGImageAtTime:time actualTime:nil error:&error];
        float frameRate = 0.0;
        if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] > 0) {
            AVAssetTrack* clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            frameRate = clipVideoTrack.nominalFrameRate;
            if (CMTimeCompare(time, clipVideoTrack.timeRange.duration) == 1) {
                time = clipVideoTrack.timeRange.duration;
            }
        }
        while (!image) {
            error = nil;
            time = CMTimeSubtract(time, CMTimeMake(1, frameRate>0 ? frameRate : 30));
            image = [gen copyCGImageAtTime:time actualTime:nil error:&error];
            if (image || CMTimeCompare(kCMTimeZero, time) == 0) {
                break;
            }
        }
        UIImage *shotImage = [[UIImage alloc] initWithCGImage:image];
        CGImageRelease(image);
        
        if(error){
            NSLog(@"error:%@",error);
            error = nil;
        }
        gen = nil;
        asset = nil;
        return shotImage;
    }
}

+ (UIImage *)geScreenShotImageFromVideoURL:(NSURL *)fileURL atTime:(CMTime)time  atSearchDirection:(bool) isForward{
    
    if( isForward )
    {
        return  [RDHelpClass getLastScreenShotImageFromVideoURL:fileURL atTime:time];
    }
    
    if (CMTimeCompare(time, kCMTimeZero) < 0) {
        time = kCMTimeZero;
    }
    @autoreleasepool {
        AVURLAsset *asset = [AVURLAsset assetWithURL:fileURL];
        AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        gen.appliesPreferredTrackTransform = YES;
        gen.apertureMode =AVAssetImageGeneratorApertureModeEncodedPixels;
        //如果需要精确时间
        gen.requestedTimeToleranceAfter = kCMTimeZero;
        gen.requestedTimeToleranceBefore = kCMTimeZero;
        
        NSError *error = nil;
        CGImageRef image = [gen copyCGImageAtTime:time actualTime:nil error:&error];
        
        float frameRate = 0.0;
        if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] > 0) {
            AVAssetTrack* clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            frameRate = clipVideoTrack.nominalFrameRate;
            if (CMTimeCompare(time, clipVideoTrack.timeRange.duration) == 1) {
                time = clipVideoTrack.timeRange.duration;
            }
        }
        while (!image) {
            error = nil;
            time = CMTimeAdd(time, CMTimeMake(1, frameRate>0 ? frameRate : 30));
            image = [gen copyCGImageAtTime:time actualTime:nil error:&error];
            if (image || CMTimeCompare(kCMTimeZero, time) == 0) {
                break;
            }
        }
        UIImage *shotImage = [[UIImage alloc] initWithCGImage:image];
        CGImageRelease(image);
        
        if(error){
            NSLog(@"error:%@",error);
            error = nil;
        }
        gen = nil;
        asset = nil;
        return shotImage;
    }
}

//从URL获取缩率图照片
+ (UIImage *)getThumbImageWithUrl:(NSURL *)url{
    if([self isSystemPhotoUrl:url]){//[self isSystemPhotoUrl:url]
        __block UIImage *image;
        
        if([[[UIDevice currentDevice] systemVersion] floatValue]>=8.0){
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.synchronous = YES;
            options.resizeMode = PHImageRequestOptionsResizeModeExact;
            
            PHFetchResult *phAsset = [PHAsset fetchAssetsWithALAssetURLs:@[url] options:nil];
            
            [[PHImageManager defaultManager] requestImageForAsset:[phAsset firstObject] targetSize:CGSizeMake(100*[UIScreen mainScreen].scale, 100*[UIScreen mainScreen].scale) contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                image = result;
                result  = nil;
                info = nil;
            }];
            
            options = nil;
            phAsset = nil;
            return image;
        }
        else{
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
            
            dispatch_async(queue, ^{
                [library assetForURL:url resultBlock:^(ALAsset *asset) {
                    
                    image = [UIImage imageWithCGImage:[asset thumbnail]];
                    //NSLog(@"获取图片");
                    dispatch_semaphore_signal(sema);
                } failureBlock:^(NSError *error) {
                    dispatch_semaphore_signal(sema);
                }];
            });
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            
            return image;
        }
    }else{
        if([self isImageUrl:url]){
           NSData *imagedata = [NSData dataWithContentsOfURL:url];
            return [UIImage imageWithData:imagedata];//[UIImage imageWithContentsOfFile:url.path];
        }else{
            return [self assetGetThumImage:0.5 url:url urlAsset:nil];
        }
    }
}
+ (UIImage *)getFullScreenImageWithUrl:(NSURL *)url{
    if([self isSystemPhotoUrl:url]){//
        __block UIImage *image;
        if([[[UIDevice currentDevice] systemVersion] floatValue]>8.0){
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            
            options.synchronous = YES;
            
            options.resizeMode = PHImageRequestOptionsResizeModeExact;
            
            PHFetchResult *phAsset = [PHAsset fetchAssetsWithALAssetURLs:@[url] options:nil];
            
            [[PHImageManager defaultManager] requestImageForAsset:[phAsset firstObject] targetSize:CGSizeMake(IMAGE_MAX_SIZE_WIDTH, IMAGE_MAX_SIZE_HEIGHT) contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                
                image = result;
                result = nil;
                info = nil;
            }];
            options = nil;
            phAsset = nil;
            return image;
        }else{
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            
            
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
            
            dispatch_async(queue, ^{
                [library assetForURL:url resultBlock:^(ALAsset *asset) {
                    
                    image = [RDHelpClass  fullSizeImageForAssetRepresentation:asset.defaultRepresentation];
                    //NSLog(@"获取图片");
                    dispatch_semaphore_signal(sema);
                } failureBlock:^(NSError *error) {
                    dispatch_semaphore_signal(sema);
                }];
            });
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            
            return image;
        }
    }else{
        if([self isImageUrl:url]){
            UIImage * image = [UIImage imageWithContentsOfFile:url.path];
            image = [self fixOrientation:image];
            return image;
        }else{
            return [self assetGetThumImage:0.2 url:url urlAsset:nil];
        }
    }
}

/// 修正图片转向
+ (UIImage *)fixOrientation:(UIImage *)aImage {
    //if (!self.shouldFixOrientation) return aImage;
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

+ (UIImage *)getImageWithUrl:(NSURL *)url withWidth:(float)width{
    if([self isSystemPhotoUrl:url]){
        __block UIImage *image;
        if([[[UIDevice currentDevice] systemVersion] floatValue]>8.0){
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            
            options.synchronous = YES;
            
            options.resizeMode = PHImageRequestOptionsResizeModeExact;
            
            PHFetchResult *phAsset = [PHAsset fetchAssetsWithALAssetURLs:@[url] options:nil];
            
            [[PHImageManager defaultManager] requestImageForAsset:[phAsset firstObject] targetSize:CGSizeMake(IMAGE_MAX_SIZE_WIDTH, IMAGE_MAX_SIZE_HEIGHT) contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                image = result;
                result = nil;
                info = nil;
            }];
            options = nil;
            phAsset = nil;
            return image;
        }else{
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            
            
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
            
            dispatch_async(queue, ^{
                [library assetForURL:url resultBlock:^(ALAsset *asset) {
                    
                    image = [RDHelpClass  getImageForAssetRepresentation:asset.defaultRepresentation width:width];
                    //NSLog(@"获取图片");
                    dispatch_semaphore_signal(sema);
                } failureBlock:^(NSError *error) {
                    dispatch_semaphore_signal(sema);
                }];
            });
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            
            return image;
        }
    }else{
        if([self isImageUrl:url]){
            return [UIImage imageWithContentsOfFile:url.path];
        }else{
            return [self assetGetThumImage:0.2 url:url urlAsset:nil];
        }
    }
}

+(UIImage *)getImageForAssetRepresentation:(ALAssetRepresentation *)assetRepresentation width:(float)width
{
    UIImage *result = nil;
    NSData *data = nil;
    
    uint8_t *buffer = (uint8_t *)malloc((size_t)(sizeof(uint8_t)*[assetRepresentation size]));
    if (buffer != NULL) {
        NSError *error = nil;
        NSUInteger bytesRead = [assetRepresentation getBytes:buffer fromOffset:0 length:(int)[assetRepresentation size] error:&error];
        data = [NSData dataWithBytes:buffer length:bytesRead];
        
        free(buffer);
    }
    
    if ([data length])
    {
        CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)data, nil);
        
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        
        [options setObject:(id)kCFBooleanTrue forKey:(id)kCGImageSourceShouldAllowFloat];
        [options setObject:(id)kCFBooleanTrue forKey:(id)kCGImageSourceCreateThumbnailFromImageAlways];
        [options setObject:(id)[NSNumber numberWithFloat:width] forKey:(id)kCGImageSourceThumbnailMaxPixelSize];
        [options setObject:(id)kCFBooleanTrue forKey:(id)kCGImageSourceCreateThumbnailWithTransform];
        
        CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(sourceRef, 0, (__bridge CFDictionaryRef)options);
        
        if (imageRef) {
            result = [UIImage imageWithCGImage:imageRef scale:[assetRepresentation scale] orientation:(UIImageOrientation)[assetRepresentation orientation]];
            CGImageRelease(imageRef);
        }
        
        if (sourceRef)
            CFRelease(sourceRef);
    }
    
    return result;
}

+(UIImage *)fullSizeImageForAssetRepresentation:(ALAssetRepresentation *)assetRepresentation
{
    UIImage *result = nil;
    NSData *data = nil;
    
    uint8_t *buffer = (uint8_t *)malloc((size_t)(sizeof(uint8_t)*[assetRepresentation size]));
    if (buffer != NULL) {
        NSError *error = nil;
        NSUInteger bytesRead = [assetRepresentation getBytes:buffer fromOffset:0 length:(int)[assetRepresentation size] error:&error];
        data = [NSData dataWithBytes:buffer length:bytesRead];
        
        free(buffer);
    }
    
    if ([data length])
    {
        CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)data, nil);
        
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        
        [options setObject:(id)kCFBooleanTrue forKey:(id)kCGImageSourceShouldAllowFloat];
        [options setObject:(id)kCFBooleanTrue forKey:(id)kCGImageSourceCreateThumbnailFromImageAlways];
        [options setObject:(id)[NSNumber numberWithFloat:IMAGE_MAX_SIZE_WIDTH] forKey:(id)kCGImageSourceThumbnailMaxPixelSize];
        [options setObject:(id)kCFBooleanTrue forKey:(id)kCGImageSourceCreateThumbnailWithTransform];
        
        CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(sourceRef, 0, (__bridge CFDictionaryRef)options);
        
        if (imageRef) {
            result = [UIImage imageWithCGImage:imageRef scale:[assetRepresentation scale] orientation:(UIImageOrientation)[assetRepresentation orientation]];
            CGImageRelease(imageRef);
        }
        
        if (sourceRef)
            CFRelease(sourceRef);
    }
    
    return result;
}
+ (UIImage *)assetGetThumImage:(CGFloat)second url:(NSURL *)url urlAsset:(AVURLAsset *)urlAsset{
    if(!urlAsset){
        NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                         forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        // 初始化媒体文件
        urlAsset = [AVURLAsset URLAssetWithURL:url options:opts];
    }
    // 根据asset构造一张图
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
    // 设定缩略图的方向
    // 如果不设定，可能会在视频旋转90/180/270°时，获取到的缩略图是被旋转过的，而不是正向的（自己的理解）
    generator.appliesPreferredTrackTransform = YES;
    // 设置图片的最大size(分辨率)
    generator.maximumSize = CGSizeMake(100*[UIScreen mainScreen].scale, 80*[UIScreen mainScreen].scale);
    //如果需要精确时间
    generator.requestedTimeToleranceAfter = kCMTimeZero;
    generator.requestedTimeToleranceBefore = kCMTimeZero;
    float frameRate = 0.0;
    if ([[urlAsset tracksWithMediaType:AVMediaTypeVideo] count] > 0) {
        AVAssetTrack* clipVideoTrack = [[urlAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        frameRate = clipVideoTrack.nominalFrameRate;
    }
    // 初始化error
    NSError *error = nil;
    // 根据时间，获得第N帧的图片
    // CMTimeMake(a, b)可以理解为获得第a/b秒的frame
    CGImageRef img = [generator copyCGImageAtTime:CMTimeMakeWithSeconds(second, frameRate>0 ? frameRate : 30) actualTime:NULL error:&error];
    // 构造图片
    UIImage *image = [UIImage imageWithCGImage: img];
    CGImageRelease(img);
    
    if(error){
        error = nil;
    }
    urlAsset = nil;
    generator = nil;
    if(image){
        return image;
    }else{
        return nil;
    }
}

+ (UIImage *)getLastScreenShotImageFromVideoURL:(NSURL *)fileURL {
    @autoreleasepool {

        AVURLAsset *asset = [AVURLAsset assetWithURL:fileURL];
        AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        gen.appliesPreferredTrackTransform = YES;
        //如果需要精确时间
        gen.requestedTimeToleranceAfter = kCMTimeZero;
        gen.requestedTimeToleranceBefore = kCMTimeZero;
        
        CMTime time = asset.duration;
        NSError *error = nil;
        CGImageRef image = [gen copyCGImageAtTime:time actualTime:nil error:&error];
        while (!image) {
            error = nil;
            time = CMTimeSubtract(time, CMTimeMake(1, 600));
            image = [gen copyCGImageAtTime:time actualTime:nil error:&error];
            if (image || CMTimeCompare(kCMTimeZero, time) == 0) {
                break;
            }
        }
        UIImage *shotImage = [[UIImage alloc] initWithCGImage:image];
        CGImageRelease(image);
        
        if(error){
            NSLog(@"error:%@",error);
            error = nil;
        }
        
        gen = nil;
        asset = nil;
        return shotImage;
    }
}

+ (NSURL *)saveImage:(NSURL *)fileURL image:(UIImage *)image atPosition:(NSString *) str
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *folderPath = [paths objectAtIndex:0];
    
    folderPath = [folderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",kFOLDERIMAGES]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = FALSE;
    BOOL isDirExist = [fileManager fileExistsAtPath:folderPath isDirectory:&isDir];
    
    if(!(isDirExist && isDir))
    {
        BOOL bCreateDir = [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
        if(!bCreateDir){
            NSLog(@"创建图片文件夹失败");
            return nil;
        }
    }
    NSString *fileName = @"";
    if ([fileURL.scheme.lowercaseString isEqualToString:@"ipod-library"]
        || [fileURL.scheme.lowercaseString isEqualToString:@"assets-library"])
    {
        NSRange range = [fileURL.absoluteString rangeOfString:@"?id="];
        if (range.location != NSNotFound) {
            fileName = [fileURL.absoluteString substringFromIndex:range.length + range.location];
            range = [fileName rangeOfString:@"&ext"];
            fileName = [fileName substringToIndex:range.location];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmssSSS";
            NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
            fileName = [fileName stringByAppendingString:nowTimeStr];
        }
    }else {
        NSRange range = [fileURL.absoluteString rangeOfString:@"Bundle/Application/"];
        if (range.location != NSNotFound) {
            fileName = [[fileURL.path lastPathComponent] stringByDeletingPathExtension];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmssSSS";
            NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
            fileName = [fileName stringByAppendingString:nowTimeStr];
        }else {
            fileName = [[fileURL.path lastPathComponent] stringByDeletingPathExtension];
        }
    }
    
    fileName = [NSString stringWithFormat:@"%@-%@",fileName,str];
    NSString *imageFilePath = [[folderPath stringByAppendingPathComponent:fileName] stringByAppendingString:@".jpg"];
    
    [UIImageJPEGRepresentation(image, 1.0) writeToFile:imageFilePath  atomically:YES];
    
    return [NSURL fileURLWithPath:imageFilePath];
}

+ (NSURL *)saveImage:(NSURL *)fileURL image:(UIImage *)image
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *folderPath = [paths objectAtIndex:0];
    
    folderPath = [folderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",kFOLDERIMAGES]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = FALSE;
    BOOL isDirExist = [fileManager fileExistsAtPath:folderPath isDirectory:&isDir];
    
    if(!(isDirExist && isDir))
    {
        BOOL bCreateDir = [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
        if(!bCreateDir){
            NSLog(@"创建图片文件夹失败");
            return nil;
        }
    }
    NSString *fileName = @"";
    if ([fileURL.scheme.lowercaseString isEqualToString:@"ipod-library"]
        || [fileURL.scheme.lowercaseString isEqualToString:@"assets-library"])
    {
        NSRange range = [fileURL.absoluteString rangeOfString:@"?id="];
        if (range.location != NSNotFound) {
            fileName = [fileURL.absoluteString substringFromIndex:range.length + range.location];
            range = [fileName rangeOfString:@"&ext"];
            fileName = [fileName substringToIndex:range.location];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmssSSS";
            NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
            fileName = [fileName stringByAppendingString:nowTimeStr];
        }
    }else {
        NSRange range = [fileURL.absoluteString rangeOfString:@"Bundle/Application/"];
        if (range.location != NSNotFound) {
            fileName = [[fileURL.path lastPathComponent] stringByDeletingPathExtension];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmssSSS";
            NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
            fileName = [fileName stringByAppendingString:nowTimeStr];
        }else {
            fileName = [[fileURL.path lastPathComponent] stringByDeletingPathExtension];
        }
    }
    NSString *imageFilePath = [[folderPath stringByAppendingPathComponent:fileName] stringByAppendingString:@".jpg"];
    
    [UIImageJPEGRepresentation(image, 1.0) writeToFile:imageFilePath  atomically:YES];
    
    return [NSURL fileURLWithPath:imageFilePath];
}

void RDHelpClassProviderReleaseData (void *info, const void *data, size_t size)
{
    free((void*)data);
}
- (UIImage*) imageBlackToTransparent:(UIImage*) image
{
    // 分配内存
    const int imageWidth = image.size.width;
    const int imageHeight = image.size.height;
    size_t      bytesPerRow = imageWidth * 4;
    uint32_t* rgbImageBuf = (uint32_t*)malloc(bytesPerRow * imageHeight);
    
    // 创建context
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), image.CGImage);
    
    // 遍历像素
    int num = 0;
    int pixelNum = imageWidth * imageHeight;
    uint32_t* pCurPtr = rgbImageBuf;
    for (int i = 0; i < pixelNum; i++, pCurPtr++)
    {
        if ((*pCurPtr & 0xFFFFFF00) == 0)    // 将黑色变成透明
        {
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[0] = 0;
            
            NSLog(@"pixelNum:%d : num:%d",pixelNum,num);
            num ++;
        }
        
        // 改成下面的代码，会将图片转成灰度
        /*uint8_t* ptr = (uint8_t*)pCurPtr;
         // gray = red * 0.11 + green * 0.59 + blue * 0.30
         uint8_t gray = ptr[3] * 0.11 + ptr[2] * 0.59 + ptr[1] * 0.30;
         ptr[3] = gray;
         ptr[2] = gray;
         ptr[1] = gray;*/
    }
    
    // 将内存转成image
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rgbImageBuf, bytesPerRow * imageHeight, RDHelpClassProviderReleaseData);
    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, 8, 32, bytesPerRow, colorSpace,
                                        kCGImageAlphaLast | kCGBitmapByteOrder32Little, dataProvider,
                                        NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    
    UIImage* resultUIImage = [UIImage imageWithCGImage:imageRef];
    
    // 释放
    CGImageRelease(imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    // free(rgbImageBuf) 创建dataProvider时已提供释放函数，这里不用free
    
    return resultUIImage;
}

/**图片旋转
 */
+ (UIImage *)imageRotatedByDegrees:(UIImage *)cImage rotation:(float)rotation
{
        CGSize size = CGSizeZero;
    if(cImage.size.width>cImage.size.height){
        if(rotation == 90 || rotation == -90 || rotation == 270 || rotation == -270){
            size = CGSizeMake(MIN(cImage.size.width, cImage.size.height), MAX(cImage.size.width, cImage.size.height));
        }else{
            size = CGSizeMake(MAX(cImage.size.width, cImage.size.height), MIN(cImage.size.width, cImage.size.height));
        }
    }else{
        if(rotation == 90 || rotation == -90 || rotation == 270 || rotation == -270){
            size = CGSizeMake(MAX(cImage.size.width, cImage.size.height), MIN(cImage.size.width, cImage.size.height));
        }else{
            size = CGSizeMake(MIN(cImage.size.width, cImage.size.height), MAX(cImage.size.width, cImage.size.height));
        }
    }
    
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,size.width,size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(rotation));
    rotatedViewBox.transform = t;
    CGSize rotatedSize = size;//rotatedViewBox.frame.size;
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    CGContextRotateCTM(bitmap, DEGREES_TO_RADIANS(-rotation));
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    //CGContextDrawImage(bitmap, CGRectMake(-size.width / 2, -size.height / 2, size.width, size.height), [cImage CGImage]);
    CGContextDrawImage(bitmap, CGRectMake(-cImage.size.width / 2, -cImage.size.height / 2, cImage.size.width, cImage.size.height), [cImage CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
    
}

+ (UIImage *)image:(UIImage *)image rotation:(float)rotation cropRect:(CGRect)cropRect {
    @autoreleasepool {
        if (CGRectEqualToRect(cropRect, CGRectZero)) {
            cropRect = CGRectMake(0, 0, 1, 1);
        }
        
        CGSize size = CGSizeZero;
        if(image.size.width>image.size.height){
            if(rotation == 90 || rotation == -90 || rotation == 270 || rotation == -270){
                size = CGSizeMake(MIN(image.size.width, image.size.height), MAX(image.size.width, image.size.height));
            }else{
                size = CGSizeMake(MAX(image.size.width, image.size.height), MIN(image.size.width, image.size.height));
            }
        }else{
            if(rotation == 90 || rotation == -90 || rotation == 270 || rotation == -270){
                size = CGSizeMake(MAX(image.size.width, image.size.height), MIN(image.size.width, image.size.height));
            }else{
                size = CGSizeMake(MIN(image.size.width, image.size.height), MAX(image.size.width, image.size.height));
            }
        }
        
        UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,size.width,size.height)];
        CGAffineTransform t = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(rotation));
        rotatedViewBox.transform = t;
        
        UIGraphicsBeginImageContext(size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(context, size.width/2, size.height/2);
        CGContextRotateCTM(context, DEGREES_TO_RADIANS(-rotation));
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextDrawImage(context, CGRectMake((-image.size.width / 2), (-image.size.height / 2), image.size.width, image.size.height), [image CGImage]);
        
        UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        CGRect rect = CGRectMake(resultImage.size.width * cropRect.origin.x, resultImage.size.height * cropRect.origin.y, resultImage.size.width * cropRect.size.width, resultImage.size.height * cropRect.size.height);
        CGImageRef newImageRef = CGImageCreateWithImageInRect(resultImage.CGImage, rect);
        resultImage = [UIImage imageWithCGImage:newImageRef];
        if (newImageRef) {
            CGImageRelease(newImageRef);
        }
        return resultImage;
    }
}

+ (CGSize )getVideoSizeForTrack:(AVURLAsset *)asset{
    CGSize size = CGSizeZero;
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks    count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        size = CGSizeApplyAffineTransform(videoTrack.naturalSize, videoTrack.preferredTransform);
        
        if (CGSizeEqualToSize(size, CGSizeZero) || size.width == 0.0 || size.height == 0.0) {
            NSArray * formatDescriptions = [videoTrack formatDescriptions];
            CMFormatDescriptionRef formatDescription = NULL;
            if ([formatDescriptions count] > 0) {
                formatDescription = (__bridge CMFormatDescriptionRef)[formatDescriptions objectAtIndex:0];
                if (formatDescription) {
                    size = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, false, false);
                }
            }
        }
    }
    size = CGSizeMake(fabs(size.width), fabs(size.height));
    return size;
}

/**判断视频是横屏还是竖屏
 */
+ (BOOL) isVideoPortrait:(AVURLAsset *)asset
{
    BOOL isPortrait = NO;
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks    count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGSize size = CGSizeApplyAffineTransform(videoTrack.naturalSize, videoTrack.preferredTransform);
        if (CGSizeEqualToSize(size, CGSizeZero) || size.width == 0.0 || size.height == 0.0) {
            NSArray * formatDescriptions = [videoTrack formatDescriptions];
            CMFormatDescriptionRef formatDescription = NULL;
            if ([formatDescriptions count] > 0) {
                formatDescription = (__bridge CMFormatDescriptionRef)[formatDescriptions objectAtIndex:0];
                if (formatDescription) {
                    size = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, false, false);
                }
            }
        }
        CGAffineTransform t = videoTrack.preferredTransform;
        if(fabs(size.height)>fabs(size.width)){
            return YES;
        }
        
        //        CGAffineTransform t = videoTrack.preferredTransform;
        // Portrait
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0)
        {
            isPortrait = YES;
        }
        // PortraitUpsideDown
        if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0)  {
            
            isPortrait = YES;
        }
        // LandscapeRight
        if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0)
        {
            isPortrait = NO;
        }
        // LandscapeLeft
        if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0)
        {
            isPortrait = NO;
        }
        if((size.width<0 || size.height<0)){
            return NO;
        }
    }
    return isPortrait;
}

+ (CGSize)trackSize:(NSURL *)contentURL rotate:(float)rotate{
    CGSize size = CGSizeZero;
    AVURLAsset *asset = [AVURLAsset assetWithURL:contentURL];
    
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        size = CGSizeApplyAffineTransform(videoTrack.naturalSize, videoTrack.preferredTransform);
        if (CGSizeEqualToSize(size, CGSizeZero) || size.width == 0.0 || size.height == 0.0) {
            NSArray * formatDescriptions = [videoTrack formatDescriptions];
            CMFormatDescriptionRef formatDescription = NULL;
            if ([formatDescriptions count] > 0) {
                formatDescription = (__bridge CMFormatDescriptionRef)[formatDescriptions objectAtIndex:0];
                if (formatDescription) {
                    size = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, false, false);
                }
            }
        }
    }
    size = CGSizeMake(fabs(size.width), fabs(size.height));
    
    CGSize newSize = size;
    
    BOOL isportrait = [self isVideoPortrait:asset];
    
    if(size.height == size.width){
        
        newSize        = size;
        
    }else if(isportrait){
        newSize = size;
        
        if(size.height < size.width){
            newSize  = CGSizeMake(size.height, size.width);
        }
        if(rotate == -90 || rotate == -270){
            newSize  = CGSizeMake(size.width, size.height);
        }
    }else{
        if(rotate == -90 || rotate == -270){
            newSize  = CGSizeMake(size.height, size.width);
        }
    }
    if (newSize.width > kVIDEOWIDTH || newSize.height > kVIDEOWIDTH) {
        if(newSize.width>newSize.height){
            CGSize tmpsize = newSize;
            newSize.width  = kVIDEOWIDTH;
            newSize.height = kVIDEOWIDTH * tmpsize.height/tmpsize.width;
        }else{
            CGSize tmpsize = newSize;
            newSize.height  = kVIDEOWIDTH;
            newSize.width = kVIDEOWIDTH * tmpsize.width/tmpsize.height;
        }
    }
    
    return newSize;
}

+ (CGSize)trackSize:(NSURL *)contentURL rotate:(float)rotate crop:(CGRect)crop{
    CGSize size = CGSizeZero;
    AVURLAsset *asset = [AVURLAsset assetWithURL:contentURL];
    
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        size = CGSizeApplyAffineTransform(videoTrack.naturalSize, videoTrack.preferredTransform);
        if (CGSizeEqualToSize(size, CGSizeZero) || size.width == 0.0 || size.height == 0.0) {
            NSArray * formatDescriptions = [videoTrack formatDescriptions];
            CMFormatDescriptionRef formatDescription = NULL;
            if ([formatDescriptions count] > 0) {
                formatDescription = (__bridge CMFormatDescriptionRef)[formatDescriptions objectAtIndex:0];
                if (formatDescription) {
                    size = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, false, false);
                }
            }
        }
    }
    size = CGSizeMake(fabs(size.width), fabs(size.height));
    
    CGSize newSize;
    
    BOOL isportrait = [self isVideoPortrait:asset];
    
    if(size.height == size.width){
        
        newSize        = size;
        
    }else if(isportrait){
        newSize = size;
        
        if(size.height < size.width){
            //newSize  = CGSizeMake(size.height, size.width);
            newSize  = CGSizeMake(MIN(size.width, size.height), MAX(size.width, size.height));
        }
        if(rotate == -90 || rotate == -270){
            newSize  = CGSizeMake(MAX(size.width, size.height), MIN(size.width, size.height));
        }
    }else{
        if(rotate == -90 || rotate == -270){
            //newSize  = CGSizeMake(size.height, size.width);
            newSize  = CGSizeMake(MIN(size.width, size.height), MAX(size.width, size.height));
        }else{
            newSize  = CGSizeMake(MAX(size.width, size.height), MIN(size.width, size.height));
            
        }
    }
    if(!isnan(crop.size.width) && !isnan(crop.size.height)){
        newSize = CGSizeMake(newSize.width * crop.size.width, newSize.height * crop.size.height);
    }
    if(newSize.width>newSize.height){
        CGSize tmpsize = newSize;
        newSize.width  = kVIDEOWIDTH;
        newSize.height = kVIDEOWIDTH * tmpsize.height/tmpsize.width;
    }else{
        CGSize tmpsize = newSize;
        newSize.height  = kVIDEOWIDTH;
        newSize.width = kVIDEOWIDTH * tmpsize.width/tmpsize.height;
    }
    
    return newSize;
}

/**通过字体文件路径加载字体, 适用于 ttf ，otf,ttc
 */
+ (NSMutableArray*)customFontArrayWithPath:(NSString*)path
{
    @autoreleasepool {
        CFStringRef fontPath = CFStringCreateWithCString(NULL, [path UTF8String], kCFStringEncodingUTF8);
        CFURLRef fontUrl = CFURLCreateWithFileSystemPath(NULL, fontPath, kCFURLPOSIXPathStyle, 0);
        if(!fontPath){
            CFRelease(fontUrl);
            return nil;
        }
        CFRelease(fontPath);
        NSMutableArray *customFontArray = [NSMutableArray array];
#if 0
        NSArray* familys = [UIFont familyNames];
        
        NSLog(@"%lu",(unsigned long)familys.count);
        for (int i = 0; i<[familys count]; i++) {
            
            NSString* family = [familys objectAtIndex:i];
            
            NSArray* fonts = [UIFont fontNamesForFamilyName:family];
            
            for (int j = 0; j<[fonts count]; j++) {
                
                NSLog(@"FontName:%@",[fonts objectAtIndex:j]);
            }
        }
        
        familys = nil;
#endif
        CFArrayRef fontArray =CTFontManagerCreateFontDescriptorsFromURL(fontUrl);
        //注册
        CTFontManagerRegisterFontsForURL(fontUrl, kCTFontManagerScopeNone, NULL);
        if(fontUrl)
            CFRelease(fontUrl);
        for (CFIndex i = 0 ; i < CFArrayGetCount(fontArray); i++){
            
            CTFontDescriptorRef  descriptor = CFArrayGetValueAtIndex(fontArray, i);
            CTFontRef fontRef = CTFontCreateWithFontDescriptor(descriptor, 10, NULL);
            NSString *fontName = CFBridgingRelease(CTFontCopyName(fontRef, kCTFontPostScriptNameKey));
            if(fontName)
                [customFontArray addObject:fontName];
            if(fontRef)
                CFRelease(fontRef);
            // if(descriptor)
            //    CFRelease(descriptor);
        }
        CFRelease(fontArray);
        return customFontArray;
        
    }
}

/**通过字体文件路径加载字体 适用于 ttf ，otf
 */
+(NSString*)customFontWithPath:(NSString*)path fontName:(NSString *)fontName
{
    NSURL *fontUrl = [NSURL fileURLWithPath:path];
    
    if(fontName){
        CFErrorRef error;
        BOOL registrationResult = NO;
        
        
        NSArray* familys = [UIFont familyNames];
        
        NSLog(@"%lu",(unsigned long)familys.count);
        for (int i = 0; i<[familys count]; i++) {
            
            NSString* family = [familys objectAtIndex:i];
            
            NSArray* fonts = [UIFont fontNamesForFamilyName:family];
            
            for (int j = 0; j<[fonts count]; j++) {
                
//                NSLog(@"FontName:%@",[fonts objectAtIndex:j]);
                if([fontName isEqualToString:[fonts objectAtIndex:j]]){
                    registrationResult = YES;
                    break;
                }
            }
            if(registrationResult){
                break;
            }
        }
        
        familys = nil;
        if(!registrationResult){
            registrationResult = CTFontManagerRegisterFontsForURL((__bridge CFURLRef)fontUrl, kCTFontManagerScopeProcess, &error);
            
            if (!registrationResult) {
                NSLog(@"Error with font registration: %@", error);
                CFRelease(error);
            }
            
        }
        return fontName;
    }else{
        
        CFURLRef urlRef = (__bridge CFURLRef)fontUrl;
        
        CGDataProviderRef fontDataProvider = CGDataProviderCreateWithURL(urlRef);
        CGFontRef fontRef = CGFontCreateWithDataProvider(fontDataProvider);
        CGDataProviderRelease(fontDataProvider);
        //CTFontManagerUnregisterGraphicsFont(fontRef, NULL);//每次反注册会增加更多内存
        CTFontManagerRegisterGraphicsFont(fontRef, NULL);
        
        fontName = CFBridgingRelease(CGFontCopyPostScriptName(fontRef));
        //    UIFont *font = [UIFont fontWithName:fontName size:size];
        CGFontRelease(fontRef);
        return fontName;//SimHei,SimSun,YouYuan,FZJZJW--GB1-0,FZJLJW--GB1-0,FZSEJW--GB1-0,FZNSTK--GBK1-0,HYy1gj,HYg3gj,HYk1gj,JLinBo,JLuobo,Jpangtouyu,SentyTEA-Platinum
    }
    
}

+(NSString *)cachedMusicNameForURL:(NSURL *)aURL{
    return [NSString stringWithFormat:@"%lu.mp3", (unsigned long)[[aURL description] hash]];
}
//根据URL的hash码为assetAudio文件命名
+(NSString *)pathAssetAudioForURL:(NSURL *)aURL{
    return [NSString stringWithFormat:@"%@/cachedAsset_Audio-%lu.m4a",[self returnEditorVideoPath],(unsigned long)[[aURL description] hash]];
}

+(NSString *)pathAssetVideoForURL:(NSURL *)aURL{
    return [NSString stringWithFormat:@"%@/cachedAsset_video-%lu.mp4",[self returnEditorVideoPath],(unsigned long)[[aURL description] hash]];
}

- (NSString *)returnEditorVideoPath{
    NSString *docmentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *editorvideoPath = [NSString stringWithFormat:@"%@/EDITORVIDEO",docmentsPath];
    return editorvideoPath;
}

+ (NSBundle *)getBundle{
    NSString * bundlePath = [[ NSBundle mainBundle] pathForResource: @"RDVEUISDK" ofType :@"bundle"];
    NSBundle *resourceBundle = [NSBundle bundleWithPath:bundlePath];
    return  resourceBundle;
}

+(id)objectForData:(NSData *)data{
    
    if(data){
        NSError *error;
        id objc = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (!objc) {
            //20190821 有的json文件中含有乱码，需要处理一下才能解析
            error = nil;
            NSString *dataString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
            NSData *utf8Data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
            
            objc = [NSJSONSerialization JSONObjectWithData:utf8Data options:NSJSONReadingMutableContainers error:&error];
            utf8Data = nil;
        }
        data = nil;
        if(error){
            return nil;
        }else{
            return objc;
        }
    }else{
        return nil;
    }
}

+(NSString *)objectToJson:(id)obj {
    if (!obj || ![NSJSONSerialization isValidJSONObject:obj]) {
        return nil;
    }
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj
                                                       options:0
                                                         error:&error];
    
    if ([jsonData length] && !error){
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }else{
        return nil;
    }
}

+ (BOOL)createSaveTmpFileFolder{
    return YES;//不能删除，草稿要用
    NSError *error = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self returnEditorVideoPath]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[self returnEditorVideoPath] error:&error];
        if(error){
            
            return NO;
        }
        [[NSFileManager defaultManager] createDirectoryAtPath:[self returnEditorVideoPath] withIntermediateDirectories:YES attributes:nil error:&error];
        if(error){
            NSLog(@"error:%@",error);
            return NO;
        }
    }else{
        [[NSFileManager defaultManager] createDirectoryAtPath:[self returnEditorVideoPath] withIntermediateDirectories:YES attributes:nil error:&error];
        if(error){
            NSLog(@"error:%@",error);
            return NO;
        }
    }
    if(error){
        NSLog(@"error:%@",error);
        return NO;
    }
    return YES;
}

+ (NSString *)getContentTextPhotoPath{
    NSFileManager *fm = [NSFileManager defaultManager];
    if(![fm fileExistsAtPath:[kRDDraftDirectory stringByAppendingPathComponent:@"TextPhoto"]]){
        [fm createDirectoryAtPath:[kRDDraftDirectory stringByAppendingPathComponent:@"TextPhoto"] withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *tmpPath = [kRDDraftDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"TextPhoto/cachedContentTextPhotoImage-"]];
    
    NSString *path = [tmpPath stringByDeletingLastPathComponent];
    NSString *filename = [[tmpPath lastPathComponent] stringByDeletingPathExtension];
    tmpPath = nil;
    NSString *cacheFilePath;
    NSInteger exportPathIndex = 0;
    BOOL have = NO;
    do {
        cacheFilePath = [path stringByAppendingString:[NSString stringWithFormat:@"/%@%ld.png",filename,(long)exportPathIndex]];
        exportPathIndex ++;
        have = [[NSFileManager defaultManager] fileExistsAtPath:cacheFilePath];
    } while (have);
    filename = nil;
    NSLog(@"outputFileurl:%@",cacheFilePath);
    return cacheFilePath;
}

+ (CGSize)fitsize:(CGSize)thisSize{
    if(thisSize.width == 0 && thisSize.height ==0)
        return CGSizeMake(0, 0);
    CGFloat wscale = thisSize.width/IMAGE_MAX_SIZE_WIDTH;
    CGFloat hscale = thisSize.height/IMAGE_MAX_SIZE_HEIGHT;
    CGFloat scale = (wscale>hscale)?wscale:hscale;
    CGSize newSize = CGSizeMake(thisSize.width/scale, thisSize.height/scale);
    return newSize;
}

+(NSString *)getSystemCureentTime{
    NSDate* date = [NSDate date];
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"yyyy.MM.dd"];
    
    NSString* time = [formatter stringFromDate:date];
    return time;
}


+(NSString *)deviceSysName {
    static dispatch_once_t one;
    static NSString *name;
    dispatch_once(&one, ^{
        NSString *model = [[UIDevice currentDevice] model];
        if(!model)return;
        NSDictionary *dic = @{
                              @"iPhone7,2" : @"iPhone 6",
                              @"iPhone7,1" : @"iPhone 6 Plus",
                              @"iPhone8,1" : @"iPhone 6s",
                              @"iPhone8,2" : @"iPhone 6s Plus",
                              @"iPhone8,4" : @"iPhone SE",
                              @"iPhone9,1" : @"iPhone 7",
                              @"iPhone9,2" : @"iPhone 7 Plus",
                              @"iPhone9,3" : @"iPhone 7",
                              @"iPhone9,4" : @"iPhone 7 Plus",
                              @"iPhone10,1" : @"iPhone 8",
                              @"iPhone10,4" : @"iPhone 8",
                              @"iPhone10,2" : @"iPhone 8 Plus",
                              @"iPhone10,5" : @"iPhone 8 Plus",
                              @"iPhone10,3" : @"iPhone X",
                              @"iPhone10,6" : @"iPhone X",
                              @"iPhone11,2" : @"iPhone XS",
                              @"iPhone11,4" : @"iPhone XS Max",
                              @"iPhone11,6" : @"iPhone XS Max",
                              @"iPhone11,8" : @"iPhone XR",
                              };
        name = dic[model];
        });
    return name;
    
}

//十六进制求UIColor
+(UIColor *) getColor: (NSString *) hexColor
{
    unsigned int red, green, blue;
    NSRange range;
    range.length = 2;
    
    range.location = 0;
    [[NSScanner scannerWithString:[hexColor substringWithRange:range]] scanHexInt:&red];
    range.location = 2;
    [[NSScanner scannerWithString:[hexColor substringWithRange:range]] scanHexInt:&green];
    range.location = 4;
    [[NSScanner scannerWithString:[hexColor substringWithRange:range]] scanHexInt:&blue];
    
    return [UIColor colorWithRed:(float)(red/255.0f) green:(float)(green/255.0f) blue:(float)(blue/255.0f) alpha:1.0f];
}

+ (NSString *) getVideoUUID {
    CFUUIDRef uuid_ref = CFUUIDCreate(NULL);
    CFStringRef uuid_string_ref= CFUUIDCreateString(NULL, uuid_ref);
    CFRelease(uuid_ref);
    NSString *uuid = [NSString stringWithString:(__bridge NSString*)uuid_string_ref];
    CFRelease(uuid_string_ref);
    return uuid;
}

+ (NSURL *)getFileURLFromAbsolutePath:(NSString *)absolutePath {
    if(absolutePath.length==0){
        return nil;
    }
    NSURL *fileURL = [NSURL URLWithString:absolutePath];
    if ([fileURL.scheme.lowercaseString isEqualToString:@"ipod-library"]
        || [fileURL.scheme.lowercaseString isEqualToString:@"assets-library"])
    {
        return fileURL;
    }else {
        fileURL = nil;
        NSString *filePah;
        NSRange range = [absolutePath rangeOfString:@"Bundle/Application/"];
        if (range.location != NSNotFound) {
            filePah = [absolutePath substringFromIndex:range.length + range.location];
            range = [filePah rangeOfString:@".app/"];
            filePah = [filePah substringFromIndex:range.length + range.location - 1];
            filePah = [[NSBundle mainBundle].bundlePath stringByAppendingString:filePah];
            fileURL = [NSURL fileURLWithPath:filePah];
        }else{
            range = [absolutePath rangeOfString:@"Data/Application/"];
            if (range.location != NSNotFound) {
                filePah = [absolutePath substringFromIndex:range.length + range.location];
                range = [filePah rangeOfString:@"/"];
                filePah = [filePah substringFromIndex:range.length + range.location - 1];
                filePah = [NSHomeDirectory() stringByAppendingString:filePah];
                fileURL = [NSURL fileURLWithPath:filePah];
            }else {
                fileURL = [NSURL URLWithString:absolutePath];
            }
        }
    }
    
    return fileURL;
}

+ (NSString *)getFileURLFromAbsolutePath_str:(NSString *)absolutePath {

    if(absolutePath.length==0){
        return nil;
    }
    NSString *fileURL = absolutePath;
    if ([fileURL isEqualToString:@"ipod-library"]
        || [fileURL isEqualToString:@"assets-library"])
    {
        return fileURL;
    }else {
        fileURL = nil;
        NSString *filePah;
        NSRange range = [absolutePath rangeOfString:@"Bundle/Application/"];
        if (range.location != NSNotFound) {
            filePah = [absolutePath substringFromIndex:range.length + range.location];
            range = [filePah rangeOfString:@".app/"];
            filePah = [filePah substringFromIndex:range.length + range.location - 1];
            filePah = [[NSBundle mainBundle].bundlePath stringByAppendingString:filePah];
            fileURL = filePah;
        }else{
            range = [absolutePath rangeOfString:@"Data/Application/"];
            if (range.location != NSNotFound) {
                filePah = [absolutePath substringFromIndex:range.length + range.location];
                range = [filePah rangeOfString:@"/"];
                filePah = [filePah substringFromIndex:range.length + range.location - 1];
                filePah = [NSHomeDirectory() stringByAppendingString:filePah];
                fileURL = filePah;
            }else {
                fileURL = absolutePath;
            }
        }
    }
    
    return fileURL;

}

//UIColor
+ (NSDictionary *)dicFromUIColor:(UIColor *)color {
    if (!color) {
        color = [UIColor clearColor];
    }
    CGFloat r=0,g=0,b=0,a=0;
    if ([self respondsToSelector:@selector(getRed:green:blue:alpha:)]) {
        [color getRed:&r green:&g blue:&b alpha:&a];
    }
    else {
        const CGFloat *components = CGColorGetComponents(color.CGColor);
        r = components[0];
        g = components[1];
        b = components[2];
        a = components[3];
    }
    return @{@"R":@(r),@"G":@(g),@"B":@(b),@"A":@(a)};
}
+ (UIColor *)UIColorFromNSDictionary:(NSDictionary *)dic {
    UIColor *color = [UIColor colorWithRed:[dic[@"R"] floatValue] green:[dic[@"G"] floatValue] blue:[dic[@"B"] floatValue] alpha:[dic[@"A"] floatValue]];
    return color;
}

+ (UIColor *)UIColorFromArray:(NSArray *)colorArray {
    float r = [colorArray[0] floatValue]/255.0;
    float g = [colorArray[1] floatValue]/255.0;
    float b = [colorArray[2] floatValue]/255.0;
    float a = [colorArray[3] floatValue];
    
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

+ (NSDictionary *)dicFromCGSize:(CGSize)size {
    NSDictionary *dic = @{@"width":@(size.width),@"height":@(size.height)};
    return dic;
}

+ (CGSize)CGSizeFromNSDictionary:(NSDictionary *)dic {
    CGFloat width = [dic[@"width"] floatValue];
    CGFloat height = [dic[@"height"] floatValue];
    
    CGSize size = {width, height};
    return size;
}

//CGRect
+ (NSDictionary *)dicFromCGRect:(CGRect)rect {
    NSDictionary *dic = @{@"x":@(rect.origin.x), @"y":@(rect.origin.y), @"width":@(rect.size.width),@"height":@(rect.size.height)};
    return dic;
}

+ (CGRect)CGRectFromNSDictionary:(NSDictionary *)dic {
    CGFloat x = [dic[@"x"] floatValue];
    CGFloat y = [dic[@"y"] floatValue];
    CGFloat width = [dic[@"width"] floatValue];
    CGFloat height = [dic[@"height"] floatValue];
    
    CGRect rect = {x, y, width, height};
    return rect;
}

//CMTimeRange
+ (NSDictionary *)dicFromCMTimeRange:(CMTimeRange)timeRange {
    NSDictionary *dic = CFBridgingRelease(CMTimeRangeCopyAsDictionary(timeRange, kCFAllocatorDefault));
    return dic;
}

+ (CMTimeRange)CMTimeRangeFromNSDictionary:(NSDictionary *)dic {
    CMTimeRange r = CMTimeRangeMakeFromDictionary((__bridge CFDictionaryRef)dic);
    return r;
}

//CMTime
+ (NSDictionary *)dicFromCMTime:(CMTime)time {
    NSDictionary *dic = CFBridgingRelease(CMTimeCopyAsDictionary(time, kCFAllocatorDefault));
    return dic;
}

+ (CMTime)CMTimeFromNSDictionary:(NSDictionary *)dic {
    CMTime time = CMTimeMakeFromDictionary((__bridge CFDictionaryRef)dic);
    return time;
}

//CGPoint
+ (NSDictionary *)dicFromCGPoint:(CGPoint)point {
    NSDictionary *dic = @{@"x":@(point.x),@"y":@(point.y)};
    return dic;
}
+ (CGPoint)CGPointFromNSDictionary:(NSDictionary *)dic {
    CGFloat x = [dic[@"x"] floatValue];
    CGFloat y = [dic[@"y"] floatValue];
    
    CGPoint point = {x, y};
    return point;
}

+ (NSString *)cachedFileNameForKey:(NSString *)key {
    const char *str = [key UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    
    return filename;
}

+ (NSString *)getSubtitleCachedFilePath:(NSString *)urlPath updatetime:(NSString *)updatetime {
    NSString *cachedFilePath = [kSubtitleFolder stringByAppendingPathComponent:[RDHelpClass cachedFileNameForKey:urlPath]];
    cachedFilePath = [NSString stringWithFormat:@"%@%@", cachedFilePath, updatetime];
    return cachedFilePath;
}

+ (NSString *)getFontCachedFilePath:(NSString *)urlPath updatetime:(NSString *)updatetime {
    NSString *cachedFilePath = [kFontFolder stringByAppendingPathComponent:[RDHelpClass cachedFileNameForKey:urlPath]];
    cachedFilePath = [NSString stringWithFormat:@"%@%@", cachedFilePath, updatetime];
    return cachedFilePath;
}

+ (NSString *)getEffectCachedFilePath:(NSString *)urlPath updatetime:(NSString *)updatetime {
    NSString *cachedFilePath = [kSpecialEffectFolder stringByAppendingPathComponent:[RDHelpClass cachedFileNameForKey:urlPath]];
    cachedFilePath = [cachedFilePath stringByAppendingString:updatetime];
    return cachedFilePath;
}

+ (NSString *)getTransitionCachedFilePath:(NSString *)urlPath updatetime:(NSString *)updatetime {
    NSString *cachedFilePath = [kTransitionFolder stringByAppendingPathComponent:[RDHelpClass cachedFileNameForKey:urlPath]];
    cachedFilePath = [cachedFilePath stringByAppendingString:updatetime];
    return cachedFilePath;
}

+(NSString *)pathSubtitleForURL:(NSURL *)aURL{
    return [kSubtitleFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"SubtitleType-%lu.zip", (unsigned long)[[aURL description] hash]]];
}

+(NSString *)pathFontForURL:(NSURL *)aURL{
    return [kFontFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"Font-%lu.zip", (unsigned long)[[aURL description] hash]]];
}
+(NSString *)pathEffectForURL:(NSURL *)aURL{
    return [kStickerFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"EffectType-%lu.zip", (unsigned long)[[aURL description] hash]]];
}

+ (NSString *)pathForURL_font_WEBP:(NSString *)name extStr:(NSString *)extStr isNetMaterial:(BOOL)isNetMaterial {
    NSString *filePath = @"";
    if(isNetMaterial){
        filePath = [NSString stringWithFormat:@"%@/%@.%@",kFontFolder,name,extStr];
    }else{
        filePath = [NSString stringWithFormat:@"%@/%@/%@.%@",kFontFolder,name,name,extStr];
    }
    return filePath;
    
}
+ (NSString *)pathForURL_font_WEBP_down:(NSString *)name extStr:(NSString *)extStr{
    return [NSString stringWithFormat:@"%@/%@.%@",kFontFolder,name,extStr];
}
//判断是否已经缓存过这个URL
+(BOOL) hasCachedFont_WEBP:(NSString *)name extStr:(NSString *)extStr isNetMaterial:(BOOL)isNetMaterial {
    if(extStr.length == 0){
        return NO;
    }
    NSFileManager *fileManager=[NSFileManager defaultManager];
    if(isNetMaterial){
        NSString * filePath = [NSString stringWithFormat:@"%@/%@",kFontFolder,name];
        if([[fileManager contentsOfDirectoryAtPath:[filePath stringByDeletingLastPathComponent] error:nil] count]>0){
            return YES;
        }
        return NO;
    }
    if ([fileManager fileExistsAtPath:[self pathForURL_font_WEBP:name extStr:extStr isNetMaterial:isNetMaterial]]) {
        return YES;
    }
    else return NO;
}

+(NSString *)pathForURL_font:(NSString *)code url:(NSString *)fontUrl{
    fontUrl = [NSString stringWithString:[fontUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    if(fontUrl.length>0){
        NSString *exString = [fontUrl substringFromIndex:fontUrl.length-3];
        return [NSString stringWithFormat:@"%@/%@.%@",kFontFolder,code,exString];//cachedFont-%d
    }else{
        return nil;
    }
    
}
//判断是否已经缓存过这个URL
+(BOOL) hasCachedFont:(NSString *)code url:(NSString *)fontUrl{
    
    if(fontUrl.length==0 || !fontUrl){
        return NO;
    }
    fontUrl = [NSString stringWithString:[fontUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSFileManager *fileManager=[NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[self pathForURL_font:code url:fontUrl]]) {
        return YES;
    }
    else return NO;
}

#pragma mark- 计算文字的方法
//获取字符串的文字域的宽
+ (float)widthForString:(NSString *)value andHeight:(float)height fontSize:(float)fontSize
{
    CGSize sizeToFit = [value boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, height)
                                           options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                        attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:fontSize]}
                                           context:nil].size;
    return sizeToFit.width;
}
//获取字符串的文字域的高
+ (float)heightForString:(NSString *)value andWidth:(float)width fontSize:(float)fontSize
{
    CGSize sizeToFit = [value boundingRectWithSize:CGSizeMake(width,CGFLOAT_MAX)
                                           options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                        attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:fontSize]}
                                           context:nil].size;
    return sizeToFit.height;
}

//获取最长的一段
+ (NSMutableArray *)getMaxLengthStringArr:(NSString *)string fontSize:(float)fontSize{
    NSMutableArray *arr  = [[string componentsSeparatedByString:@"\n"] mutableCopy];
    
    [arr sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        
        CGFloat obj1X = [self widthForString:obj1 andHeight:30 fontSize:fontSize];
        CGFloat obj2X = [self widthForString:obj2 andHeight:30 fontSize:fontSize];
        
        if (obj1X > obj2X) { // obj1排后面
            return NSOrderedDescending;
        }
        else { // obj1排前面
            return NSOrderedAscending;
        }
    }];
    return arr;
}

+ (BOOL)isCameraRollAlbum:(PHAssetCollection *)metadata {
    NSString *versionStr = [[UIDevice currentDevice].systemVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
    if (versionStr.length <= 1) {
        versionStr = [versionStr stringByAppendingString:@"00"];
    } else if (versionStr.length <= 2) {
        versionStr = [versionStr stringByAppendingString:@"0"];
    }
    CGFloat version = versionStr.floatValue;
    // 目前已知8.0.0 ~ 8.0.2系统，拍照后的图片会保存在最近添加中
    if (version >= 800 && version <= 802) {
        return ((PHAssetCollection *)metadata).assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumRecentlyAdded;
    } else {
        return ((PHAssetCollection *)metadata).assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary;
    }
}

/**进入系统设置
 */
+ (void)enterSystemSetting{
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

+ (NSString *)keyString:(id)key {
    if ([key isKindOfClass:[NSString class]]) {
        return (NSString *)key;
    } else if ([key isKindOfClass:[NSNumber class]]) {
        UInt32 keyValue = [(NSNumber *) key unsignedIntValue];
        
        //大部分keys 有 4 字符长度,而 ID3v2.2 格式的keys 只有3个字符,下面代码表示移动每个字节来确定length长度是要截短.
        size_t length = sizeof(UInt32);
        if ((keyValue >> 24) == 0) --length;
        if ((keyValue >> 16) == 0) --length;
        if ((keyValue >> 8) == 0) --length;
        if ((keyValue >> 0) == 0) --length;
        
        long address = (unsigned long)&keyValue;
        address += (sizeof(UInt32) - length);
        
        // keys 是以big-endian(高位优先)格式存储的.需要转换成符合主流CPU顺序的little-endian格式.
        keyValue = CFSwapInt32BigToHost(keyValue);
        
        // 创建一个字符数组,以keys字符字节填充
        char cstring[length];
        strncpy(cstring, (char *) address, length);
        cstring[length] = '\0';
        
        // 大部分QuickTime和iTunes keys前缀都有一个 '©', 而AVMetadataFormat.h 用'@' 表示,所以转换一下.
        if (cstring[0] == '\xA9') {
            cstring[0] = '@';
        }
        
        return [NSString stringWithCString:(char *) cstring
                                  encoding:NSUTF8StringEncoding];
    }
    else {
        return @"<<unknown>>";
    }
}

+ (float)floatMixed:(float)a b:(float)b factor:(float)factor {
    return (a + (b - a)*factor);
}

+ (void)refreshCustomTextLayerWithCurrentTime:(CMTime)currentTime
                              customDrawLayer:(CALayer *)customDrawLayer
                                     fileLsit:(NSArray <RDFile *>*)fileList
{
    [fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull file, NSUInteger idx, BOOL * _Nonnull stop) {
        if (file.customTextPhotoFile) {
            CALayer *textLayer = file.customTextPhotoFile.textLayer;
            if (CMTimeCompare(currentTime ,file.imageTimeRange.start) >= 0
                && CMTimeCompare(currentTime, CMTimeAdd(file.imageTimeRange.start, file.imageTimeRange.duration)) <= 0)
            {
                textLayer.hidden = NO;
                if (![customDrawLayer.sublayers containsObject:textLayer]) {
                    [customDrawLayer addSublayer:textLayer];
                }
                if (file.customTextPhotoFile.contentAlignment == kContentAlignmentCenter) {
                    textLayer.position = CGPointMake(customDrawLayer.bounds.size.width/2.0, customDrawLayer.bounds.size.height/2.0);
                }else if (file.customTextPhotoFile.contentAlignment == kContentAlignmentLeft) {
                    textLayer.position = CGPointMake(textLayer.bounds.size.width, customDrawLayer.bounds.size.height/2.0);
                }else {
                    textLayer.position = CGPointMake(customDrawLayer.bounds.size.width - textLayer.bounds.size.width, customDrawLayer.bounds.size.height/2.0);
                }
#if 1
                textLayer.transform = CATransform3DScale(CATransform3DIdentity, 2.0, 2.0, 1.0);
#else
                float halfDuration = CMTimeGetSeconds(CMTimeMultiplyByFloat64(file.imageTimeRange.duration, 0.5));
                float factor;
                if (CMTimeCompare(currentTime, CMTimeAdd(file.imageTimeRange.start, CMTimeMultiplyByFloat64(file.imageTimeRange.duration, 0.5))) <= 0) {
                    factor = (CMTimeGetSeconds(currentTime) - CMTimeGetSeconds(file.imageTimeRange.start)) / halfDuration;
                }else {
                    factor = (CMTimeGetSeconds(CMTimeAdd(file.imageTimeRange.start, file.imageTimeRange.duration)) - CMTimeGetSeconds(currentTime)) / halfDuration;
                }
                factor = factor > 1.0 ? 1.0 : factor;
                float scale = [RDHelpClass floatMixed:0.5 b:2.0 factor:factor];
                if (CMTimeCompare(currentTime, CMTimeAdd(file.imageTimeRange.start, CMTimeMultiplyByFloat64(file.imageTimeRange.duration, 1/3.0))) >= 0
                    && CMTimeCompare(currentTime, CMTimeAdd(file.imageTimeRange.start, CMTimeMultiplyByFloat64(file.imageTimeRange.duration, 2/3.0))) <= 0)
                {
                    scale = 2.0;
                }
//                NSLog(@"%.2f %.2f", scale, CMTimeGetSeconds(currentTime));
                textLayer.transform = CATransform3DScale(CATransform3DIdentity, scale, scale, 1.0);
#endif
            }else {
                textLayer.hidden = YES;
            }
        }
    }];
}

+ (void)setPresentNavConfig:(RDNavigationViewController *)presentNav currentNav:(RDNavigationViewController *)currentNav {
    presentNav.edit_functionLists = currentNav.edit_functionLists;
    presentNav.exportConfiguration = currentNav.exportConfiguration;
    presentNav.editConfiguration = currentNav.editConfiguration;
    presentNav.cameraConfiguration = currentNav.cameraConfiguration;
    presentNav.outPath = currentNav.outPath;
    presentNav.appAlbumCacheName = currentNav.appAlbumCacheName;
    presentNav.appKey = currentNav.appKey;
    presentNav.appSecret = currentNav.appSecret;
    presentNav.licenceKey = currentNav.licenceKey;
    presentNav.statusBarHidden = currentNav.statusBarHidden;
    presentNav.folderType = currentNav.folderType;
    presentNav.videoAverageBitRate = currentNav.videoAverageBitRate;
    presentNav.waterLayerRect = currentNav.waterLayerRect;
    presentNav.callbackBlock = currentNav.callbackBlock;
    presentNav.rdVeUiSdkDelegate = currentNav.rdVeUiSdkDelegate;
}

+ (NSURL *)getFileUrlWithFolderPath:(NSString *)folderPath fileName:(NSString *)fileName {
    if(![[NSFileManager defaultManager] fileExistsAtPath:folderPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *filePath;
    BOOL isExists = NO;
    NSInteger index = 0;
    do {
        filePath = [[folderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%d", fileName.stringByDeletingPathExtension, index]] stringByAppendingPathExtension:fileName.pathExtension];
        index ++;
        isExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    } while (isExists);
    return [NSURL fileURLWithPath:filePath];
}

+ (UIImage *) getImageFromUrl:(NSURL *)url crop:(CGRect)crop cropImageSize:(CGSize)cropImageSize {
    if (CGRectEqualToRect(crop, CGRectZero) || CGRectEqualToRect(crop, CGRectMake(0, 0, 1, 1))) {
        float imageSizePro = cropImageSize.width/cropImageSize.height;
        __block UIImage* image;
        if([self isSystemPhotoUrl:url]){
            PHAsset* asset = [[PHAsset fetchAssetsWithALAssetURLs:@[url] options:nil] objectAtIndex:0];
            
            float width;
            CGSize size;
            if (imageSizePro == 1.0) {
                width = MIN(720, MIN(asset.pixelWidth, asset.pixelHeight));
                size = CGSizeMake(width, width);
            }else if (imageSizePro > 1.0) {
                width = MIN(720, asset.pixelWidth);
                size = CGSizeMake(width, width/imageSizePro);
            }else {
                width = MIN(720, asset.pixelHeight);
                size = CGSizeMake(width*imageSizePro, width);
            }
            
            PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
            option.synchronous = YES;
            option.resizeMode = PHImageRequestOptionsResizeModeExact;
            option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            
            [[PHImageManager defaultManager] requestImageForAsset:asset
                                                       targetSize:size
                                                      contentMode:PHImageContentModeAspectFill//PHImageContentModeAspectFit
                                                          options:option
                                                    resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                        image = result;
                                                    }];
        }else {
            UIImage *originalImage = [UIImage imageWithContentsOfFile:url.path];
            CGSize size = originalImage.size;
            if (MAX(size.width, size.height) > 720) {
                if (originalImage.size.width >= originalImage.size.height) {
                    float width = MIN(720, originalImage.size.width);
                    size = CGSizeMake(width, width / (originalImage.size.width / originalImage.size.height));
                }else {
                    float height = MIN(720, originalImage.size.height);
                    size = CGSizeMake(height * (originalImage.size.width / originalImage.size.height), height);
                }
                image = [self resizeImage:originalImage toSize:size];
            }else {
                image = originalImage;
            }
            
            if (imageSizePro != size.width / size.height) {
                float x,y,w,h;
                if (imageSizePro == 1.0) {
                    w = MIN(size.width, size.height);
                    h = w;
                }else if (imageSizePro > 1.0) {
                    w = size.width;
                    h = w/imageSizePro;
                }else {
                    h = size.height;
                    w = h*imageSizePro;
                }
                x = fabs(size.width - w)/2.0;
                y = fabs(size.height - h)/2.0;
                CGRect rect = CGRectMake(x, y, w, h);
                
                CGImageRef sourceImageRef = [image CGImage];
                CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
                image = [UIImage imageWithCGImage:newImageRef];
                CGImageRelease(newImageRef);
            }
        }
        return image;
    }
    __block UIImage* image;
    if([self isSystemPhotoUrl:url]){
        PHAsset* asset = [[PHAsset fetchAssetsWithALAssetURLs:@[url] options:nil] objectAtIndex:0];
        
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.synchronous = YES;
        option.resizeMode = PHImageRequestOptionsResizeModeExact;
        option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        
        [[PHImageManager defaultManager] requestImageForAsset:asset
                                                   targetSize:CGSizeMake(720, 720)
                                                  contentMode:PHImageContentModeAspectFit
                                                      options:option
                                                resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                    CGSize size = result.size;
                                                    CGRect rect = CGRectMake(size.width * crop.origin.x, size.height * crop.origin.y, size.width * crop.size.width, size.height * crop.size.height);
                                                    CGImageRef sourceImageRef = [result CGImage];
                                                    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
                                                    image = [UIImage imageWithCGImage:newImageRef];
                                                    CGImageRelease(newImageRef);
                                                }];
    }else {
        UIImage *originalImage = [UIImage imageWithContentsOfFile:url.path];
        CGSize size = originalImage.size;
        if (MAX(size.width, size.height) > 720) {
            if (originalImage.size.width >= originalImage.size.height) {
                float width = MIN(720, originalImage.size.width);
                size = CGSizeMake(width, width / (originalImage.size.width / originalImage.size.height));
            }else {
                float height = MIN(720, originalImage.size.height);
                size = CGSizeMake(height * (originalImage.size.width / originalImage.size.height), height);
            }
            image = [self resizeImage:originalImage toSize:size];
        }else {
            image = originalImage;
        }
        
        CGRect rect = CGRectMake(size.width * crop.origin.x, size.height * crop.origin.y, size.width * crop.size.width, size.height * crop.size.height);
        CGImageRef sourceImageRef = [image CGImage];
        CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
        image = [UIImage imageWithCGImage:newImageRef];
        CGImageRelease(newImageRef);
    }
    return image;
}

+ (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size {
    @autoreleasepool {
        UIGraphicsBeginImageContext(size);
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return resultImage;
    }
}

+ (CGRect)getCropWithImageSize:(CGSize)imageSize videoSize:(CGSize)videoSize {
    float x=0,y=0,w=0,h=0;
    if (videoSize.width >= videoSize.height) {
        if (imageSize.width > imageSize.height) {
            h = imageSize.height;
            w = h * (videoSize.width / videoSize.height);
            if (w > imageSize.width) {
                w = imageSize.width;
                h = w / (videoSize.width / videoSize.height);
            }
        }else {
            w = imageSize.width;
            h = w / (videoSize.width / videoSize.height);
            if (h > imageSize.height) {
                h = imageSize.height;
                w = h * (videoSize.width / videoSize.height);
            }
        }
    }else {
        w = imageSize.height * (videoSize.width / videoSize.height);
        h = imageSize.height;
        if (w > imageSize.width) {
            w = imageSize.width;
            h = w / (videoSize.width / videoSize.height);
        }
    }
    x=(imageSize.width-w)/2;
    y=(imageSize.height-h)/2;
    CGRect crop = CGRectMake(x/imageSize.width, y/imageSize.height, w/imageSize.width, h/imageSize.height);
    
    return crop;
}

/** 压缩 相关函数
 */
+ (void)OpenZip:(NSString*)zipPath  unzipto:(NSString*)_unzipto caption:(BOOL)caption fileCount:(NSInteger)fileCount progress:(RDSectorProgressView *)progressView completionBlock:(void (^)(void))completionBlock
{
    RDZipArchive* zip = [[RDZipArchive alloc] init];
    zip.fileCounts = fileCount;
    zip.delegate = self;
    if( [zip RDUnzipOpenFile:zipPath] )
    {
        //NSInteger index =0;
        BOOL ret = [zip RDUnzipFileTo:_unzipto overWrite:YES completionProgress:^(float progress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(progressView){
                    [progressView setProgress:progress];
                }
            });
        }];
        if( NO==ret )
        {
            NSLog(@"error");
        }else{
            unlink([zipPath UTF8String]);
        }
        [zip RDUnzipCloseFile];
        completionBlock();
    }
}
+ (void)OpenZip:(NSString*)zipPath  unzipto:(NSString*)_unzipto caption:(BOOL)caption
{
    RDZipArchive* zip = [[RDZipArchive alloc] init];
    if( [zip RDUnzipOpenFile:zipPath] )
    {
        //NSInteger index =0;
        BOOL ret = [zip RDUnzipFileTo:_unzipto overWrite:YES];
        if( NO==ret )
        {
            NSLog(@"error");
        }else{
            unlink([zipPath UTF8String]);
        }
        [zip RDUnzipCloseFile];
    }
}
+ (BOOL)OpenZipp:(NSString*)zipPath  unzipto:(NSString*)_unzipto
{
    RDZipArchive* zip = [[RDZipArchive alloc] init];
    if( [zip RDUnzipOpenFile:zipPath] )
    {
        //NSInteger index =0;
        BOOL ret = [zip RDUnzipFileTo:_unzipto overWrite:YES];
        if( NO==ret )
        {
            NSLog(@"error");
        }else{
            unlink([zipPath UTF8String]);
        }
        [zip RDUnzipCloseFile];
        return YES;
    }
    return NO;
}

//+ (CGSize)getEditVideoSizeWithFileList:(NSArray *)fileList{
//    NSInteger pl_Count = 0;
//    __block NSInteger pCount = 0;
//    __block NSInteger lCount = 0;
//    __block NSInteger picPCount = 0;
//    __block NSInteger picLCount = 0;
//    __block NSInteger picLVPCount = 0;
//    NSMutableArray *sizearr = [[NSMutableArray alloc] init];
//    NSMutableArray *arr = [fileList mutableCopy];
//    for (int i=0;i<arr.count;i++) {
//        if([arr[i] isKindOfClass:[RDFile class]]){
//            RDFile *file = arr[i];
//            //截取的是正方形
//
//            __block CGSize lastSize = CGSizeZero;
//            if(file.fileType == kFILEVIDEO){//视频
//                AVURLAsset *urlAsset;
//                if(file.contentURL){
//                    urlAsset  = [AVURLAsset assetWithURL:file.contentURL];
//                }
//                if (file.isReverse) {
//                    urlAsset = [AVURLAsset assetWithURL:file.reverseVideoURL];
//                }
//                BOOL isp = [RDHelpClass isVideoPortrait:urlAsset];
//                lastSize = [RDHelpClass getVideoSizeForTrack:urlAsset];
//                if(lastSize.width != lastSize.height){
//                    if(isp){
//                        if(file.rotate==-90){
//                            lCount ++;
//                            lastSize = CGSizeMake(MAX(lastSize.height, lastSize.width), MIN(lastSize.height, lastSize.width));
//                        }else if(file.rotate==-270){
//                            lCount ++;
//                            lastSize = CGSizeMake(MAX(lastSize.height, lastSize.width), MIN(lastSize.height, lastSize.width));
//                        }else{
//                            pCount ++;
//                            lastSize = CGSizeMake(MIN(lastSize.height, lastSize.width), MAX(lastSize.height, lastSize.width));
//                        }
//
//                    }else{
//                        if(file.rotate==-90){
//                            pCount ++;
//                            lastSize = CGSizeMake(MIN(lastSize.height, lastSize.width), MAX(lastSize.height, lastSize.width));
//                        }else if(file.rotate ==-270){
//                            pCount ++;
//                            lastSize = CGSizeMake(MIN(lastSize.height, lastSize.width), MAX(lastSize.height, lastSize.width));
//                        }else{
//                            lCount ++;
//                            lastSize = CGSizeMake(MAX(lastSize.height, lastSize.width), MIN(lastSize.height, lastSize.width));
//                        }
//                    }
//
//                    CGSize last_Size;
//                    if(lastSize.height<=lastSize.width){
//                        last_Size = CGSizeMake(kVIDEOWIDTH,kVIDEOWIDTH*(lastSize.height/(float)lastSize.width));
//                        //                        last_Size = CGSizeMake(kVIDEOWIDTH*(lastSize.width/(float)lastSize.height), kVIDEOWIDTH);
//                    }else{
//                        last_Size = CGSizeMake(kVIDEOWIDTH*(lastSize.width/(float)lastSize.height),kVIDEOWIDTH);
//                        //                        last_Size = CGSizeMake(kVIDEOWIDTH,kVIDEOWIDTH/(lastSize.height/(float)lastSize.width));
//                    }
//                    if(sizearr.count==0){
//                        [sizearr addObject:[NSValue valueWithCGSize:last_Size]];
//                    }else{
//                        if(![sizearr containsObject:[NSValue valueWithCGSize:last_Size]]){
//                            [sizearr addObject:[NSValue valueWithCGSize:last_Size]];
//                        }
//                    }
//                }else{
//                    if(lastSize.height == lastSize.width && lastSize.width>0){
//                        pl_Count ++;
//                    }
//                }
//            }
//            else{
//                //图片
//                lastSize = [RDHelpClass getFullScreenImageWithUrl:file.contentURL].size;
//                if(lastSize.width < lastSize.height){
//                    if(file.rotate==-90){
//                        picLCount ++;
//                    }else if(file.rotate==-270){
//                        picLCount ++;
//                    }else{
//                        picPCount ++;
//                    }
//
//                }else if(lastSize.width == lastSize.height){
//                    picLVPCount ++;
//
//                }else{
//                    if(file.rotate==-90){
//                        picPCount ++;
//                    }else if(file.rotate==-270){
//                        picPCount ++;
//                    }else{
//                        picLCount ++;
//                    }
//                }
//            }
//        }
//    }
//
//    [arr removeAllObjects];
//    arr = nil;
//
//    if(pl_Count != 0 && pCount == 0 && lCount ==0 && (picLVPCount == 0 && picPCount == 0 && picLCount == 0)){
//        return  CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
//    }
//    if(pCount != 0 && lCount !=0){//横屏竖屏视频都有时输出比例1 ：1
//        return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
//    }
//    else if(pCount ==0 && lCount != 0){
//        if(sizearr.count == 1 && picPCount == 0  && picLVPCount == 0){
//            CGSize size = [[sizearr firstObject] CGSizeValue];
//            if(fileList.count==1)
//                size = CGSizeMake(size.width * ((RDFile *)fileList[0]).crop.size.width, size.height * ((RDFile *)fileList[0]).crop.size.height);
//            return size;//输出比例为视频源比例
//        }else if(picPCount !=0 /*|| picLVPCount != 0*/){
//            return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);//横屏视频和竖屏图片组合
//        }
//        return CGSizeMake(kVIDEOWIDTH, kVIDEOHEIGHT);//输出比例16 ：9
//    }else if(lCount == 0 && pCount != 0){
//        if(sizearr.count == 1 && picLCount == 0 && picLVPCount == 0){
//            //宽高都设置为4的倍数 是因为解决不要绿色的边
//            CGSize size = [[sizearr firstObject] CGSizeValue];
//            if(fileList.count==1)
//                size = CGSizeMake(size.width * ((RDFile *)fileList[0]).crop.size.width, size.height * ((RDFile *)fileList[0]).crop.size.height);
//            return size;//输出比例为视频源比例
//        }else if(picLCount != 0 || picLVPCount != 0){
//            return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);//竖屏视频和横屏图片组合
//        }
//        return CGSizeMake(kVIDEOHEIGHT, kVIDEOWIDTH);//输出比例9 ：16
//    }else{
//        return CGSizeMake(kVIDEOWIDTH, kVIDEOHEIGHT);//只有图片时输出比例为16 ：9
//    }
//    return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
//}

+ (CGSize)getEditVideoSizeWithFileList:(NSArray *)fileList{
    NSInteger pl_Count = 0;
    __block NSInteger pCount = 0;
    __block NSInteger lCount = 0;
    __block NSInteger picPCount = 0;
    __block NSInteger picLCount = 0;
    __block NSInteger picLVPCount = 0;
    NSMutableArray *sizearr = [[NSMutableArray alloc] init];
    NSMutableArray *arr = [fileList mutableCopy];
    for (int i=0;i<arr.count;i++) {
        if([arr[i] isKindOfClass:[RDFile class]]){
            RDFile *file = arr[i];
            //截取的是正方形
            
            __block CGSize lastSize = CGSizeZero;
            __block BOOL isp = true;
            if(file.fileType == kFILEVIDEO){//视频
                AVURLAsset *urlAsset;
                if(file.contentURL){
                    urlAsset  = [AVURLAsset assetWithURL:file.contentURL];
                }
                if (file.isReverse) {
                    urlAsset = [AVURLAsset assetWithURL:file.reverseVideoURL];
                }
                isp = [RDHelpClass isVideoPortrait:urlAsset];
                lastSize = [RDHelpClass getVideoSizeForTrack:urlAsset];
                if(lastSize.width != lastSize.height){
                    if(isp){
                        if(file.rotate==-90){
                            lCount ++;
                            lastSize = CGSizeMake(MAX(lastSize.height, lastSize.width), MIN(lastSize.height, lastSize.width));
                        }else if(file.rotate==-270){
                            lCount ++;
                            lastSize = CGSizeMake(MAX(lastSize.height, lastSize.width), MIN(lastSize.height, lastSize.width));
                        }else{
                            pCount ++;
                            lastSize = CGSizeMake(MIN(lastSize.height, lastSize.width), MAX(lastSize.height, lastSize.width));
                        }
                        
                    }else{
                        if(file.rotate==-90){
                            pCount ++;
                            lastSize = CGSizeMake(MIN(lastSize.height, lastSize.width), MAX(lastSize.height, lastSize.width));
                        }else if(file.rotate ==-270){
                            pCount ++;
                            lastSize = CGSizeMake(MIN(lastSize.height, lastSize.width), MAX(lastSize.height, lastSize.width));
                        }else{
                            lCount ++;
                            lastSize = CGSizeMake(MAX(lastSize.height, lastSize.width), MIN(lastSize.height, lastSize.width));
                        }
                    }
                    
                    CGSize last_Size;
                    if(lastSize.height<=lastSize.width){
                        last_Size = CGSizeMake(kVIDEOWIDTH,kVIDEOWIDTH*(lastSize.height/(float)lastSize.width));
                        //                        last_Size = CGSizeMake(kVIDEOWIDTH*(lastSize.width/(float)lastSize.height), kVIDEOWIDTH);
                    }else{
                        last_Size = CGSizeMake(kVIDEOWIDTH*(lastSize.width/(float)lastSize.height),kVIDEOWIDTH);
                        //                        last_Size = CGSizeMake(kVIDEOWIDTH,kVIDEOWIDTH/(lastSize.height/(float)lastSize.width));
                    }
                    if(sizearr.count==0){
                        [sizearr addObject:[NSValue valueWithCGSize:last_Size]];
                    }else{
                        if(![sizearr containsObject:[NSValue valueWithCGSize:last_Size]]){
                            [sizearr addObject:[NSValue valueWithCGSize:last_Size]];
                        }
                    }
                }else{
                    if(lastSize.height == lastSize.width && lastSize.width>0){
                        pl_Count ++;
                    }
                }
            }
            else{
                //图片
                lastSize = [RDHelpClass getFullScreenImageWithUrl:file.contentURL].size;
                isp = (lastSize.width > lastSize.height)?false:true;
                if(lastSize.width != lastSize.height){
                    if(isp){
                        if(file.rotate==-90){
                            picLCount ++;
                            lastSize = CGSizeMake(MAX(lastSize.height, lastSize.width), MIN(lastSize.height, lastSize.width));
                        }else if(file.rotate==-270){
                            picLCount ++;
                            lastSize = CGSizeMake(MAX(lastSize.height, lastSize.width), MIN(lastSize.height, lastSize.width));
                        }else{
                            picPCount ++;
                            lastSize = CGSizeMake(MIN(lastSize.height, lastSize.width), MAX(lastSize.height, lastSize.width));
                        }
                        
                    }else{
                        if(file.rotate==-90){
                            picPCount ++;
                            lastSize = CGSizeMake(MIN(lastSize.height, lastSize.width), MAX(lastSize.height, lastSize.width));
                        }else if(file.rotate ==-270){
                            picPCount ++;
                            lastSize = CGSizeMake(MIN(lastSize.height, lastSize.width), MAX(lastSize.height, lastSize.width));
                        }else{
                            picLCount ++;
                            lastSize = CGSizeMake(MAX(lastSize.height, lastSize.width), MIN(lastSize.height, lastSize.width));
                        }
                    }
                    
                    CGSize last_Size;
                    if(lastSize.height<=lastSize.width){
                        last_Size = CGSizeMake(kVIDEOWIDTH,kVIDEOWIDTH*(lastSize.height/(float)lastSize.width));
                        //                        last_Size = CGSizeMake(kVIDEOWIDTH*(lastSize.width/(float)lastSize.height), kVIDEOWIDTH);
                    }else{
                        last_Size = CGSizeMake(kVIDEOWIDTH*(lastSize.width/(float)lastSize.height),kVIDEOWIDTH);
                        //                        last_Size = CGSizeMake(kVIDEOWIDTH,kVIDEOWIDTH/(lastSize.height/(float)lastSize.width));
                    }
                    if(sizearr.count==0){
                        [sizearr addObject:[NSValue valueWithCGSize:last_Size]];
                    }else{
                        if(![sizearr containsObject:[NSValue valueWithCGSize:last_Size]]){
                            [sizearr addObject:[NSValue valueWithCGSize:last_Size]];
                        }
                    }
                }else{
                    if(lastSize.height == lastSize.width && lastSize.width>0){
                        picLVPCount ++;
                    }
                }

            }
        }
    }
    
    [arr removeAllObjects];
    arr = nil;
    
    if(pl_Count != 0 && pCount == 0 && lCount ==0 && (picLVPCount == 0 && picPCount == 0 && picLCount == 0)){
        return  CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
    }
    if(pCount != 0 && lCount !=0){//横屏竖屏视频都有时输出比例1 ：1
        return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
    }
    else if(pCount ==0 && lCount != 0){
        if(sizearr.count == 1 && picPCount == 0  && picLVPCount == 0){
            CGSize size = [[sizearr firstObject] CGSizeValue];
            if(fileList.count==1)
                size = CGSizeMake(size.width * ((RDFile *)fileList[0]).crop.size.width, size.height * ((RDFile *)fileList[0]).crop.size.height);
            return size;//输出比例为视频源比例
        }else if(picPCount !=0 /*|| picLVPCount != 0*/){
            return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);//横屏视频和竖屏图片组合
        }
        return CGSizeMake(kVIDEOWIDTH, kVIDEOHEIGHT);//输出比例16 ：9
    }else if(lCount == 0 && pCount != 0){
        if(sizearr.count == 1 && picLCount == 0 && picLVPCount == 0){
            //宽高都设置为4的倍数 是因为解决不要绿色的边
            CGSize size = [[sizearr firstObject] CGSizeValue];
            if(fileList.count==1)
                size = CGSizeMake(size.width * ((RDFile *)fileList[0]).crop.size.width, size.height * ((RDFile *)fileList[0]).crop.size.height);
            return size;//输出比例为视频源比例
        }else if(picLCount != 0 || picLVPCount != 0){
            return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);//竖屏视频和横屏图片组合
        }
        return CGSizeMake(kVIDEOHEIGHT, kVIDEOWIDTH);//输出比例9 ：16
    }else if( picLCount != 0 && picPCount !=0 )
    {   //横屏竖屏图片都有时输出比例1 ：1
        return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
    }
    else  if(picPCount ==0 && picLCount != 0){
        if(sizearr.count == 1 && pCount == 0  && pl_Count == 0){
            CGSize size = [[sizearr firstObject] CGSizeValue];
            if(fileList.count==1)
                size = CGSizeMake(size.width * ((RDFile *)fileList[0]).crop.size.width, size.height * ((RDFile *)fileList[0]).crop.size.height);
            return size;//输出比例为视频源比例
        }else if(pCount !=0 /*|| picLVPCount != 0*/){
            return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);//横屏图片和竖屏视频组合
        }
        return CGSizeMake(kVIDEOWIDTH, kVIDEOHEIGHT);//输出比例16 ：9
    }
    else if(picLCount == 0 && picPCount != 0){
        if(sizearr.count == 1 && lCount == 0 && pCount == 0){
            //宽高都设置为4的倍数 是因为解决不要绿色的边
            CGSize size = [[sizearr firstObject] CGSizeValue];
            if(fileList.count==1)
                size = CGSizeMake(size.width * ((RDFile *)fileList[0]).crop.size.width, size.height * ((RDFile *)fileList[0]).crop.size.height);
            return size;//输出比例为图片源比例
        }else if(lCount != 0 ||  pl_Count!= 0){
            return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);//竖屏图片和横屏视频组合
        }
        return CGSizeMake(kVIDEOHEIGHT, kVIDEOWIDTH);//输出比例9 ：16
    }
    else{
        return CGSizeMake(kVIDEOWIDTH, kVIDEOHEIGHT);//只有图片时输出比例为16 ：9
    }
    return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
}
+ (BOOL)is64bit
{
#if defined(__LP64__) && __LP64__
    return YES;
#else
    return NO;
#endif
}

+ (void)setFaceUItemBtnImage:(NSString*)item name:(NSString *)name item:(UIButton *)sender
{
    NSString* imgPath = [RDHelpClass getFaceUFilePathString:name type:@"png"];
    UIImage *inputImage = [UIImage imageWithContentsOfFile:imgPath];
    if (!inputImage) {
        NSURL* url = [NSURL URLWithString:item];
        NSURLRequest* request = [NSURLRequest requestWithURL:url];
        NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
        NSURLSessionDownloadTask* task = [session downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSString* imgPath = [RDHelpClass getFaceUFilePathString:name type:@"png"];
            NSData* data = UIImagePNGRepresentation([UIImage imageWithData:[NSData dataWithContentsOfURL:location]]);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [sender setImage:[UIImage imageWithData:data] forState:UIControlStateNormal];
            });
            
            NSFileManager* fileManager = [NSFileManager defaultManager];
            if (![fileManager fileExistsAtPath:imgPath]) {
                [data writeToFile:imgPath atomically:YES];
            }
        }];
        [task resume];
    }else{
        [sender setImage:inputImage forState:UIControlStateNormal];
    }
    
}

+ (NSMutableArray *)getFxArrayWithAppkey:(NSString *)appKey
                             typeUrlPath:(NSString *)typeUrlPath
                    specialEffectUrlPath:(NSString *)specialEffectUrlPath{
    return [self getCategoryMaterialWithAppkey:appKey typeUrlPath:typeUrlPath materialUrlPath:specialEffectUrlPath materialType:KRDEFFECTS];
}

+ (NSMutableArray *)getCategoryMaterialWithAppkey:(NSString *)appKey
                                      typeUrlPath:(NSString *)typeUrlPath
                                  materialUrlPath:(NSString *)materialUrlPath
                                     materialType:(RDcustomizationFunctionType)materialType{
    __block NSMutableArray *materialArray = [NSMutableArray array];
    NSString *type;
    NSString *folderPath;
    NSString *plistPath;
    
    RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
    if (materialType == KRDEFFECTS) {
        plistPath = kNewSpecialEffectPlistPath;
        folderPath = kSpecialEffectFolder;
        type = @"specialeffects";
    }
    else if (materialType == KTRANSITION) {
        plistPath = kTransitionPlistPath;
        folderPath = kTransitionFolder;
        type = @"transition";
    }else if (materialType == kRDTEXTTITLE) {//字幕
        plistPath = kSubtitlePlistPath;
        folderPath = kSubtitleFolder;
        type = @"sub_title";
    }
    NSMutableArray *oldMaterialArray = [NSMutableArray arrayWithContentsOfFile:plistPath];
    if ([lexiu currentReachabilityStatus] == RDNotReachable) {
        materialArray = oldMaterialArray;
    }else {
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        [params setObject:appKey forKey:@"appkey"];
        [params setObject:type forKey:@"type"];
        NSDictionary *typeDic = [RDHelpClass getNetworkMaterialWithParams:params
                                                                   appkey:appKey
                                                                  urlPath:typeUrlPath];
        if (typeDic && [typeDic[@"code"] intValue] == 0) {
            NSMutableArray *typeArray = typeDic[@"data"];
            [typeArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSMutableDictionary *params = [NSMutableDictionary dictionary];
                [params setObject:type forKey:@"type"];
                [params setObject:[NSNumber numberWithInt:[obj[@"id"] intValue]] forKey:@"category"];
                NSDictionary *resultDic = [RDHelpClass getNetworkMaterialWithParams:params
                                                                             appkey:appKey
                                                                            urlPath:materialUrlPath];
                if (resultDic && [resultDic[@"code"] intValue] == 0) {
                    NSMutableArray *array = [resultDic[@"data"] mutableCopy];
                    
                    if (materialType == KRDEFFECTS) {
                        NSString *coverPath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/effect_icon/剪辑-编辑-特效-无" Type:@"png"];
                        NSMutableDictionary *itemDic = [[NSMutableDictionary alloc] init];
                        [itemDic setObject:coverPath forKey:@"cover"];
                        [itemDic setObject:@"无" forKey:@"name"];
                        [itemDic setObject:[NSNumber numberWithInt:0] forKey:@"id"];
                        [itemDic setObject:@"1546936928" forKey:@"updatetime"];
                        [array insertObject:itemDic atIndex:0];
                    }
                    
                    NSDictionary *materialDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                           obj[@"name"], @"typeName",
                                           obj[@"icon_checked"], @"icon_checked",
                                           obj[@"icon_unchecked"], @"icon_unchecked",
                                           [NSNumber numberWithInt:[obj[@"id"] intValue]], @"typeId",
                                           array, @"data",
                                           nil];
                    [materialArray addObject:materialDic];
                    
                    if (oldMaterialArray.count > 0) {
                        NSFileManager *fileManager = [NSFileManager defaultManager];
                        [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            NSString *file = [obj[@"file"] stringByDeletingPathExtension];
                            NSString *updateTime = obj[@"updatetime"];
                            __block NSString *oldUpdateTime;
                            __block NSString *oldFile;
                            [oldMaterialArray enumerateObjectsUsingBlock:^(id  _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
                                if ([[obj1[@"file"] stringByDeletingPathExtension] isEqualToString:file]) {
                                    oldFile = obj1[@"file"];
                                    oldUpdateTime = obj1[@"updatetime"];
                                    *stop1 = YES;
                                }
                            }];
                            if(oldUpdateTime && ![oldUpdateTime isEqualToString:updateTime])
                            {
                                NSString *path;
                                if (materialType == KRDEFFECTS) {
                                    path = [RDHelpClass getEffectCachedFilePath:oldFile updatetime:oldUpdateTime];
                                }
                                else if (materialType == KTRANSITION) {
                                    path = [RDHelpClass getTransitionCachedFilePath:oldFile updatetime:oldUpdateTime];
                                }else if (materialType == kRDTEXTTITLE) {//字幕
                                    path = [kSubtitlePlistPath stringByAppendingPathComponent:file];
                                }
                                if ([fileManager fileExistsAtPath:path]) {
                                    [fileManager removeItemAtPath:path error:nil];
                                }
                            }
                        }];
                    }
                }
            }];
            if (![[NSFileManager defaultManager] fileExistsAtPath:folderPath]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            BOOL suc = [materialArray writeToFile:plistPath atomically:YES];
            if (!suc) {
                //NSLog(@"写入失败");
            }
        }
        [oldMaterialArray removeAllObjects];
        oldMaterialArray = nil;
    }
    return materialArray;
}

+ (UIImage *) imageWithCoverColor:(UIColor *)color Alpha:(float)alpha size:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if(color){
        CGFloat r = 0,g = 0,b = 0,a = 0;
        [color getRed:&r green:&g blue:&b alpha:&a];
        a = alpha;
        color = [UIColor colorWithRed:r green:g blue:b alpha:a];
        
    }
    CGContextSetFillColorWithColor(context, [color CGColor]);
    
    //填充圆，无边框
    CGContextAddArc(context, size.width/2.0, size.height/2.0, size.height/2.0, 0, 2*M_PI, 0); //添加一个圆
    CGContextDrawPath(context, kCGPathFill);//绘制填充
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (void)oldDownloadIconFileSticker:(RDAdvanceEditType)type
                     editConfig:(EditConfiguration *)editConfig
                         appKey:(NSString *)appKey
                      cancelBtn:(UIButton *)cancelBtn
                  progressBlock:(void(^)(float progress))progressBlock
                       callBack:(void(^)(NSError *error))callBack
                    cancelBlock:(void(^)(void))cancelBlock
{
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:kStickerTypesPath]) {
            [fileManager removeItemAtPath:kStickerTypesPath error:nil];
        }
        if ([fileManager fileExistsAtPath:kNewStickerPlistPath]) {
            [fileManager removeItemAtPath:kNewStickerPlistPath error:nil];
        }
        
    }
    
    
    BOOL hasNewEffect =  editConfig.effectResourceURL.length>0;
    NSString *uploadUrl = (hasNewEffect ? editConfig.effectResourceURL : getEffectTypeUrl);
    NSMutableDictionary *effectTypeList;
    if(hasNewEffect){
        effectTypeList = [RDHelpClass getNetworkMaterialWithType:@"effects"
                                                          appkey:appKey
                                                         urlPath:uploadUrl];
    }else{
        effectTypeList = [RDHelpClass updateInfomation:nil andUploadUrl:uploadUrl];
    }
    
    if(![effectTypeList isKindOfClass:[NSMutableDictionary class]] || !effectTypeList || (hasNewEffect ? ([effectTypeList[@"code"] intValue] != 0) : ([effectTypeList[@"code"] intValue] != 200))){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callBack) {
                NSString *message;
                if (effectTypeList) {
                    if (hasNewEffect) {
                        message = effectTypeList[@"msg"];
                    }else {
                        message = effectTypeList[@"message"];
                    }
                }
                if (!message || message.length == 0) {
                    message = RDLocalizedString(@"下载失败，请检查网络!", nil);
                }
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:RDUISDKCustomErrorDomain code:RDUISDKErrorCode_DownloadSubtitle userInfo:userInfo];
                callBack(error);
            }
        });
        return ;
    }
    NSArray *effectList = [effectTypeList objectForKey:@"data"];
    NSDictionary *effectIconDic = [effectTypeList objectForKey:@"icon"];
    
    NSString *effectIconUrl = [effectIconDic objectForKey:@"caption"];
    NSString *cacheEffectFolderPath = [[RDHelpClass pathEffectForURL:[NSURL URLWithString:effectIconUrl]] stringByDeletingLastPathComponent];
    NSString *cacheIconPath = [cacheEffectFolderPath stringByAppendingPathComponent:@"icon"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:cacheEffectFolderPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheEffectFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    if([[NSFileManager defaultManager] contentsOfDirectoryAtPath:cacheIconPath error:nil].count==0 && !hasNewEffect){
        //将plist文件写入文件夹
        BOOL suc = [effectList writeToFile:kStickerPlistPath atomically:YES];
        suc = [effectIconDic writeToFile:kStickerIconPlistPath atomically:YES];
        [RDFileDownloader downloadFileWithURL:effectIconUrl cachePath:cacheEffectFolderPath httpMethod:GET cancelBtn: cancelBtn progress:^(NSNumber *numProgress) {
            NSLog(@"progress:%f",[numProgress floatValue]);
            if(progressBlock){
                progressBlock([numProgress floatValue]);
            }
        } finish:^(NSString *fileCachePath) {
            [RDHelpClass OpenZipp:fileCachePath unzipto:cacheEffectFolderPath];
            if (callBack) {
                callBack(nil);
            }
        } fail:^(NSError *error) {
            if (callBack) {
                callBack(error);
                
            }
        } cancel:^{
            if (cancelBlock) {
                cancelBlock();
            }
        }];
    }else{
        [self updateLocalMaterialWithType:type newList:effectList];
        BOOL suc = [effectList writeToFile:kStickerPlistPath atomically:YES];
        suc = [effectIconDic writeToFile:kStickerIconPlistPath atomically:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callBack) {
                callBack(nil);
            }
        });
    }
}

+(NSDictionary *)classificationParams:( NSString * ) type atAppkey:( NSString * ) appkey atURl:( NSString * ) netMaterialTypeURL
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:type,@"type", nil];
    if( appkey.length>0)
        [params setObject:appkey forKey:@"appkey"];
    NSDictionary *dic = [RDHelpClass updateInfomation:params andUploadUrl:netMaterialTypeURL];
    BOOL hasValue = [[dic objectForKey:@"code"] integerValue]  == 0;
    if( hasValue )
        return [dic objectForKey:@"data"];
    else
        return nil;
}

+ (void)downloadIconFile:(RDAdvanceEditType)type
              editConfig:(EditConfiguration *)editConfig
                  appKey:(NSString *)appKey
               cancelBtn:(UIButton *)cancelBtn
           progressBlock:(void(^)(float progress))progressBlock
                callBack:(void(^)(NSError *error))callBack
             cancelBlock:(void(^)(void))cancelBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //创建文件夹
        if(![[NSFileManager defaultManager] fileExistsAtPath:kSubtitleEffectFolder]){
            [[NSFileManager defaultManager] createDirectoryAtPath:kSubtitleEffectFolder withIntermediateDirectories:YES attributes:nil error:nil];
        }
        switch (type) {
            case RDAdvanceEditType_Subtitle:
            {
#if 1
                [self getCategoryMaterialWithAppkey:appKey
                                        typeUrlPath:editConfig.netMaterialTypeURL
                                    materialUrlPath:editConfig.subtitleResourceURL
                                       materialType:kRDTEXTTITLE];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (callBack) {
                        callBack(nil);
                    }
                });
#else
                BOOL hasNewSubtitle =  editConfig.subtitleResourceURL.length>0;
                NSString *uploadUrl = (hasNewSubtitle ? editConfig.subtitleResourceURL : getCaptionTypeNoIdUrl);
                NSMutableDictionary *subtitleTypeList;
                if(hasNewSubtitle){
                    subtitleTypeList = [RDHelpClass getNetworkMaterialWithType:@"sub_title"
                                                                        appkey:appKey
                                                                       urlPath:uploadUrl];
                }else{
                    subtitleTypeList = [RDHelpClass updateInfomation:nil andUploadUrl:uploadUrl];
                }
                
                if(![subtitleTypeList isKindOfClass:[NSMutableDictionary class]] || !subtitleTypeList || (hasNewSubtitle ? ([subtitleTypeList[@"code"] intValue] != 0) : ([subtitleTypeList[@"code"] intValue] != 200))){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (callBack) {
                            NSString *message;
                            if (subtitleTypeList) {
                                if (hasNewSubtitle) {
                                    message = subtitleTypeList[@"msg"];
                                }else {
                                    message = subtitleTypeList[@"message"];
                                }
                            }
                            if (!message || message.length == 0) {
                                message = RDLocalizedString(@"下载失败，请检查网络!", nil);
                            }
                            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
                            NSError *error = [NSError errorWithDomain:RDUISDKCustomErrorDomain code:RDUISDKErrorCode_DownloadSubtitle userInfo:userInfo];
                            callBack(error);
                        }
                    });
                    return ;
                }
                
                NSMutableArray *subtitleList = [subtitleTypeList objectForKey:@"data"];
                if (hasNewSubtitle) {
                    [self updateLocalMaterialWithType:type newList:subtitleList];
                }
                
                NSDictionary *subtitleIconDic = [subtitleTypeList objectForKey:@"icon"];
                NSString *subtitleIconUrl = [subtitleIconDic objectForKey:@"zimu"];
                NSString *cacheSubtitleFolderPath = [[RDHelpClass pathSubtitleForURL:[NSURL URLWithString:subtitleIconUrl]] stringByDeletingLastPathComponent];
                NSString *cacheIconPath = [cacheSubtitleFolderPath stringByAppendingPathComponent:@"icon"];
                if(![[NSFileManager defaultManager] fileExistsAtPath:cacheSubtitleFolderPath]){
                    [[NSFileManager defaultManager] createDirectoryAtPath:cacheSubtitleFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
                }
                
                if([[NSFileManager defaultManager] contentsOfDirectoryAtPath:cacheIconPath error:nil].count==0 && !hasNewSubtitle){
                    //将plist文件写入文件夹
                    BOOL suc = [subtitleList writeToFile:kSubtitlePlistPath atomically:YES];
                    suc = [subtitleIconDic writeToFile:kSubtitleIconPlistPath atomically:YES];
                    [RDFileDownloader downloadFileWithURL:subtitleIconUrl cachePath:cacheSubtitleFolderPath httpMethod:GET cancelBtn: cancelBtn progress:^(NSNumber *numProgress) {
                        NSLog(@"progress:%f",[numProgress floatValue]);
                        if(progressBlock){
                            progressBlock([numProgress floatValue]);
                        }
                    } finish:^(NSString *fileCachePath) {
                        [RDHelpClass OpenZipp:fileCachePath unzipto:cacheSubtitleFolderPath];
                        if (callBack) {
                            callBack(nil);
                        }
                    } fail:^(NSError *error) {
                        if (callBack) {
                            callBack(error);
                        }
                    } cancel:^{
                        if (cancelBlock) {
                            cancelBlock();
                        }
                    }];
                }else{
                    BOOL suc = [subtitleList writeToFile:kSubtitlePlistPath atomically:YES];
                    suc = [subtitleIconDic writeToFile:kSubtitleIconPlistPath atomically:YES];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (callBack) {
                            callBack(nil);
                        }
                    });
                }
#endif
            }
                break;
            case RDAdvanceEditType_Sticker:
            {
                if (editConfig.netMaterialTypeURL.length > 0 && editConfig.effectResourceURL.length > 0) {
                    NSDictionary *dic;
                    BOOL hasValue = NO;
                    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"stickers",@"type", nil];
                    dic = [RDHelpClass getNetworkMaterialWithParams:params
                                                             appkey:appKey
                                                            urlPath:editConfig.netMaterialTypeURL];
                    hasValue = [[dic objectForKey:@"code"] integerValue]  == 0;
                    if( (hasValue && [[dic objectForKey:@"data"] count] > 0) ){
                        NSMutableArray *resultList;
                        if([[dic allKeys] containsObject:@"result"]){
                            resultList = [[dic objectForKey:@"result"] objectForKey:@"bgmusic"];
                        }else{
                            if([[dic objectForKey:@"data"] isKindOfClass:[NSArray class]]){
                                resultList = [dic objectForKey:@"data"];
                            }else{
                                resultList = [dic objectForKey:@"data"][@"data"];
                            }
                        }
                        if(resultList){
                            if(![[NSFileManager defaultManager] fileExistsAtPath:kStickerFolder]){
                                [[NSFileManager defaultManager] createDirectoryAtPath:kStickerFolder withIntermediateDirectories:YES attributes:nil error:nil];
                            }

                            BOOL suc = [resultList writeToFile:kStickerTypesPath atomically:YES];
                          
                            if ([[NSFileManager defaultManager] fileExistsAtPath:kStickerPlistPath]) {
                                [[NSFileManager defaultManager] removeItemAtPath:kStickerPlistPath error:nil];
                            }
                            if (!suc) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (callBack) {
                                        NSString *message = RDLocalizedString(@"贴纸分类信息，保存失败！", nil);
                                        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
                                        NSError *error = [NSError errorWithDomain:RDUISDKCustomErrorDomain code:RDUISDKErrorCode_DownloadSubtitle userInfo:userInfo];
                                        callBack(error);
                                    }
                                });
                            }

                            NSMutableArray * stickerArray = [NSMutableArray new];

                            for (int i = 0; i < resultList.count; i++) {

                                NSMutableDictionary *params = [NSMutableDictionary dictionary];
                                [params setObject:@"stickers" forKey:@"type"];
                                [params setObject:[resultList[i] objectForKey:@"id"]  forKey:@"category"];
                                [params setObject:[NSString stringWithFormat:@"%d" ,0] forKey: @"page_num"];
                                NSDictionary *dic2 = [RDHelpClass getNetworkMaterialWithParams:params
                                                                                        appkey:appKey urlPath:editConfig.effectResourceURL];
                                if(dic2 && [[dic2 objectForKey:@"code"] integerValue] == 0)
                                {
                                    NSMutableArray * currentStickerList = [dic2 objectForKey:@"data"];
                                    [stickerArray addObject:currentStickerList];
                                }
                                else
                                {
                                    if (callBack) {
                                        NSString *message;
                                        if (dic) {
                                            if ([[dic2 objectForKey:@"code"] integerValue]) {
                                                message = dic2[@"msg"];
                                            }else {
                                                message = dic2[@"message"];
                                            }
                                        }
                                        if (!message || message.length == 0) {
                                            message = RDLocalizedString(@"下载失败，请检查网络!", nil);
                                        }
                                        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
                                        NSError *error = [NSError errorWithDomain:RDUISDKCustomErrorDomain code:RDUISDKErrorCode_DownloadSubtitle userInfo:userInfo];
                                        callBack(error);
                                    }
                                }
                            }
                            suc = [stickerArray writeToFile:kNewStickerPlistPath atomically:YES];

                            [self updateLocalMaterialWith:RDAdvanceEditType_Sticker newList:stickerArray];

                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (callBack) {
                                    callBack(nil);
                                }
                            });
                        }
                        else
                        {
                            if (callBack) {
                                NSString *message;
                                if (dic) {
                                    if (hasValue) {
                                        message = dic[@"msg"];
                                    }else {
                                        message = dic[@"message"];
                                    }
                                }
                                if (!message || message.length == 0) {
                                    message = RDLocalizedString(@"下载失败，请检查网络!", nil);
                                }
                                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
                                NSError *error = [NSError errorWithDomain:RDUISDKCustomErrorDomain code:RDUISDKErrorCode_DownloadSubtitle userInfo:userInfo];
                                callBack(error);
                            }
                        }
                    }
                    else
                    {
                        [self oldDownloadIconFileSticker:type editConfig:editConfig appKey:appKey cancelBtn:cancelBtn progressBlock:progressBlock callBack:callBack cancelBlock:cancelBlock];
                    }
                }else
                {
                    [self oldDownloadIconFileSticker:type editConfig:editConfig appKey:appKey cancelBtn:cancelBtn progressBlock:progressBlock callBack:callBack cancelBlock:cancelBlock];
                }
            }
                break;
                
            case RDAdvanceEditType_None:
            {
                BOOL hasNewFont =  editConfig.fontResourceURL.length>0;
                NSString *uploadUrl = (hasNewFont ? editConfig.fontResourceURL : getFontTypeUrl);
                NSMutableDictionary *fontListDic;
                if(hasNewFont){
                    fontListDic = [RDHelpClass getNetworkMaterialWithType:kFontType
                                                                   appkey:appKey
                                                                  urlPath:uploadUrl];
                }else{
                    fontListDic = [RDHelpClass updateInfomation:nil andUploadUrl:uploadUrl];
                }
                if (hasNewFont ? ([fontListDic[@"code"] intValue] != 0) : ([fontListDic[@"code"] intValue] != 200)){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (callBack) {
                            NSString *message;
                            if (fontListDic) {
                                if (hasNewFont) {
                                    message = fontListDic[@"msg"];
                                }else {
                                    message = fontListDic[@"message"];
                                }
                            }
                            if (!message || message.length == 0) {
                                message = RDLocalizedString(@"下载失败，请检查网络!", nil);
                            }
                            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
                            NSError *error = [NSError errorWithDomain:RDUISDKCustomErrorDomain code:RDUISDKErrorCode_DownloadSubtitle userInfo:userInfo];
                            callBack(error);
                        }
                    });
                    return;
                }
                NSArray *fontList = [fontListDic objectForKey:@"data"];
                NSDictionary *fontIconDic = [fontListDic objectForKey:@"icon"];
                NSString *iconUrl = [fontIconDic objectForKey:@"caption"];
                NSString *cacheFolderPath = [[RDHelpClass pathFontForURL:[NSURL URLWithString:iconUrl]] stringByDeletingLastPathComponent];
                NSString *cacheIconPath = [cacheFolderPath stringByAppendingPathComponent:@"icon"];
                if(![[NSFileManager defaultManager] fileExistsAtPath:cacheFolderPath]){
                    [[NSFileManager defaultManager] createDirectoryAtPath:cacheFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
                }
                
                if([[NSFileManager defaultManager] contentsOfDirectoryAtPath:cacheIconPath error:nil].count==0 && !hasNewFont){
                    //将plist文件写入文件夹
                    BOOL suc = [fontList writeToFile:kFontPlistPath atomically:YES];
                    suc = [fontIconDic writeToFile:kFontIconPlistPath atomically:YES];
                    
                    [RDFileDownloader downloadFileWithURL:iconUrl cachePath:cacheFolderPath httpMethod:GET cancelBtn: cancelBtn progress:^(NSNumber *numProgress) {
                        NSLog(@"progress:%f",[numProgress floatValue]);
                        if(progressBlock){
                            progressBlock([numProgress floatValue]);
                        }
                    } finish:^(NSString *fileCachePath) {
                        [RDHelpClass OpenZipp:fileCachePath unzipto:cacheFolderPath];
                        if (callBack) {
                            callBack(nil);
                        }
                    } fail:^(NSError *error) {
                        if (callBack) {
                            callBack(error);
                        }
                    }cancel:^{
                        if (cancelBlock) {
                            cancelBlock();
                        }
                    }];
                }else{
                    [self updateLocalMaterialWithType:type newList:fontList];
                    BOOL suc = [fontList writeToFile:kFontPlistPath atomically:YES];
                    suc = [fontIconDic writeToFile:kFontIconPlistPath atomically:YES];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (callBack) {
                            callBack(nil);
                        }
                    });
                }
            }
                break;
                
            default:
                break;
        }
    });
}

+(void)updateLocalMaterialWith:(RDAdvanceEditType)type newList:( NSArray * ) newList
{
    NSString *folderPath;
    if (type == RDAdvanceEditType_Subtitle) {
        folderPath = kSubtitleFolder;
    }else if (type == RDAdvanceEditType_Sticker) {
        folderPath = kStickerFolder;
    }else {
        folderPath = kFontFolder;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *oldList = nil;
    
    if (type == RDAdvanceEditType_Subtitle) {
        return;
    }else if (type == RDAdvanceEditType_Sticker) {
        oldList = [[NSArray alloc] initWithContentsOfFile:kNewStickerPlistPath];
    }else {
        return;
    }
        
    if( (oldList != nil) && (oldList.count > 0) )
    {
        for ( int i = 0 ; i < newList.count; i++) {
            NSArray * newList1 = newList[ i ];
            NSArray * oldList1 = oldList[ i ];
            
            for (int j = 0; j < newList1.count; j++) {
                NSDictionary * obj1 = newList1[j];
                NSDictionary * obj2 = oldList1[j];
                if (![obj2[@"updatetime"] isEqualToString:obj1[@"updatetime"]]) {
                    NSString *file = [[obj2[@"file"] stringByDeletingLastPathComponent] lastPathComponent];
                    NSString *path = [folderPath stringByAppendingPathComponent:file];
                    if ([fileManager fileExistsAtPath:path]) {
                        [fileManager removeItemAtPath:path error:nil];
                    }
                }
            }
        }
    }
}

+ (void)updateLocalMaterialWithType:(RDAdvanceEditType)type newList:(NSArray *)newList {
    NSString *folderPath;
    if (type == RDAdvanceEditType_Subtitle) {
        folderPath = kSubtitlePlistPath;
    }else if (type == RDAdvanceEditType_Sticker) {
        folderPath = kStickerPlistPath;
    }else {
        folderPath = kFontPlistPath;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *oldList = [[NSArray alloc] initWithContentsOfFile:folderPath];
    if (oldList.count > 0) {
        [newList enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
            NSString *updateTime = obj1[@"updatetime"];
            [oldList enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj2, NSUInteger idx2, BOOL * _Nonnull stop2) {
                if ([obj2[@"id"] intValue] == [obj1[@"id"] intValue]) {
                    if (![obj2[@"updatetime"] isEqualToString:updateTime]) {
                        NSString *file = [[obj2[@"file"] stringByDeletingLastPathComponent] lastPathComponent];
                        NSString *path = [folderPath stringByAppendingPathComponent:file];
                        if ([fileManager fileExistsAtPath:path]) {
                            [fileManager removeItemAtPath:path error:nil];
                        }
                    }
                    *stop2 = YES;
                }
            }];
        }];
    }
}

/**计算转场时间的最大值
 */
+ (double)maxTransitionDuration:(RDFile *)prevFile nextFile:(RDFile *)nextFile {
    double beforeDuration = 0;
    double behindDuration = 0;
    AVURLAsset *asset;
    if(prevFile.fileType == kFILEVIDEO){
        CMTimeRange timeRange = kCMTimeRangeZero;
        if(prevFile.isReverse){
            asset = [AVURLAsset assetWithURL:prevFile.reverseVideoURL];
            if (CMTimeRangeEqual(kCMTimeRangeZero, prevFile.reverseVideoTimeRange)) {
                timeRange = CMTimeRangeMake(kCMTimeZero, prevFile.reverseDurationTime);
            }else{
                timeRange = prevFile.reverseVideoTimeRange;
            }
            if(!CMTimeRangeEqual(kCMTimeRangeZero, prevFile.videoTrimTimeRange) && CMTimeCompare(timeRange.duration, prevFile.reverseVideoTrimTimeRange.duration) == 1){
                timeRange = prevFile.reverseVideoTrimTimeRange;
            }
        }
        else{
            asset = [AVURLAsset assetWithURL:prevFile.contentURL];
            if (CMTimeRangeEqual(kCMTimeRangeZero, prevFile.videoTimeRange)) {
                timeRange = CMTimeRangeMake(kCMTimeZero, prevFile.videoDurationTime);
            }else{
                timeRange = prevFile.videoTimeRange;
            }
            if(!CMTimeRangeEqual(kCMTimeRangeZero, prevFile.videoTrimTimeRange) && CMTimeCompare(timeRange.duration, prevFile.videoTrimTimeRange.duration) == 1){
                timeRange = prevFile.videoTrimTimeRange;
            }
        }
        if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] > 0) {
            AVAssetTrack* clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            if (CMTimeCompare(CMTimeAdd(timeRange.start, timeRange.duration), clipVideoTrack.timeRange.duration) == 1) {
                timeRange = CMTimeRangeMake(timeRange.start, CMTimeSubtract(clipVideoTrack.timeRange.duration, timeRange.start));
            }
        }
        beforeDuration = CMTimeGetSeconds(timeRange.duration)/prevFile.speed;
    }else{
        beforeDuration = CMTimeGetSeconds(prevFile.imageDurationTime);
    }
    
    if(nextFile.fileType == kFILEVIDEO){
        CMTimeRange timeRange = kCMTimeRangeZero;
        if(nextFile.isReverse){
            asset = [AVURLAsset assetWithURL:nextFile.reverseVideoURL];
            if (CMTimeRangeEqual(kCMTimeRangeZero, nextFile.reverseVideoTimeRange)) {
                timeRange = CMTimeRangeMake(kCMTimeZero, nextFile.reverseDurationTime);
            }else{
                timeRange = nextFile.reverseVideoTimeRange;
            }
            if(!CMTimeRangeEqual(kCMTimeRangeZero, nextFile.videoTrimTimeRange) && CMTimeCompare(timeRange.duration, nextFile.reverseVideoTrimTimeRange.duration) == 1){
                timeRange = nextFile.reverseVideoTrimTimeRange;
            }
        }
        else{
            asset = [AVURLAsset assetWithURL:nextFile.contentURL];
            if (CMTimeRangeEqual(kCMTimeRangeZero, nextFile.videoTimeRange)) {
                timeRange = CMTimeRangeMake(kCMTimeZero, nextFile.videoDurationTime);
            }else{
                timeRange = nextFile.videoTimeRange;
            }
            if(!CMTimeRangeEqual(kCMTimeRangeZero, nextFile.videoTrimTimeRange) && CMTimeCompare(timeRange.duration, nextFile.videoTrimTimeRange.duration) == 1){
                timeRange = nextFile.videoTrimTimeRange;
            }
        }
        if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] > 0) {
            AVAssetTrack* clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            if (CMTimeCompare(CMTimeAdd(timeRange.start, timeRange.duration), clipVideoTrack.timeRange.duration) == 1) {
                timeRange = CMTimeRangeMake(timeRange.start, CMTimeSubtract(clipVideoTrack.timeRange.duration, timeRange.start));
            }
        }
        behindDuration = CMTimeGetSeconds(timeRange.duration)/nextFile.speed;
    }else{
        
        behindDuration = CMTimeGetSeconds(nextFile.imageDurationTime);
    }
    
    return MIN(MIN(beforeDuration/2.0, behindDuration/2.0), 2.0);
    
}

+ (CGSize)getEditSizeWithFile:(RDFile *)file {
    CGSize editSize;
    if (file.fileType == kFILEIMAGE || file.fileType == kTEXTTITLE) {
        UIImage *image = [RDHelpClass getFullScreenImageWithUrl:file.contentURL];
        if(file.isHorizontalMirror && file.isVerticalMirror){
            float rotate = 0;
            if(file.rotate == 0){
                rotate = -180;
            }else if(file.rotate == -90){
                rotate = -270;
            }else if(file.rotate == -180){
                rotate = -0;
            }else if(file.rotate == -270){
                rotate = -90;
            }
            image = [RDHelpClass imageRotatedByDegrees:image rotation:rotate];
        }else{
            image = [RDHelpClass imageRotatedByDegrees:image rotation:file.rotate];
        }
        editSize = CGSizeMake(image.size.width*file.crop.size.width, image.size.height*file.crop.size.height);
        image = nil;
    }else {
        if(file.isReverse){
            editSize = [RDHelpClass trackSize:file.reverseVideoURL rotate:file.rotate crop:file.crop];
        }else{
            editSize = [RDHelpClass trackSize:file.contentURL rotate:file.rotate crop:file.crop];
        }
    }
    if (editSize.width > kVIDEOWIDTH || editSize.height > kVIDEOWIDTH) {
        if(editSize.width > editSize.height){
            CGSize tmpsize = editSize;
            editSize.width  = kVIDEOWIDTH;
            editSize.height = kVIDEOWIDTH * tmpsize.height/tmpsize.width;
        }else{
            CGSize tmpsize = editSize;
            editSize.height  = kVIDEOWIDTH;
            editSize.width = kVIDEOWIDTH * tmpsize.width/tmpsize.height;
        }
    }
    return editSize;
}

+ (float)timeFromStr:(NSString *)timeStr {
    float min = 0;
    float second = 0;
    float millisecond = 0;
    NSRange range = [timeStr rangeOfString:@":"];
    if (range.location != NSNotFound) {
        min = [[timeStr substringToIndex:range.location] floatValue];
        timeStr = [timeStr substringFromIndex:range.location + 1];
        range = [timeStr rangeOfString:@"."];
        if (range.location != NSNotFound) {
            second = [[timeStr substringToIndex:range.location] floatValue];
            NSString *millisecondStr = [timeStr substringFromIndex:range.location + 1];
            if (millisecondStr.length > 0) {
                if (millisecondStr.length == 1) {
                    millisecond = [[millisecondStr stringByAppendingString:@"00"] floatValue];
                }else if (millisecondStr.length == 2) {
                    millisecond = [[millisecondStr stringByAppendingString:@"0"] floatValue];
                }else {
                    millisecond = [millisecondStr floatValue];
                }
            }
        }else {
            second = [timeStr floatValue];
        }
    }
    
    float time = min * 60 + second + millisecond/1000.0;
    
    return time;
}

+(void)animateView:(UIView *) view atUP:(bool) isUp
{
    CGRect rect = view.frame;
    if( isUp )
        view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y - view.frame.size
        .height, view.frame.size.width, view.frame.size.height);
    else
        view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y + view.frame.size
                            .height, view.frame.size.width, view.frame.size.height);
    [UIView animateWithDuration:0.1 animations:^{
        view.frame = rect;
    }];
}

+(void)animateViewHidden:(UIView *) view atUP:(bool) isUp atBlock:(void(^)(void))completedBlock
{
    [UIView animateWithDuration:0.25 animations:^{
        if( isUp )
            view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y - view.frame.size
                                    .height, view.frame.size.width, view.frame.size.height);
        else
            view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y + view.frame.size
                                    .height, view.frame.size.width, view.frame.size.height);
    } completion:^(BOOL finished) {
        if( finished )
        {
            if( isUp )
                view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y + view.frame.size
                .height, view.frame.size.width, view.frame.size.height);
            else
                view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y - view.frame.size
            .height, view.frame.size.width, view.frame.size.height);
            if( completedBlock )
            {
                completedBlock();
            }
        }
    }];
}

+ (void)setAssetAnimationArray:(VVAsset *)asset
                          name:(NSString *)name
                      duration:(float)duration
                        center:(CGPoint)center
                         scale:(float)scale
{
    if (!name || name.length == 0) {
        asset.animate = nil;
        return;
    }
    NSString *animationConfigPath = [[RDResourceBundle resourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"AssetAnimation/json/%@.json", name]];
    NSData *jsonData = [[NSData alloc] initWithContentsOfFile:animationConfigPath];
    NSArray *animationArray = [RDHelpClass objectForData:jsonData];
    jsonData = nil;
    float fps = roundf(1.0/[[animationArray[0] objectForKey:@"t"] floatValue]*10.0);
    if (fps == 0) {
        fps = kEXPORTFPS;
    }
    NSMutableArray *pointsArray = [NSMutableArray array];
    for (NSDictionary *dic in animationArray) {
        if ([dic[@"d"] boolValue] == true) {
            [pointsArray addObject:dic[@"c"]];
        }
    }
    float animationDuration = pointsArray.count / fps;
    float factor = duration / animationDuration;
    NSMutableArray *animateArray = [NSMutableArray array];
    for (int j = 0; j < pointsArray.count; j++) {
        VVAssetAnimatePosition *animate = [[VVAssetAnimatePosition alloc] init];
        animate.atTime = j/fps * factor;
        if (animate.atTime > CMTimeGetSeconds(asset.timeRange.duration)) {
            break;
        }
        float y2_o = [pointsArray[j][3] floatValue] - [pointsArray[j][1] floatValue];
        float x2_o = [pointsArray[j][2] floatValue] - [pointsArray[j][0] floatValue];
        double rotate = atan(fabsf(y2_o) / fabsf(x2_o)) * 180.0 / M_PI;
        if (x2_o < 0) {
            animate.rotate = 180 - rotate;
        }else if (y2_o >= 0) {
            animate.rotate = -rotate;
        }else {
            animate.rotate = rotate;
        }
        float w = sqrt(x2_o * x2_o + y2_o * y2_o);
        float scaleAnimate = w / 100.0 * scale;
        float cx_o = ([pointsArray[j][0] floatValue] + w/2.0)/1280.0;//json中的视频分辨率为1280*1280，媒体大小为100*100
        float cy_o = ([pointsArray[j][1] floatValue] + w/2.0)/1280.0;
        CGRect rect = CGRectMake(cx_o + ( center.x - scaleAnimate/2.0 ) - 0.5, cy_o + ( center.y - scaleAnimate/2.0 ) - 0.5, scaleAnimate, scaleAnimate);
#if 1
        animate.rect = rect;
//        NSLog(@"%d%@%@ rotate:%.2f scale:%.2f", j, NSStringFromCGPoint(CGPointMake(cx_o, cy_o)), NSStringFromCGPoint(animate.rect.origin),  animate.rotate, scale);
#else
        CGPoint lt = CGPointMake(rect.origin.x, rect.origin.y);
        CGPoint rt = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y);
        CGPoint rb = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
        CGPoint lb = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
        CGPoint rtNew = [self getRotatedPoint:rt rotate:animate.rotate anchorPoint:lt];
        CGPoint rbNew = [self getRotatedPoint:rb rotate:animate.rotate anchorPoint:lt];
        CGPoint lbNew = [self getRotatedPoint:lb rotate:animate.rotate anchorPoint:lt];
        NSLog(@"rotate:%f rt:%@%@ \n rb:%@%@ \n lb:%@%@", animate.rotate, NSStringFromCGPoint(rt), NSStringFromCGPoint(rtNew), NSStringFromCGPoint(rb), NSStringFromCGPoint(rbNew), NSStringFromCGPoint(lb), NSStringFromCGPoint(lbNew));
        [animate setPointsLeftTop:lt rightTop:rtNew rightBottom:rbNew leftBottom:lbNew];
#endif
//        NSLog(@"%f", animate.atTime);
        animate.crop = asset.crop;
        animate.opacity = asset.alpha;
        animate.brightness = asset.brightness;
        animate.contrast = asset.contrast;
        animate.saturation = asset.saturation;
        animate.vignette = asset.vignette;
        animate.sharpness = asset.sharpness;
        animate.whiteBalance = asset.whiteBalance;
        [animateArray addObject:animate];
    }
    asset.animate = animateArray;
}

+ (CGPoint)getRotatedPoint:(CGPoint)oldPoint rotate:(float)rotate anchorPoint:(CGPoint)anchorPoint {
    float x = (oldPoint.x - anchorPoint.x) * cos(rotate) - (oldPoint.y - anchorPoint.y) * sin(rotate) + anchorPoint.x;
    float y = (oldPoint.x - anchorPoint.x) * sin(rotate) + (oldPoint.y - anchorPoint.y) * cos(rotate) + anchorPoint.y;
    return CGPointMake(x, y);
}

+(NSString *)getMaterialThumbnail:(NSURL *) fileUrl
{
    NSString *fileName = @"";
    if ([fileUrl.scheme.lowercaseString isEqualToString:@"ipod-library"]
        || [fileUrl.scheme.lowercaseString isEqualToString:@"assets-library"])
    {
        NSRange range = [fileUrl.absoluteString rangeOfString:@"?id="];
        if (range.location != NSNotFound) {
            fileName = [fileUrl.absoluteString substringFromIndex:range.length + range.location];
            range = [fileName rangeOfString:@"&ext"];
            fileName = [fileName substringToIndex:range.location];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmssSSS";
            NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
            fileName = [fileName stringByAppendingString:nowTimeStr];
        }
    }else {
        fileName = [[fileUrl.path lastPathComponent] stringByDeletingPathExtension];
    }
    
    fileName = [fileName stringByAppendingFormat:@"_%d",MaterialThumbnail++];
    
    NSArray*paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString*path=[paths objectAtIndex:0];
    
    NSString *folderPath = [path stringByAppendingPathComponent:VIDEO_FILEIMAGE];
    fileName = [NSString stringWithFormat:@"%@",fileName];
    __block NSString *str = [folderPath stringByAppendingPathComponent:fileName];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:str]){
        [[NSFileManager defaultManager] createDirectoryAtPath:str withIntermediateDirectories:YES attributes:nil error:nil];
    }
    else{
        [self deleteMaterialThumbnail:str];
        [[NSFileManager defaultManager] createDirectoryAtPath:str withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return str;
}

+(void)save_Image:(int) currentIndex atURL:(NSURL *) url atPatch:(NSString *) fileImagePatch atTimes:(NSMutableArray *) times
{
    AVAssetImageGenerator *imageGenerator;
    imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:[AVURLAsset assetWithURL:url]];
    
    imageGenerator.appliesPreferredTrackTransform = YES;
    imageGenerator.maximumSize = CGSizeMake(120, 120);
    
    __block int index = currentIndex;
    [imageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        
        UIImage* videoScreen = [[UIImage alloc] initWithCGImage:image scale:3.0 orientation:UIImageOrientationUp];
        
        NSString *filePath = [fileImagePatch stringByAppendingPathComponent:
                              [NSString stringWithFormat:@"%d.png",index]];  // 保存文件的名称
        
//        NSLog(@"Image:%@,%d",filePath,index);
        
        [UIImagePNGRepresentation(videoScreen) writeToFile:filePath atomically:YES];
        
        videoScreen = nil;
        
        index++;
    }];
    
    imageGenerator = nil;
    
    for (; index != ( currentIndex + times.count );) {
        sleep(0.1);
    }
}

+(void)fileImage_Save:(NSMutableArray<RDFile *> *) fileArray atProgress:(void(^)(float progress))completedBlock atReturn:(void(^)(bool isSuccess))completedReturn
{
    NSMutableArray<RDFile *> * newFileArray = [fileArray mutableCopy];
    
    int count = 0;
    int currentIndex = 0;
    
    for (int i = 0; i< newFileArray.count; i++) {
        RDFile *file = newFileArray[i];
        if( file.fileType ==  kFILEVIDEO )
        {
            CMTimeRange timeRange = file.videoActualTimeRange;
            if (CMTimeRangeEqual(timeRange, kCMTimeRangeZero) || CMTimeRangeEqual(timeRange, kCMTimeRangeInvalid)) {
                timeRange = [RDVECore getActualTimeRange:file.contentURL];
                file.videoActualTimeRange = timeRange;
            }
            int time = ceilf(CMTimeGetSeconds(timeRange.duration));
            count += time+1;
        }
        else if( file.isGif )
        {
            CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, file.imageDurationTime);
            int time = ceilf(CMTimeGetSeconds(timeRange.duration));
            count += time+1;
        }
    }
    
    for (int i = 0; i< newFileArray.count; i++) {
        
        RDFile *file = newFileArray[i];
        if( (file.fileType == kFILEIMAGE) && ( !file.isGif ) )
            continue;
        
        NSString * filtImagePatch = file.filtImagePatch;
        CMTimeRange timeRange = file.videoActualTimeRange;
        
        if( file.isGif )
            timeRange = CMTimeRangeMake(kCMTimeZero, file.imageDurationTime);
        
        float time = ceilf(CMTimeGetSeconds(timeRange.duration)) + 1;
        
        float filCurrentIndex = 0;
        
        float fileImageCount = 50.0;
        int   iFileImageCOunt = ceilf(fileImageCount);
         
        int jCount = ceilf( time/fileImageCount );
        
        for (int j = 0; j < jCount; j++) {
            
            int tCount =  (j==( jCount- 1))?(((int)time)%iFileImageCOunt):iFileImageCOunt;
            
            if( (tCount == 0) && ( jCount == 1 ) )
            {
                tCount = time;
            }

            //获取时间
            NSMutableArray *times = [[NSMutableArray alloc] init];
            for (int t = 0; t < tCount ; t++) {
                
                float currentTime = ( (filCurrentIndex+t) >= time )?CMTimeGetSeconds(timeRange.duration) - 0.2:(filCurrentIndex+t);
                
                [times addObject:  [NSValue valueWithCMTime: CMTimeMakeWithSeconds(currentTime, TIMESCALE) ] ];
            }
            
            //获取图片
            if( file.fileType == kFILEVIDEO )
                [RDHelpClass save_Image:filCurrentIndex atURL:file.contentURL atPatch:filtImagePatch atTimes:times];
            else if( file.isGif )
            {
                for (int i = 0; i < times.count; i++) {
                    UIImage* videoScreen = [UIImage getGifThumbImageWithData:file.gifData time:CMTimeGetSeconds( [times[i]  CMTimeValue] )];
                    NSString *filePath = [filtImagePatch stringByAppendingPathComponent:
                    [NSString stringWithFormat:@"%d.png",i]];
                    [UIImagePNGRepresentation(videoScreen) writeToFile:filePath atomically:YES];
                    
                }
            }
            filCurrentIndex += times.count;
            currentIndex += times.count;
            [times removeAllObjects];
            times = nil;
            
            if( completedBlock )
            {
                completedBlock( ((float)currentIndex)/((float)count) );
            }
        }
        
        if( i == (newFileArray.count-1) )
        {
            [newFileArray removeAllObjects];
            break;
        }
    }
    
    if( completedReturn )
    {
        completedReturn(YES);
    }
}

+(void)deleteMaterialThumbnail:(NSString *) file
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
        [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
    }
}

+ (UIImage *)scaleImage:(UIImage *)image toScale:(float)scaleSize
{
    UIGraphicsBeginImageContext(CGSizeMake(image.size.width * scaleSize, image.size.height * scaleSize));
    [image drawInRect:CGRectMake(0, 0, image.size.width * scaleSize, image.size.height * scaleSize)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

//背景画布
#pragma mark- 组装场景背景媒体
+(VVAsset *)canvasFile:(RDFile *) file
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
            NSLog(@"timeRange : %f : %f ",CMTimeGetSeconds(vvasset.timeRange.start),CMTimeGetSeconds(vvasset.timeRange.duration));
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
            NSLog(@"timeRange : %f : %f ",CMTimeGetSeconds(vvasset.timeRange.start),CMTimeGetSeconds(vvasset.timeRange.duration));
        }
        vvasset.speed        = file.speed;
        vvasset.volume       = file.videoVolume;
        vvasset.audioFadeInDuration = file.audioFadeInDuration;
        vvasset.audioFadeOutDuration = file.audioFadeOutDuration;
        
        
    }else{
        vvasset.type         = RDAssetTypeImage;
        if (CMTimeCompare(file.imageTimeRange.duration, kCMTimeZero) == 1) {
            vvasset.timeRange = file.imageTimeRange;
            
            
        }else {
            vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, file.imageDurationTime);
        }
        NSLog(@"场景背景时长：%.2f s",CMTimeGetSeconds(vvasset.timeRange.duration));
        vvasset.speed        = file.speed;
#if isUseCustomLayer
        if (file.fileType == kTEXTTITLE) {
            file.imageTimeRange = vvasset.timeRange;
            vvasset.fillType = RDImageFillTypeFit;
        }
#endif
         vvasset.fillType = RDImageFillTypeFit;
    }
    vvasset.blurIntensity = file.BackgroundBlurIntensity;
    vvasset.rotate = file.rotate;
    vvasset.isVerticalMirror = file.isVerticalMirror;
    vvasset.isHorizontalMirror = file.isHorizontalMirror;
    vvasset.brightness = file.brightness;
    vvasset.contrast = file.contrast;
    vvasset.saturation = file.saturation;
    vvasset.sharpness = file.sharpness;
    vvasset.whiteBalance = file.whiteBalance;
    vvasset.vignette = file.vignette;
    
    vvasset.crop = file.crop;
    
    return vvasset;
}
#pragma mark- 根据图片地址生对应的RDFile
+(RDFile *)canvas_BackgroundPicture:(NSString *) strPatch
{
    RDFile * file = [RDFile new];
    file.contentURL = [NSURL fileURLWithPath:strPatch];
    file.fileType = kFILEIMAGE;
    file.imageDurationTime = CMTimeMakeWithSeconds(3, TIMESCALE);
    file.isVerticalMirror = NO;
    file.isHorizontalMirror = NO;
    file.speed = 1;
    file.speedIndex = 1;
    file.crop = CGRectMake(0, 0, 1, 1);
    file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
    return file;
}
#pragma mark- 适配比例 按指定比例计算素材裁剪比例
+(void)fileCrop:(RDFile *) file atfileCropModeType:(FileCropModeType) ProportionIndex atEditSize:(CGSize) editSize
{
    CGSize fileVideoSize;
    if( file.fileType == kFILEVIDEO )
        fileVideoSize = [RDHelpClass getVideoSizeForTrack:[AVURLAsset assetWithURL:file.contentURL]];
    else {
        fileVideoSize = [RDHelpClass getFullScreenImageWithUrl:file.contentURL].size;;
    }
    CGSize size = CGSizeZero;
    if( ( ( ((int)(file.rotate))/90)%2) != 0 )
    {
        fileVideoSize = CGSizeMake(fileVideoSize.height, fileVideoSize.width);
    }
    
    switch ( ProportionIndex ) {
        case kCropTypeOriginal://原始
        {
            //判断裁剪最少的一边
            float fAspectRatio = editSize.width/editSize.height;
            //已对应宽高算出的 裁剪后的宽高
            float fTailoringWidth = fAspectRatio * fileVideoSize.height;
            float fTailoringHeight = fileVideoSize.width/fAspectRatio;
            
            //裁剪数值
            float fSurplusWidth = fileVideoSize.width - fTailoringWidth;
            float fSurplusHeight = fileVideoSize.height - fTailoringHeight;
            
            if( (fSurplusWidth < 0) || ( fSurplusWidth < fSurplusHeight ) )
            {
                size = CGSizeMake(fileVideoSize.width, fTailoringHeight);
            }
            else if( (fSurplusHeight < 0) || ( fSurplusWidth > fSurplusHeight )  ) {
                size = CGSizeMake(fTailoringWidth,fileVideoSize.height);
            }else {
                size = fileVideoSize;
            }
        }
            break;
        case kCropType1v1://正方形
        {
            float fileWidth = MIN(fileVideoSize.width, fileVideoSize.height);
            size = CGSizeMake(fileWidth, fileWidth);
        }
            break;
        case kCropType16v9://16:9
        {
            float height = (9.0/16.0) * fileVideoSize.width;
            if( height <= fileVideoSize.height ) {
                size = CGSizeMake(fileVideoSize.width, height);
            }else {
                float width = (16.0/9.0) * fileVideoSize.height;
                size = CGSizeMake(width, fileVideoSize.height);
            }
        }
            break;
        case kCropType9v16://9:16
        {
            float width = (9.0/16.0) * fileVideoSize.height;
            if( width <= fileVideoSize.width ) {
                size = CGSizeMake(width, fileVideoSize.height);
            }else {
                float height = (16.0/9.0) * fileVideoSize.width;
                size = CGSizeMake(fileVideoSize.width, height);
            }
        }
            break;
        case kCropType4v3://4:3
        {
            float width = (4.0/3.0) * fileVideoSize.height;
            if( width <= fileVideoSize.width )
            {
                size = CGSizeMake(width, fileVideoSize.height);
            }else {
                float height = (3.0/4.0) * fileVideoSize.width;
                size = CGSizeMake(fileVideoSize.width, height);
            }
        }
            break;
        case kCropType3v4://3:4
        {
            float height = (4.0/3.0) * fileVideoSize.width;
            if( height <= fileVideoSize.height )
            {
                size = CGSizeMake(fileVideoSize.width, height);
            }else {
                float width = (3.0/4.0) * fileVideoSize.height;
                size = CGSizeMake(width, fileVideoSize.height);
            }
        }
            break;
        default:
            break;
    }
    
    float fwidth = (fileVideoSize.width - size.width)/fileVideoSize.width;
    float fheight = (fileVideoSize.height - size.height)/fileVideoSize.height;
//    if( ( ( ((int)(file.rotate))/90)%2) != 0 )
//        file.crop = CGRectMake( fheight/2.0 , fwidth/2.0, 1.0 - fheight, 1.0 - fwidth);
//    else
    file.crop = CGRectMake( fwidth/2.0 , fheight/2.0, 1.0 - fwidth, 1.0 - fheight);
    file.cropRect = CGRectMake(-1, -1, -1, -1);
    file.fileCropModeType = ProportionIndex;
}

+ (NSMutableArray *)getTransitionArray {
    NSMutableArray *transitionList = [NSMutableArray arrayWithContentsOfFile:kLocalTransitionPlist];
    NSArray *moreArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[kLocalTransitionFolder stringByAppendingPathComponent:@"更多/Icon"] error:nil];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES];  //YES为升序,NO为降序
    NSArray *dcriptorArr = [moreArray sortedArrayUsingDescriptors:@[descriptor]];
    [[transitionList lastObject] setObject:dcriptorArr forKey:@"data"];
    return transitionList;
}

+ (NSString *)getTransitionIconPath:(NSString *)typeName itemName:(NSString *)itemName {
    NSString *iconPath = [[[kLocalTransitionFolder stringByAppendingPathComponent:typeName] stringByAppendingPathComponent:@"Icon"] stringByAppendingPathComponent:itemName];
    return [iconPath stringByAppendingPathExtension:@"jpg"];
}

+ (NSString *)getTransitionPath:(NSString *)typeName itemName:(NSString *)itemName {
    NSString *path = [[[[kLocalTransitionFolder stringByAppendingPathComponent:typeName] stringByAppendingPathComponent:@"Json"] stringByAppendingPathComponent:itemName] stringByAppendingPathComponent:@"config.json"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        path = nil;
    }
    if (!path && ![typeName isEqualToString:kDefaultTransitionTypeName]) {
        path = [[[[kLocalTransitionFolder stringByAppendingPathComponent:typeName] stringByAppendingPathComponent:@"Icon"] stringByAppendingPathComponent:itemName] stringByAppendingPathExtension:@"jpg"];
    }
    return path;
}

+ (void)setTransition:(VVTransition *)transition file:(RDFile *)file {
    if ([file.transitionMask.pathExtension isEqualToString:@"jpg"]) {
        transition.type = RDVideoTransitionTypeMask;
    }else if (file.transitionMask) {
        transition.type = RDVideoTransitionTypeCustom;
        NSString *configPath = [RDHelpClass getTransitionPath:file.transitionTypeName itemName:file.transitionName];
        transition.customTransition = [RDGenSpecialEffect getCustomTransitionWithJsonPath:configPath];
    }else if ([file.transitionTypeName isEqualToString:kDefaultTransitionTypeName]) {
        if ([file.transitionName isEqualToString:@"闪黑"]) {
            transition.type = RDVideoTransitionTypeBlinkBlack;
        }else if ([file.transitionName isEqualToString:@"闪白"]) {
            transition.type = RDVideoTransitionTypeBlinkWhite;
        }else if ([file.transitionName isEqualToString:@"上移"]) {
            transition.type = RDVideoTransitionTypeUp;
        }else if ([file.transitionName isEqualToString:@"下移"]) {
            transition.type = RDVideoTransitionTypeDown;
        }else if ([file.transitionName isEqualToString:@"左移"]) {
            transition.type = RDVideoTransitionTypeLeft;
        }else if ([file.transitionName isEqualToString:@"右移"]) {
            transition.type = RDVideoTransitionTypeRight;
        }
    }else {
        transition.type = RDVideoTransitionTypeNone;
    }
    transition.maskURL = file.transitionMask;
    transition.duration = file.transitionDuration;
}

+(UIView *)loadProgressView:(CGRect) rect
{
    UIColor *color = [UIColor colorWithWhite:0.0 alpha:0.4];
    UIView * loadProgressView = [[UIView alloc] initWithFrame:rect];
    loadProgressView.backgroundColor = color;
    loadProgressView.tag = 0;
    
    UILabel * textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, loadProgressView.frame.size.width, loadProgressView.frame.size.height)];
    textLabel.backgroundColor = color;
    textLabel.text = @"0%";
    textLabel.tag = 1;
    textLabel.textAlignment = NSTextAlignmentCenter;
    textLabel.font = [UIFont systemFontOfSize:12];
    textLabel.textColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    
    [loadProgressView addSubview:textLabel];
    
    return loadProgressView;
}

+ (void)seplace_File:(SUPPORTFILETYPE)type touchConnect:(BOOL) isTouch   navigationVidew:(RDNavigationViewController * )navigationController exportSize:(CGSize) exportSize ViewController:(UIViewController *) ViewController  callbackBlock:(void (^)(NSMutableArray *lists))callbackBlock{
    
    if(([navigationController.rdVeUiSdkDelegate respondsToSelector:@selector(selectVideoAndImageResult:callbackBlock:)] ||
        [navigationController.rdVeUiSdkDelegate respondsToSelector:@selector(selectVideosResult:callbackBlock:)] ||
        [navigationController.rdVeUiSdkDelegate respondsToSelector:@selector(selectImagesResult:callbackBlock:)])){
    
        if(type == ONLYSUPPORT_VIDEO){
            if([navigationController.rdVeUiSdkDelegate respondsToSelector:@selector(selectVideosResult:callbackBlock:)]){
                [navigationController.rdVeUiSdkDelegate selectVideosResult:navigationController callbackBlock:^(NSMutableArray * _Nonnull lists) {
                        callbackBlock(lists);
                    
                }];
                return;
            }
        }
        else if(type == SUPPORT_ALL){
            if([navigationController.rdVeUiSdkDelegate respondsToSelector:@selector(selectVideoAndImageResult:callbackBlock:)]){
                [navigationController.rdVeUiSdkDelegate selectVideoAndImageResult:navigationController callbackBlock:^(NSMutableArray * _Nonnull lists) {
                    callbackBlock(lists);
                }];
                
                return;
            }
        }else {
            if([navigationController.rdVeUiSdkDelegate respondsToSelector:@selector(selectImagesResult:callbackBlock:)]){
                [navigationController.rdVeUiSdkDelegate selectImagesResult:navigationController callbackBlock:^(NSMutableArray * _Nonnull lists) {
                    callbackBlock(lists);
                }];
                
                return;
            }
        }
        
    }
    navigationController.cameraConfiguration.cameraOutputPath = navigationController.cameraConfiguration.cameraOutputPath;;
    
    RDMainViewController *mainVC = [[RDMainViewController alloc] init];
    if(type == ONLYSUPPORT_IMAGE){
        mainVC.showPhotos = YES;
    }
    
    mainVC.minCountLimit = 1;
    mainVC.textPhotoProportion = exportSize.width/(float)exportSize.height;
    mainVC.selectFinishActionBlock = ^(NSMutableArray <RDFile *>*filelist) {
            callbackBlock(filelist);
    };
    RDNavigationViewController* nav = [[RDNavigationViewController alloc] initWithRootViewController:mainVC];
    nav.editConfiguration.enableTextTitle = false;
    [RDHelpClass setPresentNavConfig:nav currentNav:navigationController];
    
    nav.editConfiguration.mediaCountLimit = 1;
    
    nav.navigationBarHidden = YES;
    [ViewController presentViewController:nav animated:NO completion:nil];
}

+(RDFile *)vassetToFile:(VVAsset *) vvasset
{
    RDFile * file = [RDFile new];
    
    file.contentURL = vvasset.url;
    file.speed = vvasset.speed;
    file.crop = vvasset.crop;
    file.rotate = vvasset.rotate;
    file.isHorizontalMirror = vvasset.isHorizontalMirror;
    file.isVerticalMirror = vvasset.isVerticalMirror;
    
    if( vvasset.type == RDAssetTypeVideo )
    {
        file.videoTimeRange = [RDVECore getActualTimeRange:file.contentURL];
        file.fileType = kFILEVIDEO;
        file.videoTrimTimeRange  = [RDVECore getActualTimeRange:file.contentURL];
        file.videoTrimTimeRange = vvasset.timeRange;
    }
    else{
        file.imageTimeRange = vvasset.timeRange;
        file.fileType = kFILEIMAGE;
    }
    
    return file;
}

/**进入截取
 */
+ (void)enter_Trim:(RDFile * ) file navigationVidew:(RDNavigationViewController * )navigationController  ViewController:(UIViewController *) ViewController   callbackBlock:(void (^)(CMTimeRange timeRange))callbackBlock{
    
    RDTrimVideoViewController *trimVideoVC = [[RDTrimVideoViewController alloc] init];
    trimVideoVC.trimFile = file;
    
    trimVideoVC.TrimVideoFinishBlock = ^(CMTimeRange timeRange) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            callbackBlock( timeRange );
            
        });
    };
    
    RDNavigationViewController *nav = [[RDNavigationViewController alloc] initWithRootViewController:trimVideoVC];
    [RDHelpClass setPresentNavConfig:nav currentNav:navigationController];
    nav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [ViewController presentViewController:nav animated:YES completion:nil];
}

/**进入变速
 */
+ (void)enter_Speed:(RDFile * ) file navigationVidew:(RDNavigationViewController * )navigationController  ViewController:(UIViewController *) ViewController   callbackBlock:(void (^)(RDFile *file, BOOL useAllFile))callbackBlock{
    
    ChangeSpeedVideoViewController *changeSpeedVC = [[ChangeSpeedVideoViewController alloc] init];
    changeSpeedVC.selectFile = file;
    changeSpeedVC.changeSpeedVideoFinishAction = ^(RDFile *file, BOOL useAllFile) {
        
        callbackBlock(file,useAllFile);
        
    };
    
    [navigationController pushViewController:changeSpeedVC animated:NO];
}

/**进入裁切
 */
+ (void)enter_Edit:(RDFile * ) file navigationVidew:(RDNavigationViewController * )navigationController  ViewController:(UIViewController *) ViewController   callbackBlock:(void (^)(CGRect crop, CGRect cropRect, BOOL verticalMirror, BOOL horizontalMirror, float rotate, FileCropModeType cropModeType))callbackBlock{
    __weak typeof(self) weakSelf = self;
    CropViewController *cropVC = [[CropViewController alloc] init];
    cropVC.selectFile       = file;
    cropVC.editVideoForOnceFinishAction = ^(CGRect crop, CGRect cropRect, BOOL verticalMirror, BOOL horizontalMirror, float rotate, FileCropModeType cropModeType) {
        callbackBlock(crop,cropRect,verticalMirror,horizontalMirror,rotate,cropModeType);
    };
    
    RDNavigationViewController *nav = [[RDNavigationViewController alloc] initWithRootViewController:cropVC];
    [RDHelpClass setPresentNavConfig:nav currentNav:navigationController];
    nav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [ViewController presentViewController:nav animated:YES completion:nil];
}

+ (RDCaptionAnimateType)captionAnimateToRDCaptionAnimate:(CaptionAnimateType)type {
    RDCaptionAnimateType resultType;
    switch (type) {
        case CaptionAnimateTypeUp:
        case CaptionAnimateTypeDown:
        case CaptionAnimateTypeLeft:
        case CaptionAnimateTypeRight:
            resultType = RDCaptionAnimateTypeMove;
            break;
            
        case CaptionAnimateTypeScaleInOut:
            resultType = RDCaptionAnimateTypeScaleInOut;
            break;
            
        case CaptionAnimateTypeScrollInOut:
            resultType = RDCaptionAnimateTypeScrollInOut;
            break;
            
        case CaptionAnimateTypeFadeInOut:
            resultType = RDCaptionAnimateTypeFadeInOut;
            break;
            
        default:
            resultType = RDCaptionAnimateTypeNone;
            break;
    }
    return resultType;
}

@end
