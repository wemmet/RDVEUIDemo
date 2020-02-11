//
//  cutout_editCollageView.m
//  RDVEUISDK
//
//  Created by apple on 2020/1/9.
//  Copyright © 2020 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "cutout_editCollageView.h"

@interface cutout_editCollageView ()
{
    
}

@end


@implementation cutout_editCollageView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if ( self )
    {
        self.backgroundColor = TOOLBAR_COLOR;
        
        float fheight = self.frame.size.height - kToolbarHeight;
        
        _cutoutLabelView = [[UIView alloc] initWithFrame:CGRectMake(0, fheight*0.25, self.frame.size.width, fheight*0.25)];
        
        NSString * str = @"R:255 G:255 B:255";
        
        float cutoutLabelWidth =  [RDHelpClass widthForString:str andHeight:14.0 fontSize:14.0] + 10;
        _cutoutLabel = [[UILabel alloc] initWithFrame:CGRectMake(20 + 10, 0, cutoutLabelWidth, fheight*0.25)];
        _cutoutLabel.font = [UIFont systemFontOfSize:14.0];
        _cutoutLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        _cutoutLabel.text  = str;
        [_cutoutLabelView addSubview:_cutoutLabel];
        
        _cutoutImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, (fheight*0.25 - 20)/2.0, 20, 20)];
        _cutoutImageView.layer.cornerRadius = _cutoutImageView.frame.size.width/2.0;
        _cutoutImageView.layer.masksToBounds = YES;
        _cutoutImageView.backgroundColor = UIColorFromRGB(0xffffff);
        [_cutoutLabelView addSubview:_cutoutImageView];
        
        _cutoutLabelView.frame = CGRectMake((self.frame.size.width - (cutoutLabelWidth + 20))/2.0, fheight*0.25, cutoutLabelWidth + 10, fheight*0.25);
        [self addSubview: _cutoutLabelView];
        
        [self addSubview:self.cutout_Accuracy_Slider];
        
        _cutoutCloseBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, self.frame.size.height - kToolbarHeight, 44, 44)];
        [_cutoutCloseBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
        [_cutoutCloseBtn addTarget:self action:@selector(cutoutClose_Btn) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_cutoutCloseBtn];
        
        _cutoutConfirmBtn = [[UIButton alloc] initWithFrame:CGRectMake(kWIDTH - 44, self.frame.size.height - kToolbarHeight, 44, 44)];
        [_cutoutConfirmBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
        [_cutoutConfirmBtn addTarget:self action:@selector(cutoutConfirm_Btn) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_cutoutConfirmBtn];
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(44, self.frame.size.height - kToolbarHeight + ( 44 - 44 )/2.0, kWIDTH - 44 * 2, 44)];
        label.text = RDLocalizedString(@"抠图", nil);
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        label.font = [UIFont boldSystemFontOfSize:17.0];
        [self addSubview:label];
        
        cutoutLabelWidth =  [RDHelpClass widthForString:RDLocalizedString(@"撤销抠图", nil) andHeight:14.0 fontSize:14.0] + 10;
        
        _cutoutCancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _cutoutCancelBtn.frame = CGRectMake( self.frame.size.width - 30 - cutoutLabelWidth - 5 , 5, 30 + cutoutLabelWidth, 30);
        _cutoutCancelBtn.layer.cornerRadius = 4;
        _cutoutCancelBtn.layer.masksToBounds = YES;
        _cutoutCancelBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_cutoutCancelBtn setTitle:RDLocalizedString(@"撤销抠图", nil) forState:UIControlStateNormal];
        [_cutoutCancelBtn setTitle:RDLocalizedString(@"撤销抠图", nil) forState:UIControlStateHighlighted];
        _cutoutCancelBtn.titleLabel.textAlignment = NSTextAlignmentRight;
        [_cutoutCancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/字幕颜色-撤销"] forState:UIControlStateNormal];
        [_cutoutCancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/字幕颜色-撤销"] forState:UIControlStateSelected];
        [_cutoutCancelBtn setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateNormal];
        [_cutoutCancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [_cutoutCancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        [_cutoutCancelBtn setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateSelected];
        [_cutoutCancelBtn setImageEdgeInsets:UIEdgeInsetsMake(0, -5, 0, 0)];
        [_cutoutCancelBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, -1, 0, 0)];
        _cutoutCancelBtn.backgroundColor = [UIColor clearColor];
        [_cutoutCancelBtn addTarget:self action:@selector(cutoutCancel_Btn) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:_cutoutCancelBtn];
    }
    return self;
}

-(void)cutoutCancel_Btn
{
    self.currentCollage.vvAsset.blendType = RDBlendNormal;
    [_videoCoreSDK refreshCurrentFrame];
    
}

#pragma mark- 抠图
-(void)cutoutClose_Btn
{
    
    if (_delegate && [_delegate respondsToSelector:@selector(hiddenCollageBarItem: isSave:)]) {
        [_delegate hiddenCollageBarItem:kPIP_CUTOUT isSave:NO];
    }
}
-(void)cutoutConfirm_Btn
{
    if (_delegate && [_delegate respondsToSelector:@selector(hiddenCollageBarItem: isSave:)]) {
        [_delegate hiddenCollageBarItem:kPIP_CUTOUT isSave:YES];
    }
}


- (RDZSlider *)cutout_Accuracy_Slider{
    if(!_cutout_Accuracy_Slider){
        
        NSString * str = RDLocalizedString(@"抠图精度", nil);
        
        float cutoutLabelWidth =  [RDHelpClass widthForString:str andHeight:14.0 fontSize:14.0] + 10;
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(50, 0.5*(self.frame.size.height - kToolbarHeight) + ( ( (self.frame.size.height - kToolbarHeight)*0.5 ) - 30 )/2.0 , cutoutLabelWidth, 30)];
        label.font = [UIFont systemFontOfSize:14.0];
        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        label.text  = str;
        [self addSubview:label];
        
        _cutout_Accuracy_Slider = [[RDZSlider alloc] initWithFrame:CGRectMake(label.frame.size.width + label.frame.origin.x, 0.5*(self.frame.size.height - kToolbarHeight) + ( ( (self.frame.size.height - kToolbarHeight)*0.5 ) - 30 )/2.0  , kWIDTH - (label.frame.size.width + label.frame.origin.x) - 50, 30)];
        
        _cutout_AccuracyCurrentLabel = [[UILabel alloc] init];
        _cutout_AccuracyCurrentLabel.frame = CGRectMake(0, _cutout_Accuracy_Slider.frame.origin.y - 25, 50, 20);
        _cutout_AccuracyCurrentLabel.textAlignment = NSTextAlignmentCenter;
        _cutout_AccuracyCurrentLabel.textColor = Main_Color;
        _cutout_AccuracyCurrentLabel.font = [UIFont systemFontOfSize:12];
        
        float percent = _cutout_Accuracy_Slider.value *100.0;
        _cutout_AccuracyCurrentLabel.text = [NSString stringWithFormat:@"%d", (int)percent];
        [self addSubview:_cutout_AccuracyCurrentLabel];
        _cutout_AccuracyCurrentLabel.hidden = YES;

        _cutout_Accuracy_Slider.layer.cornerRadius = 2.0;
        _cutout_Accuracy_Slider.layer.masksToBounds = YES;
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [_cutout_Accuracy_Slider setMinimumTrackImage:image forState:UIControlStateNormal];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_cutout_Accuracy_Slider setMaximumTrackImage:image forState:UIControlStateNormal];
        [_cutout_Accuracy_Slider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"]  forState:UIControlStateNormal];
        [_cutout_Accuracy_Slider setValue:0];
        _cutout_Accuracy_Slider.alpha = 1.0;
        _cutout_Accuracy_Slider.backgroundColor = [UIColor clearColor];
        [_cutout_Accuracy_Slider addTarget:self action:@selector(cutoutBeginScrub) forControlEvents:UIControlEventValueChanged];
        [_cutout_Accuracy_Slider addTarget:self action:@selector(cutoutEndScrub) forControlEvents:UIControlEventTouchUpInside];
        [_cutout_Accuracy_Slider addTarget:self action:@selector(cutoutEndScrub) forControlEvents:UIControlEventTouchCancel];
        [self addSubview:_cutout_Accuracy_Slider];
        
        
    }
    return _cutout_Accuracy_Slider;
}

