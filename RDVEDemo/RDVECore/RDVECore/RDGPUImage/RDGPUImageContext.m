#import "RDGPUImageContext.h"
#import <OpenGLES/EAGLDrawable.h>
#import <AVFoundation/AVFoundation.h>

#define MAXSHADERPROGRAMSALLOWEDINCACHE 40

extern dispatch_queue_attr_t RDGPUImageDefaultQueueAttribute(void);

@interface RDGPUImageContext()
{
    NSMutableDictionary *shaderProgramCache;
    NSMutableArray *shaderProgramUsageHistory;
    EAGLSharegroup *_sharegroup;
}

@end

@implementation RDGPUImageContext

@synthesize context = _context;
@synthesize currentShaderProgram = _currentShaderProgram;
@synthesize contextQueue = _contextQueue;
@synthesize coreVideoTextureCache = _coreVideoTextureCache;
@synthesize framebufferCache = _framebufferCache;

static void *openGLESContextQueueKey;

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }

	openGLESContextQueueKey = &openGLESContextQueueKey;
    _contextQueue = dispatch_queue_create("com.sunsetlakesoftware.RDGPUImage.openGLESContextQueue", RDGPUImageDefaultQueueAttribute());
    
#if OS_OBJECT_USE_OBJC
	dispatch_queue_set_specific(_contextQueue, openGLESContextQueueKey, (__bridge void *)self, NULL);
#endif
    shaderProgramCache = [[NSMutableDictionary alloc] init];
    shaderProgramUsageHistory = [[NSMutableArray alloc] init];
    
    return self;
}

+ (void *)contextKey {
	return openGLESContextQueueKey;
}

// Based on Colin Wheeler's example here: http://cocoasamurai.blogspot.com/2011/04/singletons-your-doing-them-wrong.html
+ (RDGPUImageContext *)sharedImageProcessingContext;
{
    static dispatch_once_t pred;
    static RDGPUImageContext *sharedImageProcessingContext = nil;
    
    dispatch_once(&pred, ^{
        sharedImageProcessingContext = [[[self class] alloc] init];
    });
    return sharedImageProcessingContext;
}

+ (dispatch_queue_t)sharedContextQueue;
{
    return [[self sharedImageProcessingContext] contextQueue];
}

+ (RDGPUImageFramebufferCache *)sharedFramebufferCache;
{
    return [[self sharedImageProcessingContext] framebufferCache];
}

+ (void)useImageProcessingContext;
{
    [[RDGPUImageContext sharedImageProcessingContext] useAsCurrentContext];
}

- (void)useAsCurrentContext;
{
    EAGLContext *imageProcessingContext = [self context];
    if ([EAGLContext currentContext] != imageProcessingContext)
    {
        [EAGLContext setCurrentContext:imageProcessingContext];
    }
}

+ (void)setActiveShaderProgram:(RDGLProgram *)shaderProgram;
{
    RDGPUImageContext *sharedContext = [RDGPUImageContext sharedImageProcessingContext];
    [sharedContext setContextShaderProgram:shaderProgram];
}

- (void)setContextShaderProgram:(RDGLProgram *)shaderProgram;
{
    EAGLContext *imageProcessingContext = [self context];
    if ([EAGLContext currentContext] != imageProcessingContext)
    {
        [EAGLContext setCurrentContext:imageProcessingContext];
    }
    
    if (self.currentShaderProgram != shaderProgram)
    {
        self.currentShaderProgram = shaderProgram;
        [shaderProgram use];
    }
}

+ (GLint)maximumTextureSizeForThisDevice;
{
    static dispatch_once_t pred;
    static GLint maxTextureSize = 0;
    
    dispatch_once(&pred, ^{
        [self useImageProcessingContext];
        glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
    });

    return maxTextureSize;
}

+ (GLint)maximumTextureUnitsForThisDevice;
{
    static dispatch_once_t pred;
    static GLint maxTextureUnits = 0;

    dispatch_once(&pred, ^{
        [self useImageProcessingContext];
        glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &maxTextureUnits);
    });
    
    return maxTextureUnits;
}

+ (GLint)maximumVaryingVectorsForThisDevice;
{
    static dispatch_once_t pred;
    static GLint maxVaryingVectors = 0;

    dispatch_once(&pred, ^{
        [self useImageProcessingContext];
        glGetIntegerv(GL_MAX_VARYING_VECTORS, &maxVaryingVectors);
    });

    return maxVaryingVectors;
}

+ (BOOL)deviceSupportsOpenGLESExtension:(NSString *)extension;
{
    static dispatch_once_t pred;
    static NSArray *extensionNames = nil;

    // Cache extensions for later quick reference, since this won't change for a given device
    dispatch_once(&pred, ^{
        [RDGPUImageContext useImageProcessingContext];
        NSString *extensionsString = [NSString stringWithCString:(const char *)glGetString(GL_EXTENSIONS) encoding:NSASCIIStringEncoding];
        extensionNames = [extensionsString componentsSeparatedByString:@" "];
    });

    return [extensionNames containsObject:extension];
}


