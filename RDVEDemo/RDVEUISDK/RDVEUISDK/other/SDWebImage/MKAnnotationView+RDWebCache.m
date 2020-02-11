//
//  MKAnnotationView+WebCache.m
//  SDWebImage
//
//  Created by Olivier Poitrey on 14/03/12.
//  Copyright (c) 2012 Dailymotion. All rights reserved.
//

#import "MKAnnotationView+RDWebCache.h"
#import "objc/runtime.h"
#import "UIView+RDWebCacheOperation.h"

static char imageURLKey;

@implementation MKAnnotationView (RDWebCache)

- (NSURL *)rd_sd_imageURL {
    return objc_getAssociatedObject(self, &imageURLKey);
}

- (void)rd_sd_setImageWithURL:(NSURL *)url {
    [self rd_sd_setImageWithURL:url placeholderImage:nil options:0 completed:nil];
}

- (void)rd_sd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder {
    [self rd_sd_setImageWithURL:url placeholderImage:placeholder options:0 completed:nil];
}

- (void)rd_sd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options {
    [self rd_sd_setImageWithURL:url placeholderImage:placeholder options:options completed:nil];
}

- (void)rd_sd_setImageWithURL:(NSURL *)url completed:(RDSDWebImageCompletionBlock)completedBlock {
    [self rd_sd_setImageWithURL:url placeholderImage:nil options:0 completed:completedBlock];
}

- (void)rd_sd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(RDSDWebImageCompletionBlock)completedBlock {
    [self rd_sd_setImageWithURL:url placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)rd_sd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options completed:(RDSDWebImageCompletionBlock)completedBlock {
    [self rd_sd_cancelCurrentImageLoad];

    objc_setAssociatedObject(self, &imageURLKey, url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.image = placeholder;

    if (url) {
        __weak MKAnnotationView *wself = self;
        id <RDSDWebImageOperation> operation = [RDSDWebImageManager.sharedManager downloadImageWithURL:url options:options progress:nil completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if (!wself) return;
            dispatch_main_sync_safe(^{
                __strong MKAnnotationView *sself = wself;
                if (!sself) return;
                if (image) {
                    sself.image = image;
                }
                if (completedBlock && finished) {
                    completedBlock(image, error, cacheType, url);
                }
            });
        }];
        [self rd_sd_setImageLoadOperation:operation forKey:@"MKAnnotationViewImage"];
    } else {
        dispatch_main_async_safe(^{
            NSError *error = [NSError errorWithDomain:@"SDWebImageErrorDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Trying to load a nil url"}];
            if (completedBlock) {
                completedBlock(nil, error, RDSDImageCacheTypeNone, url);
            }
        });
    }
}

- (void)rd_sd_cancelCurrentImageLoad {
    [self rd_sd_cancelImageLoadOperationWithKey:@"MKAnnotationViewImage"];
}

@end


@implementation MKAnnotationView (WebCacheDeprecated)

- (NSURL *)rd_imageURL {
    return [self rd_sd_imageURL];
}

- (void)rd_setImageWithURL:(NSURL *)url {
    [self rd_sd_setImageWithURL:url placeholderImage:nil options:0 completed:nil];
}

- (void)rd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder {
    [self rd_sd_setImageWithURL:url placeholderImage:placeholder options:0 completed:nil];
}

- (void)rd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options {
    [self rd_sd_setImageWithURL:url placeholderImage:placeholder options:options completed:nil];
}

- (void)rd_setImageWithURL:(NSURL *)url completed:(RDSDWebImageCompletedBlock)completedBlock {
    [self rd_sd_setImageWithURL:url placeholderImage:nil options:0 completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, NSURL *imageURL) {
        if (completedBlock) {
            completedBlock(image, error, cacheType);
        }
    }];
}

- (void)rd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(RDSDWebImageCompletedBlock)completedBlock {
    [self rd_sd_setImageWithURL:url placeholderImage:placeholder options:0 completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, NSURL *imageURL) {
        if (completedBlock) {
            completedBlock(image, error, cacheType);
        }
    }];
}

- (void)rd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options completed:(RDSDWebImageCompletedBlock)completedBlock {
    [self rd_sd_setImageWithURL:url placeholderImage:placeholder options:options completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, NSURL *imageURL) {
        if (completedBlock) {
            completedBlock(image, error, cacheType);
        }
    }];
}

- (void)rd_cancelCurrentImageLoad {
    [self rd_sd_cancelCurrentImageLoad];
}

@end
