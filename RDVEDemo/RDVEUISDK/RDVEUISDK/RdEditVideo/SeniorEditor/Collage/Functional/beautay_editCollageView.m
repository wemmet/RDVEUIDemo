//
//  beautay_editCollageView.m
//  RDVEUISDK
//
//  Created by apple on 2020/1/8.
//  Copyright © 2020 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "beautay_editCollageView.h"

@interface beautay_editCollageView ()
{
    
}

@end

@implementation beautay_editCollageView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if ( self )
    {
        self.backgroundColor = TOOLBAR_COLOR;
        
        self.beautyView.hidden = NO;
        [self addSubview:self.beautyView];
        
    }
    return self;
}

#pragma mark- 美颜
-(void)beautyClose_Btn
{
    if (_delegate && [_delegate respondsToSelector:@selector(hiddenCollageBarItem: isSave:)]) {
        [_delegate hiddenCollageBarItem:kPIP_BEAUTY isSave:NO];
    }
}
-(void)beautyConfirm_Btn
{
    if (_delegate && [_delegate respondsToSelector:@selector(hiddenCollageBarItem: isSave:)]) {
        [_delegate hiddenCollageBarItem:kPIP_BEAUTY isSave:YES];
    }
}
-(UIView *)beautyView
{
    if( !_beautyView )
    {
        _beautyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0  , self.bounds.size.width, self.bounds.size.height)];
        _beautyView.backgroundColor = TOOLBAR_COLOR;
        
        [self addSubview:_beautyView];
        
        self.beautyProgressSlider.hidden = NO;
        
        _beautyCloseBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, _beautyView.frame.size.height - kToolbarHeight, 44, 44)];
        [_beautyCloseBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
        [_beautyCloseBtn addTarget:self action:@selector(beautyClose_Btn) forControlEvents:UIControlEventTouchUpInside];
        [_beautyView addSubview:_beautyCloseBtn];
        
        _beautyConfirmBtn = [[UIButton alloc] initWithFrame:CGRectMake(kWIDTH - 44, _beautyView.frame.size.height - kToolbarHeight, 44, 44)];
        [_beautyConfirmBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
        [_beautyConfirmBtn addTarget:self action:@selector(beautyConfirm_Btn) forControlEvents:UIControlEventTouchUpInside];
        [_beautyView addSubview:_beautyConfirmBtn];
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(44, _beautyView.frame.size.height - kToolbarHeight + ( 44 - 44 )/2.0, kWIDTH - 44 * 2, 44)];
        label.text = RDLocalizedString(@"美颜", nil);
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        label.font = [UIFont boldSystemFontOfSize:17.0];
        [_beautyView addSubview:label];
    }
    return _beautyView;
}

- (RDZSlider *)beautyProgressSlider{
    if(!_beautyProgressSlider){
        
        
        _beautyProgressSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(50, 0.240*(_beautyView.frame.size.height - kToolbarHeight) + ( ( (_beautyView.frame.size.height - kToolbarHeight)*0.760 ) - 30 )/2.0  , kWIDTH - 50 - 50, 30)];
        
        _beautyCurrentLabel = [[UILabel alloc] init];
        _beautyCurrentLabel.frame = CGRectMake(0, _beautyProgressSlider.frame.origin.y - 25, 50, 20);
        _beautyCurrentLabel.textAlignment = NSTextAlignmentCenter;
        _beautyCurrentLabel.textColor = Main_Color;
        _beautyCurrentLabel.font = [UIFont systemFontOfSize:12];
        
        float percent = _beautyProgressSlider.value *100.0;
        _beautyCurrentLabel.text = [NSString stringWithFormat:@"%d", (int)percent];
        [_beautyView addSubview:_beautyCurrentLabel];
        _beautyCurrentLabel.hidden = YES;

        
        _beautyProgressSlider.layer.cornerRadius = 2.0;
        _beautyProgressSlider.layer.masksToBounds = YES;
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [_beautyProgressSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_beautyProgressSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [_beautyProgressSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"]  forState:UIControlStateNormal];
        [_beautyProgressSlider setValue:0];
        _beautyProgressSlider.alpha = 1.0;
        _beautyProgressSlider.backgroundColor = [UIColor clearColor];
        [_beautyProgressSlider addTarget:self action:@selector(beautyBeginScrub) forControlEvents:UIControlEventValueChanged];
        [_beautyProgressSlider addTarget:self action:@selector(beautyEndScrub) forControlEvents:UIControlEventTouchUpInside];
        [_beautyProgressSlider addTarget:self action:@selector(beautyEndScrub) forControlEvents:UIControlEventTouchCancel];
        [_beautyView addSubview:_beautyProgressSlider];
    }
    return _beautyProgressSlider;
}
//透明度 滑动进度条
- (void)beautyBeginScrub{
    _beautyCurrentLabel.hidden = NO;
    [self setBeauty];
}

- (void)beautyEndScrub{
    _beautyCurrentLabel.hidden = YES;
    [self setBeauty];
}

- (void)setBeauty
{
    CGFloat current = _beautyProgressSlider.value;
    float percent = current * 100;
    _beautyCurrentLabel.frame = CGRectMake(current*_beautyProgressSlider.frame.size.width+_beautyProgressSlider.frame.origin.x - _beautyCurrentLabel.frame.size.width/2.0, _beautyCurrentLabel.frame.origin.y, _beautyCurrentLabel.frame.size.width, _beautyCurrentLabel.frame.size.height);
    _beautyCurrentLabel.text = [NSString stringWithFormat:@"%d",(int)percent];
    
    if( self.currentCollage )
    {
        self.currentCollage.vvAsset.beautyBlurIntensity = current;
        [_videoCoreSDK refreshCurrentFrame];
    }
}

-(void)ImageRef
{
    [_videoCoreSDK getImageWithTime:CMTimeMake(0.2, TIMESCALE) scale:1.0 completionHandler:^(UIImage *image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _pasterView.contentImage.image = nil;
            _pasterView.contentImage.image = image;
        });
    }];
}

-(void)dealloc
{
    if( _beautyView )
    {
        [_beautyProgressSlider removeFromSuperview];
        _beautyProgressSlider = nil;
        [_beautyCurrentLabel removeFromSuperview];
        _beautyCurrentLabel = nil;
        [_beautyCloseBtn removeFromSuperview];
        _beautyCloseBtn = nil;
        [_beautyConfirmBtn removeFromSuperview];
        _beautyConfirmBtn = nil;
        
        [_beautyView removeFromSuperview];
        _beautyView = nil;
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
