//
//  ScrollViewChildItem.m
//  RDVEUISDK
//
//  Created by emmet on 16/10/23.
//  Copyright © 2016年 RDVEUISDK. All rights reserved.
//

#import "ScrollViewChildItem.h"
@interface ScrollViewChildItem()<UIGestureRecognizerDelegate,CAAnimationDelegate>{
    UITapGestureRecognizer *_gesture;
    BOOL _isReStart;
    UILabel *_moveTitleLabel;
}
@end

@implementation ScrollViewChildItem
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        _isVoiceFX = false;
        _isSwitchMuisc = false;
        _isMuisc = false;
        _cornerRadius = 15.0;
        _itemIconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.width)];
        _itemIconView.layer.cornerRadius = _cornerRadius;
        _itemIconView.layer.masksToBounds = YES;
        _itemIconView.userInteractionEnabled = YES;
        
        _itemTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, frame.size.width, frame.size.width, 20)];
        _itemTitleLabel.backgroundColor = [UIColor clearColor];
        _itemTitleLabel.font = [UIFont systemFontOfSize:_fontSize>0?_fontSize:14];
        _itemTitleLabel.textAlignment = NSTextAlignmentCenter;
        _isStartMove = NO;
        
        _moveTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width, frame.size.width, frame.size.width, 20)];
        _moveTitleLabel.backgroundColor = [UIColor clearColor];
        _moveTitleLabel.font = [UIFont systemFontOfSize:_fontSize>0?_fontSize:14];
        _moveTitleLabel.textAlignment = NSTextAlignmentCenter;
        
        

        self.userInteractionEnabled = YES;
        self.layer.masksToBounds = YES;
        _gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapgesture:)];
        _downloading = NO;
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self addSubview:_itemIconView];
            [self addSubview:_itemTitleLabel];
            [self addSubview:_moveTitleLabel];
            
            [self addGestureRecognizer:_gesture];
        });
        
     }
    return self;
}

- (void)moveAction
{
    _moveTitleLabel.hidden = NO;
    _moveTitleLabel.text = _itemTitleLabel.text;
    _moveTitleLabel.textColor = _itemTitleLabel.textColor;
    _moveTitleLabel.font      = _itemTitleLabel.font;
    
    CGRect rect = [_itemTitleLabel.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 40) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont fontWithName:_itemTitleLabel.font.fontName size:_itemTitleLabel.font.pointSize]} context:nil];
    CGRect fr = _itemTitleLabel.frame;
    if(fr.size.width > rect.size.width + 20){
        [self stopScrollTitle];
        
        return;
    }
    
    
    CGRect beginItemRect = _itemTitleLabel.frame;
    
    beginItemRect.size.width = rect.size.width+20;
    _itemTitleLabel.frame = beginItemRect;
    
    _moveTitleLabel.frame = CGRectMake(beginItemRect.size.width+10, self.frame.size.width, beginItemRect.size.width, 20);

    CGRect beginMoveRect = _moveTitleLabel.frame;
    CGRect itemEndRect = _itemTitleLabel.frame;
    itemEndRect.origin.x = -(rect.size.width+30);
    
    CGRect moveTitleEndRect = _moveTitleLabel.frame;
    moveTitleEndRect.origin.x = 0;
    
    WeakSelf(self);
    [UIView animateWithDuration:beginMoveRect.size.width/20.0 animations:^{
        StrongSelf(self);
        if( strongSelf )
        {
            weakSelf.itemTitleLabel.frame = itemEndRect;
            strongSelf->_moveTitleLabel.frame = moveTitleEndRect;
        }
    } completion:^(BOOL finished) {
        StrongSelf(self);
        if( strongSelf )
        {
            strongSelf.itemTitleLabel.frame = beginItemRect;
            strongSelf->_moveTitleLabel.frame = beginMoveRect;
            if(strongSelf.isStartMove){
                [strongSelf moveAction];
            }else{
                strongSelf.itemTitleLabel.frame = CGRectMake(0, strongSelf.frame.size.width, strongSelf.frame.size.width, 20);
                
                strongSelf->_moveTitleLabel.frame = CGRectMake(strongSelf.frame.size.width, strongSelf.frame.size.width, strongSelf.frame.size.width, 20);
                
            }
        }
    }];
    
    
