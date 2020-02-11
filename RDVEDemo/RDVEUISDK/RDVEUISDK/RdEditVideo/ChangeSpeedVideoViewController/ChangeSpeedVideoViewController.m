//
//  ChangeSpeedVideoViewController.m
//  RDVEUISDK
//
//  Created by emmet on 16/7/12.
//  Copyright © 2016年 北京锐动天地信息技术有限公司. All rights reserved.
//


#import "ChangeSpeedVideoViewController.h"
#import "RDSVProgressHUD.h"
#import "RDVECore.h"
#import "RDNavigationViewController.h"
#import "RDGenSpecialEffect.h"
#import "RDZImageSlider.h"
#import "RDATMHud.h"
#import "RDExportProgressView.h"

@interface ChangeSpeedVideoViewController ()<RDVECoreDelegate, UIAlertViewDelegate>
{
    NSInteger            _oldSpeedIndex;
    float                _oldSpeed;
    RDVECore            *_videoCoreSDK;
    UIButton            *_playButton;
    UIView              *_playerView;
    BOOL                 _disappear;
    UIView              *_changeSpeedView;
    UIButton            *useToAllBtn;

    UILabel             *speedLabel;
    RDZImageSlider            *speedSlider;
    
    RDZImageSlider            *ImageSpeedSlider;
    float                     ImageSpeedSliderMinValue;
    float                     ImageSpeedSliderMaxValue;
    
    BOOL                      isContinueExport;
    BOOL                      idleTimerDisabled;//20171101 emmet 解决不锁屏的bug
    
    CMTime                  seekTime;
    bool                    _isCore;
}
@property (nonatomic, strong) RDATMHud *hud;

@property (nonatomic, strong) RDExportProgressView *exportProgressView;
@end

@implementation ChangeSpeedVideoViewController

-(void)seekTime:(CMTime) time
{
    seekTime = time;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    _disappear = NO;
}

- (void)dealloc{
    NSLog(@"%s",__func__);
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    _disappear = YES;
}

- (BOOL)prefersStatusBarHidden {
    return !iPhone_X;
}
- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (BOOL)shouldAutorotate{
    return NO;
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationPortrait;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    if( _videoCoreSDK )
    {
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            [_videoCoreSDK filterRefresh:_videoCoreSDK.currentTime];
//        });
    }
}

