//
//  RDDoodleViewController.m
//  RDVEUISDK
//
//  Created by apple on 2019/7/12.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDDoodleViewController.h"
#import "RDSVProgressHUD.h"
#import "RDVECore.h"
#import "RDATMHud.h"
#import "RDExportProgressView.h"
#import "UIImageView+RDWebCache.h"
//贴纸
#import "RDAddEffectsByTimeline.h"

@interface RDDoodleViewController ()<RDVECoreDelegate,UIScrollViewDelegate,UIAlertViewDelegate,RDAddEffectsByTimelineDelegate>
{
    RDVECore                * rdPlayer;
    BOOL                      isContinueExport;
    BOOL                      idleTimerDisabled;
    
    NSMutableArray  *thumbTimes;
    //涂鸦
    NSMutableArray <RDWatermark *> *doodles;
    NSMutableArray <RDCaptionRangeViewFile *> *doodleFiles;
    NSMutableArray <RDCaptionRangeViewFile *> *oldDoodleFiles;
    
    UIScrollView                * addedSubtitleScrollView;
    UIScrollView                * addedMaterialEffectScrollView;
    UIImageView                 * selectedMaterialEffectItemIV;
    NSInteger                     selectedMaterialEffectIndex;
    BOOL                          isModifiedMaterialEffect;//是否修改过字幕、贴纸、去水印、画中画、涂鸦
    CMTime                        seekTime;
    
    UIView *titleView;
    UIView *toolBarView;
    UILabel *toolBarTitleLbl;
    CMTime          startPlayTime;
    
    RDVECore        *thumbImageVideoCore;//截取缩率图
    
    BOOL             isResignActive;    //20171026 wuxiaoxia 导出过程中按Home键后会崩溃
    
    UIButton *finishBtn;
    BOOL                          isNotNeedPlay;
}
@property (nonatomic, strong) RDATMHud *hud;
@property (nonatomic, strong) RDExportProgressView *exportProgressView;

@property(nonatomic,strong)UIView                       *playerView;         //播放器

//贴纸
@property(nonatomic,strong)UIView   *addEffectsByTimelineView;
@property(nonatomic,strong)RDAddEffectsByTimeline   *addEffectsByTimeline;
@property (nonatomic, strong) UIView *addedMaterialEffectView;
@property (nonatomic, assign) BOOL isAddingMaterialEffect;
@property (nonatomic, assign) BOOL isEdittingMaterialEffect;
@property (nonatomic, assign) BOOL isCancelMaterialEffect;

@property(nonatomic       )UIAlertView      *commonAlertView;
@end

@implementation RDDoodleViewController

- (void)refreshWatermarkArrayWithIsExport:(BOOL)isExport {
    NSMutableArray *array = [NSMutableArray arrayWithArray:doodles];
    rdPlayer.watermarkArray = array;
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:idleTimerDisabled];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [rdPlayer stop];
}

- (void)applicationDidReceiveMemoryWarningNotification:(NSNotification *)notification{
    NSLog(@"内存占用过高");
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveMemoryWarningNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [rdPlayer prepare];//20171026 wuxiaoxia 优化内存
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = iPhone4s;
    [[UIApplication sharedApplication] setStatusBarHidden:!iPhone_X];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT - kToolbarHeight, kWIDTH, kToolbarHeight)];
    view.backgroundColor = TOOLBAR_COLOR;
    [self.view addSubview:view];
    
    [self.view addSubview:self.playerView];
    [self initTitleView];
    [self initToolBarView];
    [self initPlayer];
    [self initThumbImageVideoCore];
    [self.view addSubview:self.addEffectsByTimelineView];
    
    _addEffectsByTimeline.thumbnailCoreSDK = rdPlayer;
    _addEffectsByTimeline.doodleConfigView.hidden = YES;
    _addEffectsByTimeline.exportSize = _exportSize;
    _addEffectsByTimeline.currentEffect = RDAdvanceEditType_Doodle;
    _addEffectsByTimeline.currentTimeLbl.text = @"0.00";
}

-(UIView *)playerView
{
    if (!_playerView) {
        _playerView = [UIView new];
        [_playerView setFrame:CGRectMake(0, kPlayerViewOriginX, kWIDTH, kPlayerViewHeight)];
        _playerView.backgroundColor =SCREEN_BACKGROUND_COLOR;
    }
    return _playerView;
}

