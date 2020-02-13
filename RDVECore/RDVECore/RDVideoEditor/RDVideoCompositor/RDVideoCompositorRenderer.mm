//
//  RDOpenGLRender.m
//  RDVECore
//  Created by 周晓林 on 2016/12/29.
//  Copyright © 2016年 xpkCoreSdk. All rights reserved.
//
/*
 
 
 */
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <Photos/Photos.h>
#import "RDVideoCompositorRenderer.h"
#import "RDImage.h"
#import "RDGLProgram.h"
#import "RDGPUImageOutput.h"
#import "RDMatrix.h"
#import "RDACVTexture.h"
//#import "RDParticleRender.h"
//#import "RDDrawElement.h"
#import "RDCustomFilterPrivate.h"
#import "RDCustomTransitionPrivate.h"
#import "RDRecordHelper.h"
#import <mach/mach.h>
#import "RDBlendFilter.h"
#import "CleanBackground.h"


#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)
#include <map>

#define MAX_NUMBER 20
#define PARTICLE_DEMO 0
#define MAX_SCALE_SIZE (1080.0)
#define MAX_WIDTH 720.0

#define COLLAGE_ASSEST_INDEX 500 //画中画媒体的索引起始值



//MARK:Shader
//MARK:非矩形
typedef int (*GetInterpolationHandlerFn) (float* percent);

NSString*  const kRDCompositorVertexShader = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;
 attribute vec2 inputTextureMaskCoordinate;
 attribute vec2 inputTextureMosaicCoordinate;
 
 uniform mat4 projection;
 uniform mat4 renderTransform;
 varying vec2 textureCoordinate;
 varying vec2 textureMaskCoordinate;
 varying vec2 textureMosaicCoordinate;
 
 uniform vec2  SrcQuadrilateral[4];  //源四边形的4个顶点在源纹理上的坐标-纹理的裁剪，顺时针0-1，左上角为0.0
 uniform vec2  DstQuadrilateral[4];  //目标四边形的4个顶点在渲染结果(纹理)中的坐标-纹理的显示位置，顺时针0-1，左上角为0.0
 
 
 varying mat3    vMatrixWarp;
 varying vec2    vQuadLine[4];
 varying vec2    vQuadDstPts[4];
 
 
 mat3 getMat( vec2 quad[4] )
{
    vec2    d3  = quad[0] + quad[3] - quad[1] - quad[2];
    if ( d3.x == 0.0 && d3.y == 0.0 )
    {
        return mat3( vec3( quad[1] - quad[0], 0.0 ),
                    vec3( quad[3] - quad[1], 0.0 ),
                    vec3( quad[0], 1.0 ) );
    }
    else
    {
        vec2    d1  = quad[1] - quad[3];
        vec2    d2  = quad[2] - quad[3];
        float   den = d1.x * d2.y - d2.x * d1.y;
        vec2    d   = vec2( d2.y * d3.x - d2.x * d3.y, d1.x * d3.y - d1.y * d3.x ) / den;
        return mat3( vec3( quad[1] - quad[0] + d.x * quad[1], d.x ),
                    vec3( quad[2] - quad[0] + d.y * quad[2], d.y ),
                    vec3(quad[0], 1.0) );
    }
}
 
 mat3 quadMat()
{
    vec2    a;
    vec2    b;
    vec2    c;
    vec2    d;
    vec2    p1;
    vec2    p2;
    int     greater = 0;
    int     gang    = -1;
    int     sang    = -1;
    for ( int i = 0; i < 4; ++i )
    {
        vQuadDstPts[i] = DstQuadrilateral[i];
        a = DstQuadrilateral[i];
        b = DstQuadrilateral[( i + 2 ) - ( i + 2 ) / 4 * 4];
        c = DstQuadrilateral[( i - 1 + 4 ) - ( i - 1 + 4 ) / 4 * 4];
        d = DstQuadrilateral[( i + 1 ) - ( i + 1 ) / 4 * 4];
        
        p1 = d - c;
        p2 = a - c;
        if ( p1.x * p2.y - p2.x * p1.y >= 0.0 )
        {
            greater ++;
            gang = i;
        }
        else
        {
            sang = i;
        }
    }
    if ( greater >= 3 ) gang = sang;
    for ( int i = 0; i < 4; ++i )
    {
        if ( gang != i ) continue;
        a = DstQuadrilateral[i];
        b = DstQuadrilateral[( i + 2 ) - ( i + 2 ) / 4 * 4];
        c = DstQuadrilateral[( i - 1 + 4 ) - ( i - 1 + 4 ) / 4 * 4];
        d = DstQuadrilateral[( i + 1 ) - ( i + 1 ) / 4 * 4];
        float den = (b.y - a.y)*(d.x - c.x) - (a.x - b.x)*(c.y - d.y);
        if ( den != 0.0 )   //把凹角镜像，之后才能计算出正确的投影。
        {
            p1.x  = ( (b.x - a.x) * (d.x - c.x) * (c.y - a.y)
                     + (b.y - a.y) * (d.x - c.x) * a.x
                     - (d.y - c.y) * (b.x - a.x) * c.x ) / den;
            p1.y  = -( (b.y - a.y) * (d.y - c.y) * (c.x - a.x)
                      + (b.x - a.x) * (d.y - c.y) * a.y
                      - (d.x - c.x) * (b.y - a.y) * c.y ) / den;
            vQuadDstPts[i] = p1 + p1 - a;
        }
    }
    //先计算投影，之后把凹消除掉，绘制去掉它后剩下的三角形。
    //可以想象为凹角是由于一张纸的一个角被折叠到背面了，所以只能看到一个三角形。
    mat3 q2s   = getMat(vQuadDstPts);
    
    if ( greater <= 1 )  //逆时针序检查到大于等于180度的角只有0个或一个
    {
        if ( greater == 1 )     //有一个凹角
        {
            for ( int i = 0; i < 4; ++i )
            {
                if ( i >= gang ) vQuadDstPts[i]  = vQuadDstPts[(i + 1) - (i + 1) / 4 * 4];
            }
        }
    }
    else    //顺时针的点序列
    {
        p1  = vQuadDstPts[3];
        vQuadDstPts[3]  = vQuadDstPts[1];
        vQuadDstPts[1]  = p1;
        if ( greater == 3 )     //有一个凹角
        {
            if ( gang == 1 ) gang = 3; else if ( gang == 3 ) gang = 1;
            for ( int i = 0; i < 4; ++i )
            {
                if ( i >= gang ) vQuadDstPts[i]  = vQuadDstPts[(i + 1) - (i + 1) / 4 * 4];
            }
        }
    }
    
    vQuadLine[0] = vQuadDstPts[1] - vQuadDstPts[0];
    vQuadLine[1] = vQuadDstPts[2] - vQuadDstPts[1];
    vQuadLine[2] = vQuadDstPts[3] - vQuadDstPts[2];
    vQuadLine[3] = vQuadDstPts[0] - vQuadDstPts[3];
    
    q2s = mat3( q2s[1][1] * q2s[2][2] - q2s[1][2] * q2s[2][1],
               q2s[0][2] * q2s[2][1] - q2s[0][1] * q2s[2][2],
               q2s[0][1] * q2s[1][2] - q2s[0][2] * q2s[1][1],
               
               q2s[1][2] * q2s[2][0] - q2s[1][0] * q2s[2][2],
               q2s[0][0] * q2s[2][2] - q2s[0][2] * q2s[2][0],
               q2s[0][2] * q2s[1][0] - q2s[0][0] * q2s[1][2],
               
               q2s[1][0] * q2s[2][1] - q2s[1][1] * q2s[2][0],
               q2s[0][1] * q2s[2][0] - q2s[0][0] * q2s[2][1],
               q2s[0][0] * q2s[1][1] - q2s[0][1] * q2s[1][0] );
    
    mat3 s2q   = getMat(SrcQuadrilateral);
    return mat3( s2q[0] * q2s[0][0] + s2q[1] * q2s[0][1] + s2q[2] * q2s[0][2],
                s2q[0] * q2s[1][0] + s2q[1] * q2s[1][1] + s2q[2] * q2s[1][2],
                s2q[0] * q2s[2][0] + s2q[1] * q2s[2][1] + s2q[2] * q2s[2][2] );
}
 
 void main()
 {
     gl_Position = projection * renderTransform * position;
     textureCoordinate = inputTextureCoordinate;
     textureMaskCoordinate = inputTextureMaskCoordinate;
     textureMosaicCoordinate = inputTextureMosaicCoordinate;
     
     vMatrixWarp = quadMat();
 }
 );




#define eq(x,y) (1.0-abs(sign(x-y)))

NSString* const kRDCompositorTransFragmentShader = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 void main(){
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
 );
NSString* const kRDCompositorFragmentShader = SHADER_STRING
(
 precision highp float;
 
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 
 uniform vec4 filter;
 uniform float filterIntensity;
 const vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
 
 uniform sampler2D inputImageTexture2; // acv 滤镜
 uniform float inputTexture2Type;
 
 uniform sampler2D inputImageTexture3;
 varying vec2 textureMaskCoordinate;
 varying vec2 textureMosaicCoordinate;
 uniform float inputMaskURL;//区分是不是mask
 
 uniform float inputAlpha;
 
 
 
 uniform highp vec2  SrcQuadrilateral[4];  //源四边形的4个顶点在源纹理上的坐标-纹理的裁剪，顺时针0-1，左上角为0.0
 uniform highp vec2  DstQuadrilateral[4];  //目标四边形的4个顶点在渲染结果(纹理)中的坐标-纹理的显示位置，顺时针0-1，左上角为0.0
 
 varying mat3  vMatrixWarp;
 varying vec2  vQuadLine[4];
 varying vec2  vQuadDstPts[4];
 uniform vec2  DstSinglePixelSize; //单个像素在目标纹理中的大小。例如目标纹理将被渲染为 800*600 的矩形，那么单个像素就是 1/800, 1/600
 uniform float rotateAngle;
 uniform float blurIntensity;
 uniform float isBlurredBorder;
 uniform vec2  cropOrigin;
 uniform vec2  cropSize;
 uniform float vignette;           //0.0 ~ 1.0  (0.0为正常图像)
 uniform float sharpness;          //-4.0~4.0   (0.0为正常图像)
 uniform float whiteBalance;       //-1~1.0    （0.0为正常图像）
 
 float inQuad( vec2 line, vec2 dstPt )
{
    float ret = 0.5;
    
    vec2 pt = textureCoordinate - dstPt;
    if ( abs(line.x) > abs(line.y))
    {
        ret = 0.5 - ( line.x > 0.0 ? pt.y - pt.x * line.y / line.x : pt.x * line.y / line.x - pt.y ) / DstSinglePixelSize.y;
    }
    else
    {
        ret = 0.5 - ( line.y > 0.0 ? pt.y * line.x / line.y - pt.x : pt.x - pt.y * line.x / line.y ) / DstSinglePixelSize.x;
    }
    return ret < 0.0 ? 0.0 : ret;
}
 
 float inQuad()
{
    float inside = 1.0;
    inside  -= inQuad( vQuadDstPts[1] - vQuadDstPts[0], vQuadDstPts[0] );
    if ( inside <= 0.0 ) return 0.0;
    inside  -= inQuad( vQuadDstPts[2] - vQuadDstPts[1], vQuadDstPts[1] );
    if ( inside <= 0.0 ) return 0.0;
    inside  -= inQuad( vQuadDstPts[3] - vQuadDstPts[2], vQuadDstPts[2] );
    if ( inside <= 0.0 ) return 0.0;
    inside  -= inQuad( vQuadDstPts[0] - vQuadDstPts[3], vQuadDstPts[3] );
    return inside;
}
 
 vec4 blur9(sampler2D image, vec2 uv, vec2 resolution, vec2 direction)
{
    vec4 color = vec4(0.0);
    vec2 off1 = vec2(1.3846153846) * direction;
    vec2 off2 = vec2(3.2307692308) * direction;
    color += texture2D(image, uv) * 0.2270270270;
    color += texture2D(image, uv + (off1 / resolution)) * 0.3162162162;
    color += texture2D(image, uv - (off1 / resolution)) * 0.3162162162;
    color += texture2D(image, uv + (off2 / resolution)) * 0.0702702703;
    color += texture2D(image, uv - (off2 / resolution)) * 0.0702702703;
    return color;
}
 vec4 blur(sampler2D inputTexture,vec2 inputCoor)
 {
     
     float dis = 4.0*blurIntensity;
     vec2 u_TextureCoordOffset[25];
     u_TextureCoordOffset[0] = vec2(-2. * dis,2. * dis);
     u_TextureCoordOffset[1] = vec2(-1. * dis,2. * dis);
     u_TextureCoordOffset[2] = vec2(0. * dis,2. * dis);
     u_TextureCoordOffset[3] = vec2(1. * dis,2. * dis);
     u_TextureCoordOffset[4] = vec2(2. * dis,2. * dis);
     u_TextureCoordOffset[5] = vec2(-2. * dis,1. * dis);
     u_TextureCoordOffset[6] = vec2(-1. * dis,1. * dis);
     u_TextureCoordOffset[7] = vec2(0. * dis,1. * dis);
     u_TextureCoordOffset[8] = vec2(1. * dis,1. * dis);
     u_TextureCoordOffset[9] = vec2(2. * dis,1. * dis);
     u_TextureCoordOffset[10] = vec2(-2. * dis,0. * dis);
     u_TextureCoordOffset[11] = vec2(-1. * dis,0. * dis);
     u_TextureCoordOffset[12] = vec2(0. * dis,0. * dis);
     u_TextureCoordOffset[13] = vec2(1. * dis,0. * dis);
     u_TextureCoordOffset[14] = vec2(2. * dis,0. * dis);
     
     
     u_TextureCoordOffset[15] = vec2(-2. * dis,-1. * dis);
     u_TextureCoordOffset[16] = vec2(-1. * dis,-1. * dis);
     u_TextureCoordOffset[17] = vec2(0. * dis,-1. * dis);
     u_TextureCoordOffset[18] = vec2(1. * dis,-1. * dis);
     u_TextureCoordOffset[19] = vec2(2. * dis,-1. * dis);
     
     u_TextureCoordOffset[20] = vec2(-2. * dis,-2. * dis);
     u_TextureCoordOffset[21] = vec2(-1. * dis,-2. * dis);
     u_TextureCoordOffset[22] = vec2(0. * dis,-2. * dis);
     u_TextureCoordOffset[23] = vec2(1. * dis,-2. * dis);
     u_TextureCoordOffset[24] = vec2(2. * dis,-2. * dis);
     
     
     
     vec4 sample[25];
     for (int i = 0; i < 25; i++)
     {
         sample[i] = texture2D(inputImageTexture, textureCoordinate.st + u_TextureCoordOffset[i]/512.0);
     }
     
     vec4 c = (
               (1.0  * (sample[0] + sample[4]  + sample[20] + sample[24])) +
               (4.0  * (sample[1] + sample[3]  + sample[5]  + sample[9] + sample[15] + sample[19] + sample[21] + sample[23])) +
               (7.0  * (sample[2] + sample[10] + sample[14] + sample[22])) +
               (16.0 * (sample[6] + sample[8]  + sample[16] + sample[18])) +
               (26.0 * (sample[7] + sample[11] + sample[13] + sample[17])) +
               (41.0 * sample[12])
               ) / 273.0;
     
     
     
     return c;
 }
 vec4 ConverCoordinate(sampler2D inputTexture,vec2 inputCoor)
 {
     float inside = inQuad();
     
     if ( inside > 0.0 )
     {
         
         vec2  vTextueCoords = inputCoor;
         float den   = vMatrixWarp[0][2] * vTextueCoords.x + vMatrixWarp[1][2] * vTextueCoords.y + vMatrixWarp[2][2];
         float x     = ( vMatrixWarp[0][0] * vTextueCoords.x + vMatrixWarp[1][0] * vTextueCoords.y + vMatrixWarp[2][0] ) / den;
         float y     = ( vMatrixWarp[0][1] * vTextueCoords.x + vMatrixWarp[1][1] * vTextueCoords.y + vMatrixWarp[2][1] ) / den;
         vec4 outColor;
         
         outColor  = vec4( texture2D(inputTexture, vec2(x,y) ) );
         
         //         outColor  = vec4( texture2D(inputTexture, vec2(x,y) ) );
         outColor.a  *= inside;//=inside; //20180801 fix bug:png的alpha通道不起作用
         
         return outColor;
         
     }
     else
     {
         discard;
     }
     
 }
 
 
 void main(){
     float brightness = filter.x;   //亮度
     float contrast = filter.y;     //对比度
     float saturation = filter.z;   //饱和度
     float opacity = filter.a;      //alpha
     vec4  textureColor;
     
     vec2 realSize = vec2(476.,852.);
     float ratio = (realSize.x > realSize.y) ?
     realSize.y/realSize.x : realSize.x/realSize.y;
     
     textureColor = ConverCoordinate(inputImageTexture,textureCoordinate);//优化锯齿
     
     
     textureColor = vec4((textureColor.rgb + vec3(brightness)), textureColor.w); // 亮度叠加
     textureColor = vec4(((textureColor.rgb - vec3(0.5)) * contrast + vec3(0.5)), textureColor.w); // 对比度叠加
     
     float luminance = dot(textureColor.rgb, luminanceWeighting);
     vec3 greyScaleColor= vec3(luminance);
     
     textureColor = vec4(mix(greyScaleColor, textureColor.rgb, saturation), textureColor.w); //饱和度
     
     
     if(vignette > 0.0)
     {
         //暗角
         float vignetteValue = 1.0 - (1.0-0.75)*vignette;
         float d = distance(textureCoordinate,vec2(0.5,0.5));
         float percent = smoothstep(0.5,vignetteValue,d);
         textureColor = vec4(mix(textureColor.rgb,vec3(0.0,0.0,0.0),percent),textureColor.a);
     }
     if(sharpness >= -4.0 && sharpness <= 4.0)
     {
         //锐化
         
         vec2 widthStep = vec2(DstSinglePixelSize.x, 0.0);
         vec2 heightStep = vec2(0.0, DstSinglePixelSize.y);
         
         vec2 inputTextureCoordinate = textureCoordinate;
         vec2 leftTextureCoordinate = inputTextureCoordinate.xy - widthStep;
         vec2 rightTextureCoordinate = inputTextureCoordinate.xy + widthStep;
         vec2 topTextureCoordinate = inputTextureCoordinate.xy + heightStep;
         vec2 bottomTextureCoordinate = inputTextureCoordinate.xy - heightStep;
         
         float centerMultiplier = 1.0 + 4.0 * sharpness;
         float edgeMultiplier = sharpness;
         
         //         mediump vec3 textureColor = texture2D(inputImageTexture, textureCoordinate).rgb;
         vec4 leftTextureColor = texture2D(inputImageTexture, leftTextureCoordinate);
         vec4 rightTextureColor = texture2D(inputImageTexture, rightTextureCoordinate);
         vec4 topTextureColor = texture2D(inputImageTexture, topTextureCoordinate);
         vec4 bottomTextureColor = texture2D(inputImageTexture, bottomTextureCoordinate);
         
         vec4 v1 = textureColor * centerMultiplier;
         vec4 v2 = leftTextureColor * edgeMultiplier;
         vec4 v3 = rightTextureColor * edgeMultiplier;
         vec4 v4 = topTextureColor * edgeMultiplier;
         vec4 v5 = bottomTextureColor * edgeMultiplier;
         textureColor = v1 - v2 - v3 - v4 -v5;
         
     }
     if(whiteBalance >= -1.0 && whiteBalance <= 1.0)
     {
         //色温
         
         float tint = 0.0;
         const lowp vec3 warmFilter = vec3(0.93, 0.54, 0.0);
         const mediump mat3 RGBtoYIQ = mat3(0.299, 0.587, 0.114, 0.596, -0.274, -0.322, 0.212, -0.523, 0.311);
         const mediump mat3 YIQtoRGB = mat3(1.0, 0.956, 0.621, 1.0, -0.272, -0.647, 1.0, -1.105, 1.702);
         mediump vec3 yiq = RGBtoYIQ * textureColor.rgb; //adjusting tint
         yiq.b = clamp(yiq.b + tint*0.5226*0.1, -0.5226, 0.5226);
         lowp vec3 rgb = YIQtoRGB * yiq;
         
         lowp vec3 processed = vec3(
                                    (rgb.r < 0.5 ? (2.0 * rgb.r * warmFilter.r) : (1.0 - 2.0 * (1.0 - rgb.r) * (1.0 - warmFilter.r))), //adjusting whiteBalance
                                    (rgb.g < 0.5 ? (2.0 * rgb.g * warmFilter.g) : (1.0 - 2.0 * (1.0 - rgb.g) * (1.0 - warmFilter.g))),
                                    (rgb.b < 0.5 ? (2.0 * rgb.b * warmFilter.b) : (1.0 - 2.0 * (1.0 - rgb.b) * (1.0 - warmFilter.b))));
         
         textureColor = vec4(mix(rgb, processed, whiteBalance), textureColor.a);
     }
     
     
     if(eq(inputTexture2Type,1.0) > 0.5){//acv
#if 0   //20180801 fix bug:上面outColor.a改了后，ipad4黑屏
         float redCurveValue   = ConverCoordinate(inputImageTexture2, vec2(textureColor.r, 0.0)).r;
         float greenCurveValue = ConverCoordinate(inputImageTexture2, vec2(textureColor.g, 0.0)).g;
         float blueCurveValue  = ConverCoordinate(inputImageTexture2, vec2(textureColor.b, 0.0)).b;
#else
         float redCurveValue   = texture2D(inputImageTexture2, vec2(textureColor.r, 0.0)).r;
         float greenCurveValue = texture2D(inputImageTexture2, vec2(textureColor.g, 0.0)).g;
         float blueCurveValue  = texture2D(inputImageTexture2, vec2(textureColor.b, 0.0)).b;
#endif
         textureColor = vec4(redCurveValue, greenCurveValue, blueCurveValue, textureColor.a);
     }
     
     if(eq(inputTexture2Type,2.0) > 0.5){ // lookup
         float blueColor = textureColor.b * 63.0;
         
         vec2 quad1;
         quad1.y = floor(floor(blueColor) / 8.0);
         quad1.x = floor(blueColor) - (quad1.y * 8.0);
         
         vec2 quad2;
         quad2.y = floor(ceil(blueColor) / 8.0);
         quad2.x = ceil(blueColor) - (quad2.y * 8.0);
         
         vec2 texPos1;
         texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
         texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
         
         vec2 texPos2;
         texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
         texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
         
         vec4 newColor1 = texture2D(inputImageTexture2, texPos1);
         vec4 newColor2 = texture2D(inputImageTexture2, texPos2);
         
         vec4 newColor = mix(newColor1, newColor2, fract(blueColor));
         textureColor = mix(textureColor, vec4(newColor.rgb, textureColor.w), filterIntensity);
     }
     
     
     if(1.0 == inputMaskURL)
     {
         vec4 textureColor3 = texture2D(inputImageTexture3, textureMaskCoordinate);
         lowp float newAlpha = dot(textureColor3.rgb,vec3(0.333333334,0.333333334,0.333333334)) *textureColor3.a;
         gl_FragColor = vec4(textureColor.xyz,newAlpha*opacity);
     }
     else {
         textureColor.a = textureColor.a*inputAlpha*opacity;
         
         if(isBlurredBorder>0.0)
         {
             float borderSize = 0.03;//羽化边框size
             
             
             if(rotateAngle == 90.0 || rotateAngle == -90.0)
             {
                 //                 if(textureCoordinate.y >(1.0-borderSize) && (inputAlpha==1.0))
                 //                     textureColor.a = (1.0-textureCoordinate.y)/borderSize*inputAlpha*opacity;
                 //                 if(textureCoordinate.y <borderSize && (inputAlpha==1.0))
                 //                     textureColor.a = (textureCoordinate.y)/borderSize*inputAlpha*opacity;
                 
                 float max_y = cropOrigin.y + cropSize.y;
                 float min_y = cropOrigin.y;
                 
                 if(textureCoordinate.y >= (max_y-borderSize) && (textureCoordinate.y <= max_y) && (inputAlpha==1.0))
                     textureColor.a = (max_y-textureCoordinate.y)/borderSize*inputAlpha*opacity;
                 else if((textureCoordinate.y <= (min_y+borderSize)) && (textureCoordinate.y >= min_y) && (inputAlpha==1.0))
                     textureColor.a = (textureCoordinate.y-min_y)/borderSize*inputAlpha*opacity;
                 
                 
             }
             else
             {
                 float max_x = cropOrigin.x + cropSize.x;
                 float min_x = cropOrigin.x;
                 
                 //                 if(textureCoordinate.x >(1.0-borderSize) && (inputAlpha==1.0))
                 //                     textureColor.a = (1.0-textureCoordinate.x)/borderSize*inputAlpha*opacity;
                 //                 if(textureCoordinate.x <borderSize && (inputAlpha==1.0))
                 //                     textureColor.a = (textureCoordinate.x)/borderSize*inputAlpha*opacity;
                 
                 
                 if((textureCoordinate.x > (max_x-borderSize))  && (inputAlpha==1.0))
                     textureColor.a = (max_x-textureCoordinate.x)/borderSize*inputAlpha*opacity;
                 else if((textureCoordinate.x < (min_x+borderSize)) && (inputAlpha==1.0))
                     textureColor.a = (textureCoordinate.x-min_x)/borderSize*inputAlpha*opacity;
             }
         }
         gl_FragColor = textureColor;
     }
 }
 );

NSString*  const  kRDCompositorBlendFragmentShader = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform vec4 color;
 uniform float factor;
 uniform float brightness;
 void main()
 {
     vec4 texture1 = texture2D(inputImageTexture, textureCoordinate);
     
     vec4 texture2 = texture2D(inputImageTexture2, textureCoordinate);
     
     vec4 mixColor = mix(texture1,texture2,mix(step(0.5,texture2.a),factor,step(0.0,factor)))*color;
     
     gl_FragColor = vec4(vec3(brightness) + mixColor.rgb,1.0);
 }
 );

NSString*  const  kRDCompositorPassThroughMaskFragmentShader = SHADER_STRING
(
 precision mediump float;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform sampler2D inputImageTexture3;
 uniform float factor;
 varying highp vec2 textureCoordinate;
 void main(){
     
     vec4 texture1 = texture2D(inputImageTexture, textureCoordinate);//foreground
     vec4 texture2 = texture2D(inputImageTexture2, textureCoordinate);//background
     vec4 texture3 = texture2D(inputImageTexture3, textureCoordinate);//mask
     
     float newAlpha = dot(texture3.rgb,vec3(0.333333334)) *texture3.a;
     newAlpha = step(factor,newAlpha);
     vec4 t = vec4(texture1.rgb,newAlpha);
     
     gl_FragColor = vec4(mix(texture2.rgb,t.rgb,t.a),texture2.a);
 }
 );



#define MAX_INSTANCE 4 // iOS 中一个shader最多支持8个纹理
#define INDEX(x) int(floor(x))

NSString*  const kRDCompositorMultiTextureVertexShader = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;
 
 uniform mat4 projection[MAX_INSTANCE];
 uniform mat4 renderTransform[MAX_INSTANCE];
 
 uniform vec4 coordOffset[MAX_INSTANCE]; // 纹理缩放
 
 varying vec2 textureCoordinate;
 
 attribute float offset; //偏移
 varying float index; // 序号
 void main()
 {
     index = offset;
     
     gl_Position = projection[INDEX(index)] * renderTransform[INDEX(index)] * position;
     textureCoordinate = coordOffset[INDEX(index)].xy + coordOffset[INDEX(index)].ba * inputTextureCoordinate;
     //     textureCoordinate = inputTextureCoordinate;
     
 }
 );
// 优化
NSString* const kRDCompositorMultiTextureFragmentShader = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 varying highp float index;
 uniform sampler2D inputImageTexture[MAX_INSTANCE];
 uniform vec3 filter[MAX_INSTANCE];
 uniform float filterIntensity;
 
 const vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
 uniform sampler2D inputImageTexture2[MAX_INSTANCE];
 uniform float inputTexture2Type[MAX_INSTANCE];
 void main(){
     
     float brightness = filter[INDEX(index)].x;//亮度
     float contrast = filter[INDEX(index)].y;//对比度
     float saturation = filter[INDEX(index)].z; //饱和度
     
     vec4 textureColor = texture2D(inputImageTexture[INDEX(index)], textureCoordinate);
     
     
     
     textureColor = vec4((textureColor.rgb + vec3(brightness)), textureColor.w); // 亮度叠加
     
     textureColor = vec4(((textureColor.rgb - vec3(0.5)) * contrast + vec3(0.5)), textureColor.w); // 对比度叠加
     
     float luminance = dot(textureColor.rgb, luminanceWeighting);
     vec3 greyScaleColor= vec3(luminance);
     
     textureColor = vec4(mix(greyScaleColor, textureColor.rgb, saturation), textureColor.w); //饱和度
     
     if(eq(inputTexture2Type[INDEX(index)],1.0) > 0.5){//acv
         float redCurveValue = texture2D(inputImageTexture2[INDEX(index)], vec2(textureColor.r, 0.0)).r;
         float greenCurveValue = texture2D(inputImageTexture2[INDEX(index)], vec2(textureColor.g, 0.0)).g;
         float blueCurveValue = texture2D(inputImageTexture2[INDEX(index)], vec2(textureColor.b, 0.0)).b;
         
         textureColor = vec4(redCurveValue, greenCurveValue, blueCurveValue, textureColor.a);
     }
     if(eq(inputTexture2Type[INDEX(index)],2.0) > 0.5){ // lookup
         float blueColor = textureColor.b * 63.0;
         
         vec2 quad1;
         quad1.y = floor(floor(blueColor) / 8.0);
         quad1.x = floor(blueColor) - (quad1.y * 8.0);
         
         vec2 quad2;
         quad2.y = floor(ceil(blueColor) / 8.0);
         quad2.x = ceil(blueColor) - (quad2.y * 8.0);
         
         vec2 texPos1;
         texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
         texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
         
         vec2 texPos2;
         texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
         texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
         
         vec4 newColor1 = texture2D(inputImageTexture2[INDEX(index)], texPos1);
         vec4 newColor2 = texture2D(inputImageTexture2[INDEX(index)], texPos2);
         
         vec4 newColor = mix(newColor1, newColor2, fract(blueColor));
         textureColor = mix(textureColor, vec4(newColor.rgb, textureColor.w), filterIntensity);
     }
     
     gl_FragColor = textureColor;
     
 }
 );



NSString *const kRDVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
     
 }
 );

NSString *const kRDBeautyFragmentShaderString = SHADER_STRING
(
    precision highp float;
    varying highp vec2 textureCoordinate;
    uniform sampler2D inputImageTexture;
    uniform highp vec2 singleStepOffset;
//    美颜glsl,beautyParams参数说明：
//        beautyParams.r 代表磨皮(0-1.0)
//        beautyParams.g 代表亮肤(1.0f - 0.3f* bright) bright范围(0-1.0)
//        beautyParams.b 代表红润(0.1f + 0.3f* tone) tone范围(0-1.0)
    uniform highp vec4 beautyParams;
    
    const mat3 saturateMatrix = mat3(
                                     1.1102, -0.0598, -0.061,
                                     -0.0774, 1.0826, -0.1186,
                                     -0.0228, -0.0228, 1.1772);
    vec2 blurCoordinates[20];
    
    float hardLight(highp float color) {
        if (color <= 0.5)
            color = color * color * 2.0;
        else
            color = 1.0 - ((1.0 - color)*(1.0 - color) * 2.0);
        return color;
    }
    
    void main(){
        vec2 v_TexturePosition = textureCoordinate;
        vec4 tc = texture2D(inputImageTexture, v_TexturePosition);
        vec3 centralColor = tc.rgb;
        blurCoordinates[0] = v_TexturePosition.xy + singleStepOffset * vec2(0.0, -10.0);
        blurCoordinates[1] = v_TexturePosition.xy + singleStepOffset * vec2(0.0, 10.0);
        blurCoordinates[2] = v_TexturePosition.xy + singleStepOffset * vec2(-10.0, 0.0);
        blurCoordinates[3] = v_TexturePosition.xy + singleStepOffset * vec2(10.0, 0.0);
        blurCoordinates[4] = v_TexturePosition.xy + singleStepOffset * vec2(5.0, -8.0);
        blurCoordinates[5] = v_TexturePosition.xy + singleStepOffset * vec2(5.0, 8.0);
        blurCoordinates[6] = v_TexturePosition.xy + singleStepOffset * vec2(-5.0, 8.0);
        blurCoordinates[7] = v_TexturePosition.xy + singleStepOffset * vec2(-5.0, -8.0);
        blurCoordinates[8] = v_TexturePosition.xy + singleStepOffset * vec2(8.0, -5.0);
        blurCoordinates[9] = v_TexturePosition.xy + singleStepOffset * vec2(8.0, 5.0);
        blurCoordinates[10] = v_TexturePosition.xy + singleStepOffset * vec2(-8.0, 5.0);
        blurCoordinates[11] = v_TexturePosition.xy + singleStepOffset * vec2(-8.0, -5.0);
        blurCoordinates[12] = v_TexturePosition.xy + singleStepOffset * vec2(0.0, -6.0);
        blurCoordinates[13] = v_TexturePosition.xy + singleStepOffset * vec2(0.0, 6.0);
        blurCoordinates[14] = v_TexturePosition.xy + singleStepOffset * vec2(6.0, 0.0);
        blurCoordinates[15] = v_TexturePosition.xy + singleStepOffset * vec2(-6.0, 0.0);
        blurCoordinates[16] = v_TexturePosition.xy + singleStepOffset * vec2(-4.0, -4.0);
        blurCoordinates[17] = v_TexturePosition.xy + singleStepOffset * vec2(-4.0, 4.0);
        blurCoordinates[18] = v_TexturePosition.xy + singleStepOffset * vec2(4.0, -4.0);
        blurCoordinates[19] = v_TexturePosition.xy + singleStepOffset * vec2(4.0, 4.0);
        //                    blurCoordinates[20] = v_TexturePosition.xy + singleStepOffset * vec2(-2.0, -2.0);
        //                    blurCoordinates[21] = v_TexturePosition.xy + singleStepOffset * vec2(-2.0, 2.0);
        //                    blurCoordinates[22] = v_TexturePosition.xy + singleStepOffset * vec2(2.0, -2.0);
        //                    blurCoordinates[23] = v_TexturePosition.xy + singleStepOffset * vec2(2.0, 2.0);
        
        float sampleColor = centralColor.g * 20.0;
        sampleColor += texture2D(inputImageTexture, blurCoordinates[0]).g;
        sampleColor += texture2D(inputImageTexture, blurCoordinates[1]).g;
        sampleColor += texture2D(inputImageTexture, blurCoordinates[2]).g;
        sampleColor += texture2D(inputImageTexture, blurCoordinates[3]).g;
        sampleColor += texture2D(inputImageTexture, blurCoordinates[4]).g;
        sampleColor += texture2D(inputImageTexture, blurCoordinates[5]).g;
        sampleColor += texture2D(inputImageTexture, blurCoordinates[6]).g;
        sampleColor += texture2D(inputImageTexture, blurCoordinates[7]).g;
        sampleColor += texture2D(inputImageTexture, blurCoordinates[8]).g;
        sampleColor += texture2D(inputImageTexture, blurCoordinates[9]).g;
        sampleColor += texture2D(inputImageTexture, blurCoordinates[10]).g;
        sampleColor += texture2D(inputImageTexture, blurCoordinates[11]).g;
        sampleColor += texture2D(inputImageTexture, blurCoordinates[12]).g * 2.0;
        sampleColor += texture2D(inputImageTexture, blurCoordinates[13]).g * 2.0;
        sampleColor += texture2D(inputImageTexture, blurCoordinates[14]).g * 2.0;
        sampleColor += texture2D(inputImageTexture, blurCoordinates[15]).g * 2.0;
        sampleColor += texture2D(inputImageTexture, blurCoordinates[16]).g * 2.0;
        sampleColor += texture2D(inputImageTexture, blurCoordinates[17]).g * 2.0;
        sampleColor += texture2D(inputImageTexture, blurCoordinates[18]).g * 2.0;
        sampleColor += texture2D(inputImageTexture, blurCoordinates[19]).g * 2.0;
        //                    sampleColor += texture2D(inputImageTexture, blurCoordinates[20]).g * 3.0;
        //                    sampleColor += texture2D(inputImageTexture, blurCoordinates[21]).g * 3.0;
        //                    sampleColor += texture2D(inputImageTexture, blurCoordinates[22]).g * 3.0;
        //                    sampleColor += texture2D(inputImageTexture, blurCoordinates[23]).g * 3.0;
        
        sampleColor = sampleColor / 48.0;
        
        float highPass = centralColor.g - sampleColor + 0.5;
        
        for (int i = 0; i < 5; i++) {
            highPass = hardLight(highPass);
        }
        float alpha = clamp(beautyParams.r, 0.0, 1.0);
        
        vec3 smoothColor = centralColor + (centralColor-vec3(highPass))*alpha*0.1;
        smoothColor = max(smoothColor, centralColor);
        
        tc = vec4(mix(smoothColor, max(smoothColor, centralColor), alpha), tc.a);
        
        tc.r = clamp(pow(tc.r, beautyParams.g), 0.0, 1.0);
        tc.g = clamp(pow(tc.g, beautyParams.g), 0.0, 1.0);
        tc.b = clamp(pow(tc.b, beautyParams.g), 0.0, 1.0);
        
        vec3 satcolor = tc.rgb * saturateMatrix;
        tc.rgb = mix(tc.rgb, satcolor, beautyParams.b);
        gl_FragColor =  tc;
    }
    
);
NSString *const kRDSimpleFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture,textureCoordinate);;//source
 }
 );

NSString *const kRDMVFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 
 
 void main()
 {
     //     gl_FragColor = texture2D(inputImageTexture,textureCoordinate);
     //     return ;
     
     vec2 newCoordinate1 = vec2(textureCoordinate.x/2.0,textureCoordinate.y);
     vec4 t1 = texture2D(inputImageTexture2,newCoordinate1); // view
     
     vec2 newCoordinate2 = newCoordinate1 + vec2(0.5,0.0);
     vec4 t2 = texture2D(inputImageTexture2, newCoordinate2);//alpha
     
     vec4 t3 = texture2D(inputImageTexture,textureCoordinate);;//source
     float newAlpha = dot(t2.rgb, vec3(0.33333334)) * t2.a;
     vec4 t = vec4(t1.rgb,newAlpha); //compositor 输出一个综合视频 再与
     //mix(a,b,v) = (1-v)a + v(b)
     vec4 textureColor = vec4(mix(t3.rgb,t.rgb,t.a),t3.a);
     
     gl_FragColor = textureColor; // view;
     return ;
 }
 );

NSString *const kRDScreenBlendFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate);
     vec4 whiteColor = vec4(1.0);
     gl_FragColor = whiteColor - ((whiteColor - textureColor2) * (whiteColor - textureColor));
 }
 );

NSString *const kRDHardLightBlendFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 const vec3 W = vec3(0.2125, 0.7154, 0.0721);
 
 void main()
 {
     vec4 base = texture2D(inputImageTexture, textureCoordinate);
     vec4 overlay = texture2D(inputImageTexture2, textureCoordinate);
     
     float ra;
     if (2.0 * overlay.r < overlay.a) {
         ra = 2.0 * overlay.r * base.r + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
     } else {
         ra = overlay.a * base.a - 2.0 * (base.a - base.r) * (overlay.a - overlay.r) + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
     }
     
     float ga;
     if (2.0 * overlay.g < overlay.a) {
         ga = 2.0 * overlay.g * base.g + overlay.g * (1.0 - base.a) + base.g * (1.0 - overlay.a);
     } else {
         ga = overlay.a * base.a - 2.0 * (base.a - base.g) * (overlay.a - overlay.g) + overlay.g * (1.0 - base.a) + base.g * (1.0 - overlay.a);
     }
     
     float ba;
     if (2.0 * overlay.b < overlay.a) {
         ba = 2.0 * overlay.b * base.b + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
     } else {
         ba = overlay.a * base.a - 2.0 * (base.a - base.b) * (overlay.a - overlay.b) + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
     }
     
     gl_FragColor = vec4(ra, ga, ba, 1.0);
 }
 );

NSString*  const  kRDChromaColorBlendFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 uniform sampler2D inputImageTexture;
// uniform sampler2D inputImageTexture2;
 uniform int bgMode;        //使用 A/B/C 3个阀值来判断背景。 0=灰白背景，1=彩色背景
 uniform vec2 thresholdA;
 uniform vec2 thresholdB;
 uniform vec2 thresholdC;
 uniform int edgeMode;    //0=硬边缘，1=边缘透明度恢复，2=整体透明度恢复。
 
 varying mediump vec2 textureCoordinate;
 const float PI = 3.14159265358979323846;
 //vec2 MirroredRepeat(vec2 pos)
 //{
 //    pos.x = floor(pos.x * 0.5) * 2.0 == floor(pos.x) ? pos.x - floor(pos.x) : 1.0 - ( pos.x - floor(pos.x) );
 //    pos.y = floor(pos.y * 0.5) * 2.0 == floor(pos.y) ? pos.y - floor(pos.y) : 1.0 - ( pos.y - floor(pos.y) );
 //    return pos;
 //}
 
 vec2 EdgeRepeat(vec2 pos)
 {
     pos.x = max( 0.001, min( pos.x, 0.999 ) );
     pos.y = max( 0.001, min( pos.y, 0.999 ) );
     return pos;
 }
 
 vec4 rgbToHsv2(vec4 pix)
 {
     vec4 hsv;
     float maxV = max( pix.r, max(pix.g, pix.b) );
     float minV = min( pix.r, min(pix.g, pix.b) );
     float d = maxV - minV;
 
     if ( d > 0.03 )
     {
         if ( maxV == pix.r )
             hsv.r = (pix.g - pix.b) / d * ( 1.0/ 6.0 );
         else if ( maxV == pix.g )
             hsv.r = (pix.b - pix.r) / d * ( 1.0/ 6.0 ) + ( 2.0 / 6.0 );
         else if ( maxV == pix.b )
             hsv.r = (pix.r - pix.g) / d * ( 1.0/ 6.0 ) + ( 4.0 / 6.0 );
         if ( hsv.r < 0.0 ) hsv.r += 1.0;
         hsv.g    = d / maxV;    //s
     }
     else{
         hsv.r    = 0.0;
         hsv.g    = 0.0;
     }
     hsv.b    = ( minV + maxV ) * 0.5;
     hsv.a    = d;
 
     return hsv;
 }
 
 int pixHyBkType(vec4 hsv)
 {
     if ( hsv.g <= thresholdA.y )
     {
         if ( hsv.b >= thresholdB.x && hsv.b <= thresholdB.y )
         {
             return -1;
         }
         else if ( edgeMode < 2 && hsv.b >= thresholdC.x && hsv.b <= thresholdC.y )
         {
             return 1;
         }
         return 0;
     }
     return 1;
 }
 
 int pixHyBkType(vec2 pxPos, out vec4 pixRgb, out vec4 pixHsv)
 {
     pixRgb = texture2D(inputImageTexture, EdgeRepeat(pxPos));
     pixHsv = rgbToHsv2(pixRgb);
     int typeMe = pixHyBkType(pixHsv);
     if ( typeMe <= 0 )
     {
         int count = 0;
         int bgCou = 0;
         int foCou = 0;
         int mayCou = 0;
         vec4 bgRgb = vec4(0.0);
         vec4 foRgb = vec4(0.0);
         vec4 mayRgb = vec4(0.0);
 
         float stepLen    = 0.03;
         float radiusLen = stepLen * 1.0;
         float radian    = 0.0;
 
         for ( int i = 0; i < 2; ++i )
         {
             for ( int j = 0; j < 6; ++j )
             {
                 float sinRadian    = sin( radian );
                 float cosRadian    = cos( radian );
                 vec2 pos = pxPos + vec2( radiusLen * sinRadian, radiusLen * cosRadian );
                 vec4 rgb = texture2D(inputImageTexture, EdgeRepeat(pos));
                 vec4 hsv = rgbToHsv2(rgb);
                 int type = pixHyBkType(hsv );
 
                 if ( type < 0 )
                 {
                     ++bgCou;
                     bgRgb += rgb;
                 }
                 else if ( type > 0 )
                 {
                     ++foCou;
                     foRgb += rgb;
                 }
                 else
                 {
                     ++mayCou;
                     mayRgb += rgb;
                 }
                 radian += PI / 3.0;
                 ++count;
             }
 
             if ( i == 0  )
             {
                 if ( bgCou == 6 )
                     return -1;
             }
             else if ( (foCou > ( bgCou + mayCou ) * 2 ) )
             {
                 return 1;
             }
             radian    += PI / 6.0;
             radiusLen += stepLen;
         }
     }
     return typeMe;
 }
 
 
 int pixHsBkType(vec4 hsv)
 {
     if ( thresholdA.x <= thresholdA.y ?
         ( hsv.r >= thresholdA.x && hsv.r <= thresholdA.y ) :
         ( hsv.r >= thresholdA.x || hsv.r <= thresholdA.y ) )
     {
         if ( hsv.a >= thresholdB.x && hsv.a <= thresholdB.y )
         {
             return -1;
         }
         else if ( edgeMode < 2 && hsv.a >= thresholdC.x && hsv.a <= thresholdC.y )
         {
             return 1;
         }
         return 0;
     }
     return 1;
 }
 
 int pixHsBkType(vec2 pxPos, out vec4 pixRgb, out vec4 pixHsv)
 {
     pixRgb = texture2D(inputImageTexture, EdgeRepeat(pxPos));
     pixHsv = rgbToHsv2(pixRgb);
     return pixHsBkType(pixHsv);
 }
 
 void main(void)
 {
     vec2 pixSize = vec2( 1.0 / 50.0,  1.0 / 50.0 );
     vec4 rgbPixes[80];
     int count = 0;
     vec4 rgbMe;
     vec4 hsvMe;
     int typeMe;
     if ( bgMode == 0 )
     {
         typeMe = pixHyBkType(textureCoordinate.st, rgbMe, hsvMe);
     }
     else
     {
         typeMe = pixHsBkType(textureCoordinate.st, rgbMe, hsvMe);
     }
//     vec4 pixBg = texture2D(inputImageTexture,textureCoordinate);
    //vec4 pixBg = vec4( 0.0, 0.0, 0.0, 1.0 );
 
 //    ++typeMe;
 //    //rgbMe = vec4( float(typeMe) / 2.0, float(typeMe) / 2.0, float(typeMe) / 2.0, 1.0);
 //    hsvMe.a = 1.0;
 //    gl_FragColor = mix( pixBg, rgbMe,  float(typeMe) / 2.0 );
 //    return;
 
    int bgCou = 0;
    int foCou = 0;
    vec4 bgRgb = vec4(0.0);
    vec4 foRgb = vec4(0.0);
     float foSub = 0.0;
 
     float alpha = 0.5;
     float stepLen    = 0.005;
     float radiusLen = stepLen * 1.5;
     float radian    = 0.0;
     for ( int i = 0; i < 10; ++i )
     {
         for ( int j = 0; j < 8; ++j )
         {
             float sinRadian    = sin( radian );
             float cosRadian    = cos( radian );
             vec2 pos = textureCoordinate.st + vec2( radiusLen * sinRadian, radiusLen * cosRadian );
             vec4 rgb;
             vec4 hsv;
             int type = bgMode == 0 ? pixHyBkType(pos, rgb, hsv) : pixHsBkType(pos, rgb, hsv);
             rgbPixes[count] = rgb;
 
             if ( type < 0 )
             {
                 ++bgCou;
                 bgRgb += rgb;
                 rgbPixes[count].a = -1.0;
             }
             else if ( type > 0 )
             {
                 ++foCou;
                 foRgb += rgb;
                 vec4 sub = abs(rgb - rgbMe);
                 sub *= sub;
                 rgbPixes[count].a = sub.r + sub.b + sub.a;
                 foSub += rgbPixes[count].a;
             }
             radian += PI / 4.0;
             ++count;
         }
     
         if ( i == 0 )
         {
             if ( typeMe > 0 && foCou == 8 )
             {
                 break;
             }
             else if ( typeMe < 0 && bgCou == 8 )
             {
                 break;
             }
         }
         else if ( i < 5 )
         {
             if ( typeMe >= 0 && foCou >= ( count - foCou ) * 4 )
             {
                 bgCou = 0;
                 foCou = 1;
                 break;
             }
         }
         if ( bgCou > 9 && foCou > 9 ) break;
 
         if ( bgCou < 2 * ( i + 1 ) || foCou < 2 * ( i + 1 ) )
         {
             radiusLen += stepLen * float(i);
         }
         radian    += PI / 8.0;
         radiusLen += stepLen;
     }
 
 
     if ( foCou == 0 )
     {
         alpha = 0.0;
     }
     else if ( bgCou == 0 )
     {
         alpha = 1.0;
     }
     else if ( foCou > 0 && bgCou > 0 )
     {
         foRgb /= float(foCou);
         bgRgb /= float(bgCou);
 
         if ( edgeMode == 0 )
         {
             vec4 hsvFo = rgbToHsv2(foRgb);
             vec4 hsvBg = rgbToHsv2(bgRgb);
 
             hsvFo = abs( hsvMe - hsvFo );
             hsvFo.r = ( hsvFo.r > 0.5 ? 1.0 - hsvFo.r : hsvFo.r );
             hsvBg = abs( hsvMe - hsvBg );
             hsvBg.r = ( hsvBg.r > 0.5 ? 1.0 - hsvBg.r : hsvBg.r );
 
             hsvFo *= hsvFo;
             hsvBg *= hsvBg;
             if ( hsvFo.r + hsvFo.b + hsvFo.a < hsvBg.r + hsvBg.b + hsvBg.a )
             {
                 alpha    = 1.0;
             }
             else
             {
                 alpha = 0.0;
             }
         }
         else
         {
     
             foSub /= float(foCou);
             foRgb    = vec4(0.0);
             foCou    = 0;
 
             for ( int i = 0; i < count; ++i )
             {
                 if ( rgbPixes[i].a >= 0.0 && foSub >= rgbPixes[i].a )
                 {
                     foRgb += rgbPixes[i];
                     ++foCou;
                 }
             }
 
             foRgb /= float(foCou);
             vec4 s    = abs(foRgb - bgRgb );
             if ( s.r >= s.g && s.r >= s.b )
             {
                 alpha = ( rgbMe.r - bgRgb.r ) / (foRgb.r - bgRgb.r );
             }
             else if ( s.g >= s.r && s.g >= s.b )
             {
                 alpha = ( rgbMe.g - bgRgb.g ) / (foRgb.g - bgRgb.g );
             }
             else if ( s.b >= s.r && s.b >= s.g )
             {
                 alpha = ( rgbMe.b - bgRgb.b ) / (foRgb.b - bgRgb.b );
             }
             alpha = max( 0.0, min( 1.0, alpha ) );
             rgbMe.r = ( rgbMe.r - bgRgb.r ) / alpha + bgRgb.r;
             rgbMe.g = ( rgbMe.g - bgRgb.g ) / alpha + bgRgb.g;
             rgbMe.b = ( rgbMe.b - bgRgb.b ) / alpha + bgRgb.b;
 
             rgbMe.r = min( 1.0, max( 0.0, rgbMe.r ) );
             rgbMe.g = min( 1.0, max( 0.0, rgbMe.g ) );
             rgbMe.b = min( 1.0, max( 0.0, rgbMe.b ) );
             rgbMe.a = 1.0;
 
             //rgbMe    = foRgb;
             //alpha    = 1.0;
         }
     }
 
    // vec4 outColor = mix( pixBg, rgbMe, alpha );
   // if(outColor.r == 0.0 && outColor.g == 0.0 && outColor.b == 0.0)
    //    outColor.a = 0.0;
    gl_FragColor = rgbMe;
    gl_FragColor.a =alpha;
 
 }

 );

NSString *const kRDChromaKeyBlendFragmentShaderString = SHADER_STRING
(
 precision highp float;
#if 0
 
 uniform sampler2D inputColorTransparencyImageTexture; //颜色透明纹理
 uniform sampler2D inputBackGroundImageTexture; //背景图片纹理
 varying highp vec2 textureCoordinate;
 uniform vec3 bgRGB;
 
void main(void)
{

    vec4 rgba = texture2D(inputColorTransparencyImageTexture, textureCoordinate.st);
    float alpha = 0.0;

    alpha = max(alpha, abs(bgRGB.r - rgba.r) );
    alpha = max(alpha, abs(bgRGB.g - rgba.g) );
    alpha = max(alpha, abs(bgRGB.b - rgba.b) );

    rgba.r = ( rgba.r - bgRGB.r ) / alpha + bgRGB.r;
    rgba.g = ( rgba.g - bgRGB.g ) / alpha + bgRGB.g;
    rgba.b = ( rgba.b - bgRGB.b ) / alpha + bgRGB.b;
    rgba.r = min( 1.0, max( 0.0, rgba.r ) );
    rgba.g = min( 1.0, max( 0.0, rgba.g ) );
    rgba.b = min( 1.0, max( 0.0, rgba.b ) );
    rgba.a = 1.0;

    vec4 pixBg = texture2D(inputBackGroundImageTexture, textureCoordinate.st);
#if 0
    vec4 pixBg = vec4(1.0,0,0,1.0); //背景
    gl_FragColor = mix( pixBg, rgba, alpha );
#else
    
    gl_FragColor = vec4(vec3(mix( pixBg, rgba, alpha ).rgb),1.0);//抠图之后的图像
    
#endif
}
#else
 
 uniform sampler2D inputColorTransparencyImageTexture;
// uniform sampler2D inputBackGroundImageTexture;
 uniform vec3 bgRGB;
// uniform float alphaUpper;        //透明度上限，如果计算出的透明度大于上限，均视为1
// uniform float alphaLower;        //透明度下限，如果计算出的透明度小于下限，均视为0
 float alphaUpper = 1.0;
 float alphaLower = 0.0;
 varying mediump vec2 textureCoordinate;
 
 vec3 rgbToHsv( vec3 rgbPix )
 {
     vec3 hsvPix;
     float maxV = max( rgbPix.r, max(rgbPix.g, rgbPix.b) );
     float minV = min( rgbPix.r, min(rgbPix.g, rgbPix.b) );
     float d = maxV - minV;
     hsvPix.b = maxV;
     if ( d > 0.0 )
     {
         hsvPix.g = d / maxV;
         if ( maxV == rgbPix.r )
             hsvPix.r = (rgbPix.g - rgbPix.b) / d * 60.0;
         else if ( maxV == rgbPix.g )
             hsvPix.r = (rgbPix.b - rgbPix.r) / d * 60.0 + 120.0;
         else if ( maxV == rgbPix.b )
             hsvPix.r = (rgbPix.r - rgbPix.g) / d * 60.0 + 240.0;
         if ( hsvPix.r < 0.0 ) hsvPix.r += 360.0;
     }
     else{
         hsvPix.g = hsvPix.r = 0.0;
     }
     return hsvPix;
 }
 
 void main(void)
 {
     vec3 hsvBG = rgbToHsv(bgRGB);
     
     vec4 rgba = texture2D(inputColorTransparencyImageTexture, textureCoordinate.st);
     vec3 hsvFO = rgbToHsv(rgba.rgb);
 
     float hue = 0.0;
     if (hsvBG.g > 0.1 || hsvBG.b > 0.1 )
     {
         if (hsvFO.g > 0.1 || hsvFO.b > 0.1 )
         {
             hue = hsvFO.r;
         }
         hue = abs(hsvBG.r - hue);
         if ( hue > 180.0 ) hue = 360.0 - hue;
         hue = hue / 120.0 + abs(hsvBG.g - hsvFO.g) * abs(hsvBG.g - hsvFO.g);
     }
     float alpha = 0.0;
     alpha = max(alpha, abs(bgRGB.r - rgba.r) );
     alpha = max(alpha, abs(bgRGB.g - rgba.g) );
     alpha = max(alpha, abs(bgRGB.b - rgba.b) );
     alpha += hue;
     if ( alpha > 1.0 ) alpha = 1.0;
 
     if ( alpha < alphaLower )
         alpha = 0.0;
     else if ( alpha > alphaUpper )
         alpha = 1.0;
     else
         alpha = ( alpha - alphaLower ) / ( alphaUpper - alphaLower );
     rgba.r = ( rgba.r - bgRGB.r ) / alpha + bgRGB.r;
     rgba.g = ( rgba.g - bgRGB.g ) / alpha + bgRGB.g;
     rgba.b = ( rgba.b - bgRGB.b ) / alpha + bgRGB.b;
     rgba.r = min( 1.0, max( 0.0, rgba.r ) );
     rgba.g = min( 1.0, max( 0.0, rgba.g ) );
     rgba.b = min( 1.0, max( 0.0, rgba.b ) );
     rgba.a = 1.0;
 
 
//     vec4 pixBg = texture2D(inputBackGroundImageTexture, textureCoordinate.st);
        vec4 pixBg = vec4( 1.0, 1.0, 1.0, 0.0 );
 
     gl_FragColor = mix( pixBg, rgba, alpha );
//    gl_FragColor = vec4( 1.0, 1.0, 1.0, 1.0 );
 
 }



#endif
 );

NSString*  const  kRDCompositorInvertFragmentShader = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform vec4 color;
 uniform float factor;
 uniform float brightness;
 void main()
 {
     vec4 texture1 = texture2D(inputImageTexture, textureCoordinate);
     
     vec4 texture2 = texture2D(inputImageTexture2, textureCoordinate);
     
     vec4 mixColor = mix(texture1,texture2,mix(step(0.5,texture2.a),factor,step(0.0,factor)))*color;
     
     if(factor <= 0.3)
         gl_FragColor = vec4(vec3(brightness) + mixColor.rgb,1.0);//闪白
     else
     {
         vec3 W = vec3(0.2125,0.7154,0.0721);
         float lum = dot(texture2.rgb,W);
         texture2 = vec4(vec3(lum),texture2.a);
         if(factor >0.3 && factor <= 0.4)
         {
             if(textureCoordinate.x<0.4 || textureCoordinate.x>0.6 || textureCoordinate.y<0.4 || textureCoordinate.y>0.6)//灰白
                 gl_FragColor = texture2;
             else
                 gl_FragColor = vec4((1.0-texture2.rgb),1.0);//反色
         }
         else if(factor <= 0.6)
         {
             if(textureCoordinate.x<0.3 || textureCoordinate.x>0.7 || textureCoordinate.y<0.3 || textureCoordinate.y>0.7)
                 gl_FragColor = vec4((1.0-texture2.rgb),1.0);//反色
             else
                 gl_FragColor = texture2;//灰白
             
         }
         else
             gl_FragColor = texture2;//灰白
         
     }
     
 }
 );

NSString*  const  kRDCompositorGrayFragmentShader = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform vec4 color;
 uniform float factor;
 uniform float brightness;
 void main()
 {
     vec4 texture1 = texture2D(inputImageTexture, textureCoordinate);
     
     vec4 texture2 = texture2D(inputImageTexture2, textureCoordinate);
     
     vec4 mixColor = mix(texture1,texture2,mix(step(0.5,texture2.a),factor,step(0.0,factor)))*color;
     
     if(factor <= 0.3)
         gl_FragColor = vec4(vec3(brightness) + mixColor.rgb,1.0);//闪白
     else
     {
         vec3 W = vec3(0.2125,0.7154,0.0721);
         float lum = dot(texture2.rgb,W);
         texture2 = vec4(vec3(lum),texture2.a);
         if(factor >0.3 && factor <= 0.4)
         {
             if(textureCoordinate.y<0.1 || textureCoordinate.y>0.9)//灰白
                 gl_FragColor = texture2;
             else
                 gl_FragColor = vec4(1.0,1.0,1.0,1.0);//白色
         }
         else if(factor <= 0.6)
         {
             if(textureCoordinate.y<0.1 || textureCoordinate.y>0.9)
                 gl_FragColor = texture2D(inputImageTexture2, textureCoordinate);//原图
             else
                 gl_FragColor = vec4(1.0,1.0,1.0,1.0);//白色
             
         }
         else
             gl_FragColor = texture2D(inputImageTexture2, textureCoordinate);//原图
         
     }
     
 }
 );

NSString*  const  kRDCompositorBulgeDistortionFragmentShader = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform vec4 color;
 uniform float factor;
 uniform float brightness;
 uniform float aspectRatio;
 
 void main()
 {
     vec4 outColor;
     float radius = factor/2.0;
     float scale = 0.1;//factor;
     vec2 center = vec2(0.5,0.5);
     vec4 texture2;
     vec4 texture1 = texture2D(inputImageTexture, textureCoordinate);
     
     //     highp vec2 textureCoordinateToUse = vec2(textureCoordinate.x, ((textureCoordinate.y - center.y) * aspectRatio) + center.y);
     highp vec2 textureCoordinateToUse = vec2(((textureCoordinate.x - center.x) * aspectRatio) + center.x, ((textureCoordinate.y - center.y) ) + center.y);
     highp float dist = distance(center, textureCoordinateToUse);
     textureCoordinateToUse = textureCoordinate;
     if(factor<0.3)
     {
         texture2 = texture2D(inputImageTexture2, textureCoordinate );
         outColor = mix(texture1,texture2,mix(step(0.5,texture2.a),factor,step(0.0,factor)))*color;
     }
     else
     {
         if (dist < radius)
         {
             textureCoordinateToUse -= center;
             highp float percent = 1.0 - ((radius - dist) / radius) * scale;
             percent = percent * percent;
             
             textureCoordinateToUse = textureCoordinateToUse * percent;//vec2(percent*aspectRatio,percent);
             textureCoordinateToUse += center;
         }
         texture2 = texture2D(inputImageTexture2, textureCoordinateToUse );
         outColor = mix(texture1,texture2,mix(step(0.5,texture2.a),factor,step(0.0,factor)))*color;
         
     }
     
     gl_FragColor = outColor;
     
 }
 );


NSString*  const  kRDCompositorGridFragmentShader = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform vec4 color;
 uniform float factor;
 uniform float brightness;
 uniform float aspectRatio;
 
 void main()
 {
     vec4 outColor;
     float radius = factor/2.0;
     float scale = 0.1;//factor;
     vec2 center = vec2(0.5,0.5);
     vec4 texture2;
     vec4 texture1 = texture2D(inputImageTexture2, textureCoordinate);
     gl_FragColor = texture1;
     return;
     
     //     highp vec2 textureCoordinateToUse = vec2(textureCoordinate.x, ((textureCoordinate.y - center.y) * aspectRatio) + center.y);
     highp vec2 textureCoordinateToUse = vec2(((textureCoordinate.x - center.x) * aspectRatio) + center.x, ((textureCoordinate.y - center.y) ) + center.y);
     highp float dist = distance(center, textureCoordinateToUse);
     textureCoordinateToUse = textureCoordinate;
     if(factor<0.3)
     {
         texture2 = texture2D(inputImageTexture2, textureCoordinate );
         outColor = mix(texture1,texture2,mix(step(0.5,texture2.a),factor,step(0.0,factor)))*color;
     }
     else
     {
         if (dist < radius)
         {
             textureCoordinateToUse -= center;
             highp float percent = 1.0 - ((radius - dist) / radius) * scale;
             percent = percent * percent;
             
             textureCoordinateToUse = textureCoordinateToUse * percent;//vec2(percent*aspectRatio,percent);
             textureCoordinateToUse += center;
         }
         texture2 = texture2D(inputImageTexture2, textureCoordinateToUse );
         outColor = mix(texture1,texture2,mix(step(0.5,texture2.a),factor,step(0.0,factor)))*color;
         
     }
     
     gl_FragColor = outColor;
     
 }
 );

NSString *const kRDGaussianBlurVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 uniform mat4 projection;
 uniform mat4 renderTransform;
 varying vec2 textureCoordinate;
 
 
 void main()
 {
     gl_Position = projection * renderTransform * position;;
     textureCoordinate = inputTextureCoordinate.xy;
     
 }
 );

NSString *const kRDGaussianBlurFragmentShaderString = SHADER_STRING
(
 precision highp float;
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform vec2 pointLB;
 uniform vec2 pointLT;
 uniform vec2 pointRT;
 uniform vec2 pointRB;
 uniform vec2 u_resolution;
 uniform vec2 u_direction;
 
 vec4 vColorRGBA;
 
 
 int isPointInRect(float x, float y) {

    vec2 A = pointLB*100.0;
    vec2 B = pointLT*100.0;
    vec2 C = pointRT*100.0;
    vec2 D = pointRB*100.0;
    
    float a = (B.x - A.x)*(y - A.y) - (B.y - A.y)*(x - A.x);
    float b = (C.x - B.x)*(y - B.y) - (C.y - B.y)*(x - B.x);
    float c = (D.x - C.x)*(y - C.y) - (D.y - C.y)*(x - C.x);
    float d = (A.x - D.x)*(y - D.y) - (A.y - D.y)*(x - D.x);
    if((a > 0.0 && b > 0.0 && c > 0.0 && d > 0.0) || (a < 0.0 && b < 0.0 && c < 0.0 && d < 0.0)) {
        return 1;
    }
    return 0;
}
 

 vec4 blur9(sampler2D image, vec2 uv, vec2 resolution, vec2 direction) {
     vec4 color = vec4(0.0);
     vec2 off1 = vec2(1.3846153846) * direction;
     vec2 off2 = vec2(3.2307692308) * direction;
     vec4 imageColor = texture2D(image, uv);
     color += imageColor * 0.2270270270;
     color += texture2D(image, uv + (off1 / resolution)) * 0.3162162162;
     color += texture2D(image, uv - (off1 / resolution)) * 0.3162162162;
     color += texture2D(image, uv + (off2 / resolution)) * 0.0702702703;
     color += texture2D(image, uv - (off2 / resolution)) * 0.0702702703;
     return color;//vec4(color.rgb,imageColor.a);
 }
 vec4 blur13(sampler2D image, vec2 uv, vec2 resolution, vec2 direction) {
    vec4 color = vec4(0.0);
    vec2 off1 = vec2(1.411764705882353) * direction;
    vec2 off2 = vec2(3.2941176470588234) * direction;
    vec2 off3 = vec2(5.176470588235294) * direction;
    color += texture2D(image, uv) * 0.1964825501511404;
    color += texture2D(image, uv + (off1 / resolution)) * 0.2969069646728344;
    color += texture2D(image, uv - (off1 / resolution)) * 0.2969069646728344;
    color += texture2D(image, uv + (off2 / resolution)) * 0.09447039785044732;
    color += texture2D(image, uv - (off2 / resolution)) * 0.09447039785044732;
    color += texture2D(image, uv + (off3 / resolution)) * 0.010381362401148057;
    color += texture2D(image, uv - (off3 / resolution)) * 0.010381362401148057;
    return color;
    
  
}
 

 void main()
 {
     

    vColorRGBA = blur9(inputImageTexture, textureCoordinate, u_resolution.xy, u_direction);

     gl_FragColor = vColorRGBA;
     
 }
 );

NSString *const kRDBorderGaussianBlurFragmentShaderString = SHADER_STRING
(

 precision highp float;
 uniform sampler2D inputImageTexture;
 uniform vec2 resolution;
 uniform vec2 viewport;
 uniform vec2 cropOriginal;
 uniform vec2 cropSize;
 uniform    float    edge;
 uniform    float    blurRadius;
 uniform bool isfirst;        //第一传 true(1), 第二次 false(0)
 varying vec2 textureCoordinate;
 const float PI = 3.14159265358979323846;
// const float gaussian[11] = float[11](0.0, 0.051161, 0.085862, 0.124283, 0.155159, 0.167071, 0.155159, 0.124283, 0.085862, 0.051161, 0.0);
 float gaussian[11];
 

 
 
 vec2 m_imgSize ;
 vec2 m_pixSize ;
 
 vec2 MirroredRepeat(vec2 pos)
{
    pos.x = floor(pos.x * 0.5) * 2.0 == floor(pos.x) ? pos.x - floor(pos.x) : 1.0 - ( pos.x - floor(pos.x) );
    pos.y = floor(pos.y * 0.5) * 2.0 == floor(pos.y) ? pos.y - floor(pos.y) : 1.0 - ( pos.y - floor(pos.y) );
    return pos;
}
 
 float rand(vec2 co)
{
    return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
}
 
 vec4 getScalePixelX( vec2 pos )
{
    float posAsImage = pos.x * m_imgSize.x;
    float posSour = floor( posAsImage );
    float ratioPix = ( posAsImage - posSour );
    posSour *= m_pixSize.x;
    
    vec4 pix;
    vec4 pixT0 = vec4(0.0);
    vec4 pixT1 = vec4(0.0);
    for ( int i = -4; i <= 5; ++i )
    {
        pix = texture2D(inputImageTexture, MirroredRepeat(vec2( posSour + float(i) * m_pixSize.x, pos.y )));
        pixT0 += pix * gaussian[i + 5];
        pixT1 += pix * gaussian[i + 4];
    }
    
    return mix( pixT0, pixT1, ratioPix );
}
 
 vec4 getScalePixelY( vec2 pos )
{
    float posAsImage = pos.y * m_imgSize.y;
    float posSour = floor( posAsImage );
    float ratioPix = ( posAsImage - posSour );
    posSour *= m_pixSize.y;
    
    vec4 pix;
    vec4 pixT0 = vec4(0.0);
    vec4 pixT1 = vec4(0.0);
    for ( int i = -4; i <= 5; ++i )
    {
        pix = texture2D(inputImageTexture, MirroredRepeat(vec2( pos.x, posSour + float(i) * m_pixSize.y )));
        pixT0 += pix * gaussian[i + 5];
        pixT1 += pix * gaussian[i + 4];
    }
    
    return mix( pixT0, pixT1, ratioPix );
}
 
 vec4 blur9(sampler2D image, vec2 uv, vec2 resolution, vec2 direction)
{
    
    
    vec4 color = vec4(0.0);
    vec2 off1 = vec2(1.3846153846) * direction;
    vec2 off2 = vec2(3.2307692308) * direction;
    color += texture2D(image, uv) * 0.2270270270;
    color += texture2D(image, uv + (off1 / resolution)) * 0.3162162162;
    color += texture2D(image, uv - (off1 / resolution)) * 0.3162162162;
    color += texture2D(image, uv + (off2 / resolution)) * 0.0702702703;
    color += texture2D(image, uv - (off2 / resolution)) * 0.0702702703;
    return color;
}
 
 void main(void)
{
    float    ratioV = viewport.x / viewport.y;
    float    ratioS = ( resolution.x * cropSize.x ) / ( resolution.y * cropSize.y );
    float    scale = ratioS / ratioV;
    vec2    coordinate = textureCoordinate.xy;
    vec2    pos;
    vec2    pos1;
    vec2    pos2;
    bool    blur = false;
    float    alpha = 0.0;
    vec4    pixMe;
    gaussian[0] = 0.0;
    gaussian[1] = 0.051161;
    gaussian[2] = 0.085862;
    gaussian[3] = 0.124283;
    gaussian[4] = 0.155159;
    gaussian[5] = 0.167071;
    gaussian[6] = 0.155159;
    gaussian[7] = 0.124283;
    gaussian[8] = 0.085862;
    gaussian[9] = 0.051161;
    gaussian[10] = 0.0;
    
    if ( ratioV > ratioS )
    {
        pos1.x    = coordinate.x;
        pos1.y    = (coordinate.y - 0.5) * scale + 0.5;
        
        pos2.x    = (coordinate.x - 0.5) / scale + 0.5;
        pos2.y    = coordinate.y;
        if ( pos2.x < edge )
        {
            blur = true;
            if ( pos2.x >= 0.0 )
                alpha    = pos2.x / edge;
        }
        else if ( pos2.x > 1.0 - edge )
        {
            blur = true;
            if ( pos2.x <= 1.0 )
                alpha    = ( 1.0 - pos2.x ) / edge;
        }
        //m_imgSize.x = viewport.x;
        //m_imgSize.y    = viewport.x / ratioS;
        m_imgSize = viewport;
        m_imgSize /= blurRadius;
        m_pixSize = 1.0 / m_imgSize;
        if (isfirst)
        {
            pos1  = pos1 * cropSize + cropOriginal;
            pos2  = pos2 * cropSize + cropOriginal;
            if ( blur )
            {
                pixMe = getScalePixelX(pos1);
                
                
                if ( alpha != 0.0 )
                {
                    pixMe = mix( texture2D(inputImageTexture, pos2), pixMe, (cos(alpha * PI) + 1.0) * 0.5 );
                }
            }
            else
            {
                pixMe = texture2D(inputImageTexture, pos2);
            }
        }
        else
        {
            if ( blur )
            {
                pixMe = getScalePixelY(coordinate);
                if ( alpha != 0.0 )
                {
                    pixMe = mix( texture2D(inputImageTexture, coordinate), pixMe, (cos(alpha * PI) + 1.0) * 0.5 );
                }
            }
            else
            {
                pixMe = texture2D(inputImageTexture, coordinate);
            }
        }
    }
    else{
        pos1.x    = (coordinate.x - 0.5) / scale + 0.5;
        pos1.y    = coordinate.y;
        
        pos2.x    = coordinate.x;
        pos2.y    = (coordinate.y - 0.5) * scale + 0.5;
        if ( pos2.y < edge )
        {
            blur = true;
            if ( pos2.y >= 0.0 )
                alpha    = pos2.y / edge;
        }
        else if ( pos2.y > 1.0 - edge )
        {
            blur = true;
            if ( pos2.y <= 1.0 )
                alpha    = ( 1.0 - pos2.y ) / edge;
        }
        //m_imgSize.x = viewport.y * ratioS;
        //m_imgSize.y    = viewport.y;
        m_imgSize = viewport;
        m_imgSize /= blurRadius;
        m_pixSize = 1.0 / m_imgSize;
        if (isfirst)
        {
            pos1  = pos1 * cropSize + cropOriginal;
            pos2  = pos2 * cropSize + cropOriginal;
            if ( blur )
            {
                pixMe = getScalePixelY(pos1);
                
                
                if ( alpha != 0.0 )
                {
                    pixMe = mix( texture2D(inputImageTexture, pos2), pixMe, (cos(alpha * PI) + 1.0) * 0.5 );
                }
            }
            else
            {
                pixMe = texture2D(inputImageTexture, pos2);
            }
        }
        else
        {
            if ( blur )
            {
                pixMe = getScalePixelX(coordinate);
                if ( alpha != 0.0 )
                {
                    pixMe = mix( texture2D(inputImageTexture, coordinate), pixMe, (cos(alpha * PI) + 1.0) * 0.5 );
                }
            }
            else
            {
                pixMe = texture2D(inputImageTexture, coordinate);
            }
        }
    }
    
    gl_FragColor = pixMe;//pixMe / float(count);
}
 
 
 );

NSString*  const kRDCustomFilterFreezeFrameVertexShader = SHADER_STRING
(
 //
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate;
 }
 
 );

NSString*  const kRDCustomFilterFreezeFrameFragmentShader = SHADER_STRING
(
 precision highp float;
 
 uniform sampler2D inputImageTexture;
 uniform float time;
 varying vec2 textureCoordinate;
 uniform float progress;
 uniform float rotateAngle;
 uniform vec2 resolution;
 
 int drawCircle(vec2 center)
 {

     float ratio = resolution.x/resolution.y;
     vec2 coordinate = textureCoordinate;
     //计算圆心
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
     if (distance(coordinate,center)>0.02 && distance(coordinate,center)<0.04 )
         return 1;
     else
         return 0;
     
 }
 
 void main()
 {
#if 0
     //定格 - 左右特效 - RDBuiltIn_freezeFrameLeftRight
     vec2 coordinate = textureCoordinate;
     float process_time = time;
     while(process_time > 3.0)
         process_time = process_time - 3.0;
     float p = process_time / 3.0;
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

     if(drawCircle(vec2(border.x,border.y)) == 1)
         outColor = vec4(0.0,0.0,0.0,1.0);
     if(drawCircle(vec2(1.0 - border.x,border.y)) == 1)
         outColor = vec4(0.0,0.0,0.0,1.0);
     if(drawCircle(vec2(border.x,1.0 - border.y)) == 1)
         outColor = vec4(0.0,0.0,0.0,1.0);
     if(drawCircle(vec2(1.0 - border.x,1.0 - border.y)) == 1)
         outColor = vec4(0.0,0.0,0.0,1.0);

     gl_FragColor = outColor;
#endif
     
     //定格 - 上下特效 - RDBuiltIn_freezeFrameTopButtom
//     float process_time = time;
//     while(process_time > 3.0)
//         process_time = process_time - 3.0;
//     float p = process_time / 3.0;
//
//     vec2 coordinate = textureCoordinate;
//     vec4 outColor ;
//     float size = 0.07;
//     vec2 border = (resolution.x > resolution.y ) ? vec2(0.02,resolution.x/resolution.y*0.02):vec2(resolution.y/resolution.x*0.02,0.02);
//
//     if(p < 0.15)
//     {
//         float factor = p / 0.15;
//#ifdef ANDROID
//         if(coordinate.y >= 0.5 && coordinate.y <= 0.5 + factor*0.5 )
//#else
//         if(coordinate.y <= 0.5 && coordinate.y >= 0.5 - factor*0.5 )
//#endif
//             outColor = texture2D(inputImageTexture, coordinate);
//         else
//             outColor = vec4(0.0,0.0,0.0,1.0);
//
//
//     }
//     else if(p < 0.3)
//     {
//         float factor = (p - 0.15) / 0.15;
//#ifdef ANDROID
//         if(coordinate.y >= 0.5 && coordinate.y < 1.0 - factor * 0.5 )
//#else
//         if(coordinate.y <= 0.5 && coordinate.y > factor*0.5 )
//#endif
//             outColor = texture2D(inputImageTexture, coordinate);
//         else
//             outColor = vec4(0.0,0.0,0.0,1.0);
//
//     }
//     else if(p < 0.45)
//     {
//         float factor = (p - 0.3) / 0.15;
//#ifdef ANDROID
//         if(coordinate.y <= 0.5 && coordinate.y > 0.5 - factor*0.5 )
//#else
//         if(coordinate.y >= 0.5 && coordinate.y < 0.5 + factor*0.5 )
//#endif
//             outColor = texture2D(inputImageTexture, coordinate);
//         else
//             outColor = vec4(0.0,0.0,0.0,1.0);
//     }
//     else if(p < 0.6)
//     {
//         float factor = (p - 0.45) / 0.15;
//#ifdef ANDROID
//         if(coordinate.y >  0.0 && coordinate.y < 0.5 + factor*0.5 )
//#else
//         if(coordinate.y <= 1.0 && coordinate.y > 0.5 - factor*0.5 )
//#endif
//             outColor = texture2D(inputImageTexture, coordinate);
//         else
//             outColor = vec4(0.0,0.0,0.0,1.0);
//     }
//     else
//         outColor = texture2D(inputImageTexture, coordinate);
//
//     if(coordinate.x < border.x || coordinate.x > (1.0 - border.x)||
//        coordinate.y < border.y || coordinate.y > (1.0 - border.y))
//         outColor = vec4(0.0,0.0,0.0,1.0);
//
//     if(p < 0.3)
//     {
//         float factor = p / 0.3;
//         if(coordinate.y >= 0.1 && coordinate.y <= 0.12 && coordinate.x < size * factor)
//             outColor = vec4(1.0,1.0,1.0,1.0);
//         if(coordinate.y >= 0.45 && coordinate.y <= 0.47 && coordinate.x > (1.0 - size) && coordinate.x <= (1.0 - size + size * factor))
//             outColor = vec4(1.0,1.0,1.0,1.0);
//         if(coordinate.y >= 0.85 && coordinate.y <= 0.87 && coordinate.x < size * factor)
//             outColor = vec4(1.0,1.0,1.0,1.0);
//     }
//     else if(p < 0.6)
//     {
//         float factor = (p - 0.3) / 0.3;
//         if(coordinate.y >= 0.1 && coordinate.y <= 0.12 && coordinate.x < (size - size * factor))
//             outColor = vec4(1.0,1.0,1.0,1.0);
//         if(coordinate.y >= 0.45 && coordinate.y <= 0.47 && coordinate.x > (1.0 - size) && coordinate.x <= (1.0 - size * factor))
//             outColor = vec4(1.0,1.0,1.0,1.0);
//         if(coordinate.y >= 0.85 && coordinate.y <= 0.87 && coordinate.x < (size - size * factor))
//             outColor = vec4(1.0,1.0,1.0,1.0);
//     }
//     gl_FragColor = outColor;

     
     //定格 - 百叶窗特效 - RDBuiltIn_freezeFrameShutters
     float process_time = time;
     while(process_time > 3.0)
         process_time = process_time - 3.0;
     float p = process_time/3.0;
     vec2 coordinate = textureCoordinate;
     vec4 outColor = texture2D(inputImageTexture, coordinate);
     int result = 0;

     float h = (resolution.x >= resolution.y) ? 0.18 : 0.08;
     float w = 0.8;
     float count  = (resolution.x >= resolution.y) ? 4.0 : 8.0;

     if(p < 0.3)
     {
         p = p / 0.3;
         for(float i = 0.0; i < count;i=i+1.0)
         {

             if(fract(i/2.0) == 0.0 && coordinate.x < (1.0 - (1.0 - w)/2.0) && coordinate.x > ((1.0 - w)/2.0 + w - w * p) &&
                coordinate.y > (0.1+i*(h+0.02)) && coordinate.y < (0.1 + i*(h+0.02) + h))
             {

                 coordinate.x = (coordinate.x-0.1)/0.8;
                 coordinate.y = (coordinate.y-0.1)/0.8;
                 outColor = mix(outColor,texture2D(inputImageTexture, coordinate),1.0);
                 result = 1;
                 break;
             }
             else if(fract(i/2.0) != 0.0 && (coordinate.x > (1.0 - w)/2.0) && (coordinate.x < 0.1 + w * p) &&
                     (coordinate.y > (0.1+i*(h+0.02)) && coordinate.y < (0.1 + i*(h+0.02) + h)))
             {

                 coordinate.x = (coordinate.x-0.1)/0.8;
                 coordinate.y = (coordinate.y-0.1)/0.8;
                 outColor = mix(outColor,texture2D(inputImageTexture, coordinate),1.0);
                 result = 1;
                 break;
             }
         }
         if(0 == result)
             outColor.rgb *= (1.0 - p);

     }
     else if(p < 0.6)
     {
         p = (p - 0.3) / 0.3;
         for(float i = 0.0;i<count;i++)
         {
             float y = i * ( h + 0.02 ) + 0.1;

             if((coordinate.x < (1.0 - (1.0 - w)/2.0) && coordinate.x > (1.0 - w)/2.0) &&
                (coordinate.y > y && coordinate.y < ((y+h) + 0.02 * p)))
             {
                 coordinate.x = (coordinate.x-0.1)/0.8;
                 coordinate.y = (coordinate.y-0.1)/0.8;
                 outColor = mix(outColor,texture2D(inputImageTexture, coordinate),1.0);
                 result = 1;
                 break;
             }
         }
         if(0 == result)
             outColor.rgb *= 0.2 ;
     }
     else
     {
         if((coordinate.x < (1.0 - (1.0 - w)/2.0) && coordinate.x > (1.0 - w)/2.0) &&
            (coordinate.y < (1.0 - (1.0 - w)/2.0) && coordinate.y > (1.0 - w)/2.0))
         {
             coordinate.x = (coordinate.x-0.1)/0.8;
             coordinate.y = (coordinate.y-0.1)/0.8;
             outColor = mix(outColor,texture2D(inputImageTexture, coordinate),1.0);
         }
         else
             outColor.rgb *= 0.2 ;
     }

     gl_FragColor    = outColor;

     
#if 0
     //定格 - 抖动特效 - RDBuiltIn_freezeFrameShake
     float process_time = time;
     while(process_time > 3.0)
         process_time = process_time - 3.0;
     float p = process_time/3.0;
     vec2 coordinate = textureCoordinate;
     vec4 outColor = texture2D(inputImageTexture, coordinate);

     //旋转变形
     float angle = 0.1;
     vec2 o = vec2(0.0,0.0);
     coordinate = textureCoordinate;
     vec2 viewportScale    = vec2(0.0,0.0);

     if(90.0 == rotateAngle || -90.0 == rotateAngle || 270.0 == rotateAngle || -270.0 == rotateAngle)
         viewportScale    = resolution.y < resolution.x ? vec2( resolution.x / resolution.y, 1.0 ) : vec2( 1.0, resolution.y / resolution.x );
     else
         viewportScale    = resolution.x < resolution.y ? vec2( 1.0, resolution.y / resolution.x ) : vec2( resolution.x / resolution.y, 1.0 );

     if(p < 0.2)
     {
         float total_count = 8.0;
         float per_time = 0.2/total_count;
         for(float count = 0.0; count < total_count ; count += 1.0)
         {
             if(p >= count *per_time && p <= (count+1.0)*per_time)
             {
                 if(count == 0.0 || count == 2.0 ||count == 4.0||count == 6.0)
                     angle = (count == 0.0) ? (p/per_time*angle) : ((p - (count*per_time))/per_time*angle);
                 else
                     angle =  (1.0 - (p - (count*per_time))/per_time)*angle;

                 if(count == 0.0 || count == 1.0 || count == 4.0 || count == 5.0)
                     angle = -angle;
                 else
                     angle = angle;

                 break;
             }
         }
         //平移到原点位置
         coordinate -= vec2(0.5, 0.5);
         coordinate *= viewportScale;

         o.x = coordinate.x*cos(angle) - coordinate.y*sin(angle);
         o.y = coordinate.x*sin(angle) + coordinate.y*cos(angle);

         o /= viewportScale;

         //平移回图片原位置
         o += vec2(0.5, 0.5);
         if(o.x < 0.0 || o.x > 1.0 ||o.y < 0.0 || o.y > 1.0 )
             outColor    = vec4(1.0,1.0,1.0,1.0);
         else
             outColor    = texture2D( inputImageTexture, o);

     }
     else
     {
         vec2 size = (resolution.x > resolution.y ) ? vec2(0.02,resolution.x/resolution.y*0.02):vec2(resolution.y/resolution.x*0.02,0.02);
         if(p < 0.25)
         {
             p = (p - 0.2)/0.05;
#ifdef ANDROID
             if(textureCoordinate.x > (1.0 - size.x) && textureCoordinate.y>(1.0-p))
#else
             if(textureCoordinate.x > (1.0 - size.x) && textureCoordinate.y<p)
#endif
                 outColor    = vec4(1.0,1.0,1.0,1.0);
             else
                 outColor    = texture2D( inputImageTexture, textureCoordinate);

         }
         else if(p < 0.3)
         {
             p = (p - 0.25)/0.05;
#ifdef ANDROID
             if(textureCoordinate.x > (1.0 - size.x) || (textureCoordinate.y < size.y && textureCoordinate.x > (1.0 - p)))
#else
             if(textureCoordinate.x > (1.0 - size.x) || (textureCoordinate.y > (1.0 - size.y) && textureCoordinate.x > (1.0 - p)))
#endif
                 outColor    = vec4(1.0,1.0,1.0,1.0);
             else
                 outColor    = texture2D( inputImageTexture, textureCoordinate);
         }
         else if(p < 0.35)
         {
             p = (p - 0.3)/0.05;
#ifdef ANDROID
             if(textureCoordinate.x > (1.0 - size.x) || textureCoordinate.y < size.y ||
                (textureCoordinate.x < size.x && textureCoordinate.y < p))
#else
             if(textureCoordinate.x > (1.0 - size.x) || textureCoordinate.y > (1.0 - size.y) ||
                (textureCoordinate.x < size.x && textureCoordinate.y > (1.0-p)))
#endif
                 outColor    = vec4(1.0,1.0,1.0,1.0);
             else
                 outColor    = texture2D( inputImageTexture, textureCoordinate);
         }
         else if(p < 0.4)
         {
             p = (p - 0.35)/0.1;
#ifdef ANDROID
             if(textureCoordinate.x > (1.0 - size.x) || textureCoordinate.y < size.y ||
                textureCoordinate.x < size.x || (textureCoordinate.y > (1.0 - size.y) && textureCoordinate.x < p))
#else
             if(textureCoordinate.x > (1.0 - size.x) || textureCoordinate.y > (1.0 - size.y) ||
                textureCoordinate.x < size.x || (textureCoordinate.y < size.y && textureCoordinate.x < p))
#endif
                 outColor    = vec4(1.0,1.0,1.0,1.0);
             else
                 outColor    = texture2D( inputImageTexture, textureCoordinate);
         }
         else
         {
             if(textureCoordinate.x > (1.0 - size.x) ||
                textureCoordinate.y > (1.0 - size.y) ||
                textureCoordinate.x < size.x || textureCoordinate.y < size.y)
                 outColor    = vec4(1.0,1.0,1.0,1.0);
             else
                 outColor    = texture2D( inputImageTexture, textureCoordinate);
         }
     }

     gl_FragColor = outColor;
#endif
     //定格 - 9屏特效 - RDBuiltIn_freezeFrameGrid
#if 0
     float process_time = time;
     while(process_time > 3.0)
         process_time = process_time - 3.0;
     float p = process_time / 3.0;
     vec2 coordinate = textureCoordinate;
     vec4 outColor = texture2D(inputImageTexture, coordinate);
 
     float factor = 1.0/3.0;
     
     if(p < 0.15)
     {
         p = p/0.15;
         if(coordinate.y > factor && coordinate.y < factor*2.0)
         {
             if(coordinate.x > 1.0 - p)
             {
                 float pos_x = coordinate.x - (1.0 - p);
                 coordinate.x = fract(pos_x/factor);
                 coordinate.y = (coordinate.y - factor)/factor;
             }
         }
         else
         {
             if(coordinate.x < p)
             {
                 float pos_x =  p - coordinate.x;
                 coordinate.x = 1.0 - fract(pos_x/factor);
                 coordinate.y = (coordinate.y < factor ) ? (coordinate.y/factor) : ((coordinate.y - factor * 2.0)/factor) ;
             }
         }
         outColor = mix(outColor,texture2D(inputImageTexture, coordinate),p);
     }
     else
     {
         if(p <= 0.5)
             p = (process_time / 4.0 - 0.15)/0.35;
         else
             p = 1.0;
         
         if(coordinate.y > factor && coordinate.y < factor*2.0)
         {
             coordinate.x = fract(coordinate.x/factor);
             coordinate.y = (coordinate.y - factor)/factor;
         }
         else
         {
             float pos_x =  1.0 - coordinate.x;
             coordinate.x = 1.0 - fract(pos_x/factor);
             coordinate.y = (coordinate.y < factor ) ? (coordinate.y/factor) : ((coordinate.y - factor * 2.0)/factor) ;
         }
         
         outColor = texture2D(inputImageTexture, coordinate);
         
         float cur_index = ceil(textureCoordinate.x / factor) + (ceil(textureCoordinate.y / factor) - 1.0)*3.0;
#ifdef ANDROID
         if(3.0 == cur_index )
             outColor = texture2D(inputImageTexture, coordinate) * vec4(232.0/255.0,249.0/255.0,128.0/255.0,1.0);
         if(2.0 == cur_index && p > 0.11)
             outColor = texture2D(inputImageTexture, coordinate) * vec4(165.0/255.0,255.0/255.0,164.0/255.0,1.0);
         if(1.0 == cur_index && p > 0.22)
             outColor = texture2D(inputImageTexture, coordinate) * vec4(131.0/255.0,224.0/255.0,185.0/255.0,1.0);
         if(4.0 == cur_index && p > 0.33)
             outColor = texture2D(inputImageTexture, coordinate) * vec4(140.0/255.0,144.0/255.0,207.0/255.0,1.0);
         if(7.0 == cur_index && p > 0.44)
             outColor = texture2D(inputImageTexture, coordinate) * vec4(220.0/255.0,112.0/255.0,122.0/255.0,1.0);
         if(8.0 == cur_index && p > 0.55)
             outColor = texture2D(inputImageTexture, coordinate) * vec4(209.0/255.0,122.0/255.0,167.0/255.0,1.0);
         if(9.0 == cur_index && p > 0.66)
             outColor = texture2D(inputImageTexture, coordinate) * vec4(180.0/255.0,107.0/255.0,246.0/255.0,1.0);
         if(6.0 == cur_index && p > 0.77)
             outColor = texture2D(inputImageTexture, coordinate) * vec4(128.0/255.0,218.0/255.0,247.0/255.0,1.0);
         if(5.0 == cur_index && p > 0.99)
             outColor = texture2D(inputImageTexture, coordinate) * vec4(138.0/255.0,165.0/255.0,237.0/255.0,1.0);
#else
         if(9.0 == cur_index )
             outColor = texture2D(inputImageTexture, coordinate) * vec4(232.0/255.0,249.0/255.0,128.0/255.0,1.0);
         if(8.0 == cur_index && p > 0.11)
             outColor = texture2D(inputImageTexture, coordinate) * vec4(165.0/255.0,255.0/255.0,164.0/255.0,1.0);
         if(7.0 == cur_index && p > 0.22)
             outColor = texture2D(inputImageTexture, coordinate) * vec4(131.0/255.0,224.0/255.0,185.0/255.0,1.0);
         if(4.0 == cur_index && p > 0.33)
             outColor = texture2D(inputImageTexture, coordinate) * vec4(140.0/255.0,144.0/255.0,207.0/255.0,1.0);
         if(1.0 == cur_index && p > 0.44)
             outColor = texture2D(inputImageTexture, coordinate) * vec4(220.0/255.0,112.0/255.0,122.0/255.0,1.0);
         if(2.0 == cur_index && p > 0.55)
             outColor = texture2D(inputImageTexture, coordinate) * vec4(209.0/255.0,122.0/255.0,167.0/255.0,1.0);
         if(3.0 == cur_index && p > 0.66)
             outColor = texture2D(inputImageTexture, coordinate) * vec4(180.0/255.0,107.0/255.0,246.0/255.0,1.0);
         if(6.0 == cur_index && p > 0.77)
             outColor = texture2D(inputImageTexture, coordinate) * vec4(128.0/255.0,218.0/255.0,247.0/255.0,1.0);
         if(5.0 == cur_index && p > 0.99)
             outColor = texture2D(inputImageTexture, coordinate) * vec4(138.0/255.0,165.0/255.0,237.0/255.0,1.0);
#endif
     }
     gl_FragColor = outColor;
     
#endif

 }
 
 
 );

NSString*  const kRDCustomFilterillusionVertexShader = SHADER_STRING
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

NSString*  const kRDCustomFilterillusionFragmentShader = SHADER_STRING
(
 //幻觉
#ifdef GL_FRAGMENT_PRECISION_HIGH
 precision highp float;
#else
 precision mediump float;
#endif
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputTextureLast; // 上一次的纹理
 varying vec2 textureCoordinate;
 
 uniform  float time;
 
 // 分RGB通道混合，不同颜色通道混合值不一样
 const lowp vec3 blendValue = vec3(0.1, 0.3, 0.6);
 // const lowp vec3 blendValue = vec3(0.3, 0.6, 0.9);
 
 void main()
 {
#if 1
     // 当前纹理颜色
     vec4 currentColor = texture2D(inputImageTexture, textureCoordinate);
     // 上一轮纹理颜色
     vec4 lastColor = texture2D(inputTextureLast, textureCoordinate);
     // 将两者混合
     gl_FragColor = vec4(mix(lastColor.rgb, currentColor.rgb, blendValue), currentColor.w);
#else
     vec2 coordinate = textureCoordinate;
     
     
     float row = 2.0;       //row
     float column = 2.0;    //column
     
     float process_time = time;
     float process = 0.0;
     
     float row_factor = 1.0/row;
     float column_factor = 1.0/column;
     
     
     float cur_row = floor(textureCoordinate.y/row_factor);
     float cur_column = floor(textureCoordinate.x/column_factor);
     
     if(textureCoordinate.y >= cur_row*row_factor && textureCoordinate.y < (cur_row+1.0)*row_factor)
     {
         coordinate.y = textureCoordinate.y-cur_row*row_factor;
         coordinate.y = coordinate.y*row-floor(coordinate.y*row);
         if(row != column)
             coordinate.y = coordinate.y/row+(1.0-row_factor)/2.0;
     }
     
     if(textureCoordinate.x >= cur_column*column_factor && textureCoordinate.x < (cur_column+1.0)*column_factor)
     {
         coordinate.x = textureCoordinate.x-cur_column*column_factor;
         coordinate.x = coordinate.x*column-floor(coordinate.x*column);
         if(row != column)
             coordinate.x = coordinate.x/column+(1.0-column_factor)/2.0;
     }
     
     
     while(process_time > 4.0)
         process_time = process_time - 4.0;
     process = process_time / 4.0;
     
     if(process< 0.25)
     {
         if(0.0 == cur_row && 0.0 == cur_column)
             gl_FragColor = texture2D(inputImageTexture, coordinate);
         else
             gl_FragColor = texture2D(inputTextureLast, coordinate);
     }
     else if(process >= 0.25 && process < 0.5)
     {
         if(0.0 == cur_row && 1.0 == cur_column)
             gl_FragColor = texture2D(inputImageTexture, coordinate);
         else
             gl_FragColor = texture2D(inputTextureLast, coordinate);
     }
     else if(process >= 0.5 && process < 0.75)
     {
         if(1.0 == cur_row && 0.0 == cur_column)
             gl_FragColor = texture2D(inputImageTexture, coordinate);
         else
             gl_FragColor = texture2D(inputTextureLast, coordinate);
     }
     else
     {
         if(1.0 == cur_row && 1.0 == cur_column)
             gl_FragColor = texture2D(inputImageTexture, coordinate);
         else
             gl_FragColor = texture2D(inputTextureLast, coordinate);
     }
    
     
     
#endif
 }
 
 
 );



NSString*  const kRDCustomFilterPencilVertexShader = SHADER_STRING
(
 //pencil
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;
 
 uniform float   time;
#if 0
 uniform float   ShadeCrossHatchingSize;
 uniform float   PencilDetaliedLineSize;
#else
 float   ShadeCrossHatchingSize = 1.0;
 float   PencilDetaliedLineSize = 1.0;
#endif
 uniform  int     PencilPaintType;
 uniform  vec2 resolution;
 vec2    DstSinglePixelSize = vec2(1.0/resolution.x,1.0/resolution.y);   //单个像素在目标纹理中的大小。
 //例如目标纹理将被渲染为 800*600 的矩形，那么单个像素就是 (1/800, 1/600)
#define PENCIL_RESOURCE_ORG_SIZE 3000.0
 
 
 varying vec2    vPencilPixPos[8];
 varying vec2    textureCoordinate;
 //Random number from 2D coordinates:
 
 float rand(vec2 co)
{
    return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
}
 void main()
{
    float   PencilPosRand = time;
    vec2 vTextueCoords = inputTextureCoordinate;
    
    float        fScs[8];
    fScs[0] = 0.5; fScs[1] = 0.4; fScs[2] = 0.35; fScs[3] = 0.7; fScs[4] = 0.8; fScs[5] = 0.3; fScs[6] = 0.35; fScs[7] = 0.35;
    if ( PencilPaintType == 3 )
    {
        fScs[1] = 0.5;
        fScs[5] = 0.6;
    }
    else if ( PencilPaintType == 4 )
    {
        fScs[1] = 0.5;
        fScs[5] = 0.8;
    }
    
    vec2 pencilXY = vTextueCoords + rand( vec2( PencilPosRand, PencilPosRand ) );
    vPencilPixPos[0].x = pencilXY.x / (PENCIL_RESOURCE_ORG_SIZE * fScs[0] * DstSinglePixelSize.x);
    vPencilPixPos[0].y = pencilXY.y / (PENCIL_RESOURCE_ORG_SIZE * fScs[0] * DstSinglePixelSize.y);
    for ( int i = 1; i < 6; ++i )
    {
        vPencilPixPos[i].x = pencilXY.x / (PENCIL_RESOURCE_ORG_SIZE * fScs[i] * ShadeCrossHatchingSize * DstSinglePixelSize.x);
        vPencilPixPos[i].y = pencilXY.y / (PENCIL_RESOURCE_ORG_SIZE * fScs[i] * ShadeCrossHatchingSize * DstSinglePixelSize.y);
    }
    vPencilPixPos[6].x = ( pencilXY.y) / (PENCIL_RESOURCE_ORG_SIZE * fScs[6] * ShadeCrossHatchingSize * DstSinglePixelSize.x);
    vPencilPixPos[6].y = ( pencilXY.x) / (PENCIL_RESOURCE_ORG_SIZE * fScs[6] * ShadeCrossHatchingSize * DstSinglePixelSize.y);
    vPencilPixPos[7].x = (1.0 - pencilXY.y) / (PENCIL_RESOURCE_ORG_SIZE * fScs[7] * ShadeCrossHatchingSize * DstSinglePixelSize.x);
    vPencilPixPos[7].y = ( pencilXY.x) / (PENCIL_RESOURCE_ORG_SIZE * fScs[7] * ShadeCrossHatchingSize * DstSinglePixelSize.y);
    
    gl_Position = position;
    textureCoordinate = inputTextureCoordinate;
}
 
 );

NSString*  const kRDCustomFilterPencilFragmentShader = SHADER_STRING
(
#ifdef GL_FRAGMENT_PRECISION_HIGH
 precision highp float;
 precision highp int;
#else
 precision mediump float;
 precision mediump int;
#endif
 //Pencil
 
 uniform sampler2D inputImageTexture;
 varying vec2 textureCoordinate;
 
 uniform  float time;
 uniform  highp vec2 resolution;
 
 
 //铅笔效果滤镜
 uniform sampler2D   TexturePencilResource;    //铅笔素材纹理
#if 0
 uniform float   ShadeCrossHatchingSize;    //用于表示明暗的交叉线的粗细。默认1.0，如果图像分辨率低，可以设置得更小，例如 0.5, 0.2 等。
 uniform float   PencilDetaliedLineSize;    //用于勾画轮廓的线条粗细。默认1.0，也可以设置得更低。一般不要超过2.0，否则轮廓线不清晰。
 uniform int     PencilPaintType;  //类型：0=铅笔素描；1=彩色铅笔；2=铅笔+淡水彩；3=炭笔素描；4=蜡笔画
 uniform float   ColoringChroma;    //着色的浓度。默认1.0，此参数只对“彩色铅笔”、“铅笔+淡水彩”、“蜡笔画”效果有效
#else
 float   ShadeCrossHatchingSize = 1.0;    //用于表示明暗的交叉线的粗细。默认1.0，如果图像分辨率低，可以设置得更小，例如 0.5, 0.2 等。
 float   PencilDetaliedLineSize = 1.0;    //用于勾画轮廓的线条粗细。默认1.0，也可以设置得更低。一般不要超过2.0，否则轮廓线不清晰。
 uniform highp int     PencilPaintType;  //类型：0=铅笔素描；1=彩色铅笔；2=铅笔+淡水彩；3=炭笔素描；4=蜡笔画
 float   ColoringChroma = 1.0;    //着色的浓度。默认1.0，此参数只对“彩色铅笔”、“铅笔+淡水彩”、“蜡笔画”效果有效
 
#endif
 
 //例如目标纹理将被渲染为 800*600 的矩形，那么单个像素就是 1/800, 1/600
 
 varying vec2    vPencilPixPos[8]; //从素材纹理上取像素的坐标，这是在顶点着色器中计算的，以提高效率。
 float    pencilPixel[8];
 vec2    DstSinglePixelSize = vec2(1.0/resolution.x,1.0/resolution.y);
 
 float mappingPencil( float light )
{
    float alpha = light > 0.95 ? 0.4 - ( light - 0.95 ) * 0.25 / 0.05 : 0.4;
    float color = pencilPixel[1] * alpha + ( 1.0 - alpha );
    if ( light <= 0.125 )
    {
        color *= ( light / 0.125 * 0.9 );
    }
    if ( light < 0.125 )
    {
        if ( light < 0.0625 )
        {
            color *= pencilPixel[6];
        }
        else{
            alpha = 1.0 - (light - 0.0625) / (0.125 - 0.0625);
            color = ( color * pencilPixel[6] - color ) * alpha + color;
        }
    }
    if ( light < 0.25 )
    {
        if ( light < 0.125 )
        {
            color *= pencilPixel[7];
        }
        else{
            alpha = 1.0 - (light - 0.125) / (0.25 - 0.125);
            color = ( color * pencilPixel[7] - color ) * alpha + color;
        }
    }
    
    if ( light < 0.375 )
    {
        if ( light < 0.3 )
        {
            color *= pencilPixel[2];
        }
        else{
            alpha = 1.0 - (light - 0.3) / (0.375 - 0.3);
            color = ( color * pencilPixel[2] - color ) * alpha + color;
        }
    }
    
    if ( light < 0.5 )
    {
        color *= pencilPixel[3];
    }
    if ( light < 0.625 )
    {
        color *= pencilPixel[5];
        if ( light < 0.5625 )
        {
            color *= pencilPixel[4];
        }
        else
        {
            alpha = 1.0 - (light - 0.5625) / (0.625 - 0.5625);
            color = (color * pencilPixel[4] - color ) * alpha + color;
        }
    }
    
    color *= pencilPixel[0];
    
    
    return color;
}
 
 
 vec4 rgbToHsv( vec4 rgbPix )
{
    vec4 hsvPix;
    float maxV = max( rgbPix.r, max(rgbPix.g, rgbPix.b) );
    float minV = min( rgbPix.r, min(rgbPix.g, rgbPix.b) );
    float d = maxV - minV;
    hsvPix.b = maxV;
    if ( d > 0.0 )
    {
        hsvPix.g = d / maxV;
        if ( maxV == rgbPix.r )
            hsvPix.r = (rgbPix.g - rgbPix.b) / d * 60.0;
        else if ( maxV == rgbPix.g )
            hsvPix.r = (rgbPix.b - rgbPix.r) / d * 60.0 + 120.0;
        else if ( maxV == rgbPix.b )
            hsvPix.r = (rgbPix.r - rgbPix.g) / d * 60.0 + 240.0;
        if ( hsvPix.r < 0.0 ) hsvPix.r += 360.0;
    }
    else{
        hsvPix.g = hsvPix.r = 0.0;
    }
    hsvPix.a = rgbPix.a;
    return hsvPix;
}
 
 vec4 hsvToRgb( vec4 hsvPix )
{
    vec4 rgbPix;
    if ( hsvPix.g == 0.0 )
    {
        rgbPix.r = rgbPix.g = rgbPix.b = hsvPix.b;
    }
    else{
        float H = hsvPix.r / 60.0;
        int    i = int(H);
        float f = ( H - float(i) );
        float v = hsvPix.b;
        float a = v * ( 1.0 - hsvPix.g );
        float b = v * ( 1.0 - hsvPix.g * f );
        float c = v * ( 1.0 - hsvPix.g * ( 1.0 - f ) );
        if( 0 == i || 6 == i){
            rgbPix.r = v; rgbPix.g = c; rgbPix.b = a;
        }
        else if( 1 == i){
            rgbPix.r = b; rgbPix.g = v; rgbPix.b = a;
        }
        else if( 2 == i){
            rgbPix.r = a; rgbPix.g = v; rgbPix.b = c;
        }
        else if( 3 == i){
            rgbPix.r = a; rgbPix.g = b; rgbPix.b = v;
        }
        else if( 4 == i){
            rgbPix.r = c; rgbPix.g = a; rgbPix.b = v;
        }
        else if( 5 == i){
            rgbPix.r = v; rgbPix.g = a; rgbPix.b = b;
        }
        
    }
    rgbPix.a = hsvPix.a;
    return rgbPix;
}
 
 vec4 rgbToYuv(vec4 rgbPix)
{
    return vec4( rgbPix.r * 0.2990 + rgbPix.g * 0.5870 + rgbPix.b * 0.1140,
                rgbPix.r * -0.1687 + rgbPix.g * -0.3313 + rgbPix.b * 0.5000 + 0.5,
                rgbPix.r * 0.5000 - rgbPix.g * 0.4187 - rgbPix.b * 0.0813 + 0.5,
                rgbPix.a );
}
 
 vec4 yuvToRgb(vec4 yuvPix)
{
    return vec4( yuvPix.r + 1.402 * ( yuvPix.b - 0.5 ),
                yuvPix.r - 0.34413 * ( yuvPix.g - 0.5 ) - 0.71414 * (yuvPix.b - 0.5 ),
                yuvPix.r + 1.772 * ( yuvPix.g - 0.5 ),
                yuvPix.a );
}
 
 void main()
{
    //         //铅笔
    vec2    vTextueCoords = textureCoordinate;  //纹理坐标
    vec4    colorPixels;
    vec4    avgColor;
    vec4    maxColor;
    float   sumLight = 0.0;
    float   avglight = 0.0;
    float   maxLight = 0.0;
    float    lineSizeX = PencilDetaliedLineSize * DstSinglePixelSize.x;
    float    lineSizeY = PencilDetaliedLineSize * DstSinglePixelSize.y;
    if ( PencilDetaliedLineSize < 1.5 )
    {
        for ( float y = -1.0; y <= 1.0; ++y )
        {
            for ( float x = -1.0; x <= 1.0; ++x )
            {
                colorPixels = texture2D(inputImageTexture, vec2(vTextueCoords.x + x * lineSizeX, vTextueCoords.y + y * lineSizeY) );
                avgColor += colorPixels;
                avglight = ( max(colorPixels.r, max(colorPixels.g, colorPixels.b)) + min(colorPixels.r, min(colorPixels.g, colorPixels.b)) ) * 0.5;
                sumLight += avglight;
                maxLight = max( maxLight, avglight );
                maxColor.r = max( maxColor.r, colorPixels.r );
                maxColor.g = max( maxColor.g, colorPixels.g );
                maxColor.b = max( maxColor.b, colorPixels.b );
                maxColor.a = max( maxColor.a, colorPixels.a );
            }
        }
        avgColor /= 9.0;
        avglight = sumLight * 1.0 / 9.0;
    }
    else if ( PencilDetaliedLineSize < 3.5 )
    {
        lineSizeX = PencilDetaliedLineSize * DstSinglePixelSize.x * 0.5;
        lineSizeY = PencilDetaliedLineSize * DstSinglePixelSize.y * 0.5;
        for ( float y = -2.0; y <= 2.0; ++y )
        {
            for ( float x = -2.0; x <= 2.0; ++x )
            {
                colorPixels = texture2D(inputImageTexture, vec2(vTextueCoords.x + x * lineSizeX, vTextueCoords.y + y * lineSizeY) );
                avgColor += colorPixels;
                avglight = ( max(colorPixels.r, max(colorPixels.g, colorPixels.b)) + min(colorPixels.r, min(colorPixels.g, colorPixels.b)) ) * 0.5;
                sumLight += avglight;
                maxLight = max( maxLight, avglight );
                maxColor.r = max( maxColor.r, colorPixels.r );
                maxColor.g = max( maxColor.g, colorPixels.g );
                maxColor.b = max( maxColor.b, colorPixels.b );
                maxColor.a = max( maxColor.a, colorPixels.a );
            }
        }
        avgColor /= 25.0;
        avglight = sumLight * 1.0 / 25.0;
    }
    else
    {
        lineSizeX = PencilDetaliedLineSize * DstSinglePixelSize.x * 0.3333333333333;
        lineSizeY = PencilDetaliedLineSize * DstSinglePixelSize.y * 0.3333333333333;
        for ( float y = -3.0; y <= 3.0; ++y )
        {
            for ( float x = -3.0; x <= 3.0; ++x )
            {
                colorPixels = texture2D(inputImageTexture, vec2(vTextueCoords.x + x * lineSizeX, vTextueCoords.y + y * lineSizeY) );
                avgColor += colorPixels;
                avglight = ( max(colorPixels.r, max(colorPixels.g, colorPixels.b)) + min(colorPixels.r, min(colorPixels.g, colorPixels.b)) ) * 0.5;
                sumLight += avglight;
                maxLight = max( maxLight, avglight );
                maxColor.r = max( maxColor.r, colorPixels.r );
                maxColor.g = max( maxColor.g, colorPixels.g );
                maxColor.b = max( maxColor.b, colorPixels.b );
                maxColor.a = max( maxColor.a, colorPixels.a );
            }
        }
        avgColor /= 49.0;
        avglight = sumLight * 1.0 / 49.0;
    }
    pencilPixel[0] = texture2D( TexturePencilResource, vPencilPixPos[0]  - floor(vPencilPixPos[0])).b;
    pencilPixel[1] = texture2D( TexturePencilResource, vPencilPixPos[1]  - floor(vPencilPixPos[1])).r;
    pencilPixel[2] = texture2D( TexturePencilResource, vPencilPixPos[2]  - floor(vPencilPixPos[2])).g;
    pencilPixel[3] = texture2D( TexturePencilResource, vPencilPixPos[3]  - floor(vPencilPixPos[3])).r;
    pencilPixel[4] = texture2D( TexturePencilResource, vPencilPixPos[4]  - floor(vPencilPixPos[4])).r;
    pencilPixel[5] = texture2D( TexturePencilResource, vPencilPixPos[5]  - floor(vPencilPixPos[5])).r;
    pencilPixel[6] = texture2D( TexturePencilResource, vPencilPixPos[6]  - floor(vPencilPixPos[6])).g;
    pencilPixel[7] = texture2D( TexturePencilResource, vPencilPixPos[7]  - floor(vPencilPixPos[7])).g;
    
    
    if ( PencilPaintType == 0 )
    {
        float    color = mappingPencil( avglight );
        maxLight = avglight + ( (1.0 - maxLight) * avglight ) / maxLight;
        color *= maxLight * maxLight;
        avgColor.r = avgColor.g = avgColor.b = color;
    }
    else if ( PencilPaintType == 1 )
    {
        avgColor = rgbToHsv(avgColor);
        avgColor.b = mappingPencil( avgColor.b );
        avgColor.g *= ColoringChroma * ( 1.0 - mappingPencil( avglight ) );
        maxLight = avglight + ( (1.0 - maxLight) * avglight ) / maxLight;
        avgColor.b *= maxLight * maxLight;
        avgColor = hsvToRgb(avgColor);
    }
    else if ( PencilPaintType == 2 )
    {
        avgColor = rgbToYuv(maxColor);
        avgColor.r = mappingPencil( avgColor.r );
        maxLight = avglight + ( (1.0 - maxLight) * avglight ) / maxLight;
        avgColor.r *= maxLight * maxLight;
        avgColor = yuvToRgb(avgColor);
        avgColor = rgbToHsv(avgColor);
        avgColor.g *= ColoringChroma;
        avgColor = hsvToRgb(avgColor);
    }
    else if ( PencilPaintType == 3 )
    {
        for ( int i = 1; i < 8; ++i )
        {
            if ( pencilPixel[i] < 0.5 )
                pencilPixel[i] = 0.0;
            else if ( pencilPixel[i] < 0.8 )
                pencilPixel[i] = ( pencilPixel[i] - 0.5 ) / 0.3 * 0.5;
            else
                pencilPixel[i] = ( pencilPixel[i] - 0.8 ) / 0.2 * 0.5 + 0.5;
        }
        float    color = mappingPencil( avglight );
        maxLight = avglight + ( (1.0 - maxLight) * avglight ) / maxLight;
        color *= maxLight * maxLight;
        avgColor.r = avgColor.g = avgColor.b = color;
    }
    else if ( PencilPaintType == 4 )
    {
        for ( int i = 2; i < 8; ++i )
        {
            if ( pencilPixel[i] < 0.5 )
                pencilPixel[i] = 0.0;
            else if ( pencilPixel[i] < 0.8 )
                pencilPixel[i] = ( pencilPixel[i] - 0.5 ) / 0.3 * 0.5;
            else
                pencilPixel[i] = ( pencilPixel[i] - 0.8 ) / 0.2 * 0.5 + 0.5;
        }
        pencilPixel[1] = 1.0;
        avgColor.r = mappingPencil(avgColor.r);
        avgColor.b = mappingPencil( avgColor.b );
        avgColor.g = mappingPencil( avgColor.g );
        maxLight = avglight + ( (1.0 - maxLight) * avglight ) / maxLight;
        avgColor.b *= maxLight * maxLight;
        avgColor = rgbToHsv(avgColor);
        avgColor.g *= ColoringChroma;
        avgColor = hsvToRgb(avgColor);
    }
    gl_FragColor = avgColor;
    
}
 
 );


NSString*  const kRDCustomFilterCrossPointVertexShader = SHADER_STRING
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

NSString*  const kRDCustomFilterCrossPointFragmentShader = SHADER_STRING
(
 //
#ifdef GL_FRAGMENT_PRECISION_HIGH
 precision highp float;
 precision highp int;
#else
 precision mediump float;
 precision mediump int;
#endif
 
 uniform sampler2D inputImageTexture;
 varying vec2 textureCoordinate;
 
 uniform  float time;
 uniform  vec2 resolution;
 
 
 uniform sampler2D   TextureRadiationResource;
 
#if 0
 uniform    vec2    CrossPointSize;    //用于表示明暗的交叉线点的大小，单位是像素。建议设置为（5，3）以上，最好是长方形。
 uniform    int     CrossPointType;  //类型：0=黑白网点；1=彩色网点
 uniform    int     CrossPointLayel;  //亮度分层数量
 uniform    float   CrossPointSharp;  //网点的清晰度，值范围 0~1。
 uniform    float   CrossPointContrast;    //转换为网点图之前的对比度调整。默认 1.0 不改变对比度，小于1.0减小对比度，大于1.0增强对比度。建议值 1.2 左右
 
#else
 
 vec2       CrossPointSize = vec2(5.0,3.0);    //用于表示明暗的交叉线点的大小，单位是像素。建议设置为（5，3）以上，最好是长方形。
 int        CrossPointLayel = 5;  //亮度分层数量
 float      CrossPointSharp = 1.0;  //网点的清晰度，值范围 0~1。
 float      CrossPointContrast = 1.2;
 uniform    int     CrossPointType;  //类型：0=黑白网点；1=彩色网点
 
#endif
 
 const float PI = 3.14159265358979323846;
 vec2    DstSinglePixelSize = vec2(1.0/resolution.x,1.0/resolution.y);
 
 float grayscaleCross( vec2 uvPos, float light, int isOffset )
 {
     light = (light - 0.5) * CrossPointContrast + (CrossPointContrast*0.5);
     light = floor(light * float(CrossPointLayel)) / float( CrossPointLayel - 1 );
     vec2 crossHalf = CrossPointSize * 0.5;
     vec2 lightHalf = light * crossHalf;
     
     vec2 crossInd = (isOffset == 1) ? floor( ( uvPos - crossHalf ) / CrossPointSize ) : floor( uvPos / CrossPointSize );
     vec2 centerPos = crossInd * CrossPointSize + ( (isOffset == 1) ? CrossPointSize : crossHalf );
     
     float    left = floor(centerPos.x - lightHalf.x);
     float    right = ceil(centerPos.x + lightHalf.x);
     float    top = floor(centerPos.y - lightHalf.y);
     float    bottom = ceil(centerPos.y + lightHalf.y);
     if ( uvPos.x >= left && uvPos.x < right &&  uvPos.y >= top && uvPos.y < bottom )
     {
         if ( left + 1.0 == right )
         {
             left = lightHalf.x * 2.0;
         }
         else if ( uvPos.x < left + 1.0 )
         {
             left = ( left + 1.0 ) - (centerPos.x - lightHalf.x);
         }
         else if ( uvPos.x > right - 1.0 )
         {
             left =  (centerPos.x + lightHalf.x) - (right - 1.0 );
         }
         else
         {
             left = 1.0;
         }
         
         if ( top + 1.0 == bottom )
         {
             top = lightHalf.y * 2.0;
         }
         else if ( uvPos.y < top + 1.0 )
         {
             top = ( top + 1.0 ) - (centerPos.y - lightHalf.y);
         }
         else if ( uvPos.y > bottom - 1.0 )
         {
             top =  (centerPos.y + lightHalf.y) - (bottom - 1.0 );
         }
         else
         {
             top = 1.0;
         }
         
         light = left * top;
     }
     else
     {
         light = 0.0;
     }
     
     return light;
 }
 vec4 rgbToYuv(vec4 rgbPix)
 {
     return vec4( rgbPix.r * 0.2990 + rgbPix.g * 0.5870 + rgbPix.b * 0.1140,
                 rgbPix.r * -0.1687 + rgbPix.g * -0.3313 + rgbPix.b * 0.5000 + 0.5,
                 rgbPix.r * 0.5000 - rgbPix.g * 0.4187 - rgbPix.b * 0.0813 + 0.5,
                 rgbPix.a );
 }
 
 vec4 yuvToRgb(vec4 yuvPix)
 {
     return vec4( yuvPix.r + 1.402 * ( yuvPix.b - 0.5 ),
                 yuvPix.r - 0.34413 * ( yuvPix.g - 0.5 ) - 0.71414 * (yuvPix.b - 0.5 ),
                 yuvPix.r + 1.772 * ( yuvPix.g - 0.5 ),
                 yuvPix.a );
 }
 
 vec4 rgbToHsv( vec4 rgbPix )
 {
     vec4 hsvPix;
     float maxV = max( rgbPix.r, max(rgbPix.g, rgbPix.b) );
     float minV = min( rgbPix.r, min(rgbPix.g, rgbPix.b) );
     float d = maxV - minV;
     hsvPix.b = maxV;
     if ( d > 0.0 )
     {
         hsvPix.g = d / maxV;
         if ( maxV == rgbPix.r )
             hsvPix.r = (rgbPix.g - rgbPix.b) / d * 60.0;
         else if ( maxV == rgbPix.g )
             hsvPix.r = (rgbPix.b - rgbPix.r) / d * 60.0 + 120.0;
         else if ( maxV == rgbPix.b )
             hsvPix.r = (rgbPix.r - rgbPix.g) / d * 60.0 + 240.0;
         if ( hsvPix.r < 0.0 ) hsvPix.r += 360.0;
     }
     else{
         hsvPix.g = hsvPix.r = 0.0;
     }
     hsvPix.a = rgbPix.a;
     return hsvPix;
 }
 
 vec4 hsvToRgb( vec4 hsvPix )
 {
     vec4 rgbPix;
     if ( hsvPix.g == 0.0 )
     {
         rgbPix.r = rgbPix.g = rgbPix.b = hsvPix.b;
     }
     else{
         float H = hsvPix.r / 60.0;
         int    i = int(H);
         float f = ( H - float(i) );
         float v = hsvPix.b;
         float a = v * ( 1.0 - hsvPix.g );
         float b = v * ( 1.0 - hsvPix.g * f );
         float c = v * ( 1.0 - hsvPix.g * ( 1.0 - f ) );
         if( 0 == i || 6 == i){
             rgbPix.r = v; rgbPix.g = c; rgbPix.b = a;
         }
         else if( 1 == i){
             rgbPix.r = b; rgbPix.g = v; rgbPix.b = a;
         }
         else if( 2 == i){
             rgbPix.r = a; rgbPix.g = v; rgbPix.b = c;
         }
         else if( 3 == i){
             rgbPix.r = a; rgbPix.g = b; rgbPix.b = v;
         }
         else if( 4 == i){
             rgbPix.r = c; rgbPix.g = a; rgbPix.b = v;
         }
         else if( 5 == i){
             rgbPix.r = v; rgbPix.g = a; rgbPix.b = b;
         }
         
     }
     rgbPix.a = hsvPix.a;
     return rgbPix;
 }
 void main()
 {
     vec2 vTextueCoords = textureCoordinate;
     vec4 pixel = texture2D(inputImageTexture, vTextueCoords );
     if ( CrossPointSharp >= 0.999 && CrossPointSharp <= 1.001 )
     {
         vec2 uvPos = vTextueCoords / DstSinglePixelSize;
         if ( CrossPointType == 0 )
         {
             float light = ( max(pixel.r, max(pixel.g, pixel.b)) + min(pixel.r, min(pixel.g, pixel.b)) ) * 0.5;
             //light = ( sin( light * PI - PI * 0.5 ) * 0.5 ) + 0.5;
             //light = (light - 0.5) * 1.4 + 0.7;
             light = max( grayscaleCross( uvPos, light, 0 ), grayscaleCross( uvPos, light, 1 ) );
             pixel.r = pixel.g = pixel.b = light;
         }
         else{
             pixel.r = max( grayscaleCross( uvPos, pixel.r, 0 ), grayscaleCross( uvPos, pixel.r, 1 ) );
             pixel.g = max( grayscaleCross( uvPos, pixel.g, 0 ), grayscaleCross( uvPos, pixel.g, 1 ) );
             pixel.b = max( grayscaleCross( uvPos, pixel.b, 0 ), grayscaleCross( uvPos, pixel.b, 1 ) );
         }
     }
     else
     {
         float lights[9];
         for ( int y = -1; y <= 1; ++y )
         {
             for ( int x = -1; x <= 1; ++x )
             {
                 vec2 pos = vTextueCoords + vec2( float(x) * DstSinglePixelSize.x, float(y) * DstSinglePixelSize.y );
                 vec4 colorPix = texture2D(inputImageTexture, pos );
                 float lightPix = CrossPointType == 0 ?
                 ( max(colorPix.r, max(colorPix.g, colorPix.b)) + min(colorPix.r, min(colorPix.g, colorPix.b)) ) * 0.5 :
                 colorPix.r * 0.2990 + colorPix.g * 0.5870 + colorPix.b * 0.1140;
                 lightPix = max( grayscaleCross( pos / DstSinglePixelSize, lightPix, 0 ), grayscaleCross( pos / DstSinglePixelSize, lightPix, 1 ) );
                 lights[(y+1) * 3 + (x+1)] = lightPix;
             }
         }
         if ( CrossPointType == 0 )
         {
             pixel.r = pixel.g = pixel.b = ( lights[0] + lights[1] + lights[2] + lights[3] + lights[5] + lights[6] + lights[7] + lights[8] ) * ( 1.0 - CrossPointSharp ) * 0.125 + lights[4] * CrossPointSharp ;
         }
         else
         {
             pixel = rgbToYuv(pixel);
             pixel.r = ( lights[0] + lights[1] + lights[2] + lights[3] + lights[5] + lights[6] + lights[7] + lights[8] ) * ( 1.0 - CrossPointSharp ) * 0.125 + lights[4] * CrossPointSharp ;
             pixel = yuvToRgb(pixel);
         }
     }
     pixel *= texture2D(TextureRadiationResource, vTextueCoords );
     gl_FragColor = pixel;
 }
 );


typedef struct GLTextureList
{
    int width;
    int height;
    GLuint texture;
    NSString *path;
    int index;
    struct GLTextureList* next;
    
}GLTextureList;

typedef struct BlurFBOList
{
    int width;
    int height;
    GLuint hTexture;    //横向模糊
    GLuint vTexture;    //纵向模糊
    GLuint hFbo;
    GLuint vFbo;
    int index;
    
    struct BlurFBOList* next;
    
}FBOList;

typedef struct TextureFBOList
{
    int width ;
    int height;
    GLuint texture;
    GLuint fbo;
    int index;
    
    struct TextureFBOList* next;
    
}TextureFBOList;



@interface RDVideoCompositorRenderer ()
{
    NSMutableDictionary<NSURL *,RDImage*>* rdImageCache;
    NSMutableDictionary<NSURL *,RDACVTexture*>* rdACVTextureCache;
    
    int bufferCount;
    int acvCount;
    GLuint normalPositionAttribute,normalTextureCoordinateAttribute,normalTextureMaskCoordinateAttribute,normalTextureMosaicCoordinateAttribute;
    GLuint normalInputTextureUniform,normalInputTextureUniform2,normalTexture2TypeUniform;
    GLuint filterIntensityUniform;
    GLuint normalInputTextureUniform3;//mask
    GLuint normalInputMaskURLUniform;
    GLuint normalInputAlphaUniform;
    GLuint normalRotateAngleUniform;
    GLuint normalBlurUniform;
    GLuint normalIsBlurredBorderUniform;
    GLuint normalCropOriginUniform;
    GLuint normalCropSizeUniform;
    GLuint normalProjectionUniform,normalTransformUniform,normalFilterUniform,normalVignetteUniform,normalSharpnessUniform,normalWhiteBalanceUniform;
    GLuint normalSrcQuadrilateralUniform;//源四边形的4顶点在纹理上的坐标-纹理的裁剪，顺时针0-1，左上角为0.0
    GLuint normalDstQuadrilateralUniform;//目标四边形的4个顶点坐标-四边形的显示位置，顺时针0-1，左上角为0.0
    GLuint normalDstSinglePixelSizeUniform;//单个像素在目标纹理中的大小。例如目标纹理将被渲染为 800*600 的矩形，那么单个像素就是 1/800, 1/600
    
    
    GLuint blendPositionAttribute,blendTextureCoordinateAttribute;
    GLuint blendInputTextureUniform,blendInputTextureUniform2;
    GLuint blendProjectionUniform,blendTransformUniform,blendColorUniform,blendFactorUniform,blendBrightnessUniform;
    
    
    
    GLuint maskPositionAttribute,maskTextureCoordinateAttribute;
    GLuint maskInputTextureUniform,maskInputTextureUniform2,maskInputTextureUniform3;
    GLuint maskProjectionUniform,maskTransformUniform,maskFactorUniform;
    
    
    
    GLuint vertShader, fragShader, blendFragShader, maskFragShader,transFragShader;
    GLuint mvVertShader,mvFragShader,screenFragShader, hardLightFragShader, chromaKeyFragShader,invertFragShader,grayFragShader;
    GLuint bulgeDistortionFragShader,gridFragShader,simpleFragShader,simpleVertShader;
    GLuint throughBlackColorFragShder,borderBlurFragShader,borderBlurVertShader,blurFragShader,blurVertShader;;
    
    GLuint multiVertShader,multiFragShader;
    GLuint multiPositionAttribute,multiTextureCoordinateAttribute;
    
    GLuint transPositionAttribute,transTextureCoordinateAttribute;
    GLuint transInputTextureUniform;
    GLuint transProjectionUniform, transTransformUniform;
    
    //mv
    GLuint mvPositionAttribute,mvTextureCoordinateAttribute;
    GLuint mvInputTextureUniform,mvInputTextureUniform2;
    
    GLuint screenPositionAttribute,screenTextureCoordinateAttribute;
    GLuint screenInputTextureUniform,screenInputTextureUniform2;
    
    
    GLuint hardLightPositionAttribute,hardLightTextureCoordinateAttribute;
    GLuint hardLightInputTextureUniform,hardLightInputTextureUniform2;
    

    //指定颜色抠图 - 透绿色
    GLuint chromaKeyPositionAttribute,chromaKeyTextureCoordinateAttribute;
    GLuint chromaKeyInputTextureUniform,chromaKeyInputTextureUniform2;
    GLuint chromaKeyColorToReplaceUniform, chromaKeyThresholdSensitivityUniform, chromaKeySmoothingUniform;
    GLuint chromaKeyEdgeModeUniform,chromaKeyThresholdAUniform,chromaKeyThresholdBUniform;
    GLuint chromaKeyThresholdCUniform,chromaKeyBgModeUniform,chromaKeyInputBackGroundImageTexture,chromaKeyInputColorTransparencyImageTexture;
    GLuint chromaKeyInputColorUnifrom;
    
    //自动识别图像并抠图
    GLuint chromaColorVertShader, chromaColorFragShader;
    GLuint chromaColorPositionAttribute,chromaColorTextureCoordinateAttribute;
    GLuint chromaColorInputTextureUniform,chromaColorInputTextureUniform2;
    GLuint chromaColorEdgeModeUniform,chromaColorThresholdAUniform,chromaColorThresholdBUniform;
    GLuint chromaColorThresholdCUniform,chromaColorBgModeUniform;
   
    
    
    GLuint invertPositionAttribute,invertTextureCoordinateAttribute;
    GLuint invertInputTextureUniform,invertInputTextureUniform2;
    GLuint invertProjectionUniform,invertTransformUniform,invertColorUniform,invertFactorUniform,invertBrightnessUniform;
    
    GLuint grayPositionAttribute,grayTextureCoordinateAttribute;
    GLuint grayInputTextureUniform,grayInputTextureUniform2;
    GLuint grayProjectionUniform,grayTransformUniform,grayColorUniform,grayFactorUniform,grayBrightnessUniform;
    
    GLuint bulgeDistortionPositionAttribute,bulgeDistortionTextureCoordinateAttribute;
    GLuint bulgeDistortionInputTextureUniform,bulgeDistortionInputTextureUniform2;
    GLuint bulgeDistortionProjectionUniform,bulgeDistortionTransformUniform,bulgeDistortionColorUniform;
    GLuint bulgeDistortionFactorUniform,bulgeDistortionBrightnessUniform,bulgeDistortionAspectRatioUniform;
    
    GLuint gridPositionAttribute,gridTextureCoordinateAttribute;
    GLuint gridInputTextureUniform,gridInputTextureUniform2;
    GLuint gridProjectionUniform,gridTransformUniform;
    GLuint gridFactorUniform;
    GLuint offscreenGridBufferHandle;
    GLuint offscreenGridTexture;
    
    GLuint simplePositionAttribute,simpleTextureCoordinateAttribute;
    GLuint simpleInputTextureUniform;
    GLuint simpleProjectionUniform,simpleTransformUniform;
    
    
    
    GLuint throughBlackColorPositionAttribute,throughBlackColorTextureCoordinateAttribute;
    GLuint throughBlackColorInputTextureUniform,throughBlackColorInputTextureUniform2;
    GLuint throughBlackColorProjectionUniform,throughBlackColorTransformUniform;
    
    //边框背景模糊
    GLuint borderBlurPositionAttribute,borderBlurTextureCoordinateAttribute;
    GLuint borderBlurInputTextureUniform,borderBlurImageWidthUniform,borderBlurImageHeightUniform;
    GLuint borderBlurProjectionUniform,borderBlurTransformUniform;
    GLuint borderBlurStartValueUniform,borderBlurEndValueUniform;
    GLuint borderBlurResolutionUniform,borderBlurViewportUniform,borderBlurEdgeUniform;
    GLuint borderBlurClipOriginalUniform,borderBlurClipSizeUniform,borderBlurIsFirstUniform,borderBlurRadiusUniform;
    
    //高斯模糊
    GLuint blurPositionAttribute,blurTextureCoordinateAttribute;
    GLuint blurInputTextureUniform,blurImageWidthUniform,blurImageHeightUniform,blurProjectionUniform,blurTransformUniform;
    GLuint blurStartValueUniform,blurEndValueUniform,blurDirectionUniform,blurResolutionUniform;
    GLuint blurPointBLUniform,blurPointTLUniform,blurPointBRUniform,blurPointTRUniform;
    
    //美颜
    GLuint beautyVertShader, beautyFragShader;
    GLuint beautyPositionAttribute,beautyTextureCoordinateAttribute;
    GLuint beautyInputTextureUniform;
    GLuint beautyParamsUniform,beautySingleStepOffsetUniform;
    CleanBackground cleanBackground;
    CleanBackground::BackgroundInfo backgroundInfo;
    

    RDMatrix4 _modelViewMatrix;
    RDMatrix4 _projectionMatrix;
    
    BOOL lockState;
    
    std::map<int,GetInterpolationHandlerFn> m_mapInterpolationHandles;
    RDBlendFilter* blendFilter;
    
#if PARTICLE_DEMO
    //    RDEmitter* pParticleEmitter;
    RDDrawElement* pDrawElement;
    
#endif
    struct BlurFBOList* pBlurFboList;           //模糊
    struct TextureFBOList* pFilterFboList;      //滤镜
    struct TextureFBOList* pDstFboList;         //最终画面
    struct GLTextureList*  pLastTextureList;    //保存当前画面的上一个画面 - 内置滤镜：幻觉
    struct TextureFBOList*  pBeautyFboList;     //美颜
    struct TextureFBOList* pCollageFboList;     //画中画
    struct TextureFBOList* pAssetFboList;       //媒体
    
    
    
    CVPixelBufferRef pixelBufferCopy; //记录上一张画面
    float  displayTime;
    float  export_time;
    
    CIContext *context;
    CVOpenGLESTextureRef sourceAssetTexture;
    
   
}
@property GLuint program;
@property GLuint blendProgram;
@property GLuint maskProgram;
@property GLuint multiProgram;
@property GLuint transProgram;
@property CVOpenGLESTextureCacheRef videoTextureCache;
@property EAGLContext *currentContext;
@property GLuint offscreenBufferHandle;
@property GLuint offscreenMosaicBufferHandle;
@property GLuint mvProgram;
@property GLuint screenProgram;
@property GLuint hardLightProgram;
@property GLuint chromaKeyProgram;
@property GLuint invertProgram;
@property GLuint grayProgram;
@property GLuint bulgeDistortionProgram;
@property GLuint gridProgram;
@property GLuint throughBlackColorProgram;
@property GLuint simpleProgram;
@property GLuint borderBlurProgram;
@property GLuint blurProgram;
@property GLuint beautyProgram;
@property GLuint chromaColorProgram;

@end

@implementation RDVideoCompositorRenderer

+ (RDVideoCompositorRenderer *)sharedVideoCompositorRender{
    static RDVideoCompositorRenderer* renderer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        renderer = [[[self class] alloc] init];
        NSLog(@"%s",__func__);
    });
    return renderer;
}
int accelerateDecelerateInterpolator(float* percent)
{
    float fInput = *percent;
    *percent = (float) (cos((fInput + 1.0f) * M_PI) / 2.0f) + 0.5f;
    return 1;
}

int accelerateInterpolator(float* percent)
{
    float fInput = *percent;
#define FACTOR  1.0f
#define DOUBLE_FACTOR  FACTOR*2
    if (FACTOR == 1.0f)
    {
        *percent = fInput * fInput;
    }
    else
    {
        *percent = (float) pow(fInput, DOUBLE_FACTOR);
    }
#undef FACTOR
#undef DOUBLE_FACTOR
    return 1;
}

int decelerateInterpolator(float* percent)
{
    float fInput = *percent;
    //    if (mFactor == 1.0f) {
    *percent = (float) (1.0f - (1.0f - fInput) * (1.0f - fInput));
    //            } else {
    //                result = (float)(1.0f - pow((1.0f - input), 2 * mFactor));
    //            }
    return 1;
}

int cycleInterpolator(float* percent)
{
    float fInput = *percent;
    *percent = (float) (sin(2 * 0.5f * M_PI * fInput));
    return 1;
}
int linearInterpolator(float* percent){
    return 1;
}

- (id)init
{
    self = [super init];
    if(self) {
        //20191126 不能用通知的方法来设置背景色，否则有两个core的情况，因为通知的name都是@"setBackGroundColor"，所以两个会互相影响，无法区分;另外两个通知同样
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setCustomFilter:) name:@"setCustomFilter" object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setExporting:) name:@"setExporting" object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setBackGroundColor:) name:@"setBackGroundColor" object:nil];
        
        pixelBufferCopy = nil;
        bufferCount = 0;
        acvCount = 0;
        lockState = NO;
        export_time = 0;
        _virtualVideoBgColor = [UIColor blackColor];
        
        
        NSLog(@"%d %d %d",(int)1.0,(int)0.9, (int)1.1);
        
        rdImageCache = [NSMutableDictionary dictionary];
        rdACVTextureCache = [NSMutableDictionary dictionary];
        
        m_mapInterpolationHandles[AnimationInterpolationTypeLinear] = &linearInterpolator;
        m_mapInterpolationHandles[AnimationInterpolationTypeAccelerateDecelerate] = &accelerateDecelerateInterpolator;
        m_mapInterpolationHandles[AnimationInterpolationTypeAccelerate] = &accelerateInterpolator;
        m_mapInterpolationHandles[AnimationInterpolationTypeDecelerate] = &decelerateInterpolator;
        m_mapInterpolationHandles[AnimationInterpolationTypeCycle] = &cycleInterpolator;
        
        _currentContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:[RDGPUImageContext sharedImageProcessingContext].context.sharegroup];
        [EAGLContext setCurrentContext:_currentContext];
        
        [self setupOffscreenRenderContext];
        double time = CACurrentMediaTime();
        [self loadShaders];
        blendFilter = [[RDBlendFilter alloc] init];
        NSLog(@"loadShaders 耗时:%lf",CACurrentMediaTime() -time);//20ms
#if PARTICLE_DEMO
        
        //        //color
        //        float startColor[4] = {0.2,0.45,0.7,1.0};
        //        float endColor[4] = {1.0,0.0,0.5,1.0};
        //
        //        pParticleEmitter = [[RDEmitter alloc] init];
        //
        //        pParticleEmitter.name = @"1f_star.png";
        //        pParticleEmitter.startScale = 0.01;
        //        pParticleEmitter.endScale = 0.2;
        //        pParticleEmitter.startAngle = 0;
        //        pParticleEmitter.endAngle = 180;
        //        pParticleEmitter.startColor = startColor;
        //        pParticleEmitter.endColor = endColor;
        //        pParticleEmitter.srcFactor = RD_GL_SRC_ALPHA;
        //        pParticleEmitter.dstFactor = RD_GL_ONE;
        //        pParticleEmitter.lifeTime = rand()%6;
        //        pParticleEmitter.birthRate = 10;
        //        pParticleEmitter.isForever = false;
        //        pParticleEmitter.velocity = {0.02,0.02};
        //        pParticleEmitter.acceleration = {0.0,0.0,};
        //        pParticleEmitter.accAngle = 360;
        
        pDrawElement = [[RDDrawElement alloc] init];
#endif
        [EAGLContext setCurrentContext:nil];
    }
    
    return self;
}
- (void)purgeAllUnassignedFramebuffers;
{
    
    
    if ([rdImageCache count] > 0) {
        
        [rdImageCache.objectEnumerator.allObjects makeObjectsPerformSelector:@selector(clear)];
        [rdImageCache removeAllObjects];
        
    }
    
    
    if ([rdACVTextureCache count] > 0) {
        [rdACVTextureCache.objectEnumerator.allObjects makeObjectsPerformSelector:@selector(clear)];
        [rdACVTextureCache removeAllObjects];
        
    }
}

- (void) clear
{
    [self purgeAllUnassignedFramebuffers];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

- (void)dealloc
{
    [context clearCaches];
    context = nil;
    if (_videoTextureCache) {
        CVOpenGLESTextureCacheFlush(self.videoTextureCache, 0);
        CFRelease(_videoTextureCache);
    }
    if (_offscreenBufferHandle) {
        glDeleteFramebuffers(1, &_offscreenBufferHandle);
        _offscreenBufferHandle = 0;
    }
    if (offscreenGridBufferHandle) {
        glDeleteFramebuffers(1, &offscreenGridBufferHandle);
        offscreenGridBufferHandle = 0;
    }
    if(offscreenGridTexture)
    {
        glDeleteTextures(1, &offscreenGridBufferHandle);
    }
    if (_offscreenMosaicBufferHandle) {
        glDeleteFramebuffers(1,&_offscreenMosaicBufferHandle);
        _offscreenMosaicBufferHandle = 0;
    }
    
    if (_program) {
        glDeleteProgram(_program);
    }
    if (_blendProgram) {
        glDeleteProgram(_blendProgram);
    }
    if (_maskProgram) {
        glDeleteProgram(_maskProgram);
    }
    if (_multiProgram) {
        glDeleteProgram(_multiProgram);
    }
    if (_transProgram) {
        glDeleteProgram(_transProgram);
    }
    if (_mvProgram) {
        glDeleteProgram(_mvProgram);
    }
    if (_screenProgram) {
        glDeleteProgram(_screenProgram);
    }
    
    if (_hardLightProgram) {
        glDeleteProgram(_hardLightProgram);
    }
    
    if (_chromaKeyProgram) {
        glDeleteProgram(_chromaKeyProgram);
    }
    if (_invertProgram) {
        glDeleteProgram(_invertProgram);
    }
    if (_grayProgram) {
        glDeleteProgram(_grayProgram);
    }
    if (_bulgeDistortionProgram) {
        glDeleteProgram(_bulgeDistortionProgram);
    }
    if(_gridProgram)
        glDeleteProgram(_gridProgram);
    if(_simpleProgram)
        glDeleteProgram(_simpleProgram);
    
    if(_borderBlurProgram)
        glDeleteProgram(_borderBlurProgram);
    
    if(_throughBlackColorProgram)
        glDeleteProgram(_throughBlackColorProgram);
    
    if(_beautyProgram)
        glDeleteProgram(_beautyProgram);
    
    if(_chromaColorProgram)
        glDeleteProgram(_chromaColorProgram);
    
    while(pBlurFboList)
    {
        struct BlurFBOList* pNext = pBlurFboList->next;
        if (pBlurFboList->hTexture) {
            glDeleteTextures(1, &pBlurFboList->hTexture);
            pBlurFboList->hTexture = 0;
        }
        if (pBlurFboList->vTexture) {
            glDeleteTextures(1, &pBlurFboList->vTexture);
            pBlurFboList->vTexture = 0;
        }
        if (pBlurFboList->hFbo) {
            glDeleteFramebuffers(1,&pBlurFboList->hFbo);
            pBlurFboList->hFbo = 0;
        }
        if (pBlurFboList->vFbo) {
            glDeleteFramebuffers(1,&pBlurFboList->vFbo);
            pBlurFboList->vFbo = 0;
        }
        
        free(pBlurFboList);
        pBlurFboList = NULL;
        pBlurFboList = pNext;
    }
    while (pFilterFboList)
    {
        struct TextureFBOList* pList = pFilterFboList->next;
        
        if (pFilterFboList->texture)
        {
            glDeleteTextures(1, &pFilterFboList->texture);
            pFilterFboList->texture = 0;
        }
        if (pFilterFboList->fbo) {
            glDeleteFramebuffers(1,&pFilterFboList->fbo);
            pFilterFboList->fbo = 0;
        }
        free(pFilterFboList);
        pFilterFboList = nullptr;
        pFilterFboList = pList;
    }
    
    while (pBeautyFboList)
    {
        struct TextureFBOList* pList = pBeautyFboList->next;
        
        if (pBeautyFboList->texture)
        {
            glDeleteTextures(1, &pBeautyFboList->texture);
            pBeautyFboList->texture = 0;
        }
        if (pBeautyFboList->fbo) {
            glDeleteFramebuffers(1,&pBeautyFboList->fbo);
            pBeautyFboList->fbo = 0;
        }
        free(pBeautyFboList);
        pBeautyFboList = nullptr;
        pBeautyFboList = pList;
    }
    
    while (pDstFboList) {
        struct TextureFBOList * pList = pDstFboList->next;
        if(pDstFboList->texture)
            glDeleteTextures(1, &pDstFboList->texture);
        if (pDstFboList->fbo) {
            glDeleteFramebuffers(1,&pDstFboList->fbo);
            pDstFboList->fbo = 0;
        }
        free(pDstFboList);
        pDstFboList = pList;
    }
    while (pLastTextureList) {
        
        struct GLTextureList * pList = pLastTextureList->next;
        if(pLastTextureList->texture)
            glDeleteTextures(1, &pLastTextureList->texture);
        free(pLastTextureList);
        pLastTextureList = pList;
        
    }
    while (pCollageFboList) {
        struct TextureFBOList * pList = pCollageFboList->next;
        if(pCollageFboList->texture)
            glDeleteTextures(1, &pCollageFboList->texture);
        if (pCollageFboList->fbo) {
            glDeleteFramebuffers(1,&pCollageFboList->fbo);
            pCollageFboList->fbo = 0;
        }
        free(pCollageFboList);
        pCollageFboList = pList;
    }
    
    while (pAssetFboList) {
        struct TextureFBOList * pList = pAssetFboList->next;
        if(pAssetFboList->texture)
            glDeleteTextures(1, &pAssetFboList->texture);
        if (pAssetFboList->fbo) {
            glDeleteFramebuffers(1,&pAssetFboList->fbo);
            pAssetFboList->fbo = 0;
        }
        free(pAssetFboList);
        pAssetFboList = pList;
    }
    
//    _mvPixelBuffer = NULL;
    _videoTextureCache = NULL;
    [EAGLContext setCurrentContext:nil];
    NSLog(@"%s %@",__func__, self);
}

#define MAXIMAGESIZE 10
- (RDACVTexture *) fetchACVTexture:(NSURL *)path{
    RDACVTexture* acvTexture;
    if ([rdACVTextureCache objectForKey:path]) {
        acvTexture = [rdACVTextureCache objectForKey:path];
    }else{
        if (!acvTexture && rdACVTextureCache.count < MAXIMAGESIZE) {
            
            acvTexture = [[RDACVTexture alloc] init];
            [acvTexture loadACVPath:path];
            [rdACVTextureCache setObject:acvTexture forKey:path];
            
        }else{
            acvTexture = [rdACVTextureCache.allValues objectAtIndex:acvCount%MAXIMAGESIZE];
            
            NSURL* url = [rdACVTextureCache.allKeys objectAtIndex:acvCount%MAXIMAGESIZE];
            [rdACVTextureCache removeObjectForKey:url];
            
            [acvTexture loadACVPath:path];
            
            [rdACVTextureCache setObject:acvTexture forKey:path];
            
        }
        acvCount++;
    }
    return acvTexture;
}
- (RDImage *) fetchImageFrameBuffer:(NSURL *)path {
    RDImage* imageBuffer;
    if ([rdImageCache objectForKey:path]) {
        imageBuffer = [rdImageCache objectForKey:path];
    }else{
        //if(rdImageCache.count == 1){//20170713 wuxiaoxia 图片与图片之间有转场的情况，rdImageCache会一直不清空，造成(1)播放到转场时卡顿(2)播放时导出，不能暂停播放(3)导出时因内存崩溃
        
        if (!imageBuffer && rdImageCache.count < MAXIMAGESIZE) {
            
            imageBuffer = [[RDImage alloc] init];
            [imageBuffer loadImagePath:path];
            [rdImageCache setObject:imageBuffer forKey:path];
            
        }else{
            imageBuffer = [rdImageCache.allValues objectAtIndex:bufferCount%MAXIMAGESIZE];
            
            NSURL* url = [rdImageCache.allKeys objectAtIndex:bufferCount%MAXIMAGESIZE];
            [rdImageCache removeObjectForKey:url];
            
            [imageBuffer loadImagePath:path];
            
            [rdImageCache setObject:imageBuffer forKey:path];
            
        }
        
        
        bufferCount++;
    }
    
    return imageBuffer;
}

- (CGRect)getAssetCrop:(VVAsset *)asset {
    CGRect crop = asset.crop;
    if(CGRectEqualToRect(crop, CGRectZero)){
        crop = CGRectMake(0, 0, 1, 1);
    }
    NSInteger value = asset.rotate;
    //emmet20190115 外面传进来的是旋转后的crop，在这里转换成旋转之前的crop
    if(value == -270 || value == 90){
        // solaren fix 90度时无法铺满全屏  因为核心中采用的是-360< x < 0 ,所以此处必须修正 否则匹配错误
        crop = CGRectMake(1 - (crop.origin.y + crop.size.height), (crop.origin.x), crop.size.height, crop.size.width);
    }
    else if(value == -90 || value == 270){
        crop = CGRectMake(crop.origin.y, 1 - (crop.origin.x + crop.size.width), crop.size.height, crop.size.width);
    }else if(value == -180 || value == 180){
        crop = CGRectMake(1 - (crop.origin.x + crop.size.width), 1 - (crop.origin.y + crop.size.height), crop.size.width, crop.size.height);
    }
    if(asset.isVerticalMirror){
        //xiachunlin20200106 左右翻转不需要计算裁剪
//        crop = CGRectMake((1 - (crop.origin.x + crop.size.width)), crop.origin.y, crop.size.width, crop.size.height);
    }
    if(asset.isHorizontalMirror){
        //xiachunlin20200106 上下翻转不需要计算裁剪
//        crop = CGRectMake(crop.origin.x,1 - (crop.origin.y + crop.size.height), crop.size.width, crop.size.height);
    }
    return crop;
}

- (CGAffineTransform)transformFromAsset:(VVAsset*) asset
                             sourceSize:(CGSize) sourceSize
                        destinationSize:(CGSize)destinationSize
                            textureData:(GLfloat*)textureData
                                 factor:(float) factor
                           fromPosition:(VVAssetAnimatePosition*)fromPosition
                             toPosition:(VVAssetAnimatePosition*)toPosition
                                 matrix:(RDMatrix4*)matrix
                             hasAnimate:(BOOL)hasAnimate
{
    float fillScaleFrom = 1.0 / fromPosition.fillScale;
    float fillScaleTo = 1.0 / toPosition.fillScale;
    CGRect crop = [self getAssetCrop:asset];
    float x = crop.origin.x;
    float y = crop.origin.y;
    float w = crop.size.width;
    float h = crop.size.height;
    
    
    if (hasAnimate) {
        if (!fromPosition.isUseRect) {//使用顶点
            x = asset.rectInVideo.origin.x;
            y = asset.rectInVideo.origin.y;
            w = asset.rectInVideo.size.width;
            h = asset.rectInVideo.size.height;
        }else {
            CGRect crop = [self CropMixed:fromPosition b:toPosition value:factor type:fromPosition.type];
            x = crop.origin.x;
            y = crop.origin.y;
            w = crop.size.width;
            h = crop.size.height;
            //            NSLog(@"crop:%@", NSStringFromCGRect(crop));
        }
    }else if (!asset.isUseRect) {//使用顶点
        x = asset.rectInVideo.origin.x;
        y = asset.rectInVideo.origin.y;
        w = asset.rectInVideo.size.width;
        h = asset.rectInVideo.size.height;
    }
    
    
    CGPoint center = CGPointMake(x + w / 2.0, y + h / 2.0);
    
    float factorScale = fillScaleFrom + (fillScaleTo - fillScaleFrom) * factor;
    
    x = center.x - w / 2.0 * factorScale;
    y = center.y - h / 2.0 * factorScale;
    w = w * factorScale;
    h = h * factorScale;
    //    NSLog(@"x:%.2f y:%.2f w:%.2f h:%.2f factorScale:%.2f fillScaleFrom:%.2f fillScaleTo:%.2f", x, y, w, h, factorScale, fillScaleFrom, fillScaleTo);
    
    float angle = (asset.rotate+360)/180.0*M_PI;
    BOOL sR = NO;
    float angleOrign = 0;
    
    
    if (asset.type == RDAssetTypeVideo) {
        CGAffineTransform t = asset.transform;
        
        
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0)
        {
            sR = YES;
            angleOrign = M_PI_2;
        }
        if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0)
        {
            sR = YES;
            angleOrign = -M_PI_2;
        }
        if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0)
        {
            sR = NO;
            angleOrign = 0;
        }
        if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0)
        {
            sR = NO;
            angleOrign = M_PI;
        }
        
    }
    
    if(sR){
        GLfloat quadTextureData1 [] = { //纹理坐标
            //            y,   x+w,
            //            y+h, x+w,
            //            y,   x,
            //            y+h, x,
            
            //2019.01.30 xcl fix bug:
            //视频本身含有旋转角度，crop为旋转之后的裁剪区域
            //视频设置旋转角度，crop为旋转之前的裁剪区域
            y,   1-x,
            y+h, 1-x,
            y,   1-x-w,
            y+h, 1-x-w,
        };
        
        
        memcpy(textureData, quadTextureData1, sizeof(quadTextureData1));
    }else{
        GLfloat quadTextureData1 [] = { //纹理坐标
            x,   y+h,
            x+w, y+h,
            x,   y,
            x+w, y,
        };
        
        memcpy(textureData, quadTextureData1, sizeof(quadTextureData1));
    }
    
    
    CGFloat dW = destinationSize.width*asset.rectInVideo.size.width;
    CGFloat dH = destinationSize.height*asset.rectInVideo.size.height;
    
    CGFloat sW,sH;
    if (sR) {
        sH  = sourceSize.width;
        sW  = sourceSize.height;
    }else{
        sW  = sourceSize.width;
        sH  = sourceSize.height;
    }
    sW *= w;
    sH *= h;
    float daspect = dW/dH;
    float saspect = sW/sH;
#if 0
    if(asset.rectInVideo.size.width == 1.0 && asset.rectInVideo.size.height == 1.0 && (fabs(saspect - daspect) < 0.1))
    {
        //20190523 保留一位小数，否则设置的分辨率与视频原分辨率只差一点，也会有黑边 (852*480)
//        daspect = (int)(daspect*10)/10.0;
//        saspect = (int)(saspect*10)/10.0;
        
        daspect = saspect;
    }
    float aspect = daspect/saspect;
#else
    float aspect = daspect/saspect;
    if(asset.rectInVideo.size.width == 1.0 && asset.rectInVideo.size.height == 1.0 && aspect < 2.0)
    {
        float ratio = fabs(aspect - 1.0);
        float diff;
        if (dH > dW) {
            diff = ratio * dH;
        }else {
            diff = ratio * dW;
        }
        if (diff <= 10.0) {//20200108 如果缩放后小于设置的分辨率10dot，就处理一下，否则会显示出一条背景色
            daspect = saspect;
            aspect = 1.0;
        }
    }
#endif
    float scale  = 1.0;// = sinf(oangle)/sinf(oangle + angle);
    float scaleInv = 1.0;
    
    if (aspect < 1.0 && sR == NO) {
        // 水平
        float alpha = atanf(1.0/daspect);
        float beta = atanf(1.0/saspect);
        
        float angleNow = angle;
        if (angleNow >= M_PI) {
            angleNow -= M_PI;
        }
        
        if (angleNow > 0 && angleNow < alpha - beta) {
            scale = cosf(beta)/cosf(beta+angleNow);
        }
        
        if (angleNow >= alpha - beta && angleNow < M_PI - beta - alpha ) {
            angleNow -= (alpha -beta);
            scale = sinf(alpha)*cosf(beta)/cosf(alpha)/sinf(alpha+angleNow);
        }
        
        if (angleNow >= M_PI -beta -alpha && angleNow <= M_PI) {
            angleNow -= (M_PI - beta - alpha);
            scale = cosf(beta)/cosf(alpha-angleNow);
        }
    }else{
        // 左上右下对角线适配
        float alpha = atanf(1.0/daspect);
        float beta = atanf(1.0/saspect);
        
        float angleNow = angle;
        if (angleNow >= M_PI) {
            angleNow -= M_PI;
        }
        
        if (angleNow >= 0 && angleNow < M_PI - alpha - beta) {
            scale = sinf(beta)/sinf(beta+angleNow);
        }
        
        if (angleNow >= M_PI - alpha - beta && angleNow < M_PI - beta + alpha ) {
            angleNow -= (M_PI - alpha -beta);
            scale = cosf(alpha)*sinf(beta)/sinf(alpha)/cosf(alpha-angleNow);
        }
        
        if (angleNow >= M_PI -beta +alpha && angleNow <= M_PI) {
            angleNow -= (M_PI - beta + alpha);
            scale = sinf(beta)/sinf(alpha+angleNow);
        }
    }
    if (aspect < 1.0 && sR == NO) {
        // 水平
        float alpha = atanf(1.0/daspect);
        float beta = atanf(1.0/saspect);
        
        float angleNow = angle;
        if (angleNow >= M_PI) {
            angleNow -= M_PI;
        }
        
        
        if (angleNow > 0 && angleNow < alpha + beta) {
            scaleInv = cosf(beta)/cosf(beta - angleNow);
        }
        
        if (angleNow >= alpha + beta && angleNow < M_PI + beta - alpha ) {
            angleNow -= (alpha + beta);
            scaleInv = sinf(alpha)*cosf(beta)/cosf(alpha)/sinf(alpha+angleNow);
        }
        
        if (angleNow >= M_PI +beta -alpha && angleNow <= M_PI) {
            angleNow -= (M_PI + beta - alpha);
            scaleInv = cosf(beta)/cosf(alpha-angleNow);
        }
    }else{
        // 右上左下对角线适配
        float alpha = atanf(1.0/daspect);
        float beta = atanf(1.0/saspect);
        float angleNow = angle;
        
        if (angleNow >= M_PI) {
            angleNow -= M_PI;
        }
        if (angleNow > 0 && angleNow < beta - alpha) {
            scaleInv = sinf(beta)/sinf(beta-angleNow);
        }
        
        if (angleNow >= beta - alpha && angleNow < beta+alpha ) {
            angleNow -= (beta - alpha);
            scaleInv = cosf(alpha)*sinf(beta)/sinf(alpha)/sinf(M_PI_2 + angleNow - alpha);
        }
        
        if (angleNow >= beta +alpha && angleNow <= M_PI) {
            angleNow -= (beta + alpha);
            scaleInv = sinf(beta)/sinf(alpha+angleNow);
        }
    }
    
    scale = MIN(scale, scaleInv);
    
    
    CGAffineTransform transform = CGAffineTransformRotate(CGAffineTransformIdentity, angleOrign);
    if ((asset.type == RDAssetTypeImage && asset.fillType != RDImageFillTypeFull)
        || (asset.type == RDAssetTypeVideo && asset.videoFillType != RDVideoFillTypeFull))
    {//20180907 wuxiaoxia 此段代码实现媒体适配
        if (aspect<1.0) {
            
            if (sR) {
                transform =  CGAffineTransformScale(transform, 1.0, 1.0/aspect);//竖直
            }else{
                transform = CGAffineTransformScale(transform, 1.0,aspect);//水平
            }
            
            
        }else{
            if (sR) {
                
                // 系统相机录制的视频（带有旋转角度），如果视频分辨率比例和窗口显示比例相同时，设置背景色，顶部和底部会有两个像素被透明，
                if(aspect == 1.0)
                    transform =  CGAffineTransformScale(transform, 1.0+2.0/(float)sourceSize.width, 1.0/aspect);//竖直（放大两个像素）
                else
                    transform =  CGAffineTransformScale(transform, 1.0, 1.0/aspect);//竖直
                
            }else{
                transform = CGAffineTransformScale(transform, 1.0/aspect, 1.0);//竖直
            }
            
        }
    }
    
    float scaleInVideo = asset.rectInVideo.size.width/asset.rectInVideo.size.height;
    
    
    saspect = saspect/scaleInVideo;
    saspect = sR?1.0/saspect : saspect;
    
    GLfloat preferredRenderTransform [] = {
        static_cast<GLfloat>(transform.a), static_cast<GLfloat>(transform.b), static_cast<GLfloat>(transform.tx), 0.0,
        static_cast<GLfloat>(transform.c), static_cast<GLfloat>(transform.d), static_cast<GLfloat>(transform.ty), 0.0,
        0.0,                       0.0,                                        1.0, 0.0,
        0.0,                       0.0,                                        0.0, 1.0,
    };
    //    if (asset.type == RDAssetTypeImage && asset.fillType == RDImageFillTypeFull) {
    //        return transform;
    //    }
    RDMatrixInitFromArray(matrix, preferredRenderTransform);
    
    float actionRotate = fromPosition.rotate + (toPosition.rotate - fromPosition.rotate)*factor;

    RDMatrixTranslate(matrix, fromPosition.anchorPoint.x * 2.0 - 1.0, fromPosition.anchorPoint.y * 2.0 - 1.0, 0);
    RDMatrixScale(matrix, 1.0, saspect, 1.0);
    RDMatrixRotate(matrix, angle * 180.0 / M_PI + actionRotate, 0, 0, 1);
    RDMatrixScale(matrix, 1.0, 1.0/saspect, 1.0);
    RDMatrixTranslate(matrix, 1.0 - fromPosition.anchorPoint.x*2.0, 1.0 - fromPosition.anchorPoint.y*2.0, 0);

    BOOL inve = sR;
    int inveAngle = asset.rotate;
    if (inveAngle == 0 || inveAngle == -180) {
        inve = sR?YES:NO;
    }
    if (inveAngle == -90 || inveAngle == -270) {
        inve = sR?NO:YES;
    }
    
    
    if (inve) {
        //        transform = CGAffineTransformScale(transform, scale*(asset.isVerticalMirror?-1:1), scale*(asset.isHorizontalMirror?-1:1));
        RDMatrixScale(matrix, scale*(asset.isVerticalMirror?-1:1), scale*(asset.isHorizontalMirror?-1:1), 1);
        
    }else{
        //        transform = CGAffineTransformScale(transform, scale*(asset.isHorizontalMirror?-1:1), scale*(asset.isVerticalMirror?-1:1));
        RDMatrixScale(matrix, scale*(asset.isHorizontalMirror?-1:1), scale*(asset.isVerticalMirror?-1:1), 1);
        
    }
    
    
    
    if (!sR) {
        //        transform = CGAffineTransformScale(transform, asset.rectInVideo.size.width, asset.rectInVideo.size.height);
        RDMatrixScale(matrix, asset.rectInVideo.size.width, asset.rectInVideo.size.height, 1);
    }else{
        //        transform = CGAffineTransformScale(transform, asset.rectInVideo.size.height, asset.rectInVideo.size.width);
        RDMatrixScale(matrix, asset.rectInVideo.size.height, asset.rectInVideo.size.width, 1);
    }
    
    
    return transform;
}


static Float64 factorForTimeInRange(CMTime time, CMTimeRange range) /* 0.0 -> 1.0 */
{
    
    CMTime elapsed = CMTimeSubtract(time, range.start);
    return CMTimeGetSeconds(elapsed) / CMTimeGetSeconds(range.duration);
}
///渲染主函数  渲染图片与视频  有优化的余地
#define Uniform(name,index) glGetUniformLocation(_multiProgram, [[NSString stringWithFormat:@"%@[%d]", @#name ,index] UTF8String] )
#define Attrib(name)  glGetAttribLocation(_multiProgram, #name )

#if 0
- (void) renderMultiTextureWithScene:(RDScene *) scene destination:(CVPixelBufferRef )destinationPixelBuffer request:(AVAsynchronousVideoCompositionRequest *)request
{
    
    
    
    
    [EAGLContext setCurrentContext:self.currentContext];
    
    
    CVOpenGLESTextureRef destTexture = [self customTextureForPixelBuffer:destinationPixelBuffer];
    
    
    glBindFramebuffer(GL_FRAMEBUFFER, self.offscreenBufferHandle);
    
    glViewport(0, 0, (int)CVPixelBufferGetWidth(destinationPixelBuffer), (int)CVPixelBufferGetHeight(destinationPixelBuffer));
    
    
    
    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(destTexture), 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        goto bail1;
    }
    
    // [RDContext setActiveShaderProgram:normalProgram]
    glUseProgram(self.multiProgram);
    
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    
    
    //因为iOS最多支持8个纹理，故同一时间只支持8个资源
    // vvAsset.count > 8 则需绘制多次
    
    int vvAssetCount = (int)scene.vvAsset.count;
    
    int startIndex = 0;
    while (vvAssetCount > MAX_INSTANCE) {
        [self multiTextureWithScene:scene startIndex:startIndex endIndex:startIndex+MAX_INSTANCE  request:request];
        vvAssetCount -= MAX_INSTANCE;
        startIndex += MAX_INSTANCE;
    }
    
    [self multiTextureWithScene:scene startIndex:startIndex endIndex:(int)scene.vvAsset.count request:request];
    
    
    
bail1:
    CFRelease(destTexture);
    CVOpenGLESTextureCacheFlush(self.videoTextureCache, 0);
    //
    [EAGLContext setCurrentContext:nil];
    
    
    
}
//仍然有这个问题

- (void) multiTextureWithScene:(RDScene *)scene startIndex:(int) start endIndex:(int) end  request:(AVAsynchronousVideoCompositionRequest *)request{
    CGSize destinationSize = _videoSize;
    float tweenFactor = factorForTimeInRange(request.compositionTime, scene.fixedTimeRange);
    
    
    
    int instance_count = 0;
    for(int i = start;i<end;i++){
        RDMatrixLoadIdentity(&_modelViewMatrix);
        RDMatrixLoadIdentity(&_projectionMatrix);
        VVAsset* asset = scene.vvAsset[i];
        
        GLfloat quadTextureData1[8] = {0};
        
        if(asset.type == RDAssetTypeVideo ) {
            
            
            
            //
            if (asset.filterType == VVAssetFilterEmpty) {
                glUniform1f(Uniform(inputTexture2Type,  instance_count), 0.0);
                
                
            }
            
            if (asset.filterType == VVAssetFilterACV) {
                glUniform1f(Uniform(inputTexture2Type,  instance_count), 1.0);
                
                RDACVTexture* acvTexture = [self fetchACVTexture:asset.filterUrl];
                
                glActiveTexture(GL_TEXTURE0 + instance_count*2);
                glBindTexture(GL_TEXTURE_2D, acvTexture.texture);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                
            }
            if (asset.filterType == VVAssetFilterLookup){
                glUniform1f(Uniform(inputTexture2Type,  instance_count), 2.0);
                
                RDImage* imageBuffer2 = [self fetchImageFrameBuffer:asset.filterUrl];
                
                glActiveTexture(GL_TEXTURE0 + instance_count*2);
                glBindTexture(GL_TEXTURE_2D, imageBuffer2.texture);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            }
            
            
            CVPixelBufferRef sourcePixelBuffer = [request sourceFrameByTrackID:[asset.trackID intValue]];
            
            
            if (!sourcePixelBuffer) {
                continue;
            }//在切换时有一帧读不出来。。。。
            
            CVOpenGLESTextureRef sourceTexture = [self customTextureForPixelBuffer:sourcePixelBuffer];
            
            
            
            
            glActiveTexture(GL_TEXTURE0 + instance_count*2+1);
            glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(sourceTexture));
            
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            CFRelease(sourceTexture);
            
            
            
            CGSize sourceSize = CGSizeMake(CVPixelBufferGetWidth(sourcePixelBuffer), CVPixelBufferGetHeight(sourcePixelBuffer));
            
            CGAffineTransform transform = [self transformFromAsset:asset sourceSize:sourceSize destinationSize:destinationSize textureData:quadTextureData1 factor:tweenFactor fromPosition:nil toPosition:nil matrix:nil];
            
            GLfloat preferredRenderTransform [] = {
                transform.a, transform.b, transform.tx, 0.0,
                transform.c, transform.d, transform.ty, 0.0,
                0.0,                       0.0,                                        1.0, 0.0,
                0.0,                       0.0,                                        0.0, 1.0,
            };
            RDMatrixInitFromArray(&_modelViewMatrix, preferredRenderTransform);
            
            
            
            
            CGRect rectInVideo = asset.rectInVideo;
            
            
            float transX = (rectInVideo.origin.x + rectInVideo.size.width/2.0) - 0.5;
            float transY = (rectInVideo.origin.y + rectInVideo.size.height/2.0) - 0.5;
            
            float size = 2.0; //不知道为什么？
            
            RDMatrixTranslate(&_projectionMatrix,transX*size , transY*size, 0);
            
            
            glUniformMatrix4fv(Uniform(renderTransform , instance_count), 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
            glUniformMatrix4fv(Uniform(projection , instance_count), 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
            
            
            GLfloat textureoffset[4] = {
                quadTextureData1[4],quadTextureData1[5],
                quadTextureData1[2]-quadTextureData1[4],quadTextureData1[3]-quadTextureData1[5]};
            
            
            glUniform4fv(Uniform(coordOffset , instance_count), 4, textureoffset);
            
            glUniform1i(Uniform(inputImageTexture2,  instance_count), instance_count*2);
            glUniform1i(Uniform(inputImageTexture ,instance_count), instance_count*2+1);
            
            glUniform3f(Uniform(filter ,instance_count), asset.brightness, asset.contrast, asset.saturation);
            
            
            
            instance_count += 1;
            
            
        }
        
        if (asset.type == RDAssetTypeImage && asset.last <= tweenFactor) {
            
            if (asset.filterType == VVAssetFilterEmpty) {
                glUniform1f(Uniform(inputTexture2Type,  instance_count), 0.0);
                
                
            }
            
            if (asset.filterType == VVAssetFilterACV) {
                glUniform1f(Uniform(inputTexture2Type,  instance_count), 1.0);
                
                RDACVTexture* acvTexture = [self fetchACVTexture:asset.filterUrl];
                
                glActiveTexture(GL_TEXTURE0 + instance_count*2);
                glBindTexture(GL_TEXTURE_2D, acvTexture.texture);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                
            }
            if (asset.filterType == VVAssetFilterLookup){
                glUniform1f(Uniform(inputTexture2Type,  instance_count), 2.0);
                
                RDImage* imageBuffer2 = [self fetchImageFrameBuffer:asset.filterUrl];
                
                glActiveTexture(GL_TEXTURE0 + instance_count*2);
                glBindTexture(GL_TEXTURE_2D, imageBuffer2.texture);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            }
            
            float value = 1.0;
            
            
            if (asset.fillType == RDImageFillTypeFit) {
                value = 1.0;
            }
            
            if (asset.fillType == RDImageFillTypeFitZoomOut) {
                value = 1.2 - 0.2 * tweenFactor;
            }
            
            if (asset.fillType == RDImageFillTypeFitZoomIn) {
                value = 1.0 + 0.2 * tweenFactor;
            }
            
            RDImage* imageBuffer = [self fetchImageFrameBuffer:asset.url];
            
            glActiveTexture(GL_TEXTURE0 + instance_count*2+1);
            glBindTexture(GL_TEXTURE_2D, imageBuffer.texture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            
            CGSize sourceSize = CGSizeMake(imageBuffer.width, imageBuffer.height);
            
            CGAffineTransform transform = [self transformFromAsset:asset sourceSize:sourceSize destinationSize:destinationSize textureData:quadTextureData1 factor:tweenFactor fromPosition:nil toPosition:nil matrix:nil];
            
            
            
            transform = CGAffineTransformScale(transform, value, value);
            
            GLfloat preferredRenderTransform [] = {
                transform.a, transform.b, transform.tx, 0.0,
                transform.c, transform.d, transform.ty, 0.0,
                0.0,                       0.0,                                        1.0, 0.0,
                0.0,                       0.0,                                        0.0, 1.0,
            };
            
            
            
            if (asset.fillType != RDImageFillTypeFull) {
                RDMatrixInitFromArray(&_modelViewMatrix, preferredRenderTransform);
            }
            
            
            if (asset.fillType != RDImageFillTypeFull) {
                
                CGRect rectInVideo = asset.rectInVideo;
                
                
                float transX = (rectInVideo.origin.x + rectInVideo.size.width/2.0) - 0.5;
                float transY = (rectInVideo.origin.y + rectInVideo.size.height/2.0) - 0.5;
                
                float size = 2.0;
                
                //NSLog(@">>>>>>>>   %f %f %@",transX, transY,[asset.url lastPathComponent]);
                RDMatrixTranslate(&_projectionMatrix,transX*size , transY*size, 0);
                
            }
            
            
            glUniformMatrix4fv(Uniform(renderTransform , instance_count), 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
            glUniformMatrix4fv(Uniform(projection , instance_count), 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
            
            
            GLfloat textureoffset[4] = {
                quadTextureData1[4],quadTextureData1[5],
                quadTextureData1[2]-quadTextureData1[4],quadTextureData1[3]-quadTextureData1[5]};
            
            glUniform4fv(Uniform(coordOffset , instance_count), 4, textureoffset);
            
            glUniform1i(Uniform(inputImageTexture2,  instance_count), instance_count*2);
            glUniform1i(Uniform(inputImageTexture ,instance_count), instance_count*2+1);
            
            glUniform3f(Uniform(filter ,instance_count), asset.brightness, asset.contrast, asset.saturation);
            
            
            instance_count += 1;
            
        }
    }
    
    
    GLfloat VertexData [] = {
        -1.0, 1.0,
        1.0, 1.0,
        -1.0, -1.0,
        1.0, -1.0,
    };
    
    
    
    GLfloat TextureData [] = { //纹理坐标
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    
    
    
    
    glVertexAttribPointer(Attrib(position), 2, GL_FLOAT, 0, 0, VertexData);
    glEnableVertexAttribArray(Attrib(position));
    
    glVertexAttribPointer(Attrib(inputTextureCoordinate), 2, GL_FLOAT, 0, 0, TextureData);
    glEnableVertexAttribArray(Attrib(inputTextureCoordinate));
    
    
    GLfloat* offset = alloca(sizeof(GLfloat) * instance_count);
    
    for (int i = 0; i<instance_count; i++) {
        offset[i] = i*1.0 + 0.3;
    }
    
    glVertexAttribPointer(Attrib(offset), 1, GL_FLOAT, GL_FALSE, 0, offset);
    
    glVertexAttribDivisorEXT(Attrib(offset), 1);
    glEnableVertexAttribArray(Attrib(offset));
    
    
    glDrawArraysInstancedEXT(GL_TRIANGLE_STRIP, 0, 4, instance_count);
    
    
    glFlush();
}
#endif

- (CGRect) CropMixed:(VVAssetAnimatePosition*)a  b:(VVAssetAnimatePosition*) b value:(float) value type:(int) type{
    
    float v = value;
    (m_mapInterpolationHandles[type])(&v);
    
    CGPoint p;
    //    if (a.path) {
    //        CGPoint p2 = [a calculateWithTimeValue:v];
    //        p = CGPointMake(p2.x/_videoSize.width, p2.y/_videoSize.height);
    //    }else{
    CGPoint p1 = calculateLinear(v, a.crop.origin, b.crop.origin);
    p = p1;
    //    }
    return CGRectMake(p.x,
                      p.y,
                      a.crop.size.width + (b.crop.size.width - a.crop.size.width) * value,
                      a.crop.size.height + (b.crop.size.height - a.crop.size.height) * value);
}

- (CGRect) CGRectMixed:(VVAssetAnimatePosition*)a  b:(VVAssetAnimatePosition*) b value:(float) value type:(int) type{
    
    float v = value;
    
    (m_mapInterpolationHandles[type])(&v);
    
    
    CGPoint p;
    
    
    if (a.path) {
        
        CGPoint p2 = [a calculateWithTimeValue:v];
        p = CGPointMake(p2.x/_videoSize.width, p2.y/_videoSize.height);
    }else{
        CGPoint p1 = calculateLinear(v, a.rect.origin, b.rect.origin);
        p = p1;
    }
    
    
    
    return CGRectMake(p.x,
                      p.y,
                      a.rect.size.width + (b.rect.size.width - a.rect.size.width) * value,
                      a.rect.size.height + (b.rect.size.height - a.rect.size.height) * value);
}

- (void)ConvertVertxCoordinatesFromSrcVertex:(GLfloat *)srcVert toDstVertex:(GLfloat *)destVert
{
    
    //srcVert ：坐标原点在左上角 （介于0 到1之间）
    //destVert：坐标原点在屏幕中心（介于-1到1之间）
    // 坐标上下镜像
    float left_top = srcVert[1];
    float left_bottom = srcVert[5];
    float right_top = srcVert[3];
    float right_bottom = srcVert[7];
    
    float top_left = srcVert[0];
    float top_right = srcVert[2];
    float bottom_left = srcVert[4];
    float bottom_right = srcVert[6];
    
    
    srcVert[0] = bottom_left;
    srcVert[2] = bottom_right;
    srcVert[4] = top_left;
    srcVert[6] = top_right;
    
    srcVert[1] = 1.0-left_bottom;
    srcVert[5] = 1.0-left_top;
    
    srcVert[3] = 1.0-right_bottom;
    srcVert[7] = 1.0-right_top;
    
    
    
    for(int i = 0;i<8;i++)
    {
        if(0 == i%2)
        {
            //x
            if( 0 == srcVert[i])
                destVert[i] = -1.0;
            else
                destVert[i] = (srcVert[i]-0.5)*2;
        }
        else
        {
            //y
            destVert[i] = (0.5-srcVert[i])*2;
        }
    }
    
}

- (const GLfloat *)textureCoordinatesForAsset:(VVAsset *)asset;
{
    static const GLfloat noRotationTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    
    static const GLfloat verticalMirrorTextureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    
    static const GLfloat downVerticalMirrorTextureCoordinates[] = {
        0.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
    };
    
    static const GLfloat verticalFlipTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f,  0.0f,
        1.0f,  0.0f,
    };
    
    static const GLfloat horizontalFlipTextureCoordinates[] = {
        1.0f, 0.0f,
        0.0f, 0.0f,
        1.0f,  1.0f,
        0.0f,  1.0f,
    };
    
    static const GLfloat downTextureCoordinates[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
    };
    
    static const GLfloat upTextureCoordinates[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
    };
    
    static const GLfloat upVerticalMirrorTextureCoordinates[] = {
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
    };
    
    static const GLfloat horizontalMirrorTextureCoordinates[] = {
        1.0f, 1.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
    };
    BOOL sR = NO;
    float angleOrign = 0;
    
    if (asset.type == RDAssetTypeVideo) {
        CGAffineTransform t = asset.transform;
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0)
        {
            sR = YES;
            angleOrign = M_PI_2;
        }
        else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0)
        {
            sR = YES;
            angleOrign = -M_PI_2;
        }
        else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0)
        {
            sR = NO;
            angleOrign = 0;
        }
        else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0)
        {
            sR = NO;
            angleOrign = M_PI;
        }
    }
    if (sR) {
        if (angleOrign == (float)M_PI_2) {
            if (asset.rotate == -90 || asset.rotate == 270) {
                if (asset.isVerticalMirror) {
                    return horizontalMirrorTextureCoordinates;
                }
                if (asset.isHorizontalMirror) {
                    return verticalMirrorTextureCoordinates;
                }
                return horizontalFlipTextureCoordinates;
            }else if (asset.rotate == 90 || asset.rotate == -270) {
                if (asset.isVerticalMirror) {
                    return verticalMirrorTextureCoordinates;
                }
                if (asset.isHorizontalMirror) {
                    return horizontalMirrorTextureCoordinates;
                }
                return noRotationTextureCoordinates;
            }else if (asset.rotate == 180 || asset.rotate == -180) {
                if (asset.isVerticalMirror) {
                    return upVerticalMirrorTextureCoordinates;
                }
                if (asset.isHorizontalMirror) {
                    return downVerticalMirrorTextureCoordinates;
                }
                return upTextureCoordinates;
            }
            if (asset.isVerticalMirror) {//上下镜像
                return downVerticalMirrorTextureCoordinates;
            }else if (asset.isHorizontalMirror) {//左右镜像
                return upVerticalMirrorTextureCoordinates;
            }
            return downTextureCoordinates;//HomeDown
        }
        if (asset.rotate == -90 || asset.rotate == 270) {
            if (asset.isVerticalMirror) {
                return verticalMirrorTextureCoordinates;
            }
            if (asset.isHorizontalMirror) {
                return horizontalMirrorTextureCoordinates;
            }
            return verticalFlipTextureCoordinates;
        }else if (asset.rotate == 90 || asset.rotate == -270) {
            if (asset.isVerticalMirror) {
                return horizontalMirrorTextureCoordinates;
            }
            if (asset.isHorizontalMirror) {
                return verticalMirrorTextureCoordinates;
            }
            return horizontalFlipTextureCoordinates;
        }else if (asset.rotate == 180 || asset.rotate == -180) {
            if (asset.isVerticalMirror) {
                return downVerticalMirrorTextureCoordinates;
            }
            if (asset.isHorizontalMirror) {
                return upVerticalMirrorTextureCoordinates;
            }
            return downTextureCoordinates;
        }
        if (asset.isVerticalMirror) {//上下镜像
            return upVerticalMirrorTextureCoordinates;
        }else if (asset.isHorizontalMirror) {//左右镜像
            return downVerticalMirrorTextureCoordinates;
        }
        return upTextureCoordinates;//HomeUp
    }else {
        if (asset.rotate == -90 || asset.rotate == 270) {
            if (asset.isVerticalMirror) {
                return downVerticalMirrorTextureCoordinates;
            }
            if (asset.isHorizontalMirror) {
                return upVerticalMirrorTextureCoordinates;
            }
            return downTextureCoordinates;
        }else if (asset.rotate == 90 || asset.rotate == -270) {
            if (asset.isVerticalMirror) {
                return upVerticalMirrorTextureCoordinates;
            }
            if (asset.isHorizontalMirror) {
                return downVerticalMirrorTextureCoordinates;
            }
            return upTextureCoordinates;
        }else if (asset.rotate == 180 || asset.rotate == -180) {
            if (asset.isVerticalMirror) {
                return horizontalMirrorTextureCoordinates;
            }
            if (asset.isHorizontalMirror) {
                return verticalMirrorTextureCoordinates;
            }
            return horizontalFlipTextureCoordinates;
        }
        if (asset.isVerticalMirror) {//上下镜像
            if (asset.rotate == 360 || asset.rotate == -360) {//360度时左右镜像与上下镜像反了
                return horizontalMirrorTextureCoordinates;
            }
            return verticalMirrorTextureCoordinates;
        }else if (asset.isHorizontalMirror) {//左右镜像
            if (asset.rotate == 360 || asset.rotate == -360) {
                return verticalMirrorTextureCoordinates;
            }
            return horizontalMirrorTextureCoordinates;
        }
        return noRotationTextureCoordinates;
    }
}

-(int) getBlendFactor:(VVAssetBlendType)facror Src:(bool)bSrc
{
    
    switch (facror) {
        case BLEND_GL_ZERO:
            return GL_ZERO;
            
        case BLEND_GL_ONE:
            return GL_ONE;
            
        case BLEND_GL_SRC_ALPHA:
            return GL_SRC_ALPHA;
            
        case BLEND_GL_ONE_MINUS_SRC_ALPHA:
            return GL_ONE_MINUS_SRC_ALPHA;
            
        default:
        {
            if(bSrc)
                return GL_SRC_ALPHA;
            else
                return GL_ONE_MINUS_SRC_ALPHA;
        }
    }
}
-(void)setBlendModelWithSrcFactor:(VVAssetBlendType)src DstFactor:(VVAssetBlendType)dst Model:(VVAssetBlendEquation)model
{
    int blendSrc = [self getBlendFactor:src Src:true];
    int blendDst = [self getBlendFactor:dst Src:false];
    //int blendModel = GL_FUNC_ADD;
    glEnable(GL_BLEND);
    glBlendFunc(blendSrc, blendDst);
    //    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}
#if 1


- (CVPixelBufferRef)pixelBufferFrom32BGRAData:(const unsigned char *)framedata size:(CGSize)size
{
    NSDictionary *pixelAttributes = [NSDictionary dictionaryWithObject:@{} forKey:(NSString *)kCVPixelBufferIOSurfacePropertiesKey];
    CVPixelBufferRef pixelBuffer = NULL;
    
    int width = size.width;
    int height = size.height;
    
    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                          width,
                                          height,
                                          kCVPixelFormatType_32BGRA,
                                          (__bridge CFDictionaryRef)pixelAttributes,
                                          &pixelBuffer);
    
    if (result != kCVReturnSuccess){
        NSLog(@"Unable to create cvpixelbuffer %d", result);
        return nil;
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer,0);
    unsigned char *yDestPlane = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    if (yDestPlane == NULL)
    {
        NSLog(@"create yDestPlane failed. value is NULL");
        return nil;
    }
    
    memcpy(yDestPlane, framedata, width * height*4);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return pixelBuffer;
}
#endif

-(CGVector ) getTranslate:(float*)vertex
{
    CGVector translate = {0.0,0.0};
    
    translate.dx = (vertex[0] + vertex[2])/2.0;
    translate.dy = (vertex[1] + vertex[3])/2.0;
    
    return translate;
}

- (void) renderMVPixelBuffer:(CVPixelBufferRef) destinationPixelBuffer
             usingSourceData:(GLubyte*) sourceData
               mvPixelBuffer:(CVPixelBufferRef) mvPixelBuffer
                        Effect:(VVMovieEffect*) effect
{
    GLfloat quadTextureData [] = { //纹理坐标
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    GLfloat quadVertexData [] = {
        -1.0, 1.0,
        1.0, 1.0,
        -1.0, -1.0,
        1.0, -1.0,
    };
    
    [EAGLContext setCurrentContext:self.currentContext];
    
    GLuint sourceTexture = [self textureFromBufferObject:sourceData Width:(int)CVPixelBufferGetWidth(destinationPixelBuffer) Height:(int)CVPixelBufferGetHeight(destinationPixelBuffer)];
    if (!sourceTexture) {
        return;
    }
    CVOpenGLESTextureRef destTexture = [self customTextureForPixelBuffer:destinationPixelBuffer];
    if (!destTexture) {
        return;
    }
    CVOpenGLESTextureRef mvTexture = [self customTextureForPixelBuffer:mvPixelBuffer];
    if (!mvTexture) {
        return;
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, self.offscreenBufferHandle);
    glViewport(0, 0, (int)CVPixelBufferGetWidth(destinationPixelBuffer), (int)CVPixelBufferGetHeight(destinationPixelBuffer));
    
    
    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, CVOpenGLESTextureGetTarget(destTexture), CVOpenGLESTextureGetName(destTexture), 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        goto bailMask;
    }
    
    
    glEnable(GL_BLEND);
    //    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);//20180730 fix bug: maskMV周围会有一条黑线
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, sourceTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(CVOpenGLESTextureGetTarget(mvTexture), CVOpenGLESTextureGetName(mvTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    if (effect.type == RDVideoMVEffectTypeMask) {
        glUseProgram(self.mvProgram);
        
        glUniform1i(mvInputTextureUniform, 0);
        glUniform1i(mvInputTextureUniform2, 1);
        
        glVertexAttribPointer(mvPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData);
        glEnableVertexAttribArray(mvPositionAttribute);
        
        glVertexAttribPointer(mvTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
        glEnableVertexAttribArray(mvTextureCoordinateAttribute);
        
    }
    
    if (effect.type == RDVideoMVEffectTypeScreen) {
        glUseProgram(self.screenProgram);
        
        
        glUniform1i(screenInputTextureUniform, 0);
        glUniform1i(screenInputTextureUniform2, 1);
        
        glVertexAttribPointer(screenPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData);
        glEnableVertexAttribArray(screenPositionAttribute);
        
        glVertexAttribPointer(screenTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
        glEnableVertexAttribArray(screenTextureCoordinateAttribute);
        
    }
    
    if (effect.type == RDVideoMVEffectTypeGray) {
        glUseProgram(self.hardLightProgram);
        
        glUniform1i(hardLightInputTextureUniform, 0);
        glUniform1i(hardLightInputTextureUniform2, 1);
        
        glVertexAttribPointer(hardLightPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData);
        glEnableVertexAttribArray(hardLightPositionAttribute);
        
        glVertexAttribPointer(hardLightTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
        glEnableVertexAttribArray(hardLightTextureCoordinateAttribute);
        
    }
    
    if (effect.type == RDVideoMVEffectTypeGreen) {
        
#if 1
        //指定绿色透明
        glUseProgram(self.chromaKeyProgram);
        glUniform1i(chromaKeyInputBackGroundImageTexture, 0); //背景纹理
        glUniform1i(chromaKeyInputColorTransparencyImageTexture, 1); //素材纹理，指定颜色透明
        glUniform3f(chromaKeyInputColorUnifrom, 0.0, 1.0, 0.0); //指定颜色透明 - 绿色
        
        glVertexAttribPointer(chromaKeyPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData);
        glEnableVertexAttribArray(chromaKeyPositionAttribute);
        
        glVertexAttribPointer(chromaKeyTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
        glEnableVertexAttribArray(chromaKeyTextureCoordinateAttribute);
#else
        
        glUseProgram(self.chromaKeyProgram);
        
        glUniform3f(chromaKeyColorToReplaceUniform, 0.0, 1.0, 0.0);
        glUniform1f(chromaKeyThresholdSensitivityUniform, 0.4);
        glUniform1f(chromaKeySmoothingUniform, 0.1);
        
        
        glUniform1i(chromaKeyInputTextureUniform, 0);
        glUniform1i(chromaKeyInputTextureUniform2, 1);
        
        glVertexAttribPointer(chromaKeyPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData);
        glEnableVertexAttribArray(chromaKeyPositionAttribute);
        
        glVertexAttribPointer(chromaKeyTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
        glEnableVertexAttribArray(chromaKeyTextureCoordinateAttribute);
#endif
    }
    
    if (effect.type == RDVideoMVEffectTypeChroma) {
        
        const CGFloat *components = CGColorGetComponents(effect.chromaColor.CGColor);
        //指定颜色透明
        glUseProgram(self.chromaKeyProgram);
        glUniform1i(chromaKeyInputBackGroundImageTexture, 0); //背景纹理
        glUniform1i(chromaKeyInputColorTransparencyImageTexture, 1); //素材纹理，指定颜色透明
        glUniform3f(chromaKeyInputColorUnifrom, components[0], components[1], components[2]); //指定颜色透明
        
        glVertexAttribPointer(chromaKeyPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData);
        glEnableVertexAttribArray(chromaKeyPositionAttribute);
        
        glVertexAttribPointer(chromaKeyTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
        glEnableVertexAttribArray(chromaKeyTextureCoordinateAttribute);
        
    }
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glFlush();//20180725 不刷新会导致11.0系统以上的设备，播放视频时不停闪烁
bailMask:
    glDeleteTextures(1, &sourceTexture);
    CFRelease(mvTexture);
    CFRelease(destTexture);
    glDisableVertexAttribArray(mvPositionAttribute);
    glDisableVertexAttribArray(mvTextureCoordinateAttribute);
}

- (GLuint)textureFromBufferObject:(unsigned char *) image Width:(int )width Height:(int)height
{
    GLuint texture = 0;
    
    glEnable(GL_TEXTURE_2D);
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)width, (int)height, 0, GL_BGRA, GL_UNSIGNED_BYTE, (GLvoid*)image);
    /**
     *  纹理过滤函数
     *  图象从纹理图象空间映射到帧缓冲图象空间(映射需要重新构造纹理图像,这样就会造成应用到多边形上的图像失真),
     *  这时就可用glTexParmeteri()函数来确定如何把纹理象素映射成像素.
     *  如何把图像从纹理图像空间映射到帧缓冲图像空间（即如何把纹理像素映射成像素）
     */
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); // S方向上的贴图模式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE); // T方向上的贴图模式
    // 线性过滤：使用距离当前渲染像素中心最近的4个纹理像素加权平均值
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    
    return texture;
}



- (bool) renderCustomFilter:(NSMutableArray<RDCustomFilter *>*)customFilterArray
     destinationPixelBuffer:(CVPixelBufferRef) destinationPixelBuffer
          usingSourceBuffer:(CVPixelBufferRef) sourcePixelBuffer
       andLastPictureBuffer:(CVPixelBufferRef)lastPictureBuffer
{
    if(!customFilterArray)
        return false;
    
    
    RDCustomFilter *pCustomFilterRender = nullptr;
    SHADER_TEXTURE_SAMPLER2D_LIST* pTextureList = nullptr;
    BOOL isNeedLastPicture = false;
    BOOL renderSuccess = false;
    for (int i = 0; i < customFilterArray.count; i++) {
        pCustomFilterRender = customFilterArray[i];
        pTextureList  = [pCustomFilterRender pTextureSamplerList];
        
        float startTime = CMTimeGetSeconds(pCustomFilterRender.timeRange.start);
        float endTime = startTime + CMTimeGetSeconds(pCustomFilterRender.timeRange.duration);
        
        if (displayTime < startTime || displayTime > endTime)
            continue;
        
        [EAGLContext setCurrentContext:self.currentContext];
        
        if(pTextureList && pCustomFilterRender.builtInType == RDBuiltIn_illusion)
            isNeedLastPicture = true;

        CVOpenGLESTextureRef source = [self customTextureForPixelBuffer:sourcePixelBuffer];
        if (!source) {
            [EAGLContext setCurrentContext:nil];
            continue;
        }
        

        CVOpenGLESTextureRef last = [self customTextureForPixelBuffer:lastPictureBuffer];
        if (!last && isNeedLastPicture) {
            [EAGLContext setCurrentContext:nil];
            continue;
        }
        CVOpenGLESTextureRef destTexture = [self customTextureForPixelBuffer:destinationPixelBuffer];
        if (!destTexture) {
            [EAGLContext setCurrentContext:nil];
            continue;
        }
        
        glBindFramebuffer(GL_FRAMEBUFFER, self.offscreenBufferHandle);
        glViewport(0, 0, (int)CVPixelBufferGetWidth(destinationPixelBuffer), (int)CVPixelBufferGetHeight(destinationPixelBuffer));
        
        
        // Attach the destination texture as a color attachment to the off screen frame buffer
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, CVOpenGLESTextureGetTarget(destTexture), CVOpenGLESTextureGetName(destTexture), 0);
        
        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
            NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
            CFRelease(source);
            CFRelease(last);
            CFRelease(destTexture);
            [EAGLContext setCurrentContext:nil];
            continue;
        }
        
        
        glEnable(GL_BLEND);
        //    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);//20180730 fix bug: maskMV周围会有一条黑线
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        
        
        //内置滤镜/特效
        if(pCustomFilterRender.builtInType == RDBuiltIn_illusion)
        {
            if(!pCustomFilterRender.vert || !pCustomFilterRender.frag)
            {
                RDTextureParams* textureParams = [[RDTextureParams alloc] init];
                textureParams.name = @"inputTextureLast";
                pCustomFilterRender.vert = kRDCustomFilterillusionVertexShader;
                pCustomFilterRender.frag = kRDCustomFilterillusionFragmentShader;
                pCustomFilterRender.timeRange  = CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, TIMESCALE),CMTimeMakeWithSeconds(endTime, TIMESCALE));
                NSError* error = [pCustomFilterRender setShaderTextureParams:textureParams];
                if(error)
                    NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
            }
            
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(CVOpenGLESTextureGetTarget(last), CVOpenGLESTextureGetName(last));
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            pCustomFilterRender.pTextureSamplerList->texture = CVOpenGLESTextureGetName(last);
        }
        else if(pCustomFilterRender.builtInType == RDBuiltIn_pencilSketch)
        {
            if(!pCustomFilterRender.vert || !pCustomFilterRender.frag)
            {
                
                pCustomFilterRender.vert = kRDCustomFilterPencilVertexShader;
                pCustomFilterRender.frag = kRDCustomFilterPencilFragmentShader;
                pCustomFilterRender.timeRange  = CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, TIMESCALE),CMTimeMakeWithSeconds(endTime, TIMESCALE));
                
                RDTextureParams *textureParams = [[RDTextureParams alloc] init];
                textureParams.name = @"TexturePencilResource";
                textureParams.type = RDSample2DBufferTexture;
                textureParams.path = @"pencil8S.png";
                NSError* error = [pCustomFilterRender setShaderTextureParams:textureParams];
                if(error)
                    NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
                
                NSMutableArray<RDShaderParams*> *paramsPencilPaintType = [[NSMutableArray alloc] init];
                RDShaderParams *PencilPaintType = [[RDShaderParams alloc] init];
                PencilPaintType.type = UNIFORM_INT;
                PencilPaintType.iValue = 0;
                [paramsPencilPaintType addObject:PencilPaintType];
                error = [pCustomFilterRender setShaderUniformParams:paramsPencilPaintType isRepeat:NO forUniform:@"PencilPaintType"];
                if(error)
                    NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
            }
            
        }
        else if(pCustomFilterRender.builtInType == RDBuiltIn_pencilColor)
        {
            if(!pCustomFilterRender.vert || !pCustomFilterRender.frag)
            {
                pCustomFilterRender.vert = kRDCustomFilterPencilVertexShader;
                pCustomFilterRender.frag = kRDCustomFilterPencilFragmentShader;
                pCustomFilterRender.timeRange  = CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, TIMESCALE),CMTimeMakeWithSeconds(endTime, TIMESCALE));
                
                RDTextureParams *textureParams = [[RDTextureParams alloc] init];
                textureParams.name = @"TexturePencilResource";
                textureParams.type = RDSample2DBufferTexture;
                textureParams.path = @"pencil8S.png";
                NSError* error = [pCustomFilterRender setShaderTextureParams:textureParams];
                if(error)
                    NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
                
                NSMutableArray<RDShaderParams*> *paramsPencilPaintType = [[NSMutableArray alloc] init];
                RDShaderParams *PencilPaintType = [[RDShaderParams alloc] init];
                PencilPaintType.type = UNIFORM_INT;
                PencilPaintType.iValue = 1;
                [paramsPencilPaintType addObject:PencilPaintType];
                error = [pCustomFilterRender setShaderUniformParams:paramsPencilPaintType isRepeat:NO forUniform:@"PencilPaintType"];
                if(error)
                    NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
            }
        }
        else if(pCustomFilterRender.builtInType == RDBuiltIn_pencilLightWater)
        {
            if(!pCustomFilterRender.vert || !pCustomFilterRender.frag)
            {
                pCustomFilterRender.vert = kRDCustomFilterPencilVertexShader;
                pCustomFilterRender.frag = kRDCustomFilterPencilFragmentShader;
                pCustomFilterRender.timeRange  = CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, TIMESCALE),CMTimeMakeWithSeconds(endTime, TIMESCALE));
                
                RDTextureParams *textureParams = [[RDTextureParams alloc] init];
                textureParams.name = @"TexturePencilResource";
                textureParams.type = RDSample2DBufferTexture;
                textureParams.path = @"pencil8S.png";
                NSError* error = [pCustomFilterRender setShaderTextureParams:textureParams];
                if(error)
                    NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
                
                NSMutableArray<RDShaderParams*> *paramsPencilPaintType = [[NSMutableArray alloc] init];
                RDShaderParams *PencilPaintType = [[RDShaderParams alloc] init];
                PencilPaintType.type = UNIFORM_INT;
                PencilPaintType.iValue = 2;
                [paramsPencilPaintType addObject:PencilPaintType];
                error = [pCustomFilterRender setShaderUniformParams:paramsPencilPaintType isRepeat:NO forUniform:@"PencilPaintType"];
                if(error)
                    NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
            }
        }
        else if(pCustomFilterRender.builtInType == RDBuiltIn_pencilCharcoalSketches)
        {
            if(!pCustomFilterRender.vert || !pCustomFilterRender.frag)
            {
                pCustomFilterRender.vert = kRDCustomFilterPencilVertexShader;
                pCustomFilterRender.frag = kRDCustomFilterPencilFragmentShader;
                pCustomFilterRender.timeRange  = CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, TIMESCALE),CMTimeMakeWithSeconds(endTime, TIMESCALE));
                
                RDTextureParams *textureParams = [[RDTextureParams alloc] init];
                textureParams.name = @"TexturePencilResource";
                textureParams.type = RDSample2DBufferTexture;
                textureParams.path = @"pencil8S.png";
                NSError* error = [pCustomFilterRender setShaderTextureParams:textureParams];
                if(error)
                    NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
                
                NSMutableArray<RDShaderParams*> *paramsPencilPaintType = [[NSMutableArray alloc] init];
                RDShaderParams *PencilPaintType = [[RDShaderParams alloc] init];
                PencilPaintType.type = UNIFORM_INT;
                PencilPaintType.iValue = 3;
                [paramsPencilPaintType addObject:PencilPaintType];
                error = [pCustomFilterRender setShaderUniformParams:paramsPencilPaintType isRepeat:NO forUniform:@"PencilPaintType"];
                if(error)
                    NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
            }
            
        }
        else if(pCustomFilterRender.builtInType == RDBuiltIn_pencilCrayon)
        {
            if(!pCustomFilterRender.vert || !pCustomFilterRender.frag)
            {
                pCustomFilterRender.vert = kRDCustomFilterPencilVertexShader;
                pCustomFilterRender.frag = kRDCustomFilterPencilFragmentShader;
                pCustomFilterRender.timeRange  = CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, TIMESCALE),CMTimeMakeWithSeconds(endTime, TIMESCALE));
                
                RDTextureParams *textureParams = [[RDTextureParams alloc] init];
                textureParams.name = @"TexturePencilResource";
                textureParams.type = RDSample2DBufferTexture;
                textureParams.path = @"pencil8S.png";
                NSError* error = [pCustomFilterRender setShaderTextureParams:textureParams];
                if(error)
                    NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
                
                NSMutableArray<RDShaderParams*> *paramsPencilPaintType = [[NSMutableArray alloc] init];
                RDShaderParams *PencilPaintType = [[RDShaderParams alloc] init];
                PencilPaintType.type = UNIFORM_INT;
                PencilPaintType.iValue = 4;
                [paramsPencilPaintType addObject:PencilPaintType];
                error = [pCustomFilterRender setShaderUniformParams:paramsPencilPaintType isRepeat:NO forUniform:@"PencilPaintType"];
                if(error)
                    NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
            }
            
        }
        else if(pCustomFilterRender.builtInType == RDBuiltIn_grayCrosspoint)
        {
            if(!pCustomFilterRender.vert || !pCustomFilterRender.frag)
            {
                pCustomFilterRender.vert = kRDCustomFilterCrossPointVertexShader;
                pCustomFilterRender.frag = kRDCustomFilterCrossPointFragmentShader;
                pCustomFilterRender.timeRange  = CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, TIMESCALE),CMTimeMakeWithSeconds(endTime, TIMESCALE));
                
                RDTextureParams *textureParams = [[RDTextureParams alloc] init];
                textureParams.name = @"TextureRadiationResource";
                textureParams.type = RDSample2DBufferTexture;
                textureParams.path = @"CrossPointLine.jpg";
                NSError* error = [pCustomFilterRender setShaderTextureParams:textureParams];
                if(error)
                    NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
                
                NSMutableArray<RDShaderParams*> *paramsCrossPointType = [[NSMutableArray alloc] init];
                RDShaderParams *CrossPointType = [[RDShaderParams alloc] init];
                CrossPointType.type = UNIFORM_INT;
                CrossPointType.iValue = 0;
                [paramsCrossPointType addObject:CrossPointType];
                error = [pCustomFilterRender setShaderUniformParams:paramsCrossPointType isRepeat:NO forUniform:@"CrossPointType"];
                if(error)
                    NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
            }
            
        }
        else if(pCustomFilterRender.builtInType == RDBuiltIn_colorCrosspoint)
        {
            if(!pCustomFilterRender.vert || !pCustomFilterRender.frag)
            {
                pCustomFilterRender.vert = kRDCustomFilterCrossPointVertexShader;
                pCustomFilterRender.frag = kRDCustomFilterCrossPointFragmentShader;
                pCustomFilterRender.timeRange  = CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, TIMESCALE),CMTimeMakeWithSeconds(endTime, TIMESCALE));
                
                RDTextureParams *textureParams = [[RDTextureParams alloc] init];
                textureParams.name = @"TextureRadiationResource";
                textureParams.type = RDSample2DBufferTexture;
                textureParams.path = @"CrossPointLine.jpg";
                NSError* error = [pCustomFilterRender setShaderTextureParams:textureParams];
                if(error)
                    NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
                
                NSMutableArray<RDShaderParams*> *paramsCrossPointType = [[NSMutableArray alloc] init];
                RDShaderParams *CrossPointType = [[RDShaderParams alloc] init];
                CrossPointType.type = UNIFORM_INT;
                CrossPointType.iValue = 1;
                [paramsCrossPointType addObject:CrossPointType];
                error = [pCustomFilterRender setShaderUniformParams:paramsCrossPointType isRepeat:NO forUniform:@"CrossPointType"];
                if(error)
                    NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
            }
            
        }
        
        
        pTextureList = [pCustomFilterRender pTextureSamplerList];
        if(pTextureList )
        {
            //添加素材
            if(pTextureList->path.length == 0)
                NSLog(@"error : texture url is null!");
            else
            {
                if (!pTextureList->texture)
                {
                    pTextureList->texture = [self textureFromUIImage:[UIImage imageWithContentsOfFile:pTextureList->path]];//ok
                    //                    pTextureList->texture = [self textureFromUIImage:[UIImage imageNamed:pTextureList->path]];//error
                    glActiveTexture(GL_TEXTURE1);
                    glBindTexture(GL_TEXTURE_2D, pTextureList->texture);
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                    
                    if( RDTextureWarpModeRepeat == pTextureList->warpMode)
                    {
                        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
                        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
                    }
                    else
                    {
                        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                    }
                }
            }
        }
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(CVOpenGLESTextureGetTarget(source), CVOpenGLESTextureGetName(source));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        
        [pCustomFilterRender renderTexture:CVOpenGLESTextureGetName(source) FrameWidth:(int)CVPixelBufferGetWidth(destinationPixelBuffer) FrameHeight:(int)CVPixelBufferGetHeight(destinationPixelBuffer) RotateAngle:0 Time:displayTime];
        
        if(source)
            CFRelease(source);
        if(last)
            CFRelease(last);
        if(destTexture)
            CFRelease(destTexture);
        
        [EAGLContext setCurrentContext:nil];
        renderSuccess = true;
    }
    
    return renderSuccess;
}



- (GLuint ) textureFromUIImage:(UIImage *)image
{
    GLuint imageTexture = -1;
    
    int imageWidth = image.size.width;
    int imageHeight = image.size.height;
    
    CGImageRef cgImage = [image CGImage];
    
    void* imageData = (void*)calloc(1, (int)imageWidth*(int)imageHeight*4);
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef imageContext = CGBitmapContextCreate(imageData, imageWidth, imageHeight, 8, 4*imageWidth, genericRGBColorspace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, imageWidth, imageHeight), cgImage);
    CGContextRelease(imageContext);
    CGColorSpaceRelease(genericRGBColorspace);
    
    glGenTextures(1, &imageTexture);
    glBindTexture(GL_TEXTURE_2D, imageTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, (GLvoid*)imageData);
    
    free(imageData);
    
    return imageTexture;
}

- (bool) renderCustomFilterIsNeedLastPicture:(NSMutableArray<RDCustomFilter *>*)customFilterArray
{
    bool result = false ;
    
    if(!customFilterArray)
        return result;
    
    RDCustomFilter *pCustomFilterRender = nullptr;
    for (int i = 0; i < customFilterArray.count; i++)
    {
        pCustomFilterRender = customFilterArray[i];
        
        float start = CMTimeGetSeconds(pCustomFilterRender.timeRange.start);
        float duration = CMTimeGetSeconds(pCustomFilterRender.timeRange.duration);
        
        if(start < displayTime && (start + duration) > displayTime)
        {
            //是否需要上一帧画面，内置特效：幻觉
            if (pCustomFilterRender.builtInType == RDBuiltIn_illusion )
                result = true;
//            else if(1)
//            {
//                //保留三位有效数字，确保精度
//                float curTime = duration > 1.0 ? (displayTime - start - floor(displayTime - start)) : start;
//                if (curTime <= _fps*3)
//                    result = true;
//            }
            else
                result = false;
        }
    }
    return result;
}
- (UIImage *) convertBitmapRGBA8ToUIImage:(unsigned char *) buffer withWidth:(int) width withHeight:(int) height {

    size_t bufferLength = width * height * 4;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, bufferLength, NULL);
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = 4 * width;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    
    if(colorSpaceRef == NULL) {
        NSLog(@"Error allocating color space");
        CGDataProviderRelease(provider);
        return nil;
    }
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef iref = CGImageCreate(width,
                                    height,
                                    bitsPerComponent,
                                    bitsPerPixel,
                                    bytesPerRow,
                                    colorSpaceRef,
                                    bitmapInfo,
                                    provider,    // data provider
                                    NULL,        // decode
                                    YES,            // should interpolate
                                    renderingIntent);
    
    uint32_t* pixels = (uint32_t*)malloc(bufferLength);
    
    if(pixels == NULL) {
        NSLog(@"Error: Memory not allocated for bitmap");
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpaceRef);
        CGImageRelease(iref);
        return nil;
    }
    
    CGContextRef context = CGBitmapContextCreate(pixels,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpaceRef,
                                                 bitmapInfo);
    
    if(context == NULL) {
        NSLog(@"Error context not created");
        free(pixels);
    }
    
    UIImage *image = nil;
    if(context) {
        CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), iref);
        CGImageRef imageRef = CGBitmapContextCreateImage(context);
        // Support both iPad 3.2 and iPhone 4 Retina displays with the correct scale
        if([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
            float scale = [[UIScreen mainScreen] scale];
            image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
        } else {
            image = [UIImage imageWithCGImage:imageRef];
        }
        CGImageRelease(imageRef);
        CGContextRelease(context);
    }
    
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(iref);
    CGDataProviderRelease(provider);
    if(pixels)
        free(pixels);
    
    return image;
}


- (void) renderMVPixelBuffer:(CVPixelBufferRef) destinationPixelBuffer
           usingSourceBuffer:(CVPixelBufferRef) sourcePixelBuffer
               mvPixelBuffer:(CVPixelBufferRef) mvPixelBuffer
                      Effect:(VVMovieEffect*) effect
{
    
    
    GLfloat quadTextureData [] = { //纹理坐标
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    GLfloat quadVertexData [] = {
        -1.0, 1.0,
        1.0, 1.0,
        -1.0, -1.0,
        1.0, -1.0,
    };
    
    [EAGLContext setCurrentContext:self.currentContext];
    
    CVOpenGLESTextureRef sourceTexture = [self customTextureForPixelBuffer:sourcePixelBuffer];
    if (!sourceTexture) {
        return;
    }
    CVOpenGLESTextureRef destTexture = [self customTextureForPixelBuffer:destinationPixelBuffer];
    if (!destTexture) {
        return;
    }
    CVOpenGLESTextureRef mvTexture = [self customTextureForPixelBuffer:mvPixelBuffer];
    if (!mvTexture) {
        return;
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, self.offscreenBufferHandle);
    glViewport(0, 0, (int)CVPixelBufferGetWidth(destinationPixelBuffer), (int)CVPixelBufferGetHeight(destinationPixelBuffer));
    
    
    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, CVOpenGLESTextureGetTarget(destTexture), CVOpenGLESTextureGetName(destTexture), 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        goto bailMask;
    }
    
    
    glEnable(GL_BLEND);
    //    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);//20180730 fix bug: maskMV周围会有一条黑线
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(CVOpenGLESTextureGetTarget(sourceTexture), CVOpenGLESTextureGetName(sourceTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(CVOpenGLESTextureGetTarget(mvTexture), CVOpenGLESTextureGetName(mvTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    
    if (effect.type == RDVideoMVEffectTypeMask) {
        
        glUseProgram(self.mvProgram);
        
        glUniform1i(mvInputTextureUniform, 0);
        glUniform1i(mvInputTextureUniform2, 1);
        
        glVertexAttribPointer(mvPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData);
        glEnableVertexAttribArray(mvPositionAttribute);
        
        glVertexAttribPointer(mvTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
        glEnableVertexAttribArray(mvTextureCoordinateAttribute);
        
    }
    
    if (effect.type == RDVideoMVEffectTypeScreen) {
       
        glUseProgram(self.screenProgram);
        
        glUniform1i(screenInputTextureUniform, 0);
        glUniform1i(screenInputTextureUniform2, 1);
        
        glVertexAttribPointer(screenPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData);
        glEnableVertexAttribArray(screenPositionAttribute);
        
        glVertexAttribPointer(screenTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
        glEnableVertexAttribArray(screenTextureCoordinateAttribute);
        
    }
    
    if (effect.type == RDVideoMVEffectTypeGray) {
        glUseProgram(self.hardLightProgram);
        
        glUniform1i(hardLightInputTextureUniform, 0);
        glUniform1i(hardLightInputTextureUniform2, 1);
        
        glVertexAttribPointer(hardLightPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData);
        glEnableVertexAttribArray(hardLightPositionAttribute);
        
        glVertexAttribPointer(hardLightTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
        glEnableVertexAttribArray(hardLightTextureCoordinateAttribute);
        
    }
    
    if (effect.type == RDVideoMVEffectTypeGreen) {
        
#if 1
        
        //指定绿色透明
        glUseProgram(self.chromaKeyProgram);
        glUniform1i(chromaKeyInputBackGroundImageTexture, 0); //背景纹理
        glUniform1i(chromaKeyInputColorTransparencyImageTexture, 1); //素材纹理，指定颜色透明
        glUniform3f(chromaKeyInputColorUnifrom, 0.0, 1.0, 0.0); //指定颜色透明 - 绿色
        
        glVertexAttribPointer(chromaKeyPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData);
        glEnableVertexAttribArray(chromaKeyPositionAttribute);
        
        glVertexAttribPointer(chromaKeyTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
        glEnableVertexAttribArray(chromaKeyTextureCoordinateAttribute);
        
#else
        glUseProgram(self.chromaKeyProgram);
        
        glUniform3f(chromaKeyColorToReplaceUniform, 0.0, 1.0, 0.0);
        glUniform1f(chromaKeyThresholdSensitivityUniform, 0.4);
        glUniform1f(chromaKeySmoothingUniform, 0.1);
        
        
        glUniform1i(chromaKeyInputTextureUniform, 0);
        glUniform1i(chromaKeyInputTextureUniform2, 1);
        
        glVertexAttribPointer(chromaKeyPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData);
        glEnableVertexAttribArray(chromaKeyPositionAttribute);
        
        glVertexAttribPointer(chromaKeyTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
        glEnableVertexAttribArray(chromaKeyTextureCoordinateAttribute);
#endif
    }
    if (effect.type == RDVideoMVEffectTypeChroma) {
            
            
        const CGFloat *components = CGColorGetComponents(effect.chromaColor.CGColor);
        //指定颜色透明
        glUseProgram(self.chromaKeyProgram);
        glUniform1i(chromaKeyInputBackGroundImageTexture, 0); //背景纹理
        glUniform1i(chromaKeyInputColorTransparencyImageTexture, 1); //素材纹理，指定颜色透明
        glUniform3f(chromaKeyInputColorUnifrom, components[0], components[1], components[2]); //指定颜色透明
        
        glVertexAttribPointer(chromaKeyPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData);
        glEnableVertexAttribArray(chromaKeyPositionAttribute);
        
        glVertexAttribPointer(chromaKeyTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
        glEnableVertexAttribArray(chromaKeyTextureCoordinateAttribute);
            
    }
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glFlush();//20180725 不刷新会导致11.0系统以上的设备，播放视频时不停闪烁
bailMask:
    CFRelease(sourceTexture);
    CFRelease(mvTexture);
    CFRelease(destTexture);
    glDisableVertexAttribArray(mvPositionAttribute);
    glDisableVertexAttribArray(mvTextureCoordinateAttribute);
}

- (void)getSrcVertFromAsset:(VVAsset*) asset Crop:(CGRect) crop srcVert:(GLfloat[][2])srcVert {
    
    CGRect srcCrop = crop;
    
    if (asset.type == RDAssetTypeVideo) {
        CGAffineTransform t = asset.transform;
        
        if((t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0) || (t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0))
        {
            //90 or -90
            srcCrop.origin.x  = crop.origin.y;
            srcCrop.origin.y  = crop.origin.x;
            
            srcCrop.size.width = crop.size.height;
            srcCrop.size.height = crop.size.width;
            
        }
    }
    
    srcVert[0][0] = srcCrop.origin.x;
    srcVert[0][1] = srcCrop.origin.y;
    srcVert[1][0] = srcCrop.origin.x + srcCrop.size.width;
    srcVert[1][1] = srcCrop.origin.y;
    srcVert[2][0] = srcCrop.origin.x + srcCrop.size.width;
    srcVert[2][1] = srcCrop.origin.y + srcCrop.size.height;
    srcVert[3][0] = srcCrop.origin.x;
    srcVert[3][1] = srcCrop.origin.y + srcCrop.size.height;
}
-(bool)getDestVertFromAsset:(VVAsset*)asset PointFrom:(VVAssetAnimatePosition*)a  PointTo:(VVAssetAnimatePosition*)b Current:(float)curTime DestVert:(GLfloat[][2])destVert watermarkStartTime:(float)watermarkStartTime
{
    GLfloat VertArray[4][2] = {0};
    float startX = 0.0;
    float startY = 0.0;
    float endX = 0.0;
    float endY = 0.0;
    bool bPoint = false;
    float percent = (curTime - watermarkStartTime - a.atTime - CMTimeGetSeconds(asset.startTimeInScene))/(b.atTime - a.atTime);
    for(int i = 0;i<[a.pointsArray count];i++)
    {
        startX = [[[a.pointsArray objectAtIndex:i] objectAtIndex:0] doubleValue];
        startY = [[[a.pointsArray objectAtIndex:i] objectAtIndex:1] doubleValue];
        
        endX = [[[b.pointsArray objectAtIndex:i] objectAtIndex:0] doubleValue];
        endY = [[[b.pointsArray objectAtIndex:i] objectAtIndex:1] doubleValue];
        
        //        NSLog(@"percent :%f start  : i: %d x:%f y:%f end: x:%f y:%f a.atTime:%f",percent,i,startX,startY,endX,endY,a.atTime);
        
        VertArray[i][0] = startX + (endX - startX)*percent;
        VertArray[i][1] = startY + (endY - startY)*percent;
        
    }
    
    if (0 == VertArray[0][0] - VertArray[1][0] && 0 == VertArray[0][1] - VertArray[3][1])
        bPoint = true;
    //video
    if (asset.type == RDAssetTypeVideo) {
        CGAffineTransform t = asset.transform;
        
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0)
        {
            //90
            
            destVert[0][0] = VertArray[1][0];
            destVert[0][1] = VertArray[1][1];
            
            destVert[1][0] = VertArray[2][0];
            destVert[1][1] = VertArray[2][1];
            
            destVert[2][0] = VertArray[3][0];
            destVert[2][1] = VertArray[3][1];
            
            destVert[3][0] = VertArray[0][0];
            destVert[3][1] = VertArray[0][1];
            
            return bPoint;
        }
        if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0)
        {
            //-90
            
            destVert[0][0] = VertArray[3][0];
            destVert[0][1] = VertArray[3][1];
            
            destVert[1][0] = VertArray[0][0];
            destVert[1][1] = VertArray[0][1];
            
            destVert[2][0] = VertArray[1][0];
            destVert[2][1] = VertArray[1][1];
            
            destVert[3][0] = VertArray[2][0];
            destVert[3][1] = VertArray[2][1];
            
            return bPoint;
        }
        if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0)
        {
            //180
            
            destVert[0][0] = VertArray[2][0];
            destVert[0][1] = VertArray[2][1];
            
            destVert[1][0] = VertArray[3][0];
            destVert[1][1] = VertArray[3][1];
            
            destVert[2][0] = VertArray[0][0];
            destVert[2][1] = VertArray[0][1];
            
            destVert[3][0] = VertArray[1][0];
            destVert[3][1] = VertArray[1][1];
            
            return bPoint;
        }
        if((t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0) )
        {
            // 0 or 360
            for(int i = 0;i<[a.pointsArray count];i++)
            {
                destVert[i][0] = VertArray[i][0];
                destVert[i][1] = VertArray[i][1];
            }
            return bPoint;
        }
    }
    else
    {
        //image
        for(int i = 0;i<[a.pointsArray count];i++)
        {
            destVert[i][0] = VertArray[i][0];
            destVert[i][1] = VertArray[i][1];
        }
        return bPoint;
    }
    
    return bPoint;
}
-(bool)getDestVertFromAsset:(VVAsset*) asset PointArray:(NSArray *)pointArray DestVert:(GLfloat[][2])destVert
{
    bool bPoint = false;
    GLfloat VertArray[4][2] = {0};
    
    for(int i = 0;i<[pointArray count];i++)
    {
        VertArray[i][0] = [[[pointArray objectAtIndex:i] objectAtIndex:0] doubleValue];
        VertArray[i][1] = [[[pointArray objectAtIndex:i] objectAtIndex:1] doubleValue];
    }
    
    if (0 == VertArray[0][0] - VertArray[1][0] && 0 == VertArray[0][1] - VertArray[3][1])
        bPoint = true;
    
    //video
    if (asset.type == RDAssetTypeVideo) {
        CGAffineTransform t = asset.transform;
        
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0)
        {
            //90
            destVert[0][0] = VertArray[1][0];
            destVert[0][1] = VertArray[1][1];
            
            destVert[1][0] = VertArray[2][0];
            destVert[1][1] = VertArray[2][1];
            
            destVert[2][0] = VertArray[3][0];
            destVert[2][1] = VertArray[3][1];
            
            destVert[3][0] = VertArray[0][0];
            destVert[3][1] = VertArray[0][1];
            
            return bPoint;
        }
        if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0)
        {
            //-90
            destVert[0][0] = VertArray[3][0];
            destVert[0][1] = VertArray[3][1];
            
            destVert[1][0] = VertArray[0][0];
            destVert[1][1] = VertArray[0][1];
            
            destVert[2][0] = VertArray[1][0];
            destVert[2][1] = VertArray[1][1];
            
            destVert[3][0] = VertArray[2][0];
            destVert[3][1] = VertArray[2][1];
            
            return bPoint;
        }
        if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0)
        {
            //180
            
            destVert[0][0] = VertArray[2][0];
            destVert[0][1] = VertArray[2][1];
            
            destVert[1][0] = VertArray[3][0];
            destVert[1][1] = VertArray[3][1];
            
            destVert[2][0] = VertArray[0][0];
            destVert[2][1] = VertArray[0][1];
            
            destVert[3][0] = VertArray[1][0];
            destVert[3][1] = VertArray[1][1];
            
            return bPoint;
        }
        if((t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0) )
        {
            // 0 or 360
            for(int i = 0;i<[pointArray count];i++)
            {
                destVert[i][0] = VertArray[i][0];
                destVert[i][1] = VertArray[i][1];
            }
            return bPoint;
        }
    }
    else
    {
        //image
        for(int i = 0;i<[pointArray count];i++)
        {
            destVert[i][0] = VertArray[i][0];
            destVert[i][1] = VertArray[i][1];
        }
        return bPoint;
    }
    
    return bPoint;
}

-(int ) getCropRectFromAsset:(VVAsset*) asset
{
    return 1;
}

-(float) getOriginRotateAngleFromAsset:(VVAsset*) asset
{
    //video
    if (asset.type == RDAssetTypeVideo) {
        float angele = 0.0;
        CGAffineTransform t = asset.transform;
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0)
            angele = 90.0;
        if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0)
            angele = 90.0;
        if((t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0) )
            angele = 0.0;
        if((t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0))
            angele = 180.0;
        return angele;
    }
    else
    {
        //image
        return asset.rotate;
    }
    
    return 0.0;
}

-(float) getRotateAngleFromAsset:(VVAsset*) asset
{
    //video
    if (asset.type == RDAssetTypeVideo) {
        float angele = 0.0;
        CGAffineTransform t = asset.transform;
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0)
            angele = 90.0;
        if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0)
            angele = 90.0;
        if((t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0) || (t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0))
            angele = 0.0;
        
        angele += asset.rotate;
        return angele;
    }
    else
    {
        //image
        return asset.rotate;
    }
    
    return 0.0;
}



//-(void )renderTotextur:(GLuint)texture StartValue:(float)startValue EndValue:(float)endValue TextureWidth:(float)width TextureHeight:(int)height
-(void )renderGaussBlurTotexture:(GLuint)texture TextureWidth:(float)width TextureHeight:(int)height IsFirst:(float)first
     OriginRotateAngle:(float)originRotateAngle UserRotateAngle:(float)userRotateAngle Crop:(CGRect)crop TextureCoordinates:(const float*)textureCoordinates
{

    GLfloat vertices[8]  = {
        
        -1.0,1.0,
        1.0,1.0,
        -1.0,-1.0,
        1.0,-1.0,
    };
    
//    GLfloat textureCoordinates[8]  = {
//        0.0,1.0,
//        1.0,1.0,
//        0.0,0.0,
//        1.0,0.0,
//
//    };
    
    glUseProgram(self.borderBlurProgram);
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    
    glUniform1i(borderBlurInputTextureUniform, 2);
    
    RDMatrixLoadIdentity(&_modelViewMatrix);
    glUniformMatrix4fv(borderBlurTransformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
    
    RDMatrixLoadIdentity(&_projectionMatrix);
    
    if(1.0 == first)
    {
        if(originRotateAngle )
        {
            if(userRotateAngle)
                RDMatrixRotate(&_projectionMatrix, originRotateAngle - userRotateAngle, 0, 0, -1);
            else
                RDMatrixRotate(&_projectionMatrix, originRotateAngle + userRotateAngle, 0, 0, -1);
        }
        else
            RDMatrixRotate(&_projectionMatrix, originRotateAngle + userRotateAngle, 0, 0, 1);
        
    }
    glUniformMatrix4fv(borderBlurProjectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
    
    glUniform1f(borderBlurEdgeUniform, 0.05);
    glUniform1f(borderBlurRadiusUniform, 20.0);
    glUniform1f(borderBlurIsFirstUniform, first);
    
    glUniform2f(borderBlurResolutionUniform, (float)width, (float)height);
    glUniform2f(borderBlurViewportUniform, (float)_videoSize.width, (float)_videoSize.height);
    if(originRotateAngle + userRotateAngle == 90.0 || originRotateAngle + userRotateAngle == -90.0 ||
       originRotateAngle + userRotateAngle == -270.0|| originRotateAngle + userRotateAngle == 270.0)
    {
        glUniform2f(borderBlurViewportUniform, (float)_videoSize.height, (float)_videoSize.width);
        if(0.0 == first)
        {
            glUniform2f(borderBlurResolutionUniform, (float)height, (float)width);
            glUniform2f(borderBlurViewportUniform, (float)_videoSize.width, (float)_videoSize.height);
        }
    }
    
    
    
    if(90 == originRotateAngle || -90 == originRotateAngle || 270 == originRotateAngle ||-270 == originRotateAngle)
    {
        //视频本身带有旋转角度
        if(1.0 == first)
        {
            //如果视频自带旋转角度：asset.crop为旋转之后的裁剪区域---->转为旋转之前的crop
            glUniform2f(borderBlurClipOriginalUniform, crop.origin.y, 1.0-crop.size.width-crop.origin.x);
            glUniform2f(borderBlurClipSizeUniform, crop.size.height, crop.size.width);
            
        }
        else
        {
            if(originRotateAngle + userRotateAngle == 90.0 || originRotateAngle + userRotateAngle == -90.0 ||
               originRotateAngle + userRotateAngle == -270.0|| originRotateAngle + userRotateAngle == 270.0)
            {
                glUniform2f(borderBlurClipOriginalUniform, crop.origin.x, crop.origin.y);
                glUniform2f(borderBlurClipSizeUniform, crop.size.width, crop.size.height);
            }
            else
            {
                glUniform2f(borderBlurClipOriginalUniform, crop.origin.y, 1.0-crop.size.width-crop.origin.x);
                glUniform2f(borderBlurClipSizeUniform, crop.size.height, crop.size.width);
            }
            
        }
        
    }
    else
    {
        //普通图片/视频
        if(1.0 == first)
        {
            glUniform2f(borderBlurClipOriginalUniform, crop.origin.x, crop.origin.y);
            glUniform2f(borderBlurClipSizeUniform, crop.size.width, crop.size.height);
        }
        
        else
        {
            if(originRotateAngle + userRotateAngle == 90.0 || originRotateAngle + userRotateAngle == -90.0 ||
               originRotateAngle + userRotateAngle == -270.0|| originRotateAngle + userRotateAngle == 270.0)
            {
                glUniform2f(borderBlurClipOriginalUniform, crop.origin.y, 1.0-crop.size.width-crop.origin.x);
                glUniform2f(borderBlurClipSizeUniform, crop.size.height, crop.size.width);
            }
            else
            {
                glUniform2f(borderBlurClipOriginalUniform, crop.origin.x, crop.origin.y);
                glUniform2f(borderBlurClipSizeUniform, crop.size.width, crop.size.height);
                
            }
           
        }
        
    }
    
    
    glVertexAttribPointer(borderBlurPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glEnableVertexAttribArray(borderBlurPositionAttribute);
    glVertexAttribPointer(borderBlurTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    glEnableVertexAttribArray(borderBlurTextureCoordinateAttribute);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDisableVertexAttribArray(borderBlurPositionAttribute);
    glDisableVertexAttribArray(borderBlurTextureCoordinateAttribute);
 
}

- (UIImage *) getImageFromPath:(NSURL *)path{
    __block UIImage* image;
    if ([RDRecordHelper isSystemPhotoUrl:path]) {
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.synchronous = YES;
        option.resizeMode = PHImageRequestOptionsResizeModeExact;
        
        PHAsset* asset =[[PHAsset fetchAssetsWithALAssetURLs:@[path] options:nil] objectAtIndex:0];
        
        CGSize size = [RDRecordHelper matchSize];
        int width = ((size.width>480?800:400));
        [[PHImageManager defaultManager] requestImageForAsset:asset
                                                   targetSize:CGSizeMake(width, width)
                                                  contentMode:PHImageContentModeAspectFit
                                                      options:option
                                                resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                    image = result;
                                                    
                                                }];
        
    }else{
        NSString* pathString = path.path;
        image = [UIImage imageWithContentsOfFile:pathString];
        image = [RDRecordHelper fixOrientation:image];
    }
    
    return image;
}

- (int)processAssetToFrameBuferObjectWithScene:(RDScene*)scene Asset:(VVAsset* )asset request:(AVAsynchronousVideoCompositionRequest *)request Index:(int)index
{
    TextureFBOList* pList = nil;
    TextureFBOList* pNode = nil;
    
    int result_statu = 1;
    int dstTextureWidth = _videoSize.width;
    int dstTextureHeight = _videoSize.height;
    float facor = 1.0;
    sourceAssetTexture = 0;
    
    if (!((RDVideoCompositorInstruction *)request.videoCompositionInstruction).isExporting) {
        facor = [self getFacorFromWidth:dstTextureWidth height:dstTextureHeight];
    }
    dstTextureWidth  *= facor;
    dstTextureHeight *= facor;
    
    if(dstTextureWidth%2 != 0)
        dstTextureWidth += 1;
    if(dstTextureHeight%2 != 0)
        dstTextureHeight += 1;
    
    pList = pAssetFboList;
    while (pList) {
        if(pList->index == index)
            break;
        pList = pList->next;
    }
    if(!pList)
    {
        if (!pAssetFboList) {
            pAssetFboList = (struct TextureFBOList*)malloc(sizeof(TextureFBOList));
            if(!pAssetFboList)
            {
                NSLog(@"dst fbo malloc fail!!");
                return 0;
            }
            memset(pAssetFboList, 0, sizeof(TextureFBOList));
            pAssetFboList->index = index;
            pNode = pAssetFboList;
        }
        else
        {
            TextureFBOList* p = pAssetFboList;
            while(p && p->next)
                p = p->next;
            p->next = (struct TextureFBOList*)malloc(sizeof(TextureFBOList));
            if(!p->next)
            {
                NSLog(@"dst fbo malloc fail!!");
                return 0;
            }
            memset(p->next, 0, sizeof(TextureFBOList));
            p->next->index = index;
            pNode = p->next;
        }
    }
    else
        pNode = pList;
    
    if (pNode->height != dstTextureHeight || pNode->width != dstTextureWidth)
        [self initFrameBuffobject:pNode DstWidth:dstTextureWidth DstHeight:dstTextureHeight];
    
    if(!pNode->fbo)
        glGenFramebuffers(1, &pNode->fbo);
    
    
    glBindFramebuffer(GL_FRAMEBUFFER, pNode->fbo);
    glViewport(0, 0, pNode->width, pNode->height);
    
    
    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, pNode->texture, 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
    
    
    glUseProgram(self.program);
    
    //开启blend
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
//    [self renderScence:scene Asset:asset AssetIndex:index request:request Statu:&result_statu];
    [self renderAsset:asset AssetIndex:index TimeRange:scene.fixedTimeRange request:request Statu:&result_statu];
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    if(sourceAssetTexture)
    {
        glBindTexture(CVOpenGLESTextureGetTarget(sourceAssetTexture), 0);
        CFRelease(sourceAssetTexture);
        sourceAssetTexture = 0;
    }

    return result_statu;
}

- (int)processAssetCustomFilterAttribute:(VVAsset* )asset request:(AVAsynchronousVideoCompositionRequest *)request CurrentTime:(float)time Index:(int)index
{
    float startTime = CMTimeGetSeconds(asset.customFilter.timeRange.start);
    float endTime = startTime + CMTimeGetSeconds(asset.customFilter.timeRange.duration);
    TextureFBOList* renderFbo = nil;
    
    if (time < startTime || time > endTime)
        return 0;
 
    float width  = pDstFboList->width;
    float height = pDstFboList->height;
    float facor = 1.0;
    struct TextureFBOList* pNode = nullptr;
    struct TextureFBOList* pList = pFilterFboList;
    
    float dstTextureWidth = pDstFboList->width;
    float dstTextureHeight = pDstFboList->height;
    
    //遍历链表找到当前需要绘制的纹理
    if(!pAssetFboList)
    {
        NSLog(@"");
        return 0;
    }
    else
    {
        renderFbo = pAssetFboList;
        while (renderFbo) {
            if(renderFbo->index == index)
                break;
            renderFbo = renderFbo->next;
        }
    }
    if(!renderFbo)
    {
        NSLog(@"fail to find specified asset texture");
        return 0;
    }
    
    if (asset.type == RDAssetTypeVideo && !((RDVideoCompositorInstruction *)request.videoCompositionInstruction).isExporting)//视频
    {
        facor = [self getFacorFromWidth:width height:height];
    }
    
    width  *= facor;
    height *= facor;
    
    if(((int)width)%2!=0)
        width = (int)(width+1);
    if(((int)height)%2!=0)
        height = (int)(height+1);
    
    //fbo size
    dstTextureWidth = width;
    dstTextureHeight = height;
    
    
    //将绘制的滤镜结果保存到FBO中
    if (!pFilterFboList) {
        pFilterFboList = (struct TextureFBOList*)malloc(sizeof(TextureFBOList));
        if(!pFilterFboList)
        {
            NSLog(@"custom filter malloc fail!!");
            return 0;
        }
        memset(pFilterFboList, 0, sizeof(TextureFBOList));
        pFilterFboList->index = index;
        pNode = pFilterFboList;
    }
    else
    {
        struct TextureFBOList* pList = pFilterFboList;
        while (pList) {
            if(pList->index == index)
            {
                pNode = pList;
                break;
            }
            pList = pList->next;
        }
        if(!pList)
        {
            pList = pFilterFboList;
            while (pList && pList->next)
                pList = pList->next;
            
            pList->next = (struct TextureFBOList*)malloc(sizeof(TextureFBOList));
            if(!pList->next)
            {
                NSLog(@"blurList malloc fail!!");
                return 0;
            }
            memset(pList->next, 0, sizeof(TextureFBOList));
            pList->next->index = index;
            pNode = pList->next;
        }
        
    }
    if (pNode->height != height || pNode->width != width)
        [self initFrameBuffobject:pNode DstWidth:width DstHeight:height];

    
    if(!pNode->fbo)
        glGenFramebuffers(1, &pNode->fbo);
    
    
    glBindFramebuffer(GL_FRAMEBUFFER, pNode->fbo);
    glViewport(0, 0, width, height);
    
    
    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, pNode->texture, 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);//20180730 fix bug: maskMV周围会有一条黑线
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    
    //内置滤镜/特效
    if(asset.customFilter.builtInType == RDBuiltIn_illusion)
    {
        
        GLuint lastTexture = 0;
        
        if(!asset.customFilter.vert || !asset.customFilter.frag)
        {
            RDTextureParams* textureParams = [[RDTextureParams alloc] init];
            textureParams.name = @"inputTextureLast";
            asset.customFilter.vert = kRDCustomFilterillusionVertexShader;
            asset.customFilter.frag = kRDCustomFilterillusionFragmentShader;
            //            pCustomFilterRender.timeRange  = CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, TIMESCALE),CMTimeMakeWithSeconds(endTime, TIMESCALE));
            NSError* error = [asset.customFilter setShaderTextureParams:textureParams];
            if(error)
                NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
        }
        
        if (pLastTextureList) {
            
            struct GLTextureList* pList = pLastTextureList;
            while (pList) {
                if (pList->index == index)
                    break;
                pList = pList->next;
            }
            if(pList)
                lastTexture = pList->texture;
            else
                lastTexture = renderFbo->texture;
            
        }
        else
            lastTexture = renderFbo->texture;
        
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, lastTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        asset.customFilter.pTextureSamplerList->texture = lastTexture;
    }
    else if(asset.customFilter.builtInType == RDBuiltIn_pencilSketch)
    {
        if(!asset.customFilter.vert || !asset.customFilter.frag)
        {
            
            asset.customFilter.vert = kRDCustomFilterPencilVertexShader;
            asset.customFilter.frag = kRDCustomFilterPencilFragmentShader;
            
            RDTextureParams *textureParams = [[RDTextureParams alloc] init];
            textureParams.name = @"TexturePencilResource";
            textureParams.type = RDSample2DBufferTexture;
            textureParams.path = @"pencil8S.png";
            NSError* error = [asset.customFilter setShaderTextureParams:textureParams];
            if(error)
                NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
            
            NSMutableArray<RDShaderParams*> *paramsPencilPaintType = [[NSMutableArray alloc] init];
            RDShaderParams *PencilPaintType = [[RDShaderParams alloc] init];
            PencilPaintType.type = UNIFORM_INT;
            PencilPaintType.iValue = 0;
            [paramsPencilPaintType addObject:PencilPaintType];
            error = [asset.customFilter setShaderUniformParams:paramsPencilPaintType isRepeat:NO forUniform:@"PencilPaintType"];
            if(error)
                error = error;
        }
        
    }
    else if(asset.customFilter.builtInType == RDBuiltIn_pencilColor)
    {
        if(!asset.customFilter.vert || !asset.customFilter.frag)
        {
            asset.customFilter.vert = kRDCustomFilterPencilVertexShader;
            asset.customFilter.frag = kRDCustomFilterPencilFragmentShader;
            
            RDTextureParams *textureParams = [[RDTextureParams alloc] init];
            textureParams.name = @"TexturePencilResource";
            textureParams.type = RDSample2DBufferTexture;
            textureParams.path = @"pencil8S.png";
            NSError* error = [asset.customFilter setShaderTextureParams:textureParams];
            if(error)
                NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
            
            NSMutableArray<RDShaderParams*> *paramsPencilPaintType = [[NSMutableArray alloc] init];
            RDShaderParams *PencilPaintType = [[RDShaderParams alloc] init];
            PencilPaintType.type = UNIFORM_INT;
            PencilPaintType.iValue = 1;
            [paramsPencilPaintType addObject:PencilPaintType];
            error = [asset.customFilter setShaderUniformParams:paramsPencilPaintType isRepeat:NO forUniform:@"PencilPaintType"];
            if(error)
                error = error;
        }
    }
    else if(asset.customFilter.builtInType == RDBuiltIn_pencilLightWater)
    {
        if(!asset.customFilter.vert || !asset.customFilter.frag)
        {
            asset.customFilter.vert = kRDCustomFilterPencilVertexShader;
            asset.customFilter.frag = kRDCustomFilterPencilFragmentShader;
            
            RDTextureParams *textureParams = [[RDTextureParams alloc] init];
            textureParams.name = @"TexturePencilResource";
            textureParams.type = RDSample2DBufferTexture;
            textureParams.path = @"pencil8S.png";
            NSError* error = [asset.customFilter setShaderTextureParams:textureParams];
            if(error)
                NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
            
            NSMutableArray<RDShaderParams*> *paramsPencilPaintType = [[NSMutableArray alloc] init];
            RDShaderParams *PencilPaintType = [[RDShaderParams alloc] init];
            PencilPaintType.type = UNIFORM_INT;
            PencilPaintType.iValue = 2;
            [paramsPencilPaintType addObject:PencilPaintType];
            error = [asset.customFilter setShaderUniformParams:paramsPencilPaintType isRepeat:NO forUniform:@"PencilPaintType"];
            if(error)
                error = error;
        }
    }
    else if(asset.customFilter.builtInType == RDBuiltIn_pencilCharcoalSketches)
    {
        if(!asset.customFilter.vert || !asset.customFilter.frag)
        {
            asset.customFilter.vert = kRDCustomFilterPencilVertexShader;
            asset.customFilter.frag = kRDCustomFilterPencilFragmentShader;
            
            RDTextureParams *textureParams = [[RDTextureParams alloc] init];
            textureParams.name = @"TexturePencilResource";
            textureParams.type = RDSample2DBufferTexture;
            textureParams.path = @"pencil8S.png";
            NSError* error = [asset.customFilter setShaderTextureParams:textureParams];
            if(error)
                NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
            
            NSMutableArray<RDShaderParams*> *paramsPencilPaintType = [[NSMutableArray alloc] init];
            RDShaderParams *PencilPaintType = [[RDShaderParams alloc] init];
            PencilPaintType.type = UNIFORM_INT;
            PencilPaintType.iValue = 3;
            [paramsPencilPaintType addObject:PencilPaintType];
            error = [asset.customFilter setShaderUniformParams:paramsPencilPaintType isRepeat:NO forUniform:@"PencilPaintType"];
            if(error)
                error = error;
        }
        
    }
    else if(asset.customFilter.builtInType == RDBuiltIn_pencilCrayon)
    {
        if(!asset.customFilter.vert || !asset.customFilter.frag)
        {
            asset.customFilter.vert = kRDCustomFilterPencilVertexShader;
            asset.customFilter.frag = kRDCustomFilterPencilFragmentShader;
            
            RDTextureParams *textureParams = [[RDTextureParams alloc] init];
            textureParams.name = @"TexturePencilResource";
            textureParams.type = RDSample2DBufferTexture;
            textureParams.path = @"pencil8S.png";
            NSError* error = [asset.customFilter setShaderTextureParams:textureParams];
            if(error)
                NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
            
            NSMutableArray<RDShaderParams*> *paramsPencilPaintType = [[NSMutableArray alloc] init];
            RDShaderParams *PencilPaintType = [[RDShaderParams alloc] init];
            PencilPaintType.type = UNIFORM_INT;
            PencilPaintType.iValue = 4;
            [paramsPencilPaintType addObject:PencilPaintType];
            error = [asset.customFilter setShaderUniformParams:paramsPencilPaintType isRepeat:NO forUniform:@"PencilPaintType"];
            if(error)
                error = error;
        }
        
    }
    else if(asset.customFilter.builtInType == RDBuiltIn_grayCrosspoint)
    {
        if(!asset.customFilter.vert || !asset.customFilter.frag)
        {
            asset.customFilter.vert = kRDCustomFilterCrossPointVertexShader;
            asset.customFilter.frag = kRDCustomFilterCrossPointFragmentShader;
            
            RDTextureParams *textureParams = [[RDTextureParams alloc] init];
            textureParams.name = @"TextureRadiationResource";
            textureParams.type = RDSample2DBufferTexture;
            textureParams.path = @"CrossPointLine.jpg";
            NSError* error = [asset.customFilter setShaderTextureParams:textureParams];
            if(error)
                NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
            
            NSMutableArray<RDShaderParams*> *paramsCrossPointType = [[NSMutableArray alloc] init];
            RDShaderParams *CrossPointType = [[RDShaderParams alloc] init];
            CrossPointType.type = UNIFORM_INT;
            CrossPointType.iValue = 0;
            [paramsCrossPointType addObject:CrossPointType];
            error = [asset.customFilter setShaderUniformParams:paramsCrossPointType isRepeat:NO forUniform:@"CrossPointType"];
            if(error)
                NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
        }
        
    }
    else if(asset.customFilter.builtInType == RDBuiltIn_colorCrosspoint)
    {
        if(!asset.customFilter.vert || !asset.customFilter.frag)
        {
            asset.customFilter.vert = kRDCustomFilterCrossPointVertexShader;
            asset.customFilter.frag = kRDCustomFilterCrossPointFragmentShader;
            
            RDTextureParams *textureParams = [[RDTextureParams alloc] init];
            textureParams.name = @"TextureRadiationResource";
            textureParams.type = RDSample2DBufferTexture;
            textureParams.path = @"CrossPointLine.jpg";
            NSError* error = [asset.customFilter setShaderTextureParams:textureParams];
            if(error)
                NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
            
            NSMutableArray<RDShaderParams*> *paramsCrossPointType = [[NSMutableArray alloc] init];
            RDShaderParams *CrossPointType = [[RDShaderParams alloc] init];
            CrossPointType.type = UNIFORM_INT;
            CrossPointType.iValue = 1;
            [paramsCrossPointType addObject:CrossPointType];
            error = [asset.customFilter setShaderUniformParams:paramsCrossPointType isRepeat:NO forUniform:@"CrossPointType"];
            if(error)
                NSLog(@"CustomFilterRender failed:%@", [error localizedDescription]);
        }
        
    }
    
    SHADER_TEXTURE_SAMPLER2D_LIST* pTextureList = [asset.customFilter pTextureSamplerList];
    
    if( pTextureList && pTextureList->type == RDSample2DBufferTexture)
    {
        //添加素材
        if(pTextureList->path.length == 0)
            NSLog(@"error : texture url is null!");
        else
        {
            if (!pTextureList->texture)
            {
                pTextureList->texture = [self textureFromUIImage:[UIImage imageWithContentsOfFile:pTextureList->path]];//OK
                //                pTextureList->texture = [self textureFromUIImage:[UIImage imageNamed:pTextureList->path]];//ERROR
                glActiveTexture(GL_TEXTURE1);
                glBindTexture(GL_TEXTURE_2D, pTextureList->texture);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                if( RDTextureWarpModeRepeat == pTextureList->warpMode)
                {
                    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
                    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
                }
                else
                {
                    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                }
            }
        }
    }

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D,renderFbo->texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    [asset.customFilter renderTexture:renderFbo->texture FrameWidth:width FrameHeight:height RotateAngle:0.0 Time:time];

    
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    if (asset.customFilter.builtInType == RDBuiltIn_illusion) {
        
        //仅仅只保存当前纹理作为下一帧备用
        struct GLTextureList* pLast = nullptr;
        if (!pLastTextureList) {
            pLastTextureList = (struct GLTextureList*)malloc(sizeof(struct GLTextureList));
            memset(pLastTextureList, 0, sizeof(struct GLTextureList));
            pLast = pLastTextureList;
        }
        else
        {
            struct GLTextureList* p = pLastTextureList;
            while (p) {
                if (p->index == index) {
                    break;
                }
                p = p->next;
            }
            if (!p) {
                p = pLastTextureList;
                while (p && p->next)
                    p = p->next;
                p->next = (struct GLTextureList*)malloc(sizeof(struct GLTextureList));
                memset(p->next, 0, sizeof(struct GLTextureList));
                pLast = p->next;
            }
            else
                pLast = p;
        }
        pLast->index = index;
        pLast->width = pNode->width;
        pLast->height = pNode->height;
        pLast->texture = pNode->texture;;
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    return 1;
}


- (UIImage *)scaleImageWithData:(NSData *)data withSize:(CGSize)size
                          scale:(CGFloat)scale
                    orientation:(UIImageOrientation)orientation {
    
    CGFloat maxPixelSize = MAX(size.width, size.height);
    CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)data, nil);
    NSDictionary *options = @{(__bridge id)kCGImageSourceCreateThumbnailFromImageAlways:(__bridge id)kCFBooleanTrue,
                              (__bridge id)kCGImageSourceThumbnailMaxPixelSize:[NSNumber numberWithFloat:maxPixelSize]
                              };
    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(sourceRef, 0, (__bridge CFDictionaryRef)options);
    UIImage *resultImage = [UIImage imageWithCGImage:imageRef scale:scale orientation:orientation];
    CGImageRelease(imageRef);
    CFRelease(sourceRef);
    
    return resultImage;
}

-(UIImage*)pixelBufferToImage:(CVPixelBufferRef) pixelBufffer Width:(int)dstWidth Height:(int)dstHeight
{
    UIImage *scaledImage = nil;
    
    
    
    CVImageBufferRef imageBuffer = pixelBufffer;
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    void * baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    //CVPixelBufferRef to UIImage
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(baseAddress,width,height,8,bytesPerRow,colorSpace,kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    
    //scale
    UIImage* image = [UIImage imageWithCGImage: quartzImage];
    UIGraphicsBeginImageContext(CGSizeMake(dstWidth, dstHeight));
    [image drawInRect:CGRectMake(0, 0, dstWidth, dstHeight)];
    scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    image = nil;
    
    //        NSData *imageData = UIImageJPEGRepresentation(image,1.0f);
    //        scaledImage = [self scaleImageWithData:imageData withSize:CGSizeMake(dstWidth , dstHeight) scale:1.0 orientation:UIImageOrientationUp];
    
    CGImageRelease(quartzImage);
    
    return scaledImage;
}
-(void )renderTotexture:(GLuint)texture StartValue:(float)startValue EndValue:(float)endValue
           TextureWidth:(float)width TextureHeight:(int)height
{
    GLfloat vertices[8]  = {
        
        -1.0,1.0,
        1.0,1.0,
        -1.0,-1.0,
        1.0,-1.0,
    };
    
    GLfloat textureCoordinates[8]  = {
        0.0,1.0,
        1.0,1.0,
        0.0,0.0,
        1.0,0.0,
    };
    
    glUseProgram(self.blurProgram);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);//
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glUniform1i(blurInputTextureUniform, 2);

    
    RDMatrixLoadIdentity(&_modelViewMatrix);
    glUniformMatrix4fv(normalTransformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
    
    RDMatrixLoadIdentity(&_projectionMatrix);
    glUniformMatrix4fv(normalProjectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
    
    glUniform1f(blurStartValueUniform,(float)startValue);
    glUniform1f(blurEndValueUniform,(float)endValue);


    glUniform1f(blurImageHeightUniform, height);
    glUniform1f(blurImageWidthUniform, width);
    
    glUniform2f(blurDirectionUniform, startValue, endValue);
    glUniform2f(blurResolutionUniform, (float)width, (float)height);
    
    //设置模糊区域坐标
    glUniform2f(blurPointTLUniform, 0.0, 0.0);
    glUniform2f(blurPointTRUniform, 1.0, 0.0);
    glUniform2f(blurPointBLUniform, 0.0, 1.0);
    glUniform2f(blurPointBRUniform, 1.0, 1.0);

    glVertexAttribPointer(blurPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glEnableVertexAttribArray(blurPositionAttribute);
    glVertexAttribPointer(blurTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    glEnableVertexAttribArray(blurTextureCoordinateAttribute);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    glDisableVertexAttribArray(blurPositionAttribute);
    glDisableVertexAttribArray(blurTextureCoordinateAttribute);

    

}
- (void)processAssetBlurAttributeScence:(RDScene *)scene Asset:(VVAsset* )asset request:(AVAsynchronousVideoCompositionRequest *)request Index:(int)index
{
    
    float intensity = asset.blurIntensity;
    
    //减少内存暂用和绘制耗时
    int dstTextureWidth = _videoSize.width/5.0;
    int dstTextureHeight = _videoSize.height/5.0;
    int result_statu = 0;
    
    if(dstTextureWidth %2 != 0)
        dstTextureWidth += 1;
    if(dstTextureHeight %2 != 0)
        dstTextureHeight += 1;
    

//    遍历找到对应的fbo
    struct BlurFBOList* pFboList = NULL;
    if (!pBlurFboList) {
        pBlurFboList = (struct BlurFBOList*)malloc(sizeof(BlurFBOList));
        if(!pBlurFboList)
        {
            NSLog(@"blurList malloc fail!!");
            return;
        }
        memset(pBlurFboList, 0, sizeof(BlurFBOList));
        pBlurFboList->index = index;
        pFboList = pBlurFboList;
    }
    else
    {
        bool hasBlurNode = false;
        struct BlurFBOList* pList = pBlurFboList;

        while (pList)
        {
            if(pList->index == index)
            {
                hasBlurNode = true;
                pFboList = pList ;
                break;
            }
            pList = pList->next;
        }
        if(!hasBlurNode)
        {
            pList = pBlurFboList;
            while (pList && pList->next)
                pList = pList->next;


            pList->next = (struct BlurFBOList*)malloc(sizeof(BlurFBOList));
            if(!pList->next)
            {
                NSLog(@"blurList malloc fail!!");
                return;
            }
            memset(pList->next, 0, sizeof(BlurFBOList));
            pList->next->index = index;
            pFboList = pList->next;
        }
    }

    if (pFboList->height != dstTextureHeight || pFboList->width != dstTextureWidth) {

        unsigned char* pImage = (unsigned char*)malloc(dstTextureWidth*dstTextureHeight*4);
        for (int i = 0; i<dstTextureWidth*dstTextureHeight; i++) {

            pImage[i*4] = 0xFF;
            pImage[i*4+1] = 0xFF;
            pImage[i*4+2] = 0xFF;
            pImage[i*4+3] = 0xFF;
        }

        if(pFboList->vTexture)
            glDeleteTextures(1, &pFboList->vTexture);
        pFboList->vTexture = [self textureFromBufferObject:pImage Width:dstTextureWidth Height:dstTextureHeight];

        if(pFboList->hTexture)
            glDeleteTextures(1, &pFboList->hTexture);


        pFboList->hTexture = [self textureFromBufferObject:pImage Width:dstTextureWidth Height:dstTextureHeight];

        pFboList->width = dstTextureWidth;
        pFboList->height = dstTextureHeight;
        free(pImage);
    }
    
//    1.绘制媒体到FBO
    if(!pFboList->vFbo)
    glGenFramebuffers(1, &pFboList->vFbo);
    
    
    glBindFramebuffer(GL_FRAMEBUFFER, pFboList->vFbo);
    glViewport(0, 0, dstTextureWidth, dstTextureHeight);
    
    
    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, pFboList->vTexture, 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
    
    glUseProgram(self.program);

    //开启blend
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //如果有设置场景背景图片或者视频
    if(scene.backgroundAsset)
    {
        scene.backgroundAsset.blurIntensity = 0;
        [self renderAsset:scene.backgroundAsset AssetIndex:-1 TimeRange:scene.fixedTimeRange request:request Statu:&result_statu];
    }
        
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    if(sourceAssetTexture)
    {
        glBindTexture(CVOpenGLESTextureGetTarget(sourceAssetTexture), 0);
        CFRelease(sourceAssetTexture);
        sourceAssetTexture = 0;
    }
    scene.backgroundAsset.blurIntensity = intensity;
    
   
//    2.绘制模糊
    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    
    //模糊叠加次数
    float blurValue = intensity*3.0;
    int count = MAX_NUMBER;//(((int)(MAX_NUMBER*intensity)) == 0)?1:(MAX_NUMBER*intensity);
    if(count%2 != 0)
        count += 1;
    for (int i = 1; i<=count; i++) {
        if (i%2 == 0) {

            if(!pFboList->vFbo)
                glGenFramebuffers(1, &pFboList->vFbo);


            glBindFramebuffer(GL_FRAMEBUFFER, pFboList->vFbo);
            glViewport(0, 0, dstTextureWidth, dstTextureHeight);


            // Attach the destination texture as a color attachment to the off screen frame buffer
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, pFboList->vTexture, 0);

            if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
                NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
            }

            [self renderTotexture:pFboList->hTexture StartValue:blurValue EndValue:0 TextureWidth:pFboList->width TextureHeight:pFboList->height];

            glBindFramebuffer(GL_FRAMEBUFFER, 0);
        }
        else
        {

            if(!pFboList->hFbo)
                glGenFramebuffers(1, &pFboList->hFbo);

            glBindFramebuffer(GL_FRAMEBUFFER, pFboList->hFbo);
            glViewport(0, 0, dstTextureWidth, dstTextureHeight);

            // Attach the destination texture as a color attachment to the off screen frame buffer
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, pFboList->hTexture, 0);

            if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
                NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
            }

            [self renderTotexture:pFboList->vTexture StartValue:0 EndValue:blurValue TextureWidth:pFboList->width TextureHeight:pFboList->height];
            glBindFramebuffer(GL_FRAMEBUFFER, 0);
        }
    }
//    NSLog(@"blur time :%g", CFAbsoluteTimeGetCurrent() - start);
}

- (int)processAssetBeautifulAttribute:(VVAsset* )asset TimeRange:(CMTimeRange)timeRange request:(AVAsynchronousVideoCompositionRequest *)request Index:(int)index
{
    
    
    RDImage* imageBuffer = NULL;
    CVPixelBufferRef pPixelBuffer = NULL;
    float width  = 0;
    float height = 0;
  
    CVOpenGLESTextureRef sourceTexture = 0;
    GLuint texture = 0;
    BOOL isResizePixelBuffer = NO;
    TextureFBOList* pList = pBeautyFboList;
    TextureFBOList* pNode = nil;
    
    if(asset.beautyBrightIntensity == 0.0 && asset.beautyToneIntensity == 0.0 && asset.beautyBlurIntensity == 0.0)
        return 1;

    if(asset.blendType == RDBlendAIChromaColor || asset.blendType == RDBlendChromaColor)
    {
        TextureFBOList* p = pCollageFboList;
        while (p)
        {
            if(p->index == index)
                break;
            p = p->next;
        }
        if(!p)
            return 0;
        
        width = p->width;
        height = p->height;
        texture = p->texture;
    }
    else
    {
        //媒体没有自定义滤镜，需解码
        if (asset.type == RDAssetTypeImage)//图片
        {
            float tweenFactor = 0;
            float currentTime = 0;
            
            if(index >= COLLAGE_ASSEST_INDEX)
            {
                float startTime = CMTimeGetSeconds(timeRange.start);
                float endTime = startTime + CMTimeGetSeconds(timeRange.duration);
                tweenFactor = (displayTime - startTime)/(endTime-startTime); //用于图片缩放
                if(tweenFactor < 0)
                    tweenFactor = 0;
                currentTime = displayTime;
            }
            else
            {
                
                tweenFactor = factorForTimeInRange(request.compositionTime, timeRange);
                currentTime =  tweenFactor * CMTimeGetSeconds(timeRange.duration) - 1/_fps;
            }
            
            currentTime = currentTime < 0 ? 0:currentTime;
            
            imageBuffer = [self fetchImageFrameBuffer:asset.url];
            [imageBuffer setCurrentTime:(currentTime - CMTimeGetSeconds(asset.startTimeInScene))*asset.speed + CMTimeGetSeconds(asset.timeRange.start)];
            
            width = imageBuffer.width;
            height = imageBuffer.height;
            texture = imageBuffer.texture;
        }
        else
        {
            //视频
            pPixelBuffer = [request sourceFrameByTrackID:[asset.trackID intValue]];
            if (!pPixelBuffer) {
                NSLog(@"processAssetBlurAttribute :has no buffer!!!!!!!! :【 %d 】 time:%f",index,CMTimeGetSeconds(request.compositionTime));
                //                    _mvPixelBuffer = NULL;
                return 0;
            }
            
            width  = CVPixelBufferGetWidth(pPixelBuffer);
            height = CVPixelBufferGetHeight(pPixelBuffer);
            pPixelBuffer = [self resizePixelBuffer:pPixelBuffer context:context isExporting:((RDVideoCompositorInstruction *)request.videoCompositionInstruction).isExporting];
            CGSize sourceSize_new = CGSizeMake(CVPixelBufferGetWidth(pPixelBuffer), CVPixelBufferGetHeight(pPixelBuffer));
            if (!CGSizeEqualToSize(CGSizeMake(width, height), sourceSize_new)) {
                isResizePixelBuffer = YES;
                width = sourceSize_new.width;
                height = sourceSize_new.height;
            }
            sourceTexture = [self customTextureForPixelBuffer:pPixelBuffer];
            texture = CVOpenGLESTextureGetName(sourceTexture);
            //                _mvPixelBuffer = pPixelBuffer;
            
        }
    }
    
    while (pList) {
        if(pList->index == index)
        {
            pNode = pList;
            break;
        }
        pList = pList->next;
    }
    
    if(!pNode)
    {
        if(!pBeautyFboList)
        {
            pBeautyFboList = (TextureFBOList*)malloc(sizeof(TextureFBOList));
            memset(pBeautyFboList, 0, sizeof(TextureFBOList));
            pNode = pBeautyFboList;
        }
        else
        {
            pList = pBeautyFboList;
            while (pList && pList->next)
                pList = pList->next;
            pList->next = (TextureFBOList*)malloc(sizeof(TextureFBOList));
            memset(pList->next, 0, sizeof(TextureFBOList));
            pNode = pList->next;
        }
        pNode->index = index;
        
    }
    
    if(((int)width)%2!=0)
        width = (int)(width+1);
    if(((int)height)%2!=0)
        height = (int)(height+1);
    
    if (pNode->height != height || pNode->width != width)
        [self initFrameBuffobject:pNode DstWidth:width DstHeight:height];

    if(!pNode->fbo)
        glGenFramebuffers(1, &pNode->fbo);
    
    glBindFramebuffer(GL_FRAMEBUFFER, pNode->fbo);
    glViewport(0, 0, width, height);
    
    
    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, pNode->texture, 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    

    GLfloat vertices[8]  = {
        
        -1.0,-1.0,
        1.0,-1.0,
        -1.0,1.0,
        1.0,1.0,
    };
    
    GLfloat textureCoordinates[8]  = {
        0.0,0.0,
        1.0,0.0,
        0.0,1.0,
        1.0,1.0,
    };
    
    glUseProgram(self.beautyProgram);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glUniform1i(beautyInputTextureUniform, 0);
    glUniform4f(beautyParamsUniform, asset.beautyBlurIntensity, 1.0f - 0.3f* asset.beautyBrightIntensity, 0.1f + 0.3f* asset.beautyToneIntensity, 1.0);
    glUniform2f(beautySingleStepOffsetUniform, 1.0/(float)width, 1.0/(float)height);
    
    
    glVertexAttribPointer(beautyPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glEnableVertexAttribArray(beautyPositionAttribute);
    glVertexAttribPointer(beautyTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    glEnableVertexAttribArray(beautyTextureCoordinateAttribute);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDisableVertexAttribArray(beautyPositionAttribute);
    glDisableVertexAttribArray(beautyTextureCoordinateAttribute);

    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    if(sourceTexture)
    {
        glBindTexture(CVOpenGLESTextureGetTarget(sourceTexture), 0);
        CFRelease(sourceTexture);
    }
    if (isResizePixelBuffer && pPixelBuffer) {
        CVPixelBufferRelease(pPixelBuffer);
    }

    return 1;
}

- (int)processAssetBorderBlurAttribute:(VVAsset* )asset scene:(RDScene *)scene request:(AVAsynchronousVideoCompositionRequest *)request Index:(int)index
{
    
    
    RDImage* imageBuffer = NULL;
    CVPixelBufferRef pPixelBuffer = NULL;
    float width  = 0;
    float height = 0;
    float videoOriginRotateAngle = 0.0;
    CVOpenGLESTextureRef sourceTexture = 0;
    GLuint texture = 0;
    
    float dstTextureWidth = 0;
    float dstTextureHeight = 0;
    BOOL isResizePixelBuffer = NO;
    
    
    if (asset.beautyBrightIntensity != 0.0 || asset.beautyToneIntensity != 0.0 || asset.beautyBlurIntensity != 0.0 )
    {
        //如果媒体设置了美颜，说明已经解码完成
        TextureFBOList *pList = pBeautyFboList;
        while (pList) {
            if(pList->index == index)
                break;
            pList = pList->next;
        }
        if(!pList)
            return 0;
        width = pList->width;
        height = pList->height;
        texture = pList->texture;
        if (asset.type == RDAssetTypeImage)//图片
            videoOriginRotateAngle = 0;
        else
            videoOriginRotateAngle = [self getOriginRotateAngleFromAsset:asset];
    }
    else
    {
        //媒体解码
        if (asset.type == RDAssetTypeImage)//图片
        {
            float tweenFactor = factorForTimeInRange(request.compositionTime, scene.fixedTimeRange);
            float currentTime =  tweenFactor * CMTimeGetSeconds(scene.fixedTimeRange.duration) - 1/_fps;
            if (currentTime < 0) {
                currentTime = 0.0;
            }
            imageBuffer = [self fetchImageFrameBuffer:asset.url];
            width = imageBuffer.width;
            height = imageBuffer.height;
            texture = imageBuffer.texture;
            videoOriginRotateAngle = 0;
            [imageBuffer setCurrentTime:(currentTime - CMTimeGetSeconds(asset.startTimeInScene))*asset.speed + CMTimeGetSeconds(asset.timeRange.start)];
        }
        else
        {
            //视频
            pPixelBuffer = [request sourceFrameByTrackID:[asset.trackID intValue]];
            if (!pPixelBuffer) {
                NSLog(@"processAssetBlurAttribute :has no buffer!!!!!!!! :【 %d 】 time:%f",index,CMTimeGetSeconds(request.compositionTime));
                //                    _mvPixelBuffer = NULL;
                return 0;
            }
            
            width  = CVPixelBufferGetWidth(pPixelBuffer);
            height = CVPixelBufferGetHeight(pPixelBuffer);
            pPixelBuffer = [self resizePixelBuffer:pPixelBuffer context:context isExporting:((RDVideoCompositorInstruction *)request.videoCompositionInstruction).isExporting];
            CGSize sourceSize_new = CGSizeMake(CVPixelBufferGetWidth(pPixelBuffer), CVPixelBufferGetHeight(pPixelBuffer));
            if (!CGSizeEqualToSize(CGSizeMake(width, height), sourceSize_new)) {
                isResizePixelBuffer = YES;
                width = sourceSize_new.width;
                height = sourceSize_new.height;
            }
            sourceTexture = [self customTextureForPixelBuffer:pPixelBuffer];
            texture = CVOpenGLESTextureGetName(sourceTexture);
            //                _mvPixelBuffer = pPixelBuffer;
            videoOriginRotateAngle = [self getOriginRotateAngleFromAsset:asset];
            
        }
    }
    
    if(((int)width)%2!=0)
        width = (int)(width+1);
    if(((int)height)%2!=0)
        height = (int)(height+1);
    
    dstTextureWidth = _videoSize.width;
    dstTextureHeight = _videoSize.height;
    
    
    struct BlurFBOList* pFboList = NULL;
    if (!pBlurFboList) {
        pBlurFboList = (struct BlurFBOList*)malloc(sizeof(BlurFBOList));
        if(!pBlurFboList)
        {
            NSLog(@"blurList malloc fail!!");
            return 0;
        }
        memset(pBlurFboList, 0, sizeof(BlurFBOList));
        pBlurFboList->index = index;
        pFboList = pBlurFboList;
    }
    else
    {
        struct BlurFBOList* pList = pBlurFboList;
        
        while (pList)
        {
            if(pList->index == index)
            {
                pFboList = pList ;
                break;
            }
            pList = pList->next;
        }
        if(!pList)
        {
            pList = pBlurFboList;
            while (pList && pList->next)
                pList = pList->next;
            
            
            pList->next = (struct BlurFBOList*)malloc(sizeof(BlurFBOList));
            if(!pList->next)
            {
                NSLog(@"blurList malloc fail!!");
                return 0;
            }
            memset(pList->next, 0, sizeof(BlurFBOList));
            pList->next->index = index;
            pFboList = pList->next;
        }
    }
    
    if (pFboList->height != dstTextureHeight || pFboList->width != dstTextureWidth) {
        
        unsigned char* pImage = (unsigned char*)malloc(dstTextureWidth*dstTextureHeight*4);
        for (int i = 0; i<dstTextureWidth*dstTextureHeight; i++) {
            
            pImage[i*4] = 0xFF;
            pImage[i*4+1] = 0xFF;
            pImage[i*4+2] = 0xFF;
            pImage[i*4+3] = 0xFF;
        }
        
        if(pFboList->hTexture)
            glDeleteTextures(1, &pFboList->hTexture);
        pFboList->hTexture = [self textureFromBufferObject:pImage Width:dstTextureWidth Height:dstTextureHeight];
        
        if(pFboList->vTexture)
            glDeleteTextures(1, &pFboList->vTexture);
        pFboList->vTexture = [self textureFromBufferObject:pImage Width:dstTextureWidth Height:dstTextureHeight];
        
        pFboList->width = dstTextureWidth;
        pFboList->height = dstTextureHeight;
        free(pImage);
    }
    
    //        if(!pFboList->hFbo)
    //            glGenFramebuffers(1, &pFboList->hFbo);
    //
    //
    //        glBindFramebuffer(GL_FRAMEBUFFER, pFboList->hFbo);
    //        glViewport(0, 0, dstTextureWidth, dstTextureHeight);
    //
    //
    //        // Attach the destination texture as a color attachment to the off screen frame buffer
    //        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, pFboList->hTexture, 0);
    //
    //        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
    //            NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    //        }
    //
    //
    //        [self renderTotextur:texture TextureWidth:width TextureHeight:height IsFirst:0 Asset:asset];
    
    
    for (int i = 0; i<=1; i++) {
        if (i == 0) {
            
            if(!pFboList->vFbo)
                glGenFramebuffers(1, &pFboList->vFbo);
            
            
            glBindFramebuffer(GL_FRAMEBUFFER, pFboList->vFbo);
            glViewport(0, 0, dstTextureWidth, dstTextureHeight);
            
            
            // Attach the destination texture as a color attachment to the off screen frame buffer
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, pFboList->vTexture, 0);
            
            if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
                NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
            }
            
            GLfloat quadTextureData[8]  = {
                0.0,1.0,
                1.0,1.0,
                0.0,0.0,
                1.0,0.0,
                
            };
            if(asset.isHorizontalMirror && asset.isVerticalMirror)
            {
                // 左右镜像 + 垂直镜像
                quadTextureData[0] = 1.0;
                quadTextureData[1] = 0.0;
                quadTextureData[2] = 0.0;
                quadTextureData[3] = 0.0;
                quadTextureData[4] = 1.0;
                quadTextureData[5] = 1.0;
                quadTextureData[6] = 0.0;
                quadTextureData[7] = 1.0;
            }
            if(asset.isHorizontalMirror && !asset.isVerticalMirror)
            {
                // 左右镜像
                if(asset.rotate + videoOriginRotateAngle == 90 || asset.rotate + videoOriginRotateAngle == -90.0 ||
                   asset.rotate + videoOriginRotateAngle == 270.0 || asset.rotate + videoOriginRotateAngle == -270.0 )
                {
                    quadTextureData[0] = 0.0;
                    quadTextureData[1] = 0.0;
                    quadTextureData[2] = 1.0;
                    quadTextureData[3] = 0.0;
                    quadTextureData[4] = 0.0;
                    quadTextureData[5] = 1.0;
                    quadTextureData[6] = 1.0;
                    quadTextureData[7] = 1.0;
                }
                else{
                    quadTextureData[0] = 1.0;
                    quadTextureData[1] = 1.0;
                    quadTextureData[2] = 0.0;
                    quadTextureData[3] = 1.0;
                    quadTextureData[4] = 1.0;
                    quadTextureData[5] = 0.0;
                    quadTextureData[6] = 0.0;
                    quadTextureData[7] = 0.0;
                }
                
            }
            if(!asset.isHorizontalMirror && asset.isVerticalMirror)
            {
                // 垂直镜像
                if(asset.rotate + videoOriginRotateAngle == 90 || asset.rotate + videoOriginRotateAngle == -90.0 ||
                   asset.rotate + videoOriginRotateAngle == 270.0 || asset.rotate + videoOriginRotateAngle == -270.0 )
                {
                    quadTextureData[0] = 1.0;
                    quadTextureData[1] = 1.0;
                    quadTextureData[2] = 0.0;
                    quadTextureData[3] = 1.0;
                    quadTextureData[4] = 1.0;
                    quadTextureData[5] = 0.0;
                    quadTextureData[6] = 0.0;
                    quadTextureData[7] = 0.0;
                }
                else{
                    quadTextureData[0] = 0.0;
                    quadTextureData[1] = 0.0;
                    quadTextureData[2] = 1.0;
                    quadTextureData[3] = 0.0;
                    quadTextureData[4] = 0.0;
                    quadTextureData[5] = 1.0;
                    quadTextureData[6] = 1.0;
                    quadTextureData[7] = 1.0;
                }
                
            }
            
            
            CGRect crop = [self getAssetCrop:asset];
            [self renderGaussBlurTotexture:texture TextureWidth:width TextureHeight:height IsFirst:1 OriginRotateAngle:videoOriginRotateAngle UserRotateAngle:asset.rotate Crop:crop TextureCoordinates:quadTextureData];
            
            
            glBindFramebuffer(GL_FRAMEBUFFER, 0);
            
        }
        else
        {
            
            if(!pFboList->hFbo)
                glGenFramebuffers(1, &pFboList->hFbo);
            
            
            glBindFramebuffer(GL_FRAMEBUFFER, pFboList->hFbo);
            glViewport(0, 0, dstTextureWidth, dstTextureHeight);
            
            
            // Attach the destination texture as a color attachment to the off screen frame buffer
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, pFboList->hTexture, 0);
            
            if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
                NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
            }
            
            const GLfloat quadTextureData[8]  = {
                0.0,1.0,
                1.0,1.0,
                0.0,0.0,
                1.0,0.0,
                
            };
            CGRect crop = [self getAssetCrop:asset];
            [self renderGaussBlurTotexture:pFboList->vTexture TextureWidth:width TextureHeight:height IsFirst:0.0 OriginRotateAngle:videoOriginRotateAngle UserRotateAngle:asset.rotate Crop:crop TextureCoordinates:quadTextureData];
            
            glBindFramebuffer(GL_FRAMEBUFFER, 0);
        }
    }
    
    
    if(sourceTexture)
    {
        glBindTexture(CVOpenGLESTextureGetTarget(sourceTexture), 0);
        CFRelease(sourceTexture);
    }
    if (isResizePixelBuffer && pPixelBuffer) {
        CVPixelBufferRelease(pPixelBuffer);
    }

    return 1;
}


// 获取当前设备可用内存(单位：MB）
- (double)availableMemory {
    vm_statistics_data_t vmStats;
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    kern_return_t kernReturn = host_statistics(mach_host_self(),
                                               HOST_VM_INFO,
                                               (host_info_t)&vmStats,
                                               &infoCount);
    
    if (kernReturn != KERN_SUCCESS) {
        return NSNotFound;
    }
    
    //    NSLog(@"free:%lu\nactive:%u\ninactive:%u\nwire:%u\nzerofill:%u\nreactivations:%u\npageins:%u\npageouts:%u\nfaults:%u\ncow_faults:%u\nlookups:%u\nhits:%u",vmStats.free_count*vm_page_size,vmStats.active_count*vm_page_size,vmStats.inactive_count*vm_page_size,vmStats.wire_count*vm_page_size,vmStats.zero_fill_count*vm_page_size,vmStats.reactivations*vm_page_size,vmStats.pageins*vm_page_size,vmStats.pageouts*vm_page_size,vmStats.faults,vmStats.cow_faults,vmStats.lookups,vmStats.hits);
    
    //    double size = ((vm_page_size * vmStats.free_count + vm_page_size * vmStats.inactive_count));
    double inactive = ((vm_page_size *vmStats.inactive_count) / 1024.0) / 1024.0;
    double free = ((vm_page_size *vmStats.free_count) / 1024.0) / 1024.0;
    double freeAll =  ((vm_page_size * vmStats.free_count + vm_page_size * vmStats.inactive_count))/1024/1024;
    NSLog(@"inactive:%f free:%f freeAll:%f", inactive, free, freeAll);
    
    return inactive;
    //    return ((vm_page_size *vmStats.free_count) / 1024.0) / 1024.0;
}

//20190128 wuxiaoxia 1080P视频为减少内存占用，在低配设备上改变buffer的大小
- (BOOL)isNeedResizeBuffer {
    //    double availableMemory = [self availableMemory];
    //    NSLog(@"availableMemory:%f", availableMemory);
    NSString* machine = [RDRecordHelper system];
    BOOL lowDevice = NO;
    if ([machine hasPrefix:@"iPhone"]) {
        NSComparisonResult result = [machine compare:@"iPhone8" options:NSCaseInsensitiveSearch];
        if (result == NSOrderedDescending) {
            lowDevice = YES;
        }
    }
    //    if (lowDevice || availableMemory < 400) {
    //        return YES;
    //    }
    if (lowDevice) {
        return YES;
    }
    return NO;
}

- (CVPixelBufferRef)resizePixelBuffer:(CVPixelBufferRef)pixelBuffer context:(CIContext*)context isExporting:(BOOL)isExporting
{
    float maxSize = 1280.0;
    float width = CVPixelBufferGetWidth(pixelBuffer);
    float height = CVPixelBufferGetHeight(pixelBuffer);
    if (MIN(width, height) < maxSize || isExporting) {
        return pixelBuffer;
    }
    //20191205 大分辨率视频预览时，缩小分辨率，以减少内存
    CGSize size = CGSizeMake(width, height);
    if (width > height) {
        width = maxSize;
        height = width / (size.width / size.height);
    }else {
        height = maxSize;
        width = height * (size.width / size.height);
    }
    CVPixelBufferRef resizedPixelBuffer = NULL;
    NSDictionary *pixelAttributes = [NSDictionary dictionaryWithObject:@{} forKey:(NSString *)kCVPixelBufferIOSurfacePropertiesKey];
    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                          width,
                                          height,
                                          kCVPixelFormatType_32BGRA,
                                          (__bridge CFDictionaryRef)pixelAttributes,
                                          &resizedPixelBuffer);
    if (result == kCVReturnSuccess && resizedPixelBuffer){
        if (!context) {
#if 1
            context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}]; // kCIContextUseSoftwareRenderer 默认YES，设置YES是创建基于GPU的CIContext对象，效率要比CPU高很多。
#else
            context = [CIContext contextWithOptions:nil];//20200106 BSXPCMessage received error for message: Connection interrupted on CIContext with iOS 8
#endif
        }
        @autoreleasepool {
            CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
            CGFloat sx = CGFloat(width) / CGFloat(size.width);
            CGFloat sy = CGFloat(height) / CGFloat(size.height);
            CGAffineTransform scaleTransform = CGAffineTransformMakeScale(sx, sy);
            CIImage *scaledImage = [ciImage imageByApplyingTransform:scaleTransform];
            [context render:scaledImage toCVPixelBuffer:resizedPixelBuffer];
        }
        return resizedPixelBuffer;
    }
    return pixelBuffer;
}

- (float)getFacorFromWidth:(float)width height:(float)height {
    float factor = 1.0;
    if (MIN(width, height) >= MAX_WIDTH && [RDRecordHelper isNeedResizeBufferSize])//720P以上视频在低配设备上播放会卡
    {
        factor = (width >= height)?(MAX_SCALE_SIZE/width):(MAX_SCALE_SIZE/height);//系数不能太小，否则会导致画面质量变差
        if(factor > 1.0)
            factor = 1.0;
        NSLog(@"factor:%f", factor);
    }
    return factor;
}


- (void)renderAsset:(VVAsset* )asset AssetIndex:(int)index TimeRange:(CMTimeRange)timeRange request:(AVAsynchronousVideoCompositionRequest *)request Statu:(int*)result_statu
{
    CGSize destinationSize = _videoSize;
    RDImage* maskImageBuffer = NULL;
    RDImage* lookUpImageBuffer = NULL;
    float tweenFactor = 0;
    float startTime = 0;
    float endTime = 0;
    float currentTime =  0;

    if(index >= COLLAGE_ASSEST_INDEX)
    {
        startTime = CMTimeGetSeconds(timeRange.start);
        endTime = startTime + CMTimeGetSeconds(timeRange.duration);
        tweenFactor = (displayTime - startTime)/(endTime-startTime); //用于图片缩放
        if(tweenFactor < 0)
            tweenFactor = 0;
        currentTime = displayTime;
    }
    else
    {
        tweenFactor = factorForTimeInRange(request.compositionTime, timeRange);
        //20180720 wuxiaoxia 简影示例中，媒体视频使用动画(VVAssetAnimatePosition)，且设置顶点时，当前时间会超前一帧
        currentTime =  tweenFactor * CMTimeGetSeconds(timeRange.duration) - 1/_fps;
    }
    currentTime = currentTime < 0.0 ? 0.0 : currentTime;


    //如果非全屏显示，不管媒体顺时针旋转还是逆时针旋转，保证媒体的旋转角度始终大于等于0，如果设置的旋转角度出现负数，画面会被缩小
//    if(asset.rotate < 0)
//        asset.rotate = 360.0 + asset.rotate;

    
    
    if(asset.maskURL)
        maskImageBuffer = [self fetchImageFrameBuffer:asset.maskURL];
    if (asset.filterType == VVAssetFilterLookup)
        lookUpImageBuffer = [self fetchImageFrameBuffer:asset.filterUrl];
    VVAssetAnimatePosition* fromPosition;
    VVAssetAnimatePosition* toPosition;
    
    BOOL hasAnimate = NO;
    bool isMV = false;
    
    [self setBlendModelWithSrcFactor:asset.srcFactor DstFactor:asset.dstFactor Model:asset.blendModel];
    
    if (asset.animate.count >= 1) {
        for (int j = 0; j<asset.animate.count; j++) {
            
            VVAssetAnimatePosition* _from = asset.animate[j];
            VVAssetAnimatePosition* _to;
            if (j == asset.animate.count - 1) {
                _to = asset.animate[j];
            }else {
                _to = asset.animate[j+1];
            }
            
            //保留三位有效数字，计算精确度
            int nTimeFrom = (int)((_from.atTime + CMTimeGetSeconds(asset.startTimeInScene))*1000) ;
            int nTimeTo = (int)((_to.atTime  + CMTimeGetSeconds(asset.startTimeInScene))*1000) ;
            isMV = (fabs(1000.0/_fps - fabs(nTimeTo - nTimeFrom))<10)?true:false;//是否每帧都有动画
            if (!isMV) {//20180913 wuxiaoxia 不是每帧都有动画的情况不需要减一帧
                currentTime =  tweenFactor * CMTimeGetSeconds(timeRange.duration);
                if (currentTime < 0) {
                    currentTime = 0.0;
                }
            }
            int nCurrent =(int)(currentTime*1000);
            
            if ((isMV && fabs(nCurrent - nTimeFrom)<50) ||(!isMV && nTimeFrom <= nCurrent && nCurrent <= nTimeTo)) {
                //                       NSLog(@"---> i:%d timeFrome:%d timeTo:%d currentTime:%d ",i,nTimeFrom,nTimeTo,nCurrent);
                fromPosition = _from;
                toPosition = _to;
                hasAnimate = YES;
                
                //                        NSLog(@"---> count:%zd i:%d j:%d frome:%f to:%f   fTime:%d tTime:%d cTime:%d ",asset.animate.count,i,j,fromPosition.fillScale,toPosition.fillScale,nTimeFrom,nTimeTo,nCurrent);
                break;
            }
            
        }
    }
    
    if (!fromPosition) {
        fromPosition = [[VVAssetAnimatePosition alloc] init];
    }
    if (!toPosition) {
        toPosition = [[VVAssetAnimatePosition alloc] init];
    }
    
    CGRect crop = [self getAssetCrop:asset];
    if(asset.type == RDAssetTypeVideo
       && currentTime >= CMTimeGetSeconds(asset.startTimeInScene)) {
        
        if (asset.filterType == VVAssetFilterEmpty) {
            glUniform1f(normalTexture2TypeUniform, 0.0);
        }
        
        if (asset.filterType == VVAssetFilterACV) {
            glUniform1f(normalTexture2TypeUniform, 1.0);
            
            RDACVTexture* acvTexture = [self fetchACVTexture:asset.filterUrl];
            
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(GL_TEXTURE_2D, acvTexture.texture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            
            glUniform1i(normalInputTextureUniform2, 1);
        }
        
        if (lookUpImageBuffer){
            glUniform1f(normalTexture2TypeUniform, 2.0);
            glUniform1f(filterIntensityUniform, asset.filterIntensity);
            //                    RDImage* imageBuffer2 = [self fetchImageFrameBuffer:asset.filterUrl];
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(GL_TEXTURE_2D, lookUpImageBuffer.texture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            glUniform1i(normalInputTextureUniform2, 1);
        }
        
        
        if (maskImageBuffer) {
            //                    RDImage* imageBuffer3 = [self fetchImageFrameBuffer:asset.maskURL];
            glActiveTexture(GL_TEXTURE2);
            glBindTexture(GL_TEXTURE_2D, maskImageBuffer.texture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            glUniform1i(normalInputTextureUniform3, 2);
            glUniform1f(normalInputMaskURLUniform, 1.0);
        }
        else {
            glUniform1f(normalInputMaskURLUniform, 0.0);
        }
        
        CVPixelBufferRef sourcePixelBuffer = nil;//[request sourceFrameByTrackID:[asset.trackID intValue]];
        CGSize sourceSize = CGSizeMake(0, 0);
        BOOL isResizePixelBuffer = NO;
        
        
        if(asset.blurIntensity)
        {
            struct BlurFBOList* pList = pBlurFboList;
            while (pList) {
                
                if(pList->index == index)
                    break;
                pList = pList->next;
            }
            if(!pList)
                return;
            
            sourceSize = CGSizeMake(pList->width, pList->height);
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D,pList->hTexture);
            
        }
        else if (asset.beautyBrightIntensity != 0.0 || asset.beautyToneIntensity != 0.0 || asset.beautyBlurIntensity != 0.0 ) {
            TextureFBOList *pList = pBeautyFboList;
            while (pList) {
                if(pList->index == index)
                    break;
                pList = pList->next;
            }
            if(!pList)
                return;
            sourceSize = CGSizeMake(pList->width, pList->height);
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D,pList->texture);
        }
        else if(asset.blendType == RDBlendAIChromaColor ||asset.blendType == RDBlendChromaColor)
        {
            TextureFBOList* pList = pCollageFboList;
            while(pList)
            {
                if(pList->index == index)
                    break;
                pList = pList->next;
            }
            if(!pList)
            {
                NSLog(@"error: fail to find texture units");
                return;
            }
            sourceSize = CGSizeMake(pList->width, pList->height);
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, pList->texture);
        }
        //                    else if (asset.customFilter)
        //                    {
        //                        struct TextureFBOList* pList = pFilterFboList;
        //                        while (pList) {
        //
        //                            if(pList->index == i)
        //                                break;
        //                            pList = pList->next;
        //                        }
        //                        if(!pList)
        //                            continue;
        //
        //                        sourceSize = CGSizeMake(pList->width, pList->height);
        //                        glActiveTexture(GL_TEXTURE0);
        //                        glBindTexture(GL_TEXTURE_2D,pList->texture);
        //                    }
        else
        {
            sourcePixelBuffer = [request sourceFrameByTrackID:[asset.trackID intValue]];
            if (!sourcePixelBuffer) {
                NSLog(@"has no buffer!!!!!!!! :【 %d 】 time:%f",index,CMTimeGetSeconds(request.compositionTime));
                //                            _mvPixelBuffer = NULL;
                *result_statu = 0;
                return;
            }//在切换时有一帧读不出来。。。。
            *result_statu = 1;
            //                        _mvPixelBuffer = sourcePixelBuffer;
            sourceSize = CGSizeMake(CVPixelBufferGetWidth(sourcePixelBuffer), CVPixelBufferGetHeight(sourcePixelBuffer));
            sourcePixelBuffer = [self resizePixelBuffer:sourcePixelBuffer context:context isExporting:((RDVideoCompositorInstruction *)request.videoCompositionInstruction).isExporting];
            CGSize sourceSize_new = CGSizeMake(CVPixelBufferGetWidth(sourcePixelBuffer), CVPixelBufferGetHeight(sourcePixelBuffer));
            if (!CGSizeEqualToSize(sourceSize, sourceSize_new)) {
                isResizePixelBuffer = YES;
                sourceSize = sourceSize_new;
            }
            sourceAssetTexture = [self customTextureForPixelBuffer:sourcePixelBuffer];
            
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(sourceAssetTexture));
            
        }
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        
        GLfloat quadTextureData1[8] = {0.0,1.0,1.0,1.0,0.0,0.0,1.0,0.0};
        
        RDMatrixLoadIdentity(&_modelViewMatrix);
        //20180917 wuxiaoxia 多媒体情况，startTimeInScene不为0的媒体，valueT错误，导致无动画或动画错误
        //                float valueT = (toPosition.atTime - fromPosition.atTime)>0.0?(currentTime - fromPosition.atTime) / (toPosition.atTime - fromPosition.atTime) : 0.0;
        float valueT = (toPosition.atTime - fromPosition.atTime)>0.0?(currentTime - CMTimeGetSeconds(asset.startTimeInScene) - fromPosition.atTime) / (toPosition.atTime - fromPosition.atTime) : 0.0;
        valueT = valueT>1.0?1.0:valueT;
        
        CGRect rectInVideo = CGRectZero;
        if (hasAnimate) {
            rectInVideo = [self CGRectMixed:fromPosition b:toPosition value:valueT type:fromPosition.type] ;
            if (fromPosition.isUseRect) {
                asset.rectInVideo = rectInVideo;
            }else {
                asset.rectInVideo = CGRectMake(0, 0, 1, 1);
            }
        }else{
            rectInVideo = asset.rectInVideo;
        }
        
        
        if(asset.blurIntensity)
        {
            
        }
        else
        {
            [self transformFromAsset:asset
                          sourceSize:sourceSize
                     destinationSize:destinationSize
                         textureData:quadTextureData1
                              factor:valueT
                        fromPosition:fromPosition
                          toPosition:toPosition
                              matrix:&_modelViewMatrix
                          hasAnimate:hasAnimate];
        }
        
        
        
        
        glUniformMatrix4fv(normalTransformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
        
        RDMatrixLoadIdentity(&_projectionMatrix);
        
        float transX = (rectInVideo.origin.x + rectInVideo.size.width/2.0) - 0.5;
        float transY = (rectInVideo.origin.y + rectInVideo.size.height/2.0) - 0.5;
        
        float size = 2.0; //不知道为什么？
        
        RDMatrixTranslate(&_projectionMatrix,transX*size , transY*size, 0);
        glUniformMatrix4fv(normalProjectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
        
        glUniform1i(normalInputTextureUniform, 0);
        glUniform1f(normalBlurUniform, asset.blurIntensity);
        
        if(asset.isBlurredBorder)
            glUniform1f(normalIsBlurredBorderUniform, 1.0);
        else
            glUniform1f(normalIsBlurredBorderUniform, 0.0);
        
        if(90 == [self getOriginRotateAngleFromAsset:asset])
        {
            //如果视频自带旋转角度，crop为旋转之后的角度，需要转换为旋转之前的裁剪区域
            glUniform2f(normalCropOriginUniform, crop.origin.y, 1.0-crop.size.width-crop.origin.x);
            glUniform2f(normalCropSizeUniform, crop.size.height, crop.size.width);
        }
        else
        {
            glUniform2f(normalCropOriginUniform, crop.origin.x, crop.origin.y);
            glUniform2f(normalCropSizeUniform, crop.size.width, crop.size.height);
        }
        
        
        glUniform1f(normalRotateAngleUniform, [self getRotateAngleFromAsset:asset]);
        
        glUniform1f(normalInputAlphaUniform, asset.alpha);
        
        float opacity =  fromPosition.opacity + (toPosition.opacity - fromPosition.opacity) * valueT;
        if (hasAnimate) {
            float brightness = fromPosition.brightness +(toPosition.brightness - fromPosition.brightness) * valueT;
            float contrast = fromPosition.contrast +(toPosition.contrast - fromPosition.contrast) * valueT;
            float saturation = fromPosition.saturation +(toPosition.saturation - fromPosition.saturation) * valueT;
            glUniform4f(normalFilterUniform, brightness, contrast, saturation,opacity);
            
            
            glUniform1f(normalWhiteBalanceUniform, fromPosition.whiteBalance +(toPosition.whiteBalance - fromPosition.whiteBalance) * valueT);
            glUniform1f(normalVignetteUniform, fromPosition.vignette +(toPosition.vignette - fromPosition.vignette) * valueT);
            glUniform1f(normalSharpnessUniform, fromPosition.sharpness +(toPosition.sharpness - fromPosition.sharpness) * valueT);
            
        }else {
            glUniform4f(normalFilterUniform, asset.brightness, asset.contrast, asset.saturation,opacity);
            
            glUniform1f(normalWhiteBalanceUniform, asset.whiteBalance);
            glUniform1f(normalVignetteUniform, asset.vignette);
            glUniform1f(normalSharpnessUniform, asset.sharpness);
            
        }
        
        GLfloat quadVertexData1 [] = {
            -1.0, 1.0,
            1.0, 1.0,
            -1.0, -1.0,
            1.0, -1.0,
        };
        
        
        //NSArray *verts = [JSONDictionary objectForKey:@"vertices"];
        
        //矩形显示
        GLfloat SrcVert[4][2]={{0.0,0.0},{1.0,0.0},{1.0,1.0},{0.0,1.0}};
        //                GLfloat SrcVert[4][2]={{0.1,0.1},{0.99,0.1},{0.99,0.9},{0.1,0.9}};
        GLfloat DstVert[4][2]={{0.0,0.0},{1.0,0.0},{1.0,1.0},{0.0,1.0}};
        //                GLfloat DstVert[4][2]={{1.0/100.0,0.3},{0.8,0.1},{1.0,1.0},{0.3,0.6}};
        
        
        if (hasAnimate) {
            if (!fromPosition.isUseRect) {
                bool bPoint = false;
                CGRect crop = [self CropMixed:fromPosition b:toPosition value:valueT type:fromPosition.type];
                [self getSrcVertFromAsset:asset Crop:crop srcVert:SrcVert];
                //不规则四边形
                if(isMV)
                    bPoint = [self getDestVertFromAsset:asset PointArray:fromPosition.pointsArray DestVert:DstVert];
                else
                    bPoint = [self getDestVertFromAsset:asset PointFrom:fromPosition PointTo:toPosition Current:currentTime DestVert:DstVert watermarkStartTime:0];
                //                        for (int i = 0; i<8; i++) {
                //                            NSLog(@"i: %d  x:%f y:%f ",i,DstVert[i][0],DstVert[i][1]);
                //                        }
                
                //20180614 四个顶点是一个点的情况，不显示该帧
                if (bPoint) {
                    if(sourceAssetTexture)
                    {
                        glBindTexture(CVOpenGLESTextureGetTarget(sourceAssetTexture), 0);
                        CFRelease(sourceAssetTexture);
                        sourceAssetTexture = 0;
                    }
                    return;
                }
                //20180725 横屏视频需要拉伸，不然不会占满整个区域
                RDMatrixLoadIdentity(&_modelViewMatrix);
                glUniformMatrix4fv(normalTransformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
            }
        }
        else if(!asset.isUseRect)
        {
            bool bPoint = false;
            CGRect crop = [self CropMixed:fromPosition b:toPosition value:valueT type:fromPosition.type];
            [self getSrcVertFromAsset:asset Crop:crop srcVert:SrcVert];
            //不规则四边形
            bPoint = [self getDestVertFromAsset:asset PointArray:asset.pointsInVideoArray DestVert:DstVert];
            
            if (bPoint) {
                
                if(sourceAssetTexture)
                {
                    glBindTexture(CVOpenGLESTextureGetTarget(sourceAssetTexture), 0);
                    CFRelease(sourceAssetTexture);
                    sourceAssetTexture = 0;
                }
                return;
            }
            //20180725 横屏视频需要拉伸，不然不会占满整个区域
            RDMatrixLoadIdentity(&_modelViewMatrix);
            glUniformMatrix4fv(normalTransformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
        }
        
        //                //部分视频最右边有黑线，处理锯齿问题
        //                for (int i = 0; i<4; i++) {
        //                    SrcVert[i][0] = (SrcVert[i][0] == 1.0)?0.99:SrcVert[i][0];
        //                    SrcVert[i][1] = (SrcVert[i][1] == 1.0)?0.99:SrcVert[i][1];
        //                }
        
        glUniform2fv(normalSrcQuadrilateralUniform, 4, SrcVert[0]);
        glUniform2fv(normalDstQuadrilateralUniform, 4, DstVert[0]);
        
        //单个像素在目标纹理中的大小。例如目标纹理将被渲染为 800*600 的矩形，那么单个像素就是 1/800, 1/600
        //                glUniform2f(normalDstSinglePixelSizeUniform,1.0/(float)(sourceSize.width),1.0/(float)(sourceSize.height));
        glUniform2f(normalDstSinglePixelSizeUniform,1.0/(float)(_videoSize.width),1.0/(float)(_videoSize.height));
        
        
        glVertexAttribPointer(normalPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData1);
        glEnableVertexAttribArray(normalPositionAttribute);
        
        glVertexAttribPointer(normalTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData1);
        glEnableVertexAttribArray(normalTextureCoordinateAttribute);
        if (asset.maskURL) {
#if 0
            GLfloat quadTextureData2 [] = { //纹理坐标
                0.0f, 1.0f,
                1.0f, 1.0f,
                0.0f, 0.0f,
                1.0f, 0.0f,
            };
#else
            const GLfloat *quadTextureData2 = [self textureCoordinatesForAsset:asset];
#endif
            glVertexAttribPointer(normalTextureMaskCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData2);
            glEnableVertexAttribArray(normalTextureMaskCoordinateAttribute);
        }
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        
        if(sourceAssetTexture)
        {
            glBindTexture(CVOpenGLESTextureGetTarget(sourceAssetTexture), 0);
            CFRelease(sourceAssetTexture);
            sourceAssetTexture = NULL;
        }
        if (isResizePixelBuffer && sourcePixelBuffer) {
            CVPixelBufferRelease(sourcePixelBuffer);
        }
    }
    
    if (asset.type == RDAssetTypeImage
        //                    && asset.last <= tweenFactor
        && currentTime >= CMTimeGetSeconds(asset.startTimeInScene)
        && currentTime <= startTime + CMTimeGetSeconds(CMTimeAdd(asset.startTimeInScene, CMTimeMultiplyByFloat64(asset.timeRange.duration, 1.0/asset.speed))))
    {
        RDImage* imageBuffer = [self fetchImageFrameBuffer:asset.url];
        [imageBuffer setCurrentTime:(currentTime - CMTimeGetSeconds(asset.startTimeInScene))*asset.speed + CMTimeGetSeconds(asset.timeRange.start)];
        
        float value = 1.0;
        if (asset.filterType == VVAssetFilterEmpty) {
            glUniform1f(normalTexture2TypeUniform, 0.0);
        }
        
        if (asset.filterType == VVAssetFilterACV) {
            glUniform1f(normalTexture2TypeUniform, 1.0);
            
            RDACVTexture* acvTexture = [self fetchACVTexture:asset.filterUrl];
            //
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(GL_TEXTURE_2D, acvTexture.texture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            
            glUniform1i(normalInputTextureUniform2, 1);
        }
        if (asset.filterType == VVAssetFilterLookup){
            glUniform1f(normalTexture2TypeUniform, 2.0);
            glUniform1f(filterIntensityUniform, asset.filterIntensity);
            
            //                  RDImage* imageBuffer2 = [self fetchImageFrameBuffer:asset.filterUrl];
            
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(GL_TEXTURE_2D, lookUpImageBuffer.texture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            glUniform1i(normalInputTextureUniform2, 1);
        }
        if (asset.maskURL) { // 如何mask是
            //                  RDImage* imageBuffer3 = [self fetchImageFrameBuffer:asset.maskURL];
            glActiveTexture(GL_TEXTURE2);
            glBindTexture(GL_TEXTURE_2D, maskImageBuffer.texture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            glUniform1i(normalInputTextureUniform3, 2);
            glUniform1f(normalInputMaskURLUniform, 1.0);
        }else {
            glUniform1f(normalInputMaskURLUniform, 0.0);
        }
        //emmet20180824
        if (asset.fillType == RDImageFillTypeAspectFill) {
            
#if 1
#if 1
            CGFloat viewAspect = _videoSize.width / _videoSize.height;
            CGFloat imageAspect = imageBuffer.width / imageBuffer.height;
            if (imageAspect < viewAspect) {
                value = viewAspect / imageAspect;
            }else {
                value = imageAspect / viewAspect;
            }
            //                    NSLog(@"value:%f", value);
#else
            if(_videoSize.width>_videoSize.height){
                if(imageBuffer.width>imageBuffer.height){
                    if(imageBuffer.height/imageBuffer.width > _videoSize.height/_videoSize.width){
                        value = _videoSize.height/imageBuffer.height  * (_videoSize.width/_videoSize.height);
                    }else{
                        
                        value = _videoSize.width/imageBuffer.width * (_videoSize.width/_videoSize.height);
                    }
                }else{
                    if(imageBuffer.height == imageBuffer.width){
                        value = _videoSize.width/(imageBuffer.height/imageBuffer.width * _videoSize.height );
                    }else{
                        value = (_videoSize.width/imageBuffer.width) * (_videoSize.width/_videoSize.height);
                    }
                }
            }else if(_videoSize.width == _videoSize.height){
                if(imageBuffer.height == imageBuffer.width){
                    value = _videoSize.width/(imageBuffer.height/imageBuffer.width * _videoSize.height );
                }else{
                    value = _videoSize.height/MIN(imageBuffer.width, imageBuffer.height);
                }
            }else{
                if(imageBuffer.width<imageBuffer.height){
                    if(imageBuffer.width/imageBuffer.height < _videoSize.width/_videoSize.height){
                        value = _videoSize.width/imageBuffer.width * (_videoSize.height/_videoSize.width);
                    }else{
                        value = _videoSize.height/imageBuffer.height * (_videoSize.height/_videoSize.width);
                    }
                }else if(imageBuffer.height == imageBuffer.width){
                    value = _videoSize.height/(imageBuffer.width/imageBuffer.height * _videoSize.width );
                }else{
                    value = _videoSize.height/imageBuffer.height * (_videoSize.height/_videoSize.width);
                }
            }
#endif
            //                    if(CMTimeGetSeconds(asset.endAnimationTimeRange.duration) !=0)
            //                    value = 1;
            
            
            //                    BOOL hasAnimate =  YES;//CMTimeGetSeconds(asset.endAnimationTimeRange.start)<=currentTime && (CMTimeGetSeconds(asset.endAnimationTimeRange.duration) + CMTimeGetSeconds(asset.endAnimationTimeRange.start))>=currentTime && currentTime >0;//asset.animate.count>0;
            //
            //                    float v = pow(MAX(_videoSize.width,_videoSize.width), 2) * 2;
            //                    if(_videoSize.width>_videoSize.height){
            //                        value = (hasAnimate ? sqrt(v) : _videoSize.height) /MIN(imageBuffer.width, imageBuffer.height);
            //                    }else if(_videoSize.width == _videoSize.height){
            //                        value = (hasAnimate ? sqrt(v) : _videoSize.width) /MIN(imageBuffer.width, imageBuffer.height);
            //                    }else{
            //                        if(imageBuffer.width<imageBuffer.height){
            //                            if(imageBuffer.width/imageBuffer.height > _videoSize.width/_videoSize.height){
            //                                value = _videoSize.width/imageBuffer.width * (_videoSize.height/_videoSize.width);
            //                            }else{
            //                                value = _videoSize.height/imageBuffer.height;
            //                            }
            //                        }else{
            //                            value = _videoSize.height/imageBuffer.height * (_videoSize.height/_videoSize.width);
            //                        }
            //                    }
            //value = 1;//imageBuffer.height/imageBuffer.width;
#else
            if(_videoSize.width>_videoSize.height){
                if(imageBuffer.width>imageBuffer.height){
                    if(imageBuffer.height/imageBuffer.width > _videoSize.height/_videoSize.width){
                        value = _videoSize.height/imageBuffer.height  * (_videoSize.width/_videoSize.height);
                    }else{
                        value = _videoSize.width/imageBuffer.width;
                    }
                }else{
                    value = (_videoSize.width/imageBuffer.width) * (_videoSize.width/_videoSize.height);
                }
            }else if(_videoSize.width == _videoSize.height){
                value = imageBuffer.height/imageBuffer.width;
            }else{
                if(imageBuffer.width<imageBuffer.height){
                    if(imageBuffer.width/imageBuffer.height > _videoSize.width/_videoSize.height){
                        value = _videoSize.width/imageBuffer.width * (_videoSize.height/_videoSize.width);
                    }else{
                        value = _videoSize.height/imageBuffer.height * (_videoSize.height/_videoSize.width);
                    }
                }else{
                    value = _videoSize.height/imageBuffer.height * (_videoSize.height/_videoSize.width);
                }
            }
#endif
        }
        if (asset.fillType == RDImageFillTypeFit) {
            value = 1.0;
        }
        
        if (asset.fillType == RDImageFillTypeFitZoomOut) {
            value = 1.2 - 0.2 * tweenFactor;
        }
        
        if (asset.fillType == RDImageFillTypeFitZoomIn) {
            value = 1.0 + 0.2 * tweenFactor;
        }
        
        // 需要设置asset的size
        GLfloat quadTextureData1[8] = {0.0,1.0,1.0,1.0,0.0,0.0,1.0,0.0};
        
        CGSize sourceSize = CGSizeMake(0, 0);
        
        if(asset.blurIntensity)
        {
            struct BlurFBOList* pList = pBlurFboList;
            while (pList) {
                
                if(pList->index == index)
                    break;
                pList = pList->next;
            }
            if(!pList)
                return;
            sourceSize = CGSizeMake(pList->width, pList->height);
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D,pList->hTexture);
        }
        else if (asset.beautyBrightIntensity != 0.0 || asset.beautyToneIntensity != 0.0 || asset.beautyBlurIntensity != 0.0 ) {
            TextureFBOList *pList = pBeautyFboList;
            while (pList) {
                if(pList->index == index)
                    break;
                pList = pList->next;
            }
            if(!pList)
                return;
            sourceSize = CGSizeMake(pList->width, pList->height);
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D,pList->texture);
        }
        else if(asset.blendType == RDBlendAIChromaColor || asset.blendType == RDBlendChromaColor)
        {
            TextureFBOList* pList = pCollageFboList;
            while(pList)
            {
                if(pList->index == index)
                    break;
                pList = pList->next;
            }
            if(!pList)
            {
                NSLog(@"error: fail to find texture units");
                return;
            }
            sourceSize = CGSizeMake(pList->width, pList->height);
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, pList->texture);
        }
        //                    else if(asset.customFilter)
        //                    {
        //                        struct TextureFBOList* pList = pFilterFboList;
        //                        while (pList) {
        //
        //                            if(pList->index == i)
        //                                break;
        //                            pList = pList->next;
        //                        }
        //                        if(!pList)
        //                            continue;
        //                        sourceSize = CGSizeMake(pList->width, pList->height);
        //                        glActiveTexture(GL_TEXTURE0);
        //                        glBindTexture(GL_TEXTURE_2D,pList->texture);
        //
        //                    }
        else
        {
            sourceSize = CGSizeMake(imageBuffer.width, imageBuffer.height);
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, imageBuffer.texture);
        }
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        
        
        
        RDMatrixLoadIdentity(&_modelViewMatrix);
        
        //                float valueT = (toPosition.atTime - fromPosition.atTime)>0.0?(currentTime - fromPosition.atTime) / (toPosition.atTime - fromPosition.atTime) : 0.0;
        float valueT = (toPosition.atTime - fromPosition.atTime)>0.0?(currentTime - CMTimeGetSeconds(asset.startTimeInScene) - fromPosition.atTime) / (toPosition.atTime - fromPosition.atTime) : 0.0;
        valueT = valueT>1.0?1.0:valueT;
        
        
        CGRect rectInVideo = CGRectZero;
        if (hasAnimate) {
            rectInVideo = [self CGRectMixed:fromPosition b:toPosition value:valueT type:fromPosition.type];
            if (fromPosition.isUseRect) {
                asset.rectInVideo = rectInVideo;
            }else {
                asset.rectInVideo = CGRectMake(0, 0, 1, 1);
            }
        }else{
            rectInVideo = asset.rectInVideo;
        }
        
        //        float left = rectInVideo.origin.x*_videoSize.width;
        //        float right = left + rectInVideo.size.width*_videoSize.width;
        //        float top = rectInVideo.origin.y*_videoSize.height;
        //        float bottom = top + rectInVideo.size.height*_videoSize.height;
        //
        //        NSLog(@"time :%.4g left_top:(x:%.4g y:%.4g) right_top:(x:%.4g y:%.4g) left_bottom:(x:%.4g y:%.4g) right_bottom:(x:%.4g y:%.4g)",currentTime,left,top,right,top,left,bottom,right,bottom);
        
        if(asset.blurIntensity)
        {
            
        }
        else
        {
            [self transformFromAsset:asset
                          sourceSize:sourceSize
                     destinationSize:destinationSize
                         textureData:quadTextureData1
                              factor:valueT
                        fromPosition:fromPosition
                          toPosition:toPosition
                              matrix:&_modelViewMatrix
                          hasAnimate:hasAnimate];
        }
        
        
        RDMatrixScale(&_modelViewMatrix, value, value, 1.0);
        
        glUniformMatrix4fv(normalTransformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
        
        
        RDMatrixLoadIdentity(&_projectionMatrix);
        
        //                if (asset.fillType != RDImageFillTypeFull) {
        //20180907 wuxiaoxia fix bug:rectInVideo不是CGRectMake(0, 0, 1, 1),且fillType为RDImageFillTypeFull，图片的位置错误
        
        float transX = (rectInVideo.origin.x + rectInVideo.size.width/2.0) - 0.5;
        float transY = (rectInVideo.origin.y + rectInVideo.size.height/2.0) - 0.5;
        
        float size = 2.0; //不知道为什么？
        
        
        RDMatrixTranslate(&_projectionMatrix,transX*size , transY*size, 0);
        
        //                }
        
        glUniformMatrix4fv(normalProjectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
        
        glUniform1i(normalInputTextureUniform, 0);
        glUniform1f(normalBlurUniform, asset.blurIntensity);
        if(asset.isBlurredBorder)
            glUniform1f(normalIsBlurredBorderUniform, 1.0);
        else
            glUniform1f(normalIsBlurredBorderUniform, 0.0);
        
        glUniform2f(normalCropOriginUniform, crop.origin.x, crop.origin.y);
        glUniform2f(normalCropSizeUniform, crop.size.width, crop.size.height);
        
        glUniform1f(normalRotateAngleUniform, [self getRotateAngleFromAsset:asset]);
        glUniform1f(normalInputAlphaUniform, asset.alpha);
        
        float opacity =  fromPosition.opacity + (toPosition.opacity - fromPosition.opacity) * valueT;
        if (hasAnimate) {
            float brightness = fromPosition.brightness +(toPosition.brightness - fromPosition.brightness) * valueT;
            float contrast = fromPosition.contrast +(toPosition.contrast - fromPosition.contrast) * valueT;
            float saturation = fromPosition.saturation +(toPosition.saturation - fromPosition.saturation) * valueT;
            glUniform4f(normalFilterUniform, brightness, contrast, saturation,opacity);
            
            glUniform1f(normalWhiteBalanceUniform, fromPosition.whiteBalance +(toPosition.whiteBalance - fromPosition.whiteBalance) * valueT);
            glUniform1f(normalVignetteUniform, fromPosition.vignette +(toPosition.vignette - fromPosition.vignette) * valueT);
            glUniform1f(normalSharpnessUniform, fromPosition.sharpness +(toPosition.sharpness - fromPosition.sharpness) * valueT);
            
        }else {
            glUniform4f(normalFilterUniform, asset.brightness, asset.contrast, asset.saturation,opacity);
            
            glUniform1f(normalWhiteBalanceUniform, asset.whiteBalance);
            glUniform1f(normalVignetteUniform, asset.vignette);
            glUniform1f(normalSharpnessUniform, asset.sharpness);
            
        }
        
        GLfloat quadVertexData1 [] = {
            -1.0, 1.0,
            1.0, 1.0,
            -1.0, -1.0,
            1.0, -1.0,
        };
        
        
        //矩形显示
        GLfloat SrcVert[4][2]={{0.0,0.0},{1.0,0.0},{1.0,1.0},{0.0,1.0}};
        GLfloat DstVert[4][2]={{0.0,0.0},{1.0,0.0},{1.0,1.0},{0.0,1.0}};
        
        if (hasAnimate) {
            if (!fromPosition.isUseRect) {
                bool bPoint = false;
                CGRect crop = [self CropMixed:fromPosition b:toPosition value:valueT type:fromPosition.type];
                [self getSrcVertFromAsset:asset Crop:crop srcVert:SrcVert];
                //不规则四边形
                if(isMV)
                    bPoint = [self getDestVertFromAsset:asset PointArray:fromPosition.pointsArray DestVert:DstVert];
                else
                    bPoint = [self getDestVertFromAsset:asset PointFrom:fromPosition PointTo:toPosition Current:currentTime DestVert:DstVert watermarkStartTime:0];
                
                if (bPoint) {
                    return;
                }
            }
        }
        else if(!asset.isUseRect)
        {
            bool bPoint = false;
            CGRect crop = [self CropMixed:fromPosition b:toPosition value:valueT type:fromPosition.type];
            [self getSrcVertFromAsset:asset Crop:crop srcVert:SrcVert];
            //不规则四边形
            bPoint = [self getDestVertFromAsset:asset PointArray:asset.pointsInVideoArray DestVert:DstVert];
            if (bPoint) {
                return;
            }
            RDMatrixLoadIdentity(&_modelViewMatrix);
            glUniformMatrix4fv(normalTransformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
        }
        //                //部分视频最右边有黑线，处理锯齿问题
        //                for (int i = 0; i<4; i++) {
        //                    SrcVert[i][0] = (SrcVert[i][0] == 1.0)?0.99:SrcVert[i][0];
        //                    SrcVert[i][1] = (SrcVert[i][1] == 1.0)?0.99:SrcVert[i][1];
        //                }
        
        
        glUniform2fv(normalSrcQuadrilateralUniform, 4, SrcVert[0]);
        glUniform2fv(normalDstQuadrilateralUniform, 4, DstVert[0]);
        
        //        float left = rectInVideo.origin.x*_videoSize.width;
        //        float right = left + rectInVideo.size.width*_videoSize.width;
        //        float top = rectInVideo.origin.y*_videoSize.height;
        //        float bottom = top + rectInVideo.size.height*_videoSize.height;
        //
        //        NSLog(@"time :%.4g left_top:(x:%.4g y:%.4g) right_top:(x:%.4g y:%.4g) left_bottom:(x:%.4g y:%.4g) right_bottom:(x:%.4g y:%.4g)",currentTime,DstVert[0][0]*730.0,DstVert[0][1]*960.0,
        //              DstVert[1][0]*730.0,DstVert[1][1]*960.0,
        //              DstVert[3][0]*730.0,DstVert[3][1]*960.0,
        //              DstVert[2][0]*730.0,DstVert[2][1]*960.0);
        
        
        //单个像素在目标纹理中的大小。例如目标纹理将被渲染为 800*600 的矩形，那么单个像素就是 1/800, 1/600
        //float quad_width  = ((DstVert[1][0] - DstVert[0][0])>(DstVert[2][0] - DstVert[3][0]))?(DstVert[1][0] - DstVert[0][0]):(DstVert[2][0] - DstVert[3][0]);
        //float quad_height = ((DstVert[3][1] - DstVert[0][1])>(DstVert[2][1] - DstVert[1][1]))?(DstVert[3][1] - DstVert[0][1]):(DstVert[2][1] - DstVert[1][1]);
        //                glUniform2f(normalDstSinglePixelSizeUniform,1.0/(float)(sourceSize.width),1.0/(float)(sourceSize.height));
        glUniform2f(normalDstSinglePixelSizeUniform,1.0/(float)(_videoSize.width),1.0/(float)(_videoSize.height));
        
        
        glVertexAttribPointer(normalPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData1);
        glEnableVertexAttribArray(normalPositionAttribute);
        
        
        glVertexAttribPointer(normalTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData1);
        
        
        glEnableVertexAttribArray(normalTextureCoordinateAttribute);
        if (asset.maskURL) {
#if 0
            GLfloat quadTextureData2 [] = { //纹理坐标
                0.0f, 1.0f,
                1.0f, 1.0f,
                0.0f, 0.0f,
                1.0f, 0.0f,
            };
#else
            const GLfloat *quadTextureData2 = [self textureCoordinatesForAsset:asset];
#endif
            
            glVertexAttribPointer(normalTextureMaskCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData2);
            glEnableVertexAttribArray(normalTextureMaskCoordinateAttribute);
        }
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        //                [imageBuffer clear];
        //                glDeleteTextures(1, &imageBuffer.texture);
        
    }
    return ;
}
- (void)simpleRenderWidthTexture:(GLuint)texture
{
    GLfloat vertices[8]  = {
        
        -1.0,-1.0,
        1.0,-1.0,
        -1.0,1.0,
        1.0,1.0,
    };
    
    GLfloat textureCoordinates[8]  = {
        0.0,0.0,
        1.0,0.0,
        0.0,1.0,
        1.0,1.0,
    };
    
    glUseProgram(self.simpleProgram);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glUniform1i(simpleInputTextureUniform, 0);
    
    RDMatrixLoadIdentity(&_modelViewMatrix);
    glUniformMatrix4fv(simpleTransformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
    
    RDMatrixLoadIdentity(&_projectionMatrix);
    glUniformMatrix4fv(simpleProjectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
    
    
    
    glVertexAttribPointer(simplePositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glEnableVertexAttribArray(simplePositionAttribute);
    glVertexAttribPointer(simpleTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    glEnableVertexAttribArray(simpleTextureCoordinateAttribute);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDisableVertexAttribArray(simplePositionAttribute);
    glDisableVertexAttribArray(simpleTextureCoordinateAttribute);
}


- (int)renderAssetToFrameBuferObject:(RDScene *)scene request:(AVAsynchronousVideoCompositionRequest *)request
{
    
    int result_statu = 1;
    float dstTextureWidth = _videoSize.width;
    float dstTextureHeight = _videoSize.height;
    float facor = 1.0;
    GLuint texture = -1;
    TextureFBOList* pList = nil;
    sourceAssetTexture = 0;
    
    if (!((RDVideoCompositorInstruction *)request.videoCompositionInstruction).isExporting) {
        facor = [self getFacorFromWidth:dstTextureWidth height:dstTextureHeight];
    }
    dstTextureWidth  *= facor;
    dstTextureHeight *= facor;
    
    if (!pDstFboList) {
        pDstFboList = (struct TextureFBOList*)malloc(sizeof(TextureFBOList));
        if(!pDstFboList)
        {
            NSLog(@"dst fbo malloc fail!!");
            return 0;
        }
        memset(pDstFboList, 0, sizeof(TextureFBOList));
        
        if (pDstFboList->height != dstTextureHeight || pDstFboList->width != dstTextureWidth)
            [self initFrameBuffobject:pDstFboList DstWidth:dstTextureWidth DstHeight:dstTextureHeight];
    }
    if(!pDstFboList->fbo)
        glGenFramebuffers(1, &pDstFboList->fbo);
    
    
    glBindFramebuffer(GL_FRAMEBUFFER, pDstFboList->fbo);
    glViewport(0, 0, dstTextureWidth, dstTextureHeight);
    
    
    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, pDstFboList->texture, 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
    
    
    
    
    //开启blend
    glEnable(GL_BLEND);
    //        //    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    if (scene.backgroundColor) {
        const CGFloat *components = CGColorGetComponents(scene.backgroundColor.CGColor);
        glClearColor(components[0]*components[3],components[1]*components[3],components[2]*components[3], components[3]);
    }
    else if(_virtualVideoBgColor) {
        const CGFloat *components = CGColorGetComponents(_virtualVideoBgColor.CGColor);
        //                glClearColor(components[0],components[1],components[2], components[3]);
        glClearColor(components[0]*components[3],components[1]*components[3],components[2]*components[3], components[3]);
        //                NSLog(@"R:%f G:%f B:%f A:%f", components[0],components[1],components[2],components[3] );
    }else {
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    }
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    texture = -1;
    //如果有背景媒体，先绘制背景媒体
    if (scene.backgroundAsset)
    {
        VVAsset* asset = scene.backgroundAsset;
        if(asset.blurIntensity){
            //模糊背景
            BlurFBOList* p =  pBlurFboList;
            while (p) {
                if(p->index == -1)
                {
                    texture = p->hTexture;
                    break;
                }
                p = p->next;
            }
        }
        else{
            //常规背景
            TextureFBOList* p =  pAssetFboList;
            while (p) {
                if(p->index == -1)
                {
                    texture = p->texture;
                    break;
                }
                p = p->next;
            }
        }
        
        if(texture == -1)
            NSLog(@"fail to find specified backgroundAsset texture ");
        else
            [self simpleRenderWidthTexture:texture];
    }
    
    //依次绘制场景中的单个媒体
    for(int i = 0;i<scene.vvAsset.count;i++)
    {
        VVAsset* asset = scene.vvAsset[i];
        texture = -1;
        pList = asset.customFilter ? pFilterFboList : pAssetFboList;
        while (pList) {
            if(pList->index == i)
            {
                texture = pList->texture;
                break;
            }
            pList = pList->next;
        }
        if(texture == -1)
        {
            NSLog(@"fail to find specified texture when i:%d hasFilter:%d",i,asset.customFilter?1:0);
            continue;
        }
        [self simpleRenderWidthTexture:texture];
    }

    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    if(sourceAssetTexture)
    {
        glBindTexture(CVOpenGLESTextureGetTarget(sourceAssetTexture), 0);
        CFRelease(sourceAssetTexture);
        sourceAssetTexture = 0;
    }

    return result_statu;
}


-(void) initFrameBuffobject:(TextureFBOList*)obj DstWidth:(int)width DstHeight:(int)height
{
    if(!obj || width<=0 || height<=0)
        return;
    if (obj->width != width || obj->height != height) {
        
        unsigned char* dataBuf =(unsigned char*) malloc(width * height *4);
        memset(dataBuf, 0, width * height *4);
        for(int i = 0;i<width*height;i++)
        {
            dataBuf[i*4] = 0x00;
            dataBuf[i*4+1] = 0x00;
            dataBuf[i*4+2] = 0x00;
            dataBuf[i*4+3] = 0xff;
            
        }
        if(obj->texture)
            glDeleteTextures(1, &obj->texture);
        if(obj->fbo)
            glDeleteFramebuffers(1, &obj->fbo);
        
        obj->width = width;
        obj->height = height;
        obj->texture = [self textureFromBufferObject:dataBuf Width:width Height:height];
        glGenFramebuffers(1, &obj->fbo);
        
        free(dataBuf);
    }
    
}

-(int) renderCollageToFrameBufferObjectWithWatermark:(RDWatermark *)collage WatermarkIndex:(int)watermarkIndex DestTextureFBO:(TextureFBOList*)fbo  ViewPort:(CGSize)size request:(AVAsynchronousVideoCompositionRequest *)request
{
    int resultStatu = 1;
    RDBlendType blendType = collage.vvAsset.blendType;
    UIColor* chromaColor = collage.vvAsset.chromaColor;
    TextureFBOList* assetFBO = fbo;
    int dstWidth = size.width;
    int dstHeight = size.height;
    
    if(!fbo || dstWidth <= 0 || dstHeight <= 0)
        return 0;
    
    if (assetFBO->width != dstWidth || assetFBO->height != dstHeight)
        [self initFrameBuffobject:assetFBO DstWidth:dstWidth DstHeight:dstHeight];

    glBindFramebuffer(GL_FRAMEBUFFER, assetFBO->fbo);
    glViewport(0, 0, dstWidth, dstHeight);


    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, assetFBO->texture, 0);

    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
    
    if(blendType == RDBlendNormal)
    {
        glClearColor(1.0, 1.0, 1.0, 0.0);
        collage.vvAsset.srcFactor = BLEND_GL_ONE;
        collage.vvAsset.dstFactor = BLEND_GL_ONE_MINUS_SRC_ALPHA;
    }
    else
        glClearColor(0.0, 0.0, 0.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(self.program);
//    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

    
    
    [self renderAsset:collage.vvAsset AssetIndex:watermarkIndex
            TimeRange:collage.timeRange request:request Statu:&resultStatu];
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    return resultStatu;
}

-(void) renderCollageChromaColorWithForegroundTexture:(GLuint)foregroundTexture andBackgroundTexture:(GLuint)backgroundTexture ChromColor:(UIColor*)chromaColor
{
    GLfloat textureCoordinates [] = { //纹理坐标
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    GLfloat vertices [] = {
        -1.0, 1.0,
        1.0, 1.0,
        -1.0, -1.0,
        1.0, -1.0,
    };
    const CGFloat *components = CGColorGetComponents(chromaColor.CGColor);
    
    
    
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
//    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);//

    if(chromaColor == NULL)
    {
        glUseProgram(self.chromaColorProgram);
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, backgroundTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glUniform1i(chromaColorInputTextureUniform, 0); //背景纹理
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, foregroundTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glUniform1i(chromaColorInputTextureUniform2, 1); //素材纹理，指定颜色透明
        
        glUniform1i(chromaColorBgModeUniform, backgroundInfo.bgMode);
        glUniform2f(chromaColorThresholdAUniform, backgroundInfo.thresholdA.begin/255.0,backgroundInfo.thresholdA.end/255.0);
        glUniform2f(chromaColorThresholdBUniform, backgroundInfo.thresholdB.begin/255.0,backgroundInfo.thresholdB.end/255.0);
        glUniform2f(chromaColorThresholdCUniform, backgroundInfo.thresholdC.begin/255.0,backgroundInfo.thresholdC.end/255.0);
        glUniform1i(chromaColorEdgeModeUniform, 1);
        
        
        
        glVertexAttribPointer(chromaColorPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
        glEnableVertexAttribArray(chromaColorPositionAttribute);
        
        glVertexAttribPointer(chromaColorTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
        glEnableVertexAttribArray(chromaColorTextureCoordinateAttribute);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
    else
    {
        //指定颜色透明
        glUseProgram(self.chromaKeyProgram);
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, backgroundTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glUniform1i(chromaKeyInputBackGroundImageTexture, 0); //背景纹理
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, foregroundTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glUniform1i(chromaKeyInputColorTransparencyImageTexture, 1); //素材纹理，指定颜色透明
#if 1
        glUniform3f(chromaKeyInputColorUnifrom, components[0], components[1], components[2]); //指定颜色透明
#else
        glUniform1i(chromaKeyBgModeUniform, backgroundInfo.bgMode);
        glUniform2f(chromaKeyThresholdAUniform, backgroundInfo.thresholdA.begin/255.0,backgroundInfo.thresholdA.end/255.0);
        glUniform2f(chromaKeyThresholdBUniform, backgroundInfo.thresholdB.begin/255.0,backgroundInfo.thresholdB.end/255.0);
        glUniform2f(chromaKeyThresholdCUniform, backgroundInfo.thresholdC.begin/255.0,backgroundInfo.thresholdC.end/255.0);
        glUniform1i(chromaKeyEdgeModeUniform, 1);
        
        //    program->setUniformValue("bgMode", m_bkInfo.bgMode);
        //    program->setUniformValue("thresholdA", QVector2D( m_bkInfo.thresholdA.begin / 255.0f, m_bkInfo.thresholdA.end / 255.0f) );
        //    program->setUniformValue("thresholdB", QVector2D(m_bkInfo.thresholdB.begin / 255.0f, m_bkInfo.thresholdB.end / 255.0f));
        //    program->setUniformValue("thresholdC", QVector2D(m_bkInfo.thresholdC.begin / 255.0f, m_bkInfo.thresholdC.end / 255.0f));
        //    program->setUniformValue("edgeMode", 1 );
#endif
        
        glVertexAttribPointer(chromaKeyPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
        glEnableVertexAttribArray(chromaKeyPositionAttribute);
        
        glVertexAttribPointer(chromaKeyTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
        glEnableVertexAttribArray(chromaKeyTextureCoordinateAttribute);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
    }
    

}


-(int ) renderCollageAIChromaColorToFrameBufferObject:(RDWatermark *)collage WatermarkIndex:(int)index Request:(AVAsynchronousVideoCompositionRequest *)request
{
    RDImage* imageBuffer = NULL;
    CVPixelBufferRef pPixelBuffer = NULL;
    float width  = 0;
    float height = 0;
    
    CVOpenGLESTextureRef sourceTexture = 0;
    GLuint texture = 0;
    BOOL isResizePixelBuffer = NO;
    TextureFBOList* pList = pCollageFboList;
    TextureFBOList* pNode = nil;
    VVAsset* asset = collage.vvAsset;
    
    //1.找到对应的FBO
    while(pList)
    {
        if(pList->index == index)
            break;
        pList = pList->next;
    }
    if(!pList)
    {
        pList = pCollageFboList;
        while (pList && pList->next)
            pList = pList->next;
        pList->next = (TextureFBOList*)malloc(sizeof(TextureFBOList));
        memset(pList->next, 0, sizeof(TextureFBOList));
        pList->next->index = index;
        pNode = pList->next;
    }
    else
        pNode = pList;
        
    //2.解码
    if (asset.type == RDAssetTypeImage)//图片
    {

        imageBuffer = [self fetchImageFrameBuffer:asset.url];
        width = imageBuffer.width;
        height = imageBuffer.height;
        texture = imageBuffer.texture;
  
        if(asset.blendType == RDBlendAIChromaColor)
        {
            int imageWidth = imageBuffer.width;
            int imageHeight = imageBuffer.height;
            CGImageRef cgImage = [imageBuffer.currentImage CGImage];

            void* imageData = (void*)calloc(1, (int)imageWidth*(int)imageHeight*4);
            CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
            CGContextRef imageContext = CGBitmapContextCreate(imageData, imageWidth, imageHeight, 8, 4*imageWidth, genericRGBColorspace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
            CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, imageWidth, imageHeight), cgImage);
            CGContextRelease(imageContext);
            CGColorSpaceRelease(genericRGBColorspace);

            memset(&backgroundInfo, 0, sizeof(backgroundInfo));
            backgroundInfo = cleanBackground.selectSolid((uint8_t*)imageData, imageWidth, imageHeight);
            free(imageData);
        }
    }
    else
    {
        //视频
        pPixelBuffer = [request sourceFrameByTrackID:[asset.trackID intValue]];
        if (!pPixelBuffer) {
            NSLog(@"renderCollageAssetToFrameBufferObjectWithWatermark :has no buffer!!!!!!!! :【 %d 】 time:%f",index,CMTimeGetSeconds(request.compositionTime));
            //                    _mvPixelBuffer = NULL;
            return 0;
        }
        
        width  = CVPixelBufferGetWidth(pPixelBuffer);
        height = CVPixelBufferGetHeight(pPixelBuffer);
        pPixelBuffer = [self resizePixelBuffer:pPixelBuffer context:context isExporting:((RDVideoCompositorInstruction *)request.videoCompositionInstruction).isExporting];
        CGSize sourceSize_new = CGSizeMake(CVPixelBufferGetWidth(pPixelBuffer), CVPixelBufferGetHeight(pPixelBuffer));
        if (!CGSizeEqualToSize(CGSizeMake(width, height), sourceSize_new)) {
            isResizePixelBuffer = YES;
            width = sourceSize_new.width;
            height = sourceSize_new.height;
        }
        sourceTexture = [self customTextureForPixelBuffer:pPixelBuffer];
        texture = CVOpenGLESTextureGetName(sourceTexture);
        //                _mvPixelBuffer = pPixelBuffer;
        
        if(asset.blendType == RDBlendAIChromaColor)
        {
            CVPixelBufferLockBaseAddress(pPixelBuffer, 0);
            uint8_t* imageData =(uint8_t*) CVPixelBufferGetBaseAddress(pPixelBuffer);
            CVPixelBufferUnlockBaseAddress(pPixelBuffer, 0);
        
            memset(&backgroundInfo, 0, sizeof(backgroundInfo));
            backgroundInfo = cleanBackground.selectSolid((uint8_t*)imageData, width, height);
            
        }
    }
    
    if(((int)width)%2!=0)
        width = (int)(width+1);
    if(((int)height)%2!=0)
        height = (int)(height+1);
    
    //3.绑定FBO绘制
    if(pNode->width != width || pNode->height != height)
        [self initFrameBuffobject:pNode DstWidth:width DstHeight:height];
    
    glBindFramebuffer(GL_FRAMEBUFFER, pNode->fbo);
    glViewport(0, 0, width, height);
    
    
    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, pNode->texture, 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return 0;
    }
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    

    GLfloat vertices[8]  = {
        
        -1.0,-1.0,
        1.0,-1.0,
        -1.0,1.0,
        1.0,1.0,
    };
    
    GLfloat textureCoordinates[8]  = {
        0.0,0.0,
        1.0,0.0,
        0.0,1.0,
        1.0,1.0,
    };
    
    glUseProgram(self.chromaColorProgram);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glUniform1i(chromaColorInputTextureUniform, 0);
    
    glUniform1i(chromaColorBgModeUniform, backgroundInfo.bgMode);
    glUniform2f(chromaColorThresholdAUniform, backgroundInfo.thresholdA.begin/255.0,backgroundInfo.thresholdA.end/255.0);
    glUniform2f(chromaColorThresholdBUniform, backgroundInfo.thresholdB.begin/255.0,backgroundInfo.thresholdB.end/255.0);
    glUniform2f(chromaColorThresholdCUniform, backgroundInfo.thresholdC.begin/255.0,backgroundInfo.thresholdC.end/255.0);
    glUniform1i(chromaColorEdgeModeUniform, 1);
    
    
    
    glVertexAttribPointer(chromaColorPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glEnableVertexAttribArray(chromaColorPositionAttribute);
    
    glVertexAttribPointer(chromaColorTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    glEnableVertexAttribArray(chromaColorTextureCoordinateAttribute);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    
    
    if(sourceTexture)
    {
        glBindTexture(CVOpenGLESTextureGetTarget(sourceTexture), 0);
        CFRelease(sourceTexture);
    }
    if (isResizePixelBuffer && pPixelBuffer) {
        CVPixelBufferRelease(pPixelBuffer);
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    return 1;
}


-(int ) renderCollageChromaColorWithForegroundTexture:(RDWatermark *)collage ChromColor:(UIColor*)chromaColor WatermarkIndex:(int)index Request:(AVAsynchronousVideoCompositionRequest *)request
{
    RDImage* imageBuffer = NULL;
    CVPixelBufferRef pPixelBuffer = NULL;
    float width  = 0;
    float height = 0;
    
    CVOpenGLESTextureRef sourceTexture = 0;
    GLuint texture = 0;
    BOOL isResizePixelBuffer = NO;
    TextureFBOList* pList = pCollageFboList;
    TextureFBOList* pNode = nil;
    VVAsset* asset = collage.vvAsset;
    
    //1.找到对应的FBO
    while(pList)
    {
        if(pList->index == index)
            break;
        pList = pList->next;
    }
    if(!pList)
    {
        pList = pCollageFboList;
        while (pList && pList->next)
            pList = pList->next;
        pList->next = (TextureFBOList*)malloc(sizeof(TextureFBOList));
        memset(pList->next, 0, sizeof(TextureFBOList));
        pList->next->index = index;
        pNode = pList->next;
    }
    else
        pNode = pList;
        
    //2.解码
    if (asset.type == RDAssetTypeImage)//图片
    {

        imageBuffer = [self fetchImageFrameBuffer:asset.url];
        width = imageBuffer.width;
        height = imageBuffer.height;
        texture = imageBuffer.texture;
    }
    else
    {
        //视频
        pPixelBuffer = [request sourceFrameByTrackID:[asset.trackID intValue]];
        if (!pPixelBuffer) {
            NSLog(@"renderCollageAssetToFrameBufferObjectWithWatermark :has no buffer!!!!!!!! :【 %d 】 time:%f",index,CMTimeGetSeconds(request.compositionTime));
            //                    _mvPixelBuffer = NULL;
            return 0;
        }
        
        width  = CVPixelBufferGetWidth(pPixelBuffer);
        height = CVPixelBufferGetHeight(pPixelBuffer);
        pPixelBuffer = [self resizePixelBuffer:pPixelBuffer context:context isExporting:((RDVideoCompositorInstruction *)request.videoCompositionInstruction).isExporting];
        CGSize sourceSize_new = CGSizeMake(CVPixelBufferGetWidth(pPixelBuffer), CVPixelBufferGetHeight(pPixelBuffer));
        if (!CGSizeEqualToSize(CGSizeMake(width, height), sourceSize_new)) {
            isResizePixelBuffer = YES;
            width = sourceSize_new.width;
            height = sourceSize_new.height;
        }
        sourceTexture = [self customTextureForPixelBuffer:pPixelBuffer];
        texture = CVOpenGLESTextureGetName(sourceTexture);
        //                _mvPixelBuffer = pPixelBuffer;
       
    }
    
    if(((int)width)%2!=0)
        width = (int)(width+1);
    if(((int)height)%2!=0)
        height = (int)(height+1);
    
    //3.绑定FBO绘制
    if(pNode->width != width || pNode->height != height)
        [self initFrameBuffobject:pNode DstWidth:width DstHeight:height];
    
    glBindFramebuffer(GL_FRAMEBUFFER, pNode->fbo);
    glViewport(0, 0, width, height);
    
    
    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, pNode->texture, 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return 0;
    }
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    GLfloat textureCoordinates [] = { //纹理坐标
            0.0f, 1.0f,
            1.0f, 1.0f,
            0.0f, 0.0f,
            1.0f, 0.0f,
        };
        GLfloat vertices [] = {
            -1.0, 1.0,
            1.0, 1.0,
            -1.0, -1.0,
            1.0, -1.0,
        };
        const CGFloat *components = CGColorGetComponents(chromaColor.CGColor);
        
    
        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    //    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);//

  
    //指定颜色透明
    glUseProgram(self.chromaKeyProgram);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glUniform1i(chromaKeyInputColorTransparencyImageTexture, 0); //素材纹理，指定颜色透明
    glUniform3f(chromaKeyInputColorUnifrom, components[0], components[1], components[2]); //指定颜色透明
    
    
    glVertexAttribPointer(chromaKeyPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glEnableVertexAttribArray(chromaKeyPositionAttribute);
    
    glVertexAttribPointer(chromaKeyTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    glEnableVertexAttribArray(chromaKeyTextureCoordinateAttribute);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    
    if(sourceTexture)
    {
        glBindTexture(CVOpenGLESTextureGetTarget(sourceTexture), 0);
        CFRelease(sourceTexture);
    }
    if (isResizePixelBuffer && pPixelBuffer) {
        CVPixelBufferRelease(pPixelBuffer);
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    return 1;
}
- (bool) renderCollageWithSourceBuffer:(CVPixelBufferRef) sourcePixelBuffer
                     DestinationBuffer:(CVPixelBufferRef) destinationPixelBuffer
                                 scene:(NSMutableArray *)pCollage
                               request:(AVAsynchronousVideoCompositionRequest *)request
{
    CVOpenGLESTextureRef destTexture   = 0;
    CVOpenGLESTextureRef sourceTexture = 0;
    int collageCount = 0;
    int dstWidth = (int)CVPixelBufferGetWidth(destinationPixelBuffer);
    int dstHeight = (int)CVPixelBufferGetHeight(destinationPixelBuffer);
    GLuint texture = 0;
    
    int maxCombinedTextureUnits = 0;
    glGetIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS,&maxCombinedTextureUnits);
    
    displayTime = CMTimeGetSeconds(request.compositionTime);
    
    if (!sourcePixelBuffer || !destinationPixelBuffer)
        return false;
    
    [EAGLContext setCurrentContext:self.currentContext];
    
    destTexture   = [self customTextureForPixelBuffer:destinationPixelBuffer];
    sourceTexture = [self customTextureForPixelBuffer:sourcePixelBuffer];

    if(!pCollageFboList)
    {
        
        for (int i = 0; i<4; i++)
        {
            TextureFBOList* pLast = nil;
            if (!pCollageFboList) {
                pCollageFboList = (TextureFBOList*)malloc(sizeof(TextureFBOList));
                memset(pCollageFboList, 0, sizeof(TextureFBOList));
                pLast = pCollageFboList;
            }
            else
            {
                TextureFBOList* p = pCollageFboList;
                while (p && p->next)
                    p = p->next;
                p->next = (TextureFBOList*)malloc(sizeof(TextureFBOList));
                memset(p->next, 0, sizeof(TextureFBOList));
                pLast = p->next;
            }
            pLast->index = -1;
            if (dstHeight != pLast->height || dstWidth != pLast->width)
                [self initFrameBuffobject:pLast DstWidth:dstWidth DstHeight:dstHeight];
            
        }
        
    }
    

    TextureFBOList* assetFBO = pCollageFboList;             //保存画中画单个媒体的绘制结果
    TextureFBOList* assetChromColorFBO = assetFBO->next;    //保存指定颜色透明绘制的结果
    TextureFBOList* firstFBO = assetChromColorFBO->next;    //保存上一次绘制的结果
    TextureFBOList* secondFBO = firstFBO->next;             //保存当前绘制的结果
    
    collageCount = 0;
    for (int i = 0; i<pCollage.count; i++)
    {
        
        RDWatermark* collage = pCollage[i];
        float startTime = CMTimeGetSeconds(collage.timeRange.start);
        float endTime = startTime + CMTimeGetSeconds(collage.timeRange.duration);
        RDBlendType blendType = collage.vvAsset.blendType;
        UIColor* chromaColor = collage.vvAsset.chromaColor;
        
        if (displayTime < startTime || displayTime > endTime)
            continue;
#if 0
        //测试指定颜色透明
        collage.vvAsset.blendType = RDBlendChromaColor;
        collage.vvAsset.chromaColor = [[UIColor alloc] initWithRed:0.0 green:1.0 blue:0.0 alpha:0.0];
        blendType = collage.vvAsset.blendType;
        chromaColor = collage.vvAsset.chromaColor;
#else
//        collage.vvAsset.blendType = RDBlendHardLight;//RDBlendColorBurn  RDBlendAIChromaColor
//        collage.vvAsset.chromaColor =  nil;
//        blendType = collage.vvAsset.blendType;
//        chromaColor = collage.vvAsset.chromaColor;
#endif
        
        
        
        //1.如果画中画媒体使用自动抠图，先将自动抠图的结果保存到FBO中
        if(blendType == RDBlendAIChromaColor &&
           [self renderCollageAIChromaColorToFrameBufferObject:collage WatermarkIndex:i+COLLAGE_ASSEST_INDEX Request:request] < 1)
        {
            NSLog(@"fail to renderCollageAIChromaColorToFrameBufferObject...");
            continue;
        }
        
        //2.如果画中画媒体使用指定颜色抠图，先将自动抠图的结果保存到FBO中
        if(blendType == RDBlendChromaColor &&
           [self renderCollageChromaColorWithForegroundTexture:collage ChromColor:chromaColor WatermarkIndex:i+COLLAGE_ASSEST_INDEX Request:request] < 1)
        {
            NSLog(@"fail to renderCollageChromaColorWithForegroundTexture...");
            continue;
        }
        
        
        //3.美颜
        if ([self processAssetBeautifulAttribute:collage.vvAsset TimeRange:collage.timeRange request:request Index:i+COLLAGE_ASSEST_INDEX] < 1)
        {
            NSLog(@"fail to processAssetBeautifulAttribute...");
            continue;
        }
        
        
        //4.将画中画媒体 自动抠图/指定颜色抠图/美颜的结果绘制到FBO
        if([self renderCollageToFrameBufferObjectWithWatermark:collage WatermarkIndex:i+COLLAGE_ASSEST_INDEX DestTextureFBO:assetFBO ViewPort:CGSizeMake(dstWidth, dstHeight) request:request] < 1)
        {
            NSLog(@"fail to renderCollageToFrameBufferObjectWithWatermark...");
            continue;
        }
        

        
        //5.再将媒体assetFBO或者抠图的FBO 与 背景纹理处理 blend 或者 常规贴图
        if(firstFBO->width != dstWidth || firstFBO->height != dstHeight)
            [self initFrameBuffobject:firstFBO DstWidth:dstWidth DstHeight:dstHeight];
        if(secondFBO->width != dstWidth || secondFBO->height != dstHeight)
            [self initFrameBuffobject:secondFBO DstWidth:dstWidth DstHeight:dstHeight];
        
        if (collageCount%2 == 0)
        {
            glBindFramebuffer(GL_FRAMEBUFFER, firstFBO->fbo);
            glViewport(0, 0, dstWidth, dstHeight);

            // Attach the destination texture as a color attachment to the off screen frame buffer
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, firstFBO->texture, 0);

            if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
                NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
            }
            
            if (blendType >= RDBlendDark)// 画中画blend模式
            {
                
                if(collageCount == 0)
                    [blendFilter renderBlendModelWithForegroundTexture:assetFBO->texture BackgroundTexture:CVOpenGLESTextureGetName(sourceTexture) BlendType:blendType];
                else
                    [blendFilter renderBlendModelWithForegroundTexture:assetFBO->texture BackgroundTexture:secondFBO->texture BlendType:blendType];
            }
            else // 常规画中画贴图
            {
                if(collageCount == 0)
                    [self renderUsingForegroundTexture:assetFBO->texture andBackgroundTexture:CVOpenGLESTextureGetName(sourceTexture)];
                else
                    [self renderUsingForegroundTexture:assetFBO->texture andBackgroundTexture:secondFBO->texture];
            }
            glBindFramebuffer(GL_FRAMEBUFFER, 0);
           
        }
        else
        {
            glBindFramebuffer(GL_FRAMEBUFFER, secondFBO->fbo);
            glViewport(0, 0, dstWidth, dstHeight);

            // Attach the destination texture as a color attachment to the off screen frame buffer
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, secondFBO->texture, 0);

            if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
                NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
            }

            if (blendType >= RDBlendDark)// 画中画blend模式
            {
                if(![blendFilter renderBlendModelWithForegroundTexture:assetFBO->texture
                                                     BackgroundTexture:firstFBO->texture BlendType:blendType] )
                    NSLog(@"fail to blendFilter renderBlendModelWithForegroundTexture...");
            }
            else
                [self renderUsingForegroundTexture:assetFBO->texture andBackgroundTexture:firstFBO->texture];
            
            glBindFramebuffer(GL_FRAMEBUFFER, 0);
            
        }
        collageCount++;
    }

    //6.绘制最后的画中画结果显示到屏幕
    glBindFramebuffer(GL_FRAMEBUFFER, self.offscreenBufferHandle);
    glViewport(0, 0, dstWidth, dstHeight);
    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(destTexture), 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        //        goto bail1;
    }

    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    if(collageCount == 0)
        texture = CVOpenGLESTextureGetName(sourceTexture);
    else if(collageCount %2 == 0)
        texture = secondFBO->texture;
    else
        texture = firstFBO->texture;
    //渲染最终画面
    [self simpleRenderWidthTexture:texture];

    
    glBindTexture(CVOpenGLESTextureGetTarget(sourceTexture), 0);
    CFRelease(sourceTexture);
    
    
    glBindTexture(CVOpenGLESTextureGetTarget(destTexture), 0);
    glFlush();
bail1:
    if (destTexture) {
        CFRelease(destTexture);
    }
    CVOpenGLESTextureCacheFlush(self.videoTextureCache, 0);
    //
    [EAGLContext setCurrentContext:nil];
    
    return false;
}


- (int) renderCustomPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer
                          scene:(RDScene *)scene
                        request:(AVAsynchronousVideoCompositionRequest *)request
{
    
//    CFAbsoluteTime start = CACurrentMediaTime();
    CVOpenGLESTextureRef destTexture = 0;
    int result_statu = 1;
    

    
    float tweenFactor = factorForTimeInRange(request.compositionTime, scene.fixedTimeRange);
    
    //20180720 wuxiaoxia 简影示例中，媒体视频使用动画(VVAssetAnimatePosition)，且设置顶点时，当前时间会超前一帧
    float currentTime =  tweenFactor * CMTimeGetSeconds(scene.fixedTimeRange.duration) - 1/_fps;
    if (currentTime < 0) {
        currentTime = 0.0;
    }
    
//    NSLog(@"currentTime:%f", currentTime);
    displayTime = CMTimeGetSeconds(request.compositionTime);
//        NSLog(@"displayTime:%f ",displayTime);
    
    [EAGLContext setCurrentContext:self.currentContext];
    
    //如果媒体有设置美颜，处理美颜效果 - 磨皮/亮肤/红润
    for(int i = 0;i<scene.vvAsset.count;i++){
        VVAsset* asset = scene.vvAsset[i];
        //如果媒体有设置美颜，直接绘制到临时纹理，纹理大小与输出分辨率大小相同
        if ([self processAssetBeautifulAttribute:asset TimeRange:scene.fixedTimeRange request:request Index:i] < 1)
            return 0;
        
    }

    //如果媒体有设置模糊强度，处理模糊效果 - 背景+边框模糊
    for(int i = 0;i<scene.vvAsset.count;i++){
        VVAsset* asset = scene.vvAsset[i];
        //如果媒体有设置模糊强度，直接绘制到临时纹理，纹理大小与输出分辨率大小相同
   
        if (asset.blurIntensity && [self processAssetBorderBlurAttribute:asset scene:scene request:request Index:i] < 1)
            return 0;
    }
    
    //如果有设置场景背景图片或者视频模糊效果 - 整体模糊
    if(scene.backgroundAsset && scene.backgroundAsset.blurIntensity)
        [self processAssetBlurAttributeScence:scene Asset:scene.backgroundAsset request:request Index:-1];
    else if(scene.backgroundAsset)
        [self processAssetToFrameBuferObjectWithScene:scene Asset:scene.backgroundAsset request:request Index:-1];
    

   
    //将媒体属性绘制到对应的FBO,旋转、缩放、裁剪归一化处理
    for(int i = 0;i<scene.vvAsset.count;i++)
    {
        VVAsset* asset = scene.vvAsset[i];
        if([self processAssetToFrameBuferObjectWithScene:scene Asset:asset request:request Index:i] < 1)
            return 0;
    }
    

    //由于媒体存在旋转角度问题，如果媒体有设置自定义特效，需要先将媒体做归一化处理，再绘制自定义特效
    for(int i = 0;i<scene.vvAsset.count;i++)
    {
        VVAsset* asset = scene.vvAsset[i];

        //如果媒体有设置自定义滤镜，直接绘制到临时纹理，纹理大小媒体解码之后分辨率大小相同
        if(asset.customFilter && [self processAssetCustomFilterAttribute:asset request:request CurrentTime:currentTime Index:i] < 1)
            return 0;
    }
    
    //将媒体属性绘制到对应的FBO
    result_statu = [self renderAssetToFrameBuferObject:scene request:request];
    
    //渲染最终画面
    destTexture = [self customTextureForPixelBuffer:destinationPixelBuffer];
    glBindFramebuffer(GL_FRAMEBUFFER, self.offscreenBufferHandle);
    glViewport(0, 0, (int)CVPixelBufferGetWidth(destinationPixelBuffer), (int)CVPixelBufferGetHeight(destinationPixelBuffer));
    
//    int w = (int)CVPixelBufferGetWidth(destinationPixelBuffer);
//    int h = (int)CVPixelBufferGetHeight(destinationPixelBuffer);
    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(destTexture), 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        //        goto bail1;
    }
    
    glEnable(GL_BLEND);
    //    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        
    if (scene.backgroundColor) {
        const CGFloat *components = CGColorGetComponents(scene.backgroundColor.CGColor);
        glClearColor(components[0]*components[3],components[1]*components[3],components[2]*components[3], components[3]);
    }
    else if(_virtualVideoBgColor) {
        const CGFloat *components = CGColorGetComponents(_virtualVideoBgColor.CGColor);
    //               glClearColor(components[0],components[1],components[2], components[3]);
        glClearColor(components[0]*components[3],components[1]*components[3],components[2]*components[3], components[3]);
    //                NSLog(@"R:%f G:%f B:%f A:%f", components[0],components[1],components[2],components[3] );
    }else {
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    }
        
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    // 渲染最终画面
    [self simpleRenderWidthTexture:pDstFboList->texture];
    glBindTexture(CVOpenGLESTextureGetTarget(destTexture), 0);
    
    glFlush();
bail1:
    if (destTexture) {
        CFRelease(destTexture);
    }
    CVOpenGLESTextureCacheFlush(self.videoTextureCache, 0);
    //
    [EAGLContext setCurrentContext:nil];
    
//    CFAbsoluteTime end = CACurrentMediaTime();
//    export_time += end - start;
//    NSLog(@"renderCustomPixelBuffer time %f", export_time);
    return result_statu;
}
#if 0
NSString*  const kRDCustomTransitionVertexShader = SHADER_STRING
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

NSString*  const kRDCustomTransitionFragmentShader = SHADER_STRING
(
 
 precision highp float;
 
 varying vec2 textureCoordinate;
 uniform sampler2D from;
 uniform sampler2D to;
 uniform float progress;
 
 uniform sampler2D displacementMap;
 
 float strength = 0.5;
 
 vec4 getFromColor(vec2 p)
 {
    return texture2D(from, p );
}
 vec4 getToColor(vec2 p)
 {
    return texture2D(to, p );
}
 
 void main()
 {
    
    vec2 uv = textureCoordinate;
    float displacement = texture2D(displacementMap, uv).r * strength;
    
    vec2 uvFrom = vec2(uv.x + progress * displacement, uv.y);
    vec2 uvTo = vec2(uv.x - (1.0 - progress) * displacement, uv.y);
    
    gl_FragColor =  mix(getFromColor(uvFrom),getToColor(uvTo),progress);
}


 
 );
#else


#endif



- (void) renderCustomTransitionPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer
               usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer
                 andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer
                        andCustomTransiton:(RDCustomTransition*)transition
                            forTweenFactor:(float)tween
{
    
    
#if 1
    
    if(!transition)
        return;
    
#else
    transition = nullptr;
    if(!transition)
    {
        transition = [[RDCustomTransition alloc] init];
        transition.vert = kRDCustomTransitionVertexShader;
        transition.frag = kRDCustomTransitionFragmentShader;
        
    }
#endif
    
    
    [EAGLContext setCurrentContext:self.currentContext];
    
    CVOpenGLESTextureRef destTexture = [self customTextureForPixelBuffer:destinationPixelBuffer];
    glBindFramebuffer(GL_FRAMEBUFFER, self.offscreenBufferHandle);
    glViewport(0, 0, (int)CVPixelBufferGetWidth(destinationPixelBuffer), (int)CVPixelBufferGetHeight(destinationPixelBuffer));
    
    
    
    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(destTexture), 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        goto bailMask;
    }
    
    
    {
        CVOpenGLESTextureRef foregroundTexture = [self customTextureForPixelBuffer:foregroundPixelBuffer];
        if (!foregroundTexture) {return;}
        CVOpenGLESTextureRef backgroundTexture = [self customTextureForPixelBuffer:backgroundPixelBuffer];
        if (!backgroundTexture) {return;}
        // Y planes of foreground and background frame are used to render the Y plane of the destination frame
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(CVOpenGLESTextureGetTarget(foregroundTexture), CVOpenGLESTextureGetName(foregroundTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(CVOpenGLESTextureGetTarget(backgroundTexture), CVOpenGLESTextureGetName(backgroundTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        struct SHADER_TRANSTION_TEXTURE_SAMPLER2D_LIST* pTextureList = [transition pTextureSamplerList];
        
        while(pTextureList)
        {
            if(pTextureList && pTextureList->type == RDSample2DBufferTexture)
            {
                //添加素材
                if(pTextureList->path.length == 0)
                    NSLog(@"error : texture url is null!");
                else
                {
                    if (!pTextureList->texture)
                    {
                        pTextureList->texture = [self textureFromUIImage:[UIImage imageWithContentsOfFile:pTextureList->path]];//ok
                        //                    pTextureList->texture = [self textureFromUIImage:[UIImage imageNamed:pTextureList->path]];//error
                        glActiveTexture(GL_TEXTURE1);
                        glBindTexture(GL_TEXTURE_2D, pTextureList->texture);
                        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                        
                        if( RDTextureWarpModeRepeat == pTextureList->warpMode)
                        {
                            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
                            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
                        }
                        else
                        {
                            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                        }
                    }
                }
            }
            pTextureList = pTextureList->next;
        }
        
        
        
        //绘制转场
        [transition renderCustromTransitionFrom:CVOpenGLESTextureGetName(foregroundTexture) To:CVOpenGLESTextureGetName(backgroundTexture) Progress:tween FrameWidth:(int)CVPixelBufferGetWidth(destinationPixelBuffer) FrameHeight:(int)CVPixelBufferGetHeight(destinationPixelBuffer)];
        
        CFRelease(foregroundTexture);
        CFRelease(backgroundTexture);
        
        
    }
    glFlush();
bailMask:
    if (destTexture) {
        CFRelease(destTexture);
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(self.videoTextureCache, 0);
    //
    [EAGLContext setCurrentContext:nil];
    
}


- (void) renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer
usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer
 andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer
          andMaskImagePath:(NSURL *) path
            forTweenFactor:(float)tween
{
    [EAGLContext setCurrentContext:self.currentContext];
    
    
    CVOpenGLESTextureRef destTexture = [self customTextureForPixelBuffer:destinationPixelBuffer];
    glBindFramebuffer(GL_FRAMEBUFFER, self.offscreenBufferHandle);
    glViewport(0, 0, (int)CVPixelBufferGetWidth(destinationPixelBuffer), (int)CVPixelBufferGetHeight(destinationPixelBuffer));
    
    
    
    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(destTexture), 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        goto bailMask;
    }
    
    
    {
        CVOpenGLESTextureRef foregroundTexture = [self customTextureForPixelBuffer:foregroundPixelBuffer];
        if (!foregroundTexture) {return;}
        CVOpenGLESTextureRef backgroundTexture = [self customTextureForPixelBuffer:backgroundPixelBuffer];
        if (!backgroundTexture) {return;}
        // Y planes of foreground and background frame are used to render the Y plane of the destination frame
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(CVOpenGLESTextureGetTarget(foregroundTexture), CVOpenGLESTextureGetName(foregroundTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(CVOpenGLESTextureGetTarget(backgroundTexture), CVOpenGLESTextureGetName(backgroundTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        
        RDImage* imageBuffer = [self fetchImageFrameBuffer:path];
        GLuint imageTexture = imageBuffer.texture;
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, imageTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        
        
        
        CFRelease(foregroundTexture);
        CFRelease(backgroundTexture);
        
        
        glUseProgram(self.maskProgram);
        
        RDMatrixLoadIdentity(&_modelViewMatrix);
        
        
        RDMatrixLoadIdentity(&_projectionMatrix);
        
        
        
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        
        
        
        glUniformMatrix4fv(maskTransformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
        glUniformMatrix4fv(maskProjectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
        
        glUniform1i(maskInputTextureUniform, 0);
        glUniform1i(maskInputTextureUniform2, 1);
        glUniform1i(maskInputTextureUniform3, 2);
        glUniform1f(maskFactorUniform, tween);
#ifdef USE_MULTITEXTURE
        glUniform4f(glGetUniformLocation(_maskProgram, "coordOffset[0]"), 0.0, 0.0, 1.0, 1.0);
#endif
        GLfloat quadVertexData1 [] = {
            -1.0, 1.0,
            1.0, 1.0,
            -1.0, -1.0,
            1.0, -1.0,
        };
        
        GLfloat quadTextureData1 [] = { //纹理坐标
            0.0f, 1.0f,
            1.0f, 1.0f,
            0.0f, 0.0f,
            1.0f, 0.0f,
        };
        
        glVertexAttribPointer(maskPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData1);
        glEnableVertexAttribArray(maskPositionAttribute);
        
        glVertexAttribPointer(maskTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData1);
        glEnableVertexAttribArray(maskTextureCoordinateAttribute);
        
#ifdef USE_MULTITEXTURE
        
        GLfloat offset[1] = {0.3};
        glVertexAttribPointer(Attrib(offset), 1, GL_FLOAT, GL_FALSE, 0, offset);
        glVertexAttribDivisorEXT(Attrib(offset), 1);
        glEnableVertexAttribArray(Attrib(offset));
        glDrawArraysInstancedEXT(GL_TRIANGLE_STRIP, 0, 4, 1);
#else
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
#endif
        
        
        
    }
    glFlush();
bailMask:
    if (destTexture) {
        CFRelease(destTexture);
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(self.videoTextureCache, 0);
    //
    [EAGLContext setCurrentContext:nil];
    
}

CGRect firstTextureRect = {0};
CGRect secondTextureRect = {0};


-(float*) getVertCoodinteFromWidth:(float)width Height:(float)height Index:(int) index VertCoordinate:(float*)vertCoodinte GridCoordinate:(float*)gridCoodinte
{
    //    float vertCoodinte[8] = {0};
    float ratio = width/height;
    float w = 0;
    float h = 0;
    int row = index/4;
    int col = index%4;
    float sumH = 0;
    float sumW = 0;
    
    if(ratio>1.0)
    {
        //        h = 1.0/3.0;
        //        w = h*ratio;
        
        w = 1.0/4.0;
        h = w/ratio;
    }
    else
    {
        //        w = 1.0/3.0;
        //        h = w/ratio;
        
        h = 1.0/4.0;
        w = h*ratio;
    }
    
    sumH = 3*h;
    sumW = 4*w;
    
    vertCoodinte[0] = col*w - (sumW - 1.0);
    vertCoodinte[1] = row*h - (sumH - 1.0);
    vertCoodinte[2] = vertCoodinte[0]+w;
    vertCoodinte[3] = vertCoodinte[1];
    vertCoodinte[4] = vertCoodinte[0];
    vertCoodinte[5] = vertCoodinte[1]+h;
    vertCoodinte[6] = vertCoodinte[0]+w;
    vertCoodinte[7] = vertCoodinte[1]+h;
    
    if(0 == index)
    {
        gridCoodinte[0] = vertCoodinte[0];
        gridCoodinte[1] = vertCoodinte[1];
        
        gridCoodinte[2] = vertCoodinte[2];
        gridCoodinte[3] = vertCoodinte[3];
        
        gridCoodinte[4] = vertCoodinte[4];
        gridCoodinte[5] = vertCoodinte[5];
        
        gridCoodinte[6] = vertCoodinte[6];
        gridCoodinte[7] = vertCoodinte[7];
    }
    else
    {
        gridCoodinte[0] = (gridCoodinte[0]<=vertCoodinte[0])?gridCoodinte[0]:vertCoodinte[0];
        gridCoodinte[1] = (gridCoodinte[1]<=vertCoodinte[1])?gridCoodinte[1]:vertCoodinte[1];
        
        gridCoodinte[2] = (gridCoodinte[2]>=vertCoodinte[2])?gridCoodinte[2]:vertCoodinte[2];
        gridCoodinte[3] = (gridCoodinte[3]<=vertCoodinte[3])?gridCoodinte[3]:vertCoodinte[3];
        
        gridCoodinte[4] = (gridCoodinte[4]<=vertCoodinte[4])?gridCoodinte[4]:vertCoodinte[4];
        gridCoodinte[5] = (gridCoodinte[5]>=vertCoodinte[5])?gridCoodinte[5]:vertCoodinte[5];
        
        gridCoodinte[6] = (gridCoodinte[6]>=vertCoodinte[6])?gridCoodinte[6]:vertCoodinte[6];
        gridCoodinte[7] = (gridCoodinte[7]>=vertCoodinte[7])?gridCoodinte[7]:vertCoodinte[7];
    }
    
    if (5 == index) {
        
        firstTextureRect.origin.x = vertCoodinte[0];
        firstTextureRect.origin.y = vertCoodinte[1];
        firstTextureRect.size.width = vertCoodinte[2] - vertCoodinte[0];
        firstTextureRect.size.height = vertCoodinte[5] - vertCoodinte[1];
    }
    if (6 == index) {
        
        secondTextureRect.origin.x = vertCoodinte[0];
        secondTextureRect.origin.y = vertCoodinte[1];
        secondTextureRect.size.width = vertCoodinte[2] - vertCoodinte[0];
        secondTextureRect.size.height = vertCoodinte[5] - vertCoodinte[1];
    }
    for(int i = 0;i<8;i++)
        printf(" i :%d  sumW :%f sumH :%f ratio :%f vertCoodinte[%d]:%f \n",i,sumW,sumH,ratio,i,vertCoodinte[i]);
    printf(" ============================ %d over \n",index+1);
    
    
    vertCoodinte[0] = (vertCoodinte[0] - 0.5)*2.0;
    vertCoodinte[1] = (vertCoodinte[1] - 0.5)*2.0;
    vertCoodinte[2] = (vertCoodinte[2] - 0.5)*2.0;
    vertCoodinte[3] = (vertCoodinte[3] - 0.5)*2.0;
    vertCoodinte[4] = (vertCoodinte[4] - 0.5)*2.0;
    vertCoodinte[5] = (vertCoodinte[5] - 0.5)*2.0;
    vertCoodinte[6] = (vertCoodinte[6] - 0.5)*2.0;
    vertCoodinte[7] = (vertCoodinte[7] - 0.5)*2.0;
    
    return vertCoodinte;
}



-(CGRect ) renderGridToFrameBufferObject:(int)width Height:(int)height Factor:(float)tween BackgroundTexture:(CVOpenGLESTextureRef)backgroundTexture ForegroundTexture:(CVOpenGLESTextureRef)foregroundTexture
{
    CGRect gridData = {0};
    GLfloat gridVertexData[8];
    
    if(!offscreenGridBufferHandle)
    {
        glGenFramebuffers(1, &offscreenGridBufferHandle);
        glBindFramebuffer(GL_FRAMEBUFFER, offscreenGridBufferHandle);
    }
    if(!offscreenGridTexture)
    {
        unsigned char* pImage = (unsigned char*)malloc(width*height*4);
        for (int i = 0; i<width*height; i++) {
            
            pImage[i*4] = 0x00;
            pImage[i*4+1] = 0x00;
            pImage[i*4+2] = 0x00;
            pImage[i*4+3] = 0xFF;
        }
        offscreenGridTexture = [self textureFromBufferObject:pImage Width:width Height:height];
        free(pImage);
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, offscreenGridBufferHandle);
    glViewport(0, 0, width, height);
    
    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, offscreenGridTexture, 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return gridData;
    }
    
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(self.simpleProgram);
    
    for (int i = 0; i < 12; i++) {
        RDMatrixLoadIdentity(&_modelViewMatrix);
        glUniformMatrix4fv(simpleTransformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
        
        RDMatrixLoadIdentity(&_projectionMatrix);
        glUniformMatrix4fv(simpleProjectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
        
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(CVOpenGLESTextureGetTarget(foregroundTexture), CVOpenGLESTextureGetName(foregroundTexture));
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(CVOpenGLESTextureGetTarget(backgroundTexture), CVOpenGLESTextureGetName(backgroundTexture));
        
        if(i%4<=1)
            glUniform1i(simpleInputTextureUniform, 0);
        else
            glUniform1i(simpleInputTextureUniform, 1);
        
        GLfloat quadVertexData1[8];
        [self getVertCoodinteFromWidth:width Height:height Index:i VertCoordinate:quadVertexData1 GridCoordinate:gridVertexData];
        
        
        NSLog(@"index:%d vertCoordinate[0]:%f vertCoordinate[1]:%f vertCoordinate[2]:%f vertCoordinate[3]:%f vertCoordinate[4]:%f vertCoordinate[5]:%f vertCoordinate[6]:%f vertCoordinate[7]:%f ",i,quadVertexData1[0],quadVertexData1[1],quadVertexData1[2],quadVertexData1[3],quadVertexData1[4],quadVertexData1[5],quadVertexData1[6],quadVertexData1[7]);
        
        
        GLfloat quadTextureData1 [] = { //纹理坐标
            
            0.0f, 0.0f,
            1.0f, 0.0f,
            0.0f, 1.0f,
            1.0f, 1.0f,
            
        };
        
        glVertexAttribPointer(simplePositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData1);
        glEnableVertexAttribArray(simplePositionAttribute);
        glVertexAttribPointer(simpleTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData1);
        glEnableVertexAttribArray(simpleTextureCoordinateAttribute);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        //glFlush();
        
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    
    
    
    gridData.origin.x = gridVertexData[0];
    gridData.origin.y = gridVertexData[1];
    gridData.size.width = gridVertexData[2] - gridVertexData[0];
    gridData.size.height = gridVertexData[5] - gridVertexData[1];
    
    //    quadTextureData1[0] = gridTextureData.origin.x;
    //    quadTextureData1[1] = gridTextureData.origin.y + gridTextureData.size.height;
    //
    //    quadTextureData1[2] = gridTextureData.origin.x + gridTextureData.size.width;
    //    quadTextureData1[3] = gridTextureData.origin.y + gridTextureData.size.height;
    //
    //    quadTextureData1[4] = gridTextureData.origin.x;
    //    quadTextureData1[5] = gridTextureData.origin.y;
    //
    //    quadTextureData1[6] = gridTextureData.origin.x + gridTextureData.size.width;
    //    quadTextureData1[7] = gridTextureData.origin.y;
    
    NSLog(@"tween:%f",tween);
    float quadTextureData1[8];
    if(tween <= 0.5)
    {
        float left_x = (firstTextureRect.origin.x - gridData.origin.x);
        float right_x = gridData.origin.x + gridData.size.width - firstTextureRect.origin.x - firstTextureRect.size.width;
        float top_y = firstTextureRect.origin.y - gridData.origin.y;
        float bottom_y = gridData.origin.y + gridData.size.height - firstTextureRect.origin.y - firstTextureRect.size.height;
        
        quadTextureData1[0] = firstTextureRect.origin.x - left_x*(tween/0.5);
        quadTextureData1[1] = firstTextureRect.origin.y + firstTextureRect.size.height + bottom_y*(tween/0.5);
        
        quadTextureData1[2] = firstTextureRect.origin.x + firstTextureRect.size.width + right_x*(tween/0.5);
        quadTextureData1[3] = firstTextureRect.origin.y + firstTextureRect.size.height + bottom_y*(tween/0.5);
        
        quadTextureData1[4] = firstTextureRect.origin.x - left_x*(tween/0.5);
        quadTextureData1[5] = firstTextureRect.origin.y - top_y*(tween/0.5);
        
        quadTextureData1[6] = firstTextureRect.origin.x + firstTextureRect.size.width + right_x*(tween/0.5);
        quadTextureData1[7] = firstTextureRect.origin.y - top_y*(tween/0.5);
    }
    else
    {
        float left_x = (secondTextureRect.origin.x - gridData.origin.x);
        float right_x = gridData.origin.x + gridData.size.width - secondTextureRect.origin.x - secondTextureRect.size.width;
        float top_y = secondTextureRect.origin.y - gridData.origin.y;
        float bottom_y = gridData.origin.y + gridData.size.height - secondTextureRect.origin.y - secondTextureRect.size.height;
        
        quadTextureData1[0] = gridData.origin.x + left_x*((tween-0.5)/0.5);
        quadTextureData1[1] = gridData.origin.y + gridData.size.height - bottom_y*((tween-0.5)/0.5);
        
        quadTextureData1[2] = gridData.origin.x + gridData.size.width - right_x*((tween-0.5)/0.5);
        quadTextureData1[3] = gridData.origin.y + gridData.size.height - bottom_y*((tween-0.5)/0.5);
        
        quadTextureData1[4] = gridData.origin.x + left_x*((tween-0.5)/0.5);
        quadTextureData1[5] = gridData.origin.y + top_y*((tween-0.5)/0.5);
        
        quadTextureData1[6] = gridData.origin.x + gridData.size.width - right_x*((tween-0.5)/0.5);
        quadTextureData1[7] = gridData.origin.y + top_y*((tween-0.5)/0.5);
    }
    
    
    gridData.origin.x = quadTextureData1[0];
    gridData.origin.y = quadTextureData1[1];
    gridData.size.width = quadTextureData1[2] - quadTextureData1[0];
    gridData.size.height = quadTextureData1[5] - quadTextureData1[1];
    return gridData;
}
- (void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer usingSourceData:(GLubyte*)foregroundPixelBuffer andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer
{
    [EAGLContext setCurrentContext:self.currentContext];
    
    CVOpenGLESTextureRef destTexture = [self customTextureForPixelBuffer:destinationPixelBuffer];
    
    GLuint foregroundTexture = [self textureFromBufferObject:foregroundPixelBuffer Width:(int)CVPixelBufferGetWidth(destinationPixelBuffer) Height:(int)CVPixelBufferGetHeight(destinationPixelBuffer)];
    
    CVOpenGLESTextureRef backgroundTexture = [self customTextureForPixelBuffer:backgroundPixelBuffer];
    // Y planes of foreground and background frame are used to render the Y plane of the destination frame
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, foregroundTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(CVOpenGLESTextureGetTarget(backgroundTexture), CVOpenGLESTextureGetName(backgroundTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    
    glBindFramebuffer(GL_FRAMEBUFFER, self.offscreenBufferHandle);
    glViewport(0, 0, (int)CVPixelBufferGetWidth(destinationPixelBuffer), (int)CVPixelBufferGetHeight(destinationPixelBuffer));
    
    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(destTexture), 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        goto bail2;
    }
    
    {
        
        glEnable(GL_BLEND);
        //    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);//20180730 fix bug: maskMV周围会有一条黑线
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        
        
        GLfloat quadVertexData1 [] = {
            -1.0, 1.0,
            1.0, 1.0,
            -1.0, -1.0,
            1.0, -1.0,
        };
        
        GLfloat quadTextureData1 [] = { //纹理坐标
            0.0f, 1.0f,
            1.0f, 1.0f,
            0.0f, 0.0f,
            1.0f, 0.0f,
        };
        
        
        glUseProgram(self.simpleProgram);
        
        glUniform1i(simpleInputTextureUniform, 0);
        
        glVertexAttribPointer(simplePositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData1);
        glEnableVertexAttribArray(simplePositionAttribute);
        
        glVertexAttribPointer(simpleTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData1);
        glEnableVertexAttribArray(simpleTextureCoordinateAttribute);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        
        
        
        glUniform1i(simpleInputTextureUniform, 1);
        
        glVertexAttribPointer(simplePositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData1);
        glEnableVertexAttribArray(simplePositionAttribute);
        
        glVertexAttribPointer(simpleTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData1);
        glEnableVertexAttribArray(simpleTextureCoordinateAttribute);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        
        glFlush();
        
        // 其他效果
    }
    
bail2:
    if (foregroundTexture) {
        glDeleteTextures(1, &foregroundTexture);
    }
    if (backgroundTexture) {
        CFRelease(backgroundTexture);
    }
    if (destTexture) {
        CFRelease(destTexture);
    }
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(self.videoTextureCache, 0);
    //
    [EAGLContext setCurrentContext:nil];
    
    
}

- (void)renderUsingForegroundTexture:(GLuint)foregroundTexture andBackgroundTexture:(GLuint)backgroundTexture
{

    GLfloat vertices [] = {
        -1.0, 1.0,
        1.0, 1.0,
        -1.0, -1.0,
        1.0, -1.0,
    };
    
    GLfloat textureCoordinates [] = { //纹理坐标
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    glUseProgram(self.simpleProgram);
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
//    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    //1.先绘制原始画面
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, backgroundTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glUniform1i(simpleInputTextureUniform, 0);
    
    RDMatrixLoadIdentity(&_modelViewMatrix);
    glUniformMatrix4fv(simpleTransformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
    
    RDMatrixLoadIdentity(&_projectionMatrix);
    glUniformMatrix4fv(simpleProjectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
    
    glVertexAttribPointer(simplePositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glEnableVertexAttribArray(simplePositionAttribute);
    glVertexAttribPointer(simpleTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    glEnableVertexAttribArray(simpleTextureCoordinateAttribute);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, foregroundTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glUniform1i(simpleInputTextureUniform, 1);
    
    RDMatrixLoadIdentity(&_modelViewMatrix);
    glUniformMatrix4fv(simpleTransformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
    
    RDMatrixLoadIdentity(&_projectionMatrix);
    glUniformMatrix4fv(simpleProjectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
    
    glVertexAttribPointer(simplePositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glEnableVertexAttribArray(simplePositionAttribute);
    glVertexAttribPointer(simpleTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    glEnableVertexAttribArray(simpleTextureCoordinateAttribute);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDisableVertexAttribArray(simplePositionAttribute);
    glDisableVertexAttribArray(simpleTextureCoordinateAttribute);

 
}

- (void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer forTweenFactor:(float)tween type:(unsigned int) type
{
    
    CGRect gridTextureData;
    
    [EAGLContext setCurrentContext:self.currentContext];
    
    CVOpenGLESTextureRef destTexture = [self customTextureForPixelBuffer:destinationPixelBuffer];
    
    CVOpenGLESTextureRef foregroundTexture = [self customTextureForPixelBuffer:foregroundPixelBuffer];
    
    CVOpenGLESTextureRef backgroundTexture = [self customTextureForPixelBuffer:backgroundPixelBuffer];
    // Y planes of foreground and background frame are used to render the Y plane of the destination frame
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(CVOpenGLESTextureGetTarget(foregroundTexture), CVOpenGLESTextureGetName(foregroundTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(CVOpenGLESTextureGetTarget(backgroundTexture), CVOpenGLESTextureGetName(backgroundTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    if(type == 12)
        gridTextureData = [self renderGridToFrameBufferObject:(int)CVPixelBufferGetWidth(destinationPixelBuffer) Height:(int)CVPixelBufferGetHeight(destinationPixelBuffer) Factor:tween BackgroundTexture:backgroundTexture ForegroundTexture:foregroundTexture];
    
    glBindFramebuffer(GL_FRAMEBUFFER, self.offscreenBufferHandle);
    glViewport(0, 0, (int)CVPixelBufferGetWidth(destinationPixelBuffer), (int)CVPixelBufferGetHeight(destinationPixelBuffer));
    
    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(destTexture), 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        goto bail2;
    }
    
    
    {
        
        int transitionType = type;
        if (transitionType <= 4) {
#ifdef USE_MULTITEXTURE
            
            glUseProgram(self.multiProgram);
            
            glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT);
            
            for (int i = 0; i<2; i++) {
                RDMatrixLoadIdentity(&_modelViewMatrix);
                
                glUniformMatrix4fv(Uniform(renderTransform , i), 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
                RDMatrixLoadIdentity(&_projectionMatrix);
                
                float lr = (i==0?0.0:2.0);
                
                if (transitionType == 1) {
                    RDMatrixTranslate(&_projectionMatrix, lr - tween*2, 0, 0);
                }else if (transitionType == 2){
                    RDMatrixTranslate(&_projectionMatrix, -1.0 *lr + tween*2, 0, 0);
                }else if (transitionType == 3) {
                    RDMatrixTranslate(&_projectionMatrix, 0, lr - tween*2, 0);
                }else if (transitionType == 4){
                    RDMatrixTranslate(&_projectionMatrix, 0, -1.0 * lr + tween*2, 0);
                }
                
                glUniformMatrix4fv(Uniform(projection , i), 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
                glUniform4f(Uniform(coordOffset , i), 0.0, 0.0, 1.0, 1.0);
                glUniform1i(Uniform(inputImageTexture , i), i);
                glUniform3f(Uniform(filter , i), 0.0, 0.0, 1.0);
            }
            GLfloat VertexData [] = {
                -1.0, 1.0,
                1.0, 1.0,
                -1.0, -1.0,
                1.0, -1.0,
            };
            
            
            
            GLfloat TextureData [] = { //纹理坐标
                0.0f, 1.0f,
                1.0f, 1.0f,
                0.0f, 0.0f,
                1.0f, 0.0f,
            };
            
            glVertexAttribPointer(Attrib(position), 2, GL_FLOAT, 0, 0, VertexData);
            glEnableVertexAttribArray(Attrib(position));
            
            glVertexAttribPointer(Attrib(inputTextureCoordinate), 2, GL_FLOAT, 0, 0, TextureData);
            glEnableVertexAttribArray(Attrib(inputTextureCoordinate));
            
            //        GLfloat* offset = alloca(sizeof(GLfloat) * 2);
            //
            //        for (int i = 0; i<2; i++) {
            //            offset[i] = i*1.0 + 0.3;
            //        }
            
            GLfloat offset[2] = {0.3,1.3};
            
            glVertexAttribPointer(Attrib(offset), 1, GL_FLOAT, GL_FALSE, 0, offset);
            
            glVertexAttribDivisorEXT(Attrib(offset), 1);
            glEnableVertexAttribArray(Attrib(offset));
            
            
            glDrawArraysInstancedEXT(GL_TRIANGLE_STRIP, 0, 4, 2);
            
#else
            glUseProgram(self.transProgram);
            //            [program use];
            // Set the render transform
            
            
            
            glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT);
            
            RDMatrixLoadIdentity(&_modelViewMatrix);
            
            glUniformMatrix4fv(transTransformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
            
            {
                
                GLfloat quadVertexData1 [] = {
                    -1.0, 1.0,
                    1.0, 1.0,
                    -1.0, -1.0,
                    1.0, -1.0,
                };
                
                
                GLfloat quadTextureData1 [] = { //纹理坐标
                    0.0f, 1.0f,
                    1.0f, 1.0f,
                    0.0f, 0.0f,
                    1.0f, 0.0f,
                };
                
                
                RDMatrixLoadIdentity(&_projectionMatrix);
                
                if (transitionType == 1) {
                    RDMatrixTranslate(&_projectionMatrix, -tween*2, 0, 0);
                }else if (transitionType == 2){
                    RDMatrixTranslate(&_projectionMatrix, tween*2, 0, 0);
                }else if (transitionType == 3) {
                    RDMatrixTranslate(&_projectionMatrix, 0, -tween*2, 0);
                }else if (transitionType == 4){
                    RDMatrixTranslate(&_projectionMatrix, 0, tween*2, 0);
                }
                
                
                glUniformMatrix4fv(transProjectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
                
                glUniform1i(transInputTextureUniform, 0);
                
                glVertexAttribPointer(transPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData1);
                glEnableVertexAttribArray(transPositionAttribute);
                
                glVertexAttribPointer(transTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData1);
                glEnableVertexAttribArray(transTextureCoordinateAttribute);
                
                // Draw the foreground frame
                glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
                
                
            }
            
            {
                
                GLfloat quadVertexData2 [] = {
                    -1.0, 1.0,
                    1.0, 1.0,
                    -1.0, -1.0,
                    1.0, -1.0,
                };
                GLfloat quadTextureData2 [] = { //纹理坐标
                    0.0f, 1.0f,
                    1.0f, 1.0f,
                    0.0f, 0.0f,
                    1.0f, 0.0f,
                };
                RDMatrixLoadIdentity(&_projectionMatrix);
                
                if (transitionType == 1) {//左推
                    
                    RDMatrixTranslate(&_projectionMatrix, 2.0-tween*2, 0, 0);
                }else if (transitionType == 2){ // 右推
                    
                    RDMatrixTranslate(&_projectionMatrix, -2.0+tween*2, 0, 0);
                    
                }else if (transitionType == 3) {// 上推
                    
                    RDMatrixTranslate(&_projectionMatrix, 0, 2.0-tween*2, 0);
                }else if (transitionType == 4){ // 下推
                    
                    RDMatrixTranslate(&_projectionMatrix, 0, -2.0+tween*2, 0);
                    
                }
                
                
                
                glUniformMatrix4fv(transProjectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
                
                glUniform1i(transInputTextureUniform, 1);
                
                
                glVertexAttribPointer(transPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData2);
                glEnableVertexAttribArray(transPositionAttribute);
                
                glVertexAttribPointer(transTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData2);
                glEnableVertexAttribArray(transTextureCoordinateAttribute);
                
                
                // Draw the background frame
                glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            }
            
#endif
            
        }
        if (transitionType == 5 || transitionType == 6 || transitionType == 7 ) { // 淡入
            glUseProgram(self.blendProgram);
            
            
            glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT);
            
            
            
            
            RDMatrixLoadIdentity(&_modelViewMatrix);
            glUniformMatrix4fv(blendTransformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
            
            
            RDMatrixLoadIdentity(&_projectionMatrix);
            glUniformMatrix4fv(blendProjectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
            
#ifdef USE_MULTITEXTURE
            glUniform4f(glGetUniformLocation(_blendProgram, "coordOffset[0]"), 0.0, 0.0, 1.0, 1.0);
#endif
            
            glUniform1i(blendInputTextureUniform, 0);
            glUniform1i(blendInputTextureUniform2, 1);
            
            
            glUniform4f(blendColorUniform, 1.0, 1.0, 1.0, 1.0);
            
            
            if (transitionType == 5) {
                glUniform1f(blendBrightnessUniform, 0.0);
                glUniform1f(blendFactorUniform, tween);
                
            }else if (transitionType == 6){
                glUniform1f(blendBrightnessUniform, 2.0*(fabs(tween-0.5)-0.5));
                glUniform1f(blendFactorUniform, tween>0.5?1.0:0.0);
                
                
            }else if(transitionType == 7){
                glUniform1f(blendBrightnessUniform, 2.0*(0.5-fabs(tween-0.5)));
                glUniform1f(blendFactorUniform, tween>0.5?1.0:0.0);
                
                
            }
            
            GLfloat quadVertexData1 [] = {
                -1.0, 1.0,
                1.0, 1.0,
                -1.0, -1.0,
                1.0, -1.0,
            };
            
            GLfloat quadTextureData1 [] = { //纹理坐标
                0.0f, 1.0f,
                1.0f, 1.0f,
                0.0f, 0.0f,
                1.0f, 0.0f,
            };
            
            glVertexAttribPointer(blendPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData1);
            glEnableVertexAttribArray(blendPositionAttribute);
            
            glVertexAttribPointer(blendTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData1);
            glEnableVertexAttribArray(blendTextureCoordinateAttribute);
            
            // Draw the foreground frame
#ifdef USE_MULTITEXTURE
            
            GLfloat offset[1] = {0.3};
            
            glVertexAttribPointer(Attrib(offset), 1, GL_FLOAT, GL_FALSE, 0, offset);
            
            glVertexAttribDivisorEXT(Attrib(offset), 1);
            glEnableVertexAttribArray(Attrib(offset));
            
            
            glDrawArraysInstancedEXT(GL_TRIANGLE_STRIP, 0, 4, 1);
#else
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
#endif
        }
        if (transitionType == 9 ) { // 闪白-黑白/反色-反色/黑白-黑白
            glUseProgram(self.invertProgram);
            
            
            
            glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT);
            
            
            
            
            RDMatrixLoadIdentity(&_modelViewMatrix);
            glUniformMatrix4fv(invertTransformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
            
            
            RDMatrixLoadIdentity(&_projectionMatrix);
            glUniformMatrix4fv(invertProjectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
            
#ifdef USE_MULTITEXTURE
            glUniform4f(glGetUniformLocation(_invertProgram, "coordOffset[0]"), 0.0, 0.0, 1.0, 1.0);
#endif
            
            glUniform1i(invertInputTextureUniform, 0);
            glUniform1i(invertInputTextureUniform2, 1);
            
            
            glUniform4f(invertColorUniform, 1.0, 1.0, 1.0, 1.0);
            
            glUniform1f(invertBrightnessUniform, 2.0*(0.5-fabs(tween-0.5)));
            glUniform1f(invertFactorUniform, tween);
            
            GLfloat quadVertexData1 [] = {
                -1.0, 1.0,
                1.0, 1.0,
                -1.0, -1.0,
                1.0, -1.0,
            };
            
            GLfloat quadTextureData1 [] = { //纹理坐标
                0.0f, 1.0f,
                1.0f, 1.0f,
                0.0f, 0.0f,
                1.0f, 0.0f,
            };
            
            glVertexAttribPointer(invertPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData1);
            glEnableVertexAttribArray(invertPositionAttribute);
            
            glVertexAttribPointer(invertTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData1);
            glEnableVertexAttribArray(invertTextureCoordinateAttribute);
            
            // Draw the foreground frame
#ifdef USE_MULTITEXTURE
            
            GLfloat offset[1] = {0.3};
            
            glVertexAttribPointer(Attrib(offset), 1, GL_FLOAT, GL_FALSE, 0, offset);
            
            glVertexAttribDivisorEXT(Attrib(offset), 1);
            glEnableVertexAttribArray(Attrib(offset));
            
            
            glDrawArraysInstancedEXT(GL_TRIANGLE_STRIP, 0, 4, 1);
#else
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
#endif
        }
        if (transitionType == 10 ) { // //闪白-中间白色/上下黑白-中间白色/上下原图-原图
            glUseProgram(self.grayProgram);
            
            
            
            glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT);
            
            
            
            
            RDMatrixLoadIdentity(&_modelViewMatrix);
            glUniformMatrix4fv(grayTransformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
            
            
            RDMatrixLoadIdentity(&_projectionMatrix);
            glUniformMatrix4fv(grayProjectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
            
#ifdef USE_MULTITEXTURE
            glUniform4f(glGetUniformLocation(_grayProgram, "coordOffset[0]"), 0.0, 0.0, 1.0, 1.0);
#endif
            
            glUniform1i(grayInputTextureUniform, 0);
            glUniform1i(grayInputTextureUniform2, 1);
            
            
            glUniform4f(grayColorUniform, 1.0, 1.0, 1.0, 1.0);
            
            glUniform1f(grayBrightnessUniform, 2.0*(0.5-fabs(tween-0.5)));
            glUniform1f(grayFactorUniform, tween);
            
            GLfloat quadVertexData1 [] = {
                -0.8, 0.8,
                0.8, 0.8,
                -0.8, -0.8,
                0.8, -0.8,
            };
            
            GLfloat quadTextureData1 [] = { //纹理坐标
                0.0f, 1.0f,
                1.0f, 1.0f,
                0.0f, 0.0f,
                1.0f, 0.0f,
            };
            
            glVertexAttribPointer(grayPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData1);
            glEnableVertexAttribArray(grayPositionAttribute);
            
            glVertexAttribPointer(grayTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData1);
            glEnableVertexAttribArray(grayTextureCoordinateAttribute);
            
            // Draw the foreground frame
#ifdef USE_MULTITEXTURE
            
            GLfloat offset[1] = {0.3};
            
            glVertexAttribPointer(Attrib(offset), 1, GL_FLOAT, GL_FALSE, 0, offset);
            
            glVertexAttribDivisorEXT(Attrib(offset), 1);
            glEnableVertexAttribArray(Attrib(offset));
            
            
            glDrawArraysInstancedEXT(GL_TRIANGLE_STRIP, 0, 4, 1);
#else
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
#endif
        }
        if (transitionType == 11 ) { //鱼眼
            glUseProgram(self.bulgeDistortionProgram);
            
            glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT);
            
            RDMatrixLoadIdentity(&_modelViewMatrix);
            glUniformMatrix4fv(bulgeDistortionTransformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
            
            
            RDMatrixLoadIdentity(&_projectionMatrix);
            glUniformMatrix4fv(bulgeDistortionProjectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
            
#ifdef USE_MULTITEXTURE
            glUniform4f(glGetUniformLocation(_bulgeDistortionProgram, "coordOffset[0]"), 0.0, 0.0, 1.0, 1.0);
#endif
            
            glUniform1i(bulgeDistortionInputTextureUniform, 0);
            glUniform1i(bulgeDistortionInputTextureUniform2, 1);
            
            float fWidth = CVPixelBufferGetWidth(backgroundPixelBuffer);
            float fHeight = CVPixelBufferGetHeight(backgroundPixelBuffer);
            glUniform1f(bulgeDistortionAspectRatioUniform, fWidth/fHeight);
            
            glUniform4f(bulgeDistortionColorUniform, 1.0, 1.0, 1.0, 1.0);
            
            glUniform1f(bulgeDistortionBrightnessUniform, 2.0*(0.5-fabs(tween-0.5)));
            glUniform1f(bulgeDistortionFactorUniform, tween);
            
            GLfloat quadVertexData1 [] = {
                -1.0, 1.0,
                1.0, 1.0,
                -1.0, -1.0,
                1.0, -1.0,
            };
            
            GLfloat quadTextureData1 [] = { //纹理坐标
                0.0f, 1.0f,
                1.0f, 1.0f,
                0.0f, 0.0f,
                1.0f, 0.0f,
            };
            
            glVertexAttribPointer(bulgeDistortionPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData1);
            glEnableVertexAttribArray(bulgeDistortionPositionAttribute);
            
            glVertexAttribPointer(bulgeDistortionTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData1);
            glEnableVertexAttribArray(bulgeDistortionTextureCoordinateAttribute);
            
            // Draw the foreground frame
#ifdef USE_MULTITEXTURE
            
            GLfloat offset[1] = {0.3};
            
            glVertexAttribPointer(Attrib(offset), 1, GL_FLOAT, GL_FALSE, 0, offset);
            
            glVertexAttribDivisorEXT(Attrib(offset), 1);
            glEnableVertexAttribArray(Attrib(offset));
            
            
            glDrawArraysInstancedEXT(GL_TRIANGLE_STRIP, 0, 4, 1);
#else
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
#endif
        }
        if(transitionType == 12)
        {
            
            
            glUseProgram(self.gridProgram);
            
            glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT);
            
            RDMatrixLoadIdentity(&_modelViewMatrix);
            glUniformMatrix4fv(gridTransformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
            
            
            RDMatrixLoadIdentity(&_projectionMatrix);
            glUniformMatrix4fv(gridProjectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
            
            
            glActiveTexture(GL_TEXTURE3);
            glBindTexture(GL_TEXTURE_2D, offscreenGridTexture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            glUniform1i(gridInputTextureUniform2, 3);
            
            //            glUniform1i(grayInputTextureUniform, 0);
            
            
            
            glUniform1f(gridFactorUniform, tween);
            
            GLfloat quadVertexData1 [] = {
                -1.0, 1.0,
                1.0, 1.0,
                -1.0, -1.0,
                1.0, -1.0,
            };
            
            
            GLfloat quadTextureData1 [] = { //纹理坐标
                //                0.0f, 1.0f,
                //                1.0f, 1.0f,
                //                0.0f, 0.0f,
                //                1.0f, 0.0f,
                
                0.0f, 1.0f,
                1.0f, 1.0f,
                0.0f, 0.6f,
                1.0f, 0.6f,
                
            };
            
            quadTextureData1[4] = gridTextureData.origin.x;
            quadTextureData1[5] = gridTextureData.origin.y + gridTextureData.size.height;
            
            quadTextureData1[6] = gridTextureData.origin.x + gridTextureData.size.width;
            quadTextureData1[7] = gridTextureData.origin.y + gridTextureData.size.height;
            
            quadTextureData1[0] = gridTextureData.origin.x;
            quadTextureData1[1] = gridTextureData.origin.y;
            
            quadTextureData1[2] = gridTextureData.origin.x + gridTextureData.size.width;
            quadTextureData1[3] = gridTextureData.origin.y;
            
            glVertexAttribPointer(gridPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData1);
            glEnableVertexAttribArray(gridPositionAttribute);
            
            glVertexAttribPointer(gridTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData1);
            glEnableVertexAttribArray(gridTextureCoordinateAttribute);
            
            // Draw  frame
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            
            
            
        }
        glFlush();
        
        // 其他效果
    }
    
bail2:
    if (foregroundTexture) {
        CFRelease(foregroundTexture);
    }
    if (backgroundTexture) {
        CFRelease(backgroundTexture);
    }
    if (destTexture) {
        CFRelease(destTexture);
    }
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(self.videoTextureCache, 0);
    //
    [EAGLContext setCurrentContext:nil];
    
    
    
    
}

- (void)setupOffscreenRenderContext
{
    
    //-- Create CVOpenGLESTextureCacheRef for optimal CVPixelBufferRef to GLES texture conversion.
    if (_videoTextureCache) {
        CFRelease(_videoTextureCache);
        _videoTextureCache = NULL;
    }
    
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _currentContext, NULL, &_videoTextureCache);
    if (err != noErr) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
    }
    
    glDisable(GL_DEPTH_TEST);
    
    
    glGenFramebuffers(1, &_offscreenMosaicBufferHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenMosaicBufferHandle);
    
    
    glGenFramebuffers(1, &_offscreenBufferHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenBufferHandle);
    
    
    
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    
    _program          = glCreateProgram();
    _blendProgram     = glCreateProgram();
    _maskProgram      = glCreateProgram();
    
    _multiProgram     = glCreateProgram();
    _transProgram     = glCreateProgram();
    _mvProgram        = glCreateProgram();
    _screenProgram    = glCreateProgram();
    _hardLightProgram = glCreateProgram();
    _chromaKeyProgram = glCreateProgram();
    _invertProgram    = glCreateProgram();
    _grayProgram      = glCreateProgram();
    _bulgeDistortionProgram = glCreateProgram();
    _gridProgram      = glCreateProgram();
    _simpleProgram    = glCreateProgram();
    _throughBlackColorProgram = glCreateProgram();
    _borderBlurProgram      = glCreateProgram();
    _blurProgram      = glCreateProgram();
    _beautyProgram = glCreateProgram();
    _chromaColorProgram = glCreateProgram();
    
    
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER source:kRDCompositorVertexShader]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    if (![self compileShader:&multiVertShader type:GL_VERTEX_SHADER source:kRDCompositorMultiTextureVertexShader]) {
        NSLog(@"failed to compile multi texture vertex shader");
        return NO;
    }
    
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER source:kRDCompositorFragmentShader]) {
        NSLog(@"Failed to compile cust fragment shader");
        return NO;
    }
    
    if (![self compileShader:&blendFragShader type:GL_FRAGMENT_SHADER source:kRDCompositorBlendFragmentShader]) {
        NSLog(@"Failed to compile blend fragment shader");
        return NO;
    }
    
    if (![self compileShader:&maskFragShader type:GL_FRAGMENT_SHADER source:kRDCompositorPassThroughMaskFragmentShader]) {
        NSLog(@"Failed to compile mask fragment shader");
        return NO;
    }
    
    if (![self compileShader:&multiFragShader type:GL_FRAGMENT_SHADER source:kRDCompositorMultiTextureFragmentShader]) {
        NSLog(@"failed to compile multi texture frag shader");
        return NO;
    }
    if (![self compileShader:&transFragShader type:GL_FRAGMENT_SHADER source:kRDCompositorTransFragmentShader]) {
        NSLog(@"failed to compile trans  frag shader");
        return NO;
    }
    if (![self compileShader:&mvVertShader type:GL_VERTEX_SHADER source:kRDVertexShaderString]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    if (![self compileShader:&mvFragShader type:GL_FRAGMENT_SHADER source:kRDMVFragmentShaderString]) {
        NSLog(@"failed to compile trans  frag shader");
        return NO;
    }
    if (![self compileShader:&screenFragShader type:GL_FRAGMENT_SHADER source:kRDScreenBlendFragmentShaderString]) {
        NSLog(@"failed to compile trans  frag shader");
        return NO;
    }
    if (![self compileShader:&hardLightFragShader type:GL_FRAGMENT_SHADER source:kRDHardLightBlendFragmentShaderString]) {
        NSLog(@"failed to compile trans  frag shader");
        return NO;
    }
    if (![self compileShader:&chromaKeyFragShader type:GL_FRAGMENT_SHADER source:kRDChromaKeyBlendFragmentShaderString]) {
        NSLog(@"failed to compile trans  frag shader");
        return NO;
    }
    if (![self compileShader:&invertFragShader type:GL_FRAGMENT_SHADER source:kRDCompositorInvertFragmentShader]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    if (![self compileShader:&grayFragShader type:GL_FRAGMENT_SHADER source:kRDCompositorGrayFragmentShader]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    if (![self compileShader:&bulgeDistortionFragShader type:GL_FRAGMENT_SHADER source:kRDCompositorBulgeDistortionFragmentShader]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    if (![self compileShader:&gridFragShader type:GL_FRAGMENT_SHADER source:kRDCompositorGridFragmentShader]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    if (![self compileShader:&borderBlurFragShader type:GL_FRAGMENT_SHADER source:kRDBorderGaussianBlurFragmentShaderString]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    if (![self compileShader:&borderBlurVertShader type:GL_VERTEX_SHADER source:kRDGaussianBlurVertexShaderString]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    if (![self compileShader:&blurFragShader type:GL_FRAGMENT_SHADER source:kRDGaussianBlurFragmentShaderString]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    if (![self compileShader:&blurVertShader type:GL_VERTEX_SHADER source:kRDGaussianBlurVertexShaderString]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    //    if (![self compileShader:&blurVertShader type:GL_VERTEX_SHADER source:kRDVertexShaderString]) {
    //        NSLog(@"Failed to compile vertex shader");
    //        return NO;
    //    }
    
    
    if (![self compileShader:&simpleFragShader type:GL_FRAGMENT_SHADER source:kRDSimpleFragmentShaderString]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    if (![self compileShader:&simpleVertShader type:GL_VERTEX_SHADER source:kRDVertexShaderString]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    if (![self compileShader:&beautyFragShader type:GL_FRAGMENT_SHADER source:kRDBeautyFragmentShaderString]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    if (![self compileShader:&beautyVertShader type:GL_VERTEX_SHADER source:kRDVertexShaderString]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    if (![self compileShader:&chromaColorFragShader type:GL_FRAGMENT_SHADER source:kRDChromaColorBlendFragmentShaderString]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    if (![self compileShader:&chromaColorVertShader type:GL_VERTEX_SHADER source:kRDVertexShaderString]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    
    
    
    //    glReleaseShaderCompiler();
    
    glAttachShader(_program, vertShader);
    glAttachShader(_program, fragShader);
    
#ifdef USE_MULTITEXTURE
    glAttachShader(_blendProgram, multiVertShader);
#else
    glAttachShader(_blendProgram, vertShader);
#endif
    
    glAttachShader(_blendProgram, blendFragShader);
#ifdef USE_MULTITEXTURE
    glAttachShader(_maskProgram, multiVertShader);
#else
    glAttachShader(_maskProgram, vertShader);
#endif
    glAttachShader(_maskProgram, maskFragShader);
    
    
    glAttachShader(_multiProgram, multiVertShader);
    glAttachShader(_multiProgram, multiFragShader);
    
    
    glAttachShader(_transProgram, vertShader);
    glAttachShader(_transProgram, transFragShader);
    
    glAttachShader(_mvProgram, mvVertShader);
    glAttachShader(_mvProgram, mvFragShader);
    
    glAttachShader(_screenProgram, mvVertShader);
    glAttachShader(_screenProgram, screenFragShader);
    
    glAttachShader(_hardLightProgram, mvVertShader);
    glAttachShader(_hardLightProgram, hardLightFragShader);
    
    glAttachShader(_chromaKeyProgram, mvVertShader);
    glAttachShader(_chromaKeyProgram, chromaKeyFragShader);
    
    glAttachShader(_invertProgram, vertShader);
    glAttachShader(_invertProgram, invertFragShader);
    
    glAttachShader(_grayProgram, vertShader);
    glAttachShader(_grayProgram, grayFragShader);
    
    glAttachShader(_bulgeDistortionProgram, vertShader);
    glAttachShader(_bulgeDistortionProgram, bulgeDistortionFragShader);
    
    glAttachShader(_gridProgram, vertShader);
    glAttachShader(_gridProgram, gridFragShader);
    
    glAttachShader(_simpleProgram, simpleVertShader);
    glAttachShader(_simpleProgram, simpleFragShader);
    
    glAttachShader(_borderBlurProgram, borderBlurVertShader);
    glAttachShader(_borderBlurProgram, borderBlurFragShader);
    
    glAttachShader(_blurProgram, blurVertShader);
    glAttachShader(_blurProgram, blurFragShader);
    
    glAttachShader(_beautyProgram, beautyVertShader);
    glAttachShader(_beautyProgram, beautyFragShader);
    
    glAttachShader(_chromaColorProgram, chromaColorVertShader);
    glAttachShader(_chromaColorProgram, chromaColorFragShader);
    
    
    // Link the program.
    if (![self linkProgram:_program]           ||
        ![self linkProgram:_blendProgram]      ||
        ![self linkProgram:_maskProgram]       ||
        ![self linkProgram:_multiProgram]      ||
        ![self linkProgram:_transProgram]      ||
        ![self linkProgram:_mvProgram]         ||
        ![self linkProgram:_screenProgram]     ||
        ![self linkProgram:_hardLightProgram]  ||
        ![self linkProgram:_chromaKeyProgram]  ||
        ![self linkProgram:_invertProgram]     ||
        ![self linkProgram:_grayProgram]       ||
        ![self linkProgram:_bulgeDistortionProgram] ||
        ![self linkProgram:_gridProgram]        ||
        ![self linkProgram:_simpleProgram]      ||
        ![self linkProgram:_borderBlurProgram]  ||
        ![self linkProgram:_blurProgram]        ||
        ![self linkProgram:_beautyProgram]      ||
        ![self linkProgram:_chromaColorProgram]
        ) {
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        
        if (multiVertShader) {
            glDeleteShader(multiVertShader);
            multiVertShader = 0;
        }
        
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (multiFragShader) {
            glDeleteShader(multiFragShader);
            multiFragShader = 0;
        }
        
        if (blendFragShader) {
            glDeleteShader(blendFragShader);
            blendFragShader = 0;
        }
        if (maskFragShader) {
            glDeleteShader(maskFragShader);
            maskFragShader = 0;
        }
        if (multiVertShader) {
            glDeleteShader(multiVertShader);
            multiVertShader = 0;
        }
        if (transFragShader) {
            glDeleteShader(transFragShader);
            transFragShader = 0;
        }
        if (mvVertShader) {
            glDeleteShader(mvVertShader);
            mvVertShader = 0;
        }
        
        if (mvFragShader) {
            glDeleteShader(mvFragShader);
            mvFragShader = 0;
        }
        
        if (screenFragShader) {
            glDeleteShader(screenFragShader);
            screenFragShader = 0;
        }
        
        if (hardLightFragShader) {
            glDeleteShader(hardLightFragShader);
            hardLightFragShader = 0;
        }
        
        if (chromaKeyFragShader) {
            glDeleteShader(chromaKeyFragShader);
            chromaKeyFragShader = 0;
        }
        if (invertFragShader) {
            glDeleteShader(invertFragShader);
            invertFragShader = 0;
        }
        if (grayFragShader) {
            glDeleteShader(grayFragShader);
            grayFragShader = 0;
        }
        if (bulgeDistortionFragShader) {
            glDeleteShader(bulgeDistortionFragShader);
            bulgeDistortionFragShader = 0;
        }
        if (gridFragShader) {
            glDeleteShader(gridFragShader);
            gridFragShader = 0;
        }
        if (simpleFragShader) {
            glDeleteShader(simpleFragShader);
            simpleFragShader = 0;
        }
        if (simpleVertShader) {
            glDeleteShader(simpleVertShader);
            simpleVertShader = 0;
        }
        if (borderBlurFragShader) {
            glDeleteShader(borderBlurFragShader);
            borderBlurFragShader = 0;
        }
        
        if (borderBlurVertShader) {
            glDeleteShader(borderBlurVertShader);
            borderBlurVertShader = 0;
        }
        if (blurFragShader) {
            glDeleteShader(blurFragShader);
            blurFragShader = 0;
        }
        
        if (blurVertShader) {
            glDeleteShader(blurVertShader);
            blurVertShader = 0;
        }
        if (beautyFragShader) {
            glDeleteShader(beautyFragShader);
            beautyFragShader = 0;
        }
        if (beautyVertShader) {
            glDeleteShader(beautyVertShader);
            beautyVertShader = 0;
        }
        if (chromaColorFragShader) {
            glDeleteShader(chromaColorFragShader);
            chromaColorFragShader = 0;
        }
        if (chromaColorVertShader) {
            glDeleteShader(chromaColorVertShader);
            chromaColorVertShader = 0;
        }
        
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        if (_blendProgram) {
            glDeleteProgram(_blendProgram);
            _blendProgram = 0;
        }
        
        if (_maskProgram) {
            glDeleteProgram(_maskProgram);
            _maskProgram = 0;
        }
        if (_multiProgram) {
            glDeleteProgram(_multiProgram);
            _multiProgram = 0;
        }
        if (_transProgram) {
            glDeleteProgram(_transProgram);
            _transProgram = 0;
        }
        if (_mvProgram) {
            glDeleteProgram(_mvProgram);
            _mvProgram = 0;
        }
        
        if (_screenProgram) {
            glDeleteProgram(_screenProgram);
            _screenProgram = 0;
        }
        
        if (_hardLightProgram) {
            glDeleteProgram(_hardLightProgram);
            _hardLightProgram = 0;
        }
        
        if (_chromaKeyProgram) {
            glDeleteProgram(_chromaKeyProgram);
            _chromaKeyProgram = 0;
        }
        if (_invertProgram) {
            glDeleteProgram(_invertProgram);
            _invertProgram = 0;
        }
        if (_grayProgram) {
            glDeleteProgram(_grayProgram);
            _grayProgram = 0;
        }
        if (_bulgeDistortionProgram) {
            glDeleteProgram(_bulgeDistortionProgram);
            _bulgeDistortionProgram = 0;
        }
        if (_gridProgram) {
            glDeleteProgram(_gridProgram);
            _gridProgram = 0;
        }
        if (_simpleProgram) {
            glDeleteProgram(_simpleProgram);
            _simpleProgram = 0;
        }
        if(_throughBlackColorProgram)
        {
            glDeleteProgram(_throughBlackColorProgram);
            _throughBlackColorProgram = 0;
        }
        if (_borderBlurProgram) {
            glDeleteProgram(_borderBlurProgram);
            _borderBlurProgram = 0;
        }
        if (_beautyProgram) {
            glDeleteProgram(_beautyProgram);
            _beautyProgram = 0;
        }
        if (_chromaColorProgram) {
            glDeleteProgram(_chromaColorProgram);
            _chromaColorProgram = 0;
        }
        
        return NO;
    }
    
    
    
    // Get uniform locations.
    normalPositionAttribute = glGetAttribLocation(_program, "position");
    normalTextureCoordinateAttribute = glGetAttribLocation(_program, "inputTextureCoordinate");
    normalTextureMaskCoordinateAttribute = glGetAttribLocation(_program, "inputTextureMaskCoordinate");
    normalTextureMosaicCoordinateAttribute = glGetAttribLocation(_program, "inputTextureMosaicCoordinate");
    normalProjectionUniform = glGetUniformLocation(_program, "projection");
    normalInputTextureUniform = glGetUniformLocation(_program, "inputImageTexture");
    normalTransformUniform = glGetUniformLocation(_program, "renderTransform");
    normalFilterUniform = glGetUniformLocation(_program, "filter");
    normalInputTextureUniform2 = glGetUniformLocation(_program, "inputImageTexture2");
    normalInputTextureUniform3 = glGetUniformLocation(_program, "inputImageTexture3");
    normalInputMaskURLUniform = glGetUniformLocation(_program, "inputMaskURL");
    normalTexture2TypeUniform = glGetUniformLocation(_program, "inputTexture2Type");
    filterIntensityUniform = glGetUniformLocation(_program, "filterIntensity");
    normalInputAlphaUniform = glGetUniformLocation(_program, "inputAlpha");
    normalSrcQuadrilateralUniform = glGetUniformLocation(_program, "SrcQuadrilateral");
    normalDstQuadrilateralUniform = glGetUniformLocation(_program, "DstQuadrilateral");
    normalDstSinglePixelSizeUniform = glGetUniformLocation(_program, "DstSinglePixelSize");
    normalRotateAngleUniform = glGetUniformLocation(_program, "rotateAngle");
    normalBlurUniform = glGetUniformLocation(_program, "blurIntensity");
    normalIsBlurredBorderUniform = glGetUniformLocation(_program, "isBlurredBorder");
    normalCropOriginUniform = glGetUniformLocation(_program, "cropOrigin");
    normalCropSizeUniform = glGetUniformLocation(_program, "cropSize");
    normalVignetteUniform = glGetUniformLocation(_program, "vignette");
    normalSharpnessUniform = glGetUniformLocation(_program, "sharpness");
    normalWhiteBalanceUniform = glGetUniformLocation(_program, "whiteBalance");
    
    
    transPositionAttribute = glGetAttribLocation(_transProgram, "position");
    transTextureCoordinateAttribute = glGetAttribLocation(_transProgram, "inputTextureCoordinate");
    transProjectionUniform = glGetUniformLocation(_transProgram, "projection");
    transTransformUniform = glGetUniformLocation(_transProgram, "renderTransform");
    transInputTextureUniform = glGetUniformLocation(_transProgram, "inputImageTexture");
    
    
    
    blendPositionAttribute = glGetAttribLocation(_blendProgram, "position");
    blendTextureCoordinateAttribute = glGetAttribLocation(_blendProgram, "inputTextureCoordinate");
#ifdef USE_MULTITEXTURE
    blendProjectionUniform = glGetUniformLocation(_blendProgram, "projection[0]");
    blendTransformUniform = glGetUniformLocation(_blendProgram, "renderTransform[0]");
#else
    blendProjectionUniform = glGetUniformLocation(_blendProgram, "projection");
    blendTransformUniform = glGetUniformLocation(_blendProgram, "renderTransform");
#endif
    blendInputTextureUniform = glGetUniformLocation(_blendProgram, "inputImageTexture");
    blendInputTextureUniform2 = glGetUniformLocation(_blendProgram, "inputImageTexture2");
    blendColorUniform = glGetUniformLocation(_blendProgram, "color");
    blendFactorUniform = glGetUniformLocation(_blendProgram, "factor");
    blendBrightnessUniform = glGetUniformLocation(_blendProgram, "brightness");
    
    
    
    maskPositionAttribute = glGetAttribLocation(_maskProgram, "position");
    maskTextureCoordinateAttribute = glGetAttribLocation(_maskProgram, "inputTextureCoordinate");
#ifdef USE_MULTITEXTURE
    maskProjectionUniform = glGetUniformLocation(_maskProgram, "projection[0]");
    maskTransformUniform = glGetUniformLocation(_maskProgram, "renderTransform[0]");
#else
    maskProjectionUniform = glGetUniformLocation(_maskProgram, "projection");
    maskTransformUniform = glGetUniformLocation(_maskProgram, "renderTransform");
#endif
    maskInputTextureUniform = glGetUniformLocation(_maskProgram, "inputImageTexture");
    maskInputTextureUniform2 = glGetUniformLocation(_maskProgram, "inputImageTexture2");
    maskInputTextureUniform3 = glGetUniformLocation(_maskProgram, "inputImageTexture3");
    maskFactorUniform = glGetUniformLocation(_maskProgram, "factor");
    
    
    multiPositionAttribute = glGetAttribLocation(_multiProgram, "position");
    multiTextureCoordinateAttribute = glGetAttribLocation(_multiProgram, "inputTextureCoordinate");
    
    //mv
    mvPositionAttribute = glGetAttribLocation(_mvProgram, "position");
    mvTextureCoordinateAttribute = glGetAttribLocation(_mvProgram, "inputTextureCoordinate");
    
    mvInputTextureUniform = glGetUniformLocation(_mvProgram, "inputImageTexture");
    mvInputTextureUniform2 = glGetUniformLocation(_mvProgram, "inputImageTexture2");
    
    
    screenPositionAttribute = glGetAttribLocation(_screenProgram, "position");
    screenTextureCoordinateAttribute = glGetAttribLocation(_screenProgram, "inputTextureCoordinate");
    
    screenInputTextureUniform = glGetUniformLocation(_screenProgram, "inputImageTexture");
    screenInputTextureUniform2 = glGetUniformLocation(_screenProgram, "inputImageTexture2");
    
    
    hardLightPositionAttribute = glGetAttribLocation(_hardLightProgram, "position");
    hardLightTextureCoordinateAttribute = glGetAttribLocation(_hardLightProgram, "inputTextureCoordinate");
    
    hardLightInputTextureUniform = glGetUniformLocation(_hardLightProgram, "inputImageTexture");
    hardLightInputTextureUniform2 = glGetUniformLocation(_hardLightProgram, "inputImageTexture2");
    
    
    chromaKeyPositionAttribute = glGetAttribLocation(_chromaKeyProgram, "position");
    chromaKeyTextureCoordinateAttribute = glGetAttribLocation(_chromaKeyProgram, "inputTextureCoordinate");
    
    chromaKeyInputTextureUniform = glGetUniformLocation(_chromaKeyProgram, "inputImageTexture");
    chromaKeyInputTextureUniform2 = glGetUniformLocation(_chromaKeyProgram, "inputImageTexture2");
    chromaKeyInputColorTransparencyImageTexture = glGetUniformLocation(_chromaKeyProgram, "inputColorTransparencyImageTexture");
    chromaKeyInputColorUnifrom = glGetUniformLocation(_chromaKeyProgram, "bgRGB");
    chromaKeyInputBackGroundImageTexture = glGetUniformLocation(_chromaKeyProgram, "inputBackGroundImageTexture");
    //    chromaKeyTransformUniform = glGetUniformLocation(_chromaKeyProgram, "renderTransform");
    chromaKeyColorToReplaceUniform = glGetUniformLocation(_chromaKeyProgram, "colorToReplace");
    chromaKeyThresholdSensitivityUniform = glGetUniformLocation(_chromaKeyProgram, "thresholdSensitivity");
    chromaKeySmoothingUniform = glGetUniformLocation(_chromaKeyProgram, "smoothing");
    chromaKeyEdgeModeUniform = glGetUniformLocation(_chromaKeyProgram, "edgeMode");
    chromaKeyThresholdAUniform = glGetUniformLocation(_chromaKeyProgram, "thresholdA");
    chromaKeyThresholdBUniform = glGetUniformLocation(_chromaKeyProgram, "thresholdB");
    chromaKeyThresholdCUniform = glGetUniformLocation(_chromaKeyProgram, "thresholdC");
    chromaKeyBgModeUniform = glGetUniformLocation(_chromaKeyProgram, "bgMode");
    
    
    invertPositionAttribute = glGetAttribLocation(_invertProgram, "position");
    invertTextureCoordinateAttribute = glGetAttribLocation(_invertProgram, "inputTextureCoordinate");
    invertProjectionUniform = glGetUniformLocation(_invertProgram, "projection");
    invertTransformUniform = glGetUniformLocation(_invertProgram, "renderTransform");
    invertInputTextureUniform = glGetUniformLocation(_invertProgram, "inputImageTexture");
    invertInputTextureUniform2 = glGetUniformLocation(_invertProgram, "inputImageTexture2");
    invertColorUniform = glGetUniformLocation(_invertProgram, "color");
    invertFactorUniform = glGetUniformLocation(_invertProgram, "factor");
    invertBrightnessUniform = glGetUniformLocation(_invertProgram, "brightness");
    
    
    
    grayPositionAttribute = glGetAttribLocation(_grayProgram, "position");
    grayTextureCoordinateAttribute = glGetAttribLocation(_grayProgram, "inputTextureCoordinate");
    grayProjectionUniform = glGetUniformLocation(_grayProgram, "projection");
    grayTransformUniform = glGetUniformLocation(_grayProgram, "renderTransform");
    grayInputTextureUniform = glGetUniformLocation(_grayProgram, "inputImageTexture");
    grayInputTextureUniform2 = glGetUniformLocation(_grayProgram, "inputImageTexture2");
    grayColorUniform = glGetUniformLocation(_grayProgram, "color");
    grayFactorUniform = glGetUniformLocation(_grayProgram, "factor");
    grayBrightnessUniform = glGetUniformLocation(_grayProgram, "brightness");
    
    
    bulgeDistortionPositionAttribute = glGetAttribLocation(_bulgeDistortionProgram, "position");
    bulgeDistortionTextureCoordinateAttribute = glGetAttribLocation(_bulgeDistortionProgram, "inputTextureCoordinate");
    bulgeDistortionProjectionUniform = glGetUniformLocation(_bulgeDistortionProgram, "projection");
    bulgeDistortionTransformUniform = glGetUniformLocation(_bulgeDistortionProgram, "renderTransform");
    bulgeDistortionInputTextureUniform = glGetUniformLocation(_bulgeDistortionProgram, "inputImageTexture");
    bulgeDistortionInputTextureUniform2 = glGetUniformLocation(_bulgeDistortionProgram, "inputImageTexture2");
    bulgeDistortionColorUniform = glGetUniformLocation(_bulgeDistortionProgram, "color");
    bulgeDistortionFactorUniform = glGetUniformLocation(_bulgeDistortionProgram, "factor");
    bulgeDistortionBrightnessUniform = glGetUniformLocation(_bulgeDistortionProgram, "brightness");
    bulgeDistortionAspectRatioUniform = glGetUniformLocation(_bulgeDistortionProgram, "aspectRatio");
    
    
    gridPositionAttribute = glGetAttribLocation(_gridProgram, "position");
    gridTextureCoordinateAttribute = glGetAttribLocation(_gridProgram, "inputTextureCoordinate");
    gridProjectionUniform = glGetUniformLocation(_gridProgram, "projection");
    gridTransformUniform = glGetUniformLocation(_gridProgram, "renderTransform");
    gridInputTextureUniform = glGetUniformLocation(_gridProgram, "inputImageTexture");
    gridInputTextureUniform2 = glGetUniformLocation(_gridProgram, "inputImageTexture2");
    gridFactorUniform = glGetUniformLocation(_gridProgram, "factor");
    
    
    simplePositionAttribute = glGetAttribLocation(_simpleProgram, "position");
    simpleTextureCoordinateAttribute = glGetAttribLocation(_simpleProgram, "inputTextureCoordinate");
    simpleInputTextureUniform = glGetUniformLocation(_simpleProgram, "inputImageTexture");
    
    
    borderBlurPositionAttribute = glGetAttribLocation(_borderBlurProgram, "position");
    borderBlurTextureCoordinateAttribute = glGetAttribLocation(_borderBlurProgram, "inputTextureCoordinate");
    borderBlurProjectionUniform = glGetUniformLocation(_borderBlurProgram, "projection");
    borderBlurTransformUniform  = glGetUniformLocation(_borderBlurProgram, "renderTransform");
    borderBlurInputTextureUniform = glGetUniformLocation(_borderBlurProgram, "inputImageTexture");
    borderBlurImageWidthUniform = glGetUniformLocation(_borderBlurProgram, "fWidth");
    borderBlurImageHeightUniform = glGetUniformLocation(_borderBlurProgram, "fHeight");
    borderBlurStartValueUniform = glGetUniformLocation(_borderBlurProgram, "startValue");
    borderBlurEndValueUniform = glGetUniformLocation(_borderBlurProgram, "endValue");
    borderBlurResolutionUniform = glGetUniformLocation(_borderBlurProgram, "resolution");
    borderBlurViewportUniform = glGetUniformLocation(_borderBlurProgram, "viewport");
    borderBlurEdgeUniform = glGetUniformLocation(_borderBlurProgram, "edge");
    borderBlurRadiusUniform = glGetUniformLocation(_borderBlurProgram, "blurRadius");
    borderBlurClipSizeUniform = glGetUniformLocation(_borderBlurProgram, "cropSize");
    borderBlurClipOriginalUniform = glGetUniformLocation(_borderBlurProgram, "cropOriginal");
    borderBlurIsFirstUniform = glGetUniformLocation(_borderBlurProgram, "isfirst");
    
    blurPositionAttribute = glGetAttribLocation(_blurProgram, "position");
    blurTextureCoordinateAttribute = glGetAttribLocation(_blurProgram, "inputTextureCoordinate");
    blurProjectionUniform = glGetUniformLocation(_blurProgram, "projection");
    blurTransformUniform  = glGetUniformLocation(_blurProgram, "renderTransform");
    blurInputTextureUniform = glGetUniformLocation(_blurProgram, "inputImageTexture");
    blurImageWidthUniform = glGetUniformLocation(_blurProgram, "fWidth");
    blurImageHeightUniform = glGetUniformLocation(_blurProgram, "fHeight");
    blurStartValueUniform = glGetUniformLocation(_blurProgram, "startValue");
    blurEndValueUniform = glGetUniformLocation(_blurProgram, "endValue");
    blurDirectionUniform = glGetUniformLocation(_blurProgram, "u_direction");
    blurResolutionUniform = glGetUniformLocation(_blurProgram, "u_resolution");
    blurPointBLUniform = glGetUniformLocation(_blurProgram, "pointLB");
    blurPointTLUniform = glGetUniformLocation(_blurProgram, "pointLT");
    blurPointTRUniform = glGetUniformLocation(_blurProgram, "pointRT");
    blurPointBRUniform = glGetUniformLocation(_blurProgram, "pointRB");

    
    beautyPositionAttribute = glGetAttribLocation(_beautyProgram, "position");
    beautyTextureCoordinateAttribute = glGetAttribLocation(_beautyProgram, "inputTextureCoordinate");
    beautyInputTextureUniform = glGetUniformLocation(_beautyProgram, "inputImageTexture");
    beautySingleStepOffsetUniform = glGetUniformLocation(_beautyProgram, "singleStepOffset");
    beautyParamsUniform = glGetUniformLocation(_beautyProgram, "beautyParams");
    
    chromaColorInputTextureUniform = glGetUniformLocation(_chromaColorProgram, "inputImageTexture");
    chromaColorInputTextureUniform2 = glGetUniformLocation(_chromaColorProgram, "inputImageTexture2");
    chromaColorEdgeModeUniform = glGetUniformLocation(_chromaColorProgram, "edgeMode");
    chromaColorThresholdAUniform = glGetUniformLocation(_chromaColorProgram, "thresholdA");
    chromaColorThresholdBUniform = glGetUniformLocation(_chromaColorProgram, "thresholdB");
    chromaColorThresholdCUniform = glGetUniformLocation(_chromaColorProgram, "thresholdC");
    chromaColorBgModeUniform = glGetUniformLocation(_chromaColorProgram, "bgMode");
    chromaColorPositionAttribute = glGetAttribLocation(_chromaColorProgram, "position");
    chromaColorTextureCoordinateAttribute = glGetAttribLocation(_chromaColorProgram, "inputTextureCoordinate");
    
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDetachShader(_blendProgram, vertShader);
        glDetachShader(_maskProgram, vertShader);
        glDetachShader(_transProgram, vertShader);
        glDetachShader(_invertProgram, vertShader);
        glDetachShader(_grayProgram, vertShader);
        glDetachShader(_bulgeDistortionProgram, vertShader);
        glDetachShader(_gridProgram, vertShader);
        glDeleteShader(vertShader);
        vertShader = 0;
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
        fragShader = 0;
    }
    
    if (blendFragShader) {
        glDetachShader(_blendProgram, blendFragShader);
        glDeleteShader(blendFragShader);
        blendFragShader = 0;
    }
    if (maskFragShader) {
        glDetachShader(_maskProgram, maskFragShader);
        glDeleteShader(maskFragShader);
        maskFragShader = 0;
    }
    if (multiVertShader) {
        glDetachShader(_multiProgram, multiVertShader);
        glDeleteShader(multiVertShader);
        multiVertShader = 0;
    }
    if (multiFragShader) {
        glDetachShader(_multiProgram, multiFragShader);
        glDeleteShader(multiFragShader);
        multiFragShader = 0;
    }
    if (transFragShader) {
        glDetachShader(_transProgram, transFragShader);
        glDeleteShader(transFragShader);
        transFragShader = 0;
    }
    
    if (mvVertShader) {
        glDetachShader(_mvProgram, mvVertShader);
        glDetachShader(_screenProgram, mvVertShader);
        glDetachShader(_hardLightProgram, mvVertShader);
        glDetachShader(_chromaKeyProgram, mvVertShader);
        glDeleteShader(mvVertShader);
        mvVertShader = 0;
    }
    if (mvFragShader) {
        glDetachShader(_mvProgram, mvFragShader);
        glDeleteShader(mvFragShader);
        mvFragShader = 0;
    }
    
    if (screenFragShader) {
        glDetachShader(_screenProgram, screenFragShader);
        glDeleteShader(screenFragShader);
        screenFragShader = 0;
    }
    
    if (hardLightFragShader) {
        glDetachShader(_hardLightProgram, hardLightFragShader);
        glDeleteShader(hardLightFragShader);
        hardLightFragShader = 0;
    }
    
    if (chromaKeyFragShader) {
        glDetachShader(_chromaKeyProgram, chromaKeyFragShader);
        glDeleteShader(chromaKeyFragShader);
        chromaKeyFragShader = 0;
    }
    if (invertFragShader) {
        glDetachShader(_invertProgram, invertFragShader);
        glDeleteShader(invertFragShader);
        invertFragShader = 0;
    }
    if (grayFragShader) {
        glDetachShader(_grayProgram, grayFragShader);
        glDeleteShader(grayFragShader);
        grayFragShader = 0;
    }
    if (bulgeDistortionFragShader) {
        glDetachShader(_bulgeDistortionProgram, bulgeDistortionFragShader);
        glDeleteShader(bulgeDistortionFragShader);
        bulgeDistortionFragShader = 0;
    }
    if (gridFragShader) {
        glDetachShader(_gridProgram, gridFragShader);
        glDeleteShader(gridFragShader);
        gridFragShader = 0;
    }
    if(simpleFragShader)
    {
        glDetachShader(_simpleProgram,simpleFragShader);
        glDeleteShader(simpleFragShader);
        simpleFragShader = 0;
    }
    if (simpleVertShader) {
        glDetachShader(_simpleProgram, simpleVertShader);
        glDeleteShader(simpleVertShader);
        simpleVertShader = 0;
    }
    if(borderBlurVertShader)
    {
        glDetachShader(_borderBlurProgram, borderBlurVertShader);
        glDeleteShader(borderBlurVertShader);
        borderBlurVertShader = 0;
    }
    if(borderBlurFragShader)
    {
        glDetachShader(_borderBlurProgram, borderBlurFragShader);
        glDeleteShader(borderBlurFragShader);
        borderBlurFragShader = 0;
    }
    if(blurVertShader)
    {
        glDetachShader(_blurProgram, blurVertShader);
        glDeleteShader(blurVertShader);
        blurVertShader = 0;
    }
    if(blurFragShader)
    {
        glDetachShader(_blurProgram, blurFragShader);
        glDeleteShader(blurFragShader);
        blurFragShader = 0;
    }
    if(chromaColorFragShader)
    {
        glDetachShader(_chromaColorProgram,chromaColorFragShader);
        glDeleteShader(chromaColorFragShader);
        chromaColorFragShader = 0;
    }
    if (chromaColorVertShader) {
        glDetachShader(_chromaColorProgram, chromaColorVertShader);
        glDeleteShader(chromaColorVertShader);
        chromaColorVertShader = 0;
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type source:(NSString *)sourceString
{
    if (sourceString == nil) {
        NSLog(@"Failed to load vertex shader: Empty source string");
        return NO;
    }
    
    GLint status;
    const GLchar *source;
    source = (GLchar *)[sourceString UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    glReleaseShaderCompiler();
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        //        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
//        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

#if defined(DEBUG)

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

#endif

#pragma mark -- Get TextureRef from PixelBuffer
- (CVOpenGLESTextureRef)lumaTextureForPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CVOpenGLESTextureRef lumaTexture = NULL;
    CVReturn err;
    
    if (!_videoTextureCache) {
        NSLog(@"No video texture cache");
        goto bail;
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
    
    // CVOpenGLTextureCacheCreateTextureFromImage will create GL texture optimally from CVPixelBufferRef.
    // Y
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _videoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RED_EXT,
                                                       (int)CVPixelBufferGetWidth(pixelBuffer),
                                                       (int)CVPixelBufferGetHeight(pixelBuffer),
                                                       GL_RED_EXT,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &lumaTexture);
    
    if (!lumaTexture || err) {
        NSLog(@"Error at creating luma texture using CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
bail:
    return lumaTexture;
}

- (CVOpenGLESTextureRef)chromaTextureForPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CVOpenGLESTextureRef chromaTexture = NULL;
    CVReturn err;
    
    if (!_videoTextureCache) {
        NSLog(@"No video texture cache");
        goto bail;
    }
    
    {
        // Periodic texture cache flush every frame
        CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
        
        // CVOpenGLTextureCacheCreateTextureFromImage will create GL texture optimally from CVPixelBufferRef.
        // UV
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           _videoTextureCache,
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_RG_EXT,
                                                           (int)CVPixelBufferGetWidthOfPlane(pixelBuffer, 1),
                                                           (int)CVPixelBufferGetHeightOfPlane(pixelBuffer, 1),
                                                           GL_RG_EXT,
                                                           GL_UNSIGNED_BYTE,
                                                           1,
                                                           &chromaTexture);
        
        if (!chromaTexture || err) {
            NSLog(@"Error at creating chroma texture using CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
    }
    
bail:
    return chromaTexture;
}
- (CVOpenGLESTextureRef) imageTextureForPixelBuffer:(CVPixelBufferRef) pixelBuffer
{
    CVOpenGLESTextureRef bgraTexture = NULL;
    CVReturn err;
    
    if (!_videoTextureCache) {
        NSLog(@"No video texture cache");
        goto bail;
    }
    {
        int width = (int)CVPixelBufferGetWidth(pixelBuffer);
        int height = (int)CVPixelBufferGetHeight(pixelBuffer);
        
        CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
        
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           _videoTextureCache,
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_RGBA,
                                                           width,
                                                           height,
                                                           GL_RGBA,
                                                           GL_UNSIGNED_BYTE,
                                                           0,
                                                           &bgraTexture);
        
        if (!bgraTexture || err) {
            NSLog(@"Error creating rgba texture using CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
    }
    
bail:
    return bgraTexture;
    
    
}
- (CVOpenGLESTextureRef)customTextureForPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CVOpenGLESTextureRef bgraTexture = NULL;
    CVReturn err;
    
    if (!_videoTextureCache) {
        NSLog(@"No video texture cache");
        goto bail;
    }
    
    {
        CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
        
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           _videoTextureCache,
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_RGBA,
                                                           (int)CVPixelBufferGetWidth(pixelBuffer),
                                                           (int)CVPixelBufferGetHeight(pixelBuffer),
                                                           GL_BGRA,
                                                           GL_UNSIGNED_BYTE,
                                                           0,
                                                           &bgraTexture);
        
        if (!bgraTexture || err) {
            NSLog(@"Error creating BGRA texture using CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
    }
bail:
    return bgraTexture;
}


@end
