//
//  TSAVI2MP4.h
//  TSAVI2MP4
//
//  Created by 周晓林 on 2017/9/21.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
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

- (UIImage *)transformImageWithContentOfFile:(NSString *)path //图片路径
                                  sourceRect:(CGRect)sourceRect //crop 坐标
                                      destLT:(CGPoint)destLT   //不规则四边形左上角顶点
                                      destRT:(CGPoint)destRT   //不规则四边形右上角顶点
                                      destLB:(CGPoint)destLB   //不规则四边形左下角顶点
                                      destRB:(CGPoint)destRB   //不规则四边形右下角顶点
                                    destRect:(CGRect*)destRect; //返回新位图的左上角坐标 和新位图的宽高

- (UIImage *)transformImageWithSourceImage:(UIImage *)imageSource //源图片
                                sourceRect:(CGRect)sourceRect //crop 坐标
                                    destLT:(CGPoint)destLT   //不规则四边形左上角顶点
                                    destRT:(CGPoint)destRT   //不规则四边形右上角顶点
                                    destLB:(CGPoint)destLB   //不规则四边形左下角顶点
                                    destRB:(CGPoint)destRB   //不规则四边形右下角顶点
                                  destRect:(CGRect*)destRect; //返回新位图的左上角坐标 和新位图的宽高

- (UIImage *)addImage:(NSString *)imageName1 withImage:(NSString *)imageName2 inRect:(CGRect )inRect;
- (UIImage *)drawImage:(UIImage *)image1 withImage:(UIImage *)image2 inRect:(CGRect )inRect;
@end
