//
//  RDParticleRender.m
//  RDVECore
//
//  Created by apple on 2018/5/16.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDQuadsRender.h"
#import "RDMatrix.h"

NSString*  const kRDSimpleVertexShader = SHADER_STRING
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

NSString*  const kRDQuadsVertexShader = SHADER_STRING
(
 
 
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;

 
 uniform mat4 projection;
 uniform mat4 renderTransform;
 varying vec2 textureCoordinate;
 
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
     
     vMatrixWarp = quadMat();
 }
 );

NSString *const kRDSimpleFragmentShader = SHADER_STRING
(
 
 
 precision highp float;
 varying vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
);
NSString *const kRDQuadsFragmentShader = SHADER_STRING
(
 

 precision highp float;
 varying vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform float alpha;
 
// void main()
// {
//     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
// }
 
 
 const vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
 
 uniform highp vec2  SrcQuadrilateral[4];  //源四边形的4个顶点在源纹理上的坐标-纹理的裁剪，顺时针0-1，左上角为0.0
 uniform highp vec2  DstQuadrilateral[4];  //目标四边形的4个顶点在渲染结果(纹理)中的坐标-纹理的显示位置，顺时针0-1，左上角为0.0
 
 varying mat3  vMatrixWarp;
 varying vec2  vQuadLine[4];
 varying vec2  vQuadDstPts[4];
 uniform vec2  DstSinglePixelSize; //单个像素在目标纹理中的大小。例如目标纹理将被渲染为 800*600 的矩形，那么单个像素就是 1/800, 1/600
 
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
         
         outColor  = vec4( texture2D(inputTexture, vec2(x,y) ) );
         outColor.a  *= inside;//=inside; //20180801 fix bug:png的alpha通道不起作用
         
         return outColor;
         
     }
     else
     {
         discard;
     }
     
 }
 
 void main(){
     vec4 outColor = ConverCoordinate(inputImageTexture,textureCoordinate);
     outColor.a  *= alpha;
     gl_FragColor = outColor;
 }
 
 );

@interface RDQuadsRender()

{
    GLuint vertShader, fragShader;
    GLuint program;
    GLuint positionAttribute,textureCoordinateAttribute,inputTextureUniform,projectionUniform,transformUniform;
    GLuint srcQuadrilateralUniform;//源四边形的4顶点在纹理上的坐标-纹理的裁剪，顺时针0-1，左上角为0.0
    GLuint dstQuadrilateralUniform;//目标四边形的4个顶点坐标-四边形的显示位置，顺时针0-1，左上角为0.0
    GLuint dstSinglePixelSizeUniform;//单个像素在目标纹理中的大小。例如目标纹理将被渲染为 800*600 的矩形，那么单个像素就是 1/800, 1/600
    GLuint alphaUniform;
    
    RDMatrix4 _modelViewMatrix;
    RDMatrix4 _projectionMatrix;

    float currentTime;
    
    int viewWidth;
    int viewHeight;
    GLuint imageTexture;
    GLuint offscreenSubtitleBufferHandle;
}


@end
@implementation RDQuadsRender


- (id)init
{
    self = [super init];
    if(self) {
        
        if (!(self = [super initWithVertexShaderFromString:kRDQuadsVertexShader fragmentShaderFromString:kRDQuadsFragmentShader])) {
            return nil;
        }


        positionAttribute = [filterProgram attributeIndex:@"position"];
        textureCoordinateAttribute = [filterProgram attributeIndex:@"inputTextureCoordinate"];
        inputTextureUniform = [filterProgram uniformIndex:@"inputImageTexture"];
        projectionUniform = [filterProgram uniformIndex:@"projection"];
        transformUniform = [filterProgram uniformIndex:@"renderTransform"];

        srcQuadrilateralUniform = [filterProgram uniformIndex:@"SrcQuadrilateral"];
        dstQuadrilateralUniform = [filterProgram uniformIndex:@"DstQuadrilateral"];
        dstSinglePixelSizeUniform = [filterProgram uniformIndex:@"DstSinglePixelSize"];
        alphaUniform = [filterProgram uniformIndex:@"alpha"];
    }
    
    return self;
}



