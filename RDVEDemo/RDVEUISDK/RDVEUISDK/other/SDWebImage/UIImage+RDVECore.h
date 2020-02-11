//
//  UIImage+VECore.h
//  RDVEUISDK
//
//  Created by Austin on 14-3-7.
//  Copyright (c) 2014年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (RDVECore)

+ (UIImage *) rd_ImageWithColor:(UIColor *)color cornerRadius:(CGFloat)cornerRadius;

+ (UIImage *) rd_buttonImageWithColor:(UIColor *)color
                      cornerRadius:(CGFloat)cornerRadius
                       shadowColor:(UIColor *)shadowColor
                      shadowInsets:(UIEdgeInsets)shadowInsets;

+ (UIImage *) rd_circularImageWithColor:(UIColor *)color
                                size:(CGSize)size;

- (UIImage *) rd_imageWithMinimumSize:(CGSize)size;

+ (UIImage *) rd_stepperPlusImageWithColor:(UIColor *)color;

+ (UIImage *) rd_stepperMinusImageWithColor:(UIColor *)color;

+ (UIImage *) rd_backButtonImageWithColor:(UIColor *)color
                            barMetrics:(UIBarMetrics) metrics
                          cornerRadius:(CGFloat)cornerRadius;

@end

