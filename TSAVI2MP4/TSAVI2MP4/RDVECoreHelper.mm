//
//  TSAVI2MP4.m
//  TSAVI2MP4
//
//  Created by 周晓林 on 2017/9/21.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#import "RDVECoreHelper.h"
#include "MP4Encoder.hpp"
#include "TsUnpack.hpp"
#include "AviUnpack.hpp"
#include "Timer.h"
//#import "RDTSAVIToMp4Helper.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <sys/utsname.h>
#import "NSString+RDTSAVI_Encrypt.h"
#import <CommonCrypto/CommonDigest.h>
#import <string.h>
#include "FreeTransform.h"
#define kAPPSIGNATUREURL @"https://ssl.17rd.com/api/appverify/signature"//检测授权
#define CustomErrorDomain @"com.17rd.rdsdk"
#define kEI_AppKey      @"RDVECORE_EIRDAPPKEY"       //编辑appkey
#define kEI_AppSecret   @"RDVECORE_EIRDAPPSECTET"    //编辑appsecret
#define kLI_AppKey      @"RDVECORE_LIRDAPPKEY"       //直播appkey
#define kLI_AppSecret   @"RDVECORE_LIRDAPPSECTET"    //直播appsecret
#define kCI_AppKey      @"RDVECORE_CIRDAPPKEY"       //云存储appkey
#define kCI_AppSecret   @"RDVECORE_CIRDAPPSECTET"    //云存储appsecret
#define VIDEO_FOLDER    @"videos"

@interface RDVECoreHelper()
{
    BOOL _sdkDisabled;
     CFreeTransform freetransform;
}
@end

@implementation RDVECoreHelper
- (instancetype) initWithAPPKey:(NSString *)appkey
                      APPSecret:(NSString *)appsecret
                     resultFail:(void (^)(NSError *error))resultFailBlock{
    
    self = [super init];
    if (self) {
        void (^initFailureBlock)(NSError *error)=^(NSError *error){
            if (resultFailBlock) {
                resultFailBlock(error);
            }
        };
        //检查授权
        _sdkDisabled = NO;
        [self checkPermissions:appkey
                                   appsecret:appsecret
                                     appType:1
                                     success:^(NSError *error){
                                         _sdkDisabled = NO;
                                     } resultFailBlock:^(NSError *error) {
                                         NSLog(@"SDK已禁用");
                                         _sdkDisabled = YES;
                                         if(initFailureBlock){
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 initFailureBlock(error);
                                             });
                                         }
                                     }];
    }
    return self;
}

- (instancetype)init{
    self = [super init];
    _sdkDisabled = YES;
    return self;
}

- (void)TSAVItoMP4:(NSString *)sourcePath outputFilePath:(NSString *)outputFilePath keepAudio:(bool)keepAudio progressBlock:(void(^)(float progress)) progressBlock completedBlock:(void(^)(NSError *error))completedBlock{
    if(_sdkDisabled){
        NSLog(@"SDK已禁用");
        NSDictionary *userInfo= [NSDictionary dictionaryWithObject:@"SDK已禁用" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:CustomErrorDomain code:200 userInfo:userInfo];
        if(completedBlock)
            completedBlock(error);
        return;
    }
    
    if(sourcePath.length==0){
        NSLog(@"源文件路径不能为空");
        NSDictionary *userInfo= [NSDictionary dictionaryWithObject:@"源文件路径不能为空" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:CustomErrorDomain code:201 userInfo:userInfo];
        if(completedBlock)
            completedBlock(error);
        return;
    }
    if(outputFilePath.length==0){
        NSLog(@"输出路径不能为空");
        NSDictionary *userInfo= [NSDictionary dictionaryWithObject:@"输出路径不能为空" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:CustomErrorDomain code:202 userInfo:userInfo];
        if(completedBlock)
            completedBlock(error);
        return;
    }
    unlink([outputFilePath UTF8String]);
    
    
    auto startTime = std::chrono::high_resolution_clock::now();
    bool succ = true;
    if([[[sourcePath pathExtension] lowercaseString] isEqualToString:@"ts"]){
        CTsUnpack Unpack;
        
        Timer t;
        t.StartTimer(100, [&](){
            float progress = Unpack.GetProgress();
            //printf(">>>%f\n",progress);
            if(progressBlock)
                progressBlock(progress);
            
        });
        
        succ = Unpack.Unpack([sourcePath UTF8String], [outputFilePath UTF8String],keepAudio);
        t.Expire();
        
    }else if([[[sourcePath pathExtension] lowercaseString] isEqualToString:@"avi"]){
        
        CAviUnpack Unpack;
        
        Timer t;
        t.StartTimer(100, [&](){
            float progress = Unpack.GetProgress();
            printf(">>>%f\n",progress);
            if(progressBlock)
                progressBlock(progress);
            
        });
        
        succ = Unpack.Unpack([sourcePath UTF8String], [outputFilePath UTF8String],keepAudio);
        t.Expire();
            
    }else{
        NSLog(@"源文件格式错误");
        NSDictionary *userInfo= [NSDictionary dictionaryWithObject:@"源文件格式错误" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:CustomErrorDomain code:202 userInfo:userInfo];
        if(completedBlock)
            completedBlock(error);
        return;
        
    }
    
    
    if (succ) {
        auto endTime = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration<float,std::ratio<1>>(endTime-startTime).count();
        NSLog(@"Success  %f",duration);
        //UISaveVideoAtPathToSavedPhotosAlbum(pathToMovie, self, nil, nil);
        completedBlock(nil);
    }else{
        NSLog(@"Error");
        NSDictionary *userInfo= [NSDictionary dictionaryWithObject:@"转换失败" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:CustomErrorDomain code:202 userInfo:userInfo];
        if(completedBlock)
            completedBlock(error);
    }
    
}



