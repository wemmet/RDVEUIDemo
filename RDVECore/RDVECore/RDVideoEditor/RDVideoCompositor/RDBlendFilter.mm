//
//  RDBlendFilter.m
//  RDVECore
//
//  Created by xiachunlin on 2020/1/3.
//  Copyright © 2020年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDBlendFilter.h"
#import "RDGPUImageACVFile.h"
#import <UIKit/UIKit.h>




#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)
#include <map>

NSString *const kRDBlendVertexShaderString = SHADER_STRING
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
NSString *const kRDDarkBlendFragmentShaderString = SHADER_STRING //变暗
(
 precision mediump float;
 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
    lowp vec4 base = texture2D(inputImageTexture, textureCoordinate);
    lowp vec4 overlayer = texture2D(inputImageTexture2, textureCoordinate);
    
    gl_FragColor = vec4(min(overlayer.rgb * base.a, base.rgb * overlayer.a) + overlayer.rgb * (1.0 - base.a) + base.rgb * (1.0 - overlayer.a), 1.0);
 }
 );
NSString *const kRDOverlayBlendFragmentShaderString = SHADER_STRING //叠加
(
 precision mediump float;
 
 varying highp vec2 textureCoordinate;

 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     mediump vec4 base = texture2D(inputImageTexture, textureCoordinate);
     mediump vec4 overlay = texture2D(inputImageTexture2, textureCoordinate);
     
     mediump float ra;
     if (2.0 * base.r < base.a) {
         ra = 2.0 * overlay.r * base.r + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
     } else {
         ra = overlay.a * base.a - 2.0 * (base.a - base.r) * (overlay.a - overlay.r) + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
     }
     
     mediump float ga;
     if (2.0 * base.g < base.a) {
         ga = 2.0 * overlay.g * base.g + overlay.g * (1.0 - base.a) + base.g * (1.0 - overlay.a);
     } else {
         ga = overlay.a * base.a - 2.0 * (base.a - base.g) * (overlay.a - overlay.g) + overlay.g * (1.0 - base.a) + base.g * (1.0 - overlay.a);
     }
     
     mediump float ba;
     if (2.0 * base.b < base.a) {
         ba = 2.0 * overlay.b * base.b + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
     } else {
         ba = overlay.a * base.a - 2.0 * (base.a - base.b) * (overlay.a - overlay.b) + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
     }
     
     gl_FragColor = vec4(ra, ga, ba, 1.0);
 }
 );

NSString *const kRDHardLightBlendFragmentShaderString = SHADER_STRING //强光
(
 precision mediump float;
 
 varying highp vec2 textureCoordinate;

 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;

 const highp vec3 W = vec3(0.2125, 0.7154, 0.0721);

 void main()
 {
     mediump vec4 base = texture2D(inputImageTexture, textureCoordinate);
     mediump vec4 overlay = texture2D(inputImageTexture2, textureCoordinate);

     highp float ra;
     if (2.0 * overlay.r < overlay.a) {
         ra = 2.0 * overlay.r * base.r + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
     } else {
         ra = overlay.a * base.a - 2.0 * (base.a - base.r) * (overlay.a - overlay.r) + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
     }
     
     highp float ga;
     if (2.0 * overlay.g < overlay.a) {
         ga = 2.0 * overlay.g * base.g + overlay.g * (1.0 - base.a) + base.g * (1.0 - overlay.a);
     } else {
         ga = overlay.a * base.a - 2.0 * (base.a - base.g) * (overlay.a - overlay.g) + overlay.g * (1.0 - base.a) + base.g * (1.0 - overlay.a);
     }
     
     highp float ba;
     if (2.0 * overlay.b < overlay.a) {
         ba = 2.0 * overlay.b * base.b + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
     } else {
         ba = overlay.a * base.a - 2.0 * (base.a - base.b) * (overlay.a - overlay.b) + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
     }
     
     gl_FragColor = vec4(ra, ga, ba, 1.0);
 }
 );

