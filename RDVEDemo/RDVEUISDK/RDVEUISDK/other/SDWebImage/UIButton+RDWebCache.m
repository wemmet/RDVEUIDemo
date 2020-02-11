/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIButton+RDWebCache.h"
#import "objc/runtime.h"
#import "UIView+RDWebCacheOperation.h"

static char imageURLStorageKey;

@implementation UIButton (RDWebCache)

- (NSURL *)rd_sd_currentImageURL {
    NSURL *url = self.imageURLStorage[@(self.state)];

    if (!url) {
        url = self.imageURLStorage[@(UIControlStateNormal)];
    }

    return url;
}

- (NSURL *)rd_sd_imageURLForState:(UIControlState)state {
    return self.imageURLStorage[@(state)];
}
#if 1
- (void)rd_sd_setImageWithURL:(NSURL *)url forState:(UIControlState)state{
    
    [self rd_sd_setImageWithURL:url forState:state placeholderImage:nil];
    
}
- (void)rd_sd_setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder {
    RDSDWebImageManager *manager = [RDSDWebImageManager sharedManager];
    NSString* key = [manager cacheKeyForURL:url];
    RDSDImageCache* cache = [RDSDImageCache sharedImageCache];
    //此方法会先从memory中取。
    UIImage *image = [cache rd_imageFromDiskCacheForKey:key];
    
    if(!image)
        [self rd_sd_setImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, NSURL *imageURL) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setImage:image forState:state];
                [self setNeedsDisplay];
            });
        }];
    else{
        [self setImage:image forState:state];
        [self setNeedsDisplay];
    }
}

#else
- (void)rd_sd_setImageWithURL:(NSURL *)url forState:(UIControlState)state {
    [self rd_sd_setImageWithURL:url forState:state placeholderImage:nil options:0 completed:nil];
}
- (void)rd_sd_setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder {
    [self rd_sd_setImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:nil];
}
#endif


- (void)rd_sd_setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options {
    [self rd_sd_setImageWithURL:url forState:state placeholderImage:placeholder options:options completed:nil];
}

- (void)rd_sd_setImageWithURL:(NSURL *)url forState:(UIControlState)state completed:(RDSDWebImageCompletionBlock)completedBlock {
    [self rd_sd_setImageWithURL:url forState:state placeholderImage:nil options:0 completed:completedBlock];
}

- (void)rd_sd_setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder completed:(RDSDWebImageCompletionBlock)completedBlock {
    [self rd_sd_setImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)rd_sd_setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options completed:(RDSDWebImageCompletionBlock)completedBlock {

    [self setImage:placeholder forState:state];
    [self rd_sd_cancelImageLoadForState:state];
    
    if (!url) {
        [self.imageURLStorage removeObjectForKey:@(state)];
        
        dispatch_main_async_safe(^{
            NSError *error = [NSError errorWithDomain:@"SDWebImageErrorDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Trying to load a nil url"}];
            if (completedBlock) {
                completedBlock(nil, error, RDSDImageCacheTypeNone, url);
            }
        });
        
        return;
    }
    
    self.imageURLStorage[@(state)] = url;

    __weak UIButton *wself = self;
    id <RDSDWebImageOperation> operation = [RDSDWebImageManager.sharedManager downloadImageWithURL:url options:options progress:nil completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        if (!wself) return;
        dispatch_main_sync_safe(^{
            __strong UIButton *sself = wself;
            if (!sself) return;
            if (image) {
                [sself setImage:image forState:state];
            }
            if (completedBlock && finished) {
                completedBlock(image, error, cacheType, url);
            }
        });
    }];
    [self rd_sd_setImageLoadOperation:operation forState:state];
}

- (void)rd_sd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state {
    [self rd_sd_setBackgroundImageWithURL:url forState:state placeholderImage:nil options:0 completed:nil];
}

- (void)rd_sd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder {
    [self rd_sd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:nil];
}

- (void)rd_sd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options {
    [self rd_sd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:options completed:nil];
}

- (void)rd_sd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state completed:(RDSDWebImageCompletionBlock)completedBlock {
    [self rd_sd_setBackgroundImageWithURL:url forState:state placeholderImage:nil options:0 completed:completedBlock];
}

- (void)sd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder completed:(RDSDWebImageCompletionBlock)completedBlock {
    [self rd_sd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)rd_sd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options completed:(RDSDWebImageCompletionBlock)completedBlock {
    [self rd_sd_cancelImageLoadForState:state];

    [self setBackgroundImage:placeholder forState:state];

    if (url) {
        __weak UIButton *wself = self;
        id <RDSDWebImageOperation> operation = [RDSDWebImageManager.sharedManager downloadImageWithURL:url options:options progress:nil completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if (!wself) return;
            dispatch_main_sync_safe(^{
                __strong UIButton *sself = wself;
                if (!sself) return;
                if (image) {
                    [sself setBackgroundImage:image forState:state];
                }
                if (completedBlock && finished) {
                    completedBlock(image, error, cacheType, url);
                }
            });
        }];
        [self rd_sd_setBackgroundImageLoadOperation:operation forState:state];
    } else {
        dispatch_main_async_safe(^{
            NSError *error = [NSError errorWithDomain:@"SDWebImageErrorDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Trying to load a nil url"}];
            if (completedBlock) {
                completedBlock(nil, error, RDSDImageCacheTypeNone, url);
            }
        });
    }
}