- (void)checkPermissions:(NSString *)appkey
               appsecret:(NSString *)appSecret
                 appType:(NSInteger)type
                 success:(void(^)(NSError *error))succeessBlock
         resultFailBlock:(void(^)(NSError *error))resultFailBlock
{
    NSString *oldAppKey;
    NSString *newAppSecret = appSecret;
    if(type == 1){
        oldAppKey = [[NSUserDefaults standardUserDefaults] objectForKey:kEI_AppKey];
        if ([appkey isEqualToString:oldAppKey]) {
            newAppSecret = [[NSUserDefaults standardUserDefaults] objectForKey:kEI_AppSecret];
        }
    }else if(type == 2){
        oldAppKey = [[NSUserDefaults standardUserDefaults] objectForKey:kLI_AppKey];
        if ([appkey isEqualToString:oldAppKey]) {
            newAppSecret = [[NSUserDefaults standardUserDefaults] objectForKey:kLI_AppSecret];
        }
    }else{
        oldAppKey = [[NSUserDefaults standardUserDefaults] objectForKey:kCI_AppKey];
        if ([appkey isEqualToString:oldAppKey]) {
            newAppSecret = [[NSUserDefaults standardUserDefaults] objectForKey:kCI_AppSecret];
        }
    }
    if(!newAppSecret || newAppSecret.length == 0){
        newAppSecret = [appSecret substringFromIndex:32];
    }
    
    if(appkey.length == 0 || newAppSecret.length == 0){
        NSDictionary *userInfo= [NSDictionary dictionaryWithObject:@"appkey 和 appsecret 不能为空" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:CustomErrorDomain code:200 userInfo:userInfo];
        NSLog(@"error:%@",error);
        resultFailBlock(error);
        return;
    }
    
    [self updatePermissionsAppKey:appkey
                        appsercet:newAppSecret
                             type:type
                          success:succeessBlock
                       resultFail:resultFailBlock];
}

- (void)updatePermissionsAppKey:(NSString *)appkey
                      appsercet:(NSString *)appsercet
                           type:(NSInteger)type
                        success:(void(^)(NSError *error))succeessBlock
                     resultFail:(void(^)(NSError *error))resultFailBlock
{
    NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[NSNumber numberWithInteger:1] forKey:@"os"];
    if(bundleName){
        [params setObject:bundleName forKey:@"packname"];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *reslutDic = [self checkSignaturewWithAPPKey:appkey appSecret:appsercet params:params andUploadUrl:kAPPSIGNATUREURL];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!reslutDic){
                NSLog(@"授权成功");
                if (succeessBlock) {
                    succeessBlock(nil);
                }
            }
            else{
                if([[reslutDic objectForKey:@"code"]integerValue] !=200){
                    NSString *message = [reslutDic objectForKey:@"message"];
                    NSLog(@"%@",message);
                    NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:message,@"message", nil];
                    NSError *error = [NSError errorWithDomain:CustomErrorDomain code:400 userInfo:userInfo];
                    if(resultFailBlock){
                        resultFailBlock(error);
                    }
                    return;
                }
                NSString *newAppSecret = [[reslutDic objectForKey:@"data"] objectForKey:@"accredit"];
                [self checkSDKAuthWithAppKey:appkey appsecret:newAppSecret appType:type success:succeessBlock resultFailBlock:resultFailBlock];
            }
        });
    });
}

