//
//  RDLookupFilter.m
//  RDVECore
//
//  Created by on 2018/4/6.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDGPUImageGaussianBlurDYFilter.h"

//绘制流程：
//    1.原始画面做全屏高斯模糊保存到fbo1
//    2.绘制马赛克贴纸旋转等操作保存到fbo2
//    3.fbo1 与 fbo2 做mask处理 保存到 fbo3
//    4.绘制原始画面
//    5.绘制fbo3



#define MAX_GUASSBLUR_INTENSITY (30)
#define MAX_ZOOMBLUR_INTENSITY (0.1)

NSString*  const kRDGaussianBlurDYVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;
 

 varying vec2 textureCoordinate;
 
 void main()
 {
     textureCoordinate = inputTextureCoordinate;
     gl_Position = position;

 }
 );

NSString *const kRDGaussianBlurDYFragmentShaderString = SHADER_STRING
(
 precision highp float;
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform vec2 pointLB;
 uniform vec2 pointLT;
 uniform vec2 pointRT;
 uniform vec2 pointRB;
 uniform vec2 size;
 uniform vec2 direction;
 
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
 vec4 blur13(sampler2D image, vec2 uv, vec2 resolution, vec2 direction)
 {
     vec4 color = vec4(0.0);
     vec2 off1 = vec2(1.411764705882353) * direction;
     vec2 off2 = vec2(3.2941176470588234) * direction;
     vec2 off3 = vec2(5.176470588235294) * direction;
     vec4 imageColor = texture2D(image, uv);
     color += imageColor * 0.1964825501511404;
     color += texture2D(image, uv + (off1 / resolution)) * 0.2969069646728344;
     color += texture2D(image, uv - (off1 / resolution)) * 0.2969069646728344;
     color += texture2D(image, uv + (off2 / resolution)) * 0.09447039785044732;
     color += texture2D(image, uv - (off2 / resolution)) * 0.09447039785044732;
     color += texture2D(image, uv + (off3 / resolution)) * 0.010381362401148057;
     color += texture2D(image, uv - (off3 / resolution)) * 0.010381362401148057;
     return color;//vec4(color.rgb,imageColor.a);
 }
 void main()
 {
     
     vec2 uv = vec2(gl_FragCoord.xy / size.xy);
//     if(uv.x < origin.x || uv.x>(origin.x+size.x) || uv.y < origin.y || uv.y>(origin.y+size.y))
    if(1 == isPointInRect(uv.x*100.0,uv.y*100.0))
         vColorRGBA = blur9(inputImageTexture, uv, size.xy, direction);
     else
         vColorRGBA = texture2D(inputImageTexture,textureCoordinate);
     gl_FragColor = vColorRGBA;
     
 }
 );


NSString *const kRDGrayFillFragmentShaderString = SHADER_STRING
(
 precision highp float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform vec2 pointLB;
 uniform vec2 pointLT;
 uniform vec2 pointRT;
 uniform vec2 pointRB;

 
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
 

 void main()
 {
    if(1 == isPointInRect(textureCoordinate.x*100.0,textureCoordinate.y*100.0))
         gl_FragColor = vec4(1.0,1.0,1.0,1.0);
     else
         gl_FragColor = texture2D(inputImageTexture,textureCoordinate);
 }
 );

NSString *const kRDMVDYFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageGrayTexture;
 uniform sampler2D inputImageGaussBlurTexture;
 
 
 void main()
 {
     //     gl_FragColor = texture2D(inputImageTexture,textureCoordinate);
     //     return ;
     
     vec2 newCoordinate1 = vec2(textureCoordinate.x/2.0,textureCoordinate.y);
     vec4 t1 = texture2D(inputImageGaussBlurTexture,textureCoordinate); // view
     
     vec2 newCoordinate2 = newCoordinate1 + vec2(0.5,0.0);
     vec4 t2 = texture2D(inputImageGrayTexture, textureCoordinate);//alpha
     
     vec4 t3 = texture2D(inputImageTexture,textureCoordinate);;//source
     float newAlpha = dot(t2.rgb, vec3(0.33333334)) * t2.a;
     vec4 t = vec4(t1.rgb,newAlpha); //compositor 输出一个综合视频 再与
     //mix(a,b,v) = (1-v)a + v(b)
     vec4 textureColor = vec4(mix(t3.rgb,t.rgb,t.a),t3.a);
     
    gl_FragColor = textureColor; // view;
     return ;
 }
 );

