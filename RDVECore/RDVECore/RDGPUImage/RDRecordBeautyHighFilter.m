//
//  RDRecordBeautyHighFilter.m
//  RDVECore
//
//  Created by 周晓林 on 16/4/19.
//  Copyright © 2016年 周晓林. All rights reserved.
//

#import "RDRecordBeautyHighFilter.h"

NSString *const kRDGPUImageBeautyHighVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 const int GAUSSIAN_SAMPLES = 9;
 
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

NSString *const kRDGPUImageBeautyHighFragmentShaderString = SHADER_STRING
(
 precision lowp float;
 
 uniform sampler2D inputImageTexture;
 
 const  int GAUSSIAN_SAMPLES = 9;
 
 varying  vec2 textureCoordinate;
 varying  vec2 blurCoordinates[GAUSSIAN_SAMPLES];
 
 uniform  float distanceNormalizationFactor;
 uniform  vec4 params;
 const  vec3 W = vec3(0.299,0.587,0.114);
 const  mat3 saturateMatrix = mat3(
                                   1.1102,-0.0598,-0.061,
                                   -0.0774,1.0826,-0.1186,
                                   -0.0228,-0.0228,1.1772);
 
 float hardlight( float color)
{
    float color1 = color * color * 2.0 * (1.0 - step(0.5,color));
    float color2 = (1.0 - ((1.0 - color)*(1.0 - color) * 2.0)) * step(0.5,color);
    return color1 + color2;
}
 
 void main()
 {
     vec4 centralColor;
     float gaussianWeightTotal;
     vec4 sum;
     vec4 sampleColor;
     float distanceFromCentralColor;
     float gaussianWeight;
     centralColor = texture2D(inputImageTexture, blurCoordinates[4]);
     gaussianWeightTotal = 0.18;
     sum = centralColor * 0.18;
     
     sampleColor = texture2D(inputImageTexture, blurCoordinates[0]);
     distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
     gaussianWeight = 0.05 * (1.0 - distanceFromCentralColor);
     gaussianWeightTotal += gaussianWeight;
     sum += sampleColor * gaussianWeight;
     
     sampleColor = texture2D(inputImageTexture, blurCoordinates[1]);
     distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
     gaussianWeight = 0.09 * (1.0 - distanceFromCentralColor);
     gaussianWeightTotal += gaussianWeight;
     sum += sampleColor * gaussianWeight;
     
     sampleColor = texture2D(inputImageTexture, blurCoordinates[2]);
     distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
     gaussianWeight = 0.12 * (1.0 - distanceFromCentralColor);
     gaussianWeightTotal += gaussianWeight;
     sum += sampleColor * gaussianWeight;
     
     sampleColor = texture2D(inputImageTexture, blurCoordinates[3]);
     distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
     gaussianWeight = 0.15 * (1.0 - distanceFromCentralColor);
     gaussianWeightTotal += gaussianWeight;
     sum += sampleColor * gaussianWeight;
     
     sampleColor = texture2D(inputImageTexture, blurCoordinates[5]);
     distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
     gaussianWeight = 0.15 * (1.0 - distanceFromCentralColor);
     gaussianWeightTotal += gaussianWeight;
     sum += sampleColor * gaussianWeight;
     
     sampleColor = texture2D(inputImageTexture, blurCoordinates[6]);
     distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
     gaussianWeight = 0.12 * (1.0 - distanceFromCentralColor);
     gaussianWeightTotal += gaussianWeight;
     sum += sampleColor * gaussianWeight;
     
     sampleColor = texture2D(inputImageTexture, blurCoordinates[7]);
     distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
     gaussianWeight = 0.09 * (1.0 - distanceFromCentralColor);
     gaussianWeightTotal += gaussianWeight;
     sum += sampleColor * gaussianWeight;
     
     sampleColor = texture2D(inputImageTexture, blurCoordinates[8]);
     distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
     gaussianWeight = 0.05 * (1.0 - distanceFromCentralColor);
     gaussianWeightTotal += gaussianWeight;
     sum += sampleColor * gaussianWeight;
     
     sampleColor = sum / gaussianWeightTotal;
     
     vec4 smooth;
     float r = centralColor.r;
     float g = centralColor.g;
     float b = centralColor.b;
     
     if(r > 0.3725 && g > 0.1568 && b > 0.0784 && r > b && (max(max(r, g), b) - min(min(r, g), b)) > 0.0588 && abs(r-g) > 0.0588){
//         mediump float highPass = centralColor.g - sampleColor.g + 0.5;
//         
//         for(int i = 0; i < 3;i++)
//         {
//             highPass = hardlight(highPass);
//         }
//         vec3 finalColor = sampleColor.rgb;
//         
//         mediump float luminance = dot(finalColor, W);
//         
//         mediump float alpha = pow(luminance, params.r);
//         
//         mediump vec3 smoothColor = centralColor.rgb + (centralColor.rgb-vec3(highPass))*alpha*0.1;
//         smoothColor.r = clamp(pow(smoothColor.r, params.g),0.0,1.0);
//         smoothColor.g = clamp(pow(smoothColor.g, params.g),0.0,1.0);
//         smoothColor.b = clamp(pow(smoothColor.b, params.g),0.0,1.0);
//         
//         vec3 lvse = vec3(1.0)-(vec3(1.0)-finalColor)*(vec3(1.0)-centralColor.rgb);
//         vec3 bianliang = max(smoothColor, centralColor.rgb);
//         //     vec3 rouguang = 2.0*centralColor.rgb*smoothColor + centralColor.rgb*centralColor.rgb - 2.0*centralColor.rgb*centralColor.rgb*smoothColor;
//         smooth = vec4(mix(centralColor.rgb, lvse, alpha), 1.0);
//         smooth.rgb = mix(smooth.rgb, bianliang, alpha);
//         //     gl_FragColor.rgb = mix(gl_FragColor.rgb, rouguang, params.b);
//         
//         vec3 satcolor = smooth.rgb*saturateMatrix;
//         smooth.rgb = mix(smooth.rgb, satcolor, params.a);
         
        
         smooth = 0.35 * (centralColor - sampleColor) + sampleColor;

         

         
     }else{
         smooth = centralColor;
     }
     smooth.r = log(1.0 + 0.2 * smooth.r)/log(1.2);
     smooth.g = log(1.0 + 0.2 * smooth.g)/log(1.2);
     smooth.b = log(1.0 + 0.2 * smooth.b)/log(1.2);
     
     gl_FragColor = smooth;
     

 
 }
 
 );

@implementation RDRecordBeautyHighFilter

- (id)init;
{
    
    if (!(self = [super initWithFirstStageVertexShaderFromString:kRDGPUImageBeautyHighVertexShaderString
                              firstStageFragmentShaderFromString:kRDGPUImageBeautyHighFragmentShaderString
                               secondStageVertexShaderFromString:kRDGPUImageBeautyHighVertexShaderString
                             secondStageFragmentShaderFromString:kRDGPUImageBeautyHighFragmentShaderString])) {
        return nil;
    }
    
    firstDistanceNormalizationFactorUniform  = [filterProgram uniformIndex:@"distanceNormalizationFactor"];
    secondDistanceNormalizationFactorUniform = [filterProgram uniformIndex:@"distanceNormalizationFactor"];
    paramsUniform = [filterProgram uniformIndex:@"params"];
    
    self.texelSpacingMultiplier = 4.0;
    self.constValue = 4.0;
    
    [self setBeautyLevel:2];
    
    
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
