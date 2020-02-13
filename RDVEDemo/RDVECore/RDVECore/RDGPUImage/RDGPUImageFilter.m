#import "RDGPUImageFilter.h"
#import "RDGPUImagePicture.h"
#import <AVFoundation/AVFoundation.h>

// Hardcode the vertex shader for standard filters, but this can be overridden
NSString *const kRDGPUImageVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 attribute vec2 inputTextureMaskCoordinate;
 
 
 varying vec2 textureCoordinate;
 varying vec2 textureMaskCoordinate;
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
     textureMaskCoordinate = inputTextureMaskCoordinate.xy;
 }
 );

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE

NSString *const kRDGPUImagePassthroughFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureMaskCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform highp float inputMosaic;//区分是不是mosaic
 
 void main()
 {
     
     if(1.0 == inputMosaic)
     {
         
         highp vec4 mosaicColor = texture2D( inputImageTexture2, textureCoordinate );
         if(mosaicColor.r == 1.0)
         {
             highp vec2 texSize = vec2(0.0,0.0);
             highp vec2 mosaicSize = vec2(20.0,20.0);//马赛克大小
             highp vec2 vTextueCoords = textureCoordinate;

             texSize.x = 852.0;//1.0/pixelSize.x;
             texSize.y = 476.0;//1.0/pixelSize.y;


             highp vec2 xy = vec2(vTextueCoords.x * texSize.x , vTextueCoords.y * texSize.y);

             highp vec2 xyMosaic = vec2(floor(xy.x / mosaicSize.x) * mosaicSize.x,
                                  floor(xy.y / mosaicSize.y) * mosaicSize.y );

             //第几块mosaic
             highp vec2 xyFloor = vec2(floor(mod(xy.x, mosaicSize.x)),
                                 floor(mod(xy.y, mosaicSize.y)));

             highp vec2 uvMosaic = vec2(xyMosaic.x / texSize.x, xyMosaic.y / texSize.y);
             gl_FragColor = texture2D( inputImageTexture, uvMosaic );

         }
         else
             gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
     }
     else
     {
         gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
     }
 }
);

#else

NSString *const kRDGPUImagePassthroughFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
);
#endif


@implementation RDGPUImageFilter

@synthesize preventRendering = _preventRendering;
@synthesize currentlyReceivingMonochromeInput;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithVertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString;
{
    if (!(self = [super init]))
    {
		return nil;
    }

    uniformStateRestorationBlocks = [NSMutableDictionary dictionaryWithCapacity:10];
    _preventRendering = NO;
    currentlyReceivingMonochromeInput = NO;
    inputRotation = kRDGPUImageNoRotation;
    backgroundColorRed = 0.0;
    backgroundColorGreen = 0.0;
    backgroundColorBlue = 0.0;
    backgroundColorAlpha = 0.0;
    imageCaptureSemaphore = dispatch_semaphore_create(0);
    dispatch_semaphore_signal(imageCaptureSemaphore);

    rdRunSynchronouslyOnVideoProcessingQueue(^{
        [RDGPUImageContext useImageProcessingContext];

        filterProgram = [[RDGPUImageContext sharedImageProcessingContext] programForVertexShaderString:vertexShaderString fragmentShaderString:fragmentShaderString];
        
        if (!filterProgram.initialized)
        {
            [self initializeAttributes];
            
            if (![filterProgram link])
            {
                NSString *progLog = [filterProgram programLog];
                NSLog(@"Program link log: %@", progLog);
                NSString *fragLog = [filterProgram fragmentShaderLog];
                NSLog(@"Fragment shader compile log: %@", fragLog);
                NSString *vertLog = [filterProgram vertexShaderLog];
                NSLog(@"Vertex shader compile log: %@", vertLog);
                filterProgram = nil;
                NSAssert(NO, @"Filter shader link failed");
            }
        }
        
        filterPositionAttribute = [filterProgram attributeIndex:@"position"];
        filterTextureCoordinateAttribute = [filterProgram attributeIndex:@"inputTextureCoordinate"];
        filterTextureMaskCoordinateAttribute = [filterProgram attributeIndex:@"inputTextureMaskCoordinate"];
        filterInputTextureUniform = [filterProgram uniformIndex:@"inputImageTexture"]; // This does assume a name of "inputImageTexture" for the fragment shader
        [RDGPUImageContext setActiveShaderProgram:filterProgram];
        
        glEnableVertexAttribArray(filterPositionAttribute);
        glEnableVertexAttribArray(filterTextureCoordinateAttribute);    
    });
    
    return self;
}

