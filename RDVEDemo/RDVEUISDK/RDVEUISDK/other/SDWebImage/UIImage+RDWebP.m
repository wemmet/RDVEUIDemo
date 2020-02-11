//
//  UIImage+WebP.m
//  SDWebImage
//
//  Created by Olivier Poitrey on 07/06/13.
//  Copyright (c) 2013 Dailymotion. All rights reserved.
//

#import "UIImage+RDWebP.h"

// This gets called when the UIImage gets collected and frees the underlying image.
static void FreeImageData(void *info, const void *data, size_t size)
{
    if(info != NULL) {
        WebPFreeDecBuffer(&(((WebPDecoderConfig *) info)->output));
        free(info);
    }
    
    free((void *) data);
}

static inline size_t RDImageByteAlign(size_t size, size_t alignment) {
    return ((size + (alignment - 1)) / alignment) * alignment;
}

@implementation UIImage (WebP)

#pragma mark - Private methods

+ (NSData *)rd_sd_convertToWebP:(UIImage *)image
                        quality:(CGFloat)quality
                          alpha:(CGFloat)alpha
                         preset:(WebPPreset)preset
                    configBlock:(void (^)(WebPConfig *))configBlock
                          error:(NSError **)error
{
    if (alpha < 1) {
        image = [self rd_sd_webPImage:image withAlpha:alpha];
    }
    
    CGImageRef webPImageRef = image.CGImage;
    size_t webPBytesPerRow = CGImageGetBytesPerRow(webPImageRef);
    
    size_t webPImageWidth = CGImageGetWidth(webPImageRef);
    size_t webPImageHeight = CGImageGetHeight(webPImageRef);
    
    CGDataProviderRef webPDataProviderRef = CGImageGetDataProvider(webPImageRef);
    CFDataRef webPImageDatRef = CGDataProviderCopyData(webPDataProviderRef);
    
    uint8_t *webPImageData = (uint8_t *)CFDataGetBytePtr(webPImageDatRef);
    
    WebPConfig config;
    if (!WebPConfigPreset(&config, preset, quality)) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Configuration preset failed to initialize." forKey:NSLocalizedDescriptionKey];
        if(error != NULL)
            *error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@.errorDomain",  [[NSBundle mainBundle] bundleIdentifier]] code:-101 userInfo:errorDetail];
        
        CFRelease(webPImageDatRef);
        return nil;
    }
    
    if (configBlock) {
        configBlock(&config);
    }
    
    if (!WebPValidateConfig(&config)) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"One or more configuration parameters are beyond their valid ranges." forKey:NSLocalizedDescriptionKey];
        if(error != NULL)
            *error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@.errorDomain",  [[NSBundle mainBundle] bundleIdentifier]] code:-101 userInfo:errorDetail];
        
        CFRelease(webPImageDatRef);
        return nil;
    }
    
    WebPPicture pic;
    if (!WebPPictureInit(&pic)) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Failed to initialize structure. Version mismatch." forKey:NSLocalizedDescriptionKey];
        if(error != NULL)
            *error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@.errorDomain",  [[NSBundle mainBundle] bundleIdentifier]] code:-101 userInfo:errorDetail];
        
        CFRelease(webPImageDatRef);
        return nil;
    }
    pic.width = (int)webPImageWidth;
    pic.height = (int)webPImageHeight;
    pic.colorspace = WEBP_YUV420;
    
    WebPPictureImportRGBA(&pic, webPImageData, (int)webPBytesPerRow);
    WebPPictureARGBToYUVA(&pic, WEBP_YUV420);
    WebPCleanupTransparentArea(&pic);
    
    WebPMemoryWriter writer;
    WebPMemoryWriterInit(&writer);
    pic.writer = WebPMemoryWrite;
    pic.custom_ptr = &writer;
    WebPEncode(&config, &pic);
    
    NSData *webPFinalData = [NSData dataWithBytes:writer.mem length:writer.size];
    
    free(writer.mem);
    WebPPictureFree(&pic);
    CFRelease(webPImageDatRef);
    
    return webPFinalData;
}

