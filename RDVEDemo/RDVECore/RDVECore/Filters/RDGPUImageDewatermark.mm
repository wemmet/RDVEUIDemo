//
//  RDDewatermark.m
//  RDVECore
//
//  Created by xcl on 2018/5/16.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDGPUImageDewatermark.h"
#import "RDMatrix.h"

NSString*  const kRDDewatermarkVertexShader = SHADER_STRING
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
NSString *const kRDDewatermarkFragmentShader = SHADER_STRING
(
 
 precision highp float;
 uniform sampler2D inputImageTexture;
 varying vec2 textureCoordinate;
 
 //两个参数，要修补的矩形在纹理上的对角坐标。例如1为左上角坐标，那么2就是右下角坐标。
 uniform vec2    WatermarkXY1;
 uniform vec2    WatermarkXY2;
 
 
 void main(){
     
     vec2 vTextueCoords = textureCoordinate;
     float x1 = min(WatermarkXY1.x, WatermarkXY2.x);
     float x2 = max(WatermarkXY1.x, WatermarkXY2.x);
     float y1 = min(WatermarkXY1.y, WatermarkXY2.y);
     float y2 = max(WatermarkXY1.y, WatermarkXY2.y);
     
     if (x1 < vTextueCoords.x && vTextueCoords.x < x2
         && y1 < vTextueCoords.y && vTextueCoords.y <y2 )
     {
         float x1t = vTextueCoords.x - x1;
         float x2t = x2 - vTextueCoords.x;
         float y1t = vTextueCoords.y - y1;
         float y2t = y2 - vTextueCoords.y;
         float x1s = x2t * y1t * y2t;
         float x2s = x1t * y1t * y2t;
         float y1s = y2t * x1t * x2t;
         float y2s = y1t * x1t * x2t;
         float ans = x1s + x2s + y1s + y2s;
         vec4  x1c = texture2D(inputImageTexture, vec2(x1,vTextueCoords.y)) * x1s;
         vec4  x2c = texture2D(inputImageTexture, vec2(x2,vTextueCoords.y)) * x2s;
         vec4  y1c = texture2D(inputImageTexture, vec2(vTextueCoords.x,y1)) * y1s;
         vec4  y2c = texture2D(inputImageTexture, vec2(vTextueCoords.x,y2)) * y2s;
         gl_FragColor = ( x1c + x2c + y1c + y2c ) / ans;
     }
     else
     {
         gl_FragColor = vec4( texture2D(inputImageTexture, vTextueCoords) );
     }
 }
 
 );

typedef struct TEXTURE_FBO_ATTRIBUTE
{
    
    GLuint texture;
    GLuint fbo;
    bool isLastTexture;
    
}TEXTURE_FBO_ATTRIBUTE;

@interface RDGPUImageDewatermark()

{
    GLuint vertShader, fragShader;
    GLuint program;
    GLuint positionAttribute,textureCoordinateAttribute,inputTextureUniform,WatermarkXY1Uniform,WatermarkXY2Uniform;
   
    float   currentTime;
    int     viewWidth;
    int     viewHeight;
    
    TEXTURE_FBO_ATTRIBUTE* pTextureFbo1;
    TEXTURE_FBO_ATTRIBUTE* pTextureFbo2;
}