- (id)initWithFragmentShaderFromString:(NSString *)fragmentShaderString;
{
    if (!(self = [self initWithVertexShaderFromString:kRDGPUImageVertexShaderString fragmentShaderFromString:fragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

- (id)initWithFragmentShaderFromFile:(NSString *)fragmentShaderFilename;
{
    NSString *fragmentShaderPathname = [[NSBundle mainBundle] pathForResource:fragmentShaderFilename ofType:@"fsh"];
    NSString *fragmentShaderString = [NSString stringWithContentsOfFile:fragmentShaderPathname encoding:NSUTF8StringEncoding error:nil];

    if (!(self = [self initWithFragmentShaderFromString:fragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

- (id)init;
{
    if (!(self = [self initWithFragmentShaderFromString:kRDGPUImagePassthroughFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

- (void)initializeAttributes;
{
    [filterProgram addAttribute:@"position"];
	[filterProgram addAttribute:@"inputTextureCoordinate"];
    [filterProgram addAttribute:@"inputTextureMaskCoordinate"];

    // Override this, calling back to this super method, in order to add new attributes to your vertex shader
}

- (void)setupFilterForSize:(CGSize)filterFrameSize;
{
    // This is where you can override to provide some custom setup, if your filter has a size-dependent element
}

//- (void)dealloc
//{
//#if !OS_OBJECT_USE_OBJC
//    if (imageCaptureSemaphore != NULL)
//    {
//        dispatch_release(imageCaptureSemaphore);
//    }
//#endif
//
//}

#pragma mark -
#pragma mark Still image processing

- (void)useNextFrameForImageCapture;
{
//    RDGPUImageFramebuffer* framebuffer = [self framebufferForOutput];
    usingNextFrameForImageCapture = YES;

    // Set the semaphore high, if it isn't already
    if (dispatch_semaphore_wait(imageCaptureSemaphore, DISPATCH_TIME_NOW) != 0)
    {
        return;
    }
}

- (CGImageRef)newCGImageFromCurrentlyProcessedOutput
{
    // Give it three seconds to process, then abort if they forgot to set up the image capture properly
    double timeoutForImageCapture = 3.0;
    dispatch_time_t convertedTimeout = dispatch_time(DISPATCH_TIME_NOW, timeoutForImageCapture * NSEC_PER_SEC);

    if (dispatch_semaphore_wait(imageCaptureSemaphore, convertedTimeout) != 0)
    {
        return NULL;
    }

     RDGPUImageFramebuffer *framebuffer = [self framebufferForOutput];
    
    usingNextFrameForImageCapture = NO;
    dispatch_semaphore_signal(imageCaptureSemaphore);
    
    CGImageRef image = [framebuffer newCGImageFromFramebufferContents];
    return image;
}

#pragma mark -
#pragma mark Managing the display FBOs

- (CGSize)sizeOfFBO;
{
    CGSize outputSize = [self maximumOutputSize];
    if ( (CGSizeEqualToSize(outputSize, CGSizeZero)) || (inputTextureSize.width < outputSize.width) )
    {
        return inputTextureSize;
    }
    else
    {
        return outputSize;
    }
}

#pragma mark -
#pragma mark Rendering

+ (const GLfloat *)textureCoordinatesForRotation:(RDGPUImageRotationMode)rotationMode;
{
    static const GLfloat noRotationTextureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    
    static const GLfloat rotateLeftTextureCoordinates[] = {
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
    };
    
    static const GLfloat rotateRightTextureCoordinates[] = {
        0.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
    };
    
    static const GLfloat verticalFlipTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f,  0.0f,
        1.0f,  0.0f,
    };
    
    static const GLfloat horizontalFlipTextureCoordinates[] = {
        1.0f, 0.0f,
        0.0f, 0.0f,
        1.0f,  1.0f,
        0.0f,  1.0f,
    };
    
    static const GLfloat rotateRightVerticalFlipTextureCoordinates[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
    };

    static const GLfloat rotateRightHorizontalFlipTextureCoordinates[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
    };

    static const GLfloat rotate180TextureCoordinates[] = {
        1.0f, 1.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
    };

    switch(rotationMode)
    {
        case kRDGPUImageNoRotation: return noRotationTextureCoordinates;
        case kRDGPUImageRotateLeft: return rotateLeftTextureCoordinates;
        case kRDGPUImageRotateRight: return rotateRightTextureCoordinates;
        case kRDGPUImageFlipVertical: return verticalFlipTextureCoordinates;
        case kRDGPUImageFlipHorizonal: return horizontalFlipTextureCoordinates;
        case kRDGPUImageRotateRightFlipVertical: return rotateRightVerticalFlipTextureCoordinates;
        case kRDGPUImageRotateRightFlipHorizontal: return rotateRightHorizontalFlipTextureCoordinates;
        case kRDGPUImageRotate180: return rotate180TextureCoordinates;
    }
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{

//    CVPixelBufferRef p = NULL;
    if (self.preventRendering)
    {
        [firstInputFramebuffer unlock];
        return;
    }
    
    [RDGPUImageContext setActiveShaderProgram:filterProgram];

    outputFramebuffer = [[RDGPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    
//    p = [outputFramebuffer pixelBuffer];
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

    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
	glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [firstInputFramebuffer unlock];
    
    if (usingNextFrameForImageCapture)
    {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
}

- (void)informTargetsAboutNewFrameAtTime:(CMTime)frameTime;
{
   
    
    if (self.frameProcessingCompletionBlock != NULL)
    {
        self.frameProcessingCompletionBlock(self, frameTime);
    }
    if(self.hasGetMVEffectImageBlock){
        if(self.frameImageProcessingCompletionBlock!= NULL){
            self.frameImageProcessingCompletionBlock(self, frameTime);
        }
    }
    
    // Get all targets the framebuffer so they can grab a lock on it
    for (id<RDGPUImageInput> currentTarget in targets)
    {
        if (currentTarget != self.targetToIgnoreForUpdates)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];

            [self setInputFramebufferForTarget:currentTarget atIndex:textureIndex];
            [currentTarget setInputSize:[self outputFrameSize] atIndex:textureIndex];
        }
    }
    
    // Release our hold so it can return to the cache immediately upon processing
    [[self framebufferForOutput] unlock];
    
    if (usingNextFrameForImageCapture)
    {
        usingNextFrameForImageCapture = NO;
    }
    else
    {
        //emmet 20170709
        [self removeOutputFramebuffer];
    }
    
    // Trigger processing last, so that our unlock comes first in serial execution, avoiding the need for a callback
    for (id<RDGPUImageInput> currentTarget in targets)
    {
        if (currentTarget != self.targetToIgnoreForUpdates)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            //NSLog(@"%s %d  frameTime:%f,index:%ld",__func__,__LINE__,CMTimeGetSeconds(frameTime),textureIndex);
            [currentTarget newFrameReadyAtTime:frameTime atIndex:textureIndex];
        }
    }
}

- (CGSize)outputFrameSize;
{
    return inputTextureSize;
}

#pragma mark -
#pragma mark Input parameters

- (void)setBackgroundColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent alpha:(GLfloat)alphaComponent;
{
    backgroundColorRed = redComponent;
    backgroundColorGreen = greenComponent;
    backgroundColorBlue = blueComponent;
    backgroundColorAlpha = alphaComponent;
}

- (void)setInteger:(GLint)newInteger forUniformName:(NSString *)uniformName;
{
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    [self setInteger:newInteger forUniform:uniformIndex program:filterProgram];
}

- (void)setFloat:(GLfloat)newFloat forUniformName:(NSString *)uniformName;
{
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    [self setFloat:newFloat forUniform:uniformIndex program:filterProgram];
}

- (void)setSize:(CGSize)newSize forUniformName:(NSString *)uniformName;
{
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    [self setSize:newSize forUniform:uniformIndex program:filterProgram];
}

- (void)setPoint:(CGPoint)newPoint forUniformName:(NSString *)uniformName;
{
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    [self setPoint:newPoint forUniform:uniformIndex program:filterProgram];
}

- (void)setFloatVec3:(RDGPUVectore3)newVec3 forUniformName:(NSString *)uniformName;
{
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    [self setVec3:newVec3 forUniform:uniformIndex program:filterProgram];
}

- (void)setFloatVec4:(RDGPUVectore4)newVec4 forUniform:(NSString *)uniformName;
{
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    [self setVec4:newVec4 forUniform:uniformIndex program:filterProgram];
}

- (void)setFloatArray:(GLfloat *)array length:(GLsizei)count forUniform:(NSString*)uniformName
{
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    
    [self setFloatArray:array length:count forUniform:uniformIndex program:filterProgram];
}

- (void)setMatrix3f:(RDGPUMatrix3x3)matrix forUniform:(GLint)uniform program:(RDGLProgram *)shaderProgram;
{
    rdRunAsynchronouslyOnVideoProcessingQueue(^{
        [RDGPUImageContext setActiveShaderProgram:shaderProgram];
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniformMatrix3fv(uniform, 1, GL_FALSE, (GLfloat *)&matrix);
        }];
    });
}

- (void)setMatrix4f:(RDGPUMatrix4x4)matrix forUniform:(GLint)uniform program:(RDGLProgram *)shaderProgram;
{
    rdRunAsynchronouslyOnVideoProcessingQueue(^{
        [RDGPUImageContext setActiveShaderProgram:shaderProgram];
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniformMatrix4fv(uniform, 1, GL_FALSE, (GLfloat *)&matrix);
        }];
    });
}

- (void)setFloat:(GLfloat)floatValue forUniform:(GLint)uniform program:(RDGLProgram *)shaderProgram;
{
    rdRunAsynchronouslyOnVideoProcessingQueue(^{
        [RDGPUImageContext setActiveShaderProgram:shaderProgram];
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniform1f(uniform, floatValue);
        }];
    });
}

- (void)setPoint:(CGPoint)pointValue forUniform:(GLint)uniform program:(RDGLProgram *)shaderProgram;
{
    rdRunAsynchronouslyOnVideoProcessingQueue(^{
        [RDGPUImageContext setActiveShaderProgram:shaderProgram];
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            GLfloat positionArray[2];
            positionArray[0] = pointValue.x;
            positionArray[1] = pointValue.y;
            
            glUniform2fv(uniform, 1, positionArray);
        }];
    });
}

- (void)setSize:(CGSize)sizeValue forUniform:(GLint)uniform program:(RDGLProgram *)shaderProgram;
{
    rdRunAsynchronouslyOnVideoProcessingQueue(^{
        [RDGPUImageContext setActiveShaderProgram:shaderProgram];
        
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            GLfloat sizeArray[2];
            sizeArray[0] = sizeValue.width;
            sizeArray[1] = sizeValue.height;
            
            glUniform2fv(uniform, 1, sizeArray);
        }];
    });
}

- (void)setVec3:(RDGPUVectore3)vectorValue forUniform:(GLint)uniform program:(RDGLProgram *)shaderProgram;
{
    rdRunAsynchronouslyOnVideoProcessingQueue(^{
        [RDGPUImageContext setActiveShaderProgram:shaderProgram];

        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniform3fv(uniform, 1, (GLfloat *)&vectorValue);
        }];
    });
}

