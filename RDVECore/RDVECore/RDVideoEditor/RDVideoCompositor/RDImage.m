//
//  RDImageFrameBuffer.m
//  RDVECore
//
//  Created by 周晓林 on 2017/5/15.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#import "RDImage.h"
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "RDRecordHelper.h"
// 优化从相册获取图片
// 纹理复用 ？
@interface RDImage()
{
    GLuint _imageTexture;
    float imageWidth;
    float imageHeight;
    
    int m_dWidth;
    NSMutableArray *imagesDurationArray;
    NSInteger prevIndex;
}
@end
@implementation RDImage

- (UIImage *) getImageFromPath:(NSURL *)path{
    __block UIImage* image;
    if ([RDRecordHelper isSystemPhotoUrl:path]) {
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.synchronous = YES;
        option.resizeMode = PHImageRequestOptionsResizeModeExact;

        PHAsset* asset =[[PHAsset fetchAssetsWithALAssetURLs:@[path] options:nil] objectAtIndex:0];
        int width = m_dWidth;
        if ([[asset valueForKey:@"uniformTypeIdentifier"] isEqualToString:@"com.compuserve.gif"]) {
            [[PHImageManager defaultManager] requestImageDataForAsset:asset
                                                              options:option
                                                        resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                                                            image = [self imageWithData:imageData];
                                                            if (image.size.width > width || image.size.height > width) {
                                                                CGSize targetSize;
                                                                if (image.size.width >= image.size.height) {
                                                                    targetSize = CGSizeMake(width, width * (image.size.height / image.size.width));
                                                                }else {
                                                                    targetSize = CGSizeMake(width * (image.size.width / image.size.height), width);
                                                                }
                                                                image = [RDRecordHelper resizeImage:image toSize:targetSize];
                                                            }
                                                        }];
        }else {
            [[PHImageManager defaultManager] requestImageForAsset:asset
                                                       targetSize:CGSizeMake(width, width)
                                                      contentMode:PHImageContentModeAspectFit
                                                          options:option
                                                    resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                        image = result;
                                                    }];
        }
    } else {
        NSData *data = [NSData dataWithContentsOfURL:path];
        image = [self imageWithData:data];
        if (!image) {
            image = [UIImage imageWithContentsOfFile:path.path];
            image = [RDRecordHelper fixOrientation:image];
        }
        data = nil;
    }
    return image;
}

- (UIImage *)imageWithData:(NSData *)data {
    if (!data) {
        return nil;
    }
    UIImage *image;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    size_t count = CGImageSourceGetCount(source);
    if (count <= 1) {
        image = [[UIImage alloc] initWithData:data];
    }
    else {
        NSMutableArray *images = [NSMutableArray array];
        NSTimeInterval duration = 0.0f;
        imagesDurationArray = [NSMutableArray array];
        for (size_t i = 0; i < count; i++) {
            CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, i, NULL);
            duration += [RDRecordHelper frameDurationAtIndex:i source:source];
            UIImage *image = [UIImage imageWithCGImage:imageRef scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
            [images addObject:image];
            
            CGImageRelease(imageRef);
            [imagesDurationArray addObject:[NSNumber numberWithFloat:duration]];
        }
//        NSLog(@"%@", imagesDurationArray);
        image = [UIImage animatedImageWithImages:images duration:duration];
    }
    if (source) {
        CFRelease(source);
    }
    return image;
}

- (GLvoid*)CGImageCreateDecoded:(CGImageRef)cgImage {
    if (!cgImage) {
        return NULL;
    }
    
    BOOL hasAlpha = [self CGImageContainsAlpha:cgImage];
    // iOS prefer BGRA8888 (premultiplied) or BGRX8888 bitmapInfo for screen rendering, which is same as `UIGraphicsBeginImageContext()` or `- [CALayer drawInContext:]`
    // Though you can use any supported bitmapInfo (see: https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_context/dq_context.html#//apple_ref/doc/uid/TP30001066-CH203-BCIBHHBB ) and let Core Graphics reorder it when you call `CGContextDrawImage`
    // But since our build-in coders use this bitmapInfo, this can have a little performance benefit
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
    bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
    void* imageData = (void*)calloc(1, (int)m_dWidth*(int)m_dWidth*4);
    CGContextRef context = CGBitmapContextCreate(imageData, m_dWidth, m_dWidth, 8, 4*m_dWidth, [self colorSpaceGetDeviceRGB], bitmapInfo);
    if (!context) {
        return NULL;
    }
    
    // Apply transform
    CGContextDrawImage(context, CGRectMake(0, 0, m_dWidth, m_dWidth), cgImage); // The rect is bounding box of CGImage, don't swap width & height
//    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    return (GLvoid*)imageData;
}

- (BOOL)CGImageContainsAlpha:(CGImageRef)cgImage {
    if (!cgImage) {
        return NO;
    }
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(cgImage);
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    return hasAlpha;
}

