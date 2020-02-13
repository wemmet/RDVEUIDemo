#import <Foundation/Foundation.h>
#import "RDGPUImageOutput.h"

@interface RDGPUImageFilterPipeline : NSObject
{
    NSString *stringValue;
}

@property (strong) NSMutableArray *filters;

@property (strong) RDGPUImageOutput *input;
@property (strong) id <RDGPUImageInput> output;

- (id) initWithOrderedFilters:(NSArray*) filters input:(RDGPUImageOutput*)input output:(id <RDGPUImageInput>)output;
- (id) initWithConfiguration:(NSDictionary*) configuration input:(RDGPUImageOutput*)input output:(id <RDGPUImageInput>)output;
- (id) initWithConfigurationFile:(NSURL*) configuration input:(RDGPUImageOutput*)input output:(id <RDGPUImageInput>)output;

- (void) addFilter:(RDGPUImageOutput<RDGPUImageInput> *)filter;
- (void) addFilter:(RDGPUImageOutput<RDGPUImageInput> *)filter atIndex:(NSUInteger)insertIndex;
- (void) replaceFilterAtIndex:(NSUInteger)index withFilter:(RDGPUImageOutput<RDGPUImageInput> *)filter;
- (void) replaceAllFilters:(NSArray *) newFilters;
- (void) removeFilter:(RDGPUImageOutput<RDGPUImageInput> *)filter;
- (void) removeFilterAtIndex:(NSUInteger)index;
- (void) removeAllFilters;

- (UIImage *) currentFilteredFrame;
- (UIImage *) currentFilteredFrameWithOrientation:(UIImageOrientation)imageOrientation;
- (CGImageRef) newCGImageFromCurrentFilteredFrame;

@end
