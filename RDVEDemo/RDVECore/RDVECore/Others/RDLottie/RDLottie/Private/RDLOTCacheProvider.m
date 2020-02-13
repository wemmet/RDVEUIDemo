//
//  RDLOTCacheProvider.m
//  RDLottie
//
//  Created by punmy on 2017/7/8.
//
//

#import "RDLOTCacheProvider.h"

@implementation RDLOTCacheProvider

static id<RDLOTImageCache> _imageCache;

+ (id<RDLOTImageCache>)imageCache {
    return _imageCache;
}

+ (void)setImageCache:(id<RDLOTImageCache>)cache {
    _imageCache = cache;
}

@end