NSString *const kRDSimpleDYFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture,textureCoordinate);
     return ;
 }
 );

//放大模糊
NSString *const kRDGaussianZoomBlurDYFragmentShaderString = SHADER_STRING
(
 precision highp float;
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform float intensity;
 uniform float startValue;
 uniform float endValue;
 
 vec4 vColorRGBA;
 void main()
 {
     
     
     highp vec2 blurCenter = vec2(0.5,0.5);
     highp float blurSize = 2.0;
     
     float progress = 0.0;
     float xx = sqrt((textureCoordinate.x-0.5)*(textureCoordinate.x-0.5) + (textureCoordinate.y-0.5)*(textureCoordinate.y-0.5));
     if(xx >= 0.5)
         progress = 1.0;
     else
         progress = xx/0.5;
     
     blurSize = 1.0*progress;
     highp vec2 samplingOffset = 1.0/100.0 * (blurCenter - textureCoordinate) * blurSize;
     
     
     vColorRGBA = texture2D(inputImageTexture, textureCoordinate) * 0.18;
     vColorRGBA += texture2D(inputImageTexture, textureCoordinate + samplingOffset) * 0.15;
     vColorRGBA += texture2D(inputImageTexture, textureCoordinate + (2.0 * samplingOffset)) *  0.12;
     vColorRGBA += texture2D(inputImageTexture, textureCoordinate + (3.0 * samplingOffset)) * 0.09;
     vColorRGBA += texture2D(inputImageTexture, textureCoordinate + (4.0 * samplingOffset)) * 0.05;
     vColorRGBA += texture2D(inputImageTexture, textureCoordinate - samplingOffset) * 0.15;
     vColorRGBA += texture2D(inputImageTexture, textureCoordinate - (2.0 * samplingOffset)) *  0.12;
     vColorRGBA += texture2D(inputImageTexture, textureCoordinate - (3.0 * samplingOffset)) * 0.09;
     vColorRGBA += texture2D(inputImageTexture, textureCoordinate - (4.0 * samplingOffset)) * 0.05;
     
     gl_FragColor = vColorRGBA;
     return;
     
 }
 );



@interface RDGPUImageGaussianBlurDYFilter()
{
    //高斯模糊
    int blurTextureWidth;
    int blurTextureHeight;
    GLuint texHorizontal,texVertical,fboHorizontal,fboVertical;
    GLuint blurPositionAttribute,blurTextureCoordinateAttribute;
    GLuint blurInputTextureUniform,blurVertShader,blurFragShader;
    GLuint blurStartValueUniform,blurEndValueUniform,blurTypeUniform;
    GLuint blurResolutionUniform,blurDirectionUniform;
    GLuint blurPointTLUniform,blurPointTRUniform,blurPointBRUniform,blurPointBLUniform;
    GLuint blurProgram;
    
    //黑白图
    int grayTextureWidth;
    int grayTextureHeight;
    GLuint texWhiteColor,texBlackColor,fboGray;
    GLuint grayProgram,grayVertShader,grayFragShader;
    GLuint grayPointTLUniform,grayPointTRUniform,grayPointBRUniform,grayPointBLUniform;
    GLuint grayPositionAttribute,grayTextureCoordinateAttribute,grayInputTextureUniform;
    
    
    //透黑色
    int mvTextureWidth;
    int mvTextureHeight;
    GLuint texMV,fboMV;
    GLuint mvPositionAttribute,mvTextureCoordinateAttribute,mvInputTextureUniform;
    GLuint mvInputGrayTextureUniform,mvInputGaussBlurTextureUniform;
    GLuint mvProgram,mvVertShader,mvFragShader;
    
    int textureWidth;
    int textureHeight;
    GLuint texGaussBlur,fboGaussblur;
    GLuint simpleProgram,simpleVertShader,simpleFragShader;
    GLuint simplePositionAttribute,simpleTextureCoordinateAttribute,simpleInputTextureUniform;
    
    
    CGSize frameSize;
    float currentTime;
}
@end

@implementation RDGPUImageGaussianBlurDYFilter


