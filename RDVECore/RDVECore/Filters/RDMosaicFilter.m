//
//  RDMosaicFilter.m
//  RDVECore
//
//  Created by 周晓林 on 2018/4/6.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDMosaicFilter.h"
#import "RDMatrix.h"

//android马赛克绘制流程：
//    1.原始画面做全屏马赛克保存到fbo1
//    2.绘制马赛克贴纸旋转等操作保存到fbo2
//    3.fbo1 与 fbo2 做mask处理 保存到 fbo3
//    4.绘制原始画面
//    5.绘制fbo3


NSString *const kRDMosaicFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform highp vec2  inputpixelSize; //单个像素在目标纹理中的大小。例如目标纹理将被渲染为 800*600 的矩形，那么单个像素就是 1/800, 1/600
 
 uniform vec2 pointLB;
 uniform vec2 pointLT;
 uniform vec2 pointRT;
 uniform vec2 pointRB;
 
 uniform float mosaicBlockSize;
 
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
    {
        highp vec2 texSize = vec2(0.0,0.0);
        highp vec2 mosaicSize = vec2(mosaicBlockSize,mosaicBlockSize);//马赛克大小
        highp vec2 vTextueCoords = textureCoordinate;

        texSize.x = 1.0/inputpixelSize.x;
        texSize.y = 1.0/inputpixelSize.y;


        highp vec2 xy = vec2(vTextueCoords.x * texSize.x , vTextueCoords.y * texSize.y);

        highp vec2 xyMosaic = vec2(floor(xy.x / mosaicSize.x) * mosaicSize.x,
                                        floor(xy.y / mosaicSize.y) * mosaicSize.y );

             //第几块mosaic
        highp vec2 xyFloor = vec2(floor(mod(xy.x, mosaicSize.x)),
                                       floor(mod(xy.y, mosaicSize.y)));

        highp vec2 uvMosaic = vec2(xyMosaic.x / texSize.x, xyMosaic.y / texSize.y);
        gl_FragColor = vec4(texture2D( inputImageTexture, uvMosaic ).rgb,1.0);
    }
    else
        gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
}
 );
NSString*  const kRDMosaicVertexShader = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;
 
 uniform mat4 projection;
 uniform mat4 renderTransform;
 varying vec2 textureCoordinate;
 
 void main()
 {
     textureCoordinate = inputTextureCoordinate;
     gl_Position = projection * renderTransform * position;
    

 }
 );


//纹理链表
typedef struct RD_GL_TEXTURE_LIST
{
    int width;
    int height;
    GLuint texture;
    char imagePath[2048];
    struct RD_GL_TEXTURE_LIST* next;
    
}RD_GL_TEXTURE_LIST;

//帧缓冲区对象
typedef struct RD_GL_FRAME_BUFFER_OBJECT
{
    int width;
    int height;
    GLuint texture;
    GLuint fbo;
    
}RD_GL_FRAME_BUFFER_OBJECT;


@interface RDMosaicFilter()
{

    RD_GL_TEXTURE_LIST* pTextureList;
    
    GLuint mosaicInputTextureUniform;//mosaic texture
    GLuint mosaicInputMainTextureUniform;
    GLuint mosaicPixelSizeUniform;//单个像素在目标纹理中的大小。例如目标纹理将被渲染为 800*600 的矩形，那么单个像素就是 1/800, 1/600
    GLuint mosaicPositionAttribute,mosaicTextureCoordinateAttribute;
    GLuint mosaicPointTLUniform,mosaicPointTRUniform,mosaicPointBLUniform,mosaicPointBRUniform;
    GLuint mosaicVertShader, mosaicFragShader;
    GLuint mosaicProgram;
    GLuint mosaicBlockSizeUniform;// 马赛克大小
    GLuint mosaicProjectionUniform,mosaicTransformUniform;
    
    RD_GL_FRAME_BUFFER_OBJECT firstFrameObject;
    RD_GL_FRAME_BUFFER_OBJECT secondFrameObject;
    
    
    RDMatrix4 modelViewMatrix;
    RDMatrix4 projectionMatrix;
    
    int textureCount;
    float currentTime;
}

@end
@implementation RDMosaicFilter


