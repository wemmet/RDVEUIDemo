//
//  RDVoiceFXViewController.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2019/6/25.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDVoiceFXViewController.h"
#import "RDSVProgressHUD.h"
#import "RDVECore.h"
#import "RDATMHud.h"
#import "RDExportProgressView.h"
#import "RDZSlider.h"
#import "ScrollViewChildItem.h"

@interface RDVoiceFXViewController ()<RDVECoreDelegate, UIAlertViewDelegate, ScrollViewChildItemDelegate>
{
    UIButton                * finishBtn;
    NSMutableArray          * scenes;
    RDVECore                * rdPlayer;
    BOOL                      isContinueExport;
    BOOL                      idleTimerDisabled;//20171101 emmet 解决不锁屏的bug
    NSArray                 * soundEffectArray;
    UIView                  * soundEffectView;
    NSInteger                 selectedSoundEffectIndex;
    UIScrollView            * soundEffectScrollView;
    RDZSlider               * soundEffectSlider;
    UILabel                 * soundEffectLabel;
    float                     oldPitch;
}
@property (nonatomic, strong) UIView *customSoundView;
@property (nonatomic, strong) RDATMHud *hud;

@property (nonatomic, strong) RDExportProgressView *exportProgressView;

@end

@implementation RDVoiceFXViewController

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
    
    oldPitch = 1.0;
    [self initToolBarView];
    [self initPlayer];
    [self initSoundEffectView];
}

- (void)initToolBarView{
    UIView *toolBarView = [[UIView alloc] initWithFrame:CGRectMake(0, kPlayerViewOriginX, kWIDTH, 44)];
    toolBarView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:toolBarView];
    
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
    titleLbl.text = RDLocalizedString(@"变声", nil);
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
    [finishBtn setTitleColor:Main_Color forState:UIControlStateNormal];
    [finishBtn setTitle:RDLocalizedString(@"导出", nil) forState:UIControlStateNormal];
    [finishBtn addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:finishBtn];
}

- (void)initSoundEffectView {
    soundEffectArray = [NSArray arrayWithObjects:@"自定义", @"原音", @"男声", @"女声", @"怪兽", @"卡通", @"回声", @"混响", @"室内", @"舞台", @"KTV", @"厂房", @"竞技场", @"电音", nil];
    soundEffectView = [[UIView alloc] initWithFrame:CGRectMake(0, kNavigationBarHeight + kPlayerViewHeight, kWIDTH, kHEIGHT - kNavigationBarHeight - kPlayerViewHeight - (iPhone_X ? 34 : 0))];
    soundEffectView.backgroundColor = BOTTOM_COLOR;
    [self.view addSubview:soundEffectView];
    
    soundEffectScrollView           = [UIScrollView new];
    soundEffectScrollView.frame     = CGRectMake(0, (soundEffectView.frame.size.height - (iPhone4s ? 70 : (kWIDTH>320 ? 100 : 80)))/2.0 + 20, soundEffectView.frame.size.width, (iPhone4s ? 70 : (kWIDTH>320 ? 100 : 80)));
    soundEffectScrollView.backgroundColor                   = BOTTOM_COLOR;
    soundEffectScrollView.showsHorizontalScrollIndicator    = NO;
    soundEffectScrollView.showsVerticalScrollIndicator      = NO;
    [soundEffectView addSubview:soundEffectScrollView];
    WeakSelf(self);
    [soundEffectArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        StrongSelf(self);
        ScrollViewChildItem *item   = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(idx*(strongSelf->soundEffectScrollView.frame.size.height - 15)+10, 0, (strongSelf->soundEffectScrollView.frame.size.height - 25), strongSelf->soundEffectScrollView.frame.size.height)];
        item.backgroundColor = [UIColor clearColor];
        item.fontSize       = 12;
        item.type           = 4;
        item.delegate       = strongSelf;
        item.selectedColor  = Main_Color;
        item.normalColor    = UIColorFromRGB(0x888888);
        item.cornerRadius   = 3.0;
        item.exclusiveTouch = YES;
        item.itemIconView.backgroundColor   = [UIColor clearColor];
        item.itemIconView.image = [RDHelpClass imageWithContentOfFile:[NSString stringWithFormat:@"jianji/VoiceFXIcon/剪辑-音效-%@_", obj]];
        item.itemTitleLabel.text            = RDLocalizedString(obj, nil);
        item.tag                            = idx + 1;
        item.itemTitleLabel.adjustsFontSizeToFitWidth = YES;
        [strongSelf->soundEffectScrollView addSubview:item];
        [item setSelected:(idx == strongSelf->selectedSoundEffectIndex+1 ? YES : NO)];
    }];
    
    soundEffectScrollView.contentSize = CGSizeMake(soundEffectArray.count * (soundEffectScrollView.frame.size.height - 15)+20, soundEffectScrollView.frame.size.height);
}

