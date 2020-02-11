//
//  RDCircleView.m
//  RDVEUISDK
//
//  Created by emmet on 2017/3/29.
//  Copyright © 2017年 RDVEUISDK. All rights reserved.
//

#import "RDCircleView.h"

@interface RDCircleView ()
{
    
    CAShapeLayer *backGroundLayer; //背景图层
    CAShapeLayer *frontFillLayer;      //用来填充的图层
    UIBezierPath *backGroundBezierPath; //背景贝赛尔曲线
    UIBezierPath *frontFillBezierPath;  //用来填充的贝赛尔曲线
    
    
}
@end

@implementation RDCircleView
@synthesize progressColor = _progressColor;
@synthesize progressTrackColor = _progressTrackColor;
@synthesize progressValue = _progressValue;
@synthesize progressStrokeWidth = _progressStrokeWidth;
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setUp];
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self setUp];
        
    }
    return self;
    
}
/**
 *  初始化创建图层
 */
- (void)setUp
{
    //创建背景图层
    backGroundLayer = [CAShapeLayer layer];
    backGroundLayer.fillColor = nil;
    backGroundLayer.frame = self.bounds;
    
    //创建填充图层
    frontFillLayer = [CAShapeLayer layer];
    frontFillLayer.fillColor = nil;
    frontFillLayer.frame = self.bounds;
    
    
    [self.layer addSublayer:backGroundLayer];
    [backGroundLayer addSublayer:frontFillLayer];
    backGroundLayer.masksToBounds = YES;
    backGroundLayer.cornerRadius = CGRectGetWidth(backGroundLayer.bounds)/2.0;
}

- (void)startAnimation{
    //缩放动画
    _animation = YES;
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];//
    scaleAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    scaleAnimation.toValue = [NSNumber numberWithFloat:0.9];
    scaleAnimation.duration = 0.5f;
    scaleAnimation.autoreverses = YES;
    scaleAnimation.repeatCount = HUGE_VALF;
    scaleAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    [frontFillLayer addAnimation:scaleAnimation forKey:@"scaleAnimation"];
    
}

- (void)stopAnimation{
    _animation = NO;
    [frontFillLayer removeAllAnimations];
}

- (void)setProgressColor:(UIColor *)progressColor
{
    _progressColor = progressColor;
    frontFillLayer.strokeColor = progressColor.CGColor;
}
- (UIColor *)progressColor
{
    return _progressColor;
}
- (void)setProgressTrackColor:(UIColor *)progressTrackColor
{
    _progressTrackColor = progressTrackColor;
    backGroundLayer.strokeColor = progressTrackColor.CGColor;
    backGroundBezierPath = [UIBezierPath bezierPathWithArcCenter:self.center radius:(CGRectGetWidth(self.bounds)-self.progressStrokeWidth)/2.f startAngle:0 endAngle:M_PI*2
                                                       clockwise:YES];
    backGroundLayer.path = backGroundBezierPath.CGPath;
}
- (UIColor *)progressTrackColor
{
    return _progressTrackColor;
}
- (void)setProgressValue:(CGFloat)progressValue
{
    _progressValue = progressValue;
    frontFillBezierPath = [UIBezierPath bezierPathWithArcCenter:self.center radius:(CGRectGetWidth(self.bounds)-self.progressStrokeWidth)/2.f startAngle:-M_PI_4 endAngle:(2*M_PI)*progressValue-M_PI_4 clockwise:YES];
    frontFillLayer.path = frontFillBezierPath.CGPath;
}
- (CGFloat)progressValue
{
    return _progressValue;
}
- (void)setProgressStrokeWidth:(CGFloat)progressStrokeWidth
{
    _progressStrokeWidth = progressStrokeWidth;
    frontFillLayer.lineWidth = progressStrokeWidth;
    backGroundLayer.lineWidth = progressStrokeWidth;
    
    [self setNeedsLayout];
    
}

- (void)setProgressRect:(CGRect)rect{
    backGroundLayer.frame = rect;
    
    frontFillLayer.frame = rect;
    
    
}

- (CGFloat)progressStrokeWidth
{
    return _progressStrokeWidth;
}
//20170330
- (void)dealloc{
    NSLog(@"%s",__func__);
    [frontFillLayer removeFromSuperlayer];
    frontFillLayer = nil;
    [backGroundLayer removeFromSuperlayer];
    backGroundLayer = nil;
}
@end