+ (UIImage *)rd_sd_imageWithWebP:(NSString *)filePath error:(NSError **)error
{
    // If passed `filepath` is invalid, return nil to caller and log error in console
   
    NSError *dataError = nil;
    NSData *imgData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&dataError];
    if (dataError != nil) {
        *error = dataError;
        return nil;
    }
    return [UIImage rd_sd_imageWithWebPData:imgData error:error];
}

+ (UIImage *)rd_sd_imageWithWebPData:(NSData *)imgData error:(NSError **)error
{
    // `WebPGetInfo` weill return image width and height
    @autoreleasepool {
        int width = 0, height = 0;
        if(!WebPGetInfo([imgData bytes], [imgData length], &width, &height)) {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"Header formatting error." forKey:NSLocalizedDescriptionKey];
            if(error != NULL)
                *error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@.errorDomain",  [[NSBundle mainBundle] bundleIdentifier]] code:-101 userInfo:errorDetail];
            return nil;
        }
        WebPDecoderConfig * config = malloc(sizeof(WebPDecoderConfig));
        if(!RDWebPInitDecoderConfig(config)) {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"Failed to initialize structure. Version mismatch." forKey:NSLocalizedDescriptionKey];
            if(error != NULL)
                *error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@.errorDomain",  [[NSBundle mainBundle] bundleIdentifier]] code:-101 userInfo:errorDetail];
            if(config)
                free(config);
            return nil;
        }
        
        config->options.no_fancy_upsampling = 1;
        config->options.bypass_filtering = 1;
        config->options.use_threads = 1;
        config->output.colorspace = MODE_RGBA;
        
        //    size_t bitsPerComponent = 8;
//        size_t bitsPerPixel = 32;
        size_t bytesPerRow = 4 * width;//RDImageByteAlign(bitsPerPixel / 8 * width, 32);//20180828 下载字幕有时会报ERROR_CGDataProvider_BufferIsNotBigEnough从而崩溃
        size_t length = bytesPerRow * height;
        
        void *pixels = calloc(1, length);
        if (!pixels) {
            if(config)
                free(config);
            return nil;
        }
        config->output.is_external_memory = 1;
        config->output.u.RGBA.rgba = pixels;
        config->output.u.RGBA.stride = (int)bytesPerRow;
        config->output.u.RGBA.size = length;
        
        // Decode the WebP image data into a RGBA value array
        VP8StatusCode decodeStatus = WebPDecode([imgData bytes], [imgData length], config);
        if (config) {
            free(config);
        }
        if (decodeStatus != VP8_STATUS_OK) {
            NSString *errorString = [self rd_sd_statusForVP8Code:decodeStatus];
            
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:errorString forKey:NSLocalizedDescriptionKey];
            if(error != NULL)
                *error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@.errorDomain",  [[NSBundle mainBundle] bundleIdentifier]] code:-101 userInfo:errorDetail];
            return nil;
        }
        
        // Construct UIImage from the decoded RGBA value array
        uint8_t *data = WebPDecodeRGBA([imgData bytes], [imgData length], &width, &height);
        //    CGDataProviderRef provider = CGDataProviderCreateWithData(config, data, config->options.scaled_width  * config->options.scaled_height * 4, FreeImageData);
        CGDataProviderRef provider = CGDataProviderCreateWithData(pixels, data, length, FreeImageData);
        
        CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault |kCGImageAlphaLast;
        CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
        
        CGImageRef imageRef = CGImageCreate(width, height, 8, 32, 4 * width, colorSpaceRef, bitmapInfo, provider, NULL, YES, renderingIntent);
        UIImage *result = [UIImage imageWithCGImage:imageRef];    // Free resources to avoid memory leaks
        CGImageRelease(imageRef);
        CGColorSpaceRelease(colorSpaceRef);
        CGDataProviderRelease(provider);
        return result;
    }
    
}


