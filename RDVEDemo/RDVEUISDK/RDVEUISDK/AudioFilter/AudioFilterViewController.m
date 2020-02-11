//
//  AudioFilterViewController.m
//  RDVEUISDK
//
//  Created by 周晓林 on 2018/1/13.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "AudioFilterViewController.h"
#import "RDVECore.h"
#import "RDExportProgressView.h"
#import "RDNavigationViewController.h"
#import "RDATMHud.h"
#import "RDATMHudDelegate.h"
#import<objc/runtime.h>

@interface UIButton (BlockButton)
@property (nonatomic,copy) void(^block)(UIButton *sender);
-(void) addTapBlock:(void(^)(UIButton * btn) )block;
@end
@implementation UIButton (BlockButton)
-(void)setBlock:(void(^)(UIButton*))block{
    objc_setAssociatedObject(self,@selector(block), block,OBJC_ASSOCIATION_COPY_NONATOMIC);
    [self addTarget: self action:@selector(click:)forControlEvents:UIControlEventTouchUpInside];
}

-(void(^)(UIButton*))block{
    return objc_getAssociatedObject(self,@selector(block));
}

-(void)addTapBlock:(void(^)(UIButton*))block{
    self.block= block;
    [self addTarget: self action:@selector(click:)forControlEvents:UIControlEventTouchUpInside];
}

-(void)click:(UIButton*)btn{
    if(self.block) {
        self.block(btn);
    }
}
@end

@interface AudioFilterViewController ()<RDVECoreDelegate, UIAlertViewDelegate, RDATMHudDelegate>
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

@implementation AudioFilterViewController

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
    
    if (iPhone4s) {
        [self buildSlider:CGRectMake(10, kWIDTH + 50, kWIDTH, 10) title:@"视频1音量" tag:100];
        [self buildSlider:CGRectMake(10, kWIDTH + 80, kWIDTH, 10) title:@"视频2音量" tag:200];
        [self buildButton:CGRectMake(10, kWIDTH + 100, 30, 20) title:@"视频1音效" tag:110];
        [self buildButton:CGRectMake(kWIDTH/2 + 10, kWIDTH + 100, 30, 20) title:@"视频2音效" tag:210];
        [self buildButton:CGRectMake(10, kWIDTH + 130 , 30, 20) title:@"视频1､2音效" tag:300];
    }else {
        [self buildSlider:CGRectMake(10, kWIDTH + 50, kWIDTH, 10) title:@"视频1音量" tag:100];
        [self buildSlider:CGRectMake(10, kWIDTH + 100, kWIDTH, 10) title:@"视频2音量" tag:200];
        [self buildButton:CGRectMake(10, kWIDTH + 160, 30, 30) title:@"视频1音效" tag:110];
        [self buildButton:CGRectMake(kWIDTH/2 + 10, kWIDTH + 160, 30, 30) title:@"视频2音效" tag:210];
        [self buildButton:CGRectMake(10, kWIDTH + 200 , 30, 30) title:@"视频1､2音效" tag:300];
    }
}

