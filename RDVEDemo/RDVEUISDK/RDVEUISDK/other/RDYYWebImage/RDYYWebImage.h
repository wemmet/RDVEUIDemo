//
//  RDYYWebImage.h
//  RDYYWebImage <https://github.com/ibireme/RDYYWebImage>
//
//  Created by ibireme on 15/2/23.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

#if __has_include(<RDYYWebImage/RDYYWebImage.h>)
FOUNDATION_EXPORT double RDYYWebImageVersionNumber;
FOUNDATION_EXPORT const unsigned char RDYYWebImageVersionString[];
#import <RDYYWebImage/RDYYImageCache.h>
#import <RDYYWebImage/RDYYWebImageOperation.h>
#import <RDYYWebImage/RDYYWebImageManager.h>
#import <RDYYWebImage/UIImage+RDYYWebImage.h>
#import <RDYYWebImage/UIImageView+RDYYWebImage.h>
#import <RDYYWebImage/UIButton+RDYYWebImage.h>
#import <RDYYWebImage/CALayer+RDYYWebImage.h>
#import <RDYYWebImage/MKAnnotationView+RDYYWebImage.h>
#else
#import "RDYYImageCache.h"
#import "RDYYWebImageOperation.h"
#import "RDYYWebImageManager.h"
#import "UIImage+RDYYWebImage.h"
#import "UIImageView+RDYYWebImage.h"
#import "UIButton+RDYYWebImage.h"
#import "CALayer+RDYYWebImage.h"
#import "MKAnnotationView+RDYYWebImage.h"
#endif

#if __has_include(<RDYYImage/RDYYImage.h>)
#import <RDYYImage/RDYYImage.h>
#elif __has_include(<RDYYWebImage/RDYYImage.h>)
#import <RDYYWebImage/RDYYImage.h>
#import <RDYYWebImage/RDYYFrameImage.h>
#import <RDYYWebImage/RDYYSpriteSheetImage.h>
#import <RDYYWebImage/RDYYImageCoder.h>
#import <RDYYWebImage/RDYYAnimatedImageView.h>
#else
#import "RDYYImage.h"
#import "RDYYFrameImage.h"
#import "RDYYSpriteSheetImage.h"
#import "RDYYImageCoder.h"
#import "RDYYAnimatedImageView.h"
#endif

#if __has_include(<RDYYCache/RDYYCache.h>)
#import <RDYYCache/RDYYCache.h>
#elif __has_include(<RDYYWebImage/RDYYCache.h>)
#import <RDYYWebImage/RDYYCache.h>
#import <RDYYWebImage/RDYYMemoryCache.h>
#import <RDYYWebImage/RDYYDiskCache.h>
#import <RDYYWebImage/RDYYKVStorage.h>
#else
#import "RDYYCache.h"
#import "RDYYMemoryCache.h"
#import "RDYYDiskCache.h"
#import "RDYYKVStorage.h"
#endif