- (void)initTitleView{
    titleView = [[UIView alloc] initWithFrame:CGRectMake(0, kPlayerViewOriginX, kWIDTH, 44)];
    titleView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:titleView];
    
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
    titleLbl.text = RDLocalizedString(@"涂鸦", nil);
    titleLbl.textColor = [UIColor whiteColor];
    titleLbl.font = [UIFont boldSystemFontOfSize:20.0];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    [titleView addSubview:titleLbl];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(0, 0, 44, 44);
    [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_返回默认_"] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:cancelBtn];
    
    finishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    finishBtn.frame = CGRectMake(kWIDTH - 64, 0, 64, 44);
    finishBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [finishBtn setTitleColor:Main_Color forState:UIControlStateNormal];
    [finishBtn setTitle:RDLocalizedString(@"导出", nil) forState:UIControlStateNormal];
    [finishBtn addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:finishBtn];
}

- (void)initToolBarView{
    toolBarView = [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT - kToolbarHeight, kWIDTH, kToolbarHeight)];
    toolBarView.backgroundColor = TOOLBAR_COLOR;
    toolBarView.hidden = YES;
    [self.view addSubview:toolBarView];
    
    toolBarTitleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
    toolBarTitleLbl.textAlignment = NSTextAlignmentCenter;
    toolBarTitleLbl.font = [UIFont boldSystemFontOfSize:20];
    toolBarTitleLbl.textColor = [UIColor whiteColor];
    toolBarTitleLbl.text = RDLocalizedString(@"涂鸦", nil);
    [toolBarView addSubview:toolBarTitleLbl];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(0, 0, 44, 44);
    [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(cancelEditDoodle) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:cancelBtn];
    
    UIButton *finishEditDoodleBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    finishEditDoodleBtn.frame = CGRectMake(kWIDTH - 44, 0, 44, 44);
    [finishEditDoodleBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
    [finishEditDoodleBtn addTarget:self action:@selector(finishEditDoodle) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:finishEditDoodleBtn];
}

- (void)initPlayer {
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
    if( !rdPlayer )
    {
        NSString *exportOutPath = _outputPath.length>0 ? _outputPath : [RDHelpClass pathAssetVideoForURL:_file.contentURL];
        unlink([exportOutPath UTF8String]);
        [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
        
        if (CGSizeEqualToSize(_exportSize, CGSizeZero)) {
            _exportSize = [RDHelpClass getVideoSizeForTrack:[AVURLAsset assetWithURL:_file.contentURL]];
            if(_exportSize.height <= _exportSize.width){
                _exportSize = CGSizeMake(kVIDEOWIDTH,kVIDEOWIDTH*(_exportSize.height/(float)_exportSize.width));
            }else{
                _exportSize = CGSizeMake(kVIDEOWIDTH*(_exportSize.width/(float)_exportSize.height),kVIDEOWIDTH);
            }
        }
        
        
        rdPlayer = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                          APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                         LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                          videoSize:_exportSize
                                                fps:kEXPORTFPS
                                         resultFail:^(NSError *error) {
                                             NSLog(@"initSDKError:%@", error.localizedDescription);
                                         }];
        
        rdPlayer.frame = CGRectMake(0, kNavigationBarHeight, self.playerView.frame.size.width, self.playerView.frame.size.height);
        rdPlayer.delegate = self;
        [self.playerView addSubview:rdPlayer.view];
    }
    [self performSelector:@selector(refreshRdPlayer:) withObject:rdPlayer afterDelay:0.1];
}
- (void)refreshRdPlayer:(RDVECore *)Player {
    
    [RDSVProgressHUD dismiss];
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
    
    NSMutableArray *array = [NSMutableArray arrayWithArray:doodles];
    rdPlayer.watermarkArray = array;
    
    [Player setScenes:scenes];
    [Player build];
}

-(void)titleViewHidden:(BOOL) isHidden
{
    titleView.hidden = isHidden;
    toolBarView.hidden = !isHidden;
}

- (void)toolbarTitleLblHidden:(BOOL)hidden {
    toolBarTitleLbl.hidden = hidden;
    _addedMaterialEffectView.hidden = !hidden;
}

