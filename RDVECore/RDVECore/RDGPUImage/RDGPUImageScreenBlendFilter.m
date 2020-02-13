#import "RDGPUImageScreenBlendFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kRDGPUImageScreenBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;

 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     mediump vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     mediump vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
     mediump vec4 whiteColor = vec4(1.0);
     gl_FragColor = whiteColor - ((whiteColor - textureColor2) * (whiteColor - textureColor));
 }
);
#else
NSString *const kRDGPUImageScreenBlendFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
     vec4 whiteColor = vec4(1.0);
     gl_FragColor = whiteColor - ((whiteColor - textureColor2) * (whiteColor - textureColor));
 }
);
#endif

@implementation RDGPUImageScreenBlendFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kRDGPUImageScreenBlendFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end