+ (NSData *)rd_sd_pngDataWithWebPData:(NSData *)imgData error:(NSError **)error
{
    // `WebPGetInfo` weill return image width and height
    
    int width = 0, height = 0;
    if(!WebPGetInfo([imgData bytes], [imgData length], &width, &height)) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Header formatting error." forKey:NSLocalizedDescriptionKey];
        if(error != NULL)
            *error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@.errorDomain",  [[NSBundle mainBundle] bundleIdentifier]] code:-101 userInfo:errorDetail];
        return nil;
    }
    WebPDecoderConfig * config = malloc(sizeof(WebPDecoderConfig));
    if(!RDWebPInitDecoderConfig(config)) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Failed to initialize structure. Version mismatch." forKey:NSLocalizedDescriptionKey];
        if(error != NULL)
            *error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@.errorDomain",  [[NSBundle mainBundle] bundleIdentifier]] code:-101 userInfo:errorDetail];
        if(config)
            free(config);
        return nil;
    }
    
    config->options.no_fancy_upsampling = 1;
    config->options.bypass_filtering = 1;
    config->options.use_threads = 1;
    config->output.colorspace = MODE_RGBA;
    
    //    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = RDImageByteAlign(bitsPerPixel / 8 * width, 32);
    size_t length = bytesPerRow * height;
    
    void *pixels = calloc(1, length);
    if (!pixels) {
        if(config)
            free(config);
        return nil;
    }
    config->output.is_external_memory = 1;
    config->output.u.RGBA.rgba = pixels;
    config->output.u.RGBA.stride = (int)bytesPerRow;
    config->output.u.RGBA.size = length;
    
    // Decode the WebP image data into a RGBA value array
    VP8StatusCode decodeStatus = WebPDecode([imgData bytes], [imgData length], config);
    if (config) {
        free(config);
    }
    if (decodeStatus != VP8_STATUS_OK) {
        NSString *errorString = [self rd_sd_statusForVP8Code:decodeStatus];
        
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:errorString forKey:NSLocalizedDescriptionKey];
        if(error != NULL)
            *error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@.errorDomain",  [[NSBundle mainBundle] bundleIdentifier]] code:-101 userInfo:errorDetail];
        return nil;
    }
    
    // Construct UIImage from the decoded RGBA value array
//
    uint8_t *data = WebPDecodeRGBA([imgData bytes], [imgData length], &width, &height);
    //    CGDataProviderRef provider = CGDataProviderCreateWithData(config, data, config->options.scaled_width  * config->options.scaled_height * 4, FreeImageData);
    CGDataProviderRef provider = CGDataProviderCreateWithData(pixels, data, length, FreeImageData);

    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault |kCGImageAlphaLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;

    CGImageRef imageRef = CGImageCreate(width, height, 8, 32, 4 * width, colorSpaceRef, bitmapInfo, provider, NULL, YES, renderingIntent);

    UIImage *result = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorSpaceRef);
    CGDataProviderRelease(provider);
    data = NULL;
    imgData = nil;
    NSData *resultData = nil;
    @try {
        resultData  = UIImagePNGRepresentation(result);
    } @catch (NSException *exception) {
        NSLog(@"exception:%@",exception);
    } @finally {

    }
//     Free resources to avoid memory leaks
//
////     Construct a UIImage from the decoded RGBA value array
//    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);//CGDataProviderCreateWithData( NULL,config->output.u.RGBA.rgba, config->output.u.RGBA.size, FreeImageData);
//    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
////    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;// : kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipLast;
//
//    CGBitmapInfo bitmapInfo = config->input.has_alpha ? kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast : kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipLast;
//    size_t components = config->input.has_alpha ? 4 : 3;
//    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
//    CGImageRef imageRef = CGImageCreate(width, height, 8, components * 8, components * width, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
//
//    CGDataProviderRelease(provider);
//    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
//    NSData *resultData  = UIImagePNGRepresentation(image);
//
//    CGImageRelease(imageRef);
    
    
    
    
    return resultData;
}

#pragma mark - Synchronous methods
+ (UIImage *)rd_sd_imageWithWebP:(NSString *)filePath
{
    NSParameterAssert(filePath != nil);
    return [self rd_sd_imageWithWebP:filePath error:nil];
}

