//
//  RDRecordBeautyLowFilter.h
//  RDVECore
//
//  Created by 周晓林 on 16/4/19.
//  Copyright © 2016年 周晓林. All rights reserved.

#import "RDGPUImageTwoPassTextureSamplingFilter.h"
//#import "RDGPUImageTwoPassTextureSamplingFilter.h"
@interface RDRecordBeautyLowFilter : RDGPUImageTwoPassTextureSamplingFilter
{
    CGFloat firstDistanceNormalizationFactorUniform;
    CGFloat secondDistanceNormalizationFactorUniform;
    GLint paramsUniform;
    
}
@property (nonatomic,readwrite) float constValue;
@property (nonatomic,readwrite) RDGPUVectore4 parmas;
@property (readwrite, nonatomic) CGFloat texelSpacingMultiplier;

- (void) setBeautyLevel: (NSInteger ) level;

@end
