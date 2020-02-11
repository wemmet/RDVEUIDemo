//
//  RDTouchButton.m
//  dyUIAPI
//
//  Created by emmet on 2017/6/8.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDTouchButton.h"

#define kRecordBtnColor UIColorFromRGB(0xfc1c8f)

@interface RDAnimationView : UIImageView
{
    CGRect  _origionFrame;
    BOOL    _stopAnimation;
    NSMutableArray *images;
}
@property (nonatomic,readonly,strong) UIImage *minImage;
@property (nonatomic,readonly,strong) UIImage *maxImage;
@end

@implementation RDAnimationView
- (UIImage *) imageWithCoverColor:(UIColor *)color Alpha:(float)alpha size:(CGSize)size LineWidth:(float)lineWidth
{
    
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat r = 0,g = 0,b = 0,a = 0;
    if(color){
        [color getRed:&r green:&g blue:&b alpha:&a];
    }
    
    //空心圆
    CGContextSetRGBStrokeColor(context, r, g, b, 1);
    CGContextSetLineWidth(context, lineWidth);
    CGContextAddArc(context, size.width/2.0, size.width/2.0, size.width/2.0 - 15/2.0-lineWidth/2, 0, 2*M_PI, 0);
    CGContextDrawPath(context, kCGPathStroke);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    
    if(self){
    
        self.layer.masksToBounds = YES;
        self.contentMode = UIViewContentModeScaleAspectFit;
        _origionFrame = frame;
        images = [NSMutableArray new];
        for (int i = 10; i<=25; i++) {
           UIImage *image = [self imageWithCoverColor:kRecordBtnColor Alpha:1.0 size:CGSizeMake(_origionFrame.size.width + 45, _origionFrame.size.height + 45) LineWidth:i];
            [images addObject:image];
            
        }
        for (int i = 25; i>=10; i--) {
            UIImage *image = [self imageWithCoverColor:kRecordBtnColor Alpha:1.0 size:CGSizeMake(_origionFrame.size.width + 45, _origionFrame.size.height + 45) LineWidth:i];
            [images addObject:image];
        }
        
        self.animationImages = images;
        self.animationDuration = 0.8;
        
        _minImage = [self imageWithCoverColor:kRecordBtnColor Alpha:1.0 size:CGSizeMake(_origionFrame.size.width, _origionFrame.size.height ) LineWidth:20];
        _maxImage = [self imageWithCoverColor:kRecordBtnColor Alpha:1.0 size:CGSizeMake(_origionFrame.size.width - 45, _origionFrame.size.height - 45) LineWidth:45];
    }
    
    return self;
}


- (void)startAnimation{
    [self startAnimating];
}

- (void)stopAnimation{
    [self stopAnimating];
}

@end

@interface RDTouchButton()<CAAnimationDelegate>{
    CGPoint    _touchBeginPoint;
    float      _difxSpan;
    float      _difySpan;
    BOOL       _animation;
    CGRect     _beginRecordRect;
    UIImage   *normalImage;
    UIImage   *hightImage;
    UIImage   *selectImage;
    UIImage   *disabledImage;
    
    RDAnimationView *_animationView;
    UIImageView     *_iconImageView;
    UIView          *defaultView;
}

@end
@implementation RDTouchButton

- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        _origionFrame = frame;
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.frame = CGRectMake((self.bounds.size.width - 82)/2.0, (self.bounds.size.height - 82)/2.0, 82, 82);
        _iconImageView.backgroundColor = [UIColor clearColor];
        [self addSubview:_iconImageView];
        
        defaultView = [[UIView alloc] initWithFrame:self.bounds];
        defaultView.layer.borderColor = [kRecordBtnColor colorWithAlphaComponent:0.5].CGColor;
        defaultView.layer.borderWidth = 6.0;
        defaultView.layer.cornerRadius = frame.size.height/2.0;
        [self addSubview:defaultView];
        
        UIView *centerView = [[UIView alloc] initWithFrame:CGRectMake((frame.size.width - 64)/2.0, (frame.size.width - 64)/2.0, 64, 64)];
        centerView.backgroundColor = kRecordBtnColor;
        centerView.layer.cornerRadius = 32.0;
        [defaultView addSubview:centerView];
    }
    
    return self;
}