- (UIView *)customSoundView {
    if (!_customSoundView) {
        _customSoundView = [[UIView alloc] initWithFrame:soundEffectView.bounds];
        _customSoundView.backgroundColor = BOTTOM_COLOR;
        [soundEffectView addSubview:_customSoundView];
        if (selectedSoundEffectIndex >= 0) {
            _customSoundView.hidden = YES;
        }
        
        UIImageView *soundEffectImage = [[UIImageView alloc] initWithFrame:CGRectMake(5, (_customSoundView.bounds.size.height - 30)/2.0, 30, 30)];
        soundEffectImage.image = [RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"编辑-变声-变调_@2x" Type:@"png"]];
        [_customSoundView addSubview:soundEffectImage];
        
        soundEffectSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(40, (_customSoundView.bounds.size.height - 20)/2.0, kWIDTH - 100, 20)];
        soundEffectSlider.backgroundColor = [UIColor clearColor];
        [soundEffectSlider setMaximumValue:250];
        [soundEffectSlider setMinimumValue:-150];
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [soundEffectSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        soundEffectSlider.layer.cornerRadius = 2.0;
        soundEffectSlider.layer.masksToBounds = YES;
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [soundEffectSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [soundEffectSlider setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
        [soundEffectSlider setValue:logf(oldPitch*1200)/logf(2.0)];
        [soundEffectSlider addTarget:self action:@selector(soundEffectScrub) forControlEvents:UIControlEventValueChanged];
        [soundEffectSlider addTarget:self action:@selector(soundEffectEndScrub) forControlEvents:UIControlEventTouchUpInside];
        [soundEffectSlider addTarget:self action:@selector(soundEffectEndScrub) forControlEvents:UIControlEventTouchCancel];
        [_customSoundView addSubview:soundEffectSlider];
        
        soundEffectLabel = [[UILabel alloc] initWithFrame:CGRectMake(kWIDTH - 60 , soundEffectSlider.frame.origin.y, 60, 20)];
        soundEffectLabel.textAlignment = NSTextAlignmentCenter;
        soundEffectLabel.textColor = UIColorFromRGB(0xffffff);
        soundEffectLabel.font = [UIFont systemFontOfSize:10];
        soundEffectLabel.text = [NSString stringWithFormat:@"%.2f", pow(2.0, soundEffectSlider.value/1200.0)];
        [_customSoundView addSubview:soundEffectLabel];
    }
    return _customSoundView;
}

//变调强度 滑动进度条
- (void)soundEffectScrub{
    float pitch = pow(2.0, soundEffectSlider.value/1200.0);
    soundEffectLabel.text = [NSString stringWithFormat:@"%.2f", pitch];
}

- (void)soundEffectEndScrub{
    float pitch = pow(2.0, soundEffectSlider.value/1200.0);
    [scenes enumerateObjectsUsingBlock:^(RDScene*  _Nonnull scene, NSUInteger idx, BOOL * _Nonnull stop) {
        [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.identifier.length > 0) {
                [rdPlayer setPitch:pitch identifier:obj.identifier];
            }
        }];
    }];
    if (!rdPlayer.isPlaying) {
        [rdPlayer play];
    }
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
    rdPlayer.enableAudioEffect = YES;
    rdPlayer.shouldRepeat = YES;
    rdPlayer.delegate = self;
    [self.view addSubview:rdPlayer.view];
    
    scenes = [NSMutableArray array];
    RDScene *scene = [RDScene new];
    VVAsset *vvAsset = [VVAsset new];
    vvAsset.url = _file.contentURL;
    if(_file.fileType == kFILEVIDEO){
        vvAsset.type = RDAssetTypeVideo;
        vvAsset.identifier = @"video";
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
}

