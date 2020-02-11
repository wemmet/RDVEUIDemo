//
//  RDTrimVideoViewController.m
//  RDVEUISDK
//
//  Created by emmet on 2017/6/29.
//  Copyright © 2017年 com.rd. All rights reserved.
//

#import "RDTrimVideoViewController.h"
#import "RDVECore.h"
#import "NMCutRangeSlider_RD.h"
#import "RDNavigationViewController.h"
#import "RDExportProgressView.h"
#import "RDUICliper.h"
#import "RDGenSpecialEffect.h"
#import "RDZSlider.h"
#import "ScrollViewChildItem.h"
#import "UIImageView+RDWebCache.h"
#import "RDDownTool.h"

#import "RDSVProgressHUD.h"
#import "RDTrimSlider.h"
@interface RDTrimVideoViewController ()<RDVECoreDelegate,NMCutRangeSlider_RDDelegate, UIScrollViewDelegate, CropDelegate, ScrollViewChildItemDelegate,RDTrimSliderDelegate>{
    CMTimeRange clipTimeRange;
    CMTimeRange clipSliderTimeRange;
    RDVECore      *thumbVideoCore;
    
//设置界面相关----------------------------------------
    BOOL                     _selectMin;
    BOOL                     _selectMax;
    BOOL                     isPortrait;
    BOOL                     isSelectedSquare;
    BOOL                     isSquareVideo;         //是否是正方形视频
    UIScrollView            *playerScrollView;      //用于定长截取的情况
    UIImageView             *playerScrollHintIV;
    UIButton                *squareChangeBtn;
    RDExportProgressView    *_exportProgress;
    BOOL                     _idleTimerDisabled;
    //--------------------------------------------------
    RDUICliper              *_cliper;
    
    
    CGSize                   presentationSize;
    UIView                  *volumeView;
    UILabel                 *volumeLbl;
    RDZSlider               *volumeSlider;
    BOOL                     isNeedPrepare;
    
    //              AE 图片素材编辑 界面
    UIView              *materialFilterVIew;
    NSMutableArray          <RDScene *>*scenes;
    NSInteger               currentFilterIndex;
    UIButton *filterBtn;
    UIButton *volumeBtn;
    
    UILabel         *titleLabel;
    //音量
    double           volumeCount;
    
    UIScrollView            *AEScrollView;
    UIView                  *AEVolumeView;
    UIView                  *AEfilterView;
    
    NSMutableArray  *thumbTimes;
    RDVECore        *thumbImageVideoCore;//截取缩率图
    
    BOOL            isFrist;
    
    CMTime                  seekTime;
    
    bool    isThumbImageCore;
    
    BOOL isCoreStop;
}
@property(nonatomic,strong)RDVECore         *videoCoreSDK;
@property(nonatomic,strong)UIView           *playerView;
@property(nonatomic,strong)UIButton         *playButton;
@property(nonatomic,strong)UIView           *showTimeView;
@property(nonatomic,strong)UILabel          *startTrimLabel;
@property(nonatomic,strong)UILabel          *trimRangeLabel;
@property(nonatomic,strong)UILabel          *endTrimLabel;
@property(nonatomic,strong)NMCutRangeSlider_RD *videoSlider;
@property(nonatomic,assign)CGFloat              selectVideoDuration;
@property(nonatomic,strong)UIView              *switchView;

//滤镜
@property(nonatomic,strong)UIView           *filterView;
@property(nonatomic,strong)UIScrollView     *filterChildsView;
@property (nonatomic, strong) NSMutableArray *filtersName;

@property(nonatomic,strong)RDTrimSlider    *trimSlider;

@property(nonatomic,strong)UIView                               *dragTimeView;   //调整当前的拖拽时间显示
@property(nonatomic,strong)UILabel                              *dragTimeLbl;//当前播放时间

@end

@implementation RDTrimVideoViewController
-(void)seekTime:(CMTime) time
{
    seekTime = time;
}
- (void)initChildView{
    
    if( _videoCoreSDK  )
    {
        _videoCoreSDK.delegate = self;
        _videoCoreSDK.frame = CGRectMake(0, 0, kWIDTH, kPlayerViewHeight);
        _videoCoreSDK.view.frame = CGRectMake(0, 0, kWIDTH, kPlayerViewHeight);
        [_playerView insertSubview:_videoCoreSDK.view atIndex:0];
        scenes = [_videoCoreSDK getScenes];
//        [self.view insertSubview: belowSubview:self.playButton];
    }
    else
        [self initPlayer];
}

-(void)setVideoCoreSDK:(RDVECore *) core
{
    if( core )
        isCoreStop = true;
    _videoCoreSDK = core;
}

- (void)initThumbVideoCore{
    [thumbVideoCore stop];
    thumbVideoCore = nil;
    
    NSMutableArray *scenes = [NSMutableArray new];
    RDScene *scene = [[RDScene alloc] init];
    VVAsset* vvasset = [[VVAsset alloc] init];
    
    vvasset.url = _trimFile.contentURL;
    
    if(_trimFile.fileType == kFILEVIDEO){
        vvasset.videoActualTimeRange = _trimFile.videoActualTimeRange;
        vvasset.type = RDAssetTypeVideo;
        if(_trimFile.isReverse){
            if (CMTimeRangeEqual(kCMTimeRangeZero, _trimFile.reverseVideoTimeRange)) {
                vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, _trimFile.reverseDurationTime);
            }else{
                vvasset.timeRange = _trimFile.reverseVideoTimeRange;
            }
            
            NSLog(@"timeRange.duration:%f",CMTimeGetSeconds(vvasset.timeRange.duration));
        }
        else{
            if (CMTimeRangeEqual(kCMTimeRangeZero, _trimFile.videoTimeRange)) {
                vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, _trimFile.videoDurationTime);
            }else{
                vvasset.timeRange = _trimFile.videoTimeRange;
            }
            NSLog(@"timeRange.duration:%f",CMTimeGetSeconds(vvasset.timeRange.duration));
        }
        vvasset.speed        = _trimFile.speed;
        vvasset.volume       = _trimFile.videoVolume;
    }else{
        NSLog(@"图片");
        vvasset.type         = RDAssetTypeImage;
        if (CMTimeCompare(_trimFile.imageTimeRange.duration, kCMTimeZero) == 1) {
            vvasset.timeRange = _trimFile.imageTimeRange;
        }else {
            vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, _trimFile.imageDurationTime);
        }
        vvasset.speed        = _trimFile.speed;
        vvasset.volume       = _trimFile.videoVolume;
    }
    scene.transition.type   = RDVideoTransitionTypeNone;
    scene.transition.duration = 0.0;
    vvasset.rotate = _trimFile.rotate;
    vvasset.isVerticalMirror = _trimFile.isVerticalMirror;
    vvasset.isHorizontalMirror = _trimFile.isHorizontalMirror;
    vvasset.crop = _trimFile.crop;
    if (_isAdjustVolumeEnable) {
        vvasset.crop = CGRectMake(0, 0, 1, 1);
    }
    [scene.vvAsset addObject:vvasset];
    [scenes addObject:scene];
    
    if (!thumbVideoCore) {
        thumbVideoCore =  [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                                 APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                                LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                                 videoSize:_editVideoSize
                                                       fps:kEXPORTFPS
                                                resultFail:^(NSError *error) {
                                                    NSLog(@"initSDKError:%@", error.localizedDescription);
                                                }];
    }
    [thumbVideoCore setEditorVideoSize:_editVideoSize];
    [thumbVideoCore setScenes:scenes];
    [thumbVideoCore build];
    
}

/**初始化播放器
 */
- (void)initPlayer{
    scenes = [NSMutableArray new];
    RDScene *scene = [[RDScene alloc] init];
    VVAsset* vvasset = [[VVAsset alloc] init];
    vvasset.url = _trimFile.contentURL;
    vvasset.identifier = @"video";
    if(_trimFile.fileType == kFILEVIDEO){
        vvasset.videoActualTimeRange = _trimFile.videoActualTimeRange;
        vvasset.type = RDAssetTypeVideo;
        if(_trimFile.isReverse){
            vvasset.url = _trimFile.reverseVideoURL;
            
            if (CMTimeRangeEqual(kCMTimeRangeZero, _trimFile.reverseVideoTimeRange)) {
                vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, _trimFile.reverseDurationTime);
            }else{
                vvasset.timeRange = _trimFile.reverseVideoTimeRange;
            }
            
            NSLog(@"timeRange.duration:%f",CMTimeGetSeconds(vvasset.timeRange.duration));
        }
        else{
            if (CMTimeRangeEqual(kCMTimeRangeZero, _trimFile.videoTimeRange)) {
                vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, _trimFile.videoDurationTime);
            }else{
                vvasset.timeRange = _trimFile.videoTimeRange;
            }
            NSLog(@"timeRange.duration:%f",CMTimeGetSeconds(vvasset.timeRange.duration));
        }
        vvasset.speed        = _trimFile.speed;
        vvasset.volume       = _trimFile.videoVolume;
    }else{
        NSLog(@"图片");
        vvasset.type         = RDAssetTypeImage;
        vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, _trimFile.imageDurationTime);
        vvasset.speed        = _trimFile.speed;
        vvasset.volume       = _trimFile.videoVolume;
    }
    scene.transition.type   = RDVideoTransitionTypeNone;
    scene.transition.duration = 0.0;
    vvasset.rotate = _trimFile.rotate;
    vvasset.isVerticalMirror = _trimFile.isVerticalMirror;
    vvasset.isHorizontalMirror = _trimFile.isHorizontalMirror;
    vvasset.crop = _trimFile.crop;
    if (_isAdjustVolumeEnable) {
        vvasset.crop = CGRectMake(0, 0, 1, 1);
    }
    
    if (_globalFilters.count > 0) {
        RDFilter* filter = _globalFilters[_trimFile.filterIndex];
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
    
    vvasset.brightness = _trimFile.brightness;
    vvasset.contrast = _trimFile.contrast;
    vvasset.saturation = _trimFile.saturation;
    vvasset.sharpness = _trimFile.sharpness;
    vvasset.whiteBalance = _trimFile.whiteBalance;
    vvasset.vignette = _trimFile.vignette;
    [scene.vvAsset addObject:vvasset];
    //添加特效
    //滤镜特效
    if( _trimFile.customFilterIndex != 0 )
    {
        NSArray *filterFxArray = [NSArray arrayWithContentsOfFile:kNewSpecialEffectPlistPath];
        vvasset.customFilter = [RDGenSpecialEffect getCustomFilerWithFxId:_trimFile.customFilterId filterFxArray:filterFxArray timeRange:CMTimeRangeMake(kCMTimeZero,vvasset.timeRange.duration)];
    }
    //时间特效
    if( _trimFile.fileTimeFilterType != kTimeFilterTyp_None )
    {
        [RDGenSpecialEffect refreshVideoTimeEffectType:scenes atFile:_trimFile atscene:scene atTimeRange:_trimFile.fileTimeFilterTimeRange atIsRemove:NO];
    }
    else
        [scenes addObject:scene];

    if (!_videoCoreSDK) {
        _videoCoreSDK = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                               APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                              LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                               videoSize:_editVideoSize
                                                     fps:kEXPORTFPS
                                              resultFail:^(NSError *error) {
                                                  NSLog(@"initSDKError:%@", error.localizedDescription);
                                              }];
        _videoCoreSDK.delegate = self;
        _videoCoreSDK.frame = self.playerView.bounds;
        if (_isShowClipView) {
            [_playerView insertSubview:_videoCoreSDK.view atIndex:0];
        }else {
            [self.playerView insertSubview:_videoCoreSDK.view belowSubview:self.playButton];
        }
    }
    if (_isRotateEnable) {
        CGSize size = [self getVideoSizeForTrack];
        if(size.height == size.width){
            presentationSize = size;
        }else if(isPortrait){
            presentationSize = size;
            if(size.height < size.width){
                presentationSize  = CGSizeMake(size.height, size.width);
            }
            if(_trimFile.rotate == -90 || _trimFile.rotate == -270){
                presentationSize  = CGSizeMake(size.width, size.height);
            }
        }else{
            presentationSize  = size;
            if(_trimFile.rotate == -90 || _trimFile.rotate == -270){
                presentationSize  = CGSizeMake(size.height, size.width);
            }
        }
        size = presentationSize;
        if((_trimFile.rotate == -90 || _trimFile.rotate == -270) && isPortrait){
            size.width = presentationSize.height;
            size.height = presentationSize.width;
        }
        [_videoCoreSDK setEditorVideoSize:size];
    }
    
    [_videoCoreSDK setScenes:scenes];
    
    if (_musicURL) {
        RDMusic *music = [[RDMusic alloc] init];
        music.url = _musicURL;
        music.clipTimeRange = _musicTimeRange;
        music.volume = _musicVolume;
        music.isFadeInOut = YES;
        [_videoCoreSDK setMusics:[NSMutableArray arrayWithObject:music]];
    }
    if (_isAdjustVolumeEnable) {
        _videoCoreSDK.enableAudioEffect = YES;
    }
    [_videoCoreSDK build];
}

/**播放器
 */
- (UIView *)playerView{
    if(!_playerView){
        _playerView = [UIView new];
        _playerView.backgroundColor = [UIColor clearColor];
        if (!isSquareVideo && _trimType != TRIMMODEAUTOTIME && _trimExportVideoType != TRIMEXPORTVIDEOTYPE_ORIGINAL) {
            if (isSelectedSquare) {
                _playerView.frame = CGRectMake(0, 0, playerScrollView.contentSize.width, playerScrollView.contentSize.height);
            }else {
                if (isPortrait) {
                    _playerView.frame = CGRectMake((playerScrollView.frame.size.height - playerScrollView.frame.size.height*9/16)/2.0, 0, playerScrollView.frame.size.width*9/16, playerScrollView.frame.size.height);
                }else {
                    _playerView.frame = CGRectMake(0, (playerScrollView.frame.size.height - playerScrollView.frame.size.height*9/16)/2.0, playerScrollView.frame.size.width, playerScrollView.frame.size.height*9/16);
                }
            }
            [playerScrollView addSubview:_playerView];
        }else {
            if (((RDNavigationViewController *)self.navigationController).isSingleFunc) {
                _playerView.frame = CGRectMake(0, kNavigationBarHeight, kWIDTH, kPlayerViewHeight);
            }else {
                _playerView.frame = CGRectMake(0, kPlayerViewOriginX, kWIDTH, kPlayerViewHeight);
            }
            [self.view addSubview:_playerView];
        }
        
        if (!_isShowClipView) {
            [self.view addSubview:[self playButton]];
        }
    }
    return _playerView;
}

/**播放暂停按键
 */
