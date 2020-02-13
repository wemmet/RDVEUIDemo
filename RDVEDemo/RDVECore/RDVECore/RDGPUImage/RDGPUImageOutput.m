#import "RDGPUImageOutput.h"
#import "RDGPUImageMovieWriter.h"
#import "RDGPUImagePicture.h"
#import <mach/mach.h>


@implementation RDGPUImageOutput

@synthesize shouldSmoothlyScaleOutput = _shouldSmoothlyScaleOutput;
@synthesize shouldIgnoreUpdatesToThisTarget = _shouldIgnoreUpdatesToThisTarget;
@synthesize audioEncodingTarget = _audioEncodingTarget;
@synthesize targetToIgnoreForUpdates = _targetToIgnoreForUpdates;
@synthesize frameProcessingCompletionBlock = _frameProcessingCompletionBlock;
//@synthesize frameImageProcessingCompletionBlock = _frameImageProcessingCompletionBlock;
@synthesize enabled = _enabled;
@synthesize outputTextureOptions = _outputTextureOptions;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init; 
{
	if (!(self = [super init]))
    {
		return nil;
    }

    targets = [[NSMutableArray alloc] init];
    targetTextureIndices = [[NSMutableArray alloc] init];
    _enabled = YES;
    allTargetsWantMonochromeData = YES;
    usingNextFrameForImageCapture = NO;
    
    // set default texture options
    _outputTextureOptions.minFilter = GL_LINEAR;
    _outputTextureOptions.magFilter = GL_LINEAR;
    _outputTextureOptions.wrapS = GL_CLAMP_TO_EDGE;
    _outputTextureOptions.wrapT = GL_CLAMP_TO_EDGE;
    _outputTextureOptions.internalFormat = GL_RGBA;
    _outputTextureOptions.format = GL_BGRA;
    _outputTextureOptions.type = GL_UNSIGNED_BYTE;

    return self;
}

//- (void)dealloc 
//{
//   [self removeAllTargets];
//}

#pragma mark -
#pragma mark Managing targets
- (void)setInputFramebufferForTarget:(id<RDGPUImageInput>)target atIndex:(NSInteger)inputTextureIndex;
{
    [target setInputFramebuffer:[self framebufferForOutput] atIndex:inputTextureIndex];
}

- (RDGPUImageFramebuffer *)framebufferForOutput;
{
//    if(outputFramebuffer == nil){
//        NSLog(@"outputFramebuffer is null");
//    }else{
//        NSLog(@"outputFramebuffer");
//    }
    return outputFramebuffer;
}

- (void)removeOutputFramebuffer;
{
    outputFramebuffer = nil;
}

- (void)notifyTargetsAboutNewOutputTexture;
{
    for (id<RDGPUImageInput> currentTarget in targets)
    {
        NSInteger indexOfObject = [targets indexOfObject:currentTarget];
        NSInteger textureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
        
        [self setInputFramebufferForTarget:currentTarget atIndex:textureIndex];
    }
}

- (NSArray*)targets;
{
	return [NSArray arrayWithArray:targets];
}

- (void)addTarget:(id<RDGPUImageInput>)newTarget;
{
    NSInteger nextAvailableTextureIndex = [newTarget nextAvailableTextureIndex];
    [self addTarget:newTarget atTextureLocation:nextAvailableTextureIndex];
    
    if ([newTarget shouldIgnoreUpdatesToThisTarget])
    {
        _targetToIgnoreForUpdates = newTarget;
    }
}

- (void)addTarget:(id<RDGPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation;
{
    if([targets containsObject:newTarget])
    {
        return;
    }
    
    cachedMaximumOutputSize = CGSizeZero;
    rdRunSynchronouslyOnVideoProcessingQueue(^{
        [self setInputFramebufferForTarget:newTarget atIndex:textureLocation];
        [targets addObject:newTarget];
        [targetTextureIndices addObject:[NSNumber numberWithInteger:textureLocation]];
        
        allTargetsWantMonochromeData = allTargetsWantMonochromeData && [newTarget wantsMonochromeInput];
    });
}

- (void)removeTarget:(id<RDGPUImageInput>)targetToRemove;
{
    if(![targets containsObject:targetToRemove])
    {
        return;
    }
    
    if (_targetToIgnoreForUpdates == targetToRemove)
    {
        _targetToIgnoreForUpdates = nil;
    }
    
    cachedMaximumOutputSize = CGSizeZero;
    
    NSInteger indexOfObject = [targets indexOfObject:targetToRemove];
    NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];

    rdRunSynchronouslyOnVideoProcessingQueue(^{
        [targetToRemove setInputSize:CGSizeZero atIndex:textureIndexOfTarget];
		[targetToRemove setInputRotation:kRDGPUImageNoRotation atIndex:textureIndexOfTarget];

        [targetTextureIndices removeObjectAtIndex:indexOfObject];
        [targets removeObject:targetToRemove];
        [targetToRemove endProcessing];
    });
}

- (void)removeAllTargets;
{
    cachedMaximumOutputSize = CGSizeZero;
    rdRunSynchronouslyOnVideoProcessingQueue(^{
        for (id<RDGPUImageInput> targetToRemove in targets)
        {
            NSInteger indexOfObject = [targets indexOfObject:targetToRemove];
            NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            
            [targetToRemove setInputSize:CGSizeZero atIndex:textureIndexOfTarget];
            [targetToRemove setInputRotation:kRDGPUImageNoRotation atIndex:textureIndexOfTarget];
        }
        [targets removeAllObjects];
        [targetTextureIndices removeAllObjects];
        
        allTargetsWantMonochromeData = YES;
    });
}

