//
//  RDGPUImageCameraMVEffectFilter.h
//  RDVECore
//
//  Created by xcl on 2019/5/15.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDGPUImageFilter.h"
#import "RDCameraFile.h"


@interface RDGPUImageCameraMVEffectFilter : RDGPUImageFilter


@property (nonatomic, assign) CMTime currentTime ;

/** 帧率
 */
@property (nonatomic, assign) float fps;

/** lottie画面
 */
@property (nonatomic, assign) GLubyte* lottiePixel;
/** mv
 */
@property (nonatomic, strong) NSMutableArray<RDCameraMVEffect*>* mvEffects;
/** 画面缩放
 */
@property (nonatomic, strong) NSMutableArray<RDCameraCustomAnimate*>* animate;

@end


