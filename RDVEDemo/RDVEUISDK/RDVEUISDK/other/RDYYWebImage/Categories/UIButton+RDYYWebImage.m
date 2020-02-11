//
//  UIButton+RDYYWebImage.m
//  RDYYWebImage <https://github.com/ibireme/RDYYWebImage>
//
//  Created by ibireme on 15/2/23.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "UIButton+RDYYWebImage.h"
#import "RDYYWebImageOperation.h"
#import "_RDYYWebImageSetter.h"
#import <objc/runtime.h>

// Dummy class for category
@interface UIButton_RDYYWebImage : NSObject @end
@implementation UIButton_RDYYWebImage @end

static inline NSNumber *UIControlStateSingle(UIControlState state) {
    if (state & UIControlStateHighlighted) return @(UIControlStateHighlighted);
    if (state & UIControlStateDisabled) return @(UIControlStateDisabled);
    if (state & UIControlStateSelected) return @(UIControlStateSelected);
    return @(UIControlStateNormal);
}

static inline NSArray *UIControlStateMulti(UIControlState state) {
    NSMutableArray *array = [NSMutableArray new];
    if (state & UIControlStateHighlighted) [array addObject:@(UIControlStateHighlighted)];
    if (state & UIControlStateDisabled) [array addObject:@(UIControlStateDisabled)];
    if (state & UIControlStateSelected) [array addObject:@(UIControlStateSelected)];
    if ((state & 0xFF) == 0) [array addObject:@(UIControlStateNormal)];
    return array;
}

static int _RDYYWebImageSetterKey;
static int _RDYYWebImageBackgroundSetterKey;


@interface _RDYYWebImageSetterDicForButton : NSObject
- (_RDYYWebImageSetter *)setterForState:(NSNumber *)state;
- (_RDYYWebImageSetter *)lazySetterForState:(NSNumber *)state;
@end

@implementation _RDYYWebImageSetterDicForButton {
    NSMutableDictionary *_dic;
    dispatch_semaphore_t _lock;
}
- (instancetype)init {
    self = [super init];
    _lock = dispatch_semaphore_create(1);
    _dic = [NSMutableDictionary new];
    return self;
}
- (_RDYYWebImageSetter *)setterForState:(NSNumber *)state {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    _RDYYWebImageSetter *setter = _dic[state];
    dispatch_semaphore_signal(_lock);
    return setter;
    
}
- (_RDYYWebImageSetter *)lazySetterForState:(NSNumber *)state {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    _RDYYWebImageSetter *setter = _dic[state];
    if (!setter) {
        setter = [_RDYYWebImageSetter new];
        _dic[state] = setter;
    }
    dispatch_semaphore_signal(_lock);
    return setter;
}
@end


@implementation UIButton (RDYYWebImage)

#pragma mark - image