#pragma mark- RDVECoreDelegate
- (void)statusChanged:(RDVECore *)sender status:(RDVECoreStatus)status {
    if (status == kRDVECoreStatusReadyToPlay) {
        [RDSVProgressHUD dismiss];
        if(sender == rdPlayer){
            if (_addEffectsByTimeline.isAddingEffect) {
                if (CMTimeCompare(seekTime, kCMTimeZero) == 1) {
                    WeakSelf(self);
                    [rdPlayer seekToTime:seekTime toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
                        StrongSelf(self);
                        if (!strongSelf->isNotNeedPlay) {
                            [strongSelf playVideo:YES];
                        }else {
                            strongSelf->isNotNeedPlay = NO;
                        }
                        strongSelf->seekTime = kCMTimeZero;
                    }];
                }else if(!isNotNeedPlay) {
                    [self playVideo:YES];
                }else {
                    isNotNeedPlay = NO;
                }
            }else if (CMTimeCompare(seekTime, kCMTimeZero) == 1) {
                if( _addEffectsByTimeline.isPlay )
                {
                    WeakSelf(self);
                    [rdPlayer seekToTime:seekTime toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
                        StrongSelf(self);
                        if (!strongSelf->isNotNeedPlay) {
                            [strongSelf playVideo:YES];
                        }else {
                            strongSelf->isNotNeedPlay = NO;
                        }
                        strongSelf->seekTime = kCMTimeZero;
                        _addEffectsByTimeline.isPlay = false;
                    }];
                }
                else{
                    [rdPlayer seekToTime:seekTime toleranceTime:kCMTimeZero completionHandler:nil];
                    seekTime = kCMTimeZero;
                    isNotNeedPlay = NO;
                }
            }
        }else{
            [self loadTrimmerViewThumbImage];
        }
    }
}
/**更新播放进度条
 */
