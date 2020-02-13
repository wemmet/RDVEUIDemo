//
//  RDLOTTintCIFilter.h
//  RDLottie
//
//  Created by xiachunlin Withrow on 2019/11/28.
//  Copyright © 2019 Brandon Withrow. All rights reserved.
//
//


#import "RDLOTTintCIFilter.h"
#import "RDLOTColorInterpolator.h"
#import "RDLOTNumberInterpolator.h"


@implementation RDLOTTintCIFilter


- (CIImage *) outputImage
{

    RDLOTColorInterpolator *colorInterpolator = nil;
    RDLOTNumberInterpolator *valueInterpolator = nil;
    float value = 0;
    CIFilter *filterTint001 = nil;
    CIFilter *filterTint002 = nil;
    CIFilter *filterTint003 = nil;
    CIImage  *tintOutImage = nil;
    
    //1.处理饱和度
    AdbeEffect* effect = [_effectArray objectAtIndex:2];
    //获取饱和度值
    valueInterpolator = [[RDLOTNumberInterpolator alloc] initWithKeyframes:effect.keyframes];
    value = [valueInterpolator floatValueForFrame:_curFrame];
    
    
    filterTint003 = [CIFilter filterWithName:@"CIColorControls" //饱和度
                        withInputParameters: @{
        kCIInputImageKey: _inputImage,
        @"inputSaturation": [NSNumber numberWithFloat:(100.0 - value)/100.0],
    
    }];
    
    
    //2.将黑色映射到
    effect = [_effectArray objectAtIndex:0];
    colorInterpolator = [[RDLOTColorInterpolator alloc] initWithKeyframes:effect.keyframes];
    CGColorRef color = [colorInterpolator colorForFrame:_curFrame];
    const CGFloat *colorComponents = CGColorGetComponents(color);
    float r = colorComponents[0];
    float g = colorComponents[1];
    float b = colorComponents[2];
    float a = colorComponents[3];
    if((!r && !g && !b) || (1.0 == r && 1.0 == g && 1.0 == b))
    {
        // 常规Tint001 映射到 (0,0,0,a) 或者 (1,1,1,a)

    }
    else
    {
        filterTint001 = [CIFilter filterWithName:@"CIColorMatrix"
                            withInputParameters: @{
            kCIInputImageKey: filterTint003.outputImage,
        @"inputRVector": [CIVector vectorWithX:1 Y:0 Z:0 W:0],
        @"inputGVector": [CIVector vectorWithX:0 Y:1 Z:0 W:0],
        @"inputBVector": [CIVector vectorWithX:0 Y:0 Z:1 W:0],
        @"inputAVector": [CIVector vectorWithX:0 Y:0 Z:0 W:1],
        @"inputBiasVector": [CIVector vectorWithX:r Y:g Z:b],
        }];
        NSLog(@"r: %g g:%g b:%g",r,g,b);
    }
        
    //3.将白色影射到
    effect = [_effectArray objectAtIndex:1];
    colorInterpolator = [[RDLOTColorInterpolator alloc] initWithKeyframes:effect.keyframes];
    color = [colorInterpolator colorForFrame:_curFrame];
    colorComponents = CGColorGetComponents(color);
    r = colorComponents[0];
    g = colorComponents[1];
    b = colorComponents[2];
    a = colorComponents[3];
    
    if(filterTint001)
        tintOutImage = filterTint001.outputImage;
    else if(filterTint003)
        tintOutImage = filterTint003.outputImage;
    else
        tintOutImage = _inputImage;

    if((!r && !g && !b) || (1.0 == r && 1.0 == g && 1.0 == b))
    {
        filterTint002 = [CIFilter filterWithName:@"CIColorControls" //饱和度
                            withInputParameters: @{
            kCIInputImageKey: tintOutImage,
            @"inputSaturation": [NSNumber numberWithFloat:1.0],
        }];
    }
    else
    {
        filterTint002 = [CIFilter filterWithName:@"CIColorMatrix"
                            withInputParameters: @{
        kCIInputImageKey: tintOutImage,
        @"inputRVector": [CIVector vectorWithX:r Y:0 Z:0 W:0],
        @"inputGVector": [CIVector vectorWithX:0 Y:g Z:0 W:0],
        @"inputBVector": [CIVector vectorWithX:0 Y:0 Z:b W:0],
        @"inputAVector": [CIVector vectorWithX:0 Y:0 Z:0 W:a],
        @"inputBiasVector": [CIVector vectorWithX:0 Y:0 Z:0],
        }];
    }

//    NSLog(@"count:%d frame:%g",_effectArray.count,[_curFrame floatValue]);
    return filterTint002.outputImage;
}
@end