- (void)_yy_setImageWithURL:(NSURL *)imageURL
             forSingleState:(NSNumber *)state
                placeholder:(UIImage *)placeholder
                    options:(RDYYWebImageOptions)options
                    manager:(RDYYWebImageManager *)manager
                   progress:(RDYYWebImageProgressBlock)progress
                  transform:(RDYYWebImageTransformBlock)transform
                 completion:(RDYYWebImageCompletionBlock)completion {
    if ([imageURL isKindOfClass:[NSString class]]) imageURL = [NSURL URLWithString:(id)imageURL];
    manager = manager ? manager : [RDYYWebImageManager sharedManager];
    
    _RDYYWebImageSetterDicForButton *dic = objc_getAssociatedObject(self, &_RDYYWebImageSetterKey);
    if (!dic) {
        dic = [_RDYYWebImageSetterDicForButton new];
        objc_setAssociatedObject(self, &_RDYYWebImageSetterKey, dic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    _RDYYWebImageSetter *setter = [dic lazySetterForState:state];
    int32_t sentinel = [setter cancelWithNewURL:imageURL];
    
    _yy_dispatch_sync_on_main_queue(^{
        if (!imageURL) {
            if (!(options & RDYYWebImageOptionIgnorePlaceHolder)) {
                [self setImage:placeholder forState:state.integerValue];
            }
            return;
        }
        
        // get the image from memory as quickly as possible
        UIImage *imageFromMemory = nil;
        if (manager.cache &&
            !(options & RDYYWebImageOptionUseNSURLCache) &&
            !(options & RDYYWebImageOptionRefreshImageCache)) {
            imageFromMemory = [manager.cache getImageForKey:[manager cacheKeyForURL:imageURL] withType:RDYYImageCacheTypeMemory];
        }
        if (imageFromMemory) {
            if (!(options & RDYYWebImageOptionAvoidSetImage)) {
                [self setImage:imageFromMemory forState:state.integerValue];
            }
            if(completion) completion(imageFromMemory, imageURL, RDYYWebImageFromMemoryCacheFast, RDYYWebImageStageFinished, nil);
            return;
        }
        
        
        if (!(options & RDYYWebImageOptionIgnorePlaceHolder)) {
            [self setImage:placeholder forState:state.integerValue];
        }
        
        __weak typeof(self) _self = self;
        dispatch_async([_RDYYWebImageSetter setterQueue], ^{
            RDYYWebImageProgressBlock _progress = nil;
            if (progress) _progress = ^(NSInteger receivedSize, NSInteger expectedSize) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    progress(receivedSize, expectedSize);
                });
            };
            
            __block int32_t newSentinel = 0;
            __block __weak typeof(setter) weakSetter = nil;
            RDYYWebImageCompletionBlock _completion = ^(UIImage *image, NSURL *url, RDYYWebImageFromType from, RDYYWebImageStage stage, NSError *error) {
                __strong typeof(_self) self = _self;
                BOOL setImage = (stage == RDYYWebImageStageFinished || stage == RDYYWebImageStageProgress) && image && !(options & RDYYWebImageOptionAvoidSetImage);
                dispatch_async(dispatch_get_main_queue(), ^{
                    BOOL sentinelChanged = weakSetter && weakSetter.sentinel != newSentinel;
                    if (setImage && self && !sentinelChanged) {
                        [self setImage:image forState:state.integerValue];
                    }
                    if (completion) {
                        if (sentinelChanged) {
                            completion(nil, url, RDYYWebImageFromNone, RDYYWebImageStageCancelled, nil);
                        } else {
                            completion(image, url, from, stage, error);
                        }
                    }
                });
            };
            
            newSentinel = [setter setOperationWithSentinel:sentinel url:imageURL options:options manager:manager progress:_progress transform:transform completion:_completion];
            weakSetter = setter;
        });
    });
}

- (void)_yy_cancelImageRequestForSingleState:(NSNumber *)state {
    _RDYYWebImageSetterDicForButton *dic = objc_getAssociatedObject(self, &_RDYYWebImageSetterKey);
    _RDYYWebImageSetter *setter = [dic setterForState:state];
    if (setter) [setter cancel];
}

- (NSURL *)yy_imageURLForState:(UIControlState)state {
    _RDYYWebImageSetterDicForButton *dic = objc_getAssociatedObject(self, &_RDYYWebImageSetterKey);
    _RDYYWebImageSetter *setter = [dic setterForState:UIControlStateSingle(state)];
    return setter.imageURL;
}

- (void)yy_setImageWithURL:(NSURL *)imageURL
                  forState:(UIControlState)state
               placeholder:(UIImage *)placeholder {
    [self yy_setImageWithURL:imageURL
                 forState:state
              placeholder:placeholder
                  options:kNilOptions
                  manager:nil
                 progress:nil
                transform:nil
               completion:nil];
}

- (void)yy_setImageWithURL:(NSURL *)imageURL
                  forState:(UIControlState)state
                   options:(RDYYWebImageOptions)options {
    [self yy_setImageWithURL:imageURL
                    forState:state
                 placeholder:nil
                     options:options
                     manager:nil
                    progress:nil
                   transform:nil
                  completion:nil];
}

- (void)yy_setImageWithURL:(NSURL *)imageURL
                  forState:(UIControlState)state
               placeholder:(UIImage *)placeholder
                   options:(RDYYWebImageOptions)options
                completion:(RDYYWebImageCompletionBlock)completion {
    [self yy_setImageWithURL:imageURL
                    forState:state
                 placeholder:placeholder
                     options:options
                     manager:nil
                    progress:nil
                   transform:nil
                  completion:completion];
}

- (void)yy_setImageWithURL:(NSURL *)imageURL
                  forState:(UIControlState)state
               placeholder:(UIImage *)placeholder
                   options:(RDYYWebImageOptions)options
                  progress:(RDYYWebImageProgressBlock)progress
                 transform:(RDYYWebImageTransformBlock)transform
                completion:(RDYYWebImageCompletionBlock)completion {
    [self yy_setImageWithURL:imageURL
                    forState:state
                 placeholder:placeholder
                     options:options
                     manager:nil
                    progress:progress
                   transform:transform
                  completion:completion];
}

