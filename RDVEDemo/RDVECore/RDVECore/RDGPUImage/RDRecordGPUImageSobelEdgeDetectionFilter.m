#import "RDRecordGPUImageSobelEdgeDetectionFilter.h"
#import "RDGPUImageGrayscaleFilter.h"
#import "RDRecordGPUImage3x3ConvolutionFilter.h"

//   Code from "Graphics Shaders: Theory and Practice" by M. Bailey and S. Cunningham 
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kRDRecordGPUImageSobelEdgeDetectionFragmentShaderString = SHADER_STRING
(
 precision mediump float;

 varying vec2 textureCoordinate;
 varying vec2 leftTextureCoordinate;
 varying vec2 rightTextureCoordinate;
 
 varying vec2 topTextureCoordinate;
 varying vec2 topLeftTextureCoordinate;
 varying vec2 topRightTextureCoordinate;
 
 varying vec2 bottomTextureCoordinate;
 varying vec2 bottomLeftTextureCoordinate;
 varying vec2 bottomRightTextureCoordinate;

 uniform sampler2D inputImageTexture;
 uniform float edgeStrength;
 
 void main()
 {
    float bottomLeftIntensity = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
    float topRightIntensity = texture2D(inputImageTexture, topRightTextureCoordinate).r;
    float topLeftIntensity = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
    float bottomRightIntensity = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
    float leftIntensity = texture2D(inputImageTexture, leftTextureCoordinate).r;
    float rightIntensity = texture2D(inputImageTexture, rightTextureCoordinate).r;
    float bottomIntensity = texture2D(inputImageTexture, bottomTextureCoordinate).r;
    float topIntensity = texture2D(inputImageTexture, topTextureCoordinate).r;
    float h = -topLeftIntensity - 2.0 * topIntensity - topRightIntensity + bottomLeftIntensity + 2.0 * bottomIntensity + bottomRightIntensity;
    float v = -bottomLeftIntensity - 2.0 * leftIntensity - topLeftIntensity + bottomRightIntensity + 2.0 * rightIntensity + topRightIntensity;
    
    float mag = length(vec2(h, v)) * edgeStrength;
    
    gl_FragColor = vec4(vec3(mag), 1.0);
 }
);
#else
NSString *const kRDRecordGPUImageSobelEdgeDetectionFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying vec2 leftTextureCoordinate;
 varying vec2 rightTextureCoordinate;
 
 varying vec2 topTextureCoordinate;
 varying vec2 topLeftTextureCoordinate;
 varying vec2 topRightTextureCoordinate;
 
 varying vec2 bottomTextureCoordinate;
 varying vec2 bottomLeftTextureCoordinate;
 varying vec2 bottomRightTextureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform float edgeStrength;

 void main()
 {
     float bottomLeftIntensity = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
     float topRightIntensity = texture2D(inputImageTexture, topRightTextureCoordinate).r;
     float topLeftIntensity = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
     float bottomRightIntensity = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
     float leftIntensity = texture2D(inputImageTexture, leftTextureCoordinate).r;
     float rightIntensity = texture2D(inputImageTexture, rightTextureCoordinate).r;
     float bottomIntensity = texture2D(inputImageTexture, bottomTextureCoordinate).r;
     float topIntensity = texture2D(inputImageTexture, topTextureCoordinate).r;
     float h = -topLeftIntensity - 2.0 * topIntensity - topRightIntensity + bottomLeftIntensity + 2.0 * bottomIntensity + bottomRightIntensity;
     float v = -bottomLeftIntensity - 2.0 * leftIntensity - topLeftIntensity + bottomRightIntensity + 2.0 * rightIntensity + topRightIntensity;
     
     float mag = length(vec2(h, v)) * edgeStrength;
     
     gl_FragColor = vec4(vec3(mag), 1.0);
 }
);
#endif

@implementation RDRecordGPUImageSobelEdgeDetectionFilter

@synthesize texelWidth = _texelWidth; 
@synthesize texelHeight = _texelHeight; 
@synthesize edgeStrength = _edgeStrength;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [self initWithFragmentShaderFromString:kRDRecordGPUImageSobelEdgeDetectionFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

- (id)initWithFragmentShaderFromString:(NSString *)fragmentShaderString;
{
    // Do a luminance pass first to reduce the calculations performed at each fragment in the edge detection phase

    if (!(self = [super initWithFirstStageVertexShaderFromString:kRDGPUImageVertexShaderString firstStageFragmentShaderFromString:kRDGPUImageLuminanceFragmentShaderString secondStageVertexShaderFromString:kRDRecordGPUImageNearbyTexelSamplingVertexShaderString secondStageFragmentShaderFromString:fragmentShaderString]))
    {
		return nil;
    }
    
    hasOverriddenImageSizeFactor = NO;
    
    texelWidthUniform = [secondFilterProgram uniformIndex:@"texelWidth"];
    texelHeightUniform = [secondFilterProgram uniformIndex:@"texelHeight"];
    edgeStrengthUniform = [secondFilterProgram uniformIndex:@"edgeStrength"];
    
    self.edgeStrength = 1.0;
    return self;
}

- (void)setupFilterForSize:(CGSize)filterFrameSize;
{
    if (!hasOverriddenImageSizeFactor)
    {
        _texelWidth = 1.0 / filterFrameSize.width;
        _texelHeight = 1.0 / filterFrameSize.height;
        
        rdRunSynchronouslyOnVideoProcessingQueue(^{
            RDGLProgram *previousProgram = [RDGPUImageContext sharedImageProcessingContext].currentShaderProgram;
            [RDGPUImageContext setActiveShaderProgram:secondFilterProgram];
            glUniform1f(texelWidthUniform, _texelWidth);
            glUniform1f(texelHeightUniform, _texelHeight);
            [RDGPUImageContext setActiveShaderProgram:previousProgram];
        });
    }
}

- (void)setUniformsForProgramAtIndex:(NSUInteger)programIndex;
{
    [super setUniformsForProgramAtIndex:programIndex];
    
    if (programIndex == 1)
    {
        glUniform1f(texelWidthUniform, _texelWidth);
        glUniform1f(texelHeightUniform, _texelHeight);
    }
}

- (BOOL)wantsMonochromeInput;
{
//    return YES;
    return NO;
}

- (BOOL)providesMonochromeOutput;
{
//    return YES;
    return NO;
}

#pragma mark -
#pragma mark Accessors

- (void)setTexelWidth:(CGFloat)newValue;
{
    hasOverriddenImageSizeFactor = YES;
    _texelWidth = newValue;
    
    [self setFloat:_texelWidth forUniform:texelWidthUniform program:secondFilterProgram];
}

- (void)setTexelHeight:(CGFloat)newValue;
{
    hasOverriddenImageSizeFactor = YES;
    _texelHeight = newValue;

    [self setFloat:_texelHeight forUniform:texelHeightUniform program:secondFilterProgram];
}

- (void)setEdgeStrength:(CGFloat)newValue;
{
    _edgeStrength = newValue;
    
    [self setFloat:_edgeStrength forUniform:edgeStrengthUniform program:secondFilterProgram];
}


@end

