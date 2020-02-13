//
//  RDCustomFilterPrivate.m
//  RDVECore
//
//  Created by apple on 2018/11/29.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDCustomTransitionPrivate.h"
#import "RDMatrix.h"

#define kBitsPerComponent (8)
#define kBitsPerPixel (32)
#define kPixelChannelCount (4)//每一行的像素点占用的字节数，每个像素点的ARGB四个通道各占8个bit

#define ENABLE_ATTRIBUTE 1

NSString*  const kRDCustomVertexShader = SHADER_STRING
(
 //幻觉
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate;
 }
 
 );

@implementation RDCustomTransition (Private)

- (NSError *)compileShader:(GLuint *)shader type:(GLenum)type source:(char *)source
{
    GLint status;
//    GLenum gl_error = GL_NO_ERROR;
    NSString *strError = @"";
    NSError* error = nil;
    
    if ( !strlen(source)) {
        NSLog(@"Failed to load vertex shader: Empty source string");
        error = [NSError errorWithDomain:@"Failed to load vertex shader: Empty source string" code:__LINE__ userInfo:nil];
        return error;
    }
    *shader = glCreateShader(type);
    
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        if(log)
        {
            NSLog(@"Shader compile log:\n%s", log);
            strError = [NSString stringWithCString:log encoding:NSUTF8StringEncoding];
            free(log);
        }
        
    }
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        error = [NSError errorWithDomain:strError code:__LINE__ userInfo:nil];
        return error;
    }
    
    return nil;
}

- (NSError *)linkProgram:(GLuint)prog
{
    NSError* error = nil;
    GLint status;
    NSString* strError = @"";
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        if(log)
        {
            NSLog(@"Program link log:\n%s", log);
            strError = [NSString stringWithCString:log encoding:NSUTF8StringEncoding];
            free(log);
        }
        
    }
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        error = [NSError errorWithDomain:strError code:__LINE__ userInfo:nil];
        return error;
    }
    
    return nil;
}

- (NSError* )loadShaders
{
    GLuint vShader, fShader;
    NSError* error = nil;
    self.program          = glCreateProgram();
    
    
    error = [self compileShader:&vShader type:GL_VERTEX_SHADER source:(GLchar *)[self.vert UTF8String]];
    if(error)
        return error;
    
    self.vertShader = vShader;
    
    error = [self compileShader:&fShader type:GL_FRAGMENT_SHADER source:(GLchar *)[self.frag UTF8String]];
    if(error)
        return error;
    
    self.fragShader = fShader;
    
    
    glAttachShader(self.program, self.vertShader);
    glAttachShader(self.program, self.fragShader);
    
    // Link the program.
    error = [self linkProgram:self.program];
    if (error)
    {
        if (self.vertShader) {
            glDeleteShader(self.vertShader);
            self.vertShader = 0;
        }
        
        if (self.fragShader) {
            glDeleteShader(self.fragShader);
            self.fragShader = 0;
        }
        
        if (self.program) {
            glDeleteProgram(self.program);
            self.program = 0;
        }
        return error;
    }
    
    
    // Get texture shader uniform locations.
    
    self.positionAttribute             = glGetAttribLocation(self.program,  "position");
    self.textureCoordinateAttribute    = glGetAttribLocation(self.program,  "inputTextureCoordinate");
    self.inputTextureUniform           = glGetUniformLocation(self.program, "inputImageTexture");
    self.resolutionUniform             = glGetUniformLocation(self.program, "resolution");
    self.progressUniform               = glGetUniformLocation(self.program, "progress");
    self.fromUniform                   = glGetUniformLocation(self.program, "from");
    if ((GLint)self.fromUniform < 0)
    {
        error = [NSError errorWithDomain:@"Uniform : 'from' not found " code:__LINE__ userInfo:nil];
        return error;
    }
    
    self.toUniform                     = glGetUniformLocation(self.program, "to");
    if ((GLint)self.toUniform < 0)
    {
        error = [NSError errorWithDomain:@"Uniform : 'to' not found " code:__LINE__ userInfo:nil];
        return error;
    }
    
    
    struct SHADER_UNIFORMS_LIST* pShaderUniformList = self.pUniformList;
    
    while (pShaderUniformList) {
        
        pShaderUniformList->uniform = glGetUniformLocation(self.program, [pShaderUniformList->name UTF8String]);
        //        if ((GLint)pShaderUniformList->uniform < 0)
        //        {
        //            error = [NSError errorWithDomain:@"invalid params" code:__LINE__ userInfo:nil];
        //            return error;
        //        }
        
        pShaderUniformList = pShaderUniformList->next;
    }
    
    struct SHADER_TRANSTION_TEXTURE_SAMPLER2D_LIST * pSampler2DList = self.pTextureSamplerList;
    
    while (pSampler2DList) {
        
        pSampler2DList->uniform = glGetUniformLocation(self.program, [pSampler2DList->name UTF8String]);
        //        if ((GLint)pSampler2DList->uniform < 0)
        //        {
        //            error = [NSError errorWithDomain:@"invalid params" code:__LINE__ userInfo:nil];
        //            return error;
        //        }
        pSampler2DList = pSampler2DList->next;
    }
    
    
    // Release vertex and fragment shaders.
    if (self.vertShader) {
        glDetachShader(self.program, self.vertShader);
        glDeleteShader(self.vertShader);
    }
    if (self.fragShader) {
        glDetachShader(self.program, self.fragShader);
        glDeleteShader(self.fragShader);
    }
    return nil;
}