- (void)setOrigionFrame:(CGRect)origionFrame{
    _origionFrame = origionFrame;
    self.frame = _origionFrame;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    float scale = 3;
    _beginRecordRect  = CGRectMake(self.frame.origin.x - ((24 * scale)/2.0), self.frame.origin.y - ((24 * scale)/2.0), 82+(24 * scale), 82+(24 * scale));
    self.frame = _beginRecordRect;
    UITouch *aTouch = [touches anyObject];
    NSLog(@"%s", __func__);
    [self setImage:nil forState:UIControlStateNormal];
    _animation = YES;
    _iconImageView.alpha = 0.0;
    _touchBeginPoint = [aTouch locationInView:self.superview];
    _difxSpan = _touchBeginPoint.x - self.frame.origin.x;
    _difySpan = _touchBeginPoint.y - self.frame.origin.y;
    [self startAnimation];
    if(_delegate){
        if([_delegate respondsToSelector:@selector(touchesRDTouchButtonBegin:)]){
            [_delegate touchesRDTouchButtonBegin:self];
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *aTouch = [touches anyObject];
    CGPoint p = [aTouch locationInView:self.superview];

    if(self.superview){
        if(_animation){
            self.frame = CGRectMake(p.x - _difxSpan, p.y - _difySpan, self.frame.size.width, self.frame.size.height);
            if(_delegate){
                if([_delegate respondsToSelector:@selector(touchesRDTouchButtonMoving:)]){
                    [_delegate touchesRDTouchButtonMoving:self];
                }
            }
        }
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if(_delegate){
        if([_delegate respondsToSelector:@selector(touchesRDTouchButtonEnd:)]){
            [_delegate touchesRDTouchButtonEnd:self];
        }
    }
    [self stopAnimation:YES];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if(_delegate){
        if([_delegate respondsToSelector:@selector(touchesRDTouchButtonEnd:)]){
            [_delegate touchesRDTouchButtonEnd:self];
        }
    }
    [self stopAnimation:YES];    
}

- (void)startAnimation{
    defaultView.hidden = YES;
    if(!_animationView){
        _animationView = [[RDAnimationView alloc] initWithFrame:self.bounds];
        [self insertSubview:_animationView atIndex:0];
        [_animationView startAnimating];
    }
}
- (void)stopAnimation{
   _animation = NO;
    [self stopAnimation:NO];
}

- (void)stopAnimation:(BOOL)animation{
     NSLog(@"%s  line:%d",__func__,__LINE__);
   _iconImageView.alpha = 1.0;
    defaultView.hidden = NO;
    if(animation){
        
        [_animationView stopAnimating];
        _animationView.animationImages = nil;
        _animationView.image = _animationView.maxImage;
        [UIView animateWithDuration:0.2 animations:^{
            self.frame = _beginRecordRect;
            _animationView.frame = CGRectMake((self.bounds.size.width - 82)/2.0, (self.bounds.size.height - 82)/2.0, 82, 82);
        } completion:^(BOOL finished) {
            self.frame = _origionFrame;

            if(_animationView){
                [_animationView removeFromSuperview];
                _animationView = nil;
            }
        }];
        
    }else{
        self.frame = _origionFrame;

        if(_animationView){
            [_animationView stopAnimating];
            [_animationView removeFromSuperview];
            _animationView = nil;
        }
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    [_animationView.layer removeAnimationForKey:@"scale"];
    if(_animationView){
        [_animationView removeFromSuperview];
        _animationView = nil;
    }
    
    if(_delegate){
        if([_delegate respondsToSelector:@selector(touchesRDTouchButtonEnd:)]){
            [_delegate touchesRDTouchButtonEnd:self];
        }
    }
}
@end
