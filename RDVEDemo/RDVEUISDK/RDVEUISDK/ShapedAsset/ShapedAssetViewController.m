//
//  ShapedAssetViewController.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/5/30.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "ShapedAssetViewController.h"
#import "RDVECore.h"
#import "RDExportProgressView.h"
#import "RDNavigationViewController.h"
#import "RDATMHud.h"
#import "RDATMHudDelegate.h"

@interface ShapedAssetViewController ()<RDVECoreDelegate, UIAlertViewDelegate, RDATMHudDelegate>
{
    UIView                  * titleView;
    RDVECore                * rdPlayer;
    CGSize                    exportVideoSize;
    UIButton                * playBtn;
    RDExportProgressView    * exportProgressView;
    UIAlertView             * commonAlertView;
    RDATMHud                * hud;
    BOOL                      idleTimerDisabled;
}

@end

@implementation ShapedAssetViewController

- (BOOL)prefersStatusBarHidden {
    return !iPhone_X;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [rdPlayer stop];
    rdPlayer.delegate = nil;
    rdPlayer = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)applicationEnterHome:(NSNotification *)notification{
    if(exportProgressView){
        [rdPlayer cancelExportMovie:^{
            //更新UI需在主线程中操作
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
                [exportProgressView removeFromSuperview];
                exportProgressView = nil;
            });
        }];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationController.navigationBarHidden = YES;
    exportVideoSize = CGSizeMake(852, 852);
    
    hud = [[RDATMHud alloc] initWithDelegate:self];
    [self.view addSubview:hud.view];
    
    [self initTitleView];
    [self initPlayer];
    
    playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    playBtn.frame = CGRectMake((kWIDTH - 68)/2.0, titleView.frame.size.height + kWIDTH + (kHEIGHT - titleView.frame.size.height - kWIDTH - 68)/2.0, 68, 68);
    playBtn.backgroundColor = [UIColor clearColor];
    [playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [playBtn addTarget:self action:@selector(playBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    playBtn.enabled = NO;
    [self.view addSubview:playBtn];
}

- (void)initTitleView {
    titleView = [UIView new];
    titleView.frame = CGRectMake(0, 0, kWIDTH, iPhone_X ? 88 : 44);
    titleView.backgroundColor = UIColorFromRGB(NV_Color);
    [self.view addSubview:titleView];
    
    UILabel *titleLbl = [UILabel new];
    titleLbl.frame = CGRectMake(0, (titleView.frame.size.height - 44), kWIDTH, 44);
    titleLbl.textAlignment = NSTextAlignmentCenter;
    titleLbl.backgroundColor = [UIColor clearColor];
    titleLbl.font = [UIFont boldSystemFontOfSize:20];
    titleLbl.textColor = [UIColor whiteColor];
    titleLbl.text = RDLocalizedString(@"照片电影", nil);
    [titleView addSubview:titleLbl];
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.backgroundColor = [UIColor clearColor];
    backBtn.frame = CGRectMake(5, (titleView.frame.size.height - 44), 44, 44);
    [backBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_返回默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:backBtn];
    
    UIButton *publishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    publishBtn.exclusiveTouch = YES;
    publishBtn.backgroundColor = [UIColor clearColor];
    publishBtn.frame = CGRectMake(kWIDTH - 69, (titleView.frame.size.height - 44), 64, 44);
    publishBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [publishBtn setTitleColor:Main_Color forState:UIControlStateNormal];
    [publishBtn setTitle:RDLocalizedString(@"导出", nil) forState:UIControlStateNormal];
    [publishBtn addTarget:self action:@selector(publishBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:publishBtn];
}

- (void)initPlayer {
    NSMutableArray *scenes = [NSMutableArray array];
    [scenes addObject:[self getScene]];
    
    rdPlayer = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                      APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                     LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                      videoSize:exportVideoSize
                                            fps:kEXPORTFPS
                                     resultFail:^(NSError *error) {
                                         NSLog(@"initError:%@", error);
                                     }];
    rdPlayer.frame = CGRectMake(0, titleView.frame.size.height, kWIDTH, kWIDTH);
    rdPlayer.delegate = self;
    [self.view addSubview:rdPlayer.view];
    
    [rdPlayer setScenes:scenes];
    
    NSString *musicPath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"huiyi" Type:@"mp3"];
    RDMusic *music = [[RDMusic alloc] init];
    music.url = [NSURL fileURLWithPath:musicPath];
    AVURLAsset *asset = [AVURLAsset assetWithURL:music.url];
    music.clipTimeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    music.isFadeInOut = YES;
    [rdPlayer setMusics:[NSMutableArray arrayWithObject:music]];
    
    [rdPlayer build];
}

- (RDScene *)getScene {
    RDScene *scene = [[RDScene alloc] init];
    
    VVAsset* vvasset = [[VVAsset alloc] init];
    vvasset.url          = _assetURL;
    if([RDHelpClass isImageUrl:_assetURL]){
        vvasset.type         = RDAssetTypeImage;
        vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(4, TIMESCALE));
        vvasset.fillType     = RDImageFillTypeFull;
    }else {
        vvasset.type         = RDAssetTypeVideo;
        vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, [AVURLAsset assetWithURL:_assetURL].duration);
    }
    
    NSMutableArray *animateArray = [NSMutableArray array];
    for (int k = 0; k < CMTimeGetSeconds(vvasset.timeRange.duration)/4.0; k++) {
        for (int j = 0; j < 4; j++) {
            for (int i = 0; i <= kEXPORTFPS; i++) {
                VVAssetAnimatePosition *animate = [[VVAssetAnimatePosition alloc] init];
                animate.atTime = k*4.0 + j + CMTimeGetSeconds(CMTimeMake(i, kEXPORTFPS));
                if (animate.atTime > CMTimeGetSeconds(vvasset.timeRange.duration)) {
                    break;
                }
                switch (j) {
                    case 0:
                        [animate setPointsLeftTop:CGPointMake(i/100.0, 0.3) rightTop:CGPointMake(0.8, 0.1) rightBottom:CGPointMake(1.0, 1.0) leftBottom:CGPointMake(0.3, 0.6)];
                        break;
                    case 1:
                        [animate setPointsLeftTop:CGPointMake(0.1, 0.3) rightTop:CGPointMake(0.8, i/100.0) rightBottom:CGPointMake(1.0, 1.0) leftBottom:CGPointMake(0.3, 0.6)];
                        break;
                    case 2:
                        [animate setPointsLeftTop:CGPointMake(0.1, 0.3) rightTop:CGPointMake(0.8, 0.1) rightBottom:CGPointMake(1.0 - i/100.0, 1.0) leftBottom:CGPointMake(0.3, 0.6)];
                        break;
                    case 3:
                        [animate setPointsLeftTop:CGPointMake(0.1, 0.3) rightTop:CGPointMake(0.8, 0.1) rightBottom:CGPointMake(1.0, 1.0) leftBottom:CGPointMake(0.3, 1 - i/100.0)];
                        break;

                    default:
                        break;
                }
                [animateArray addObject:animate];
            }
        }
    }
    vvasset.animate = animateArray;
    
    [scene.vvAsset addObject:vvasset];
    
    return scene;
}
     
