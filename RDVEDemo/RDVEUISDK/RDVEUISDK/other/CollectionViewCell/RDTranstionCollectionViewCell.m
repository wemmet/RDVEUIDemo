//
//  RDTranstionCollectionViewCell.m
//  RDVEUISDK
//
//  Created by emmet on 16/2/25.
//  Copyright © 2016年 RDVEUISDK. All rights reserved.
//

#import "RDTranstionCollectionViewCell.h"

@interface RDTranstionCollectionViewCell()

@end
@implementation RDTranstionCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame{
    
    if(self = [super initWithFrame:frame]){
        [self initwithRect:frame];
    }
    return self;
}

- (void)initwithRect:(CGRect )rect{
    self.musicUrl = nil;
//    UIView *backView = [[UIView alloc] initWithFrame:rect];
//    backView.backgroundColor = [UIColor clearColor];//[RDHelpClass colorWithHexString:@"34333b"];
//    [self addSubview:backView];
    
    float fheight = rect.size.height;
    
//    backView.frame = CGRectMake((rect.size.width - fheight)/2, 0, fheight, rect.size.height);
    
    self.customImageView = [[UIImageView alloc] init];
    self.customImageView.frame = CGRectMake(0, 0, fheight*0.7, fheight*0.7);
    self.customImageView.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:0.0].CGColor;
    self.customImageView.layer.borderWidth = 1.0;
    self.customImageView.layer.cornerRadius = 5.0;
    self.customImageView.layer.masksToBounds = YES;
    self.customImageView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.customImageView];
    
    self.customDetailTextLabel = [[UILabel alloc] initWithFrame:rect];
    self.customDetailTextLabel.backgroundColor = [UIColor clearColor];
    self.customDetailTextLabel.font = [UIFont systemFontOfSize:13];
    self.customDetailTextLabel.frame = CGRectMake(0, fheight*0.7, rect.size.width, fheight*0.3);
    self.customDetailTextLabel.textAlignment= NSTextAlignmentCenter;
    self.customDetailTextLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    [self addSubview:self.customDetailTextLabel];
    
    self.moveTitleLabel = [[UILabel alloc] initWithFrame:self.customDetailTextLabel.frame];
    self.moveTitleLabel.backgroundColor = [UIColor clearColor];
    self.moveTitleLabel.font =  [UIFont systemFontOfSize:13];
    self.moveTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.moveTitleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    self.moveTitleLabel.hidden = YES;
    [self addSubview:self.moveTitleLabel];

//    if (iPhone4s) {
//        backView.frame = CGRectMake((rect.size.width - 40)/2, 0, 40, rect.size.height);
//        self.customImageView.frame = CGRectMake(0, 0, 40, 40);
//        self.customDetailTextLabel.frame = CGRectMake(0, 35, rect.size.width, 34);
//        self.moveTitleLabel.frame  =  CGRectMake(0, 35, rect.size.width, 34);
//    }
    
    self.userInteractionEnabled = YES;
    self.layer.masksToBounds = YES;
}

- (void)tapSelectedImage:(UITapGestureRecognizer *)gesture{
    if(_delegate){
        if([_delegate respondsToSelector:@selector(tapSelectedImage:)]){
            [_delegate tapSelectedImage:self];
        }
    }
}

- (void)setSelected:(BOOL)selected{
    [super setSelected:selected];
}
//- (void)dealloc{
////    NSLog(@"%s",__func__);
//}


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
    if (!_isStartMove) {
        [self stopScrollTitle];
        _isStartMove = YES;
        [self moveAction];
    }
}
- (void)pauseScrollTitle{
    _isStartMove = NO;
    [self pauseLayer:_customDetailTextLabel.layer];
}
- (void)stopScrollTitle{
    _isStartMove = NO;
    [UIView setAnimationsEnabled:YES];
    [_customDetailTextLabel.layer removeAllAnimations];
    [_moveTitleLabel.layer removeAllAnimations];
    _moveTitleLabel.hidden = YES;
    _customDetailTextLabel.frame = CGRectMake(0, _customDetailTextLabel.frame.origin.y, self.frame.size.width, _customDetailTextLabel.frame.size.height);
}