- (UIButton *)playButton{
    if(!_playButton){
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _playButton.backgroundColor = [UIColor clearColor];
        if (playerScrollView) {
            _playButton.frame = CGRectMake(5, playerScrollView.frame.origin.y + playerScrollView.frame.size.height - 44, 44, 44);
        }else {
            _playButton.frame = CGRectMake(5, _playerView.frame.origin.y + _playerView.frame.size.height - 44, 44, 44);
        }
        [_playButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
        [_playButton addTarget:self action:@selector(tapPlayButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playButton;
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

- (void)viewDidLoad {
    [super viewDidLoad];
    if (_customBackgroundColor) {
        self.view.backgroundColor = _customBackgroundColor;
    }else {
        self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    }
    [self setValue];
    
    if (_trimType != TRIMMODEAUTOTIME && _trimExportVideoType != TRIMEXPORTVIDEOTYPE_ORIGINAL) {
        if ((_trimExportVideoType == TRIMEXPORTVIDEOTYPE_SQUARE || _trimExportVideoType == TRIMEXPORTVIDEOTYPE_MIXED_SQUARE)) {
            isSelectedSquare = YES;
        }else {
            isSelectedSquare = NO;
        }
        if (_editVideoSize.width == _editVideoSize.height) {
            isSquareVideo = YES;
        }else {
            [self initPlayerScrollView];
        }
    }
    [self playerView];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, _playerView.frame.size.height + _playerView.frame.origin.y, kWIDTH, kHEIGHT - (_playerView.frame.size.height + _playerView.frame.origin.y))];
    imageView.backgroundColor = TOOLBAR_COLOR;
    [self.view addSubview:imageView];
    
//    if( _isAdjustVolumeEnable  )
//    {
//        _playerView.frame = CGRectMake(0, kPlayerViewOriginX, kWIDTH, kPlayerViewHeight);
//    }
    [self initChildView];
    if (_trimFile.isVerticalMirror || _trimFile.isHorizontalMirror || _trimFile.rotate != 0 || _trimFile.isReverse) {
        if( !_trimFile.contentURL )
            [self initThumbVideoCore];
    }
    [self initVideoRangeSlider];
    
    if (_trimType != TRIMMODEAUTOTIME && !_isAdjustVolumeEnable) {
        [self.view addSubview:self.switchView];
    }
    
    if (_isRotateEnable) {
        UIButton *rotationBtn = [[UIButton alloc] init];
        rotationBtn.frame = CGRectMake(kWIDTH - 44, _videoSlider.frame.origin.y - 64, 44.0, 44.0);
        [rotationBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/bianji/剪辑-编辑旋转默认_"] forState:UIControlStateNormal];
        [rotationBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/bianji/剪辑-编辑旋转点击_"] forState:UIControlStateHighlighted];
        [rotationBtn addTarget:self action:@selector(rotationBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        rotationBtn.tag = 1;
        [self.view addSubview:rotationBtn];
    }
    
    [self.view addSubview:self.showTimeView];
    
    if (_trimType != TRIMMODEAUTOTIME
        && _trimExportVideoType != TRIMEXPORTVIDEOTYPE_ORIGINAL
        && (![[NSUserDefaults standardUserDefaults] objectForKey:@"showedPortraitHint"]
            || ![[NSUserDefaults standardUserDefaults] objectForKey:@"showedLandscapeHint"]))
    {
        [self initPlayerScrollHintIV];
    }
    if (_isShowClipView) {
        [self initCropView];
    }
    [self initToolBarView];
//    [RDHelpClass animateView:_videoSlider atUP:NO];
    if( !_trimFile.filtImagePatch )
        isThumbImageCore = true;
}



- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = iPhone4s;
    [[UIApplication sharedApplication] setStatusBarHidden:!iPhone_X];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationDidEnterBackgroundNotification object:nil];
   
    if(_defaultSelectMinOrMax == kRDDefaultSelectCutMin && _trimType == TRIMMODESPECIFYTIME_TWO){
        [self switchAction];
    }

    if (isNeedPrepare) {
        [_videoCoreSDK prepare];
        if (thumbVideoCore) {
            [thumbVideoCore prepare];
            [_videoSlider continueLoadThumb];
        }
    }
    if( _videoCoreSDK )
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self seektimeCore];
        });
    }
    
    if( isThumbImageCore )
    {
        [self initThumbImageVideoCore];
        _videoSlider.videoCoreSDK = thumbImageVideoCore;
        isThumbImageCore = false;
    }
    [_videoSlider loadCutRangeSlider];
}

-(void)seektimeCore
{
    if( CMTimeGetSeconds(seekTime) > 0 )
    {
        double time = CMTimeGetSeconds(seekTime);
        [_videoCoreSDK seekToTime:seekTime];
        seekTime = kCMTimeZero;
        float duration = _videoCoreSDK.duration;
        float progress = time/duration;
        if(!isnan(progress)){
            if (_isAdjustVolumeEnable)
            {
                if( [_trimSlider progress:progress] >= 1.0 )
                {
                    [self playToEnd];
                }
                else
                    _startTrimLabel.text = [NSString stringWithFormat:@"%@",[RDHelpClass timeToStringFormat:progress]];
            }
            else
                [_videoSlider progress:progress];
        }
    }
}



- (void)applicationEnterHome:(NSNotification *)notification{
    if(_exportProgress){
        [_videoCoreSDK cancelExportMovie:^{
            //更新UI需在主线程中操作
            dispatch_async(dispatch_get_main_queue(), ^{
                [_exportProgress removeFromSuperview];
                _exportProgress = nil;
            });
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];

    if (playerScrollHintIV && !playerScrollHintIV.hidden) {
        [self performSelector:@selector(hiddenPlayerScrollHintIV) withObject:nil afterDelay:2];
    }
    [thumbImageVideoCore prepare];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    [_videoCoreSDK stop];
    [thumbVideoCore stop];
    [_videoSlider.imageGenerator cancelAllCGImageGeneration];
    [thumbImageVideoCore stop];
}

- (void)setValue{
    if(!_trimFile && _trimVideoAsset){
        _trimFile = [RDFile new];
        _trimFile.contentURL = _trimVideoAsset.URL;
        _trimFile.fileType = kFILEVIDEO;
        _trimFile.videoDurationTime = [AVURLAsset assetWithURL:_trimFile.contentURL].duration;
        _trimFile.videoTimeRange = CMTimeRangeMake(kCMTimeZero,_trimFile.videoDurationTime);
        _trimFile.reverseVideoTimeRange = _trimFile.videoTimeRange;
        _trimFile.videoTrimTimeRange = kCMTimeRangeInvalid;
        _trimFile.reverseVideoTrimTimeRange = kCMTimeRangeInvalid;
        _trimFile.speedIndex = 2;
        _trimFile.thumbImage = [RDHelpClass getThumbImageWithUrl:_trimFile.contentURL];
    }else {
        if (CGRectEqualToRect(_trimFile.crop, CGRectZero)) {
            _trimFile.crop                  = CGRectMake(0, 0, 1, 1);
        }
    }
    if (_trimFile.isReverse) {
        CGFloat dur = CMTimeGetSeconds(_trimFile.reverseVideoTimeRange.duration);
        if(isnan(dur) || dur ==0){
            _trimFile.reverseVideoTimeRange = CMTimeRangeMake(kCMTimeZero, [AVURLAsset assetWithURL:_trimFile.reverseVideoURL].duration);
        }
        dur = CMTimeGetSeconds(_trimFile.reverseVideoTrimTimeRange.duration);
        if(isnan(dur) || dur ==0){
            _trimFile.reverseVideoTrimTimeRange = _trimFile.reverseVideoTimeRange;
        }
        clipTimeRange = _trimFile.reverseVideoTimeRange;
        clipSliderTimeRange = _trimFile.reverseVideoTrimTimeRange;
        
        _editVideoSize = [RDHelpClass trackSize:_trimFile.reverseVideoURL rotate:_trimFile.rotate crop:_trimFile.crop];
        
        isPortrait = [RDHelpClass isVideoPortrait:[AVURLAsset assetWithURL:_trimFile.reverseVideoURL]];
    }else {
        if (_trimFile.isGif) {
            clipTimeRange = CMTimeRangeMake(kCMTimeZero, _trimFile.imageDurationTime);
            if (CMTimeCompare(_trimFile.imageTimeRange.duration, kCMTimeZero) == 1) {
                clipSliderTimeRange = _trimFile.imageTimeRange;
            }else {
                clipSliderTimeRange = clipTimeRange;
            }
        }else {
            CGFloat dur = CMTimeGetSeconds(_trimFile.videoTimeRange.duration);
            if(isnan(dur) || dur ==0){
                _trimFile.videoTimeRange = CMTimeRangeMake(kCMTimeZero, [AVURLAsset assetWithURL:_trimFile.contentURL].duration);
            }
            dur = CMTimeGetSeconds(_trimFile.videoTrimTimeRange.duration);
            if(isnan(dur) || dur ==0){
                _trimFile.videoTrimTimeRange = _trimFile.videoTimeRange;
            }
            clipTimeRange = _trimFile.videoTimeRange;
            clipSliderTimeRange = _trimFile.videoTrimTimeRange;
        }
        if (_isAdjustVolumeEnable) {
            if (_trimFile.isGif) {
                _editVideoSize = [RDHelpClass getFullScreenImageWithUrl:_trimFile.contentURL].size;
            }else {
                _editVideoSize = [RDHelpClass trackSize:_trimFile.contentURL rotate:0];
            }
        }else {
            _editVideoSize = [RDHelpClass getEditSizeWithFile:_trimFile];
        }
        isPortrait = [RDHelpClass isVideoPortrait:[AVURLAsset assetWithURL:_trimFile.contentURL]];
    }
}

- (void)initToolBarView{
    UIView *toolBarView = [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT - kToolbarHeight, kWIDTH, kToolbarHeight)];
    toolBarView.backgroundColor = TOOLBAR_COLOR;
    [self.view addSubview:toolBarView];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(0, 0, 44, 44);
    if (_cancelButtonTitle.length > 0) {
        cancelBtn.backgroundColor = _cancelButtonBackgroundColor;
        [cancelBtn setTitle:_cancelButtonTitle forState:UIControlStateNormal];
        [cancelBtn setTitleColor:_cancelButtonTitleColor forState:UIControlStateNormal];
        CGSize size = [cancelBtn sizeThatFits:CGSizeZero];
        cancelBtn.frame = CGRectMake(10, 0, size.width, 44);
    }else {
        [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
    }
    [cancelBtn addTarget:self action:@selector(tapBackBtn) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:cancelBtn];
    
    UIButton *finishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    finishBtn.frame = CGRectMake(kWIDTH - 44, 0, 44, 44);
    if (_otherButtonTitle.length > 0) {
        finishBtn.backgroundColor = _cancelButtonBackgroundColor;
        [finishBtn setTitle:_otherButtonTitle forState:UIControlStateNormal];
        [finishBtn setTitleColor:_otherButtonTitleColor forState:UIControlStateNormal];
        CGSize size = [finishBtn sizeThatFits:CGSizeZero];
        finishBtn.frame = CGRectMake(kWIDTH - size.width - 10, 0, size.width, 44);
    }else if (((RDNavigationViewController *)self.navigationController).isSingleFunc) {
        toolBarView.backgroundColor = [UIColor blackColor];
        toolBarView.frame = CGRectMake(0, kPlayerViewOriginX, kWIDTH, 44);
        
        [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_返回默认_"] forState:UIControlStateNormal];
        [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_返回点击_"] forState:UIControlStateHighlighted];
        
        finishBtn.frame = CGRectMake(kWIDTH - 64, 0, 64, 44);
        finishBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [finishBtn setTitleColor:Main_Color forState:UIControlStateNormal];
        [finishBtn setTitle:RDLocalizedString(@"导出", nil) forState:UIControlStateNormal];
    }else {
        [finishBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
    }
    [finishBtn addTarget:self action:@selector(tapsaveBtn) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:finishBtn];
    
    if (_isAdjustVolumeEnable) {
        if( isThumbImageCore )
            [self initThumbImageVideoCore];
    
        isFrist = true;
        Float64 nowTime = _videoCoreSDK.duration;
        _videoSlider.selectedDurationValue = _trimDuration_OneSpecifyTime;
        _videoSlider.moveValue = _trimDuration_OneSpecifyTime/nowTime>1.0?1.0:_trimDuration_OneSpecifyTime/nowTime;
        _videoSlider.upperValue = _videoSlider.lowerValue + _videoSlider.moveValue;
        
        float width = (kWIDTH - 44*2)/2.0;
        
        filterBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        filterBtn.frame = CGRectMake(44, 0, width, 44);
        [filterBtn setTitle:RDLocalizedString(@"滤镜", nil) forState:UIControlStateNormal];
        [filterBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:1.5] forState:UIControlStateNormal];
        [filterBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        filterBtn.titleLabel.font = [UIFont systemFontOfSize:17.0];
        [filterBtn addTarget:self action:@selector(filterBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [toolBarView addSubview:filterBtn];
        
        volumeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        volumeBtn.frame = CGRectMake(44 + width, 0, width, 44);
//        [volumeBtn setImage:[RDHelpClass imageWithContentOfFile:@"音量"] forState:UIControlStateNormal];
        [volumeBtn setTitle:RDLocalizedString(@"音量", nil) forState:UIControlStateNormal];
        [volumeBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:1.5] forState:UIControlStateNormal];
        [volumeBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        volumeBtn.titleLabel.font = [UIFont systemFontOfSize:17.0];
        [volumeBtn addTarget:self action:@selector(volumeBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        volumeBtn.selected = YES;
        [toolBarView addSubview:volumeBtn];
        
        volumeView = [[UIView alloc] initWithFrame:CGRectMake(0, ( _videoSlider.frame.size.height - kToolbarHeight - 51 )/2.0, kWIDTH, 51)];
        [self.view addSubview:volumeView];
        
        UIImageView *VolumeImageView = [[UIImageView alloc] initWithFrame:CGRectMake( (50-31)/2.0 , 0, 31, 31)];
        VolumeImageView.image = [RDHelpClass imageWithContentOfFile:@"音量"];
        [volumeView addSubview:VolumeImageView];
        
        volumeSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(50, 0, kWIDTH - 80, 31)];
        volumeSlider.isAETemplate = TRUE;
        volumeSlider.backgroundColor = [UIColor clearColor];
        [volumeSlider setMaximumValue:1];
        [volumeSlider setMinimumValue:0];
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [volumeSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        volumeSlider.layer.cornerRadius = 2.0;
        volumeSlider.layer.masksToBounds = YES;
        [volumeSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [volumeSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
        [volumeSlider setValue:0];
        volumeSlider.alpha = 1.0;
        
        [volumeSlider setValue:_trimFile.videoVolume];
        volumeCount = _trimFile.videoVolume;
        [volumeSlider addTarget:self action:@selector(scrubVolume:) forControlEvents:UIControlEventValueChanged];
        [volumeSlider addTarget:self action:@selector(endScrubVolume:) forControlEvents:UIControlEventTouchUpInside];
        [volumeSlider addTarget:self action:@selector(endScrubVolume:) forControlEvents:UIControlEventTouchCancel];
        [volumeView addSubview:volumeSlider];
        
        UILabel *tipLbl2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0 + 31 + 5, kWIDTH, 20)];
        tipLbl2.text = RDLocalizedString(@"提示:滑动滑杆确定您需要合并到背景音乐的音量大小", nil);
        tipLbl2.textColor = [UIColor whiteColor];
        tipLbl2.textAlignment = NSTextAlignmentCenter;
        tipLbl2.font = [UIFont systemFontOfSize:10.0];
        tipLbl2.numberOfLines = 0;
        [volumeView addSubview:tipLbl2];
        
        float fWidthX = (AEScrollView.frame.size.height- AEVolumeView.frame.size.height)/2.0;
        
        AEScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, _playerView.frame.origin.y + _playerView.frame.size.height, kWIDTH, kHEIGHT - (_playerView.frame.origin.y + _playerView.frame.size.height) - kToolbarHeight)];
        _videoSlider.frame = CGRectMake(_videoSlider.frame.origin.x, 25+fWidthX, _videoSlider.frame.size.width, _videoSlider.frame.size.height);
        [self.view addSubview:AEScrollView];
        
        volumeView.frame = CGRectMake(volumeView.frame.origin.x, _videoSlider.frame.size.height+_videoSlider.frame.origin.y + 20, volumeView.frame.size.width, volumeView.frame.size.height);
        _showTimeView.frame = CGRectMake(0, _videoSlider.frame.origin.y - 20, kWIDTH, 20);
        
        
        AEVolumeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, volumeView.frame.size.height+volumeView.frame.origin.y+5)];
        [AEVolumeView addSubview:self.trimSlider];
        [AEVolumeView addSubview:_videoSlider];
        [AEVolumeView addSubview:_showTimeView];
        [AEVolumeView addSubview:volumeView];
        
        if( AEVolumeView.frame.size.height <  AEScrollView.frame.size.height )
        {
            float fWidthX = (AEScrollView.frame.size.height- AEVolumeView.frame.size.height)/2.0;
            
            AEVolumeView.frame = CGRectMake(0, 0, kWIDTH, AEScrollView.frame.size.height);
            
            _videoSlider.frame = CGRectMake(_videoSlider.frame.origin.x, _showTimeView.frame.size.height+_showTimeView.frame.origin.y, _videoSlider.frame.size.width, _videoSlider.frame.size.height);
            _showTimeView.frame = CGRectMake(0, _videoSlider.frame.origin.y - 20, kWIDTH, 20);
            
            volumeView.frame = CGRectMake(volumeView.frame.origin.x, volumeView.frame.origin.y+fWidthX, volumeView.frame.size.width, volumeView.frame.size.height);
        }
        [AEScrollView addSubview:AEVolumeView];
        AEScrollView.contentSize = CGSizeMake(0, AEVolumeView.frame.size.height);
        
        [self filterBtnAction:filterBtn];
        AEVolumeView.hidden = YES;
    }else {
        
        UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
        if (_customTitle.length > 0) {
            titleLbl.text = _customTitle;
        }else {
            titleLbl.text = RDLocalizedString(@"截取", nil);
        }
        
        titleLbl.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        titleLbl.font = [UIFont boldSystemFontOfSize:17.0];
        titleLbl.textAlignment = NSTextAlignmentCenter;
        [toolBarView addSubview:titleLbl];
    }
    [RDHelpClass animateView:toolBarView atUP:NO];
}

/**显示截取的时间信息
 */
- (UIView *)showTimeView{
    if(!_showTimeView){
        _showTimeView = [UIView new];
        _showTimeView.frame = CGRectMake(0, _videoSlider.frame.origin.y - 20, kWIDTH, 20);
        [_showTimeView addSubview:self.startTrimLabel];
        [_showTimeView addSubview:self.trimRangeLabel];
        [_showTimeView addSubview:self.endTrimLabel];
    }
    return _showTimeView;
}
/**截取开始时间
 */
- (UILabel *)startTrimLabel{
    if(!_startTrimLabel){
        _startTrimLabel = [[UILabel alloc] init];
        _startTrimLabel.frame = CGRectMake(0, 0, 80, 20);
        _startTrimLabel.font = [UIFont systemFontOfSize:10];
        _startTrimLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.0];
        _startTrimLabel.textColor = UIColorFromRGB(0xffffff);
        _startTrimLabel.textAlignment = NSTextAlignmentCenter;
        _startTrimLabel.text = @"00:00.0";
        _startTrimLabel.layer.cornerRadius = 4;
        _startTrimLabel.layer.masksToBounds = YES;
        _startTrimLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.8];
        _startTrimLabel.shadowOffset = CGSizeMake(-1, 1);
    }
    return _startTrimLabel;
}

/**截取时长
 */
- (UILabel *)trimRangeLabel{
    if(!_trimRangeLabel){
        _trimRangeLabel = [[UILabel alloc] init];
        _trimRangeLabel.frame = CGRectMake((kWIDTH - 80)/2.0, 0, 80, 20);
        _trimRangeLabel.font = [UIFont systemFontOfSize:10];
        _trimRangeLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.0];
        _trimRangeLabel.textColor = UIColorFromRGB(0xffffff);
        _trimRangeLabel.textAlignment = NSTextAlignmentCenter;
        _trimRangeLabel.text = @"00:00.0";
        _trimRangeLabel.layer.cornerRadius = 4;
        _trimRangeLabel.layer.masksToBounds = YES;
        _trimRangeLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.8];
        _trimRangeLabel.shadowOffset = CGSizeMake(-1, 1);
    }
    return _trimRangeLabel;
}

/**截取结束时间
 */
- (UILabel *)endTrimLabel{
    if(!_endTrimLabel){
        _endTrimLabel = [[UILabel alloc] init];
        _endTrimLabel.frame = CGRectMake(kWIDTH - 80, 0, 80, 20);
        _endTrimLabel.font = [UIFont systemFontOfSize:10];
        _endTrimLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.0];
        _endTrimLabel.textColor = UIColorFromRGB(0xffffff);
        _endTrimLabel.textAlignment = NSTextAlignmentCenter;
        _endTrimLabel.text = @"00:00.0";
        _endTrimLabel.layer.cornerRadius = 4;
        _endTrimLabel.layer.masksToBounds = YES;
        _endTrimLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.8];
        _endTrimLabel.shadowOffset = CGSizeMake(-1, 1);
    }
    return _endTrimLabel;
}

