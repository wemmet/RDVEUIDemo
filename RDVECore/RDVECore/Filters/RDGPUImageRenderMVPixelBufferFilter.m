//
//  RDLookupFilter.m
//  RDVECore
//
//  Created by  on 2018/4/6.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDGPUImageRenderMVPixelBufferFilter.h"
#include "stdio.h"
#include "stdlib.h"


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
NSString *const kRDFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture,inputImageTexture2);

     return ;
     
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

NSString *const kRDChromaKeyBlendFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 
 uniform float thresholdSensitivity;
 uniform float smoothing;
 uniform vec3 colorToReplace;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate);
     
     float maskY = 0.2989 * colorToReplace.r + 0.5866 * colorToReplace.g + 0.1145 * colorToReplace.b;
     float maskCr = 0.7132 * (colorToReplace.r - maskY);
     float maskCb = 0.5647 * (colorToReplace.b - maskY);
     
     float Y = 0.2989 * textureColor.r + 0.5866 * textureColor.g + 0.1145 * textureColor.b;
     float Cr = 0.7132 * (textureColor.r - Y);
     float Cb = 0.5647 * (textureColor.b - Y);
     
     //     float blendValue = 1.0 - smoothstep(thresholdSensitivity - smoothing, thresholdSensitivity , abs(Cr - maskCr) + abs(Cb - maskCb));
     float blendValue = 1.0 - smoothstep(thresholdSensitivity, thresholdSensitivity + smoothing, distance(vec2(Cr, Cb), vec2(maskCr, maskCb)));
     gl_FragColor = mix(textureColor, textureColor2, blendValue);
 }
 );


NSString *const kRDGPUImageRenderMVPixelBufferFragmentShaderString = SHADER_STRING
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
@interface RDGPUImageRenderMVPixelBufferFilter()
{
    
    GLuint vertShader, fragShader, mvVertShader,mvFragShader,screenFragShader, hardLightFragShader, chromaKeyFragShader;
    
    GLuint imageTexture1;
    GLuint imageTexture2;
    GLuint inputImageTexture2Uniform;
    GLuint offscreenBufferHandle1;
    GLuint offscreenBufferHandle2;
    
    GLuint mvProgram;
    GLuint mvPositionAttribute,mvTextureCoordinateAttribute;
    GLuint mvInputTextureUniform,mvInputTextureUniform2;
    
    GLuint screenProgram;
    GLuint screenPositionAttribute,screenTextureCoordinateAttribute;
    GLuint screenInputTextureUniform,screenInputTextureUniform2;
    
    GLuint hardLightProgram;
    GLuint hardLightPositionAttribute,hardLightTextureCoordinateAttribute;
    GLuint hardLightInputTextureUniform,hardLightInputTextureUniform2;
    
    GLuint chromaKeyProgram;
    GLuint chromaKeyPositionAttribute,chromaKeyTextureCoordinateAttribute;
    GLuint chromaKeyInputTextureUniform,chromaKeyInputTextureUniform2;
    GLuint chromaKeyColorToReplaceUniform, chromaKeyThresholdSensitivityUniform, chromaKeySmoothingUniform;
    
    NSInteger mvType;
}

@end
@implementation RDGPUImageRenderMVPixelBufferFilter


- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kRDMVFragmentShaderString]))
    {
        return nil;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMV:) name:@"refreshMV" object:nil];
    
    return self;
}

- (void)refreshMV:(NSNotification *)notification {
    _instruction = [notification.userInfo objectForKey:@"instruction"];
//    _mvPixels = (__bridge CVPixelBufferRef)([notification.userInfo objectForKey:@"mvPixels"]);
//    mvType = [[notification.userInfo objectForKey:@"mvType"] integerValue];
    _mvPixels = (__bridge CVPixelBufferRef)(notification.object);
}

