//
//  RDm
//  RDVEUISDK
//
//  Created by apple on 2019/4/25.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//
#import "RDNavigationViewController.h"
#import "RDAddEffectsByTimeline.h"
#import "RDSectorProgressView.h"
#import "RDFileDownloader.h"
#import "SubtitleColorControl.h"
#import "CaptionRangeView.h"
#import "UIButton+RDWebCache.h"
#import "UIImage+RDWebP.h"
#import "RDMBProgressHUD.h"
#import "RDZSlider.h"
#import "RDAddEffectsByTimeline+Subtitle.h"
#import "RDAddEffectsByTimeline+Sticker.h"
#import "RDAddEffectsByTimeline+Dewatermark.h"
#import "RDAddEffectsByTimeline+Collage.h"
#import "RDAddEffectsByTimeline+FXView.h"

#import "RDChooseMusic.h"

#import "RDSoundChooseMusic.h"

#import "RDSVProgressHUD.h"
float globalInset = 8;

@interface RDAddEffectsByTimeline ()<CaptionVideoTrimmerDelegate,RDPasterTextViewDelegate,SubtitleColorControlDelegate,UIScrollViewDelegate,editCollageViewDelegate,RDVECoreDelegate>
{
    RDZSlider               *alphaSlider;
    UILabel                 *alphaValueLbl;
    RDZSlider               *thicknessSlider;
    SubtitleColorControl    *colorControl;
    float           rotaionSaveAngle;
    UIView *spanView;
}
@property (nonatomic, strong) NSMutableArray *colorArray;
@property(nonatomic,strong)RDMBProgressHUD  *progressHUD;

@end

@implementation RDAddEffectsByTimeline

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if ( self )
    {
        self.backgroundColor = TOOLBAR_COLOR;
        [self initUI];
    }
    return self;
}

#pragma mark- 初始化 公共控件
-(void) initUI
{
    _isBlankCaptionRangeView = true;
    _lock = [[NSLock alloc] init];
    [self addSubview:self.playBtnView];
    
    
    [self addSubview:self.currentTimeLbl];
    [self addSubview:self.durationTimeLbl];
    [self addSubview:self.dragTimeView];
    [self addSubview:self.addBtn];
    [self addSubview:self.cancelBtn];
    [self addSubview:self.finishBtn];
    [self addSubview:self.deletedBtn];
    [self addSubview:self.editBtn];
    _isPlay = false;
    float y = _playBtnView.frame.origin.y - (iPhone4s ? (45 - 44)/2.0 : (50 - 45)/2.0);
    spanView = [[UIView alloc] initWithFrame:CGRectMake((kWIDTH - 3)/2.0, y-2 + 5, 3, 50 - 5)];
    spanView.backgroundColor = [UIColor whiteColor];
    spanView.layer.cornerRadius = 1.5;
    [self addSubview:spanView];
    if (iPhone4s) {
        CGRect frame = _currentTimeLbl.frame;
        frame.origin.y = 0;
        _currentTimeLbl.frame = frame;
        
        frame = _playBtn.frame;
        frame.origin.y = 13;
        _playBtn.frame = frame;
    }
}

- (void)prepareWithEditConfiguration:(EditConfiguration *)editConfiguration
                              appKey:(NSString *)appKey
                          exportSize:(CGSize)exportSize
                          playerView:(UIView *)playerView
                                 hud:(RDATMHud *)hud
{
    _editConfiguration = editConfiguration;
    _appKey = appKey;
    _exportSize = exportSize;
    _playerView = playerView;
    _hud = hud;
}

- (CaptionVideoTrimmerView *)doodleTrimmerView {
    if (!_doodleTrimmerView) {
        _doodleTrimmerView = [self TrimmerView];
    }
    return _doodleTrimmerView;
}

//贴纸
-(CaptionVideoTrimmerView *)stickerTrimmerView
{
    if(!_stickerTrimmerView)
    {
        _stickerTrimmerView = [self TrimmerView];
    }
    return _stickerTrimmerView;
}
//字幕
-(CaptionVideoTrimmerView *)subtitleTrimmerView
{
    if(!_subtitleTrimmerView)
    {
        _subtitleTrimmerView = [self TrimmerView];
    }
    return _subtitleTrimmerView;
}
//去水印
-(CaptionVideoTrimmerView*)dewatermarkTrimmerView
{
    if(!_dewatermarkTrimmerView)
    {
        _dewatermarkTrimmerView = [self TrimmerView];
    }
    return _dewatermarkTrimmerView;
}
//画中画
-(CaptionVideoTrimmerView*)collageTrimmerView
{
    if(!_collageTrimmerView)
    {
        _collageTrimmerView = [self TrimmerView];
        _collageTrimmerView.isCollage = true;
    }
    return _collageTrimmerView;
}
//音效
-(CaptionVideoTrimmerView*)soundTrimmerView
{
    if(!_soundTrimmerView)
    {
        _soundTrimmerView = [self TrimmerView];
    }
    return _soundTrimmerView;
}
//多段配乐
-(CaptionVideoTrimmerView*)multi_trackTrimmerView
{
    if(!_multi_trackTrimmerView)
    {
        _multi_trackTrimmerView = [self TrimmerView];
    }
    return _multi_trackTrimmerView;
}
//特效
-(CaptionVideoTrimmerView*)fXTrimmerView
{
    if(!_fXTrimmerView)
    {
        _fXTrimmerView = [self TrimmerView];
    }
    return _fXTrimmerView;
}

- (CaptionVideoTrimmerView *)TrimmerView{
    CGRect rect = CGRectMake(0, _playBtnView.frame.origin.y - (iPhone4s ? (45 - 44)/2.0 : (50 - 45)/2.0), self.bounds.size.width, 45);
    CaptionVideoTrimmerView * TrimmerView = [[CaptionVideoTrimmerView alloc] initWithFrame:rect videoCore: _thumbnailCoreSDK];
    TrimmerView.backgroundColor = [UIColor clearColor];
    [TrimmerView setClipTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(_thumbnailCoreSDK.duration, TIMESCALE))];
    [TrimmerView setThemeColor:[UIColor lightGrayColor]];
    TrimmerView.tag = 1;
    [TrimmerView setDelegate:self];
    TrimmerView.scrollView.decelerationRate = 0.8;
    TrimmerView.piantouDuration = 0;
    TrimmerView.pianweiDuration = 0;
    TrimmerView.rightSpace = 20;
    
//    NSMutableArray *thumbTimes = [NSMutableArray array];
//    NSInteger num = 0;while (num<_thumbnailCoreSDK.duration) {
//        [thumbTimes addObject:@(num)];
//        num +=2;
//    }
//    [thumbTimes addObject:@(_thumbnailCoreSDK.duration)];
//    TrimmerView.thumbTimes = thumbTimes.count;
//    [_thumbnailCoreSDK getImageAtTime:kCMTimeZero scale:0.3 completion:^(UIImage *image) {
//        [TrimmerView resetSubviews:image];
//    }];
    return TrimmerView;
}

-(UILabel *)durationTimeLbl
{
    if(!_durationTimeLbl){
        _durationTimeLbl = [[UILabel alloc] initWithFrame:CGRectMake(kWIDTH - 100 - 15,  _playBtnView.frame.origin.y - (iPhone4s ? (45 - 44)/2.0 : (50 - 45)/2.0) - 15, 100, 15)];
        _durationTimeLbl.textAlignment = NSTextAlignmentRight;
        _durationTimeLbl.textColor = UIColorFromRGB(0xababab);
        _durationTimeLbl.text = @"0.00";
        _durationTimeLbl.font = [UIFont systemFontOfSize:10];
    }
    return _durationTimeLbl;
}

- (UILabel *)currentTimeLbl{
    if(!_currentTimeLbl){
        _currentTimeLbl = [[UILabel alloc] initWithFrame:CGRectMake((kWIDTH - 100)/2.0,  _playBtnView.frame.origin.y - (iPhone4s ? (45 - 44)/2.0 : (50 - 45)/2.0) - 15, 100, 15)];
        _currentTimeLbl.textAlignment = NSTextAlignmentCenter;
        _currentTimeLbl.textColor = [UIColor whiteColor];
        _currentTimeLbl.text = @"0.00";
        _currentTimeLbl.font = [UIFont systemFontOfSize:10];
    }
    return _currentTimeLbl;
}


-(UIView *) playBtnView
{
    if( !_playBtnView )
    {
        _playBtnView = [[UIView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height/2.0 - 44 + 15, 49, 44)];
        [_playBtnView addSubview:self.playBtn];
        _playBtnView.backgroundColor = [UIColor clearColor];
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.colors = @[(__bridge id)[UIColor blackColor].CGColor, (__bridge id)[UIColor colorWithWhite:0.0 alpha:0.0].CGColor];
        gradientLayer.locations = @[@0.5, @1.0];
        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(1.0, 0);
        gradientLayer.frame = CGRectMake(0, 0, _playBtnView.bounds.size.width*2/6.0, _playBtnView.bounds.size.height);
        [_playBtnView.layer addSublayer:gradientLayer];
    }
    return _playBtnView;
}

