//
//  BCMeshShader.m
//  BCMeshTransformView
//
//  Copyright (c) 2014 Bartosz Ciechanowski. All rights reserved.
//

#import "BCMeshShader.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

@implementation BCMeshShader


NSString*  const kRDBCMeshShaderVertexShader = SHADER_STRING
(
 precision highp float;
 attribute vec4 position;
 attribute vec3 normal;
 attribute vec2 texCoord;

 varying lowp vec2 texCoordVarying;
 varying lowp vec4 shadingVarying;

 uniform mat4 viewProjectionMatrix;
 uniform mat3 normalMatrix;

 uniform vec3 lightDirection;
 uniform float diffuseFactor;

 void main()
 {
     vec3 worldNormal = normalize(normalMatrix * normal);
     
     float diffuseIntensity = abs(dot(worldNormal, lightDirection));
     float diffuse = mix(1.0, diffuseIntensity, diffuseFactor);
     
     shadingVarying = vec4(diffuse, diffuse, diffuse, 1.0);
     texCoordVarying = texCoord;

     gl_Position = viewProjectionMatrix * position;
 }


);
NSString*  const  kRDBCMeshShaderFragmentShader = SHADER_STRING
(

 
// precision lowp float;
 precision highp float;

 varying vec2 texCoordVarying;
 varying vec4 shadingVarying;

 uniform sampler2D texSampler;

 void main()
 {
     //Branch-less transparent texture border
     
     vec2 centered = abs(texCoordVarying - vec2(0.5));
     
     // if tex coords are out of bounds, they're over 0.5 at this point
     
     vec2 clamped = clamp(sign(centered - vec2(0.5)), 0.0, 1.0);
     
     // If a tex coord is out of bounds, then it's equal to 1.0 at this point, otherwise it's 0.0.
     // If either coordinate is 1.0, then their sum will be larger than zero
     
     float inBounds = 1.0 - clamp(clamped.x + clamped.y, 0.0, 1.0);
     
     gl_FragColor = shadingVarying * texture2D(texSampler, texCoordVarying) * inBounds;
 }



);

- (BOOL)loadProgram
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    _program = glCreateProgram();
    
#if 0
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:[self shaderName] ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader \"%@\"", [self shaderName]);
        return NO;
    }
    
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:[self shaderName] ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader \"%@\"", [self shaderName]);
        return NO;
    }
#else
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER source:kRDBCMeshShaderVertexShader]) {
        NSLog(@"failed to compile multi texture vertex shader");
        return NO;
    }
    
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER source:kRDBCMeshShaderFragmentShader]) {
        NSLog(@"Failed to compile cust fragment shader");
        return NO;
    }
    
#endif
    
    glAttachShader(_program, vertShader);
    glAttachShader(_program, fragShader);
    
    [self bindAttributeLocations];
    
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program %d for shader \"%@\"", _program, [self shaderName]);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    [self getUniformLocations];
    
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (void)dealloc
{
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
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
    
   
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    glReleaseShaderCompiler();
    return YES;
}
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader \"%@\"", [self shaderName]);
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader \"%@\" compile log:\n%s", [self shaderName], log);
        free(log);
    }
#endif
    
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
        NSLog(@"Program \"%@\" link log:\n%s", [self shaderName], log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}



#pragma mark - Concrete

- (void)bindAttributeLocations
{
    glBindAttribLocation(self.program, BCVertexAttribPosition, "position");
    glBindAttribLocation(self.program, BCVertexAttribNormal, "normal");
    glBindAttribLocation(self.program, BCVertexAttribTexCoord, "texCoord");
}

- (void)getUniformLocations
{
    _viewProjectionMatrixUniform = glGetUniformLocation(self.program, "viewProjectionMatrix");
    _normalMatrixUniform = glGetUniformLocation(self.program, "normalMatrix");
    _lightDirectionUniform = glGetUniformLocation(self.program, "lightDirection");
    _diffuseFactorUniform = glGetUniformLocation(self.program, "diffuseFactor");
    _texSamplerUniform = glGetUniformLocation(self.program, "texSampler");
}

- (NSString *)shaderName
{
    return @"BCMeshShader";
}


@end