// http://www.khronos.org/registry/gles/extensions/EXT/EXT_texture_rg.txt

+ (BOOL)deviceSupportsRedTextures;
{
    static dispatch_once_t pred;
    static BOOL supportsRedTextures = NO;
    
    dispatch_once(&pred, ^{
        supportsRedTextures = [RDGPUImageContext deviceSupportsOpenGLESExtension:@"GL_EXT_texture_rg"];
    });
    
    return supportsRedTextures;
}

+ (BOOL)deviceSupportsFramebufferReads;
{
    static dispatch_once_t pred;
    static BOOL supportsFramebufferReads = NO;
    
    dispatch_once(&pred, ^{
        supportsFramebufferReads = [RDGPUImageContext deviceSupportsOpenGLESExtension:@"GL_EXT_shader_framebuffer_fetch"];
    });
    
    return supportsFramebufferReads;
}

+ (CGSize)sizeThatFitsWithinATextureForSize:(CGSize)inputSize;
{
    GLint maxTextureSize = [self maximumTextureSizeForThisDevice]; 
    if ( (inputSize.width < maxTextureSize) && (inputSize.height < maxTextureSize) )
    {
        return inputSize;
    }
    
    CGSize adjustedSize;
    if (inputSize.width > inputSize.height)
    {
        adjustedSize.width = (CGFloat)maxTextureSize;
        adjustedSize.height = ((CGFloat)maxTextureSize / inputSize.width) * inputSize.height;
    }
    else
    {
        adjustedSize.height = (CGFloat)maxTextureSize;
        adjustedSize.width = ((CGFloat)maxTextureSize / inputSize.height) * inputSize.width;
    }

    return adjustedSize;
}

- (void)presentBufferForDisplay;
{
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (RDGLProgram *)programForVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString;
{
    NSString *lookupKeyForShaderProgram = [NSString stringWithFormat:@"V: %@ - F: %@", vertexShaderString, fragmentShaderString];
    RDGLProgram *programFromCache = [shaderProgramCache objectForKey:lookupKeyForShaderProgram];

    if (programFromCache == nil)
    {
        programFromCache = [[RDGLProgram alloc] initWithVertexShaderString:vertexShaderString fragmentShaderString:fragmentShaderString];
        [shaderProgramCache setObject:programFromCache forKey:lookupKeyForShaderProgram];
    }
    
    return programFromCache;
}

- (void)useSharegroup:(EAGLSharegroup *)sharegroup;
{
    NSAssert(_context == nil, @"Unable to use a share group when the context has already been created. Call this method before you use the context for the first time.");
    
    _sharegroup = sharegroup;
}

- (EAGLContext *)createContext;
{
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:_sharegroup];
    NSAssert(context != nil, @"Unable to create an OpenGL ES 2.0 context. The RDGPUImage framework requires OpenGL ES 2.0 support to work.");
    return context;
}


#pragma mark -
#pragma mark Manage fast texture upload

+ (BOOL)supportsFastTextureUpload;
{
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-pointer-compare"
    return (CVOpenGLESTextureCacheCreate != NULL);
#pragma clang diagnostic pop

#endif
}

#pragma mark -
#pragma mark Accessors

- (EAGLContext *)context;
{
    if (_context == nil)
    {
        _context = [self createContext];
        [EAGLContext setCurrentContext:_context];
        
        // Set up a few global settings for the image processing pipeline
        glDisable(GL_DEPTH_TEST);
    }
    
    return _context;
}

- (CVOpenGLESTextureCacheRef)coreVideoTextureCache;
{
    if (_coreVideoTextureCache == NULL)
    {
#if defined(__IPHONE_6_0)
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [self context], NULL, &_coreVideoTextureCache);
#else
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)[self context], NULL, &_coreVideoTextureCache);
#endif
        
        if (err)
        {
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", err);
        }

    }
    
    return _coreVideoTextureCache;
}

- (RDGPUImageFramebufferCache *)framebufferCache;
{
    if (_framebufferCache == nil)
    {
        _framebufferCache = [[RDGPUImageFramebufferCache alloc] init];
    }
    
    return _framebufferCache;
}

- (void)dealloc {
    NSLog(@"%s", __func__);
    if (_coreVideoTextureCache != NULL) {
        CFRelease(_coreVideoTextureCache);
    }
#if !OS_OBJECT_USE_OBJC
    if (_contextQueue != NULL)
    {
        dispatch_release(_contextQueue);
    }
#endif
}

@end
