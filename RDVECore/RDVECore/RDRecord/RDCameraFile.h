//
//  RDCameraFile.h
//  RDVECore
//
//  Created by emmet on 2017/5/22.
//  Copyright © 2017年 Solaren. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "RDScene.h"

@interface RDCameraFile : NSObject
@property (nonatomic , copy) NSString  * fileName;
@property (nonatomic , copy) NSURL  * fileReversUrl;

@property (nonatomic , assign) double duration;

@property (nonatomic , assign) double speed;
@end

// 相机随拍聚焦特效
@interface RDCameraMVEffect : NSObject

// 视频资源地址
@property (nonatomic , strong) NSURL*  url;
// 混合类型
@property (nonatomic , assign) RDVideoMVEffectType type;

@end

/** 可设置画面每帧的动画
 */
@interface RDCameraCustomAnimate : NSObject

/**开始时间
 */
@property (nonatomic,assign) CGFloat atTime;


/**画面裁剪位置，默认为CGRectZero
 */
@property (nonatomic ,assign) CGRect crop;


/**动画类型
 */
@property (nonatomic,assign) AnimationInterpolationType type;


/**等比例缩放，默认1.0
 */
@property (nonatomic, assign) float scale;

@end