- (UIView *)switchView {
    if (!_switchView) {
        _switchView = [[UIView alloc] init];
        _switchView.layer.cornerRadius = 27/2.0;
        _switchView.layer.masksToBounds = YES;
        _switchView.layer.borderColor = [UIColor grayColor].CGColor;
        _switchView.layer.borderWidth = 1;
        
        Float64 duration = CMTimeGetSeconds(clipTimeRange.duration);
        Float64 duration1 = CMTimeGetSeconds(clipSliderTimeRange.duration);
        Float64 nowTime = _videoCoreSDK.duration;
        float scale = nowTime/duration;
        
        if (_trimType == TRIMMODESPECIFYTIME_TWO) {
            _switchView.frame=CGRectMake((kWIDTH - 98)/2.0, self.videoSlider.frame.origin.y - 20 - 37, 98, 27);

            UILabel* leftLabel = [[UILabel alloc] init];
            UILabel* rightLabel = [[UILabel alloc] init];
            
            leftLabel.frame = CGRectMake(0, 0, 49, 27);
            leftLabel.layer.cornerRadius = 27/2.0;
            leftLabel.layer.masksToBounds = YES;
            leftLabel.text = [NSString stringWithFormat:RDLocalizedString(@"%.f秒", nil),_trimMinDuration_TwoSpecifyTime];
            leftLabel.tag = 100;
            leftLabel.textColor = [UIColor whiteColor];
            leftLabel.textAlignment = NSTextAlignmentCenter;
            leftLabel.font = [UIFont systemFontOfSize:13];
            
            rightLabel.frame = CGRectMake(49, 0, 49, 27);
            rightLabel.backgroundColor = [UIColor whiteColor];
            rightLabel.layer.cornerRadius = 27/2.0;
            rightLabel.layer.masksToBounds = YES;
            rightLabel.text =[NSString stringWithFormat:RDLocalizedString(@"%.f秒", nil),_trimMaxDuration_TwoSpecifyTime];
            rightLabel.tag = 200;
            rightLabel.textColor = [UIColor blackColor];
            rightLabel.textAlignment = NSTextAlignmentCenter;
            rightLabel.font = [UIFont systemFontOfSize:13];
            _selectMax = YES;
            _selectMin = NO;
            [_switchView addSubview:leftLabel];
            [_switchView addSubview:rightLabel];
            
            UITapGestureRecognizer* switchTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchAction)];
            [_switchView addGestureRecognizer:switchTap];
            
            _videoSlider.selectedDurationValue = _trimMaxDuration_TwoSpecifyTime;
            _videoSlider.moveValue = _trimMaxDuration_TwoSpecifyTime/nowTime>1.0?1.0:_trimMaxDuration_TwoSpecifyTime/nowTime;
            
            if (fabs(duration1*scale-_trimMinDuration_TwoSpecifyTime) < 0.1 ) {
                
                rightLabel.backgroundColor = [UIColor clearColor];
                rightLabel.textColor = [UIColor whiteColor];
                leftLabel.backgroundColor = [UIColor whiteColor];
                leftLabel.textColor = [UIColor blackColor];
                _videoSlider.moveValue = _trimMinDuration_TwoSpecifyTime/nowTime>1.0?1.0:_trimMinDuration_TwoSpecifyTime/nowTime;
                
            }
            if(fabs(duration1*scale-_trimMaxDuration_TwoSpecifyTime)<0.1){
                rightLabel.backgroundColor = [UIColor whiteColor];
                rightLabel.textColor = [UIColor blackColor];
                leftLabel.backgroundColor = [UIColor clearColor];
                leftLabel.textColor = [UIColor whiteColor];
                
                _videoSlider.moveValue = _trimMaxDuration_TwoSpecifyTime/nowTime>1.0?1.0:_trimMaxDuration_TwoSpecifyTime/nowTime;
                
            }
        }else {
            _switchView.frame=CGRectMake((kWIDTH - 49)/2.0, self.videoSlider.frame.origin.y - 20 - 37, 49, 27);

            UILabel *durationLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 49, 27)];
            if (_trimDuration_OneSpecifyTime < 1.0) {
                durationLbl.text =[NSString stringWithFormat:RDLocalizedString(@"%.2f秒", nil),_trimDuration_OneSpecifyTime];
            }else {
                durationLbl.text =[NSString stringWithFormat:RDLocalizedString(@"%.f秒", nil),_trimDuration_OneSpecifyTime];
            }
            durationLbl.textColor = [UIColor blackColor];
            durationLbl.backgroundColor = [UIColor whiteColor];
            durationLbl.layer.cornerRadius = 27/2.0;
            durationLbl.layer.masksToBounds = YES;
            durationLbl.textAlignment = NSTextAlignmentCenter;
            durationLbl.font = [UIFont systemFontOfSize:13];
            [_switchView addSubview:durationLbl];
            
            _videoSlider.selectedDurationValue = _trimDuration_OneSpecifyTime;
            _videoSlider.moveValue = _trimDuration_OneSpecifyTime/nowTime>1.0?1.0:_trimDuration_OneSpecifyTime/nowTime;
        }
        _videoSlider.upperValue = _videoSlider.lowerValue + _videoSlider.moveValue;
        
        if (!isSquareVideo
            && (_trimExportVideoType == TRIMEXPORTVIDEOTYPE_MIXED_ORIGINAL
                || _trimExportVideoType == TRIMEXPORTVIDEOTYPE_MIXED_SQUARE) ) {
                squareChangeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
                squareChangeBtn.backgroundColor = [UIColor clearColor];
                squareChangeBtn.frame = CGRectMake(kWIDTH - 44 - 35, _switchView.frame.origin.y - (44 - 27)/2.0, 44, 44);
                [squareChangeBtn setBackgroundImage:[RDHelpClass imageWithContentOfFile:@"视频截取_1比1未选中_"] forState:UIControlStateNormal];
                [squareChangeBtn setBackgroundImage:[RDHelpClass imageWithContentOfFile:@"视频截取_1比1选中_"] forState:UIControlStateSelected];
                [squareChangeBtn addTarget:self action:@selector(squareChangeBtnAction:) forControlEvents:UIControlEventTouchUpInside];
                if (isSelectedSquare) {
                    squareChangeBtn.selected = YES;
                }
                [self.view addSubview:squareChangeBtn];
            }
    }
    return _switchView;
}

- (AVAssetImageGenerator *)imageGenerator{
    AVAssetImageGenerator *imageGenerator;
    if (thumbVideoCore) {
        imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:thumbVideoCore.composition];
        imageGenerator.videoComposition = thumbVideoCore.videoComposition;
    }else {
        AVURLAsset *asset = [AVURLAsset assetWithURL:_trimFile.contentURL];
        imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    }
    imageGenerator.appliesPreferredTrackTransform = YES;
    
    CGSize siz = CGSizeMake(100*[UIScreen mainScreen].scale, 60*[UIScreen mainScreen].scale);
    imageGenerator.maximumSize = siz;
    
    return imageGenerator;
}

/*
 初始化滑竿控件
 */
