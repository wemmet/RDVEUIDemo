//
//  MKAnnotationView+RDYYWebImage.m
//  RDYYWebImage <https://github.com/ibireme/RDYYWebImage>
//
//  Created by ibireme on 15/2/23.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "MKAnnotationView+RDYYWebImage.h"
#import "RDYYWebImageOperation.h"
#import "_RDYYWebImageSetter.h"
#import <objc/runtime.h>

// Dummy class for category
@interface MKAnnotationView_RDYYWebImage : NSObject @end
@implementation MKAnnotationView_RDYYWebImage @end


static int _RDYYWebImageSetterKey;

@implementation MKAnnotationView (RDYYWebImage)

- (NSURL *)yy_imageURL {
    _RDYYWebImageSetter *setter = objc_getAssociatedObject(self, &_RDYYWebImageSetterKey);
    return setter.imageURL;
}

- (void)setYy_imageURL:(NSURL *)imageURL {
    [self yy_setImageWithURL:imageURL
              placeholder:nil
                  options:kNilOptions
                  manager:nil
                 progress:nil
                transform:nil
               completion:nil];
}

- (void)yy_setImageWithURL:(NSURL *)imageURL placeholder:(UIImage *)placeholder {
    [self yy_setImageWithURL:imageURL
                 placeholder:placeholder
                     options:kNilOptions
                     manager:nil
                    progress:nil
                   transform:nil
                  completion:nil];
}

- (void)yy_setImageWithURL:(NSURL *)imageURL options:(RDYYWebImageOptions)options {
    [self yy_setImageWithURL:imageURL
                 placeholder:nil
                     options:options
                     manager:nil
                    progress:nil
                   transform:nil
                  completion:nil];
}

- (void)yy_setImageWithURL:(NSURL *)imageURL
               placeholder:(UIImage *)placeholder
                   options:(RDYYWebImageOptions)options
                completion:(RDYYWebImageCompletionBlock)completion {
    [self yy_setImageWithURL:imageURL
                 placeholder:placeholder
                     options:options
                     manager:nil
                    progress:nil
                   transform:nil
                  completion:completion];
}

- (void)yy_setImageWithURL:(NSURL *)imageURL
               placeholder:(UIImage *)placeholder
                   options:(RDYYWebImageOptions)options
                  progress:(RDYYWebImageProgressBlock)progress
                 transform:(RDYYWebImageTransformBlock)transform
                completion:(RDYYWebImageCompletionBlock)completion {
    [self yy_setImageWithURL:imageURL
                 placeholder:placeholder
                     options:options
                     manager:nil
                    progress:progress
                   transform:transform
                  completion:completion];
}

- (void)yy_setImageWithURL:(NSURL *)imageURL
               placeholder:(UIImage *)placeholder
                   options:(RDYYWebImageOptions)options
                   manager:(RDYYWebImageManager *)manager
                  progress:(RDYYWebImageProgressBlock)progress
                 transform:(RDYYWebImageTransformBlock)transform
                completion:(RDYYWebImageCompletionBlock)completion {
    if ([imageURL isKindOfClass:[NSString class]]) imageURL = [NSURL URLWithString:(id)imageURL];
    manager = manager ? manager : [RDYYWebImageManager sharedManager];
    
    _RDYYWebImageSetter *setter = objc_getAssociatedObject(self, &_RDYYWebImageSetterKey);
    if (!setter) {
        setter = [_RDYYWebImageSetter new];
        objc_setAssociatedObject(self, &_RDYYWebImageSetterKey, setter, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    int32_t sentinel = [setter cancelWithNewURL:imageURL];
    
    _yy_dispatch_sync_on_main_queue(^{
        if ((options & RDYYWebImageOptionSetImageWithFadeAnimation) &&
            !(options & RDYYWebImageOptionAvoidSetImage)) {
            if (!self.highlighted) {
                [self.layer removeAnimationForKey:_RDYYWebImageFadeAnimationKey];
            }
        }
        if (!imageURL) {
            if (!(options & RDYYWebImageOptionIgnorePlaceHolder)) {
                self.image = placeholder;
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
                self.image = imageFromMemory;
            }
            if(completion) completion(imageFromMemory, imageURL, RDYYWebImageFromMemoryCacheFast, RDYYWebImageStageFinished, nil);
            return;
        }
        
        if (!(options & RDYYWebImageOptionIgnorePlaceHolder)) {
            self.image = placeholder;
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
                BOOL showFade = ((options & RDYYWebImageOptionSetImageWithFadeAnimation) && !self.highlighted);
                dispatch_async(dispatch_get_main_queue(), ^{
                    BOOL sentinelChanged = weakSetter && weakSetter.sentinel != newSentinel;
                    if (setImage && self && !sentinelChanged) {
                        if (showFade) {
                            CATransition *transition = [CATransition animation];
                            transition.duration = stage == RDYYWebImageStageFinished ? _RDYYWebImageFadeTime : _RDYYWebImageProgressiveFadeTime;
                            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                            transition.type = kCATransitionFade;
                            [self.layer addAnimation:transition forKey:_RDYYWebImageFadeAnimationKey];
                        }
                        self.image = image;
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

- (void)yy_cancelCurrentImageRequest {
    _RDYYWebImageSetter *setter = objc_getAssociatedObject(self, &_RDYYWebImageSetterKey);
    if (setter) [setter cancel];
}

@end
