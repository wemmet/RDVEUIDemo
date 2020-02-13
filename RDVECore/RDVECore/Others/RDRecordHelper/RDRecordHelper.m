//
//  RDRecordHelper.m
//  RDVECore
//
//  Created by 周晓林 on 16/4/18.
//  Copyright © 2016年 周晓林. All rights reserved.
//

#import "RDRecordHelper.h"
#import <sys/utsname.h>
#import "NSString+RD_Encrypt.h"
#import <CommonCrypto/CommonDigest.h>
#import "TSerialKey.h"

@implementation RDRecordHelper

#define kAPPSIGNATUREURL @"https://ssl.17rd.com/api/appverify/signature"//检测授权
#define CustomErrorDomain @"com.17rd.rdsdk"
#define kEI_AppKey      @"RDVECORE_EIRDAPPKEY"       //编辑appkey
#define kEI_AppSecret   @"RDVECORE_EIRDAPPSECTET"    //编辑appsecret
#define kLI_AppKey      @"RDVECORE_LIRDAPPKEY"       //直播appkey
#define kLI_AppSecret   @"RDVECORE_LIRDAPPSECTET"    //直播appsecret
#define kCI_AppKey      @"RDVECORE_CIRDAPPKEY"       //云存储appkey
#define kCI_AppSecret   @"RDVECORE_CIRDAPPSECTET"    //云存储appsecret
#define VIDEO_FOLDER    @"videos"

/**检查授权
 *type 1:编辑 2:直播 3:云储存
 */
+ (void)checkPermissions:(NSString *)appkey
               appsecret:(NSString *)appSecret
              LicenceKey:(NSString *)licenceKey
                 appType:(NSInteger)type
                 success:(void(^)())succeessBlock
         resultFailBlock:(void(^)(NSError *error))resultFailBlock
{
    NSString *oldAppKey;
    NSString *newAppSecret = appSecret;
    if(type == 1){
        oldAppKey = [[NSUserDefaults standardUserDefaults] objectForKey:kEI_AppKey];
        if ([appkey isEqualToString:oldAppKey] && appSecret.length > 0) {
            newAppSecret = [[NSUserDefaults standardUserDefaults] objectForKey:kEI_AppSecret];
        }
    }else if(type == 2){
        oldAppKey = [[NSUserDefaults standardUserDefaults] objectForKey:kLI_AppKey];
        if ([appkey isEqualToString:oldAppKey] && appSecret.length > 0) {
            newAppSecret = [[NSUserDefaults standardUserDefaults] objectForKey:kLI_AppSecret];
        }
    }else{
        oldAppKey = [[NSUserDefaults standardUserDefaults] objectForKey:kCI_AppKey];
        if ([appkey isEqualToString:oldAppKey] && appSecret.length > 0) {
            newAppSecret = [[NSUserDefaults standardUserDefaults] objectForKey:kCI_AppSecret];
        }
    }
    if((!newAppSecret || newAppSecret.length == 0) && appSecret.length > 0){
        newAppSecret = [appSecret substringFromIndex:32];
    }
    
    if(appkey.length == 0 || (licenceKey.length == 0 && newAppSecret.length == 0)){
        NSDictionary *userInfo= [NSDictionary dictionaryWithObject:@"appkey 和 appsecret 不能为空" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:CustomErrorDomain code:200 userInfo:userInfo];
        NSLog(@"error:%@",error);
        resultFailBlock(error);
        return;
    }
    
    [self updatePermissionsAppKey:appkey
                        appsercet:newAppSecret
                       LicenceKey:licenceKey
                             type:type
                          success:succeessBlock
                       resultFail:resultFailBlock];
}