#define kBitsPerComponent (8)
#define kBitsPerPixel (32)
#define kPixelChannelCount (4)//每一行的像素点占用的字节数，每个像素点的ARGB四个通道各占8个bit
-(GLuint)textureFromCVPixelBufferRef:(CVPixelBufferRef)pixelBufffer
{
//    UIImage *image;
    GLuint texture;
    CVPixelBufferLockBaseAddress(pixelBufffer, 0);// 锁定pixel buffer的基地址
    void * baseAddress = CVPixelBufferGetBaseAddress(pixelBufffer);// 得到pixel buffer的基地址
    size_t width = CVPixelBufferGetWidth(pixelBufffer);
    size_t height = CVPixelBufferGetHeight(pixelBufffer);
    size_t bufferSize = CVPixelBufferGetDataSize(pixelBufffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBufffer);// 得到pixel buffer的行字节数
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();// 创建一个依赖于设备的RGB颜色空间
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, baseAddress, bufferSize, NULL);
    
    CGImageRef cgImage = CGImageCreate(width,
                                       height,
                                       kBitsPerComponent,
                                       kBitsPerPixel,
                                       bytesPerRow,
                                       rgbColorSpace,
                                       kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrderDefault,
                                       provider,
                                       NULL,
                                       true,
                                       kCGRenderingIntentDefault);//这个是建立一个CGImageRef对象的函数
    
//    image = [UIImage imageWithCGImage:cgImage];
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(rgbColorSpace);
//    NSData* imageData = UIImageJPEGRepresentation(image, 1.0);//1代表图片是否压缩
//    image = [UIImage imageWithData:imageData];
    CVPixelBufferUnlockBaseAddress(pixelBufffer, 0);   // 解锁pixel buffer
    
    int imageWidth = (int)CVPixelBufferGetWidth(pixelBufffer);
    int imageHeight = (int)CVPixelBufferGetWidth(pixelBufffer);
    
    
    void* imagePixel = (void*)calloc(1, (int)imageWidth*(int)imageHeight*4);
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef imageContext = CGBitmapContextCreate(imagePixel, imageWidth, imageHeight, 8, 4*imageWidth, genericRGBColorspace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, imageWidth, imageHeight), cgImage);
    CGImageRelease(cgImage);  //类似这些CG...Ref 在使用完以后都是需要release的，不然内存会有问题
    CGContextRelease(imageContext);
    CGColorSpaceRelease(genericRGBColorspace);
    
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, (GLvoid*)imagePixel);
    
    free(imagePixel);
    
    return texture;
}

