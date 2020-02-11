//
//  RDCompressVideoViewController.m
//  RDVEUISDK
//
//  Created by apple on 2019/7/17.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDCompressVideoViewController.h"
#import "RDSVProgressHUD.h"
#import "RDVECore.h"
#import "RDATMHud.h"
#import "RDExportProgressView.h"
#import "RDZSlider.h"

@interface RDCompressVideoViewController ()<RDVECoreDelegate>
{
    BOOL             isResignActive;    //20171026 wuxiaoxia 导出过程中按Home键后会崩溃
    
    RDVECore                * rdPlayer;
    BOOL                      isContinueExport;
    BOOL                      idleTimerDisabled;
    
    CMTime          startPlayTime;
    
    RDAdvanceEditType            selecteFunction;
    CMTime                        seekTime;
    BOOL                          isNotNeedPlay;
    
    UIScrollView                *addedMaterialEffectScrollView;
    UIImageView                 *selectedMaterialEffectItemIV;
    NSInteger                    selectedMaterialEffectIndex;
    BOOL                         isModifiedMaterialEffect;//是否修改过字幕、贴纸、去水印、画中画、涂鸦
    
    UIView *toolBarView;
    RDVECore        *thumbImageVideoCore;//截取缩率图
    NSMutableArray  *thumbTimes;
    
    UIButton *finishBtn;
    
    CMTime endfendTime;
    
    float   videoFps;
    float   _VideoBitRate;
}
@property (nonatomic, assign)float   currentVideoWidth;
@property (nonatomic, assign)float   currentVideoHeight;
@property (nonatomic, assign)float   currentVideoBitRate;

@property (nonatomic, strong) RDATMHud              * hud;
@property (nonatomic, strong) RDExportProgressView  * exportProgressView;

@property(nonatomic,strong)UIView           *playerView;
@property(nonatomic,strong)UIButton         *playButton;    //播放
@property(nonatomic,strong)UIView           *playerToolBar;
@property(nonatomic,strong)UILabel          *currentTimeLabel;
@property(nonatomic,strong)UILabel          *durationLabel;
@property(nonatomic,strong)UIButton         *zoomButton;
@property(nonatomic,strong)RDZSlider        *videoProgressSlider;

//自定义设置 视频参数
@property(nonatomic,strong)UIScrollView     *videoParameterView;
@property(nonatomic,strong)UILabel          *videoBitRateLabel;
@property(nonatomic,strong)RDZSlider        *videoBitRateSlider;

@property(nonatomic,strong)UIButton         *videoOriginalSizeBtn;
@property(nonatomic,strong)UIButton         *video480PBtn;
@property(nonatomic,strong)UIButton         *video720PBtn;
@property(nonatomic,strong)UIButton         *video1080PBtn;

@property(nonatomic,strong)UIButton         *closeBtn;

@property(nonatomic,strong)UILabel          *compressionFileSizeLabel;
@end

@implementation RDCompressVideoViewController

-(void)setCurrentVideoWidth:(float) currentVideoWidth
{
    _currentVideoWidth = currentVideoWidth;
}
-(void)setCurrentVideoHeight:(float) currentVideoHeight
{
    _currentVideoHeight = currentVideoHeight;
}
-(void)setCurrentVideoBitRate:(float) currentVideoBitRate
{
    _currentVideoBitRate = currentVideoBitRate;
    float fileSize = ( 128.0/1024.0 + _currentVideoBitRate )*rdPlayer.duration/8;
    _compressionFileSizeLabel.text = [NSString stringWithFormat:RDLocalizedString(@"压缩后大小:%.2fMB", nil),fileSize];
}

- (void)applicationEnterHome:(NSNotification *)notification{
    isResignActive = YES;
    if(_exportProgressView && [notification.name isEqualToString:UIApplicationDidEnterBackgroundNotification]){
        __block typeof(self) myself = self;
        [rdPlayer cancelExportMovie:^{
            //更新UI需在主线程中操作
            dispatch_async(dispatch_get_main_queue(), ^{
                [myself.exportProgressView removeFromSuperview];
                myself.exportProgressView = nil;
            });
        }];
    }
}

