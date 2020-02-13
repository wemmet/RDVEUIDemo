#import "RDGPUImageFilterGroup.h"
#import "RDGPUImagePicture.h"

@implementation RDGPUImageFilterGroup

@synthesize terminalFilter = _terminalFilter;
@synthesize initialFilters = _initialFilters;
@synthesize inputFilterToIgnoreForUpdates = _inputFilterToIgnoreForUpdates;

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    filters = [[NSMutableArray alloc] init];
    
    return self;
}

#pragma mark -
#pragma mark Filter management

- (void)addFilter:(RDGPUImageOutput<RDGPUImageInput> *)newFilter;
{
    [filters addObject:newFilter];
}

- (RDGPUImageOutput<RDGPUImageInput> *)filterAtIndex:(NSUInteger)filterIndex;
{
    return [filters objectAtIndex:filterIndex];
}

- (NSUInteger)filterCount;
{
    return [filters count];
}

#pragma mark -
#pragma mark Still image processing

- (void)useNextFrameForImageCapture;
{
    [self.terminalFilter useNextFrameForImageCapture];
}

- (CGImageRef)newCGImageFromCurrentlyProcessedOutput;
{
    return [self.terminalFilter newCGImageFromCurrentlyProcessedOutput];
}

#pragma mark -
#pragma mark RDGPUImageOutput overrides

- (void)setTargetToIgnoreForUpdates:(id<RDGPUImageInput>)targetToIgnoreForUpdates;
{
    [_terminalFilter setTargetToIgnoreForUpdates:targetToIgnoreForUpdates];
}

- (void)addTarget:(id<RDGPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation;
{
    [_terminalFilter addTarget:newTarget atTextureLocation:textureLocation];
}

- (void)removeTarget:(id<RDGPUImageInput>)targetToRemove;
{
    [_terminalFilter removeTarget:targetToRemove];
}

- (void)removeAllTargets;
{
    [_terminalFilter removeAllTargets];
}

- (NSArray *)targets;
{
    return [_terminalFilter targets];
}

- (void)setFrameProcessingCompletionBlock:(void (^)(RDGPUImageOutput *, CMTime))frameProcessingCompletionBlock;
{
    [_terminalFilter setFrameProcessingCompletionBlock:frameProcessingCompletionBlock];
}

- (void (^)(RDGPUImageOutput *, CMTime))frameProcessingCompletionBlock;
{
    return [_terminalFilter frameProcessingCompletionBlock];
}

- (void)setFrameImageProcessingCompletionBlock:(void (^)(RDGPUImageOutput *, CMTime))frameImageProcessingCompletionBlock{
    [_terminalFilter setFrameImageProcessingCompletionBlock:frameImageProcessingCompletionBlock];
}

- (void (^)(RDGPUImageOutput *, CMTime))frameImageProcessingCompletionBlock{
    return [_terminalFilter frameImageProcessingCompletionBlock];
}

#pragma mark -
#pragma mark RDGPUImageInput protocol

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    for (RDGPUImageOutput<RDGPUImageInput> *currentFilter in _initialFilters)
    {
        if (currentFilter != self.inputFilterToIgnoreForUpdates)
        {
            [currentFilter newFrameReadyAtTime:frameTime atIndex:textureIndex];
        }
    }
}

- (void)setInputFramebuffer:(RDGPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
{
    for (RDGPUImageOutput<RDGPUImageInput> *currentFilter in _initialFilters)
    {
        [currentFilter setInputFramebuffer:newInputFramebuffer atIndex:textureIndex];
    }
}

- (NSInteger)nextAvailableTextureIndex;
{
//    if ([_initialFilters count] > 0)
//    {
//        return [[_initialFilters objectAtIndex:0] nextAvailableTextureIndex];
//    }
    
    return 0;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    for (RDGPUImageOutput<RDGPUImageInput> *currentFilter in _initialFilters)
    {
        [currentFilter setInputSize:newSize atIndex:textureIndex];
    }
}

- (void)setInputRotation:(RDGPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
    for (RDGPUImageOutput<RDGPUImageInput> *currentFilter in _initialFilters)
    {
        [currentFilter setInputRotation:newInputRotation  atIndex:(NSInteger)textureIndex];
    }
}

- (void)forceProcessingAtSize:(CGSize)frameSize;
{
    for (RDGPUImageOutput<RDGPUImageInput> *currentFilter in filters)
    {
        [currentFilter forceProcessingAtSize:frameSize];
    }
}

- (void)forceProcessingAtSizeRespectingAspectRatio:(CGSize)frameSize;
{
    for (RDGPUImageOutput<RDGPUImageInput> *currentFilter in filters)
    {
        [currentFilter forceProcessingAtSizeRespectingAspectRatio:frameSize];
    }
}

- (CGSize)maximumOutputSize;
{
    // I'm temporarily disabling adjustments for smaller output sizes until I figure out how to make this work better
    return CGSizeZero;

    /*
    if (CGSizeEqualToSize(cachedMaximumOutputSize, CGSizeZero))
    {
        for (id<RDGPUImageInput> currentTarget in _initialFilters)
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

- (void)endProcessing;
{
    if (!isEndProcessing)
    {
        isEndProcessing = YES;
        
        for (id<RDGPUImageInput> currentTarget in _initialFilters)
        {
            [currentTarget endProcessing];
        }
    }
}

- (BOOL)wantsMonochromeInput;
{
    BOOL allInputsWantMonochromeInput = YES;
    for (RDGPUImageOutput<RDGPUImageInput> *currentFilter in _initialFilters)
    {
        allInputsWantMonochromeInput = allInputsWantMonochromeInput && [currentFilter wantsMonochromeInput];
    }
    
    return allInputsWantMonochromeInput;
}

- (void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue;
{
    for (RDGPUImageOutput<RDGPUImageInput> *currentFilter in _initialFilters)
    {
        [currentFilter setCurrentlyReceivingMonochromeInput:newValue];
    }
}

@end