- (void)progress:(RDVECore *)sender currentTime:(CMTime)currentTime{
    //- (void)progressCurrentTime:(CMTime)currentTime{
    
    float progress = CMTimeGetSeconds(currentTime)/rdPlayer.duration;
    
    if(sender == thumbImageVideoCore){
        return;
    }
    if([rdPlayer isPlaying]){
        if(!_addEffectsByTimeline.trimmerView.videoCore) {
            [_addEffectsByTimeline.trimmerView setVideoCore:thumbImageVideoCore];
        }
        [_addEffectsByTimeline.trimmerView setProgress:progress animated:NO];
        _addEffectsByTimeline.currentTimeLbl.text = [RDHelpClass timeToStringFormat:CMTimeGetSeconds(currentTime)];
        if(_isAddingMaterialEffect){
            BOOL suc = [_addEffectsByTimeline.trimmerView changecurrentCaptionViewTimeRange];
            if(!suc){
                [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
            }
        }
    }
}
- (void)playToEnd{
    [self playVideo:NO];
    if (_isAddingMaterialEffect) {
        [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
    }else {
        [_addEffectsByTimeline.trimmerView setProgress:0 animated:NO];
    }
    [rdPlayer seekToTime:kCMTimeZero toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
}

- (void)tapPlayerView{
    [self playVideo:![rdPlayer isPlaying]];
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
    
    [self refreshWatermarkArrayWithIsExport:YES];
    
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
    [self refreshWatermarkArrayWithIsExport:NO];
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
    [self exportMovie];
}

- (void)back{
    [self dismissViewControllerAnimated:YES completion:^{
        if(((RDNavigationViewController *)self.navigationController).cancelHandler){
            ((RDNavigationViewController *)self.navigationController).cancelHandler();
        }
    }];
}

- (void)cancelEditDoodle {
    if(!_isAddingMaterialEffect && !_isEdittingMaterialEffect)
    {
        if(!_addEffectsByTimeline.trimmerView.rangeSlider.hidden)
        {
            _addEffectsByTimeline.trimmerView.currentCaptionView = nil;
            return;
        }
    }
    
    if (_isAddingMaterialEffect || _isEdittingMaterialEffect)
    {
        _addEffectsByTimeline.currentTimeLbl.hidden = NO;
        if (_isAddingMaterialEffect)  {
            [_addEffectsByTimeline cancelEffectAction:nil];
        }else {
            [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
            isNotNeedPlay = YES;
        }
        self.isAddingMaterialEffect = NO;
        self.isEdittingMaterialEffect = NO;
    }else if (!_addEffectsByTimeline.doodleConfigView.hidden) {
        _addEffectsByTimeline.doodleConfigView.hidden = YES;
    }
}

- (void)finishEditDoodle {
    if(!_isAddingMaterialEffect && !_isEdittingMaterialEffect)
    {
        if(!_addEffectsByTimeline.trimmerView.rangeSlider.hidden)
        {
            _addEffectsByTimeline.trimmerView.currentCaptionView = nil;
            return;
        }
    }
    if (!_addEffectsByTimeline.doodleDrawView.hidden) {
        if ([_addEffectsByTimeline.doodleDrawView isHasContent]) {
            RDWatermark *doodle = [[RDWatermark alloc] init];
            doodle.timeRange = CMTimeRangeMake(rdPlayer.currentTime, CMTimeSubtract(CMTimeMakeWithSeconds(rdPlayer.duration, TIMESCALE), rdPlayer.currentTime));
            doodle.vvAsset.url = [RDHelpClass getFileUrlWithFolderPath:kDoodleFolder fileName:@"doodle.png"];
            doodle.vvAsset.type = RDAssetTypeImage;
            doodle.vvAsset.fillType = RDImageFillTypeFit;
            doodle.vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeSubtract(CMTimeMakeWithSeconds(rdPlayer.duration, TIMESCALE), rdPlayer.currentTime));
            if (!doodles) {
                doodles = [NSMutableArray array];
            }
            [doodles addObject:doodle];
            
            UIImage *doodleImage = [_addEffectsByTimeline.doodleDrawView getImage];
            unlink([doodle.vvAsset.url.path UTF8String]);
            [UIImagePNGRepresentation(doodleImage) writeToFile:doodle.vvAsset.url.path atomically:YES];
            _addEffectsByTimeline.doodleDrawView.hidden = YES;
            _addEffectsByTimeline.doodleConfigView.hidden = YES;
            
            [_addEffectsByTimeline.trimmerView changeDoodleCurrentRangeviewFile:doodle
                                                                     thumbImage:doodleImage
                                                                    captionView:nil];
            seekTime = rdPlayer.currentTime;
            _addEffectsByTimeline.isAddingEffect = YES;
            [self initPlayer];
            [self titleViewHidden:YES];
            toolBarView.hidden = YES;
            _addedMaterialEffectView.hidden = YES;
        }else {
            [_addEffectsByTimeline cancelEffectAction:nil];
            self.isAddingMaterialEffect = NO;
        }
        [_addEffectsByTimeline.doodleDrawView clearScreen];
    }else if (_isAddingMaterialEffect || _isEdittingMaterialEffect) {
        [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
    }
}

- (void)dealloc {
    NSLog(@"%s", __func__);
}
#pragma mark- addEffectsByTimeline
- (UIView *)addEffectsByTimelineView{
    if(!_addEffectsByTimelineView){
        _addEffectsByTimelineView = [UIView new];
        _addEffectsByTimelineView.frame = CGRectMake(0, self.playerView.frame.size.height  + self.playerView.frame.origin.y, kWIDTH, kHEIGHT - kPlayerViewOriginX - kPlayerViewHeight - kToolbarHeight);
        _addEffectsByTimelineView.backgroundColor = SCREEN_BACKGROUND_COLOR;
        [_addEffectsByTimelineView addSubview:self.addEffectsByTimeline];
    }
    return _addEffectsByTimelineView;
}
- (RDAddEffectsByTimeline *)addEffectsByTimeline {
    if (!_addEffectsByTimeline) {
        float height = kHEIGHT - kPlayerViewOriginX - kPlayerViewHeight - kToolbarHeight;
        _addEffectsByTimeline = [[RDAddEffectsByTimeline alloc] initWithFrame:CGRectMake(0,0, kWIDTH, height)];
        [_addEffectsByTimeline prepareWithEditConfiguration:((RDNavigationViewController *)self.navigationController).editConfiguration
                                                     appKey:((RDNavigationViewController *)self.navigationController).appKey
                                                 exportSize:_exportSize
                                                 playerView:_playerView
                                                        hud:_hud];
        _addEffectsByTimeline.delegate = self;
    }
    return _addEffectsByTimeline;
}

- (UIView *)addedMaterialEffectView {
    if (!_addedMaterialEffectView) {
        _addedMaterialEffectView = [[UIView alloc] initWithFrame:CGRectMake(44, kHEIGHT - kToolbarHeight, kWIDTH - 44*2, 44)];
        _addedMaterialEffectView.hidden = YES;
        _addedMaterialEffectView.backgroundColor = TOOLBAR_COLOR;
        

        
        [self.view addSubview:_addedMaterialEffectView];
        
        UILabel *addedLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 64, 44)];
        addedLbl.text = RDLocalizedString(@"已添加", nil);
        addedLbl.textColor = UIColorFromRGB(0x888888);
        addedLbl.font = [UIFont systemFontOfSize:14.0];
        [_addedMaterialEffectView addSubview:addedLbl];
        
        addedMaterialEffectScrollView =  [UIScrollView new];
        addedMaterialEffectScrollView.frame = CGRectMake(64, 0, _addedMaterialEffectView.bounds.size.width - 64, 44);
        addedMaterialEffectScrollView.showsVerticalScrollIndicator = NO;
        addedMaterialEffectScrollView.showsHorizontalScrollIndicator = NO;
        [_addedMaterialEffectView addSubview:addedMaterialEffectScrollView];
        
        selectedMaterialEffectItemIV = [[UIImageView alloc] initWithFrame:CGRectMake(0, addedMaterialEffectScrollView.bounds.size.height - 27, 27, 27)];
        
        selectedMaterialEffectItemIV.image = [RDHelpClass imageWithContentOfFile:@"/jianji/effectVideo/特效-选中勾_"];
        selectedMaterialEffectItemIV.hidden = YES;
        [addedMaterialEffectScrollView addSubview:selectedMaterialEffectItemIV];
    }
    return _addedMaterialEffectView;
}

#pragma mark - RDAddEffectsByTimelineDelegate
- (void)pauseVideo {
    [self playVideo:NO];
}

- (void)playOrPauseVideo {
    [self playVideo:![rdPlayer isPlaying]];
}

- (void)changeCurrentTime:(float)currentTime {
    if(![rdPlayer isPlaying]){
        WeakSelf(self);
        [rdPlayer seekToTime:CMTimeMakeWithSeconds(currentTime, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
            StrongSelf(self);
            float duration = strongSelf->rdPlayer.duration;
            if(CMTimeGetSeconds(strongSelf->startPlayTime)>= CMTimeGetSeconds(CMTimeSubtract(CMTimeMakeWithSeconds(duration, TIMESCALE), CMTimeMakeWithSeconds(0.1, TIMESCALE)))){
                [strongSelf playVideo:YES];
            }
        }];
    }
}

- (void)addMaterialEffect {
    if( [rdPlayer isPlaying] ) {
        [self playVideo:NO];
    }
    _isAddingMaterialEffect = YES;
    _addedMaterialEffectView.hidden = YES;
    _addEffectsByTimeline.doodleDrawView.hidden = NO;
    [self titleViewHidden:YES];
    [self toolbarTitleLblHidden:NO];
}

- (void)cancelMaterialEffect {
    self.isCancelMaterialEffect = YES;
    [self deleteMaterialEffect];
    self.isCancelMaterialEffect = NO;
    self.isAddingMaterialEffect = NO;
    self.isEdittingMaterialEffect = NO;
}

- (void)deleteMaterialEffect {
    [self playVideo:NO];
    if (!_isCancelMaterialEffect) {
        seekTime = rdPlayer.currentTime;
    }
    isNotNeedPlay = YES;
    if (_isCancelMaterialEffect) {
        seekTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(_addEffectsByTimeline.trimmerView.currentCaptionView.file.timeRange.start) + _addEffectsByTimeline.trimmerView.piantouDuration,TIMESCALE);
    }
    BOOL suc = [_addEffectsByTimeline.trimmerView deletedcurrentCaption];
    if(suc){
        NSMutableArray *__strong arr = [_addEffectsByTimeline.trimmerView getTimesFor_videoRangeView_withTime];
        [doodles removeAllObjects];
        [doodleFiles removeAllObjects];
        
        for(CaptionRangeView *view in arr){
            RDWatermark *doodle = view.file.doodle;
            if(doodle){
                [doodles addObject:doodle];
                [doodleFiles addObject:view.file];
            }
        }
        [self initPlayer];
    }else{
        isNotNeedPlay = NO;
        NSLog(@"删除失败");
    }
    float progress = CMTimeGetSeconds(seekTime)/rdPlayer.duration;
    if( progress < 0 )
        progress = 0.0;
    [_addEffectsByTimeline.trimmerView setProgress:progress animated:NO];
    [self refreshAddMaterialEffectScrollView];
    selectedMaterialEffectItemIV.hidden = YES;
    self.isAddingMaterialEffect = NO;
    self.isEdittingMaterialEffect = NO;
    self.isCancelMaterialEffect = NO;
    [self titleViewHidden:NO];
    if (doodles.count > 0) {
        [self toolbarTitleLblHidden:YES];
    }else {
        [self toolbarTitleLblHidden:NO];
    }
}

- (void)updateMaterialEffect:(NSMutableArray *)newEffectArray
                newFileArray:(NSMutableArray *)newFileArray
                isSaveEffect:(BOOL)isSaveEffect
{
    _isAddingMaterialEffect = NO;
    _addEffectsByTimeline.currentTimeLbl.hidden = NO;
    if (rdPlayer.isPlaying) {
        [self playVideo:NO];
    }
    seekTime = rdPlayer.currentTime;
    float time = CMTimeGetSeconds(seekTime);
    if (time >= rdPlayer.duration) {
        seekTime = kCMTimeZero;
    }
    self.addedMaterialEffectView.hidden = NO;
    if (!doodles) {
        doodles = [NSMutableArray array];
    }
    if (!doodleFiles) {
        doodleFiles = [NSMutableArray array];
    }
    [self refreshMaterialEffectArray:doodles newArray:newEffectArray];
    [self refreshMaterialEffectArray:doodleFiles newArray:newFileArray];
    if( isSaveEffect )
        self.isEdittingMaterialEffect = NO;
    selectedMaterialEffectItemIV.hidden = YES;
    [self performSelector:@selector(initPlayer) withObject:nil afterDelay:0.1];
    
    if (isSaveEffect) {        
        [self refreshAddMaterialEffectScrollView];
        [_addEffectsByTimeline.syncContainer removeFromSuperview];
        selectedMaterialEffectItemIV.hidden = YES;
        self.isAddingMaterialEffect = NO;
        self.isEdittingMaterialEffect = NO;
        [self titleViewHidden:NO];
    }
    if (!_isEdittingMaterialEffect) {
        if ( newEffectArray.count == 0 && (_addEffectsByTimeline.trimmerView.currentCaptionView == nil)) {
            [self toolbarTitleLblHidden:NO];
        }else {
            [self toolbarTitleLblHidden:YES];
        }
    }
}

- (void)refreshMaterialEffectArray:(NSMutableArray *)oldArray newArray:(NSMutableArray *)newArray {
    [oldArray removeAllObjects];
    [newArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [oldArray addObject:obj];
    }];
}

