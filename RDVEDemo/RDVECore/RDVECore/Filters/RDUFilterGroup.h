//
//  RDUFilterGroup.h
//  RDVECore
//
//  Created by 周晓林 on 2017/10/16.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//  常用调整融合处理滤镜

#import "RDGPUImageFilterGroup.h"

@interface RDUFilterGroup : RDGPUImageFilterGroup
@property (nonatomic, assign) CGFloat brightness; // 亮度
@property (nonatomic, assign) CGFloat exposure; // 曝光
@property (nonatomic, assign) CGFloat saturation; // 饱和度

@property (nonatomic, assign) CGFloat temperature; //色温
@property (nonatomic, assign) CGFloat tint;

@property (nonatomic, assign) CGFloat sharpness;// 锐度

@end
