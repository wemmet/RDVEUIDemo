//
//  RDRecordBeautyLowFilter.m
//  RDVECore
//
//  Created by 周晓林 on 16/4/19.
//  Copyright © 2016年 周晓林. All rights reserved.
//

#import "RDRecordBeautyLowFilter.h"

NSString *const kRDGPUImageBeautyLowVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 const int GAUSSIAN_SAMPLES = 7;
 
 uniform float texelWidthOffset;
 uniform float texelHeightOffset;
 
 varying vec2 textureCoordinate;
 varying vec2 blurCoordinates[GAUSSIAN_SAMPLES];
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
     
     // Calculate the positions for the blur
     int multiplier = 0;
     vec2 blurStep;
     vec2 singleStepOffset = vec2(texelWidthOffset, texelHeightOffset);
     
     for (int i = 0; i < GAUSSIAN_SAMPLES; i++)
     {
         multiplier = (i - ((GAUSSIAN_SAMPLES - 1) / 2));
         // Blur in x (horizontal)
         blurStep = float(multiplier) * singleStepOffset;
         blurCoordinates[i] = inputTextureCoordinate.xy + blurStep;
     }
 }
 );

NSString *const kRDGPUImageBeautyLowFragmentShaderString = SHADER_STRING
(
 precision lowp float;
 
 uniform sampler2D inputImageTexture;
 
 const  int GAUSSIAN_SAMPLES = 7;
 
 varying  vec2 textureCoordinate;
 varying  vec2 blurCoordinates[GAUSSIAN_SAMPLES];
 
 uniform  float distanceNormalizationFactor;
 uniform  vec4 params;
 const  vec3 W = vec3(0.299,0.587,0.114);
 const  mat3 saturateMatrix = mat3(
                                   1.1102,-0.0598,-0.061,
                                   -0.0774,1.0826,-0.1186,
                                   -0.0228,-0.0228,1.1772);
 
 void main()
 {
     vec4 centralColor;
     float gaussianWeightTotal;
     vec4 sum;
     vec4 sampleColor;
     float distanceFromCentralColor;
     float gaussianWeight;
     centralColor = texture2D(inputImageTexture, blurCoordinates[3]);
     gaussianWeightTotal = 1.0;
     sum = centralColor * 1.0;
     
     sampleColor = texture2D(inputImageTexture, blurCoordinates[0]);
     distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
     gaussianWeight = 1.0 * (1.0 - distanceFromCentralColor);
     gaussianWeightTotal += gaussianWeight;
     sum += sampleColor * gaussianWeight;
     
     sampleColor = texture2D(inputImageTexture, blurCoordinates[1]);
     distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
     gaussianWeight = 1.0 * (1.0 - distanceFromCentralColor);
     gaussianWeightTotal += gaussianWeight;
     sum += sampleColor * gaussianWeight;
     sampleColor = texture2D(inputImageTexture, blurCoordinates[2]);
     distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
     gaussianWeight = 1.0 * (1.0 - distanceFromCentralColor);
     gaussianWeightTotal += gaussianWeight;
     sum += sampleColor * gaussianWeight;
     
     sampleColor = texture2D(inputImageTexture, blurCoordinates[4]);
     distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
     gaussianWeight = 1.0 * (1.0 - distanceFromCentralColor);
     gaussianWeightTotal += gaussianWeight;
     sum += sampleColor * gaussianWeight;

     sampleColor = texture2D(inputImageTexture, blurCoordinates[5]);
     distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
     gaussianWeight = 1.0 * (1.0 - distanceFromCentralColor);
     gaussianWeightTotal += gaussianWeight;
     sum += sampleColor * gaussianWeight;
     
     sampleColor = texture2D(inputImageTexture, blurCoordinates[6]);
     distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
     gaussianWeight = 1.0 * (1.0 - distanceFromCentralColor);
     gaussianWeightTotal += gaussianWeight;
     sum += sampleColor * gaussianWeight;

     
     sampleColor = sum / gaussianWeightTotal;
     
     sampleColor = vec4(centralColor.r,sampleColor.g,centralColor.b,sampleColor.a);
     

     vec3 satcolor = sampleColor.rgb ;
     gl_FragColor.rgb = mix(sampleColor.rgb, satcolor, params.a);
 }
 );


@implementation RDRecordBeautyLowFilter

- (id)init;
{
    
    if (!(self = [super initWithFirstStageVertexShaderFromString:kRDGPUImageBeautyLowVertexShaderString
                              firstStageFragmentShaderFromString:kRDGPUImageBeautyLowFragmentShaderString
                               secondStageVertexShaderFromString:kRDGPUImageBeautyLowVertexShaderString
                             secondStageFragmentShaderFromString:kRDGPUImageBeautyLowFragmentShaderString])) {
        return nil;
    }
    
    firstDistanceNormalizationFactorUniform  = [filterProgram uniformIndex:@"distanceNormalizationFactor"];
    secondDistanceNormalizationFactorUniform = [filterProgram uniformIndex:@"distanceNormalizationFactor"];
    paramsUniform = [filterProgram uniformIndex:@"params"];
    
    self.texelSpacingMultiplier = 3.0;
    self.constValue = 8.0;
    
    [self setBeautyLevel:3];
    
    
    return self;
}
- (void)setTexelSpacingMultiplier:(CGFloat)newValue;
{
    _texelSpacingMultiplier = newValue;
    
    _verticalTexelSpacing = _texelSpacingMultiplier;
    _horizontalTexelSpacing = _texelSpacingMultiplier;
    
    [self setupFilterForSize:[self sizeOfFBO]];
}
- (void)setParmas:(RDGPUVectore4 )parmas{
    _parmas = parmas;
    [self setVec4:parmas forUniform:paramsUniform program:filterProgram];
}

- (void) setBeautyLevel: (NSInteger ) level;
{
    switch (level) {
        case 1:
            self.parmas = (RDGPUVectore4){1.0,1.0,0.15,0.15};
            break;
        case 2:
            self.parmas = (RDGPUVectore4){0.8,0.9,0.2,0.2};
            break;
        case 3:
            self.parmas = (RDGPUVectore4){0.6,0.8,0.25,0.25};
            break;
        case 4:
            self.parmas = (RDGPUVectore4){0.4,0.7,0.38,0.3};
            break;
        case 5:
            self.parmas = (RDGPUVectore4){0.33,0.63,0.4,0.35};
            break;
        default:
            break;
    }
}

#pragma mark -
#pragma mark Accessors

- (void)setConstValue:(float)constValue{
    _constValue = constValue;
    [self setFloat:constValue
        forUniform:firstDistanceNormalizationFactorUniform
           program:filterProgram];
    
    [self setFloat:constValue
        forUniform:secondDistanceNormalizationFactorUniform
           program:secondFilterProgram];
    
}
#pragma mark dealloc
- (void)dealloc{
    NSLog(@"%s",__func__);
}
@end