- (UIButton *)playBtn{
    if(!_playBtn){
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _playBtn.backgroundColor = [UIColor clearColor];
        _playBtn.frame = CGRectMake(5, 0, 44, 44);
        [_playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
        [_playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateHighlighted];
        [_playBtn addTarget:self action:@selector(tapPlayButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}

- (UIButton *)speechRecogBtn {
    if (!_speechRecogBtn && _editConfiguration.enableAIRecogSubtitle) {
        float width = 113;
        _speechRecogBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _speechRecogBtn.frame = CGRectMake((_addBtn.frame.origin.x - width)/2.0, self.bounds.size.height/2.0 + (self.bounds.size.height/2.0 - 27)/2.0+5, width, 27);
        _speechRecogBtn.layer.borderColor = UIColorFromRGB(0xb2b2b2).CGColor;
        _speechRecogBtn.layer.borderWidth = 1.0;
        _speechRecogBtn.layer.cornerRadius = _speechRecogBtn.bounds.size.height/2.0;
        _speechRecogBtn.layer.masksToBounds = YES;
        [_speechRecogBtn setTitle:RDLocalizedString(@"AI 识别", nil) forState:UIControlStateNormal];
        [_speechRecogBtn setTitleColor:UIColorFromRGB(0xb2b2b2) forState:UIControlStateNormal];
        [_speechRecogBtn.titleLabel setFont:[UIFont systemFontOfSize:14]];
        _speechRecogBtn.hidden = YES;
        [_speechRecogBtn addTarget:self action:@selector(speechRecogBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        width = [_speechRecogBtn sizeThatFits:CGSizeZero].width + 30;
        _speechRecogBtn.frame = CGRectMake((_addBtn.frame.origin.x - width)/2.0, self.bounds.size.height/2.0 + (self.bounds.size.height/2.0 - 27)/2.0+5, width, 27);
        [self addSubview:_speechRecogBtn];
    }
    return _speechRecogBtn;
}

- (UIButton *)addBtn{
    if(!_addBtn){
        _addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _addBtn.backgroundColor = [UIColor clearColor];
        _addBtn.frame = CGRectMake((kWIDTH - 113)/2.0, self.bounds.size.height/2.0 + (self.bounds.size.height/2.0 - 35)/2.0+5, 113, 35);
        _addBtn.layer.borderColor = CUSTOM_GRAYCOLOR.CGColor;
        _addBtn.layer.borderWidth = 1.0;
        _addBtn.layer.cornerRadius = 35/2.0;
        _addBtn.layer.masksToBounds = YES;
        [_addBtn setTitle:RDLocalizedString(@"添加", nil) forState:UIControlStateNormal];
        [_addBtn setTitleColor:CUSTOM_GRAYCOLOR forState:UIControlStateNormal];
        [_addBtn.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [_addBtn.titleLabel setFont:[UIFont systemFontOfSize:16]];
        [_addBtn addTarget:self action:@selector(addEffectAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _addBtn;
}

- (UIButton *)finishBtn{
    if(!_finishBtn){
        _finishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _finishBtn.backgroundColor = [UIColor clearColor];
        _finishBtn.frame = _addBtn.frame;
        _finishBtn.layer.borderColor = CUSTOM_GRAYCOLOR.CGColor;
        _finishBtn.layer.borderWidth = 1.0;
        _finishBtn.layer.cornerRadius = 35/2.0;
        _finishBtn.layer.masksToBounds = YES;
        [_finishBtn setTitle:RDLocalizedString(@"完成", nil) forState:UIControlStateNormal];
        [_finishBtn setTitleColor:CUSTOM_GRAYCOLOR forState:UIControlStateNormal];
        [_finishBtn.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [_finishBtn.titleLabel setFont:[UIFont systemFontOfSize:16]];
        [_finishBtn addTarget:self action:@selector(finishEffectAction:) forControlEvents:UIControlEventTouchDown];
        _finishBtn.hidden = YES;
    }
    return _finishBtn;
}

- (UIButton *)deletedBtn{
    if(!_deletedBtn){
        _deletedBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _deletedBtn.backgroundColor = [UIColor clearColor];
        _deletedBtn.frame = CGRectMake(_addBtn.frame.origin.x + _addBtn.bounds.size.width + 24, _addBtn.frame.origin.y + (35 - 27)/2.0, 65, 27);
        _deletedBtn.layer.borderColor = UIColorFromRGB(0xb2b2b2).CGColor;
        _deletedBtn.layer.borderWidth = 1.0;
        _deletedBtn.layer.cornerRadius = _deletedBtn.bounds.size.height/2.0;
        _deletedBtn.layer.masksToBounds = YES;
        [_deletedBtn setTitle:RDLocalizedString(@"删除", nil) forState:UIControlStateNormal];
        [_deletedBtn setTitleColor:UIColorFromRGB(0xb2b2b2) forState:UIControlStateNormal];
        [_deletedBtn.titleLabel setFont:[UIFont systemFontOfSize:14]];
        [_deletedBtn addTarget:self action:@selector(deleteEffectAction:) forControlEvents:UIControlEventTouchUpInside];
        _deletedBtn.hidden = YES;
    }
    return _deletedBtn;
}

- (UIButton *)cancelBtn {
    if(!_cancelBtn){
        _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelBtn.backgroundColor = [UIColor clearColor];
        _cancelBtn.frame = CGRectMake(_addBtn.frame.origin.x - 24 - 65, self.bounds.size.height/2.0 + (self.bounds.size.height/2.0 - 27)/2.0+5, 65, 27);
        _cancelBtn.layer.borderColor = UIColorFromRGB(0xb2b2b2).CGColor;
        _cancelBtn.layer.borderWidth = 1.0;
        _cancelBtn.layer.cornerRadius = _cancelBtn.bounds.size.height/2.0;
        _cancelBtn.layer.masksToBounds = YES;
        [_cancelBtn setTitle:RDLocalizedString(@"取消", nil) forState:UIControlStateNormal];
        [_cancelBtn setTitleColor:UIColorFromRGB(0xb2b2b2) forState:UIControlStateNormal];
        [_cancelBtn.titleLabel setFont:[UIFont systemFontOfSize:14]];
        _cancelBtn.hidden = YES;
        [_cancelBtn addTarget:self action:@selector(cancelEffectAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}

-(UIButton *)editBtn
{
    if(!_editBtn){
        _editBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _editBtn.backgroundColor = [UIColor clearColor];
        _editBtn.frame = CGRectMake(_addBtn.frame.origin.x - 24 - 65, _addBtn.frame.origin.y + (35 - 27)/2.0, 65, 27);
        _editBtn.layer.borderColor = UIColorFromRGB(0xb2b2b2).CGColor;
        _editBtn.layer.borderWidth = 1.0;
        _editBtn.layer.cornerRadius = _editBtn.bounds.size.height/2.0;
        _editBtn.layer.masksToBounds = YES;
        [_editBtn setTitle:RDLocalizedString(@"编辑", nil) forState:UIControlStateNormal];
        [_editBtn setTitleColor:UIColorFromRGB(0xb2b2b2) forState:UIControlStateNormal];
        [_editBtn.titleLabel setFont:[UIFont systemFontOfSize:14]];
        [_editBtn addTarget:self action:@selector(edit_Btn) forControlEvents:UIControlEventTouchUpInside];
        _editBtn.hidden = YES;
    }
    return _editBtn;
}

- (UIView *)doodleConfigView {
    if (!_doodleConfigView) {
        CGRect videoRect = AVMakeRectWithAspectRatioInsideRect(_exportSize, _playerView.bounds);
        _doodleDrawView = [[DrawView alloc] initWithFrame:videoRect];
        [_doodleDrawView setStrokeColor:[UIColor whiteColor]];
        [_doodleDrawView setStrokeWidth:22/2.0];
        [_doodleDrawView clearScreen];
        [_playerView addSubview:_doodleDrawView];
        
        _doodleConfigView = [[UIView alloc] initWithFrame:self.bounds];
        _doodleConfigView.backgroundColor = TOOLBAR_COLOR;
        [self addSubview:_doodleConfigView];
        
        float space = (_doodleConfigView.frame.size.height - 30*3)/4.0;
        
        UILabel *alphaLbl = [[UILabel alloc] initWithFrame:CGRectMake(20, space, 50, 30)];
        alphaLbl.textColor = UIColorFromRGB(0x888888);
        alphaLbl.textAlignment = NSTextAlignmentLeft;
        alphaLbl.font = [UIFont systemFontOfSize:12];
        alphaLbl.text = RDLocalizedString(@"透明度", nil);
        [_doodleConfigView addSubview:alphaLbl];
        
        alphaSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(50+20, space, _doodleConfigView.frame.size.width - 140, 30)];
        [alphaSlider setMaximumValue:1];
        [alphaSlider setMinimumValue:0];
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        [alphaSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        alphaSlider.layer.cornerRadius = 2.0;
        alphaSlider.layer.masksToBounds = YES;
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [alphaSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [alphaSlider setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
        alphaSlider.backgroundColor = [UIColor clearColor];
        alphaSlider.tag = 1;
        [alphaSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        [_doodleConfigView addSubview:alphaSlider];
        
        alphaValueLbl = [[UILabel alloc] initWithFrame:CGRectMake((_doodleConfigView.frame.size.width - 70), space, 50, 30)];
        alphaValueLbl.textColor = UIColorFromRGB(0x888888);
        alphaValueLbl.textAlignment = NSTextAlignmentCenter;
        alphaValueLbl.font = [UIFont systemFontOfSize:13];
        alphaValueLbl.backgroundColor = [UIColor clearColor];
        [_doodleConfigView addSubview:alphaValueLbl];
        
        float ItemBtnWidth = [RDHelpClass widthForString:RDLocalizedString(@"描边", nil) andHeight:12 fontSize:12];
        UILabel * thicknessLbl = [[UILabel alloc] initWithFrame:CGRectMake(20, space*2 + 30, ItemBtnWidth, 30)];
        thicknessLbl.textColor = UIColorFromRGB(0x888888);
        thicknessLbl.text = RDLocalizedString(@"描边", nil);
        thicknessLbl.font = [UIFont systemFontOfSize:12];
        thicknessLbl.textAlignment = NSTextAlignmentLeft;
        [_doodleConfigView addSubview:thicknessLbl];
        
        UIImageView *thinIV = [[UIImageView alloc] initWithFrame:CGRectMake(thicknessLbl.frame.size.width + 5 + thicknessLbl.frame.origin.x, thicknessLbl.frame.origin.y + 5, 20, 20)];
        thinIV.image = [RDHelpClass imageWithContentOfFile:@"jianji/字幕边框-细"];
        [_doodleConfigView addSubview:thinIV];
        
        thicknessSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(thinIV.frame.size.width + thinIV.frame.origin.x + 5, thicknessLbl.frame.origin.y, _doodleConfigView.frame.size.width - (thinIV.frame.size.width + thinIV.frame.origin.x + 5 + 20 + 30), 30)];
        [thicknessSlider setMaximumValue:22];
        [thicknessSlider setMinimumValue:1];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        [thicknessSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        thicknessSlider.layer.cornerRadius = 2.0;
        thicknessSlider.layer.masksToBounds = YES;
        [thicknessSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [thicknessSlider setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
        thicknessSlider.backgroundColor = [UIColor clearColor];
        thicknessSlider.tag = 2;
        [thicknessSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        [_doodleConfigView addSubview:thicknessSlider];
        
        UIImageView * thickIV = [[UIImageView alloc] initWithFrame:CGRectMake((_doodleConfigView.frame.size.width - 45), thicknessLbl.frame.origin.y + 5, 20, 20)];
        thickIV.image = [RDHelpClass imageWithContentOfFile:@"jianji/字幕边框-粗"];
        [_doodleConfigView addSubview:thickIV];

        colorControl = [[SubtitleColorControl alloc] initWithFrame:CGRectMake(50, space*3 + 30*2, _doodleConfigView.frame.size.width - 50 - 20, 30) Colors:self.colorArray CurrentColor:[UIColor whiteColor] atisDefault:TRUE];
        colorControl.delegate = self;
        [_doodleConfigView addSubview:colorControl];
        
        UIButton *cancelDoodleBtn = [[UIButton alloc] initWithFrame:CGRectMake(15, colorControl.frame.origin.y, 30, 30)];
        [cancelDoodleBtn setImage: [RDHelpClass imageWithContentOfFile:@"jianji/字幕颜色-撤销"]  forState:UIControlStateNormal];
        [cancelDoodleBtn addTarget:self action:@selector(cancelDoodleBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_doodleConfigView addSubview:cancelDoodleBtn];
        
        [alphaSlider setValue:1.0];
        alphaValueLbl.text = [NSString stringWithFormat:@"%.1lf%%",alphaSlider.value*100.0];
        [thicknessSlider setValue:22/2.0];
        [colorControl setValue:[UIColor whiteColor]];
    }
    
    return _doodleConfigView;
}

- (NSMutableArray *)colorArray {
    if (!_colorArray) {
        _colorArray = [NSMutableArray array];
        
        [_colorArray addObject:[UIColor clearColor]];
        [_colorArray addObject:UIColorFromRGB(0xffffff)];
        [_colorArray addObject:UIColorFromRGB(0xf9edb1)];
        [_colorArray addObject:UIColorFromRGB(0xffa078)];
        [_colorArray addObject:UIColorFromRGB(0xfe6c6c)];
        [_colorArray addObject:UIColorFromRGB(0xfe4241)];
        [_colorArray addObject:UIColorFromRGB(0x7cddfe)];
        [_colorArray addObject:UIColorFromRGB(0x41c5dc)];
        
        [_colorArray addObject:UIColorFromRGB(0x0695b5)];
        [_colorArray addObject:UIColorFromRGB(0x2791db)];
        [_colorArray addObject:UIColorFromRGB(0x0271fe)];
        [_colorArray addObject:UIColorFromRGB(0xdcffa3)];
        [_colorArray addObject:UIColorFromRGB(0xc7fe64)];
        [_colorArray addObject:UIColorFromRGB(0x82e23a)];
        [_colorArray addObject:UIColorFromRGB(0x25ba66)];
        [_colorArray addObject:UIColorFromRGB(0x017e54)];
        
        [_colorArray addObject:UIColorFromRGB(0xfdbacc)];
        [_colorArray addObject:UIColorFromRGB(0xff5a85)];
        [_colorArray addObject:UIColorFromRGB(0xff5ab0)];
        [_colorArray addObject:UIColorFromRGB(0xb92cec)];
        [_colorArray addObject:UIColorFromRGB(0x7e01ff)];
        [_colorArray addObject:UIColorFromRGB(0x848484)];
        [_colorArray addObject:UIColorFromRGB(0x88754d)];
        [_colorArray addObject:UIColorFromRGB(0x164c6e)];
    }
    return _colorArray;
}

#pragma mark- 控件类型切换
- (void)setCurrentEffect:(RDAdvanceEditType)currentEffect
{
    _addBtn.hidden = NO;
    _trimmerView.hidden = YES;
    _cancelBtn.hidden = YES;
    _editBtn.hidden = YES;
    _finishBtn.hidden = YES;
    _deletedBtn.hidden = YES;
    _speechRecogBtn.hidden = YES;
    
    _currentEffect = currentEffect;
    
    if( _durationTimeLbl )
        _durationTimeLbl.text = [RDHelpClass timeToStringFormat: _thumbnailCoreSDK.duration];
    
    switch ( currentEffect ) {
        case RDAdvanceEditType_Subtitle:        //文字
        {
            __block BOOL isHidden = YES;
            [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.fileType == kFILEVIDEO && !obj.isReverse) {
                    isHidden = NO;
                    *stop = YES;
                }
            }];
            if (!isHidden) {
                self.speechRecogBtn.hidden = NO;
                _speechRecogBtn.selected = NO;
            }else {
                self.speechRecogBtn.selected = YES;
            }
            _trimmerView = self.subtitleTrimmerView;
            [self touchescurrentCaptionView:_trimmerView showOhidden:NO startTime:0.0];
            [self checkSubtitleIconDownload];
            if( self.pasterView )
            self.pasterView.hidden = YES;
        }
            break;
        case RDAdvanceEditType_Sticker:     //贴纸
        {
            _trimmerView = self.stickerTrimmerView;
            [self touchescurrentCaptionView:_trimmerView showOhidden:NO startTime:0.0];
            [self checkStickerIconDownload];
            if( self.pasterView )
                self.pasterView.hidden = YES;
        }
            break;
        case RDAdvanceEditType_Dewatermark: //去水印
        {
            _trimmerView = self.dewatermarkTrimmerView;
        }
            break;
        case RDAdvanceEditType_Collage:     //画中画
        {
            _trimmerView = self.collageTrimmerView;
        }
            break;
        case RDAdvanceEditType_Doodle:
        {
            _trimmerView = self.doodleTrimmerView;
            _doodleDrawView.hidden = YES;
        }
            break;
        case RDAdvanceEditType_Multi_track:
            _trimmerView = self.multi_trackTrimmerView;
            break;
        case RDAdvanceEditType_Sound:
            _trimmerView = self.soundTrimmerView;
            break;
        case RDAdvanceEditType_Effect:
            _trimmerView = self.fXTrimmerView;
            self.fXTrimmerView.isFX  = true;
            break;
        default:
            break;
    }
    _trimmerView.hidden = NO;
    [self addSubview:_trimmerView];
    [self sendSubviewToBack:_trimmerView];
}

#pragma mark - 按钮事件
- (void)speechRecogBtnAction:(UIButton *)sender {
    if (!_requestIdArray) {
        _requestIdArray = [NSMutableArray array];
    }else if (_requestIdArray.count > 0) {
        for (NSDictionary *dic in _requestIdArray) {
            [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(getSpeechRecogCallBackWithDic:) object:dic];
        }
        [_requestIdArray removeAllObjects];
    }
    if (_delegate && [_delegate respondsToSelector:@selector(prepareSpeechRecog)]) {
        [_delegate prepareSpeechRecog];
    }
}

- (void)addEffectAction:(UIButton *)sender {
    if (_isEdittingEffect) {
        [self finishEffectAction:nil];
    }
    _trimmerView.currentCaptionView = nil;
    _cancelBtn.hidden = NO;
//    self.trimmerView.isTiming = YES;
    switch (_currentEffect) {
        case RDAdvanceEditType_Effect:
        {
            if( !self.fXConfigView )
            {
                [self initFXView];
            }
            self.fXConfigView.hidden = NO;
        }
            break;
        case RDAdvanceEditType_Doodle:
        {
            _doodleDrawView.hidden = NO;
            _doodleConfigView.hidden = NO;
            [self.trimmerView addCapation:nil type:1 captionDuration:0];
            self.trimmerView.rangeSlider.hidden = YES;
        }
            break;
        case RDAdvanceEditType_Subtitle:
            [self addSubtitle];
            _editBtn.hidden = YES;
            _speechRecogBtn.hidden = YES;
            
//            _cancelBtn.hidden = YES;
            break;
        case RDAdvanceEditType_Sticker:
            [self addSticker];
            break;
        case RDAdvanceEditType_Dewatermark:
            [self addDewatermark];
            break;
        case RDAdvanceEditType_Collage:
            self.currentCollage = nil;
            [self updateSyncLayerPositionAndTransform];
            [self.trimmerView addCapation:nil type:1 captionDuration:0];
            break;
        case RDAdvanceEditType_Multi_track://多段配乐
        case RDAdvanceEditType_Sound:      //音效
        {
            if(  _currentEffect != RDAdvanceEditType_Sound )
            {
                RDChooseMusic *cloudMusic = [[RDChooseMusic alloc] init];
                
                [cloudMusic setTitile:@"选择配乐"];
                cloudMusic.isNOSound = YES;
                cloudMusic.isLocal = YES;
                
                cloudMusic.soundMusicTypeResourceURL = ((RDNavigationViewController *)((RDNavigationViewController*)_delegate).navigationController).editConfiguration.soundMusicTypeResourceURL;
                cloudMusic.soundMusicResourceURL = ((RDNavigationViewController *)((RDNavigationViewController*)_delegate).navigationController).editConfiguration.soundMusicResourceURL;
                cloudMusic.selectedIndex = 0;
                cloudMusic.cloudMusicResourceURL = ((RDNavigationViewController *)((RDNavigationViewController*)_delegate).navigationController).editConfiguration.cloudMusicResourceURL;
                cloudMusic.backBlock = ^{
                   //关闭
                    [self cancelEffectAction:nil];
                    self.trimmerView.rangeSlider.hidden = YES;
                    self.cancelBtn.hidden = YES;
                    self.deletedBtn.hidden = YES;
                };
                cloudMusic.selectCloudMusic = ^(RDMusic *music) {
                   //添加
                    self.trimmerView.rangeSlider.hidden= YES;
                    [self.trimmerView changeMulti_trackCurrentRangeviewFile:music captionView:nil];
                    self.addBtn.hidden = YES;
                    self.finishBtn.hidden = NO;
                    self.cancelBtn.hidden = NO;
                    self.trimmerView.rangeSlider.hidden= YES;
                    if (self.delegate && [self.delegate respondsToSelector:@selector(addingMusic:)]) {
                        [self.delegate addingMusic:music];
                    }
                };
                [self.trimmerView addCapation:nil type:1 captionDuration:0];
                [((RDNavigationViewController*)_delegate).navigationController pushViewController:cloudMusic animated:NO];
            }
            else
            {
                __block RDSoundDChooseMusic *cloudMusic = [[RDSoundDChooseMusic alloc] initWithFrame:CGRectMake(0, kHEIGHT/2.0, kWIDTH, kHEIGHT/2.0)];
                
                
                cloudMusic.soundMusicTypeResourceURL = ((RDNavigationViewController *)((RDNavigationViewController*)_delegate).navigationController).editConfiguration.soundMusicTypeResourceURL;
                cloudMusic.soundMusicResourceURL = ((RDNavigationViewController *)((RDNavigationViewController*)_delegate).navigationController).editConfiguration.soundMusicResourceURL;
                cloudMusic.selectedIndex = 0;
                cloudMusic.cloudMusicResourceURL = ((RDNavigationViewController *)((RDNavigationViewController*)_delegate).navigationController).editConfiguration.cloudMusicResourceURL;
                cloudMusic.backBlock = ^{
                   //关闭
                    [self cancelEffectAction:nil];
                    
                    self.trimmerView.rangeSlider.hidden = YES;
                    self.cancelBtn.hidden = YES;
                    self.deletedBtn.hidden = YES;
                    
                    [RDHelpClass animateViewHidden:cloudMusic atUP:NO atBlock:^{
                        [cloudMusic removeFromSuperview];
                        cloudMusic = nil;
                    }];
                    
                    
                };
                cloudMusic.selectCloudMusic = ^(RDMusic *music) {
                   //添加
                    self.trimmerView.rangeSlider.hidden= YES;
                    [self.trimmerView changeMulti_trackCurrentRangeviewFile:music captionView:nil];
                    self.addBtn.hidden = YES;
                    self.finishBtn.hidden = NO;
                    self.cancelBtn.hidden = NO;
                    self.trimmerView.rangeSlider.hidden= YES;
                    if (self.delegate && [self.delegate respondsToSelector:@selector(addingMusic:)]) {
                        [self.delegate addingMusic:music];
                    }
                    [RDHelpClass animateViewHidden:cloudMusic atUP:NO atBlock:^{
                        [cloudMusic removeFromSuperview];
                        cloudMusic = nil;
                    }];
                };
                cloudMusic.viewController = ((RDNavigationViewController*)_delegate);
                cloudMusic.navigationController = (RDNavigationViewController *)((RDNavigationViewController*)_delegate).navigationController;
                [cloudMusic setTitile:@"选择音效"];
                cloudMusic.isNOSound = NO;
                cloudMusic.isLocal = NO;
                [cloudMusic viewDidLoad];
                [((UIViewController*)self.delegate).view addSubview:cloudMusic];
                [self.trimmerView addCapation:nil type:1 captionDuration:0];
//                [((RDNavigationViewController*)_delegate).navigationController pushViewController:cloudMusic animated:NO];
//                [self.trimmerView addCapation:nil type:1 captionDuration:0];
                cloudMusic.frame = CGRectMake(cloudMusic.frame.origin.x, kHEIGHT, cloudMusic.frame.size.width, cloudMusic.frame.size.height);
                [UIView animateWithDuration:0.25 animations:^{
                    cloudMusic.frame = CGRectMake(cloudMusic.frame.origin.x, kHEIGHT/2.0, cloudMusic.frame.size.width, cloudMusic.frame.size.height);
                } completion:^(BOOL finished) {
                    if( finished )
                    {
                        cloudMusic.hidden = NO;
                        self.hidden = NO;
                    }
                }];
            }
            
        }
            break;
        default:
            break;
    }
    
    [_trimmerView.scrollView setContentOffset:CGPointMake(_trimmerView.scrollView.contentOffset.x, _trimmerView.scrollView.contentOffset.y) animated:NO];//20171019 wuxiaoxia 滚动过程中点击“添加字幕”时，让滚动条立即停止滚动
    
    _deletedBtn.hidden = YES;
    _addBtn.hidden = YES;
    _finishBtn.hidden = NO;
    if (_delegate && [_delegate respondsToSelector:@selector(addMaterialEffect)]) {
        [_delegate addMaterialEffect];
    }
}

- (void)cancelEffectAction:(UIButton *)sender {
    
    if( _currentCollage )
    {
        _currentCollage = nil;
        if( _delegate && [_delegate respondsToSelector:@selector(collage_initPlay)] )
        {
            [_delegate collage_initPlay];
            
        }
    }
    _isSettingEffect = NO;
    _editBtn.hidden = YES;
    _cancelBtn.hidden = YES;
    _finishBtn.hidden = YES;
    _deletedBtn.hidden = YES;
    _editBtn.hidden = YES;
    _addBtn.hidden = NO;
    if (_currentEffect == RDAdvanceEditType_Subtitle) {
        _speechRecogBtn.hidden = _speechRecogBtn.selected;
    }
    [_doodleDrawView clearScreen];
    _doodleDrawView.hidden = YES;
    _doodleConfigView.hidden = YES;
    _albumView.hidden = YES;
    _albumTitleView.hidden = YES;
    [_syncContainer removeFromSuperview];
    _syncContainer = nil;
    [_pasterView removeFromSuperview];
    _pasterView = nil;
    if (_delegate && [_delegate respondsToSelector:@selector(cancelMaterialEffect)]) {
        [_delegate cancelMaterialEffect];
    }
    [_dewatermarkRectView removeFromSuperview];
    _dewatermarkRectView = nil;
    _dewatermarkTypeView.hidden = YES;
}

- (void)finishEffectAction:(UIButton *)sender {
     if( _dragTimeView )
         _dragTimeView.hidden = YES;
    if (_currentEffect == RDAdvanceEditType_Sticker) {
        if( self.stickerConfigView.pasterTextView )
            [self saveSubtitleOrEffectWithPasterView:self.stickerConfigView.pasterTextView];
    }else if (_currentEffect == RDAdvanceEditType_Subtitle) {
        if( self.subtitleConfigView.pasterTextView )
            [self saveSubtitleOrEffectWithPasterView:self.subtitleConfigView.pasterTextView];
    }else if (_currentEffect == RDAdvanceEditType_Collage) {
        [self addCollageFinishAction:sender];
    }
    
    self.trimmerView.isTiming = false;
    
    if (_currentEffect != RDAdvanceEditType_Collage) {
        
       
        
        NSMutableArray *__strong arr = [_trimmerView getTimesFor_videoRangeView_withTime];
        
        NSMutableArray *newEffectArray = [NSMutableArray array];
        NSMutableArray <RDCaptionRangeViewFile *>* newFileArray = [NSMutableArray array];
        NSMutableArray *newEffectArray1 = [NSMutableArray array];
        NSMutableArray <RDCaptionRangeViewFile *>* newFileArray1 = [NSMutableArray array];
        NSMutableArray *newEffectArray2 = [NSMutableArray array];
        NSMutableArray <RDCaptionRangeViewFile *>* newFileArray2 = [NSMutableArray array];
        for(CaptionRangeView *view in arr){
            CMTimeRange timeRange = CMTimeRangeMake(CMTimeAdd(view.file.timeRange.start, CMTimeMakeWithSeconds(_trimmerView.piantouDuration, TIMESCALE)), view.file.timeRange.duration);
            if(CMTimeGetSeconds(timeRange.duration)==0){
                [view removeFromSuperview];
                continue;
            }
            switch (_currentEffect) {
                case RDAdvanceEditType_Effect:
                {
                    RDFXFilter *fxFilter= view.file.customFilter;
                    if(fxFilter){
                        if( (fxFilter.FXTypeIndex == 1) || (fxFilter.FXTypeIndex == 2) )
                        {
                            fxFilter.customFilter.timeRange = view.file.timeRange;
                        }
                        
                        [newEffectArray addObject:fxFilter];
                        [newFileArray addObject:view.file];
                    }
                }
                    break;
                case RDAdvanceEditType_Subtitle:
                {
                    RDCaption *ppcaption= view.file.caption;
                    if(ppcaption){
                        if( !self.subtitleConfigView.pasterTextView )
                        {
                            ppcaption.timeRange = timeRange;
                        }
                        else
                        {
                            ppcaption.timeRange = timeRange;
                            ppcaption.position    = view.file.centerPoint;
                            ppcaption.imageAnimate.inType = [RDHelpClass captionAnimateToRDCaptionAnimate:(CaptionAnimateType)view.file.caption.imageAnimate.inType];
                            ppcaption.imageAnimate.outType = [RDHelpClass captionAnimateToRDCaptionAnimate:(CaptionAnimateType)view.file.caption.imageAnimate.outType];
                            ppcaption.music       = nil;
                            ppcaption.angle       = view.file.rotationAngle;
                            ppcaption.scale       = view.file.scale;
                            ppcaption.tColor      = view.file.tColor ? view.file.tColor : view.file.caption.tColor;
                            ppcaption.strokeColor = view.file.strokeColor ? view.file.strokeColor : view.file.caption.strokeColor;
                            if(view.file.caption.frameArray.count>0)
                                ppcaption.frameArray      = @[view.file.caption.frameArray[0]];
                            ppcaption.pText = view.file.captionText;
                        }
                        
                        [newEffectArray addObject:ppcaption];
                        [newFileArray addObject:view.file];
                    }
                }
                    break;
                case RDAdvanceEditType_Sticker:
                {
                    RDCaption *ppcaption= view.file.caption;
                    if(ppcaption){
                        
                        if( !self.stickerConfigView.pasterTextView )
                        {
                            ppcaption.timeRange  = timeRange;
                        }
                        else
                        {
                            ppcaption.timeRange   = timeRange;
                            ppcaption.position    = view.file.centerPoint;
                            ppcaption.music       = nil;
                            ppcaption.angle       = view.file.rotationAngle;
                            ppcaption.tFontSize   = view.file.caption.tFontSize;
                            ppcaption.scale       = view.file.scale;
                            ppcaption.tColor      = view.file.tColor ? view.file.tColor : view.file.caption.tColor;
                            ppcaption.strokeColor = view.file.strokeColor ? view.file.strokeColor : view.file.caption.strokeColor;
                            ppcaption.tFontName   = view.file.fontName;
                            ppcaption.pText       = view.titleLabel.text;
                        }
                        [newEffectArray addObject:ppcaption];
                        [newFileArray addObject:view.file];
                    }
                    _stickerConfigView.hidden = YES;
                }
                    break;
                case RDAdvanceEditType_Dewatermark:
                {
                    if (_dewatermarkRectView) {
                        CGRect rect = [self.dewatermarkRectView getclipRect];
                        
                        CaptionRangeView *view = self.trimmerView.currentCaptionView;
                        if (view.file.blur) {
                            RDAssetBlur *blur = view.file.blur;
                            blur.intensity = self.dewatermakSlider.value;
                            [blur setPointsLeftTop:rect.origin
                                          rightTop:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y)
                                       rightBottom:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height)
                                        leftBottom:CGPointMake(rect.origin.x, rect.origin.y + rect.size.height)];
                        }else if (view.file.mosaic) {
                            RDMosaic *mosaic = view.file.mosaic;
                            mosaic.mosaicSize = self.dewatermakSlider.value;
                            [mosaic setPointsLeftTop:rect.origin
                                            rightTop:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y)
                                         rightBottom:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height)
                                          leftBottom:CGPointMake(rect.origin.x, rect.origin.y + rect.size.height)];
                        }else {
                            RDDewatermark *dewatermark = view.file.dewatermark;
                            if (dewatermark) {
                                dewatermark.rect = rect;
                            }
                        }
                        if (sender) {
                            _isSettingEffect = NO;
                            [self.trimmerView saveCurrentRangeview:YES];
                        }else {
                            [self.trimmerView saveCurrentRangeview:NO];
                        }
                        _dewatermarkTypeView.hidden = YES;
                        [_dewatermarkRectView removeFromSuperview];
                        _dewatermarkRectView = nil;
                    }
                    if (view.file.blur) {
                        RDAssetBlur *blur = view.file.blur;
                        blur.timeRange = timeRange;
                        [newEffectArray addObject:blur];
                        [newFileArray addObject:view.file];
                    }else if (view.file.mosaic) {
                        RDMosaic *mosaic= view.file.mosaic;
                        mosaic.timeRange = timeRange;
                        [newEffectArray1 addObject:mosaic];
                        [newFileArray1 addObject:view.file];
                    }else if (view.file.dewatermark) {
                        RDDewatermark *dewatermark = view.file.dewatermark;
                        dewatermark.timeRange = timeRange;
                        [newEffectArray2 addObject:dewatermark];
                        [newFileArray2 addObject:view.file];
                    }
                }
                case RDAdvanceEditType_Doodle:
                {
                    RDWatermark *doodle = view.file.doodle;
                    if (doodle) {
                        doodle.timeRange = timeRange;
                        doodle.vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, doodle.timeRange.duration);
                        
                        [newEffectArray addObject:doodle];
                        [newFileArray addObject:view.file];
                    }
                }
                    break;
                case RDAdvanceEditType_Multi_track: //多段配乐
                case RDAdvanceEditType_Sound:       //音效
                {
                    RDMusic *music= view.file.music;
                    if(music){
                        music.effectiveTimeRange = timeRange;
                        [newEffectArray addObject:music];
                        [newFileArray addObject:view.file];
                    }
                }
                    break;
                default:
                    break;
            }
        }
        if (_currentEffect == RDAdvanceEditType_Dewatermark) {
            if (_delegate && [_delegate respondsToSelector:@selector(updateDewatermark:newBlurFileArray:newMosaicArray:newMosaicArray:newDewatermarkArray:newDewatermarkFileArray:isSaveEffect:)]) {
                [_delegate updateDewatermark:newEffectArray newBlurFileArray:newFileArray newMosaicArray:newEffectArray1 newMosaicArray:newFileArray1 newDewatermarkArray:newEffectArray2 newDewatermarkFileArray:newFileArray2 isSaveEffect:(sender ? YES : NO)];
            }
        }else if (_delegate && [_delegate respondsToSelector:@selector(updateMaterialEffect:newFileArray:isSaveEffect:)]) {
            [_delegate updateMaterialEffect:newEffectArray newFileArray:newFileArray isSaveEffect:(sender ? YES : NO)];
        }
    }
    
    if( (RDAdvanceEditType_Dewatermark !=  _currentEffect)
       && (RDAdvanceEditType_Subtitle !=  _currentEffect)
       && (RDAdvanceEditType_Sticker !=  _currentEffect)
       )
        [_trimmerView saveCurrentRangeview:NO];
    
//    if (_trimmerView.progress < 1.0) {
        _addBtn.hidden = NO;
//    }else {
//        _addBtn.hidden = YES;
//    }
    if (_currentEffect == RDAdvanceEditType_Subtitle) {
        if( self.subtitleConfigView.pasterTextView )
        {
            [self.subtitleConfigView.pasterTextView removeFromSuperview];
            self.subtitleConfigView.pasterTextView  = nil;
            [self.subtitleConfigView clear];
            [self.subtitleConfigView removeFromSuperview];
            self.subtitleConfigView = nil;
            [self.syncContainer removeFromSuperview];
            self.trimmerView.rangeSlider.hidden = YES;
        }
        _speechRecogBtn.hidden = _speechRecogBtn.selected;
    }
    _trimmerView.currentCaptionView = nil;
    _finishBtn.hidden = YES;
    _deletedBtn.hidden = YES;
    _cancelBtn.hidden = YES;
    _editBtn.hidden = YES;
    
//    if (sender) {
//        _trimmerView.rangeSlider.hidden = YES;
//    }
    _trimmerView.isJumpTail = false;
    _oldMaterialEffectFile = nil;
}

- (void)deleteEffectAction:(UIButton *)sender {
    _currentCollage = nil;
    
    [_pasterView removeFromSuperview];
    _pasterView = nil;
    [_syncContainer removeFromSuperview];
    _syncContainer = nil;
    _trimmerView.rangeSlider.hidden= YES;
    _addBtn.hidden = NO;
    if (_currentEffect == RDAdvanceEditType_Subtitle) {
        _speechRecogBtn.hidden = _speechRecogBtn.selected;
    }
    _deletedBtn.hidden = YES;
    _finishBtn.hidden = YES;
    _cancelBtn.hidden = YES;
    _editBtn.hidden = YES;
    [_dewatermarkRectView removeFromSuperview];
    _dewatermarkRectView = nil;
    
    if (_isAddingEffect) {
        [_trimmerView getcurrentCaption:_currentMaterialEffectIndex];
    }
    _oldMaterialEffectFile = nil;
    if (_delegate && [_delegate respondsToSelector:@selector(deleteMaterialEffect)]) {
        [_delegate deleteMaterialEffect];
    }
}

- (void)editAddedEffect {
    [self.stickerConfigView setContentTextFieldText: @""];
    [self.stickerConfigView.pasterTextView removeFromSuperview];
    self.stickerConfigView.pasterTextView = nil;
    [self.stickerConfigView removeFromSuperview];
    self.stickerConfigView = nil;
    
    if (_isEdittingEffect) {
        [self finishEffectAction:nil];
    }

    CaptionRangeView * currentRangeView = [_trimmerView getcurrentCaptionFromId:_currentMaterialEffectIndex];
//    [_trimmerView.scrollView setContentOffset:CGPointMake(_trimmerView.currentCaptionView.frame.origin.x, 0) animated:NO];
    _oldMaterialEffectFile = [currentRangeView.file mutableCopy];
    
    switch (_currentEffect) {
        case RDAdvanceEditType_Collage:
            
            [self editCollage];
            _editBtn.hidden = NO;
            
            break;
        case RDAdvanceEditType_Dewatermark:
            [self editDewatermark];
            break;
        case RDAdvanceEditType_Sticker:
        case RDAdvanceEditType_Subtitle:
        {
            self.trimmerView.scrollView.scrollEnabled = YES;
//            CaptionRangeView * currentRangeView = [self.trimmerView getcurrentCaptionFromId:self.currentMaterialEffectIndex];
//            [self.trimmerView getcurrentCaption:currentRangeView.file.captionId];
//            self.oldMaterialEffectFile = [currentRangeView.file mutableCopy];
            _editBtn.hidden = NO;
        }
            break;
        case RDAdvanceEditType_Doodle:
//            [_trimmerView getcurrentCaptionFromId:_currentMaterialEffectIndex];
//            [_trimmerView.scrollView setContentOffset:CGPointMake(_trimmerView.currentCaptionView.frame.origin.x, 0) animated:NO];
            break;
        default:
            break;
    }
    _addBtn.hidden = YES;
    _finishBtn.hidden = NO;
    _deletedBtn.hidden = NO;
    _speechRecogBtn.hidden = YES;
}

-(void)edit_Btn
{
    _speechRecogBtn.hidden = YES;
    _isEdittingEffect = YES;
    switch ( _currentEffect) {
        case RDAdvanceEditType_Subtitle:
            [self editSubtitle];
            break;
        case RDAdvanceEditType_Sticker:
            [self editSticker];
            break;
        case RDAdvanceEditType_Dewatermark:
            [self editDewatermark];
            break;
        case RDAdvanceEditType_Collage:
            
            [self editCollage_Features];
            
            break;
        default:
            break;
    }
}

- (void)discardEdit {
#if 0
    if( _currentEffect == RDAdvanceEditType_Dewatermark )
    {
        NSMutableArray *__strong arr = [_trimmerView getTimesFor_videoRangeView_withTime];
        
        NSMutableArray *newEffectArray = [NSMutableArray array];
        NSMutableArray <RDCaptionRangeViewFile *>* newFileArray = [NSMutableArray array];
        NSMutableArray *newEffectArray1 = [NSMutableArray array];
        NSMutableArray <RDCaptionRangeViewFile *>* newFileArray1 = [NSMutableArray array];
        for(CaptionRangeView *view in arr){
            RDCaption *ppcaption= view.file.caption;
            RDDewatermark *dewatermark = view.file.dewatermark;
            RDMusic * music = view.file.music;
            if(ppcaption){
                ppcaption.timeRange   = CMTimeRangeMake(CMTimeAdd(view.file.timeRange.start, CMTimeMakeWithSeconds(_trimmerView.piantouDuration, TIMESCALE)), view.file.timeRange.duration);
                if(CMTimeGetSeconds(ppcaption.timeRange.duration)==0){
                    [view removeFromSuperview];
                    continue;
                }
                [newEffectArray1 addObject:ppcaption];
                [newFileArray1 addObject:view.file];
            }else if (dewatermark) {
                dewatermark.timeRange   = CMTimeRangeMake(CMTimeAdd(view.file.timeRange.start, CMTimeMakeWithSeconds(_trimmerView.piantouDuration, TIMESCALE)), view.file.timeRange.duration);
                if(CMTimeGetSeconds(dewatermark.timeRange.duration)==0){
                    [view removeFromSuperview];
                    continue;
                }
                [newEffectArray addObject:dewatermark];
                [newFileArray addObject:view.file];
            }else if (music) {
                music.effectiveTimeRange   = CMTimeRangeMake(CMTimeAdd(view.file.timeRange.start, CMTimeMakeWithSeconds(self.trimmerView.piantouDuration, TIMESCALE)), view.file.timeRange.duration);
                if(CMTimeGetSeconds(music.effectiveTimeRange.duration)==0){
                    [view removeFromSuperview];
                    continue;
                }
                [newEffectArray addObject:music];
                [newFileArray addObject:view.file];
            }
        }
        
        [_trimmerView saveCurrentRangeview:NO];
        if (_delegate && [_delegate respondsToSelector:@selector(updateMaterialEffect:newFileArray:newEffectArray1:newFileArray1:isSaveEffect:)]) {
            [_delegate updateMaterialEffect:newEffectArray newFileArray:newFileArray newEffectArray1:newEffectArray1 newFileArray1:newFileArray1 isSaveEffect:NO];
        }
    }
#endif
//    [_thumbnailCoreSDK cancelImage];
//    [_thumbnailCoreSDK stop];
    switch (_currentEffect) {
        case RDAdvanceEditType_Subtitle:
        {
//            [self pasterViewDidClose:_subtitleConfigView.pasterTextView];
            [_subtitleConfigView clear];
            [_subtitleConfigView.pasterTextView removeFromSuperview];
            _subtitleConfigView.pasterTextView = nil;
            [_subtitleConfigView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            [_subtitleConfigView setContentTextFieldText: @""];
            [_subtitleConfigView removeFromSuperview];
            _subtitleConfigView = nil;
        }
            break;
        case RDAdvanceEditType_Sticker:
        {
            [_stickerConfigView clear];
            [_stickerConfigView.pasterTextView removeFromSuperview];
            _stickerConfigView.pasterTextView = nil;
            [_stickerConfigView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            [_stickerConfigView removeFromSuperview];
            _stickerConfigView = nil;
        }
            break;
        case RDAdvanceEditType_Dewatermark:
        {
            
        }
            break;
        case RDAdvanceEditType_Collage:
        {
            _albumView.frame = self.superview.frame;
            [self refreshAblumScrollViewViewFrame];
            _albumScrollView.contentOffset = CGPointMake(0, 0);
            _albumTitleView.hidden = YES;
            [_pasterView removeFromSuperview];
            _pasterView = nil;
            [_syncContainer removeFromSuperview];
            
            _syncContainer = nil;
        }
            break;
        case RDAdvanceEditType_Doodle:
        {
            [_doodleDrawView clearScreen];
        }
            break;
        default:
            break;
    }
    _dewatermarkTypeView.hidden = YES;
    [_syncContainer removeFromSuperview];
//    [_trimmerView setProgress:0 animated:NO];
    [_trimmerView clearCaptionRangeVew];
    [_trimmerView clear];
    [_trimmerView.frameView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)startMaterialAddEffect {
    switch (_currentEffect) {
        case RDAdvanceEditType_Doodle:
        {
            _doodleConfigView.hidden = YES;
        }
            break;
            
        default:
            break;
    }
    [_trimmerView.scrollView setContentOffset:_trimmerView.scrollView.contentOffset animated:NO];
    
    _currentTimeLbl.hidden = YES;
    _deletedBtn.hidden = YES;
    _subtitleConfigView.hidden = NO;
    _subtitleConfigView.isEditting = NO;
    _subtitleConfigView.inAnimationIndex = 0;
    _subtitleConfigView.outAnimationIndex = 0;
    _subtitleConfigView.captionRangeView = [_trimmerView addCapation:nil type:2 captionDuration:4];
    [_subtitleConfigView clickToolItem:nil];
    [_subtitleConfigView touchescaptionTypeViewChildWithIndex:0];
}

- (void)loadTrimmerViewThumbImage:(UIImage *)image
                   thumbnailCount:(NSInteger)thumbnailCount
                   addEffectArray:(NSMutableArray *)addEffectArray
                     oldFileArray:(NSMutableArray <RDCaptionRangeViewFile *>*)oldFileArray
{
    [addEffectArray removeAllObjects];
    [_trimmerView.frameView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_trimmerView.videoRangeView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    if(_trimmerView){
        [_trimmerView setVideoCore:_thumbnailCoreSDK];
        [_trimmerView setClipTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, TIMESCALE), _thumbnailCoreSDK.composition.duration)];
        _trimmerView.thumbTimes = thumbnailCount;
        [_trimmerView resetSubviews:image];
//        [_trimmerView setProgress:0 animated:NO];
        
        [self refreshAddEffectArray:addEffectArray oldFileArray:oldFileArray index:1];
        [self touchescurrentCaptionView:_trimmerView showOhidden:NO startTime:0.0];
    }
    [_trimmerView cancelCurrent];
}

- (void)loadDewatermarkThumbImage:(UIImage *)image
                   thumbnailCount:(NSInteger)thumbnailCount
                        blurArray:(NSMutableArray *)blurArray
                 oldBlurFileArray:(NSMutableArray<RDCaptionRangeViewFile *> *)oldBlurFileArray
                      mosaicArray:(NSMutableArray *)mosaicArray
               oldMosaicFileArray:(NSMutableArray<RDCaptionRangeViewFile *> *)oldMosaicFileArray
                 dewatermarkArray:(NSMutableArray *)dewatermarkArray
          oldDewatermarkFileArray:(NSMutableArray<RDCaptionRangeViewFile *> *)oldDewatermarkFileArray
{
    [blurArray removeAllObjects];
    [mosaicArray removeAllObjects];
    [dewatermarkArray removeAllObjects];
    [_trimmerView.frameView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_trimmerView.videoRangeView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
    if(_trimmerView){
        [_trimmerView setVideoCore:_thumbnailCoreSDK];
        [_trimmerView setClipTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, TIMESCALE), _thumbnailCoreSDK.composition.duration)];
        _trimmerView.thumbTimes = thumbnailCount;
        [_trimmerView resetSubviews:image];
//        [_trimmerView setProgress:0 animated:NO];
        
        [self refreshAddEffectArray:blurArray oldFileArray:oldBlurFileArray index:1];
        [self refreshAddEffectArray:mosaicArray oldFileArray:oldMosaicFileArray index:2];
        [self refreshAddEffectArray:dewatermarkArray oldFileArray:oldDewatermarkFileArray index:3];
        
        [self touchescurrentCaptionView:_trimmerView showOhidden:NO startTime:0.0];
    }
    [_trimmerView cancelCurrent];
}

- (void)refreshAddEffectArray:(NSMutableArray *)addEffectArray
                 oldFileArray:(NSMutableArray <RDCaptionRangeViewFile *>*)oldFileArray
                        index:(NSInteger)index
{
    for(RDCaptionRangeViewFile *file in oldFileArray){
        RDWatermark *collage = file.collage;
        RDWatermark *doodle = file.doodle;
        RDCaption *caption = file.caption;
        RDAssetBlur *blur = file.blur;
        RDMosaic *mosaic = file.mosaic;
        RDDewatermark *dewaterMark = file.dewatermark;
        RDMusic * music = file.music;
        RDFXFilter * fxFilter = file.customFilter;
        switch (_currentEffect) {
            case RDAdvanceEditType_Subtitle:
            {
                if (CMTimeGetSeconds(caption.timeRange.start) >= _thumbnailCoreSDK.duration) {
                    [oldFileArray removeObject:file];
                    continue;
                }
                [addEffectArray addObject:caption];
            }
                break;
            case RDAdvanceEditType_Sticker:
            {
                if (CMTimeGetSeconds(caption.timeRange.start) >= _thumbnailCoreSDK.duration) {
                    [oldFileArray removeObject:file];
                    continue;
                }
                [addEffectArray addObject:caption];
            }
                break;
            case RDAdvanceEditType_Dewatermark:
            {
                if (index == 1) {
                    if (CMTimeGetSeconds(blur.timeRange.start) >= _thumbnailCoreSDK.duration) {
                        [oldFileArray removeObject:file];
                        continue;
                    }
                    [addEffectArray addObject:blur];
                }
                else if (index == 2) {
                    if (CMTimeGetSeconds(mosaic.timeRange.start) >= _thumbnailCoreSDK.duration) {
                        [oldFileArray removeObject:file];
                        continue;
                    }
                    [addEffectArray addObject:mosaic];
                }else {
                    if (CMTimeGetSeconds(dewaterMark.timeRange.start) >= _thumbnailCoreSDK.duration) {
                        [oldFileArray removeObject:file];
                        continue;
                    }
                    [addEffectArray addObject:dewaterMark];
                }
            }
                break;
            case RDAdvanceEditType_Collage:
            {
                if (CMTimeGetSeconds(collage.timeRange.start) >= _thumbnailCoreSDK.duration) {
                    [oldFileArray removeObject:file];
                    continue;
                }
                [addEffectArray addObject:collage];
            }
                break;
            case RDAdvanceEditType_Doodle:
            {
                if (CMTimeGetSeconds(doodle.timeRange.start) >= _thumbnailCoreSDK.duration) {
                    [oldFileArray removeObject:file];
                    continue;
                }
                [addEffectArray addObject:doodle];
            }
                break;
            case RDAdvanceEditType_Multi_track: //多段配乐
            case RDAdvanceEditType_Sound:       //音效
            {
                if (CMTimeGetSeconds(music.effectiveTimeRange.start) >= _thumbnailCoreSDK.duration) {
                    [oldFileArray removeObject:file];
                    continue;
                }
                [addEffectArray addObject:music];
            }
                break;
            case RDAdvanceEditType_Effect:
            {
                if( fxFilter.customFilter )
                {
                    if (CMTimeGetSeconds(fxFilter.customFilter.timeRange.start) >= _thumbnailCoreSDK.duration) {
                        [oldFileArray removeObject:fxFilter];
                        continue;
                    }
                }
                [addEffectArray addObject:fxFilter];
            }
                break;
            default:
                break;
        }
        
        CaptionRangeView *view = [[CaptionRangeView alloc] init];
        RDCaptionRangeViewFile *newFile = [[RDCaptionRangeViewFile alloc] init];
        
        float width = CMTimeGetSeconds(file.timeRange.duration) * _trimmerView.videoRangeView.frame.size.width/_thumbnailCoreSDK.duration;
        float oginx = (CMTimeGetSeconds(file.timeRange.start)+ _trimmerView.piantouDuration) * _trimmerView.videoRangeView.frame.size.width/_thumbnailCoreSDK.duration;
        if (oginx >=0){
            CGRect rect              = file.home;
            rect.origin.x            = oginx;
            rect.size.width          = width;
            rect.size.height         = _trimmerView.frame.size.height;
            file.home                = rect;
            view.backgroundColor     = Main_Color;
            view.alpha               = 0.8;
            newFile                  = [file copy];
            view.file                = newFile;
            view.frame               = newFile.home;
            [view setTitle:newFile.captionText forState:UIControlStateNormal];
            
            [_trimmerView.videoRangeView addSubview:view];
            
            if( (RDAdvanceEditType_Effect == _currentEffect) && (view.file.customFilter.FXTypeIndex == 5) )
                _trimmerView.timeEffectCapation = view;
            
        }
    }
    [_trimmerView cancelCurrent];
}

- (void)startAddMaterialEffect:(CMTimeRange)timeRange {
    
}

#pragma mark- ===字幕===
- (void)previewCompletion {
    self.subtitleConfigView.pasterTextView.hidden = NO;
    NSMutableArray *arr = [self.trimmerView getTimesFor_videoRangeView_withTime];
    NSMutableArray *newEffectArray = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>* newFileArray = [NSMutableArray array];
    for(CaptionRangeView *view in arr){
        RDCaption *ppcaption= view.file.caption;
        if(ppcaption){
            if (view != self.trimmerView.currentCaptionView) {
                [newEffectArray addObject:ppcaption];
                [newFileArray addObject:view.file];
            }
        }
    }
    if (self.delegate &&[self.delegate respondsToSelector:@selector(updateMaterialEffect:newFileArray:isSaveEffect:)]) {
        [self.delegate updateMaterialEffect:newEffectArray newFileArray:newFileArray isSaveEffect:NO];
    }
}

#pragma mark- 播放按钮操作
- (void)tapPlayButton{
    if ( _isAddingEffect || _isEdittingEffect ) {
        [self finishEffectAction:_finishBtn];
        if( (_currentEffect == RDAdvanceEditType_Collage)
           ||  (_currentEffect == RDAdvanceEditType_Doodle)
            ||  (_currentEffect == RDAdvanceEditType_Multi_track)
           ||  (_currentEffect == RDAdvanceEditType_Sound) )
            _isPlay = true;
        [self performSelector:@selector(Play) withObject:nil afterDelay:0.2];
        
        if(_currentEffect == RDAdvanceEditType_Collage)
        {
            self.editBtn.hidden = YES;
            self.finishBtn.hidden = YES;
            self.deletedBtn.hidden = YES;
            self.EditCollageView.hidden = YES;
            self.addBtn.hidden = NO;
            self.speechRecogBtn.hidden = YES;
        }
    }
    else
    {
        if (_delegate && [_delegate respondsToSelector:@selector(playOrPauseVideo)]) {
            [_delegate playOrPauseVideo];
        }
    }
    
    
}

-(void)Play
{
    if (_delegate && [_delegate respondsToSelector:@selector(playOrPauseVideo)]) {
        [_delegate playOrPauseVideo];
    }
}

- (void)cancelDoodleBtnAction:(UIButton *)sender {
    [_doodleDrawView revokeScreen];
}

- (void)scrub:(RDZSlider *)slider{
    if(slider == alphaSlider){
        alphaValueLbl.text = [NSString stringWithFormat:@"%.1lf%%",slider.value*100];
        [_doodleDrawView setStrokeColor:[colorControl.currentColor colorWithAlphaComponent:slider.value]];
    }else {
        [_doodleDrawView setStrokeWidth:slider.value];
    }
}

#pragma mark - SubtitleColorControlDelegate
-(void)SubtitleColorChanged:(UIColor *) color  Index:(int) index  View:(UIControl *) SELF {
    if (CGColorEqualToColor(color.CGColor, [UIColor clearColor].CGColor)) {
        [_doodleDrawView setStrokeColor:color];
        alphaSlider.value = 0;
        alphaValueLbl.text = @"0.0%";
        alphaSlider.enabled = NO;
    }else {
        [_doodleDrawView setStrokeColor:[color colorWithAlphaComponent:alphaSlider.value]];
        alphaSlider.enabled = YES;
    }
}

#pragma mark- CaptionVideoTrimmerDelegate
- (void)didEndChangeSelectedMinimumValue_maximumValue
{
    NSMutableArray *__strong arr = [_trimmerView getTimesFor_videoRangeView_withTime];
    
    NSMutableArray *newEffectArray = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>* newFileArray = [NSMutableArray array];
    NSMutableArray *newEffectArray1 = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>* newFileArray1 = [NSMutableArray array];
    NSMutableArray *newEffectArray2 = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>* newFileArray2 = [NSMutableArray array];
    for(CaptionRangeView *view in arr){
        CMTimeRange timeRange = CMTimeRangeMake(CMTimeAdd(view.file.timeRange.start, CMTimeMakeWithSeconds(_trimmerView.piantouDuration, TIMESCALE)), view.file.timeRange.duration);
        if(CMTimeGetSeconds(timeRange.duration)==0){
            [view removeFromSuperview];
            continue;
        }
        switch (_currentEffect) {
            case RDAdvanceEditType_Subtitle:
            {
                RDCaption *ppcaption= view.file.caption;
                if(ppcaption){
                    ppcaption.timeRange   = timeRange;
                    [newEffectArray addObject:ppcaption];
                    [newFileArray addObject:view.file];
                }
            }
                break;
            case RDAdvanceEditType_Sticker:
            {
                RDCaption *ppcaption = view.file.caption;
                if(ppcaption){
                    ppcaption.timeRange   = timeRange;
                    [newEffectArray addObject:ppcaption];
                    [newFileArray addObject:view.file];
                }
            }
                break;
            case RDAdvanceEditType_Dewatermark:
            {
                if (view.file.blur) {
                    RDAssetBlur *blur = view.file.blur;
                    blur.timeRange = timeRange;
                    [newEffectArray addObject:blur];
                    [newFileArray addObject:view.file];
                }else if (view.file.mosaic) {
                    RDMosaic *mosaic= view.file.mosaic;
                    mosaic.timeRange   = timeRange;
                    [newEffectArray1 addObject:mosaic];
                    [newFileArray1 addObject:view.file];
                }else if (view.file.dewatermark) {
                    RDDewatermark *dewatermark = view.file.dewatermark;
                    dewatermark.timeRange   = timeRange;
                    [newEffectArray2 addObject:dewatermark];
                    [newFileArray2 addObject:view.file];
                }
            }
                break;
            case RDAdvanceEditType_Collage:
            {
                RDWatermark *collage= view.file.collage;
                if(collage){
                    collage.timeRange   = timeRange;
                    if (collage.vvAsset.type == RDAssetTypeImage) {
                        collage.vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, collage.timeRange.duration);
                    }
                    
                    if( self.currentCollage )
                    {
                        self.currentCollage.timeRange = collage.timeRange;
                        
                        self.currentCollage.vvAsset.timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds( CMTimeGetSeconds(collage.timeRange.start) -  self.trimmerView.rangeSlider.minValue, TIMESCALE), collage.timeRange.duration);
                         if (collage.vvAsset.type == RDAssetTypeVideo) {
                             collage.vvAsset.timeRange = self.currentCollage.vvAsset.timeRange;
                         }
                    }
                    
                    [newEffectArray addObject:collage];
                    [newFileArray addObject:view.file];
                }
            }
                break;
            case RDAdvanceEditType_Doodle:
            {
                RDWatermark *doodle = view.file.doodle;
                if (doodle) {
                    doodle.timeRange = timeRange;
                    doodle.vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, doodle.timeRange.duration);
                    
                    [newEffectArray addObject:doodle];
                    [newFileArray addObject:view.file];
                }
            }
                break;
            case RDAdvanceEditType_Multi_track:
            {
                RDMusic *music= view.file.music;
                if(music){
                    music.effectiveTimeRange   = timeRange;
                    [newEffectArray addObject:music];
                    [newFileArray addObject:view.file];
                }
            }
                break;
            case RDAdvanceEditType_Sound:
            {
                RDMusic *music= view.file.music;
                if(music){
                    music.effectiveTimeRange   = timeRange;
                    [newEffectArray addObject:music];
                    [newFileArray addObject:view.file];
                }
            }
                break;
            case RDAdvanceEditType_Effect:
            {
                RDFXFilter *fxFilter= view.file.customFilter;
                if(fxFilter){
                    if( fxFilter.customFilter )
                        fxFilter.customFilter.timeRange  = timeRange;
                    
                    [newEffectArray addObject:fxFilter];
                    [newFileArray addObject:view.file];
                }
            }
                break;
            default:
                break;
        }        
    }
    
    [_trimmerView saveCurrentRangeview:NO];
//    _addBtn.hidden = NO;
//    _finishBtn.hidden = YES;
//    _deletedBtn.hidden = YES;
//    _cancelBtn.hidden = YES;
    if (_currentEffect == RDAdvanceEditType_Dewatermark) {
        if (_delegate && [_delegate respondsToSelector:@selector(updateDewatermark:newBlurFileArray:newMosaicArray:newMosaicArray:newDewatermarkArray:newDewatermarkFileArray:isSaveEffect:)]) {
            [_delegate updateDewatermark:newEffectArray newBlurFileArray:newFileArray newMosaicArray:newEffectArray1 newMosaicArray:newFileArray1 newDewatermarkArray:newEffectArray2 newDewatermarkFileArray:newFileArray2 isSaveEffect:NO];
        }
    }else if (_delegate && [_delegate respondsToSelector:@selector(updateMaterialEffect:newFileArray:isSaveEffect:)]) {
        [_delegate updateMaterialEffect:newEffectArray newFileArray:newFileArray isSaveEffect:NO];
    }
}

- (void)capationScrollViewWillBegin:(CaptionVideoTrimmerView *)trimmerView
{
    if (_delegate && [_delegate respondsToSelector:@selector(pauseVideo)]) {
        [_delegate pauseVideo];
    }
}

- (void)capationScrollViewWillEnd:(CaptionVideoTrimmerView *)trimmerView
                        startTime:(Float64)capationStartTime
                          endTime:(Float64)capationEndTime
{
    if (_isAddingEffect
//        || _isEdittingEffect
        ) {
//        if (_currentEffect != RDAdvanceEditType_Subtitle) {
            [self finishEffectAction:_finishBtn];
//        }
//        else {
//            CaptionRangeView *view = trimmerView.currentCaptionView;
//            CMTimeRange timeRange = CMTimeRangeMake(CMTimeAdd(view.file.timeRange.start, CMTimeMakeWithSeconds(trimmerView.piantouDuration, TIMESCALE)), view.file.timeRange.duration);
//            if (capationStartTime < CMTimeGetSeconds(timeRange.start) || capationStartTime > CMTimeGetSeconds(CMTimeAdd(timeRange.start, timeRange.duration))) {
//                [self finishEffectAction:_finishBtn];
//            }
//        }
    }else {
        if (_delegate && [_delegate respondsToSelector:@selector(pauseVideo)]) {
            [_delegate pauseVideo];
        }
    }
}

- (void)touchescurrentCaptionView:(CaptionVideoTrimmerView *)trimmerView
                      showOhidden:(BOOL)flag
                        startTime:(Float64)captionStartTime
{
    if (_trimmerView.startTime >= _thumbnailCoreSDK.duration) {
        _addBtn.enabled = NO;
        if( _currentEffect == RDAdvanceEditType_Subtitle  )
        {
            if( _editBtn.hidden )
                _speechRecogBtn.enabled = NO;
        }
    }else {
        if( _currentEffect == RDAdvanceEditType_Subtitle  )
        {
            if( _editBtn.hidden )
                _speechRecogBtn.enabled = YES;
        }
        _addBtn.enabled = YES;
    }
    if([_delegate respondsToSelector:@selector(TimesFor_videoRangeView_withTime:)]){
        [_delegate TimesFor_videoRangeView_withTime:0];
    }
#if 0
    switch (_currentEffect) {
        case RDAdvanceEditType_Subtitle://文字
        case RDAdvanceEditType_Sticker://贴纸
        {
            NSArray *items = [[self.trimmerView getCaptionsViewForcurrentTime:NO] copy];
            RdCanAddCaptionType type = [self.trimmerView checkCanAddCaption];
            if(items.count>=5 || type != kCanAddCaption){
                self.addBtn.enabled = NO;
            }else{
                self.addBtn.enabled = YES;
                if(items.count>=1){
                    flag = NO;
                }else{
                    flag = YES;
                }
            }
            if(!flag){
                self.deletedBtn.hidden = NO;
            }else{
                self.deletedBtn.hidden = YES;
            }
            self.addBtn.hidden = NO;
            if(self.finishBtn.hidden){
                self.deletedBtn.hidden = flag;
            }else{
                self.deletedBtn.hidden = YES;
            }
        }
            break;
        case RDAdvanceEditType_Dewatermark://去水印
        {
            NSArray *items = [_trimmerView getCaptionsViewForcurrentTime:NO];
            RdCanAddCaptionType type = [_trimmerView checkCanAddCaption];
            if(items.count>=5 || type != kCanAddCaption){
                _addBtn.enabled = NO;
            }else{
                _addBtn.enabled = YES;
                if(items.count>=1){
                    flag = NO;
                }else{
                    flag = YES;
                }
            }
            _addBtn.hidden = NO;
        }
            break;
        case RDAdvanceEditType_Collage://画中画
        {
            NSArray *items = [_trimmerView getCaptionsViewForcurrentTime:NO];
            RdCanAddCaptionType type = [_trimmerView checkCanAddCaption];
            if(items.count>=5 || type != kCanAddCaption){
                _addBtn.enabled = NO;
            }else{
                _addBtn.enabled = YES;
                if(items.count>=1){
                    flag = NO;
                }else{
                    flag = YES;
                }
            }
            _addBtn.hidden = NO;
        }
            break;
        default:
            break;
    }
#endif
}

- (void)changeCaptionViewType:(CaptionRangeView *)captionRangeView
{
    CaptionRangeView *rangeView = captionRangeView;
    
    float sc                 = rangeView.file.scale;
    float ppsc               = (rangeView.file.caption.size.width * _exportSize.width)/ (float) rangeView.file.caption.size.width < 1 ? (rangeView.file.caption.size.width * _exportSize.width)/ (float) rangeView.file.caption.size.width : 1;
    CGFloat   radius         = atan2f(rangeView.file.captionTransform.b, rangeView.file.captionTransform.a);
    UIColor  *fontstrokeColor = rangeView.file.caption.strokeColor;
    UIColor  *fontTextColor  = rangeView.file.caption.tColor;
    NSString *fontName       = rangeView.file.caption.tFontName;
//    NSString *fontCode       = rangeView.file.fontCode;//20191227
    float fontSize           = rangeView.file.tFontSize / (_exportSize.width/self.syncContainer.bounds.size.width);//bug：每编辑一次字幕，字幕就会变大
    RDCaptionTextAlignment alignment = rangeView.file.caption.tAlignment;
    CGPoint pushInPoint = rangeView.file.caption.textAnimate.pushInPoint;
    CGPoint pushOutPoint = rangeView.file.caption.textAnimate.pushOutPoint;
    
    BOOL isBold = rangeView.file.caption.isBold;
    BOOL isItalic = rangeView.file.caption.isItalic;
    BOOL isShadow = rangeView.file.caption.isShadow;
    float textAlpha = rangeView.file.caption.textAlpha;
    float strokeAlpha = rangeView.file.caption.strokeAlpha;
    float strokeWidth = rangeView.file.caption.strokeWidth;
    CGSize  tShadowOffset  = rangeView.file.caption.tShadowOffset;
    UIColor  *tShadowColor  = rangeView.file.caption.tShadowColor;
    BOOL isVerticalText = rangeView.file.caption.isVerticalText;
    NSString *captionTextField_text = rangeView.file.captionText;
    NSInteger inAnimateTypeIndex = rangeView.file.inAnimationIndex;
    NSInteger outAnimateTypeIndex = rangeView.file.inAnimationIndex;
    SubtitleScrollView *subtitleConfigEditView;
    if(!subtitleConfigEditView){
        subtitleConfigEditView = [[SubtitleScrollView alloc] initWithFrame:CGRectMake(0, kHEIGHT - 280, kWIDTH, 280)];
        subtitleConfigEditView.fontResourceURL = _editConfiguration.fontResourceURL;
        subtitleConfigEditView.delegate = self;
    }
    subtitleConfigEditView.isEditting = YES;
    subtitleConfigEditView.isBold = isBold;
    subtitleConfigEditView.isItalic = isItalic;
    [subtitleConfigEditView setIsVerticalText:isVerticalText];
    subtitleConfigEditView.isShadow = isShadow;
    subtitleConfigEditView.textAlpha = textAlpha;
    subtitleConfigEditView.strokeWidth = strokeWidth;
    subtitleConfigEditView.strokeAlpha = strokeAlpha;
    subtitleConfigEditView.inAnimationIndex     = rangeView.file.inAnimationIndex;
    subtitleConfigEditView.outAnimationIndex     = rangeView.file.outAnimationIndex;
    subtitleConfigEditView.selectColorItemIndex     = rangeView.file.selectColorItemIndex;
    subtitleConfigEditView.selectBorderColorItemIndex = rangeView.file.selectBorderColorItemIndex;
    subtitleConfigEditView.selectedTypeId        = rangeView.file.selectTypeId;
    subtitleConfigEditView.selectFontItemIndex        = rangeView.file.selectFontItemIndex;
    
    subtitleConfigEditView.captionRangeView = captionRangeView;
    [subtitleConfigEditView setContentTextFieldText:captionTextField_text];
    [subtitleConfigEditView touchescaptionTypeViewChildWithIndex:captionRangeView.file.captiontypeIndex];
    
//    subtitleConfigEditView.pasterTextView.fontCode = fontCode;//20191227
    subtitleConfigEditView.pasterTextView.fontPath = rangeView.file.fontPath;
    subtitleConfigEditView.pasterTextView.contentLabel.fontColor = fontTextColor;
    subtitleConfigEditView.pasterTextView.contentLabel.strokeColor = fontstrokeColor;
    subtitleConfigEditView.pasterTextView.contentLabel.textAlpha = textAlpha;
    subtitleConfigEditView.pasterTextView.contentLabel.strokeAlpha = strokeAlpha;
    subtitleConfigEditView.pasterTextView.contentLabel.strokeWidth = strokeWidth;
    subtitleConfigEditView.pasterTextView.shadowLbl.fontColor = fontTextColor;
    subtitleConfigEditView.pasterTextView.shadowLbl.strokeColor = fontTextColor;
    subtitleConfigEditView.pasterTextView.shadowLbl.textAlpha = textAlpha;
    subtitleConfigEditView.pasterTextView.shadowLbl.strokeAlpha = strokeAlpha;
    subtitleConfigEditView.pasterTextView.shadowLbl.strokeWidth = strokeWidth;
    subtitleConfigEditView.pasterTextView.isBold = isBold;
    subtitleConfigEditView.pasterTextView.isItalic = isItalic;
    subtitleConfigEditView.pasterTextView.isVerticalText = isVerticalText;
    subtitleConfigEditView.pasterTextView.isShadow = isShadow;
    subtitleConfigEditView.pasterTextView.shadowOffset = tShadowOffset;
    subtitleConfigEditView.pasterTextView.shadowColor = tShadowColor;
    [subtitleConfigEditView.pasterTextView setFontName:fontName];
    [subtitleConfigEditView.pasterTextView setFontSize:fontSize];
    [subtitleConfigEditView.pasterTextView setTextString:captionTextField_text adjustPosition:NO];
    [subtitleConfigEditView.pasterTextView setAlignment:(NSTextAlignment)alignment];
    [subtitleConfigEditView.pasterTextView.contentLabel setNeedsDisplay];
    [subtitleConfigEditView.pasterTextView.shadowLbl setNeedsDisplay];
    CGAffineTransform transform2 = CGAffineTransformMakeRotation(radius);
    
    subtitleConfigEditView.pasterTextView.transform = CGAffineTransformScale(transform2, sc*ppsc, sc*ppsc);
    CGPoint center = CGPointMake(self.syncContainer.frame.size.width * rangeView.file.centerPoint.x, self.syncContainer.frame.size.height * rangeView.file.centerPoint.y);
    subtitleConfigEditView.pasterTextView.center = center;
    
    [self.trimmerView changeCurrentRangeviewFile:nil
                                          tColor:fontTextColor
                                     strokeColor:fontstrokeColor
                                        fontName:fontName
                                        fontCode:nil// fontCode
                                       typeIndex:self.trimmerView.currentCaptionView.file.captiontypeIndex
                                       frameSize:CGSizeZero
                                     captionText:captionTextField_text
                                        aligment:alignment
                              inAnimateTypeIndex:inAnimateTypeIndex
                             outAnimateTypeIndex:outAnimateTypeIndex
                                     pushInPoint:pushInPoint
                                    pushOutPoint:pushOutPoint
                                     captionView:captionRangeView];
    if(sc == 1){
        sc = 1.0f;
    }
    float fontScale  = 1.2f * ((sc * ppsc) - 1);
    [subtitleConfigEditView setSubtitleSize:fontScale];
    
    [subtitleConfigEditView.pasterTextView hideEditingHandles];
    subtitleConfigEditView.isEditting = NO;
    
    [_trimmerView changeCurrentRangeviewWithTColor:subtitleConfigEditView.pasterTextView.contentLabel.fontColor
                                             alpha:subtitleConfigEditView.pasterTextView.contentLabel.textAlpha
                                           colorId:subtitleConfigEditView.selectColorItemIndex
                                       captionView:captionRangeView];
    
    [_trimmerView changeCurrentRangeviewWithstrokeColor:subtitleConfigEditView.pasterTextView.contentLabel.strokeColor
                                            borderWidth:subtitleConfigEditView.pasterTextView.contentLabel.strokeWidth
                                                  alpha:subtitleConfigEditView.pasterTextView.contentLabel.strokeAlpha
                                          borderColorId:subtitleConfigEditView.selectBorderColorItemIndex
                                            captionView:captionRangeView];
    
    [_trimmerView changeCurrentRangeviewWithFontName:subtitleConfigEditView.pasterTextView.fontName
                                            fontCode:subtitleConfigEditView.pasterTextView.fontCode
                                            fontPath:subtitleConfigEditView.pasterTextView.fontPath
                                              fontId:subtitleConfigEditView.selectFontItemIndex
                                         captionView:captionRangeView];
    
    [_trimmerView changeCurrentRangeviewWithIsBold:subtitleConfigEditView.pasterTextView.isBold
                                          isItalic:subtitleConfigEditView.pasterTextView.isItalic
                                          isShadow:subtitleConfigEditView.pasterTextView.isShadow
                                       shadowColor:subtitleConfigEditView.pasterTextView.shadowColor
                                      shadowOffset:subtitleConfigEditView.pasterTextView.shadowOffset
                                       captionView:captionRangeView];
    
    captionRangeView.file.caption.isVerticalText = subtitleConfigEditView.pasterTextView.isVerticalText;
    if(captionRangeView.file.alignment != RDSubtitleAlignmentUnknown){
        [self changePosition:captionRangeView.file.alignment subtitleScrollView:subtitleConfigEditView];
    }
    [self saveSubtitleOrEffectWithPasterView:subtitleConfigEditView.pasterTextView
                            captionRangeView:captionRangeView
                             inAnimationType:subtitleConfigEditView.inAnimationIndex
                            outAnimationType:subtitleConfigEditView.outAnimationIndex];
    [subtitleConfigEditView.pasterTextView removeFromSuperview];
    subtitleConfigEditView.pasterTextView  = nil;
    [subtitleConfigEditView setContentTextFieldText: @""];
    subtitleConfigEditView = nil;
    [self.syncContainer removeFromSuperview];
}

- (void)trimmerView:(id)trimmerView didChangeLeftPosition:(CGFloat)startTime rightPosition:(CGFloat)endTime
{
    if (_delegate && [_delegate respondsToSelector:@selector(changeCurrentTime:)]) {
        [_delegate changeCurrentTime:startTime];
    }
    self.currentTimeLbl.text = [RDHelpClass timeToStringFormat:startTime];
}

-(void)TimesFor_videoRangeView_withTime:(int)captionId
{
    if (_delegate && [_delegate respondsToSelector:@selector(TimesFor_videoRangeView_withTime:)]) {
        [_delegate TimesFor_videoRangeView_withTime:captionId];
    }
}

-(void)dragRangeSlider:(float) x dragStartTime:(float) dragStartTime dragTime:( float ) dragTime isLeft:(float) isleft isHidden:(BOOL) isHidden;
{
    if( isHidden )
    {
        if( _dragTimeView )
            _dragTimeView.hidden = YES;
        spanView.hidden = NO;
    }
    else
    {
        if( isleft )
            [_thumbnailCoreSDK seekToTime:CMTimeMakeWithSeconds(dragStartTime, TIMESCALE)];
        else
            [_thumbnailCoreSDK seekToTime:CMTimeMakeWithSeconds(dragTime+dragStartTime, TIMESCALE)];
        
        spanView.hidden = YES;
        _dragTimeView.hidden = NO;
        
         if( isleft )
             [self InitDragTimeView:[RDHelpClass timeToStringFormat:dragStartTime] atX:x + _trimmerView.frame.origin.x];
        else
            [self InitDragTimeView:[RDHelpClass timeToStringFormat:dragTime+dragStartTime] atX:x + _trimmerView.frame.origin.x];
    }
}

-(void)InitDragTimeView:(NSString *) str atX:(float) x
{
    if( _dragTimeView )
    {
        [_dragTimeLbl removeFromSuperview];
        _dragTimeLbl = nil;
        
        [_dragTimeView removeFromSuperview];
        _dragTimeView = nil;
    }
    
    float Width =  [RDHelpClass widthForString:str andHeight:10 fontSize:10] + 10;
    
    _dragTimeView = [[UIView alloc] initWithFrame:CGRectMake(x - Width/2.0, _playBtnView.frame.origin.y - 25 - 3, Width, 25)];
    
    UILabel * label1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _dragTimeView.frame.size.width, 25)];
    label1.textAlignment = NSTextAlignmentCenter;
    label1.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.01];
    label1.layer.shadowColor = [UIColor blackColor].CGColor;
    label1.layer.shadowRadius = 5;
    label1.layer.shadowOffset = CGSizeZero;
    label1.layer.shadowOpacity = 0.8;
    [_dragTimeView addSubview:label1];
    
    _dragTimeLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _dragTimeView.frame.size.width, 20)];
    _dragTimeLbl.textAlignment = NSTextAlignmentCenter;
    _dragTimeLbl.backgroundColor = UIColorFromRGB(0xf0f0f0);
    _dragTimeLbl.textColor = [UIColor blackColor];
    _dragTimeLbl.text = str;
    _dragTimeLbl.font = [UIFont systemFontOfSize:10];
    _dragTimeLbl.layer.cornerRadius=5;
    _dragTimeLbl.layer.masksToBounds = YES;
    //        _dragTimeLbl.layer.shadowColor=[UIColor redColor].CGColor;
    //        _dragTimeLbl.layer.shadowOffset=CGSizeMake(0, 0);
    //        _dragTimeLbl.layer.shadowOpacity=0.5;
    //        _dragTimeLbl.layer.shadowRadius=5;
    [_dragTimeView addSubview:_dragTimeLbl];
    
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake( (Width-2)/2.0 , _dragTimeLbl.frame.size.height, 2, 10)];
    label.backgroundColor = [UIColor whiteColor];
    
    [_dragTimeView addSubview:label];
    
    [self addSubview:_dragTimeView];
}

/*
 根据配置文件获取字幕或特效信息
 */
- (RDCaption *)getCurrentCaptionConfig{
    @try {
        NSString *path = [[NSString stringWithFormat:@"%@",_subtitleEffectConfigPath] stringByAppendingFormat:@"/config.json"];
        
        NSFileManager *manager = [[NSFileManager alloc] init];
        if([manager fileExistsAtPath:path]){
            NSLog(@"have");
        }else{
            NSLog(@"nohave");
        }
        
        NSData *data = [[NSData alloc] initWithContentsOfFile:path];
        data = [[NSData alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]];
        
        NSError *err;
        if(data){
            [_lock lock];
            _subtitleEffectConfig = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingMutableContainers
                                                                     error:&err];
            [_lock unlock];
            
            if(err) {
                NSLog(@"json解析失败：%@",err);
            }
            float   x = [_subtitleEffectConfig[@"centerX"] floatValue];
            float   y = [_subtitleEffectConfig[@"centerY"] floatValue];
            int     w = [_subtitleEffectConfig[@"width"] intValue];
            int     h = [_subtitleEffectConfig[@"height"] intValue];
            
            int fx = 0,fy = 0,fw = 0,fh = 0;
            NSArray *textPadding = _subtitleEffectConfig[@"textPadding"];
            fx =  [textPadding[0] intValue];
            fy =  [textPadding[1] intValue]+3;
            fw =  [_subtitleEffectConfig[@"textWidth"] intValue];
            fh =  [_subtitleEffectConfig[@"textHeight"] intValue];
            
            RDCaption *ppCaption = [[RDCaption alloc]init];
            ppCaption.isVerticalText = [_subtitleEffectConfig[@"vertical"] boolValue];
            ppCaption.imageFolderPath =[_subtitleEffectConfigPath  stringByAppendingString:@"/"];// [[NSBundle mainBundle].bundlePath  stringByAppendingString:@"/"];
            ppCaption.type = (RDCaptionType)[[_subtitleEffectConfig objectForKey:@"type"] integerValue];
            if(rotaionSaveAngle == 0){
                ppCaption.angle = 0;
            }else{
                ppCaption.angle = rotaionSaveAngle;
            }
            ppCaption.position= CGPointMake(x, y);
            ppCaption.size = CGSizeMake(w, h);
            ppCaption.duration = [_subtitleEffectConfig[@"duration"] floatValue];
            ppCaption.imageName = _subtitleEffectConfig[@"name"];
            
            ppCaption.scale = 1;
            ppCaption.angle = 0;
            if([_subtitleEffectConfig[@"music"] isKindOfClass:[NSMutableDictionary class]]){
                ppCaption.music.name = _subtitleEffectConfig[@"music"][@"src"];
            }else{
                ppCaption.music.name = nil;
            }
            if(ppCaption.type == RDCaptionTypeHasText){
                if(_currentEffect == RDAdvanceEditType_Sticker){
                    [_stickerConfigView setContentTextFieldText:_subtitleEffectConfig[@"textContent"]];
                }else{
                    if(![_subtitleConfigView isEditting] && ![_subtitleConfigView isFieldChanged]){
//                        ppCaption.pText = _subtitleEffectConfig[@"textContent"];
                        ppCaption.pText = RDLocalizedString(@"点击输入字幕", nil);
                        [_subtitleConfigView setContentTextFieldText:ppCaption.pText];
                    }else{
                        ppCaption.pText = [_subtitleConfigView contentTextFieldText];
                        [_subtitleConfigView setContentTextFieldText:ppCaption.pText];
                        
                    }
                }
                
                ppCaption.tFontName = _subtitleEffectConfig[@"textFont"];//@"Helvetica-Bold";//
                ppCaption.tFrame = CGRectMake(fx, fy, fw, fh);
                NSArray *textColors = _subtitleEffectConfig[@"textColor"];
                float r = [(textColors[0]) floatValue]/255.0;
                float g = [(textColors[1]) floatValue]/255.0;
                float b = [(textColors[2]) floatValue]/255.0;
                
                ppCaption.tColor = [UIColor colorWithRed:r green:g blue:b alpha:1];
                
                NSArray *strokeColors = _subtitleEffectConfig[@"strokeColor"];
                
                ppCaption.strokeColor =  [UIColor colorWithRed:[(strokeColors[0]) floatValue]/255.0
                                                         green:[(strokeColors[0]) floatValue]/255.0
                                                          blue:[(strokeColors[0]) floatValue]/255.0
                                                         alpha:1];
                
                
                if([_subtitleEffectConfig objectForKey:@"tAngle"])
                    ppCaption.tAngle = [[_subtitleEffectConfig objectForKey:@"tAngle"] floatValue];
                
                ppCaption.strokeWidth = [[_subtitleEffectConfig objectForKey:@"strokeWidth"] floatValue]/2;
                
            }
            NSString *filter = [_subtitleEffectConfig objectForKey:@"filter"];
            if (filter) {
                if ([filter isEqualToString:@"pixelate"]) {
                    ppCaption.stickerType = RDStickerType_Pixelate;
                }
            }
            ppCaption.frameArray = _subtitleEffectConfig[@"frameArray"];
            ppCaption.timeArray = _subtitleEffectConfig[@"timeArray"];
#if 0
            double captionStart = [_currentTimeLbl.text doubleValue];//格式：00:02.2
            if(_currentEffect == RDAdvanceEditType_Sticker){
                captionStart = [_currentTimeLbl.text doubleValue];
            }
#else
            double captionStart = CMTimeGetSeconds(_thumbnailCoreSDK.currentTime);
#endif
            ppCaption.timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(captionStart/*+0.1*/, TIMESCALE), CMTimeMakeWithSeconds(ppCaption.duration, TIMESCALE));
            
            if(_currentEffect == RDAdvanceEditType_Subtitle){
                if ([[_subtitleEffectConfig objectForKey:@"stretchability"] boolValue]) {
                    [_subtitleConfigView setSubtitleSize:-0.35];
                }else {
                    [_subtitleConfigView setSubtitleSize:0];
                }
            }
            if(_currentEffect == RDAdvanceEditType_Sticker){
                [_stickerConfigView setPointSizeScrollView_contentOffset:1.0];
//                float width = ((_stickerConfigView.contentSize.width-_stickerConfigView.frame.size.width)/5.0);
//                _stickerConfigView.contentOffset = CGPointMake(width, 0);
            }
#if 0
            if( [_subtitleEffectConfig[@"textContent"] isEqualToString:RDLocalizedString(@"点击输入字幕", nil)] )
            {
                ppCaption.strokeWidth = 2.0;
                ppCaption.strokeColor = UIColorFromRGB(0x000000);
                ppCaption.strokeAlpha = 1.0;
            }
#endif
            return ppCaption;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@",exception);
    }
    return nil;
}

-(void)deleteMaterialEffect_Effect:(NSString *) strPatch
{
    if([_delegate respondsToSelector:@selector(deleteMaterialEffect_Effect:)]){
        [_delegate deleteMaterialEffect_Effect:strPatch];
    }
}


#pragma mark- 字幕保存
- (void)saveSubtitleOrEffectWithPasterView:(RDPasterTextView *)pasterTextView
{
    [self updateSyncLayerPositionAndTransform];
    [self saveSubtitleOrEffectWithPasterView:pasterTextView
                            captionRangeView:((_currentEffect == RDAdvanceEditType_Subtitle) ? self.subtitleConfigView.captionRangeView : nil)
                             inAnimationType:self.subtitleConfigView.inAnimationIndex
                            outAnimationType:self.subtitleConfigView.outAnimationIndex];
}

- (void)saveSubtitleOrEffectWithPasterView:(RDPasterTextView *)pasterTextView
                          captionRangeView:(CaptionRangeView *)captionRangeView
                           inAnimationType:(CaptionAnimateType)inAnimationType
                          outAnimationType:(CaptionAnimateType)outAnimationType
{
    CGFloat radius = atan2f(pasterTextView.transform.b, pasterTextView.transform.a);
    rotaionSaveAngle = - radius * (180 / M_PI);
    float captionLastScale = [pasterTextView getFramescale];
    float  scaleValue = ((_exportSize.width > _exportSize.height)?_exportSize.width/_syncContainer.frame.size.width:_exportSize.height/_syncContainer.frame.size.height);
    CGPoint point = CGPointMake(pasterTextView.center.x/_syncContainer.frame.size.width, pasterTextView.center.y/_syncContainer.frame.size.height);
    
    CGRect saveRect = CGRectMake(0, 0, pasterTextView.contentImage.frame.size.width/_syncContainer.bounds.size.width, pasterTextView.contentImage.frame.size.height/_syncContainer.bounds.size.height);
    
    CGPoint centPoint = pasterTextView.labelBgView.center;
    CGSize  centSize = pasterTextView.contentLabel.frame.size;
    
    CGRect centRect = CGRectZero;
    if (_currentEffect == RDAdvanceEditType_Sticker)
        centRect = CGRectMake(centPoint.x, centPoint.y, centSize.width, centSize.height);
    else
        centRect = CGRectMake(centPoint.x - globalInset, centPoint.y - globalInset, centSize.width, centSize.height + (pasterTextView.contentLabel.onlyoneline ? 2 : 0.0));
    
    CGRect textRect = CGRectMake(centRect.origin.x * scaleValue, centRect.origin.y * scaleValue, centRect.size.width * scaleValue, centRect.size.height * scaleValue);
    CGRect contentsCenter = pasterTextView.contentImage.layer.contentsCenter;
    float tFontSize = pasterTextView.fontSize*scaleValue;    
    CGPoint pushInPoint = CGPointZero;
    CGPoint pushOutPoint = CGPointZero;//直接消失
    if (captionRangeView) {
        switch (inAnimationType) {
            case CaptionAnimateTypeUp:
                pushInPoint = CGPointMake(0, 1.0  + (pasterTextView.frame.size.height/2.0/_syncContainer.frame.size.height - point.y)/captionLastScale);
                break;
                
            case CaptionAnimateTypeDown:
                pushInPoint = CGPointMake(0, -(point.y + pasterTextView.frame.size.height/2.0/_syncContainer.frame.size.height)/captionLastScale);
                break;
                
            case CaptionAnimateTypeLeft:
                pushInPoint = CGPointMake(1.0  + (pasterTextView.frame.size.width/2.0/_syncContainer.frame.size.width - point.x)/captionLastScale, 0);
                break;
                
            case CaptionAnimateTypeRight:
                pushInPoint = CGPointMake(-(point.x + pasterTextView.frame.size.width/2.0/_syncContainer.frame.size.width)/captionLastScale, 0);
                break;
                
            default:
                break;
        }
        switch (outAnimationType) {
            case CaptionAnimateTypeUp:
                pushOutPoint = CGPointMake(0, 1.0  + (pasterTextView.frame.size.height/2.0/_syncContainer.frame.size.height - point.y)/captionLastScale);
                break;
                
            case CaptionAnimateTypeDown:
                pushOutPoint = CGPointMake(0, -(point.y + pasterTextView.frame.size.height/2.0/_syncContainer.frame.size.height)/captionLastScale);
                break;
                
            case CaptionAnimateTypeLeft:
                pushOutPoint = CGPointMake(1.0  + (pasterTextView.frame.size.width/2.0/_syncContainer.frame.size.width - point.x)/captionLastScale, 0);
                break;
                
            case CaptionAnimateTypeRight:
                pushOutPoint = CGPointMake(-(point.x + pasterTextView.frame.size.width/2.0/_syncContainer.frame.size.width)/captionLastScale, 0);
                break;
                
            default:
                break;
        }
    }
    [_trimmerView saveCurrentRangeview:pasterTextView.contentLabel.pText
                            typeIndex:pasterTextView.typeIndex
                        rotationAngle:rotaionSaveAngle
                            transform:pasterTextView.transform
                          centerPoint:point
                       ppcaptionFrame:saveRect
                       contentsCenter:contentsCenter
                               tFrame:textRect
                           customSize:captionLastScale
                          tStretching:pasterTextView.needStretching
                             fontSize:tFontSize
                          strokeWidth:pasterTextView.contentLabel.strokeWidth
                             aligment:(RDCaptionTextAlignment)pasterTextView.alignment
                     inAnimationType:inAnimationType
                     outAnimationType:outAnimationType
                          pushInPoint:pushInPoint
                         pushOutPoint:pushOutPoint
                      widthProportion:saveRect.size.width/(CGFloat)_exportSize.width
                            themeName:nil
                                pSize:pasterTextView.frame.size
                                 flag:YES
                          captionView:captionRangeView];
}

#pragma mark- 初始化添加字幕和特效的控件
//1:subtitle 2:effect
- (RDPasterTextView *)newCreateCurrentlyEditingLabel:(NSInteger)subtitleOrEffect caption:(RDCaption *)caption{
    NSDictionary * dic = _subtitleEffectConfig;
    float imageW = 0.0;
    float imageH = 0.0;
    //20190919 既存的有的字幕图片大小与配置文件中的大小不一致，所以还是需要使用配置文件中的
//    if (subtitleOrEffect == 1) {
        imageW = [dic[@"width"] floatValue];
        imageH = [dic[@"height"] floatValue];
//    }
    NSMutableArray *images = [[NSMutableArray alloc] init];
    int imagesCount = [[dic objectForKey:@"count"] intValue];
    if(imagesCount > 1){
        for (int i=0; i<imagesCount; i++) {
            NSString *imagePath = [_subtitleEffectConfigPath stringByAppendingString:[NSString stringWithFormat:@"/%@%d.png",[dic objectForKey:@"name"],i]];
            UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
            if (!image) {
                imagePath = [_subtitleEffectConfigPath stringByAppendingString:[NSString stringWithFormat:@"/%@%d.webp",[dic objectForKey:@"name"],i]];
                NSError *error = nil;
                image = [UIImage rd_sd_imageWithWebP:imagePath error:&error];
            }
            if(image) {
                if (subtitleOrEffect == 1) {
                    [images addObject:image];
                }
                if (imageW == 0.0) {
                    imageW = image.size.width;
                    imageH = image.size.height;
                    if (subtitleOrEffect == 2) {
                        break;
                    }
                }
            }
        }
    }else{
        NSString *imagePath = [_subtitleEffectConfigPath stringByAppendingString:[NSString stringWithFormat:@"/%@0.png",[dic objectForKey:@"name"]]];
        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
        if (image) {
            if (subtitleOrEffect == 1) {
                [images addObject:image];
            }
            if (imageW == 0.0) {
                imageW = image.size.width;
                imageH = image.size.height;
            }
        }
    }
    [self updateSyncLayerPositionAndTransform];
    
    BOOL lashen = [[dic objectForKey:@"stretchability"] boolValue];
    BOOL onlyoneLine = [[dic objectForKey:@"singleLine"] boolValue];
    CGRect contentsCenter_Rect = CGRectZero;
    CGRect textviewRect;
    CGRect textLabelRect;
    CGRect textOutRect = CGRectZero;
    
    BOOL isVertical = [dic[@"vertical"] boolValue];
//    CGPoint pasterViewCenter;
    double x = _syncContainer.frame.size.width * [[dic objectForKey:@"centerX"]doubleValue];
    double y = _syncContainer.frame.size.height * [[dic objectForKey:@"centerY"]doubleValue];
    float rectW = [[dic objectForKey:@"rectW"] floatValue];
    if (rectW == 0) {
        rectW = 1/3.0;
        if (lashen) {
            rectW = 1/5.0;
            if (lashen && !isVertical && imageH > imageW) {
                rectW = 1/8.0;
            }
        }
    }
    double sizeW = _syncContainer.frame.size.width * rectW;
    double sizeH = sizeW * (imageH / imageW);
    
    float imageRatio = sizeW / imageW;
    
    if (isVertical && [[dic objectForKey:@"rectW"]doubleValue] == 0.0) {
        double w = sizeW * (imageW / imageH);
        sizeH = sizeW;
        sizeW = w;
        imageRatio = sizeH / imageH;
    }
    if(lashen){
        if(CGPointEqualToPoint(caption.position, CGPointMake(0, 0))){
            caption.position = CGPointMake(x, y);
        }
        NSArray *borderPadding = dic[@"borderPadding"];
        double contentsCenter_x = [borderPadding[0] doubleValue];
        double contentsCenter_w = imageW - contentsCenter_x - [borderPadding[2] doubleValue];
        double contentsCenter_y = [borderPadding[1] doubleValue];
        double contentsCenter_h = imageH -contentsCenter_y - [borderPadding[3] doubleValue];
        
        NSArray *textPadding = dic[@"textPadding"];
        double t_left = [textPadding[0] doubleValue] * imageRatio;
        double t_right = [textPadding[2] doubleValue] * imageRatio;
        double t_top = [textPadding[1] doubleValue] * imageRatio;
        double t_buttom = [textPadding[3] doubleValue] * imageRatio;
        
        if([[dic objectForKey:@"textContent"] isEqualToString:RDLocalizedString(@"点击输入字幕", nil)]){
            if(isVertical)
            {
                sizeW += 5;
                sizeH -= 15;
            }else
            {
                sizeW += 15;
                sizeH += 15;
            }
        }
        contentsCenter_Rect = CGRectMake(contentsCenter_x/imageW, contentsCenter_y/imageH, contentsCenter_w/imageW, contentsCenter_h/imageH);
        
        textLabelRect = CGRectMake(t_left + globalInset , t_top + globalInset, sizeW - t_left - t_right, sizeH - t_top - t_buttom);
        textOutRect = CGRectMake(t_left, t_top, t_right, t_buttom);
    }else{
        NSArray *textPadding = dic[@"textPadding"];
        
        double t_Width = [[dic objectForKey:@"textWidth"]doubleValue] * imageRatio;
        double t_Height = [[dic objectForKey:@"textHeight"]doubleValue] * imageRatio;
        
        double t_x = [textPadding[0] doubleValue] * imageRatio  - t_Width/2.0;
        double t_y = [textPadding[1] doubleValue] * imageRatio  - t_Height/2.0;
        
        textLabelRect = CGRectMake(t_x + globalInset ,t_y + globalInset,t_Width , t_Height);
    }
    textviewRect = CGRectMake(x - (sizeW + globalInset *2.0)/2.0, y - (sizeH + globalInset *2.0)/2.0, sizeW + globalInset *2.0, sizeH + globalInset *2.0);
    textviewRect = CGRectMake((_syncContainer.frame.size.width - textviewRect.size.width)/2.0, (_syncContainer.frame.size.height - textviewRect.size.height)/2.0, textviewRect.size.width, textviewRect.size.height);//20200121 默认位置都在视频的中心
//    pasterViewCenter =  CGPointMake(textviewRect.origin.x + textviewRect.size.width/2.0, textviewRect.origin.y + textviewRect.size.height/2.0);
    
    float strokeWidth;
    UIColor *tColor;
    UIColor *strokeColor;
    NSString *pText = RDLocalizedString(@"点击输入字幕", nil);//    [dic objectForKey:@"textContent"];
    if (caption) {
        strokeWidth = caption.strokeWidth;
        tColor = caption.tColor;
        strokeColor = caption.strokeColor;
        if(caption.pText.length > 0){
            pText = caption.pText;
        }
    }else {
        strokeWidth = [[dic objectForKey:@"strokeWidth"] floatValue];
        
        NSArray *textColor = dic[@"textColor"];
        float r = [textColor[0] floatValue]/255.0;
        float g = [textColor[1] floatValue]/255.0;
        float b = [textColor[2] floatValue]/255.0;
        tColor = [UIColor colorWithRed:r green:g blue:b alpha:1];
        
        NSArray *strokeColors = dic[@"strokeColor"];
        strokeColor = [UIColor colorWithRed:[strokeColors[0] floatValue]/255.0 green:[strokeColors[1] floatValue]/255.0 blue:[strokeColors[2] floatValue]/255.0 alpha:1.0];
        if([[dic objectForKey:@"textContent"] isEqualToString:RDLocalizedString(@"点击输入字幕", nil)])
        {
            strokeWidth = 2.0;
            strokeColor = UIColorFromRGB(0x000000);
        }
    }
    RDPasterLabel* label = [[RDPasterLabel alloc] init];
    label.backgroundColor = [UIColor grayColor];
    label.textAlignment = NSTextAlignmentCenter;
    [label setClipsToBounds:YES];
    [label setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin];
    [label setText:pText];
    [label sizeToFit];
    
    UIImageView* imageView = [[UIImageView alloc] init];
    [imageView setClipsToBounds:YES];
    if(subtitleOrEffect == 1){
        imageView.animationImages = images;
        UIImage *image = [images firstObject];
        imageView.layer.contentsScale = image.scale;
        if (lashen) {
            imageView.layer.contentsScale = imageH / sizeH;
        }
    }else {
        imageView.layer.contentsScale = 2.0;
    }
    imageView.layer.contentsCenter = contentsCenter_Rect;
    imageView.layer.contentsGravity = kCAGravityResize;
    [imageView setNeedsLayout];
    [imageView setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin];
    [imageView sizeToFit];
    
    self.syncContainer.hidden = NO;
 
//    if([[dic objectForKey:@"textContent"] isEqualToString:RDLocalizedString(@"点击输入字幕", nil)] && ((caption.pText.length <= 0)  || ( [caption.pText isEqualToString:RDLocalizedString(@"点击输入字幕", nil)] )) )
//     {
//         strokeColor = UIColorFromRGB(0x000000);
//         strokeWidth = 2.0;
//          if (caption)
//          {
//              _trimmerView.currentCaptionView.file.caption.strokeWidth = 2.0;
//              _trimmerView.currentCaptionView.file.caption.strokeColor = UIColorFromRGB(0x000000);
//
//              self.subtitleConfigView.strokeWidth = 2.0;
//              self.subtitleConfigView.strokeAlpha = 1.0;
//
//              [_trimmerView changeCurrentRangeviewWithstrokeColor:strokeColor
//                                                      borderWidth:strokeWidth
//                                                            alpha:1.0
//                                                    borderColorId:self.subtitleConfigView.selectBorderColorItemIndex
//                                                      captionView:_trimmerView.currentCaptionView];
//
//          }
//     }
//
    
    BOOL isRestore = false;
    
    if( ![pText isEqualToString:RDLocalizedString(@"点击输入字幕", nil)] )
    {
        if( caption )
        {
            textviewRect = CGRectMake(self.pasterTextPoint.x, self.pasterTextPoint.y, textviewRect.size.width, textviewRect.size.height);
            isRestore = true;
        }
    }
    
    RDPasterTextView *pasterView = [[RDPasterTextView alloc] initWithFrame:textviewRect
                                                          pasterViewEnbled:YES
                                                            superViewFrame:self.syncContainer.frame
                                                              contentImage:imageView
                                                                 textLabel:label
                                                                  textRect:textLabelRect
                                                                   ectsize:CGSizeMake(imageW, imageH)
                                                                       ect:textOutRect
                                                            needStretching:lashen
                                                               onlyoneLine:onlyoneLine
                                                                 textColor:tColor
                                                               strokeColor:strokeColor
                                                               strokeWidth:strokeWidth syncContainerRect:self.syncContainer.bounds
                                                                isRestore:isRestore];
    
    pasterView.rectW = rectW;
    pasterView.isVerticalText = [dic[@"vertical"] boolValue];
    pasterView.pname = [dic objectForKey:@"name"];
    
    [pasterView setSyncContainer:self.syncContainer];
    
    double fps = [[dic objectForKey:@"fps"] doubleValue];
    pasterView.fps = fps>0 ? fps :0.005;
    [pasterView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    if (pasterView.isVerticalText) {
        [pasterView setFontSize:(textLabelRect.size.width/2.0 > 15.0 ? textLabelRect.size.width/2.0 : 15)];
    }else {
        [pasterView setFontSize:(textLabelRect.size.height/2.0 > 15.0 ?textLabelRect.size.height/2.0 : 15)];
    }
    [pasterView setFontName:@"Helvetica"];
    if (pText.length > 0) {
        [pasterView setTextString:pText adjustPosition:YES];
    }
    pasterView.backgroundColor = [UIColor clearColor];
    [self.syncContainer addSubview:pasterView];
    pasterView.delegate = self;
    pasterView.hidden = NO;
    if(!self.syncContainer.superview){
        [_playerView addSubview:self.syncContainer];
    }
    
    if(subtitleOrEffect == 2){
        _stopAnimated = NO;
        pasterView.isHiddenAlignBtn = YES;
    }else {
        pasterView.isHiddenAlignBtn = NO;
    }
    if([pText isEqualToString:RDLocalizedString(@"点击输入字幕", nil)]){
        pText = @"";
    }
    if( [pText isEqualToString:RDLocalizedString(@"点击输入字幕", nil)] )
    {
//        if(lashen){
//            pasterView.center = pasterViewCenter;
//        }
        
        CGRect frame = pasterView.frame;
        if (frame.size.width < 16) {
            frame.size.width = 16;
        }
        if (frame.size.height < 16) {
            frame.size.height = 16;
        }
        if (frame.origin.x + frame.size.width > self.syncContainer.frame.size.width) {
            if (frame.size.width > _syncContainer.frame.size.width) {
                frame.origin.x = -(frame.size.width - _syncContainer.frame.size.width)/2.0;
            }else {
                frame.origin.x -= frame.origin.x + frame.size.width - self.syncContainer.frame.size.width;
            }
        }
        if (frame.origin.y + frame.size.height > self.syncContainer.frame.size.height) {
            if (frame.size.height > _syncContainer.frame.size.height) {
                frame.origin.y = -(frame.size.height - _syncContainer.frame.size.height)/2.0;
            }else {
                frame.origin.y -= frame.origin.y + frame.size.height - self.syncContainer.frame.size.height;
            }
        }
        if(frame.origin.x<0 && frame.size.width <= _syncContainer.frame.size.width){
            frame.origin.x = 0;
        }
        if(frame.origin.y<0 && frame.size.height <= _syncContainer.frame.size.height){
            frame.origin.y = 0;
        }
        pasterView.frame = frame;
    }
    if(subtitleOrEffect == 2){
        [self performSelectorInBackground:@selector(playAnim:) withObject:pasterView];
    }
    
    return pasterView;
}

-(void)playAnim:(RDPasterTextView *)pasterTextView {
    if( _stopAnimated )
        return;
    [_lock lock];
    NSDictionary *config = [_subtitleEffectConfig mutableCopy];
    NSString * configPath = _subtitleEffectConfigPath;
    [_lock unlock];
    
    NSArray *frames = [config objectForKey:@"frameArray"];
    NSArray *times = [config objectForKey:@"timeArray"];
    
    float frames_duration = [config[@"duration"] floatValue];
    float waitTime = frames_duration/[frames count];
    int frames_count = (int)frames.count; //帧数
    float dtime = waitTime; // 每一张图片显示时间
    
    float start = 0;
    float current = 0;
    
    while (pasterTextView && !_stopAnimated) {
        current +=waitTime;
        
        if (current >= start) {
            if(frames.count >0){
                
                int index = (int)((current - start)/dtime) % frames_count;
                
                double repetStartTime = 0;
                if(times.count>1){
                    repetStartTime = [[[times objectAtIndex:1] objectForKey:@"beginTime"] doubleValue];
                }
                if(current - start >= repetStartTime){
                    int notRepetStartCount = 0;
                    int notRepetStopCount = (int)frames.count;
                    for (int i=0 ;i<frames.count;i++) {
                        NSDictionary *dic = frames[i];
                        if([[dic objectForKey:@"time"] doubleValue] == repetStartTime){
                            notRepetStartCount = i;
                        }
                        if(times.count>2){
                            if([[dic objectForKey:@"time"] doubleValue] == [[[times objectAtIndex:2] objectForKey:@"beginTime"] doubleValue]){
                                notRepetStopCount = i;
                            }
                        }
                    }
                    index = (int)((current - start)/dtime) % frames_count;
                    if(times.count>1){
                        if([[[times objectAtIndex:0] objectForKey:@"beginTime"] doubleValue] != [[[times objectAtIndex:1] objectForKey:@"beginTime"] doubleValue] && frames_duration <=(current - start)){
                            if(times.count>2){
                                index = (index%(frames_count - notRepetStartCount - (frames_count - notRepetStopCount)) + notRepetStartCount);
                            }else{
                                index = (index%(frames_count - notRepetStartCount - (frames_count - notRepetStopCount)) + notRepetStartCount);
                            }
                        }
                    }
                }
                if( _stopAnimated )
                    return;
                //NSLog(@"index%d",index);
                NSString *name = [NSString stringWithFormat:@"%@%d",config[@"name"],[frames[index][@"pic"] intValue]];
                UIImage* image;
                NSString* imagePath = [NSString stringWithFormat:@"%@/%@",configPath,name];
                if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@.webp",imagePath]]) {
                    image = [UIImage rd_sd_imageWithWebP:[NSString stringWithFormat:@"%@.webp",imagePath]];
                }else if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@.png",imagePath]]){
                    image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@.png",imagePath]];
                }
                
                imagePath = nil;
                name = nil;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (image) {
                        pasterTextView.contentImage.image = nil;
                        pasterTextView.contentImage.image = image;
                    }
                });
            }
        }
        usleep(waitTime * 1000000);
    }
}

- (void)updateSyncLayerPositionAndTransform
{
    if(!self.syncContainer){
        self.syncContainer = [[syncContainerView alloc] init];
        [self.playerView addSubview:_syncContainer];
    }
    //视频分辨率
    CGSize presentationSize  = _exportSize;
    CGRect videoRect = AVMakeRectWithAspectRatioInsideRect(presentationSize, _playerView.bounds);
    
    self.syncContainer.frame = videoRect;
    self.syncContainer.layer.masksToBounds = YES;
}

#pragma mark - 画中画
- (void)initPasterViewWithFile:(UIImage *)thumbImage {
    [self.pasterView removeFromSuperview];
    self.pasterView = nil;
    if (!self.pasterView) {
        if (self.albumView.frame.origin.y == kNavigationBarHeight) {
            WeakSelf(self);
            [UIView animateWithDuration:0.3 animations:^{
                StrongSelf(self);
                self.albumView.frame = self.superview.frame;
                
                CGRect frame = self.albumScrollView.frame;
                frame.size.height = self.albumView.bounds.size.height - 18;
                self.albumScrollView.frame = frame;
                
                UICollectionView *collectionView = [self.albumScrollView viewWithTag:1];
                frame = collectionView.frame;
                frame.size.height = self.albumScrollView.bounds.size.height;
                collectionView.frame = frame;
                
                collectionView = [self.albumScrollView viewWithTag:2];
                frame = collectionView.frame;
                frame.size.height = self.albumScrollView.bounds.size.height;
                collectionView.frame = frame;
            }];
        }
        CGSize size = thumbImage.size;
        float width;
        float height;
        if (self.syncContainer.bounds.size.width == self.syncContainer.bounds.size.height) {
            width = self.syncContainer.bounds.size.width/4.0;
            height = width / (size.width / size.height);
        }else if (self.syncContainer.bounds.size.width < self.syncContainer.bounds.size.height) {
            width = self.syncContainer.bounds.size.width/2.0;
            height = width / (size.width / size.height);
        }else {
            height = self.syncContainer.bounds.size.height / 2.0;
            width = height * (size.width / size.height);
        }
        CGRect frame = CGRectMake((self.syncContainer.bounds.size.width - width)/2.0, (self.syncContainer.bounds.size.height - height)/2.0, width, height);
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        imageView.image = thumbImage;
        
        self.pasterView = [[RDPasterTextView alloc] initWithFrame:CGRectInset(frame, -8, -8)
                                                   superViewFrame:self.playerView.frame
                                                     contentImage:imageView
                                                syncContainerRect:self.playerView.bounds];
        
        
        
        self.pasterView.mirrorBtn.hidden = NO;
        self.pasterView.delegate = self;
        [self.syncContainer addSubview:self.pasterView];
        [self.pasterView setSyncContainer:self.syncContainer];
        if (!_syncContainer.superview) {
            [_playerView addSubview:_syncContainer];
        }
    }else {
        self.pasterView.contentImage.image = thumbImage;
        
        CGSize size = thumbImage.size;
        float width;
        float height;
        if (self.syncContainer.bounds.size.width == self.syncContainer.bounds.size.height) {
            width = self.syncContainer.bounds.size.width/4.0;
            height = width / (size.width / size.height);
        }else if (self.syncContainer.bounds.size.width <= self.syncContainer.bounds.size.height) {
            width = self.syncContainer.bounds.size.width/2.0;
            height = width / (size.width / size.height);
        }else {
            height = self.syncContainer.bounds.size.height / 2.0;
            width = height * (size.width / size.height);
        }
        CGRect frame = CGRectMake((self.syncContainer.bounds.size.width - width)/2.0, (self.syncContainer.bounds.size.height - height)/2.0, width, height);
        CGRect rect = CGRectInset(frame, -8, -8);
        [self.pasterView refreshBounds:CGRectMake(0, 0, rect.size.width, rect.size.height)];
    }
    
    
}

#pragma mark- RDPasterTextViewDelegate
- (void)pasterViewDidClose:(RDPasterTextView *)sticker{
    _deletedBtn.hidden = YES;
    _cancelBtn.hidden = YES;
    _finishBtn.hidden = YES;
    _editBtn.hidden = YES;
    _addBtn.hidden = NO;
    _trimmerView.rangeSlider.hidden= YES;
    if(_currentEffect == RDAdvanceEditType_Subtitle || _currentEffect == RDAdvanceEditType_Sticker){
        if (_delegate && [_delegate respondsToSelector:@selector(deleteMaterialEffect)]) {
            [_delegate deleteMaterialEffect];
        }
        if (_currentEffect == RDAdvanceEditType_Subtitle) {
            _speechRecogBtn.hidden = _speechRecogBtn.selected;
            [self.subtitleConfigView setContentTextFieldText:@""];
            [self.subtitleConfigView.pasterTextView removeFromSuperview];
            self.subtitleConfigView.pasterTextView = nil;
            [self.subtitleConfigView clear];
            [self.subtitleConfigView removeFromSuperview];
            self.subtitleConfigView = nil;
        }else {
            [self.stickerConfigView setContentTextFieldText: @""];
            [self.stickerConfigView.pasterTextView removeFromSuperview];
            self.stickerConfigView.pasterTextView = nil;
            [self.stickerConfigView removeFromSuperview];
            self.stickerConfigView = nil;
        }        
    }
    else if(_currentEffect == RDAdvanceEditType_Collage)
    {
        [_pasterView removeFromSuperview];
        _pasterView = nil;
        if (_isAddingEffect) {
            if (_delegate && [_delegate respondsToSelector:@selector(cancelMaterialEffect)]) {
                [_delegate cancelMaterialEffect];
            }
        }else if (_isEdittingEffect) {
            if (_delegate && [_delegate respondsToSelector:@selector(deleteMaterialEffect)]) {
                [_delegate deleteMaterialEffect];
            }
        }
    }
}

//- (void)pasterViewDidChangeFrame:(RDPasterTextView *)sticker{
//    if(enterSticker){
//        float width = ((_addEffectsByTimeline.stickerConfigView.contentSize.width-_addEffectsByTimeline.stickerConfigView.frame.size.width)*0.5);
//        float fontScale  =  1.2f *([(_addEffectsByTimeline.stickerConfigView.pasterTextView) getFramescale] - 1);
//        float contentOffset_x = width * fontScale + width;
//        if(fontScale>-0.97 && fontScale<0.97)
//            _addEffectsByTimeline.stickerConfigView.contentOffset = CGPointMake(contentOffset_x, 0);
//    }else{
//        float fontScale  =  1.2f *([_addEffectsByTimeline.subtitleConfigView.pasterTextView getFramescale] - 1);
//        [_addEffectsByTimeline.subtitleConfigView setSubtitleSize:fontScale];
//
//    }
//}

- (void)pasterViewMoved:(RDPasterTextView *)sticker{
    
    if( _currentEffect == RDAdvanceEditType_Collage )
    {
        if( self.currentCollage )
        {
            if( sticker.isDrag_Upated )
            {
                NSLog(@"collage");
                CGRect rect = CGRectMake(0, 0, 1, 1);
                double rotate = 0;
                [self pasterView_Rect:&rect atRotate:&rotate];
                
                self.currentCollage.vvAsset.alpha = sticker.dragaAlpha;
                self.trimmerView.currentCaptionView.file.collage.vvAsset.alpha = sticker.dragaAlpha;
                sticker.dragaAlpha = -1;
                
                self.currentCollage.vvAsset.rotate = rotate;
                self.currentCollage.vvAsset.rectInVideo = rect;
                if (CMTimeCompare(_refreshCurrentTime, kCMTimeInvalid) == 0) {
                    _refreshCurrentTime = _thumbnailCoreSDK.currentTime;
                }
                [_thumbnailCoreSDK refreshCurrentFrame];
            }
            else
            {
                if( sticker.dragaAlpha == -1 )
                {
                    sticker.dragaAlpha = self.currentCollage.vvAsset.alpha;
                    self.currentCollage.vvAsset.alpha = 0.0;
                    self.trimmerView.currentCaptionView.file.collage.vvAsset.alpha = 0;
                    [_thumbnailCoreSDK refreshCurrentFrame];
                }
            }
//            [_thumbnailCoreSDK filterRefresh:_thumbnailCoreSDK.currentTime];
        }else {
            self.pasterView.contentImage.alpha = 1.0;
        }
    }
    
    [self.trimmerView changeCurrentRangeviewWithSubtitleAlignment:RDSubtitleAlignmentUnknown captionView:self.subtitleConfigView.captionRangeView];
}

-(void)pasterView_Rect:(  CGRect * ) rect atRotate:( double * ) rotate
{
    CGPoint point = CGPointMake(self.pasterView.center.x/self.syncContainer.frame.size.width, self.pasterView.center.y/self.syncContainer.frame.size.height);
    float scale = [self.pasterView getFramescale];
    
    (*rect).size = CGSizeMake(self.pasterView.contentImage.frame.size.width*scale / self.syncContainer.bounds.size.width, self.pasterView.contentImage.frame.size.height*scale / self.syncContainer.bounds.size.height);
    (*rect).origin = CGPointMake(point.x - (*rect).size.width/2.0, point.y - (*rect).size.height/2.0);
    CGFloat radius = atan2f(self.pasterView.transform.b, self.pasterView.transform.a);
    (*rotate) = - radius * (180 / M_PI);
    
    self.pasterView.contentImage.image = [self RangeView_Image:self.trimmerView.currentCaptionView atCrop:*rect];
}

- (void)pasterViewSizeScale:(RDPasterTextView *_Nullable)sticker atValue:( float ) value
{
    if (_currentEffect == RDAdvanceEditType_Subtitle) {
        [self.subtitleConfigView setProgressSize:value];
    }else if (_currentEffect == RDAdvanceEditType_Sticker) {
        [self.stickerConfigView setPointSizeScrollView_contentOffset:value];
    }
}

//抠图颜色提取返回函数
-(void)paster_CutoutColor:(RDPasterTextView * _Nullable) cutOut_PasterText atColorRed:(float) colorRed atColorGreen:(float) colorGreen atColorBlue:(float) colorBlue atAlpha:(float) colorApha isRefresh:(BOOL) isRefresh
{
    UIColor *color =  [UIColor colorWithRed:colorRed green:colorGreen blue:colorBlue alpha:colorApha];
    
    if( isRefresh )
    {
//        [[self.EditCollageView.videoCoreSDK getScenes] enumerateObjectsUsingBlock:^(RDScene * _Nonnull obj1, NSUInteger idx, BOOL * _Nonnull stop) {
//
//            [obj1.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//
//                obj.blendType =  RDBlendChromaColor;
//                obj.chromaColor = color;
//
//            }];
//
//        }];
        
        self.currentCollage.vvAsset.blendType = RDBlendChromaColor;
        self.currentCollage.vvAsset.chromaColor = color;
        
        //    self.EditCollageView.videoCoreSDK.delegate = self;
        [self.EditCollageView.videoCoreSDK refreshCurrentFrame];
        //    [self.EditCollageView.videoCoreSDK seekToTime:self.EditCollageView.videoCoreSDK.currentTime];
        
//        [self performSelector:@selector(ImageRef) withObject:nil afterDelay:0.2];
    }
    
    
    [self.EditCollageView.collage_cutout_View setCutoutColor:colorRed atColorGreen:colorGreen atColorBlue:colorBlue atAlpha:colorApha];
    
    
     NSString * str = [NSString stringWithFormat:@"R:%d G:%d B:%d",colorRed,colorGreen,colorBlue];
    
    float cutoutLabelWidth =  [RDHelpClass widthForString:str andHeight:14.0 fontSize:14.0] + 10;
}

-(void)ImageRef
{
    [self.EditCollageView.videoCoreSDK getImageWithTime:CMTimeMake(0.2, TIMESCALE) scale:1.0 completionHandler:^(UIImage *image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _pasterView.contentImage.image = nil;
            _pasterView.contentImage.image = image;
        });
    }];
}


