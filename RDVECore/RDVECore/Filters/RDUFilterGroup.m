//
//  RDUFilterGroup.m
//  RDVECore
//
//  Created by 周晓林 on 2017/10/16.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDUFilterGroup.h"
#import "RDGPUImageBrightnessFilter.h"
#import "RDGPUImageExposureFilter.h"
#import "RDGPUImageSaturationFilter.h"
#import "RDGPUImageSharpenFilter.h"
#import "RDGPUImageWhiteBalanceFilter.h"

@interface RDUFilterGroup()
{
    RDGPUImageBrightnessFilter* brightnessFilter;
    RDGPUImageExposureFilter* exposureFilter;
    RDGPUImageSaturationFilter* saturationFilter;
    RDGPUImageSharpenFilter* sharpenFilter;
    RDGPUImageWhiteBalanceFilter* whiteBalanceFilter;
}
@end
@implementation RDUFilterGroup
- (instancetype)init{
    if (self = [super init]) {
        brightnessFilter = [[RDGPUImageBrightnessFilter alloc] init];
        [self addFilter:brightnessFilter];
        
        exposureFilter = [[RDGPUImageExposureFilter alloc] init];
        [self addFilter:exposureFilter];
        
        saturationFilter = [[RDGPUImageSaturationFilter alloc] init];
        [self addFilter:saturationFilter];
        
        sharpenFilter = [[RDGPUImageSharpenFilter alloc] init];
        [self addFilter:sharpenFilter];
        
        whiteBalanceFilter = [[RDGPUImageWhiteBalanceFilter alloc] init];
        [self addFilter:whiteBalanceFilter];
        
        [brightnessFilter addTarget:exposureFilter];
        [exposureFilter addTarget:saturationFilter];
        [saturationFilter addTarget:sharpenFilter];
        [sharpenFilter addTarget:whiteBalanceFilter];
        
        self.initialFilters = [NSArray arrayWithObject:brightnessFilter];
        self.terminalFilter = whiteBalanceFilter;
        
        self.brightness = 0.0;
        self.exposure = 0.0;
        self.saturation = 1.0;
        self.sharpness = 0.0;
        
        
        self.temperature = 5000.0;
        self.tint = 0.0;
        
        
    }
    return self;
}
- (void)setSharpness:(CGFloat)sharpness{
    sharpenFilter.sharpness = sharpness;
}
- (CGFloat)sharpness{
    return sharpenFilter.sharpness;
}
- (void)setTint:(CGFloat)tint{
    whiteBalanceFilter.tint = tint;
}
- (CGFloat)tint{
    return whiteBalanceFilter.tint;
}

- (void)setBrightness:(CGFloat)brightness{
    brightnessFilter.brightness = brightness;
}
- (CGFloat)brightness{
    return brightnessFilter.brightness;
}

- (void)setExposure:(CGFloat)exposure{
    exposureFilter.exposure = exposure;
}

- (CGFloat)exposure{
    return exposureFilter.exposure;
}

- (void)setSaturation:(CGFloat)saturation{
    saturationFilter.saturation = saturation;
}
- (CGFloat)saturation{
    return saturationFilter.saturation;
}

@end
