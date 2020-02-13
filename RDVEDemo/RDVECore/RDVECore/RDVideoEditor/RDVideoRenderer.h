//
//  RDCompositorPlayer.h
//  RDVECore
//  
//  Created by 周晓林 on 2017/2/27.
//  Copyright © 2017年 xpkCoreSdk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
//#import "RDVideoEditor.h"
#import "RDEditorObject.h"

typedef NS_ENUM(NSInteger, RenderStatus) {
    kRenderStatusUnknown,
    kRenderStatusWillChangeMedia,
    kRenderStatusReadyToPlay,
    kRenderStatusFailed
};

@class RDVideoRenderer;

@protocol RDRendererPlayerDelegate<NSObject>

@optional
- (void)statusChanged:(RenderStatus)status;

- (void)statusChanged:(RDVideoRenderer *)render statues:(RenderStatus)status;

- (void)playToEnd;

- (void)playCurrentTime:(CMTime) currentTime;

- (void)currentBufferTime:(CMTime) bufferTime;

@end

@protocol RDVideoRendererDelegate<NSObject>

@optional
- (void)willOutputPixelBuffer:(CVPixelBufferRef) pixelBuffer time:(CMTime)time;

@end

@interface RDVideoRenderer : NSObject
@property (nonatomic, strong) RDEditorObject* editor;
@property (nonatomic, weak) id<RDVideoRendererDelegate>  delegate;
@property (nonatomic, weak) id<RDRendererPlayerDelegate> playDelegate;
@property (nonatomic, assign) CMTime currentTime;
@property (nonatomic,assign)RenderStatus status;
@property (nonatomic,assign)BOOL isMute;
@property (nonatomic, assign) float playRate;
@property (nonatomic,assign) BOOL isMain;
@property (nonatomic, assign) BOOL isRefreshCurrentFrame;
- (void) prepare;
- (void) reverse:(CMTime)time;
- (void) play;
- (void) pause;
- (void) seekToTime:(CMTime)time;
- (void) seekToTime:(CMTime)time toleranceTime:(CMTime) tolerance completionHandler:(void (^)(BOOL finished))completionHandler;
- (UIImage*)getImageAtTime:(CMTime) outputTime scale:(float) scale;
- (void)getImageAtTime:(CMTime) outputTime scale:(float) scale completion:(void (^)(UIImage *image))completionHandler;
- (UIImage *)getCurrentFrameWithScale:(float) scale;
- (CMTime)playerItemDuration;
- (void)refreshCurrentFrame:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler;
- (void) clear;
@end