- (void)initVideoRangeSlider{
    if (_videoSlider) {
        [_videoSlider.subviews respondsToSelector:@selector(removeFromSuperview)];
        [_videoSlider.imageGenerator cancelAllCGImageGeneration];
        [_videoSlider removeFromSuperview];
        _videoSlider = nil;
    }
    float y;
    if (playerScrollView) {
        y = playerScrollView.frame.origin.y + playerScrollView.bounds.size.height;
    }else {
        y = _playerView.frame.origin.y + _playerView.bounds.size.height;
    }
    if (_trimType != TRIMMODEAUTOTIME && !_isAdjustVolumeEnable) {
        y += 20 + 37;
    }
    CGRect videoSliderRect;
    if (((RDNavigationViewController *)self.navigationController).isSingleFunc) {
        videoSliderRect = CGRectMake(26, y + (kHEIGHT - y - (iPhone_X ? 34 : 0) - 50)/2.0, kWIDTH - 52, 50);
    }else {
        videoSliderRect = CGRectMake(26, y + (kHEIGHT - y - kToolbarHeight - 50)/2.0, kWIDTH - 52, 50);
    }
    _videoSlider = [[NMCutRangeSlider_RD alloc] initWithFrame:videoSliderRect];
    _videoSlider.speed = _trimFile.speed;
    _videoSlider.backgroundColor = [UIColor clearColor];
    _videoSlider.delegate = self;
    
    _videoSlider.handProgressTrackMove = ^(float progressTime) {
        
        CMTime currentTime = CMTimeMakeWithSeconds(progressTime,TIMESCALE);
        
        [_videoCoreSDK seekToTime:currentTime];
        
    };
    
    clipTimeRange = kCMTimeRangeZero;
    clipSliderTimeRange = kCMTimeRangeZero;
    if(_trimFile.isReverse){
        _selectVideoDuration = CMTimeGetSeconds(_trimFile.reverseVideoTimeRange.duration);
        if(_selectVideoDuration == 0 || isnan(_selectVideoDuration)){
            _selectVideoDuration = CMTimeGetSeconds([AVURLAsset assetWithURL:_trimFile.reverseVideoURL].duration);
        }
        clipTimeRange = CMTimeRangeMake(_trimFile.reverseVideoTimeRange.start, CMTimeMakeWithSeconds(_selectVideoDuration, TIMESCALE));
        clipSliderTimeRange = _trimFile.reverseVideoTrimTimeRange;
    }else{
        if (_trimFile.isGif) {
            _selectVideoDuration = CMTimeGetSeconds(_trimFile.imageDurationTime);
            if(_selectVideoDuration == 0 || isnan(_selectVideoDuration)){
                _selectVideoDuration = CMTimeGetSeconds([AVURLAsset assetWithURL:_trimFile.contentURL].duration);
            }
            clipTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(_selectVideoDuration, TIMESCALE));
            if (CMTimeCompare(_trimFile.imageTimeRange.duration, kCMTimeZero) == 1) {
                clipSliderTimeRange = _trimFile.imageTimeRange;
            }else {
                clipSliderTimeRange = clipTimeRange;
            }
        }else {
            _selectVideoDuration = CMTimeGetSeconds(_trimFile.videoTimeRange.duration);
            if(_selectVideoDuration == 0 || isnan(_selectVideoDuration)){
                _selectVideoDuration = CMTimeGetSeconds([AVURLAsset assetWithURL:_trimFile.contentURL].duration);
            }
            clipTimeRange = CMTimeRangeMake(_trimFile.videoTimeRange.start, CMTimeMakeWithSeconds(_selectVideoDuration, TIMESCALE));
            clipSliderTimeRange = _trimFile.videoTrimTimeRange;
        }
    }
    _videoSlider.durationValue = _selectVideoDuration/(float)_trimFile.speed;
    
    UIImage* image = nil;
    image = [RDHelpClass imageWithContentOfFile:@"jianji/jiequ/剪辑-截取_把手默认_"];
    _videoSlider.lowerHandleImageNormal = image;
    
    _videoSlider.lowerHandleImage = image;
    image = [RDHelpClass imageWithContentOfFile:@"jianji/jiequ/剪辑-截取_把手选中_"];
    _videoSlider.lowerHandleImageHighlighted = image;
    
    image = [RDHelpClass imageWithContentOfFile:@"jianji/jiequ/剪辑-截取_把手默认_"];
    _videoSlider.upperHandleImageNormal = image;
    _videoSlider.upperHandleImage = image;
    image = [RDHelpClass imageWithContentOfFile:@"jianji/jiequ/剪辑-截取_把手选中_"];
    _videoSlider.upperHandleImageHighlighted = image;
    
    if( !isCoreStop )
    {
        _videoSlider.imageGenerator = [self imageGenerator];
    }
    else
    {
        _videoSlider.filtImagePatch = _trimFile.filtImagePatch;
    }
    _videoSlider.mode = _trimType == TRIMMODEAUTOTIME;
   
    Float64 start = CMTimeGetSeconds(clipTimeRange.start);
    Float64 duration = CMTimeGetSeconds(clipTimeRange.duration);
    Float64 start1 = CMTimeGetSeconds(clipSliderTimeRange.start);
    Float64 duration1 = CMTimeGetSeconds(clipSliderTimeRange.duration);

    _videoSlider.lowerValue=((start1 - start)<=0 ? 0 : (start1 - start))/duration;
    
    if(duration1 != 0)
        _videoSlider.upperValue=(duration1 + ((start1 - start)<=0 ? 1 : (start1 - start)))/duration;
    else{
        _videoSlider.upperValue=1.0;
    }
    [self.view addSubview:_videoSlider];

    //修复 “截取分割后截取页视频轴的时刻点显示错误” bug
    {
        self.startTrimLabel.text = [RDHelpClass timeToStringFormat:(start1 - start)/_trimFile.speed];
        self.trimRangeLabel.text = [RDHelpClass timeToStringFormat:duration1/_trimFile.speed];
        self.endTrimLabel.text = [RDHelpClass timeToStringFormat:((start1 - start) + duration1)/_trimFile.speed];
        //self.startTrimLabel.text = [RDHelpClass timeToStringFormat:start1/_trimFile.speed];
        //self.trimRangeLabel.text = [RDHelpClass timeToStringFormat:duration1/_trimFile.speed];
        //self.endTrimLabel.text = [RDHelpClass timeToStringFormat:(start1 + duration1)/_trimFile.speed];
    }

    CMTime startTime = CMTimeMakeWithSeconds(_videoCoreSDK.duration*_videoSlider.lowerValue, TIMESCALE);
    [_videoCoreSDK seekToTime:startTime toleranceTime:kCMTimeZero completionHandler:nil];
    
    
}

- (void)initPlayerScrollView {
    
    playerScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, kPlayerViewOriginX, kWIDTH, kWIDTH)];
    playerScrollView.bounces = NO;
    playerScrollView.delegate = self;
    if (isSquareVideo || !isSelectedSquare) {
        playerScrollView.contentSize = CGSizeMake(kWIDTH, kWIDTH);
    }else {
        CGSize size = [self getVideoSizeForTrack];
        if (isPortrait) {
            playerScrollView.contentSize = CGSizeMake(kWIDTH, kWIDTH * size.height/size.width);
            playerScrollView.contentOffset = CGPointMake(0, (playerScrollView.contentSize.height - kWIDTH)/2);
        }else {
            playerScrollView.contentSize = CGSizeMake(playerScrollView.frame.size.height * size.width/size.height, playerScrollView.frame.size.height);
            playerScrollView.contentOffset = CGPointMake((playerScrollView.contentSize.width - kWIDTH)/2, 0);
        }
        
        
//        if (isPortrait) {
//            playerScrollView.contentSize = CGSizeMake(kWIDTH, kWIDTH*2 - 80);
//            playerScrollView.contentOffset = CGPointMake(0, (playerScrollView.contentSize.height - kWIDTH)/2);
//        }else {
//            playerScrollView.contentSize = CGSizeMake(kWIDTH*2 - 80, kWIDTH);
//            playerScrollView.contentOffset = CGPointMake((playerScrollView.contentSize.width - kWIDTH)/2, 0);
//        }
    }
    [self.view addSubview:playerScrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (playerScrollHintIV && !playerScrollHintIV.hidden) {
        playerScrollHintIV.hidden = YES;
    }
}

- (void)initPlayerScrollHintIV {
    playerScrollHintIV = [[UIImageView alloc] initWithFrame:CGRectMake((kWIDTH - 160)/2, (playerScrollView.frame.size.height - 160)/2, 160, 160)];
    playerScrollHintIV.backgroundColor = [UIColor clearColor];
    if (isPortrait) {
        playerScrollHintIV.image = [RDHelpClass imageWithContentOfFile:@"视频截取_竖划_"];
    }else {
        playerScrollHintIV.image = [RDHelpClass imageWithContentOfFile:@"视频截取_横划_"];
    }
    if (isSelectedSquare) {
        if (isPortrait) {
            if ([[NSUserDefaults standardUserDefaults] objectForKey:@"showedPortraitHint"]) {
                playerScrollHintIV.hidden = YES;
            }else {
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"showedPortraitHint"];
            }
        }else {
            if ([[NSUserDefaults standardUserDefaults] objectForKey:@"showedLandscapeHint"]) {
                playerScrollHintIV.hidden = YES;
            }else {
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"showedLandscapeHint"];
            }
        }
    }else {
        playerScrollHintIV.hidden = YES;
    }
    [self.view addSubview:playerScrollHintIV];
}

- (void)hiddenPlayerScrollHintIV {
    playerScrollHintIV.hidden = YES;
}

- (void)initCropView{
    if(_cliper.superview){
        _cliper.delegate = nil;
        [_cliper removeFromSuperview];
        _cliper = nil;
    }
    _cliper = [[RDUICliper alloc]initWithView:_playerView freedom:YES];
    _cliper.backgroundColor = [UIColor clearColor];
    [_cliper setCropText:@" "];
    [_cliper setFrame:_playerView.frame];
    [_cliper setFrameRect:_playerView.frame];
    _cliper.clipsToBounds = YES;
    _cliper.delegate = self;
//    [_cliper.playBtn removeFromSuperview];
//    _cliper.playBtn = nil;
    [self updateSyncLayerPositionAndTransform];
}

- (CGSize )getVideoSizeForTrack{
    CGSize size = CGSizeZero;
    if (_trimFile.fileType == kFILEVIDEO) {
        AVURLAsset *asset = [AVURLAsset assetWithURL:_trimFile.contentURL];
        
        NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        if([tracks count] > 0) {
            AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
            size = CGSizeApplyAffineTransform(videoTrack.naturalSize, videoTrack.preferredTransform);
            if (CGSizeEqualToSize(size, CGSizeZero) || size.width == 0.0 || size.height == 0.0) {
                NSArray * formatDescriptions = [videoTrack formatDescriptions];
                CMFormatDescriptionRef formatDescription = NULL;
                if ([formatDescriptions count] > 0) {
                    formatDescription = (__bridge CMFormatDescriptionRef)[formatDescriptions objectAtIndex:0];
                    if (formatDescription) {
                        size = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, false, false);
                    }
                }
            }
        }
    }else {
        size = [RDHelpClass getFullScreenImageWithUrl:_trimFile.contentURL].size;
    }
    size = CGSizeMake(fabs(size.width), fabs(size.height));
    return size;
}

- (void)updateSyncLayerPositionAndTransform{
    CGSize size = [self getVideoSizeForTrack];
    CGSize presentationSize;
    _trimFile.crop = [self getVideoCrop];
    if(size.height == size.width){
        
        presentationSize        = size;
        
    }else if(isPortrait){
        presentationSize = size;
        
        if(size.height < size.width){
            presentationSize  = CGSizeMake(size.height, size.width);
        }
        if(_trimFile.rotate == -90 || _trimFile.rotate == -270){
            presentationSize  = CGSizeMake(size.width, size.height);
        }
    }else{
        presentationSize  = [self getVideoSizeForTrack];
        if(_trimFile.rotate == -90 || _trimFile.rotate == -270){
            CGSize size = [self getVideoSizeForTrack];
            presentationSize  = CGSizeMake(size.height, size.width);
        }
    }
    CGRect videoRect         = AVMakeRectWithAspectRatioInsideRect(presentationSize, _playerView.bounds);
    
    if (_trimFile.fileCropModeType == kCropTypeFixed && CGRectEqualToRect(_trimFile.cropRect, CGRectZero)) {
        float x=0,y=0,w=0,h=0;
//            size = videoRect.size.height>videoRect.size.width? videoRect.size.width :videoRect.size.height;
        w=videoRect.size.width*_trimFile.crop.size.width;
        h=videoRect.size.height*_trimFile.crop.size.height;
        x=(videoRect.size.width-w)/2;
        y=(videoRect.size.height-h)/2;
        _trimFile.cropRect = CGRectMake(x, y, w, h);
    }
    if (CGSizeEqualToSize(_maxCropSize, CGSizeZero)) {
        [_cliper setVideoSize:presentationSize];
    }else {
        [_cliper setVideoSize:_maxCropSize];
    }
    [_cliper setFrameRect:videoRect];
    [_cliper setCropType:_trimFile.fileCropModeType];
    [_cliper setClipRect:_trimFile.cropRect];
    
    _cliper.fileType = 1;
    [_cliper setNeedsDisplay];
}

- (CGRect)getVideoCrop {
    AVURLAsset *asset;
    if(_trimFile.isReverse){
        asset = [AVURLAsset assetWithURL:_trimFile.reverseVideoURL];
    }else {
        asset = [AVURLAsset assetWithURL:_trimFile.contentURL];
    }
//    BOOL isPortrait = [RDHelpClass isVideoPortrait:asset];
    CGSize videoSize = [RDHelpClass getVideoSizeForTrack:asset];
    
    CGRect cropRect = CGRectZero;
    CGRect crop = CGRectZero;
    if (_trimFile.rotate == -90 || _trimFile.rotate == -270) {
        isPortrait = !isPortrait;
    }
    if (isPortrait) {
        videoSize = CGSizeMake(MIN(videoSize.width, videoSize.height), MAX(videoSize.width, videoSize.height));
        
        float ratiow = _videoInViewSize.width/_videoInViewSize.height;
        float ratioh = _videoInViewSize.height/_videoInViewSize.width;
        if (ratiow <= 1.0) {
            cropRect = CGRectMake((videoSize.width - videoSize.height*ratiow)/2.0, 0, videoSize.height*ratiow, videoSize.height);
            
            if (cropRect.size.width > videoSize.width) {
                cropRect = CGRectMake(0, (videoSize.height - videoSize.width*ratioh)/2.0, videoSize.width, videoSize.width*ratioh);
                crop = CGRectMake(0, cropRect.origin.y/videoSize.height, 1.0, cropRect.size.height/videoSize.height);
            }else {
                crop = CGRectMake(cropRect.origin.x/videoSize.width, 0, cropRect.size.width/videoSize.width, 1.0);
            }
        }else {
            cropRect = CGRectMake(0, (videoSize.height - videoSize.width*ratioh)/2.0, videoSize.width, videoSize.width*ratioh);
            crop = CGRectMake(0, cropRect.origin.y/videoSize.height, 1.0, cropRect.size.height/videoSize.height);
        }
    }else {
        videoSize = CGSizeMake(MAX(videoSize.width, videoSize.height), MIN(videoSize.width, videoSize.height));
        
        float ratiow = _videoInViewSize.width/_videoInViewSize.height;
        float ratioh = _videoInViewSize.height/_videoInViewSize.width;
        cropRect = CGRectMake((videoSize.width - videoSize.height*ratiow)/2.0, (videoSize.height - videoSize.height)/2.0, videoSize.height*ratiow, videoSize.height);
        
        if (cropRect.size.width > videoSize.width) {
            cropRect = CGRectMake(0, (videoSize.height - videoSize.width*ratioh)/2.0, videoSize.width, videoSize.width*ratioh);
            crop = CGRectMake(0, cropRect.origin.y/videoSize.height, 1.0, cropRect.size.height/videoSize.height);
        }else {
            crop = CGRectMake(cropRect.origin.x/videoSize.width, 0, cropRect.size.width/videoSize.width, 1.0);
        }
    }
    return crop;
}

#pragma mark-UICliperDelegate
- (void)cropViewDidChangeClipValue:(CGRect)rect clipRect:(CGRect)clipRect{
    _trimFile.crop = rect;
    _trimFile.cropRect = clipRect;
}
- (void)touchesEndSuperView{
    [self playVideo:NO];
}

- (void)rotationBtnAction:(UIButton *)sender {
    [self playVideo:NO];
    
    if(_trimFile.rotate == 0){
        _trimFile.rotate = -90;
    }else if(_trimFile.rotate == -90){
        _trimFile.rotate = -180;
    }else if(_trimFile.rotate == -180){
        _trimFile.rotate = -270;
    }else if(_trimFile.rotate == -270){
        _trimFile.rotate = 0;
    }
    [self initPlayer];
}

- (BOOL)touchUpinslidePlayeBtn{
    [self playVideo:![_videoCoreSDK isPlaying]];
    return [_videoCoreSDK isPlaying];
}

/**返回
 */
