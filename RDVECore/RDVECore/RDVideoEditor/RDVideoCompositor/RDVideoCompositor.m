//
//  RDVideoCompositor.m
//  RDVECore
//
//  Created by 周晓林 on 2017/5/8.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#import "RDVideoCompositor.h"
#import "RDVideoCompositorRenderer.h"
#import "RDVideoCompositorInstruction.h"
#import "RDScene.h"
#define RENDERINGQUEUE "com.17rd.xpk.renderingqueue"
#define RENDERCONTEXTQUEUE "com.17rd.xpk.rendercontextqueue"

#import <UIKit/UIKit.h>
@interface RDVideoCompositor()
{
    BOOL _shouldCancelAllRequest;
    BOOL _renderContextDidChange;
    dispatch_queue_t _renderingQueue;
    dispatch_queue_t _renderContextQueue;
    AVVideoCompositionRenderContext *_renderContext;
    
    RDVideoCompositorRenderer* _renderer;
    NSNotificationName notificationName;
    CVPixelBufferRef pixelBufferCopy; //记录上一张画面
}

@end

@implementation RDVideoCompositor
- (instancetype)init{
    
    if (self = [super init]) {
        _renderingQueue = dispatch_queue_create(RENDERINGQUEUE, DISPATCH_QUEUE_SERIAL);
        _renderContextQueue = dispatch_queue_create(RENDERCONTEXTQUEUE, DISPATCH_QUEUE_SERIAL);
        _renderContextDidChange = NO;
//        _renderer = [RDVideoCompositorRenderer sharedVideoCompositorRender];//同时seek截图有问题 ????
        _renderer = [[RDVideoCompositorRenderer alloc] init];//多次初始化videocore会崩溃
#if 0
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notification:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notification:) name:UIApplicationDidBecomeActiveNotification object:nil];
#else   //20190729 wuxiaoxia 处于UIApplicationWillResignActiveNotification这个状态(如下拉通知栏、上拉快捷栏、双击home键的情况)还是可以导出，只有真正切到后台时才停止导出
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
#endif
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notification:) name:UIApplicationWillEnterForegroundNotification object:nil];
//        _shouldCancelAllRequest = YES;
    }
    return self;
}
- (void) notification: (NSNotification*) notification {
    notificationName = notification.name;
    if([notification.name isEqualToString:UIApplicationDidEnterBackgroundNotification]) {

        _shouldCancelAllRequest = YES;
        
    }
    
    else if([notification.name isEqualToString:UIApplicationWillEnterForegroundNotification]) {
        
        _shouldCancelAllRequest = NO;
    }
    
    else if ([notification.name isEqualToString:UIApplicationDidBecomeActiveNotification]){
        
        _shouldCancelAllRequest = NO;
    }
}

- (BOOL)supportsWideColorSourceFrames{
    return NO;
}

- (void)renderContextChanged:(AVVideoCompositionRenderContext *)newRenderContext{
    dispatch_sync(_renderContextQueue, ^{
        _renderContext = newRenderContext;
        _renderContextDidChange = YES;
    });
}
- (NSDictionary *)sourcePixelBufferAttributes
{
    return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
              (NSString*)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]};
}

- (NSDictionary *)requiredPixelBufferAttributesForRenderContext
{
    return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
              (NSString*)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]};
}

- (void)startVideoCompositionRequest:(AVAsynchronousVideoCompositionRequest *)request
{
//    NSLog(@"%s%@",__func__, CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, request.compositionTime)));
    __weak typeof(self) weakSelf = self;
    @autoreleasepool {
        dispatch_async(_renderingQueue, ^{
            
            if (_shouldCancelAllRequest) {
                [request finishCancelledRequest];
            }else{
                NSError *err = nil;
                
#if 0
                CVPixelBufferRef resultPixels = [weakSelf newRenderedPixelBufferForRequest:request error:&err];
                
                
                if (resultPixels) {
                    [request finishWithComposedVideoFrame:resultPixels];
                    CVPixelBufferRelease(resultPixels);
                    resultPixels = nil;
                }else{
                    [request finishWithError:err];
                }
#else
                CVPixelBufferRef resultPixels = [weakSelf newRenderedPixelBufferForRequest:request error:&err];
                if (resultPixels) {
                    
                    RDVideoCompositorInstruction* instruction = request.videoCompositionInstruction;
                    if(err && instruction.isExporting)
                    {
//                        NSLog(@"newRenderedPixelBufferForRequest error code :%d",err.code);
                        CVPixelBufferLockBaseAddress(resultPixels, 0);
                        int bufferWidth      = (int)CVPixelBufferGetWidth(resultPixels);
                        uint8_t *baseAddress = CVPixelBufferGetBaseAddress(resultPixels);
                        
                        // 构造黑屏数据格式：图片像素第一行，0 ~ width/2 白色；width/2 ～ width 绿色
                        for(int i = 0;i<bufferWidth;i++)
                        {
                            if(i<bufferWidth/2)
                            {
                                baseAddress[i*4] = 0xff;
                                baseAddress[i*4+1] = 0xff;
                                baseAddress[i*4+2] = 0xff;
                                baseAddress[i*4+3] = 0xff;
                            }
                            else
                            {
                                baseAddress[i*4] = 0x00;
                                baseAddress[i*4+1] = 0xff;
                                baseAddress[i*4+2] = 0x00;
                                baseAddress[i*4+3] = 0xff;
                            }
                        }
                       
                        CVPixelBufferUnlockBaseAddress(resultPixels, 0);
                    }

                    [request finishWithComposedVideoFrame:resultPixels];
                    CVPixelBufferRelease(resultPixels);
                    resultPixels = nil;
                    
                }else{
                    [request finishWithError:err];
                   
                }
#endif
            }
        });
    }
}