- (void)yy_setImageWithURL:(NSURL *)imageURL
                  forState:(UIControlState)state
               placeholder:(UIImage *)placeholder
                   options:(RDYYWebImageOptions)options
                   manager:(RDYYWebImageManager *)manager
                  progress:(RDYYWebImageProgressBlock)progress
                 transform:(RDYYWebImageTransformBlock)transform
                completion:(RDYYWebImageCompletionBlock)completion {
    for (NSNumber *num in UIControlStateMulti(state)) {
        [self _yy_setImageWithURL:imageURL
                   forSingleState:num
                      placeholder:placeholder
                          options:options
                          manager:manager
                         progress:progress
                        transform:transform
                       completion:completion];
    }
}

- (void)yy_cancelImageRequestForState:(UIControlState)state {
    for (NSNumber *num in UIControlStateMulti(state)) {
        [self _yy_cancelImageRequestForSingleState:num];
    }
}


#pragma mark - background image

- (void)_yy_setBackgroundImageWithURL:(NSURL *)imageURL
                       forSingleState:(NSNumber *)state
                          placeholder:(UIImage *)placeholder
                              options:(RDYYWebImageOptions)options
                              manager:(RDYYWebImageManager *)manager
                             progress:(RDYYWebImageProgressBlock)progress
                            transform:(RDYYWebImageTransformBlock)transform
                           completion:(RDYYWebImageCompletionBlock)completion {
    if ([imageURL isKindOfClass:[NSString class]]) imageURL = [NSURL URLWithString:(id)imageURL];
    manager = manager ? manager : [RDYYWebImageManager sharedManager];
    
    _RDYYWebImageSetterDicForButton *dic = objc_getAssociatedObject(self, &_RDYYWebImageBackgroundSetterKey);
    if (!dic) {
        dic = [_RDYYWebImageSetterDicForButton new];
        objc_setAssociatedObject(self, &_RDYYWebImageBackgroundSetterKey, dic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    _RDYYWebImageSetter *setter = [dic lazySetterForState:state];
    int32_t sentinel = [setter cancelWithNewURL:imageURL];
    
    _yy_dispatch_sync_on_main_queue(^{
        if (!imageURL) {
            if (!(options & RDYYWebImageOptionIgnorePlaceHolder)) {
                [self setBackgroundImage:placeholder forState:state.integerValue];
            }
            return;
        }
        
        // get the image from memory as quickly as possible
        UIImage *imageFromMemory = nil;
        if (manager.cache &&
            !(options & RDYYWebImageOptionUseNSURLCache) &&
            !(options & RDYYWebImageOptionRefreshImageCache)) {
            imageFromMemory = [manager.cache getImageForKey:[manager cacheKeyForURL:imageURL] withType:RDYYImageCacheTypeMemory];
        }
        if (imageFromMemory) {
            if (!(options & RDYYWebImageOptionAvoidSetImage)) {
                [self setBackgroundImage:imageFromMemory forState:state.integerValue];
            }
            if(completion) completion(imageFromMemory, imageURL, RDYYWebImageFromMemoryCacheFast, RDYYWebImageStageFinished, nil);
            return;
        }
        
        
        if (!(options & RDYYWebImageOptionIgnorePlaceHolder)) {
            [self setBackgroundImage:placeholder forState:state.integerValue];
        }
        
        __weak typeof(self) _self = self;
        dispatch_async([_RDYYWebImageSetter setterQueue], ^{
            RDYYWebImageProgressBlock _progress = nil;
            if (progress) _progress = ^(NSInteger receivedSize, NSInteger expectedSize) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    progress(receivedSize, expectedSize);
                });
            };
            
            __block int32_t newSentinel = 0;
            __block __weak typeof(setter) weakSetter = nil;
            RDYYWebImageCompletionBlock _completion = ^(UIImage *image, NSURL *url, RDYYWebImageFromType from, RDYYWebImageStage stage, NSError *error) {
                __strong typeof(_self) self = _self;
                BOOL setImage = (stage == RDYYWebImageStageFinished || stage == RDYYWebImageStageProgress) && image && !(options & RDYYWebImageOptionAvoidSetImage);
                dispatch_async(dispatch_get_main_queue(), ^{
                    BOOL sentinelChanged = weakSetter && weakSetter.sentinel != newSentinel;
                    if (setImage && self && !sentinelChanged) {
                        [self setBackgroundImage:image forState:state.integerValue];
                    }
                    if (completion) {
                        if (sentinelChanged) {
                            completion(nil, url, RDYYWebImageFromNone, RDYYWebImageStageCancelled, nil);
                        } else {
                            completion(image, url, from, stage, error);
                        }
                    }
                });
            };
            
            newSentinel = [setter setOperationWithSentinel:sentinel url:imageURL options:options manager:manager progress:_progress transform:transform completion:_completion];
            weakSetter = setter;
        });
    });
}

