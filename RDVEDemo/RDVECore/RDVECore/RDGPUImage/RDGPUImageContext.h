#import "RDGLProgram.h"
#import "RDGPUImageFramebuffer.h"
#import "RDGPUImageFramebufferCache.h"

#define RDGPUImageRotationSwapsWidthAndHeight(rotation) ((rotation) == kRDGPUImageRotateLeft || (rotation) == kRDGPUImageRotateRight || (rotation) == kRDGPUImageRotateRightFlipVertical || (rotation) == kRDGPUImageRotateRightFlipHorizontal)


typedef NS_ENUM(NSUInteger, RDGPUImageRotationMode) {
	kRDGPUImageNoRotation,
	kRDGPUImageRotateLeft,
	kRDGPUImageRotateRight,
	kRDGPUImageFlipVertical,
	kRDGPUImageFlipHorizonal,
	kRDGPUImageRotateRightFlipVertical,
	kRDGPUImageRotateRightFlipHorizontal,
	kRDGPUImageRotate180
};

@interface RDGPUImageContext : NSObject

@property(readonly, nonatomic) dispatch_queue_t contextQueue;
@property(strong, nonatomic) RDGLProgram *currentShaderProgram;
@property(strong, nonatomic) EAGLContext *context;
@property(readonly) CVOpenGLESTextureCacheRef coreVideoTextureCache;
@property(readonly) RDGPUImageFramebufferCache *framebufferCache;

+ (void *)contextKey;
+ (RDGPUImageContext *)sharedImageProcessingContext;
+ (dispatch_queue_t)sharedContextQueue;
+ (RDGPUImageFramebufferCache *)sharedFramebufferCache;
+ (void)useImageProcessingContext;
- (void)useAsCurrentContext;
+ (void)setActiveShaderProgram:(RDGLProgram *)shaderProgram;
- (void)setContextShaderProgram:(RDGLProgram *)shaderProgram;
+ (GLint)maximumTextureSizeForThisDevice;
+ (GLint)maximumTextureUnitsForThisDevice;
+ (GLint)maximumVaryingVectorsForThisDevice;
+ (BOOL)deviceSupportsOpenGLESExtension:(NSString *)extension;
+ (BOOL)deviceSupportsRedTextures;
+ (BOOL)deviceSupportsFramebufferReads;
+ (CGSize)sizeThatFitsWithinATextureForSize:(CGSize)inputSize;

- (void)presentBufferForDisplay;
- (RDGLProgram *)programForVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString;

- (void)useSharegroup:(EAGLSharegroup *)sharegroup;

// Manage fast texture upload
+ (BOOL)supportsFastTextureUpload;

@end

@protocol RDGPUImageInput <NSObject>
- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
- (void)setInputFramebuffer:(RDGPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
- (NSInteger)nextAvailableTextureIndex;
- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
- (void)setInputRotation:(RDGPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
- (CGSize)maximumOutputSize;
- (void)endProcessing;
- (BOOL)shouldIgnoreUpdatesToThisTarget;
- (BOOL)enabled;
- (BOOL)wantsMonochromeInput;
- (void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue;
@end