- (void)applicationEnterHome:(NSNotification *)notification{
    if(_exportProgressView){
        __block typeof(self) myself = self;
        [_videoCoreSDK cancelExportMovie:^{
            //更新UI需在主线程中操作
            dispatch_async(dispatch_get_main_queue(), ^{
                [myself.exportProgressView removeFromSuperview];
                myself.exportProgressView = nil;
                [[UIApplication sharedApplication] setIdleTimerDisabled:idleTimerDisabled];
            });
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if( !_isCore )
    {
        [_videoCoreSDK stop];
        [_videoCoreSDK.view removeFromSuperview];
        _videoCoreSDK.delegate = nil;
        _videoCoreSDK = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = iPhone4s;
    [[UIApplication sharedApplication] setStatusBarHidden:!iPhone_X];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;////关闭滑动返回的手势
    
    _oldSpeed = _selectFile.speed;
    _oldSpeedIndex = _selectFile.speedIndex;
    _editVideoSize = [RDHelpClass getEditSizeWithFile:_selectFile];
#if isUseCustomLayer
    if (_selectFile.fileType == kTEXTTITLE) {
        _selectFile.imageTimeRange = CMTimeRangeMake(kCMTimeZero, _selectFile.imageTimeRange.duration);
    }
#endif
    
    [self initPlayerView];
    [self initChangeSpeedView];
//    [self initPlayer];
    [self initChildView];
    [self initToolBarView];
    [RDHelpClass animateView:_changeSpeedView atUP:NO];
}

- (void)initChildView{
    
    if( _videoCoreSDK  )
    {
        _videoCoreSDK.delegate = self;
        _videoCoreSDK.frame = CGRectMake(0, kPlayerViewOriginX, kWIDTH, kPlayerViewHeight);
        [_playerView insertSubview:_videoCoreSDK.view atIndex:0];
//        [self.view insertSubview: belowSubview:self.playButton];
    }
    else
        [self initPlayer];
}

-(void)setVideoCoreSDK:(RDVECore *) core
{
    if( core )
        _isCore = true;
    _videoCoreSDK = core;
}

- (void)initToolBarView{
    UIView *toolBarView = [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT - kToolbarHeight, kWIDTH, kToolbarHeight)];
    toolBarView.backgroundColor = TOOLBAR_COLOR;
    [self.view addSubview:toolBarView];
    
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
    if (_selectFile.fileType == kFILEVIDEO || _selectFile.isGif) {
        titleLbl.text = RDLocalizedString(@"调速",nil);
    }else {
        titleLbl.text = RDLocalizedString(@"时长",nil);
    }
    titleLbl.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    titleLbl.font = [UIFont boldSystemFontOfSize:17.0];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    [toolBarView addSubview:titleLbl];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(0, 0, 44, 44);
    [cancelBtn addTarget:self action:@selector(touchesChangeSpeedCancelBtn) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:cancelBtn];
    
    UIButton *finishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    if (((RDNavigationViewController *)self.navigationController).isSingleFunc) {
        toolBarView.backgroundColor = [UIColor blackColor];
        toolBarView.frame = CGRectMake(0, kPlayerViewOriginX, kWIDTH, 44);
        
        [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_返回默认_"] forState:UIControlStateNormal];
        [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_返回点击_"] forState:UIControlStateHighlighted];
        
        finishBtn.frame = CGRectMake(kWIDTH - 64, 0, 64, 44);
        finishBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [finishBtn setTitleColor:Main_Color forState:UIControlStateNormal];
        [finishBtn setTitle:RDLocalizedString(@"导出", nil) forState:UIControlStateNormal];        
    }else {
        [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
        finishBtn.frame = CGRectMake(kWIDTH - 44, 0, 44, 44);
        [finishBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
    }
    [finishBtn addTarget:self action:@selector(touchesChangeSpeedSaveBtn) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:finishBtn];
    [RDHelpClass animateView:toolBarView atUP:NO];
}

/**初始化视频播放控件
 */
- (void)initPlayerView{
    _playerView = [[UIView alloc] init];
    if (((RDNavigationViewController *)self.navigationController).isSingleFunc) {
        _playerView.frame = CGRectMake(0, kNavigationBarHeight, kWIDTH, kPlayerViewHeight);
    }else {
        _playerView.frame = CGRectMake(0, kPlayerViewOriginX, kWIDTH, kPlayerViewHeight);
    }
    _playerView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_playerView];
    
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _playButton.backgroundColor = [UIColor clearColor];
    _playButton.frame = CGRectMake(5, _playerView.frame.origin.y - _playerView.frame.size.height - 44, 44, 44);
    [_playButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
    [_playButton addTarget:self action:@selector(playbtnTouchUpInslide) forControlEvents:UIControlEventTouchUpInside];
    [_playerView addSubview:_playButton];
}

- (void)initPlayer{
    //[RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
    NSMutableArray *scenes = [NSMutableArray new];
    RDScene *scene = [[RDScene alloc] init];
    VVAsset* vvasset = [[VVAsset alloc] init];
    vvasset.url = _selectFile.contentURL;
    
    if(_selectFile.fileType == kFILEVIDEO){
        vvasset.type = RDAssetTypeVideo;
        vvasset.videoActualTimeRange = _selectFile.videoActualTimeRange;
        if(_selectFile.isReverse){
            vvasset.url = _selectFile.reverseVideoURL;
            if (CMTimeRangeEqual(kCMTimeRangeZero, _selectFile.reverseVideoTimeRange)) {
                vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, _selectFile.reverseDurationTime);
            }else{
                vvasset.timeRange = _selectFile.reverseVideoTimeRange;
            }
            if(CMTimeCompare(vvasset.timeRange.duration, _selectFile.reverseVideoTrimTimeRange.duration) == 1 && CMTimeGetSeconds(_selectFile.reverseVideoTrimTimeRange.duration)>0){
                vvasset.timeRange = _selectFile.reverseVideoTrimTimeRange;
            }
            NSLog(@"timeRange : %f : %f ",CMTimeGetSeconds(vvasset.timeRange.start),CMTimeGetSeconds(vvasset.timeRange.duration));
            
        }
        else{
            if (CMTimeRangeEqual(kCMTimeRangeZero, _selectFile.videoTimeRange)) {
                vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, _selectFile.videoDurationTime);
            }else{
                vvasset.timeRange = _selectFile.videoTimeRange;
            }
            if(!CMTimeRangeEqual(kCMTimeRangeZero, _selectFile.videoTrimTimeRange) && CMTimeCompare(vvasset.timeRange.duration, _selectFile.videoTrimTimeRange.duration) == 1){
                vvasset.timeRange = _selectFile.videoTrimTimeRange;
            }
        }
        vvasset.speed        = _selectFile.speed;
        vvasset.volume       = _selectFile.videoVolume;
    }else{
        vvasset.type         = RDAssetTypeImage;
        if (CMTimeCompare(_selectFile.imageTimeRange.duration, kCMTimeZero) == 1) {
            vvasset.timeRange = _selectFile.imageTimeRange;
        }else {
            vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, _selectFile.imageDurationTime);
        }
        vvasset.speed        = _selectFile.speed;
        vvasset.volume       = _selectFile.videoVolume;
#if isUseCustomLayer
        if (_selectFile.fileType == kTEXTTITLE) {
            _selectFile.imageTimeRange = vvasset.timeRange;
            vvasset.fillType = RDImageFillTypeFull;
        }
#endif
    }
    scene.transition.type   = RDVideoTransitionTypeNone;
    scene.transition.duration = 0.0;
    vvasset.rotate = _selectFile.rotate;
    vvasset.isVerticalMirror = _selectFile.isVerticalMirror;
    vvasset.isHorizontalMirror = _selectFile.isHorizontalMirror;
    vvasset.crop = _selectFile.crop;
    
    vvasset.brightness = _selectFile.brightness;
    vvasset.contrast = _selectFile.contrast;
    vvasset.saturation = _selectFile.saturation;
    vvasset.sharpness = _selectFile.sharpness;
    vvasset.whiteBalance = _selectFile.whiteBalance;
    vvasset.vignette = _selectFile.vignette;
    if (_globalFilters.count > 0) {
        RDFilter* filter = _globalFilters[_selectFile.filterIndex];
        if (filter.type == kRDFilterType_LookUp) {
            vvasset.filterType = VVAssetFilterLookup;
        }else if (filter.type == kRDFilterType_ACV) {
            vvasset.filterType = VVAssetFilterACV;
        }else {
            vvasset.filterType = VVAssetFilterEmpty;
        }
        if (filter.filterPath.length > 0) {
            vvasset.filterUrl = [NSURL fileURLWithPath:filter.filterPath];
        }
    }
    
    [scene.vvAsset addObject:vvasset];
    //添加特效
    //滤镜特效
    if( _selectFile.customFilterIndex != 0 )
    {
        NSArray *filterFxArray = [NSArray arrayWithContentsOfFile:kNewSpecialEffectPlistPath];
        vvasset.customFilter = [RDGenSpecialEffect getCustomFilerWithFxId:_selectFile.customFilterId filterFxArray:filterFxArray timeRange:CMTimeRangeMake(kCMTimeZero,vvasset.timeRange.duration)];
    }
    //时间特效
    if( _selectFile.fileTimeFilterType != kTimeFilterTyp_None )
    {
        [RDGenSpecialEffect refreshVideoTimeEffectType:scenes atFile:_selectFile atscene:scene atTimeRange:_selectFile.fileTimeFilterTimeRange atIsRemove:NO];
    }
    else
        [scenes addObject:scene];
    if(!_videoCoreSDK){
        _videoCoreSDK = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                               APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                              LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                               videoSize:_editVideoSize
                                                     fps:kEXPORTFPS
                                              resultFail:^(NSError *error) {
                                                  NSLog(@"initSDKError:%@", error.localizedDescription);
                                              }];
        _videoCoreSDK.frame = _playerView.bounds;
        _videoCoreSDK.view.backgroundColor = [UIColor blackColor];
        _videoCoreSDK.delegate = self;
        [_playerView insertSubview:_videoCoreSDK.view belowSubview:_playButton];
    }
    [_videoCoreSDK setEditorVideoSize:_editVideoSize];
    [_videoCoreSDK setScenes:scenes];
    
    if (_musicURL) {
        RDMusic *music = [[RDMusic alloc] init];
        music.url = _musicURL;
        music.clipTimeRange = _musicTimeRange;
        music.volume = _musicVolume;
        music.isFadeInOut = YES;
        [_videoCoreSDK setMusics:[NSMutableArray arrayWithObject:music]];
    }
    [_videoCoreSDK build];
}

/*
 初始化调速控件
 */
- (void)initChangeSpeedView{
    _changeSpeedView = [[UIView alloc] init];
    if (((RDNavigationViewController *)self.navigationController).isSingleFunc) {
        _changeSpeedView.frame = CGRectMake(0, _playerView.frame.origin.y + _playerView.frame.size.height, kWIDTH, kHEIGHT - _playerView.frame.origin.y - _playerView.frame.size.height - - (iPhone_X ? 34 : 0));
    }else {
        _changeSpeedView.frame = CGRectMake(0, _playerView.frame.origin.y + _playerView.frame.size.height, kWIDTH, kHEIGHT - _playerView.frame.origin.y - _playerView.frame.size.height - kToolbarHeight);
    }
    _changeSpeedView.backgroundColor = TOOLBAR_COLOR;
    [self.view addSubview:_changeSpeedView];
    
    if (!((RDNavigationViewController *)self.navigationController).isSingleFunc) {
        useToAllBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        useToAllBtn.frame = CGRectMake(15, 0, 120, 35 );
        useToAllBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [useToAllBtn setTitle:RDLocalizedString(@"应用到所有", nil) forState:UIControlStateNormal];
        [useToAllBtn setTitle:RDLocalizedString(@"应用到所有", nil) forState:UIControlStateHighlighted];
        [useToAllBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateNormal];
        [useToAllBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [useToAllBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到默认"] forState:UIControlStateNormal];
        [useToAllBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到选择"] forState:UIControlStateSelected];
        [useToAllBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, -1, 0, 0)];
        [useToAllBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 1, 0, 0)];
        CGSize useToAllSize = [useToAllBtn.titleLabel sizeThatFits:CGSizeZero];
        useToAllBtn.frame = CGRectMake( 5, useToAllBtn.frame.origin.y, 120, useToAllBtn.frame.size.height);
        [useToAllBtn addTarget:self action:@selector(useToAllBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_changeSpeedView addSubview:useToAllBtn];
    }
    
    if(_selectFile.fileType == kFILEVIDEO || _selectFile.isGif){
        speedSlider = [[RDZImageSlider alloc] initWithFrame:CGRectMake(30, 35 + (_changeSpeedView.bounds.size.height - 35 - 27)/2.0, kWIDTH - 60, 27)];
        speedSlider.minimumValue = 0.0;
        speedSlider.maximumValue = 1.0;
        //设置了会减小滚动区域的宽度，但整个slider的宽度不变
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/片段编辑-轨道2"];
        [speedSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/片段编辑-轨道1"];
        [speedSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [speedSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
        [speedSlider addTarget:self action:@selector(beginScrub) forControlEvents:UIControlEventTouchDown];
        [speedSlider addTarget:self action:@selector(scrub) forControlEvents:UIControlEventValueChanged];
        [speedSlider addTarget:self action:@selector(endScrub) forControlEvents:UIControlEventTouchUpInside];
        [speedSlider addTarget:self action:@selector(endScrub) forControlEvents:UIControlEventTouchCancel];
        [_changeSpeedView addSubview:speedSlider];
        
        speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, speedSlider.frame.origin.y - 50, kWIDTH, 20)];
        speedLabel.text = [NSString stringWithFormat:@"%.2f",_selectFile.speed];
        speedLabel.textAlignment = NSTextAlignmentCenter;
        speedLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];;
        [speedLabel setFont:[UIFont systemFontOfSize:14]];
        [_changeSpeedView addSubview:speedLabel];
        
        [_changeSpeedView addSubview:[self scaleLabel:0 atStr:@"1/4" atRect:CGSizeMake(kWIDTH - 60, 45)]];
        [_changeSpeedView addSubview:[self scaleLabel:1 atStr:@"1/2" atRect:CGSizeMake(kWIDTH - 60, 45)]];
        [_changeSpeedView addSubview:[self scaleLabel:2 atStr:@"1x" atRect:CGSizeMake(kWIDTH - 60, 45)]];
        [_changeSpeedView addSubview:[self scaleLabel:3 atStr:@"2x" atRect:CGSizeMake(kWIDTH - 60, 45)]];
        [_changeSpeedView addSubview:[self scaleLabel:4 atStr:@"4x" atRect:CGSizeMake(kWIDTH - 60, 45)]];
        
        float value = _selectFile.speed;
        if( value <= 0.5 )
        {
            value = (value - 0.25)/0.25*0.25;
        }
        else if( (value > 0.5) && (value <= 1.0) )
        {
            value = (value - 0.5)/0.5*0.25 + 0.25;
        }
        else if( (value > 1.0) && (value <= 2.0) )
        {
            value = (value - 1.0)/1.0*0.25 + 0.5 ;
        }
        else if( (value > 2.0) && (value <= 4.0) )
        {
            value = (value - 2.0)/2.0*0.25 + 0.75;
        }
        speedSlider.value = value;
    }else{
        ImageSpeedSlider = [[RDZImageSlider alloc] initWithFrame:CGRectMake(30, 35 + (_changeSpeedView.bounds.size.height - 35 - 27)/2.0, kWIDTH - 60, 27)];
        ImageSpeedSlider.minimumValue = 0.0;
        ImageSpeedSlider.maximumValue = 1.0;
        ImageSpeedSliderMinValue = 0.1;
        ImageSpeedSliderMaxValue = 8.0;
        //设置了会减小滚动区域的宽度，但整个slider的宽度不变
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/片段编辑-轨道2"];
        [ImageSpeedSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/片段编辑-轨道1"];
        [ImageSpeedSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [ImageSpeedSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
        [ImageSpeedSlider addTarget:self action:@selector(ImageScrub) forControlEvents:UIControlEventTouchDown];
        [ImageSpeedSlider addTarget:self action:@selector(ImageScrub) forControlEvents:UIControlEventValueChanged];
        [ImageSpeedSlider addTarget:self action:@selector(ImageEndScrub) forControlEvents:UIControlEventTouchUpInside];
        [ImageSpeedSlider addTarget:self action:@selector(ImageEndScrub) forControlEvents:UIControlEventTouchCancel];
        [_changeSpeedView addSubview:ImageSpeedSlider];
        
        speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, ImageSpeedSlider.frame.origin.y - 50, kWIDTH, 20)];
        speedLabel.text = [NSString stringWithFormat:@"%.2f",CMTimeGetSeconds(_selectFile.imageDurationTime)];
        speedLabel.textAlignment = NSTextAlignmentCenter;
        speedLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        [speedLabel setFont:[UIFont systemFontOfSize:14.0]];
        [_changeSpeedView addSubview:speedLabel];
        
        [_changeSpeedView addSubview:[self scaleLabel:0 atStr:[NSString stringWithFormat:RDLocalizedString(@"%.1f秒",nil), ImageSpeedSliderMinValue] atRect:CGSizeMake(kWIDTH - 60, 45)]];
        [_changeSpeedView addSubview:[self scaleLabel:1 atStr:[NSString stringWithFormat:RDLocalizedString(@"%.1f秒",nil), roundf(ImageSpeedSliderMinValue+(ImageSpeedSliderMaxValue - ImageSpeedSliderMinValue)/4.0)]atRect:CGSizeMake(kWIDTH - 60, 45)]];
        [_changeSpeedView addSubview:[self scaleLabel:2 atStr:[NSString stringWithFormat:RDLocalizedString(@"%.1f秒",nil), roundf(ImageSpeedSliderMinValue+(ImageSpeedSliderMaxValue - ImageSpeedSliderMinValue)/4.0*2.0)] atRect:CGSizeMake(kWIDTH - 60, 45)]];
        [_changeSpeedView addSubview:[self scaleLabel:3 atStr:[NSString stringWithFormat:RDLocalizedString(@"%.1f秒",nil), roundf(ImageSpeedSliderMinValue+(ImageSpeedSliderMaxValue - ImageSpeedSliderMinValue)/4.0*3.0)] atRect:CGSizeMake(kWIDTH - 60, 45)]];
        [_changeSpeedView addSubview:[self scaleLabel:4 atStr:[NSString stringWithFormat:RDLocalizedString(@"%.1f秒",nil), ImageSpeedSliderMaxValue] atRect:CGSizeMake(kWIDTH - 60, 45)]];
        
        float value = CMTimeGetSeconds(_selectFile.imageDurationTime);
//        value = value - 3.0;
//        value = value/4.0;
        value = (value - ImageSpeedSliderMinValue) / (ImageSpeedSliderMaxValue - ImageSpeedSliderMinValue);
        ImageSpeedSlider.value = value;
   }
}

-(UILabel *)scaleLabel:(int) index atStr:(NSString *) str atRect:(CGSize) size
{
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake( index*(size.width/4.0) + 30 - 35/2.0 , speedLabel.frame.size.height + speedLabel.frame.origin.y + 15, 35, size.height - 27)];
    label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    label.font  = [UIFont systemFontOfSize:12.0];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = str;
    return label;
}

#pragma mark-滑动进度条 图片
- (void)ImageBeginScrub{
    if([_videoCoreSDK isPlaying]){
        [self  playVideo:NO];
    }
}

- (void)ImageScrub{
    float value = ImageSpeedSlider.value*(ImageSpeedSliderMaxValue - ImageSpeedSliderMinValue) + ImageSpeedSliderMinValue;
    value = roundf(value/ 0.1f)* 0.1f;
    speedLabel.text = [NSString stringWithFormat:@"%.2f",value];
}

- (void)ImageEndScrub{
    float value = ImageSpeedSlider.value*(ImageSpeedSliderMaxValue - ImageSpeedSliderMinValue) + ImageSpeedSliderMinValue;
    value = roundf(value/ 0.1f)* 0.1f;
    speedLabel.text = [NSString stringWithFormat:@"%.2f",value];
    _selectFile.imageDurationTime = CMTimeMakeWithSeconds(value, TIMESCALE);;
    
    [self initPlayer];
}

#pragma mark-滑动进度条 视频
- (void)beginScrub{
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
}

- (void)scrub{
    float value = 0.0;
    if( speedSlider.value <= 0.25 )
    {
        value = (speedSlider.value/0.25) * 0.25 + 0.25;
    }
    else if( (speedSlider.value > 0.25) && (speedSlider.value <= 0.5) )
    {
        value = ((speedSlider.value - 0.25 )/0.25) * 0.5 + 0.5;
    }
    else if( (speedSlider.value > 0.5) && (speedSlider.value <= 0.75) )
    {
        value = ((speedSlider.value - 0.5 )/0.25) * 1.0 + 1.0;
    }
    else if( (speedSlider.value > 0.75) && (speedSlider.value <= 1.0) )
    {
        value = ((speedSlider.value - 0.75 )/0.25) * 2.0 + 2.0;
    }
    speedLabel.text = [NSString stringWithFormat:@"%.2f", value];
}

- (void)endScrub{
    float value = 0.0;
    if( speedSlider.value <= 0.25 )
    {
        value = (speedSlider.value/0.25) * 0.25 + 0.25;
    }
    else if( (speedSlider.value > 0.25) && (speedSlider.value <= 0.5) )
    {
        value = ((speedSlider.value - 0.25 )/0.25) * 0.5 + 0.5;
    }
    else if( (speedSlider.value > 0.5) && (speedSlider.value <= 0.75) )
    {
        value = ((speedSlider.value - 0.5 )/0.25) * 1.0 + 1.0;
    }
    else if( (speedSlider.value > 0.75) && (speedSlider.value <= 1.0) )
    {
        value = ((speedSlider.value - 0.75 )/0.25) * 2.0 + 2.0;
    }
    speedLabel.text = [NSString stringWithFormat:@"%.2f", value];
    _selectFile.speed = value;
    [self initPlayer];
}

#pragma mark- 播放暂停
- (void)playVideo:(BOOL)flag{
    if(!flag){
        if([_videoCoreSDK isPlaying]){
            [_videoCoreSDK pause];
        }
        [_playButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
    }else{
        if(_disappear){
            return;
        }
        if(![_videoCoreSDK isPlaying]){
            [_videoCoreSDK play];
        }
        [_playButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateNormal];
    }
}

#pragma mark- RDVECoreDelegate
- (void)statusChanged:(RDVECoreStatus)status {
    if (status == kRDVECoreStatusReadyToPlay) {
//        [self playVideo:YES];
        if (CMTimeCompare(seekTime, kCMTimeZero) == 1) {
            [_videoCoreSDK seekToTime:seekTime];
            seekTime = kCMTimeZero;
        }
    }
}

#if isUseCustomLayer
- (void)progressCurrentTime:(CMTime)currentTime customDrawLayer:(CALayer *)customDrawLayer {
    [RDHelpClass refreshCustomTextLayerWithCurrentTime:currentTime customDrawLayer:customDrawLayer fileLsit:@[_selectFile]];
}
#endif

- (void)tapPlayerView{
    [self playVideo:![_videoCoreSDK isPlaying]];
}

- (void)playToEnd{
    [_videoCoreSDK seekToTime:kCMTimeZero];
    [self playVideo:NO];
}

#pragma mark- 点击事件
/**应用到所有
 */
- (void)useToAllBtnAction:(UIButton *)sender {
    sender.selected = !sender.selected;
}

/**点击取消调速
 */
- (void)touchesChangeSpeedCancelBtn{
    
    [self playVideo:NO];
    //emmet 20171019更新取消调速没生效
    _selectFile.speed = _oldSpeed;
    _selectFile.speedIndex = _oldSpeedIndex;
    if (((RDNavigationViewController *)self.navigationController).isSingleFunc) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }else {
        [self.navigationController popViewControllerAnimated:NO];
    }
}
/**点击保存调速
 */
- (void)touchesChangeSpeedSaveBtn{
    if (((RDNavigationViewController *)self.navigationController).isSingleFunc) {
        [self exportMovie];
    }else {
        [self playVideo:NO];
        [RDSVProgressHUD dismiss];
        
        [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        [self.navigationController popViewControllerAnimated:NO];
        if(_changeSpeedVideoFinishAction){
            _changeSpeedVideoFinishAction(_selectFile, useToAllBtn.selected);
        }
    }
}

- (void)playbtnTouchUpInslide{
     [self playVideo:!_videoCoreSDK.isPlaying];
}

#pragma mark - 导出
- (RDATMHud *)hud{
    if(!_hud){
        _hud = [[RDATMHud alloc] initWithDelegate:nil];
        [self.navigationController.view addSubview:_hud.view];
    }
    return _hud;
}

- (RDExportProgressView *)exportProgressView{
    if(!_exportProgressView){
        _exportProgressView = [[RDExportProgressView alloc] initWithFrame:CGRectMake(0,0, kWIDTH, kHEIGHT)];
        _exportProgressView.canTouchUpCancel = YES;
        [_exportProgressView setProgressTitle:RDLocalizedString(@"视频导出中，请耐心等待...", nil)];
        [_exportProgressView setProgress:0 animated:NO];
        [_exportProgressView setTrackbackTintColor:UIColorFromRGB(0x545454)];
        [_exportProgressView setTrackprogressTintColor:[UIColor whiteColor]];
        __weak typeof(self) weakself = self;
        _exportProgressView.cancelExportBlock = ^(){
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:RDLocalizedString(@"视频尚未导出完成，确定取消导出？",nil)
                                                                    message:nil
                                                                   delegate:weakself
                                                          cancelButtonTitle:RDLocalizedString(@"取消",nil)
                                                          otherButtonTitles:RDLocalizedString(@"确定",nil), nil];
                alertView.tag = 2;
                [alertView show];
                
            });
        };
    }
    return _exportProgressView;
}

- (void)exportMovie{
    if(!isContinueExport && ((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration > 0
       && _videoCoreSDK.duration > ((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration){
        
        NSString *maxTime = [RDHelpClass timeToStringNoSecFormat:((float )((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration)];
        NSString *message = [NSString stringWithFormat:RDLocalizedString(@"当前时长超过了导入时长限制%@秒",nil),maxTime];
        [self.hud setCaption:message];
        [self.hud show];
        [self.hud hideAfter:2];
        return;
    }
    if(!isContinueExport && ((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration > 0
       && _videoCoreSDK.duration > ((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration){
        
        NSString *maxTime = [RDHelpClass timeToStringNoSecFormat:((float )((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration)];
        NSString *message = [NSString stringWithFormat:@"%@。%@",[NSString stringWithFormat:RDLocalizedString(@"当前时长超过了导出时长限制%@秒",nil),maxTime],RDLocalizedString(@"您可以关闭本提示去调整，或继续导出。",nil)];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:RDLocalizedString(@"温馨提示",nil)
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:RDLocalizedString(@"关闭",nil)
                                                  otherButtonTitles:RDLocalizedString(@"继续",nil), nil];
        alertView.tag = 1;
        [alertView show];
        return;
    }
    
    [_videoCoreSDK stop];
    if(self.exportProgressView.superview){
        [self.exportProgressView removeFromSuperview];
    }
    [self.view addSubview:self.exportProgressView];
    self.exportProgressView.hidden = NO;
    [self.exportProgressView setProgress:0 animated:NO];
    
    [RDGenSpecialEffect addWatermarkToVideoCoreSDK:_videoCoreSDK totalDration:_videoCoreSDK.duration exportSize:_editVideoSize exportConfig:((RDNavigationViewController *)self.navigationController).exportConfiguration];
    
    NSString *export = ((RDNavigationViewController *)self.navigationController).outPath;
    if(export.length==0){
        export = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportvideo.mp4"];
    }
    unlink([export UTF8String]);
    idleTimerDisabled = [UIApplication sharedApplication].idleTimerDisabled;
    [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
    
    AVMutableMetadataItem *titleMetadata = [[AVMutableMetadataItem alloc] init];
    titleMetadata.key = AVMetadataCommonKeyTitle;
    titleMetadata.keySpace = AVMetadataKeySpaceQuickTimeMetadata;
    titleMetadata.locale =[NSLocale currentLocale];
    titleMetadata.value = @"titile";
    
    AVMutableMetadataItem *locationMetadata = [[AVMutableMetadataItem alloc] init];
    locationMetadata.key = AVMetadataCommonKeyLocation;
    locationMetadata.keySpace = AVMetadataKeySpaceQuickTimeMetadata;
    locationMetadata.locale = [NSLocale currentLocale];
    locationMetadata.value = @"location";
    
    AVMutableMetadataItem *creationDateMetadata = [[AVMutableMetadataItem alloc] init];
    creationDateMetadata.key = AVMetadataCommonKeyCopyrights;
    creationDateMetadata.keySpace = AVMetadataKeySpaceQuickTimeMetadata;
    creationDateMetadata.locale = [NSLocale currentLocale];
    creationDateMetadata.value = @"copyrights";
    
    AVMutableMetadataItem *descriptionMetadata = [[AVMutableMetadataItem alloc] init];
    descriptionMetadata.key = AVMetadataCommonKeyDescription;
    descriptionMetadata.keySpace = AVMetadataKeySpaceQuickTimeMetadata;
    descriptionMetadata.locale = [NSLocale currentLocale];
    descriptionMetadata.value = @"descriptionMetadata";
    
    WeakSelf(self);
    [_videoCoreSDK exportMovieURL:[NSURL fileURLWithPath:export]
                             size:_editVideoSize
                          bitrate:((RDNavigationViewController *)self.navigationController).videoAverageBitRate
                              fps:kEXPORTFPS
                         metadata:@[titleMetadata, locationMetadata, creationDateMetadata, descriptionMetadata]
                     audioBitRate:0
              audioChannelNumbers:1
           maxExportVideoDuration:((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration
                         progress:^(float progress) {
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 if(_exportProgressView)
                                     [_exportProgressView setProgress:progress*100.0 animated:NO];
                             });
                         } success:^{
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 [weakSelf exportMovieSuc:export];
                             });
                         } fail:^(NSError *error) {
                             NSLog(@"失败:%@",error);
                             [weakSelf exportMovieFail:error];
                         }];
    
}
- (void)exportMovieFail:(NSError *)error {
    isContinueExport = NO;
    if(self.exportProgressView.superview){
        [self.exportProgressView removeFromSuperview];
    }
    [_videoCoreSDK removeWaterMark];
    [_videoCoreSDK removeEndLogoMark];
    [_videoCoreSDK filterRefresh:kCMTimeZero];
    self.exportProgressView = nil;
    [[UIApplication sharedApplication] setIdleTimerDisabled:idleTimerDisabled];
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:error.localizedDescription
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:RDLocalizedString(@"确定",nil)
                                                  otherButtonTitles:nil, nil];
        alertView.tag = 3;
        [alertView show];
    }
}
- (void)exportMovieSuc:(NSString *)exportPath{
    isContinueExport = NO;
    if(self.exportProgressView.superview){
        [self.exportProgressView removeFromSuperview];
        self.exportProgressView = nil;
    }
    
    [_videoCoreSDK stop];
    _videoCoreSDK.delegate = nil;
    [_videoCoreSDK.view removeFromSuperview];
    _videoCoreSDK = nil;
    
    [self dismissViewControllerAnimated:NO completion:^{
        if(((RDNavigationViewController *)self.navigationController).callbackBlock){
            ((RDNavigationViewController *)self.navigationController).callbackBlock(exportPath);
        }
    }];
}

#pragma mark- UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (alertView.tag) {
        case 1:
            if (buttonIndex == 1) {
                isContinueExport = YES;
                [self exportMovie];
            }
            break;
        case 2:
            if(buttonIndex == 1){
                isContinueExport = NO;
                [_exportProgressView setProgress:0 animated:NO];
                [_exportProgressView removeFromSuperview];
                _exportProgressView = nil;
                [[UIApplication sharedApplication] setIdleTimerDisabled:idleTimerDisabled];
                [_videoCoreSDK cancelExportMovie:nil];
            }
            break;
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