//是否显示字幕文字编辑界面
- (void)pasterViewShowText
{
    self.subtitleConfigView.topView.hidden = NO;
    self.subtitleConfigView.bottomView.hidden = YES;
    [self.subtitleConfigView.textView becomeFirstResponder];
    [self.subtitleConfigView saveTextFieldTxt];
}

- (BOOL)checkStickerIconDownload{    
    BOOL hasNewSticker =  _editConfiguration.effectResourceURL.length>0;
    NSArray *icons = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:kStickerIconPath error:nil];
    NSArray *stickers = [[NSArray alloc] initWithContentsOfFile:kStickerPlistPath];
    NSArray *newStickers = [[NSArray alloc] initWithContentsOfFile:kNewStickerPlistPath];
    NSMutableArray *stickerTypes = [NSMutableArray arrayWithContentsOfFile:kStickerTypesPath];

    BOOL isRefresh = false;
    
    RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
     if ([lexiu currentReachabilityStatus] == RDNotReachable) {
         isRefresh = false;
     }
    else
    {
        NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"stickers",@"type", nil];
        if( _appKey.length>0)
            [params setObject:_appKey forKey:@"appkey"];
        NSDictionary *dic = [RDHelpClass updateInfomation:params andUploadUrl:_editConfiguration.netMaterialTypeURL];
        BOOL hasValue = [[dic objectForKey:@"code"] integerValue]  == 0;
