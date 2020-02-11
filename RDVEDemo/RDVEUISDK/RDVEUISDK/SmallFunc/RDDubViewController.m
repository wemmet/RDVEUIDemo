//
//  RDDubViewController.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2019/6/26.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDDubViewController.h"
#import "RDSVProgressHUD.h"
#import "RDVECore.h"
#import "RDATMHud.h"
#import "RDExportProgressView.h"
#import "DubbingTrimmerView.h"

@interface RDDubViewController ()<RDVECoreDelegate, UIAlertViewDelegate, DubbingTrimmerDelegate>
{
    RDVECore                            * rdPlayer;
    BOOL                                  isContinueExport;
    BOOL                                  idleTimerDisabled;
    NSMutableArray                      * thumbTimes;
    NSMutableArray<DubbingRangeView *>  * dubbingNewMusicArr;
    NSMutableArray<DubbingRangeView *>  * dubbingMusicArr;
    NSMutableArray<RDMusic *>           * dubbingArr;
    CMTime                                startDubbingTime;
    CMTime                                startPlayTime;
    NSString                            * dubbingCafFilePath;
    NSString                            * dubbingMp3FilePath;
    AVAudioSession                      * session;
    AVAudioRecorder                     * recorder;
    RDVECore                            * thumbImageVideoCore;//截取缩率图
    BOOL                                  isModifiedMaterialEffect;
    float                                 oldVolume;
    float                                 volumeMultipleM;
}
@property (nonatomic, assign) BOOL isAddingMaterialEffect;
@property (nonatomic, assign) BOOL isEdittingMaterialEffect;
@property(nonatomic,strong)UIView               *dubbingView;
@property(nonatomic,strong)UIButton             *dubbingPlayBtn;
@property(nonatomic,strong)DubbingTrimmerView   *dubbingTrimmerView;
@property(nonatomic,strong)UIView               *dubbingVolumeView;
@property(nonatomic,strong)UILabel              *dubbingCurrentTimeLbl;
@property(nonatomic,strong)UISlider             *dubbingVolumeSlider;
@property(nonatomic,strong)UIButton             *dubbingBtn;
@property(nonatomic,strong)UIButton             *deletedDubbingBtn;
@property(nonatomic,strong)UIButton             *reDubbingBtn;
@property(nonatomic,strong)UIButton             *auditionDubbingBtn;
@property (nonatomic, strong) RDATMHud *hud;
@property (nonatomic, strong) RDExportProgressView *exportProgressView;

@end