- (GLuint)textureFromImage:(NSString *) image
{
    CGImageRef        brushImage;
    CGContextRef    brushContext;
    GLubyte            *brushData;
    struct RD_GL_TEXTURE_LIST* pList = NULL;
    struct RD_GL_TEXTURE_LIST* pLast = NULL;
    
    
    if (!pTextureList) {
        pTextureList = (RD_GL_TEXTURE_LIST* )malloc(sizeof(struct RD_GL_TEXTURE_LIST));
        memset(pTextureList, 0, sizeof(struct RD_GL_TEXTURE_LIST));
        pLast = pTextureList;
    }
    else
    {
        pList = pTextureList;
        while (pList) {
            
            //if ([pList->imagePath isEqualToString:image] ) {
            if (!strcmp(pList->imagePath, [image UTF8String]) ) {
                return pList->texture;
            }
            pList = pList->next;
        }
        
        pList = pTextureList;
        while (pList && pList->next) {
            pList = pList->next;
        }
        
        pList->next = (RD_GL_TEXTURE_LIST* )malloc(sizeof(struct RD_GL_TEXTURE_LIST));
        memset(pList->next, 0, sizeof(struct RD_GL_TEXTURE_LIST));
        pLast = pList->next;
        
    }
    strcpy(pLast->imagePath, [image UTF8String]);
    
    
    // First create a UIImage object from the data in a image file, and then extract the Core Graphics image
    //brushImage = [image CGImage];
    brushImage = [UIImage imageNamed:image].CGImage;
    
    // Get the width and height of the image
    pLast->width = (int)CGImageGetWidth(brushImage);
    pLast->height = (int)CGImageGetHeight(brushImage);
    if(pLast->width%2 != 0)
        pLast->width -= 1;
    if(pLast->height%2 != 0)
        pLast->height -= 1;
    
    // Make sure the image exists
    if(brushImage) {
        // Allocate  memory needed for the bitmap context
        brushData = (GLubyte *) calloc(pLast->width * pLast->height * 4, sizeof(GLubyte));
        // Use  the bitmatp creation function provided by the Core Graphics framework.
        brushContext = CGBitmapContextCreate(brushData, pLast->width, pLast->height, 8, pLast->width * 4, CGImageGetColorSpace(brushImage), kCGImageAlphaPremultipliedLast);
        // After you create the context, you can draw the  image to the context.
        CGContextDrawImage(brushContext, CGRectMake(0.0, 0.0, (CGFloat)pLast->width, (CGFloat)pLast->height), brushImage);
        // You don't need the context at this point, so you need to release it to avoid memory leaks.
        CGContextRelease(brushContext);
        
        glEnable(GL_TEXTURE_2D);
        glGenTextures(1, &pLast->texture);
        glBindTexture(GL_TEXTURE_2D, pLast->texture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)pLast->width, (int)pLast->height, 0, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid*)brushData);
        
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
        return pLast->texture;
        
    }
    NSLog(@"Failed to create texture from image: %@", image);
    return -1;
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
    mosaicProgram          = glCreateProgram();
    
    if (![self compileShader:&mosaicVertShader type:GL_VERTEX_SHADER source:kRDMosaicVertexShader]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    
    if (![self compileShader:&mosaicFragShader type:GL_FRAGMENT_SHADER source:kRDMosaicFragmentShaderString]) {
        NSLog(@"Failed to compile cust fragment shader");
        return NO;
    }
    
    glAttachShader(mosaicProgram, mosaicVertShader);
    glAttachShader(mosaicProgram, mosaicFragShader);

    
    if (![self linkProgram:mosaicProgram]) {
        
        if (mosaicVertShader) {
            glDeleteShader(mosaicVertShader);
            mosaicVertShader = 0;
        }
        if (mosaicFragShader) {
            glDeleteShader(mosaicFragShader);
            mosaicFragShader = 0;
        }
        
        return NO;
    }
 
    
    mosaicPositionAttribute = glGetAttribLocation(mosaicProgram, "position");
    mosaicTextureCoordinateAttribute = glGetAttribLocation(mosaicProgram, "inputTextureCoordinate");
    mosaicProjectionUniform = glGetUniformLocation(mosaicProgram, "projection");
    mosaicTransformUniform = glGetUniformLocation(mosaicProgram, "renderTransform");
    mosaicInputTextureUniform = glGetUniformLocation(mosaicProgram, "inputImageTexture2");
    mosaicInputMainTextureUniform = glGetUniformLocation(mosaicProgram, "inputImageTexture");
    mosaicPixelSizeUniform = glGetUniformLocation(mosaicProgram, "inputpixelSize");
    mosaicBlockSizeUniform = glGetUniformLocation(mosaicProgram, "mosaicBlockSize");
    mosaicPointBLUniform = glGetUniformLocation(mosaicProgram, "pointLB");
    mosaicPointTLUniform = glGetUniformLocation(mosaicProgram, "pointLT");
    mosaicPointTRUniform = glGetUniformLocation(mosaicProgram, "pointRT");
    mosaicPointBRUniform = glGetUniformLocation(mosaicProgram, "pointRB");
    
    // Release vertex and fragment shaders.
    if (mosaicVertShader) {
        glDetachShader(mosaicProgram, mosaicVertShader);
        glDeleteShader(mosaicVertShader);
    }
    if (mosaicFragShader) {
        glDetachShader(mosaicProgram, mosaicFragShader);
        glDeleteShader(mosaicFragShader);
    }
    
    return YES;
}

