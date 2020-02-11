//
//  CircleView.m
//  RDVEUISDK
//
//  Created by 周晓林 on 2017/3/21.
//  Copyright © 2017年 周晓林. All rights reserved.
//

#import "CircleView.h"
#define WIDTH self.frame.size.width
#define HEIGHT self.frame.size.height

@implementation CircleView


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        [self initData];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        [self initData];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        [self initData];
    }
    return self;
}

/** 初始化数据*/
- (void)initData
{
    self.progressWidth = 3.0;
    self.progressColor = [UIColor redColor];
    self.progressBackgroundColor = [UIColor grayColor];
    self.percent = 0.0;
    self.clockwise =0;
    self.backgroundColor = [UIColor clearColor];

}

#pragma mark -- 画进度条

- (void)drawRect:(CGRect)rect
{
    self.backgroundColor = [UIColor clearColor];
    //获取当前画布
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetShouldAntialias(context, YES);
    CGContextAddArc(context, WIDTH/2, HEIGHT/2, (WIDTH-self.progressWidth)/2, 0, M_PI*2, 0);
    [self.progressBackgroundColor setStroke];//设置圆描边背景的颜色
    //画线的宽度
    CGContextSetLineWidth(context, self.progressWidth);
    //绘制路径
    CGContextStrokePath(context);
    
    if(self.percent)
    {
        CGFloat angle = 2 * self.percent * M_PI - M_PI_2;
        if(self.clockwise) {//反方向
            CGContextAddArc(context, WIDTH/2, HEIGHT/2, (WIDTH-self.progressWidth)/2, ((int)self.percent == 1 ? -M_PI_2 : angle), -M_PI_2, 0);
        }
        else {//正方向
            CGContextAddArc(context, WIDTH/2, HEIGHT/2, (WIDTH-self.progressWidth)/2, -M_PI_2, angle, 0);
        }
        [self.progressColor setStroke];//设置圆描边的颜色
        CGContextSetLineWidth(context, self.progressWidth);
        CGContextStrokePath(context);
    }
}

- (void)setPercent:(float)percent
{
    _percent = percent;
    if(self.percent <= 0 || self.percent > 1){
        dispatch_async(dispatch_get_main_queue(), ^{self.hidden = YES;});
         return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hidden = NO;
        NSLog(@"download:%f",_percent);
        [self setNeedsDisplay];
    });
}

- (void)dealloc{
//    NSLog(@"%s",__func__);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