- (void)checkSDKAuthWithAppKey:(NSString *)appkey
                     appsecret:(NSString *)appSecret
                       appType:(NSInteger)type
                       success:(void(^)(NSError *error))succeessBlock
               resultFailBlock:(void(^)(NSError *error))resultFailBlock
{
    NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    NSString *newAppSecret = [appSecret substringFromIndex:32];
    NSDictionary *accessDic = [self AES128DecryptWithSecret:newAppSecret andAppKey:appkey];
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    NSString *nowTimeStr = [NSString stringWithFormat:@"%.lf",interval]; //时间戳，从 1970 年 1 月 1 日 0 点 0 分 0 秒开始到现在的秒数
    
    if(type == 1){//编辑
        NSString *eibTimeStr = [accessDic objectForKey:@"eib"]; //基本功能,从 1970 年 1 月 1 日 0 点 0 分 0 秒开始到到期时间的秒数
        NSString *eiaTimeStr = [accessDic objectForKey:@"eia"]; //高级功能
        if((([eibTimeStr compare:nowTimeStr] == NSOrderedAscending) && ([eiaTimeStr compare:nowTimeStr] == NSOrderedAscending)) && accessDic){
            if(resultFailBlock){
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"申请的服务已过期" forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:CustomErrorDomain code:400 userInfo:userInfo];
                resultFailBlock(error);
            }
        }else if (((eibTimeStr && eibTimeStr.length > 0 && [eibTimeStr compare:nowTimeStr] != NSOrderedAscending)
                   || (eiaTimeStr && eiaTimeStr.length > 0 && [eiaTimeStr compare:nowTimeStr] != NSOrderedAscending)))
        {
            NSLog(@"授权成功");
            if (succeessBlock) {
                succeessBlock(nil);
            }
            [[NSUserDefaults standardUserDefaults] setObject:appkey forKey:kEI_AppKey];
            [[NSUserDefaults standardUserDefaults] setObject:appSecret forKey:kEI_AppSecret];
        }else {
            if (resultFailBlock) {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"未开通视频编辑服务" forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:CustomErrorDomain code:401 userInfo:userInfo];
                
                resultFailBlock(error);
            }
        }
    }else if(type == 2){//直播
        NSString *libTimeStr = [accessDic objectForKey:@"lib"]; //基本功能,从 1970 年 1 月 1 日 0 点 0 分 0 秒开始到到期时间的秒数
        NSString *licTimeStr = [accessDic objectForKey:@"lic"]; //云服务功能
        if((([libTimeStr compare:nowTimeStr] == NSOrderedAscending) && ([licTimeStr compare:nowTimeStr] == NSOrderedAscending)) && accessDic){
            if(resultFailBlock){
                NSDictionary *userInfo= [NSDictionary dictionaryWithObject:@"申请的服务已过期" forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:CustomErrorDomain code:400 userInfo:userInfo];
                resultFailBlock(error);
            }
        }else if (((libTimeStr && libTimeStr.length > 0 && [libTimeStr compare:nowTimeStr] != NSOrderedAscending)
                   || (licTimeStr && licTimeStr.length > 0 && [licTimeStr compare:nowTimeStr] != NSOrderedAscending)))
        {
            NSLog(@"授权成功");
            if (succeessBlock) {
                succeessBlock(nil);
            }
            [[NSUserDefaults standardUserDefaults] setObject:appkey forKey:kLI_AppKey];
            [[NSUserDefaults standardUserDefaults] setObject:appSecret forKey:kLI_AppSecret];
        }else {
            if (resultFailBlock) {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"未开通直播服务" forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:CustomErrorDomain code:401 userInfo:userInfo];
                
                resultFailBlock(error);
            }
        }
    }else{//云储存
        NSString *cicTimeStr = [accessDic objectForKey:@"cic"]; //云储存到期时间,从 1970 年 1 月 1 日 0 点 0 分 0 秒开始到到期时间的秒数
        if(([cicTimeStr compare:nowTimeStr] == NSOrderedAscending) && accessDic){
            if(resultFailBlock){
                NSDictionary *userInfo= [NSDictionary dictionaryWithObject:@"申请的服务已过期" forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:CustomErrorDomain code:400 userInfo:userInfo];
                resultFailBlock(error);
            }
        }else if (cicTimeStr && cicTimeStr.length > 0 && [cicTimeStr compare:nowTimeStr] != NSOrderedAscending)
        {
            NSLog(@"授权成功");
            if (succeessBlock) {
                succeessBlock(nil);
            }
            [[NSUserDefaults standardUserDefaults] setObject:appkey forKey:kLI_AppKey];
            [[NSUserDefaults standardUserDefaults] setObject:appSecret forKey:kLI_AppSecret];
        }else {
            if (resultFailBlock) {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"未开通云储存服务" forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:CustomErrorDomain code:401 userInfo:userInfo];
                
                resultFailBlock(error);
            }
        }
    }
}