- (instancetype)initWithImage:(UIImage *)image{
    
    
    if (!(self = [super init])) {
        return nil;
    }
    
    if(![self loadShaders])
    {
        NSLog(@"[self loadShaders] loader shader fail!");
    }
    
    return self;
}

- (GLuint)textureFromFrameBufferObject:(unsigned char *) image Width:(int )width Height:(int)height
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

- (void)transformScreenCoordinates:(GLfloat *)srcVert toShsderVertexCoordinates:(GLfloat *)destVert
{
    
    //srcVert ：坐标原点在左上角 （介于0 到1之间）
    //destVert：坐标原点在屏幕中心（介于-1到1之间）
    
    for(int i = 0;i<8;i++)
    {
        if(0 == i%2)
        {
            //x
           destVert[i] = (srcVert[i]-0.5)*2;
        }
        else
        {
            //y
            destVert[i] = -(0.5-srcVert[i])*2;
        }
    }
    
    
}

-(int)initFrameBufferObjectWithWidth:(int)width Height:(int)height
{
    unsigned char* pImage = nil;
    if(firstFrameObject.texture)
    {
        glDeleteTextures(1, &firstFrameObject.texture);
        firstFrameObject.texture = 0;
    }
        
    if(firstFrameObject.fbo)
    {
        glDeleteFramebuffers(1,&firstFrameObject.fbo);
        firstFrameObject.fbo = 0;
    }
    
    if(secondFrameObject.texture)
    {
        glDeleteTextures(1, &secondFrameObject.texture);
        secondFrameObject.texture = 0;
    }
    if(secondFrameObject.fbo)
    {
        glDeleteFramebuffers(1,&secondFrameObject.fbo);
        secondFrameObject.fbo = 0;
    }
    
    if(!firstFrameObject.fbo)
        glGenFramebuffers(1, &firstFrameObject.fbo);
    if(!secondFrameObject.fbo)
        glGenFramebuffers(1, &secondFrameObject.fbo);
    
    firstFrameObject.width = width;
    firstFrameObject.height = height;
    
    secondFrameObject.width = width;
    secondFrameObject.height = height;
    
    pImage = (unsigned char*)malloc(width*height*4);
    for (int i = 0; i<width*height; i++) {
            
        pImage[i*4] = 0xFF;
        pImage[i*4+1] = 0x00;
        pImage[i*4+2] = 0x00;
        pImage[i*4+3] = 0xFF;
    }

    firstFrameObject.texture = [self textureFromBufferObject:pImage Width:width Height:height];
    secondFrameObject.texture = [self textureFromBufferObject:pImage Width:width Height:height];
    free(pImage);
    
    return 1;
}