+ (void)updatePermissionsAppKey:(NSString *)appkey
                      appsercet:(NSString *)appsercet
                     LicenceKey:(NSString *)licenceKey
                           type:(NSInteger)type
                        success:(void(^)())succeessBlock
                     resultFail:(void(^)(NSError *error))resultFailBlock
{
    //20190826 (1)有licenceKey，先检查licenceKey (2)licenceKey没过的情况，a、有appsercet，则检查appkey和appsercet b、无appsercet，则不检查
    NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    if (licenceKey.length > 0) {
        int days = 0;
        unsigned char feature = 0x01;
        int validateKey = RDValidateKey([licenceKey UTF8String], [@"rdve_version_ios" UTF8String], feature, &days, [bundleName UTF8String]);
        if(validateKey == 0){
            if (succeessBlock) {
                succeessBlock();
            }
            return;
        }else if (!appsercet || appsercet.length == 0) {
            if (resultFailBlock) {
                NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:@"申请的服务已过期",@"message", nil];
                NSError *error = [NSError errorWithDomain:CustomErrorDomain code:400 userInfo:userInfo];
                if(resultFailBlock){
                    resultFailBlock(error);
                }
            }
            return;
        }
    }
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[NSNumber numberWithInteger:1] forKey:@"os"];
    if(bundleName){
        [params setObject:bundleName forKey:@"packname"];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *reslutDic = [self checkSignaturewWithAPPKey:appkey appSecret:appsercet params:params andUploadUrl:kAPPSIGNATUREURL];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!reslutDic){//20171025 wuxiaoxia 没有网络时，什么也不检查，直接通过
                if (succeessBlock) {
                    succeessBlock();
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
                [self checkSDKAuthWithAppKey:appkey appsecret:newAppSecret appType:type isFromServer:YES success:succeessBlock resultFailBlock:resultFailBlock];
            }
        });
    });
    
}