- (void)pushOtherAlbumsVC:(UIViewController *)otherAlbumsVC {
    isNotNeedPlay = YES;
    [self.navigationController pushViewController:otherAlbumsVC animated:YES];
}
-(void)TimesFor_videoRangeView_withTime:(int)captionId
{
    [addedMaterialEffectScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[RDAddItemButton class]]) {
            RDAddItemButton * addItemBtn = (RDAddItemButton*) obj;
            addItemBtn.redDotImageView.hidden = YES;
        }
    }];
    
    NSMutableArray *array = [_addEffectsByTimeline.trimmerView getCaptionsViewForcurrentTime:NO];
    
    if( array && (array.count > 0)  )
    {
        [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            CaptionRangeView * rangeV = (CaptionRangeView*)obj;
            for (int i = 0; i < addedMaterialEffectScrollView.subviews.count; i++) {
                UIView * obj = addedMaterialEffectScrollView.subviews[i];
                
                if ([obj isKindOfClass:[RDAddItemButton class]]) {
                    RDAddItemButton * addItemBtn = (RDAddItemButton*) obj;
                    if( (rangeV.file.captionId == addItemBtn.tag) && ( addItemBtn.tag != _addEffectsByTimeline.trimmerView.currentCaptionView ) )
                    {
                        addItemBtn.redDotImageView.hidden = NO;
                        break;
                    }
                }
                
            }
        }];
    }
}

