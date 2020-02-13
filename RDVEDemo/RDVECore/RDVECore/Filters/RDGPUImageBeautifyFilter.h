//
//  GPUImageBeautifyFilter.h
//  BeautifyFaceDemo
//
//  Created by guikz on 16/4/28.
//  Copyright © 2016年 guikz. All rights reserved.
//

#import "RDGPUImageFilterGroup.h"
#import "RDGPUImageBilateralFilter.h"
//#import "RDGPUImageCannyEdgeDetectionFilter.h"
#import "RDGPUImageSobelEdgeDetectionFilter.h"
#import "RDGPUImageHSBFilter.h"
@class RDGPUImageCombinationFilter;

@interface RDGPUImageBeautifyFilter : RDGPUImageFilterGroup {
    RDGPUImageBilateralFilter *bilateralFilter;
    RDGPUImageSobelEdgeDetectionFilter *sobelEdgeFilter;
    RDGPUImageCombinationFilter *combinationFilter;
    RDGPUImageHSBFilter *hsbFilter;
}

// 0.0 - 1.0 磨皮参数
@property (nonatomic, assign) CGFloat intensity;
// 0.0 - 1.0 亮度
@property (nonatomic, assign) CGFloat brightness;

@end
