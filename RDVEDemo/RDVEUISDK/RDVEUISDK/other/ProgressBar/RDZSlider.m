//
//  RDZSlider.m
//  RDVEUISDK
//
//  Created by 周晓林 on 2016/12/6.
//  Copyright © 2016年 RDVEUISDK. All rights reserved.
//

#import "RDZSlider.h"
@interface RDZSlider()
@property (nonatomic, strong) UIImageView* highlightView;
@end
@implementation RDZSlider

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.highlightView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 10)];
        _isAETemplate = false;
        _highlightView.center = CGPointMake(frame.size.width/2, frame.size.height/2);
        
    }
    return self;
}

- (void)setFrame:(CGRect)frame{
    [super setFrame:frame];

    _highlightView.frame = CGRectMake(0, 0, frame.size.width, 5);
    _highlightView.center = CGPointMake(frame.size.width/2, frame.size.height/2);

//    [_highlightView setFrame:CGRectMake(0, 0, frame.size.width, 5)];
    
}
- (void)setHighlightImage:(UIImage *)highlightImage
{
    _highlightView.image = highlightImage;
    [self insertSubview:_highlightView atIndex:2];
}

- (CGRect)trackRectForBounds:(CGRect)bounds
{
//    if(_isAdj)
//        return CGRectMake(bounds.origin.x - 5, bounds.origin.y, bounds.size.width, 40);
    
    if( _isAETemplate )
    {
        bounds.origin.x=bounds.origin.x+5;
        
        bounds.size.width=bounds.size.width-10;
    }
    bounds =  [super trackRectForBounds:bounds ];
    return bounds;
}

-(CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value {
    if(_isAETemplate)
    {
        rect.origin.x=rect.origin.x-4.0;
        
        rect.size.width=rect.size.width+8;
        return CGRectInset([super thumbRectForBounds:bounds trackRect:rect value:value],4.0,4.0);
    }
    else
        return [super thumbRectForBounds:bounds trackRect:rect value:value];
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
