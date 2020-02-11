//
//  RDExportProgressView.m
//  RDVEUISDK
//
//  Created by emmet on 2016/12/1.
//  Copyright © 2016年 RDVEUISDK. All rights reserved.
//

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#import "RDHelpClass.h"
#import "RDExportProgressView.h"
@interface RDExportProgressView()
{
    UIView *_childrensView;
    UILabel *_progressTitleLabel;
    UILabel *_trackprogressLabel;
    UIImageView *_trackbackGround;
    UIImageView *_trackprogress;
    float _progress;
}
@end
@implementation RDExportProgressView

- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
        
        CGRect childViewFrame = CGRectMake(40, (frame.size.height - 60)/2.0, frame.size.width - 80, 70);

        [self initChildrensView:childViewFrame];
        if(!self.backgroundColor){
            self.backgroundColor = [UIColor clearColor];
        }
        _canTouchUpCancel = NO;
    }
    return self;
}

- (void)initChildrensView:(CGRect )frame{
    _canTouchUpCancel = NO;
    _childrensView = [[UIView alloc] initWithFrame:frame];
    _childrensView.backgroundColor = [UIColor clearColor];
    [self addSubview:_childrensView];
    _progressTitleLabel= [[UILabel alloc] initWithFrame:CGRectMake(0,0, _childrensView.frame.size.width, 25)];
    _progressTitleLabel.textColor = [UIColor whiteColor];
    _progressTitleLabel.font = [UIFont systemFontOfSize:13];
    _progressTitleLabel.textAlignment = NSTextAlignmentCenter;
    _progressTitleLabel.text = RDLocalizedString(@"视频导出中，请耐心等待...", nil);
    
    _cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(_childrensView.frame.size.width - 44, (_childrensView.frame.size.height - 25 - 15 - 44)/2.0 + 25, 44, 44)];
    _cancelBtn.backgroundColor = [UIColor clearColor];
    _cancelBtn.imageEdgeInsets = UIEdgeInsetsMake((44-17)/2.0, (44-17)/2.0, (44-17)/2.0, (44-17)/2.0);
    [_cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/ProgressImage/进度取消默认_"] forState:UIControlStateNormal];
    //[_cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/ProgressImage/进度取消点击_"] forState:UIControlStateHighlighted];
    [_cancelBtn addTarget:self action:@selector(cancelExportAction) forControlEvents:UIControlEventTouchUpInside];
    
    _trackbackGround= [[UIImageView alloc] initWithFrame:CGRectMake(0, (_childrensView.frame.size.height - 25 - 15 - 4)/2.0 + 25, _cancelBtn.frame.origin.x - 20, 4)];
    if(_trackbackTintColor){
        _trackbackGround.backgroundColor = _trackbackTintColor;
    }
    if(_trackbackImage){
        _trackbackGround.image = _trackbackImage;
        _trackbackGround.contentMode = UIViewContentModeScaleAspectFill;
    }
    _trackbackGround.layer.masksToBounds = YES;
    
    _trackprogress = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, 0, _trackbackGround.frame.size.height)];
    _trackprogress.backgroundColor = [UIColor clearColor];
    if(_trackprogressTintColor){
        _trackbackGround.backgroundColor = _trackprogressTintColor;
    }
    if(_trackprogressImag){
        _trackprogress.image = _trackprogressImag;
        _trackprogress.contentMode = UIViewContentModeScaleAspectFill;
    }
    
    _trackprogressLabel= [[UILabel alloc] initWithFrame:CGRectMake(0, _childrensView.frame.size.height - 15, _childrensView.frame.size.width, 15)];
    _trackprogressLabel.textColor = [UIColor whiteColor];
    _trackprogressLabel.font = [UIFont systemFontOfSize:17];
    _trackprogressLabel.textAlignment = NSTextAlignmentCenter;
    _trackprogressLabel.text = @"0.0%";

    [_childrensView addSubview:_progressTitleLabel];
    [_childrensView addSubview:_trackbackGround];
    [_trackbackGround addSubview:_trackprogress];
    [_childrensView addSubview:_trackprogressLabel];
    [_childrensView addSubview:_cancelBtn];
    
    
    _trackbackGround.backgroundColor = UIColorFromRGB(0x888888);
    _trackprogress.backgroundColor = UIColorFromRGB(0xfed430);
    _trackbackGround.layer.cornerRadius = 2;
    _trackprogress.layer.cornerRadius = 2;
    _trackbackGround.layer.masksToBounds = YES;
    _trackprogress.layer.masksToBounds = YES;
}