- (void)setVec4:(RDGPUVectore4)vectorValue forUniform:(GLint)uniform program:(RDGLProgram *)shaderProgram;
{
    rdRunAsynchronouslyOnVideoProcessingQueue(^{
        [RDGPUImageContext setActiveShaderProgram:shaderProgram];
        
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniform4fv(uniform, 1, (GLfloat *)&vectorValue);
        }];
    });
}

- (void)setFloatArray:(GLfloat *)arrayValue length:(GLsizei)arrayLength forUniform:(GLint)uniform program:(RDGLProgram *)shaderProgram;
{
    // Make a copy of the data, so it doesn't get overwritten before async call executes
    NSData* arrayData = [NSData dataWithBytes:arrayValue length:arrayLength * sizeof(arrayValue[0])];

    rdRunAsynchronouslyOnVideoProcessingQueue(^{
        [RDGPUImageContext setActiveShaderProgram:shaderProgram];
        
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniform1fv(uniform, arrayLength, [arrayData bytes]);
        }];
    });
}

- (void)setInteger:(GLint)intValue forUniform:(GLint)uniform program:(RDGLProgram *)shaderProgram;
{
    rdRunAsynchronouslyOnVideoProcessingQueue(^{
        [RDGPUImageContext setActiveShaderProgram:shaderProgram];

        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniform1i(uniform, intValue);
        }];
    });
}

