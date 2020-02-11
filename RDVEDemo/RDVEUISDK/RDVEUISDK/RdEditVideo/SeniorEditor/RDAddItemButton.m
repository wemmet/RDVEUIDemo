//
//  RDAddItemButton.m
//  RDVEUISDK
//
//  Created by apple on 2019/10/10.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDAddItemButton.h"
#define kFxIconTag 1000

@interface RDAddItemButton()<CAAnimationDelegate>
{
    BOOL _isReStart;
    
}

@end

@implementation RDAddItemButton

+(RDAddItemButton *)initFXframe:(CGRect) rect atpercentage:(float) propor
{
    RDAddItemButton * fxItemBtn = [[RDAddItemButton alloc] initWithFrame:rect];
//    @property(nonatomic,strong)UIImageView *thumbnailIV;
    fxItemBtn.propor = propor;
    fxItemBtn.label = [[UILabel alloc] initWithFrame:CGRectMake(0, fxItemBtn.frame.size.height*propor, fxItemBtn.frame.size.width, fxItemBtn.frame.size.height*(1.0-propor))];
    fxItemBtn.label.textAlignment = NSTextAlignmentCenter;
    fxItemBtn.label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    fxItemBtn.label.font = [UIFont systemFontOfSize:12];
    [fxItemBtn addSubview:fxItemBtn.label];
    
    fxItemBtn.moveTitleLabel = [[UILabel alloc] initWithFrame:fxItemBtn.label.frame];
    fxItemBtn.moveTitleLabel.backgroundColor = [UIColor clearColor];
    fxItemBtn.moveTitleLabel.font = [UIFont systemFontOfSize:12];
    fxItemBtn.moveTitleLabel.textAlignment = NSTextAlignmentCenter;
    fxItemBtn.moveTitleLabel.hidden = YES;
    [fxItemBtn addSubview:fxItemBtn.moveTitleLabel];
    
    fxItemBtn.thumbnailIV = [[UIImageView alloc] initWithFrame:CGRectMake((fxItemBtn.frame.size.width  - fxItemBtn.frame.size.height*propor)/2.0, 0, fxItemBtn.frame.size.height*propor, fxItemBtn.frame.size.height*propor)];
    [fxItemBtn addSubview:fxItemBtn.thumbnailIV];
    fxItemBtn.thumbnailIV.layer.cornerRadius = 5;
    fxItemBtn.thumbnailIV.layer.masksToBounds = YES;
    fxItemBtn.thumbnailIV.layer.borderWidth = 1.0;
    fxItemBtn.thumbnailIV.layer.borderColor = [UIColor clearColor].CGColor;
    fxItemBtn.thumbnailIV.tag = kFxIconTag;
    
    fxItemBtn.userInteractionEnabled = YES;
    fxItemBtn.layer.masksToBounds = YES;
    
    return fxItemBtn;
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
    [self pauseLayer:_label.layer];
}
- (void)stopScrollTitle{
    _isReStart = NO;
    _moveTitleLabel.hidden = YES;
    _isStartMove = NO;
    [UIView setAnimationsEnabled:YES];
    [_label.layer removeAllAnimations];
    [_moveTitleLabel.layer removeAllAnimations];
    _label.frame = CGRectMake(0, self.frame.size.height*_propor, self.frame.size.width, self.frame.size.height*(1.0-_propor));
}

- (void)moveAction
{
    _moveTitleLabel.hidden = NO;
    _moveTitleLabel.text = _label.text;
    _moveTitleLabel.textColor = _label.textColor;
    _moveTitleLabel.font      = _label.font;
    
    CGRect rect = [_label.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, self.frame.size.height*(1.0-_propor)) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont fontWithName:_label.font.fontName size:_label.font.pointSize]} context:nil];
    CGRect fr = _label.frame;
    if(fr.size.width > rect.size.width + 20){
        [self stopScrollTitle];
        
        return;
    }
    
    
    CGRect beginItemRect = _label.frame;
    
    beginItemRect.size.width = rect.size.width+20;
    _label.frame = beginItemRect;
    
    _moveTitleLabel.frame = CGRectMake(beginItemRect.size.width+10, self.frame.size.height*_propor, beginItemRect.size.width, self.frame.size.height*(1.0-_propor));
    
    CGRect beginMoveRect = _moveTitleLabel.frame;
    CGRect itemEndRect = _label.frame;
    itemEndRect.origin.x = -(rect.size.width+30);
    
    CGRect moveTitleEndRect = _moveTitleLabel.frame;
    moveTitleEndRect.origin.x = 0;
    
    WeakSelf(self);
    [UIView animateWithDuration:beginMoveRect.size.width/20.0 animations:^{
        StrongSelf(self);
        if( strongSelf )
        {
            weakSelf.label.frame = itemEndRect;
            strongSelf->_moveTitleLabel.frame = moveTitleEndRect;
        }
    } completion:^(BOOL finished) {
        StrongSelf(self);
        if( strongSelf )
        {
            strongSelf.label.frame = beginItemRect;
            strongSelf->_moveTitleLabel.frame = beginMoveRect;
            if(strongSelf.isStartMove){
                [strongSelf moveAction];
            }else{
                strongSelf.label.frame = CGRectMake(0, self.frame.size.height*_propor, strongSelf.frame.size.width, self.frame.size.height*(1.0-_propor));
                
                strongSelf->_moveTitleLabel.frame = CGRectMake(strongSelf.frame.size.width, self.frame.size.height*_propor, strongSelf.frame.size.width, self.frame.size.height*(1.0-_propor));
                
            }
        }
    }];
}


- (void)dealloc{
//    NSLog(@"%s",__func__);
    [self stopScrollTitle];
    [_label removeFromSuperview];
    _label = nil;
    [_moveTitleLabel removeFromSuperview];
    _moveTitleLabel = nil;
    [_thumbnailIV removeFromSuperview];
    _thumbnailIV = nil;
    
    [_redDotImageView removeFromSuperview];
    _redDotImageView = nil;
}

-(void)textColor:(UIColor *) color
{
    _label.textColor = color;
    _moveTitleLabel.textColor = color;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
