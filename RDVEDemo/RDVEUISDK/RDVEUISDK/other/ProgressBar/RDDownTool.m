//
//  RDDownTool.m
//  RDVEUISDK
//
//  Created by 周晓林 on 2017/3/22.
//  Copyright © 2017年 周晓林. All rights reserved.
//


#import "RDDownTool.h"
@interface RDDownTool()<NSURLSessionDownloadDelegate>
{
    NSString* _savePath;
}
@property (nonatomic,strong) NSURLSession* session;
@property (nonatomic,strong) NSURLSessionDownloadTask* task;

@end
@implementation RDDownTool
- (instancetype)initWithURLPath:(NSString*)path savePath:(NSString*)savePath
{
    if (self = [super init]) {
        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        NSURL* taskURL = [[NSURL URLWithString:path] copy];
        //20170412 用下面这种方式可以设置请求方式 get 还是 post
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:taskURL];
        request.HTTPMethod = @"GET";
        self.task = [self.session downloadTaskWithRequest:request];
        _savePath = nil;
        _savePath = [savePath copy];

        
        return self;
    }
    return nil;
}


- (void) start;
{
    [self.task resume];
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    [fileManager moveItemAtPath:location.path toPath:_savePath error:nil];
    
    if ([self Finish]) {
        _Finish();
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    [_session finishTasksAndInvalidate];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    float value = (float)totalBytesWritten/totalBytesExpectedToWrite;
    NSLog(@"%f",value);
    if ([self Progress]) {
        _Progress(value);
    }
}
@end