- (void)_yy_cancelBackgroundImageRequestForSingleState:(NSNumber *)state {
    _RDYYWebImageSetterDicForButton *dic = objc_getAssociatedObject(self, &_RDYYWebImageBackgroundSetterKey);
    _RDYYWebImageSetter *setter = [dic setterForState:state];
    if (setter) [setter cancel];
}

- (NSURL *)yy_backgroundImageURLForState:(UIControlState)state {
    _RDYYWebImageSetterDicForButton *dic = objc_getAssociatedObject(self, &_RDYYWebImageBackgroundSetterKey);
    _RDYYWebImageSetter *setter = [dic setterForState:UIControlStateSingle(state)];
    return setter.imageURL;
}

- (void)yy_setBackgroundImageWithURL:(NSURL *)imageURL
                            forState:(UIControlState)state
                         placeholder:(UIImage *)placeholder {
    [self yy_setBackgroundImageWithURL:imageURL
                              forState:state
                           placeholder:placeholder
                               options:kNilOptions
                               manager:nil
                              progress:nil
                             transform:nil
                            completion:nil];
}

- (void)yy_setBackgroundImageWithURL:(NSURL *)imageURL
                            forState:(UIControlState)state
                             options:(RDYYWebImageOptions)options {
    [self yy_setBackgroundImageWithURL:imageURL
                              forState:state
                           placeholder:nil
                               options:options
                               manager:nil
                              progress:nil
                             transform:nil
                            completion:nil];
}

- (void)yy_setBackgroundImageWithURL:(NSURL *)imageURL
                            forState:(UIControlState)state
                         placeholder:(UIImage *)placeholder
                             options:(RDYYWebImageOptions)options
                          completion:(RDYYWebImageCompletionBlock)completion {
    [self yy_setBackgroundImageWithURL:imageURL
                              forState:state
                           placeholder:placeholder
                               options:options
                               manager:nil
                              progress:nil
                             transform:nil
                            completion:completion];
}

- (void)yy_setBackgroundImageWithURL:(NSURL *)imageURL
                            forState:(UIControlState)state
                         placeholder:(UIImage *)placeholder
                             options:(RDYYWebImageOptions)options
                            progress:(RDYYWebImageProgressBlock)progress
                           transform:(RDYYWebImageTransformBlock)transform
                          completion:(RDYYWebImageCompletionBlock)completion {
    [self yy_setBackgroundImageWithURL:imageURL
                              forState:state
                           placeholder:placeholder
                               options:options
                               manager:nil
                              progress:progress
                             transform:transform
                            completion:completion];
}

- (void)yy_setBackgroundImageWithURL:(NSURL *)imageURL
                            forState:(UIControlState)state
                         placeholder:(UIImage *)placeholder
                             options:(RDYYWebImageOptions)options
                             manager:(RDYYWebImageManager *)manager
                            progress:(RDYYWebImageProgressBlock)progress
                           transform:(RDYYWebImageTransformBlock)transform
                          completion:(RDYYWebImageCompletionBlock)completion {
    for (NSNumber *num in UIControlStateMulti(state)) {
        [self _yy_setBackgroundImageWithURL:imageURL
                             forSingleState:num
                                placeholder:placeholder
                                    options:options
                                    manager:manager
                                   progress:progress
                                  transform:transform
                                 completion:completion];
    }
}

- (void)yy_cancelBackgroundImageRequestForState:(UIControlState)state {
    for (NSNumber *num in UIControlStateMulti(state)) {
        [self _yy_cancelBackgroundImageRequestForSingleState:num];
    }
}

@end