- (NSError *) setshaderTextureParams:(RDTranstionTextureParams *)textureParams
{
    struct SHADER_TRANSTION_TEXTURE_SAMPLER2D_LIST * pList = nullptr;
    NSError *error = nil;
    
    if(NULL == textureParams )
    {
        error = [NSError errorWithDomain:@"invalid params" code:__LINE__ userInfo:nil];
        return error;
    }
    if([textureParams.name isEqualToString: @"from"] || [textureParams.name isEqualToString: @"to"])
    {
        NSLog(@"shader : %@ is built in variables",textureParams.name);
        return nil;
    }
    
    if(!self.pTextureSamplerList)
    {
        self.pTextureSamplerList = (struct SHADER_TRANSTION_TEXTURE_SAMPLER2D_LIST*)malloc(sizeof(struct SHADER_TRANSTION_TEXTURE_SAMPLER2D_LIST));
        memset(self.pTextureSamplerList, 0, sizeof(struct SHADER_TRANSTION_TEXTURE_SAMPLER2D_LIST));
        if(textureParams.path.length > 0)
            self.pTextureSamplerList->path  = textureParams.path;
        if(textureParams.name.length > 0)
            self.pTextureSamplerList->name   = [[NSString alloc] initWithString:textureParams.name];
        else
        {
            error = [NSError errorWithDomain:@"texture name is invalid params" code:__LINE__ userInfo:nil];
            return error;
        }
        //        self.pTextureSamplerList->builtInType = textureParams.builtInType;
        self.pTextureSamplerList->type      = textureParams.type;
        self.pTextureSamplerList->warpMode  = textureParams.warpMode;
        
        
    }
    else
    {
        pList = self.pTextureSamplerList;
        while (pList && pList->next)
            pList = pList->next;
        
        pList->next = (struct SHADER_TRANSTION_TEXTURE_SAMPLER2D_LIST*)malloc(sizeof(struct SHADER_TRANSTION_TEXTURE_SAMPLER2D_LIST));
        memset(pList->next, 0, sizeof(struct SHADER_TRANSTION_TEXTURE_SAMPLER2D_LIST));
        if(textureParams.path.length > 0)
            pList->next->path  = textureParams.path;
        if(textureParams.name.length > 0)
            pList->next->name   = [[NSString alloc] initWithString:textureParams.name];
        else
        {
            error = [NSError errorWithDomain:@"texture name is invalid params" code:__LINE__ userInfo:nil];
            return error;
        }
        //        pList->next->builtInType = textureParams.builtInType;
        pList->next->type       = textureParams.type;
        pList->next->warpMode   = textureParams.warpMode;
    }
    return NULL;
}
- (NSError *) setshaderUniformParams:(RDTranstionShaderParams *)params forUniform:(NSString *)uniform
{
    NSError* error = nil;
    struct SHADER_UNIFORMS_LIST* pList = nullptr;
    struct SHADER_UNIFORMS_LIST* pUniformLast = nullptr;
    
    if(NULL == uniform)
    {
        error = [NSError errorWithDomain:@"invalid params" code:__LINE__ userInfo:nil];
        return error;
    }

    
    if (!self.pUniformList) {
        
        self.pUniformList = (struct SHADER_UNIFORMS_LIST*)malloc(sizeof(struct SHADER_UNIFORMS_LIST));
        memset(self.pUniformList, 0, sizeof(struct SHADER_UNIFORMS_LIST));
        pUniformLast = self.pUniformList;
        
    }
    else
    {
        
        pList = self.pUniformList;
        while (pList && pList->next)
            pList = pList->next;
        
        pList->next = (struct SHADER_UNIFORMS_LIST*)malloc(sizeof(struct SHADER_UNIFORMS_LIST));
        memset(pList->next, 0, sizeof(struct SHADER_UNIFORMS_LIST));
        
        pUniformLast = pList->next;
        
    }
    
    pUniformLast->name = [[NSString alloc] initWithString:uniform];
    
    struct SHADER_PARAM_LIST* pParamsList = nullptr;
    if (!pUniformLast->data) {
        pUniformLast->data = (struct SHADER_PARAM_LIST*)malloc(sizeof(struct SHADER_PARAM_LIST));
        memset(pUniformLast->data, 0, sizeof(struct SHADER_PARAM_LIST));
        pParamsList = pUniformLast->data ;
        
    }
    else
    {
        struct SHADER_PARAM_LIST* pLast = pUniformLast->data;
        while (pLast && pLast->next)
            pLast = pLast->next;
        
        pLast->next = (struct SHADER_PARAM_LIST*)malloc(sizeof(struct SHADER_PARAM_LIST));
        memset(pLast->next, 0, sizeof(struct SHADER_PARAM_LIST));
        pParamsList = pLast->next;
    }
    
    
    pUniformLast->type = params.type;

    if (UNIFORM_INT == pUniformLast->type)
        pParamsList->iValue = params.iValue;
    if (UNIFORM_FLOAT == pUniformLast->type)
        pParamsList->fValue = params.fValue;
    if (UNIFORM_ARRAY == pUniformLast->type)
    {
        
        if(!pParamsList->array)
            pParamsList->array = (float*)malloc(sizeof(float)*params.array.count);
        
        
        for (int j = 0; j<params.array.count; j++)
            pParamsList->array[j]= [params.array[j] floatValue];
        
        pParamsList->arrayLength = params.array.count;
    }
    if (UNIFORM_MATRIX4X4 == pUniformLast->type)
        pParamsList->matrix4 = params.matrix4;
    
    return nil;
}

