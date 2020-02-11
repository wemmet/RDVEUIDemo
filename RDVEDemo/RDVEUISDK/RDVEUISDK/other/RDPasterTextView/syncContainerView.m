//
//  syncContainerView.m
//  RDVEUISDK
//
//  Created by apple on 2020/1/13.
//  Copyright © 2020 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "syncContainerView.h"
#import "RDPasterTextView.h"

@implementation syncContainerView

- (void)pinchGestureRecognizer:(UIPinchGestureRecognizer *)recognizer
{
    if( _currentPasterTextView )
    {
        RDPasterTextView * PasterText = (RDPasterTextView *)_currentPasterTextView;
        [PasterText pinchGestureRecognizer:recognizer];
    }
}

-(void)pasterMidline:(UIView *) PasterTextView isHidden:(bool) ishidden
{
    RDPasterTextView * PasterText = (RDPasterTextView *)PasterTextView;
    
    float interval = 2.5;
    
    float width = 30;
    float height = 3;
    
    if( !ishidden && self )
    {
        float x = self.frame.size.width/2.0;
        float y = self.frame.size.height/2.0;
        
        CGPoint center = PasterText.center;
        
        if( ( center.x >= ( x - interval ) ) && ( center.x <= ( x + interval ) )  )
        {
            
            if( !_syncContainer_X_Left )
            {
                _syncContainer_X_Left = [[UIImageView alloc] initWithFrame:CGRectMake((self.frame.size.width - height)/2.0, 0, height, width)];
                _syncContainer_X_Left.backgroundColor = UIColorFromRGB(0xffffff);
                _syncContainer_X_Left.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
                _syncContainer_X_Left.layer.borderWidth = 0.5;
                [self addSubview:_syncContainer_X_Left];
                
                _syncContainer_X_Right = [[UIImageView alloc] initWithFrame:CGRectMake((self.frame.size.width - height)/2.0, self.frame.size.height - width, height, width)];
                _syncContainer_X_Right.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
                _syncContainer_X_Right.layer.borderWidth = 0.5;
                _syncContainer_X_Right.backgroundColor = UIColorFromRGB(0xffffff);
                [self addSubview:_syncContainer_X_Right];
            }
            
            _syncContainer_X_Right.hidden = NO;
            _syncContainer_X_Left.hidden = NO;
        }
        else
        {
            _syncContainer_X_Right.hidden = YES;
            _syncContainer_X_Left.hidden = YES;
        }
        
        if( ( center.y >= ( y - interval ) ) && ( center.y <= ( y + interval ) )  )
        {
            if( !_syncContainer_Y_Left )
            {
                _syncContainer_Y_Left = [[UIImageView alloc] initWithFrame:CGRectMake(0, (self.frame.size.height - height)/2.0, width, height)];
                _syncContainer_Y_Left.backgroundColor = UIColorFromRGB(0xffffff);
                _syncContainer_Y_Left.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
                _syncContainer_Y_Left.layer.borderWidth = 0.5;
                [self addSubview:_syncContainer_Y_Left];
                
                _syncContainer_Y_Right = [[UIImageView alloc] initWithFrame:CGRectMake( self.frame.size.width - width,  (self.frame.size.height - height)/2.0, width, height)];
                _syncContainer_Y_Right.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
                _syncContainer_Y_Right.layer.borderWidth = 0.5;
                _syncContainer_Y_Right.backgroundColor = UIColorFromRGB(0xffffff);
                [self addSubview:_syncContainer_Y_Right];
            }
            
            _syncContainer_Y_Right.hidden = NO;
            _syncContainer_Y_Left.hidden = NO;
        }
        else{
            _syncContainer_Y_Right.hidden = YES;
            _syncContainer_Y_Left.hidden = YES;
        }
    }
    else{
        if( _syncContainer_Y_Right )
        {
            _syncContainer_Y_Right.hidden = YES;
            _syncContainer_Y_Left.hidden = YES;
        }
        if( _syncContainer_X_Right )
        {
            _syncContainer_X_Right.hidden = YES;
            _syncContainer_X_Left.hidden = YES;
        }
    }
}

-(void)setMark
{
    if( _syncContainer_X_Left )
    {
        [self addSubview:_syncContainer_Y_Left];
        [self addSubview:_syncContainer_Y_Right];
        
        [self addSubview:_syncContainer_X_Left];
        [self addSubview:_syncContainer_X_Right];
    }
    UIPinchGestureRecognizer *GestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureRecognizer:)];
    
    [self addGestureRecognizer:GestureRecognizer];
}

- (void)dealloc{

    if( _syncContainer_Y_Right )
    {
        [_syncContainer_Y_Right removeFromSuperview];
        _syncContainer_Y_Right = nil;
        
        [_syncContainer_Y_Left removeFromSuperview];
        _syncContainer_Y_Left = nil;
        
        [_syncContainer_X_Right removeFromSuperview];
        _syncContainer_X_Right = nil;
        
        [_syncContainer_X_Left removeFromSuperview];
        _syncContainer_X_Left = nil;
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
