#import "RDGPUImageGaussianBlurFilter.h"

@interface RDGPUImageBilateralFilter : RDGPUImageGaussianBlurFilter
{
    CGFloat firstDistanceNormalizationFactorUniform;
    CGFloat secondDistanceNormalizationFactorUniform;
}
// A normalization factor for the distance between central color and sample color.
@property(nonatomic, readwrite) CGFloat distanceNormalizationFactor;
@end