//        hasValue = false;
        
        if( hasValue  )
        {
            if( [dic[@"data"] count] > 0 )
            {
                if( (stickerTypes == nil) || ( newStickers == nil ) )
                    isRefresh  = true;
            }
            else
            {
                if( (stickers == nil) ||  (stickerTypes != nil)   )
                    isRefresh  = true;
            }
        }
        else
        {
            if( (stickers == nil) ||  (stickerTypes != nil)   )
                isRefresh  = true;
        }
    }
    
    bool isType = false;
    if( (stickerTypes!= nil) && (stickerTypes.count > 0) && ( newStickers != nil ) && ( newStickers.count > 0 ) )
    {
        isType = true;
    }
    else if( (stickerTypes== nil) && ( stickers != nil ) && (stickers.count > 0) )
    {
        isType = true;
    }
    
    if( ((icons.count>0 && !hasNewSticker) ||  isType ) && !isRefresh  ){
        
        [self initStickerEditView];
        
        [RDHelpClass downloadIconFile:RDAdvanceEditType_Sticker
                           editConfig:_editConfiguration
                               appKey:_appKey
                            cancelBtn:nil
                        progressBlock:nil
                             callBack:nil
                          cancelBlock:nil];
        return YES;
    }else{
        [self initProgressHUD:RDLocalizedString(@"请稍等...", nil)];
        __weak typeof(self) myself = self;
        [RDHelpClass downloadIconFile:RDAdvanceEditType_Sticker
                           editConfig:_editConfiguration
                               appKey:_appKey
                            cancelBtn:_progressHUD.cancelBtn
                        progressBlock:^(float progress) {
                            [myself myProgressTask:progress];
                        } callBack:^(NSError *error) {
                            if(!error){
                                [myself initStickerEditView];
                                [self.stickerConfigView touchescaptionTypeViewChildWithIndex:0];
                            }
                            [myself.progressHUD hide:NO];
                        } cancelBlock:^{
                            [myself.progressHUD hide:NO];
                        }];
        return NO;
    }
}