-(void )renderTotexture:(GLuint)texture StartValue:(float)startValue EndValue:(float)endValue PointArray:(NSArray*)pointsArray BlurType:(float)type Vertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates
{
    
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(blurProgram);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    glUniform1i(blurInputTextureUniform, 0);
    glUniform2f(blurDirectionUniform, startValue, endValue);

    glUniform2f(blurResolutionUniform, (float)frameSize.width, (float)frameSize.height);
    glUniform1f(blurTypeUniform, (float)type);

//     NSLog(@"StartValue:%f EndValue:%f ",startValue,endValue);

    //获取模糊区域坐标
    CGPoint pointTL= CGPointFromString([pointsArray objectAtIndex:0]);
    CGPoint pointTR= CGPointFromString([pointsArray objectAtIndex:1]);
    CGPoint pointBR= CGPointFromString([pointsArray objectAtIndex:2]);
    CGPoint pointBL= CGPointFromString([pointsArray objectAtIndex:3]);
    //设置模糊区域坐标
    glUniform2f(blurPointTLUniform, pointTL.x, pointTL.y);
    glUniform2f(blurPointTRUniform, pointTR.x, pointTR.y);
    glUniform2f(blurPointBLUniform, pointBL.x, pointBL.y);
    glUniform2f(blurPointBRUniform, pointBR.x, pointBR.y);
    
    
    glVertexAttribPointer(blurPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(blurTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    
}
- (GLuint)textureFromBufferObject:(unsigned char *) image Width:(int )width Height:(int)height
{
    
    
    GLuint texture = 0;
    
    glEnable(GL_TEXTURE_2D);
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)width, (int)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid*)image);
    
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
- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    
    
    static const GLfloat imageVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    //NSLog(@"frameTime:%lf",CMTimeGetSeconds(frameTime));
    currentTime = CMTimeGetSeconds(frameTime);
    
    [self renderToTextureWithVertices:imageVertices textureCoordinates:[[self class] textureCoordinatesForRotation:inputRotation]];
    
    [self informTargetsAboutNewFrameAtTime:frameTime];
}

