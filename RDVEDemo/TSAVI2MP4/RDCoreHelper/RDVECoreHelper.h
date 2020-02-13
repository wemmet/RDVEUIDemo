//
//  TSAVI2MP4.h
//  TSAVI2MP4
//
//  Created by 周晓林 on 2017/9/21.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RDVECoreHelper : NSObject
/**  初始化对象
 *
 *  @param appkey          在锐动SDK官网(http://www.rdsdk.com/ )中注册的应用Key。
 *  @param appsecret       在锐动SDK官网(http://www.rdsdk.com/ )中注册的应用秘钥。
 *  @param resultFailBlock 初始化失败的回调［error：初始化失败的错误码］
 */
- (instancetype) initWithAPPKey:(NSString *)appkey
                      APPSecret:(NSString *)appsecret
                     resultFail:(void (^)(NSError *error))resultFailBlock;

/**  初始化对象
 *
 *  @param sourcePath         源文件路径
 *  @param outputFilePath     输出文件路径
 *  @param keepAudio          是否需要音频
 *  @param progressBlock      输出进度
 *  @param completedBlock     转换完成的回调［error：初始化失败的错误码］
 */
- (void)TSAVItoMP4:(NSString *)sourcePath outputFilePath:(NSString *)outputFilePath keepAudio:(bool)keepAudio progressBlock:(void(^)(float progress)) progressBlock completedBlock:(void(^)(NSError *error))completedBlock;

@end
