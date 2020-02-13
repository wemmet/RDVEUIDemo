//
//  RDCustomTransition.h
//  RDVECore
//
//  Created by xcl on 2018/11/27.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#ifndef RDCUSTOM_TRANSITION_H
#define RDCUSTOM_TRANSITION_H


#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AVFoundation/AVFoundation.h>
#import "RDCustomShader.h"



@interface RDTranstionShaderParams : NSObject

/** uniform 变量类型（包含 int/float/ma4/array类型）
 */
@property (nonatomic ,assign) SHADER_UNIFORM_TYPE type;


/** 设置shader 中 uniform float 类型变量参数
 */
@property (nonatomic ,assign) float fValue;

/** 设置shader 中 uniform int 类型变量参数
 */
@property (nonatomic ,assign) int iValue;



/** 设置shader 中 uniform mat4 类型变量参数
 */
@property (nonatomic,assign) RDGLMatrix4x4    matrix4;

/** 设置shader 中 uniform 数组 类型变量参数
 */
@property (nonatomic,strong) NSMutableArray<NSNumber *>*array;

@end

@interface RDTranstionTextureParams : NSObject

/** 纹理类型
 */
@property (nonatomic, assign)RDTextureType type;

/** 纹理图片或者视频
 */
@property (nonatomic, copy) NSString*  path;

/** shader 纹理变量名
 */
@property (nonatomic, copy)NSString* name;


/** 纹理模式
 */
@property (nonatomic, assign)RDTextureWarpMode warpMode;

@end



@interface RDCustomTransition : NSObject

/**  自定义转场名称
 */
@property (nonatomic, copy) NSString* name;

/**  顶点着色器脚本
 */
@property (nonatomic, copy) NSString* vert;

/** 片元着色器脚本
 shader内置变量名：
 from             :前一个画面
 to               :后一个画面
 progress         :转场进度
 resolution       :视图窗口分辨率
 */
@property (nonatomic, copy) NSString* frag;



/**  设置shader中 uniform sampler2D 类型参数（纹理参数）
 */
- (NSError *) setShaderTextureParams:(RDTranstionTextureParams *)textureParams;


/**  设置shader变量参数
 *
 *  @param params       设置参数
 *  @param uniform      shader中变量的名字
 */
- (NSError *) setShaderUniformParams:(RDTranstionShaderParams *)params
                          forUniform:(NSString *)uniform;



@end

#endif /* Header_h */