- (GLuint)textureFromImage {
    GLuint texture;
    
    int imageWidth = _dstImage.size.width;
    int imageHeight = _dstImage.size.height;
    
    
    void* imagePixel = (void*)calloc(1, (int)imageWidth*(int)imageHeight*4);
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef imageContext = CGBitmapContextCreate(imagePixel, imageWidth, imageHeight, 8, 4*imageWidth, genericRGBColorspace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, imageWidth, imageHeight), _dstImage.CGImage);
    CGContextRelease(imageContext);
    CGColorSpaceRelease(genericRGBColorspace);
    
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, (GLvoid*)imagePixel);
    
    free(imagePixel);
    
    return texture;
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
-(bool )loadShader
{
    
    mvProgram        = glCreateProgram();
    screenProgram    = glCreateProgram();
    hardLightProgram = glCreateProgram();
    chromaKeyProgram = glCreateProgram();
    
    if (![self compileShader:&mvVertShader type:GL_VERTEX_SHADER source:kRDVertexShaderString]) {
        NSLog(@"Failed to compile vertex shader");
        return false;
    }
    if (![self compileShader:&mvFragShader type:GL_FRAGMENT_SHADER source:kRDMVFragmentShaderString]) {
        NSLog(@"failed to compile trans  frag shader");
        return false;
    }
    if (![self compileShader:&screenFragShader type:GL_FRAGMENT_SHADER source:kRDScreenBlendFragmentShaderString]) {
        NSLog(@"failed to compile trans  frag shader");
        return false;
    }
    if (![self compileShader:&hardLightFragShader type:GL_FRAGMENT_SHADER source:kRDHardLightBlendFragmentShaderString]) {
        NSLog(@"failed to compile trans  frag shader");
        return false;
    }
    if (![self compileShader:&chromaKeyFragShader type:GL_FRAGMENT_SHADER source:kRDChromaKeyBlendFragmentShaderString]) {
        NSLog(@"failed to compile trans  frag shader");
        return false;
    }
    glAttachShader(mvProgram, mvVertShader);
    glAttachShader(mvProgram, mvFragShader);
    
    glAttachShader(screenProgram, mvVertShader);
    glAttachShader(screenProgram, screenFragShader);
    
    glAttachShader(hardLightProgram, mvVertShader);
    glAttachShader(hardLightProgram, hardLightFragShader);
    
    glAttachShader(chromaKeyProgram, mvVertShader);
    glAttachShader(chromaKeyProgram, chromaKeyFragShader);
    
    
    // Link the program.
    if (
        ![self linkProgram:mvProgram]         ||
        ![self linkProgram:screenProgram]     ||
        ![self linkProgram:hardLightProgram]  ||
        ![self linkProgram:chromaKeyProgram]
        ) {
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
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
    
        if (mvProgram) {
            glDeleteProgram(mvProgram);
            mvProgram = 0;
        }
        
        if (screenProgram) {
            glDeleteProgram(screenProgram);
            screenProgram = 0;
        }
        
        if (hardLightProgram) {
            glDeleteProgram(hardLightProgram);
            hardLightProgram = 0;
        }
        
        if (chromaKeyProgram) {
            glDeleteProgram(chromaKeyProgram);
            chromaKeyProgram = 0;
        }
        
        
        return NO;
    }
    
    mvPositionAttribute = glGetAttribLocation(mvProgram, "position");
    mvTextureCoordinateAttribute = glGetAttribLocation(mvProgram, "inputTextureCoordinate");
    
    mvInputTextureUniform = glGetUniformLocation(mvProgram, "inputImageTexture");
    mvInputTextureUniform2 = glGetUniformLocation(mvProgram, "inputImageTexture2");
    
    screenPositionAttribute = glGetAttribLocation(screenProgram, "position");
    screenTextureCoordinateAttribute = glGetAttribLocation(screenProgram, "inputTextureCoordinate");
    
    screenInputTextureUniform = glGetUniformLocation(screenProgram, "inputImageTexture");
    screenInputTextureUniform2 = glGetUniformLocation(screenProgram, "inputImageTexture2");
    
    
    hardLightPositionAttribute = glGetAttribLocation(hardLightProgram, "position");
    hardLightTextureCoordinateAttribute = glGetAttribLocation(hardLightProgram, "inputTextureCoordinate");
    
    hardLightInputTextureUniform = glGetUniformLocation(hardLightProgram, "inputImageTexture");
    hardLightInputTextureUniform2 = glGetUniformLocation(hardLightProgram, "inputImageTexture2");
    
    
    chromaKeyPositionAttribute = glGetAttribLocation(chromaKeyProgram, "position");
    chromaKeyTextureCoordinateAttribute = glGetAttribLocation(chromaKeyProgram, "inputTextureCoordinate");
    
    chromaKeyInputTextureUniform = glGetUniformLocation(chromaKeyProgram, "inputImageTexture");
    chromaKeyInputTextureUniform2 = glGetUniformLocation(chromaKeyProgram, "inputImageTexture2");
    //    chromaKeyTransformUniform = glGetUniformLocation(chromaKeyProgram, "renderTransform");
    chromaKeyColorToReplaceUniform = glGetUniformLocation(chromaKeyProgram, "colorToReplace");
    chromaKeyThresholdSensitivityUniform = glGetUniformLocation(chromaKeyProgram, "thresholdSensitivity");
    chromaKeySmoothingUniform = glGetUniformLocation(chromaKeyProgram, "smoothing");
    
    
    // Release vertex and fragment shaders.
   
    if (mvVertShader) {
        glDetachShader(mvProgram, mvVertShader);
        glDeleteShader(mvVertShader);
    }
    if (mvFragShader) {
        glDetachShader(mvProgram, mvFragShader);
        glDeleteShader(mvFragShader);
    }
    
    if (screenFragShader) {
        glDetachShader(screenProgram, screenFragShader);
        glDeleteShader(screenFragShader);
    }
    
    if (hardLightFragShader) {
        glDetachShader(hardLightProgram, hardLightFragShader);
        glDeleteShader(hardLightFragShader);
    }
    
    if (chromaKeyFragShader) {
        glDetachShader(chromaKeyProgram, chromaKeyFragShader);
        glDeleteShader(chromaKeyFragShader);
    }

    return true;
}