- (CGColorSpaceRef)colorSpaceGetDeviceRGB {
    static CGColorSpaceRef colorSpace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colorSpace = CGColorSpaceCreateDeviceRGB();
    });
    return colorSpace;
}

- (instancetype) init{
    if (!(self = [super init])) {
        return nil;
    }

#if 0   //20190925 1080p图片会不清晰
    CGSize size = [RDRecordHelper matchSize];
    m_dWidth = ((size.width>480?800:400));
#else
    m_dWidth = 1080;
#endif
    glGenTextures(1, &_imageTexture);
    glBindTexture(GL_TEXTURE_2D, _imageTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, m_dWidth, m_dWidth, 0, GL_BGRA, GL_UNSIGNED_BYTE, (GLvoid*)NULL);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    return self;
}

- (instancetype)initWithImagePath:(NSURL *)path{
    if (!(self = [super init])) {
        return nil;
    }
    
    _currentImage = [self getImageFromPath:path];
    imageWidth = _currentImage.size.width;
    imageHeight = _currentImage.size.height;
    
    
    CGImageRef cgImage = [_currentImage CGImage];
    
    void* imageData = (void*)calloc(1, (int)imageWidth*(int)imageHeight*4);
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef imageContext = CGBitmapContextCreate(imageData, imageWidth, imageHeight, 8, 4*imageWidth, genericRGBColorspace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, imageWidth, imageHeight), cgImage);
    CGContextRelease(imageContext);
    CGColorSpaceRelease(genericRGBColorspace);
    
    
    glGenTextures(1, &_imageTexture);
    glBindTexture(GL_TEXTURE_2D, _imageTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, (GLvoid*)imageData);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    
    free(imageData);
    
    return self;
}



- (void)loadImagePath:(NSURL *)path
{
    _currentImage = [self getImageFromPath:path];
    imageWidth = _currentImage.size.width;
    imageHeight = _currentImage.size.height;
    float time = CACurrentMediaTime();
    CGImageRef cgImage = [_currentImage CGImage];
    
    void* imageData = (void*)calloc(1, (int)m_dWidth*(int)m_dWidth*4);
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef imageContext = CGBitmapContextCreate(imageData, m_dWidth, m_dWidth, 8, 4*m_dWidth, genericRGBColorspace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, m_dWidth, m_dWidth), cgImage);
    CGContextRelease(imageContext);
    CGColorSpaceRelease(genericRGBColorspace);
    
    glBindTexture(GL_TEXTURE_2D, _imageTexture);
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0,  m_dWidth, m_dWidth,GL_BGRA, GL_UNSIGNED_BYTE, (GLvoid*)imageData);
    free(imageData);
    NSLog(@"耗时%lf",CACurrentMediaTime()-time);
}
- (void)setCurrentTime:(float)currentTime {
    if (!imagesDurationArray || imagesDurationArray.count == 0) {
        return;
    }
    if (currentTime > _currentImage.duration) {
        currentTime = fmodf(currentTime, _currentImage.duration);
    }
    [imagesDurationArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        float duration = [obj floatValue];
        if (duration >= currentTime) {
            if (prevIndex != idx) {
                prevIndex = idx;
//                NSLog(@"currentTime:%f idx:%lu", currentTime, (unsigned long)idx);
//                float time = CACurrentMediaTime();
                CGImageRef cgImage = [_currentImage.images[idx] CGImage];
    #if 0
                void* imageData = (void*)calloc(1, (int)m_dWidth*(int)m_dWidth*4);
                CGContextRef imageContext = CGBitmapContextCreate(imageData, m_dWidth, m_dWidth, 8, 4*m_dWidth, [self colorSpaceGetDeviceRGB], kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
                CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, m_dWidth, m_dWidth), cgImage);
                NSLog(@"耗时1 %lf",CACurrentMediaTime()-time);
                CGContextRelease(imageContext);
    #else
                GLvoid *imageData = [self CGImageCreateDecoded:cgImage];
    #endif
                glBindTexture(GL_TEXTURE_2D, _imageTexture);
                glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0,  m_dWidth, m_dWidth,GL_BGRA, GL_UNSIGNED_BYTE, (GLvoid*)imageData);
                free(imageData);
//                NSLog(@"耗时%lf",CACurrentMediaTime()-time);
            }
            *stop = YES;
        }
    }];
}

- (GLuint)texture{
    return _imageTexture;
}
- (float)width{
    return imageWidth;
}
- (float)height{
    return imageHeight;
}
- (void)clear{
    if (_imageTexture) {
        glDeleteTextures(1, &_imageTexture);
        _imageTexture = 0;
    }
    [imagesDurationArray removeAllObjects];
    _currentImage = nil;
}

- (void)dealloc{
//    NSLog(@"%s",__func__);
    
}

@end