- (BOOL)checkSubtitleIconDownload{
    NSArray *icons = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:kSubtitleIconPath error:nil];
    NSArray *fontIcons = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:kFontIconPath error:nil];
    
    BOOL hasNewSubtitle =  _editConfiguration.subtitleResourceURL.length>0;
    
    NSArray *subtitles = [[NSArray alloc] initWithContentsOfFile:kSubtitlePlistPath];
    if( (icons.count>0 && fontIcons.count>0 && !hasNewSubtitle) || (hasNewSubtitle && subtitles.count>0) ){
        
        [self initSubtitleConfigEditView:YES];
        [RDHelpClass downloadIconFile:RDAdvanceEditType_Subtitle
                           editConfig:_editConfiguration
                               appKey:_appKey
                            cancelBtn:nil
                        progressBlock:nil
                             callBack:nil
                          cancelBlock:nil];
        return YES;
    }else{
        __weak typeof(self) myself = self;
        if(icons.count>0 && !hasNewSubtitle){
            if(fontIcons.count>0){
                [self initSubtitleConfigEditView:YES];
            }else{
                [self initProgressHUD:RDLocalizedString(@"请稍等...", nil)];
                [RDHelpClass downloadIconFile:RDAdvanceEditType_None
                                   editConfig:_editConfiguration
                                       appKey:_appKey
                                    cancelBtn:_progressHUD.cancelBtn
                                progressBlock:^(float progress) {
                                    [myself myProgressTask:progress];
                                } callBack:^(NSError *error) {
                                    if(!error){
                                        [myself initSubtitleConfigEditView:YES];
                                    }
                                    [myself.progressHUD hide:NO];
                                } cancelBlock:^{
                                    [myself.progressHUD hide:NO];
                                }];
            }
        }
        else{
            NSArray *fontIcons = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:kFontIconPath error:nil];
            [self initProgressHUD:RDLocalizedString(@"请稍等...", nil)];
            [RDHelpClass downloadIconFile:RDAdvanceEditType_Subtitle
                               editConfig:_editConfiguration
                                   appKey:_appKey
                                cancelBtn:_progressHUD.cancelBtn
                            progressBlock:^(float progress) {
                                if(fontIcons.count>0){
                                    [myself myProgressTask:progress];
                                }else{
                                    [myself myProgressTask:progress/2.0];
                                }
                            } callBack:^(NSError *error) {
                                if(fontIcons.count>0 && !hasNewSubtitle){
                                    if(!error){
                                        
                                        [myself initSubtitleConfigEditView:YES];
                                    }
                                    [myself.progressHUD hide:NO];
                                }else{
                                    [RDHelpClass downloadIconFile:RDAdvanceEditType_None
                                                       editConfig:_editConfiguration
                                                           appKey:_appKey
                                                        cancelBtn:_progressHUD.cancelBtn
                                                    progressBlock:^(float progress) {
                                                        [myself myProgressTask:progress/2.0 + 0.5];
                                                    } callBack:^(NSError *error) {
                                                        if(!error){
                                                            [myself initSubtitleConfigEditView:YES];
                                                        }
                                                        [myself.progressHUD hide:NO];
                                                    } cancelBlock:^{
                                                        [myself.progressHUD hide:NO];
                                                    }];
                                }
                            } cancelBlock:^{
                                [myself.progressHUD hide:NO];
                            }];
        }
        return NO;
    }
}