- (void) buildButton:(CGRect) rect title:(NSString*)title tag:(NSInteger) tag{
    
    CGRect labelRect = CGRectMake(rect.origin.x, rect.origin.y, 60, rect.size.height);

    UILabel* label = [[UILabel alloc] initWithFrame:labelRect];
    label.text = RDLocalizedString(@"无效果", nil);
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:16.0];
    [self.view addSubview:label];
    CGRect buttonRect = CGRectMake(rect.origin.x+60, rect.origin.y, kWIDTH/2 - 60, rect.size.height);
    
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = buttonRect;
    button.tag = tag;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16.0];
    button.backgroundColor = [UIColor whiteColor];
    
    [button addTapBlock:^(UIButton *btn) {
        
        if (btn.tag == 300) {
            static int countE = 0;
            
            ++countE;
            
            [rdPlayer setAudioFilter:countE%14 identifier:@"Video0"];
            [rdPlayer setAudioFilter:countE%14 identifier:@"Video1"];
            NSString* effectname = @"";
            switch (countE%14) {
                case 0:
                    effectname = @"无效果";
                    break;
                case 1:
                    effectname = @"男声";
                    break;
                case 2:
                    effectname = @"女声";
                    break;
                case 3:
                    effectname = @"怪兽";
                    break;
                case 4:
                    effectname = @"卡通";
                    break;
                case 5:
                    effectname = @"卡通 快";
                    break;
                case 6:
                    effectname = @"回声";
                    break;
                case 7:
                    effectname = @"混响";
                    break;
                case 8:
                    effectname = @"室内";
                    break;
                case 9:
                    effectname = @"小舞台";
                    break;
                case 10:
                    effectname = @"KTV";
                    break;
                case 11:
                    effectname = @"厂房";
                    break;
                case 12:
                    effectname = @"竞技场";
                    break;
                case 13:
                    effectname = @"电音";
                    break;
                default:
                    break;
            }
            
            label.text = RDLocalizedString(effectname, nil);
            
            
        }else{
            static int countVideo = 0;
            static int countAudio = 0;
            
            NSString* identifier;
            int count = 0;
            if (button.tag == 110) {
                identifier = @"Video0";
                count = ++countVideo;
            }
            if (button.tag == 210) {
                identifier = @"Video1";
                count = ++countAudio;
            }
            
            NSString* effectname = @"";
            switch (count%14) {
                case 0:
                    effectname = @"无效果";
                    break;
                case 1:
                    effectname = @"男声";
                    break;
                case 2:
                    effectname = @"女声";
                    break;
                case 3:
                    effectname = @"怪兽";
                    break;
                case 4:
                    effectname = @"卡通";
                    break;
                case 5:
                    effectname = @"卡通 快";
                    break;
                case 6:
                    effectname = @"回声";
                    break;
                case 7:
                    effectname = @"混响";
                    break;
                case 8:
                    effectname = @"室内";
                    break;
                case 9:
                    effectname = @"小舞台";
                    break;
                case 10:
                    effectname = @"KTV";
                    break;
                case 11:
                    effectname = @"厂房";
                    break;
                case 12:
                    effectname = @"竞技场";
                    break;
                case 13:
                    effectname = @"电音";
                    break;
                default:
                    break;
            }
            
            label.text = RDLocalizedString(effectname, nil);
            
            [rdPlayer setAudioFilter:count%14 identifier:identifier];
        }
        
        
    }];
    [self.view addSubview:button];
}
- (void) audioFilter:(UIButton *) button{
    static int countVideo = 0;
    static int countAudio = 0;
    
    NSString* identifier;
    if (button.tag == 110) {
        identifier = @"Video0";
        
        [rdPlayer setAudioFilter:(++countVideo)%14 identifier:identifier];

        button.titleLabel.text = [NSString stringWithFormat:@"%d",countVideo];
        
    }
    if (button.tag == 210) {
        identifier = @"Video1";
        [rdPlayer setAudioFilter:(++countAudio)%14 identifier:identifier];
        
        button.titleLabel.text = [NSString stringWithFormat:@"%d",countAudio];    }
    
   
}