//透明度 滑动进度条
- (void)cutoutBeginScrub{
    _cutout_AccuracyCurrentLabel.hidden = NO;
    [self setCutout];
}

- (void)cutoutEndScrub{
    _cutout_AccuracyCurrentLabel.hidden = YES;
    [self setCutout];
}

- (void)setCutout
{
    CGFloat current = _cutout_Accuracy_Slider.value;
    float percent = current * 100;
    _cutout_AccuracyCurrentLabel.frame = CGRectMake(current*_cutout_Accuracy_Slider.frame.size.width+ _cutout_Accuracy_Slider.frame.origin.x - _cutout_AccuracyCurrentLabel.frame.size.width/2.0, _cutout_AccuracyCurrentLabel.frame.origin.y, _cutout_AccuracyCurrentLabel.frame.size.width, _cutout_AccuracyCurrentLabel.frame.size.height);
    _cutout_AccuracyCurrentLabel.text = [NSString stringWithFormat:@"%d",(int)percent];
    
    
    
    
}

-(void)setCutoutColor:(float) colorRed atColorGreen:(float) colorGreen atColorBlue:(float) colorBlue atAlpha:(float) colorApha
{
    float fheight = self.frame.size.height - kToolbarHeight;
    
    NSString * str = [NSString stringWithFormat:@"R:%.1f G:%.1f B:%.1f",colorGreen,colorBlue,colorApha];
    
    float cutoutLabelWidth =  [RDHelpClass widthForString:str andHeight:14.0 fontSize:14.0] + 10;
    _cutoutLabel.frame = CGRectMake(20 + 10, 0, cutoutLabelWidth, fheight*0.25);
    _cutoutLabel.text  = str;
    
    _cutoutImageView.backgroundColor = [UIColor colorWithRed:colorRed green:colorGreen blue:colorBlue alpha:colorApha];
    
    _cutoutLabelView.frame = CGRectMake((self.frame.size.width - (cutoutLabelWidth + 20))/2.0, fheight*0.25, cutoutLabelWidth + 10, fheight*0.25);
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