- (void)initProgressHUD:(NSString *)message{
    if (_progressHUD) {
        _progressHUD = nil;
    }
    //圆形进度条
    _progressHUD = [[RDMBProgressHUD alloc] initWithView:self.superview.superview];
    [self.superview.superview addSubview:_progressHUD];
    _progressHUD.removeFromSuperViewOnHide = YES;
    _progressHUD.mode = RDMBProgressHUDModeDeterminate;
    _progressHUD.animationType = RDMBProgressHUDAnimationFade;
    _progressHUD.labelText = message;
    _progressHUD.isShowCancelBtn = YES;
    [_progressHUD show:YES];
    [self myProgressTask:0];
    
}
- (void)myProgressTask:(float)progress{
    [_progressHUD setProgress:progress];
}

- (void)clear {
    if (_albumScrollView) {
        UICollectionView *videoCollectionView = [_albumScrollView viewWithTag:1];
        [videoCollectionView removeFromSuperview];
        UICollectionView *picCollectionView = [_albumScrollView viewWithTag:2];
        [picCollectionView removeFromSuperview];
        videoCollectionView = nil;
        picCollectionView = nil;
        [self.videoArray removeAllObjects];
        [self.picArray removeAllObjects];
    }
    if (_requestIdArray.count > 0) {
        for (NSDictionary *dic in _requestIdArray) {
            [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(getSpeechRecogCallBackWithDic:) object:dic];
        }
        [_requestIdArray removeAllObjects];
    }
}



