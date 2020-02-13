//
//  RDCustomTransitionPrivate.h
//  RDVECore
//
//  Created by xcl on 2018/11/29.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDGPUImageFilter.h"
#import "RDCustomTransition.h"

typedef struct SHADER_PARAM_LIST
{
    float           time;
    int             iValue;
    float           fValue;
    float*          array;
    int             arrayLength;
    RDGLMatrix4x4   matrix4;
    
    struct SHADER_PARAM_LIST* next;
    
}SHADER_PARAM_LIST;

typedef struct SHADER_UNIFORMS_LIST
{
    SHADER_UNIFORM_TYPE type;                           //uniform 变量类型
    GLuint uniform;
    NSString *name;
    BOOL isRepeat;
    
    struct SHADER_PARAM_LIST* data;    //time 对应的参数链表
    struct SHADER_UNIFORMS_LIST *next;
    
}SHADER_UNIFORMS_LIST;

typedef struct SHADER_TRANSTION_TEXTURE_SAMPLER2D_LIST
{
    GLuint uniform;
    GLuint texture;
    NSString *name;
    NSString *path;
    int type;
    int warpMode;
    struct SHADER_TRANSTION_TEXTURE_SAMPLER2D_LIST* next;
    
}SHADER_TRANSTION_TEXTURE_SAMPLER2D_LIST;

@interface RDCustomTransition (Private)

@property GLuint vertShader, fragShader;
@property GLuint program;
@property GLuint positionAttribute,textureCoordinateAttribute,timeUniform,inputTextureUniform,resolutionUniform,progressUniform;
@property struct SHADER_UNIFORMS_LIST* pUniformList;
@property struct SHADER_TRANSTION_TEXTURE_SAMPLER2D_LIST* pTextureSamplerList;
@property GLuint fromUniform,toUniform;

- (NSError *) setshaderTextureParams:(RDTranstionTextureParams *)textureParams;
- (NSError *) setshaderUniformParams:(RDTranstionShaderParams *)params forUniform:(NSString *)uniform;
- (void) renderCustromTransitionFrom:(GLuint) from To:(GLuint)to Progress:(float)progress FrameWidth:(int)width FrameHeight:(int)height;

@end
