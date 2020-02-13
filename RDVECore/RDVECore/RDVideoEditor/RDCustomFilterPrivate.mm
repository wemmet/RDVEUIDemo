//
//  RDCustomFilterPrivate.m
//  RDVECore
//
//  Created by apple on 2018/11/29.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDCustomFilterPrivate.h"
#import "RDMatrix.h"

#define kBitsPerComponent (8)
#define kBitsPerPixel (32)
#define kPixelChannelCount (4)//每一行的像素点占用的字节数，每个像素点的ARGB四个通道各占8个bit

#define ENABLE_ATTRIBUTE 1
#define CYCLE_TIME 2

NSString*  const kRDCustomVertexShader = SHADER_STRING
(
 
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate;
 }
 
 );
NSString *const kRDCustomFilterFragmentShader1 = SHADER_STRING
(
 
 //RDBuiltIn_freezeFrameLeftRight
 precision highp float;
 
 uniform sampler2D inputImageTexture;
 uniform float time;
 varying vec2 textureCoordinate;
 uniform float progress;
 uniform float rotateAngle;
 uniform vec2 resolution;
 
 int drawGraph(vec2 center)
{
    if(progress < 0.1 || (progress > 0.2 && progress < 0.3) || (progress > 0.4 && progress < 0.5) ||
       (progress > 0.6 && progress < 0.7) ||(progress > 0.8 && progress < 0.9))
    {
        float ratio = resolution.x/resolution.y;
        vec2 coordinate = textureCoordinate;
        
        if(ratio<1.0)
        {
            center = vec2(center.x,center.y/ratio);
            coordinate.y = coordinate.y/ratio;
        }
        else
        {
            center = vec2(center.x*ratio,center.y);
            coordinate.x = coordinate.x*ratio;
        }
        if (distance(coordinate,center)>0.03 && distance(coordinate,center)<0.05 )
            return 1;
        else
            return 0;
    }
    else
    {
        vec2 coordinate = textureCoordinate;
        vec2 size1 = (resolution.x > resolution.y ) ? vec2(0.03,resolution.x/resolution.y*0.03):vec2(resolution.y/resolution.x*0.03,0.03);
        vec2 size2 = (resolution.x > resolution.y ) ? vec2(0.015,resolution.x/resolution.y*0.015):vec2(resolution.y/resolution.x*0.015,0.015);
        float left = center.x - size1.x;
        float right = center.x + size1.x;
        float top = center.y - size1.y;
        float bottom = center.y + size1.y;
        if(coordinate.x > left && coordinate.x < right && coordinate.y > top && coordinate.y < bottom &&
           (abs(coordinate.x - center.x) > size2.x || abs(coordinate.y - center.y) > size2.y))
            return 1;
        else
            return 0;
    }

}
 
 void main()
{
    
    
    vec2 coordinate = textureCoordinate;
    float p = progress;
    vec4 outColor ;
    
    vec2 border = (resolution.x > resolution.y ) ? vec2(0.04,resolution.x/resolution.y*0.04):vec2(resolution.y/resolution.x*0.04,0.04);
    if(coordinate.x < border.x || coordinate.x > (1.0 - border.x)||
       coordinate.y < border.y || coordinate.y > (1.0 - border.y))
        outColor = vec4(1.0,1.0,1.0,1.0);
    else
    {
        if(p < 0.3)
        {
            float process = p / 0.6;
            if(coordinate.x <= (0.5 + process)  && coordinate.x >= process)
            {
                coordinate.x = (coordinate.x - process)/1.0;
                outColor = texture2D(inputImageTexture, coordinate);
            }
            else
            {
                coordinate = textureCoordinate;
                if(coordinate.x <= (1.0 - process) && coordinate.x >= (0.5 - process))
                {
                    coordinate.x = 0.5 + (coordinate.x - (0.5 - process))/1.0;
                    outColor = texture2D(inputImageTexture, coordinate);
                }
                else
                    outColor = vec4(0.0,0.0,0.0,1.0);
            }
            
        }
        else if(p < 0.6)
        {
            float process = p / 0.6 -  0.5;
            
            if(coordinate.x <= (0.5 + process)  && coordinate.x >= process)
            {
                coordinate.x = 0.5 + (coordinate.x - process)/1.0;
                outColor = texture2D(inputImageTexture, coordinate);
                
            }
            else
            {
                coordinate = textureCoordinate;
                if(coordinate.x <= (1.0 - process) && coordinate.x >= (0.5 - process))
                {
                    coordinate.x = (coordinate.x - (0.5 - process))/1.0;
                    outColor = texture2D(inputImageTexture, coordinate);
                }
                else
                    outColor = vec4(0.0,0.0,0.0,1.0);
            }
            
        }
        else
            outColor = texture2D(inputImageTexture, textureCoordinate);
    }
    
    if(drawGraph(vec2(border.x,border.y)) == 1)
        outColor = vec4(0.0,0.0,0.0,1.0);
    if(drawGraph(vec2(1.0 - border.x,border.y)) == 1)
        outColor = vec4(0.0,0.0,0.0,1.0);
    if(drawGraph(vec2(border.x,1.0 - border.y)) == 1)
        outColor = vec4(0.0,0.0,0.0,1.0);
    if(drawGraph(vec2(1.0 - border.x,1.0 - border.y)) == 1)
        outColor = vec4(0.0,0.0,0.0,1.0);
    
    gl_FragColor = outColor;
}




);
NSString *const kRDCustomFilterFragmentShader = SHADER_STRING
(

 precision highp float;
 
 uniform sampler2D inputImageTexture;
 uniform float time;
 varying vec2 textureCoordinate;
 uniform float progress;
 uniform vec2 resolution;

 
 void main()
 {
#if 0
     //模糊缩放
     highp vec2 blurCenter = vec2(0.5,0.5);
     highp float blurSize = 2.0;
     vec4 vColorRGBA = vec4(0.0,0.0,0.0,0.0);
     float process = fract(time) < 0.5 ? fract(time) : (1.0 - fract(time));
     float len = 0.1*process;
     highp vec2 samplingOffset = 1.0/100.0 * blurCenter * process * 1.5;
     vec2 coordinate = textureCoordinate;
     if(coordinate.x < 0.5)
         coordinate.x = process/0.5*0.2 + coordinate.x/0.5*(0.5-process/0.5*0.2);
     else
         coordinate.x = 0.5 + (coordinate.x - 0.5)/0.5*(0.5-process/0.5*0.2);

     vColorRGBA = texture2D(inputImageTexture, coordinate) * 0.18;
     vColorRGBA += texture2D(inputImageTexture, coordinate + samplingOffset) * 0.15;
     vColorRGBA += texture2D(inputImageTexture, coordinate + (2.0 * samplingOffset)) *  0.12;
     vColorRGBA += texture2D(inputImageTexture, coordinate + (3.0 * samplingOffset)) * 0.09;
     vColorRGBA += texture2D(inputImageTexture, coordinate + (4.0 * samplingOffset)) * 0.05;
     vColorRGBA += texture2D(inputImageTexture, coordinate - samplingOffset) * 0.15;
     vColorRGBA += texture2D(inputImageTexture, coordinate - (2.0 * samplingOffset)) *  0.12;
     vColorRGBA += texture2D(inputImageTexture, coordinate - (3.0 * samplingOffset)) * 0.09;
     vColorRGBA += texture2D(inputImageTexture, coordinate - (4.0 * samplingOffset)) * 0.05;


     if(coordinate.y < len)
         gl_FragColor = vec4(mix(vColorRGBA.rgb,vec3(0.0,0.0,0.0),(len - coordinate.y)/len),vColorRGBA.a);
     else if ((1.0 - coordinate.y) < len )
         gl_FragColor = vec4(mix(vColorRGBA.rgb,vec3(0.0,0.0,0.0),(1.0 - (1.0 - coordinate.y)/len)),vColorRGBA.a);
     else
         gl_FragColor = vColorRGBA;
     
//     窗格 - 周期：1s
//     highp vec2 blurCenter = vec2(0.5,0.5);
//     highp float blurSize = 0.6;
//     vec4 vColorRGBA = vec4(0.0,0.0,0.0,0.0);
//     float process = fract(time) ;
//     highp vec2 samplingOffset = 1.0/100.0 * blurCenter  * blurSize;
//     vec2 coordinate = textureCoordinate;
//
//
//     if(coordinate.x < process || coordinate.x > (process+0.5))
//     {
//         vColorRGBA = texture2D(inputImageTexture, coordinate) * 0.18;
//         vColorRGBA += texture2D(inputImageTexture, coordinate + samplingOffset) * 0.15;
//         vColorRGBA += texture2D(inputImageTexture, coordinate + (2.0 * samplingOffset)) *  0.12;
//         vColorRGBA += texture2D(inputImageTexture, coordinate + (3.0 * samplingOffset)) * 0.09;
//         vColorRGBA += texture2D(inputImageTexture, coordinate + (4.0 * samplingOffset)) * 0.05;
//         vColorRGBA += texture2D(inputImageTexture, coordinate - samplingOffset) * 0.15;
//         vColorRGBA += texture2D(inputImageTexture, coordinate - (2.0 * samplingOffset)) *  0.12;
//         vColorRGBA += texture2D(inputImageTexture, coordinate - (3.0 * samplingOffset)) * 0.09;
//         vColorRGBA += texture2D(inputImageTexture, coordinate - (4.0 * samplingOffset)) * 0.05;
//
//         float luminance = dot(vColorRGBA.rgb,vec3(0.2125,0.7154,0.0721));
//         gl_FragColor = vec4(vec3(luminance),vColorRGBA.a);
//     }
//     else
//     {
//         gl_FragColor = texture2D(inputImageTexture, coordinate);
//     }
#else
    
     //九屏镜像
//     vec2 coordinate = textureCoordinate;
//
//
//     float row = 3.0;       //row
//     float column = 3.0;    //column
//
//     float row_factor = 1.0/row;
//     float column_factor = 1.0/column;
//
//     float cur_row = floor(textureCoordinate.y/row_factor);
//     float cur_column = floor(textureCoordinate.x/column_factor);
//
//     if(textureCoordinate.y >= cur_row*row_factor && textureCoordinate.y < (cur_row+1.0)*row_factor)
//     {
//         coordinate.y = textureCoordinate.y-cur_row*row_factor;
//         if(cur_row == 1.0)
//             coordinate.y = coordinate.y/row_factor;
//         else
//             coordinate.y = 1.0 - coordinate.y/row_factor;
//     }
//
//     if(textureCoordinate.x >= cur_column*column_factor && textureCoordinate.x < (cur_column+1.0)*column_factor)
//     {
//         coordinate.x = textureCoordinate.x-cur_column*column_factor;
//         if(cur_column == 1.0)
//             coordinate.x = coordinate.x/column_factor;
//         else
//             coordinate.x = 1.0 - coordinate.x/column_factor;
//     }
//
//     gl_FragColor = texture2D(inputImageTexture, coordinate);

//     //弹簧
//     vec2 coordinate = textureCoordinate;
//     float factor = 0.1;
//     float process = fract(time) < 0.5 ? fract(time) : (1.0 - fract(time));
//
//     float left_x = factor * process / 0.5 * fract(time);
//     float right_x = 1.0 - left_x;
//     float top_y = factor * process / 0.5 * fract(time);
//     float bottom_y  = 1.0 - top_y;
//
//     if(coordinate.x > left_x && coordinate.x < right_x && coordinate.y > top_y && coordinate.y < bottom_y)
//     {
//         coordinate.x = (coordinate.x - left_x)/(1.0-left_x*2.0);
//         coordinate.y = (coordinate.y - top_y)/(1.0-top_y*2.0);
//
//         left_x = factor * process / 0.5 * fract(time);
//         right_x = 1.0 - left_x;
//         top_y = factor * process / 0.5 * fract(time);
//         bottom_y  = 1.0 - top_y;
//
//         if(coordinate.x > left_x && coordinate.x < right_x && coordinate.y > top_y && coordinate.y < bottom_y)
//         {
//             coordinate.x = (coordinate.x - left_x)/(1.0-left_x*2.0);
//             coordinate.y = (coordinate.y - top_y)/(1.0-top_y*2.0);
//
//             left_x = factor * process / 0.5 * fract(time);
//             right_x = 1.0 - left_x;
//             top_y = factor * process / 0.5 * fract(time);
//             bottom_y  = 1.0 - top_y;
//
//             if(coordinate.x > left_x && coordinate.x < right_x && coordinate.y > top_y && coordinate.y < bottom_y)
//             {
//                 coordinate.x = (coordinate.x - left_x)/(1.0-left_x*2.0);
//                 coordinate.y = (coordinate.y - top_y)/(1.0-top_y*2.0);
//             }
//         }
//     }
//
//     gl_FragColor = texture2D(inputImageTexture, coordinate);
     

     //多层 - 周期：3s
//     vec2 coordinate = textureCoordinate;
//
//     float process = fract(time);
//     float process_time = time;
//     while(process_time > 3.0)
//         process_time = process_time - 3.0;
//     process = process_time / 3.0;
//
//     if(process < 0.15)
//     {
//
//         float p = process/0.15;
//         float left_x = 0.5 - 0.4 * p;
//         float right_x = 1.0 - left_x;
//         float top_y = 0.5 - 0.4 * p;
//         float bottom_y  = 1.0 - top_y;
//
//         if(coordinate.x > left_x && coordinate.x < right_x && coordinate.y > top_y && coordinate.y < bottom_y)
//         {
//             coordinate.x = 1.0 - (coordinate.x - left_x)/(1.0-left_x*2.0);
//             coordinate.y = (coordinate.y - top_y)/(1.0-top_y*2.0);
//         }
//
//     }
//     else if( process <= 0.3 && process >= 0.15)
//     {
//         float p = (process - 0.15)/0.15;
//         float left_x = 0.5 - 0.3 * p;
//         float right_x = 1.0 - left_x;
//         float top_y = 0.5 - 0.3 * p;
//         float bottom_y  = 1.0 - top_y;
//
//         if(coordinate.x > left_x && coordinate.x < right_x && coordinate.y > top_y && coordinate.y < bottom_y)
//         {
//             coordinate.x = (coordinate.x - left_x)/(1.0-left_x*2.0);
//             coordinate.y = (coordinate.y - top_y)/(1.0-top_y*2.0);
//         }
//         else if(coordinate.x > 0.1 && coordinate.x < 0.9 && coordinate.y > 0.1 && coordinate.y < 0.9)
//         {
//             coordinate.x = 1.0 - (coordinate.x - 0.1)/(1.0-0.1*2.0);
//             coordinate.y = (coordinate.y - 0.1)/(1.0-0.1*2.0);
//         }
//
//
//     }
//     else if(process > 0.3 && process < 0.6)
//     {
//         float left_x = 0.2;
//         float right_x = 1.0 - left_x;
//         float top_y = 0.2;
//         float bottom_y  = 1.0 - top_y;
//         if(coordinate.x > left_x && coordinate.x < right_x && coordinate.y > top_y && coordinate.y < bottom_y)
//         {
//             coordinate.x = (coordinate.x - left_x)/(1.0-left_x*2.0);
//             coordinate.y = (coordinate.y - top_y)/(1.0-top_y*2.0);
//         }
//         else if(coordinate.x > 0.1 && coordinate.x < 0.9 && coordinate.y > 0.1 && coordinate.y < 0.9)
//         {
//             coordinate.x = 1.0 - (coordinate.x - 0.1)/(1.0-0.1*2.0);
//             coordinate.y = (coordinate.y - 0.1)/(1.0-0.1*2.0);
//         }
//
//
//     }
//     else if(process >= 0.6 && process < 0.75)
//     {
//         float p = (process - 0.6)/0.15;
//         float left_x = 0.2 + 0.3*p;
//         float right_x = 1.0 - left_x;
//         float top_y = 0.2 + 0.3*p;
//         float bottom_y  = 1.0 - top_y;
//         if(coordinate.x > left_x && coordinate.x < right_x && coordinate.y > top_y && coordinate.y < bottom_y)
//         {
//             coordinate.x = (coordinate.x - left_x)/(1.0-left_x*2.0);
//             coordinate.y = (coordinate.y - top_y)/(1.0-top_y*2.0);
//         }
//         else if(coordinate.x > 0.1 && coordinate.x < 0.9 && coordinate.y > 0.1 && coordinate.y < 0.9)
//         {
//             coordinate.x = 1.0 - (coordinate.x - 0.1)/(1.0-0.1*2.0);
//             coordinate.y = (coordinate.y - 0.1)/(1.0-0.1*2.0);
//         }
//     }
//     else
//     {
//
//         float p = (process - 0.75)/0.15;
//         float left_x = 0.1 + 0.4*p;
//         float right_x = 1.0 - left_x;
//         float top_y = 0.1 + 0.4*p;
//         float bottom_y  = 1.0 - top_y;
//         if(coordinate.x > left_x && coordinate.x < right_x && coordinate.y > top_y && coordinate.y < bottom_y)
//         {
//             coordinate.x = 1.0 - (coordinate.x - left_x)/(1.0-left_x*2.0);
//             coordinate.y = (coordinate.y - top_y)/(1.0-top_y*2.0);
//         }
//
//
//     }
//     gl_FragColor = texture2D(inputImageTexture, coordinate);
     
     
//     波浪
//     //距离系数
//     float distanceFactor = 30.0;
//     //时间系数
//     float timeFactor = -10.0;
//     //sin函数结果系数
//     float totalFactor = 3.0;
//
//     vec2 coordinate = textureCoordinate;
//     //计算uv到中间点的向量(向外扩，反过来就是向里缩)
//     vec2 dv = vec2(0.5, 0.5) - coordinate;
//     //计算像素点距中点的距离
//     float dis = sqrt(dv.x * dv.x + dv.y * dv.y);
//     //用sin函数计算出波形的偏移值factor
//     //dis在这里都是小于1的，所以我们需要乘以一个比较大的数，比如60，这样就有多个波峰波谷
//     //sin函数是（-1，1）的值域，我们希望偏移值很小，所以这里我们缩小100倍，据说乘法比较快,so...
//     float sinFactor = sin(dis * distanceFactor + time * timeFactor) * totalFactor * 0.01;
//     //归一化
//     vec2 dv1 = normalize(dv);
//     //计算每个像素uv的偏移值
//     vec2 offset = dv1  * sinFactor;
//     //像素采样时偏移offset
//     vec2 uv = offset + coordinate;
//     gl_FragColor = texture2D(inputImageTexture, uv);
     
     
     //左右定格
     vec2 coordinate = textureCoordinate;
     float process_time = time;
     while(process_time > 3.0)
         process_time = process_time - 3.0;
     float p = process_time / 3.0;
     vec4 outColor ;
     if(p < 0.3)
     {
         float process = p / 0.6;
         if(coordinate.x <= (0.5 + process)  && coordinate.x >= process)
         {
             coordinate.x = (coordinate.x - process)/1.0;
             outColor = texture2D(inputImageTexture, coordinate);
         }
         else
         {
             coordinate = textureCoordinate;
             if(coordinate.x <= (1.0 - process) && coordinate.x >= (0.5 - process))
             {
                 coordinate.x = 0.5 + (coordinate.x - (0.5 - process))/1.0;
                 outColor = texture2D(inputImageTexture, coordinate);
             }
             else
                 outColor = vec4(0.0,0.0,0.0,1.0);
         }
         
     }
     else if(p < 0.6)
     {
         float process = p / 0.6 -  0.5;
         
         if(coordinate.x <= (0.5 + process)  && coordinate.x >= process)
         {
             coordinate.x = 0.5 + (coordinate.x - process)/1.0;
             outColor = texture2D(inputImageTexture, coordinate);
             
         }
         else
         {
             coordinate = textureCoordinate;
             if(coordinate.x <= (1.0 - process) && coordinate.x >= (0.5 - process))
             {
                 coordinate.x = (coordinate.x - (0.5 - process))/1.0;
                 outColor = texture2D(inputImageTexture, coordinate);
             }
             else
                 outColor = vec4(0.0,0.0,0.0,1.0);
         }
         
     }
     else
         outColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = outColor;
//     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
//     gl_FragColor = vec4(1.0,0.0,0.0,1.0);

#endif
     
 }

);