-(bool)renderMosaicToFrameBufferWithCurrentTime:(float)seconds Vertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates
{
    bool        hasMosaic = false;
    //检查当前时间是否有马赛克
    for(int j = 0; j < _mosaics.count; j++)
    {
        CMTimeRange mosaicsTimeRange = ([[_mosaics objectAtIndex:j] timeRange]);
        float mosaicsStartTime = CMTimeGetSeconds(mosaicsTimeRange.start);
        float mosaicsEndTime = mosaicsStartTime + CMTimeGetSeconds(mosaicsTimeRange.duration);
        if (seconds < mosaicsStartTime || seconds > mosaicsEndTime) {
            continue;
        }
        else
        {
            hasMosaic = true;
            break;
        }

    }
    //没有马赛克，直接返回false
    if(!hasMosaic)
        return false;
    
    //如果有马赛克，绘制到临时FBO
    CGSize size = [self sizeOfFBO];
    int         width = size.width;
    int         height = size.height;
    textureCount = 0;
    //开启blend
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glUseProgram(mosaicProgram);

    
    for(int i = 0; i < _mosaics.count;i++)
    {
        RDMosaic *mosaic = [_mosaics objectAtIndex:i];
        float blockSize = mosaic.mosaicSize*90 + 10.0;//0~100
        NSArray* pointsArray = mosaic.pointsArray;//[NSArray arrayWithObjects:NSStringFromCGPoint(CGPointMake(0, 0)),
//                                NSStringFromCGPoint(CGPointMake(0.5, 0)),NSStringFromCGPoint(CGPointMake(0.5, 0.5)),
//                                NSStringFromCGPoint(CGPointMake(0, 0.5)),nil];;


//        if(i == 0)
//        {
//            blockSize = 20;
//            pointsArray = [NSArray arrayWithObjects:NSStringFromCGPoint(CGPointMake(0, 0)),
//            NSStringFromCGPoint(CGPointMake(0.5, 0)),
//            NSStringFromCGPoint(CGPointMake(0.5, 0.5)),
//            NSStringFromCGPoint(CGPointMake(0, 0.5)),nil];;
//        }
//        else
//        {
//            blockSize = 80;
//            pointsArray = [NSArray arrayWithObjects:NSStringFromCGPoint(CGPointMake(0.5, 0.5)),
//            NSStringFromCGPoint(CGPointMake(1.0, 0.5)),
//            NSStringFromCGPoint(CGPointMake(1.0, 1.0)),
//            NSStringFromCGPoint(CGPointMake(0.5, 1.0)),nil];;
//        }

        CMTimeRange mosaicsTimeRange = ([[_mosaics objectAtIndex:i] timeRange]);
        float mosaicsStartTime = CMTimeGetSeconds(mosaicsTimeRange.start);
        float mosaicsEndTime = mosaicsStartTime + CMTimeGetSeconds(mosaicsTimeRange.duration);
        //如果有多个马赛克，检查当前时间点应该显示的马赛克
        if (seconds < mosaicsStartTime || seconds > mosaicsEndTime) {
            continue;
        }
        
        if(!firstFrameObject.fbo || width != firstFrameObject.width || height != firstFrameObject.height)
            [self initFrameBufferObjectWithWidth:width Height:height];

        //处理马赛克
        if (textureCount % 2 == 0) {
            glBindFramebuffer(GL_FRAMEBUFFER, firstFrameObject.fbo);
            glViewport(0, 0, width, height);

            // Attach the destination texture as a color attachment to the off screen frame buffer
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, firstFrameObject.texture, 0);

            if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
                NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
            }
            
            //draw
            if(textureCount == 0)
                [self renderTotexture:[firstInputFramebuffer texture] Width:width Height:height PointArray:pointsArray BlockSize:blockSize Vertices:vertices textureCoordinates:textureCoordinates];
            else
                [self renderTotexture:secondFrameObject.texture Width:width Height:height PointArray:pointsArray BlockSize:blockSize Vertices:vertices textureCoordinates:textureCoordinates];
            
            glBindFramebuffer(GL_FRAMEBUFFER, 0);
        }
        else
        {
            glBindFramebuffer(GL_FRAMEBUFFER, secondFrameObject.fbo);
            glViewport(0, 0, width, height);

            // Attach the destination texture as a color attachment to the off screen frame buffer
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, secondFrameObject.texture, 0);

            if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
                NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
            }
            
            //draw
            [self renderTotexture:firstFrameObject.texture Width:width Height:height PointArray:pointsArray BlockSize:blockSize Vertices:vertices textureCoordinates:textureCoordinates];
            glBindFramebuffer(GL_FRAMEBUFFER, 0);
        }
       
       textureCount++;
    }