- (void)initCommonAlertViewWithTitle:(NSString *)title
                             message:(NSString *)message
                   cancelButtonTitle:(NSString *)cancelButtonTitle
                   otherButtonTitles:(NSString *)otherButtonTitles
                        alertViewTag:(NSInteger)alertViewTag
{
    if (commonAlertView) {
        commonAlertView.delegate = nil;
        commonAlertView = nil;
    }
    commonAlertView = [[UIAlertView alloc] initWithTitle:title
                                                 message:message
                                                delegate:self
                                       cancelButtonTitle:cancelButtonTitle
                                       otherButtonTitles:otherButtonTitles, nil];
    commonAlertView.tag = alertViewTag;
    [commonAlertView show];
}

- (void)initProgressView {
    exportProgressView = [[RDExportProgressView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, kHEIGHT)];
    [exportProgressView setProgressTitle:RDLocalizedString(@"视频导出中，请耐心等待...", nil)];
    [exportProgressView setProgress:0 animated:NO];
    [exportProgressView setTrackbackTintColor:UIColorFromRGB(0x545454)];
    [exportProgressView setTrackprogressTintColor:[UIColor whiteColor]];
    exportProgressView.canTouchUpCancel = YES;
    __weak typeof(self) weakself = self;
    exportProgressView.cancelExportBlock = ^(){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself initCommonAlertViewWithTitle:RDLocalizedString(@"视频尚未导出完成，确定取消导出？", nil)
                                           message:nil
                                 cancelButtonTitle:RDLocalizedString(@"取消", nil)
                                 otherButtonTitles:RDLocalizedString(@"确定", nil)
                                      alertViewTag:1];
        });
        
    };
    [self.view addSubview:exportProgressView];
}

