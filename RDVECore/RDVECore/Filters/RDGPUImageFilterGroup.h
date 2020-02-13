#import "RDGPUImageOutput.h"
#import "RDGPUImageFilter.h"
#import "RDGPUImageOutput.h"
@interface RDGPUImageFilterGroup : RDGPUImageOutput <RDGPUImageInput>
{
    NSMutableArray *filters;
    BOOL isEndProcessing;
}

@property(readwrite, nonatomic, strong) RDGPUImageOutput<RDGPUImageInput> *terminalFilter;
@property(readwrite, nonatomic, strong) NSArray *initialFilters;
@property(readwrite, nonatomic, strong) RDGPUImageOutput<RDGPUImageInput> *inputFilterToIgnoreForUpdates; 

// Filter management
- (void)addFilter:(RDGPUImageOutput<RDGPUImageInput> *)newFilter;
- (RDGPUImageOutput<RDGPUImageInput> *)filterAtIndex:(NSUInteger)filterIndex;
- (NSUInteger)filterCount;

@end