- (GLubyte*)getLottieBuffer:(RDLOTAnimationView *)lottieView layer:(CALayer *)layer time:(CMTime)outputTime {
    @autoreleasepool {
        float time = CMTimeGetSeconds(outputTime);
        float animationTime = time;
        if (lottieView.isRepeat && lottieView.animationPlayCount > 1) {
            int timeInt = time * 1000000;
            int animationDurationInt = lottieView.animationDuration * 1000000;
            int animationTimeInt = timeInt % animationDurationInt;
            animationTime = animationTimeInt / 1000000.0;
//            NSLog(@"time:%.2f animationDuration:%.2f animationTime:%.2f", time, _lottieView.animationDuration, animationTime);
        }
        if (lottieView.endStartTime > 0.0 && animationTime > lottieView.imagesDuration) {
            lottieView.animationProgress = (animationTime + lottieView.endStartTime)/lottieView.animationDuration;
        }else {
            lottieView.animationProgress = animationTime/lottieView.animationDuration;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMVLottieTime" object:[NSValue valueWithCMTime:outputTime]];
        CGSize layerPixelSize = _renderContext.size;
        
        GLubyte *imageData = (GLubyte *) calloc(1, (int)layerPixelSize.width * (int)layerPixelSize.height * 4);
        
        CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
        CGContextRef imageContext = CGBitmapContextCreate(imageData, (int)layerPixelSize.width, (int)layerPixelSize.height, 8, (int)layerPixelSize.width * 4, genericRGBColorspace,  kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGContextTranslateCTM(imageContext, 0.0f, layerPixelSize.height);
        CGContextScaleCTM(imageContext, layer.contentsScale, -layer.contentsScale);
//        double startTime = CACurrentMediaTime();
        [layer renderInContext:imageContext];
//        NSLog(@"_lottieLayer 耗时2222:%lf",CACurrentMediaTime() - startTime);
        CGContextRelease(imageContext);
        CGColorSpaceRelease(genericRGBColorspace);
        
        return imageData;
    }
}

static Float64 factorForTimeInRange(CMTime time, CMTimeRange range) /* 0.0 -> 1.0 */
{
    
    CMTime elapsed = CMTimeSubtract(time, range.start);
    return CMTimeGetSeconds(elapsed) / CMTimeGetSeconds(range.duration);
}



- (CVPixelBufferRef)newRenderedPixelBufferForRequest:(AVAsynchronousVideoCompositionRequest *)request error:(NSError **)errOut
{
    CGSize renderSize = _renderContext.size;
    CMTime frameDuration = _renderContext.videoComposition.frameDuration;
    _renderer.fps = frameDuration.timescale;
    _renderer.videoSize = renderSize;
        
    RDVideoCompositorInstruction* instruction = request.videoCompositionInstruction;
    CVPixelBufferRef dstPixels = NULL;// = [_renderContext newPixelBuffer]; // 以dstPixel
    GLubyte* lottiePixel = NULL;
    if (instruction.lottieView) {
//        NSLog(@"compositionTime:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, request.compositionTime)));
        lottiePixel = [self getLottieBuffer:instruction.lottieView layer:instruction.lottieViewLayer time:request.compositionTime];
    }
    if (!instruction.lottieView.isBlackVideo) {
        dstPixels = [_renderContext newPixelBuffer];
    }
    _renderer.virtualVideoBgColor = instruction.virtualVideoBgColor;
    if (instruction.mvEffects.count > 0) {
        _renderer.hasMV = YES;
    }else {
        _renderer.hasMV = NO;
    }
    if (instruction.customType == RDCustomTypePassThrough && !instruction.lottieView.isBlackVideo) {
        RDScene* scene = instruction.scene;
        // 要在场景上支持Mask pass两次
        if([_renderer renderCustomPixelBuffer:dstPixels scene:scene request:request] != 1)
            *errOut = [NSError errorWithDomain:NSURLErrorDomain code:121 userInfo:@{NSLocalizedDescriptionKey:@"解码失败"}];
    }
    
    if (instruction.customType == RDCustomTypeTransition) {
       
        //
        CVPixelBufferRef previousPixels = [_renderContext newPixelBuffer];
        RDScene* previousScene = instruction.previosScene;
        if([_renderer renderCustomPixelBuffer:previousPixels scene:previousScene request:request] != 1) // 这里应该修改为帧缓存形式 不再使用newPixelBuffer
            *errOut = [NSError errorWithDomain:NSURLErrorDomain code:121 userInfo:@{NSLocalizedDescriptionKey:@"解码失败"}];
        
        
        CVPixelBufferRef nextPixels = [ _renderContext newPixelBuffer];
        RDScene* nextScene = instruction.nextScene;
        if([_renderer renderCustomPixelBuffer:nextPixels scene:nextScene request:request] != 1)
            *errOut = [NSError errorWithDomain:NSURLErrorDomain code:121 userInfo:@{NSLocalizedDescriptionKey:@"解码失败"}];
        
        
        if (previousPixels && nextPixels) {
            float tweenFactor = factorForTimeInRange(request.compositionTime, request.videoCompositionInstruction.timeRange);
            if (previousScene.transition.type == RDVideoTransitionTypeMask) {
                [_renderer renderPixelBuffer:dstPixels usingForegroundSourceBuffer:previousPixels andBackgroundSourceBuffer:nextPixels andMaskImagePath:previousScene.transition.maskURL forTweenFactor:tweenFactor];

            }
            else if(previousScene.transition.type == RDVideoTransitionTypeCustom)
            {
                [_renderer renderCustomTransitionPixelBuffer:dstPixels usingForegroundSourceBuffer:previousPixels andBackgroundSourceBuffer:nextPixels andCustomTransiton:previousScene.transition.customTransition forTweenFactor:tweenFactor];
                
            }
            else{
#if 1
               
                if(previousScene.transition.positions.count>0){
                    NSMutableArray *factors = [NSMutableArray array];
                    
                    for (int i = 0; i<previousScene.transition.positions.count; i++) {
                        float p = [previousScene.transition.positions[i] floatValue];
                        RDPostion *postion = [[RDPostion alloc] init];
                        postion.postion = p;
                        postion.atTime  = i/(float)previousScene.transition.positions.count;
                        [factors addObject:postion];
                    }
                    
                    
                    for (int i = 0; i<previousScene.transition.positions.count; i++) {
                        RDPostion *postion = factors[i];
                        if(postion.atTime>tweenFactor){
                            tweenFactor = postion.postion;
                            break;
                        }
                    }
                }
                
#endif
//                NSLog(@"tweenFactor:%f",tweenFactor);

                [_renderer renderPixelBuffer:dstPixels usingForegroundSourceBuffer:previousPixels andBackgroundSourceBuffer:nextPixels forTweenFactor:tweenFactor type:previousScene.transition.type];
            }
        }

        CVPixelBufferRelease(previousPixels);
        CVPixelBufferRelease(nextPixels);
    }
    
    if (instruction.mvEffects.count > 0) {
        
        CVPixelBufferRef tempPixel = NULL;
        for (int i = 0; i<instruction.mvEffects.count; i++) {
            VVMovieEffect* effect = instruction.mvEffects[i];
            
            
            CVPixelBufferRef mvPixels = nil;
//            if (mvUseSourceBuffer) {
//                mvPixels = _renderer.mvPixelBuffer;
//            }else {
                mvPixels = [request sourceFrameByTrackID:[effect.trackID intValue]];
//            }
            if (!mvPixels) {
                NSLog(@"no mv buffer:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, request.compositionTime)));
                break;
            }
#ifdef USERENDERFILTER
            NSDictionary *mvDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                   instruction, @"instruction",
                                   nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMV" object:(__bridge id _Nullable)(mvPixels) userInfo:mvDic];
#endif
            CVPixelBufferRef resultPixels = [_renderContext newPixelBuffer];
            if(instruction.lottieView)
            {
                if(!instruction.lottieView.isBlackVideo)
                {
                    if(0 == i)
                    {
                        if(!tempPixel)
                            tempPixel = [_renderContext newPixelBuffer];
                        [_renderer renderPixelBuffer:tempPixel usingSourceData:lottiePixel andBackgroundSourceBuffer:dstPixels];
                        [_renderer renderMVPixelBuffer:resultPixels usingSourceBuffer:tempPixel mvPixelBuffer:mvPixels Effect:effect];
                    }
                    else
                        [_renderer renderMVPixelBuffer:resultPixels usingSourceBuffer:dstPixels mvPixelBuffer:mvPixels Effect:effect];
                }
                else
                {
                    if(0 == i)
                        [_renderer renderMVPixelBuffer:resultPixels usingSourceData:lottiePixel mvPixelBuffer:mvPixels Effect:effect];
                    else
                        [_renderer renderMVPixelBuffer:resultPixels usingSourceBuffer:dstPixels mvPixelBuffer:mvPixels Effect:effect];
                }

            }
            else {
                [_renderer renderMVPixelBuffer:resultPixels usingSourceBuffer:dstPixels mvPixelBuffer:mvPixels Effect:effect];
            }
            CVPixelBufferRelease(dstPixels);
            dstPixels = resultPixels;
        }
        if(tempPixel)
            CVPixelBufferRelease(tempPixel);
    }
    if(lottiePixel) {
        free(lottiePixel);
    }

    if (instruction.customFilterArray.count > 0) {
        //自定义滤镜shader
        BOOL bRenderSuccess = false;
        BOOL isNeedLastPicture = [_renderer renderCustomFilterIsNeedLastPicture:instruction.customFilterArray];
        CVPixelBufferRef resultCustomFilterPixels = [_renderContext newPixelBuffer];
        if(!isNeedLastPicture || !pixelBufferCopy)
            bRenderSuccess = [_renderer renderCustomFilter:instruction.customFilterArray destinationPixelBuffer:resultCustomFilterPixels usingSourceBuffer:dstPixels andLastPictureBuffer:dstPixels];
        else
        bRenderSuccess = [_renderer renderCustomFilter:instruction.customFilterArray destinationPixelBuffer:resultCustomFilterPixels usingSourceBuffer:dstPixels andLastPictureBuffer:pixelBufferCopy];
        if(bRenderSuccess)
        {
            CVPixelBufferRelease(dstPixels);
            dstPixels = resultCustomFilterPixels;
        }
        else
            CVPixelBufferRelease(resultCustomFilterPixels);
        
        if(isNeedLastPicture)
        {
            //保存上一帧画面
            
            CVPixelBufferLockBaseAddress(dstPixels, 0);
            int bufferWidth      = (int)CVPixelBufferGetWidth(dstPixels);
            int bufferHeight     = (int)CVPixelBufferGetHeight(dstPixels);
            size_t bytesPerRow   = CVPixelBufferGetBytesPerRow(dstPixels);
            uint8_t *baseAddress = CVPixelBufferGetBaseAddress(dstPixels);
            
            // Copy the pixel buffer
            if(!pixelBufferCopy)
            {
                NSDictionary *pixelAttributes = [NSDictionary dictionaryWithObject:@{} forKey:(NSString *)kCVPixelBufferIOSurfacePropertiesKey];
                CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                                      bufferWidth,
                                                      bufferHeight,
                                                      kCVPixelFormatType_32BGRA,
                                                      (__bridge CFDictionaryRef)pixelAttributes,
                                                      &pixelBufferCopy);
                
                if (result != kCVReturnSuccess){
                    NSLog(@"Unable to create cvpixelbuffer %d", result);
                    return nil;
                }
            }
            CVPixelBufferLockBaseAddress(pixelBufferCopy, 0);
            uint8_t *copyBaseAddress = CVPixelBufferGetBaseAddress(pixelBufferCopy);
            memcpy(copyBaseAddress, baseAddress, bufferHeight * bytesPerRow);
            CVPixelBufferUnlockBaseAddress(pixelBufferCopy, 0);
            CVPixelBufferUnlockBaseAddress(dstPixels, 0);
        }
        
    }
    
    if (instruction.watermarks.count > 0) {
        //画中画
        CVPixelBufferRef resultPixelsCollage = [_renderContext newPixelBuffer];
        [_renderer renderCollageWithSourceBuffer:dstPixels DestinationBuffer:resultPixelsCollage scene:instruction.watermarks request:request];
        
        CVPixelBufferRelease(dstPixels);
        dstPixels = resultPixelsCollage;
        
    }
    
    
    return dstPixels;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_renderer clear];
    _renderer = nil;
    NSLog(@"%s",__func__);
}

- (void)cancelAllPendingVideoCompositionRequests{
    _shouldCancelAllRequest = YES;
    if (![notificationName isEqualToString:UIApplicationWillResignActiveNotification]) {//20180316 wuxiaoxia 修复bug:播放时按电源键有时崩溃
        dispatch_barrier_async(_renderingQueue, ^{
            _shouldCancelAllRequest = NO;
        });
    }
}
@end



