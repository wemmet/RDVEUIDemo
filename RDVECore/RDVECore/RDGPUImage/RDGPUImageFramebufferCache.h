#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "RDGPUImageFramebuffer.h"

@interface RDGPUImageFramebufferCache : NSObject

// Framebuffer management
- (RDGPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize textureOptions:(GPUTextureOptions)textureOptions onlyTexture:(BOOL)onlyTexture;
- (RDGPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize onlyTexture:(BOOL)onlyTexture;
- (void)returnFramebufferToCache:(RDGPUImageFramebuffer *)framebuffer;
- (void)purgeAllUnassignedFramebuffers;
- (void)addFramebufferToActiveImageCaptureList:(RDGPUImageFramebuffer *)framebuffer;
- (void)removeFramebufferFromActiveImageCaptureList:(RDGPUImageFramebuffer *)framebuffer;

@end
