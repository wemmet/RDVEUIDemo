//
//  RDMaskFilter.m
//  RDVECore
//
//  Created by apple on 2018/4/23.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDMaskFilter.h"

NSString *const kRDMaskFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureMaskCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2; // Mask texture
 
 //uniform lowp float intensity;
 
 
 
 void main()
 {

     highp vec4 textureColor  = texture2D(inputImageTexture,  textureCoordinate);
     highp vec4 textureColor2 = texture2D(inputImageTexture2, textureMaskCoordinate);
     
     
#if 1
     lowp float newAlpha = dot(textureColor2.rgb,vec3(0.333333334,0.333333334,0.333333334)) *textureColor2.a;
     textureColor = vec4(textureColor.xyz,newAlpha);
     
     if(textureColor.r < 0.0 && textureColor.b < 0.0 && textureColor.g < 0.0  )
         textureColor.a = 0.0;
     gl_FragColor = textureColor;
#else
     
     if(textureColor2.r < 0.1 && textureColor2.b < 0.1 && textureColor2.g < 0.1  )
     {
         textureColor.r = textureColor2.r;
         textureColor.b = textureColor2.b;
         textureColor.g = textureColor2.g;
         
     }
     textureColor.a= 1.0;
     
     if(textureColor.r < 0.1 && textureColor.b < 0.1 && textureColor.g < 0.1  )
     {
         textureColor.a = 0.0;
     }
     
     gl_FragColor = textureColor;
#endif

 }
 );
@interface RDMaskFilter()
{
    GLuint _imageTexture;
}
@end
@implementation RDMaskFilter
- (instancetype)initWithImage:(UIImage *)image{
    if (!(self = [super initWithFragmentShaderFromString:kRDMaskFragmentShaderString])) {
        return nil;
    }
    
    //intensityUniform = [filterProgram uniformIndex:@"intensity"];
    inputImageTexture2Uniform = [filterProgram uniformIndex:@"inputImageTexture2"];
    
    int imageWidth = image.size.width;
    int imageHeight = image.size.height;
    
    CGImageRef cgImage = [image CGImage];
    
    void* imageData = (void*)calloc(1, (int)imageWidth*(int)imageHeight*4);
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef imageContext = CGBitmapContextCreate(imageData, imageWidth, imageHeight, 8, 4*imageWidth, genericRGBColorspace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, imageWidth, imageHeight), cgImage);
    CGContextRelease(imageContext);
    CGColorSpaceRelease(genericRGBColorspace);
    
    glGenTextures(1, &_imageTexture);
    glBindTexture(GL_TEXTURE_2D, _imageTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, (GLvoid*)imageData);
    
    
    free(imageData);
    
 //   self.intensity = 1.0f;
    return self;
}
- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates{
    
    if (self.preventRendering)
    {
        [firstInputFramebuffer unlock];
        return;
    }
    
    [RDGPUImageContext setActiveShaderProgram:filterProgram];
    
    outputFramebuffer = [[RDGPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    if (usingNextFrameForImageCapture)
    {
        [outputFramebuffer lock];
    }
    
    [self setUniformsForProgramAtIndex:0];
    
    //开启blend
    glEnable(GL_BLEND);
    //        //    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    
    glUniform1i(filterInputTextureUniform, 2);
    
    glActiveTexture(GL_TEXTURE3);
    glBindTexture(GL_TEXTURE_2D, _imageTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, self.outputTextureOptions.wrapS);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, self.outputTextureOptions.wrapT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, self.outputTextureOptions.minFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, self.outputTextureOptions.magFilter);    
    
    glUniform1i(inputImageTexture2Uniform, 3);
//    glUniform1i(intensityUniform, 0.5f);
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glEnableVertexAttribArray(filterPositionAttribute);

    
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    glEnableVertexAttribArray(filterTextureCoordinateAttribute);

    GLfloat quadTextureData2 [] = { //纹理坐标

        1.0f, 1.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
    };
    
    glVertexAttribPointer(filterTextureMaskCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData2);
    glEnableVertexAttribArray(filterTextureMaskCoordinateAttribute);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [firstInputFramebuffer unlock];
    
    if (usingNextFrameForImageCapture)
    {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
    
    
    
}
//- (void)setIntensity:(CGFloat)intensity
//{
//    _intensity = intensity;
//
//    [self setFloat:_intensity forUniform:intensityUniform program:filterProgram];
//
//}

- (instancetype)initWithImagePath:(NSString *)path
{
    UIImage* image = [UIImage imageWithContentsOfFile:path];
    return [self initWithImage:image];
}
- (instancetype)initWithImageNamed:(NSString *)name{
    UIImage* image = [UIImage imageNamed:name];
    return [self initWithImage:image];
}
- (void)dealloc{
    glDeleteTextures(1, &_imageTexture);
}
@end