- (void)refreshFinishBtn{
    if(_customSoundView.hidden){
        [finishBtn setTitle:RDLocalizedString(@"导出", nil) forState:UIControlStateNormal];
        [finishBtn setImage:nil forState:UIControlStateNormal];
    }else{
        [finishBtn setTitle:@"" forState:UIControlStateNormal];
        [finishBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_下一步完成默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    }
}

#pragma mark- RDVECoreDelegate
- (void)statusChanged:(RDVECoreStatus)status {
    if (status == kRDVECoreStatusReadyToPlay) {
        [RDSVProgressHUD dismiss];
    }
}

- (void)playToEnd{
    [rdPlayer seekToTime:kCMTimeZero];
}

- (void)tapPlayerView{
    if (rdPlayer.isPlaying) {
        [rdPlayer pause];
    }else {
        [rdPlayer play];
    }
}

#pragma mark- scrollViewChildItemDelegate
- (void)scrollViewChildItemTapCallBlock:(ScrollViewChildItem *)item{
    if (item.tag-2 != selectedSoundEffectIndex || item.tag-2 == -1) {
        [((ScrollViewChildItem *)[soundEffectScrollView viewWithTag:selectedSoundEffectIndex+2]) setSelected:NO];
        [item setSelected:YES];
        selectedSoundEffectIndex = item.tag-2;
        if (selectedSoundEffectIndex == -1) {
            self.customSoundView.hidden = NO;
            [self refreshFinishBtn];
            [scenes enumerateObjectsUsingBlock:^(RDScene*  _Nonnull scene, NSUInteger idx, BOOL * _Nonnull stop) {
                [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (obj.identifier.length > 0) {
                        [rdPlayer setAudioFilter:RDAudioFilterTypeCustom identifier:obj.identifier];
                    }
                }];
            }];
        }else {
            _customSoundView.hidden = YES;
            __block float pitch = 1.0;
            [scenes enumerateObjectsUsingBlock:^(RDScene*  _Nonnull scene, NSUInteger idx, BOOL * _Nonnull stop) {
                [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (obj.identifier.length > 0) {
                        if (selectedSoundEffectIndex <= RDAudioFilterTypeCartoon) {
                            pitch = [rdPlayer setAudioFilter:(RDAudioFilterType)selectedSoundEffectIndex identifier:obj.identifier];
                        }else {
                            pitch = [rdPlayer setAudioFilter:(RDAudioFilterType)(selectedSoundEffectIndex+1) identifier:obj.identifier];
                        }
                    }
                }];
            }];
            soundEffectSlider.value = logf(pitch*1200)/logf(2.0);
            NSLog(@"pitch:%.2f value:%.2f", pitch, soundEffectSlider.value);
            soundEffectLabel.text = [NSString stringWithFormat:@"%.2f", pow(2.0, soundEffectSlider.value/1200.0)];
            if (!rdPlayer.isPlaying) {
                [rdPlayer play];
            }
        }
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
        default:
            break;
    }
}

#pragma mark - 按钮事件
- (void)save{
    if (_customSoundView && !_customSoundView.hidden) {
        _customSoundView.hidden = YES;
        [self refreshFinishBtn];
        oldPitch = powf(2.0, soundEffectSlider.value/1200.0);
    }else {
        [self exportMovie];
    }
}

- (void)back{
    if (_customSoundView && !_customSoundView.hidden) {
        _customSoundView.hidden = YES;
        [self refreshFinishBtn];
        soundEffectSlider.value = logf(oldPitch*1200)/logf(2.0);
        soundEffectLabel.text = [NSString stringWithFormat:@"%.2f", pow(2.0, soundEffectSlider.value/1200.0)];
        [scenes enumerateObjectsUsingBlock:^(RDScene*  _Nonnull scene, NSUInteger idx, BOOL * _Nonnull stop) {
            [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.identifier.length > 0) {
                    [rdPlayer setPitch:oldPitch identifier:obj.identifier];
                }
            }];
        }];
    }else {
        [self dismissViewControllerAnimated:YES completion:^{
            if(((RDNavigationViewController *)self.navigationController).cancelHandler){
                ((RDNavigationViewController *)self.navigationController).cancelHandler();
            }
        }];
    }
}

- (void)dealloc {
    NSLog(@"%s", __func__);
}

@end
