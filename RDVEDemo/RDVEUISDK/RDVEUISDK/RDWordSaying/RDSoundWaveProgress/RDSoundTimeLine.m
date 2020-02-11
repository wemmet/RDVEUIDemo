//
//  RDSoundTimeLine.m
//  RDVEUISDK
//
//  Created by apple on 2019/7/30.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDSoundTimeLine.h"

@implementation RDSoundTimeLine

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _minTime = 0;
        _maxTime = 60;
        _LineWidth = 1.0;
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
    }
    return self;
}

//绘图
-(void)drawRect:(CGRect)rect{
    CGContextRef contex = UIGraphicsGetCurrentContext();
    
    int count = (_maxTime - _minTime)*4 + 1;
    float x = _LineWidth/2.0 + kWIDTH/2.0;
    float width = (kWIDTH/6.0/4.0);
    for (int i = 0; i < count; i++) {
        int rem = i % 4;
        if( rem != 0 )
        {
            [self drawSmallScale: x + ((float)i)*width context:contex height:self.frame.size.height];
        }
        else
        {
            [self drawBigScale: x + ((float)i)*width context:contex height:self.frame.size.height];
            [self drawText:x + ((float)i)*width interval: ((float)i)*(1.0/4.0) context:contex height:self.frame.size.height];
        }
    }
}
#pragma mark --- 画小刻度
-(void)drawSmallScale:(float)x context:(CGContextRef)ctx height:(float)height{
    // 创建一个新的空图形路径。
    CGContextBeginPath(ctx);
    
    CGContextMoveToPoint(ctx, x-_LineWidth/2.0, height/2.0);
    CGContextAddLineToPoint(ctx, x-_LineWidth/2.0, height/2.0+5);
    // 设置图形的线宽
    CGContextSetLineWidth(ctx, _LineWidth);
    // 设置图形描边颜色
    CGContextSetStrokeColorWithColor(ctx, TEXT_COLOR.CGColor);
    // 根据当前路径，宽度及颜色绘制线
    CGContextStrokePath(ctx);
}
#pragma mark --- 画大刻度
-(void)drawBigScale:(float)x context:(CGContextRef)ctx height:(float)height{
    // 创建一个新的空图形路径。
    CGContextBeginPath(ctx);
    
    CGContextMoveToPoint(ctx, x-_LineWidth*0.5, height/2.0);
    CGContextAddLineToPoint(ctx, x-_LineWidth*0.5, height/2.0+10);
    // 设置图形的线宽
    CGContextSetLineWidth(ctx, _LineWidth);
    // 设置图形描边颜色
    CGContextSetStrokeColorWithColor(ctx, TEXT_COLOR.CGColor);
    // 根据当前路径，宽度及颜色绘制线
    CGContextStrokePath(ctx);
}
#pragma mark --> 在刻度上标记文本
-(void)drawText:(float)x interval:(float)interval context:(CGContextRef)ctx height:(float)height{
    
    int minu = ((int)interval)/60;
    int sec = ((int)interval)%60;
    
    NSString *text = @"00:00";
    
    if( sec < 10 )
    {
        text = [NSString stringWithFormat:@"0%d:0%d",minu,sec];
    }
    else{
        text = [NSString stringWithFormat:@"0%d:%d",minu,sec];
    }
    
    CGContextSetRGBFillColor(ctx, 1, 0, 0, 1);
    UIFont *font = [UIFont systemFontOfSize:10];
    NSMutableParagraphStyle *paragraph=[[NSMutableParagraphStyle alloc]init];
    paragraph.alignment=NSTextAlignmentCenter;//居中
    [text drawInRect:CGRectMake(x-15, (height/2.0 - 10)/2.0, 30, 10) withAttributes:@{NSFontAttributeName : font,NSForegroundColorAttributeName:TEXT_COLOR,NSParagraphStyleAttributeName:paragraph}];
}
@end