- (void)back {
    if(_cancelBlock){
        _cancelBlock();
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)playBtnAction:(UIButton *)sender {
    if([rdPlayer isPlaying]){
        [rdPlayer pause];
        [playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
    }else {
        [rdPlayer play];
        [playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_暂停_@3x" Type:@"png"]] forState:UIControlStateNormal];
    }
}

- (void)publishBtnAction:(UIButton *)sender {
    if(((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration > 0
       && rdPlayer.duration > ((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration){
        
        NSString *maxTime = [RDHelpClass timeToStringNoSecFormat:((float )((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration)];
        NSString *message = [NSString stringWithFormat:RDLocalizedString(@"当前时长超过了导入时长限制%@秒",nil),maxTime];
        [hud setCaption:message];
        [hud show];
        [hud hideAfter:2];
        return;
    }
    if(((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration > 0
       && rdPlayer.duration > ((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration){
        
        NSString *maxTime = [RDHelpClass timeToStringNoSecFormat:((float )((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration)];
        NSString *message = [NSString stringWithFormat:@"%@。%@",[NSString stringWithFormat:RDLocalizedString(@"当前时长超过了导出时长限制%@秒",nil),maxTime],RDLocalizedString(@"您可以关闭本提示去调整，或继续导出。",nil)];
        [self initCommonAlertViewWithTitle:RDLocalizedString(@"温馨提示",nil)
                                   message:message
                         cancelButtonTitle:RDLocalizedString(@"关闭",nil)
                         otherButtonTitles:RDLocalizedString(@"继续",nil)
                              alertViewTag:6];
        return;
    }
    [rdPlayer stop];
    [playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [self initProgressView];
    [RDGenSpecialEffect addWatermarkToVideoCoreSDK:rdPlayer totalDration:rdPlayer.duration exportSize:exportVideoSize exportConfig:((RDNavigationViewController *)self.navigationController).exportConfiguration];
    
    NSString *outputPath = ((RDNavigationViewController *)self.navigationController).outPath;
    if(!outputPath || outputPath.length == 0){
        outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportvideo.mp4"];
    }
    unlink([outputPath UTF8String]);
    idleTimerDisabled = [UIApplication sharedApplication].idleTimerDisabled;
    [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
    
    __weak typeof(self) weakSelf = self;
    [rdPlayer exportMovieURL:[NSURL fileURLWithPath:outputPath]
                        size:exportVideoSize
                     bitrate:((RDNavigationViewController *)self.navigationController).videoAverageBitRate
                         fps:kEXPORTFPS
                audioBitRate:0
         audioChannelNumbers:1
      maxExportVideoDuration:((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration
                    progress:^(float progress) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            StrongSelf(self);
                            [strongSelf->exportProgressView setProgress:progress*100.0 animated:NO];
                        });
                    } success:^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf exportMovieSuc:outputPath];
                        });
                    } fail:^(NSError *error) {
                        NSLog(@"导出失败:%@",error);
                        [weakSelf exportMovieFail];
                        
                    }];
}

- (void)exportMovieFail{
    [exportProgressView removeFromSuperview];
    exportProgressView = nil;
    [[UIApplication sharedApplication] setIdleTimerDisabled: idleTimerDisabled];
    [rdPlayer removeWaterMark];
    [rdPlayer removeEndLogoMark];
    [rdPlayer filterRefresh:kCMTimeZero];
}

- (void)exportMovieSuc:(NSString *)exportPath{
    [exportProgressView removeFromSuperview];
    exportProgressView = nil;
    [[UIApplication sharedApplication] setIdleTimerDisabled: idleTimerDisabled];
    
    if(((RDNavigationViewController *)self.navigationController).callbackBlock){
        ((RDNavigationViewController *)self.navigationController).callbackBlock(exportPath);
    }
    [self.navigationController.childViewControllers[0] dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - RDVECoreDelegate
- (void)statusChanged:(RDVECoreStatus)status {
    if (status == kRDVECoreStatusReadyToPlay) {
        playBtn.enabled = YES;
    }
}

- (void)playToEnd {
    [rdPlayer seekToTime:kCMTimeZero];
    [playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1) {
        if(buttonIndex == 1){
            [self cancelExport];
        }
    }
}

- (void)cancelExport{
    [exportProgressView removeFromSuperview];
    exportProgressView = nil;
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [rdPlayer cancelExportMovie:nil];
}

- (void)dealloc {
    NSLog(@"%s", __func__);
    if (commonAlertView) {
        [commonAlertView dismissWithClickedButtonIndex:0 animated:YES];
        commonAlertView.delegate = nil;
        commonAlertView = nil;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