/**从网络获取授权信息
 *
 */
- (id)checkSignaturewWithAPPKey:(NSString *)appkey appSecret:(NSString *)appsecret params:(NSMutableDictionary *)params andUploadUrl:(NSString *)uploadUrl{
    appsecret = appsecret.length>32 ? [appsecret substringToIndex:32] : appsecret;
    uploadUrl=[NSString stringWithString:[uploadUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *url=[NSURL URLWithString:uploadUrl];
    NSString *postURL= [self createPostURL:params];
    //=====
    NSData *postData = [postURL dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    int random = [self getRandomNumber:1 to:10000];
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    NSString *nbTimeStr = [NSString stringWithFormat:@"%.lf",interval];
    
    NSString *signaturebefor = [self sha1String:[NSString stringWithFormat:@"%@%@%@",appsecret,[NSString stringWithFormat:@"%d", random],nbTimeStr]];
    
    [request setValue:appkey forHTTPHeaderField:@"Appkey"];
    [request setValue:[NSString stringWithFormat:@"%d", random] forHTTPHeaderField:@"Nonce"];
    [request setValue:nbTimeStr forHTTPHeaderField:@"Timestamp"];
    [request setValue:signaturebefor forHTTPHeaderField:@"Signature"];
    
    [request setHTTPBody:postData];
    NSHTTPURLResponse* urlResponse = nil;
    NSError *error;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:NULL];
    
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

- (int)getRandomNumber:(int)from to:(int)to
{
    return (int)(from + (arc4random() % (to - from + 1)));
    
}

- (NSDictionary *)AES128DecryptWithSecret:(NSString *)secret andAppKey:(NSString *)appKey
{
    NSRange range = NSMakeRange(12, 16);
    NSString *ivStr = [[[self md5_16:appKey] substringWithRange:range] lowercaseString];//必须是小写
    if(![ivStr isKindOfClass:[NSString class]]){
        return nil;
    }else{
        if(ivStr.length==0 || !ivStr){
            return nil;
        }
    }
    NSString *result = [secret rdTSAVIDecryptedWithAESUsingKey:appKey andIV:[ivStr dataUsingEncoding:NSUTF8StringEncoding]];
    if([[UIDevice currentDevice].systemVersion floatValue]<8.0){
        NSString *st =  [result substringFromIndex:result.length - 1];
        if(![st isEqualToString:@"}"]){
            result = [result stringByAppendingString:@"}"];
        }
    }else{
        BOOL ra = [result rangeOfString:@"}"].length == NSNotFound ? NO : YES;
        if(!ra){
            result = [result stringByAppendingString:@"}"];
        }
    }
    NSMutableDictionary *contentDic = [self parseDataFromJSONString:result];
    
    return contentDic;
}

//解析JSONData
- (id)parseDataFromJSONString:(NSString *)jasonStr {
    if (jasonStr) {
        jasonStr = [jasonStr stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];//加这一句，解决解析解密后的字符串抛出的"Garbage at End"错误（含有JSON转换无法识别的字符）
        NSData *content = [jasonStr dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        id getData = [NSJSONSerialization JSONObjectWithData:content options:NSJSONReadingMutableLeaves error:&error];
        if (!error) {
            return getData;
        }
    }
    return nil;
}

//MD5 16位加密
- (NSString *)md5_16:(NSString *)str
{
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), result );
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]
            ];
}

- (NSString *)createPostURL:(NSMutableDictionary *)params
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

#pragma mark- sha1 加密
- (NSString *)sha1String:(NSString *)srcString{
    const char *cstr = [srcString cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:srcString.length];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, (int)data.length, digest);
    
    NSMutableString* result = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH *2];
    
    for(int i =0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", digest[i]];
    }
    
    return result;
}