- (void) buildSlider:(CGRect) rect title:(NSString*)title tag:(NSInteger) tag{
    CGRect labelRect = CGRectMake(rect.origin.x, rect.origin.y, 70, rect.size.height);
    
    UILabel* label = [[UILabel alloc] initWithFrame:labelRect];
    label.text = title;
    label.font = [UIFont systemFontOfSize:14];
    label.textColor = [UIColor whiteColor];
    [self.view addSubview:label];
    
    CGRect sliderRect = CGRectMake(rect.origin.x + 70, rect.origin.y, rect.size.width - rect.origin.x*2.0 - 70, rect.size.height);
    UISlider* slider = [[UISlider alloc] initWithFrame:sliderRect];
    slider.minimumValue = 0.0;
    slider.maximumValue = 1.0;
    slider.value = 1.0;
    slider.continuous = YES;
    slider.tag = tag;
    [slider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
    [slider addTarget:self action:@selector(beginScrubbing:) forControlEvents:UIControlEventTouchDown];
    [slider addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpInside];
    [slider addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpOutside];
    [slider addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchCancel];
    [self.view addSubview:slider];
}

- (void) beginScrubbing:(UISlider *) sender{
    NSString* identifier;
    if (sender.tag == 100) {
        identifier = @"Video0";
    }
    if (sender.tag == 200) {
        identifier = @"Video1";
    }

    float value = sender.value;
    
    [rdPlayer setVolume:value identifier:identifier];
    
}
- (void) scrub:(UISlider *) sender{
    NSString* identifier;
    if (sender.tag == 100) {
        identifier = @"Video0";
    }
    if (sender.tag == 200) {
        identifier = @"Video1";
    }
    
    float value = sender.value;
    
    [rdPlayer setVolume:value identifier:identifier];
    
}
- (void) endScrubbing:(UISlider *) sender{
    NSString* identifier;
    if (sender.tag == 100) {
        identifier = @"Video0";
    }
    if (sender.tag == 200) {
        identifier = @"Video1";
    }
    
    float value = sender.value;
    
    [rdPlayer setVolume:value identifier:identifier];
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
    titleLbl.text = RDLocalizedString(@"音效处理", nil);
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
    [scenes addObject:[self getSecne:photosFrameArray]];
    
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
    rdPlayer.shouldRepeat = YES;
    [self.view addSubview:rdPlayer.view];
    
    
    
    playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    playBtn.frame = CGRectMake((kWIDTH - 68)/2.0, (titleView.frame.size.height + kWIDTH - 68) / 2, 68, 68);
    playBtn.backgroundColor = [UIColor clearColor];
    [playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [playBtn addTarget:self action:@selector(playBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    playBtn.enabled = NO;
    [self.view addSubview:playBtn];
    
    
    [rdPlayer setScenes:scenes];
    
//    NSString *musicPath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"huiyi" Type:@"mp3"];
//    RDMusic *music = [[RDMusic alloc] init];
//    music.url = [NSURL fileURLWithPath:musicPath];
//    music.identifier = @"Music";
//    AVURLAsset *asset = [AVURLAsset assetWithURL:music.url];
//    music.clipTimeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
//    [rdPlayer setMusics:[NSMutableArray arrayWithObject:music]];
    rdPlayer.enableAudioEffect = YES; // 实时调整音量及音频特效时  开启
    [rdPlayer build];
}

- (RDScene *)getSecne:(NSMutableArray *)photosFrameArray {
    float totalDuration = 0.0;
    RDScene *scene = [[RDScene alloc] init];
    for (int i = 0; i < _fileList.count; i++) {
        RDFile *file = _fileList[i];
        
        VVAsset* vvasset = [[VVAsset alloc] init];
        vvasset.url = file.contentURL;
        if (i == 0) {
            vvasset.identifier = @"Video0";
        }else{
            vvasset.identifier = @"Video1";
        }
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
            
        }
        if (CMTimeGetSeconds(vvasset.timeRange.duration)*vvasset.speed > totalDuration) {
            totalDuration = CMTimeGetSeconds(vvasset.timeRange.duration)*vvasset.speed;
        }
        vvasset.rotate = file.rotate;
        vvasset.isVerticalMirror = file.isVerticalMirror;
        vvasset.isHorizontalMirror = file.isHorizontalMirror;
        vvasset.fillType = RDImageFillTypeFit;
        vvasset.crop = file.crop;
        if (i == 0) {
            vvasset.rectInVideo = CGRectMake(0, 0, 0.5, 0.5);
        }else{
            vvasset.rectInVideo = CGRectMake(0.5, 0.5, 0.5, 0.5);
        }
        
        [scene.vvAsset addObject:vvasset];
    }
    
    
    
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
    [rdPlayer pause];
    [self clearRDPlayer];
    
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

- (void)clearRDPlayer {
    [rdPlayer stop];
    [rdPlayer.view removeFromSuperview];
    rdPlayer.delegate = nil;
    rdPlayer = nil;
}

- (void)dealloc {
    rdPlayer.delegate = nil;
    rdPlayer = nil;
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