- (void)tapBackBtn{
    
    if( !isCoreStop )
        [_videoCoreSDK stop];
    [thumbVideoCore stop];
    if(_cancelBlock){
        _cancelBlock();
    }
    
    UIViewController *upView = [self.navigationController popViewControllerAnimated:NO];
    if(!upView){
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

/**保存
 */
- (void)tapsaveBtn{
    [self playVideo:NO];
    
    if (_isShowClipView) {
        _trimFile.crop = [_cliper getclipRect];
        _trimFile.cropRect = CGRectZero;//再次裁剪时，裁剪界面与该界面的播放器大小不一致，所以到裁剪界面与重新设置cropRect
    }
    
    //emmet 20171026 分割后再截取，截取时间错误
    float duration = _videoSlider.durationValue;
    CMTime start = CMTimeMakeWithSeconds((CMTimeGetSeconds(clipTimeRange.start)) + duration*_videoSlider.lowerValue*(float)_trimFile.speed, TIMESCALE);
    CMTime endtime = CMTimeMakeWithSeconds((CMTimeGetSeconds(clipTimeRange.start)) + duration*_videoSlider.upperValue*(float)_trimFile.speed,TIMESCALE);
    
    CMTimeRange range = CMTimeRangeMake(start, CMTimeSubtract(endtime, start));
    if(_trimType != TRIMMODEAUTOTIME){
        if (_trimType == TRIMMODESPECIFYTIME_ONE) {
            if(CMTimeGetSeconds(_trimFile.videoTrimTimeRange.start)/(float)_trimFile.speed + _trimDuration_OneSpecifyTime >= duration){
                if(_videoSlider.selectedDurationValue<duration){
                    range.duration = CMTimeMakeWithSeconds(_videoSlider.selectedDurationValue/(float)_trimFile.speed, TIMESCALE);
                    range.start = CMTimeMakeWithSeconds((duration - _videoSlider.selectedDurationValue)/(float)_trimFile.speed, TIMESCALE);
                }
            }
        }else {
            if(_selectMax){
                if(CMTimeGetSeconds(_trimFile.videoTrimTimeRange.start)/(float)_trimFile.speed + _trimMaxDuration_TwoSpecifyTime >= duration){
                    if(_videoSlider.selectedDurationValue<duration){
                        range.duration = CMTimeMakeWithSeconds(_videoSlider.selectedDurationValue/(float)_trimFile.speed, TIMESCALE);
                        range.start = CMTimeMakeWithSeconds((duration - _videoSlider.selectedDurationValue)/(float)_trimFile.speed, TIMESCALE);
                    }
                }
            }else{
                if(CMTimeGetSeconds(_trimFile.videoTrimTimeRange.start)/(float)_trimFile.speed + _trimMinDuration_TwoSpecifyTime >= duration){
                    if(_videoSlider.selectedDurationValue<duration){
                        range.duration = CMTimeMakeWithSeconds(_videoSlider.selectedDurationValue/(float)_trimFile.speed, TIMESCALE);
                        range.start = CMTimeMakeWithSeconds((duration - _videoSlider.selectedDurationValue)/(float)_trimFile.speed, TIMESCALE);
                    }
                }
            }
        }
        NSLog(@"start :%f, duration:%f",CMTimeGetSeconds(range.start),CMTimeGetSeconds(range.duration));
        _trimFile.videoTrimTimeRange = range;
        if (_trimExportVideoType != TRIMEXPORTVIDEOTYPE_ORIGINAL && isSelectedSquare && !isSquareVideo) {
            [self setVideoCropSize];
        }
    }
    if(((RDNavigationViewController *)self.navigationController).isSingleFunc && ((RDNavigationViewController *)self.navigationController).callbackBlock){
        [self exportVideo:_trimFile.contentURL timeRange:range];
        return;
    }else if (_selectAndTrimFinishBlock) {
        if(_cutType == RDCutVideoReturnTypePath){
            [self exportVideo:_trimFile.contentURL timeRange:range];
        }else{
            _trimFile.videoTimeRange = range;
            _selectAndTrimFinishBlock(_trimFile);
            [self.presentingViewController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
        }
    }
    else if (_TrimAndRotateVideoFinishBlock) {
        [self dismissViewControllerAnimated:NO completion:nil];
        _TrimAndRotateVideoFinishBlock(_trimFile.rotate, range);
        return;
    }
    else if (_TrimAndCropVideoFinishBlock) {
        _TrimAndCropVideoFinishBlock(_trimFile.contentURL, _trimFile.crop, _trimFile.cropRect, range, volumeSlider.value);
    }
    else if (_TrimAndCropVideoFinishFiltersBlock) {
        
        range.duration = CMTimeMakeWithSeconds(_trimDuration_OneSpecifyTime/(float)_trimFile.speed, TIMESCALE);
        range.start = CMTimeMakeWithSeconds( _trimSlider.progressValue/(float)_trimFile.speed, TIMESCALE);
        
        _TrimAndCropVideoFinishFiltersBlock(_trimFile.contentURL, _trimFile.crop, _trimFile.cropRect, range, volumeSlider.value,_trimFile.filterIndex);
    } else if(_TrimVideoFinishBlock){
        _TrimVideoFinishBlock(range);

    }else{
        _trimFile.videoTrimTimeRange = range;
        _cutType = RDCutVideoReturnTypePath;
        if(_rd_CutVideoReturnType){
            _rd_CutVideoReturnType(&_cutType);
        }
        if(_cutType == RDCutVideoReturnTypePath){
            if((_callbackBlock  || _trimCallbackBlock) && [AVURLAsset assetWithURL:(_trimFile.isReverse ? _trimFile.reverseVideoURL : _trimFile.contentURL)]){
                [self exportVideo:_trimFile.isReverse ? _trimFile.reverseVideoURL : _trimFile.contentURL timeRange:_trimFile.videoTrimTimeRange];
                return;
            }
        }
        if(_cutType == RDCutVideoReturnTypeTime){
            
            if(_callbackBlock  || _trimCallbackBlock){
                if([[self.navigationController childViewControllers] count]>1){
                    if ( !isCoreStop && _videoCoreSDK) {
                        [_videoCoreSDK stop];
                        _videoCoreSDK.delegate = nil;
                        _videoCoreSDK = nil;
                    }
                    else{
                        [_videoCoreSDK seekToTime:kCMTimeZero];
                    }
                    [_videoSlider.subviews respondsToSelector:@selector(removeFromSuperview)];
                    [_videoSlider.imageGenerator cancelAllCGImageGeneration];
                    [_videoSlider removeFromSuperview];
                    _videoSlider = nil;
                    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                    [(RDNavigationViewController *)self.navigationController rdPopViewControllerAnimated:NO];
                    
                    if(_trimVideoAsset && _trimCallbackBlock){
                        
                        _trimCallbackBlock(_cutType,_trimVideoAsset,(_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).start,CMTimeMakeWithSeconds(CMTimeGetSeconds((_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).duration) + CMTimeGetSeconds((_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).start), TIMESCALE),_trimFile.crop);
                        
                    }else if (_callbackBlock) {
                        _callbackBlock(_cutType,nil,(_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).start,CMTimeMakeWithSeconds(CMTimeGetSeconds((_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).duration) + CMTimeGetSeconds((_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).start), TIMESCALE),_trimFile.crop);
                    }

                    
                    UIViewController *upView = [self.navigationController popViewControllerAnimated:NO];
                    if(!upView){
                        [self dismissViewControllerAnimated:NO completion:nil];
                    }
                    
                }else{
                    if(_exportProgress){
                        [_exportProgress removeFromSuperview];
                        _exportProgress = nil;
                    }
                    if ( !isCoreStop && _videoCoreSDK) {
                        [_videoCoreSDK stop];
                        _videoCoreSDK.delegate = nil;
                        _videoCoreSDK = nil;
                    }
                    else{
                        [_videoCoreSDK seekToTime:kCMTimeZero];
                    }
                    [_videoSlider.subviews respondsToSelector:@selector(removeFromSuperview)];
                    [_videoSlider.imageGenerator cancelAllCGImageGeneration];
                    [_videoSlider removeFromSuperview];
                    _videoSlider = nil;
                    
                    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                    WeakSelf(self);
                    UIViewController *upView = [self.navigationController popViewControllerAnimated:NO];
                    if(!upView){
                        [self dismissViewControllerAnimated:NO completion:^{
                            StrongSelf(self);
                            if(_trimVideoAsset){
                                if(_trimCallbackBlock){
                                    _trimCallbackBlock(_cutType,_trimVideoAsset,(_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).start,CMTimeMakeWithSeconds(CMTimeGetSeconds((_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).duration) + CMTimeGetSeconds((_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).start), TIMESCALE),_trimFile.crop);
                                }
                                if(_callbackBlock){
                                    
                                    _callbackBlock(_cutType,nil,(_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).start,CMTimeMakeWithSeconds(CMTimeGetSeconds((_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).duration) + CMTimeGetSeconds((_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).start), TIMESCALE),_trimFile.crop);
                                }
                            }else{
                                if(_callbackBlock){
                                    
                                    _callbackBlock(_cutType,nil,(_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).start,CMTimeMakeWithSeconds(CMTimeGetSeconds((_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).duration) + CMTimeGetSeconds((_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).start), TIMESCALE),_trimFile.crop);
                                }
                            }
                        }];
                    }else{
                        StrongSelf(self);
                        if(_trimVideoAsset){
                            if(_trimCallbackBlock){
                                _trimCallbackBlock(_cutType,_trimVideoAsset,(_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).start,CMTimeMakeWithSeconds(CMTimeGetSeconds((_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).duration) + CMTimeGetSeconds((_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).start), TIMESCALE),_trimFile.crop);
                            }
                            if(_callbackBlock){
                                
                                _callbackBlock(_cutType,nil,(_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).start,CMTimeMakeWithSeconds(CMTimeGetSeconds((_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).duration) + CMTimeGetSeconds((_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).start), TIMESCALE),_trimFile.crop);
                            }
                        }else{
                            if(_callbackBlock){
                                
                                _callbackBlock(_cutType,nil,(_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).start,CMTimeMakeWithSeconds(CMTimeGetSeconds((_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).duration) + CMTimeGetSeconds((_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).start), TIMESCALE),_trimFile.crop);
                            }
                        }
                    }
                }
                return;
            }
        }
        return;
    }
    
    UIViewController *upView = [self.navigationController popViewControllerAnimated:NO];
    if(!upView){
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)volumeBtnAction:(UIButton *)sender {
    AEVolumeView.hidden = NO;
    sender.selected = YES;
    filterBtn.selected = NO;
    AEfilterView.hidden = YES;
    
//    [AEVolumeView addSubview:_videoSlider];
    [AEVolumeView addSubview:self.trimSlider];
    [AEVolumeView addSubview:_showTimeView];
    
    AEScrollView.contentSize = CGSizeMake(0, AEfilterView.frame.size.height);
}

#pragma mark - 滤镜
- (void)filterBtnAction:(UIButton *)sender {
    if( !materialFilterVIew )
    {
        materialFilterVIew = [[UIView alloc] initWithFrame:CGRectMake(0, _videoSlider.frame.size.height+_videoSlider.frame.origin.y + 15.0/2.0, kWIDTH, 85)];
        [AEScrollView addSubview:materialFilterVIew];
        
        [materialFilterVIew addSubview:self.filterView];
        
        AEfilterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, materialFilterVIew.frame.size.height+materialFilterVIew.frame.origin.y)];
        
        [AEfilterView addSubview:_videoSlider];
        [AEfilterView addSubview:self.trimSlider];
        [AEfilterView addSubview:_showTimeView];
        [AEfilterView addSubview:materialFilterVIew];
        
        if( AEfilterView.frame.size.height <  AEScrollView.frame.size.height )
        {
            float fWidthX = (AEScrollView.frame.size.height- AEfilterView.frame.size.height)/2.0;
            
            AEfilterView.frame = CGRectMake(0, 0, kWIDTH, AEScrollView.frame.size.height);
            
            _videoSlider.frame = CGRectMake(_videoSlider.frame.origin.x, _showTimeView.frame.size.height+_showTimeView.frame.origin.y, _videoSlider.frame.size.width, _videoSlider.frame.size.height);
            _showTimeView.frame = CGRectMake(0, _videoSlider.frame.origin.y - 20, kWIDTH, 20);
            
            materialFilterVIew.frame = CGRectMake(materialFilterVIew.frame.origin.x, materialFilterVIew.frame.origin.y+fWidthX, materialFilterVIew.frame.size.width, materialFilterVIew.frame.size.height);
        }
        
        
        [AEScrollView addSubview:AEfilterView];
    }
    else
    {
        AEfilterView.hidden = NO;
    }
    
//    [AEfilterView addSubview:_videoSlider];
    _videoSlider.hidden = YES;
    [AEfilterView addSubview:_showTimeView];
    [AEfilterView addSubview:self.trimSlider];
    
    AEScrollView.contentSize = CGSizeMake(0, materialFilterVIew.frame.size.height + _filterView.bounds.size.height);
    AEVolumeView.hidden = YES;
    titleLabel.hidden = NO;
    sender.selected = YES;
    volumeBtn.selected = NO;
    currentFilterIndex = _trimFile.filterIndex;
}

-(RDTrimSlider*)trimSlider
{
    if( !_trimSlider )
    {
//        [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
        self.endTrimLabel.text = [RDHelpClass timeToStringFormat:_videoCoreSDK.duration/_trimFile.speed];
        _trimSlider = [[RDTrimSlider alloc] initWithFrame:_videoSlider.frame  videoCore:_videoCoreSDK trimDuration_OneSpecifyTime:_trimDuration_OneSpecifyTime];
        _trimSlider.delegate = self;
        [self performSelector:@selector(loadTrimmerViewThumbImage) withObject:nil afterDelay:0.1];
        _trimRangeLabel.text = [NSString stringWithFormat:@"%@",[RDHelpClass timeToStringFormat:_trimDuration_OneSpecifyTime]];
        CMTimeRange timeRange = kCMTimeRangeZero;
        if(_trimFile.isReverse){
            timeRange = _trimFile.reverseVideoTrimTimeRange;
        }else{
            timeRange = _trimFile.videoTrimTimeRange;
        }
        [_trimSlider interceptProgress:CMTimeGetSeconds( timeRange.start )];
    }
    return _trimSlider;
}
-(void)trimmerViewProgress:(CGFloat)startTime
{
    [_videoCoreSDK seekToTime:CMTimeMakeWithSeconds(startTime, TIMESCALE) toleranceTime:kCMTimeZero completionHandler:nil];
    _startTrimLabel.text = [NSString stringWithFormat:@"%@",[RDHelpClass timeToStringFormat:startTime]];
    if([_videoCoreSDK isPlaying])
        [self playVideo:NO];
}

#pragma mark-ThumbImageVideoCore
- (void)initThumbImageVideoCore{
    [thumbImageVideoCore stop];
    thumbImageVideoCore = nil;
    
    NSMutableArray *scenes = [NSMutableArray new];
    RDScene *scene = [[RDScene alloc] init];
    VVAsset* vvasset = [[VVAsset alloc] init];
    
    vvasset.url = _trimFile.contentURL;
    
    if(_trimFile.fileType == kFILEVIDEO){
        vvasset.videoActualTimeRange = _trimFile.videoActualTimeRange;
        vvasset.type = RDAssetTypeVideo;
        if(_trimFile.isReverse){
            if (CMTimeRangeEqual(kCMTimeRangeZero, _trimFile.reverseVideoTimeRange)) {
                vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, _trimFile.reverseDurationTime);
            }else{
                vvasset.timeRange = _trimFile.reverseVideoTimeRange;
            }
            
            NSLog(@"timeRange.duration:%f",CMTimeGetSeconds(vvasset.timeRange.duration));
        }
        else{
            if (CMTimeRangeEqual(kCMTimeRangeZero, _trimFile.videoTimeRange)) {
                vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, _trimFile.videoDurationTime);
            }else{
                vvasset.timeRange = _trimFile.videoTimeRange;
            }
            NSLog(@"timeRange.duration:%f",CMTimeGetSeconds(vvasset.timeRange.duration));
        }
        vvasset.speed        = _trimFile.speed;
        vvasset.volume       = _trimFile.videoVolume;
    }else{
        NSLog(@"图片");
        vvasset.type         = RDAssetTypeImage;
        if (CMTimeCompare(_trimFile.imageTimeRange.duration, kCMTimeZero) == 1) {
            vvasset.timeRange = _trimFile.imageTimeRange;
        }else {
            vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, _trimFile.imageDurationTime);
        }
        vvasset.speed        = _trimFile.speed;
        vvasset.volume       = _trimFile.videoVolume;
    }
    scene.transition.type   = RDVideoTransitionTypeNone;
    scene.transition.duration = 0.0;
    vvasset.rotate = _trimFile.rotate;
    vvasset.isVerticalMirror = _trimFile.isVerticalMirror;
    vvasset.isHorizontalMirror = _trimFile.isHorizontalMirror;
    vvasset.crop = _trimFile.crop;
    if (_isAdjustVolumeEnable) {
        vvasset.crop = CGRectMake(0, 0, 1, 1);
    }
    [scene.vvAsset addObject:vvasset];
    [scenes addObject:scene];
    
    if (!thumbImageVideoCore) {
        thumbImageVideoCore =  [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                                 APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                                LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                                 videoSize:_editVideoSize
                                                       fps:kEXPORTFPS
                                                resultFail:^(NSError *error) {
                                                    NSLog(@"initSDKError:%@", error.localizedDescription);
                                                }];
    }
    [thumbImageVideoCore setEditorVideoSize:_editVideoSize];
    [thumbImageVideoCore setScenes:scenes];
    [thumbImageVideoCore build];
    
}
#pragma mark- thumbnailCoreSDK
- (void)loadTrimmerViewThumbImage {
    @autoreleasepool {
        [thumbTimes removeAllObjects];
        thumbTimes = nil;
        thumbTimes=[[NSMutableArray alloc] init];
        Float64 duration;
        Float64 start;
        duration = _videoCoreSDK.duration;
        start = (duration > (_trimDuration_OneSpecifyTime/2.0) ? 0.2 : (duration-0.05));
        [thumbTimes addObject:[NSValue valueWithCMTime:CMTimeMakeWithSeconds(start,TIMESCALE)]];
        float actualFramesNeeded = duration/(_trimDuration_OneSpecifyTime/2.0);
        Float64 durationPerFrame = duration / (actualFramesNeeded*1.0);
        /*截图为什么用两个for循环：第一个for循环是分配内存，第二个for循环显示图片，截图快一些*/
        for (int i=1; i<actualFramesNeeded; i++){
            CMTime time = CMTimeMakeWithSeconds( (int)(start + i*durationPerFrame),TIMESCALE);
            [thumbTimes addObject:[NSValue valueWithCMTime:time]];
        }
//        [thumbImageVideoCore getImageWithTime:CMTimeMakeWithSeconds(start,TIMESCALE) scale:0.2 completionHandler:^(UIImage *image) {
//            if(!image){
//                image = [thumbImageVideoCore getImageAtTime:CMTimeMakeWithSeconds(start,TIMESCALE) scale:0.2];
//                if (!image) {
//                    image = [_videoCoreSDK getImageAtTime:CMTimeMakeWithSeconds(start,TIMESCALE) scale:0.2];
//                }
//            }
            
            [_trimSlider loadTrimmerViewThumbImage:nil
                                    thumbnailCount:thumbTimes.count];
            
            CMTimeRange timeRange = kCMTimeRangeZero;
            if(_trimFile.isReverse){
                timeRange = _trimFile.reverseVideoTrimTimeRange;
            }else{
                timeRange = _trimFile.videoTrimTimeRange;
            }
            [_trimSlider interceptProgress:CMTimeGetSeconds( timeRange.start )];
            
            [self refreshTrimmerViewImage];
//        }];
    }
}
- (void)refreshTrimmerViewImage {
    @autoreleasepool {
        if( thumbImageVideoCore )
        {
            Float64 durationPerFrame = thumbImageVideoCore.duration / (thumbTimes.count*1.0);
            for (int i=0; i<thumbTimes.count; i++){
                CMTime time = CMTimeMakeWithSeconds(i*durationPerFrame + 0.2,TIMESCALE);
                [thumbTimes replaceObjectAtIndex:i withObject:[NSValue valueWithCMTime:time]];
            }
            [self refreshThumbWithImageTimes:thumbTimes nextRefreshIndex:0 isLastArray:YES];
        }
        else
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                Float64 durationPerFrame = _videoCoreSDK.duration / (thumbTimes.count*1.0);
                for (int i=0; i<thumbTimes.count; i++){
                    CMTime time = CMTimeMakeWithSeconds(i*durationPerFrame + 0.2,TIMESCALE);
                    [thumbTimes replaceObjectAtIndex:i withObject:[NSValue valueWithCMTime:time]];
                }
                
                [thumbTimes enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    
                    int number = ceilf( CMTimeGetSeconds([ ((NSValue*)obj) CMTimeValue]) )*_trimFile.speed;
                    
                    NSString * strPatch = [_trimFile.filtImagePatch stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.png",number]];
                    
                    __block UIImage * image = nil;
                    image = [[UIImage alloc] initWithContentsOfFile:strPatch];
                    dispatch_async(dispatch_get_main_queue(), ^{
                    
                        [_trimSlider.TrimmerView refreshThumbImage:idx thumbImage:image];
                        
                    });
                    
                    
                }];
            });
        }
    }
}
- (void)refreshThumbWithImageTimes:(NSArray *)imageTimes nextRefreshIndex:(int)nextRefreshIndex isLastArray:(BOOL)isLastArray{
    @autoreleasepool {
        __weak typeof(self) weakSelf = self;
        [thumbImageVideoCore getImageWithTimes:[imageTimes mutableCopy] scale:0.1 completionHandler:^(UIImage *image, NSInteger idx) {
            StrongSelf(self);
            if(!image){
                return;
            }
            
            [strongSelf->_trimSlider.TrimmerView refreshThumbImage:idx thumbImage:image];
            
            if(idx == imageTimes.count - 1)
            {

                
                
                if( strongSelf )
                    [strongSelf->thumbImageVideoCore stop];
                [RDSVProgressHUD dismiss];
            }
        }];
    }
}


