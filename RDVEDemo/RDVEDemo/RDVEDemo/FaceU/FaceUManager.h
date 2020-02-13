//
//  FaceUManager.h
//  RDVEDemo
//
//  Created by wuxiaoxia on 2019/9/06.
//  Copyright © 2019年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface FaceUManager : NSObject

/** 磨皮(0、1、2、3、4、5、6)
 */
@property (nonatomic, assign) NSInteger blurLevel;

/** 美型等级 (0~1)
 */
@property (nonatomic, assign) float faceShapeLevel;

/** 美型类型 (0、1、2、3) 女神：0，网红：1，自然：2
 */
@property (nonatomic, assign) NSInteger faceShape;

/** 美白 (0~1)
 */
@property (nonatomic, assign) float colorLevel;

/** 瘦脸 (0~1)
 */
@property (nonatomic, assign) float cheekThinning;

/** 大眼 (0~1)
 */
@property (nonatomic, assign) float eyeEnlarging;

+ (FaceUManager *)shareManager;

/**加载普通道具*/
- (void)loadItem:(NSString *)itemPath;

/**将道具绘制到pixelBuffer*/
- (void)renderItemsToPixelBuffer:(CVPixelBufferRef)pixelBuffer;

/**切换摄像头要调用此函数*/
- (void)onCameraChange;

/**销毁全部道具*/
- (void)destoryItems;
    
@end
