//
//  LocalPhotoCell.m
//  RDVEUISDK
//
//  Created by emmet on 16/6/6.
//  Copyright © 2016年 RDVEUISDK. All rights reserved.
//

#import "LocalPhotoCell.h"
#import "RDHelpClass.h"
@implementation LocalPhotoCell

-(void)setIsPhoto:(BOOL)isPhoto
{
    NSString * str1 = nil;
    NSString * str2 = nil;
    if( isPhoto )
    {
        str1 = @"album/相册_图片";
        str2 = @"album/相册_图片";
    }
    else{
        str1 = @"album/相册_视频";
        str2 = @"album/相册_视频";
    }
    
    [_addBtn setImage:[RDHelpClass imageWithContentOfFile:str1] forState:UIControlStateNormal];
    [_addBtn setImage:[RDHelpClass imageWithContentOfFile:str2] forState:UIControlStateHighlighted];
    _duration.textAlignment = NSTextAlignmentLeft;
    //文字阴影
    //阴影颜色
    _duration.layer.shadowColor = [UIColor blackColor].CGColor;
    //阴影偏移量
    _duration.layer.shadowOffset = CGSizeMake(0, 1);
    //阴影不透明度
    _duration.layer.shadowOpacity = 0.5;
    //阴影半径
    _duration.layer.shadowRadius = 2;
    
    _durationBlack.backgroundColor = [UIColor colorWithWhite:0 alpha:0.0];
    
    
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _isAll  = false;
        self.bSelectHandle = NO;
        _isDownloadingInLocal = NO;
        // 加载nib
        _ivImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _ivImageView.backgroundColor = [UIColor clearColor];
        _ivImageView.contentMode = UIViewContentModeScaleAspectFill;
        _ivImageView.layer.masksToBounds = YES;
        
        _durationBlack = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height-20, frame.size.width, 20)];
        _durationBlack.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        
        _duration     = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, _durationBlack.frame.size.width - 10, 20)];
        _duration.backgroundColor = [UIColor clearColor];
        _duration.textAlignment = NSTextAlignmentRight;
        _duration.textColor = UIColorFromRGB(0xffffff);
        _duration.font = [UIFont systemFontOfSize:kWIDTH>320 ? 12 : 10];
        
        [_durationBlack addSubview:_duration];
        [_ivImageView addSubview:_durationBlack];
        [_ivImageView addSubview:_videoMark];
        _videoMark.alpha = 0;
        _videoMark.hidden = YES;
        [self addSubview:_ivImageView];
        _durationBlack.hidden = NO;
#if 0
        _videoMark = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width - 25 - 3, 3, 25, 25)];
        _videoMark.backgroundColor = UIColorFromRGB(0x0dc215);
        _videoMark.textColor = [UIColor whiteColor];
        _videoMark.font = [UIFont systemFontOfSize:18];
        _videoMark.layer.masksToBounds = YES;
        _videoMark.adjustsFontSizeToFitWidth = YES;
        _videoMark.layer.cornerRadius = 25/2.0;
        _videoMark.textAlignment = NSTextAlignmentCenter;
#else
        _addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _addBtn.frame = CGRectMake(frame.size.width - 40, 0, 40, 40);
        _addBtn.layer.cornerRadius = 20.0;
        _addBtn.layer.masksToBounds = YES;
        //2019 12 11 修改
