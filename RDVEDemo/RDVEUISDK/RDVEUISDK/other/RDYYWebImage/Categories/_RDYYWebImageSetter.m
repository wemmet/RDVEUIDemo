//
//  _RDYYWebImageSetter.m
//  RDYYWebImage <https://github.com/ibireme/RDYYWebImage>
//
//  Created by ibireme on 15/7/15.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "_RDYYWebImageSetter.h"
#import "RDYYWebImageOperation.h"
#import <libkern/OSAtomic.h>

NSString *const _RDYYWebImageFadeAnimationKey = @"RDYYWebImageFade";
const NSTimeInterval _RDYYWebImageFadeTime = 0.2;
const NSTimeInterval _RDYYWebImageProgressiveFadeTime = 0.4;


@implementation _RDYYWebImageSetter {
    dispatch_semaphore_t _lock;
    NSURL *_imageURL;
    NSOperation *_operation;
    int32_t _sentinel;
}

- (instancetype)init {
    self = [super init];
    _lock = dispatch_semaphore_create(1);
    return self;
}

- (NSURL *)imageURL {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    NSURL *imageURL = _imageURL;
    dispatch_semaphore_signal(_lock);
    return imageURL;
}

- (void)dealloc {
    OSAtomicIncrement32(&_sentinel);
    [_operation cancel];
}

- (int32_t)setOperationWithSentinel:(int32_t)sentinel
                                url:(NSURL *)imageURL
                            options:(RDYYWebImageOptions)options
                            manager:(RDYYWebImageManager *)manager
                           progress:(RDYYWebImageProgressBlock)progress
                          transform:(RDYYWebImageTransformBlock)transform
                         completion:(RDYYWebImageCompletionBlock)completion {
    if (sentinel != _sentinel) {
        if (completion) completion(nil, imageURL, RDYYWebImageFromNone, RDYYWebImageStageCancelled, nil);
        return _sentinel;
    }
    
    NSOperation *operation = [manager requestImageWithURL:imageURL options:options progress:progress transform:transform completion:completion];
    if (!operation && completion) {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : @"RDYYWebImageOperation create failed." };
        completion(nil, imageURL, RDYYWebImageFromNone, RDYYWebImageStageFinished, [NSError errorWithDomain:@"com.ibireme.webimage" code:-1 userInfo:userInfo]);
    }
    
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    if (sentinel == _sentinel) {
        if (_operation) [_operation cancel];
        _operation = operation;
        sentinel = OSAtomicIncrement32(&_sentinel);
    } else {
        [operation cancel];
    }
    dispatch_semaphore_signal(_lock);
    return sentinel;
}

- (int32_t)cancel {
    return [self cancelWithNewURL:nil];
}

- (int32_t)cancelWithNewURL:(NSURL *)imageURL {
    int32_t sentinel;
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    if (_operation) {
        [_operation cancel];
        _operation = nil;
    }
    _imageURL = imageURL;
    sentinel = OSAtomicIncrement32(&_sentinel);
    dispatch_semaphore_signal(_lock);
    return sentinel;
}

+ (dispatch_queue_t)setterQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.ibireme.webimage.setter", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    });
    return queue;
}

@end
