//
//  RDRangeView.m
//  dyUIAPIDemo
//
//  Created by wuxiaoxia on 2017/5/11.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDRangeView.h"
#import <QuartzCore/QuartzCore.h>
typedef NS_ENUM(NSInteger,TouchPositionType) {
    kTouchNone,
    kTouchLeft,
    kTouchRight,
    kTouchMiddle
    
};
@interface RDRangeView ()
{
    TouchPositionType _touchType;
    CGPoint           _touchBeginPoint;
    float             _difxSpan;
    float             _framewidthspan;
    UIImageView      *_leftHandle;
    UIImageView      *_rightHandle;
    UIImageView      *_middleHandle;
}
@end
@implementation RDRangeView

- (instancetype)init{
    self = [super init];
    if(self){
        _touchType = kTouchNone;
        _canMoveLeft = NO;
        _canMoveRight = NO;
        _canChangeWidth = NO;
        _hasMiddle = NO;
        
    }
    return self;
}

- (void)setHasMiddle:(BOOL)hasMiddle{
    _hasMiddle = hasMiddle;
    if(hasMiddle){
        _canChangeWidth = NO;
        _middleHandle = [UIImageView new];
        _middleHandle.frame = CGRectMake(self.frame.size.width/2.0, (self.frame.size.height-36)/2.0, 36, 36);
        _middleHandle.backgroundColor = [UIColor clearColor];
        _middleHandle.highlightedImage = [RDHelpClass imageWithContentOfFile:@"/jianji/effectVideo/时间特效-特效位置点击_"];
        _middleHandle.image = [RDHelpClass imageWithContentOfFile:@"/jianji/effectVideo/时间特效-特效位置默认_"];
        [self addSubview:_middleHandle];
    }
}

- (void)setCanMoveLeft:(BOOL)canMoveLeft{
    _canMoveLeft = canMoveLeft;
    if(_canMoveLeft){
        _leftHandle = [UIImageView new];
        _leftHandle.frame = CGRectMake(0, (self.frame.size.height-36)/2.0, 36, 36);
        _leftHandle.backgroundColor = [UIColor clearColor];
        _leftHandle.highlightedImage = [RDHelpClass imageWithContentOfFile:@"/jianji/effectVideo/时间特效-倒序_左点击_"];
        _leftHandle.image = [RDHelpClass imageWithContentOfFile:@"/jianji/effectVideo/时间特效-倒序_左默认_"];
        [self addSubview:_leftHandle];
    }else{
        if(_leftHandle.superview){
            [_leftHandle removeFromSuperview];
        }
        _leftHandle = nil;
    }
}

- (void)setCanMoveRight:(BOOL)canMoveRight{
    _canMoveRight = canMoveRight;
    
    if(_canMoveRight){
        _rightHandle = [UIImageView new];
        _rightHandle.frame = CGRectMake(self.frame.size.width - 36, (self.frame.size.height-36)/2.0, 36, 36);
        _rightHandle.backgroundColor = [UIColor clearColor];
        _rightHandle.highlightedImage = [RDHelpClass imageWithContentOfFile:@"/jianji/effectVideo/时间特效-倒序_右点击_"];
        _rightHandle.image = [RDHelpClass imageWithContentOfFile:@"/jianji/effectVideo/时间特效-倒序_右默认_"];
        [self addSubview:_rightHandle];
    }else{
        if(_rightHandle.superview){
            [_rightHandle removeFromSuperview];
        }
        _rightHandle = nil;
    }
}

- (void)drawRect:(CGRect)rect{
    
    [super drawRect:rect];
    if(_hasMiddle){
        _canMoveLeft = NO;
        _canMoveRight = NO;
    }
    
    self.userInteractionEnabled = YES;
    self.titleLabel.numberOfLines = 2;
    self.titleLabel.text = self.file.name;
    _middleHandle.frame = CGRectMake((self.frame.size.width - 36)/2.0, (self.frame.size.height-36)/2.0, 36, 36);

    CGFloat red = 0.0;
    CGFloat green = 0.0;
    CGFloat blue = 0.0;
    CGFloat alpha = 1.0;
    if( _coverColor != nil )
        [_coverColor getRed:&red green:&green blue:&blue alpha:&alpha];
    
    if(_hasMiddle &&(_canMoveRight && _canMoveLeft)){
        if( alpha > 0  )
            self.backgroundColor = [_coverColor colorWithAlphaComponent:0.8];//用这种方法背景半透明，但是子控件不会透明
        else
            self.backgroundColor = [_coverColor colorWithAlphaComponent:0.0];//用这种方法背景半透明，但是子控件不会透明
    }else if(!_hasMiddle &&(_canMoveRight || _canMoveLeft)){
        if( alpha > 0  )
            self.backgroundColor = [_coverColor colorWithAlphaComponent:0.8];
        else
            self.backgroundColor = [_coverColor colorWithAlphaComponent:0.0];//用这种方法背景半透明，但是子控件不会透明
    }else if(_hasMiddle &&(!_canMoveRight || !_canMoveLeft)){
        if( alpha > 0  )
            self.backgroundColor = [_coverColor colorWithAlphaComponent:0.8];
        else
            self.backgroundColor = [_coverColor colorWithAlphaComponent:0.0];//用这种方法背景半透明，但是子控件不会透明
    }else{
        if( alpha > 0  )
            self.backgroundColor = [_coverColor colorWithAlphaComponent:0.6];
        else
            self.backgroundColor = [_coverColor colorWithAlphaComponent:0.0];//用这种方法背景半透明，但是子控件不会透明
    }
}

