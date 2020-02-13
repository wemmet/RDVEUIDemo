//
//  RDCustomFilterPrivate.h
//  RDVECore
//
//  Created by apple on 2018/11/29.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDGPUImageFilter.h"
#import "RDCustomFilter.h"


typedef struct SHADER_PARAMS_LIST
{
    float           time;
    int             iValue;
    float           fValue;
    float*          array;
    int             arrayLength;
    RDGLMatrix4x4   matrix4;
    
    struct SHADER_PARAMS_LIST* next;
    
}SHADER_PARAMS_LIST;

typedef struct SHADER_UNIFORM_LIST
{
    SHADER_UNIFORM_TYPE type;                           //uniform 变量类型
    GLuint uniform;
    NSString *name;
    BOOL isRepeat;
    
    struct SHADER_PARAMS_LIST* data;    //time 对应的参数链表
    struct SHADER_UNIFORM_LIST *next;
    
}SHADER_UNIFORM_LIST;


typedef struct SHADER_ATTRIBUTE_LIST
{

    GLuint uniform;
    NSString *name;
    NSData* array;
    int size;
    
    struct SHADER_ATTRIBUTE_LIST *next;
    
}SHADER_ATTRIBUTE_LIST;

typedef struct SHADER_TEXTURE_SAMPLER2D_LIST
{
    GLuint uniform;
    GLuint texture;
    NSString *name;
//    RDBuiltIn_TYPE builtInType;
    NSString *path;
    int type;
    int warpMode;
    struct SHADER_TEXTURE_SAMPLER2D_LIST* next;
    
}SHADER_TEXTURE_SAMPLER2D_LIST;


@interface RDCustomFilter (Private)

@property GLuint vertShader, fragShader;
@property GLuint filterProgram;
@property GLuint positionAttribute,textureCoordinateAttribute,timeUniform,inputTextureUniform,resolutionUniform;
@property GLuint progressUniform,rotateAngleUniform,fromUnifrom,toUnifrom;
@property struct SHADER_UNIFORM_LIST* pUniformList;
//@property struct SHADER_ATTRIBUTE_LIST* pAttributeList;
@property struct SHADER_TEXTURE_SAMPLER2D_LIST* pTextureSamplerList;

- (NSError *) setshaderTextureParams:(RDTextureParams *)textureParams;
- (NSError *) setshaderUniformParams:(NSMutableArray<RDShaderParams*> *)params TimeRepeats:(BOOL)repeat  forUniform:(NSString *)uniform;

- (int)  renderTexture:(GLuint)texture FrameWidth:(int)width FrameHeight:(int)height RotateAngle:(float)rotateAngle Time:(float)time;

@end
