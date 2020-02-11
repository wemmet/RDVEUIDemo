//
//  decibelLine.m
//  RDVEUISDK
//
//  Created by apple on 2019/7/31.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "decibelLine.h"

@implementation recordingSegment
@end

@implementation decibelLine

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _currentAudioDecibelNumber = 0;
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
    }
    return self;
}

//绘图
-(void)drawRect:(CGRect)rect{
    CGContextRef contex = UIGraphicsGetCurrentContext();
    
    float x = (kWIDTH/6.0/maxInterval);
    
    [_decibelArray enumerateObjectsUsingBlock:^(recordingSegment * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        UIColor * color = _CurrentNumberColor;
        if( (idx%2) != ((_decibelArray.count-1)%2) )
        {
            color = _lastNumberColor;
        }
        for (int i = 0; i < obj.decibelArray.count; i++) {
            float height = (obj.decibelArray[i].floatValue) * (self.frame.size.height)*39.0/40.0
            + (self.frame.size.height)/40.0;
            [self drawSmallScale:x * (i+obj.startValue) context:contex height:height atColor:color];
        }
        
    }];
    
    
}
#pragma mark --- 画小刻度
-(void)drawSmallScale:(float)x context:(CGContextRef)ctx height:(float)height atColor:(UIColor *) color{
    // 创建一个新的空图形路径。
    CGContextBeginPath(ctx);
    float width = (kWIDTH/6.0/maxInterval)/3.0;
    CGContextMoveToPoint(ctx, x, (self.frame.size.height - height)/2.0);
    CGContextAddLineToPoint(ctx, x, self.frame.size.height - (self.frame.size.height - height)/2.0);
    // 设置图形的线宽
    CGContextSetLineWidth(ctx, width);
    // 设置图形描边颜色
    CGContextSetStrokeColorWithColor(ctx, color.CGColor);
    // 根据当前路径，宽度及颜色绘制线
    CGContextStrokePath(ctx);
}

@end