- (void)refreshAddMaterialEffectScrollView {
    if( !addedMaterialEffectScrollView )
        self.addedMaterialEffectView.hidden = NO;
    
    [addedMaterialEffectScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    NSMutableArray *__strong arr = [_addEffectsByTimeline.trimmerView getTimesFor_videoRangeView_withTime];
    NSInteger index = 0;
    for (int i = 0; i < arr.count; i++) {
        CaptionRangeView *view = arr[i];
        if (_isAddingMaterialEffect && view == _addEffectsByTimeline.trimmerView.currentCaptionView) {
            index = view.file.captionId;
        }
        if (view.file.doodle) {
            RDAddItemButton *addedItemBtn = [RDAddItemButton buttonWithType:UIButtonTypeCustom];
            addedItemBtn.frame = CGRectMake(i * 50, (44 - 40)/2.0, 40, 40);
            [addedItemBtn setImage:view.file.thumbnailImage forState:UIControlStateNormal];
            addedItemBtn.tag = view.file.captionId;
            [addedItemBtn addTarget:self action:@selector(addedMaterialEffectItemBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            addedItemBtn.redDotImageView = [[UIImageView alloc] initWithFrame:CGRectMake(addedItemBtn.frame.size.width - addedMaterialEffectScrollView.bounds.size.height/6.0, addedMaterialEffectScrollView.bounds.size.height - addedMaterialEffectScrollView.bounds.size.height/2.0, addedMaterialEffectScrollView.bounds.size.height/6.0, addedMaterialEffectScrollView.bounds.size.height/6.0)];
            
            addedItemBtn.redDotImageView.backgroundColor = [UIColor redColor];
            addedItemBtn.redDotImageView.layer.cornerRadius =  addedItemBtn.redDotImageView.frame.size.height/2.0;
            addedItemBtn.redDotImageView.layer.masksToBounds = YES;
            addedItemBtn.redDotImageView.layer.shadowColor = [UIColor redColor].CGColor;
            addedItemBtn.redDotImageView.layer.shadowOffset = CGSizeZero;
            addedItemBtn.redDotImageView.layer.shadowOpacity = 0.5;
            addedItemBtn.redDotImageView.layer.shadowRadius = 2.0;
            addedItemBtn.redDotImageView.clipsToBounds = NO;
            
            [addedItemBtn addSubview:addedItemBtn.redDotImageView];
            addedItemBtn.redDotImageView.hidden = YES;
            [addedMaterialEffectScrollView addSubview:addedItemBtn];
        }
    }
    [addedMaterialEffectScrollView setContentSize:CGSizeMake(addedMaterialEffectScrollView.subviews.count * 50, 0)];
    if (_isEdittingMaterialEffect) {
        [addedMaterialEffectScrollView addSubview:selectedMaterialEffectItemIV];
    }
    if ( _isAddingMaterialEffect && !_isEdittingMaterialEffect ) {
        selectedMaterialEffectIndex = index;
        _addEffectsByTimeline.currentMaterialEffectIndex = selectedMaterialEffectIndex;
        UIButton *itemBtn = [addedMaterialEffectScrollView viewWithTag:index];
        CGRect frame = selectedMaterialEffectItemIV.frame;
        frame.origin.x = itemBtn.frame.origin.x + itemBtn.bounds.size.width - frame.size.width + 6;
        selectedMaterialEffectItemIV.frame = frame;
        selectedMaterialEffectItemIV.hidden = NO;
        [addedMaterialEffectScrollView addSubview:selectedMaterialEffectItemIV];
    }
    
    if( arr.count > 0 )
    {
        _addedMaterialEffectView.hidden = NO;
    }
    else
    {
        _addedMaterialEffectView.hidden = YES;
    }
}

- (void)setIsAddingMaterialEffect:(BOOL)isAddingMaterialEffect {
    _isAddingMaterialEffect = isAddingMaterialEffect;
    _addEffectsByTimeline.isAddingEffect = isAddingMaterialEffect;
}

- (void)setIsEdittingMaterialEffect:(BOOL)isEdittingMaterialEffect {
    _isEdittingMaterialEffect = isEdittingMaterialEffect;
    _addEffectsByTimeline.isEdittingEffect = isEdittingMaterialEffect;
}

- (void)addedMaterialEffectItemBtnAction:(UIButton *)sender {
    if (!selectedMaterialEffectItemIV.hidden && sender.tag == selectedMaterialEffectIndex)
        return;
    
    if (rdPlayer.isPlaying) {
        [self playVideo:NO];
    }
    
    selectedMaterialEffectIndex = sender.tag;
    _addEffectsByTimeline.currentMaterialEffectIndex = selectedMaterialEffectIndex;
    CGRect frame = selectedMaterialEffectItemIV.frame;
    frame.origin.x = sender.frame.origin.x + sender.bounds.size.width - frame.size.width + 6;
    selectedMaterialEffectItemIV.frame = frame;
    
    _addEffectsByTimeline.trimmerView.isJumpTail = true;
    
    [_addEffectsByTimeline editAddedEffect];
    if (!selectedMaterialEffectItemIV.superview) {
        [addedMaterialEffectScrollView addSubview:selectedMaterialEffectItemIV];
    }
    selectedMaterialEffectItemIV.hidden = NO;
    _addedMaterialEffectView.hidden = NO;
    self.isEdittingMaterialEffect = YES;
    self.isAddingMaterialEffect = NO;
    
    CMTime time = _addEffectsByTimeline.trimmerView.currentCaptionView.file.timeRange.start;
    seekTime = time;
    seekTime = CMTimeAdd(_addEffectsByTimeline.trimmerView.currentCaptionView.file.timeRange.start, CMTimeMakeWithSeconds(0.2, TIMESCALE));
    [rdPlayer seekToTime:seekTime toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
    [rdPlayer filterRefresh:seekTime];
    _addEffectsByTimeline.trimmerView.isJumpTail = false;
    [self titleViewHidden:YES];
    [self toolbarTitleLblHidden:YES];
}
#pragma mark- 字幕、特效、配音截图
-(void)loadTrimmerViewThumbImage {
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
                [_addEffectsByTimeline loadTrimmerViewThumbImage:image
                                                  thumbnailCount:thumbTimes.count
                                                  addEffectArray:doodles
                                                   oldFileArray:oldDoodleFiles];
                //NSLog(@"截图次数：%d",actualFramesNeeded);
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
            if(strongSelf.addEffectsByTimeline.trimmerView)
                [strongSelf.addEffectsByTimeline.trimmerView refreshThumbImage:idx thumbImage:image];
            
            if(idx == imageTimes.count - 1)
            {
                if( strongSelf )
                    [strongSelf->thumbImageVideoCore stop];
                [RDSVProgressHUD dismiss];
            }
        }];
    }
}

#pragma mark- 播放
//播放按钮切换
-(void) playVideo:(BOOL) play{
    if (!play) {
        [rdPlayer pause];
        [_addEffectsByTimeline.playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
        [_addEffectsByTimeline.playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateHighlighted];
    }
    else
    {
        if (rdPlayer.status != kRDVECoreStatusReadyToPlay
            || isResignActive
            ) {
            return;
        }
        [rdPlayer play];
        startPlayTime = rdPlayer.currentTime;
        [_addEffectsByTimeline.playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateNormal];
        [_addEffectsByTimeline.playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateHighlighted];
    }
}

- (void)initThumbImageVideoCore{
    thumbImageVideoCore = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                                 APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                                LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                                 videoSize:_exportSize
                                                       fps:kEXPORTFPS
                                                resultFail:^(NSError *error) {
                                                    NSLog(@"initSDKError:%@", error.localizedDescription);
                                                }];
    thumbImageVideoCore.delegate = self;
    thumbImageVideoCore.frame = _playerView.bounds;
    thumbImageVideoCore.customFilterArray = nil;
    [self performSelector:@selector(refreshRdPlayer:) withObject:thumbImageVideoCore afterDelay:0.1];
}

- (void)applicationEnterHome:(NSNotification *)notification{
    isResignActive = YES;
    if(_exportProgressView && [notification.name isEqualToString:UIApplicationDidEnterBackgroundNotification]){
        __block typeof(self) myself = self;
        [rdPlayer cancelExportMovie:^{
            //更新UI需在主线程中操作
            dispatch_async(dispatch_get_main_queue(), ^{
                [myself cancelExportBlock];
                //移除 “取消导出框”
                [myself.commonAlertView dismissWithClickedButtonIndex:0 animated:YES];
                [myself.exportProgressView removeFromSuperview];
                myself.exportProgressView = nil;
            });
        }];
    }
}

- (void)cancelExportBlock{
    [_exportProgressView setProgress:0 animated:NO];
    [_exportProgressView removeFromSuperview];
    _exportProgressView = nil;
    [self refreshWatermarkArrayWithIsExport:NO];
    [[UIApplication sharedApplication] setIdleTimerDisabled: idleTimerDisabled];
}

- (void)appEnterForegroundNotification:(NSNotification *)notification{
    isResignActive = NO;
}

#pragma makr- keybordShow&Hidde
- (void)keyboardWillShow:(NSNotification *)notification{
    NSValue *value = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGSize keyboardSize = [value CGRectValue].size;
    
    CGRect bottomViewFrame = _addEffectsByTimeline.subtitleConfigView.frame;
    bottomViewFrame.origin.y = kHEIGHT - keyboardSize.height - 48;
    _addEffectsByTimeline.subtitleConfigView.frame = bottomViewFrame;
}

- (void)keyboardWillHide:(NSNotification *)notification{
    CGRect bottomViewFrame = _addEffectsByTimeline.subtitleConfigView.frame;
    bottomViewFrame.origin.y = kHEIGHT - _addEffectsByTimeline.subtitleConfigView.frame.size.height;
    _addEffectsByTimeline.subtitleConfigView.frame = bottomViewFrame;
}
@end
