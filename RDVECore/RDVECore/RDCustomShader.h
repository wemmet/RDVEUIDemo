//
//  RDCustomFilter.h
//  RDVECore
//
//  Created by xcl on 2018/11/27.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#ifndef RDCUSTOMSHADER_H
#define RDCUSTOMSHADER_H

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AVFoundation/AVFoundation.h>

struct RDGLVectore4 {
    
    float one;
    float two;
    float three;
    float four;
};
typedef struct RDGLVectore4 RDGLVectore4;



struct RDGLMatrix4x4 {
    
    RDGLVectore4 one;
    RDGLVectore4 two;
    RDGLVectore4 three;
    RDGLVectore4 four;
};
typedef struct RDGLMatrix4x4 RDGLMatrix4x4;

//纹理类型
typedef NS_ENUM(NSInteger, RDTextureType) {
    RDSample2DMainTexture,                      // 主画面纹理
    RDSample2DBufferTexture,                    // 图像数据
    
};

//纹理模式
typedef NS_ENUM(NSInteger, RDTextureWarpMode) {
    RDTextureWarpModeClampToEdge,               // 位于纹理边缘或者靠近纹理边缘的纹理单元将用于纹理计算，但不使用纹理边框上的纹理单元,默认使用该模式
    RDTextureWarpModeRepeat,                    // 纹理边界重复
    RDTextureWarpModeMirroredRepeat,            // 超出纹理范围的坐标整数部分被忽略，但当整数部分为奇数时进行取反，形成镜像效果
    
};

//uniform 变量类型
typedef NS_ENUM(NSInteger, SHADER_UNIFORM_TYPE)
{
    UNIFORM_INT,
    UNIFORM_FLOAT,
    UNIFORM_ARRAY,
    UNIFORM_MATRIX4X4,
};

//内置滤镜
typedef NS_ENUM(NSInteger, RDBuiltIn_TYPE)
{
    RDBuiltIn_None,
    RDBuiltIn_illusion,                     //幻觉
    RDBuiltIn_pencilSketch,                 //铅笔素描
    RDBuiltIn_pencilColor,                  //铅笔彩色
    RDBuiltIn_pencilLightWater,             //铅笔+淡水彩
    RDBuiltIn_pencilCharcoalSketches,       //炭笔素描
    RDBuiltIn_pencilCrayon,                 //蜡笔画
    RDBuiltIn_grayCrosspoint,               //黑白交叉
    RDBuiltIn_colorCrosspoint,              //彩色交叉
    
};



#endif /* Header_h */