+ (void)checkSDKAuthWithAppKey:(NSString *)appkey
                     appsecret:(NSString *)appSecret
                       appType:(NSInteger)type
                  isFromServer:(BOOL)isFromServer
                       success:(void(^)())succeessBlock
               resultFailBlock:(void(^)(NSError *error))resultFailBlock
{
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
                succeessBlock();
            }
            [[NSUserDefaults standardUserDefaults] setObject:appkey forKey:kEI_AppKey];
            [[NSUserDefaults standardUserDefaults] setObject:appSecret forKey:kEI_AppSecret];
            [[NSUserDefaults standardUserDefaults] synchronize];
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
                succeessBlock();
            }
            [[NSUserDefaults standardUserDefaults] setObject:appkey forKey:kLI_AppKey];
            [[NSUserDefaults standardUserDefaults] setObject:appSecret forKey:kLI_AppSecret];
            [[NSUserDefaults standardUserDefaults] synchronize];
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
        }else if ((cicTimeStr && cicTimeStr.length > 0 && [cicTimeStr compare:nowTimeStr] != NSOrderedAscending))
        {
            NSLog(@"授权成功");
            if (succeessBlock) {
                succeessBlock();
            }
            [[NSUserDefaults standardUserDefaults] setObject:appkey forKey:kLI_AppKey];
            [[NSUserDefaults standardUserDefaults] setObject:appSecret forKey:kLI_AppSecret];
            [[NSUserDefaults standardUserDefaults] synchronize];
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
+ (id)checkSignaturewWithAPPKey:(NSString *)appkey appSecret:(NSString *)appsecret params:(NSMutableDictionary *)params andUploadUrl:(NSString *)uploadUrl
{
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
    
    if(appkey.length>0)
    [request setValue:appkey forHTTPHeaderField:@"Appkey"];
    [request setValue:[NSString stringWithFormat:@"%d", random] forHTTPHeaderField:@"Nonce"];
    [request setValue:nbTimeStr forHTTPHeaderField:@"Timestamp"];
    [request setValue:signaturebefor forHTTPHeaderField:@"Signature"];
    
    [request setHTTPBody:postData];
    NSHTTPURLResponse* urlResponse = nil;
    NSError *error;
    //NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:NULL];
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
    
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

+ (int)getRandomNumber:(int)from to:(int)to
{
    return (int)(from + (arc4random() % (to - from + 1)));
    
}

+ (NSDictionary *)AES128DecryptWithSecret:(NSString *)secret andAppKey:(NSString *)appKey
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
    NSString *result = [secret rd_DecryptedWithAESUsingKey:appKey andIV:[ivStr dataUsingEncoding:NSUTF8StringEncoding]];
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
+ (id)parseDataFromJSONString:(NSString *)jasonStr {
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

+(id)parseDataFromJSONData:(NSData *)data{
    
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

//MD5 16位加密
+ (NSString *)md5_16:(NSString *)str
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

#pragma mark- sha1 加密
+ (NSString *)sha1String:(NSString *)srcString{
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
#pragma mark 适配 对应机器
//iPhone5 后置摄像头AVCaptureSessionPreset1920x1080 前置AVCaptureSessionPreset1280x720
//iPhone4 后置摄像头AVCaptureSessionPreset1280x720 前置AVCaptureSessionPreset640x480
//iPhone7 iPhone6+
+ (BOOL) isAsyncAudio
{
    NSString* machine = [self system];
    if ([machine hasPrefix:@"iPhone5,2"]) {
        return YES;
    }
    return NO;
}
+ (int) matchLength{
    NSString* machine = [self system];
    
    if ([machine hasPrefix:@"iPod7"]) {
        return 1000;
    }else if ([machine hasPrefix:@"iPhone5,2"]){
        return 1000;
    }else if ([machine hasPrefix:@"iPhone4"]){
        return 1000;
    }else if ([machine hasPrefix:@"iPhone6"]){
        return 1000;
    }else if ([machine hasPrefix:@"iPhone7"]){
        return 1000;
    }else if ([machine hasPrefix:@"iPad2,1"]){
        return 1000;
    }else if ([machine hasPrefix:@"iPad2"]){
        return 1000;
    }
    else if ([machine hasPrefix:@"iPhone3"]){
        return 1000;
    }
    return 1000;

}


+ (CGSize ) matchSize
{
    NSString* machine = [self system];
    if ([machine hasPrefix:@"iPod7"]) {
        return CGSizeMake(720, 1280);
    }else if ([machine hasPrefix:@"iPhone5,2"]){
        return CGSizeMake(720, 1280);
    }else if ([machine hasPrefix:@"iPhone4"]){
        return CGSizeMake(480, 640);
    }else if ([machine hasPrefix:@"iPhone6"]){
        return CGSizeMake(720, 1280);
    }else if ([machine hasPrefix:@"iPhone7"]){
        return CGSizeMake(720, 1280);
    }else if ([machine hasPrefix:@"iPad2,1"]){
        return CGSizeMake(480, 640);
    }else if ([machine hasPrefix:@"iPad2"]){
        return CGSizeMake(480, 640);
    }
    else if ([machine hasPrefix:@"iPhone3"]){
        return CGSizeMake(480, 640);
    }
    return CGSizeMake(720, 1280);
}

+ (BOOL) canFaceU{
    NSString* machine = [self system];
    if ([machine hasPrefix:@"iPod7"]) {
        return YES;
    }else if ([machine hasPrefix:@"iPhone5,2"]){
        return NO;
    }else if ([machine hasPrefix:@"iPhone4"]){
        return NO;
    }else if ([machine hasPrefix:@"iPhone6"]){
        return YES;
    }else if ([machine hasPrefix:@"iPhone7"]){
        return YES;
    }else if ([machine hasPrefix:@"iPad2"]){
        return NO;
    }
    else if ([machine hasPrefix:@"iPhone3"]){
        return NO;
    }
    return YES;

}

+ (NSString *)sessionPreset
{
    //return AVCaptureSessionPreset640x480;
    
    NSString* machine = [self system];
    if ([machine hasPrefix:@"iPod7"]) {
        return AVCaptureSessionPreset1280x720;
    }else if ([machine hasPrefix:@"iPhone5,2"]){
        return AVCaptureSessionPreset1280x720;
    }else if ([machine hasPrefix:@"iPhone4"]){
        return AVCaptureSessionPreset640x480;
    }else if ([machine hasPrefix:@"iPhone6"]){
        return AVCaptureSessionPreset1280x720;
    }else if ([machine hasPrefix:@"iPhone7"]){
        return AVCaptureSessionPreset1280x720;
    }else if ([machine hasPrefix:@"iPad2,1"]){
        return AVCaptureSessionPreset640x480;
    }else if ([machine hasPrefix:@"iPad2"]){
        return AVCaptureSessionPreset640x480;
    }
    else if ([machine hasPrefix:@"iPhone3"]){
        return AVCaptureSessionPreset640x480;
    }
    return AVCaptureSessionPreset1280x720;
}

+ (RDGPUImageBeautifyFilter *)beautyFilter
{
//    NSString* machine = [self system];
//    if ([machine hasPrefix:@"iPod7"]) {
//        return [[RDGPUImageBeautifyFilter alloc] init];
//    }else if ([machine hasPrefix:@"iPhone5"]){
//        return [[RDRecordBeautyMediumFilter alloc] init];
//    }else if ([machine hasPrefix:@"iPhone4"]){
//        return [[RDRecordBeautyMediumFilter alloc] init];
//    }else if ([machine hasPrefix:@"iPhone6"]){
//        return [[RDGPUImageBeautifyFilter alloc] init];
//
//    }else if ([machine hasPrefix:@"iPhone7"]){
//        return [[RDGPUImageBeautifyFilter alloc] init];
//    }else if ([machine hasPrefix:@"iPad2"]){
//        return [[RDRecordBeautyMediumFilter alloc] init];
//    }else if ([machine hasPrefix:@"iPhone3"]){
//        return [[RDRecordBeautyLowFilter alloc] init];
//
//    }else if ([machine hasPrefix:@"iPhone9"]){
//        return [[RDGPUImageBeautifyFilter alloc] init];
//
//    }
    return [[RDGPUImageBeautifyFilter alloc] init];
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

+ (NSString *)getVideoMergeFilePathString{
    return [[RDRecordHelper alloc] getVideoMergeFilePathString];
}

- (NSString *)getVideoMergeFilePathString
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    path = [path stringByAppendingPathComponent:VIDEO_FOLDER];
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if(error){
            NSLog(@"error:%@",error);
            return nil;
        }
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmssSSS";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    NSString *fileName = [[path stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@"merge.mp4"];
    
    return fileName;
}

+(NSString *)getVideoReversFilePathString{
    return [[RDRecordHelper alloc] getVideoReversFilePathString];

}

- (NSString *)getVideoReversFilePathString
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    path = [path stringByAppendingPathComponent:VIDEO_FOLDER];
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if(error){
            NSLog(@"error:%@",error);
            return nil;
        }
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmssSSS";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    NSString *fileName = [[path stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@"revers.mp4"];
    
    return fileName;
}
+ (NSString *)getVideoSaveFilePathString{
    return [[RDRecordHelper alloc] getVideoSaveFilePathString];
}
- (NSString *)getVideoSaveFilePathString
{
    @autoreleasepool {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path = [paths objectAtIndex:0];
        
        path = [path stringByAppendingPathComponent:VIDEO_FOLDER];
        if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
            NSError *error;
            [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
            if(error){
                NSLog(@"error:%@",error);
                paths = nil;
                path = nil;
                return nil;
            }
        }
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyyMMddHHmmssSSS";
        
        NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
        
        NSString *nowTimeStr = [formatter stringFromDate:date];
        
        NSString *fileName = [[path stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@".mp4"];
        date = nil;
        paths = nil;
        path = nil;
        formatter = nil;
        nowTimeStr = nil;
        
        return fileName;
    }
}

+ (NSString *)getRecordFilePath {
    @autoreleasepool {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path = [paths objectAtIndex:0];
        
        path = [path stringByAppendingPathComponent:VIDEO_FOLDER];
        if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
            NSError *error;
            [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
            if(error){
                NSLog(@"error:%@",error);
                paths = nil;
                path = nil;
                return nil;
            }
        }
        
        NSString *fileName = [[path stringByAppendingPathComponent:@"rdRecord"] stringByAppendingString:@".mp4"];
        paths = nil;
        path = nil;
        
        return fileName;
    }
}

+ (NSString*)getFaceUFilePathString:(NSString *) name type:(NSString*)type
{
    NSString *cacheDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    
    NSString *path = [cacheDirectory stringByAppendingPathComponent:@"faceu"];
    NSString* fileName = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",name,type]];
    path = nil;
    return fileName;

}
+ (NSString *)getVideoSaveFolderPathString
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    path = [path stringByAppendingPathComponent:VIDEO_FOLDER];
    paths = nil;
    return path;
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
        NSString* imgPath = [RDRecordHelper getFaceUFilePathString:name type:@"png"];
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
    NSString *postURL= [RDRecordHelper createPostJsonURL:params];
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

+ (NSString *) getResourceFromBundle : (NSString *) name Type : (NSString *) type
{
    NSString* bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"VideoRecord.bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    return [bundle pathForResource:[NSString stringWithFormat:@"%@",name] ofType:type];
}

+ (NSString *)getSystemCureentTime{
    NSDate* date = [NSDate date];
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"yyyy.MM.dd"];
    
    NSString* time = [formatter stringFromDate:date];
    return time;
}

/**判断是否为系统相册URL
 */
+ (BOOL)isSystemPhotoUrl:(NSURL *)url{
    if ([[[url scheme] lowercaseString] isEqualToString:@"assets-library"]) {
        return YES;
    }else{
        return NO;
    }
}

+ (BOOL)isLowDevice {
    NSString* machine = [RDRecordHelper system];
    BOOL lowDevice = NO;
    if ([machine hasPrefix:@"iPhone"]) {
        if ([machine hasPrefix:@"iPhone3"]
            || [machine hasPrefix:@"iPhone4"]
            || [machine hasPrefix:@"iPhone5"]
            || [machine hasPrefix:@"iPhone6"]
            || [machine hasPrefix:@"iPhone7"]
            || [machine hasPrefix:@"iPhone8"])
        {
            lowDevice = YES;
        }
    }else {
        lowDevice = YES;
    }    
    
    return lowDevice;
}

+ (BOOL)isNeedResizeBufferSize {
    NSString* machine = [RDRecordHelper system];
    BOOL isNeedResizeBufferSize = NO;
    if ([machine hasPrefix:@"iPhone"]) {
        if ([machine hasPrefix:@"iPhone3"]
            || [machine hasPrefix:@"iPhone4"]
            || [machine hasPrefix:@"iPhone5"]
            || [machine hasPrefix:@"iPhone6"]
            || [machine hasPrefix:@"iPhone7"])
        {
            isNeedResizeBufferSize = YES;
        }
    }else {
        isNeedResizeBufferSize = YES;
    }
    
    return isNeedResizeBufferSize;
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

+(UIImage *)imageFromSampleBuffer:(CVPixelBufferRef)sampleBuffer crop:(CGRect)crop imageSize:(CGSize)imageSize rotation:(UIImageOrientation)orientation
{
    UIImage *shotImage = nil;
    CGImageRef tempImageRef = nil;
    CVImageBufferRef imageBuffer = sampleBuffer;
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    void * baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    //CVPixelBufferRef to UIImage
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(baseAddress,width,height,8,bytesPerRow,colorSpace,kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    //rotate
    if(UIImageOrientationUp == orientation)
        tempImageRef = quartzImage;
    else
        tempImageRef = [self image:quartzImage rotation:orientation];
    //crop
    CGFloat imageWidth = CGImageGetWidth(tempImageRef);
    CGFloat imageHeight = CGImageGetHeight(tempImageRef);
    float imagePro = imageWidth/imageHeight;
    float animationPro = imageSize.width/imageSize.height;
    
    if (imagePro != animationPro) {
        CGRect rect;
        if (CGRectEqualToRect(crop, CGRectMake(0, 0, 1.0, 1.0))) {
            CGFloat width;
            CGFloat height;
            if (imageWidth*imageSize.height <= imageHeight*imageSize.width) {
                width  = imageWidth;
                height = imageWidth * imageSize.height / imageSize.width;
            }else {
                width  = imageHeight * imageSize.width / imageSize.height;
                height = imageHeight;
            }
            rect = CGRectMake((imageWidth - width)/2.0, (imageHeight - height)/2.0, width, height);
        }else {
            rect = CGRectMake(imageWidth * crop.origin.x, imageHeight * crop.origin.y, imageWidth * crop.size.width, imageHeight * crop.size.height);
        }
        CGImageRef newImageRef = CGImageCreateWithImageInRect(tempImageRef, rect);
        shotImage = [UIImage imageWithCGImage:newImageRef];
        CGImageRelease(newImageRef);
    }else {
        if (CGRectEqualToRect(crop, CGRectMake(0, 0, 1.0, 1.0))) {
            shotImage = [UIImage imageWithCGImage:tempImageRef];
        }else {
            CGRect rect = CGRectMake(imageWidth * crop.origin.x, imageHeight * crop.origin.y, imageWidth * crop.size.width, imageHeight * crop.size.height);
            CGImageRef newImageRef = CGImageCreateWithImageInRect(tempImageRef, rect);
            shotImage = [UIImage imageWithCGImage:newImageRef];
            CGImageRelease(newImageRef);
        }
    }
    CGImageRelease(quartzImage);
    return  shotImage;
}

+(CGImageRef)image:(CGImageRef )image rotation:(UIImageOrientation)orientation
{
    long double rotate = 0.0;
    CGRect rect;
    float translateX = 0;
    float translateY = 0;
    float scaleX = 1.0;
    float scaleY = 1.0;
    CGFloat imageWidth = CGImageGetWidth(image);
    CGFloat imageHeight = CGImageGetHeight(image);
    
    switch (orientation) {
        case UIImageOrientationLeft:
            rotate = M_PI_2;
            rect = CGRectMake(0, 0, imageHeight, imageWidth);
            translateX = 0;
            translateY = -rect.size.width;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationRight:
            rotate = 3 * M_PI_2;
            rect = CGRectMake(0, 0, imageHeight, imageWidth);
            translateX = -rect.size.height;
            translateY = 0;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationDown:
            rotate = M_PI;
            rect = CGRectMake(0, 0, imageWidth, imageHeight);
            translateX = -rect.size.width;
            translateY = -rect.size.height;
            break;
        default:
            rotate = 0.0;
            rect = CGRectMake(0, 0, imageWidth, imageHeight);
            translateX = 0;
            translateY = 0;
            break;
    }
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //做CTM变换
    CGContextTranslateCTM(context, 0.0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextRotateCTM(context, rotate);
    CGContextTranslateCTM(context, translateX, translateY);
    
    CGContextScaleCTM(context, scaleX, scaleY);
    //绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, rect.size.width, rect.size.height), image);
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();//20190424 开启上下文后，必须关闭，否则会崩溃
    
    return newPic.CGImage;
    
}
#define bufferClamp(a) (a>255?255:(a<0?0:a))

+ (UIImage *)imageFromYUVSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    uint8_t *yBuffer = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    size_t yPitch = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
    uint8_t *cbCrBuffer = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
    size_t cbCrPitch = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 1);
    
    int bytesPerPixel = 4;
    uint8_t *rgbBuffer = (uint8_t *)malloc(width * height * bytesPerPixel);
    
    for(int y = 0; y < height; y++) {
        uint8_t *rgbBufferLine = &rgbBuffer[y * width * bytesPerPixel];
        uint8_t *yBufferLine = &yBuffer[y * yPitch];
        uint8_t *cbCrBufferLine = &cbCrBuffer[(y >> 1) * cbCrPitch];
        
        for(int x = 0; x < width; x++) {
            int16_t y = yBufferLine[x];
            int16_t cb = cbCrBufferLine[x & ~1] - 128;
            int16_t cr = cbCrBufferLine[x | 1] - 128;
            
            uint8_t *rgbOutput = &rgbBufferLine[x*bytesPerPixel];
            
            int16_t r = (int16_t)roundf( y + cr *  1.4 );
            int16_t g = (int16_t)roundf( y + cb * -0.343 + cr * -0.711 );
            int16_t b = (int16_t)roundf( y + cb *  1.765);
            
            rgbOutput[0] = 0xff;
            rgbOutput[1] = bufferClamp(b);
            rgbOutput[2] = bufferClamp(g);
            rgbOutput[3] = bufferClamp(r);
        }
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbBuffer, width, height, 8, width * bytesPerPixel, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(quartzImage);
    free(rgbBuffer);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    return image;
}

+ (UIImage *)convertMirrorImage:(UIImage *)image {
    //Quartz重绘图片
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 2);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextClipToRect(currentContext, rect);
    CGContextRotateCTM(currentContext, (CGFloat) M_PI);
    CGContextTranslateCTM(currentContext, -rect.size.width, -rect.size.height);
    CGContextDrawImage(currentContext, rect, image.CGImage);
    
    //翻转图片
    UIImage *drawImage = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *flipImage = [[UIImage alloc] initWithCGImage:drawImage.CGImage];
    
    return flipImage;
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

+ (UIImage *)addImage:(UIImage *)image1 withImage:(UIImage *)image2 {
    @autoreleasepool {
        UIGraphicsBeginImageContext(image1.size);
        [image1 drawInRect:CGRectMake(0, 0, image1.size.width, image1.size.height)];
        [image2 drawInRect:CGRectMake((image1.size.width - image2.size.width)/2,(image1.size.height - image2.size.height)/2, image2.size.width, image2.size.height)];
        UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return resultingImage;
    }
}

+ (UIImage *)imageWithGifData:(NSData *)data
                durationArray:(NSMutableArray *)durationArray
                   targetSize:(CGSize)targetSize
                      maxSize:(float)maxSize
                         crop:(CGRect)crop
{
    if (!data) {
        return nil;
    }
    UIImage *image;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    size_t count = CGImageSourceGetCount(source);
    if (count <= 1) {
        image = [[UIImage alloc] initWithData:data];
    }else {
        NSMutableArray *images = [NSMutableArray array];
        NSTimeInterval duration = 0.0f;
        for (size_t i = 0; i < count; i++) {
            CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, i, NULL);
            
            duration += [RDRecordHelper frameDurationAtIndex:i source:source];
            UIImage *image = [UIImage imageWithCGImage:imageRef scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
            CGImageRelease(imageRef);
            
            CGSize imageSize = image.size;
            CGSize size = imageSize;
            if (MAX(size.width, size.height) > maxSize) {
                if (imageSize.width >= imageSize.height) {
                    float width = MIN(maxSize, imageSize.width);
                    size = CGSizeMake(width, width / (imageSize.width / imageSize.height));
                }else {
                    float height = MIN(maxSize, imageSize.height);
                    size = CGSizeMake(height * (imageSize.width / imageSize.height), height);
                }
                image = [self resizeImage:image toSize:size];
            }
            if (CGRectEqualToRect(crop, CGRectMake(0, 0, 1, 1))) {
                float imageSizePro = targetSize.width/targetSize.height;
                if (imageSizePro != size.width / size.height) {
                    float x,y,w,h;
                    if (imageSizePro == 1.0) {
                        w = MIN(size.width, size.height);
                        h = w;
                    }else if (imageSizePro > 1.0) {
                        w = size.width;
                        h = w/imageSizePro;
                        if (h > size.height) {
                            h = size.height;
                            w = h*imageSizePro;
                        }
                    }else {
                        h = size.height;
                        w = h*imageSizePro;
                        if (w > size.width) {
                            w = size.width;
                            h = w / imageSizePro;
                        }
                    }
                    x = fabs(size.width - w)/2.0;
                    y = fabs(size.height - h)/2.0;
                    CGRect rect = CGRectMake(x, y, w, h);
                    
                    CGImageRef sourceImageRef = [image CGImage];
                    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
                    image = [UIImage imageWithCGImage:newImageRef];
                    CGImageRelease(newImageRef);
                }
            }else {
                CGRect rect = CGRectMake(image.size.width * crop.origin.x, image.size.height * crop.origin.y, image.size.width * crop.size.width, image.size.height * crop.size.height);
                CGImageRef sourceImageRef = [image CGImage];
                CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
                image = [UIImage imageWithCGImage:newImageRef];
            }
            [images addObject:image];
            
            [durationArray addObject:[NSNumber numberWithFloat:duration]];
        }
        //        NSLog(@"%@", imagesDurationArray);
        image = [UIImage animatedImageWithImages:images duration:duration];
    }
    if (source) {
        CFRelease(source);
    }
    return image;
}

+ (float)frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source {
    float frameDuration = 0.1f;
    CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    if (!cfFrameProperties) {
        return frameDuration;
    }
    NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
    NSDictionary *gifProperties = frameProperties[(NSString *)kCGImagePropertyGIFDictionary];
    
    NSNumber *delayTimeUnclampedProp = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTimeUnclampedProp != nil) {
        frameDuration = [delayTimeUnclampedProp floatValue];
    } else {
        NSNumber *delayTimeProp = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTimeProp != nil) {
            frameDuration = [delayTimeProp floatValue];
        }
    }
    
    // Many annoying ads specify a 0 duration to make an image flash as quickly as possible.
    // We follow Firefox's behavior and use a duration of 100 ms for any frames that specify
    // a duration of <= 10 ms. See <rdar://problem/7689300> and <http://webkit.org/b/36082>
    // for more information.
    
    if (frameDuration < 0.011f) {
        frameDuration = 0.100f;
    }
    
    CFRelease(cfFrameProperties);
    return frameDuration;
}

+ (NSString *) getUUID {
    CFUUIDRef uuid_ref = CFUUIDCreate(NULL);
    CFStringRef uuid_string_ref= CFUUIDCreateString(NULL, uuid_ref);
    CFRelease(uuid_ref);
    NSString *uuid = [NSString stringWithString:(__bridge NSString*)uuid_string_ref];
    CFRelease(uuid_string_ref);
    return uuid;
}

+ (NSString *)getUrlPath:(NSURL *)url {
    NSString *path = [NSString stringWithFormat:@"%lu", (unsigned long)[[url description] hash]];
    return path;
}

+ (CMTimeRange)getActualTimeRange:(NSURL *)path {
    double time = CACurrentMediaTime();
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:path options:nil];
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] == 0) {
        return kCMTimeRangeZero;
    }
    AVAssetImageGenerator *assetGen = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    assetGen.requestedTimeToleranceAfter = kCMTimeZero;
    assetGen.requestedTimeToleranceBefore = kCMTimeZero;
    
    float frameRate = 0.0;
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] > 0) {
        AVAssetTrack* clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        frameRate = clipVideoTrack.nominalFrameRate;
    }
    if (frameRate == 0.0) {
        frameRate = 30;
    }
    CMTime time_start = kCMTimeZero;
    CMTime actualTime_start;
    NSError *error = nil;
    CGImageRef image = [assetGen copyCGImageAtTime:time_start actualTime:&actualTime_start error:&error];
    while (!image) {
        error = nil;
        time_start = CMTimeAdd(time_start, CMTimeMake(1, frameRate));
        image = [assetGen copyCGImageAtTime:time_start actualTime:&actualTime_start error:&error];
        if (image || CMTimeCompare(time_start, asset.duration) >= 0) {
            break;
        }
    }
    CGImageRelease(image);
    CMTime time_end = asset.duration;
    CMTime actualTime_end;
    image = [assetGen copyCGImageAtTime:time_end actualTime:&actualTime_end error:&error];
    while (!image) {
        error = nil;
        time_end = CMTimeSubtract(time_end, CMTimeMake(1, frameRate));
        image = [assetGen copyCGImageAtTime:time_end actualTime:&actualTime_end error:&error];
        if (image || CMTimeCompare(time_end, kCMTimeZero) <= 0) {
            break;
        }
    }
    CGImageRelease(image);
    assetGen = nil;
    
    CMTimeRange timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(CMTimeGetSeconds(actualTime_start), TIMESCALE), CMTimeMakeWithSeconds(CMTimeGetSeconds(CMTimeSubtract(actualTime_end, actualTime_start)), TIMESCALE));;
    if (CMTimeCompare(actualTime_start, kCMTimeZero) == 1) {
        timeRange = CMTimeRangeMake(CMTimeAdd(timeRange.start, CMTimeMake(1, TIMESCALE)), timeRange.duration);
    }
    if (CMTimeCompare(actualTime_end, asset.duration) == -1) {
        if (CMTimeCompare(actualTime_end, kCMTimeZero) == 0) {
            timeRange = CMTimeRangeMake(timeRange.start, CMTimeSubtract(asset.duration, CMTimeMake(1, TIMESCALE)));
        }else {
            timeRange = CMTimeRangeMake(timeRange.start, CMTimeSubtract(timeRange.duration, CMTimeMake(1, TIMESCALE)));
        }
    }
    NSLog(@"actualTimeRange:%@%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, timeRange.start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, timeRange.duration)));
    NSLog(@"actualTimeRange 耗时:%f", CACurrentMediaTime() - time);
    return timeRange;
}

@end
