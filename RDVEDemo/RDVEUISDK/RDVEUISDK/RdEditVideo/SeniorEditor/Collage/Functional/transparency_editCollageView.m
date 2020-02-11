//
//  transparency_editCollageView.m
//  RDVEUISDK
//
//  Created by apple on 2020/1/8.
//  Copyright © 2020 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "transparency_editCollageView.h"

@interface transparency_editCollageView ()
{
    
}

@end

@implementation transparency_editCollageView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if ( self )
    {
        self.backgroundColor = TOOLBAR_COLOR;
        
        self.transparencyView.hidden = NO;
        [self addSubview:self.transparencyView];
    }
    return self;
}

#pragma mark- 透明度
-(void)transparencyClose_Btn
{
    if (_delegate && [_delegate respondsToSelector:@selector(hiddenCollageBarItem: isSave:)]) {
        [_delegate hiddenCollageBarItem:kPIP_TRANSPARENCY isSave:NO];
    }
}
-(void)transparencyConfirm_Btn
{
    if (_delegate && [_delegate respondsToSelector:@selector(hiddenCollageBarItem: isSave:)]) {
        [_delegate hiddenCollageBarItem:kPIP_TRANSPARENCY isSave:YES];
    }
}
-(UIView *)transparencyView
{
    if( !_transparencyView )
    {
        _transparencyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0  , self.bounds.size.width, self.bounds.size.height)];
        _transparencyView.backgroundColor = TOOLBAR_COLOR;
        
        [self addSubview:_transparencyView];
        
        self.transparencyProgressSlider.hidden = NO;
        
        _transparencyCloseBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, _transparencyView.frame.size.height - kToolbarHeight, 44, 44)];
        [_transparencyCloseBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
        [_transparencyCloseBtn addTarget:self action:@selector(transparencyClose_Btn) forControlEvents:UIControlEventTouchUpInside];
        [_transparencyView addSubview:_transparencyCloseBtn];
        
        _transparencyConfirmBtn = [[UIButton alloc] initWithFrame:CGRectMake(kWIDTH - 44, _transparencyView.frame.size.height - kToolbarHeight, 44, 44)];
        [_transparencyConfirmBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
        [_transparencyConfirmBtn addTarget:self action:@selector(transparencyConfirm_Btn) forControlEvents:UIControlEventTouchUpInside];
        [_transparencyView addSubview:_transparencyConfirmBtn];
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(44, _transparencyView.frame.size.height - kToolbarHeight + ( 44 - 44 )/2.0, kWIDTH - 44 * 2, 44)];
        label.text = RDLocalizedString(@"透明度", nil);
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        label.font = [UIFont boldSystemFontOfSize:17.0];
        [_transparencyView addSubview:label];
    }
    return _transparencyView;
}

- (RDZSlider *)transparencyProgressSlider{
    if(!_transparencyProgressSlider){
        
        
        _transparencyProgressSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(50, 0.240*(_transparencyView.frame.size.height - kToolbarHeight) + ( ( (_transparencyView.frame.size.height - kToolbarHeight)*0.760 ) - 30 )/2.0  , kWIDTH - 50 - 50, 30)];
        
        _transparencyCurrentLabel = [[UILabel alloc] init];
        _transparencyCurrentLabel.frame = CGRectMake(0, _transparencyProgressSlider.frame.origin.y - 25, 50, 20);
        _transparencyCurrentLabel.textAlignment = NSTextAlignmentCenter;
        _transparencyCurrentLabel.textColor = Main_Color;
        _transparencyCurrentLabel.font = [UIFont systemFontOfSize:12];
        
        float percent = _transparencyProgressSlider.value *100.0;
        _transparencyCurrentLabel.text = [NSString stringWithFormat:@"%d", (int)percent];
        [_transparencyView addSubview:_transparencyCurrentLabel];
        _transparencyCurrentLabel.hidden = YES;

        
        _transparencyProgressSlider.layer.cornerRadius = 2.0;
        _transparencyProgressSlider.layer.masksToBounds = YES;
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [_transparencyProgressSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_transparencyProgressSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [_transparencyProgressSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"]  forState:UIControlStateNormal];
        [_transparencyProgressSlider setValue:0];
        _transparencyProgressSlider.alpha = 1.0;
        _transparencyProgressSlider.backgroundColor = [UIColor clearColor];
        [_transparencyProgressSlider addTarget:self action:@selector(transparencyBeginScrub) forControlEvents:UIControlEventValueChanged];
        [_transparencyProgressSlider addTarget:self action:@selector(transparencyEndScrub) forControlEvents:UIControlEventTouchUpInside];
        [_transparencyProgressSlider addTarget:self action:@selector(transparencyEndScrub) forControlEvents:UIControlEventTouchCancel];
        [_transparencyView addSubview:_transparencyProgressSlider];
    }
    return _transparencyProgressSlider;
}
//透明度 滑动进度条
- (void)transparencyBeginScrub{
    _transparencyCurrentLabel.hidden = NO;
    [self setTransparency];
}

- (void)transparencyEndScrub{
    _transparencyCurrentLabel.hidden = YES;
    [self setTransparency];
}

- (void)setTransparency
{
    CGFloat current = _transparencyProgressSlider.value;
    float percent = current * 100;
    _transparencyCurrentLabel.frame = CGRectMake(current*_transparencyProgressSlider.frame.size.width+_transparencyProgressSlider.frame.origin.x - _transparencyCurrentLabel.frame.size.width/2.0, _transparencyCurrentLabel.frame.origin.y, _transparencyCurrentLabel.frame.size.width, _transparencyCurrentLabel.frame.size.height);
    _transparencyCurrentLabel.text = [NSString stringWithFormat:@"%d",(int)percent];
    
//    [[_videoCoreSDK getScenes] enumerateObjectsUsingBlock:^(RDScene * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        [obj.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
//            obj.alpha = current;
//        }];
//    }];
    
    if( _pasterView )
    {
        
        if( self.currentCollage )
        {
            self.currentCollage.vvAsset.alpha = current;
        }
    }
    
    [_videoCoreSDK refreshCurrentFrame];
}

-(void)ImageRef
{
//    [_videoCoreSDK getImageWithTime:CMTimeMake(0.2, TIMESCALE) scale:1.0 completionHandler:^(UIImage *image) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            _pasterView.contentImage.image = nil;
//            _pasterView.contentImage.image = image;
//        });
//    }];
}


-(void)dealloc
{
    if( _transparencyView )
    {
        [_transparencyProgressSlider removeFromSuperview];
        _transparencyProgressSlider = nil;
        [_transparencyCurrentLabel removeFromSuperview];
        _transparencyCurrentLabel = nil;
        [_transparencyCloseBtn removeFromSuperview];
        _transparencyCloseBtn = nil;
        [_transparencyConfirmBtn removeFromSuperview];
        _transparencyConfirmBtn = nil;
        
        [_transparencyView removeFromSuperview];
        _transparencyView = nil;
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