- (GLuint)textureFromImage:(NSString *) image
{
    CGImageRef        brushImage;
    CGContextRef    brushContext;
    GLubyte            *brushData;
    int width = 0;
    int height = 0;
    GLuint texture = 0;
    
    
    // First create a UIImage object from the data in a image file, and then extract the Core Graphics image
    brushImage = [UIImage imageWithContentsOfFile:image].CGImage;
    
    // Get the width and height of the image
    width = CGImageGetWidth(brushImage);
    height = CGImageGetHeight(brushImage);
    
    // Make sure the image exists
    if(brushImage) {
        // Allocate  memory needed for the bitmap context
        brushData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte));
        // Use  the bitmatp creation function provided by the Core Graphics framework.
        brushContext = CGBitmapContextCreate(brushData, width, height, 8, width * 4, CGImageGetColorSpace(brushImage), kCGImageAlphaPremultipliedLast);
        // After you create the context, you can draw the  image to the context.
        CGContextDrawImage(brushContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), brushImage);
        // You don't need the context at this point, so you need to release it to avoid memory leaks.
        CGContextRelease(brushContext);
        
        glEnable(GL_TEXTURE_2D);
        glGenTextures(1, &texture);
        glBindTexture(GL_TEXTURE_2D, texture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)width, (int)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid*)brushData);
        
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
        
        free(brushData);
        return texture;
        
    }
    NSLog(@"Failed to create texture from image: %@", image);
    return -1;
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


- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates{
    

    CGSize frameSize ;
    GLuint textureImage = 0;
    //矩形显示
    GLfloat SrcVert[4][2]={{0.0,0.0},{1.0,0.0},{1.0,1.0},{0.0,1.0}};
    //GLfloat SrcVert[4][2]={{0.1,0.1},{0.99,0.1},{0.99,0.9},{0.1,0.9}};
    GLfloat DstVert[4][2]={{0.0,0.0},{1.0,0.0},{1.0,1.0},{0.0,1.0}};
//    GLfloat DstVert[4][2]={{1.0/100.0,0.3},{0.8,0.1},{1.0,1.0},{0.3,0.6}};
    float alpha = 1.0;
    
    GLfloat quadTextureData[8] = {

        
        0.0,1.0,
        1.0,1.0,
        0.0,0.0,
        1.0,0.0,
    };
    GLfloat quadVertexData [8] = {
        
        -1.0,1.0,
        1.0,1.0,
        -1.0,-1.0,
        1.0,-1.0,
    };
    
    if (self.preventRendering)
    {
        [firstInputFramebuffer unlock];
        return;
    }
    

    frameSize = [self sizeOfFBO];
    [RDGPUImageContext setActiveShaderProgram:filterProgram];
    
    outputFramebuffer = [[RDGPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    if (usingNextFrameForImageCapture)
    {
        [outputFramebuffer lock];
    }
//    CVPixelBufferRef p = [outputFramebuffer pixelBuffer];
    [self setUniformsForProgramAtIndex:0];
    
    //开启blend
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    
    glUniform1i(filterInputTextureUniform, 2);
    
    RDMatrixLoadIdentity(&_modelViewMatrix);
    glUniformMatrix4fv(transformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
    
    RDMatrixLoadIdentity(&_projectionMatrix);
    RDMatrixTranslate(&_projectionMatrix,0.0 , 0.0, 0);
    
    glUniformMatrix4fv(projectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
    
    
    //        //矩形显示
    //        GLfloat SrcVert[4][2]={{0.0,0.0},{1.0,0.0},{1.0,1.0},{0.0,1.0}};
    //        //                GLfloat SrcVert[4][2]={{0.1,0.1},{0.99,0.1},{0.99,0.9},{0.1,0.9}};
    //        //GLfloat DstVert[4][2]={{0.0,0.0},{1.0,0.0},{1.0,1.0},{0.0,1.0}};
    //        GLfloat DstVert[4][2]={{1.0/100.0,0.3},{0.8,0.1},{1.0,1.0},{0.3,0.6}};
    
    glUniform2fv(srcQuadrilateralUniform, 4, SrcVert[0]);
    glUniform2fv(dstQuadrilateralUniform, 4, DstVert[0]);
    
    glUniform1f(alphaUniform, 1.0);
    
    glUniform2f(dstSinglePixelSizeUniform,1.0/(float)(frameSize.width),1.0/(float)(frameSize.height));
    
    glVertexAttribPointer(positionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData);
    glEnableVertexAttribArray(positionAttribute);
    
    glVertexAttribPointer(textureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
    glEnableVertexAttribArray(textureCoordinateAttribute);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    
    for(int i = 0; i < _captionLight.count;i++)
    {
        RDCaptionLight *caption = [_captionLight objectAtIndex:i];

        CMTimeRange timeRange = ([[_captionLight objectAtIndex:i] timeRange]);
        float startTime = CMTimeGetSeconds(timeRange.start);
        float endTime = startTime + CMTimeGetSeconds(timeRange.duration);

        if (currentTime < startTime || currentTime > endTime) {
            continue;
        }
        if(caption.animateList.count)
        {
            //如果有动画
            for (int i = 0; i < caption.animateList.count; i++)
            {
                RDCaptionLightCustomAnimate* _from = caption.animateList[i];
                RDCaptionLightCustomAnimate* _to;
                if (i == caption.animateList.count - 1) {
                    _to = caption.animateList[i];
                }else {
                    _to = caption.animateList[i+1];
                }

                if ( _from.atTime <= currentTime && _to.atTime >= currentTime)
                {
                    for (int j = 0; j<[_from.pointsArray count];j++)
                    {
                        DstVert[j][0] = [[[_from.pointsArray objectAtIndex:j] objectAtIndex:0] doubleValue];
                        DstVert[j][1] = [[[_from.pointsArray objectAtIndex:j] objectAtIndex:1] doubleValue];
                    }

                    alpha = _from.opacity;
                    break;
                }
                else
                    continue;
            }
        }
        else
        {
            //没有动画
            for(int i = 0;i<[caption.pointsInVideoArray count];i++)
            {
                DstVert[i][0] = [[[caption.pointsInVideoArray objectAtIndex:i] objectAtIndex:0] doubleValue];
                DstVert[i][1] = [[[caption.pointsInVideoArray objectAtIndex:i] objectAtIndex:1] doubleValue];
            }
            
            if (!caption.isFade)
                alpha = 1.0;
            else
            {
                float inDuration = caption.fadeInDuration;
                float outDuration = caption.fadeOutDuration;
                if (inDuration + outDuration > CMTimeGetSeconds(timeRange.duration)) {
                    if (outDuration > 0 && inDuration > 0) {
                        inDuration = CMTimeGetSeconds(timeRange.duration)/2.0;
                        outDuration = CMTimeGetSeconds(timeRange.duration)/2.0;
                    }else if (inDuration > 0) {
                        inDuration = CMTimeGetSeconds(timeRange.duration);
                    }else {
                        outDuration = CMTimeGetSeconds(timeRange.duration);
                    }
                }
                if(startTime + inDuration >= currentTime)
                    alpha = (currentTime - startTime)/inDuration;
                if(currentTime + outDuration >= endTime)
                    alpha = (endTime - currentTime)/outDuration;
            }
        }

        textureImage = [self textureFromImage:[[_captionLight objectAtIndex:i] imagePath]];
        glActiveTexture(GL_TEXTURE3);
        glBindTexture(GL_TEXTURE_2D, textureImage);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, self.outputTextureOptions.wrapS);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, self.outputTextureOptions.wrapT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, self.outputTextureOptions.minFilter);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, self.outputTextureOptions.magFilter);
        
        glUniform1i(inputTextureUniform, 3);
        
        RDMatrixLoadIdentity(&_modelViewMatrix);
        glUniformMatrix4fv(transformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
        
        RDMatrixLoadIdentity(&_projectionMatrix);
        RDMatrixTranslate(&_projectionMatrix,0.0 , 0.0, 0);
        
        glUniformMatrix4fv(projectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
        
        
//        //矩形显示
//        GLfloat SrcVert[4][2]={{0.0,0.0},{1.0,0.0},{1.0,1.0},{0.0,1.0}};
//        //                GLfloat SrcVert[4][2]={{0.1,0.1},{0.99,0.1},{0.99,0.9},{0.1,0.9}};
//        //GLfloat DstVert[4][2]={{0.0,0.0},{1.0,0.0},{1.0,1.0},{0.0,1.0}};
//        GLfloat DstVert[4][2]={{1.0/100.0,0.3},{0.8,0.1},{1.0,1.0},{0.3,0.6}};
        
        glUniform2fv(srcQuadrilateralUniform, 4, SrcVert[0]);
        glUniform2fv(dstQuadrilateralUniform, 4, DstVert[0]);
    
        glUniform1f(alphaUniform, alpha);
        
        glUniform2f(dstSinglePixelSizeUniform,1.0/(float)(frameSize.width),1.0/(float)(frameSize.height));
        
        glVertexAttribPointer(positionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData);
        glEnableVertexAttribArray(positionAttribute);
        
        glVertexAttribPointer(textureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
        glEnableVertexAttribArray(textureCoordinateAttribute);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        if(textureImage)
            glDeleteTextures(1, &textureImage);
    
    }
    [firstInputFramebuffer unlock];
    
    if (usingNextFrameForImageCapture)
    {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
    
    
    return;
}



- (void)dealloc
{
    if (offscreenSubtitleBufferHandle) {
        glDeleteFramebuffers(1,&offscreenSubtitleBufferHandle);
        offscreenSubtitleBufferHandle = 0;
    }
    
    if (program) {
        glDeleteProgram(program);
        program = 0;
    }
    
    if (vertShader) {
        glDetachShader(program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(program, fragShader);
        glDeleteShader(fragShader);
    }
}

@end