- (void)setProgressTitle:(NSString *)progressTitle{
    _progressTitleLabel.text = progressTitle;

}
- (void)setProgress:(double)progress animated:(BOOL)animated{
    
    if(isnan(progress) || progress <0){
//        progress = 0.f;
        _trackprogressLabel.text = @"0.0%";
        return;
    }
    _progress = progress;
    
    float flag = animated ? 0.15:0.;
    dispatch_async(dispatch_get_main_queue(), ^{
        if(animated){
            [UIView animateWithDuration:flag animations:^{
                if(_trackprogressLabel){
                    _trackprogress.frame = CGRectMake(0, 0, progress/100.0 * _trackbackGround.frame.size.width , _trackbackGround.frame.size.height);
                    @try {
                        _trackprogressLabel.text = [NSString stringWithFormat:@"%.1f%%",_progress];
                    } @catch (NSException *exception) {
                        NSLog(@"exception:%@",exception);
                    }
                }
            } completion:^(BOOL finished) {
            }];
        }
        else{
            if(_trackprogressLabel){
                @try {
                    _trackprogress.frame = CGRectMake(0, 0, progress/100.0 * MAX(_trackbackGround.frame.size.width, 0) , _trackbackGround.frame.size.height);
                    _trackprogressLabel.text = [NSString stringWithFormat:@"%.1f%%",MAX(_progress, 0)];
                } @catch (NSException *exception) {
                    NSLog(@"exception:%@",exception);
                }
            }
        }
        
   });
}

- (void)setProgress2:(double)progress animated:(BOOL)animated{
    
    if(isnan(progress) || progress <=0){
        progress = 0.f;
        _trackprogressLabel.text = @"0.0%";
    }
    _progress = progress;
    
    float flag = animated ? 0.15:0.;
    if(animated){
        [UIView animateWithDuration:flag animations:^{
            if(_trackprogressLabel){
                _trackprogress.frame = CGRectMake(0, 0, progress/100.0 * _trackbackGround.frame.size.width , _trackbackGround.frame.size.height);
                @try {
                    _trackprogressLabel.text = [NSString stringWithFormat:@"%.1f%%",_progress];
                } @catch (NSException *exception) {
                    NSLog(@"exception:%@",exception);
                }
            }
        } completion:^(BOOL finished) {
        }];
    }
    else{
        if(_trackprogressLabel){
            @try {
                _trackprogress.frame = CGRectMake(0, 0, progress/100.0 * MAX(_trackbackGround.frame.size.width, 0) , _trackbackGround.frame.size.height);
                _trackprogressLabel.text = [NSString stringWithFormat:@"%.1f%%",MAX(_progress, 0)];
            } @catch (NSException *exception) {
                NSLog(@"exception:%@",exception);
            }
        }
    }
        
}

- (void)setTrackbackImage:(UIImage *)trackbackImage{
    if(_trackbackGround && trackbackImage){
        _trackbackGround.image = trackbackImage;
        _trackbackGround.contentMode = UIViewContentModeScaleAspectFill;
    }
}

- (void)setTrackbackTintColor:(UIColor *)trackbackTintColor{
    if(!_trackbackGround && trackbackTintColor){
        _trackbackGround.backgroundColor = trackbackTintColor;
    }
}

- (void)setTrackprogressImag:(UIImage *)trackprogressImag{
    if(_trackprogress && trackprogressImag){
        _trackprogress.image = trackprogressImag;
        _trackprogress.contentMode = UIViewContentModeScaleToFill;
    }
}

- (void)setTrackprogressTintColor:(UIColor *)trackprogressTintColor{
    if(!_trackprogress && trackprogressTintColor){
        _trackprogress.backgroundColor = trackprogressTintColor;
    }
}

- (void)cancelExportAction{
    if(_cancelBtn.selected){
        return;
    }
    if((isnan(_progress) || _progress <=0) && !_canTouchUpCancel){
        return;
    }
    //_cancelBtn.selected = YES;
    if(_cancelExportBlock){
        _cancelExportBlock();
    }
    
    //[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(cancelExportActionBlock) object:nil];
    //[self performSelector:@selector(cancelExportActionBlock) withObject:nil afterDelay:0.4];
}
- (void)cancelExportActionBlock{
    if(_cancelExportBlock){
        _cancelExportBlock();
    }
}

- (void)dismiss{
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview) withObject:nil];
    [self removeFromSuperview];
    
}

//20170330
- (void)dealloc{
    NSLog(@"%s",__func__);
}

@end