//TODO:20170612 emmet 用下面这种方式执行动画时间长了就会卡死
//    fr.size.width = rect.size.width + 20;
//    fr.origin.x = self.frame.size.width;
//    _itemTitleLabel.frame = fr;
//    //self.frame.size.width +
//    CGPoint fromPoint = CGPointMake(_itemTitleLabel.frame.size.width/2, _itemTitleLabel.frame.origin.y + _itemTitleLabel.frame.size.height/2.0);
//    
//    UIBezierPath *movePath = [UIBezierPath bezierPath];
//    [movePath moveToPoint:fromPoint];
//    [movePath addLineToPoint:CGPointMake(-_itemTitleLabel.frame.size.width, _itemTitleLabel.frame.origin.y + _itemTitleLabel.frame.size.height/2.0)];
//    
//    CAKeyframeAnimation *moveAnim = [CAKeyframeAnimation animationWithKeyPath:@"position"];
//    moveAnim.path = movePath.CGPath;
//    moveAnim.removedOnCompletion = NO;
//    
//    moveAnim.duration = _itemTitleLabel.frame.size.width * 8 * 0.01;
//    [moveAnim setDelegate:self];
//    
//    [_itemTitleLabel.layer addAnimation:moveAnim forKey:nil];
//    
//    fr = _moveTitleLabel.frame;
//    fr.size.width = (rect.size.width + 20) *2;
//    fr.origin.x = self.frame.size.width*2;
//    _moveTitleLabel.frame = fr;
//    
//    fromPoint = CGPointMake(self.frame.size.width + _moveTitleLabel.frame.size.width/2, _moveTitleLabel.frame.origin.y + _moveTitleLabel.frame.size.height/2.0);
//    
//    movePath = [UIBezierPath bezierPath];
//    [movePath moveToPoint:fromPoint];
//    [movePath addLineToPoint:CGPointMake(0, _moveTitleLabel.frame.origin.y + _moveTitleLabel.frame.size.height/2.0)];
//    
//    CAKeyframeAnimation *moveAnim1 = [CAKeyframeAnimation animationWithKeyPath:@"position"];
//    moveAnim1.path = movePath.CGPath;
//    moveAnim1.removedOnCompletion = NO;
//    
//    moveAnim1.duration = _itemTitleLabel.frame.size.width * 8 * 0.01;
//    [moveAnim1 setDelegate:self];
//    
//    [_moveTitleLabel.layer addAnimation:moveAnim1 forKey:nil];
    
}

-(void)pauseLayer:(CALayer*)layer
{
    CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
    layer.speed = 0.0;
    layer.timeOffset = pausedTime;
}

-(void)resumeLayer:(CALayer*)layer
{
    CFTimeInterval pausedTime = layer.timeOffset;
    layer.speed = 1.0;
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime = timeSincePause;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    if (flag) {
        [self moveAction];
    }
}

- (void)startScrollTitle{
    [self stopScrollTitle];
    _isStartMove = YES;
    _isReStart = YES;
    [self moveAction];
}
- (void)pauseScrollTitle{
    _isReStart = YES;
    _isStartMove = NO;
    [self pauseLayer:_itemTitleLabel.layer];
}
- (void)stopScrollTitle{
    _isReStart = NO;
    _moveTitleLabel.hidden = YES;
    _isStartMove = NO;
    [UIView setAnimationsEnabled:YES];
    [_itemTitleLabel.layer removeAllAnimations];
    [_moveTitleLabel.layer removeAllAnimations];
    _itemTitleLabel.frame = CGRectMake(0, self.frame.size.width, self.frame.size.width, 20);
}

- (void)restartMoveTitle{
    //[self resumeLayer:_itemTitleLabel.layer];
}

- (CGRect )getIconFrame{
    return _itemIconView.frame;
}

- (void)tapgesture:(UITapGestureRecognizer *)gesture{
    if(self.delegate){
        [self.delegate scrollViewChildItemTapCallBlock:self];
    }
}
- (void)setCornerRadius:(float)cornerRadius{
    _cornerRadius = cornerRadius;
    _itemIconView.layer.cornerRadius = _cornerRadius;
    [self setNeedsDisplay];
}

- (void)setFontSize:(float)fontSize{
    _fontSize = fontSize;
//    if(iPhone4s){
//        _fontSize = 10;
//    }
    _itemTitleLabel.font = [UIFont systemFontOfSize:_fontSize>0?_fontSize:14];
    [self setNeedsDisplay];
}

- (void)setSelected:(BOOL)selected{
    if(selected){
        _itemIconView.layer.borderColor = _selectedColor?_selectedColor.CGColor:[UIColor greenColor].CGColor;
        _itemIconView.layer.borderWidth = 1.0;
        _itemTitleLabel.textColor = [UIColor whiteColor];
        if( _isVoiceFX )
        {
            _itemTitleLabel.textColor = [UIColor whiteColor];
            _itemIconView.backgroundColor = SCREEN_BACKGROUND_COLOR;
        }
        
        if(  _isMuisc )
        {
            _itemTitleLabel.textColor = [UIColor whiteColor];
            if( !_isSwitchMuisc )
            {
                _itemIconselectedView.layer.borderColor = _selectedColor?_selectedColor.CGColor:[UIColor greenColor].CGColor;
                _itemIconselectedView.layer.borderWidth = 1.0;
            }
            _itemIconselectedView.hidden = NO;
            _itemIconView.hidden = YES;
        }
        
    }else{
        
        _itemIconView.layer.borderColor = [UIColor clearColor].CGColor;
        _itemIconView.layer.borderWidth = 0.0;
        _itemTitleLabel.textColor = _normalColor? _normalColor:[UIColor whiteColor];
        
        if( _isVoiceFX )
        {
            _itemTitleLabel.textColor = [UIColor whiteColor];
            _itemIconView.backgroundColor = UIColorFromRGB(0x333333);
        }
        
        if(  _isMuisc )
        {
            _itemTitleLabel.textColor = UIColorFromRGB(0x666666);
            _itemIconselectedView.hidden = YES;
            _itemIconView.hidden = NO;
        }
    }
}
- (void)dealloc{
//    NSLog(@"%s",__func__);
    [self stopScrollTitle];
    [_itemTitleLabel removeFromSuperview];
    _itemTitleLabel = nil;
    [_moveTitleLabel removeFromSuperview];
    _moveTitleLabel = nil;
    [_itemIconView removeFromSuperview];
    _itemIconView = nil;
    [self removeGestureRecognizer:_gesture];
    _gesture = nil;
}
@end