- (NSString *)createPostJsonURL:(NSMutableDictionary *)params
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

- (NSString *)getSystemCureentTime{
    NSDate* date = [NSDate date];
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"yyyy.MM.dd"];
    
    NSString* time = [formatter stringFromDate:date];
    return time;
}

- (void)dealloc{
    NSLog(@"%s",__func__);
}




- (CGContextRef) newBitmapRGBA8ContextFromImage:(CGImageRef) image {
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
    uint32_t *bitmapData;
    size_t bitsPerPixel = 32;
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = bitsPerPixel / bitsPerComponent;
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    size_t bytesPerRow = width * bytesPerPixel;
    size_t bufferLength = bytesPerRow * height;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    if(!colorSpace) {
        NSLog(@"Error allocating color space RGB\n");
        return NULL;
    }
    // Allocate memory for image data
    bitmapData = (uint32_t *)malloc(bufferLength);
    if(!bitmapData) {
        NSLog(@"Error allocating memory for bitmap\n");
        CGColorSpaceRelease(colorSpace);
        return NULL;
    }
    //Create bitmap context
    context = CGBitmapContextCreate(bitmapData,
                                    width,
                                    height,
                                    bitsPerComponent,
                                    bytesPerRow,
                                    colorSpace,
                                    kCGImageAlphaPremultipliedLast);    // RGBA
    if(!context) {
        free(bitmapData);
        NSLog(@"Bitmap context not created");
    }
    CGColorSpaceRelease(colorSpace);
    return context;
}
- (unsigned char *) convertUIImageToBitmapRGBA8:(UIImage *) image {
    
    CGImageRef imageRef = image.CGImage;
    
    // Create a bitmap context to draw the uiimage into
    CGContextRef context = [ self newBitmapRGBA8ContextFromImage:imageRef];
    
    if(!context) {
        return NULL;
    }
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    CGRect rect = CGRectMake(0, 0, width, height);
    
    // Draw image into the context to get the raw image data
    CGContextDrawImage(context, rect, imageRef);
    
    // Get a pointer to the data
    unsigned char *bitmapData = (unsigned char *)CGBitmapContextGetData(context);
    
    // Copy the data and release the memory (return memory allocated with new)
    size_t bytesPerRow = CGBitmapContextGetBytesPerRow(context);
    size_t bufferLength = bytesPerRow * height;
    
    unsigned char *newBitmap = NULL;
    
    if(bitmapData) {
        newBitmap = (unsigned char *)malloc(sizeof(unsigned char) * bytesPerRow * height);
        
        if(newBitmap) {    // Copy the data
            for(int i = 0; i < bufferLength; ++i) {
                newBitmap[i] = bitmapData[i];
            }
        }
        
        free(bitmapData);
        
    } else {
        NSLog(@"Error getting bitmap pixel data\n");
    }
    
    CGContextRelease(context);
    
    return newBitmap;
}

- (UIImage * )convertBitsDataIntoUIImage:(void*)bitsData width:(int)width height:(int)height
{
    
    // set up for CGImage creation
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = 4 * width;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
//    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();//
    void *colorData = bitsData;
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, colorData, width*4*height, NULL);
    CGImageRef cgImage2 = CGImageCreate(width,
                                        height,
                                        bitsPerComponent,
                                        bitsPerPixel,
                                        bytesPerRow,
                                        colorSpace,
                                        kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault,
                                        provider,
                                        NULL,
                                        NO,
                                        kCGRenderingIntentDefault);
    UIImage * image = [UIImage imageWithCGImage:cgImage2];
    
    
    
    
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(cgImage2);
    return image;
}


- (UIImage *)transformImageWithContentOfFile:(NSString *)path //图片路径
                                  sourceRect:(CGRect)sourceRect //crop 坐标
                                      destLT:(CGPoint)destLT   //不规则四边形左上角顶点
                                      destRT:(CGPoint)destRT   //不规则四边形右上角顶点
                                      destLB:(CGPoint)destLB   //不规则四边形左下角顶点
                                      destRB:(CGPoint)destRB   //不规则四边形右下角顶点
                                    destRect:(CGRect*)destRect //返回新位图的左上角坐标 和新位图的宽高
{
    UIImage*  imageSource=[UIImage imageWithContentsOfFile:path];
  
    return  [self transformImageWithSourceImage:imageSource sourceRect:sourceRect destLT:destLT destRT:destRT destLB:destLB destRB:destRB destRect:destRect];
}