- (void)appEnterForegroundNotification:(NSNotification *)notification{
    isResignActive = NO;
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
- (void)applicationDidReceiveMemoryWarningNotification:(NSNotification *)notification{
    NSLog(@"内存占用过高");
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [[UIApplication sharedApplication] setIdleTimerDisabled:idleTimerDisabled];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [rdPlayer stop];
    [rdPlayer.view removeFromSuperview];
    rdPlayer.delegate = nil;
    rdPlayer = nil;
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveMemoryWarningNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    if( !rdPlayer )
        [self initPlayer];
    
    if( !_videoParameterView )
        [self.view addSubview:self.videoParameterView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = iPhone4s;
    [[UIApplication sharedApplication] setStatusBarHidden:!iPhone_X];
    
    [self.view addSubview:self.playerView];
    [self initToolBarView];
    [self.view addSubview:self.playerToolBar];
    [self initPlayer];
}
- (void)initToolBarView{
    toolBarView = [[UIView alloc] initWithFrame:CGRectMake(0, kPlayerViewOriginX, kWIDTH, 44)];
    toolBarView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:toolBarView];
    
    UILabel * titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
    titleLbl.text = RDLocalizedString(@"视频压缩", nil);
    titleLbl.textColor = [UIColor whiteColor];
    titleLbl.font = [UIFont boldSystemFontOfSize:20.0];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    [toolBarView addSubview:titleLbl];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(0, 0, 44, 44);
    [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_返回默认_"] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:cancelBtn];
    
    finishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    finishBtn.frame = CGRectMake(kWIDTH - 64, 0, 64, 44);
    finishBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    
    [finishBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [finishBtn setTitleColor:Main_Color forState:UIControlStateNormal];
    [finishBtn setTitle:RDLocalizedString(@"导出",nil) forState:UIControlStateNormal];
    [finishBtn addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:finishBtn];
}

/**播放器
 */
- (UIView *)playerView{
    if(!_playerView){
        _playerView = [UIView new];
        _playerView.frame = CGRectMake(0, kNavigationBarHeight, kWIDTH, kPlayerViewHeight);
        _playerView.backgroundColor = [UIColor blackColor];
        [_playerView addSubview:[self playButton]];
    }
    return _playerView;
}
#pragma mark- 播放器
/**播放暂停按键
 */
- (UIButton *)playButton{
    if(!_playButton){
        _playButton = [UIButton new];
        _playButton.backgroundColor = [UIColor clearColor];
        _playButton.frame = CGRectMake((_playerView.frame.size.width - 56)/2.0, (_playerView.frame.size.height - 56)/2.0, 56, 56);
        [_playButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [_playButton addTarget:self action:@selector(tapPlayButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playButton;
}
- (UIView *)playerToolBar{
    if(!_playerToolBar){
        _playerToolBar = [[UIView alloc] initWithFrame:CGRectMake(0, _playerView.frame.origin.y + _playerView.bounds.size.height - 44, _playerView.frame.size.width, 44)];
        [_playerToolBar addSubview:self.currentTimeLabel];
        [_playerToolBar addSubview:self.durationLabel];
        [_playerToolBar addSubview:self.videoProgressSlider];
        [_playerToolBar addSubview:self.zoomButton];
    }
    return _playerToolBar;
}

- (UILabel *)durationLabel{
    if(!_durationLabel){
        _durationLabel = [[UILabel alloc] init];
        _durationLabel.frame = CGRectMake(_playerToolBar.frame.size.width - 60 - 50, (_playerToolBar.frame.size.height - 20)/2.0, 60, 20);
        _durationLabel.textAlignment = NSTextAlignmentCenter;
        _durationLabel.textColor = [UIColor whiteColor];
        if( iPhone4s )
            _durationLabel.font  = [UIFont systemFontOfSize:10];
        else
            _durationLabel.font = [UIFont systemFontOfSize:12];
    }
    return _durationLabel;
}

- (UILabel *)currentTimeLabel{
    if(!_currentTimeLabel){
        _currentTimeLabel = [[UILabel alloc] init];
        _currentTimeLabel.frame = CGRectMake(5, (_playerToolBar.frame.size.height - 20)/2.0,60, 20);
        _currentTimeLabel.textAlignment = NSTextAlignmentLeft;
        _currentTimeLabel.textColor = [UIColor whiteColor];
        if( iPhone4s )
            _currentTimeLabel.font  = [UIFont systemFontOfSize:10];
        else
            _currentTimeLabel.font = [UIFont systemFontOfSize:12];
    }
    return _currentTimeLabel;
}

- (UIButton *)zoomButton{
    if(!_zoomButton){
        _zoomButton = [UIButton new];
        _zoomButton.backgroundColor = [UIColor clearColor];
        _zoomButton.frame = CGRectMake(_playerToolBar.frame.size.width - 50, (_playerToolBar.frame.size.height - 44)/2.0, 44, 44);
        [_zoomButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/jiequ/剪辑-截取_全屏默认_"] forState:UIControlStateNormal];
        [_zoomButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/jiequ/剪辑-截取_缩小默认_"] forState:UIControlStateSelected];
        [_zoomButton addTarget:self action:@selector(tapzoomButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _zoomButton;
}
//是否全屏
- (void)tapzoomButton{
    _zoomButton.selected = !_zoomButton.selected;
    if(_zoomButton.selected){
        [self.view bringSubviewToFront:_playerView];
        [_playerToolBar removeFromSuperview];
        [self.view insertSubview:_playerToolBar aboveSubview:_playerView];
        //放大
        CGRect videoThumbnailFrame = CGRectZero;
        CGRect playerFrame = CGRectZero;
        _playerView.transform = CGAffineTransformIdentity;
        if(_exportSize.width>_exportSize.height){
            _playerView.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(90));
            videoThumbnailFrame = [_playerView frame];
            videoThumbnailFrame.origin.x=0;
            videoThumbnailFrame.origin.y=0;
            videoThumbnailFrame.size.height = kHEIGHT;
            videoThumbnailFrame.size.width  = kWIDTH;
            playerFrame = videoThumbnailFrame;
            playerFrame.origin.x=0;
            playerFrame.origin.y=0;
            playerFrame.size.width = kHEIGHT;
            playerFrame.size.height  = kWIDTH;
            _playerToolBar.transform = _playerView.transform;
            _playerToolBar.frame = CGRectMake(0, 0, 44, playerFrame.size.width);
            _currentTimeLabel.frame = CGRectMake(5, (_playerToolBar.frame.size.width - 20)/2.0, 60, 20);
            _videoProgressSlider.frame = CGRectMake(60, (_playerToolBar.frame.size.width - 30)/2.0, _playerToolBar.frame.size.height - 60 - 60 - 50, 30);
            _durationLabel.frame = CGRectMake(_playerToolBar.frame.size.height - 60 - 50, (_playerToolBar.frame.size.width - 20)/2.0, 60, 20);
            _zoomButton.frame = CGRectMake(_playerToolBar.frame.size.height - 50, 0, 44, 44);
        }else{
            _playerView.transform = CGAffineTransformIdentity;
            videoThumbnailFrame = [_playerView frame];
            videoThumbnailFrame.origin.x=0;
            videoThumbnailFrame.origin.y=0;
            videoThumbnailFrame.size.height = kHEIGHT;
            videoThumbnailFrame.size.width  = kWIDTH;
            playerFrame = videoThumbnailFrame;
            _playerToolBar.transform = _playerView.transform;
            _playerToolBar.frame = CGRectMake(0, playerFrame.size.height - (iPhone_X ? 78 : 44), playerFrame.size.width, (iPhone_X ? 78 : 44));
            _currentTimeLabel.frame = CGRectMake(5, (_playerToolBar.frame.size.height - 20)/2.0,60, 20);
            _videoProgressSlider.frame = CGRectMake(60, (_playerToolBar.frame.size.height - 30)/2.0, _playerToolBar.frame.size.width - 60 - 60 - 50, 30);
            _durationLabel.frame = CGRectMake(_playerToolBar.frame.size.width - 60 - 50, (_playerToolBar.frame.size.height - 20)/2.0, 60, 20);
            _zoomButton.frame = CGRectMake(_playerToolBar.frame.size.width - 50, (_playerToolBar.frame.size.height - 44)/2.0, 44, 44);
        }
        if (iPhone_X) {
            rdPlayer.fillMode = kRDViewFillModeScaleAspectFill;
        }
        [_playerView setFrame:videoThumbnailFrame];
        
        rdPlayer.frame = playerFrame;
        _playButton.frame = CGRectMake((playerFrame.size.width - 44.0)/2.0, (playerFrame.size.height - 44)/2.0, 44, 44);
        if(![rdPlayer isPlaying]){
            if (CMTimeGetSeconds(CMTimeAdd(rdPlayer.currentTime, CMTimeMake(2, kEXPORTFPS))) > rdPlayer.duration) {
                [rdPlayer seekToTime:CMTimeSubtract(rdPlayer.currentTime, CMTimeMake(2, kEXPORTFPS))];
            }else {
                [rdPlayer seekToTime:CMTimeAdd(rdPlayer.currentTime, CMTimeMake(2, kEXPORTFPS))];
            }
        }
    }else{
        if (iPhone_X) {
            rdPlayer.fillMode = kRDViewFillModeScaleAspectFit;
        }
        [_playerToolBar removeFromSuperview];
        [self.view insertSubview:_playerToolBar aboveSubview:_playerView];
        //缩小
        _playerView.transform = CGAffineTransformIdentity;
        _playerToolBar.transform = _playerView.transform;
        if (((RDNavigationViewController *)self.navigationController).isSingleFunc) {
            [_playerView setFrame:CGRectMake(0, kNavigationBarHeight, kWIDTH, kPlayerViewHeight)];
        }else {
            [_playerView setFrame:CGRectMake(0, kPlayerViewOriginX, kWIDTH, kPlayerViewHeight)];
        }
        rdPlayer.frame = _playerView.bounds;
        _playButton.frame = CGRectMake((_playerView.frame.size.width - 44.0)/2.0, (_playerView.frame.size.height - 44)/2.0, 44, 44);
        _playerToolBar.frame = CGRectMake(0, _playerView.frame.origin.y + _playerView.frame.size.height - 44, _playerView.frame.size.width, 44);
        _currentTimeLabel.frame = CGRectMake(5, (_playerToolBar.frame.size.height - 20)/2.0,60, 20);
        _videoProgressSlider.frame = CGRectMake(60, (_playerToolBar.frame.size.height - 30)/2.0, _playerToolBar.frame.size.width - 60 - 60 - 50, 30);
        _durationLabel.frame = CGRectMake(_playerToolBar.frame.size.width - 60 - 50, _playerToolBar.frame.size.height - 30, 60, 20);
        _zoomButton.frame = CGRectMake(_playerToolBar.frame.size.width - 50, (_playerToolBar.frame.size.height - 44)/2.0, 44, 44);
        if(![rdPlayer isPlaying]){
            if (CMTimeGetSeconds(CMTimeSubtract(rdPlayer.currentTime, CMTimeMake(2, kEXPORTFPS))) >= 0.0) {
                [rdPlayer seekToTime:CMTimeSubtract(rdPlayer.currentTime, CMTimeMake(2, kEXPORTFPS))];
            }else {
                [rdPlayer seekToTime:CMTimeAdd(rdPlayer.currentTime, CMTimeMake(2, kEXPORTFPS))];
            }
        }
    }
}

//进度条
- (RDZSlider *)videoProgressSlider{
    if(!_videoProgressSlider){
        _videoProgressSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(60, (_playerToolBar.frame.size.height - 30)/2.0, _playerToolBar.frame.size.width - 60 - 60 - 50, 30)];
        _videoProgressSlider.backgroundColor = [UIColor clearColor];
        [_videoProgressSlider setMaximumValue:1];
        [_videoProgressSlider setMinimumValue:0];
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        _videoProgressSlider.layer.cornerRadius = 2.0;
        _videoProgressSlider.layer.masksToBounds = YES;
        image = [image imageWithTintColor];
        [_videoProgressSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_videoProgressSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [_videoProgressSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
        [_videoProgressSlider setValue:0];
        [_videoProgressSlider addTarget:self action:@selector(beginScrub:) forControlEvents:UIControlEventTouchDown];
        [_videoProgressSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        [_videoProgressSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchUpInside];
        [_videoProgressSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchCancel];
    }
    return _videoProgressSlider;
}
//MARK: 滑动进度条
/**开始滑动
 */
- (void)beginScrub:(RDZSlider *)slider{
    if( slider == _videoProgressSlider )
    {
        if([rdPlayer isPlaying]){
            [self playVideo:NO];
        }
    }else if(  slider == _videoBitRateSlider  )
    {
        self.currentVideoBitRate = _videoBitRateSlider.value;
        _videoBitRateLabel.text = [NSString stringWithFormat:@"%.2fM",_currentVideoBitRate];
    }
}
/**正在滑动
 */
- (void)scrub:(RDZSlider *)slider{
    if( slider == _videoProgressSlider )
    {
        CGFloat current = _videoProgressSlider.value*rdPlayer.duration;
        [rdPlayer seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
        self.currentTimeLabel.text = [RDHelpClass timeToStringFormat:current];
    }else if(  slider == _videoBitRateSlider  )
    {
        self.currentVideoBitRate = _videoBitRateSlider.value;
        _videoBitRateLabel.text = [NSString stringWithFormat:@"%.2fM",_currentVideoBitRate];
    }
}
/**滑动结束
 */
- (void)endScrub:(RDZSlider *)slider{
    if( slider == _videoProgressSlider )
    {
        CGFloat current = _videoProgressSlider.value*rdPlayer.duration;
        [rdPlayer seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
    }else if(  slider == _videoBitRateSlider  )
    {
        self.currentVideoBitRate = _videoBitRateSlider.value;
        _videoBitRateLabel.text = [NSString stringWithFormat:@"%.2fM",_currentVideoBitRate];
    }
}
/**点击播放暂停按键
 */
- (void)tapPlayButton{
    [self playVideo:![rdPlayer isPlaying]];
}

- (void)playerToolbarShow{
    self.playerToolBar.hidden = NO;
    self.playButton.hidden = NO;
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerToolbarHidden) object:nil];
    [self performSelector:@selector(playerToolbarHidden) withObject:nil afterDelay:2];
}

- (void)playerToolbarHidden{
    [UIView animateWithDuration:0.25 animations:^{
        self.playButton.hidden = YES;
    }];
}

- (void)playVideo:(BOOL)play{
    if(!play){
#if 1
        [rdPlayer pause];
#else
        if([rdPlayer isPlaying]){//不加这个判断，否则疯狂切换音乐在低配机器上有可能反应不过来
            [rdPlayer pause];
        }
#endif
        [_playButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
        _playButton.hidden = NO;
        [self playerToolbarShow];
        
    }else{
        if (rdPlayer.status != kRDVECoreStatusReadyToPlay || isResignActive) {
            return;
        }
#if 1
        [rdPlayer play];
#else
        if(![rdPlayer isPlaying]){//不加这个判断，否则疯狂切换音乐在低配机器上有可能反应不过来
            [rdPlayer play];
        }
#endif
        [_playButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_暂停_@3x" Type:@"png"]] forState:UIControlStateNormal];
        _playButton.hidden = YES;
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerToolbarHidden) object:nil];
        [self performSelector:@selector(playerToolbarHidden) withObject:nil afterDelay:2];
        
    }
}

- (NSDictionary *) getVideoInformation
{
    AVURLAsset *urlAsset = [AVURLAsset assetWithURL:_file.contentURL];
    
    AVAssetTrack *videoTrack = nil;
    
    NSArray *videoTracks = [urlAsset tracksWithMediaType:AVMediaTypeVideo];
    

    if ([videoTracks count] > 0)
        videoTrack = [videoTracks objectAtIndex:0];
    
    CGSize trackDimensions = CGSizeApplyAffineTransform(videoTrack.naturalSize, videoTrack.preferredTransform);
    if (CGSizeEqualToSize(trackDimensions, CGSizeZero) || trackDimensions.width == 0.0 || trackDimensions.height == 0.0) {
        NSArray * formatDescriptions = [videoTrack formatDescriptions];
        CMFormatDescriptionRef formatDescription = NULL;
        if ([formatDescriptions count] > 0) {
            formatDescription = (__bridge CMFormatDescriptionRef)[formatDescriptions objectAtIndex:0];
            if (formatDescription) {
                trackDimensions = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, false, false);
            }
        }
    }
    
    int width = trackDimensions.width;
    int height = trackDimensions.height;
    
    float frameRate = [videoTrack nominalFrameRate];
    float bps = [videoTrack estimatedDataRate];
    
    return @{
             @"width":@(width),
             @"height":@(height),
             @"fps":@(frameRate),
             @"bitrate":@(bps)};
    
}

#pragma mark- 播放器初始化
- (void)initPlayer {
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
    NSString *exportOutPath = _outputPath.length>0 ? _outputPath : [RDHelpClass pathAssetVideoForURL:_file.contentURL];
    unlink([exportOutPath UTF8String]);
    [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
    
    if (CGSizeEqualToSize(_exportSize, CGSizeZero)) {
        NSDictionary* information = [self getVideoInformation];
        _exportSize = CGSizeMake([[information objectForKey:@"width"] intValue], [[information objectForKey:@"height"] intValue]);
        videoFps = [[information objectForKey:@"fps"] floatValue];
        self.currentVideoBitRate = [[information objectForKey:@"bitrate"] floatValue]/1000000.0;
        _currentVideoWidth = _exportSize.width;
        _currentVideoHeight = _exportSize.height;
        _VideoBitRate = self.currentVideoBitRate;
    }
    
    rdPlayer = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                      APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                     LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                      videoSize:_exportSize
                                            fps:videoFps
                                     resultFail:^(NSError *error) {
                                         NSLog(@"initSDKError:%@", error.localizedDescription);
                                     }];
    rdPlayer.frame = CGRectMake(0, 0, _playerView.frame.size.width, _playerView.frame.size.height);
    rdPlayer.delegate = self;
    [_playerView addSubview:rdPlayer.view];
    [self refreshRdPlayer:rdPlayer];
    [_playerView addSubview:[self playButton]];
}

- (void)refreshRdPlayer:(RDVECore *)Player {
    VVAsset *vvAsset = nil;
    vvAsset = [VVAsset new];
    vvAsset.url = _file.contentURL;
    if(_file.fileType == kFILEVIDEO){
        vvAsset.type = RDAssetTypeVideo;
        if (CMTimeRangeEqual(kCMTimeRangeZero, _file.videoTimeRange)) {
            vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, _file.videoDurationTime);
        }else{
            vvAsset.timeRange = _file.videoTimeRange;
        }
        if(!CMTimeRangeEqual(kCMTimeRangeZero, _file.videoTrimTimeRange) && CMTimeCompare(vvAsset.timeRange.duration, _file.videoTrimTimeRange.duration) == 1){
            vvAsset.timeRange = _file.videoTrimTimeRange;
        }
    }else {
        vvAsset.type = RDAssetTypeImage;
        vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, _file.imageDurationTime);
    }
    vvAsset.crop = _file.crop;
    vvAsset.volume = _file.videoVolume;
    RDScene * scene = [[RDScene alloc] init];
   scene .vvAsset = [NSMutableArray arrayWithObject:vvAsset];
    NSMutableArray<RDScene *> * scenes = [NSMutableArray new];
    [scenes addObject:scene];
    [Player setScenes:scenes];
    [Player build];
    
    _durationLabel.text = [RDHelpClass timeToStringFormat:rdPlayer.duration];
    _currentTimeLabel.text = [RDHelpClass timeToStringFormat:0.0];
    float fileSize = ( 128.0/1024.0 + _currentVideoBitRate )*rdPlayer.duration/8;
}


#pragma mark- RDVECoreDelegate
- (void)statusChanged:(RDVECore *)sender status:(RDVECoreStatus)status {
    if (status == kRDVECoreStatusReadyToPlay) {
        [RDSVProgressHUD dismiss];
        if (CMTimeCompare(seekTime, kCMTimeZero) == 0) {
            [self playVideo:YES];
        }else {
            CMTime time = seekTime;
            seekTime = kCMTimeZero;
            __weak typeof(self) weakSelf = self;
            [rdPlayer seekToTime:time toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
                [weakSelf playVideo:YES];
            }];
        }
    }
}
/**更新播放进度条
 */
- (void)progress:(RDVECore *)sender currentTime:(CMTime)currentTime{
    if(sender == rdPlayer){
        if([rdPlayer isPlaying]){
            self.currentTimeLabel.text = [RDHelpClass timeToStringFormat:MIN(CMTimeGetSeconds(currentTime), rdPlayer.duration)];
            float progress = CMTimeGetSeconds(currentTime)/rdPlayer.duration;
            [_videoProgressSlider setValue:progress];
        }
    }
}

- (void)progressCurrentTime:(CMTime)currentTime customDrawLayer:(CALayer *)customDrawLayer {
}

- (void)playToEnd{
    [self playVideo:NO];
    [rdPlayer seekToTime:kCMTimeZero toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
    [_videoProgressSlider setValue:0];
}

- (void)tapPlayerView{
    self.playButton.hidden = !self.playButton.hidden;
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
       && rdPlayer.duration > ((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration){
        
        NSString *maxTime = [RDHelpClass timeToStringNoSecFormat:((float )((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration)];
        NSString *message = [NSString stringWithFormat:RDLocalizedString(@"当前时长超过了导入时长限制%@秒",nil),maxTime];
        [self.hud setCaption:message];
        [self.hud show];
        [self.hud hideAfter:2];
        return;
    }
    if(!isContinueExport && ((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration > 0
       && rdPlayer.duration > ((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration){
        
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
    [rdPlayer stop];
    
    if(self.exportProgressView.superview){
        [self.exportProgressView removeFromSuperview];
    }
    [self.view addSubview:self.exportProgressView];
    
    [RDGenSpecialEffect addWatermarkToVideoCoreSDK:rdPlayer totalDration:rdPlayer.duration exportSize:_exportSize exportConfig:((RDNavigationViewController *)self.navigationController).exportConfiguration];
    
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
    [rdPlayer exportMovieURL:[NSURL fileURLWithPath:export]
                        size:CGSizeMake(_currentVideoWidth, _currentVideoHeight)
                     bitrate:_currentVideoBitRate
                         fps:videoFps
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
    [rdPlayer removeWaterMark];
    [rdPlayer removeEndLogoMark];
    [rdPlayer filterRefresh:kCMTimeZero];
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
    
    [rdPlayer stop];
    rdPlayer.delegate = nil;
    [rdPlayer.view removeFromSuperview];
    rdPlayer = nil;
    
    [self dismissViewControllerAnimated:YES completion:^{
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
                [rdPlayer cancelExportMovie:nil];
            }
            break;
        default:
            break;
    }
}

#pragma mark - 按钮事件
- (void)save{
    if([rdPlayer isPlaying]){
        [self playVideo:NO];
    }
    [self exportMovie];
}

- (void)back{
    if([rdPlayer isPlaying]){
        [self playVideo:NO];
    }
    
    [self dismissViewControllerAnimated:YES completion:^{
        if(((RDNavigationViewController *)self.navigationController).cancelHandler){
            ((RDNavigationViewController *)self.navigationController).cancelHandler();
        }
    }];
}
#pragma mark- 设置视频
-(UIScrollView *)videoParameterView
{
    if( !_videoParameterView )
    {
        _videoParameterView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, kNavigationBarHeight + kPlayerViewHeight, kWIDTH, kHEIGHT - kNavigationBarHeight - kPlayerViewHeight - (iPhone_X ? 34 : 0))];
        _videoParameterView.backgroundColor = BOTTOM_COLOR;
        
        UILabel *fileLbl = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 150, 20)];
        fileLbl.text = RDLocalizedString(@"原始属性:", nil);
        fileLbl.textColor = [UIColor whiteColor];
        fileLbl.font = [UIFont systemFontOfSize:14];
        [_videoParameterView addSubview:fileLbl];
        
        float width = (kWIDTH - 15 - 70)/3.0;
        UILabel *resolutionLbl = [[UILabel alloc] initWithFrame:CGRectMake(70, 30, width + 10, 20)];
        resolutionLbl.text = [NSString stringWithFormat:RDLocalizedString(@"分辨率:%dx%d", nil), (int)_exportSize.width,(int)_exportSize.height];
        resolutionLbl.textAlignment = NSTextAlignmentCenter;
        resolutionLbl.textColor = [UIColor whiteColor];
        resolutionLbl.font = [UIFont systemFontOfSize:(iPhone4s ? 10 : 12)];
        [_videoParameterView addSubview:resolutionLbl];
        
        UILabel *fileBitrateLbl = [[UILabel alloc] initWithFrame:CGRectMake(80 + width, resolutionLbl.frame.origin.y, width, 20)];
        fileBitrateLbl.text = [NSString stringWithFormat:RDLocalizedString(@"码率:%.2fMbps", nil), _VideoBitRate];
        fileBitrateLbl.textAlignment = NSTextAlignmentCenter;
        fileBitrateLbl.textColor = [UIColor whiteColor];
        fileBitrateLbl.font = [UIFont systemFontOfSize:(iPhone4s ? 10 : 12)];
        [_videoParameterView addSubview:fileBitrateLbl];
        
        UILabel *fileSizeLbl = [[UILabel alloc] initWithFrame:CGRectMake(80 + width*2.0, resolutionLbl.frame.origin.y, width, 20)];
        fileSizeLbl.text = [NSString stringWithFormat:RDLocalizedString(@"大小:%.2fMB", nil), ( 128.0/1024.0 + _VideoBitRate )*rdPlayer.duration/8];
        fileSizeLbl.textAlignment = NSTextAlignmentCenter;
        fileSizeLbl.textColor = [UIColor whiteColor];
        fileSizeLbl.font = [UIFont systemFontOfSize:(iPhone4s ? 10 : 12)];
        [_videoParameterView addSubview:fileSizeLbl];
        
        UILabel *compressionLbl = [[UILabel alloc] initWithFrame:CGRectMake(15, 60, 150, 20)];
        compressionLbl.text = RDLocalizedString(@"压缩设置:", nil);
        compressionLbl.textColor = [UIColor whiteColor];
        compressionLbl.font = [UIFont systemFontOfSize:14];
        [_videoParameterView addSubview:compressionLbl];
        
        _compressionFileSizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(kWIDTH - 215, 60, 200, 20)];
        float fileSize = ( 128.0/1024.0 + _currentVideoBitRate )*rdPlayer.duration/8;
        _compressionFileSizeLabel.text = [NSString stringWithFormat:RDLocalizedString(@"压缩后大小:%.2fMB", nil),fileSize];
        _compressionFileSizeLabel.textAlignment = NSTextAlignmentRight;
        _compressionFileSizeLabel.textColor = [UIColor whiteColor];
        _compressionFileSizeLabel.font  = [UIFont systemFontOfSize:(iPhone4s ? 10 : 12)];
        [_videoParameterView addSubview:_compressionFileSizeLabel];
        
        [_videoParameterView addSubview:self.videoBitRateSlider];
        [_videoParameterView addSubview:self.videoOriginalSizeBtn];
        [_videoParameterView addSubview:self.video480PBtn];
        [_videoParameterView addSubview:self.video720PBtn];
        [_videoParameterView addSubview:self.video1080PBtn];
        _videoParameterView.contentSize = CGSizeMake(0, _video1080PBtn.frame.origin.y + _video1080PBtn.frame.size.height + 10);
    }
    return _videoParameterView;
}
//进度条
- (RDZSlider *)videoBitRateSlider{
    if(!_videoBitRateSlider){
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(15, _compressionFileSizeLabel.frame.origin.y + _compressionFileSizeLabel.frame.size.height + (iPhone4s ? 0 : 10), 60, 30)];
        label.text = RDLocalizedString(@"码率:", nil);
        label.textAlignment = NSTextAlignmentRight;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:(iPhone4s ? 10 : 12)];
        [_videoParameterView addSubview:label];
        
        _videoBitRateSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(label.frame.origin.x + label.frame.size.width, label.frame.origin.y, _videoParameterView.frame.size.width - label.frame.origin.x - label.frame.size.width - 30 - 40, 30)];
        _videoBitRateSlider.backgroundColor = [UIColor clearColor];
        [_videoBitRateSlider setMaximumValue:_VideoBitRate];
        [_videoBitRateSlider setMinimumValue:0];
        [_videoBitRateSlider setValue:_currentVideoBitRate];
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        _videoBitRateSlider.layer.cornerRadius = 2.0;
        _videoBitRateSlider.layer.masksToBounds = YES;
        image = [image imageWithTintColor];
        [_videoBitRateSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_videoBitRateSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [_videoBitRateSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
//        [_videoBitRateSlider setValue:0];
        [_videoBitRateSlider addTarget:self action:@selector(beginScrub:) forControlEvents:UIControlEventTouchDown];
        [_videoBitRateSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        [_videoBitRateSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchUpInside];
        [_videoBitRateSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchCancel];
        
        _videoBitRateLabel = [[UILabel alloc] initWithFrame:CGRectMake(_videoBitRateSlider.frame.size.width + _videoBitRateSlider.frame.origin.x + 5, label.frame.origin.y, 50, 30)];
        _videoBitRateLabel.text = [NSString stringWithFormat:@"%.2fM",_currentVideoBitRate];
        _videoBitRateLabel.textColor = [UIColor whiteColor];
        _videoBitRateLabel.font  = [UIFont systemFontOfSize:(iPhone4s ? 10 : 12)];
        [_videoParameterView addSubview:_videoBitRateLabel];
    }
    return _videoBitRateSlider;
}

-(UIButton *)videoPBtn:(int) tag atStr:(NSString *) str
{
    float width = (kWIDTH - _videoBitRateSlider.frame.origin.x - 15 - 10*4)/4.0;
    
    UIButton *videoPBtn = [[UIButton alloc] initWithFrame:CGRectMake(_videoBitRateSlider.frame.origin.x + 10 + (width+10)*(tag-1), _videoBitRateSlider.frame.origin.y + _videoBitRateSlider.frame.size.height + 10, width, 30)];
    videoPBtn.titleLabel.font  = [UIFont systemFontOfSize:(iPhone4s ? 10 : 12)];
    [videoPBtn setTitle:str forState:UIControlStateNormal];
    [videoPBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [videoPBtn setTitleColor:Main_Color forState:UIControlStateSelected];
    if( tag == 1 )
    {
        videoPBtn.selected = YES;
        videoPBtn.layer.borderColor    = Main_Color.CGColor;
    }
    else
        videoPBtn.layer.borderColor    = [UIColor whiteColor].CGColor;
    
    videoPBtn.tag = tag;
    
    videoPBtn.layer.borderWidth    = 1;
    videoPBtn.layer.cornerRadius   = 3;
    videoPBtn.layer.masksToBounds  = YES;
    videoPBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    [videoPBtn addTarget:self action:@selector(videoP_Btn:) forControlEvents:UIControlEventTouchUpInside];
    return  videoPBtn;
}

-(UIButton *)video480PBtn
{
    if( !_video480PBtn )
    {
        _video480PBtn = [self videoPBtn:2 atStr:@"480P"];
    }
    return _video480PBtn;
}

-(UIButton *)videoOriginalSizeBtn
{
    if( !_videoOriginalSizeBtn )
    {
        UILabel * label1 = [[UILabel alloc] initWithFrame:CGRectMake(0, _videoBitRateSlider.frame.origin.y + _videoBitRateSlider.frame.size.height + 10, 75, 30)];
        label1.text = RDLocalizedString(@"分辨率:", nil);
        label1.textAlignment = NSTextAlignmentRight;
        label1.textColor = [UIColor whiteColor];
        label1.font  = [UIFont systemFontOfSize:(iPhone4s ? 10 : 12)];
        [_videoParameterView addSubview:label1];
        
        _videoOriginalSizeBtn = [self videoPBtn:1 atStr:RDLocalizedString(@"原始", nil)];
    }
    return  _videoOriginalSizeBtn;
    
}
-(UIButton *)video720PBtn
{
    if( !_video720PBtn )
    {
        _video720PBtn = [self videoPBtn:3 atStr:@"720P"];
    }
    return  _video720PBtn;
}
-(UIButton *)video1080PBtn
{
    if( !_video1080PBtn )
    {
        _video1080PBtn = [self videoPBtn:4 atStr:@"1080P"];
    }
    return  _video1080PBtn;
}
-(void)videoP_Btn:(UIButton *) btn
{
    float fheight = 480;
    float fwidth = 640;
    _videoOriginalSizeBtn.selected = NO;
    _video1080PBtn.selected = NO;
    _video720PBtn.selected = NO;
    _video480PBtn.selected = NO;
    _video1080PBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    _video720PBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    _video480PBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    _videoOriginalSizeBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    
    btn.selected = YES;
    btn.layer.borderColor    = Main_Color.CGColor;
    
    float bitRate = 0;
    
    switch (btn.tag) {
        case 1:
        {
            fheight = _exportSize.width;
            fwidth = _exportSize.height;
            bitRate = _VideoBitRate;
        }
            break;
        case 2:
        {
            //480P
            fheight = 480;
            fwidth = 640;
            bitRate = 0.85;
        }
            break;
        case 3:
        {
            //720P
            fheight = 720;
            fwidth = 1280;
            bitRate = 1.8;
        }
            break;
        case 4:
        {
            //1080
            fheight = 1080;
            fwidth = 1920;
            bitRate = 3.0;
        }
            break;
        default:
            break;
    }
    if( btn.tag == 1 )
    {
        _currentVideoWidth = fwidth;
        _currentVideoHeight = fheight;
        return;
    }
        
    if( _exportSize.width > _exportSize.height )
    {
        float width = ( _exportSize.width/_exportSize.height ) * fheight;
//        if( width > fwidth )
//        {
//            float height = ( _exportSize.height/_exportSize.width ) * fwidth;
//            _currentVideoWidth = fwidth;
//            _currentVideoHeight = height;
//        }
//        else{
            _currentVideoWidth = width;
            _currentVideoHeight = fheight;
//        }
    }
    else
    {
        float height = ( _exportSize.height/_exportSize.width ) * fheight;
//        if( height > fwidth )
//        {
//            float width = ( _exportSize.width/_exportSize.height ) * fheight;
//            _currentVideoWidth = width;
//            _currentVideoHeight = fheight;
//        }
//        else{
            _currentVideoWidth = fheight;
            _currentVideoHeight = height;
//        }
    }
    if( _VideoBitRate < bitRate)
    {
        self.currentVideoBitRate = _VideoBitRate;
    }
    else
        self.currentVideoBitRate = bitRate;
    _videoBitRateLabel.text = [NSString stringWithFormat:@"%.2fM",_currentVideoBitRate];
    [_videoBitRateSlider setValue:_currentVideoBitRate];
}

- (void)dealloc {
    NSLog(@"%s", __func__);
}
@end