- (void)rd_sd_setImageLoadOperation:(id<RDSDWebImageOperation>)operation forState:(UIControlState)state {
    [self rd_sd_setImageLoadOperation:operation forKey:[NSString stringWithFormat:@"UIButtonImageOperation%@", @(state)]];
}

- (void)rd_sd_cancelImageLoadForState:(UIControlState)state {
    [self rd_sd_cancelImageLoadOperationWithKey:[NSString stringWithFormat:@"UIButtonImageOperation%@", @(state)]];
}

- (void)rd_sd_setBackgroundImageLoadOperation:(id<RDSDWebImageOperation>)operation forState:(UIControlState)state {
    [self rd_sd_setImageLoadOperation:operation forKey:[NSString stringWithFormat:@"UIButtonBackgroundImageOperation%@", @(state)]];
}

- (void)rd_sd_cancelBackgroundImageLoadForState:(UIControlState)state {
    [self rd_sd_cancelImageLoadOperationWithKey:[NSString stringWithFormat:@"UIButtonBackgroundImageOperation%@", @(state)]];
}

- (NSMutableDictionary *)imageURLStorage {
    NSMutableDictionary *storage = objc_getAssociatedObject(self, &imageURLStorageKey);
    if (!storage)
    {
        storage = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &imageURLStorageKey, storage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return storage;
}

@end


@implementation UIButton (RDWebCacheDeprecated)

- (NSURL *)rd_currentImageURL {
    return [self rd_sd_currentImageURL];
}

- (NSURL *)rd_imageURLForState:(UIControlState)state {
    return [self rd_sd_imageURLForState:state];
}

- (void)rd_setImageWithURL:(NSURL *)url forState:(UIControlState)state {
    [self rd_sd_setImageWithURL:url forState:state placeholderImage:nil options:0 completed:nil];
}

- (void)rd_setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder {
    [self rd_sd_setImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:nil];
}

- (void)rd_setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options {
    [self rd_sd_setImageWithURL:url forState:state placeholderImage:placeholder options:options completed:nil];
}

- (void)setImageWithURL:(NSURL *)url forState:(UIControlState)state completed:(RDSDWebImageCompletionBlock)completedBlock {
    [self rd_sd_setImageWithURL:url forState:state placeholderImage:nil options:0 completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, NSURL *imageURL) {
        if (completedBlock) {
            completedBlock(image, error, cacheType,imageURL);
        }
    }];
}

- (void)rd_setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder completed:(RDSDWebImageCompletedBlock)completedBlock {
    [self rd_sd_setImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, NSURL *imageURL) {
        if (completedBlock) {
            completedBlock(image, error, cacheType);
        }
    }];
}

- (void)rd_setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options completed:(RDSDWebImageCompletedBlock)completedBlock {
    [self rd_sd_setImageWithURL:url forState:state placeholderImage:placeholder options:options completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, NSURL *imageURL) {
        if (completedBlock) {
            completedBlock(image, error, cacheType);
        }
    }];
}

- (void)rd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state {
    [self rd_sd_setBackgroundImageWithURL:url forState:state placeholderImage:nil options:0 completed:nil];
}

- (void)rd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder {
    [self rd_sd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:nil];
}

- (void)rd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options {
    [self rd_sd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:options completed:nil];
}

- (void)rd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state completed:(RDSDWebImageCompletedBlock)completedBlock {
    [self rd_sd_setBackgroundImageWithURL:url forState:state placeholderImage:nil options:0 completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, NSURL *imageURL) {
        if (completedBlock) {
            completedBlock(image, error, cacheType);
        }
    }];
}

- (void)rd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder completed:(RDSDWebImageCompletedBlock)completedBlock {
    [self rd_sd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, NSURL *imageURL) {
        if (completedBlock) {
            completedBlock(image, error, cacheType);
        }
    }];
}

- (void)rd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options completed:(RDSDWebImageCompletedBlock)completedBlock {
    [self rd_sd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:options completed:^(UIImage *image, NSError *error, RDSDImageCacheType cacheType, NSURL *imageURL) {
        if (completedBlock) {
            completedBlock(image, error, cacheType);
        }
    }];
}

- (void)rd_cancelCurrentImageLoad {
    // in a backwards compatible manner, cancel for current state
    [self rd_sd_cancelImageLoadForState:self.state];
}

- (void)rd_cancelBackgroundImageLoadForState:(UIControlState)state {
    [self rd_sd_cancelBackgroundImageLoadForState:state];
}

@end