- (struct SHADER_PARAM_LIST* ) getShaderParams:(struct SHADER_PARAM_LIST* )paramsList FromTime:(float)time Repeat:(BOOL)isRepeat
{
    struct SHADER_PARAM_LIST* pList = nullptr;
    float maxTime = 0;
    if (!paramsList)
        return nullptr;
    
    pList = paramsList;
    while (pList && pList->next)
        pList = pList->next;
    maxTime = pList->time;
    
    pList = paramsList;
    while (pList) {
        
        //保留三位有效数字，计算精确度
        int paramTime = (int)(pList->time*1000) ;
        int curTime = (int)(time*1000) ;
        if (isRepeat) {
            int cyc = ((int)(maxTime*1000));
            curTime = curTime - curTime/cyc*cyc;
        }
        else
        {
            if(!pList->next)
                break;
        }
        
        if (fabs(paramTime - curTime )<5 )
            break;
        pList = pList->next;
    }
    return pList;
}



- (void) renderCustromTransitionFrom:(GLuint)from To:(GLuint)to Progress:(float)progress FrameWidth:(int)width FrameHeight:(int)height
{
    
    SHADER_PARAM_LIST* pParams = nullptr;
    
    GLfloat quadTextureData[8] = {
        
//        0.0,0.0,
//        1.0,0.0,
//        0.0,1.0,
//        1.0,1.0,
        0.0,1.0,
        1.0,1.0,
        0.0,0.0,
        1.0,0.0,
    };
    GLfloat quadVertexData [] = {
        
        
        -1.0,1.0,
        1.0,1.0,
        -1.0,-1.0,
        1.0,-1.0,
    };
    
    if (!self.vert) {
        self.name = nil;//不需要解密
        self.vert = kRDCustomVertexShader;
    }
    if (self.vert && self.frag) {
        //加载脚本
        if(!self.program)
        {
            if([self loadShaders])
            {
                NSLog(@" RDCustomFilter loadeShader error");
                return ;
            }
        }
    }
    
    glUseProgram(self.program);
    
    //开启blend
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
//  glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, from);
    glUniform1i(self.fromUniform, 0);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, to);
    glUniform1i(self.toUniform, 1);
    
    if (self.pTextureSamplerList) {

        int index = 0;
        struct SHADER_TRANSTION_TEXTURE_SAMPLER2D_LIST* pList = self.pTextureSamplerList;
        while (pList) {

            glActiveTexture(GL_TEXTURE2+index);
            glBindTexture(GL_TEXTURE_2D, pList->texture);
            glUniform1i(self.pTextureSamplerList->uniform, 2+index);
            index++;

            pList = pList->next;
        }

    }
    
    glUniform2f(self.resolutionUniform,width,height);
    glUniform1f(self.progressUniform, progress);
    
    
    //为uniform赋值
    if(self.pUniformList)
    {
        struct SHADER_UNIFORMS_LIST* pList = self.pUniformList;
        
        while (pList) {
            
            if(!pList->uniform)
                pList->uniform = glGetUniformLocation(self.program, [pList->name UTF8String]);
            
            pParams = [self getShaderParams:pList->data FromTime:0.0 Repeat:pList->isRepeat];
            if(!pParams)
            {
                NSLog(@"error : get shader params error ");
                pList = pList->next;
                continue;
            }
            
            if (UNIFORM_INT == pList->type)
                glUniform1i(pList->uniform, pParams->iValue);
            
            if (UNIFORM_FLOAT == pList->type)
                glUniform1f(pList->uniform, pParams->fValue);
            
            if (UNIFORM_MATRIX4X4 == pList->type)
                glUniformMatrix4fv(pList->uniform, 1, GL_FALSE, (GLfloat*)&pParams->matrix4);
            
            if (UNIFORM_ARRAY == pList->type)
            {
                if(2 == pParams->arrayLength)
                    glUniform2f(pList->uniform,pParams->array[0],pParams->array[1]);
                else if(3 == pParams->arrayLength)
                    glUniform3f(pList->uniform,pParams->array[0],pParams->array[1],pParams->array[2]);
                else
                    glUniform1fv(pList->uniform, pParams->arrayLength, pParams->array );
                
            }
          
            
            pList = pList->next;
        }
    }
    glVertexAttribPointer(self.positionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData);
    glEnableVertexAttribArray(self.positionAttribute);
    
    glVertexAttribPointer(self.textureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
    glEnableVertexAttribArray(self.textureCoordinateAttribute);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDisableVertexAttribArray(self.positionAttribute);
    glDisableVertexAttribArray(self.textureCoordinateAttribute);
    
    
    return ;
}

@end