- (RDATMHud *)collageHud{
    if(!_collageHud){
        _collageHud = [[RDATMHud alloc] initWithDelegate:nil];
        [((UIViewController*)_delegate).navigationController.view addSubview:_collageHud.view];
    }
    return _hud;
}
#pragma mark- editCollageViewDelegate
//显示控件
-(void)showCollageBarItem:( RDPIPFunctionType ) pipType
{
    if( (kPIP_ROTATE != pipType) && (kPIP_MIRROR != pipType) && (kPIP_FLIPUPANDDOWN != pipType) )
    {
        if (_delegate && [_delegate respondsToSelector:@selector(showCollageBarItem:)]) {
            [_delegate showCollageBarItem:pipType];
        }
    }
    
    if( !self.EditCollageView )
        return;
    
    switch (pipType) {
        case kPIP_SINGLEFILTER: //MARK:画中画 滤镜
        {
            filter_editCollageView           *collage_filter_View = self.EditCollageView.collage_filter_View;
            collage_filter_View.selectFilterIndex =
            self.trimmerView.currentCaptionView.file.collageFilterIndex;
            if( ![collage_filter_View  getNewFilterSortArray] )
            {
                [((ScrollViewChildItem *)[collage_filter_View.filterChildsView viewWithTag:[collage_filter_View getCurrentFilterIndex]+1]) setSelected:NO];
            }
            else{
                [collage_filter_View scrollViewIndex: collage_filter_View.selectFilterIndex - 1];
                [collage_filter_View filterLabelBtn: [collage_filter_View.fileterLabelNewScroView viewWithTag:[collage_filter_View getCurrentlabelFilter]] ];
            }
            [collage_filter_View.filterProgressSlider setValue:self.trimmerView.currentCaptionView.file.collage.vvAsset.filterIntensity];
        }
            break;
        case kPIP_ADJUST://MARK:画中画 调色
        {
            
        }
            break;
        case kPIP_MIXEDMODE://MARK:画中画 混合模式
        {
            mixed_editCollageView            *collage_mixed_View = self.EditCollageView.collage_mixed_View;
            
            if( (self.trimmerView.currentCaptionView.file.collage.vvAsset.blendType != RDBlendAIChromaColor) && (self.trimmerView.currentCaptionView.file.collage.vvAsset.blendType != RDBlendChromaColor) )
            {
                [collage_mixed_View setcurrentMixedIndex:self.trimmerView.currentCaptionView.file.collage.vvAsset.blendType];
            }
            
            [collage_mixed_View.mixed_Ttansparency_slider setValue:self.trimmerView.currentCaptionView.file.collage.vvAsset.alpha];
        }
            break;
        case kPIP_CUTOUT://MARK:画中画 抠图
        {
            cutout_editCollageView *collage_cutout_View = self.EditCollageView.collage_cutout_View;
            
            [collage_cutout_View.pasterView setCutoutMagnifier:true];
        }
            break;
        case kPIP_VOLUME://MARK:画中画 声音
        {
            volume_editCollageView *collage_volume_View = self.EditCollageView.collage_volume_View;

            [collage_volume_View.volumeProgressSlider setValue:self.trimmerView.currentCaptionView.file.collage.vvAsset.volume];
            [collage_volume_View.fadeInVolumeSlider setValue:self.trimmerView.currentCaptionView.file.collage.vvAsset.audioFadeInDuration];
            [collage_volume_View.fadeOutVolumeSlider setValue:self.trimmerView.currentCaptionView.file.collage.vvAsset.audioFadeOutDuration];
            
        }
            break;
        case kPIP_BEAUTY://MARK:画中画 美颜
        {
            beautay_editCollageView *collage_beautay_View = self.EditCollageView.collage_beautay_View;
            
            float beautyBlurIntensity = self.trimmerView.currentCaptionView.file.collage.vvAsset.beautyBlurIntensity;
            
            [collage_beautay_View.beautyProgressSlider setValue:beautyBlurIntensity];
        }
            break;
        case kPIP_TRANSPARENCY://MARK:画中画 透明度
        {
            
            
            transparency_editCollageView *collage_transparency_View = self.EditCollageView.collage_transparency_View;
            
            float alpha = self.trimmerView.currentCaptionView.file.collage.vvAsset.alpha;
            
            [collage_transparency_View.transparencyProgressSlider setValue:alpha];
            
            [[self.EditCollageView.videoCoreSDK getScenes] enumerateObjectsUsingBlock:^(RDScene * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
               
                [obj.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj1, NSUInteger idx, BOOL * _Nonnull stop) {
                    obj1.alpha = 1.0;
                }];
            }];
//            [self.EditCollageView.videoCoreSDK filterRefresh:self.EditCollageView.videoCoreSDK.currentTime];
            if (CMTimeCompare(_refreshCurrentTime, kCMTimeInvalid) == 0) {
                _refreshCurrentTime = self.EditCollageView.videoCoreSDK.currentTime;
            }
            [self.EditCollageView.videoCoreSDK filterRefresh:_refreshCurrentTime];
        }
            break;
        case kPIP_ROTATE://MARK:画中画 旋转
        {
            
            CGFloat radius = atan2f(self.pasterView.transform.b, self.pasterView.transform.a);
            double rotate = - radius * (180 / M_PI);
            
            rotate -= 90;
            
            //旋转
//            if(self.trimmerView.currentCaptionView.file.rotate == 0){
//                self.trimmerView.currentCaptionView.file.rotate = -90;
//            }else if(self.trimmerView.currentCaptionView.file.rotate == -90){
//                self.trimmerView.currentCaptionView.file.rotate = -180;
//            }else if(self.trimmerView.currentCaptionView.file.rotate == -180){
//                self.trimmerView.currentCaptionView.file.rotate = -270;
//            }else if(self.trimmerView.currentCaptionView.file.rotate == -270){
//                self.trimmerView.currentCaptionView.file.rotate = 0;
//            }
            
            if( rotate > -360 )
            {
                rotate = rotate + 360;
            }
            
//            rotate += self.trimmerView.currentCaptionView.file.rotate;
            
            radius = -(rotate*M_PI)/180.0;
            
            self.pasterView.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(radius), [self.pasterView getFramescale], [self.pasterView getFramescale]);
            
//            self.trimmerView.currentCaptionView.file.rotate = rotate;
            
            self.currentCollage.vvAsset.rotate = rotate;
            
            CGPoint point = CGPointMake(self.pasterView.center.x/self.syncContainer.frame.size.width, self.pasterView.center.y/self.syncContainer.frame.size.height);
            
            float scale = [self.pasterView getFramescale];
            CGRect rect;
            rect.size = CGSizeMake(self.pasterView.contentImage.frame.size.width*scale / self.syncContainer.bounds.size.width, self.pasterView.contentImage.frame.size.height*scale / self.syncContainer.bounds.size.height);
            rect.origin = CGPointMake(point.x - rect.size.width/2.0, point.y - rect.size.height/2.0);
            self.currentCollage.vvAsset.rectInVideo = rect;
//            [self collage_InitPaterView];
//
//            CGRect rect = CGRectMake(0, 0, 1, 1);
//            [self pasterView_Rect:&rect atRotate:&rotate];
//            self.currentCollage.vvAsset.rotate = rotate;
//            self.currentCollage.vvAsset.rectInVideo = rect;
//
            [self.thumbnailCoreSDK refreshCurrentFrame];
        }
            break;
        case kPIP_MIRROR://MARK:画中画 左右镜像
        {
            self.currentCollage.vvAsset.isHorizontalMirror = !self.currentCollage.vvAsset.isHorizontalMirror;
            
            BOOL isHorizontalMirror = self.currentCollage.vvAsset.isHorizontalMirror;
            BOOL isVerticalMirror = self.currentCollage.vvAsset.isVerticalMirror;
            if (isHorizontalMirror && isVerticalMirror) {
                [self.pasterView setContentImageTransform:kLRUPFlipTransform];
            }else if (isHorizontalMirror) {
                [self.pasterView setContentImageTransform:kLRFlipTransform];
            }else if (isVerticalMirror) {
                [self.pasterView setContentImageTransform:kUDFlipTransform];
            }
            else{
               [self.pasterView setContentImageTransform:CGAffineTransformMakeScale(1.0,1.0)];
            }
        
            
//            [self collage_InitPaterView];
//
//            double rotate = 0;
//            CGRect rect = CGRectMake(0, 0, 1, 1);
//            [self pasterView_Rect:&rect atRotate:&rotate];
//            self.currentCollage.vvAsset.rotate = rotate;
//            self.currentCollage.vvAsset.rectInVideo = rect;
            
            [self.thumbnailCoreSDK refreshCurrentFrame];
        }
            break;
        case kPIP_FLIPUPANDDOWN://MARK:画中画 上下镜像
        {
            self.currentCollage.vvAsset.isVerticalMirror = !self.currentCollage.vvAsset.isVerticalMirror;
            
            BOOL isHorizontalMirror = self.currentCollage.vvAsset.isHorizontalMirror;
            BOOL isVerticalMirror = self.currentCollage.vvAsset.isVerticalMirror;
            if (isHorizontalMirror && isVerticalMirror) {
                [self.pasterView setContentImageTransform:kLRUPFlipTransform];
            }else if (isHorizontalMirror) {
                [self.pasterView setContentImageTransform:kLRFlipTransform];
            }else if (isVerticalMirror) {
                [self.pasterView setContentImageTransform:kUDFlipTransform];
            }
            else{
                [self.pasterView setContentImageTransform:CGAffineTransformMakeScale(1.0,1.0)];
            }
            
//            [self collage_InitPaterView];
//
//            double rotate = 0;
//            CGRect rect = CGRectMake(0, 0, 1, 1);
//            [self pasterView_Rect:&rect atRotate:&rotate];
//            self.currentCollage.vvAsset.rotate = rotate;
//            self.currentCollage.vvAsset.rectInVideo = rect;
            
            [self.thumbnailCoreSDK refreshCurrentFrame];
        }
            break;
        case KPIP_DELETE://MARK:画中画 删除
        {
            self.EditCollageView.hidden = YES;
            [self deleteEffectAction: _deletedBtn ];
        } 
            break;
        case KPIP_REPLACE://MARK:画中画 替换
        {
            RDFileType filType = kFILEIMAGE;
            
            if( self.EditCollageView.currentVvAsset.type == RDAssetTypeVideo)
                filType = kFILEVIDEO;
            [RDHelpClass seplace_File:filType touchConnect:true navigationVidew:((UIViewController*)_delegate).navigationController exportSize:[RDHelpClass trackSize:self.EditCollageView.currentVvAsset.url rotate:0] ViewController:_delegate callbackBlock:^(NSMutableArray *lists) {
                [self addFileWithList:lists];
                [self collage_InitPaterView];
                self.pasterView.isDrag = TRUE;
                CGRect rect = CGRectMake(0, 0, 1, 1);
                double rotate = 0;
                [self pasterView_Rect:&rect atRotate:&rotate];
                self.currentCollage.vvAsset.rotate = rotate;
                self.currentCollage.vvAsset.rectInVideo = rect;
                self.trimmerView.currentCaptionView.file.collage.vvAsset.rotate = rotate;
                self.trimmerView.currentCaptionView.file.collage.vvAsset.rectInVideo = rect;
                CaptionRangeView * rangeView = self.trimmerView.currentCaptionView;
                
                
                
                [self.trimmerView changecurrentCaptionViewTimeRange:CMTimeGetSeconds(self.currentCollage.timeRange.duration)];
                [self.trimmerView setisSeektime:TRUE];
                self.trimmerView.currentCaptionView = rangeView;
                [self.trimmerView setisSeektime:false];
                
                [self collage_CoreBuild];
            }];
        }
            break;
        case KPIP_TRIM://MARK:画中画 截取
        {
            RDFile * file = [RDHelpClass vassetToFile:self.EditCollageView.currentVvAsset];
            //时间小于0.2不让截取
            int dd;
            if (file.isGif) {
                dd = CMTimeGetSeconds(file.imageDurationTime)*100 / file.speed;
            }else {
                dd = CMTimeGetSeconds(file.videoTimeRange.duration)*100 / file.speed;
                if(file.isReverse){
                    dd = CMTimeGetSeconds(file.reverseVideoTimeRange.duration)*100/ file.speed;
                }
            }
            
            if(dd<1.0 * 100){
                if( !_collageHud )
                {
                    [self collageHud];
                }
                
                [_collageHud setCaption:RDLocalizedString(@"截取不能小于1.0秒!", nil)];
                [_collageHud show];
                [_collageHud hideAfter:2];
                return;
            }
            
            [RDHelpClass enter_Trim:file navigationVidew:((UIViewController*)_delegate).navigationController ViewController:_delegate callbackBlock:^(CMTimeRange timeRange) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                   
                    self.EditCollageView.currentVvAsset.timeRange = timeRange;
                    self.currentCollage.vvAsset.timeRange = timeRange;
                    self.trimmerView.currentCaptionView.file.collage.vvAsset.timeRange = timeRange;
                
                    self.trimmerView.currentCaptionView.file.collage.timeRange = CMTimeRangeMake(self.trimmerView.currentCaptionView.file.collage.timeRange.start, timeRange.duration);
                    self.currentCollage.timeRange = CMTimeRangeMake(self.currentCollage.timeRange.start, timeRange.duration);
                    
                    CaptionRangeView * rangeView = self.trimmerView.currentCaptionView;
                    
                    
                    [self.trimmerView changecurrentCaptionViewTimeRange:CMTimeGetSeconds(timeRange.duration)];
                    [self.trimmerView setisSeektime:TRUE];
                    self.trimmerView.currentCaptionView = rangeView;
                    [self.trimmerView setisSeektime:false];
//                    Float64 duration = CMTimeGetSeconds(self.trimmerView.clipTimeRange.duration);
//                    float width = (self.trimmerView.videoRangeView.frame.size.width/duration) * CMTimeGetSeconds(timeRange.duration);
//                    self.trimmerView.currentCaptionView.frame = CGRectMake(self.trimmerView.currentCaptionView.frame.origin.x, self.trimmerView.currentCaptionView.frame.origin.y, width, self.trimmerView.currentCaptionView.frame.size.height);
//
                    
                    [self collage_CoreBuild];
                    
                });
                
            }];
        }
            break;
        case KPIP_CHANGESPEED://MARK:画中画 变速
        {
            RDFile * file = [RDHelpClass vassetToFile:self.EditCollageView.currentVvAsset];
            
            [RDHelpClass enter_Speed:file navigationVidew:((UIViewController*)_delegate).navigationController ViewController:_delegate callbackBlock:^(RDFile *file, BOOL useAllFile) {
                
                if( file.fileType == kFILEIMAGE )
                {
                    self.EditCollageView.currentVvAsset.timeRange = file.imageTimeRange;
                    self.trimmerView.currentCaptionView.file.collage.vvAsset.timeRange = file.imageTimeRange;
                }
                self.EditCollageView.currentVvAsset.speed = file.speed;
                self.currentCollage.vvAsset.speed = file.speed;
                self.trimmerView.currentCaptionView.file.collage.vvAsset.speed = file.speed;
                
                
                [self collage_CoreBuild];
                
            }];
        }
            break;
        case KPIP_EDIT://MARK:画中画 裁切
        {
            RDFile * file = [RDHelpClass vassetToFile:self.EditCollageView.currentVvAsset];
            
            [RDHelpClass enter_Edit:file navigationVidew:((UIViewController*)_delegate).navigationController ViewController:_delegate callbackBlock:^(CGRect crop, CGRect cropRect, BOOL verticalMirror, BOOL horizontalMirror, float rotate, FileCropModeType cropModeType) {
                
                CGFloat radius = atan2f(self.pasterView.transform.b, self.pasterView.transform.a);
                double rotate1 = - radius * (180 / M_PI);
                
                rotate1 -= self.trimmerView.currentCaptionView.file.rotate;
                
                
                rotate1 += rotate;
                
                radius = -(rotate1*M_PI)/180.0;
                
                self.pasterView.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(radius), [self.pasterView getFramescale], [self.pasterView getFramescale]);
                
                self.trimmerView.currentCaptionView.file.collage.vvAsset.isVerticalMirror = verticalMirror;
                self.trimmerView.currentCaptionView.file.collage.vvAsset.isHorizontalMirror = horizontalMirror;
                
                BOOL isHorizontalMirror = self.trimmerView.currentCaptionView.file.collage.vvAsset.isHorizontalMirror;
                BOOL isVerticalMirror = self.trimmerView.currentCaptionView.file.collage.vvAsset.isVerticalMirror;
                if (isHorizontalMirror && isVerticalMirror) {
                    [self.pasterView setContentImageTransform:kLRUPFlipTransform];
                }else if (isHorizontalMirror) {
                    [self.pasterView setContentImageTransform:kLRFlipTransform];
                }else if (isVerticalMirror) {
                    [self.pasterView setContentImageTransform:kUDFlipTransform];
                }
                else{
                    [self.pasterView setContentImageTransform:CGAffineTransformMakeScale(1.0,1.0)];
                }
                
                self.EditCollageView.currentVvAsset.crop = crop;
                self.currentCollage.vvAsset.crop = crop;
                self.trimmerView.currentCaptionView.file.collage.vvAsset.crop = crop;
                
                [self collage_InitPaterView];
                self.pasterView.isDrag = TRUE;
                CGRect rect = CGRectMake(0, 0, 1, 1);
                [self pasterView_Rect:&rect atRotate:&rotate];
                self.currentCollage.vvAsset.rotate = rotate;
                self.currentCollage.vvAsset.rectInVideo = rect;
                
                [self.EditCollageView.videoCoreSDK refreshCurrentFrame];
                
//                [self collage_CoreBuild];
            }];
        }
            break;
        default:
            break;
    }
    
}

-(void)collage_InitPaterView
{
    CGSize size = CGSizeZero;
    
    UIImage *image = [RDHelpClass getFullScreenImageWithUrl:self.EditCollageView.currentVvAsset.url];
    
    if( ![RDHelpClass isImageUrl:self.EditCollageView.currentVvAsset.url] )
    {
        AVURLAsset *asset = [AVURLAsset assetWithURL:self.EditCollageView.currentVvAsset.url];
        
        NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        if([tracks count] > 0) {
            AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
            size = CGSizeApplyAffineTransform(videoTrack.naturalSize, videoTrack.preferredTransform);
        }
        size = CGSizeMake(fabs(size.width), fabs(size.height));
    }
    else
    {
        size = image.size;
    }
    
    image = [RDHelpClass image:image rotation:0 cropRect:self.currentCollage.vvAsset.crop];
    
    CGPoint  center = self.pasterView.center;
    
    self.trimmerView.currentCaptionView.file.thumbnailImage = image;
    
    CaptionRangeView * rangeView = self.trimmerView.currentCaptionView;
    [self initPasterViewWithFile:rangeView.file.thumbnailImage];
//    self.pasterView.alpha = 0.0;
    
    float ppsc = (rangeView.file.caption.size.width * kVIDEOWIDTH)/ (float) rangeView.file.caption.size.width <1 ? (rangeView.file.caption.size.width * kVIDEOWIDTH)/ (float) rangeView.file.caption.size.width : 1;
    float sc = rangeView.file.scale;
    CGFloat radius = atan2f(rangeView.file.captionTransform.b, rangeView.file.captionTransform.a);
    
    CGAffineTransform transform2 = CGAffineTransformMakeRotation(radius);
    self.pasterView.transform = CGAffineTransformScale(transform2, sc * ppsc, sc * ppsc);
    [self.pasterView setFramescale: sc * ppsc];
    self.pasterView.center = center;
    
    self.pasterView.contentImage.alpha = 0.0;
    
    BOOL isHorizontalMirror = rangeView.file.collage.vvAsset.isHorizontalMirror;
    BOOL isVerticalMirror = rangeView.file.collage.vvAsset.isVerticalMirror;
    if (isHorizontalMirror && isVerticalMirror) {
        [self.pasterView setContentImageTransform:kLRUPFlipTransform];
    }else if (isHorizontalMirror) {
        [self.pasterView setContentImageTransform:kLRFlipTransform];
    }else if (isVerticalMirror) {
        [self.pasterView setContentImageTransform:kUDFlipTransform];
    }
}


