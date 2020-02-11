//
//  UIImage+Tint.h
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/12/11.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Tint)

- (UIImage *) imageWithTintColor;

- (UIImage *)imageWithBlendMode:(CGBlendMode)blendMode tintColor:(UIColor *)tintColor;

@end
