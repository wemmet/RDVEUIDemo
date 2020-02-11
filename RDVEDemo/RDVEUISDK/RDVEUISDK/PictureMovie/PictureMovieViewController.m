//
//  PictureMovieViewController.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2017/12/1.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "PictureMovieViewController.h"
#import "RDVECore.h"
#import "RDExportProgressView.h"
#import "RDNavigationViewController.h"
#import "RDATMHud.h"
#import "RDATMHudDelegate.h"

@interface PictureMovieViewController ()<RDVECoreDelegate, UIAlertViewDelegate, RDATMHudDelegate>
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

@implementation PictureMovieViewController

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
                [exportProgressView removeFromSuperview];
                exportProgressView = nil;
                [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
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
    playBtn.enabled = YES;
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
    NSMutableArray *photosFrameArray = [NSMutableArray array];
    CGRect frame = CGRectZero;
    frame = CGRectMake(0, 0, 1.0, 1.0);
    [photosFrameArray addObject:[NSValue valueWithCGRect:frame]];
    
    frame = CGRectMake(0, 0, 1/3.0, 0.5);
    [photosFrameArray addObject:[NSValue valueWithCGRect:frame]];
    
    frame = CGRectMake(1/3.0, 0, 1/3.0, 0.5);
    [photosFrameArray addObject:[NSValue valueWithCGRect:frame]];
    
    frame = CGRectMake(1/3.0*2.0, 0, 1/3.0, 0.5);
    [photosFrameArray addObject:[NSValue valueWithCGRect:frame]];
    
    frame = CGRectMake(0, 0.5, 1/4.0, 0.5);
    [photosFrameArray addObject:[NSValue valueWithCGRect:frame]];
    
    frame = CGRectMake(1/4.0, 0.5, 1/4.0, 0.5);
    [photosFrameArray addObject:[NSValue valueWithCGRect:frame]];
    
    frame = CGRectMake(1/4.0*2.0, 0.5, 1/4.0, 0.5);
    [photosFrameArray addObject:[NSValue valueWithCGRect:frame]];
    
    frame = CGRectMake(1/4.0*3.0, 0.5, 1/4.0, 0.5);
    [photosFrameArray addObject:[NSValue valueWithCGRect:frame]];
    
    NSMutableArray *scenes = [NSMutableArray array];
    [scenes addObject:[self getScene:photosFrameArray]];
    [scenes addObject:[self getScene:photosFrameArray]];
    
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

- (RDScene *)getScene:(NSMutableArray *)photosFrameArray {
    float totalDuration = 0.0;
    RDScene *scene = [[RDScene alloc] init];
    for (int i = 0; i < _fileList.count; i++) {
        RDFile *file = _fileList[i];
        
        VVAsset* vvasset = [[VVAsset alloc] init];
        vvasset.url = file.contentURL;
        
        if(file.fileType == kFILEVIDEO){
            vvasset.videoActualTimeRange = file.videoActualTimeRange;
            vvasset.type = RDAssetTypeVideo;
            if(file.isReverse){
                vvasset.url = file.reverseVideoURL;
                if (CMTimeRangeEqual(kCMTimeRangeZero, file.reverseVideoTimeRange)) {
                    vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, file.reverseDurationTime);
                }else{
                    vvasset.timeRange = file.reverseVideoTimeRange;
                }
                if(CMTimeCompare(vvasset.timeRange.duration, file.reverseVideoTrimTimeRange.duration) == 1 && CMTimeGetSeconds(file.reverseVideoTrimTimeRange.duration)>0){
                    vvasset.timeRange = file.reverseVideoTrimTimeRange;
                }
            }
            else{
                if (CMTimeRangeEqual(kCMTimeRangeZero, file.videoTimeRange)) {
                    vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, file.videoDurationTime);
                }else{
                    vvasset.timeRange = file.videoTimeRange;
                }
                if(!CMTimeRangeEqual(kCMTimeRangeZero, file.videoTrimTimeRange) && CMTimeCompare(vvasset.timeRange.duration, file.videoTrimTimeRange.duration) == 1){
                    vvasset.timeRange = file.videoTrimTimeRange;
                }
            }
            vvasset.speed        = file.speed;
            vvasset.volume       = file.videoVolume;
        }else{
            vvasset.type         = RDAssetTypeImage;
            vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, file.imageDurationTime);
            vvasset.speed        = file.speed;
            vvasset.fillType     = RDImageFillTypeFit;
        }
        if (CMTimeGetSeconds(vvasset.timeRange.duration)*vvasset.speed > totalDuration) {
            totalDuration = CMTimeGetSeconds(vvasset.timeRange.duration)*vvasset.speed;
        }
        vvasset.rotate = file.rotate;
        vvasset.isVerticalMirror = file.isVerticalMirror;
        vvasset.isHorizontalMirror = file.isHorizontalMirror;
        vvasset.crop = file.crop;        
        [scene.vvAsset addObject:vvasset];
    }
    
    for (int i = 0; i < scene.vvAsset.count; i++) {
        CGRect frame = [[photosFrameArray objectAtIndex:i] CGRectValue];
        
        VVAsset *vvAsset = [scene.vvAsset objectAtIndex:i];
        
        VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
        VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
        
        VVAssetAnimatePosition *animateOutStart = [[VVAssetAnimatePosition alloc] init];
        animateOutStart.atTime = totalDuration - 1.0;
        animateOutStart.rect = frame;
        animateOutStart.opacity = 1.0;
        
        VVAssetAnimatePosition *animateOutEnd = [[VVAssetAnimatePosition alloc] init];
        animateOutEnd.atTime = totalDuration;
        animateOutEnd.rect = frame;
        animateOutEnd.opacity = 0.0;
        
        switch (i) {
            case 0:
            {
                animateInStart.atTime = 0.0;
                animateInStart.opacity = 0.0;
                animateInStart.fillScale = 5.0;
                
                animateInEnd.atTime = 1.0;
                animateInEnd.opacity = 1.0;
                animateInEnd.fillScale = 2.0;
                
                animateOutStart.fillScale = 2.0;
                animateOutEnd.fillScale = 1.0;
            }
                break;
                
            case 1://平移（推进、推出）
            {
                animateInStart.atTime = 0.0;
                animateInStart.type = AnimationInterpolationTypeDecelerate;
                animateInStart.rect = CGRectMake(-frame.size.width, -frame.size.height, frame.size.width, frame.size.height);
                
                animateInEnd.atTime = 1.0;
                animateInEnd.rect = frame;
            }
                break;
                
            case 2://放大缩小
            {
                animateInStart.atTime = 0.0;
                animateInStart.rect = CGRectMake(frame.origin.x + frame.size.width/2.0, frame.origin.y + frame.size.height/2.0, 0, 0);
                
                animateInEnd.atTime = 1.0;
                animateInEnd.rect = frame;
            }
                break;
                
            case 3://平移同时放大缩小
            {
                animateInStart.atTime = 0.0;
                animateInStart.rect = CGRectMake(1.0, 0.0, 0.0, 0.0);
                
                animateInEnd.atTime = 1.0;
                animateInEnd.rect = frame;
            }
                break;
                
            case 4://旋转
            {
                animateInStart.atTime = 0.0;
                animateInStart.anchorPoint = CGPointMake(0.5, 0.5);
                animateInStart.rotate = 0.0;
                animateInStart.rect = frame;
                
                animateInEnd.atTime = 1.0;
                animateInEnd.anchorPoint = CGPointMake(0.5, 0.5);
                animateInEnd.rotate = 45.0;
                animateInEnd.rect = frame;
                
                animateOutStart.rotate = 45.0;
                animateOutEnd.rotate = 45.0;
            }
                break;
                
            case 5://旋转同时放大缩小
            {
                animateInStart.atTime = 0.0;
                animateInStart.anchorPoint = CGPointMake(0.5, 0.5);
                animateInStart.rotate = 0.0;
                animateInStart.rect = CGRectMake(frame.origin.x + frame.size.width/2.0, frame.origin.y + frame.size.height/2.0, 0.0, 0.0);
                
                animateInEnd.atTime = 1.0;
                animateInEnd.anchorPoint = CGPointMake(0.5, 0.5);
                animateInEnd.rotate = 90.0;
                animateInEnd.rect = frame;
                
                animateOutStart.anchorPoint = CGPointMake(0.5, 0.5);
                animateOutStart.rotate = 90.0;
                
                animateOutEnd.anchorPoint = CGPointMake(0.5, 0.5);
                animateOutEnd.rotate = 90.0;
            }
                break;
                
            case 6://按照一定角度倾斜入场
            {
                animateInStart.atTime = 0.0;
                animateInStart.anchorPoint = CGPointMake(0.5, 0.5);
                animateInStart.rotate = 45.0;
                animateInStart.rect = CGRectMake(frame.origin.x - frame.size.width/2.0, 1.0, frame.size.width, frame.size.height);
                
                animateInEnd.atTime = 1.0;
                animateInEnd.anchorPoint = CGPointMake(0.5, 0.5);
                animateInEnd.rotate = 45.0;
                animateInEnd.rect = frame;
                
                animateOutStart.rotate = 45.0;
                animateOutEnd.rotate = 45.0;
                animateOutEnd.rect = CGRectMake(frame.origin.x + frame.size.width/2.0, 1.0, frame.size.width, frame.size.height);
            }
                break;
                
            case 7://加/减速度入场、出场
            {
                UIBezierPath *path = [UIBezierPath bezierPath];
                path.lineCapStyle = kCGLineCapRound;
                path.lineJoinStyle = kCGLineJoinRound;
                [path moveToPoint:CGPointMake(0, 0)];
                [path addCurveToPoint:CGPointMake(kWIDTH, kWIDTH) controlPoint1:CGPointMake(kWIDTH, 0) controlPoint2:CGPointMake(0, kWIDTH)];
                
                animateInStart.atTime = 0.0;
                animateInStart.anchorPoint = CGPointMake(0.5, 0.5);
                animateInStart.rotate = 45.0;
                animateInStart.rect = CGRectMake(frame.origin.x - frame.size.width/2.0, 1.0, frame.size.width, frame.size.height);
                animateInStart.type = AnimationInterpolationTypeAccelerate;
                animateInStart.path = path;//设置path后，媒体会从path的起点到终点，然后再到animateInEnd.rect
                
                animateInEnd.atTime = 1.0;
                animateInEnd.anchorPoint = CGPointMake(0.5, 0.5);
                animateInEnd.rotate = 45.0;
                animateInEnd.rect = frame;
                
                animateOutStart.rotate = 45.0;
                animateOutStart.type = AnimationInterpolationTypeDecelerate;
                animateOutStart.rect = frame;
                
                animateOutEnd.rotate = 45.0;
                animateOutEnd.rect = CGRectMake(frame.origin.x + frame.size.width/2.0, 1.0, frame.size.width, frame.size.height);
            }
                break;
                
            default:
                break;
        }
        vvAsset.animate = [NSMutableArray arrayWithObjects:animateInStart, animateInEnd, animateOutStart, animateOutEnd, nil];
    }
    scene.transition.type     = RDVideoTransitionTypeMask;
    scene.transition.duration = 1;
    scene.transition.maskURL  = [NSURL fileURLWithPath:[kE2ETransPath stringByAppendingString:@"/007.JPG"]];
    
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
                            [exportProgressView setProgress:progress*100.0 animated:NO];
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
