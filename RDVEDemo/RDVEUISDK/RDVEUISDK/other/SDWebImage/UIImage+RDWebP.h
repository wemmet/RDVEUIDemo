//
//  UIImage+WebP.h
//  SDWebImage
//
//  Created by Olivier Poitrey on 07/06/13.
//  Copyright (c) 2013 Dailymotion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "rd_decode.h"
#import "rd_encode.h"
//#import "<#header#>"

// Fix for issue #416 Undefined symbols for architecture armv7 since WebP introduction when deploying to device
//void RDWebPInitPremultiplyNEON(void);

//void RDWebPInitUpsamplersNEON(void);

//void RDVP8DspInitNEON(void);

@interface UIImage (WebP)

+ (UIImage *)rd_sd_imageWithWebPData:(NSData *)data;
+ (NSData *)rd_sd_pngDataWithWebPData:(NSData *)imgData;
+ (UIImage *)rd_sd_imageWithWebP:(NSString *)filePath;

+ (UIImage *)rd_sd_imageWithWebP:(NSString *)filePath error:(NSError **)error;

+ (NSData *)rd_sd_imageToWebP:(UIImage *)image quality:(CGFloat)quality;

+ (void)rd_sd_imageToWebP:(UIImage *)image
                  quality:(CGFloat)quality
                    alpha:(CGFloat)alpha
                   preset:(WebPPreset)preset
          completionBlock:(void (^)(NSData* result))completionBlock
             failureBlock:(void (^)(NSError* error))failureBlock;

+ (void)rd_sd_imageToWebP:(UIImage*)image
                  quality:(CGFloat)quality
                    alpha:(CGFloat)alpha
                   preset:(WebPPreset)preset
              configBlock:(void (^)(WebPConfig* config))configBlock
          completionBlock:(void (^)(NSData* result))completionBlock
             failureBlock:(void (^)(NSError* error))failureBlock;

+ (void)rd_sd_imageWithWebP:(NSString*)filePath
            completionBlock:(void (^)(UIImage* result))completionBlock
               failureBlock:(void (^)(NSError* error))failureBlock;

- (UIImage*)rd_sd_imageByApplyingAlpha:(CGFloat)alpha;

@end
