//
//  RDSectorProgressView.m
//  RDVEUISDK
//
//  Created by emmet on 15/8/26.
//  Copyright (c) 2015年 emmet. All rights reserved.
//


#import "RDSectorProgressView.h"
#import "RDHelpClass.h"

#define UIColorMake(r, g, b, a) [UIColor colorWithRed:r / 255. green:g / 255. blue:b / 255. alpha:a]

@interface RDSectorProgressView (){
    NSInteger integer;
}
@property(nonatomic, strong) NSTimer *timer;
@end

@implementation RDSectorProgressView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupParams];
        self.layer.borderColor = [UIColor whiteColor].CGColor;
        self.layer.borderWidth = 1;
        self.layer.cornerRadius = frame.size.width/2;
        self.layer.masksToBounds = YES;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupParams];
    }

    return self;
}

- (void)setupParams {
    self.backgroundColor = [UIColor clearColor];

    self.frameWidth = 0;
    self.progressColor = [UIColor greenColor];
    self.progressBackgroundColor =  UIColorFromRGB(0x27262c);
    self.circleBackgroundColor = [UIColor clearColor];
}

- (void)setProgress:(float)progress{//20161104 bug205
    
    [self progressValueChange:progress];
    
}

- (void)progressValueChange:(float)progress{
    
    _progress = progress;
    [self setNeedsDisplay];
    
}


#pragma mark draw progress
- (void)drawRect:(CGRect)rect {
    [self drawFillPie:rect margin:0 color:self.circleBackgroundColor percentage:1];
    [self drawFramePie:rect];
    [self drawFillPie:rect margin:self.frameWidth color:self.progressBackgroundColor percentage:1];
    [self drawFillPie:rect margin:self.frameWidth+2 color:self.progressColor percentage:_progress];
}

- (void)drawFillPie:(CGRect)rect margin:(CGFloat)margin color:(UIColor *)color percentage:(CGFloat)percentage {
    CGFloat radius = MIN(CGRectGetHeight(rect), CGRectGetWidth(rect)) * 0.5 - margin;
    CGFloat centerX = CGRectGetWidth(rect) * 0.5;
    CGFloat centerY = CGRectGetHeight(rect) * 0.5;

    CGContextRef cgContext = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(cgContext, [color CGColor]);
    CGContextMoveToPoint(cgContext, centerX, centerY);
    CGContextAddArc(cgContext, centerX, centerY, radius, (CGFloat) -M_PI_2, (CGFloat) (-M_PI_2 + M_PI * 2 * percentage), 0);
    CGContextClosePath(cgContext);
    CGContextFillPath(cgContext);
}

- (void)drawFramePie:(CGRect)rect {
    CGFloat radius = MIN(CGRectGetHeight(rect), CGRectGetWidth(rect)) * 0.5;
    CGFloat centerX = CGRectGetWidth(rect) * 0.5;
    CGFloat centerY = CGRectGetHeight(rect) * 0.5;

    [[UIColor whiteColor] set];
    CGFloat fw = self.frameWidth + 1;
    CGRect frameRect = CGRectMake(
            centerX - radius + fw,
            centerY - radius + fw,
            (radius - fw) * 1,
            (radius - fw) * 1);
    UIBezierPath *insideFrame = [UIBezierPath bezierPathWithOvalInRect:frameRect];
    insideFrame.lineWidth = 0.5;
    [insideFrame stroke];
}
//20170330
- (void)dealloc{
    NSLog(@"%s",__func__);
}
@end