- (void)moveAction
{
    if( !_isStartMove ) {
        return;
    }
    _moveTitleLabel.hidden = NO;
    _moveTitleLabel.text = _customDetailTextLabel.text;
    _moveTitleLabel.textColor = _customDetailTextLabel.textColor;
    _moveTitleLabel.font      = _customDetailTextLabel.font;
    
    CGRect rect = [_customDetailTextLabel.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, _customDetailTextLabel.frame.size.height)
                                                            options:NSStringDrawingUsesLineFragmentOrigin
                                                         attributes:@{NSFontAttributeName : [UIFont fontWithName:_customDetailTextLabel.font.fontName size:_customDetailTextLabel.font.pointSize]}
                                                            context:nil];
//    if(rect.size.width < _customDetailTextLabel.frame.size.width){
//        [self stopScrollTitle];
//        return;
//    }
    CGRect beginItemRect = _customDetailTextLabel.frame;
    
    beginItemRect.size.width = rect.size.width+20;
    _customDetailTextLabel.frame = beginItemRect;

    _moveTitleLabel.frame = CGRectMake(beginItemRect.size.width+10, _customDetailTextLabel.frame.origin.y, beginItemRect.size.width, _customDetailTextLabel.frame.size.height);
    
    CGRect beginMoveRect = _moveTitleLabel.frame;
    CGRect itemEndRect = _customDetailTextLabel.frame;
    itemEndRect.origin.x = -(beginItemRect.size.width+10);
    
    CGRect moveTitleEndRect = _moveTitleLabel.frame;
    moveTitleEndRect.origin.x = 0;
    _customDetailTextLabel.frame = beginItemRect;
    
    _customDetailTextLabel.hidden = NO;
    _moveTitleLabel.hidden = NO;
    
    WeakSelf(self);
    [UIView animateWithDuration:beginMoveRect.size.width/20.0 animations:^{
        StrongSelf(self);
        if( strongSelf )
        {
            weakSelf.customDetailTextLabel.frame = itemEndRect;
            weakSelf.moveTitleLabel.frame = moveTitleEndRect;
        }
    } completion:^(BOOL finished) {
        StrongSelf(self);
        if( strongSelf )
        {
            strongSelf.customDetailTextLabel.frame = beginItemRect;
            strongSelf->_moveTitleLabel.frame = beginMoveRect;
            if(strongSelf.isStartMove){
                [strongSelf moveAction];
            }else{
                strongSelf.customDetailTextLabel.frame = CGRectMake(0, _customDetailTextLabel.frame.origin.y, strongSelf.frame.size.width, _customDetailTextLabel.frame.size.height);
                
                strongSelf->_moveTitleLabel.frame = CGRectMake(strongSelf.frame.size.width, _customDetailTextLabel.frame.origin.y, strongSelf.frame.size.width, _customDetailTextLabel.frame.size.height);
                
            }
        }
    }];
}


- (void)dealloc{
//    NSLog(@"%s",__func__);
    [self stopScrollTitle];
    [_customDetailTextLabel removeFromSuperview];
    _customDetailTextLabel = nil;
    [_moveTitleLabel removeFromSuperview];
    _moveTitleLabel = nil;
    
    _customImageView.image = nil;
    [_customImageView removeFromSuperview];
    _customImageView = nil;

    
    _selectImageView.image = nil;
    [_selectImageView removeFromSuperview];
    _selectImageView = nil;

    _delegate = nil;

    [_customDetailTextLabel removeFromSuperview];
    _customDetailTextLabel = nil;
    _isStartMove = NO;
}

-(void)delete
{
    [self stopScrollTitle];
    [_customDetailTextLabel removeFromSuperview];
    _customDetailTextLabel = nil;
    [_moveTitleLabel removeFromSuperview];
    _moveTitleLabel = nil;
    
    _customImageView.image = nil;
    [_customImageView removeFromSuperview];
    _customImageView = nil;

    
    _selectImageView.image = nil;
    [_selectImageView removeFromSuperview];
    _selectImageView = nil;

    _delegate = nil;

    [_customDetailTextLabel removeFromSuperview];
    _customDetailTextLabel = nil;
    _isStartMove = NO;
}

-(void)textColor:(UIColor *)color
{
    _customDetailTextLabel.textColor = color;
    _moveTitleLabel.textColor  = color;
}

@end
