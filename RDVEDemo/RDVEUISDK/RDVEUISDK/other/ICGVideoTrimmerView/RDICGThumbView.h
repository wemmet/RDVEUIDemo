//
//  ICGVideoTrimmerLeftOverlay.h
//  ICGVideoTrimmer
//
//  Created by Huong Do on 1/19/15.
//  Copyright (c) 2015 ichigo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RDICGThumbView : UIView

@property (strong, nonatomic) UIColor *color;

- (instancetype)initWithFrame:(CGRect)frame color:(UIColor *)color right:(BOOL)flag;

- (instancetype)initWithFrame:(CGRect)frame thumbImage:(UIImage *)image;

@end
// 版权属于原作者
// http://code4app.com (cn) http://code4app.net (en)
// 发布代码于最专业的源码分享网站: Code4App.com