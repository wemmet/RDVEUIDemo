#import "RDGPUImageExposureFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kRDGPUImageExposureFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform highp float exposure;
 
 void main()
 {
     highp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = vec4(textureColor.rgb * pow(2.0, exposure), textureColor.w);
 }
);
#else
NSString *const kRDGPUImageExposureFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform float exposure;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = vec4(textureColor.rgb * pow(2.0, exposure), textureColor.w);
 }
);
#endif

@implementation RDGPUImageExposureFilter

@synthesize exposure = _exposure;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kRDGPUImageExposureFragmentShaderString]))
    {
		return nil;
    }
    
    exposureUniform = [filterProgram uniformIndex:@"exposure"];
    self.exposure = 0.0;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setExposure:(CGFloat)newValue;
{
    _exposure = newValue;
    
    [self setFloat:_exposure forUniform:exposureUniform program:filterProgram];
}

@end

