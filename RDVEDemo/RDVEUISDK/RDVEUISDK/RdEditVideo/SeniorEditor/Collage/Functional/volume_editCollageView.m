//
//  volume_editCollageView.m
//  RDVEUISDK
//
//  Created by apple on 2020/1/8.
//  Copyright © 2020 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "volume_editCollageView.h"

@interface volume_editCollageView ()
{
    UIView              *assetVolumeView;
    UILabel             *fadeDurationLbel;
    
    //音量
    float               volumeMultipleM;
    CMTime              fadeInOrfadeOutTime;
}

@end

@implementation volume_editCollageView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if ( self )
    {
        volumeMultipleM = 2.0;
        self.backgroundColor = TOOLBAR_COLOR;
        
        self.volumeView.hidden = NO;
        [self addSubview:self.volumeView];
    }
    return self;
}

#pragma mark- 音量
- (void)vloumeAllBtnOnClick:(UIButton *)sender{
    sender.selected = !sender.selected;
}

-( UIView *)volumeView
{
    if(!_volumeView )
    {
        _volumeView = [UIView new];
        _volumeView.frame = CGRectMake(0, 0  , self.bounds.size.width, self.bounds.size.height);
        _volumeView.backgroundColor = TOOLBAR_COLOR;
        
        _vloume_navagatio_View = [[UIView alloc] init];
        _vloume_navagatio_View.frame = CGRectMake(_volumeView.frame.size.width*(1.0-0.426)/2.0, (_volumeView.frame.size.height - kToolbarHeight)*0.24  + ( (_volumeView.frame.size.height - kToolbarHeight)*( 1.0 - 0.24 - 0.194 ) - 30 )/4.0, _volumeView.frame.size.width*0.426, (_volumeView.frame.size.height - kToolbarHeight)*0.194);
        _vloume_navagatio_View.layer.borderColor = [UIColor colorWithWhite:1 alpha:1].CGColor;
        _vloume_navagatio_View.layer.borderWidth = 1;
        _vloume_navagatio_View.layer.masksToBounds = YES;
        _vloume_navagatio_View.layer.cornerRadius = 5;
        [_volumeView addSubview:_vloume_navagatio_View];
        
        self.vloumeBtn.hidden = NO;
        self.fadeInOrOutBtn.hidden = NO;
        
        assetVolumeView = [[UIView alloc] initWithFrame:CGRectMake(0, (_volumeView.frame.size.height - kToolbarHeight)*(  0.24 + 0.194 ) + ( (_volumeView.frame.size.height - kToolbarHeight)*( 1.0 - 0.24 - 0.194 ) - 30 )/2.0, kWIDTH, 30)];
        [_volumeView addSubview:assetVolumeView];
        
        UILabel * VolumeLabel = [UILabel new];
        VolumeLabel.frame = CGRectMake(40, 0, 60, 30);
        VolumeLabel.textAlignment = NSTextAlignmentCenter;
        VolumeLabel.backgroundColor = [UIColor clearColor];
        VolumeLabel.font = [UIFont systemFontOfSize:14];
        VolumeLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        VolumeLabel.text = RDLocalizedString(@"音量", nil);
        
        [assetVolumeView addSubview:VolumeLabel];
        [assetVolumeView addSubview:self.volumeProgressSlider];
        
        _volumeCloseBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, _volumeView.frame.size.height - kToolbarHeight, 44, 44)];
        [_volumeCloseBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
        [_volumeCloseBtn addTarget:self action:@selector(volumeClose_Btn) forControlEvents:UIControlEventTouchUpInside];
        [_volumeView addSubview:_volumeCloseBtn];
        
        _volumeConfirmBtn = [[UIButton alloc] initWithFrame:CGRectMake(kWIDTH - 44, _volumeView.frame.size.height - kToolbarHeight, 44, 44)];
        [_volumeConfirmBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
        [_volumeConfirmBtn addTarget:self action:@selector(volumeConfirm_Btn) forControlEvents:UIControlEventTouchUpInside];
        [_volumeView addSubview:_volumeConfirmBtn];
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(44, _volumeView.frame.size.height - kToolbarHeight + ( 44 - 44 )/2.0, kWIDTH - 44 * 2, 44)];
        label.text = RDLocalizedString(@"音量", nil);
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        label.font = [UIFont boldSystemFontOfSize:17];
        [_volumeView addSubview:label];
        
        _vloumeCurrentLabel = [[UILabel alloc] init];
        _vloumeCurrentLabel.frame = CGRectMake(0, assetVolumeView.frame.origin.y - 15, 50, 20);
        _vloumeCurrentLabel.textAlignment = NSTextAlignmentCenter;
        _vloumeCurrentLabel.textColor = Main_Color;
        _vloumeCurrentLabel.font = [UIFont systemFontOfSize:12];
        
        float percent = _volumeProgressSlider.value* volumeMultipleM *100.0;
        _vloumeCurrentLabel.text = [NSString stringWithFormat:@"%d", (int)percent];
        [_volumeView addSubview:_vloumeCurrentLabel];
        _vloumeCurrentLabel.hidden = YES;
        
        [self addSubview:_volumeView];
    }
    return _volumeView;
}
- (RDZSlider *)volumeProgressSlider{
    if(!_volumeProgressSlider){
        //        _volumeProgressSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(90,  (_volumeView.frame.size.height - kToolbarHeight)*(  0.24 + 0.194 ) + ( (_volumeView.frame.size.height - kToolbarHeight)*0.449 - 30 )/2.0, kWIDTH - 90 - 50, 30)];
        _volumeProgressSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(100, 0, kWIDTH - 100 - 50, 30)];
        
        _volumeProgressSlider.layer.cornerRadius = 2.0;
        _volumeProgressSlider.layer.masksToBounds = YES;
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [_volumeProgressSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_volumeProgressSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [_volumeProgressSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"]  forState:UIControlStateNormal];
        [_volumeProgressSlider setValue:0];
        _volumeProgressSlider.alpha = 1.0;
        _volumeProgressSlider.backgroundColor = [UIColor clearColor];
        [_volumeProgressSlider addTarget:self action:@selector(volumeBeginScrub) forControlEvents:UIControlEventValueChanged];
        [_volumeProgressSlider addTarget:self action:@selector(volumeEndScrub) forControlEvents:UIControlEventTouchUpInside];
        [_volumeProgressSlider addTarget:self action:@selector(volumeEndScrub) forControlEvents:UIControlEventTouchCancel];
    }
    return _volumeProgressSlider;
}

//音量 滑动进度条
- (void)volumeBeginScrub{
    _vloumeCurrentLabel.hidden = NO;
    [self setVolume];
}

- (void)volumeEndScrub{
    _vloumeCurrentLabel.hidden = YES;
    [self setVolume];
}

-(void)volumeClose_Btn
{
    if (_delegate && [_delegate respondsToSelector:@selector(hiddenCollageBarItem: isSave:)]) {
        [_delegate hiddenCollageBarItem:kPIP_VOLUME isSave:NO];
    }
}

-(void)volumeConfirm_Btn
{
    CGFloat current = _volumeProgressSlider.value;
    float percent = current * volumeMultipleM;
    RDZSlider *fadeInSlider = [_volumeFadeView viewWithTag:1];
    RDZSlider *fadeOutSlider = [_volumeFadeView viewWithTag:2];
    _currentVvAsset.volume = percent;
    _currentVvAsset.audioFadeInDuration = fadeInSlider.value;
    _currentVvAsset.audioFadeOutDuration = fadeOutSlider.value;
    
    if (_delegate && [_delegate respondsToSelector:@selector(hiddenCollageBarItem: isSave:)]) {
        [_delegate hiddenCollageBarItem:kPIP_VOLUME isSave:YES];
    }
}

-(void)setVolume
{
    CGFloat current = _volumeProgressSlider.value;
    float percent = current * volumeMultipleM;
    _vloumeCurrentLabel.frame = CGRectMake(current*_volumeProgressSlider.frame.size.width+_volumeProgressSlider.frame.origin.x - _vloumeCurrentLabel.frame.size.width/2.0, _vloumeCurrentLabel.frame.origin.y, _vloumeCurrentLabel.frame.size.width, _vloumeCurrentLabel.frame.size.height);
    _vloumeCurrentLabel.text = [NSString stringWithFormat:@"%d",(int)(percent*100)];
    
    
    [[_videoCoreSDK getScenes] enumerateObjectsUsingBlock:^(RDScene * _Nonnull obj1, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [obj1.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.volume = percent;
        }];
        
    }];
    [_videoCoreSDK refreshCurrentFrame];
}

