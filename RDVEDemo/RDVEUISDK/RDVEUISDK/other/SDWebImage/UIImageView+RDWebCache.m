/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImageView+RDWebCache.h"
#import "objc/runtime.h"
#import "UIView+RDWebCacheOperation.h"

static char imageURLKey;

@implementation UIImageView (RDWebCache)
#if 1
- (void)rd_sd_setImageWithURL:(NSURL *)url {
    if([url isKindOfClass:[NSURL class]]){
        [self rd_sd_setImageWithURL:url placeholderImage:nil];
    }else if([url isKindOfClass:[NSString class]]){
        [self rd_sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@",url]] placeholderImage:nil];
    }
    
}
- (void)rd_sd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder {
    RDSDWebImageManager *manager = [RDSDWebImageManager sharedManager];
    NSString* key = [manager cacheKeyForURL:url];
    RDSDImageCache* cache = [RDSDImageCache sharedImageCache];
    //此方法会先从memory中取。
    self.image = [cache rd_imageFromDiskCacheForKey:key];
    if(!self.image)
        [self rd_sd_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, NSURL *imageURL) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.image = image;
                [self setNeedsDisplay];
            });
        }];
}

#else
- (void)rd_sd_setImageWithURL:(NSURL *)url {
    [self rd_sd_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)rd_sd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder {
    [self rd_sd_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}
#endif


- (void)rd_sd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options {
    [self rd_sd_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)rd_sd_setImageWithURL:(NSURL *)url completed:(RDSDWebImageCompletionBlock)completedBlock {
    [self rd_sd_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)rd_sd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(RDSDWebImageCompletionBlock)completedBlock {
    [self rd_sd_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:completedBlock];
}

- (void)rd_sd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options completed:(RDSDWebImageCompletionBlock)completedBlock {
    [self rd_sd_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)rd_sd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options progress:(RDSDWebImageDownloaderProgressBlock)progressBlock completed:(RDSDWebImageCompletionBlock)completedBlock {
    [self rd_sd_cancelCurrentImageLoad];
    objc_setAssociatedObject(self, &imageURLKey, url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    if (!(options & RDSDWebImageDelayPlaceholder)) {
        self.image = placeholder;
    }
    
    if (url) {
        __weak UIImageView *wself = self;
        id <RDSDWebImageOperation> operation = [RDSDWebImageManager.sharedManager downloadImageWithURL:url options:options progress:progressBlock completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if (!wself) return;
            dispatch_main_sync_safe(^{
                if (!wself) return;
                if (image) {
                    wself.image = image;
                    [wself setNeedsLayout];
                } else {
                    if ((options & RDSDWebImageDelayPlaceholder)) {
                        wself.image = placeholder;
                        [wself setNeedsLayout];
                    }
                }
                if (completedBlock && finished) {
                    completedBlock(image, error, cacheType, url);
                }
            });
        }];
        [self rd_sd_setImageLoadOperation:operation forKey:@"UIImageViewImageLoad"];
    } else {
        dispatch_main_async_safe(^{
            NSError *error = [NSError errorWithDomain:@"SDWebImageErrorDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Trying to load a nil url"}];
            if (completedBlock) {
                completedBlock(nil, error, RDSDImageCacheTypeNone, url);
            }
        });
    }
}

- (void)rd_sd_setImageWithPreviousCachedImageWithURL:(NSURL *)url andPlaceholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options progress:(RDSDWebImageDownloaderProgressBlock)progressBlock completed:(RDSDWebImageCompletionBlock)completedBlock {
    NSString *key = [[RDSDWebImageManager sharedManager] cacheKeyForURL:url];
    UIImage *lastPreviousCachedImage = [[RDSDImageCache sharedImageCache] rd_imageFromDiskCacheForKey:key];
    
    [self rd_sd_setImageWithURL:url placeholderImage:lastPreviousCachedImage ?: placeholder options:options progress:progressBlock completed:completedBlock];
}

- (NSURL *)rd_sd_imageURL {
    return objc_getAssociatedObject(self, &imageURLKey);
}

- (void)rd_sd_setAnimationImagesWithURLs:(NSArray *)arrayOfURLs {
    [self rd_sd_cancelCurrentAnimationImagesLoad];
    __weak UIImageView *wself = self;

    NSMutableArray *operationsArray = [[NSMutableArray alloc] init];

    for (NSURL *logoImageURL in arrayOfURLs) {
        id <RDSDWebImageOperation> operation = [RDSDWebImageManager.sharedManager downloadImageWithURL:logoImageURL options:0 progress:nil completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if (!wself) return;
            dispatch_main_sync_safe(^{
                __strong UIImageView *sself = wself;
                [sself stopAnimating];
                if (sself && image) {
                    NSMutableArray *currentImages = [[sself animationImages] mutableCopy];
                    if (!currentImages) {
                        currentImages = [[NSMutableArray alloc] init];
                    }
                    [currentImages addObject:image];

                    sself.animationImages = currentImages;
                    [sself setNeedsLayout];
                }
                [sself startAnimating];
            });
        }];
        [operationsArray addObject:operation];
    }

    [self rd_sd_setImageLoadOperation:[NSArray arrayWithArray:operationsArray] forKey:@"UIImageViewAnimationImages"];
}

- (void)rd_sd_cancelCurrentImageLoad {
    [self rd_sd_cancelImageLoadOperationWithKey:@"UIImageViewImageLoad"];
}

- (void)rd_sd_cancelCurrentAnimationImagesLoad {
    [self rd_sd_cancelImageLoadOperationWithKey:@"UIImageViewAnimationImages"];
}

@end


@implementation UIImageView (RDWebCacheDeprecated)

- (NSURL *)rd_imageURL {
    return [self rd_sd_imageURL];
}

- (void)rd_setImageWithURL:(NSURL *)url {
    [self rd_sd_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)rd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder {
    [self rd_sd_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)rd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options {
    [self rd_sd_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)rd_setImageWithURL:(NSURL *)url completed:(RDSDWebImageCompletedBlock)completedBlock {
    [self rd_sd_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, NSURL *imageURL) {
        if (completedBlock) {
            completedBlock(image, error, cacheType);
        }
    }];
}

- (void)rd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(RDSDWebImageCompletedBlock)completedBlock {
    [self rd_sd_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, NSURL *imageURL) {
        if (completedBlock) {
            completedBlock(image, error, cacheType);
        }
    }];
}

- (void)rd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options completed:(RDSDWebImageCompletedBlock)completedBlock {
    [self rd_sd_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, NSURL *imageURL) {
        if (completedBlock) {
            completedBlock(image, error, cacheType);
        }
    }];
}

- (void)rd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options progress:(RDSDWebImageDownloaderProgressBlock)progressBlock completed:(RDSDWebImageCompletedBlock)completedBlock {
    [self rd_sd_setImageWithURL:url placeholderImage:placeholder options:options progress:progressBlock completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, NSURL *imageURL) {
        if (completedBlock) {
            completedBlock(image, error, cacheType);
        }
    }];
}

- (void)rd_cancelCurrentArrayLoad {
    [self rd_sd_cancelCurrentAnimationImagesLoad];
}

- (void)rd_cancelCurrentImageLoad {
    [self rd_sd_cancelCurrentImageLoad];
}

- (void)rd_setAnimationImagesWithURLs:(NSArray *)arrayOfURLs {
    [self rd_sd_setAnimationImagesWithURLs:arrayOfURLs];
}

@end
