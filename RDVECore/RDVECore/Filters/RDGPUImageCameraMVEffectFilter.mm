//
//  RDGPUImageCameraMVEffectFilter.m
//  RDVECore
//
//  Created by xcl on 2019/5/15.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

//#import "RDVideoCompositorRenderer.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <Photos/Photos.h>
//#import "RDImage.h"
//#import "RDGLProgram.h"
//#import "RDGPUImageOutput.h"
#import "RDMatrix.h"
//#import "RDACVTexture.h"
////#import "RDParticleRender.h"
////#import "RDDrawElement.h"
//#import "RDCustomFilterPrivate.h"
//#import "RDCustomTransitionPrivate.h"
//#import "RDRecordHelper.h"
//#import <mach/mach.h>

#import "RDGPUImageCameraMVEffectFilter.h"
#import <Photos/Photos.h>
#include <map>

typedef int (*GetInterpolationHandlerFn) (float* percent);

@interface RDVideoComposition : NSObject

@property (nonatomic,strong) NSURL                      *url;
@property (nonatomic,assign) int                        type;
@property (nonatomic,assign) CMTimeRange                timeRange;
@property (nonatomic,strong) AVAssetReader              *reverseReader;
@property (nonatomic,assign) Float64                    oldSampleFrameTime;
@property (nonatomic,strong) AVAssetReaderTrackOutput   *readerOutput;
@property (nonatomic,strong) AVMutableComposition       *videoURLComposition;
@property (nonatomic,assign) BOOL                       videoCopyNextSampleBufferFinish;

@end
@implementation RDVideoComposition
@end
NSString *const kRDCameraMVEffectVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 attribute vec4 inputResourceTextureCoordinate;
 uniform mat4 projection;
 uniform mat4 transform;
 
 varying vec2 textureCoordinate ;
 varying vec2 resourceTextureCoordinate;
 
 void main()
 {
     gl_Position = position * projection * transform;
     textureCoordinate = inputTextureCoordinate.xy;
     resourceTextureCoordinate = inputResourceTextureCoordinate.xy;
     
 }
 );
NSString *const kRDCameraMVEffectMVFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 
 varying highp vec2 textureCoordinate;
 varying highp vec2 resourceTextureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 
 
 void main()
 {
#if 0
     vec2 newCoordinate1 = vec2(textureCoordinate.x/2.0,resourceTextureCoordinate.y);
     vec4 t1 = texture2D(inputImageTexture2,newCoordinate1); // view
     
     vec2 newCoordinate2 = newCoordinate1 + vec2(0.5,0.0);
     vec4 t2 = texture2D(inputImageTexture2, newCoordinate2);//alpha
     
     vec4 t3 = texture2D(inputImageTexture,textureCoordinate);;//source
     float newAlpha = dot(t2.rgb, vec3(0.33333334)) * t2.a;
     vec4 t = vec4(t1.rgb,newAlpha); //compositor 输出一个综合视频 再与
     //mix(a,b,v) = (1-v)a + v(b)
     vec4 textureColor = vec4(mix(t3.rgb,t.rgb,t.a),t3.a);
     
#else
     //相机带有旋转角度，最终mask画面为旋转之后的画面，上下取像素值计算
     vec2 newCoordinate1 = vec2(textureCoordinate.x,resourceTextureCoordinate.y/2.0);
     vec4 t1 = texture2D(inputImageTexture2,newCoordinate1); // view
     
     vec2 newCoordinate2 = newCoordinate1 + vec2(0.0,0.5);
     vec4 t2 = texture2D(inputImageTexture2, newCoordinate2);//alpha
     
     vec4 t3 = texture2D(inputImageTexture,textureCoordinate);;//source
     float newAlpha = dot(t1.rgb, vec3(0.33333334)) * t1.a;
     vec4 t = vec4(t2.rgb,newAlpha); //compositor 输出一个综合视频 再与
     //mix(a,b,v) = (1-v)a + v(b)
     vec4 textureColor = vec4(mix(t3.rgb,t.rgb,t.a),t3.a);
     
     
#endif
     
     gl_FragColor = textureColor; // view;
     return ;
 }
 );

NSString *const kRDCameraMVEffectScreenBlendFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 varying highp vec2 resourceTextureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     vec4 textureColor2 = texture2D(inputImageTexture2, resourceTextureCoordinate);
     vec4 whiteColor = vec4(1.0);
     gl_FragColor = whiteColor - ((whiteColor - textureColor2) * (whiteColor - textureColor));
     
//     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
//     vec4 textureColor2 = texture2D(inputImageTexture2, resourceTextureCoordinate);
//     if(textureColor2.g>140.0/255.0 &&  textureColor2.r<128.0/255.0 && textureColor2.b<128.0/255.0)
//     {
//         textureColor2.a = 0.0;
//     }
//     else
//         textureColor2.a = 1.0;
//
//     gl_FragColor = textureColor2;
     
 }
 );

NSString *const kRDCameraMVEffectSimpleBlendFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     gl_FragColor = textureColor;
 }
 );

