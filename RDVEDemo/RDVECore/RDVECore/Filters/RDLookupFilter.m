//
//  RDLookupFilter.m
//  RDVECore
//
//  Created by 周晓林 on 2018/4/6.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDLookupFilter.h"



NSString* const kBackCameraVertexShader = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 uniform float texelWidth;
 uniform float texelHeight;
 
 varying vec2 blurCoordinates[9];
 
 void main(){
     vec2 singleStepOffset = vec2(texelWidth, texelHeight);
     blurCoordinates[0] = inputTextureCoordinate.xy;
     blurCoordinates[1] = inputTextureCoordinate.xy + singleStepOffset * vec2(1.0, 0.0);
     blurCoordinates[2] = inputTextureCoordinate.xy + singleStepOffset * vec2(-1.0, 0.0);
     blurCoordinates[3] = inputTextureCoordinate.xy + singleStepOffset * vec2(0.0, 1.0);
     blurCoordinates[4] = inputTextureCoordinate.xy + singleStepOffset * vec2(0.0, -1.0);
     blurCoordinates[5] = inputTextureCoordinate.xy + singleStepOffset * vec2(1.0, 1.0);
     blurCoordinates[6] = inputTextureCoordinate.xy + singleStepOffset * vec2(1.0, -1.0);
     blurCoordinates[7] = inputTextureCoordinate.xy + singleStepOffset * vec2(-1.0, 1.0);
     blurCoordinates[8] = inputTextureCoordinate.xy + singleStepOffset * vec2(-1.0, -1.0);
     
     gl_Position = position;
 }
 );

NSString* const kBackCameraFragmentShader = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 varying highp vec2 blurCoordinates[9];
 uniform highp float intensity;
 uniform highp float saturation;
 const highp vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
 void main()
{
    lowp vec4 sum = vec4(0.0);
    sum += texture2D(inputImageTexture, blurCoordinates[0]);
    sum += texture2D(inputImageTexture, blurCoordinates[1]);
    sum += texture2D(inputImageTexture, blurCoordinates[2]);
    sum += texture2D(inputImageTexture, blurCoordinates[3]);
    sum += texture2D(inputImageTexture, blurCoordinates[4]);
    sum += texture2D(inputImageTexture, blurCoordinates[5]);
    sum += texture2D(inputImageTexture, blurCoordinates[6]);
    sum += texture2D(inputImageTexture, blurCoordinates[7]);
    sum += texture2D(inputImageTexture, blurCoordinates[8]);
    
    
    lowp vec3 blurredImageColor = sum.rgb / 9.0;
    lowp vec4 sharpImageColor = texture2D(inputImageTexture, blurCoordinates[0]);
    
    
    lowp vec3 highPass = sharpImageColor.rgb - blurredImageColor;
    
    lowp float luminance = dot(sharpImageColor.rgb, luminanceWeighting);
    lowp vec3 greyScaleColor = vec3(luminance);
    lowp vec3 color = sharpImageColor.rgb + highPass * intensity;
    
    gl_FragColor = vec4(mix(greyScaleColor, color, saturation), 1.0);
}
);


NSString *const kRDLookupFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2; // lookup texture
 
 uniform lowp float intensity;
 
 
 
 void main()
 {
     
     highp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     highp float blueColor = textureColor.b * 63.0;
     
     highp vec2 quad1;
     quad1.y = floor(floor(blueColor) / 8.0);
     quad1.x = floor(blueColor) - (quad1.y * 8.0);
     
     highp vec2 quad2;
     quad2.y = floor(ceil(blueColor) / 8.0);
     quad2.x = ceil(blueColor) - (quad2.y * 8.0);
     
     highp vec2 texPos1;
     texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
     texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
     
     highp vec2 texPos2;
     texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
     texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
     
     lowp vec4 newColor1 = texture2D(inputImageTexture2, texPos1);
     lowp vec4 newColor2 = texture2D(inputImageTexture2, texPos2);
     
     lowp vec4 newColor = mix(newColor1, newColor2, fract(blueColor));
     textureColor = mix(textureColor, vec4(newColor.rgb, textureColor.w), intensity);
     gl_FragColor = textureColor;
 }
 );
