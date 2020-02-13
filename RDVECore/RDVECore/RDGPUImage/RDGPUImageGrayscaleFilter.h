#import "RDGPUImageFilter.h"

extern NSString *const kRDGPUImageLuminanceFragmentShaderString;

/** Converts an image to grayscale (a slightly faster implementation of the saturation filter, without the ability to vary the color contribution)
 */
@interface RDGPUImageGrayscaleFilter : RDGPUImageFilter

@end