@implementation RDDubViewController

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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIApplication sharedApplication] setIdleTimerDisabled:idleTimerDisabled];
    
    [rdPlayer stop];
    [rdPlayer.view removeFromSuperview];
    rdPlayer.delegate = nil;
    rdPlayer = nil;
    
    [thumbImageVideoCore stop];
    thumbImageVideoCore.delegate = nil;
    thumbImageVideoCore = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)applicationEnterHome:(NSNotification *)notification{
    if(_exportProgressView){
        __block typeof(self) myself = self;
        [rdPlayer cancelExportMovie:^{
            //更新UI需在主线程中操作
            dispatch_async(dispatch_get_main_queue(), ^{
                [myself.exportProgressView removeFromSuperview];
                myself.exportProgressView = nil;
                [[UIApplication sharedApplication] setIdleTimerDisabled:idleTimerDisabled];
            });
        }];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = iPhone4s;
    [[UIApplication sharedApplication] setStatusBarHidden:!iPhone_X];
    
    volumeMultipleM = 5.0;
    oldVolume = 1.0;
    
    [self initToolBarView];
    [self initPlayer];
    [self.view addSubview:self.dubbingView];
}

- (void)initToolBarView{
    UIView *toolBarView = [[UIView alloc] initWithFrame:CGRectMake(0, kPlayerViewOriginX, kWIDTH, 44)];
    toolBarView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:toolBarView];
    
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
    titleLbl.text = RDLocalizedString(@"配音", nil);
    titleLbl.textColor = [UIColor whiteColor];
    titleLbl.font = [UIFont boldSystemFontOfSize:20.0];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    [toolBarView addSubview:titleLbl];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(0, 0, 44, 44);
    [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_返回默认_"] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:cancelBtn];
    
    UIButton *finishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    finishBtn.frame = CGRectMake(kWIDTH - 64, 0, 64, 44);
    finishBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [finishBtn setTitleColor:Main_Color forState:UIControlStateNormal];
    [finishBtn setTitle:RDLocalizedString(@"导出", nil) forState:UIControlStateNormal];
    [finishBtn addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:finishBtn];
}

- (UIView *)dubbingView{
    if(!_dubbingView){
        _dubbingView = [[UIView alloc] initWithFrame:CGRectMake(0, kNavigationBarHeight + kPlayerViewHeight, kWIDTH, kHEIGHT - kNavigationBarHeight - kPlayerViewHeight - (iPhone_X ? 34 : 0))];
        _dubbingView.backgroundColor = BOTTOM_COLOR;
        
        [_dubbingView addSubview:self.dubbingPlayBtn];
        [_dubbingView addSubview:self.dubbingTrimmerView];
        
        UIView *spanView = [[UIView alloc] initWithFrame:CGRectMake((kWIDTH - 3)/2.0, _dubbingTrimmerView.frame.origin.y-2, 3, 50)];
        spanView.backgroundColor = [UIColor whiteColor];
        spanView.layer.cornerRadius = 1.5;
        [_dubbingView addSubview:spanView];
        
        [_dubbingView addSubview:self.dubbingCurrentTimeLbl];
        [_dubbingView addSubview:self.dubbingBtn];
        [_dubbingView addSubview:self.deletedDubbingBtn];
        [_dubbingView addSubview:self.reDubbingBtn];
        [_dubbingView addSubview:self.auditionDubbingBtn];
        
        if (iPhone4s) {
            CGRect frame = _dubbingCurrentTimeLbl.frame;
            frame.origin.y = 0;
            _dubbingCurrentTimeLbl.frame = frame;
            
            frame = _dubbingTrimmerView.frame;
            frame.origin.y = 15;
            _dubbingTrimmerView.frame = frame;
            
            frame = _dubbingPlayBtn.frame;
            frame.origin.y = 13;
            _dubbingPlayBtn.frame = frame;
            
            frame = spanView.frame;
            frame.origin.y = _dubbingTrimmerView.frame.origin.y-2;
            spanView.frame = frame;
        }
        [self.view addSubview:self.dubbingVolumeView];
    }
    return _dubbingView;
}

/**配音缩率图进度滑块
 */
- (DubbingTrimmerView *)dubbingTrimmerView{
    if(!_dubbingTrimmerView){
        CGRect rect = CGRectMake(67, _dubbingPlayBtn.frame.origin.y - (iPhone4s ? (45 - 44)/2.0 : (50 - 45)/2.0), _dubbingView.bounds.size.width - 67 - 20, 45);
        _dubbingTrimmerView = [[DubbingTrimmerView alloc] initWithFrame:rect videoCore:thumbImageVideoCore];
        _dubbingTrimmerView.backgroundColor = [UIColor clearColor];
        [_dubbingTrimmerView setClipTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(thumbImageVideoCore.duration, TIMESCALE))];
        [_dubbingTrimmerView setThemeColor:[UIColor lightGrayColor]];
        [_dubbingTrimmerView setDelegate:self];
        _dubbingTrimmerView.tag = 3;
        _dubbingTrimmerView.piantouDuration = 0;
        _dubbingTrimmerView.pianweiDuration = 0;
        _dubbingTrimmerView.rightSpace = 20;
        
        thumbTimes = [NSMutableArray array];
        NSInteger num = 0;
        while (num<thumbImageVideoCore.duration) {
            [thumbTimes addObject:@(num)];
            num +=2;
        }
        [thumbTimes addObject:@(thumbImageVideoCore.duration)];
        _dubbingTrimmerView.thumbImageTimes = thumbTimes.count;
        [thumbImageVideoCore getImageAtTime:kCMTimeZero scale:0.3 completion:^(UIImage *image) {
            [_dubbingTrimmerView resetSubviews:image];
        }];
    }
    return _dubbingTrimmerView;
}

/**进入配音界面的播放按键
 */