//隐藏控件
-(void)hiddenCollageBarItem:( RDPIPFunctionType ) pipType isSave:(BOOL) isSave
{
    //画中画 滤镜
    NSURL * filterUrl = self.EditCollageView.currentCollage.vvAsset.filterUrl;
    VVAssetFilter filterType = self.EditCollageView.currentCollage.vvAsset.filterType;
    float filterIntensity = self.EditCollageView.currentCollage.vvAsset.filterIntensity;
    //画中画 调色
    float  brightness = self.EditCollageView.currentCollage.vvAsset.brightness;
    float  contrast = self.EditCollageView.currentCollage.vvAsset.contrast;
    float  saturation = self.EditCollageView.currentCollage.vvAsset.saturation;
    float  sharpness = self.EditCollageView.currentCollage.vvAsset.sharpness;
    float  whiteBalance = self.EditCollageView.currentCollage.vvAsset.whiteBalance;
    float  vignette = self.EditCollageView.currentCollage.vvAsset.vignette;
    //画中画 混合模式
    RDBlendType blendType = self.EditCollageView.currentCollage.vvAsset.blendType;
    
    //画中画 抠图
    //画中画 声音
    float  vloume = 1.0;
    float  audioFadeInDuration = 0;
    float  audioFadeOutDuration = 0;
    
    //画中画 美颜
    float  beautyBlurIntensity = self.EditCollageView.currentCollage.vvAsset.beautyBlurIntensity;
//    float  beautyBrightIntensity = self.EditCollageView.currentVvAsset.beautyBrightIntensity;
//    float  beautyToneIntensity = self.EditCollageView.currentVvAsset.beautyToneIntensity;
    
    //画中画 透明度
    float alpha = self.EditCollageView.currentCollage.vvAsset.alpha;
    
    //画中画 旋转
    //画中画 左右镜像
    //画中画 上下镜像
    
    if( !isSave )
    {
        _pasterView.contentImage.image = nil;
        _pasterView.contentImage.image = self.trimmerView.currentCaptionView.file.thumbnailImage;
    }
    
    switch (pipType) {
        case kPIP_SINGLEFILTER://MARK:画中画 滤镜
        {
            if( isSave )
            {
                NSLog( @"画中画 滤镜路径：%@", filterUrl.absoluteString );
                NSLog( @"画中画 滤镜类型：%d", filterType );
                NSLog( @"画中画 滤镜强度：%.1f", filterIntensity );
                
                self.trimmerView.currentCaptionView.file.collageFilterIndex = self.EditCollageView.collage_filter_View.selectFilterIndex;
                self.trimmerView.currentCaptionView.file.collage.vvAsset.filterUrl = filterUrl;
                self.trimmerView.currentCaptionView.file.collage.vvAsset.filterType = filterType;
                self.trimmerView.currentCaptionView.file.collage.vvAsset.filterIntensity = filterIntensity;
                
//                VVAsset*  vvAsset = self.trimmerView.currentCaptionView.file.collage.vvAsset;
//                vvAsset.filterUrl = filterUrl;
//                vvAsset.filterType = filterType;
//                vvAsset.filterIntensity = filterIntensity;
                
            }
            else
            {
                self.EditCollageView.currentVvAsset.filterType = self.trimmerView.currentCaptionView.file.collage.vvAsset.filterType;
                self.EditCollageView.currentVvAsset.filterIntensity = self.trimmerView.currentCaptionView.file.collage.vvAsset.filterIntensity;
                self.EditCollageView.currentVvAsset.filterUrl = self.trimmerView.currentCaptionView.file.collage.vvAsset.filterUrl;
                [_thumbnailCoreSDK refreshCurrentFrame];
            }
            
            [self.EditCollageView.collage_filter_View removeFromSuperview];
            self.EditCollageView.collage_filter_View = nil;
        }
            break;
        case kPIP_ADJUST://MARK:画中画 调色
        {
            if( isSave )
            {
                NSLog( @"画中画 亮度：%.1f", brightness );
                NSLog( @"画中画 对比度：%.1f", contrast );
                NSLog( @"画中画 饱和度：%.1f", saturation );
                NSLog( @"画中画 锐度：%.1f", sharpness );
                NSLog( @"画中画 色温：%.1f", whiteBalance );
                NSLog( @"画中画 暗角：%.1f", vignette );
                
                self.trimmerView.currentCaptionView.file.collage.vvAsset.brightness =brightness;
                self.trimmerView.currentCaptionView.file.collage.vvAsset.contrast =contrast;
                self.trimmerView.currentCaptionView.file.collage.vvAsset.saturation =saturation;
                self.trimmerView.currentCaptionView.file.collage.vvAsset.sharpness =sharpness;
                self.trimmerView.currentCaptionView.file.collage.vvAsset.whiteBalance =whiteBalance;
                self.trimmerView.currentCaptionView.file.collage.vvAsset.vignette =vignette;
                
                VVAsset*  vvAsset = self.trimmerView.currentCaptionView.file.collage.vvAsset;
                vvAsset.brightness =brightness;
                vvAsset.contrast =contrast;
                vvAsset.saturation =saturation;
                vvAsset.sharpness =sharpness;
                vvAsset.whiteBalance =whiteBalance;
                vvAsset.vignette =vignette;
            }
            else{
                
                VVAsset*  vvAsset = self.trimmerView.currentCaptionView.file.collage.vvAsset;
                self.EditCollageView.currentVvAsset.brightness = vvAsset.brightness;
                self.EditCollageView.currentVvAsset.contrast = vvAsset.contrast;
                self.EditCollageView.currentVvAsset.saturation = vvAsset.saturation;
                self.EditCollageView.currentVvAsset.sharpness = vvAsset.sharpness;
                self.EditCollageView.currentVvAsset.whiteBalance = vvAsset.whiteBalance;
                self.EditCollageView.currentVvAsset.vignette = vvAsset.vignette;
                [_thumbnailCoreSDK refreshCurrentFrame];
            }
            
            [self.EditCollageView.collage_toni_View removeFromSuperview];
            self.EditCollageView.collage_toni_View = nil;
        }
            break;
        case kPIP_MIXEDMODE://MARK:画中画 混合模式
        {
            if( isSave )
            {
                NSLog( @"画中画 混合模式：%.1f", blendType );
                NSLog( @"画中画 不透明度：%.1f", alpha );
                VVAsset*  vvAsset = self.trimmerView.currentCaptionView.file.collage.vvAsset;
                vvAsset.blendType =blendType;
                vvAsset.alpha =alpha;
            }
            else{
                VVAsset*  vvAsset = self.trimmerView.currentCaptionView.file.collage.vvAsset;
                self.EditCollageView.currentVvAsset.blendType = vvAsset.blendType;
                self.EditCollageView.currentVvAsset.alpha = vvAsset.alpha;
                [_thumbnailCoreSDK refreshCurrentFrame];
            }
            [self.EditCollageView.collage_mixed_View removeFromSuperview];
            self.EditCollageView.collage_mixed_View = nil;
        }
            break;
        case kPIP_CUTOUT://MARK:画中画 抠图
        {
            [_pasterView setCutoutMagnifier:false];
            
            if( isSave )
            {
                self.trimmerView.currentCaptionView.file.collage.vvAsset.blendType = self.currentCollage.vvAsset.blendType;
                
                self.trimmerView.currentCaptionView.file.collage.vvAsset.chromaColor = self.currentCollage.vvAsset.chromaColor;
            }
            else
            {
                VVAsset*  vvAsset = self.trimmerView.currentCaptionView.file.collage.vvAsset;
                self.trimmerView.currentCaptionView.file.collage.vvAsset.blendType = RDBlendNormal;
                self.currentCollage.vvAsset.blendType = vvAsset.blendType;
                self.currentCollage.vvAsset.chromaColor = vvAsset.chromaColor;
                
                [_thumbnailCoreSDK refreshCurrentFrame];
            }
            
            [self.EditCollageView.collage_cutout_View removeFromSuperview];
            self.EditCollageView.collage_cutout_View = nil;
        }
            break;
        case kPIP_VOLUME://MARK:画中画 声音
        {
            if( isSave )
            {
                vloume = self.EditCollageView.collage_volume_View.volumeProgressSlider.value;
                audioFadeInDuration = self.EditCollageView.collage_volume_View.fadeInVolumeSlider.value;
                audioFadeOutDuration = self.EditCollageView.collage_volume_View.fadeOutVolumeSlider.value;
                
                NSLog( @"画中画 音量：%.1f", vloume );
                NSLog( @"画中画 淡入时长：%.1f", audioFadeInDuration );
                NSLog( @"画中画 淡出时长：%.1f", audioFadeOutDuration );
                
                self.trimmerView.currentCaptionView.file.collage.vvAsset.volume =vloume;
                self.trimmerView.currentCaptionView.file.collage.vvAsset.audioFadeInDuration =audioFadeInDuration;
                self.trimmerView.currentCaptionView.file.collage.vvAsset.audioFadeOutDuration =audioFadeOutDuration;
                
                VVAsset*  vvAsset = self.trimmerView.currentCaptionView.file.collage.vvAsset;
                vvAsset.volume =vloume;
                vvAsset.audioFadeInDuration =audioFadeInDuration;
                vvAsset.audioFadeOutDuration =audioFadeOutDuration;
            }
            else{
                VVAsset*  vvAsset = self.trimmerView.currentCaptionView.file.collage.vvAsset;
                
                self.EditCollageView.currentVvAsset.volume = vvAsset.volume;
                self.EditCollageView.currentVvAsset.audioFadeInDuration = vvAsset.audioFadeInDuration;
                self.EditCollageView.currentVvAsset.audioFadeOutDuration = vvAsset.audioFadeOutDuration;
                [_thumbnailCoreSDK refreshCurrentFrame];
            }
            
            [self.EditCollageView.collage_volume_View removeFromSuperview];
            self.EditCollageView.collage_volume_View = nil;
        }
            break;
        case kPIP_BEAUTY://MARK:画中画 美颜
        {
            if( isSave )
            {
                NSLog( @"画中画 美颜磨皮：%.1f", beautyBlurIntensity );
//                NSLog( @"画中画 美颜亮肤：%.1f", beautyBrightIntensity );
//                NSLog( @"画中画 美颜红润：%.1f", beautyToneIntensity );
                
                self.trimmerView.currentCaptionView.file.collage.vvAsset.beautyBlurIntensity = beautyBlurIntensity;
//                self.trimmerView.currentCaptionView.file.collage.vvAsset.beautyBrightIntensity = beautyBrightIntensity;
//                self.trimmerView.currentCaptionView.file.collage.vvAsset.beautyToneIntensity = beautyToneIntensity;
                
                VVAsset*  vvAsset = self.trimmerView.currentCaptionView.file.collage.vvAsset;
                vvAsset.beautyBlurIntensity = beautyBlurIntensity;
//                vvAsset.beautyBrightIntensity = beautyBrightIntensity;
//                vvAsset.beautyToneIntensity = beautyToneIntensity;
                
            }
            else{
                
                VVAsset*  vvAsset = self.trimmerView.currentCaptionView.file.collage.vvAsset;
                self.EditCollageView.currentVvAsset.beautyBlurIntensity = vvAsset.beautyBlurIntensity;
                [_thumbnailCoreSDK refreshCurrentFrame];
            }
            
            [self.EditCollageView.collage_beautay_View removeFromSuperview];
            self.EditCollageView.collage_beautay_View = nil;
        }
            break;
        case kPIP_TRANSPARENCY://MARK:画中画 透明度
        {
            if( isSave )
            {
                NSLog( @"画中画 透明度：%.1f", alpha );
                
                self.trimmerView.currentCaptionView.file.collage.vvAsset.alpha = alpha;
                
                VVAsset*  vvAsset = self.trimmerView.currentCaptionView.file.collage.vvAsset;
                vvAsset.alpha = alpha;
                
            }
            else{
                
                VVAsset*  vvAsset = self.trimmerView.currentCaptionView.file.collage.vvAsset;
                self.EditCollageView.currentVvAsset.alpha = vvAsset.alpha;
                [_thumbnailCoreSDK refreshCurrentFrame];
            }
            
            [self.EditCollageView.collage_transparency_View removeFromSuperview];
            self.EditCollageView.collage_transparency_View = nil;
        }
            break;
        case kPIP_ROTATE://MARK:画中画 旋转
        {
            
        }
            break;
        case kPIP_MIRROR://MARK:画中画 左右镜像
        {
            
        }
            break;
        case kPIP_FLIPUPANDDOWN://MARK:画中画 上下镜像
        {
            
        }
            break;
        default:
            break;
    }
}

//返回
-(void)editCollage_back
{
    self.editBtn.hidden = NO;
    self.finishBtn.hidden = NO;
    self.deletedBtn.hidden = NO;
    self.EditCollageView.hidden = YES;
    self.addBtn.hidden = YES;
}

#pragma mark- 替换媒体
- (void)addFileWithList:(NSMutableArray *)filelist{
    
    if ([filelist[0] isKindOfClass:[NSURL class]]) {
        for (int i = 0; i < filelist.count; i++) {
            NSURL *url = filelist[i];
            if ([url isKindOfClass:[NSURL class]]) {
                RDFile *file = [RDFile new];
                if([RDHelpClass isImageUrl:url]){
                    //图片
                    file.contentURL = url;
                    file.fileType = kFILEIMAGE;
                    file.imageDurationTime = CMTimeMakeWithSeconds(3, TIMESCALE);
                    file.speedIndex = 1;
                }else{
                    //视频
                    file.contentURL = url;
                    file.fileType = kFILEVIDEO;
                    AVURLAsset * asset = [AVURLAsset assetWithURL:file.contentURL];
                    CMTime duration = asset.duration;
                    file.videoDurationTime = duration;
                    file.videoTimeRange = CMTimeRangeMake(kCMTimeZero,file.videoDurationTime);
                    file.reverseVideoTimeRange = file.videoTimeRange;
                    file.videoTrimTimeRange = kCMTimeRangeInvalid;
                    file.reverseVideoTrimTimeRange = kCMTimeRangeInvalid;
                    file.speedIndex = 2;
                    
                    file.filtImagePatch = [RDHelpClass getMaterialThumbnail:file.contentURL];
                }
                file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
                [filelist replaceObjectAtIndex:i withObject:file];
            }
        }
    }
    
    RDFile * file = filelist[0];
    
    CMTimeRange timeRange = self.currentCollage.timeRange;
    
    VVAsset* vvAsset = [VVAsset new];
    vvAsset.url = file.contentURL;
    vvAsset.volume = 0.0;
    if ([RDHelpClass isImageUrl:file.contentURL]) {
        vvAsset.type = RDAssetTypeImage;
        vvAsset.fillType = RDImageFillTypeFit;
       vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(CMTimeGetSeconds(timeRange.duration), TIMESCALE));
    }else {
        CMTime duration = [AVURLAsset assetWithURL:file.contentURL].duration;
        vvAsset.type = RDAssetTypeVideo;
        vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(CMTimeGetSeconds(duration), TIMESCALE));
        
        if( CMTimeGetSeconds(duration) > CMTimeGetSeconds(timeRange.duration) )
        {
            vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, timeRange.duration);
        }
    }
    
    self.trimmerView.currentCaptionView.file.collage.vvAsset = vvAsset;
    self.currentCollage.vvAsset = vvAsset;
    self.EditCollageView.currentVvAsset = vvAsset;
    
    self.trimmerView.currentCaptionView.file.collage.timeRange = CMTimeRangeMake(self.trimmerView.currentCaptionView.file.collage.timeRange.start, vvAsset.timeRange.duration);
    self.currentCollage.timeRange = CMTimeRangeMake(self.currentCollage.timeRange.start, vvAsset.timeRange.duration);
}

-(void)collage_CoreBuild
{
    if( self.currentCollage )
    {
        if( _delegate && [_delegate respondsToSelector:@selector(collage_initPlay)] )
           [_delegate collage_initPlay];
    }
}


#pragma mark - RDVECoreDelegate
- (void)statusChanged:(RDVECore *)sender status:(RDVECoreStatus)status {
    if (status == kRDVECoreStatusReadyToPlay) {
        if(sender == self.EditCollageView.videoCoreSDK ){
            [RDSVProgressHUD dismiss];
            [self.EditCollageView.videoCoreSDK getImageWithTime:CMTimeMake(0.2, TIMESCALE) scale:1.0 completionHandler:^(UIImage *image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    CGPoint  center = self.pasterView.center;
                    
                    self.trimmerView.currentCaptionView.file.thumbnailImage = image;
                    
                    CaptionRangeView * rangeView = self.trimmerView.currentCaptionView;
                    [self initPasterViewWithFile:rangeView.file.thumbnailImage];
                    
                    
                    float ppsc = (rangeView.file.caption.size.width * kVIDEOWIDTH)/ (float) rangeView.file.caption.size.width <1 ? (rangeView.file.caption.size.width * kVIDEOWIDTH)/ (float) rangeView.file.caption.size.width : 1;
                    float sc = rangeView.file.scale;
                    CGFloat radius = atan2f(rangeView.file.captionTransform.b, rangeView.file.captionTransform.a);
                    
                    CGAffineTransform transform2 = CGAffineTransformMakeRotation(radius);
                    self.pasterView.transform = CGAffineTransformScale(transform2, sc * ppsc, sc * ppsc);
                    [self.pasterView setFramescale: sc * ppsc];
                    self.pasterView.center = center;
                    
                    self.pasterView.contentImage.alpha = rangeView.file.collage.vvAsset.alpha;
                    
                    BOOL isHorizontalMirror = rangeView.file.collage.vvAsset.isHorizontalMirror;
                    BOOL isVerticalMirror = rangeView.file.collage.vvAsset.isVerticalMirror;
                    if (isHorizontalMirror && isVerticalMirror) {
                        [self.pasterView setContentImageTransform:kLRUPFlipTransform];
                    }else if (isHorizontalMirror) {
                        [self.pasterView setContentImageTransform:kLRFlipTransform];
                    }else if (isVerticalMirror) {
                        [self.pasterView setContentImageTransform:kUDFlipTransform];
                    }
                    
                });
            }];
            self.EditCollageView.videoCoreSDK.delegate = nil;
        }
    }
}

-(void)dealloc
{
    if( _playBtnView )
    {
        [_playBtnView removeFromSuperview];
        _playBtnView = nil;
    }
    
    if( _playBtn )
    {
        [_playBtn removeFromSuperview];
        _playBtn = nil;
    }
    
    if( _durationTimeLbl )
    {
        [_durationTimeLbl removeFromSuperview];
        _durationTimeLbl = nil;
    }
    
    if( _currentTimeLbl )
    {
        [_currentTimeLbl removeFromSuperview];
        _currentTimeLbl = nil;
    }
    
    if( _dragTimeLbl )
    {
        [_dragTimeLbl removeFromSuperview];
        _dragTimeLbl = nil;
    }
    if( _addBtn )
    {
        [_addBtn removeFromSuperview];
        _addBtn = nil;
    }
    if( _finishBtn )
    {
        [_finishBtn removeFromSuperview];
        _finishBtn = nil;
    }
    if( _deletedBtn )
    {
        [_deletedBtn removeFromSuperview];
        _deletedBtn = nil;
    }
    if( _cancelBtn )
    {
        [_cancelBtn removeFromSuperview];
        _cancelBtn = nil;
    }
    if( _editBtn )
    {
        [_editBtn removeFromSuperview];
        _editBtn = nil;
    }
    if( _speechRecogBtn )
    {
        [_speechRecogBtn removeFromSuperview];
        _speechRecogBtn = nil;
    }
    if( _hud )
    {
        [_hud removeFromParentViewController];
        _hud = nil;
    }
    if( _albumScrollView )
    {
        [_albumScrollView removeFromSuperview];
        _albumScrollView = nil;
    }
    if( _soundTrimmerView )
    {
        [_soundTrimmerView.scrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if( [obj isKindOfClass:[UIImageView class]] )
            {
                UIImageView * imageView = (UIImageView*)obj;
                imageView.image = nil;
                [imageView removeFromSuperview];
                imageView = nil;
            }
        }];
        [_soundTrimmerView removeFromSuperview];
        _soundTrimmerView = nil;
    }
    if( _multi_trackTrimmerView )
    {
        [_multi_trackTrimmerView.scrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if( [obj isKindOfClass:[UIImageView class]] )
            {
                UIImageView * imageView = (UIImageView*)obj;
                imageView.image = nil;
                [imageView removeFromSuperview];
                imageView = nil;
            }
        }];
        [_multi_trackTrimmerView removeFromSuperview];
        _multi_trackTrimmerView = nil;
    }
    if( _subtitleTrimmerView )
    {
        [_subtitleTrimmerView.scrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if( [obj isKindOfClass:[UIImageView class]] )
            {
                UIImageView * imageView = (UIImageView*)obj;
                imageView.image = nil;
                [imageView removeFromSuperview];
                imageView = nil;
            }
        }];
        [_subtitleTrimmerView removeFromSuperview];
        _subtitleTrimmerView = nil;
    }
    if( _stickerTrimmerView )
    {
        [_subtitleTrimmerView.scrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if( [obj isKindOfClass:[UIImageView class]] )
            {
                UIImageView * imageView = (UIImageView*)obj;
                imageView.image = nil;
                [imageView removeFromSuperview];
                imageView = nil;
            }
        }];
        [_stickerTrimmerView removeFromSuperview];
        _stickerTrimmerView = nil;
    }
    
    if( _dewatermarkTrimmerView )
    {
        [_dewatermarkTrimmerView.scrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if( [obj isKindOfClass:[UIImageView class]] )
            {
                UIImageView * imageView = (UIImageView*)obj;
                imageView.image = nil;
                [imageView removeFromSuperview];
                imageView = nil;
            }
        }];
        [_dewatermarkTrimmerView removeFromSuperview];
        _dewatermarkTrimmerView = nil;
    }
    
    if( _collageTrimmerView )
    {
        [_collageTrimmerView.scrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if( [obj isKindOfClass:[UIImageView class]] )
            {
                UIImageView * imageView = (UIImageView*)obj;
                imageView.image = nil;
                [imageView removeFromSuperview];
                imageView = nil;
            }
        }];
        [_collageTrimmerView removeFromSuperview];
        _collageTrimmerView = nil;
    }
    
    if( _doodleTrimmerView )
    {
        [_doodleTrimmerView.scrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if( [obj isKindOfClass:[UIImageView class]] )
            {
                UIImageView * imageView = (UIImageView*)obj;
                imageView.image = nil;
                [imageView removeFromSuperview];
                imageView = nil;
            }
        }];
        [_doodleTrimmerView removeFromSuperview];
        _doodleTrimmerView = nil;
    }
    
    if( _fXTrimmerView )
    {
        [_fXTrimmerView.scrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if( [obj isKindOfClass:[UIImageView class]] )
            {
                UIImageView * imageView = (UIImageView*)obj;
                imageView.image = nil;
                [imageView removeFromSuperview];
                imageView = nil;
            }
        }];
        [_fXTrimmerView removeFromSuperview];
        _fXTrimmerView = nil;
    }
    
    
    
    
    if( _dragTimeView )
    {
        [_dragTimeView removeFromSuperview];
        _dragTimeView = nil;
    }
    
    if( _collageHud )
    {
        [_collageHud removeFromParentViewController];
        _collageHud = nil;
    }
    
}
@end
