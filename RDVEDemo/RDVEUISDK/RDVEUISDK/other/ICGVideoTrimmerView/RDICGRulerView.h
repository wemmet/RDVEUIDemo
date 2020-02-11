//
//  ICGRulerView.h
//  ICGVideoTrimmer
//
//  Created by Huong Do on 1/25/15.
//  Copyright (c) 2015 ichigo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RDICGRulerView : UIView

@property (assign, nonatomic) CGFloat widthPerSecond;
@property (strong, nonatomic) UIColor *themeColor;

- (instancetype)initWithFrame:(CGRect)frame widthPerSecond:(CGFloat)width themeColor:(UIColor *)color;

@end
// 版权属于原作者
// http://code4app.com (cn) http://code4app.net (en)
// 发布代码于最专业的源码分享网站: Code4App.com