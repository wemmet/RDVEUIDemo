//
//  RDReverseViewController.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2019/6/25.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDReverseViewController.h"
#import "RDSVProgressHUD.h"
#import "RDVECore.h"
#import "RDATMHud.h"
#import "RDExportProgressView.h"
#import "RDMBProgressHUD.h"

@interface RDReverseViewController ()<RDVECoreDelegate, UIAlertViewDelegate>
{
    RDVECore                * rdPlayer;
    BOOL                      isContinueExport;
    BOOL                      idleTimerDisabled;//20171101 emmet 解决不锁屏的bug
    RDMBProgressHUD         * progressHUD;
    UIButton                * reverseBtn;
}
@property (nonatomic, strong) RDATMHud *hud;

@property (nonatomic, strong) RDExportProgressView *exportProgressView;

@end

@implementation RDReverseViewController

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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIApplication sharedApplication] setIdleTimerDisabled:idleTimerDisabled];
    
    [rdPlayer stop];
    [rdPlayer.view removeFromSuperview];
    rdPlayer.delegate = nil;
    rdPlayer = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = iPhone4s;
    [[UIApplication sharedApplication] setStatusBarHidden:!iPhone_X];
    
    NSString *reversePath = [RDGenSpecialEffect ExportURL:_file];
    if (![[NSFileManager defaultManager] fileExistsAtPath:reversePath]) {
        [self initCircleView];
        [self performSelectorInBackground:@selector(exportReverseVideo:) withObject:[NSURL fileURLWithPath:reversePath]];
    }else {
        AVURLAsset * asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:reversePath]];
        if (![asset isPlayable]) {
            [self initCircleView];
            [self performSelectorInBackground:@selector(exportReverseVideo:) withObject:[NSURL fileURLWithPath:reversePath]];
        }else {
            _file.reverseVideoURL = [NSURL fileURLWithPath:reversePath];
        }
    }
    
    [self initToolBarView];
    [self initPlayer];
    
    reverseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    reverseBtn.frame = CGRectMake(kWIDTH/3.0, kNavigationBarHeight + kPlayerViewHeight + (kHEIGHT - kNavigationBarHeight - kPlayerViewHeight - (iPhone_X ? 34 : 0) - 50)/2.0, kWIDTH/3.0, 50);
    reverseBtn.backgroundColor = Main_Color;
    reverseBtn.layer.cornerRadius = 5.0;
    [reverseBtn setTitle:RDLocalizedString(@"倒放", nil) forState:UIControlStateNormal];
    [reverseBtn setTitle:RDLocalizedString(@"恢复原视频", nil) forState:UIControlStateSelected];
    [reverseBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [reverseBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    reverseBtn.titleLabel.font = [UIFont systemFontOfSize:15.0];
    [reverseBtn addTarget:self action:@selector(reverseBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:reverseBtn];
}

- (void)initToolBarView{
    UIView *toolBarView = [[UIView alloc] initWithFrame:CGRectMake(0, kPlayerViewOriginX, kWIDTH, 44)];
    toolBarView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:toolBarView];
    
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
    titleLbl.text = RDLocalizedString(@"倒放", nil);
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
        if(_file.isReverse){
            vvAsset.url = _file.reverseVideoURL;
            if (CMTimeRangeEqual(kCMTimeRangeZero, _file.reverseVideoTimeRange)) {
                vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, _file.reverseDurationTime);
            }else{
                vvAsset.timeRange = _file.reverseVideoTimeRange;
            }
            if(CMTimeCompare(vvAsset.timeRange.duration, _file.reverseVideoTrimTimeRange.duration) == 1 && CMTimeGetSeconds(_file.reverseVideoTrimTimeRange.duration)>0){
                vvAsset.timeRange = _file.reverseVideoTrimTimeRange;
            }
        }
        else{
            if (CMTimeRangeEqual(kCMTimeRangeZero, _file.videoTimeRange)) {
                vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, _file.videoDurationTime);
            }else{
                vvAsset.timeRange = _file.videoTimeRange;
            }
            if(!CMTimeRangeEqual(kCMTimeRangeZero, _file.videoTrimTimeRange) && CMTimeCompare(vvAsset.timeRange.duration, _file.videoTrimTimeRange.duration) == 1){
                vvAsset.timeRange = _file.videoTrimTimeRange;
            }
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

-(void)initCircleView
{
    progressHUD = [[RDMBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:progressHUD];
    progressHUD.removeFromSuperViewOnHide = YES;
    progressHUD.mode = RDMBProgressHUDModeDeterminate;
    progressHUD.animationType = RDMBProgressHUDAnimationFade;
    progressHUD.labelText = RDLocalizedString(@"倒放处理中，请稍等...",nil);
    progressHUD.labelFont = [UIFont boldSystemFontOfSize:10];
    progressHUD.isShowCancelBtn = NO;
}

- (void)exportReverseVideo:(NSURL *)videourl{
    [RDVECore exportReverseVideo:_file.contentURL
                       outputUrl:videourl
                       timeRange:_file.videoTimeRange
                      videoSpeed:_file.speed
                   progressBlock:^(NSNumber *prencent) {
                       dispatch_async(dispatch_get_main_queue(), ^{
                           progressHUD.progress = [prencent floatValue];
                       });
                   }
                   callbackBlock:^{
                       dispatch_async(dispatch_get_main_queue(), ^{
                           [progressHUD removeFromSuperview];
                           progressHUD = nil;
                           _file.reverseVideoURL = videourl;
                           if (reverseBtn.selected) {
                               _file.isReverse = YES;
                               [self initPlayer];
                           }
                       });
                   }
                            fail:^{
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    NSLog(@"倒序失败");
                                    [progressHUD removeFromSuperview];
                                    progressHUD = nil;
                                });
                            } cancel:nil];
}

#pragma mark- RDVECoreDelegate
- (void)statusChanged:(RDVECoreStatus)status {
    if (status == kRDVECoreStatusReadyToPlay) {
        [RDSVProgressHUD dismiss];
        [rdPlayer play];
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
    if (!reverseBtn.selected && ![RDHelpClass isSystemPhotoUrl:_file.contentURL]) {
        [self dismissViewControllerAnimated:YES completion:^{
            if(((RDNavigationViewController *)self.navigationController).callbackBlock){
                ((RDNavigationViewController *)self.navigationController).callbackBlock(_file.contentURL.path);
            }
        }];
    }else {
        [self exportMovie];
    }
}

- (void)back{
    [self dismissViewControllerAnimated:YES completion:^{
        if(((RDNavigationViewController *)self.navigationController).cancelHandler){
            ((RDNavigationViewController *)self.navigationController).cancelHandler();
        }
    }];
}

- (void)reverseBtnAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected && progressHUD) {
        [progressHUD show:YES];
    }else {
        _file.isReverse = sender.selected;
        [self initPlayer];
    }
}

- (void)dealloc {
    NSLog(@"%s", __func__);
}

@end
