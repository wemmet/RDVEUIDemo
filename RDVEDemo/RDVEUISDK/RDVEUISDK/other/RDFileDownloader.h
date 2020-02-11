//
//  RDFileDownloader.h
//  RDVEUISDK
//
//  Created by emmet on 2017/3/27.
//  Copyright © 2017年 RDVEUISDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
/**请求方式
 */
typedef NS_ENUM(NSInteger, HTTPMethod){
    GET,//get 方式请求
    POST//post 方式请求
    
};
@interface RDFileDownloader : NSObject

#pragma mark- 方式一
/**下载网络数据
 @params  sourceUrlstr 数据源地址
 @params  cachePath 文件缓存地址或文件夹
 @params  httpMethod 请求方式
 @params  progress 下载进度
 @params  finish 下载完成
 @params  fail 下载失败
 */

+ (void)downloadFileWithURL:(NSString *)sourceUrlstr cachePath:(NSString *)cachePath httpMethod:(HTTPMethod )httpMethod progress:(void(^)(NSNumber *numProgress))progress finish:(void (^)(NSString *fileCachePath))finish fail:(void(^)(NSError *error))fail;

+ (void)downloadFileWithURL:(NSString *)sourceUrlstr cachePath:(NSString *)cachePath httpMethod:(HTTPMethod )httpMethod cancelBtn:(UIButton *)cancelBtn progress:(void(^)(NSNumber *numProgress))progress finish:(void (^)(NSString *fileCachePath))finish fail:(void(^)(NSError *error))fail cancel:(void(^)(void))cancel;


#pragma mark- 方式二
@property (nonatomic ,copy)NSString *cacheFilePath;

- (instancetype)init;

- (void)downloadFileWithURL:(NSString *)sourceUrlstr httpMethod:(HTTPMethod )httpMethod progress:(void(^)(NSNumber *numProgress))progress finish:(void (^)(NSString *fileCachePath))finish fail:(void(^)(NSError *error))fail cancel:(void(^)(void))cancel;

- (void)downloadFileWithURL:(NSString *)sourceUrlstr cachePath:(NSString *)cachePath httpMethod:(HTTPMethod )httpMethod progress:(void(^)(NSNumber *numProgress))progress finish:(void (^)(NSString *fileCachePath))finish fail:(void(^)(NSError *error))fail cancel:(void(^)(void))cancel;

- (float)progress;

- (void)cancel;
@end