- (void)setAndExecuteUniformStateCallbackAtIndex:(GLint)uniform forProgram:(RDGLProgram *)shaderProgram toBlock:(dispatch_block_t)uniformStateBlock;
{
    [uniformStateRestorationBlocks setObject:[uniformStateBlock copy] forKey:[NSNumber numberWithInt:uniform]];
    uniformStateBlock();
}

- (void)setUniformsForProgramAtIndex:(NSUInteger)programIndex;
{
    [uniformStateRestorationBlocks enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
        dispatch_block_t currentBlock = obj;
        currentBlock();
    }];
}

#pragma mark -
#pragma mark RDGPUImageInput

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    
    
    static const GLfloat imageVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    //NSLog(@"frameTime:%lf",CMTimeGetSeconds(frameTime));
    [self renderToTextureWithVertices:imageVertices textureCoordinates:[[self class] textureCoordinatesForRotation:inputRotation]];

    [self informTargetsAboutNewFrameAtTime:frameTime];
}

- (NSInteger)nextAvailableTextureIndex;
{
    return 0;
}

- (void)setInputFramebuffer:(RDGPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
{
    firstInputFramebuffer = newInputFramebuffer;
    [firstInputFramebuffer lock];
}

- (CGSize)rotatedSize:(CGSize)sizeToRotate forIndex:(NSInteger)textureIndex;
{
    CGSize rotatedSize = sizeToRotate;
    
    if (RDGPUImageRotationSwapsWidthAndHeight(inputRotation))
    {
        rotatedSize.width = sizeToRotate.height;
        rotatedSize.height = sizeToRotate.width;
    }
    
    return rotatedSize; 
}

- (CGPoint)rotatedPoint:(CGPoint)pointToRotate forRotation:(RDGPUImageRotationMode)rotation;
{
    CGPoint rotatedPoint;
    switch(rotation)
    {
        case kRDGPUImageNoRotation: return pointToRotate; break;
        case kRDGPUImageFlipHorizonal:
        {
            rotatedPoint.x = 1.0 - pointToRotate.x;
            rotatedPoint.y = pointToRotate.y;
        }; break;
        case kRDGPUImageFlipVertical:
        {
            rotatedPoint.x = pointToRotate.x;
            rotatedPoint.y = 1.0 - pointToRotate.y;
        }; break;
        case kRDGPUImageRotateLeft:
        {
            rotatedPoint.x = 1.0 - pointToRotate.y;
            rotatedPoint.y = pointToRotate.x;
        }; break;
        case kRDGPUImageRotateRight:
        {
            rotatedPoint.x = pointToRotate.y;
            rotatedPoint.y = 1.0 - pointToRotate.x;
        }; break;
        case kRDGPUImageRotateRightFlipVertical:
        {
            rotatedPoint.x = pointToRotate.y;
            rotatedPoint.y = pointToRotate.x;
        }; break;
        case kRDGPUImageRotateRightFlipHorizontal:
        {
            rotatedPoint.x = 1.0 - pointToRotate.y;
            rotatedPoint.y = 1.0 - pointToRotate.x;
        }; break;
        case kRDGPUImageRotate180:
        {
            rotatedPoint.x = 1.0 - pointToRotate.x;
            rotatedPoint.y = 1.0 - pointToRotate.y;
        }; break;
    }
    
    return rotatedPoint;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    if (self.preventRendering)
    {
        return;
    }
    
    if (overrideInputSize)
    {
        if (CGSizeEqualToSize(forcedMaximumSize, CGSizeZero))
        {
        }
        else
        {
            CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(newSize, CGRectMake(0.0, 0.0, forcedMaximumSize.width, forcedMaximumSize.height));
            inputTextureSize = insetRect.size;
        }
    }
    else
    {
        CGSize rotatedSize = [self rotatedSize:newSize forIndex:textureIndex];
        
        if (CGSizeEqualToSize(rotatedSize, CGSizeZero))
        {
            inputTextureSize = rotatedSize;
        }
        else if (!CGSizeEqualToSize(inputTextureSize, rotatedSize))
        {
            inputTextureSize = rotatedSize;
        }
    }
    
    [self setupFilterForSize:[self sizeOfFBO]];
}

- (void)setInputRotation:(RDGPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
    inputRotation = newInputRotation;
}

- (void)forceProcessingAtSize:(CGSize)frameSize;
{    
    if (CGSizeEqualToSize(frameSize, CGSizeZero))
    {
        overrideInputSize = NO;
    }
    else
    {
        overrideInputSize = YES;
        inputTextureSize = frameSize;
        forcedMaximumSize = CGSizeZero;
    }
}

- (void)forceProcessingAtSizeRespectingAspectRatio:(CGSize)frameSize;
{
    if (CGSizeEqualToSize(frameSize, CGSizeZero))
    {
        overrideInputSize = NO;
        inputTextureSize = CGSizeZero;
        forcedMaximumSize = CGSizeZero;
    }
    else
    {
        overrideInputSize = YES;
        forcedMaximumSize = frameSize;
    }
}

- (CGSize)maximumOutputSize;
{
    // I'm temporarily disabling adjustments for smaller output sizes until I figure out how to make this work better
    return CGSizeZero;

    /*
    if (CGSizeEqualToSize(cachedMaximumOutputSize, CGSizeZero))
    {
        for (id<RDGPUImageInput> currentTarget in targets)
        {
            if ([currentTarget maximumOutputSize].width > cachedMaximumOutputSize.width)
            {
                cachedMaximumOutputSize = [currentTarget maximumOutputSize];
            }
        }
    }
    
    return cachedMaximumOutputSize;
     */
}

- (void)endProcessing 
{
    if (!isEndProcessing)
    {
        isEndProcessing = YES;
        
        for (id<RDGPUImageInput> currentTarget in targets)
        {
            [currentTarget endProcessing];
        }
    }
}

- (BOOL)wantsMonochromeInput;
{
    return NO;
}

#pragma mark -
#pragma mark Accessors

@end