@implementation RDCustomFilter (Private)

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
- (int ) hasSample2DMainTexture
{
    struct SHADER_TEXTURE_SAMPLER2D_LIST * pList = self.pTextureSamplerList;
    while (pList) {
        if (pList->type == RDSample2DMainTexture)
            return 1;
        pList = pList->next;
    }
    
    return 0;
}
- (NSError *) setshaderTextureParams:(RDTextureParams *)textureParams
{
    struct SHADER_TEXTURE_SAMPLER2D_LIST * pList = nullptr;
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
        self.pTextureSamplerList = (struct SHADER_TEXTURE_SAMPLER2D_LIST*)malloc(sizeof(struct SHADER_TEXTURE_SAMPLER2D_LIST));
        memset(self.pTextureSamplerList, 0, sizeof(struct SHADER_TEXTURE_SAMPLER2D_LIST));
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
        
        pList->next = (struct SHADER_TEXTURE_SAMPLER2D_LIST*)malloc(sizeof(struct SHADER_TEXTURE_SAMPLER2D_LIST));
        memset(pList->next, 0, sizeof(struct SHADER_TEXTURE_SAMPLER2D_LIST));
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
- (NSError *) setshaderUniformParams:(NSMutableArray<RDShaderParams*> *)params  TimeRepeats:(BOOL)repeat  forUniform:(NSString *)uniform
{
    NSError* error = nil;
    struct SHADER_UNIFORM_LIST* pList = nullptr;
    struct SHADER_UNIFORM_LIST* pUniformLast = nullptr;
    

    if(NULL == uniform)
    {
        error = [NSError errorWithDomain:@"invalid params" code:__LINE__ userInfo:nil];
        return error;
    }
    
    if (!self.pUniformList) {
        
        self.pUniformList = (struct SHADER_UNIFORM_LIST*)malloc(sizeof(struct SHADER_UNIFORM_LIST));
        memset(self.pUniformList, 0, sizeof(struct SHADER_UNIFORM_LIST));
        pUniformLast = self.pUniformList;
        
    }
    else
    {
        
        pList = self.pUniformList;
        while (pList && pList->next)
            pList = pList->next;
        
        pList->next = (struct SHADER_UNIFORM_LIST*)malloc(sizeof(struct SHADER_UNIFORM_LIST));
        memset(pList->next, 0, sizeof(struct SHADER_UNIFORM_LIST));
        
        pUniformLast = pList->next;
        
    }
    
    pUniformLast->name = [[NSString alloc] initWithString:uniform];
    pUniformLast->isRepeat = repeat;
    
    for (int i = 0; i<params.count; i++) {
        
        struct SHADER_PARAMS_LIST* pParamsList = nullptr;
        RDShaderParams* p = params[i];
        if (!pUniformLast->data) {
            pUniformLast->data = (struct SHADER_PARAMS_LIST*)malloc(sizeof(struct SHADER_PARAMS_LIST));
            memset(pUniformLast->data, 0, sizeof(struct SHADER_PARAMS_LIST));
            pParamsList = pUniformLast->data ;
            
        }
        else
        {
            struct SHADER_PARAMS_LIST* pLast = pUniformLast->data;
            while (pLast && pLast->next)
                pLast = pLast->next;
            
            pLast->next = (struct SHADER_PARAMS_LIST*)malloc(sizeof(struct SHADER_PARAMS_LIST));
            memset(pLast->next, 0, sizeof(struct SHADER_PARAMS_LIST));
            pParamsList = pLast->next;
        }
        
        pParamsList->time = p.time;
        pUniformLast->type = params[i].type;
//        self.pUniformList->type = params[i].type;
        if (UNIFORM_INT == pUniformLast->type)
            pParamsList->iValue = p.iValue;
        if (UNIFORM_FLOAT == pUniformLast->type)
            pParamsList->fValue = p.fValue;
        if (UNIFORM_ARRAY == pUniformLast->type)
        {
            
            if(!pParamsList->array)
                pParamsList->array = (float*)malloc(sizeof(float)*p.array.count);
            
     
            for (int j = 0; j<p.array.count; j++)
                pParamsList->array[j]= [p.array[j] floatValue];
            
            pParamsList->arrayLength = p.array.count;
        }
        if (UNIFORM_MATRIX4X4 == pUniformLast->type)
            pParamsList->matrix4 = p.matrix4;
      
        
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
    GLuint vertShader, fragShader;
    NSError* error = nil;
    self.filterProgram          = glCreateProgram();
    
    

    error = [self compileShader:&vertShader type:GL_VERTEX_SHADER source:(GLchar *)[self.vert UTF8String]];
    if(error)
        return error;
    
    self.vertShader = vertShader;
    
    error = [self compileShader:&fragShader type:GL_FRAGMENT_SHADER source:(GLchar *)[self.frag UTF8String]];
    if(error)
        return error;
    
    self.fragShader = fragShader;
    
    
    glAttachShader(self.filterProgram, vertShader);
    glAttachShader(self.filterProgram, fragShader);
    
    // Link the program.
    error = [self linkProgram:self.filterProgram];
    if (error)
    {
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        
        if (self.filterProgram) {
            glDeleteProgram(self.filterProgram);
            self.filterProgram = 0;
        }
        return error;
    }
    
    
    // Get texture shader uniform locations.
#if ENABLE_ATTRIBUTE
    self.positionAttribute             = glGetAttribLocation(self.filterProgram, "position");
    self.textureCoordinateAttribute    = glGetAttribLocation(self.filterProgram, "inputTextureCoordinate");
#endif
    self.timeUniform                   = glGetUniformLocation(self.filterProgram, "time");
    self.inputTextureUniform           = glGetUniformLocation(self.filterProgram, "inputImageTexture");
    self.resolutionUniform             = glGetUniformLocation(self.filterProgram, "resolution");
    self.progressUniform               = glGetUniformLocation(self.filterProgram, "progress");
    self.rotateAngleUniform            = glGetUniformLocation(self.filterProgram, "rotateAngle");
    self.fromUnifrom                   = glGetUniformLocation(self.filterProgram, "from");
    self.toUnifrom                     = glGetUniformLocation(self.filterProgram, "to");
    
    
    struct SHADER_UNIFORM_LIST* pShaderUniformList = self.pUniformList;
    
    while (pShaderUniformList) {
        
        pShaderUniformList->uniform = glGetUniformLocation(self.filterProgram, [pShaderUniformList->name UTF8String]);
//        if ((GLint)pShaderUniformList->uniform < 0)
//        {
//            error = [NSError errorWithDomain:@"invalid params" code:__LINE__ userInfo:nil];
//            return error;
//        }
        
        pShaderUniformList = pShaderUniformList->next;
    }
    
    
    struct SHADER_TEXTURE_SAMPLER2D_LIST * pSampler2DList = self.pTextureSamplerList;
    
    while (pSampler2DList) {
        
        pSampler2DList->uniform = glGetUniformLocation(self.filterProgram, [pSampler2DList->name UTF8String]);
//        if ((GLint)pSampler2DList->uniform < 0)
//        {
//            error = [NSError errorWithDomain:@"invalid params" code:__LINE__ userInfo:nil];
//            return error;
//        }
        pSampler2DList = pSampler2DList->next;
    }
    
    
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(self.filterProgram, vertShader);
        glDeleteShader(vertShader);
        vertShader = 0;
    }
    if (fragShader) {
        glDetachShader(self.filterProgram, fragShader);
        glDeleteShader(fragShader);
        fragShader = 0;
    }
    return nil;
}

- (struct SHADER_PARAMS_LIST* ) getShaderParams:(struct SHADER_PARAMS_LIST* )paramsList FromTime:(float)time Repeat:(BOOL)isRepeat
{
    struct SHADER_PARAMS_LIST* pList = nullptr;
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

- (int)  renderTexture:(GLuint)texture FrameWidth:(int)width FrameHeight:(int)height RotateAngle:(float)rotateAngle Time:(float)time
{
    int index = 0;
    SHADER_PARAMS_LIST* pParams = nullptr;
    
    GLfloat quadTextureData[8] = {
        
        0.0,0.0,
        1.0,0.0,
        0.0,1.0,
        1.0,1.0,
        
    };
    GLfloat quadVertexData [] = {
        
        -1.0,-1.0,
        1.0,-1.0,
        -1.0,1.0,
        1.0,1.0,
    };
    if (!self.vert) {
        self.name = nil;//不需要解密
        self.vert = kRDCustomVertexShader;
    }
#if 0
    
    self.name = nil;//不需要解密
    self.vert = kRDCustomVertexShader;
    
    self.name = nil;//不需要解密
    self.frag = kRDCustomFilterFragmentShader1;
    
    
#endif
    
    if (self.vert && self.frag) {
        //加载脚本
        if(!self.filterProgram)
        {
            if([self loadShaders])
            {
                NSLog(@"error:custom filter shader loadeShader error");
                return -__LINE__;
            }
        }
    }
    
    glUseProgram(self.filterProgram);
    
    //开启blend
    glEnable(GL_BLEND);
//    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);//2019.01.28 xcl fix bug:修正带有边框模糊的黑线问题
    
    
    if((GLint) self.fromUnifrom >= 0 && (GLint)self.toUnifrom >= 0)
    {
        //特效转场
        glActiveTexture(GL_TEXTURE0+index);
        glBindTexture(GL_TEXTURE_2D, texture);
        glUniform1i(self.fromUnifrom, index);
        index++;
        
        glActiveTexture(GL_TEXTURE0+index);
        glBindTexture(GL_TEXTURE_2D, texture);
        glUniform1i(self.toUnifrom, index);
        index++;
        
    }
    else if((GLint)self.inputTextureUniform >= 0)
    {
        glActiveTexture(GL_TEXTURE0+index);
        glBindTexture(GL_TEXTURE_2D, texture);
        glUniform1i(self.inputTextureUniform, index);
        index++;
    }
    else if([self hasSample2DMainTexture] > 0)
    {
//        NSLog(@"freezeFrame picture");
    }
    else
    {
        NSLog(@"error:custom filter shader is invalid");
        return -__LINE__;
    }
    
    if (self.pTextureSamplerList) {

       
        struct SHADER_TEXTURE_SAMPLER2D_LIST* pList = self.pTextureSamplerList;
        while (pList) {

            glActiveTexture(GL_TEXTURE0+index);
            glBindTexture(GL_TEXTURE_2D, pList->texture);
            glUniform1i(self.pTextureSamplerList->uniform, index);
            index++;

            pList = pList->next;
        }
        

    }
    
    glUniform2f(self.resolutionUniform,(float)width,(float)height);
    glUniform1f(self.timeUniform, time );
    

    float progress = 0;
    //保留三位有效数字
    int start_time = ((int)(CMTimeGetSeconds(self.timeRange.start)*1000));
    int end_time = ((int)(CMTimeGetSeconds(self.timeRange.duration)*1000)) + start_time;
    
    if(end_time - start_time <= self.cycleDuration*1000 )
        progress = (time*1000-start_time)/(end_time-start_time);
    else if(time*1000 <= end_time && time*1000 > start_time)
        progress = ((float)(time-((int)(time/self.cycleDuration))*self.cycleDuration))/(float)self.cycleDuration;

//    NSLog(@"renderTexture time : %f  start:%d end:%d progress:%f ",time,start_time,end_time,progress);
    glUniform1f(self.progressUniform, progress);
    glUniform1f(self.rotateAngleUniform, rotateAngle);
    
    //为uniform赋值
    if(self.pUniformList)
    {
        struct SHADER_UNIFORM_LIST* pList = self.pUniformList;
        
        while (pList) {
            
            if(!pList->uniform)
                pList->uniform = glGetUniformLocation(self.filterProgram, [pList->name UTF8String]);
            
            pParams = [self getShaderParams:pList->data FromTime:time Repeat:pList->isRepeat];
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
//                else if(4 == pParams->arrayLength)
//                    glUniform4f(pList->uniform,pParams->array[0],pParams->array[1],pParams->array[2],pParams->array[3]);
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
    glFlush();
    
    glDisableVertexAttribArray(self.positionAttribute);
    glDisableVertexAttribArray(self.textureCoordinateAttribute);
    
    
    return 1;
}

@end