- (UIImage *)transformImageWithSourceImage:(UIImage *)imageSource //图片路径
                                  sourceRect:(CGRect)sourceRect //crop 坐标
                                      destLT:(CGPoint)destLT   //不规则四边形左上角顶点
                                      destRT:(CGPoint)destRT   //不规则四边形右上角顶点
                                      destLB:(CGPoint)destLB   //不规则四边形左下角顶点
                                      destRB:(CGPoint)destRB   //不规则四边形右下角顶点
                                    destRect:(CGRect*)destRect //返回新位图的左上角坐标 和新位图的宽高
{
    
    if(_sdkDisabled){
        NSLog(@"SDK已禁用");
        return nil;
    }
    
    if(!imageSource){
        NSLog(@"源文件不存在");
        return nil;
    }
    unsigned char * pbits=  [self convertUIImageToBitmapRGBA8:imageSource];
    
    freetransform.setImage(pbits, imageSource.size.width, imageSource.size.height,0);
    freetransform.setSourRect(sourceRect.origin.x, sourceRect.origin.y, sourceRect.size.width, sourceRect.size.height);
    freetransform.setMapLeftTop(destLT.x, destLT.y);
    freetransform.setMapRightTop(destRT.x, destRT.y);
    freetransform.setMapLeftBottom(destLB.x, destLB.y);
    freetransform.setMapRightBottom(destRB.x, destRB.y);
    int neww,newh,newpitch;
    unsigned char * pbits2= (unsigned char * ) freetransform.transform(&neww, &newh, &newpitch);
    
    UIImage*  imagedest=[self convertBitsDataIntoUIImage:pbits2 width:neww height:newh];
    
    GRect rect=freetransform.bound();
    (*destRect).origin.x=rect.topLeft().x();
    (*destRect).origin.y=rect.topLeft().y();
    (*destRect).size.width=rect.width();
    (*destRect).size.height=rect.height();
    return  imagedest ;
    //
}


- (UIImage *)addImage:(NSString *)imageName1 withImage:(NSString *)imageName2 inRect:(CGRect )inRect{
    
    UIImage *image1 = [UIImage imageNamed:imageName1];
    UIImage *image2 = [UIImage imageNamed:imageName2];
    
    UIGraphicsBeginImageContext(image1.size);
    
    [image1 drawInRect:CGRectMake(0, 0, image1.size.width, image1.size.height)];
    
    [image2 drawInRect:inRect];//CGRectMake((image1.size.width - image2.size.width)/2,(image1.size.height - image2.size.height)/2, image2.size.width, image2.size.height)
    
    UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return resultingImage;
}

- (UIImage *)drawImage:(UIImage *)image1 withImage:(UIImage *)image2 inRect:(CGRect )inRect{
    
    
    UIGraphicsBeginImageContext(image1.size);
    
    [image1 drawInRect:CGRectMake(0, 0, image1.size.width, image1.size.height)];
    
    [image2 drawInRect:inRect];//CGRectMake((image1.size.width - image2.size.width)/2,(image1.size.height - image2.size.height)/2, image2.size.width, image2.size.height)
    
    UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return resultingImage;
}

@end


#if 0

#import "TSAVI2MP4.h"
#include "TsUnpack.hpp"
#include "AviUnpack.hpp"
#include "Timer.h"

@implementation TSAVI2MP4
+ (BOOL)unpackFrom:(NSString *)fromPathString to:(NSString *)toPathString{
    if ([fromPathString containsString:@".ts"] || [fromPathString containsString:@".TS"]) {
        CTsUnpack unpack;
//        Timer t;
//        t.StartTimer(1000, [&](){
//            float progress = unpack.GetProgress();
//            printf(">>>%f\n",progress);
//
//
//        });
        bool succ = unpack.Unpack([fromPathString UTF8String], [toPathString UTF8String]);
        if (succ) {
            NSLog(@"Success");
        }else{
            NSLog(@"Fail");
        }
        return succ;
    }
    
    if ([fromPathString containsString:@".avi"]) {
        CAviUnpack unpack;
        Timer t;
        t.StartTimer(1000, [&](){
            float progress = unpack.GetProgress();
            printf(">>>%f\n",progress);
            
            
        });
        bool succ = unpack.Unpack([fromPathString UTF8String], [toPathString UTF8String]);
        return succ;
    }
    return NO;
}

@end
#endif