-(int) initFrameBufferObject
{
    int         width = frameSize.width;
    int         height = frameSize.height;
    
    
    if (blurTextureHeight != height || blurTextureWidth != width) {

        unsigned char* pImage = (unsigned char*)malloc(width*height*4);
        for (int i = 0; i<width*height; i++) {

            pImage[i*4] = 0xFF;
            pImage[i*4+1] = 0x00;
            pImage[i*4+2] = 0x00;
            pImage[i*4+3] = 0xFF;
        }

        if(texHorizontal)
            glDeleteTextures(1, &texHorizontal);
        texHorizontal = [self textureFromBufferObject:pImage Width:width Height:height];

        if(texVertical)
            glDeleteTextures(1, &texVertical);
        texVertical = [self textureFromBufferObject:pImage Width:width Height:height];

        blurTextureWidth = width;
        blurTextureHeight = height;
        free(pImage);
    }
    
    if(!fboHorizontal)
        glGenFramebuffers(1, &fboHorizontal);
    
    if(!fboVertical)
        glGenFramebuffers(1, &fboVertical);
    
    return 1;
}
-(int)renderFullScreenGaussBlurWithBlurIntensity:(float)blurIntensity BackGroundTexture:(GLuint)bkTexture Vertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates
{
    int height = frameSize.height;
    int width = frameSize.width;
    NSArray* pointArray = [NSArray arrayWithObjects:NSStringFromCGPoint(CGPointMake(0.0, 0.0)),
                            NSStringFromCGPoint(CGPointMake(1.0, 0.0)),NSStringFromCGPoint(CGPointMake(1.0, 1.0)),
                            NSStringFromCGPoint(CGPointMake(0.0, 1.0)),nil];
    
    float blurValue = blurIntensity*12.0;
    int number = MAX_GUASSBLUR_INTENSITY;//(((int)(MAX_GUASSBLUR_INTENSITY*blurIntensity)) == 0)?1:(MAX_GUASSBLUR_INTENSITY*blurIntensity);
    if(number%2 != 0)
        number += 1;
    
    if (blurTextureHeight != height || blurTextureWidth != width) {

        unsigned char* pImage = (unsigned char*)malloc(width*height*4);
        for (int i = 0; i<width*height; i++) {

            pImage[i*4] = 0xFF;
            pImage[i*4+1] = 0x00;
            pImage[i*4+2] = 0x00;
            pImage[i*4+3] = 0xFF;
        }

        if(texHorizontal)
            glDeleteTextures(1, &texHorizontal);
        texHorizontal = [self textureFromBufferObject:pImage Width:width Height:height];

        if(texVertical)
            glDeleteTextures(1, &texVertical);
        texVertical = [self textureFromBufferObject:pImage Width:width Height:height];

        blurTextureWidth = width;
        blurTextureHeight = height;
        free(pImage);
    }
    
    for (int i = 1; i<=number; i++)
    {
        if (i%2 == 0) {
            
            if(!fboHorizontal)
                glGenFramebuffers(1, &fboHorizontal);


            glBindFramebuffer(GL_FRAMEBUFFER, fboHorizontal);
            glViewport(0, 0, width, height);


            // Attach the destination texture as a color attachment to the off screen frame buffer
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texHorizontal, 0);

            if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
                NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
            }

            [self renderTotexture:texVertical StartValue:0 EndValue:blurValue PointArray:pointArray BlurType:0
                         Vertices:vertices textureCoordinates:textureCoordinates];
            glBindFramebuffer(GL_FRAMEBUFFER, 0);
           
        }
        else
        {

            if(!fboVertical)
                glGenFramebuffers(1, &fboVertical);

            glBindFramebuffer(GL_FRAMEBUFFER, fboVertical);
            glViewport(0, 0, width, height);


            // Attach the destination texture as a color attachment to the off screen frame buffer
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texVertical, 0);

            if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
                NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
            }

            if(i == 1 )
                [self renderTotexture:bkTexture StartValue:blurValue EndValue:0
                           PointArray:pointArray BlurType:0 Vertices:vertices textureCoordinates:textureCoordinates];
            else
                [self renderTotexture:texHorizontal StartValue:blurValue EndValue:0 PointArray:pointArray BlurType:0 Vertices:vertices textureCoordinates:textureCoordinates];
            glBindFramebuffer(GL_FRAMEBUFFER, 0);
            
        }
    }
    return 0;
}
-(int)renderWhiteColorFillGaussBlurWithPointArray:(NSArray*)pointsArray Vertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates
{
    int height = frameSize.height;
    int width = frameSize.width;
    
    if (grayTextureHeight != height || grayTextureWidth != width) {

        unsigned char* pImage = (unsigned char*)malloc(width*height*4);
        for (int i = 0; i<width*height; i++) {

            pImage[i*4] = 0x00;
            pImage[i*4+1] = 0x00;
            pImage[i*4+2] = 0x00;
            pImage[i*4+3] = 0xFF;
        }

        if(texWhiteColor)
            glDeleteTextures(1, &texWhiteColor);
        texWhiteColor = [self textureFromBufferObject:pImage Width:width Height:height];
        
        if(texBlackColor)
            glDeleteTextures(1, &texBlackColor);
        texBlackColor = [self textureFromBufferObject:pImage Width:width Height:height];
        
        

        grayTextureWidth = width;
        grayTextureHeight = height;
        free(pImage);
    }
    
    if(!fboGray)
        glGenFramebuffers(1, &fboGray);

    glBindFramebuffer(GL_FRAMEBUFFER, fboGray);
    glViewport(0, 0, width, height);


    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texWhiteColor, 0);

    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
    
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(grayProgram);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texBlackColor);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); // S方向上的贴图模式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE); // T方向上的贴图模式
    // 线性过滤：使用距离当前渲染像素中心最近的4个纹理像素加权平均值
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glUniform1i(grayInputTextureUniform, 0);
    
    //获取模糊区域坐标
    CGPoint pointTL= CGPointFromString([pointsArray objectAtIndex:0]);
    CGPoint pointTR= CGPointFromString([pointsArray objectAtIndex:1]);
    CGPoint pointBR= CGPointFromString([pointsArray objectAtIndex:2]);
    CGPoint pointBL= CGPointFromString([pointsArray objectAtIndex:3]);
    //设置模糊区域坐标
    glUniform2f(grayPointTLUniform, pointTL.x, pointTL.y);
    glUniform2f(grayPointTRUniform, pointTR.x, pointTR.y);
    glUniform2f(grayPointBLUniform, pointBL.x, pointBL.y);
    glUniform2f(grayPointBRUniform, pointBR.x, pointBR.y);
    
    
    glVertexAttribPointer(grayPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(grayTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    return 0;
}

-(int)renderGaussBlurWithTexture:(GLuint)srcTexture Vertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates
{
    int height = frameSize.height;
    int width = frameSize.width;
    
    if (textureWidth != height || textureHeight != width) {

        unsigned char* pImage = (unsigned char*)malloc(width*height*4);
        for (int i = 0; i<width*height; i++) {

            pImage[i*4] = 0x00;
            pImage[i*4+1] = 0x00;
            pImage[i*4+2] = 0x00;
            pImage[i*4+3] = 0xFF;
        }

        if(texGaussBlur)
            glDeleteTextures(1, &texGaussBlur);
        texGaussBlur = [self textureFromBufferObject:pImage Width:width Height:height];
        
        textureWidth = width;
        textureHeight = height;
        free(pImage);
    }
    
    if(!fboGaussblur)
        glGenFramebuffers(1, &fboGaussblur);

    glBindFramebuffer(GL_FRAMEBUFFER, fboGaussblur);
    glViewport(0, 0, width, height);


    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texGaussBlur, 0);

    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
    
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(simpleProgram);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, srcTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); // S方向上的贴图模式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE); // T方向上的贴图模式
    // 线性过滤：使用距离当前渲染像素中心最近的4个纹理像素加权平均值
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glUniform1i(simpleInputTextureUniform, 0);
    
    glVertexAttribPointer(simplePositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(simpleTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    return 0;
}

-(int)renderGaussBlurWithBackGroundTexture:(GLuint)bkTexture FullScreenGaussblurTexture:(GLuint)blurTexture GrayTexture:(GLuint)whiteColorTexture
                                  Vertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates
{
    int height = frameSize.height;
    int width = frameSize.width;
    
    if (mvTextureHeight != height || mvTextureWidth != width) {

        unsigned char* pImage = (unsigned char*)malloc(width*height*4);
        for (int i = 0; i<width*height; i++) {

            pImage[i*4] = 0x00;
            pImage[i*4+1] = 0x00;
            pImage[i*4+2] = 0x00;
            pImage[i*4+3] = 0xFF;
        }

        if(texMV)
            glDeleteTextures(1, &texMV);
        texMV = [self textureFromBufferObject:pImage Width:width Height:height];

        mvTextureWidth = width;
        mvTextureHeight = height;
        free(pImage);
    }
    
    if(!fboMV)
        glGenFramebuffers(1, &fboMV);

    glBindFramebuffer(GL_FRAMEBUFFER, fboMV);
    glViewport(0, 0, width, height);


    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texMV, 0);

    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
    
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(mvProgram);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, bkTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); // S方向上的贴图模式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE); // T方向上的贴图模式
    // 线性过滤：使用距离当前渲染像素中心最近的4个纹理像素加权平均值
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glUniform1i(mvInputTextureUniform, 0);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, whiteColorTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); // S方向上的贴图模式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE); // T方向上的贴图模式
    // 线性过滤：使用距离当前渲染像素中心最近的4个纹理像素加权平均值
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glUniform1i(mvInputGrayTextureUniform, 1);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, blurTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); // S方向上的贴图模式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE); // T方向上的贴图模式
    // 线性过滤：使用距离当前渲染像素中心最近的4个纹理像素加权平均值
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glUniform1i(mvInputGaussBlurTextureUniform, 2);
    
    
    glVertexAttribPointer(mvProgram, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(mvProgram, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    return 0;
}
- (bool)renderBlurToFrameBufferObjectWithTime:(float)seconds Vertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates
{

    
    bool hasBlur = false;
    int width = frameSize.width;
    int height = frameSize.height;
    int blockNum = 0;
    
    
    //检查当前时间是否有模糊效果
    for(int j = 0; j < _blurBlocks.count; j++)
    {
        CMTimeRange stickersTimeRange = ([[_blurBlocks objectAtIndex:j] timeRange]);
        float stickersStartTime = CMTimeGetSeconds(stickersTimeRange.start);
        float stickersEndTime = stickersStartTime + CMTimeGetSeconds(stickersTimeRange.duration);
    //        NSLog(@"seconds ：%f stickersStartTime:%f stickersEndTime:%f ",seconds,stickersStartTime,stickersEndTime);
        if (seconds < stickersStartTime || seconds > stickersEndTime) {
            continue;
        }
        else
        {
            hasBlur = true;
            break;
        }

    }
//    没有模糊效果，直接返回false
    if(!hasBlur)
        return false;

    
    for(int j = 0; j < _blurBlocks.count;j++)
    {

        RDAssetBlur *blurBlock = [_blurBlocks objectAtIndex:j];
        float blurIntensity = blurBlock.intensity;
        NSArray *pointArray = blurBlock.pointsArray;
        float blueType = blurBlock.type;

        CMTimeRange stickersTimeRange = ([[_blurBlocks objectAtIndex:j] timeRange]);
        float stickersStartTime = CMTimeGetSeconds(stickersTimeRange.start);
        float stickersEndTime = stickersStartTime + CMTimeGetSeconds(stickersTimeRange.duration);

        //如果有多个模糊效果，检查当前时间点应该显示的模糊效果
        if (seconds < stickersStartTime || seconds > stickersEndTime) {
    //           NSLog(@"i = %d stickersStartTime = %f stickersEndTime=%f seconds=%f",i,stickersStartTime,stickersEndTime,seconds);
        }
        else
        {
            //1.对画面做全屏模糊
            [self renderFullScreenGaussBlurWithBlurIntensity:blurIntensity BackGroundTexture:[firstInputFramebuffer texture] Vertices:vertices textureCoordinates:textureCoordinates];
            
            //2.构造灰度图
            [self renderWhiteColorFillGaussBlurWithPointArray:pointArray Vertices:vertices textureCoordinates:textureCoordinates];
            
            //3.透黑色
            if(blockNum == 0)
                [self renderGaussBlurWithBackGroundTexture:[firstInputFramebuffer texture] FullScreenGaussblurTexture:texVertical GrayTexture:texWhiteColor Vertices:vertices textureCoordinates:textureCoordinates];
            else
                [self renderGaussBlurWithBackGroundTexture:texGaussBlur FullScreenGaussblurTexture:texVertical GrayTexture:texWhiteColor Vertices:vertices textureCoordinates:textureCoordinates];
            
            //4.将绘制的结果保存到临时缓冲区，作为最终结果显示或者作为下一个高斯模糊块的底图
            [self renderGaussBlurWithTexture:texMV Vertices:vertices textureCoordinates:textureCoordinates];
            blockNum++;
        }
    }
    return true;
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates{
    
    bool hasBlur = false;
    NSArray* pointsArray = [NSArray arrayWithObjects:NSStringFromCGPoint(CGPointMake(0.0, 0.0)),
                            NSStringFromCGPoint(CGPointMake(0.0, 0.0)),NSStringFromCGPoint(CGPointMake(0.0, 0.0)),
                            NSStringFromCGPoint(CGPointMake(0.0, 0.0)),nil];
    
    if (self.preventRendering)
    {
        [firstInputFramebuffer unlock];
        return;
    }
    frameSize = [self sizeOfFBO];

    //处理模糊
//    [RDGPUImageContext setActiveShaderProgram:filterProgram];
    hasBlur = [self renderBlurToFrameBufferObjectWithTime:currentTime Vertices:vertices textureCoordinates:textureCoordinates];
   

    [RDGPUImageContext setActiveShaderProgram:filterProgram];
    outputFramebuffer = [[RDGPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    if (usingNextFrameForImageCapture)
    {
        [outputFramebuffer lock];
    }
    CVPixelBufferRef p = [outputFramebuffer pixelBuffer];
    
    //绘制处理好的frameBuffer
//    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
//    glClear(GL_COLOR_BUFFER_BIT);

    [self setUniformsForProgramAtIndex:0];
    
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE2);

    if (hasBlur) {
            glBindTexture(GL_TEXTURE_2D, texGaussBlur);
    }
    else
        glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    
    glUniform1i(filterInputTextureUniform, 2);
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [firstInputFramebuffer unlock];
    if (usingNextFrameForImageCapture)
    {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
    
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
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}
- (BOOL)loadShaders
{
    blurProgram = glCreateProgram();
    grayProgram = glCreateProgram();
    mvProgram = glCreateProgram();
    simpleProgram = glCreateProgram();
    
    if (![self compileShader:&blurVertShader type:GL_VERTEX_SHADER source:kRDGaussianBlurDYVertexShaderString]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    if (![self compileShader:&blurFragShader type:GL_FRAGMENT_SHADER source:kRDGaussianBlurDYFragmentShaderString]) {
        NSLog(@"Failed to compile cust fragment shader");
        return NO;
    }
    
    if (![self compileShader:&grayVertShader type:GL_VERTEX_SHADER source:kRDGaussianBlurDYVertexShaderString]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    if (![self compileShader:&grayFragShader type:GL_FRAGMENT_SHADER source:kRDGrayFillFragmentShaderString]) {
        NSLog(@"Failed to compile cust fragment shader");
        return NO;
    }
    
    if (![self compileShader:&mvVertShader type:GL_VERTEX_SHADER source:kRDGaussianBlurDYVertexShaderString]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    if (![self compileShader:&mvFragShader type:GL_FRAGMENT_SHADER source:kRDMVDYFragmentShaderString]) {
        NSLog(@"Failed to compile cust fragment shader");
        return NO;
    }
    
    if (![self compileShader:&simpleVertShader type:GL_VERTEX_SHADER source:kRDGaussianBlurDYVertexShaderString]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    if (![self compileShader:&simpleFragShader type:GL_FRAGMENT_SHADER source:kRDSimpleDYFragmentShaderString]) {
        NSLog(@"Failed to compile cust fragment shader");
        return NO;
    }
    
    
    
    glAttachShader(blurProgram, blurVertShader);
    glAttachShader(blurProgram, blurFragShader);
    
    glAttachShader(grayProgram, grayVertShader);
    glAttachShader(grayProgram, grayFragShader);
    
    glAttachShader(mvProgram, mvVertShader);
    glAttachShader(mvProgram, mvFragShader);
    
    glAttachShader(simpleProgram, simpleVertShader);
    glAttachShader(simpleProgram, simpleFragShader);
    
    
    // Link the program.
    if (![self linkProgram:blurProgram] ||
        ![self linkProgram:grayProgram] ||
        ![self linkProgram:mvProgram] ||
        ![self linkProgram:simpleProgram]) {
        
        if (blurVertShader) {
            glDeleteShader(blurVertShader);
            blurVertShader = 0;
        }
        if (blurFragShader) {
            glDeleteShader(blurFragShader);
            blurFragShader = 0;
        }
        
        if (grayVertShader) {
            glDeleteShader(grayVertShader);
            grayVertShader = 0;
        }
        if (grayFragShader) {
            glDeleteShader(grayFragShader);
            grayFragShader = 0;
        }
        
        if (mvVertShader) {
            glDeleteShader(mvVertShader);
            mvVertShader = 0;
        }
        if (mvFragShader) {
            glDeleteShader(mvFragShader);
            mvFragShader = 0;
        }
        
        if (simpleVertShader) {
            glDeleteShader(simpleVertShader);
            simpleVertShader = 0;
        }
        if (simpleFragShader) {
            glDeleteShader(simpleFragShader);
            simpleFragShader = 0;
        }
        
        return NO;
    }
    
   
    blurStartValueUniform = glGetUniformLocation(blurProgram, "startValue");
    blurEndValueUniform = glGetUniformLocation(blurProgram, "endValue");
    blurDirectionUniform = glGetUniformLocation(blurProgram, "direction");
    blurResolutionUniform = glGetUniformLocation(blurProgram, "size");
    blurPointBLUniform = glGetUniformLocation(blurProgram, "pointLB");
    blurPointTLUniform = glGetUniformLocation(blurProgram, "pointLT");
    blurPointTRUniform = glGetUniformLocation(blurProgram, "pointRT");
    blurPointBRUniform = glGetUniformLocation(blurProgram, "pointRB");
    blurTypeUniform = glGetUniformLocation(blurProgram, "blurType");
    blurPositionAttribute = glGetAttribLocation(blurProgram, "position");
    blurTextureCoordinateAttribute = glGetAttribLocation(blurProgram, "inputTextureCoordinate");
    blurInputTextureUniform = glGetUniformLocation(blurProgram, "inputImageTexture");

    grayPointBLUniform = glGetUniformLocation(grayProgram, "pointLB");
    grayPointTLUniform = glGetUniformLocation(grayProgram, "pointLT");
    grayPointTRUniform = glGetUniformLocation(grayProgram, "pointRT");
    grayPointBRUniform = glGetUniformLocation(grayProgram, "pointRB");
    grayPositionAttribute = glGetAttribLocation(grayProgram, "position");
    grayTextureCoordinateAttribute = glGetAttribLocation(grayProgram, "inputTextureCoordinate");
    grayInputTextureUniform = glGetUniformLocation(grayProgram, "inputImageTexture");
    

    mvPositionAttribute = glGetAttribLocation(mvProgram, "position");
    mvTextureCoordinateAttribute = glGetAttribLocation(mvProgram, "inputTextureCoordinate");
    mvInputTextureUniform = glGetUniformLocation(mvProgram, "inputImageTexture");
    mvInputGrayTextureUniform = glGetUniformLocation(mvProgram, "inputImageGrayTexture");
    mvInputGaussBlurTextureUniform = glGetUniformLocation(mvProgram, "inputImageGaussBlurTexture");
    
    simplePositionAttribute = glGetAttribLocation(simpleProgram, "position");
    simpleTextureCoordinateAttribute = glGetAttribLocation(simpleProgram, "inputTextureCoordinate");
    simpleInputTextureUniform = glGetUniformLocation(simpleProgram, "inputImageTexture");
   
    
    
    // Release vertex and fragment shaders.
    if (blurVertShader) {
        glDetachShader(blurProgram, blurVertShader);
        glDeleteShader(blurVertShader);
    }
    if (blurFragShader) {
        glDetachShader(blurProgram, blurFragShader);
        glDeleteShader(blurFragShader);
    }
    
    if (grayVertShader) {
        glDeleteShader(grayVertShader);
        grayVertShader = 0;
    }
    if (grayFragShader) {
        glDeleteShader(grayFragShader);
        grayFragShader = 0;
    }
    
    if (mvVertShader) {
        glDeleteShader(mvVertShader);
        mvVertShader = 0;
    }
    if (mvFragShader) {
        glDeleteShader(mvFragShader);
        mvFragShader = 0;
    }
    
    if (simpleVertShader) {
        glDeleteShader(simpleVertShader);
        simpleVertShader = 0;
    }
    if (simpleFragShader) {
        glDeleteShader(simpleFragShader);
        simpleFragShader = 0;
    }
    
    return YES;
}

- (instancetype)init
{
    if (!(self = [super init])) {
            return nil;
        }
   
        
//    if (!(self = [super initWithFragmentShaderFromString:kRDGaussianBlurDYFragmentShaderString])) {
//        return nil;
//    }
//
//    intensityUniform = [filterProgram uniformIndex:@"intensity"];
//    directionUniform = [filterProgram uniformIndex:@"direction"];
//    resolutionUniform = [filterProgram uniformIndex:@"resolution"];
//    blurPointBLUniform = [filterProgram uniformIndex:@"pointLB"];
//    blurPointTLUniform = [filterProgram uniformIndex:@"pointLT"];
//    blurPointTRUniform = [filterProgram uniformIndex:@"pointRT"];
//    blurPointBRUniform = [filterProgram uniformIndex:@"pointRB"];
//    blurTypeUniform = [filterProgram uniformIndex:@"blurType"];
//    blurInputTextureUniform = [filterProgram uniformIndex:@"inputImageTexture"];
    
    if(![self loadShaders]){
        NSLog(@"gauss blure filter load shader fail!");
        return nil;
    }
        
    return self;
}


- (void)dealloc{
    
    if (fboHorizontal) {
        glDeleteFramebuffers(1, &fboHorizontal);
        fboHorizontal = 0;
    }
    if (fboVertical) {
        glDeleteFramebuffers(1,&fboVertical);
        fboVertical = 0;
    }
    if (fboGray) {
        glDeleteFramebuffers(1,&fboGray);
        fboGray = 0;
    }
    if (fboMV) {
        glDeleteFramebuffers(1,&fboMV);
        fboMV = 0;
    }
    if (fboGaussblur) {
        glDeleteFramebuffers(1,&fboGaussblur);
        fboGaussblur = 0;
    }
    if(texHorizontal)
    {
        glDeleteTextures(1, &texHorizontal);
        texHorizontal = 0;
    }
    if(texVertical)
    {
        glDeleteTextures(1, &texVertical);
        texVertical = 0;
    }
    if(texBlackColor)
    {
        glDeleteTextures(1, &texBlackColor);
        texBlackColor = 0;
    }
    if(texWhiteColor)
    {
        glDeleteTextures(1, &texWhiteColor);
        texWhiteColor = 0;
    }
    if(texMV)
    {
        glDeleteTextures(1, &texMV);
        texMV = 0;
    }
    if(texGaussBlur)
    {
        glDeleteTextures(1, &texGaussBlur);
        texGaussBlur = 0;
    }
    if (blurProgram) {
        glDeleteProgram(blurProgram);
    }
    if (grayProgram) {
        glDeleteProgram(grayProgram);
    }
    if (mvProgram) {
        glDeleteProgram(mvProgram);
    }
    if (simpleProgram) {
        glDeleteProgram(simpleProgram);
    }
}
@end