+ (UIImage *)rd_sd_imageWithWebPData:(NSData *)imgData
{
    NSParameterAssert(imgData != nil);
    return [self rd_sd_imageWithWebPData:imgData error:nil];
}

+ (NSData *)rd_sd_pngDataWithWebPData:(NSData *)imgData
{
    NSParameterAssert(imgData != nil);
    return [self rd_sd_pngDataWithWebPData:imgData error:nil];
}

+ (NSData *)rd_sd_imageToWebP:(UIImage *)image quality:(CGFloat)quality
{
    NSParameterAssert(image != nil);
    NSParameterAssert(quality >= 0.0f && quality <= 100.0f);
    return [self rd_sd_convertToWebP:image quality:quality alpha:1.0f preset:WEBP_PRESET_DEFAULT configBlock:nil error:nil];
}

#pragma mark - Asynchronous methods
+ (void)rd_sd_imageWithWebP:(NSString *)filePath completionBlock:(void (^)(UIImage *result))completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    NSParameterAssert(filePath != nil);
    NSParameterAssert(completionBlock != nil);
    NSParameterAssert(failureBlock != nil);
    
    // Create dispatch_queue_t for decoding WebP concurrently
    dispatch_queue_t fromWebPQueue = dispatch_queue_create("com.seanooi.ioswebp.fromwebp", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(fromWebPQueue, ^{
        
        NSError *error = nil;
        UIImage *webPImage = [self rd_sd_imageWithWebP:filePath error:&error];
        
        // Return results to caller on main thread in completion block if `webPImage` != nil
        // Else return in failure block
        if(webPImage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(webPImage);
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }
    });
}

+ (void)rd_sd_imageToWebP:(UIImage *)image
                  quality:(CGFloat)quality
                    alpha:(CGFloat)alpha
                   preset:(WebPPreset)preset
          completionBlock:(void (^)(NSData *result))completionBlock
             failureBlock:(void (^)(NSError *error))failureBlock
{
    [self rd_sd_imageToWebP:image
                    quality:quality
                      alpha:alpha
                     preset:preset
                configBlock:nil
            completionBlock:completionBlock
               failureBlock:failureBlock];
}

