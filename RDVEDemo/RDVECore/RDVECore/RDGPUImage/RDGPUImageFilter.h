#import "RDGPUImageOutput.h"

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

#define RDGPUImageHashIdentifier #
#define RDGPUImageWrappedLabel(x) x
#define RDGPUImageEscapedHashIdentifier(a) RDGPUImageWrappedLabel(RDGPUImageHashIdentifier)a

extern NSString *const kRDGPUImageVertexShaderString;
extern NSString *const kRDGPUImagePassthroughFragmentShaderString;

struct RDGPUVectore4 {
    GLfloat one;
    GLfloat two;
    GLfloat three;
    GLfloat four;
};
typedef struct RDGPUVectore4 RDGPUVectore4;

struct RDGPUVectore3 {
    GLfloat one;
    GLfloat two;
    GLfloat three;
};
typedef struct RDGPUVectore3 RDGPUVectore3;

struct RDGPUMatrix4x4 {
    RDGPUVectore4 one;
    RDGPUVectore4 two;
    RDGPUVectore4 three;
    RDGPUVectore4 four;
};
typedef struct RDGPUMatrix4x4 RDGPUMatrix4x4;

struct RDGPUMatrix3x3 {
    RDGPUVectore3 one;
    RDGPUVectore3 two;
    RDGPUVectore3 three;
};
typedef struct RDGPUMatrix3x3 RDGPUMatrix3x3;

/** RDGPUImage's base filter class
 
 Filters and other subsequent elements in the chain conform to the RDGPUImageInput protocol, which lets them take in the supplied or processed texture from the previous link in the chain and do something with it. Objects one step further down the chain are considered targets, and processing can be branched by adding multiple targets to a single output or filter.
 */
@interface RDGPUImageFilter : RDGPUImageOutput <RDGPUImageInput>
{
    RDGPUImageFramebuffer *firstInputFramebuffer;
    
    RDGLProgram *filterProgram;
    GLint filterPositionAttribute, filterTextureCoordinateAttribute, filterTextureMaskCoordinateAttribute;
    GLint filterInputTextureUniform;
    GLfloat backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha;
    
    BOOL isEndProcessing;

    CGSize currentFilterSize;
    RDGPUImageRotationMode inputRotation;
    
    BOOL currentlyReceivingMonochromeInput;
    
    NSMutableDictionary *uniformStateRestorationBlocks;
    dispatch_semaphore_t imageCaptureSemaphore;
    
    void(^frameImageCompletionBlock)(RDGPUImageOutput*, CMTime);
}
@property(readwrite, nonatomic, copy) NSString *name;
@property(readonly) CVPixelBufferRef renderTarget;
@property(assign, nonatomic) BOOL preventRendering;
@property(assign, nonatomic) BOOL currentlyReceivingMonochromeInput;
@property(assign, nonatomic) BOOL hasGetMVEffectImageBlock;

/// @name Initialization and teardown

/**
 Initialize with vertex and fragment shaders
 
 You make take advantage of the SHADER_STRING macro to write your shaders in-line.
 @param vertexShaderString Source code of the vertex shader to use
 @param fragmentShaderString Source code of the fragment shader to use
 */
- (id)initWithVertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString;

/**
 Initialize with a fragment shader
 
 You may take advantage of the SHADER_STRING macro to write your shader in-line.
 @param fragmentShaderString Source code of fragment shader to use
 */
- (id)initWithFragmentShaderFromString:(NSString *)fragmentShaderString;
/**
 Initialize with a fragment shader
 @param fragmentShaderFilename Filename of fragment shader to load
 */
- (id)initWithFragmentShaderFromFile:(NSString *)fragmentShaderFilename;
- (void)initializeAttributes;
- (void)setupFilterForSize:(CGSize)filterFrameSize;
- (CGSize)rotatedSize:(CGSize)sizeToRotate forIndex:(NSInteger)textureIndex;
- (CGPoint)rotatedPoint:(CGPoint)pointToRotate forRotation:(RDGPUImageRotationMode)rotation;

/// @name Managing the display FBOs
/** Size of the frame buffer object
 */
- (CGSize)sizeOfFBO;

/// @name Rendering
+ (const GLfloat *)textureCoordinatesForRotation:(RDGPUImageRotationMode)rotationMode;
- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
- (void)informTargetsAboutNewFrameAtTime:(CMTime)frameTime;
- (CGSize)outputFrameSize;

/// @name Input parameters
- (void)setBackgroundColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent alpha:(GLfloat)alphaComponent;
- (void)setInteger:(GLint)newInteger forUniformName:(NSString *)uniformName;
- (void)setFloat:(GLfloat)newFloat forUniformName:(NSString *)uniformName;
- (void)setSize:(CGSize)newSize forUniformName:(NSString *)uniformName;
- (void)setPoint:(CGPoint)newPoint forUniformName:(NSString *)uniformName;
- (void)setFloatVec3:(RDGPUVectore3)newVec3 forUniformName:(NSString *)uniformName;
- (void)setFloatVec4:(RDGPUVectore4)newVec4 forUniform:(NSString *)uniformName;
- (void)setFloatArray:(GLfloat *)array length:(GLsizei)count forUniform:(NSString*)uniformName;

- (void)setMatrix3f:(RDGPUMatrix3x3)matrix forUniform:(GLint)uniform program:(RDGLProgram *)shaderProgram;
- (void)setMatrix4f:(RDGPUMatrix4x4)matrix forUniform:(GLint)uniform program:(RDGLProgram *)shaderProgram;
- (void)setFloat:(GLfloat)floatValue forUniform:(GLint)uniform program:(RDGLProgram *)shaderProgram;
- (void)setPoint:(CGPoint)pointValue forUniform:(GLint)uniform program:(RDGLProgram *)shaderProgram;
- (void)setSize:(CGSize)sizeValue forUniform:(GLint)uniform program:(RDGLProgram *)shaderProgram;
- (void)setVec3:(RDGPUVectore3)vectorValue forUniform:(GLint)uniform program:(RDGLProgram *)shaderProgram;
- (void)setVec4:(RDGPUVectore4)vectorValue forUniform:(GLint)uniform program:(RDGLProgram *)shaderProgram;
- (void)setFloatArray:(GLfloat *)arrayValue length:(GLsizei)arrayLength forUniform:(GLint)uniform program:(RDGLProgram *)shaderProgram;
- (void)setInteger:(GLint)intValue forUniform:(GLint)uniform program:(RDGLProgram *)shaderProgram;

- (void)setAndExecuteUniformStateCallbackAtIndex:(GLint)uniform forProgram:(RDGLProgram *)shaderProgram toBlock:(dispatch_block_t)uniformStateBlock;
- (void)setUniformsForProgramAtIndex:(NSUInteger)programIndex;

@end