NSString *const kRDSoftLightBlendFragmentShaderString = SHADER_STRING //柔光
(
 precision mediump float;
 
 varying highp vec2 textureCoordinate;

 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     mediump vec4 base = texture2D(inputImageTexture, textureCoordinate);
     mediump vec4 overlay = texture2D(inputImageTexture2, textureCoordinate);
     
     lowp float alphaDivisor = base.a + step(base.a, 0.0); // Protect against a divide-by-zero blacking out things in the output
     gl_FragColor = base * (overlay.a * (base / alphaDivisor) + (2.0 * overlay * (1.0 - (base / alphaDivisor)))) + overlay * (1.0 - base.a) + base * (1.0 - overlay.a);
 }
 );

NSString *const kRDLinearBurnBlendFragmentShaderString = SHADER_STRING //线性加深
(
 precision mediump float;
 
 varying highp vec2 textureCoordinate;

 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     mediump vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     mediump vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate);
    vec3 d = max(textureColor.rgb + textureColor2.rgb - vec3(1.0), vec3(0.0,0.0,0.0));
    if(textureColor2.a == 0.0)
        gl_FragColor = textureColor;
    else
        gl_FragColor = vec4(clamp(textureColor.rgb + textureColor2.rgb - vec3(1.0), vec3(0.0), vec3(1.0)), textureColor.a);
     
//     gl_FragColor = vec4(clamp(textureColor.rgb + textureColor2.rgb - vec3(1.0), vec3(0.0), vec3(1.0)), textureColor.a);
 }
 );
NSString *const kRDColorBurnBlendFragmentShaderString = SHADER_STRING //颜色加深
(
 precision mediump float;
 
 varying highp vec2 textureCoordinate;


 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
    mediump vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    mediump vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate);
    mediump vec4 whiteColor = vec4(1.0);
//    gl_FragColor = whiteColor - (whiteColor - textureColor) / textureColor2;
    if(textureColor2.a == 0.0)
        gl_FragColor = textureColor;
    else
        gl_FragColor = whiteColor - (whiteColor - textureColor) / textureColor2;
 }
 );

NSString *const kRDLightenBlendFragmentShaderString = SHADER_STRING //变亮
(
 varying highp vec2 textureCoordinate;

 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    lowp vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate);
    
    gl_FragColor = max(textureColor, textureColor2);
 }
);

NSString *const kRDMultiplyBlendFragmentShaderString = SHADER_STRING //正片叠底
(
 varying highp vec2 textureCoordinate;


 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     lowp vec4 base = texture2D(inputImageTexture, textureCoordinate);
     lowp vec4 overlayer = texture2D(inputImageTexture2, textureCoordinate);
          
     gl_FragColor = overlayer * base + overlayer * (1.0 - base.a) + base * (1.0 - overlayer.a);
 }
);

NSString *const kRDScreenBlendFragmentShaderString = SHADER_STRING //滤色
(
 varying highp vec2 textureCoordinate;


 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     mediump vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     mediump vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate);
     mediump vec4 whiteColor = vec4(1.0);
     gl_FragColor = whiteColor - ((whiteColor - textureColor2) * (whiteColor - textureColor));
 }
);


NSString *const kRDColorDodgeBlendFragmentShaderString = SHADER_STRING //颜色减浅
(
 precision mediump float;
 varying highp vec2 textureCoordinate;

 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     vec4 base = texture2D(inputImageTexture, textureCoordinate);
     vec4 overlay = texture2D(inputImageTexture2, textureCoordinate);
     
     vec3 baseOverlayAlphaProduct = vec3(overlay.a * base.a);
     vec3 rightHandProduct = overlay.rgb * (1.0 - base.a) + base.rgb * (1.0 - overlay.a);
     
     vec3 firstBlendColor = baseOverlayAlphaProduct + rightHandProduct;
     vec3 overlayRGB = clamp((overlay.rgb / clamp(overlay.a, 0.01, 1.0)) * step(0.0, overlay.a), 0.0, 0.99);
     
     vec3 secondBlendColor = (base.rgb * overlay.a) / (1.0 - overlayRGB) + rightHandProduct;
     
     vec3 colorChoice = step((overlay.rgb * base.a + base.rgb * overlay.a), baseOverlayAlphaProduct);
     
     gl_FragColor = vec4(mix(firstBlendColor, secondBlendColor, colorChoice), 1.0);
 }
 
 );