@end
@implementation RDGPUImageDewatermark

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
    
    program  = glCreateProgram();
    
    
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER source:kRDDewatermarkVertexShader]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER source:kRDDewatermarkFragmentShader]) {
        NSLog(@"Failed to compile cust fragment shader");
        return NO;
    }
    
    glAttachShader(program, vertShader);
    glAttachShader(program, fragShader);
    
    
    // Link the program.
    if (![self linkProgram:program]) {
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        return NO;
    }
    
    
    positionAttribute = glGetAttribLocation(program, "position");
    textureCoordinateAttribute = glGetAttribLocation(program, "inputTextureCoordinate");
    inputTextureUniform = glGetUniformLocation(program, "inputImageTexture");
    WatermarkXY1Uniform = glGetUniformLocation(program, "WatermarkXY1");
    WatermarkXY2Uniform = glGetUniformLocation(program, "WatermarkXY2");
    
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(program, vertShader);
        glDeleteShader(vertShader);
        vertShader = 0;
    }
    if (fragShader) {
        glDetachShader(program, fragShader);
        glDeleteShader(fragShader);
        fragShader = 0;
    }
    
    return YES;
}
- (id)init
{
    self = [super init];
    if(self) {
        
#if 0
        if(![self loadShaders])
            NSLog(@"RDGPUImageDewatermark loader shader fail!");
#else
        if (!(self = [super initWithFragmentShaderFromString:kRDDewatermarkFragmentShader])) {
            return nil;
        }
        inputTextureUniform = [filterProgram uniformIndex:@"inputImageTexture"];
        WatermarkXY1Uniform = [filterProgram uniformIndex:@"WatermarkXY1"];
        WatermarkXY2Uniform = [filterProgram uniformIndex:@"WatermarkXY2"];
#endif
    }
    
    
    return self;
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

-(bool)renderToFrameBufferObject:(int)screenWidth ScreenHeight:(int)sereenHeight CurrentTime:(float)seconds
{
    
    int         width = screenWidth;
    int         height = sereenHeight;
    bool        bDewatermark = false;
    int         drawCount = 0;
    
    //检查当前时间是否去水印
    for(int j = 0; j < _watermark.count; j++)
    {
        CMTimeRange watermarkTimeRange = ([[_watermark objectAtIndex:j] timeRange]);
        float watermarkStartTime = CMTimeGetSeconds(watermarkTimeRange.start);
        float watermarkEndTime = watermarkStartTime + CMTimeGetSeconds(watermarkTimeRange.duration);
        //NSLog(@"seconds ：%f watermarkStartTime:%f watermarkEndTime:%f ",seconds,watermarkStartTime,watermarkEndTime);
        if (seconds < watermarkStartTime || seconds > watermarkEndTime) {
            continue;
        }
        else
        {
            bDewatermark = true;
            break;
        }
        
    }
    //没有水印，直接返回false
    if(!bDewatermark)
        return false;
    
    if (!pTextureFbo1) {
        pTextureFbo1 = (struct TEXTURE_FBO_ATTRIBUTE*)malloc(sizeof(struct TEXTURE_FBO_ATTRIBUTE));
        if(!pTextureFbo1)
        {
            NSLog(@"error :struct TEXTURE_FBO_ATTRIBUTE malloc fail ");
            return false;
        }
        memset(pTextureFbo1, 0, sizeof(TEXTURE_FBO_ATTRIBUTE));
        
    }
    if (!pTextureFbo2) {
        pTextureFbo2 = (struct TEXTURE_FBO_ATTRIBUTE*)malloc(sizeof(struct TEXTURE_FBO_ATTRIBUTE));
        if(!pTextureFbo2)
        {
            NSLog(@"error :struct TEXTURE_FBO_ATTRIBUTE malloc fail ");
            return false;
        }
        memset(pTextureFbo2, 0, sizeof(struct TEXTURE_FBO_ATTRIBUTE));
    }
    
    if( width != viewWidth || height != viewHeight)
    {
        CGSize sizeImage;
        unsigned char* pImage = (unsigned char*)malloc(width*height*4);
        for (int i = 0; i<width*height; i++) {
            
            pImage[i*4] = 0xFF;
            pImage[i*4+1] = 0x00;
            pImage[i*4+2] = 0x00;
            pImage[i*4+3] = 0xFF;
        }
        
        
        sizeImage.width = width;
        sizeImage.height = height;
        
        viewWidth = width;
        viewHeight = height;
        if(pTextureFbo1->texture)
            glDeleteTextures(1, &pTextureFbo1->texture);
        pTextureFbo1->texture = [self textureFromBufferObject:pImage Width:width Height:height];
        if(pTextureFbo2->texture)
            glDeleteTextures(1, &pTextureFbo2->texture);
        pTextureFbo2->texture = [self textureFromBufferObject:pImage Width:width Height:height];
        
        free(pImage);
    }
    if(!pTextureFbo1->fbo)
        glGenFramebuffers(1, &pTextureFbo1->fbo);
    if(!pTextureFbo2->fbo)
        glGenFramebuffers(1, &pTextureFbo2->fbo);
    
    
    for(int i = 0; i < _watermark.count;i++)
    {
        
        RDDewatermark *pWatermark = [_watermark objectAtIndex:i];
        CMTimeRange watermarkTimeRange = ([[_watermark objectAtIndex:i] timeRange]);
        float watermarkStartTime = CMTimeGetSeconds(watermarkTimeRange.start);
        float watermarkEndTime = watermarkStartTime + CMTimeGetSeconds(watermarkTimeRange.duration);
        //如果有多个水印，检查当前时间点应该处理的水印
        if (seconds < watermarkStartTime || seconds > watermarkEndTime) {
            continue;
        }
        
        
        if(drawCount%2 == 0)
        {
            glBindFramebuffer(GL_FRAMEBUFFER, pTextureFbo1->fbo);
            glViewport(0, 0, width, height);
            
            // Attach the destination texture as a color attachment to the off screen frame buffer
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, pTextureFbo1->texture, 0);
            
            if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
                NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
                return false;
            }
            pTextureFbo1->isLastTexture = true;
            pTextureFbo2->isLastTexture = false;
        }
        else
        {
            glBindFramebuffer(GL_FRAMEBUFFER, pTextureFbo2->fbo);
            glViewport(0, 0, width, height);
            
            // Attach the destination texture as a color attachment to the off screen frame buffer
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, pTextureFbo2->texture, 0);
            
            if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
                NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
                return false;
            }
            pTextureFbo1->isLastTexture = false;
            pTextureFbo2->isLastTexture = true;
            
        }
        
        //开启blend
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
//        glUseProgram(program);
        
        glActiveTexture(GL_TEXTURE0);
        if (0 == drawCount%2)
        {
            if(0 == drawCount)
                glBindTexture(GL_TEXTURE_2D,[firstInputFramebuffer texture]);
            else
                glBindTexture(GL_TEXTURE_2D, pTextureFbo2->texture);
                
        }
        else
            glBindTexture(GL_TEXTURE_2D, pTextureFbo1->texture);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        
        GLfloat quadTextureData[8] = {

            0.0,0.0,
            1.0,0.0,
            0.0,1.0,
            1.0,1.0,
        };
        
        GLfloat quadVertexData[8] = {
            
            -1.0,-1.0,
            1.0,-1.0,
            -1.0,1.0,
            1.0,1.0,
        };
    
        glUniform2f(WatermarkXY1Uniform,pWatermark.rect.origin.x,pWatermark.rect.origin.y);
        glUniform2f(WatermarkXY2Uniform,pWatermark.rect.origin.x + pWatermark.rect.size.width,pWatermark.rect.origin.y+pWatermark.rect.size.height);
        
        glUniform1i(inputTextureUniform, 0);
        
        glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData);
        glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        
        drawCount++;
        
    }
    
    
    return true;
    
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates{
    

    bool bDewatermark = false;
    
    if (self.preventRendering)
    {
        [firstInputFramebuffer unlock];
        return;
    }
    
    [RDGPUImageContext setActiveShaderProgram:filterProgram];
    
    //如果有去水印设置，先处理到临时frame bufer object
    bDewatermark = [self renderToFrameBufferObject:[self sizeOfFBO].width ScreenHeight:[self sizeOfFBO].height CurrentTime:currentTime];
    
    outputFramebuffer = [[RDGPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    if (usingNextFrameForImageCapture)
    {
        [outputFramebuffer lock];
    }
    CVPixelBufferRef p = [outputFramebuffer pixelBuffer];
    
    [self setUniformsForProgramAtIndex:0];
    
    
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE2);
    if(!bDewatermark)
        glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    else
    {
        if (pTextureFbo1->isLastTexture)
            glBindTexture(GL_TEXTURE_2D, pTextureFbo1->texture);
        else
            glBindTexture(GL_TEXTURE_2D, pTextureFbo2->texture);
    }
    
    glUniform1i(filterInputTextureUniform, 2);
    glUniform2f(WatermarkXY1Uniform,0,0);
    glUniform2f(WatermarkXY2Uniform,0.0,0.0);
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [firstInputFramebuffer unlock];
    
    if (usingNextFrameForImageCapture)
    {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
    
    return;
}



- (void)dealloc
{
    
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
    if(pTextureFbo1)
    {
        glDeleteTextures(1, &pTextureFbo1->texture);
        glDeleteFramebuffers(1,&pTextureFbo1->fbo);
    }
    if(pTextureFbo2)
    {
        glDeleteTextures(1, &pTextureFbo2->texture);
        glDeleteFramebuffers(1,&pTextureFbo2->fbo);
    }
}

@end