-(UIButton *) vloumeBtn
{
    if( !_vloumeBtn )
    {
        UIImage *nomarlImage = [RDHelpClass rdImageWithColor:SCREEN_BACKGROUND_COLOR cornerRadius:0];
        UIImage *selectedImage = [RDHelpClass rdImageWithColor:[UIColor whiteColor] cornerRadius:0];
        
        _vloumeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _vloumeBtn.frame = CGRectMake(0,0, _volumeView.frame.size.width*0.426/2.0, (_volumeView.frame.size.height - kToolbarHeight)*0.194 );
        [_vloumeBtn setTitle:RDLocalizedString(@"音    量", nil) forState:UIControlStateNormal];
        [_vloumeBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateNormal];
        [_vloumeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        
        
        
        [_vloumeBtn setBackgroundImage:nomarlImage forState:UIControlStateNormal];
        [_vloumeBtn setBackgroundImage:selectedImage forState:UIControlStateSelected];
        
        _vloumeBtn.tag = 0;
        _vloumeBtn.font = [UIFont systemFontOfSize:14];
        [_vloumeBtn addTarget:self action:@selector(setAssetVolume:) forControlEvents:UIControlEventTouchUpInside];
        [_vloume_navagatio_View addSubview:_vloumeBtn];
        
        _vloumeBtn.selected = YES;
    }
    return _vloumeBtn;
}
-(UIButton *) fadeInOrOutBtn
{
    if( !_fadeInOrOutBtn )
    {
//        UIRectCornerTopLeft     = 1 << 0,
//        UIRectCornerTopRight    = 1 << 1,
//        UIRectCornerBottomLeft  = 1 << 2,
//        UIRectCornerBottomRight = 1 << 3,
        
        UIImage *nomarlImage = [RDHelpClass rdImageWithColor:SCREEN_BACKGROUND_COLOR cornerRadius:0];
        UIImage *selectedImage = [RDHelpClass rdImageWithColor:[UIColor whiteColor] cornerRadius:0];
        
        _fadeInOrOutBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _fadeInOrOutBtn.frame = CGRectMake(_volumeView.frame.size.width*0.426/2.0, 0, _volumeView.frame.size.width*0.426/2.0, (_volumeView.frame.size.height - kToolbarHeight)*0.194 );
        [_fadeInOrOutBtn setTitle:RDLocalizedString(@"淡入淡出", nil) forState:UIControlStateNormal];
        [_fadeInOrOutBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateNormal];
        [_fadeInOrOutBtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        
        [_vloumeBtn setBackgroundImage:nomarlImage forState:UIControlStateNormal];
        [_vloumeBtn setBackgroundImage:selectedImage forState:UIControlStateSelected];
        
        _fadeInOrOutBtn.tag = 1;
        _fadeInOrOutBtn.font = [UIFont systemFontOfSize:14];
        [_fadeInOrOutBtn addTarget:self action:@selector(setAssetVolume:) forControlEvents:UIControlEventTouchUpInside];
        [_vloume_navagatio_View addSubview:_fadeInOrOutBtn];
    }
    return _fadeInOrOutBtn;
}

- (UIView *)volumeFadeView {
    if (!_volumeFadeView) {
        _volumeFadeView = [[UIView alloc] initWithFrame:CGRectMake(0, (_volumeView.frame.size.height - kToolbarHeight)*(  0.24 + 0.194 ) + ( (_volumeView.frame.size.height - kToolbarHeight)*( 1.0 - 0.24 - 0.194 ) - 30 )/2.0, kWIDTH, 30)];
        [_volumeView addSubview:_volumeFadeView];
        
        fadeDurationLbel = [[UILabel alloc] initWithFrame:CGRectMake(0, _volumeFadeView.frame.origin.y - 15, 50, 20)];
        fadeDurationLbel.textAlignment = NSTextAlignmentCenter;
        fadeDurationLbel.textColor = Main_Color;
        fadeDurationLbel.font = [UIFont systemFontOfSize:12];
        fadeDurationLbel.hidden = YES;
        [_volumeView addSubview:fadeDurationLbel];
        
        for (int i = 0; i < 2; i++) {
            UILabel *label = [[UILabel alloc] init];
            label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
            label.font = [UIFont systemFontOfSize:14];
            
            RDZSlider *fadeSlider = [[RDZSlider alloc] init];
            fadeSlider.backgroundColor = [UIColor clearColor];
            [fadeSlider setMaximumValue:1];
            [fadeSlider setMinimumValue:0];
            fadeSlider.layer.cornerRadius = 2.0;
            fadeSlider.layer.masksToBounds = YES;
            UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
            image = [image imageWithTintColor];
            [fadeSlider setMinimumTrackImage:image forState:UIControlStateNormal];
            image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
            [fadeSlider setMaximumTrackImage:image forState:UIControlStateNormal];
            [fadeSlider setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"]  forState:UIControlStateNormal];
            fadeSlider.tag = i + 1;
            [fadeSlider addTarget:self action:@selector(volumeFadeBeginScrub:) forControlEvents:UIControlEventTouchDown];
            [fadeSlider addTarget:self action:@selector(volumeFadeScrub:) forControlEvents:UIControlEventValueChanged];
            [fadeSlider addTarget:self action:@selector(volumeFadeEndScrub:) forControlEvents:UIControlEventTouchUpInside];
            [fadeSlider addTarget:self action:@selector(volumeFadeEndScrub:) forControlEvents:UIControlEventTouchCancel];
            
            if (i == 0) {
                label.frame = CGRectMake(25, 0, 70, 30);
                label.text = RDLocalizedString(@"淡入时长", nil);
                fadeSlider.frame = CGRectMake(85, 0, kWIDTH/2.0 - 100, 30);
                _fadeInVolumeSlider = fadeSlider;
            }else {
                label.frame = CGRectMake(kWIDTH/2.0 + 15, 0, 70, 30);
                label.text = RDLocalizedString(@"淡出时长", nil);
                fadeSlider.frame = CGRectMake(kWIDTH/2.0 + 85, 0, kWIDTH/2.0 - 100, 30);
                _fadeOutVolumeSlider = fadeSlider;
            }
            [_volumeFadeView addSubview:label];
            [_volumeFadeView addSubview:fadeSlider];
        }
    }
    return _volumeFadeView;
}

- (void)setAssetVolume:(UIButton *)sender {
    sender.selected = YES;
    if (sender.tag == 0) {
        _fadeInOrOutBtn.selected = NO;
        _vloumeBtn.layer.borderColor = [UIColor whiteColor].CGColor;
        _vloumeBtn.backgroundColor = [UIColor whiteColor];
        _fadeInOrOutBtn.layer.borderColor = [UIColor whiteColor].CGColor;
        _fadeInOrOutBtn.backgroundColor = [UIColor clearColor];
        self.volumeFadeView.hidden = YES;
        assetVolumeView.hidden = NO;
    }else {
        _vloumeBtn.selected = NO;
        _vloumeBtn.layer.borderColor = [UIColor whiteColor].CGColor;
        _vloumeBtn.backgroundColor = [UIColor clearColor];
        _fadeInOrOutBtn.layer.borderColor = [UIColor whiteColor].CGColor;
        _fadeInOrOutBtn.backgroundColor = [UIColor whiteColor];
        assetVolumeView.hidden = YES;
        self.volumeFadeView.hidden = NO;
        
        VVAsset *asset = _currentVvAsset;
        RDZSlider *fadeInSlider = [_volumeFadeView viewWithTag:1];
        fadeInSlider.value = asset.audioFadeInDuration;
        fadeInSlider.maximumValue = CMTimeGetSeconds(asset.timeRange.duration)/2.0;
        RDZSlider *fadeOutSlider = [_volumeFadeView viewWithTag:2];
        fadeOutSlider.value = asset.audioFadeOutDuration;
        fadeOutSlider.maximumValue = fadeInSlider.maximumValue;
    }
}

- (void)volumeFadeBeginScrub:(RDZSlider *)slider {
    fadeInOrfadeOutTime = _videoCoreSDK.currentTime;
    CGRect rect = [slider thumbRectForBounds:CGRectMake(0, 0, slider.currentThumbImage.size.width, slider.currentThumbImage.size.height) trackRect:slider.frame value:slider.value];
    fadeDurationLbel.center = CGPointMake(rect.origin.x + slider.currentThumbImage.size.width/2.0, fadeDurationLbel.center.y);
    fadeDurationLbel.text = [NSString stringWithFormat:@"%.1fs",slider.value];
    fadeDurationLbel.hidden = NO;
//    [self playVideo:YES];
}

- (void)volumeFadeScrub:(RDZSlider *)slider {
    CGRect rect = [slider thumbRectForBounds:CGRectMake(0, 0, slider.currentThumbImage.size.width, slider.currentThumbImage.size.height) trackRect:slider.frame value:slider.value];
    fadeDurationLbel.center = CGPointMake(rect.origin.x + slider.currentThumbImage.size.width/2.0, fadeDurationLbel.center.y);
    fadeDurationLbel.text = [NSString stringWithFormat:@"%.1fs",slider.value];
}

- (void)volumeFadeEndScrub:(RDZSlider *)slider {
    
    if( self.currentCollage )
    {
        if (slider.tag == 1) {
            self.currentCollage.vvAsset.audioFadeInDuration = slider.value;
        }else {
            self.currentCollage.vvAsset.audioFadeOutDuration = slider.value;
        }
        
        [_videoCoreSDK refreshCurrentFrame];
    }
    WeakSelf(self);
    fadeDurationLbel.hidden = YES;
}

-(void)mode_Btn:(UIButton *) btn
{
    if( btn.tag == 0 )
    {
        btn.selected = YES;
        _fadeInOrOutBtn.selected = NO;
        _fadeInOrOutBtn.layer.borderColor =  [UIColor whiteColor].CGColor;
        _fadeInOrOutBtn.backgroundColor = [UIColor clearColor];
    }
    else if( btn.tag == 1 )
    {
        _vloumeBtn.layer.borderColor =  [UIColor whiteColor].CGColor;
        _vloumeBtn.backgroundColor = [UIColor clearColor];
    }
}

-(void)dealloc
{
    if( _volumeCloseBtn )
    {
        [_volumeCloseBtn removeFromSuperview];
        _volumeCloseBtn = nil;
        
        [_volumeConfirmBtn removeFromSuperview];
        _volumeConfirmBtn = nil;
    }
    
    if( _vloumeCurrentLabel )
    {
        [_vloumeCurrentLabel removeFromSuperview];
        _vloumeCurrentLabel = nil;
        
        [_volumeProgressSlider removeFromSuperview];
        _volumeProgressSlider = nil;
    }
    
    if( _vloume_navagatio_View )
    {
        [_vloume_navagatio_View removeFromSuperview];
        _vloume_navagatio_View = nil;
        
        [_vloumeBtn removeFromSuperview];
        _vloumeBtn = nil;
     
        [_fadeInOrOutBtn removeFromSuperview];
        _fadeInOrOutBtn = nil;
        
        [_volumeFadeView removeFromSuperview];
        _volumeFadeView = nil;
        
        [_fadeInVolumeSlider removeFromSuperview];
        _fadeInVolumeSlider = nil;
        
        [_fadeOutVolumeSlider removeFromSuperview];
        _fadeOutVolumeSlider = nil;
    }
    
    [assetVolumeView removeFromSuperview];
    assetVolumeView = nil;
    [fadeDurationLbel removeFromSuperview];
    fadeDurationLbel = nil;
    
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