NSString *const kRDCameraMVEffectHardLightBlendFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 varying highp vec2 resourceTextureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 const vec3 W = vec3(0.2125, 0.7154, 0.0721);
 
 void main()
 {
     vec4 base = texture2D(inputImageTexture, textureCoordinate);
     vec4 overlay = texture2D(inputImageTexture2, resourceTextureCoordinate);
     
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

NSString *const kRDCameraMVEffectChromaKeyBlendFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 varying highp vec2 resourceTextureCoordinate;

 
 uniform float thresholdSensitivity;
 uniform float smoothing;
 uniform vec3 colorToReplace;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     vec4 textureColor2 = texture2D(inputImageTexture2, resourceTextureCoordinate);
     
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
@interface RDGPUImageCameraMVEffectFilter()
{
    GLuint texture1,texture2,fbo1,fbo2,lottieTexture,lottieFbo;
    GLuint imageTexture;
    
    
    GLuint mvProgram;
    GLuint screenProgram;
    GLuint hardLightProgram;
    GLuint chromaKeyProgram;
    
    GLuint vertShader,mvFragShader,screenFragShader, hardLightFragShader, chromaKeyFragShader;
    
    
    GLuint mvPositionAttribute,mvTextureCoordinateAttribute,mvResourceTextureCoordinateAttribute;
    GLuint mvProjectionUniform,mvTransformUniform;
    GLuint mvInputTextureUniform,mvInputTextureUniform2;
    
    GLuint screenPositionAttribute,screenTextureCoordinateAttribute,screenResourceTextureCoordinateAttribute;
    GLuint screenProjectionUniform,screenTransformUniform;
    GLuint screenInputTextureUniform,screenInputTextureUniform2;
    
    
    GLuint hardLightPositionAttribute,hardLightTextureCoordinateAttribute,hardLightResourceTextureCoordinateAttribute;
    GLuint hardLightInputTextureUniform,hardLightInputTextureUniform2;
    GLuint hardLightProjectionUniform,hardLightTransformUniform;
    
    
    
    GLuint chromaKeyPositionAttribute,chromaKeyTextureCoordinateAttribute,chromaKeyResourceTextureCoordinateAttribute;
    GLuint chromaKeyInputTextureUniform,chromaKeyInputTextureUniform2;
    GLuint chromaKeyColorToReplaceUniform, chromaKeyThresholdSensitivityUniform, chromaKeySmoothingUniform;
    GLuint chromaKeyProjectionUniform,chromaKeyTransformUniform;
    
    RDMatrix4 modelViewMatrix;
    RDMatrix4 projectionMatrix;
    
    CGSize viewSzie;
    int textureWidth;
    int textureHeight;
    
    
    NSMutableArray<RDVideoComposition *> *compositionArray;
    std::map<int,GetInterpolationHandlerFn> m_mapInterpolationHandles;
}

@end
@implementation RDGPUImageCameraMVEffectFilter

int cameraAccelerateDecelerateInterpolator(float* percent)
{
    float fInput = *percent;
    *percent = (float) (cos((fInput + 1.0f) * M_PI) / 2.0f) + 0.5f;
    return 1;
}

int cameraAccelerateInterpolator(float* percent)
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

int cameraDecelerateInterpolator(float* percent)
{
    float fInput = *percent;
    //    if (mFactor == 1.0f) {
    *percent = (float) (1.0f - (1.0f - fInput) * (1.0f - fInput));
    //            } else {
    //                result = (float)(1.0f - pow((1.0f - input), 2 * mFactor));
    //            }
    return 1;
}

int cameraCycleInterpolator(float* percent)
{
    float fInput = *percent;
    *percent = (float) (sin(2 * 0.5f * M_PI * fInput));
    return 1;
}
int cameraLinearInterpolator(float* percent){
    return 1;
}

- (instancetype)init
{

    
    if (!(self = [super init]))
        return nil;
    
    compositionArray = nil;
    imageTexture = 0;
    
    if(![self loadShader])
        NSLog(@"error ： [RDGPUImageCameraMVEffectFilter loadShaders] loader shader fail!");
    
    m_mapInterpolationHandles[AnimationInterpolationTypeLinear] = &cameraLinearInterpolator;
    m_mapInterpolationHandles[AnimationInterpolationTypeAccelerateDecelerate] = &cameraAccelerateDecelerateInterpolator;
    m_mapInterpolationHandles[AnimationInterpolationTypeAccelerate] = &cameraAccelerateInterpolator;
    m_mapInterpolationHandles[AnimationInterpolationTypeDecelerate] = &cameraDecelerateInterpolator;
    m_mapInterpolationHandles[AnimationInterpolationTypeCycle] = &cameraCycleInterpolator;
    
    return self;
}
- (CGRect) CropMixed:(RDCameraCustomAnimate*)a  b:(RDCameraCustomAnimate*) b value:(float) value type:(int) type{
    
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
-(BOOL )loadShader
{
    
    mvProgram          = glCreateProgram();
    screenProgram      = glCreateProgram();
    hardLightProgram   = glCreateProgram();
    chromaKeyProgram   = glCreateProgram();
    
    
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER source:kRDCameraMVEffectVertexShaderString]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    
    if (![self compileShader:&mvFragShader type:GL_FRAGMENT_SHADER source:kRDCameraMVEffectMVFragmentShaderString]) {
        NSLog(@"Failed to compile cust fragment shader");
        return NO;
    }
    if (![self compileShader:&screenFragShader type:GL_FRAGMENT_SHADER source:kRDCameraMVEffectScreenBlendFragmentShaderString]) {
        NSLog(@"Failed to compile cust fragment shader");
        return NO;
    }
    if (![self compileShader:&chromaKeyFragShader type:GL_FRAGMENT_SHADER source:kRDCameraMVEffectChromaKeyBlendFragmentShaderString]) {
        NSLog(@"Failed to compile cust fragment shader");
        return NO;
    }
    if (![self compileShader:&hardLightFragShader type:GL_FRAGMENT_SHADER source:kRDCameraMVEffectHardLightBlendFragmentShaderString]) {
        NSLog(@"Failed to compile cust fragment shader");
        return NO;
    }
    
    
    
    glAttachShader(mvProgram, vertShader);
    glAttachShader(mvProgram, mvFragShader);
    
    glAttachShader(screenProgram, vertShader);
    glAttachShader(screenProgram, screenFragShader);
    
    glAttachShader(chromaKeyProgram, vertShader);
    glAttachShader(chromaKeyProgram, chromaKeyFragShader);
    
    glAttachShader(hardLightProgram, vertShader);
    glAttachShader(hardLightProgram, hardLightFragShader);
    
    
    
    // Link the program.
    if (![self linkProgram:mvProgram]         ||
        ![self linkProgram:screenProgram]     ||
        ![self linkProgram:hardLightProgram]  ||
        ![self linkProgram:chromaKeyProgram]  )
    {
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
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
    mvResourceTextureCoordinateAttribute = glGetAttribLocation(mvProgram, "inputResourceTextureCoordinate");
    mvProjectionUniform = glGetUniformLocation(mvProgram,"projection");
    mvTransformUniform = glGetUniformLocation(mvProgram,"transform");
    
    mvInputTextureUniform = glGetUniformLocation(mvProgram, "inputImageTexture");
    mvInputTextureUniform2 = glGetUniformLocation(mvProgram, "inputImageTexture2");
    
    
    screenPositionAttribute = glGetAttribLocation(screenProgram, "position");
    screenTextureCoordinateAttribute = glGetAttribLocation(screenProgram, "inputTextureCoordinate");
    screenResourceTextureCoordinateAttribute = glGetAttribLocation(screenProgram, "inputResourceTextureCoordinate");
    
    screenInputTextureUniform = glGetUniformLocation(screenProgram, "inputImageTexture");
    screenInputTextureUniform2 = glGetUniformLocation(screenProgram, "inputImageTexture2");
    screenProjectionUniform = glGetUniformLocation(screenProgram,"projection");
    screenTransformUniform = glGetUniformLocation(screenProgram,"transform");
    
    
    hardLightPositionAttribute = glGetAttribLocation(hardLightProgram, "position");
    hardLightTextureCoordinateAttribute = glGetAttribLocation(hardLightProgram, "inputTextureCoordinate");
    hardLightTextureCoordinateAttribute = glGetAttribLocation(hardLightProgram, "inputResourceTextureCoordinate");
    
    hardLightInputTextureUniform = glGetUniformLocation(hardLightProgram, "inputImageTexture");
    hardLightInputTextureUniform2 = glGetUniformLocation(hardLightProgram, "inputImageTexture2");
    hardLightProjectionUniform = glGetUniformLocation(hardLightProgram,"projection");
    hardLightTransformUniform = glGetUniformLocation(hardLightProgram,"transform");
    
    
    chromaKeyPositionAttribute = glGetAttribLocation(chromaKeyProgram, "position");
    chromaKeyTextureCoordinateAttribute = glGetAttribLocation(chromaKeyProgram, "inputTextureCoordinate");
    chromaKeyTextureCoordinateAttribute = glGetAttribLocation(chromaKeyProgram, "inputResourceTextureCoordinate");
    
    chromaKeyInputTextureUniform = glGetUniformLocation(chromaKeyProgram, "inputImageTexture");
    chromaKeyInputTextureUniform2 = glGetUniformLocation(chromaKeyProgram, "inputImageTexture2");
    //    chromaKeyTransformUniform = glGetUniformLocation(_chromaKeyProgram, "renderTransform");
    chromaKeyColorToReplaceUniform = glGetUniformLocation(chromaKeyProgram, "colorToReplace");
    chromaKeyThresholdSensitivityUniform = glGetUniformLocation(chromaKeyProgram, "thresholdSensitivity");
    chromaKeySmoothingUniform = glGetUniformLocation(chromaKeyProgram, "smoothing");
    chromaKeyProjectionUniform = glGetUniformLocation(chromaKeyProgram,"projection");
    chromaKeyTransformUniform = glGetUniformLocation(chromaKeyProgram,"transform");
    
    // Release vertex and fragment shaders.
    
    if (vertShader) {
        glDeleteShader(vertShader);
        vertShader = 0;
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
    return YES;
}


-(UIImage *)imageFromSampleBuffer:(CVPixelBufferRef)sampleBuffer crop:(CGRect)crop imageSize:(CGSize)imageSize rotation:(UIImageOrientation)orientation
{
    UIImage *shotImage = nil;
    CGImageRef tempImageRef = nil;
    CVImageBufferRef imageBuffer = sampleBuffer;
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
    //rotate
    if(UIImageOrientationUp == orientation)
        tempImageRef = quartzImage;
    else
        tempImageRef = [self image:quartzImage rotation:orientation];
    //crop
    CGFloat imageWidth = CGImageGetWidth(tempImageRef);
    CGFloat imageHeight = CGImageGetHeight(tempImageRef);
    float imagePro = imageWidth/imageHeight;
    float animationPro = imageSize.width/imageSize.height;
    
    if (imagePro != animationPro) {
        CGRect rect;
        if (CGRectEqualToRect(crop, CGRectMake(0, 0, 1.0, 1.0))) {
            CGFloat width;
            CGFloat height;
            if (imageWidth*imageSize.height <= imageHeight*imageSize.width) {
                width  = imageWidth;
                height = imageWidth * imageSize.height / imageSize.width;
            }else {
                width  = imageHeight * imageSize.width / imageSize.height;
                height = imageHeight;
            }
            rect = CGRectMake((imageWidth - width)/2.0, (imageHeight - height)/2.0, width, height);
        }else {
            rect = CGRectMake(imageWidth * crop.origin.x, imageHeight * crop.origin.y, imageWidth * crop.size.width, imageHeight * crop.size.height);
        }
        CGImageRef newImageRef = CGImageCreateWithImageInRect(tempImageRef, rect);
        shotImage = [UIImage imageWithCGImage:newImageRef];
        CGImageRelease(newImageRef);
    }else {
        if (CGRectEqualToRect(crop, CGRectMake(0, 0, 1.0, 1.0))) {
            shotImage = [UIImage imageWithCGImage:tempImageRef];
        }else {
            CGRect rect = CGRectMake(imageWidth * crop.origin.x, imageHeight * crop.origin.y, imageWidth * crop.size.width, imageHeight * crop.size.height);
            CGImageRef newImageRef = CGImageCreateWithImageInRect(tempImageRef, rect);
            shotImage = [UIImage imageWithCGImage:newImageRef];
            CGImageRelease(newImageRef);
        }
    }
    CGImageRelease(quartzImage);
    return  shotImage;
}

-(CGImageRef)image:(CGImageRef )image rotation:(UIImageOrientation)orientation
{
    long double rotate = 0.0;
    CGRect rect;
    float translateX = 0;
    float translateY = 0;
    float scaleX = 1.0;
    float scaleY = 1.0;
    CGFloat imageWidth = CGImageGetWidth(image);
    CGFloat imageHeight = CGImageGetHeight(image);
    
    switch (orientation) {
        case UIImageOrientationLeft:
            rotate = M_PI_2;
            rect = CGRectMake(0, 0, imageHeight, imageWidth);
            translateX = 0;
            translateY = -rect.size.width;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationRight:
            rotate = 3 * M_PI_2;
            rect = CGRectMake(0, 0, imageHeight, imageWidth);
            translateX = -rect.size.height;
            translateY = 0;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationDown:
            rotate = M_PI;
            rect = CGRectMake(0, 0, imageWidth, imageHeight);
            translateX = -rect.size.width;
            translateY = -rect.size.height;
            break;
        default:
            rotate = 0.0;
            rect = CGRectMake(0, 0, imageWidth, imageHeight);
            translateX = 0;
            translateY = 0;
            break;
    }
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //做CTM变换
    CGContextTranslateCTM(context, 0.0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextRotateCTM(context, rotate);
    CGContextTranslateCTM(context, translateX, translateY);
    
    CGContextScaleCTM(context, scaleX, scaleY);
    //绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, rect.size.width, rect.size.height), image);
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();//20190424 开启上下文后，必须关闭，否则会崩溃
    
    return newPic.CGImage;
    
}

- (UIImage* )getScreenshotFromVideoURL:(NSURL *)fileURL atTime:(CMTime)time crop:(CGRect)crop imageSize:(CGSize)imageSize {
    @autoreleasepool {
        
//        NSLog(@"getScreenshotFromVideoURL in");
        
//        double startTime = CACurrentMediaTime();
//        NSLog(@"ScreenshotTime:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, time)));
//        double time_start = CACurrentMediaTime();
        
//        if(!getScreenshotFinish)
//            return nil;
      
        RDVideoComposition* videoComposition = nil;
        CMTime currentSampleTime;
        Float64 currentTime = 0;
        CMSampleBufferRef sample = nil ;
        NSMutableArray *samples = [[NSMutableArray alloc] init];
        Float64 screenshotTime = (float)((int)(CMTimeGetSeconds(time)*1000))/1000.0;//保留三位有效数字，计算精确度
        
        for(int j = 0; j < compositionArray.count; j++)
        {
            RDVideoComposition *composition = [compositionArray objectAtIndex:j];
            if ([fileURL isEqual:composition.url] ) {
                videoComposition = composition;
                if(composition.reverseReader.status != AVAssetReaderStatusReading){
                    
                    [self createReverseReaderWithPixelFormat32BGRA:composition timeRange:composition.timeRange];
                    [composition.reverseReader startReading];
                    
                }
                
                break;
            }
            else
                videoComposition = nil;
        }
        if(!videoComposition)
        {
            NSLog(@"error : do not find video videoComposition");
            return nil;
        }
        
        //        NSLog(@"createReverseReaderWithPixelFormat32BGRA耗时：%lf",CACurrentMediaTime() - time_start);
        //        time_start = CACurrentMediaTime();
        if (screenshotTime > (CMTimeGetSeconds(videoComposition.timeRange.start) + CMTimeGetSeconds(videoComposition.timeRange.duration))) {
            float start_time = CMTimeGetSeconds(videoComposition.timeRange.start);
            float duration_time = CMTimeGetSeconds(videoComposition.timeRange.duration);
            screenshotTime = ((screenshotTime/(start_time+duration_time)) - (int)(screenshotTime/(start_time+duration_time)))*(start_time+duration_time) + start_time;
        }
        
        
        while(videoComposition.reverseReader.status == AVAssetReaderStatusReading ) {

//          if(!getScreenshotFinish)
//                return nil;
 
            
            videoComposition.videoCopyNextSampleBufferFinish = FALSE;
            sample = [videoComposition.readerOutput copyNextSampleBuffer];
            videoComposition.videoCopyNextSampleBufferFinish = TRUE;

            
            currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sample);
            currentTime = (float)((int)(CMTimeGetSeconds(currentSampleTime)*1000))/1000.0; //保留三位有效数字，计算精确度
            
            
            
            //            NSLog(@"screenshotTime:%@ currentTime:%@ time_start:%.05f time_duration:%.05f",CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, time)),CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentSampleTime)),CMTimeGetSeconds(videoComposition.timeRange.start),CMTimeGetSeconds(videoComposition.timeRange.duration));
            if(screenshotTime < 0)
                screenshotTime = videoComposition.oldSampleFrameTime;
            
            if ((currentTime - screenshotTime > 1.0/_fps*2 && screenshotTime!= 0)  || !sample) {//seek 或者 播放到文件末尾
                
                @try {
                    [videoComposition.reverseReader cancelReading];
                    videoComposition.reverseReader = nil;
                } @catch (NSException *exception) {
                    NSLog(@"exception: %@",exception);
                }
                
                
                [self createReverseReaderWithPixelFormat32BGRA:videoComposition timeRange:videoComposition.timeRange];
                [videoComposition.reverseReader startReading];
                if(sample){
                    CFRelease(sample);
                    sample = nil;
                }
                continue;
            }
            
            
            if (currentTime >= screenshotTime || fabs(currentTime - screenshotTime)<= 1.0/_fps) { //播放到文件末尾，最后一帧时间无限接近截图时间
                //                NSLog(@"反转截图:sample: %f screenshotTime：%f",currentTime, screenshotTime);
                [samples addObject:(__bridge id)sample];
                CFRelease(sample);
                sample = nil;
                videoComposition.oldSampleFrameTime = currentTime;
                break;
            }
            if(sample){
                CFRelease(sample);
                sample = nil;
            }
        }
        
        //       NSLog(@"copyNextSampleBuffer解码耗时：%lf",CACurrentMediaTime() - time_start);
        //        time_start = CACurrentMediaTime();
        
        UIImage* image = nil ;
        if(samples.count)
        {
    
            // take the image/pixel buffer from tail end of the array
            CVPixelBufferRef imageBufferRef = CMSampleBufferGetImageBuffer((__bridge CMSampleBufferRef)samples[0]);
            //相机带有旋转角度，画面需要旋转
            image = [self imageFromSampleBuffer:imageBufferRef crop:crop imageSize:imageSize rotation:UIImageOrientationLeft];
            
            [samples removeAllObjects];
            samples = nil;
            
        }
        //        NSLog(@"截图 耗时2222:%lf",CACurrentMediaTime() - time_start);
        //        NSLog(@"getScreenshotFromVideoURL out");
        return image;
    }
}

- (AVMutableComposition *)buildVideoForFileURL:(NSURL *)url timeRange:(CMTimeRange)timerange
{
    if (!url) {
        return nil;
    }
    AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack* videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    //    AVMutableCompositionTrack* audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    
    AVAssetTrack* assetVideoTrack = [videoTracks objectAtIndex:0];
    
    NSError *error;
    BOOL suc = [videoTrack insertTimeRange:timerange ofTrack:assetVideoTrack atTime:kCMTimeZero error:&error];
    if(!suc){
        NSLog(@"***video insert error:%@",error);
    }
    
    //    NSLog(@"videoTrack:start %@     duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, videoTrack.timeRange.start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, videoTrack.timeRange.duration)));
    return mixComposition;
    
}
- (void)createReverseReaderWithPixelFormat32BGRA:(RDVideoComposition *)composition timeRange:(CMTimeRange )timerange{
    
//    NSLog(@"createReverseReaderWithPixelFormat32BGRA in ");
    //    _lastReverseProgress = 0;
    //    _lastReverseWriteProgress = 0;
    composition.reverseReader = nil;
    NSError *error;
    composition.reverseReader = [[AVAssetReader alloc] initWithAsset:composition.videoURLComposition error:&error];
    AVAssetTrack *videoTrack = [[composition.videoURLComposition tracksWithMediaType:AVMediaTypeVideo] lastObject];
    
    NSDictionary *readerOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil];
    
    composition.readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack
                                                                          outputSettings:readerOutputSettings];
    //_readerOutput.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmLowQualityZeroLatency;
    composition.readerOutput.alwaysCopiesSampleData = NO;
    [composition.reverseReader addOutput:composition.readerOutput];
    composition.reverseReader.timeRange = timerange;//;
    BOOL statu = [composition.readerOutput supportsRandomAccess];
    [composition.readerOutput setSupportsRandomAccess:YES];
    statu = [composition.readerOutput supportsRandomAccess];
    
//    NSLog(@"createReverseReaderWithPixelFormat32BGRA out ");
    return ;
    
}




- (GLuint ) textureFromUIImage:(UIImage *)image
{
    GLuint texture = -1;
    
    int imageWidth = image.size.width;
    int imageHeight = image.size.height;
    
    CGImageRef cgImage = [image CGImage];
    
    void* imageData = (void*)calloc(1, (int)imageWidth*(int)imageHeight*4);
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef imageContext = CGBitmapContextCreate(imageData, imageWidth, imageHeight, 8, 4*imageWidth, genericRGBColorspace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, imageWidth, imageHeight), cgImage);
    CGContextRelease(imageContext);
    CGColorSpaceRelease(genericRGBColorspace);
    
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, (GLvoid*)imageData);
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
    free(imageData);
    
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
//    NSLog(@"frameTime:%lf",CMTimeGetSeconds(frameTime));
//    currentTime = CMTimeGetSeconds(frameTime);
    
    [self renderToTextureWithVertices:imageVertices textureCoordinates:[[self class] textureCoordinatesForRotation:inputRotation]];
    
    [self informTargetsAboutNewFrameAtTime:frameTime];
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
-(void )renderWithSrcTexture:(GLuint)srcTexture EffectTexture:(GLuint)effectTexture Type:(int)type Scale:(float)scale
                    Vertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates
{
    
    float resourceTextureCoordinates[8] = {0,0,1.0,0.0,0.0,1.0,1.0,1.0};
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, srcTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, effectTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    
    if (type == 0) {
        glUseProgram(mvProgram);
        
        RDMatrixLoadIdentity(&projectionMatrix);
        glUniformMatrix4fv(mvProjectionUniform, 1, GL_FALSE, (GLfloat*)&projectionMatrix.m[0][0]);
        RDMatrixLoadIdentity(&modelViewMatrix);
        RDMatrixScale(&modelViewMatrix,scale , scale, 1.0);
        glUniformMatrix4fv(mvTransformUniform, 1, GL_FALSE, (GLfloat*)&modelViewMatrix.m[0][0]);
        
        glUniform1i(mvInputTextureUniform, 0);
        glUniform1i(mvInputTextureUniform2, 1);
        
        glVertexAttribPointer(mvPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
        glEnableVertexAttribArray(mvPositionAttribute);
        
        glVertexAttribPointer(mvTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
        glEnableVertexAttribArray(mvTextureCoordinateAttribute);
        
        glVertexAttribPointer(mvResourceTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, resourceTextureCoordinates);
        glEnableVertexAttribArray(mvResourceTextureCoordinateAttribute);
        
    }
    
    if (type == 1) {
        glUseProgram(screenProgram);
        
        RDMatrixLoadIdentity(&projectionMatrix);
        glUniformMatrix4fv(screenProjectionUniform, 1, GL_FALSE, (GLfloat*)&projectionMatrix.m[0][0]);
        RDMatrixLoadIdentity(&modelViewMatrix);
        RDMatrixScale(&modelViewMatrix,scale , scale, 1.0);
        glUniformMatrix4fv(screenTransformUniform, 1, GL_FALSE, (GLfloat*)&modelViewMatrix.m[0][0]);
        
        glUniform1i(screenInputTextureUniform, 0);
        glUniform1i(screenInputTextureUniform2, 1);
        
        glVertexAttribPointer(screenPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
        glEnableVertexAttribArray(screenPositionAttribute);
        
        glVertexAttribPointer(screenTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
        glEnableVertexAttribArray(screenTextureCoordinateAttribute);
        
        glVertexAttribPointer(screenResourceTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, resourceTextureCoordinates);
        glEnableVertexAttribArray(screenResourceTextureCoordinateAttribute);
    }
    
    if (type == 2) {
        glUseProgram(hardLightProgram);
        
        RDMatrixLoadIdentity(&projectionMatrix);
        glUniformMatrix4fv(hardLightProjectionUniform, 1, GL_FALSE, (GLfloat*)&projectionMatrix.m[0][0]);
        RDMatrixLoadIdentity(&modelViewMatrix);
        RDMatrixScale(&modelViewMatrix,scale , scale, 1.0);
        glUniformMatrix4fv(hardLightTransformUniform, 1, GL_FALSE, (GLfloat*)&modelViewMatrix.m[0][0]);
        
        glUniform1i(hardLightInputTextureUniform, 0);
        glUniform1i(hardLightInputTextureUniform2, 1);
        
        glVertexAttribPointer(hardLightPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
        glEnableVertexAttribArray(hardLightPositionAttribute);
        
        glVertexAttribPointer(hardLightTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
        glEnableVertexAttribArray(hardLightTextureCoordinateAttribute);
        
        glVertexAttribPointer(hardLightResourceTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, resourceTextureCoordinates);
        glEnableVertexAttribArray(hardLightResourceTextureCoordinateAttribute);
    }
    
    if (type == 3) {
        glUseProgram(chromaKeyProgram);
        
        RDMatrixLoadIdentity(&projectionMatrix);
        glUniformMatrix4fv(chromaKeyProjectionUniform, 1, GL_FALSE, (GLfloat*)&projectionMatrix.m[0][0]);
        RDMatrixLoadIdentity(&modelViewMatrix);
        RDMatrixScale(&modelViewMatrix,scale , scale, 1.0);
        glUniformMatrix4fv(chromaKeyTransformUniform, 1, GL_FALSE, (GLfloat*)&modelViewMatrix.m[0][0]);
        
        glUniform3f(chromaKeyColorToReplaceUniform, 0.0, 1.0, 0.0);
        glUniform1f(chromaKeyThresholdSensitivityUniform, 0.4);
        glUniform1f(chromaKeySmoothingUniform, 0.1);
        
        
        glUniform1i(chromaKeyInputTextureUniform, 0);
        glUniform1i(chromaKeyInputTextureUniform2, 1);
        
        glVertexAttribPointer(chromaKeyPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
        glEnableVertexAttribArray(chromaKeyPositionAttribute);
        
        glVertexAttribPointer(chromaKeyTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
        glEnableVertexAttribArray(chromaKeyTextureCoordinateAttribute);
        
        glVertexAttribPointer(chromaKeyResourceTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, resourceTextureCoordinates);
        glEnableVertexAttribArray(chromaKeyResourceTextureCoordinateAttribute);
        
    }
    
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glFlush();
    
}

//- (GLuint)textureFromBufferObject:(unsigned char *) image Width:(int )width Height:(int)height
//{
//
//
//    GLuint texture = 0;
//
//    glEnable(GL_TEXTURE_2D);
//    glGenTextures(1, &texture);
//    glBindTexture(GL_TEXTURE_2D, texture);
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)width, (int)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid*)image);
//
//    /**
//     *  纹理过滤函数
//     *  图象从纹理图象空间映射到帧缓冲图象空间(映射需要重新构造纹理图像,这样就会造成应用到多边形上的图像失真),
//     *  这时就可用glTexParmeteri()函数来确定如何把纹理象素映射成像素.
//     *  如何把图像从纹理图像空间映射到帧缓冲图像空间（即如何把纹理像素映射成像素）
//     */
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); // S方向上的贴图模式
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE); // T方向上的贴图模式
//    // 线性过滤：使用距离当前渲染像素中心最近的4个纹理像素加权平均值
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//
//
//    return texture;
//}

- (BOOL)renderLottiePixelToFrameBufferWithPixel:(GLubyte*)pixel Vertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates
{
    lottieTexture = [self textureFromBufferObject:pixel Width:viewSzie.width Height:viewSzie.height];
    if (!lottieTexture) {
        return NO;
    }
    
    if(!lottieFbo)
        glGenFramebuffers(1, &lottieFbo);
    glBindFramebuffer(GL_FRAMEBUFFER, lottieFbo);
    glViewport(0, 0, viewSzie.width, viewSzie.height);
    
    
    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, lottieTexture, 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }
    if(compositionArray.count % 2 != 0)
        [self renderWithSrcTexture:texture1 EffectTexture:lottieTexture Type:0 Scale:1.0 Vertices:vertices textureCoordinates:textureCoordinates];
    else
        [self renderWithSrcTexture:texture2 EffectTexture:lottieTexture Type:0 Scale:1.0 Vertices:vertices textureCoordinates:textureCoordinates];
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    return YES;
}

- (int )convertSourceCoordinates:(float*)src ToDstCoordinates:(float* )dst
{
    float w = src[2] - src[0];
    float h = src[5] - src[1];
    float x = src[0];
    float y = src[1];
 
    dst[0] = y;
    dst[1] = 1.0 - x - w;
    dst[2] = y + h;
    dst[3] = 1.0 - x - w;
    dst[4] = y;
    dst[5] = 1.0 - x;
    dst[6] = y + h;
    dst[7] = 1.0 - x;
    
    return 1;
}

- (BOOL)renderCameraMVToFrameBufferWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates
{
    float dstTextureCoordinates[8] = {0};
    float tempTextureCoordinates[8] = {0};
    
    if (_mvEffects.count) {
        if (!compositionArray) {
            compositionArray = [NSMutableArray array];
            
            for (int i = 0; i<_mvEffects.count; i++) {
                RDCameraMVEffect* zoom = _mvEffects[i];
                RDVideoComposition* videoCompostion = [[RDVideoComposition alloc] init];
                videoCompostion.url = zoom.url;
                videoCompostion.type = zoom.type;
                AVAsset *asset = [AVAsset assetWithURL:videoCompostion.url];
                videoCompostion.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(CMTimeGetSeconds(asset.duration), TIMESCALE));
                videoCompostion.videoURLComposition = [self buildVideoForFileURL:videoCompostion.url timeRange:videoCompostion.timeRange];
                [self createReverseReaderWithPixelFormat32BGRA:videoCompostion timeRange:videoCompostion.timeRange];
                [videoCompostion.reverseReader startReading];
                videoCompostion.videoCopyNextSampleBufferFinish = TRUE;
                [compositionArray addObject:videoCompostion];
            }
        }
        
        
        
        for(int i = 0;i < compositionArray.count;i++)
        {
            int         width = viewSzie.width;
            int         height = viewSzie.height;
            AVURLAsset* asset = nil;
            CGSize size ;
            
            RDVideoComposition* composition = compositionArray[i];
            {
                asset = [AVURLAsset assetWithURL:composition.url];
                if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] > 0) {
                    
                    AVAssetTrack* clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
                    size = clipVideoTrack.naturalSize;
                    if (CGSizeEqualToSize(size, CGSizeZero) || size.width == 0.0 || size.height == 0.0) {
                        NSArray * formatDescriptions = [clipVideoTrack formatDescriptions];
                        CMFormatDescriptionRef formatDescription = NULL;
                        if ([formatDescriptions count] > 0) {
                            formatDescription = (__bridge CMFormatDescriptionRef)[formatDescriptions objectAtIndex:0];
                            if (formatDescription) {
                                size = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, false, false);
                            }
                        }
                    }
                }
            }
            NSLog(@"renderCameraMVToFrameBufferWithVertices:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, _currentTime)));
            //相机拍摄带有旋转角度 imagesize宽高互换
            UIImage* image = [self getScreenshotFromVideoURL:composition.url atTime:_currentTime crop:CGRectMake(0,0,1.0,1.0) imageSize:CGSizeMake(size.height, size.width)];
            if(imageTexture)
            {
                glDeleteTextures(1, &imageTexture);
                imageTexture = 0;
            }
            
            imageTexture = [self textureFromUIImage:image];
            
            if (textureHeight != height || textureWidth != width) {
                
                unsigned char* pImage = (unsigned char*)malloc(width*height*4);
                for (int i = 0; i<width*height; i++) {
                    
                    pImage[i*4] = 0xFF;
                    pImage[i*4+1] = 0x00;
                    pImage[i*4+2] = 0x00;
                    pImage[i*4+3] = 0xFF;
                }
                
                if(texture1)
                    glDeleteTextures(1, &texture1);
                texture1 = [self textureFromBufferObject:pImage Width:width Height:height];
                
                if(texture2)
                    glDeleteTextures(1, &texture2);
                texture2 = [self textureFromBufferObject:pImage Width:width Height:height];
                
                textureWidth = width;
                textureHeight = height;
                free(pImage);
            }
            
            
            if (i%2 == 0) {
                
                if(!fbo1)
                    glGenFramebuffers(1, &fbo1);
                
                glBindFramebuffer(GL_FRAMEBUFFER, fbo1);
                glViewport(0, 0, width, height);
                
                // Attach the destination texture as a color attachment to the off screen frame buffer
                glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture1, 0);
                
                if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
                    NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
                }
                
                if(i == 0)
                {
                    // 需要处理裁剪区域 缩放动作
                    float scale = 1.0;
                    if(_animate.count)
                    {
                        RDCameraCustomAnimate* fromPosition;
                        RDCameraCustomAnimate* toPosition;
 
                        for (int j = 0; j<_animate.count; j++) {
                            
                            RDCameraCustomAnimate* _from = _animate[j];
                            RDCameraCustomAnimate* _to;
                            if (j == _animate.count - 1) {
                                _to = _animate[j];
                            }else {
                                _to = _animate[j+1];
                            }
                            
                            //保留三位有效数字，计算精确度
                            int nTimeFrom = (int)(_from.atTime * 1000) ;
                            int nTimeTo = (int)(_to.atTime * 1000) ;
                            int nCurrent =(int)(CMTimeGetSeconds(_currentTime)*1000);
                            
                            if ( nTimeFrom <= nCurrent && nCurrent <= nTimeTo) {
                                fromPosition = _from;
                                toPosition = _to;
                                //当前缩放因子
                                scale = _from.scale;
                                break;
                            }
                        }
                        float valueT = (toPosition.atTime - fromPosition.atTime)>0.0?(CMTimeGetSeconds(_currentTime) - fromPosition.atTime) / (toPosition.atTime - fromPosition.atTime) : 0.0;
                        valueT = valueT>1.0?1.0:valueT;
                        CGRect crop = [self CropMixed:fromPosition b:toPosition value:valueT type:fromPosition.type];
                        
                        if(CGRectEqualToRect(crop, CGRectZero))
                        {
                            NSLog(@"error:renderCameraMVToFrameBufferWithVertices invalid crop");
                            crop = CGRectMake(0.0, 0.0, 1.0, 1.0);
                        }
                        
                        
                        tempTextureCoordinates[0] = crop.origin.x;
                        tempTextureCoordinates[1] = crop.origin.y;
                        tempTextureCoordinates[2] = crop.origin.x + crop.size.width;
                        tempTextureCoordinates[3] = crop.origin.y;
                        tempTextureCoordinates[4] = crop.origin.x;
                        tempTextureCoordinates[5] = crop.origin.y + crop.size.height;
                        tempTextureCoordinates[6] = crop.origin.x + crop.size.width;
                        tempTextureCoordinates[7] = crop.origin.y + crop.size.height;
                        
                    }
                    else
                        memcpy(tempTextureCoordinates, textureCoordinates, sizeof(textureCoordinates[0])*8);
                    
                    
//                    CGRect crop = CGRectMake(0.5, 0.5, 0.5, 0.5);
//                    tempTextureCoordinates[0] = crop.origin.x;
//                    tempTextureCoordinates[1] = crop.origin.y;
//                    tempTextureCoordinates[2] = crop.origin.x + crop.size.width;
//                    tempTextureCoordinates[3] = crop.origin.y;
//                    tempTextureCoordinates[4] = crop.origin.x;
//                    tempTextureCoordinates[5] = crop.origin.y + crop.size.height;
//                    tempTextureCoordinates[6] = crop.origin.x + crop.size.width;
//                    tempTextureCoordinates[7] = crop.origin.y + crop.size.height;
                    
                    //由于相机拍摄自带旋转角度，需要转换到旋转之前的裁剪区域
                    [self convertSourceCoordinates:tempTextureCoordinates ToDstCoordinates:dstTextureCoordinates];
                    //绘制
                    [self renderWithSrcTexture:[firstInputFramebuffer texture] EffectTexture:imageTexture Type:composition.type Scale:scale Vertices:vertices textureCoordinates:dstTextureCoordinates];
                }
                else
                    [self renderWithSrcTexture:texture2 EffectTexture:imageTexture Type:composition.type Scale:1.0 Vertices:vertices textureCoordinates:textureCoordinates];
                
                glBindFramebuffer(GL_FRAMEBUFFER, 0);
            }
            else
            {
                if(!fbo2)
                    glGenFramebuffers(1, &fbo2);
                
                glBindFramebuffer(GL_FRAMEBUFFER, fbo2);
                glViewport(0, 0, width, height);
                
                
                // Attach the destination texture as a color attachment to the off screen frame buffer
                glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture2, 0);
                
                if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
                    NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
                }
                [self renderWithSrcTexture:texture1 EffectTexture:imageTexture Type:composition.type Scale:1.0 Vertices:vertices textureCoordinates:textureCoordinates];
                glBindFramebuffer(GL_FRAMEBUFFER, 0);
            }
        }
        
        if(_lottiePixel)
            return [self renderLottiePixelToFrameBufferWithPixel:_lottiePixel Vertices:vertices textureCoordinates:textureCoordinates];
        
        return YES;
    }
    return NO;
    
    
}
- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates{
    
    if (self.preventRendering)
    {
        [firstInputFramebuffer unlock];
        return;
    }
    
    viewSzie = [self sizeOfFBO];
    BOOL cameraMV = [self renderCameraMVToFrameBufferWithVertices:vertices textureCoordinates:textureCoordinates];

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
    
    glActiveTexture(GL_TEXTURE2);
    if(cameraMV)
    {
        if (_lottiePixel) {
            glBindTexture(GL_TEXTURE_2D, lottieTexture);
        }
        else
        {
            if(compositionArray.count % 2 != 0)
                glBindTexture(GL_TEXTURE_2D, texture1);
            else
                glBindTexture(GL_TEXTURE_2D, texture2);
        }
        
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
    
    if (lottieTexture) {
        glDeleteTextures(1, &lottieTexture);
        lottieTexture = 0;
    }

}

- (void)dealloc{

    if(imageTexture)
    {
        glDeleteTextures(1, &imageTexture);
        imageTexture = 0;
    }
    
    
    for (RDVideoComposition *composition in compositionArray) {
        if (composition.reverseReader.status == AVAssetReaderStatusReading) {
            [composition.reverseReader cancelReading];
            composition.reverseReader = nil;
            composition.readerOutput = nil;
            composition.videoURLComposition = nil;
        }
    }
    [compositionArray removeAllObjects];
    compositionArray = nil;
    
    
    if (fbo1) {
        glDeleteFramebuffers(1, &fbo1);
        fbo1 = 0;
    }
    if (fbo2) {
        glDeleteFramebuffers(1,&fbo2);
        fbo2 = 0;
    }
    if (lottieFbo) {
        glDeleteFramebuffers(1,&lottieFbo);
        lottieFbo = 0;
    }
    if(texture1)
    {
        glDeleteTextures(1, &texture1);
        texture1 = 0;
    }
    if(texture2)
    {
        glDeleteTextures(1, &texture2);
        texture2 = 0;
    }
    if (lottieTexture) {
        glDeleteTextures(1, &lottieTexture);
        lottieTexture = 0;
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
}
@end