- (void)setCoverRect:(CGRect)coverRect{
    _coverRect = coverRect;
    [self setNeedsDisplay];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    _difxSpan = 0;
    UITouch *aTouch = [touches anyObject];
    if (aTouch.tapCount == 1) {
        CGPoint p = [aTouch locationInView:self];
        _touchBeginPoint = [aTouch locationInView:self.superview];
        if(_hasMiddle){
            if(!_canMoveLeft && !_canMoveRight){
                NSLog(@"****-->%s p:%f",__func__,p.x);
                _touchType = kTouchMiddle;
                _difxSpan = _touchBeginPoint.x - self.frame.origin.x;
            }else{
                _touchType = kTouchNone;
            }
        }else{
            if(CGRectContainsPoint([self touchRectForHandle:CGPointMake(18, self.frame.size.height/2.0)], p))
            {
                NSLog(@"***左-->%s p:%f",__func__,p.x);
                _touchType = kTouchLeft;
                _difxSpan = _touchBeginPoint.x - self.frame.origin.x;
                _framewidthspan = self.frame.origin.x + self.frame.size.width;


            }else if(CGRectContainsPoint([self touchRectForHandle:CGPointMake(self.frame.size.width-18, self.frame.size.height/2.0)], p))
            {
                _touchType = kTouchRight;
                NSLog(@"***右-->%s p:%f",__func__,p.x);
                _difxSpan = self.frame.origin.x + self.frame.size.width - _touchBeginPoint.x;

            }
        }

        if(_delegate){
            if([_delegate respondsToSelector:@selector(touchesRangeViewBegin:)]){
                [_delegate touchesRangeViewBegin:self];
            }
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *aTouch = [touches anyObject];
    if (aTouch.tapCount == 1) {
        CGPoint p = [aTouch locationInView:self.superview];
//        NSLog(@"***%s p:%f",__func__,p.x);
            switch (_touchType) {
                case kTouchLeft:
                {
                    if(_canChangeWidth){
                        float width = MIN(MAX(fabs(_framewidthspan - p.x + _difxSpan), (_canMoveLeft && _canMoveRight) ? (_leftHandle.bounds.size.width + _rightHandle.bounds.size.width - 15): _minWidth),self.superview.frame.size.width);
                        CGRect rect = self.frame;
                        rect.size.width = width;
                        rect.origin.x = MAX(MIN(p.x - _difxSpan, self.superview.frame.size.width - width), 0);
                        self.frame = rect;
                        _leftHandle.frame = CGRectMake(0, (self.frame.size.height-36)/2.0, 36, 36);
                        _rightHandle.frame = CGRectMake(self.frame.size.width - 36, (self.frame.size.height-36)/2.0, 36, 36);
                    }
                }
                    break;
                case kTouchRight:
                {
                    if(_canChangeWidth){
                        CGRect rect = self.frame;
                        rect.size.width = MIN(MAX(p.x +_difxSpan - self.frame.origin.x, (_canMoveLeft && _canMoveRight) ? (_leftHandle.bounds.size.width + _rightHandle.bounds.size.width - 15) : _minWidth), self.superview.frame.size.width - self.frame.origin.x);
                        self.frame = rect;
                        _leftHandle.frame = CGRectMake(0, (self.frame.size.height-36)/2.0, 36, 36);
                        _rightHandle.frame = CGRectMake(self.frame.size.width - 36, (self.frame.size.height-36)/2.0, 36, 36);
                    }
                }
                    break;
                case kTouchMiddle:
                {
                    if(_hasMiddle){
//                        NSLog(@"***difx:%f",_difxSpan);
                        self.frame = CGRectMake(MAX(MIN(p.x - _difxSpan, self.superview.frame.size.width - self.frame.size.width), 0), self.frame.origin.y, self.frame.size.width, self.frame.size.height);
                        _middleHandle.frame = CGRectMake((self.frame.size.width - 36)/2.0, (self.frame.size.height-36)/2.0, 36, 36);
                    }
                }
                    break;

                default:
                    break;
            }
        if(_delegate){
            if([_delegate respondsToSelector:@selector(touchesRangeViewMoving:)]){
                [_delegate touchesRangeViewMoving:self];
            }
        }
    }

}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *aTouch = [touches anyObject];
    if (aTouch.tapCount == 1) {
        CGPoint p = [aTouch locationInView:self.superview];
        NSLog(@"**%s p:%f",__func__,p.x);
        _touchType = kTouchNone;
    }
    if(_delegate){
        if([_delegate respondsToSelector:@selector(touchesRangeViewEnd:)]){
            [_delegate touchesRangeViewEnd:self];
        }
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *aTouch = [touches anyObject];
    if (aTouch.tapCount == 1) {
        CGPoint p = [aTouch locationInView:self.superview];
        NSLog(@"**%s p:%f",__func__,p.x);

    }
}

- (CGRect) touchRectForHandle:(CGPoint) point
{
    float xPadding = 10;
    if(_canMoveLeft || _canMoveRight){
        xPadding = MAX(_leftHandle.frame.size.width, _rightHandle.frame.size.width);
    }
    CGRect touchRect = CGRectMake(point.x, point.y - 18, 10, self.frame.size.height);
    touchRect.origin.x -= xPadding/2.0;
    touchRect.size.width += xPadding;
    return touchRect;
}

- (void)dealloc{
    NSLog(@"%s",__func__);
    
    _leftHandle.image = nil;
    _rightHandle.image = nil;
    _middleHandle.image = nil;
    
    _tmpImage = nil;
    
    _file = nil;
}

@end
