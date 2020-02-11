/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImageView+RDHighlightedWebCache.h"
#import "UIView+RDWebCacheOperation.h"

#define UIImageViewHighlightedWebCacheOperationKey @"highlightedImage"

@implementation UIImageView (RDHighlightedWebCache)

- (void)rd_sd_setHighlightedImageWithURL:(NSURL *)url {
    [self rd_sd_setHighlightedImageWithURL:url options:0 progress:nil completed:nil];
}

- (void)rd_sd_setHighlightedImageWithURL:(NSURL *)url options:(RDSDWebImageOptions)options {
    [self rd_sd_setHighlightedImageWithURL:url options:options progress:nil completed:nil];
}

- (void)rd_sd_setHighlightedImageWithURL:(NSURL *)url completed:(RDSDWebImageCompletionBlock)completedBlock {
    [self rd_sd_setHighlightedImageWithURL:url options:0 progress:nil completed:completedBlock];
}

- (void)rd_sd_setHighlightedImageWithURL:(NSURL *)url options:(RDSDWebImageOptions)options completed:(RDSDWebImageCompletionBlock)completedBlock {
    [self rd_sd_setHighlightedImageWithURL:url options:options progress:nil completed:completedBlock];
}

- (void)rd_sd_setHighlightedImageWithURL:(NSURL *)url options:(RDSDWebImageOptions)options progress:(RDSDWebImageDownloaderProgressBlock)progressBlock completed:(RDSDWebImageCompletionBlock)completedBlock {
    [self rd_sd_cancelCurrentHighlightedImageLoad];

    if (url) {
        __weak UIImageView      *wself    = self;
        id<RDSDWebImageOperation> operation = [RDSDWebImageManager.sharedManager downloadImageWithURL:url options:options progress:progressBlock completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if (!wself) return;
            dispatch_main_sync_safe (^
                                     {
                                         if (!wself) return;
                                         if (image) {
                                             wself.highlightedImage = image;
                                             [wself setNeedsLayout];
                                         }
                                         if (completedBlock && finished) {
                                             completedBlock(image, error, cacheType, url);
                                         }
                                     });
        }];
        [self rd_sd_setImageLoadOperation:operation forKey:UIImageViewHighlightedWebCacheOperationKey];
    } else {
        dispatch_main_async_safe(^{
            NSError *error = [NSError errorWithDomain:@"SDWebImageErrorDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Trying to load a nil url"}];
            if (completedBlock) {
                completedBlock(nil, error, RDSDImageCacheTypeNone, url);
            }
        });
    }
}

- (void)rd_sd_cancelCurrentHighlightedImageLoad {
    [self rd_sd_cancelImageLoadOperationWithKey:UIImageViewHighlightedWebCacheOperationKey];
}

@end


@implementation UIImageView (HighlightedWebCacheDeprecated)

- (void)rd_setHighlightedImageWithURL:(NSURL *)url {
    [self rd_sd_setHighlightedImageWithURL:url options:0 progress:nil completed:nil];
}

- (void)setHighlightedImageWithURL:(NSURL *)url options:(RDSDWebImageOptions)options {
    [self rd_sd_setHighlightedImageWithURL:url options:options progress:nil completed:nil];
}

- (void)rd_setHighlightedImageWithURL:(NSURL *)url completed:(RDSDWebImageCompletedBlock)completedBlock {
    [self rd_sd_setHighlightedImageWithURL:url options:0 progress:nil completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, NSURL *imageURL) {
        if (completedBlock) {
            completedBlock(image, error, cacheType);
        }
    }];
}

- (void)rd_setHighlightedImageWithURL:(NSURL *)url options:(RDSDWebImageOptions)options completed:(RDSDWebImageCompletedBlock)completedBlock {
    [self rd_sd_setHighlightedImageWithURL:url options:options progress:nil completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, NSURL *imageURL) {
        if (completedBlock) {
            completedBlock(image, error, cacheType);
        }
    }];
}

- (void)rd_setHighlightedImageWithURL:(NSURL *)url options:(RDSDWebImageOptions)options progress:(RDSDWebImageDownloaderProgressBlock)progressBlock completed:(RDSDWebImageCompletedBlock)completedBlock {
    [self rd_sd_setHighlightedImageWithURL:url options:0 progress:progressBlock completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, NSURL *imageURL) {
        if (completedBlock) {
            completedBlock(image, error, cacheType);
        }
    }];
}

- (void)rd_cancelCurrentHighlightedImageLoad {
    [self rd_sd_cancelCurrentHighlightedImageLoad];
}

@end
