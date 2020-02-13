//
//  RDVideoCompositorRenderer.h
//  RDVECore
//
//  核心渲染  处理视频帧 或 生成图片帧 处理转场
//  Created by 周晓林 on 2017/5/9.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "RDScene.h"
#import "RDVideoCompositorInstruction.h"
#import "RDCustomTransition.h"

@interface RDVideoCompositorRenderer : NSObject

@property (nonatomic,assign) CGSize videoSize;
@property (nonatomic,assign) float fps;
@property (nonatomic,assign) BOOL hasMV;
@property (nonatomic,assign) CVPixelBufferRef mvPixelBuffer;
@property (nonatomic,strong) UIColor *virtualVideoBgColor;

+ (RDVideoCompositorRenderer *) sharedVideoCompositorRender;
- (void) clear;
// 多纹理绘制优化
- (void) renderMultiTextureWithScene:(RDScene *) scene
                         destination:(CVPixelBufferRef )destinationPixelBuffer
                             request:(AVAsynchronousVideoCompositionRequest *)request;

- (int) renderCustomPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer
                           scene:(RDScene *)scene
                         request:(AVAsynchronousVideoCompositionRequest *)request; //渲染核心函数

- (void) renderMVPixelBuffer:(CVPixelBufferRef) destinationPixelBuffer
           usingSourceData:(GLubyte*) sourceData
               mvPixelBuffer:(CVPixelBufferRef) mvPixelBuffer
                        Effect:(VVMovieEffect*) effect;


- (void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer usingSourceData:(GLubyte*)foregroundPixelBuffer andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer;

- (void) renderMVPixelBuffer:(CVPixelBufferRef) destinationPixelBuffer
           usingSourceBuffer:(CVPixelBufferRef) sourcePixelBuffer
               mvPixelBuffer:(CVPixelBufferRef) mvPixelBuffer
                        Effect:(VVMovieEffect*) effect;

- (void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer
usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer
andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer
           forTweenFactor:(float)tween
                     type:(unsigned int) type;


- (bool) renderCustomFilterIsNeedLastPicture:(NSMutableArray<RDCustomFilter *>*)customFilterArray;

- (bool) renderCustomFilter:(NSMutableArray<RDCustomFilter *>*)customFilterArray
     destinationPixelBuffer:(CVPixelBufferRef) destinationPixelBuffer
          usingSourceBuffer:(CVPixelBufferRef) sourcePixelBuffer
       andLastPictureBuffer:(CVPixelBufferRef)lastPictureBuffer;

- (void) renderCustomTransitionPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer
               usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer
                 andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer
                        andCustomTransiton:(RDCustomTransition*)transition
                            forTweenFactor:(float)tween;


- (void) renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer
usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer
 andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer
          andMaskImagePath:(NSURL *) path
            forTweenFactor:(float)tween;

- (bool) renderCollageWithSourceBuffer:(CVPixelBufferRef) sourcePixelBuffer
                     DestinationBuffer:(CVPixelBufferRef) destinationPixelBuffer
                     scene:(NSMutableArray *)scene
                     request:(AVAsynchronousVideoCompositionRequest *)request;



#if 0
- (void) renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer
         usingSourceBuffer:(CVPixelBufferRef)sourcePixelBuffer
                     angle:(float) angle
                   aspectR:(BOOL) aspectR
            verticalMirror:(BOOL) isVerticalMirror
          horizontalMirror:(BOOL) isHorizontalMirror;
- (void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer
        usingSourceBuffer:(CVPixelBufferRef)sourcedPixelBuffer
           forTweenFactor:(float)tween
                transform:(CGAffineTransform) t
                     crop:(CGRect) crop
                    angle:(float) angle
           verticalMirror:(BOOL) isVerticalMirror
         horizontalMirror:(BOOL) isHorizontalMirror
             completeEdge:(BOOL) isCompleteEdge;
;

- (void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer
           usingImagePath:(NSURL *)path
           forTweenFactor:(float)tween
            animationType:(int)type
                     crop:(CGRect) crop
                    angle:(float) angle
           verticalMirror:(BOOL) isVerticalMirror
         horizontalMirror:(BOOL) isHorizontalMirror
             completeEdge:(BOOL) isCompleteEdge;
#endif

@end