- (void)addFileWithList:(NSMutableArray *)thumbFilelist{
    isNeedPrepare = NO;
    if([RDHelpClass isImageUrl:[thumbFilelist firstObject]]){
        _trimFile.contentURL = [thumbFilelist firstObject];
        _trimFile.fileType = kFILEIMAGE;
        _trimFile.imageDurationTime = CMTimeMakeWithSeconds(KPICDURATION, TIMESCALE);
        _trimFile.speedIndex = 1;
    }else{
        _trimFile.contentURL = [thumbFilelist firstObject];
        _trimFile.fileType = kFILEVIDEO;
        _trimFile.videoDurationTime =[AVURLAsset assetWithURL:_trimFile.contentURL].duration;
        _trimFile.videoTimeRange = CMTimeRangeMake(kCMTimeZero,_trimFile.videoDurationTime);
        _trimFile.reverseVideoTimeRange = _trimFile.videoTimeRange;
        _trimFile.videoTrimTimeRange = kCMTimeRangeInvalid;
        _trimFile.reverseVideoTrimTimeRange = kCMTimeRangeInvalid;
        _trimFile.speedIndex = 2;
    }
    
    clipTimeRange = _trimFile.videoTimeRange;
    clipSliderTimeRange = _trimFile.videoTrimTimeRange;
    
    _editVideoSize = [RDHelpClass trackSize:_trimFile.contentURL rotate:0];
    isPortrait = [RDHelpClass isVideoPortrait:[AVURLAsset assetWithURL:_trimFile.contentURL]];
    [_videoSlider.subviews respondsToSelector:@selector(removeFromSuperview)];
    [_videoSlider.imageGenerator cancelAllCGImageGeneration];
    [_videoSlider removeFromSuperview];
    _videoSlider = nil;
    [_videoCoreSDK setEditorVideoSize:_editVideoSize];
    [self initPlayer];
    if (_trimFile.isVerticalMirror || _trimFile.isHorizontalMirror || _trimFile.rotate != 0 || _trimFile.isReverse) {
        [self initThumbVideoCore];
    }
    [self initVideoRangeSlider];
    Float64 nowTime = _videoCoreSDK.duration;
    _videoSlider.selectedDurationValue = _trimDuration_OneSpecifyTime;
    _videoSlider.moveValue = _trimDuration_OneSpecifyTime/nowTime>1.0?1.0:_trimDuration_OneSpecifyTime/nowTime;
    _videoSlider.upperValue = _videoSlider.lowerValue + _videoSlider.moveValue;
    [self initCropView];
    [volumeSlider setValue:_trimFile.videoVolume];
    volumeLbl.text = [NSString stringWithFormat:RDLocalizedString(@"音量大小:%.1f", nil), _trimFile.videoVolume];
}

#pragma mark - 滑动进度条
/**开始滑动
 */
//- (void)beginScrubVolume:(RDZSlider *)slider{
//    if(_videoCoreSDK.isPlaying){
//        [self playVideo:NO];
//    }
//}

/**正在滑动
 */
- (void)scrubVolume:(RDZSlider *)slider{
    volumeLbl.text = [NSString stringWithFormat:RDLocalizedString(@"音量大小:%.1f", nil), slider.value];
    [_videoCoreSDK setVolume:slider.value identifier:@"video"];
}
/**滑动结束
 */
- (void)endScrubVolume:(RDZSlider *)slider{
    volumeLbl.text = [NSString stringWithFormat:RDLocalizedString(@"音量大小:%.1f", nil), slider.value];
    _trimFile.videoVolume = slider.value;
    [_videoCoreSDK setVolume:slider.value identifier:@"video"];
}

- (void)setVideoCropSize {
    CGRect cropRect = [self getCropRect];
    float originalVideoWidth    = _editVideoSize.width;
    float originalVideoHeight   = _editVideoSize.height;
    
    float videoW;
    float videoH;
    
    if (isPortrait) {
        videoW = MIN(originalVideoWidth, originalVideoHeight);
        videoH = MAX(originalVideoWidth, originalVideoHeight);
    }else{
        videoW = originalVideoWidth;
        videoH = originalVideoHeight;
    }
    
    if(_trimFile.rotate == -90 || _trimFile.rotate == -270){
        cropRect.origin.x = cropRect.origin.x/videoH;
        cropRect.origin.y = cropRect.origin.y/videoW;
        
        cropRect.size.width = cropRect.size.width/videoH;
        cropRect.size.height = cropRect.size.height/videoW;
    }else{
        cropRect.origin.x = cropRect.origin.x/videoW;
        cropRect.origin.y = cropRect.origin.y/videoH;
        cropRect.size.width = cropRect.size.width/videoW;
        cropRect.size.height = cropRect.size.height/videoH;
    }
    
    if(_trimFile.isHorizontalMirror){
        cropRect.origin.x =  (1 - cropRect.origin.x - cropRect.size.width);
    }
    _trimFile.crop = cropRect;
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    NSLog(@"X : Y : %f  %f",scrollView.contentOffset.x,scrollView.contentOffset.y);
}
//以MIN(_editorVideoSize.width, _editorVideoSize.height)为宽和高，裁剪成正方形
- (CGRect)getCropRect
{
    float scale;
    CGRect r;
    if (isPortrait) {
        scale = _editVideoSize.height/playerScrollView.contentSize.height;
        r = CGRectMake(0, playerScrollView.contentOffset.y*scale, _editVideoSize.width, _editVideoSize.width);
    }else {
        scale = _editVideoSize.width/playerScrollView.contentSize.width;
        r = CGRectMake(playerScrollView.contentOffset.x*scale, 0, _editVideoSize.height, _editVideoSize.height);
    }
    
    return r;
}

/**播放暂停
 */
- (void)tapPlayButton{
    [self playVideo:![_videoCoreSDK isPlaying]];
}

- (void)playVideo:(BOOL)play{
  
    if(!play){
        [_cliper playerVideo:NO];
        if([_videoCoreSDK isPlaying]){
           [_videoCoreSDK pause];
        }
        [_playButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
    }else{
        [_cliper playerVideo:YES];
        [_playButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateNormal];
        if(![_videoCoreSDK isPlaying]){
            CMTime endTime = CMTimeMakeWithSeconds(_videoCoreSDK.duration*_videoSlider.upperValue, TIMESCALE);
            CMTime currentTime = CMTimeAdd(_videoCoreSDK.currentTime, CMTimeMake(1, kEXPORTFPS));
            if (_isAdjustVolumeEnable) {
                endTime = CMTimeMakeWithSeconds(_trimDuration_OneSpecifyTime+CMTimeGetSeconds(currentTime), TIMESCALE);
            }
            if (_trimType == TRIMMODEAUTOTIME && CMTimeCompare(currentTime, endTime) >= 0) {
                if (_isAdjustVolumeEnable) {
                    [_videoCoreSDK seekToTime:CMTimeMakeWithSeconds(_trimSlider.progressValue,TIMESCALE) toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
                        [_videoCoreSDK play];
                    }];
                }
                else
                {
                    [_videoCoreSDK seekToTime:CMTimeMakeWithSeconds(_videoCoreSDK.duration*_videoSlider.lowerValue,TIMESCALE) toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
                        [_videoCoreSDK play];
                    }];
                }
            }else {
                [_videoCoreSDK play];
            }
        }
    }
}

#pragma mark - RDVECoreDelegate
- (void)statusChanged:(RDVECore *)sender status:(RDVECoreStatus)status
{
    if (status == kRDVECoreStatusReadyToPlay) {
       if(sender == _videoCoreSDK)
       {
        if (_isAdjustVolumeEnable) {
            if( isFrist )
            {
                CMTimeRange timeRange = kCMTimeRangeZero;
                if(_trimFile.isReverse){
                    timeRange = _trimFile.reverseVideoTrimTimeRange;
                }else{
                    timeRange = _trimFile.videoTrimTimeRange;
                }
                [_videoCoreSDK seekToTime:timeRange.start toleranceTime:kCMTimeZero completionHandler:nil];
                isFrist = false;
            }
        }
        else{
           [self seektimeCore];
        }
       }
       else if(sender == thumbImageVideoCore )
       {
           
       }
    }
}
- (void)tapPlayerView{
    [self playVideo:![_videoCoreSDK isPlaying]];
}

- (void)progressCurrentTime:(CMTime)currentTime{
    CMTime time = currentTime;
    if(!_videoCoreSDK.isPlaying){
        return;
    }
    //NSLog(@"%d",time.value/time.timescale);
    if([[NSString stringWithFormat:@"%f", CMTimeGetSeconds(time)] isEqualToString:@"nan"])
    {
        return;
    }
    float progress = CMTimeGetSeconds(time);
    
    CMTime endtime = CMTimeMakeWithSeconds(_videoCoreSDK.duration*_videoSlider.upperValue, TIMESCALE);

    if (_trimType == TRIMMODEAUTOTIME) {
        if(CMTimeCompare(CMTimeAdd(currentTime, CMTimeMake(1, kEXPORTFPS)), endtime) == 1){
            [self playToEnd];
            return;
        }
    }else {
        Float64 start = CMTimeGetSeconds(clipTimeRange.duration)*_videoSlider.lowerValue+CMTimeGetSeconds(clipTimeRange.start);
        float moveValue = _videoSlider.moveValue*_videoCoreSDK.duration;
        if (_isAdjustVolumeEnable)
        {
            start = _trimSlider.progressValue;
            moveValue = _trimSlider.progressValue + _trimDuration_OneSpecifyTime;
        }
        if (CMTimeGetSeconds(CMTimeAdd(time, CMTimeMake(1, kEXPORTFPS))) - start >= moveValue){
            [self playToEnd];
            return;
        }
    }
    
    if(!isnan(progress)){
        if (_isAdjustVolumeEnable)
        {
            if( [_trimSlider progress:progress] >= 1.0 )
            {
                [self playToEnd];
            }
            else
                _startTrimLabel.text = [NSString stringWithFormat:@"%@",[RDHelpClass timeToStringFormat:progress]];
        }
        else
            [_videoSlider progress:progress];
    }
}

