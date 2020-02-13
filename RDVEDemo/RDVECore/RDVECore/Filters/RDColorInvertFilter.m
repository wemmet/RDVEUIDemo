#import "RDColorInvertFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kRDInvertFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    gl_FragColor = vec4((1.0 - textureColor.rgb), textureColor.w);
 }
);                                                                    
#else
NSString *const kRDInvertFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = vec4((1.0 - textureColor.rgb), textureColor.w);
 }
 );
#endif

@implementation RDColorInvertFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kRDInvertFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end

