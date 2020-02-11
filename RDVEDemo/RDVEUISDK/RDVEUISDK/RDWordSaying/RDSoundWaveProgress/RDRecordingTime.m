//
//  RDRecordingTime.m
//  RDVEUISDK
//
//  Created by apple on 2019/8/1.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDRecordingTime.h"


@interface RDRecordingTime()
{
    NSMutableArray<UILabel *> *timeFrameArray;
    float width;
}
@end

@implementation RDRecordingTime

-(void)refreshTime:(float) sec atIsNode:(bool) isNode
{
    width =  sec/60.0 * self.frame.size.width;
    if( isNode )
    {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(width - 2.5, 0, 2.5, self.frame.size.height)];
        label.backgroundColor = [UIColor whiteColor];
        if( !timeFrameArray )
            timeFrameArray = [NSMutableArray<UILabel *> new];
        [self addSubview:label];
        [timeFrameArray addObject:label];
    }
    [self setNeedsDisplay];
}

-(void)deleteRefreshTime:(float) sec atdecibelArray:(NSMutableArray<recordingSegment *> *) decibelArray
{
    [timeFrameArray enumerateObjectsUsingBlock:^(UILabel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
        obj = nil;
    }];
    
    [timeFrameArray removeAllObjects];
    timeFrameArray = nil;
    timeFrameArray = [NSMutableArray<UILabel*> new];
    
    [decibelArray enumerateObjectsUsingBlock:^(recordingSegment * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        float fWidth = ((float)obj.endValue/maxInterval)/60.0 * self.frame.size.width;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(fWidth - 2.5, 0, 2.5, self.frame.size.height)];
        label.backgroundColor = [UIColor whiteColor];
        [self addSubview:label];
        [timeFrameArray addObject:label];
        
    }];
    
    width =  sec/60.0 * self.frame.size.width;
    [self setNeedsDisplay];
}

-(void)clearTime
{
    if( timeFrameArray )
    {
        [timeFrameArray enumerateObjectsUsingBlock:^(UILabel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
            obj = nil;
        }];
        [timeFrameArray removeAllObjects];
        timeFrameArray = nil;
        width = 0;
    }
}

//绘图
-(void)drawRect:(CGRect)rect{
    CGContextRef contex = UIGraphicsGetCurrentContext();
    // 创建一个新的空图形路径。
    if( !width )
        return;
    
    CGContextBeginPath(contex);
    CGContextMoveToPoint(contex, 0, self.frame.size.height/2.0);
    CGContextAddLineToPoint(contex, width, self.frame.size.height/2.0);
    // 设置图形的线宽
    CGContextSetLineWidth(contex, self.frame.size.height);
    // 设置图形描边颜色
    CGContextSetStrokeColorWithColor(contex, Main_Color.CGColor);
    // 根据当前路径，宽度及颜色绘制线
    CGContextStrokePath(contex);
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