//        [_addBtn setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_剪辑剪辑默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
//        [_addBtn setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_剪辑剪辑选中_@3x" Type:@"png"]] forState:UIControlStateHighlighted];
        [_addBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_添加默认_"] forState:UIControlStateNormal];
        [_addBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_添加点击_"] forState:UIControlStateHighlighted];
        [_addBtn addTarget:self action:@selector(addBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_addBtn];
#endif
        
        _progressView = [[CircleView alloc]initWithFrame:CGRectMake((frame.size.width - 30)/2.0, (frame.size.height - 30)/2.0, 30, 30)];
        _progressView.progressColor = Main_Color;
        _progressView.progressWidth = 5.f;
        [_progressView setPercent:0.0];
        _progressView.progressBackgroundColor = [UIColor clearColor];
        [self addSubview:_progressView];
        
        
        
        _icloudIcon = [[UIImageView alloc] initWithFrame:CGRectMake(5, frame.size.height - 20, 20, 20)];
        _icloudIcon.backgroundColor = [UIColor clearColor];
        _icloudIcon.image = [RDHelpClass imageWithContentOfFile:@"cloud_"];
        _icloudIcon.contentMode = UIViewContentModeScaleAspectFill;
        _icloudIcon.layer.masksToBounds = YES;
        _icloudIcon.hidden = YES;
        [self addSubview:_icloudIcon];
        
        _gifLbl = [[UILabel alloc] initWithFrame:CGRectMake(5, self.frame.size.height - 20, 25, 15)];
        _gifLbl.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
        _gifLbl.layer.borderColor = [UIColor whiteColor].CGColor;
        _gifLbl.layer.borderWidth = 1.0;
        _gifLbl.layer.cornerRadius = 3.0;
        _gifLbl.layer.masksToBounds = YES;
        _gifLbl.text = @"GIF";
        _gifLbl.textColor = [UIColor whiteColor];
        _gifLbl.textAlignment = NSTextAlignmentCenter;
        _gifLbl.font = [UIFont systemFontOfSize:10.0];
        _gifLbl.hidden = YES;
        [self addSubview:_gifLbl];
    }
    return self;
}

- (UILabel *)titleLbl {
    if (!_titleLbl) {
        _titleLbl = [[UILabel alloc] initWithFrame:self.bounds];
        _titleLbl.textColor = [UIColor whiteColor];
        _titleLbl.font = [UIFont systemFontOfSize:12.0];
        _titleLbl.textAlignment = NSTextAlignmentCenter;
        _titleLbl.numberOfLines = 0;
        [self addSubview:_titleLbl];
    }
    return _titleLbl;
}

- (void)setSelectMode:(BOOL)bSelect
{
#if 0
    self.bSelectHandle = bSelect;
    if (bSelect){
        _videoMark.hidden = NO;
        _ivImageView.layer.borderColor = [UIColor clearColor].CGColor;
        [UIView animateWithDuration:0.1 animations:^{
            _ivImageView.layer.borderWidth = 3;
            _ivImageView.alpha = 0.9;
            _videoMark.alpha = 1;
        } completion:^(BOOL finished) {
        }];
    }
    else{
        _ivImageView.layer.borderColor = [UIColor clearColor].CGColor;
        [UIView animateWithDuration:0.1 animations:^{
            _ivImageView.layer.borderWidth = 0;
            _videoMark.alpha = 0;
        } completion:^(BOOL finished) {
            _ivImageView.alpha = 1.0;
            _videoMark.hidden = YES;
        }];
        
    }
#endif
}

- (void)addBtnAction:(UIButton *)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(addVideo:)]) {
        [_delegate addVideo:self];
    }
}

- (void)dealloc{
//    NSLog(@"%s",__func__);
    
    
    
    if(_videoMark.superview)
        [_videoMark removeFromSuperview];
    if(_duration.superview)
        [_duration removeFromSuperview];
    if(_durationBlack.superview)
        [_durationBlack removeFromSuperview];
    if(_ivImageView.superview)
        [_ivImageView removeFromSuperview];
    _ivImageView.image = nil;
    _duration.text = nil;
    _videoMark = nil;
    _duration = nil;
    _durationBlack = nil;
    _ivImageView = nil;
    
}

-(void)setSelectedAnimation:(int) index
{
    if( !_animationView )
    {
        _animationView = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width/3.0, self.frame.size.height/3.0, self.frame.size.width/3.0, self.frame.size.height/3.0)];
        _animationView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
        
        [self addSubview:_animationView];
        
        _animationLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width/3.0, self.frame.size.height/3.0, self.frame.size.width/3.0, self.frame.size.height/3.0)];
        _animationLabel.textAlignment = NSTextAlignmentCenter;
        _animationLabel.font = [UIFont boldSystemFontOfSize:20];
        _animationLabel.textColor = [UIColor whiteColor];
        _animationLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:_animationLabel];
    }
    
    _animationLabel.hidden = NO;
    _animationView.hidden = NO;
    
    _animationLabel.text = [NSString stringWithFormat:@"%d",index];
    
    _animationView.frame = CGRectMake(self.frame.size.width/3.0, self.frame.size.height/3.0, self.frame.size.width/3.0, self.frame.size.height/3.0);
    
    [UIView animateWithDuration:0.25 animations:^{
       
        _animationView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        
    } completion:^(BOOL finished) {
        
        _animationView.hidden = YES;
        _animationLabel.hidden = YES;
        
    }];
}

@end