#pragma mark -
#pragma mark Manage the output texture

- (void)forceProcessingAtSize:(CGSize)frameSize;
{
    
}

- (void)forceProcessingAtSizeRespectingAspectRatio:(CGSize)frameSize;
{
}

#pragma mark -
#pragma mark Still image processing

- (void)useNextFrameForImageCapture;
{

}

- (CGImageRef)newCGImageFromCurrentlyProcessedOutput;
{
    return nil;
}

- (CGImageRef)newCGImageByFilteringCGImage:(CGImageRef)imageToFilter;
{
    RDGPUImagePicture *stillImageSource = [[RDGPUImagePicture alloc] initWithCGImage:imageToFilter];
    
    [self useNextFrameForImageCapture];
    [stillImageSource addTarget:(id<RDGPUImageInput>)self];
    [stillImageSource processImage];
    
    CGImageRef processedImage = [self newCGImageFromCurrentlyProcessedOutput];
    
    [stillImageSource removeTarget:(id<RDGPUImageInput>)self];
    return processedImage;
}

- (BOOL)providesMonochromeOutput;
{
    return NO;
}

#pragma mark -
#pragma mark Platform-specific image output methods

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE

- (UIImage *)imageFromCurrentFramebuffer;
{
	UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    UIImageOrientation imageOrientation = UIImageOrientationLeft;
	switch (deviceOrientation)
    {
		case UIDeviceOrientationPortrait:
			imageOrientation = UIImageOrientationUp;
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			imageOrientation = UIImageOrientationDown;
			break;
		case UIDeviceOrientationLandscapeLeft:
			imageOrientation = UIImageOrientationLeft;
			break;
		case UIDeviceOrientationLandscapeRight:
			imageOrientation = UIImageOrientationRight;
			break;
		default:
			imageOrientation = UIImageOrientationUp;
			break;
	}
    
    return [self imageFromCurrentFramebufferWithOrientation:imageOrientation];
}

- (UIImage *)imageFromCurrentFramebufferWithOrientation:(UIImageOrientation)imageOrientation;
{
    CGImageRef cgImageFromBytes = [self newCGImageFromCurrentlyProcessedOutput];
    UIImage *finalImage = [UIImage imageWithCGImage:cgImageFromBytes scale:1.0 orientation:imageOrientation];
    CGImageRelease(cgImageFromBytes);
    
    return finalImage;
}

- (UIImage *)imageByFilteringImage:(UIImage *)imageToFilter;
{
    CGImageRef image = [self newCGImageByFilteringCGImage:[imageToFilter CGImage]];
    UIImage *processedImage = [UIImage imageWithCGImage:image scale:[imageToFilter scale] orientation:[imageToFilter imageOrientation]];
    CGImageRelease(image);
    return processedImage;
}

- (CGImageRef)newCGImageByFilteringImage:(UIImage *)imageToFilter
{
    return [self newCGImageByFilteringCGImage:[imageToFilter CGImage]];
}

#else

- (NSImage *)imageFromCurrentFramebuffer;
{
    return [self imageFromCurrentFramebufferWithOrientation:UIImageOrientationLeft];
}

- (NSImage *)imageFromCurrentFramebufferWithOrientation:(UIImageOrientation)imageOrientation;
{
    CGImageRef cgImageFromBytes = [self newCGImageFromCurrentlyProcessedOutput];
    NSImage *finalImage = [[NSImage alloc] initWithCGImage:cgImageFromBytes size:NSZeroSize];
    CGImageRelease(cgImageFromBytes);
    
    return finalImage;
}

- (NSImage *)imageByFilteringImage:(NSImage *)imageToFilter;
{
    CGImageRef image = [self newCGImageByFilteringCGImage:[imageToFilter CGImageForProposedRect:NULL context:[NSGraphicsContext currentContext] hints:nil]];
    NSImage *processedImage = [[NSImage alloc] initWithCGImage:image size:NSZeroSize];
    CGImageRelease(image);
    return processedImage;
}

- (CGImageRef)newCGImageByFilteringImage:(NSImage *)imageToFilter
{
    return [self newCGImageByFilteringCGImage:[imageToFilter CGImageForProposedRect:NULL context:[NSGraphicsContext currentContext] hints:nil]];
}

#endif

#pragma mark -
#pragma mark Accessors

- (void)setAudioEncodingTarget:(RDGPUImageMovieWriter *)newValue;
{    
    _audioEncodingTarget = newValue;
    if( ! _audioEncodingTarget.hasAudioTrack )
    {
        _audioEncodingTarget.hasAudioTrack = YES;
    }
}

-(void)setOutputTextureOptions:(GPUTextureOptions)outputTextureOptions
{
    _outputTextureOptions = outputTextureOptions;
    
    if( outputFramebuffer.texture )
    {
        glBindTexture(GL_TEXTURE_2D,  outputFramebuffer.texture);
        //_outputTextureOptions.format
        //_outputTextureOptions.internalFormat
        //_outputTextureOptions.magFilter
        //_outputTextureOptions.minFilter
        //_outputTextureOptions.type
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _outputTextureOptions.wrapS);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _outputTextureOptions.wrapT);
        glBindTexture(GL_TEXTURE_2D, 0);
    }
}

@end
