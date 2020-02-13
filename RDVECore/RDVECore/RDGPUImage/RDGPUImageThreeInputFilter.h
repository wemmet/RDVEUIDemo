#import "RDGPUImageTwoInputFilter.h"

extern NSString *const kRDGPUImageThreeInputTextureVertexShaderString;

@interface RDGPUImageThreeInputFilter : RDGPUImageTwoInputFilter
{
    RDGPUImageFramebuffer *thirdInputFramebuffer;

    GLint filterThirdTextureCoordinateAttribute;
    GLint filterInputTextureUniform3;
    RDGPUImageRotationMode inputRotation3;
    GLuint filterSourceTexture3;
    CMTime thirdFrameTime;
    
    BOOL hasSetSecondTexture, hasReceivedThirdFrame, thirdFrameWasVideo;
    BOOL thirdFrameCheckDisabled;
}

- (void)disableThirdFrameCheck;

@end
