//
//  RDCustomDrawViewController.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2019/4/3.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDCustomDrawViewController.h"
#import "RDATMHud.h"
#import "RDMoveProgress.h"
#import "RDVECore.h"
#import "RDExportProgressView.h"
#import "RDNavigationViewController.h"
#import "RDZSlider.h"

@interface RDCustomDrawViewController ()<RDVECoreDelegate>
{
    BOOL                      isResignActive;
    UIView                  * playerView;
    UIButton                * playBtn;
    UIView                  * playerToolBar;
    UILabel                 * currentTimeLabel;
    UILabel                 * durationLabel;
    RDZSlider               * videoProgressSlider;
    RDMoveProgress          * playProgress;
    RDVECore                * rdPlayer;
    CGSize                    exportVideoSize;
    RDExportProgressView    * exportProgressView;
    UIAlertView             * commonAlertView;
    RDATMHud                * hud;
    BOOL                      idleTimerDisabled;
    
    NSMutableArray          <CATextLayer*>* textLayerArray;
}

@end

@implementation RDCustomDrawViewController

- (BOOL)prefersStatusBarHidden {
    return !iPhone_X;
}
- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)applicationEnterHome:(NSNotification *)notification{
    isResignActive = YES;
    if(exportProgressView && [notification.name isEqualToString:UIApplicationDidEnterBackgroundNotification]){
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

- (void)appEnterForegroundNotification:(NSNotification *)notification{
    isResignActive = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    hud = [[RDATMHud alloc] initWithDelegate:self];
    [self.view addSubview:hud.view];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [hud releaseHud];
    hud = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    
    exportVideoSize = CGSizeMake(480, 852);
    [self initTitleView];
    [self initPlayerView];
    [self initPlayer];
    [self initTextLayerArray];
}

- (void)initTitleView {
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, kNavigationBarHeight)];
    [self.view addSubview:titleView];
    
    UILabel *titleLbl = [UILabel new];
    titleLbl.frame = CGRectMake(0, (titleView.frame.size.height - 44), kWIDTH, 44);
    titleLbl.textAlignment = NSTextAlignmentCenter;
    titleLbl.backgroundColor = [UIColor clearColor];
    titleLbl.text = RDLocalizedString(@"自绘", nil);
    titleLbl.font = [UIFont boldSystemFontOfSize:20];
    titleLbl.textColor = UIColorFromRGB(0xffffff);
    [titleView addSubview:titleLbl];
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.exclusiveTouch = YES;
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

- (void)initTextLayerArray {
    textLayerArray = [NSMutableArray array];
    
    CATextLayer *textLayer1 = [self createTextLayerWithSize:CGSizeMake(375, 53) textColor:[UIColor blackColor] textStr:@"静夜思" index:0];
    CATextLayer *textLayer2 = [self createTextLayerWithSize:CGSizeMake(375, 71) textColor:[UIColor redColor] textStr:@"床前明月光" index:1];
    CATextLayer *textLayer3 = [self createTextLayerWithSize:CGSizeMake(375, 96) textColor:[UIColor blackColor] textStr:@"疑是地上霜" index:2];
    CATextLayer *textLayer4 = [self createTextLayerWithSize:CGSizeMake(375, 80) textColor:[UIColor redColor] textStr:@"举头望明月" index:3];
    CATextLayer *textLayer5 = [self createTextLayerWithSize:CGSizeMake(375, 128) textColor:[UIColor blackColor] textStr:@"低头思故乡" index:4];
    [textLayerArray addObject:textLayer1];
    [textLayerArray addObject:textLayer2];
    [textLayerArray addObject:textLayer3];
    [textLayerArray addObject:textLayer4];
    [textLayerArray addObject:textLayer5];
    CATextLayer *layer = [CATextLayer layer];
    layer.bounds = CGRectMake(0, 0, exportVideoSize.width, exportVideoSize.height);
    layer.position = CGPointMake(0, 0);
    layer.anchorPoint = CGPointMake(0, 0);
    layer.backgroundColor = [UIColor clearColor].CGColor;
    [textLayerArray addObject:layer];
    
    [layer addSublayer:textLayer1];
    [layer addSublayer:textLayer2];
    [layer addSublayer:textLayer3];
    [layer addSublayer:textLayer4];
}

- (CATextLayer *)createTextLayerWithSize:(CGSize)size
                               textColor:(UIColor *)textColor
                                 textStr:(NSString *)textStr
                                   index:(int)index
{
    CATextLayer *textLayer = [CATextLayer layer];
    textLayer.backgroundColor = [UIColor clearColor].CGColor;
    textLayer.bounds = CGRectMake(0, 0, size.width, size.height);
    textLayer.position = CGPointMake(0, 0);
    textLayer.anchorPoint = CGPointMake(0, 0);
    textLayer.foregroundColor = textColor.CGColor;
    textLayer.alignmentMode = kCAAlignmentLeft;
    textLayer.wrapped = YES;
    //以Retina方式来渲染，防止画出来的文本模糊
    textLayer.contentsScale = [UIScreen mainScreen].scale;
    textLayer.truncationMode = kCATruncationEnd;
    
    UIFont *font;
    switch (index) {
        case 0:
            font = [UIFont boldSystemFontOfSize:31.0];
            break;
        case 1:
            font = [UIFont boldSystemFontOfSize:44.0];
            break;
        case 2:
            font = [UIFont boldSystemFontOfSize:63.0];
            break;
        case 3:
            font = [UIFont boldSystemFontOfSize:51.0];
            break;
        case 4:
            font = [UIFont boldSystemFontOfSize:72.0];
            break;
            
        default:
            break;
    }
    CFStringRef fontName = (__bridge CFStringRef)font.fontName;
    CGFontRef fontRef = CGFontCreateWithFontName(fontName);
    textLayer.font = fontRef;
    textLayer.fontSize = font.pointSize;
    CGFontRelease(fontRef);
    
    textLayer.string = textStr;
    textLayer.hidden = YES;
    return textLayer;
}

- (void)initPlayerView {
    playerView = [[UIView alloc] initWithFrame:CGRectMake(0, (iPhone_X ? 44 :0) + kNavigationBarHeight, kWIDTH, kHEIGHT - ((iPhone_X ? 44 :0) + kNavigationBarHeight))];
    [self.view addSubview:playerView];
    
    playBtn = [UIButton new];
    playBtn.backgroundColor = [UIColor clearColor];
    playBtn.frame = CGRectMake((playerView.frame.size.width - 56)/2.0, (playerView.frame.size.height - 56)/2.0, 56, 56);
    [playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [playBtn addTarget:self action:@selector(tapPlayButton) forControlEvents:UIControlEventTouchUpInside];
    [playerView addSubview:playBtn];
    
    playerToolBar = [UIView new];
    playerToolBar.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    playerToolBar.frame = CGRectMake(0, playerView.frame.size.height - 44, playerView.frame.size.width, 44);
    playerToolBar.hidden = YES;
    [playerView addSubview:playerToolBar];
    
    durationLabel = [[UILabel alloc] init];
    durationLabel.frame = CGRectMake(playerToolBar.frame.size.width - 45, (playerToolBar.frame.size.height - 20)/2.0, 40, 20);
    durationLabel.textAlignment = NSTextAlignmentRight;
    durationLabel.textColor = UIColorFromRGB(0xffffff);
    durationLabel.font = [UIFont systemFontOfSize:12];
    [playerToolBar addSubview:durationLabel];
    
    currentTimeLabel = [[UILabel alloc] init];
    currentTimeLabel.frame = CGRectMake(5, (playerToolBar.frame.size.height - 20)/2.0, 40, 20);
    currentTimeLabel.text = [RDHelpClass timeToStringNoSecFormat:0.0];
    currentTimeLabel.textAlignment = NSTextAlignmentLeft;
    currentTimeLabel.textColor = UIColorFromRGB(0xffffff);
    currentTimeLabel.font = [UIFont systemFontOfSize:12];
    [playerToolBar addSubview:currentTimeLabel];
    
    videoProgressSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(40, (playerToolBar.frame.size.height - 30)/2.0, playerToolBar.frame.size.width - 80, 30)];
    
    videoProgressSlider.backgroundColor = [UIColor clearColor];
    [videoProgressSlider setMaximumValue:1];
    [videoProgressSlider setMinimumValue:0];
    UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
    image = [image imageWithTintColor];
    [videoProgressSlider setMinimumTrackImage:image forState:UIControlStateNormal];
    image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
    [videoProgressSlider setMaximumTrackImage:image forState:UIControlStateNormal];
    [videoProgressSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
    [videoProgressSlider setValue:0];
    videoProgressSlider.alpha = 1.0;
    
    [videoProgressSlider addTarget:self action:@selector(beginScrub:) forControlEvents:UIControlEventTouchDown];
    [videoProgressSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
    [videoProgressSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchUpInside];
    [videoProgressSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchCancel];
    [playerToolBar addSubview:videoProgressSlider];
    
    playProgress = [[RDMoveProgress alloc] initWithFrame:CGRectMake(0, playerView.frame.size.height - 5,  playerView.frame.size.width, 5)];
    [playProgress setProgress:0 animated:NO];
    [playProgress setTrackTintColor:Main_Color];
    [playProgress setBackgroundColor:UIColorFromRGB(0x888888)];
    [playerView addSubview:playProgress];
}

- (void)initPlayer {
    rdPlayer = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                      APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                     LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                      videoSize:exportVideoSize
                                            fps:kEXPORTFPS
                                     resultFail:^(NSError *error) {
                                         NSLog(@"initSDKError:%@", error.localizedDescription);
                                     }];
    rdPlayer.frame = playerView.bounds;
    rdPlayer.delegate = self;
    [playerView insertSubview:rdPlayer.view atIndex:0];
    
    RDScene *scene = [[RDScene alloc] init];
    VVAsset *asset = [[VVAsset alloc] init];
    asset.type = RDAssetTypeVideo;
    asset.url = [NSURL fileURLWithPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"background" Type:@"mp4"]];
    asset.timeRange = CMTimeRangeMake(kCMTimeZero, [AVURLAsset assetWithURL:asset.url].duration);
    [scene.vvAsset addObject:asset];
    [rdPlayer setScenes:[NSMutableArray arrayWithObject:scene]];
    [rdPlayer build];
}

#pragma mark - 按钮事件
- (void)back {
    [rdPlayer pause];
    [self clearRDPlayer];
    
    if(_cancelBlock){
        _cancelBlock();
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tapPlayButton {
    [self playVideo:![rdPlayer isPlaying]];
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


- (void)exportMovieFail{
    [exportProgressView removeFromSuperview];
    exportProgressView = nil;
    [[UIApplication sharedApplication] setIdleTimerDisabled: idleTimerDisabled];
    [rdPlayer removeWaterMark];
    [rdPlayer removeEndLogoMark];
    [rdPlayer filterRefresh:kCMTimeZero];
}

- (void)exportMovieSuc:(NSString *)exportPath{
    [self clearRDPlayer];
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
        if (!isResignActive) {
            [self playVideo:YES];
        }
    }
}

- (void)progressCurrentTime:(CMTime)currentTime customDrawLayer:(CALayer *)customDrawLayer {
    currentTimeLabel.text = [RDHelpClass timeToStringNoSecFormat:MIN(CMTimeGetSeconds(currentTime), rdPlayer.duration)];
    
    float progress = CMTimeGetSeconds(currentTime)/rdPlayer.duration;
    [videoProgressSlider setValue:progress];
    [playProgress setProgress:progress animated:NO];
    
    if (customDrawLayer.sublayers.count == 0) {
        [customDrawLayer addSublayer:textLayerArray[4]];
        [customDrawLayer addSublayer:textLayerArray[5]];
    }
    textLayerArray[0].hidden = NO;
    if (CMTimeCompare(currentTime, CMTimeMake(127, 30)) == -1) {
        textLayerArray[1].hidden = YES;
    }else {
        textLayerArray[1].hidden = NO;
    }
    if (CMTimeCompare(currentTime, CMTimeMake(210, 30)) == -1)  {
        textLayerArray[2].hidden = YES;
    }else {
        textLayerArray[2].hidden = NO;
    }
    if (CMTimeCompare(currentTime, CMTimeMake(294, 30)) == -1)  {
        textLayerArray[3].hidden = YES;
    }else {
        textLayerArray[3].hidden = NO;
    }
    if (CMTimeCompare(currentTime, CMTimeMake(375, 30)) == -1) {
        textLayerArray[4].hidden = YES;
    }else {
        textLayerArray[4].hidden = NO;
    }
    CGPoint anchor00 = CGPointMake(0.5, 52.5);
    CGPoint anchor10 = CGPointMake(2.222, 66.889);
    CGPoint anchor20 = CGPointMake(2.5, 1.5);
    CGPoint anchor30 = CGPointMake(9.5, 1.5);
    CGPoint anchor40 = CGPointMake(372.5, 126);
    CGPoint anchor50 = CGPointMake(402, 460);
    [self setTextLayerTransform:textLayerArray[5] position:anchor50 rotation:0 scale:CGSizeMake(1, 1) anchor:anchor50];
    
    float current = CMTimeGetSeconds(currentTime);
    if (CMTimeCompare(currentTime, CMTimeMake(127, 30)) == -1) {
        [self setTextLayerTransform:textLayerArray[0] position:CGPointMake(53, 452) rotation:0 scale:CGSizeMake(1, 1) anchor:anchor00];
        textLayerArray[1].transform = CATransform3DIdentity;
        textLayerArray[2].transform = CATransform3DIdentity;
        textLayerArray[3].transform = CATransform3DIdentity;
        textLayerArray[4].transform = CATransform3DIdentity;
    }else if (CMTimeCompare(currentTime, CMTimeMake(127, 30)) >= 0 && CMTimeCompare(currentTime, CMTimeMake(136, 30)) == -1) {
        float factor = (current - CMTimeGetSeconds(CMTimeMake(127, 30))) / (CMTimeGetSeconds(CMTimeMake(135, 30)) - CMTimeGetSeconds(CMTimeMake(127, 30)));
        factor = factor > 1.0 ? 1.0 : factor;
        float rotate = [self rotateMixed:0 b:-1.57 factor:factor];
        CGPoint position = [self CGPointMixed:CGPointMake(53, 452) b:CGPointMake(69, 455) factor:factor];
        [self setTextLayerTransform:textLayerArray[0] position:position rotation:rotate scale:CGSizeMake(1, 1) anchor:anchor00];
        
        rotate = [self rotateMixed:1.5 b:0 factor:factor];
        CGSize scale = [self CGSizeMixed:CGSizeMake(0.1, 0.1) b:CGSizeMake(0.9, 0.9) factor:factor];
        [self setTextLayerTransform:textLayerArray[1] position:CGPointMake(73, 454) rotation:rotate scale:scale anchor:anchor10];
        
        textLayerArray[2].transform = CATransform3DIdentity;
        textLayerArray[3].transform = CATransform3DIdentity;
        textLayerArray[4].transform = CATransform3DIdentity;
    }
    else if (CMTimeCompare(currentTime, CMTimeMake(136, 30)) >= 0 && CMTimeCompare(currentTime, CMTimeMake(210, 30)) == -1) {//136~210
        [self setTextLayerTransform:textLayerArray[0] position:CGPointMake(69, 455) rotation:-1.57 scale:CGSizeMake(1, 1) anchor:anchor00];
        [self setTextLayerTransform:textLayerArray[1] position:CGPointMake(73, 454) rotation:0 scale:CGSizeMake(0.9, 0.9) anchor:anchor10];
        textLayerArray[2].transform = CATransform3DIdentity;
        textLayerArray[3].transform = CATransform3DIdentity;
        textLayerArray[4].transform = CATransform3DIdentity;
    }else if (CMTimeCompare(currentTime, CMTimeMake(210, 30)) >= 0 && CMTimeCompare(currentTime, CMTimeMake(220, 30)) == -1) {//211
        float factor = (current - CMTimeGetSeconds(CMTimeMake(210, 30))) / (CMTimeGetSeconds(CMTimeMake(219, 30)) - CMTimeGetSeconds(CMTimeMake(210, 30)));
        factor = factor > 1.0 ? 1.0 : factor;
        CGPoint position = [self CGPointMixed:CGPointMake(69, 455) b:CGPointMake(69, 374.5) factor:factor];
        CGSize scale = [self CGSizeMixed:CGSizeMake(1, 1) b:CGSizeMake(0.68, 0.68) factor:factor];
        [self setTextLayerTransform:textLayerArray[0] position:position rotation:-1.57 scale:scale anchor:anchor00];
        
        position = [self CGPointMixed:CGPointMake(73, 454) b:CGPointMake(73.25, 374.25) factor:factor];
        scale = [self CGSizeMixed:CGSizeMake(0.9, 0.9) b:CGSizeMake(0.58, 0.58) factor:factor];
        [self setTextLayerTransform:textLayerArray[1] position:position rotation:0 scale:scale anchor:anchor10];
        
        position = [self CGPointMixed:CGPointMake(73.5, 471) b:CGPointMake(73.5, 384) factor:factor];
        scale = [self CGSizeMixed:CGSizeMake(0, 0) b:CGSizeMake(0.87, 0.87) factor:factor];
        [self setTextLayerTransform:textLayerArray[2] position:position rotation:0 scale:scale anchor:anchor20];
        
        textLayerArray[3].transform = CATransform3DIdentity;
        textLayerArray[4].transform = CATransform3DIdentity;
    }
    else if (CMTimeCompare(currentTime, CMTimeMake(220, 30)) >= 0 && CMTimeCompare(currentTime, CMTimeMake(294, 30)) == -1) {//220~294
        [self setTextLayerTransform:textLayerArray[0] position:CGPointMake(69, 374.5) rotation:-1.57 scale:CGSizeMake(0.68, 0.68) anchor:anchor00];
        [self setTextLayerTransform:textLayerArray[1] position:CGPointMake(73.25, 374.25) rotation:0 scale:CGSizeMake(0.58, 0.58) anchor:anchor10];
        [self setTextLayerTransform:textLayerArray[2] position:CGPointMake(73.5, 384) rotation:0 scale:CGSizeMake(0.87, 0.87) anchor:anchor20];
        textLayerArray[3].transform = CATransform3DIdentity;
        textLayerArray[4].transform = CATransform3DIdentity;
    }
    else if (CMTimeCompare(currentTime, CMTimeMake(294, 30)) >= 0 && CMTimeCompare(currentTime, CMTimeMake(305, 30)) == -1) {//295
        float factor = (current - CMTimeGetSeconds(CMTimeMake(294, 30))) / (CMTimeGetSeconds(CMTimeMake(304, 30)) - CMTimeGetSeconds(CMTimeMake(295, 30)));
        factor = factor > 1.0 ? 1.0 : factor;
        CGPoint position = [self CGPointMixed:CGPointMake(69, 374.5) b:CGPointMake(69, 318) factor:factor];
        CGSize scale = [self CGSizeMixed:CGSizeMake(0.68, 0.68) b:CGSizeMake(0.42, 0.42) factor:factor];
        [self setTextLayerTransform:textLayerArray[0] position:position rotation:-1.57 scale:scale anchor:anchor00];
        
        position = [self CGPointMixed:CGPointMake(73.25, 374.25) b:CGPointMake(73.25, 317.75) factor:factor];
        scale = [self CGSizeMixed:CGSizeMake(0.58, 0.58) b:CGSizeMake(0.32, 0.32) factor:factor];
        [self setTextLayerTransform:textLayerArray[1] position:position rotation:0 scale:scale anchor:anchor10];
        
        position = [self CGPointMixed:CGPointMake(73.5, 384) b:CGPointMake(73.5, 327.5) factor:factor];
        scale = [self CGSizeMixed:CGSizeMake(0.87, 0.87) b:CGSizeMake(0.61, 0.61) factor:factor];
        [self setTextLayerTransform:textLayerArray[2] position:position rotation:0 scale:scale anchor:anchor20];
        
        position = [self CGPointMixed:CGPointMake(78, 462) b:CGPointMake(78, 393.5) factor:factor];
        scale = [self CGSizeMixed:CGSizeMake(0.087, 0.087) b:CGSizeMake(0.87, 0.87) factor:factor];
        [self setTextLayerTransform:textLayerArray[3] position:position rotation:0 scale:scale anchor:anchor30];
        
        textLayerArray[4].transform = CATransform3DIdentity;
    }else if (CMTimeCompare(currentTime, CMTimeMake(305, 30)) >= 0 && CMTimeCompare(currentTime, CMTimeMake(375, 30)) == -1) {//305~374
        [self setTextLayerTransform:textLayerArray[0] position:CGPointMake(69, 318) rotation:-1.57 scale:CGSizeMake(0.42, 0.42) anchor:anchor00];
        [self setTextLayerTransform:textLayerArray[1] position:CGPointMake(73.25, 317.75) rotation:0 scale:CGSizeMake(0.32, 0.32) anchor:anchor10];
        [self setTextLayerTransform:textLayerArray[2] position:CGPointMake(73.5, 327.5) rotation:0 scale:CGSizeMake(0.61, 0.61) anchor:anchor20];
        [self setTextLayerTransform:textLayerArray[3] position:CGPointMake(78, 393.5) rotation:0 scale:CGSizeMake(0.87, 0.87) anchor:anchor30];
        textLayerArray[4].transform = CATransform3DIdentity;
    }else if (CMTimeCompare(currentTime, CMTimeMake(375, 30)) >= 0 && CMTimeCompare(currentTime, CMTimeMake(385, 30)) == -1) {//383~384
        [self setTextLayerTransform:textLayerArray[0] position:CGPointMake(69, 318) rotation:-1.57 scale:CGSizeMake(0.42, 0.42) anchor:anchor00];
        [self setTextLayerTransform:textLayerArray[1] position:CGPointMake(73.25, 317.75) rotation:0 scale:CGSizeMake(0.32, 0.32) anchor:anchor10];
        [self setTextLayerTransform:textLayerArray[2] position:CGPointMake(73.5, 327.5) rotation:0 scale:CGSizeMake(0.61, 0.61) anchor:anchor20];
        [self setTextLayerTransform:textLayerArray[3] position:CGPointMake(78, 393.5) rotation:0 scale:CGSizeMake(0.87, 0.87) anchor:anchor30];
        
        float factor = (current - CMTimeGetSeconds(CMTimeMake(375, 30))) / (CMTimeGetSeconds(CMTimeMake(384, 30)) - CMTimeGetSeconds(CMTimeMake(375, 30)));
        factor = factor > 1.0 ? 1.0 : factor;
        CGPoint position = [self CGPointMixed:CGPointMake(402, 460) b:CGPointMake(402, 488) factor:factor];
        float rotate = [self rotateMixed:0 b:1.57 factor:factor];
        [self setTextLayerTransform:textLayerArray[5] position:position rotation:rotate scale:CGSizeMake(1, 1) anchor:anchor50];
        
        position = [self CGPointMixed:CGPointMake(394, 467) b:CGPointMake(394, 481) factor:factor];
        rotate = [self rotateMixed:-1.57 b:0 factor:factor];
        CGSize scale = [self CGSizeMixed:CGSizeMake(0, 0) b:CGSizeMake(0.85, 0.85) factor:factor];
        [self setTextLayerTransform:textLayerArray[4] position:position rotation:rotate scale:scale anchor:anchor40];
    }else {//385
        [self setTextLayerTransform:textLayerArray[0] position:CGPointMake(69, 318) rotation:-1.57 scale:CGSizeMake(0.42, 0.42) anchor:anchor00];
        [self setTextLayerTransform:textLayerArray[1] position:CGPointMake(73.25, 317.75) rotation:0 scale:CGSizeMake(0.32, 0.32) anchor:anchor10];
        [self setTextLayerTransform:textLayerArray[2] position:CGPointMake(73.5, 327.5) rotation:0 scale:CGSizeMake(0.61, 0.61) anchor:anchor20];
        [self setTextLayerTransform:textLayerArray[3] position:CGPointMake(78, 393.5) rotation:0 scale:CGSizeMake(0.87, 0.87) anchor:anchor30];
        [self setTextLayerTransform:textLayerArray[5] position:CGPointMake(402, 488) rotation:1.57 scale:CGSizeMake(1, 1) anchor:anchor50];
        [self setTextLayerTransform:textLayerArray[4] position:CGPointMake(394, 481) rotation:0 scale:CGSizeMake(0.85, 0.85) anchor:anchor40];
    }
}

- (float)rotateMixed:(float)a b:(float)b factor:(float)factor {
    return (a + (b - a)*factor);
}

- (CGPoint)CGPointMixed:(CGPoint)a  b:(CGPoint)b factor:(float)factor {
    float x = a.x + (b.x - a.x) * factor;
    float y = a.y + (b.y - a.y) * factor;
    return CGPointMake(x, y);
}

- (CGSize)CGSizeMixed:(CGSize)a  b:(CGSize)b factor:(float)factor {
    float w = a.width + (b.width - a.width) * factor;
    float h = a.height + (b.height - a.height) * factor;
    return CGSizeMake(w, h);
}

- (void)setTextLayerTransform:(CATextLayer *)textLayer
                     position:(CGPoint)position
                     rotation:(CGFloat)rotation
                        scale:(CGSize)scale
                       anchor:(CGPoint)anchor
{
    CATransform3D baseXform = CATransform3DIdentity;
    CATransform3D translateXform = CATransform3DTranslate(baseXform, position.x, position.y, 0);
    CATransform3D rotateXform = CATransform3DRotate(translateXform, rotation, 0, 0, 1);
    CATransform3D scaleXform = CATransform3DScale(rotateXform, scale.width, scale.height, 1);
    CATransform3D anchorXform = CATransform3DTranslate(scaleXform, -1 * anchor.x, -1 * anchor.y, 0);
    textLayer.transform = anchorXform;
}

- (void)playToEnd{
    [self playVideo:NO];
    
    [rdPlayer seekToTime:kCMTimeZero toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
    [videoProgressSlider setValue:0];
    [playProgress setProgress:0 animated:NO];
}

- (void)tapPlayerView{
    if(playBtn.hidden){
        playBtn.hidden = NO;
        [self playerToolbarShow];
    }else{
        playBtn.hidden = YES;
        [self playerToolbarHidden];
    }
}

#pragma mark - 滑动进度条
/**开始滑动
 */
- (void)beginScrub:(RDZSlider *)slider{
    if([rdPlayer isPlaying]){
        [self playVideo:NO];
    }
}

/**正在滑动
 */
- (void)scrub:(RDZSlider *)slider{
    CGFloat current = videoProgressSlider.value*rdPlayer.duration;
    [rdPlayer seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
    currentTimeLabel.text = [RDHelpClass timeToStringNoSecFormat:current];
    [playProgress setProgress:videoProgressSlider.value animated:NO];
    
}
/**滑动结束
 */
- (void)endScrub:(RDZSlider *)slider{
    
    CGFloat current = videoProgressSlider.value*rdPlayer.duration;
    [rdPlayer seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
}

- (void)playVideo:(BOOL)play{
    if(!play){
        [rdPlayer pause];
        [playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
        playBtn.hidden = NO;
        [self playerToolbarShow];
    }else{
        if (rdPlayer.status != kRDVECoreStatusReadyToPlay || isResignActive) {
            return;
        }
        [rdPlayer play];
        [playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_暂停_@3x" Type:@"png"]] forState:UIControlStateNormal];
        playBtn.hidden = YES;
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerToolbarHidden) object:nil];
        [self performSelector:@selector(playerToolbarHidden) withObject:nil afterDelay:2];
    }
}

- (void)playerToolbarShow{
    playerToolBar.hidden = NO;
    playBtn.hidden = NO;
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerToolbarHidden) object:nil];
    [self performSelector:@selector(playerToolbarHidden) withObject:nil afterDelay:2];
}

- (void)playerToolbarHidden{
//    [UIView animateWithDuration:0.25 animations:^{
//        playerToolBar.hidden = YES;
//        playBtn.hidden = YES;
//    }];
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

- (void)clearRDPlayer {
    [rdPlayer stop];
    [rdPlayer.view removeFromSuperview];
    rdPlayer.delegate = nil;
    rdPlayer = nil;
}

- (void)dealloc {
    NSLog(@"%s", __func__);
}

@end
