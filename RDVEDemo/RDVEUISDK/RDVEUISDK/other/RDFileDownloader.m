//
//  RDFileDownloader.m
//  RDVEUISDK
//
//  Created by emmet on 2017/3/27.
//  Copyright © 2017年 RDVEUISDK. All rights reserved.
//

#import "RDFileDownloader.h"
typedef void(^ProgressBlock)(NSNumber *numProgress);
typedef void(^FinishBlock)( NSString *fileCachePath);
typedef void(^FailBlock)( NSError *error);
typedef void(^CancelBlock)();



@interface RDFileDownloader()<NSURLSessionDelegate>{
    NSURLSession* _session;
    NSURLSessionDownloadTask *_task;
    ProgressBlock _progressBlock;
    FinishBlock   _finishBlock;
    FailBlock     _failBlock;
    CancelBlock   _cancel;
    NSString      *_cachePath;
    float          _progress;
}
@end

@implementation RDFileDownloader
- (instancetype)init{
    self = [super init];
    return self;
}

+ (void)downloadFileWithURL:(NSString *)sourceUrlstr cachePath:(NSString *)cachePath httpMethod:(HTTPMethod )httpMethod progress:(void(^)(NSNumber *numProgress))progress finish:(void (^)(NSString *fileCachePath))finish fail:(void(^)(NSError *error))fail{
    [[[RDFileDownloader alloc] init] downloadFileWithURL:sourceUrlstr cachePath:cachePath httpMethod:httpMethod cancelbtn:nil progress:progress finish:finish fail:fail cancel:nil];

}


+ (void)downloadFileWithURL:(NSString *)sourceUrlstr cachePath:(NSString *)cachePath httpMethod:(HTTPMethod )httpMethod cancelBtn:(UIButton *)cancelBtn progress:(void(^)(NSNumber *numProgress))progress finish:(void (^)(NSString *fileCachePath))finish fail:(void(^)(NSError *error))fail cancel:(void(^)())cancel{
    [[[RDFileDownloader alloc] init] downloadFileWithURL:sourceUrlstr cachePath:cachePath httpMethod:httpMethod cancelbtn:(UIButton *)cancelBtn progress:progress finish:finish fail:fail cancel:cancel];
}

- (void)downloadFileWithURL:(NSString *)urlstr cachePath:(NSString *)cachePath httpMethod:(HTTPMethod )httpMethod cancelbtn:(UIButton *)cancelBtn progress:(void(^)(NSNumber *numProgress))progress finish:(void (^)(NSString *fileCachePath))finish fail:(void(^)(NSError *error))fail cancel:(void(^)())cancel{
    
    _cachePath = cachePath;
    _finishBlock = finish;
    _failBlock = fail;
    _cancel = cancel;
    _progressBlock = progress;
    if(_cancel && cancelBtn){
        dispatch_async(dispatch_get_main_queue(), ^{
            [cancelBtn removeTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
            [cancelBtn addTarget:self action:@selector(cancelTouchDown:) forControlEvents:UIControlEventTouchDown];
        });
    }
    
    NSURL *url = [NSURL URLWithString:urlstr];
    
    // 创建会话
    _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration
                                                                    defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    if(httpMethod == POST){
        request.HTTPMethod = @"POST";

    }else{
        request.HTTPMethod = @"GET";//@"POST";//20170427 wuxiaoxia 客户(大鸟)的音乐必须用get,锐动的get和post都可
    }
    _task = [_session downloadTaskWithRequest:request];
    [_task resume];
    
}


- (void)cancelTouchDown:(UIButton*)sender{
    [self cancel];
}

- (void)cancel{
    if(_task){
        [_task cancel];
        [_session invalidateAndCancel];
        if(_cancel){
            _cancel();
        }
    }
}

- (void)downloadFileWithURL:(NSString *)sourceUrlstr httpMethod:(HTTPMethod )httpMethod progress:(void(^)(NSNumber *numProgress))progress finish:(void (^)(NSString *fileCachePath))finish fail:(void(^)(NSError *error))fail cancel:(void(^)())cancel{
    [self downloadFileWithURL:sourceUrlstr cachePath:nil httpMethod:httpMethod cancelbtn:nil progress:progress finish:finish fail:fail cancel:cancel];

}


- (void)downloadFileWithURL:(NSString *)sourceUrlstr cachePath:(NSString *)cachePath httpMethod:(HTTPMethod )httpMethod progress:(void(^)(NSNumber *numProgress))progress finish:(void (^)(NSString *fileCachePath))finish fail:(void(^)(NSError *error))fail cancel:(void(^)())cancel{
    
    [self downloadFileWithURL:sourceUrlstr cachePath:cachePath httpMethod:httpMethod cancelbtn:nil progress:progress finish:finish fail:fail cancel:cancel];
}

- (float)progress{
    return _progress;
}

#pragma mark - NSURLSessionDataDelegate Function
// 下载了数据的过程中会调用的代理方法
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten
totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    _progress = 1.0 * totalBytesWritten / totalBytesExpectedToWrite;
    
    if(_progressBlock)
    _progressBlock([NSNumber numberWithFloat:_progress]);
}
// 重新恢复下载的代理方法
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes{
}
// 写入数据到本地的时候会调用的方法
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location{
    NSError *error;
    NSString *filePath = nil;
    if(_cacheFilePath.length>0){
        filePath = _cacheFilePath;
    }else{
        if([[_cachePath substringFromIndex:_cachePath.length-1] isEqualToString:@"/"]){
            filePath = [_cachePath stringByAppendingString:[NSString stringWithFormat:@"%@",downloadTask.response.suggestedFilename]];
        }else{
            filePath = [_cachePath stringByAppendingString:[NSString stringWithFormat:@"/%@",downloadTask.response.suggestedFilename]];
        }
    }
    
    NSLog(@"filePath : %@",filePath);
    unlink([filePath UTF8String]);
   
    BOOL suc = [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:filePath] error:&error];
    long long size = sizeof(filePath);
    
    NSLog(@"filePath : %@  size:%lld",filePath,size);
    if(_finishBlock&& suc){
        _finishBlock(filePath);
    }else{
        [[NSFileManager defaultManager] removeItemAtURL:location error:&error];
        if(_failBlock){
            _failBlock(error);
        }
    }
    [_session finishTasksAndInvalidate];
}
// 请求完成，错误调用的代理方法
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if(error){
        if(![[error.userInfo objectForKey:@"NSLocalizedDescription"] isEqualToString:RDLocalizedString(@"已取消", nil)] && _failBlock){
            _failBlock(error);
        }
    }
}

- (void)dealloc{
    NSLog(@"%s",__func__);
    _session = nil;
    _task = nil;
    _progressBlock = nil;
    _finishBlock = nil;
    _failBlock = nil;
    _cachePath = nil;
}
@end