typedef struct BlendFilterList
{
    GLuint program;
    GLuint vertShader;
    GLuint fragShader;
    GLuint inputTextureUniform;
    GLuint inputTextureUniform2;
    GLuint positionAttribute;
    GLuint textureCoordinateAttribute;
    int blendType;
    
    struct BlendFilterList* next;
    
}BlendFilterList;

@interface RDBlendFilter()
{
    struct BlendFilterList* blendList;
}

@end
@implementation RDBlendFilter


- (instancetype) init{
    if (!(self = [super init])) {
        return nil;
    }
    if(![self loadShaders])
    {
        NSLog(@"blend filter list load shader error! ");
        return nil;
    }
    
    
    return self;
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
- (BOOL)loadShaders
{
    BlendFilterList* pLast = nil;
    for (int i = RDBlendDark; i<= RDBlendColorDodge; i++) {
        
        if (!blendList) {
            blendList = (BlendFilterList*)malloc(sizeof(BlendFilterList));
            memset(blendList, 0, sizeof(BlendFilterList));
            pLast = blendList;
        }
        else
        {
            BlendFilterList* p = blendList;
            while(p && p->next)
                p = p->next;
            p->next = (BlendFilterList*)malloc(sizeof(BlendFilterList));
            memset(p->next, 0, sizeof(BlendFilterList));
            pLast = p->next;
        }
        pLast->blendType = i;
        pLast->program = glCreateProgram();
        
        if (![self compileShader:&pLast->vertShader type:GL_VERTEX_SHADER source:kRDBlendVertexShaderString]) {
            NSLog(@"Failed to compile RDBlendDark vertex shader");
            return NO;
        }
        
        switch (i) {
            case RDBlendDark:
            {
                if (![self compileShader:&pLast->fragShader type:GL_FRAGMENT_SHADER source:kRDDarkBlendFragmentShaderString]) {
                    NSLog(@"Failed to compile RDBlendDark fragment shader");
                    return NO;
                }
                break;
            }
//            case RDBlendLS:
//                break;
            case RDBlendOverlay:
            {
                if (![self compileShader:&pLast->fragShader type:GL_FRAGMENT_SHADER source:kRDOverlayBlendFragmentShaderString]) {
                    NSLog(@"Failed to compile RDBlendOverlay fragment shader");
                    return NO;
                }
                break;
            }
            case RDBlendHardLight:
            {
                if (![self compileShader:&pLast->fragShader type:GL_FRAGMENT_SHADER source:kRDHardLightBlendFragmentShaderString]) {
                    NSLog(@"Failed to compile RDBlendHardLight fragment shader");
                    return NO;
                }
                break;
            }
            case RDBlendSoftLight:
            {
                if (![self compileShader:&pLast->fragShader type:GL_FRAGMENT_SHADER source:kRDSoftLightBlendFragmentShaderString]) {
                    NSLog(@"Failed to compile RDBlendSoftLight fragment shader");
                    return NO;
                }
                break;
            }
            case RDBlendLinearBurn:
            {
                if (![self compileShader:&pLast->fragShader type:GL_FRAGMENT_SHADER source:kRDLinearBurnBlendFragmentShaderString]) {
                    NSLog(@"Failed to compile RDBlendLinearBurn fragment shader");
                    return NO;
                }
                break;
            }
            case RDBlendColorBurn:
            {
                if (![self compileShader:&pLast->fragShader type:GL_FRAGMENT_SHADER source:kRDColorBurnBlendFragmentShaderString]) {
                    NSLog(@"Failed to compile RDBlendColorBurn fragment shader");
                    return NO;
                }
                break;
            }
            case RDBlendColorDodge:
            {
                if (![self compileShader:&pLast->fragShader type:GL_FRAGMENT_SHADER source:kRDColorDodgeBlendFragmentShaderString]) {
                    NSLog(@"Failed to compile RDBlendColorDodge fragment shader");
                    return NO;
                }
                break;
            }
            case RDBlendLighten:
            {
                if (![self compileShader:&pLast->fragShader type:GL_FRAGMENT_SHADER source:kRDLightenBlendFragmentShaderString]) {
                    NSLog(@"Failed to compile RDBlendLighten fragment shader");
                    return NO;
                }
                break;
            }
            case RDBlendMultiply:
            {
                if (![self compileShader:&pLast->fragShader type:GL_FRAGMENT_SHADER source:kRDMultiplyBlendFragmentShaderString]) {
                    NSLog(@"Failed to compile RDBlendMultiply fragment shader");
                    return NO;
                }
                break;
            }
            case RDBlendScreen:
            {
                if (![self compileShader:&pLast->fragShader type:GL_FRAGMENT_SHADER source:kRDScreenBlendFragmentShaderString]) {
                    NSLog(@"Failed to compile RDBlendScreen fragment shader");
                    return NO;
                }
                break;
            }
            default:
                NSLog(@"Failed to find fragment or vert shader");
                return NO;
        }
        
        glAttachShader(pLast->program, pLast->vertShader);
        glAttachShader(pLast->program, pLast->fragShader);
        
        // Link the program.
        if (![self linkProgram:pLast->program]
            ) {
            if (pLast->vertShader) {
                glDeleteShader(pLast->vertShader);
                pLast->vertShader = 0;
            }
            
            if (pLast->fragShader) {
                glDeleteShader(pLast->fragShader);
                pLast->fragShader = 0;
            }
            return NO;
        }
        
        
        pLast->positionAttribute = glGetAttribLocation(pLast->program, "position");
        pLast->textureCoordinateAttribute = glGetAttribLocation(pLast->program, "inputTextureCoordinate");
        pLast->inputTextureUniform = glGetUniformLocation(pLast->program, "inputImageTexture");
        pLast->inputTextureUniform2 = glGetUniformLocation(pLast->program, "inputImageTexture2");
        
        // Release vertex and fragment shaders.
        if (pLast->vertShader) {
            glDeleteShader(pLast->vertShader);
            pLast->vertShader = 0;
        }
        
        if (pLast->fragShader) {
            glDeleteShader(pLast->fragShader);
            pLast->fragShader = 0;
        }
    }

    return YES;
}

- (BOOL)renderBlendModelWithForegroundTexture:(GLuint)foregroundTexture BackgroundTexture:(GLuint)backgroundTexture BlendType:(RDBlendType)type
{
    
    if(!blendList)
    {
        NSLog(@"BlendFilterList is nil,invalid Filter");
        return NO;
    }
    
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
    
    BlendFilterList* curFilter = nil;
    BlendFilterList* p = blendList;
    while (p) {
        
        if (p->blendType == type) {
            curFilter = p;
            break;
        }
        p = p->next;
    }
    
    if(!curFilter)
    {
        NSLog(@"fail to find specify filter from BlendFilterList,invalid Filter");
        return NO;
    }
        
    
    glUseProgram(curFilter->program);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, backgroundTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glUniform1i(curFilter->inputTextureUniform, 0);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, foregroundTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glUniform1i(curFilter->inputTextureUniform2, 1);
    
    glVertexAttribPointer(curFilter->positionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glEnableVertexAttribArray(curFilter->positionAttribute);
    glVertexAttribPointer(curFilter->textureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    glEnableVertexAttribArray(curFilter->textureCoordinateAttribute);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    return YES;
}

- (void)dealloc{
    NSLog(@"%s",__func__);
    while (blendList) {
        BlendFilterList* p = blendList->next;
        glDeleteProgram(blendList->program);
        free(blendList);
        blendList = p;
    }
}

@end