- (void)playToEnd{
    [self playVideo:NO];
    CMTime start = CMTimeMakeWithSeconds(_videoCoreSDK.duration*_videoSlider.lowerValue, TIMESCALE);
    if (_isAdjustVolumeEnable)
    {
        start = CMTimeMakeWithSeconds(_trimSlider.progressValue, TIMESCALE);
        [_trimSlider progress:_trimSlider.progressValue];
        _startTrimLabel.text = [NSString stringWithFormat:@"%@",[RDHelpClass timeToStringFormat:_trimSlider.progressValue]];
    }
    [_videoCoreSDK seekToTime:start toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
        [self playVideo:NO];
    }];
    
}

#pragma mark-
- (void) switchAction{
    [self playVideo:NO];

    UILabel* leftLabel = [_switchView viewWithTag:100];
    UILabel* rightLabel = [_switchView viewWithTag:200];
    Float64 duration = _videoCoreSDK.duration;
    float durationValue = 0.0;
    
    if ([rightLabel.textColor isEqual:[UIColor blackColor]]) {
        rightLabel.backgroundColor = [UIColor clearColor];
        rightLabel.textColor = [UIColor whiteColor];
        leftLabel.backgroundColor = [UIColor whiteColor];
        leftLabel.textColor = [UIColor blackColor];
        durationValue = _trimMinDuration_TwoSpecifyTime/duration>1.0?1.0:_trimMinDuration_TwoSpecifyTime/duration;
        leftLabel.layer.cornerRadius = 15;
        leftLabel.layer.masksToBounds = YES;
        _selectMin = YES;
        _selectMax = NO;
        _videoSlider.selectedDurationValue = _trimMinDuration_TwoSpecifyTime;
    }else{
        rightLabel.backgroundColor = [UIColor whiteColor];
        rightLabel.textColor = [UIColor blackColor];
        leftLabel.backgroundColor = [UIColor clearColor];
        leftLabel.textColor = [UIColor whiteColor];
        durationValue = _trimMaxDuration_TwoSpecifyTime/duration>1.0?1.0:_trimMaxDuration_TwoSpecifyTime/duration;
        rightLabel.layer.cornerRadius = 15;
        rightLabel.layer.masksToBounds = YES;
        _selectMin = NO;
        _selectMax = YES;
        _videoSlider.selectedDurationValue = _trimMaxDuration_TwoSpecifyTime;
        
    }
    _videoSlider.moveValue = durationValue;
    
    float beginValue = _videoSlider.lowerValue;
    
    if (beginValue+durationValue <= 1.0) {
        
        [_videoSlider setUpperValue:beginValue+durationValue];
    }
    if (beginValue+durationValue > 1.0) {
        [_videoSlider setUpperValue:1.0];
        [_videoSlider setLowerValue:1.0-durationValue];
    }
    
    Float64 start_time = duration*_videoSlider.lowerValue;
    if(_videoSlider.isloadFinishThumb) {
        [_videoCoreSDK seekToTime:CMTimeMakeWithSeconds(start_time, TIMESCALE)];
        [_videoSlider progress:start_time];
    }
    
    CMTime start = CMTimeMakeWithSeconds(duration*_videoSlider.lowerValue*(float)_trimFile.speed, TIMESCALE);
    CMTime endtime = CMTimeMakeWithSeconds(duration*_videoSlider.upperValue*(float)_trimFile.speed,TIMESCALE);

    _startTrimLabel.text = [NSString stringWithFormat:@"%@",[RDHelpClass timeToStringFormat:(CMTimeGetSeconds(start))]];
    float currentDuration = round(CMTimeGetSeconds(endtime)-CMTimeGetSeconds(start));
    _trimRangeLabel.text = [NSString stringWithFormat:@"%@",[RDHelpClass timeToStringFormat:currentDuration]];
    _endTrimLabel.text = [NSString stringWithFormat:@"%@",[RDHelpClass timeToStringFormat:(CMTimeGetSeconds(endtime))]];
}

- (void)squareChangeBtnAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    isSelectedSquare = sender.selected;
    if (isSelectedSquare) {

        CGSize size = [self getVideoSizeForTrack];
        if (isPortrait) {
            playerScrollView.contentSize = CGSizeMake(kWIDTH, kWIDTH * size.height/size.width);
            playerScrollView.contentOffset = CGPointMake(0, (playerScrollView.contentSize.height - kWIDTH)/2);
        }else {
            playerScrollView.contentSize = CGSizeMake(playerScrollView.frame.size.height * size.width/size.height, playerScrollView.frame.size.height);
            playerScrollView.contentOffset = CGPointMake((playerScrollView.contentSize.width - kWIDTH)/2, 0);
        }

//        float scrollViewWidth = kWIDTH;
//        if (isPortrait) {
//            playerScrollView.contentSize = CGSizeMake(scrollViewWidth, scrollViewWidth*2 - 80);
//            playerScrollView.contentOffset = CGPointMake(0, (playerScrollView.contentSize.height - scrollViewWidth)/2);
//        }else {
//            playerScrollView.contentSize = CGSizeMake(scrollViewWidth*2 - 80, scrollViewWidth);
//            playerScrollView.contentOffset = CGPointMake((playerScrollView.contentSize.width - scrollViewWidth)/2, 0);
//        }
        _playerView.frame = CGRectMake(0, 0, playerScrollView.contentSize.width, playerScrollView.contentSize.height);
    }else {
        if (isPortrait) {
            _playerView.frame = CGRectMake((playerScrollView.frame.size.height - playerScrollView.frame.size.height*9/16)/2, 0, playerScrollView.frame.size.width*9/16, playerScrollView.frame.size.height);
        }else {
            _playerView.frame = CGRectMake(0, (playerScrollView.frame.size.height - playerScrollView.frame.size.height*9/16)/2, playerScrollView.frame.size.width, playerScrollView.frame.size.height*9/16);
        }
        playerScrollView.contentOffset = CGPointZero;
        playerScrollView.contentSize = CGSizeMake(playerScrollView.frame.size.width, playerScrollView.frame.size.height);
    }
    _videoCoreSDK.frame = _playerView.bounds;
    _videoCoreSDK.view.frame = _playerView.bounds;
    if (isSelectedSquare) {
        if (isPortrait && ![[NSUserDefaults standardUserDefaults] objectForKey:@"showedPortraitHint"]) {
            playerScrollHintIV.hidden = NO;
            [self performSelector:@selector(hiddenPlayerScrollHintIV) withObject:nil afterDelay:2];
            [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"showedPortraitHint"];
        }
        else if (!isPortrait && ![[NSUserDefaults standardUserDefaults] objectForKey:@"showedLandscapeHint"]) {
            playerScrollHintIV.hidden = NO;
            [self performSelector:@selector(hiddenPlayerScrollHintIV) withObject:nil afterDelay:2];
            [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"showedLandscapeHint"];
        }
    }
}

//20171026 wuxiaoxia 优化内存
- (void)NMCutRangeSliderLoadThumbsCompletion {
    [thumbVideoCore stop];
    thumbVideoCore = nil;
}

- (void)beginScrub:(NMCutRangeSlider_RD *)slider{
    [self playVideo:NO];
    CMTime start = CMTimeMakeWithSeconds(_videoCoreSDK.duration*_videoSlider.lowerValue, TIMESCALE);
    CMTime endtime = CMTimeMakeWithSeconds(_videoCoreSDK.duration*_videoSlider.upperValue,TIMESCALE);
    float x = 0;
    if(_videoSlider.handleLeft)
        x = _videoSlider.lowerHandle.frame.origin.x + _videoSlider.lowerHandle.frame.size.width;
    else if(_videoSlider.handleRight)
        x = _videoSlider.upperHandle.frame.origin.x;
    
//    self.dragTimeView.hidden = NO;
//    _dragTimeView.frame  = CGRectMake(x + _videoSlider.frame.origin.x - 18 - 11.5, _dragTimeView.frame.origin.y, _dragTimeView.frame.size.width, _dragTimeView.frame.size.height);
    
    if(_videoSlider.handleLeft)
        [self InitDragTimeView:[RDHelpClass timeToStringFormat:CMTimeGetSeconds(start)] atX:x+_videoSlider.frame.origin.x-5 ];
    else
        [self InitDragTimeView:[RDHelpClass timeToStringFormat:CMTimeGetSeconds(endtime)] atX:x + _videoSlider.frame.origin.x];
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
    
    _dragTimeView = [[UIView alloc] initWithFrame:CGRectMake(x - Width/2.0 + 3, _videoSlider.frame.origin.y - 25 - 3, Width, 25)];
    
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
    
    [self.view addSubview:_dragTimeView];
}

- (void)scrub:(NMCutRangeSlider_RD *)slider{
    CMTime start = CMTimeMakeWithSeconds(_videoCoreSDK.duration*_videoSlider.lowerValue, TIMESCALE);
    if((_trimType != TRIMMODEAUTOTIME) && CMTimeGetSeconds(start)<0){
        return;
    }
    CMTime endtime = CMTimeMakeWithSeconds(_videoCoreSDK.duration*_videoSlider.upperValue,TIMESCALE);
    
    NSLog(@"%f",CMTimeGetSeconds(endtime));
    _startTrimLabel.text = [NSString stringWithFormat:@"%@",[RDHelpClass timeToStringFormat:(CMTimeGetSeconds(start))]];
    if (_trimType == TRIMMODEAUTOTIME) {
        _trimRangeLabel.text = [NSString stringWithFormat:@"%@",[RDHelpClass timeToStringFormat:(CMTimeGetSeconds(endtime) - CMTimeGetSeconds(start))]];
    }else {
        _trimRangeLabel.text = [NSString stringWithFormat:@"%@",[RDHelpClass timeToStringFormat:round(CMTimeGetSeconds(endtime)-CMTimeGetSeconds(start))]];
    }
    _endTrimLabel.text = [NSString stringWithFormat:@"%@",[RDHelpClass timeToStringFormat:(CMTimeGetSeconds(endtime))]];
    
    float x = 0;
    
    if(slider.handleLeft){
        
        x = slider.lowerHandle.frame.origin.x + slider.lowerHandle.frame.size.width;
        [_videoCoreSDK seekToTime:CMTimeMakeWithSeconds(_videoCoreSDK.duration*_videoSlider.lowerValue, TIMESCALE) toleranceTime:kCMTimeZero completionHandler:nil];
    
    }else if(slider.handleRight){
        
        x = slider.upperHandle.frame.origin.x;
        [_videoCoreSDK seekToTime:CMTimeMakeWithSeconds(_videoCoreSDK.duration*_videoSlider.upperValue,TIMESCALE) toleranceTime:kCMTimeZero completionHandler:nil];
        
    }
    
    if(_videoSlider.handleLeft)
        [self InitDragTimeView:[RDHelpClass timeToStringFormat:CMTimeGetSeconds(start)] atX:x+_videoSlider.frame.origin.x ];
    else
        [self InitDragTimeView:[RDHelpClass timeToStringFormat:CMTimeGetSeconds(endtime)] atX:x + _videoSlider.frame.origin.x];
    
}

- (void)endScrub:(NMCutRangeSlider_RD *)slider{
    if (_trimType != TRIMMODEAUTOTIME) {
        CMTime progressValue = CMTimeMakeWithSeconds(MAX(_videoSlider.progressValue,_videoCoreSDK.duration*_videoSlider.lowerValue), TIMESCALE);
        [_videoCoreSDK seekToTime:progressValue];
    }
    self.dragTimeView.hidden = YES;
}

- (void)changeCutVideoReturnType:(RDCutVideoReturnType )type{
    _cutType = type;
    if(_trimType != TRIMMODEAUTOTIME){
        CMTimeRange range = _trimFile.videoTrimTimeRange;
        if (_trimType == TRIMMODESPECIFYTIME_ONE) {
            if(CMTimeGetSeconds(_trimFile.videoTrimTimeRange.start)/(float)_trimFile.speed + _trimDuration_OneSpecifyTime >= _videoCoreSDK.duration){
                if(_videoSlider.selectedDurationValue<_videoCoreSDK.duration){
                    range.duration = CMTimeMakeWithSeconds(_videoSlider.selectedDurationValue/(float)_trimFile.speed, TIMESCALE);
                    range.start = CMTimeMakeWithSeconds((_videoCoreSDK.duration - _videoSlider.selectedDurationValue)/(float)_trimFile.speed, TIMESCALE);
                }
            }
        }else {
            if(_selectMax){
                if(CMTimeGetSeconds(_trimFile.videoTrimTimeRange.start)/(float)_trimFile.speed + _trimMaxDuration_TwoSpecifyTime >= _videoCoreSDK.duration){
                    if(_videoSlider.selectedDurationValue<_videoCoreSDK.duration){
                        range.duration = CMTimeMakeWithSeconds(_videoSlider.selectedDurationValue/(float)_trimFile.speed, TIMESCALE);
                        range.start = CMTimeMakeWithSeconds((_videoCoreSDK.duration - _videoSlider.selectedDurationValue)/(float)_trimFile.speed, TIMESCALE);
                    }
                }
            }else{
                if(CMTimeGetSeconds(_trimFile.videoTrimTimeRange.start)/(float)_trimFile.speed + _trimMinDuration_TwoSpecifyTime >= _videoCoreSDK.duration){
                    if(_videoSlider.selectedDurationValue<_videoCoreSDK.duration){
                        range.duration = CMTimeMakeWithSeconds(_videoSlider.selectedDurationValue/(float)_trimFile.speed, TIMESCALE);
                        range.start = CMTimeMakeWithSeconds((_videoCoreSDK.duration - _videoSlider.selectedDurationValue)/(float)_trimFile.speed, TIMESCALE);
                    }
                }
            }
        }
        NSLog(@"start :%f, duration:%f",CMTimeGetSeconds(range.start),CMTimeGetSeconds(range.duration));
        _trimFile.videoTrimTimeRange = range;
    }
    if(_cutVideoFinishAction){
        _cutVideoFinishAction(_trimFile);
        if([[self.navigationController childViewControllers] count]>1){
            [(RDNavigationViewController *)self.navigationController rdPopViewControllerAnimated:NO];
        }else{
            [self dismissViewControllerAnimated:NO completion:nil];
        }
    }else{
        if(_cutType == RDCutVideoReturnTypePath){
            if((_callbackBlock || _trimCallbackBlock) && _trimVideoAsset){
                [self exportVideo:_trimVideoAsset.URL timeRange:_trimFile.videoTrimTimeRange];
                return;
            }
        }
        if(_cutType == RDCutVideoReturnTypeTime){
            if(_exportProgress){
                [_exportProgress removeFromSuperview];
                _exportProgress = nil;
            }
            if ( !isCoreStop && _videoCoreSDK) {
                [_videoCoreSDK.view removeFromSuperview];
                _videoCoreSDK.delegate = nil;
                _videoCoreSDK = nil;
            }
            else{
                [_videoCoreSDK seekToTime:kCMTimeZero];
            }
            [_videoSlider.subviews respondsToSelector:@selector(removeFromSuperview)];
            [_videoSlider removeFromSuperview];
            _videoSlider = nil;
            
            if((_callbackBlock || _trimCallbackBlock)){
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(_trimVideoAsset && _trimCallbackBlock){
                        _trimCallbackBlock(_cutType,_trimVideoAsset,_trimFile.videoTrimTimeRange.start,CMTimeMakeWithSeconds(CMTimeGetSeconds(_trimFile.videoTrimTimeRange.duration) + CMTimeGetSeconds(_trimFile.videoTrimTimeRange.start), TIMESCALE),_trimFile.crop);
                        
                    }else if (_callbackBlock) {
                        _callbackBlock(_cutType,nil,_trimFile.videoTrimTimeRange.start,CMTimeMakeWithSeconds(CMTimeGetSeconds(_trimFile.videoTrimTimeRange.duration) + CMTimeGetSeconds(_trimFile.videoTrimTimeRange.start), TIMESCALE),_trimFile.crop);
                        
                    }
                });
                UIViewController *upView = [self.navigationController popViewControllerAnimated:NO];
                if(!upView){
                    [self dismissViewControllerAnimated:NO completion:nil];
                }
                return;
            }
        }
    }
}

