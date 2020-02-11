//
//  ComminuteRangeView.m
//  RDVEUISDK
//
//  Created by emmet on 15/8/21.
//  Copyright (c) 2015年 emmet. All rights reserved.
//

#import "RDComminuteRangeView.h"
#import "RDHelpClass.h"

#define isPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define DRAG_THRESHOLD 10


//float ComminutedistanceBetweenPoints(CGPoint a, CGPoint b);

@implementation RDComminuteRangeView

- (void)setThumb:(UIImage *)thumb{
    _thumb = thumb;
//    self.layer.contents = (id)_thumb.CGImage;
    
}

- (void)drawRect:(CGRect)rect{
    [super drawRect:rect];
//    CGContextRef context =UIGraphicsGetCurrentContext();
//    float inset = 100;
//    //圆的边框宽度为2，颜色为红色
//    
//    CGContextSetLineWidth(context,2);
//    
//    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
//    
//    //CGRect rect = CGRectMake(inset, inset, _thumb.size.width - inset *2.0f, _thumb.size.height - inset *2.0f);
//    
//    CGContextAddEllipseInRect(context, rect);
//    
//    CGContextClip(context);
//    
//    //在圆区域内画出image原图
//    
//    [_thumb drawInRect:rect];
//    
//    CGContextAddEllipseInRect(context, rect);
//    
//    CGContextStrokePath(context);
}

- (void)dealloc{
    NSLog(@"%s",__func__);
}
@end
