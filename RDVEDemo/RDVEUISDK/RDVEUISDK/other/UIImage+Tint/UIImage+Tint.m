//
//  UIImage+Tint.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/12/11.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "UIImage+Tint.h"

@implementation UIImage (Tint)

- (UIImage *)imageWithTintColor {
    return self;
    //kCGBlendModeLuminosity
    //kCGBlendModePlusDarker
    //kCGBlendModeDarken
//    return [self imageWithBlendMode:kCGBlendModeLuminosity tintColor:Main_Color];
}

- (UIImage *)imageWithBlendMode:(CGBlendMode)blendMode tintColor:(UIColor *)tintColor
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    [tintColor setFill];
    CGRect bounds = CGRectMake(0, 0, self.size.width, self.size.height);
    UIRectFill(bounds);
    
    //Draw the tinted image in context
    [self drawInRect:bounds blendMode:blendMode alpha:1.0f];
    
    if (blendMode != kCGBlendModeDestinationIn) {
        [self drawInRect:bounds blendMode:kCGBlendModeDestinationIn alpha:1.0f];
    }
    
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return tintedImage;
}

@end