- (void)initProgress{
    _exportProgress = [[RDExportProgressView alloc] initWithFrame:CGRectMake(0,0, kWIDTH, kHEIGHT)];
    [_exportProgress setProgress:0 animated:NO];
    [self.navigationController.view addSubview:_exportProgress];
    __weak typeof(self) weakSelf = self;
    _exportProgress.cancelExportBlock = ^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf cancelExport];
        });
        
    };
}

- (void)exportVideo:(NSURL *)fileurl timeRange:(CMTimeRange)timeRange{
    [self initProgress];
    
    NSString *exportOutPath = self.outputFilePath.length>0 ? self.outputFilePath : [RDHelpClass pathAssetVideoForURL:fileurl];
    unlink([exportOutPath UTF8String]);
    _idleTimerDisabled = [UIApplication sharedApplication].idleTimerDisabled;
    [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
    
    CGSize size = [RDHelpClass getVideoSizeForTrack:[AVURLAsset assetWithURL:fileurl]];
    if (_trimExportVideoType != TRIMEXPORTVIDEOTYPE_ORIGINAL && isSelectedSquare && !isSquareVideo) {
        float width = MIN(_editVideoSize.width, _editVideoSize.height);
        size = CGSizeMake(width, width);
    }
    
    scenes = [NSMutableArray new];
    RDScene *scene = [[RDScene alloc] init];
    VVAsset* vvasset = [[VVAsset alloc] init];
    vvasset.url = _trimFile.contentURL;
    vvasset.identifier = @"video";
    if(_trimFile.fileType == kFILEVIDEO){
        vvasset.videoActualTimeRange = _trimFile.videoActualTimeRange;
        vvasset.type = RDAssetTypeVideo;
        if(_trimFile.isReverse){
            vvasset.url = _trimFile.reverseVideoURL;
        }
        vvasset.timeRange = timeRange;
        vvasset.speed        = _trimFile.speed;
        vvasset.volume       = _trimFile.videoVolume;
    }else{
        NSLog(@"图片");
        vvasset.type         = RDAssetTypeImage;
        vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, _trimFile.imageDurationTime);
        vvasset.speed        = _trimFile.speed;
        vvasset.volume       = _trimFile.videoVolume;
    }
    scene.transition.type   = RDVideoTransitionTypeNone;
    scene.transition.duration = 0.0;
    vvasset.rotate = _trimFile.rotate;
    vvasset.isVerticalMirror = _trimFile.isVerticalMirror;
    vvasset.isHorizontalMirror = _trimFile.isHorizontalMirror;
    vvasset.crop = _trimFile.crop;
    if (_isAdjustVolumeEnable) {
        vvasset.crop = CGRectMake(0, 0, 1, 1);
    }
    if (_globalFilters.count > 0) {
        RDFilter* filter = _globalFilters[_trimFile.filterIndex];
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
    vvasset.brightness = _trimFile.brightness;
    vvasset.contrast = _trimFile.contrast;
    vvasset.saturation = _trimFile.saturation;
    vvasset.sharpness = _trimFile.sharpness;
    vvasset.whiteBalance = _trimFile.whiteBalance;
    vvasset.vignette = _trimFile.vignette;
    [scene.vvAsset addObject:vvasset];
    //添加特效
    //滤镜特效
    if( _trimFile.customFilterIndex != 0 )
    {
        NSArray *filterFxArray = [NSArray arrayWithContentsOfFile:kNewSpecialEffectPlistPath];
        vvasset.customFilter = [RDGenSpecialEffect getCustomFilerWithFxId:_trimFile.customFilterId filterFxArray:filterFxArray timeRange:CMTimeRangeMake(kCMTimeZero,vvasset.timeRange.duration)];
    }
    //时间特效
    if( _trimFile.fileTimeFilterType != kTimeFilterTyp_None )
    {
        [RDGenSpecialEffect refreshVideoTimeEffectType:scenes atFile:_trimFile atscene:scene atTimeRange:_trimFile.fileTimeFilterTimeRange atIsRemove:NO];
    }
    else {
        [scenes addObject:scene];
    }
    [_videoCoreSDK setScenes:scenes];
    [_videoCoreSDK setEditorVideoSize:size];
    WeakSelf(self);
    [_videoCoreSDK exportMovieURL:[NSURL fileURLWithPath:exportOutPath]
                             size:size
                          bitrate:((RDNavigationViewController *)self.navigationController).videoAverageBitRate
                              fps:kEXPORTFPS
                     audioBitRate:0
              audioChannelNumbers:1
           maxExportVideoDuration:((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration
                         progress:^(float progress) {
                             [_exportProgress setProgress:progress*100.0 animated:NO];
                         } success:^{
                             [weakSelf exportSuccessWithFilePath:exportOutPath timeRange:timeRange];
                         } fail:^(NSError *error) {
                             [weakSelf exportMovieFail:error];
                         }];
}

- (void)exportSuccessWithFilePath:(NSString *)filePath timeRange:(CMTimeRange)timeRange {
    [_videoSlider.subviews respondsToSelector:@selector(removeFromSuperview)];
    [_videoSlider.imageGenerator cancelAllCGImageGeneration];
    [_videoSlider removeFromSuperview];
    _videoSlider = nil;
    
    [_exportProgress removeFromSuperview];
    _exportProgress = nil;
    
    [_videoCoreSDK stop];
    _videoCoreSDK.delegate = nil;
    _videoCoreSDK = nil;
    
    if (thumbVideoCore) {
        [thumbVideoCore stop];
        thumbVideoCore.delegate = nil;
        thumbVideoCore = nil;
    }
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    if(((RDNavigationViewController *)self.navigationController).isSingleFunc && ((RDNavigationViewController *)self.navigationController).callbackBlock){
        [self dismissViewControllerAnimated:YES completion:^{
            if(((RDNavigationViewController *)self.navigationController).callbackBlock){
                ((RDNavigationViewController *)self.navigationController).callbackBlock(filePath);
            }
        }];
    }else if(_selectAndTrimFinishBlock){
        _trimFile.contentURL = [NSURL fileURLWithPath:self.outputFilePath];
        _trimFile.videoTimeRange = CMTimeRangeMake(kCMTimeZero, timeRange.duration);
        _trimFile.videoTrimTimeRange = _trimFile.videoTimeRange;
        _selectAndTrimFinishBlock(_trimFile);
        [self.presentingViewController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    }
    else {
        if (_trimVideoAsset && _trimCallbackBlock) {
            AVURLAsset *urlAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:_outputFilePath] options:nil];
            _trimCallbackBlock(_cutType,urlAsset,(_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).start,CMTimeMakeWithSeconds(CMTimeGetSeconds((_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).duration) + CMTimeGetSeconds((_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).start), TIMESCALE),_trimFile.crop);
        }
        if (_callbackBlock) {
            _callbackBlock(_cutType,filePath,(_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).start,CMTimeMakeWithSeconds(CMTimeGetSeconds((_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).duration) + CMTimeGetSeconds((_trimFile.isReverse ? _trimFile.reverseVideoTrimTimeRange : _trimFile.videoTrimTimeRange).start), TIMESCALE),_trimFile.crop);
        }
        if([[self.navigationController childViewControllers] count]>1){
            [(RDNavigationViewController *)self.navigationController rdPopViewControllerAnimated:NO];
        }else{
            [self dismissViewControllerAnimated:NO completion:nil];
        }
    }
}

- (void)exportMovieFail:(NSError *)error {
    if(_failback){
        NSDictionary *userInfo= [[NSDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"%@", error.localizedDescription],@"message", nil];
        NSError *error = [NSError errorWithDomain:RDUISDKCustomErrorDomain code:RDUISDKErrorCode_TrimVideo userInfo:userInfo];
        _failback(error);
    }
    [_exportProgress removeFromSuperview];
    _exportProgress = nil;
    [self initPlayer];
}

- (void)cancelExport {
    [_videoCoreSDK cancelExportMovie:^{
        [_exportProgress removeFromSuperview];
        _exportProgress = nil;
        [self initPlayer];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    [thumbVideoCore stop];
    thumbVideoCore = nil;
    [_videoSlider.imageGenerator cancelAllCGImageGeneration];
    if(  !isCoreStop )
    {
        [_videoCoreSDK stop];
        [_videoCoreSDK.view removeFromSuperview];
        _videoCoreSDK.delegate = nil;
        _videoCoreSDK = nil;
    }
    NSLog(@"%s",__func__);
}

//AE 图片素材编辑
#pragma mark- 图片素材 滤镜
- (UIView *)filterView{
    if(!_filterView){
        
        _filtersName = [@[@"原始",@"黑白",@"香草",@"香水",@"香檀",@"飞花",@"颜如玉",@"韶华",@"露丝",@"霓裳",@"雨后"] mutableCopy];
        
        _filterView = [UIView new];
        _filterView.frame = CGRectMake(0, (100 - (kHEIGHT - kPlayerViewOriginX - kPlayerViewHeight - kToolbarHeight - _videoSlider.frame.size.height))/2.0, kWIDTH, kHEIGHT - kPlayerViewOriginX - kPlayerViewHeight - kToolbarHeight - _videoSlider.frame.size.height );
        _filterView.backgroundColor = TOOLBAR_COLOR;
        _filterChildsView           = [UIScrollView new];
        
        float height =  85;
//        if( height > 100 )
//        {
//            height = 100;
            _filterView.frame = CGRectMake(0, 0, kWIDTH, height);
//        }
//
//        if( height < 100 )
//        {
//            _filterView.frame = CGRectMake(0, 0, kWIDTH, _filterView.frame.size.height-50);
//            _filterChildsView.frame     = CGRectMake(0, (iPhone_X ? 0 : 15) + (_filterView.bounds.size.height - 70 )/2.0, _filterView.frame.size.width, height );
//        }
//        else
//        {
            _filterChildsView.frame     = CGRectMake(0, ( _filterView.bounds.size.height - height)/2.0, _filterView.frame.size.width, height );
//        }

        _filterChildsView.backgroundColor                   = [UIColor clearColor];
        _filterChildsView.showsHorizontalScrollIndicator    = NO;
        _filterChildsView.showsVerticalScrollIndicator      = NO;
        [_filterView addSubview:_filterChildsView];
        
        [_globalFilters enumerateObjectsUsingBlock:^(RDFilter*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            ScrollViewChildItem *item   = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(idx*(height - 15)+10, 0, (height - 25), height)];
            item.backgroundColor        = [UIColor clearColor];
            item.fontSize       = 12;
            item.type           = 2;
            item.delegate       = self;
            item.selectedColor  = Main_Color;
            item.normalColor    = UIColorFromRGB(0x888888);
            item.cornerRadius   = item.frame.size.width/2.0;
            item.exclusiveTouch = YES;
            item.itemIconView.backgroundColor   = [UIColor clearColor];
            item.itemTitleLabel.text            = RDLocalizedString(obj.name, nil);
            item.tag                            = idx + 1;
            item.itemTitleLabel.adjustsFontSizeToFitWidth = YES;
            NSString *path = [RDHelpClass pathInCacheDirectory:@"filterImage"];
            if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
            }
            NSString *photoPath     = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"image%@.jpg",obj.name]];
            
            if(idx == 0){
                NSString* bundlePath    = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"VideoRecord.bundle"];
                NSBundle *bundle        = [NSBundle bundleWithPath:bundlePath];
                NSString *filePath      = [bundle pathForResource:[NSString stringWithFormat:@"%@",@"原图"] ofType:@"png"];
                item.itemIconView.image = [UIImage imageWithContentsOfFile:filePath];
            }else
                item.itemIconView.image = [UIImage imageWithContentsOfFile:photoPath];
            
            [self.filterChildsView addSubview:item];
            [item setSelected:(idx == _trimFile.filterIndex ? YES : NO)];
        }];
        
        _filterChildsView.contentSize = CGSizeMake(_globalFilters.count * (self.filterChildsView.frame.size.height - 15)+20, 0);
    }
    return _filterView;
}

#pragma mark - scrollViewChildItemDelegate
- (void)scrollViewChildItemTapCallBlock:(ScrollViewChildItem *)item {
    //滤镜
    __weak typeof(self) myself = self;
    [((ScrollViewChildItem *)[_filterChildsView viewWithTag:_trimFile.filterIndex+1]) setSelected:NO];
    [item setSelected:YES];
    [self refreshFilter:item.tag - 1];
    if(![_videoCoreSDK isPlaying]){
        [_videoCoreSDK filterRefresh:_videoCoreSDK.currentTime];
        //emmet 20171026 修复 “切换滤镜效果视频暂停” bug
//        [self playVideo:YES];
    }
}

- (void)refreshFilter:(NSInteger)filterIndex {
    _trimFile.filterIndex = filterIndex;
    RDFilter* filter = _globalFilters[filterIndex];
    [scenes enumerateObjectsUsingBlock:^(RDScene *  _Nonnull scene, NSUInteger idx1, BOOL * _Nonnull stop1) {
        [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx2, BOOL * _Nonnull stop2) {
            if (filter.type == kRDFilterType_LookUp) {
                asset.filterType = VVAssetFilterLookup;
            }else if (filter.type == kRDFilterType_ACV) {
                asset.filterType = VVAssetFilterACV;
            }else {
                asset.filterType = VVAssetFilterEmpty;
            }
            if (filter.filterPath.length > 0) {
                asset.filterUrl = [NSURL fileURLWithPath:filter.filterPath];
            }
        }];
    }];
}

/**检测有多少个Filter正在下载
 */
- (NSInteger)downLoadingFilterCount{
    __block int count = 0;
    [_filterChildsView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[ScrollViewChildItem class]]){
            if(((ScrollViewChildItem *)obj).downloading){
                count +=1;
            }
        }
    }];
    NSLog(@"dwonloadingFiltersCount:%d",count);
    return count;
}
#pragma makr- 音量
-(void)tapVolumeBackBtn
{
    _trimFile.videoVolume = volumeCount;
    volumeBtn.selected = NO;
    [volumeSlider setValue:volumeCount];
    [_videoCoreSDK setVolume:volumeCount identifier:@"video"];
    volumeView.hidden = YES;
}
@end