+ (void)rd_sd_imageToWebP:(UIImage *)image
                  quality:(CGFloat)quality
                    alpha:(CGFloat)alpha
                   preset:(WebPPreset)preset
              configBlock:(void (^)(WebPConfig *))configBlock
          completionBlock:(void (^)(NSData *result))completionBlock
             failureBlock:(void (^)(NSError *error))failureBlock
{
    NSAssert(image != nil, @"imageToWebP:quality:alpha:completionBlock:failureBlock image cannot be nil");
    NSAssert(quality >= 0 && quality <= 100, @"imageToWebP:quality:alpha:completionBlock:failureBlock quality has to be [0, 100]");
    NSAssert(alpha >= 0 && alpha <= 1, @"imageToWebP:quality:alpha:completionBlock:failureBlock alpha has to be [0, 1]");
    NSAssert(completionBlock != nil, @"imageToWebP:quality:alpha:completionBlock:failureBlock completionBlock cannot be nil");
    NSAssert(failureBlock != nil, @"imageToWebP:quality:alpha:completionBlock:failureBlock failureBlock block cannot be nil");
    
    // Create dispatch_queue_t for encoding WebP concurrently
    dispatch_queue_t toWebPQueue = dispatch_queue_create("com.seanooi.ioswebp.towebp", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(toWebPQueue, ^{
        
        NSError *error = nil;
        NSData *webPFinalData = [self rd_sd_convertToWebP:image quality:quality alpha:alpha preset:preset configBlock:configBlock error:&error];
        
        // Return results to caller on main thread in completion block is `webPFinalData` != nil
        // Else return in failure block
        if(!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(webPFinalData);
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }
    });
}

#pragma mark - Utilities

- (UIImage *)rd_sd_imageByApplyingAlpha:(CGFloat) alpha
{
    NSParameterAssert(alpha >= 0.0f && alpha <= 1.0f);
    
    if (alpha <= 1) {
        
        UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
        
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGRect area = CGRectMake(0, 0, self.size.width, self.size.height);
        
        CGContextScaleCTM(ctx, 1, -1);
        CGContextTranslateCTM(ctx, 0, -area.size.height);
        
        CGContextSetAlpha(ctx, alpha);
        CGContextSetBlendMode(ctx, kCGBlendModeXOR);
        CGContextSetFillColorWithColor(ctx, [UIColor clearColor].CGColor);
        
        CGContextDrawImage(ctx, area, self.CGImage);
        
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        return newImage;
        
    }
    else {
        return self;
    }
}

+ (UIImage *)rd_sd_webPImage:(UIImage *)image withAlpha:(CGFloat)alpha
{
    // CGImageAlphaInfo of images with alpha are kCGImageAlphaPremultipliedFirst
    // Convert to kCGImageAlphaPremultipliedLast to avoid gray-ish background
    // when encoding alpha images to WebP format
    
    CGImageRef imageRef = image.CGImage;
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    UInt8* pixelBuffer = malloc(height * width * 4);
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
    CGContextRef context = CGBitmapContextCreate(pixelBuffer, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextSetRGBFillColor(context, 0, 0, 0, 1);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    CGDataProviderRef dataProviderRef = CGImageGetDataProvider(imageRef);
    CFDataRef dataRef = CGDataProviderCopyData(dataProviderRef);
    
    GLubyte *pixels = (GLubyte *)CFDataGetBytePtr(dataRef);
    
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            NSInteger byteIndex = ((width * 4) * y) + (x * 4);
            pixelBuffer[byteIndex + 3] = pixels[byteIndex + 3]*alpha;
        }
    }
    
    CGContextRef ctx = CGBitmapContextCreate(pixelBuffer, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGImageRef newImgRef = CGBitmapContextCreateImage(ctx);
    
    free(pixelBuffer);
    CFRelease(dataRef);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(ctx);
    
    UIImage *newImage = [UIImage imageWithCGImage:newImgRef];
    CGImageRelease(newImgRef);
    
    return newImage;
}

+ (NSString *)rd_sd_version:(NSInteger)version
{
    // Convert version number to hexadecimal and parse it accordingly
    // E.g: v2.5.7 is 0x020507
    
    NSString *hex = [NSString stringWithFormat:@"%06lx", (long)version];
    NSMutableArray *array = [NSMutableArray array];
    for (int x = 0; x < [hex length]; x += 2) {
        [array addObject:@([[hex substringWithRange:NSMakeRange(x, 2)] integerValue])];
    }
    
    return [array componentsJoinedByString:@"."];
}

#pragma mark - Error statuses

+ (NSString *)rd_sd_statusForVP8Code:(VP8StatusCode)code
{
    NSString *errorString;
    switch (code) {
        case VP8_STATUS_OUT_OF_MEMORY:
            errorString = @"OUT_OF_MEMORY";
            break;
        case VP8_STATUS_INVALID_PARAM:
            errorString = @"INVALID_PARAM";
            break;
        case VP8_STATUS_BITSTREAM_ERROR:
            errorString = @"BITSTREAM_ERROR";
            break;
        case VP8_STATUS_UNSUPPORTED_FEATURE:
            errorString = @"UNSUPPORTED_FEATURE";
            break;
        case VP8_STATUS_SUSPENDED:
            errorString = @"SUSPENDED";
            break;
        case VP8_STATUS_USER_ABORT:
            errorString = @"USER_ABORT";
            break;
        case VP8_STATUS_NOT_ENOUGH_DATA:
            errorString = @"NOT_ENOUGH_DATA";
            break;
        default:
            errorString = @"UNEXPECTED_ERROR";
            break;
    }
    return errorString;
}

@end

#if !COCOAPODS
// Functions to resolve some undefined symbols when using WebP and force_load flag
//void RDWebPInitPremultiplyNEON(void) {}
//void RDWebPInitUpsamplersNEON(void) {}
//void RDVP8DspInitNEON(void) {}
#endif