//    glUseProgram(0);
    return true;
    
}
-(void )renderTotexture:(GLuint)texture Width:(int )width Height:(int)height PointArray:(NSArray*)pointsArray BlockSize:(float)blockSize Vertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates
{
 
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture );
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glUniform1i(mosaicInputMainTextureUniform,0);
    
    glUniform2f(mosaicPixelSizeUniform,1.0/(float)(width),1.0/(float)(height));
    glUniform1f(mosaicBlockSizeUniform, blockSize);

    RDMatrixLoadIdentity(&modelViewMatrix);
    glUniformMatrix4fv(mosaicTransformUniform, 1, GL_FALSE, (GLfloat*)&modelViewMatrix.m[0][0]);
    
    RDMatrixLoadIdentity(&projectionMatrix);
    glUniformMatrix4fv(mosaicProjectionUniform, 1, GL_FALSE, (GLfloat*)&projectionMatrix.m[0][0]);
    
    //获取马赛克区域坐标
    CGPoint pointTL= CGPointFromString([pointsArray objectAtIndex:0]);
    CGPoint pointTR= CGPointFromString([pointsArray objectAtIndex:1]);
    CGPoint pointBR= CGPointFromString([pointsArray objectAtIndex:2]);
    CGPoint pointBL= CGPointFromString([pointsArray objectAtIndex:3]);
    
    //设置马赛克区域坐标
    glUniform2f(mosaicPointTLUniform, pointTL.x, pointTL.y);
    glUniform2f(mosaicPointTRUniform, pointTR.x, pointTR.y);
    glUniform2f(mosaicPointBLUniform, pointBL.x, pointBL.y);
    glUniform2f(mosaicPointBRUniform, pointBR.x, pointBR.y);
    
    glVertexAttribPointer(mosaicPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glEnableVertexAttribArray(mosaicPositionAttribute);
    
    glVertexAttribPointer(mosaicTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    glEnableVertexAttribArray(mosaicTextureCoordinateAttribute);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    
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
    
    bool hasMosaic = false;
    
    if (self.preventRendering)
    {
        [firstInputFramebuffer unlock];
        return;
    }
    hasMosaic = [self renderMosaicToFrameBufferWithCurrentTime:currentTime Vertices:vertices textureCoordinates:textureCoordinates];
    [RDGPUImageContext setActiveShaderProgram:filterProgram];
    
    outputFramebuffer = [[RDGPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    if (usingNextFrameForImageCapture)
    {
        [outputFramebuffer lock];
    }
    
//    CVPixelBufferRef p = [outputFramebuffer pixelBuffer];
    [self setUniformsForProgramAtIndex:0];
    
    
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE2);

    if (hasMosaic) {
        if(textureCount %2 == 0)
            glBindTexture(GL_TEXTURE_2D, secondFrameObject.texture);
        else
            glBindTexture(GL_TEXTURE_2D, firstFrameObject.texture);
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
- (void)setIntensity:(CGFloat)intensity
{
    
}

- (instancetype)initWithImageNetPath:(NSString *)path
{
    UIImage* image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:path]]];
    if(image){
        return [self initWithImage:image];
    }
    return nil;
}

- (instancetype)initWithImagePath:(NSString *)path
{

#if 0
    UIImage* image = [UIImage imageWithContentsOfFile:path];
    if(image){
        return [self initWithImage:image];
    }
    return nil;
#else
    return [self initWithImage:NULL];
#endif
    
}
- (instancetype)initWithImageNamed:(NSString *)name{
    UIImage* image = [UIImage imageNamed:name];
    return [self initWithImage:image];
}
- (void)dealloc{
    
    
    while(pTextureList)
    {
        
        struct RD_GL_TEXTURE_LIST* pList = pTextureList->next;
        if(pTextureList->texture)
            glDeleteTextures(1, &pTextureList->texture);
        free(pTextureList);
        pTextureList = pList;
    }
    pTextureList = NULL;
    
    if(firstFrameObject.texture)
        glDeleteTextures(1, &firstFrameObject.texture);
    if(firstFrameObject.fbo)
        glDeleteFramebuffers(1,&firstFrameObject.fbo);
    
    if(secondFrameObject.texture)
        glDeleteTextures(1, &secondFrameObject.texture);
    if(secondFrameObject.fbo)
        glDeleteFramebuffers(1,&secondFrameObject.fbo);
    
    if (mosaicProgram)
        glDeleteProgram(mosaicProgram);
}
@end
