//
//  RDMoveProgress.m
//  RDVEUISDK
//
//  Created by emmet on 15/10/13.
//  Copyright © 2015年 emmet. All rights reserved.
//

#import "RDMoveProgress.h"
@interface RDMoveProgress()

@property (nonatomic,strong)UIImageView *trackTintView;
@property (nonatomic,strong)UIImageView *progressView;

@end

@implementation RDMoveProgress

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        self.trackTintView= [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 0, frame.size.height)];
        if(self.trackTintColor){
            self.trackTintView.backgroundColor = self.trackTintColor;
        }
        if(self.trackImage){
            self.trackTintView.image = self.trackImage;
            self.trackTintView.contentMode = UIViewContentModeScaleToFill;
        } 
        self.trackTintView.layer.masksToBounds = YES;
        
        self.progressView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        self.progressView.backgroundColor = [UIColor clearColor];
        [self addSubview:self.progressView];
        [self addSubview:self.trackTintView];
        
        self.progressView.layer.cornerRadius = frame.size.height/2.0;
        self.trackTintView.layer.cornerRadius = frame.size.height/2.0;
        self.progressView.layer.masksToBounds = YES;
        self.trackTintView.layer.masksToBounds = YES;
        self.layer.cornerRadius = frame.size.height/2.0;
        self.layer.masksToBounds = YES;
        if(!self.backgroundColor){
            self.backgroundColor = [UIColor clearColor];
        }
    }
    return self;
}

- (void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    self.progressView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    self.trackTintView.frame = CGRectMake(0, 0, self.progress * self.frame.size.width , self.trackTintView.frame.size.height);
    self.progressView.layer.cornerRadius = frame.size.height/2.0;
    self.trackTintView.layer.cornerRadius = frame.size.height/2.0;
    self.progressView.layer.masksToBounds = YES;
    self.trackTintView.layer.masksToBounds = YES;
    self.layer.cornerRadius = frame.size.height/2.0;
    self.layer.masksToBounds = YES;
}

- (void)setProgress:(double)progress animated:(BOOL)animated{
    
    if(isnan(progress) || progress <=0){
        progress = 0.f;
    }
    self.progress = progress;
    
    float flag = animated ? 0.15:0.;
    [UIView animateWithDuration:flag animations:^{
        self.trackTintView.frame = CGRectMake(0, 0, progress * self.frame.size.width , self.trackTintView.frame.size.height);
    } completion:^(BOOL finished) {
        
    }];
}

- (void)setProgressImag:(UIImage *)progressImag{
    self.progressView.image = progressImag;
}

- (void)setProgressTintColor:(UIColor *)progressTintColor{

}

- (void)setTrackImage:(UIImage *)trackImage{
    if(self.trackImage){
        self.trackTintView.image = trackImage;
        self.trackTintView.contentMode = UIViewContentModeScaleToFill;
        self.trackTintView.alpha = 1.0;
    }
}

- (void)setTrackTintColor:(UIColor *)trackTintColor{
    if(trackTintColor){
        self.trackTintView.backgroundColor = trackTintColor;
        self.trackTintView.alpha = 1.0;

    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
//20170330
- (void)dealloc{
//    NSLog(@"%s",__func__);
}
@end