- (GLuint)createTextureWidthWidth:(int )width AndHeight:(int)height
{
 
    GLuint texture = 0;
//    CGSize sizeImage;
    unsigned char* pImage = (unsigned char*)malloc(width*height*4);
    for (int i = 0; i<width*height; i++) {
        
        pImage[i*4] = 0xFF;
        pImage[i*4+1] = 0x00;
        pImage[i*4+2] = 0x00;
        pImage[i*4+3] = 0xFF;
    }

    
    
    glEnable(GL_TEXTURE_2D);
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)width, (int)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid*)pImage);
    
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
    free(pImage);
    
    return texture;
}

-(int)renderMVPixelBuffer:(GLuint)sourceTexture MVPixel:(GLuint)mvTexture Type:(int)type
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

    
    
    glEnable(GL_BLEND);
    //    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);//
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, sourceTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, mvTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    if (type == 0) {
        if(!mvProgram)
            [self loadShader];
        glUseProgram(mvProgram);
        
        glUniform1i(mvInputTextureUniform, 0);
        glUniform1i(mvInputTextureUniform2, 1);
        
        glVertexAttribPointer(mvPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData);
        glEnableVertexAttribArray(mvPositionAttribute);
        
        glVertexAttribPointer(mvTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
        glEnableVertexAttribArray(mvTextureCoordinateAttribute);
        
    }
    
    if (type == 1) {
        
        if(!screenProgram)
            [self loadShader];
        glUseProgram(screenProgram);
        
        
        glUniform1i(screenInputTextureUniform, 0);
        glUniform1i(screenInputTextureUniform2, 1);
        
        glVertexAttribPointer(screenPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData);
        glEnableVertexAttribArray(screenPositionAttribute);
        
        glVertexAttribPointer(screenTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
        glEnableVertexAttribArray(screenTextureCoordinateAttribute);
        
    }
    
    if (type == 2) {
        
        if(!hardLightProgram)
            [self loadShader];
        glUseProgram(hardLightProgram);
        
        glUniform1i(hardLightInputTextureUniform, 0);
        glUniform1i(hardLightInputTextureUniform2, 1);
        
        glVertexAttribPointer(hardLightPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData);
        glEnableVertexAttribArray(hardLightPositionAttribute);
        
        glVertexAttribPointer(hardLightTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
        glEnableVertexAttribArray(hardLightTextureCoordinateAttribute);
        
    }
    
    if (type == 3) {
        
        if(!chromaKeyProgram)
            [self loadShader];
        glUseProgram(chromaKeyProgram);
        
        glUniform3f(chromaKeyColorToReplaceUniform, 0.0, 1.0, 0.0);
        glUniform1f(chromaKeyThresholdSensitivityUniform, 0.4);
        glUniform1f(chromaKeySmoothingUniform, 0.1);
        
        
        glUniform1i(chromaKeyInputTextureUniform, 0);
        glUniform1i(chromaKeyInputTextureUniform2, 1);
        
        glVertexAttribPointer(chromaKeyPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData);
        glEnableVertexAttribArray(chromaKeyPositionAttribute);
        
        glVertexAttribPointer(chromaKeyTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
        glEnableVertexAttribArray(chromaKeyTextureCoordinateAttribute);
        
    }
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glFlush();//20180725 不刷新会导致11.0系统以上的设备，播放视频时不停闪烁
bailMask:
    
    glDisableVertexAttribArray(mvPositionAttribute);
    glDisableVertexAttribArray(mvTextureCoordinateAttribute);
    
    
    return 1;
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates{
    
    
    GLuint sourceTexture = 0 ;
    GLuint mvTexture = 0;
    
    if (self.preventRendering)
    {
        [firstInputFramebuffer unlock];
        return;
    }
    
    //mv绘制到临时FBO
    
//    CGSize size = [self sizeOfFBO];
    
    if(!offscreenBufferHandle1)
        glGenFramebuffers(1, &offscreenBufferHandle1);
    if(!offscreenBufferHandle2)
        glGenFramebuffers(1, &offscreenBufferHandle2);
    
    if (_instruction.mvEffects.count > 0) {
        
        for (int i = 0; i<_instruction.mvEffects.count; i++) {
            VVMovieEffect* effect = _instruction.mvEffects[i];
            
            if (!_mvPixels) {
                return;
            }
            
            mvTexture = [self textureFromCVPixelBufferRef:_mvPixels];
            if (!mvTexture) {
                return ;
            }
            
            if (i%2 == 0) {
                
                if(!offscreenBufferHandle1)
                    glGenFramebuffers(1, &offscreenBufferHandle1);
                
                glBindFramebuffer(GL_FRAMEBUFFER, offscreenBufferHandle1);
                
                if(!imageTexture1)
//                    imageTexture1 = [self createTextureWidthWidth:CVPixelBufferGetWidth(_dstPixels) AndHeight:CVPixelBufferGetHeight(_dstPixels)];
                    imageTexture1 = [self createTextureWidthWidth:_dstImage.size.width AndHeight:_dstImage.size.height];
                // Attach the destination texture as a color attachment to the off screen frame buffer
                glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, imageTexture1, 0);
                
                if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
                    NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
                    return;
                }
                
                if(i == 0)
                {
//                    sourceTexture = [self textureFromCVPixelBufferRef:_dstPixels];
                    sourceTexture = [self textureFromImage];
                    if (!sourceTexture) {
                        return ;
                    }
                }
                else
                    sourceTexture = imageTexture2;
                
                [self renderMVPixelBuffer:sourceTexture MVPixel:mvTexture Type:effect.type];
                glBindFramebuffer(GL_FRAMEBUFFER, 0);
                
                
            }
            else
            {
                if(!offscreenBufferHandle2)
                    glGenFramebuffers(1, &offscreenBufferHandle2);
                
                glBindFramebuffer(GL_FRAMEBUFFER, offscreenBufferHandle2);
                
                if(!imageTexture2)
//                    imageTexture2 = [self createTextureWidthWidth:CVPixelBufferGetWidth(_dstPixels) AndHeight:CVPixelBufferGetHeight(_dstPixels)];
                    imageTexture2 = [self createTextureWidthWidth:_dstImage.size.width AndHeight:_dstImage.size.height];
                // Attach the destination texture as a color attachment to the off screen frame buffer
                glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, imageTexture2, 0);
                
                if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
                    NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
                    return;
                }
                sourceTexture = imageTexture1;
                
                [self renderMVPixelBuffer:sourceTexture MVPixel:mvTexture Type:effect.type];
                glBindFramebuffer(GL_FRAMEBUFFER, 0);
                
            
            }
            if(sourceTexture && 0 == i)
                glDeleteTextures(1, &sourceTexture);
            if(mvTexture)
                glDeleteTextures(1, &mvTexture);
        }
    }
    
    [RDGPUImageContext setActiveShaderProgram:filterProgram];
    
    outputFramebuffer = [[RDGPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    if (usingNextFrameForImageCapture)
    {
        [outputFramebuffer lock];
    }
    
    
    [self setUniformsForProgramAtIndex:0];
    
    
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
    if(!inputImageTexture2Uniform)
        inputImageTexture2Uniform = [filterProgram uniformIndex:@"inputImageTexture2"];
    glActiveTexture(GL_TEXTURE3);
    if((_instruction.mvEffects.count - 1)%2 == 0)
        glBindTexture(GL_TEXTURE_2D, imageTexture1);
    else
        glBindTexture(GL_TEXTURE_2D, imageTexture2);
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


- (void)dealloc{

    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshMV" object:nil];

    glDeleteTextures(1, &imageTexture1);
    glDeleteTextures(1, &imageTexture2);
    if (offscreenBufferHandle1) {
        glDeleteFramebuffers(1,&offscreenBufferHandle1);
        offscreenBufferHandle1 = 0;
    }
    if (offscreenBufferHandle2) {
        glDeleteFramebuffers(1,&offscreenBufferHandle2);
        offscreenBufferHandle2 = 0;
    }
    if (mvProgram) {
        glDeleteProgram(mvProgram);
    }
    if (screenProgram) {
        glDeleteProgram(screenProgram);
    }
    
    if (hardLightProgram) {
        glDeleteProgram(hardLightProgram);
    }
    
    if (chromaKeyProgram) {
        glDeleteProgram(chromaKeyProgram);
    }
}
@end


    