- (UIButton *)dubbingPlayBtn{
    if(!_dubbingPlayBtn){
        _dubbingPlayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _dubbingPlayBtn.backgroundColor = [UIColor clearColor];
        _dubbingPlayBtn.frame = CGRectMake(5, _dubbingView.bounds.size.height/2.0 - 44, 44, 44);
        [_dubbingPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
        [_dubbingPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateHighlighted];
        [_dubbingPlayBtn addTarget:self action:@selector(tapPlayButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _dubbingPlayBtn;
}

/**配音按键
 */
- (UIButton *)dubbingBtn{
    if(!_dubbingBtn){
        _dubbingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _dubbingBtn.backgroundColor = [UIColor clearColor];
        _dubbingBtn.frame = CGRectMake((kWIDTH - 113)/2.0, _dubbingView.bounds.size.height/2.0 + (_dubbingView.bounds.size.height/2.0 - 35)/2.0, 113, 35);
        _dubbingBtn.layer.borderColor = CUSTOM_GRAYCOLOR.CGColor;
        _dubbingBtn.layer.borderWidth = 1.0;
        _dubbingBtn.layer.cornerRadius = 35/2.0;
        _dubbingBtn.layer.masksToBounds = YES;
        [_dubbingBtn setTitle:RDLocalizedString(@"添加", nil) forState:UIControlStateNormal];
        [_dubbingBtn setTitle:RDLocalizedString(@"完成", nil) forState:UIControlStateSelected];
        [_dubbingBtn setTitleColor:CUSTOM_GRAYCOLOR forState:UIControlStateNormal];
        [_dubbingBtn setTitleColor:CUSTOM_GRAYCOLOR forState:UIControlStateSelected];
        [_dubbingBtn setSelected:NO];
        [_dubbingBtn.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [_dubbingBtn.titleLabel setFont:[UIFont systemFontOfSize:16]];
        [_dubbingBtn addTarget:self action:@selector(touchesDownDubbingBtn) forControlEvents:UIControlEventTouchDown];
    }
    return _dubbingBtn;
}

/**删除配音按键
 */
- (UIButton *)deletedDubbingBtn{
    if(!_deletedDubbingBtn){
        _deletedDubbingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _deletedDubbingBtn.backgroundColor = [UIColor clearColor];
        _deletedDubbingBtn.frame = _dubbingBtn.frame;
        _deletedDubbingBtn.layer.borderColor = CUSTOM_GRAYCOLOR.CGColor;
        _deletedDubbingBtn.layer.borderWidth = 1.0;
        _deletedDubbingBtn.layer.cornerRadius = 35/2.0;
        _deletedDubbingBtn.layer.masksToBounds = YES;
        [_deletedDubbingBtn setTitle:RDLocalizedString(@"删除", nil) forState:UIControlStateNormal];
        [_deletedDubbingBtn setTitleColor:CUSTOM_GRAYCOLOR forState:UIControlStateNormal];
        [_deletedDubbingBtn.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [_deletedDubbingBtn.titleLabel setFont:[UIFont systemFontOfSize:16]];
        [_deletedDubbingBtn addTarget:self action:@selector(deleteBtnAction) forControlEvents:UIControlEventTouchDown];
        _deletedDubbingBtn.hidden = YES;
    }
    return _deletedDubbingBtn;
}

/**重新配音按键
 */
- (UIButton *)reDubbingBtn{
    if(!_reDubbingBtn){
        _reDubbingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _reDubbingBtn.backgroundColor = [UIColor clearColor];
        _reDubbingBtn.frame = CGRectMake(_dubbingBtn.frame.origin.x - 24 - 65, _dubbingBtn.frame.origin.y + (35 - 27)/2.0, 65, 27);
        _reDubbingBtn.layer.borderColor = UIColorFromRGB(0xb2b2b2).CGColor;
        _reDubbingBtn.layer.borderWidth = 1.0;
        _reDubbingBtn.layer.cornerRadius = _reDubbingBtn.bounds.size.height/2.0;
        _reDubbingBtn.layer.masksToBounds = YES;
        [_reDubbingBtn setTitle:RDLocalizedString(@"重配", nil) forState:UIControlStateNormal];
        [_reDubbingBtn setTitleColor:UIColorFromRGB(0xb2b2b2) forState:UIControlStateNormal];
        [_reDubbingBtn.titleLabel setFont:[UIFont systemFontOfSize:14]];
        [_reDubbingBtn addTarget:self action:@selector(reDubbingTouchesUp) forControlEvents:UIControlEventTouchUpInside];
        _reDubbingBtn.hidden = YES;
    }
    return _reDubbingBtn;
}

/**试听配音按键
 */
- (UIButton *)auditionDubbingBtn{
    if(!_auditionDubbingBtn){
        _auditionDubbingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _auditionDubbingBtn.backgroundColor = [UIColor clearColor];
        _auditionDubbingBtn.frame = CGRectMake(_dubbingBtn.frame.origin.x + _dubbingBtn.bounds.size.width + 24, _reDubbingBtn.frame.origin.y, 65, 27);
        _auditionDubbingBtn.layer.borderColor = UIColorFromRGB(0xb2b2b2).CGColor;
        _auditionDubbingBtn.layer.borderWidth = 1.0;
        _auditionDubbingBtn.layer.cornerRadius = _auditionDubbingBtn.bounds.size.height/2.0;
        _auditionDubbingBtn.layer.masksToBounds = YES;
        [_auditionDubbingBtn setTitle:RDLocalizedString(@"试听", nil) forState:UIControlStateNormal];
        [_auditionDubbingBtn setTitleColor:UIColorFromRGB(0xb2b2b2) forState:UIControlStateNormal];
        [_auditionDubbingBtn.titleLabel setFont:[UIFont systemFontOfSize:14]];
        [_auditionDubbingBtn addTarget:self action:@selector(auditionDubbingTouchesUp) forControlEvents:UIControlEventTouchUpInside];
        _auditionDubbingBtn.hidden = YES;
    }
    return _auditionDubbingBtn;
}

/**配音当前时间
 */
- (UILabel *)dubbingCurrentTimeLbl{
    if(!_dubbingCurrentTimeLbl){
        _dubbingCurrentTimeLbl = [[UILabel alloc] initWithFrame:CGRectMake((kWIDTH - 60)/2.0, _dubbingTrimmerView.frame.origin.y - 15 - 8, 60, 15)];
        _dubbingCurrentTimeLbl.textAlignment = NSTextAlignmentCenter;
        _dubbingCurrentTimeLbl.textColor = [UIColor whiteColor];
        _dubbingCurrentTimeLbl.text = @"0.00";
        _dubbingCurrentTimeLbl.font = [UIFont systemFontOfSize:12];
    }
    return _dubbingCurrentTimeLbl;
}

/**配音音量
 */
- (UIView *)dubbingVolumeView{
    if(!_dubbingVolumeView){
        _dubbingVolumeView = [UIView new];
        _dubbingVolumeView.frame = CGRectMake(10, kPlayerViewOriginX + kPlayerViewHeight - 35 - (LastIphone5?0:15), kWIDTH - 20, 35);
        
        _dubbingVolumeSlider = [[UISlider alloc] initWithFrame:CGRectMake(41, 2, _dubbingVolumeView.frame.size.width-82 + 15, 31)];
        _dubbingVolumeSlider.minimumValue = 0;
        _dubbingVolumeSlider.maximumValue = 1;
        _dubbingVolumeSlider.value = 1.0;
        [_dubbingVolumeSlider setMaximumTrackTintColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
        [_dubbingVolumeSlider setMinimumTrackTintColor:[UIColor whiteColor]];
        UIImage *thumbImage = [RDHelpClass rdImageWithColor:Main_Color cornerRadius:9];
        [_dubbingVolumeSlider setThumbImage:thumbImage forState:UIControlStateNormal];
        [_dubbingVolumeSlider addTarget:self action:@selector(dubbingVolumeSliderEndScrub) forControlEvents:UIControlEventTouchUpInside];
        [_dubbingVolumeSlider addTarget:self action:@selector(dubbingVolumeSliderEndScrub) forControlEvents:UIControlEventTouchCancel];
        
        UILabel *peiyueValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
        peiyueValueLabel.textAlignment = NSTextAlignmentCenter;
        peiyueValueLabel.textColor = [UIColor whiteColor];
        peiyueValueLabel.font = [UIFont systemFontOfSize:11];
        peiyueValueLabel.text = RDLocalizedString(@"配音", nil);
        peiyueValueLabel.adjustsFontSizeToFitWidth = YES;
        
        [_dubbingVolumeView addSubview:_dubbingVolumeSlider];
        [_dubbingVolumeView addSubview:peiyueValueLabel];
        
        _dubbingVolumeView.hidden = YES;
    }
    return _dubbingVolumeView;
}

- (void)initPlayer {
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
    NSString *exportOutPath = _outputPath.length>0 ? _outputPath : [RDHelpClass pathAssetVideoForURL:_file.contentURL];
    unlink([exportOutPath UTF8String]);
    [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
    
    if (CGSizeEqualToSize(_exportSize, CGSizeZero)) {
        _exportSize = [RDHelpClass getVideoSizeForTrack:[AVURLAsset assetWithURL:_file.contentURL]];
    }
    
    rdPlayer = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                      APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                     LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                      videoSize:_exportSize
                                            fps:kEXPORTFPS
                                     resultFail:^(NSError *error) {
                                         NSLog(@"initSDKError:%@", error.localizedDescription);
                                     }];
    rdPlayer.frame = CGRectMake(0, kNavigationBarHeight, kWIDTH, kPlayerViewHeight);
    rdPlayer.delegate = self;
    [self.view addSubview:rdPlayer.view];
    
    NSMutableArray *scenes = [NSMutableArray array];
    RDScene *scene = [RDScene new];
    VVAsset *vvAsset = [VVAsset new];
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
    scene.vvAsset = [NSMutableArray arrayWithObject:vvAsset];
    [scenes addObject:scene];
    
    [rdPlayer setScenes:scenes];
    [rdPlayer build];
    
    if(!thumbImageVideoCore){
        thumbImageVideoCore = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                                     APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                                    LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                                     videoSize:_exportSize
                                                           fps:kEXPORTFPS
                                                    resultFail:^(NSError *error) {
                                                        NSLog(@"initSDKError:%@", error.localizedDescription);
                                                    }];
        thumbImageVideoCore.delegate = self;
        [thumbImageVideoCore setScenes:scenes];
        [thumbImageVideoCore build];
    }
}

#pragma mark- RDVECoreDelegate
- (void)statusChanged:(RDVECore *)sender status:(RDVECoreStatus)status {
    if (status == kRDVECoreStatusReadyToPlay) {
        if (sender == rdPlayer) {
            [RDSVProgressHUD dismiss];
        }else {
            [self loadTrimmerViewThumbImage];
        }
    }
}

- (void)progress:(RDVECore *)sender currentTime:(CMTime)currentTime{
    if (sender == rdPlayer && rdPlayer.isPlaying) {
        float progress = CMTimeGetSeconds(currentTime)/rdPlayer.duration;
        if(!_dubbingTrimmerView.videoCore)
            [_dubbingTrimmerView setVideoCore:thumbImageVideoCore];
        [_dubbingTrimmerView setProgress:progress animated:NO];
        if(_isAddingMaterialEffect){
            BOOL suc = [_dubbingTrimmerView changecurrentRangeviewppDubbingFile:CMTimeGetSeconds(CMTimeSubtract(currentTime, startDubbingTime)) volume:_dubbingVolumeSlider.value*volumeMultipleM callBlock:nil];
            if(!suc){
                [self touchesDownDubbingBtn];
                _dubbingBtn.hidden = YES;
                _deletedDubbingBtn.hidden = NO;
                _dubbingVolumeView.hidden = NO;
            }
        }
    }
}

- (void)playToEnd{
    [rdPlayer seekToTime:kCMTimeZero];
    [_dubbingPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
    [_dubbingPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateHighlighted];
    if (_isAddingMaterialEffect) {
        [self touchesDownDubbingBtn];
        _dubbingBtn.hidden = YES;
        _deletedDubbingBtn.hidden = NO;
        _dubbingVolumeView.hidden = NO;
    }
}

- (void)tapPlayerView{
    if (rdPlayer.isPlaying) {
        [rdPlayer pause];
    }else {
        [rdPlayer play];
    }
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
    [self refreshDubbing];
    
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
                        size:_exportSize
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
        case 4:
            if (buttonIndex == 1) {
                [self dismissViewControllerAnimated:YES completion:^{
                    if(((RDNavigationViewController *)self.navigationController).cancelHandler){
                        ((RDNavigationViewController *)self.navigationController).cancelHandler();
                    }
                }];
            }
            break;
        default:
            break;
    }
}

#pragma mark - 按钮事件
- (void)save{
    if(_isAddingMaterialEffect )
    {
        [self touchesDownDubbingBtn];
    }else {
        [self exportMovie];
    }
}

- (void)back{
    if (isModifiedMaterialEffect) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:RDLocalizedString(@"确定放弃所有操作?",nil)
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:RDLocalizedString(@"取消",nil)
                                                  otherButtonTitles:RDLocalizedString(@"确定",nil), nil];
        alertView.tag = 4;
        [alertView show];
        isModifiedMaterialEffect = NO;
    }else {
        [self dismissViewControllerAnimated:YES completion:^{
            if(((RDNavigationViewController *)self.navigationController).cancelHandler){
                ((RDNavigationViewController *)self.navigationController).cancelHandler();
            }
        }];
    }
}

- (void)tapPlayButton{
    [self playVideo:![rdPlayer isPlaying]];
}

- (void)playVideo:(BOOL)play{
    if(!play){
        [rdPlayer pause];
        [_dubbingPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
        [_dubbingPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateHighlighted];
        if (_isAddingMaterialEffect) {
            [self touchesDownDubbingBtn];
        }
    }else{
        if (rdPlayer.status != kRDVECoreStatusReadyToPlay) {
            return;
        }
        [rdPlayer play];
        startPlayTime = rdPlayer.currentTime;
        [_dubbingPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateNormal];
        [_dubbingPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateHighlighted];
    }
}

- (void)reDubbingTouchesUp{
    //MARK:重新配音
    [self playToEnd];
    dubbingNewMusicArr = [_dubbingTrimmerView getTimesFor_videoRangeView];
    for (DubbingRangeView *dubb  in dubbingNewMusicArr) {
        [dubb removeFromSuperview];
    }
    [dubbingArr removeAllObjects];
    
    [_dubbingTrimmerView setProgress:0 animated:NO];
    _deletedDubbingBtn.hidden = YES;
    _reDubbingBtn.hidden = YES;
    _auditionDubbingBtn.hidden = YES;
    _dubbingBtn.hidden = NO;
    _dubbingBtn.enabled = YES;
    _dubbingVolumeView.hidden = YES;
    isModifiedMaterialEffect = YES;
    [self refreshDubbing];
}

#ifdef kRECORDAAC
-(AVAudioRecorder *)recorder{
    //AVAudioRecorder * _audioRecorder;
    if (!recorder) {
        //创建录音文件保存路径
        NSString *fileName = [RDHelpClass createFilename];
        
        dubbingCafFilePath = [[RDHelpClass returnEditorVideoPath] stringByAppendingString:[NSString stringWithFormat:@"/DubbingFile%@.aac",fileName]];
        
        NSURL *url=[NSURL URLWithString:dubbingCafFilePath];
        //创建录音格式设置
        NSDictionary *setting=[self getAudioSetting];
        //创建录音机
        NSError *error=nil;
        recorder=[[AVAudioRecorder alloc]initWithURL:url settings:setting error:&error];
        recorder.meteringEnabled=YES;//如果要监控声波则必须设置为YES
        if (error) {
            NSLog(@"创建录音机对象时发生错误，错误信息：%@",error.localizedDescription);
            return nil;
        }
    }
    return recorder;
}

-(NSDictionary *)getAudioSetting{
    //LinearPCM 是iOS的一种无损编码格式,但是体积较为庞大
    //录音设置
    NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] init];
    //录音格式 无法使用
    [recordSettings setValue :[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey: AVFormatIDKey];
    //采样率
    [recordSettings setValue :[NSNumber numberWithFloat:44100.0] forKey: AVSampleRateKey];//11025.0
    //通道数
    [recordSettings setValue :[NSNumber numberWithInt:2] forKey: AVNumberOfChannelsKey];
    //线性采样位数
    [recordSettings setValue :[NSNumber numberWithInt:16] forKey: AVLinearPCMBitDepthKey];
    //音频质量,采样质量
    [recordSettings setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    
    return recordSettings;
}
#endif

- (void)touchesDownDubbingBtn{
    if( _dubbingBtn.selected )
    {
        //停止配音
        [self touchesUpDubbingBtn];
        [_dubbingBtn setSelected:NO];
        return;
    }
    _reDubbingBtn.hidden = YES;
    _auditionDubbingBtn.hidden = YES;
    [_dubbingBtn setSelected:YES];
    //MARK:开始配音
    NSLog(@"按下配音键");
    [rdPlayer playerMute:YES];
    if(![rdPlayer isPlaying]){
        [self playVideo:YES];
    }
    startDubbingTime = rdPlayer.currentTime;
    if (_dubbingTrimmerView.scrollView.contentOffset.x == 0) {
        startDubbingTime = kCMTimeZero;
    }
    _isAddingMaterialEffect = YES;
    isModifiedMaterialEffect = YES;
#ifdef kRECORDAAC
    
    session = [AVAudioSession sharedInstance];
    //session.description;
    NSError *sessionError;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    
    if(session == nil) {
        NSLog(@"Error creating session: %@", [sessionError description]);
    }else {
        [session setActive:YES error:nil];
    }
    
    [[self recorder] record];
#else
    NSString *fileName = [RDHelpClass createFilename];
    
    dubbingCafFilePath = [[RDHelpClass returnEditorVideoPath] stringByAppendingString:[NSString stringWithFormat:@"/DubbingFile%@",fileName]];
    dubbingMp3FilePath = [[RDHelpClass returnEditorVideoPath] stringByAppendingString:[NSString stringWithFormat:@"/DubbingFile%@.mp3",fileName]];
    
    session = [AVAudioSession sharedInstance];
    //session.description;
    NSError *sessionError;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    
    if(session == nil) {
        NSLog(@"Error creating session: %@", [sessionError description]);
    }else {
        [session setActive:YES error:nil];
    }
    //录音设置
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] init];
    //    //录音格式 无法使用
    [settings setValue :[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey: AVFormatIDKey];
    //采样率
    [settings setValue :[NSNumber numberWithFloat:44100.0] forKey: AVSampleRateKey];//44100.0
    //通道数
    [settings setValue :[NSNumber numberWithInt:2] forKey: AVNumberOfChannelsKey];
    //线性采样位数
    [settings setValue :[NSNumber numberWithInt:16] forKey: AVLinearPCMBitDepthKey];
    //音频质量,采样质量
    [settings setValue:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
    
    NSURL *recordedFile = [[NSURL alloc] initFileURLWithPath:dubbingCafFilePath];
    recorder = [[AVAudioRecorder alloc] initWithURL:recordedFile settings:settings error:nil];
    [recorder prepareToRecord];
    [recorder record];
#endif
    
    [_dubbingTrimmerView addDubbing];
    
}

- (void)touchesUpDubbingBtn{
    if(!_isAddingMaterialEffect){
        return;
    }
    //MARK:结束配音
    [rdPlayer playerMute:NO];
    _isAddingMaterialEffect = NO;
    [self playVideo:NO];
    
    if(recorder)//
    {
        [[self recorder] stop];
        recorder = nil;
        if(!dubbingArr){
            dubbingArr = [NSMutableArray array];
        }
        if(!dubbingNewMusicArr){
            dubbingNewMusicArr = [NSMutableArray array];
        }
        if(!dubbingMusicArr){
            dubbingMusicArr = [NSMutableArray array];
        }
        float dubbingcurrentDuration = CMTimeGetSeconds(rdPlayer.currentTime) - CMTimeGetSeconds(startDubbingTime);
        if(dubbingcurrentDuration<=0){
            dubbingcurrentDuration = rdPlayer.duration - CMTimeGetSeconds(startDubbingTime);
        }
        if(dubbingcurrentDuration !=0 && (rdPlayer.duration < CMTimeGetSeconds(startDubbingTime))){
            [_dubbingTrimmerView changecurrentRangeviewppDubbingFile:dubbingcurrentDuration volume:_dubbingVolumeSlider.value*volumeMultipleM callBlock:nil];
        }
        BOOL suc = [_dubbingTrimmerView savecurrentRangeviewWithMusicPath:dubbingCafFilePath volume:_dubbingVolumeSlider.value*volumeMultipleM dubbingIndex:[[_dubbingTrimmerView getTimesFor_videoRangeView] count]-1 flag:YES];
        if(suc){
            dubbingNewMusicArr = [_dubbingTrimmerView getTimesFor_videoRangeView];
            double duration = CMTimeGetSeconds([dubbingNewMusicArr lastObject].dubbingDuration);
            if(duration<0.2){
                [[dubbingNewMusicArr lastObject] removeFromSuperview];
                [dubbingNewMusicArr removeLastObject];
            }
            [dubbingArr removeAllObjects];
            for (DubbingRangeView *dubb  in dubbingNewMusicArr) {
                if (dubb.musicPath && dubb.musicPath.length > 0) {
                    RDMusic *music = [[RDMusic alloc] init];
                    music.clipTimeRange = CMTimeRangeMake(kCMTimeZero,dubb.dubbingDuration);
                    
                    CMTime start = CMTimeAdd(dubb.dubbingStartTime, CMTimeMake(_dubbingTrimmerView.piantouDuration, TIMESCALE));
                    music.effectiveTimeRange = CMTimeRangeMake(start, music.clipTimeRange.duration);
                    music.url = [NSURL fileURLWithPath:dubb.musicPath];
                    music.volume = dubb.volume;
                    music.isRepeat = NO;
                    [dubbingArr addObject:music];
                }
            }            
        }else{
            [self.hud setCaption:RDLocalizedString(@"时间至少大于0.5秒!", nil)];
            [self.hud show];
            [self.hud hideAfter:2];
            
            [_dubbingPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_播放_"] forState:UIControlStateNormal];
            [_dubbingPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_播放_"] forState:UIControlStateHighlighted];
        }
#if 0
        RdCanAddDubbingType type = [_dubbingTrimmerView checkCanAddDubbing];
        if (type == kCanAddDubbing) {
            _dubbingBtn.enabled = YES;
            _dubbingVolumeView.hidden = YES;
        }else if (type == kCannotAddDubbing) {
            _dubbingBtn.hidden = YES;
            _deletedDubbingBtn.hidden = NO;
            _dubbingVolumeView.hidden = NO;
        }else {
            _dubbingBtn.enabled = NO;
            _dubbingVolumeView.hidden = NO;
        }
#endif
        if (CMTimeGetSeconds(rdPlayer.currentTime) >= rdPlayer.duration) {
            _dubbingBtn.hidden = YES;
            _deletedDubbingBtn.hidden = NO;
            _dubbingVolumeView.hidden = NO;
        }
    }
    _reDubbingBtn.hidden = NO;
    _auditionDubbingBtn.hidden = NO;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
}

- (void)deleteBtnAction{
    //MARK:删除配音
    if ([rdPlayer isPlaying]) {
        [self playVideo:NO];
    }
    [_dubbingTrimmerView deletedcurrentDubbing];
    dubbingNewMusicArr = [_dubbingTrimmerView getTimesFor_videoRangeView];
    [dubbingArr removeAllObjects];
    for (DubbingRangeView *dubb  in dubbingNewMusicArr) {
        RDMusic *music = [[RDMusic alloc] init];
        music.clipTimeRange = CMTimeRangeMake(kCMTimeZero,dubb.dubbingDuration);
        
        CMTime start = CMTimeAdd(dubb.dubbingStartTime, CMTimeMake(_dubbingTrimmerView.piantouDuration, TIMESCALE));
        music.effectiveTimeRange = CMTimeRangeMake(start, music.clipTimeRange.duration);
        music.url = [NSURL fileURLWithPath:dubb.musicPath];
        music.volume = dubb.volume;
        music.isRepeat = NO;
        [dubbingArr addObject:music];
    }
    _deletedDubbingBtn.hidden = YES;
    if (dubbingNewMusicArr.count == 0) {
        _reDubbingBtn.hidden = YES;
        _auditionDubbingBtn.hidden = YES;
    }
    _dubbingBtn.hidden = NO;
    _dubbingVolumeView.hidden = YES;
    [self touchescurrentdubbingView:nil flag:YES];
    isModifiedMaterialEffect = YES;
    [self refreshDubbing];
}

- (void)auditionDubbingTouchesUp{
    //MARK:试听配音
    dubbingNewMusicArr = [_dubbingTrimmerView getTimesFor_videoRangeView];
    [dubbingArr removeAllObjects];
    for (DubbingRangeView *dubb  in dubbingNewMusicArr) {
        RDMusic *music = [[RDMusic alloc] init];
        music.clipTimeRange = CMTimeRangeMake(kCMTimeZero,dubb.dubbingDuration);
        
        CMTime start = CMTimeAdd(dubb.dubbingStartTime, CMTimeMake(_dubbingTrimmerView.piantouDuration, TIMESCALE));
        music.effectiveTimeRange = CMTimeRangeMake(start, music.clipTimeRange.duration);
        music.url = [NSURL fileURLWithPath:dubb.musicPath];
        music.volume = dubb.volume;
        music.isRepeat = NO;
        [dubbingArr addObject:music];
    }
    _dubbingBtn.selected = NO;
    [_dubbingTrimmerView setProgress:0 animated:NO];
    [self refreshDubbing];
}

- (void)refreshDubbing {
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
    [rdPlayer setDubbingMusics:dubbingArr];
    [rdPlayer build];
}

- (void)dubbingVolumeSliderEndScrub {
    [_dubbingTrimmerView changeCurrentVolume:_dubbingVolumeSlider.value*volumeMultipleM];
}

#pragma mark - DubbingTrimViewDelegate
- (void) touchescurrentdubbingView:(DubbingRangeView *)sender flag:(BOOL)flag{
    RdCanAddDubbingType type = [_dubbingTrimmerView checkCanAddDubbing];
    if(type != kCanAddDubbing){
        _dubbingBtn.enabled = NO;
        flag = NO;
    }else{
        _dubbingBtn.enabled = YES;
        flag = YES;
    }
    if(!flag){
        _deletedDubbingBtn.hidden = NO;
        _dubbingBtn.hidden = YES;
        _dubbingVolumeView.hidden = NO;
    }else{
        _deletedDubbingBtn.hidden = YES;
        _dubbingBtn.hidden = NO;
        _dubbingVolumeView.hidden = YES;
    }
}
- (void)dubbingScrollViewWillBegin:(DubbingTrimmerView *)trimmerView{
    if([rdPlayer isPlaying]){
        [self playVideo:NO];
    }
    [_dubbingPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
    [_dubbingPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateHighlighted];
}
- (void)dubbingScrollViewWillEnd:(DubbingTrimmerView *)trimmerView
                       startTime:(Float64)capationStartTime
                         endTime:(Float64)capationEndTime
{
    [rdPlayer seekToTime:CMTimeMakeWithSeconds(capationStartTime, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
}

- (void)trimmerView:(id)trimmerView didChangeLeftPosition:(CGFloat)startTime rightPosition:(CGFloat)endTime{
    if(![rdPlayer isPlaying]){
        WeakSelf(self);
        [rdPlayer seekToTime:CMTimeMakeWithSeconds(startTime, TIMESCALE) toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
            StrongSelf(self);
            float duration = rdPlayer.duration;
            if(CMTimeGetSeconds(strongSelf->startPlayTime)>= CMTimeGetSeconds(CMTimeSubtract(CMTimeMakeWithSeconds(duration, TIMESCALE), CMTimeMakeWithSeconds(0.1, TIMESCALE)))){
                [strongSelf playVideo:YES];
            }
        }];
    }
    self.dubbingCurrentTimeLbl.text = [RDHelpClass timeToSecFormat:startTime];
}

- (void)loadTrimmerViewThumbImage {
    @autoreleasepool {
        [thumbTimes removeAllObjects];
        thumbTimes = nil;
        thumbTimes=[[NSMutableArray alloc] init];
        Float64 duration;
        Float64 start;
        duration = thumbImageVideoCore.duration;
        start = (duration > 2 ? 1 : (duration-0.05));
        [thumbTimes addObject:[NSValue valueWithCMTime:CMTimeMakeWithSeconds(start,TIMESCALE)]];
        NSInteger actualFramesNeeded = duration/2;
        Float64 durationPerFrame = duration / (actualFramesNeeded*1.0);
        /*截图为什么用两个for循环：第一个for循环是分配内存，第二个for循环显示图片，截图快一些*/
        for (int i=1; i<actualFramesNeeded; i++){
            CMTime time = CMTimeMakeWithSeconds(start + i*durationPerFrame,TIMESCALE);
            [thumbTimes addObject:[NSValue valueWithCMTime:time]];
        }
        [thumbImageVideoCore getImageWithTime:CMTimeMakeWithSeconds(start,TIMESCALE) scale:0.2 completionHandler:^(UIImage *image) {
            if(!image){
                image = [thumbImageVideoCore getImageAtTime:CMTimeMakeWithSeconds(start,TIMESCALE) scale:0.2];
                if (!image) {
                    image = [rdPlayer getImageAtTime:CMTimeMakeWithSeconds(start,TIMESCALE) scale:0.2];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.dubbingTrimmerView.frameView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                [self.dubbingTrimmerView.videoRangeView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                
                if(_dubbingTrimmerView){
                    [_dubbingTrimmerView setVideoCore:thumbImageVideoCore];
                    [_dubbingTrimmerView setClipTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, TIMESCALE), CMTimeMakeWithSeconds(thumbImageVideoCore.duration, TIMESCALE))];
                    _dubbingTrimmerView.thumbImageTimes = thumbTimes.count;
                    [_dubbingTrimmerView resetSubviews:image];
                    [self.dubbingTrimmerView setProgress:0 animated:NO];
                    
                    for (DubbingRangeView *dubbing in dubbingMusicArr) {
                        if (dubbing.allControlEvents == 0) {
                            [_dubbingTrimmerView addDubbingTarget:dubbing];
                        }
                        Float64 start = CMTimeGetSeconds(dubbing.dubbingStartTime);
                        Float64 duration = CMTimeGetSeconds(dubbing.dubbingDuration);
                        float oginx = (start + _dubbingTrimmerView.piantouDuration)*_dubbingTrimmerView.videoRangeView.frame.size.width/CMTimeGetSeconds(_dubbingTrimmerView.clipTimeRange.duration);
                        float width =  duration *_dubbingTrimmerView.videoRangeView.frame.size.width/CMTimeGetSeconds(_dubbingTrimmerView.clipTimeRange.duration);
                        CGRect rect= dubbing.frame;
                        rect.origin.x = oginx;
                        rect.size.width = width;
                        dubbing.frame = rect;
                        RDMusic *music = [[RDMusic alloc] init];
                        music.clipTimeRange = CMTimeRangeMake(kCMTimeZero,dubbing.dubbingDuration);
                        music.effectiveTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(CMTimeGetSeconds(dubbing.dubbingStartTime) + _dubbingTrimmerView.piantouDuration,TIMESCALE), dubbing.dubbingDuration);
                        music.url = [NSURL fileURLWithPath:dubbing.musicPath];
                        music.volume = dubbing.volume;
                        music.isRepeat = NO;
                        
                        [_dubbingTrimmerView.videoRangeView addSubview:dubbing];
                        [dubbingArr addObject:music];
                    }
                    NSArray *dubbingArray = [_dubbingTrimmerView getTimesFor_videoRangeView_withTime];
                    if (dubbingArray.count > 0) {
                        _reDubbingBtn.hidden = NO;
                        _auditionDubbingBtn.hidden = NO;
                    }else {
                        _reDubbingBtn.hidden = YES;
                        _auditionDubbingBtn.hidden = YES;
                    }
                    [self touchescurrentdubbingView:[dubbingArray firstObject] flag:YES];
                }
                [self refreshTrimmerViewImage];
            });
        }];
    }
}

- (void)refreshTrimmerViewImage {
    @autoreleasepool {
        Float64 durationPerFrame = thumbImageVideoCore.duration / (thumbTimes.count*1.0);
        for (int i=0; i<thumbTimes.count; i++){
            CMTime time = CMTimeMakeWithSeconds(i*durationPerFrame + 0.2,TIMESCALE);
            [thumbTimes replaceObjectAtIndex:i withObject:[NSValue valueWithCMTime:time]];
        }
        [self refreshThumbWithImageTimes:thumbTimes nextRefreshIndex:0 isLastArray:YES];
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
            NSLog(@"获取图片：%zd",idx);
                if(strongSelf.dubbingTrimmerView)
                    [strongSelf.dubbingTrimmerView refreshThumbImage:idx thumbImage:image];
            if(idx == imageTimes.count - 1)
            {
               if( strongSelf )
                [strongSelf->thumbImageVideoCore stop];
            }
        }];
    }
}

- (void)dealloc {
    NSLog(@"%s", __func__);
}

@end