@interface RDLookupFilter()
{
    
    CGImageRef  f_cgImage;
    GLuint      _imageTexture;
    void*       imageData;
    int         imageHeight;
    int         imageWidth;
}

@end
@implementation RDLookupFilter



- (instancetype)initWithImage:(UIImage *)image intensity:(float)intensity{
    
    if (!(self = [super initWithFragmentShaderFromString:kRDLookupFragmentShaderString])) {
        return nil;
    }
    
    intensityUniform = [filterProgram uniformIndex:@"intensity"];
    inputImageTexture2Uniform = [filterProgram uniformIndex:@"inputImageTexture2"];
    
    imageWidth = 512;//image.size.width; //20180418 因上面都是用的512,如图片不是512*512, 会导致使用lookup滤镜时黑屏
    imageHeight = 512;//image.size.height;
    
//    NSLog(@"look up image width:%f height:%f ",image.size.width,image.size.height);
    
    CGImageRef cgImage = [image CGImage];
    
    imageData = (void*)calloc(1, (int)imageWidth*(int)imageHeight*4);
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef imageContext = CGBitmapContextCreate(imageData, imageWidth, imageHeight, 8, 4*imageWidth, genericRGBColorspace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, imageWidth, imageHeight), cgImage);
    CGContextRelease(imageContext);
    CGColorSpaceRelease(genericRGBColorspace);

    if (intensity < 0 || intensity > 1.0) {
        intensity = 1.0;
    }
    self.intensity = intensity;

    return self;

}



- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates{
    
    
    if (self.preventRendering)
    {
        [firstInputFramebuffer unlock];
        return;
    }
    
    [RDGPUImageContext setActiveShaderProgram:filterProgram];
    
    if(!_imageTexture)
    {
        glGenTextures(1, &_imageTexture);
        glBindTexture(GL_TEXTURE_2D, _imageTexture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, (GLvoid*)imageData);
        //  free(imageData);
    }
    
    outputFramebuffer = [[RDGPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    if (usingNextFrameForImageCapture)
    {
        [outputFramebuffer lock];
    }
    
    [self setUniformsForProgramAtIndex:0];
    
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    
    glUniform1i(filterInputTextureUniform, 2);
    
    
    glActiveTexture(GL_TEXTURE3);
    glBindTexture(GL_TEXTURE_2D, _imageTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    
    glUniform1i(inputImageTexture2Uniform, 3);
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [firstInputFramebuffer unlock];
    
    if (usingNextFrameForImageCapture)
    {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
    
    
    
}
- (void)setIntensity:(CGFloat)intensity
{
    _intensity = intensity;
    
    [self setFloat:_intensity forUniform:intensityUniform program:filterProgram];
    
}

- (instancetype)initWithImageNetPath:(NSString *)path intensity:(float)intensity
{
    UIImage* image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:path]]];
    if(image){
        return [self initWithImage:image intensity:intensity];
    }
    return nil;
    
}

- (instancetype)initWithImagePath:(NSString *)path intensity:(float)intensity {
    return [self initWithImage:[UIImage imageWithContentsOfFile:path]  intensity:intensity];
}

- (instancetype)initWithImageNamed:(NSString *)name intensity:(float)intensity{
    return [self initWithImage:[UIImage imageNamed:name] intensity:intensity];
}
- (void)dealloc{

//    glDeleteTextures(0, &_imageTexture);
    glDeleteTextures(1, &_imageTexture);//20180712 fix bug:每次切换lookup滤镜内存都会增长
   if(imageData)
       free(imageData);
    imageData = NULL;
    
}
@end
