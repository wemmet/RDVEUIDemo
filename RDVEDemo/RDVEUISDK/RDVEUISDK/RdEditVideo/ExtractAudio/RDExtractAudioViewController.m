//
//  RDExtractAudioViewController.m
//  RDVEUISDK
//
//  Created by apple on 2019/7/15.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDExtractAudioViewController.h"
#import "RDVECore.h"
#import "NMCutRangeSlider_RD.h"
#import "RDNavigationViewController.h"
#import "RDExportProgressView.h"
#import "RDUICliper.h"
#import "RDGenSpecialEffect.h"
#import "RDZSlider.h"
#import "RDMainViewController.h"

#import "RDExportProgressView.h"
@interface RDExtractAudioViewController ()<RDVECoreDelegate,NMCutRangeSlider_RDDelegate, UIScrollViewDelegate, CropDelegate>
{
    CMTimeRange clipTimeRange;
    CMTimeRange clipSliderTimeRange;
    
    RDVECore         *rdPlayer;
    
    BOOL                      idleTimerDisabled;
    
    UIView *toolBarView;
    RDVECore        *thumbImageVideoCore;//截取缩率图
    BOOL             isResignActive;    //20171026 wuxiaoxia 导出过程中按Home键后会崩溃
    UIButton *finishBtn;
    UILabel *titleLbl;
    
    bool    isThumbImageCore;
}
@property(nonatomic,strong)UIView                       *playerView;         //播放器
@property(nonatomic,strong)NMCutRangeSlider_RD *videoSlider;
@property(nonatomic,strong)UIButton         *playButton;
@property(nonatomic,strong)UIView           *showTimeView;
@property(nonatomic,strong)UILabel          *startTrimLabel;
@property(nonatomic,strong)UILabel          *trimRangeLabel;
@property(nonatomic,strong)UILabel          *endTrimLabel;
@property(nonatomic,assign)CGFloat              selectVideoDuration;

@end

@implementation RDExtractAudioViewController

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

- (void)appEnterForegroundNotification:(NSNotification *)notification{
    isResignActive = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:idleTimerDisabled];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [rdPlayer stop];
}

- (void)applicationDidReceiveMemoryWarningNotification:(NSNotification *)notification{
    NSLog(@"内存占用过高");
}

- (void)applicationEnterHome:(NSNotification *)notification{
    isResignActive = YES;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveMemoryWarningNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [rdPlayer prepare];//20171026 wuxiaoxia 优化内存
    
    if( isThumbImageCore )
    {
        [self initThumbImageVideoCore];
        _videoSlider.videoCoreSDK = thumbImageVideoCore;
        isThumbImageCore = false;
    }
    [_videoSlider loadCutRangeSlider];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = iPhone4s;
    [[UIApplication sharedApplication] setStatusBarHidden:!iPhone_X];
    
    ((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType = SUPPORT_ALL;
    
    [self.view addSubview:self.playerView];
    [self.view addSubview:self.playButton];
    [self initToolBarView];
    
    [self initPlayer];
    
    [self initThumbImageVideoCore];
    
    [self initVideoRangeSlider];
    
    [self.view addSubview:self.showTimeView];
    // Do any additional setup after loading the view.
    if( !_file.filtImagePatch )
        isThumbImageCore = true;
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


- (void)initThumbImageVideoCore{
    if(!thumbImageVideoCore){
        int fps = kEXPORTFPS;
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableMVEffect){
            fps = 15;//20180720 与json文件中一致
        }
        thumbImageVideoCore = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                                     APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                                    LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                                     videoSize:_exportSize
                                                           fps:kEXPORTFPS
                                                    resultFail:^(NSError *error) {
                                                        NSLog(@"initSDKError:%@", error.localizedDescription);
                                                    }];
        thumbImageVideoCore.delegate = self;
    }
    thumbImageVideoCore.frame = _playerView.bounds;
    thumbImageVideoCore.customFilterArray = nil;
    [self refreshRdPlayer:thumbImageVideoCore];
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
    
    [Player setScenes:scenes];
    [Player build];
}

- (void)initPlayer {
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
    if( !rdPlayer )
    {
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
        
        rdPlayer.frame = CGRectMake(0, 0, self.playerView.frame.size.width, self.playerView.frame.size.height);
        rdPlayer.delegate = self;
        
        [self.playerView addSubview:rdPlayer.view];
    }
    [self performSelector:@selector(refreshRdPlayer:) withObject:rdPlayer afterDelay:0.1];
}

- (void)initToolBarView{
    toolBarView = [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT - kToolbarHeight, kWIDTH, kToolbarHeight)];
    toolBarView.backgroundColor = TOOLBAR_COLOR;
    [self.view addSubview:toolBarView];
    
    titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
    titleLbl.text = RDLocalizedString(@"提取音频", nil);
    titleLbl.textColor = [UIColor whiteColor];
    titleLbl.font = [UIFont boldSystemFontOfSize:20.0];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    [toolBarView addSubview:titleLbl];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(0, 0, 44, 44);
    [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:cancelBtn];
    
    finishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    finishBtn.frame = CGRectMake(kWIDTH - 64, 0, 64, 44);
    [finishBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_下一步完成默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [finishBtn addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:finishBtn];
}

- (void)back{
    
    if( _isExtract )
    {
        [self dismissViewControllerAnimated:YES completion:^{
            if( _cancelAction )
                _cancelAction();
        }];
        return;
    }
    
    if( _cancelAction )
        _cancelAction();
    [self.navigationController popViewControllerAnimated:YES];
}
-(void)save{
    if( _isExtract  )
        [self export];
    else
    {
        [self playVideo:NO];
        CMTime start = CMTimeMakeWithSeconds(rdPlayer.duration*_videoSlider.lowerValue, TIMESCALE);
        CMTime endtime = CMTimeMakeWithSeconds(rdPlayer.duration*_videoSlider.upperValue,TIMESCALE);
        if( _finishAction )
            _finishAction(nil, CMTimeRangeMake(start, CMTimeSubtract(endtime, start)) );
        [self.navigationController popViewControllerAnimated:YES];
    }
}

//截取进度条
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
    CGRect videoSliderRect = CGRectMake(26, _playerView.frame.size.height + _playerView.frame.origin.y + 44 + (kHEIGHT - _playerView.frame.origin.y -  _playerView.bounds.size.height - kToolbarHeight - 50 - 44)/2.0 , kWIDTH - 52, 50);
    _videoSlider = [[NMCutRangeSlider_RD alloc] initWithFrame:videoSliderRect];
    _videoSlider.speed = _file.speed;
    _videoSlider.backgroundColor = [UIColor clearColor];
    _videoSlider.delegate = self;
    
    _videoSlider.handProgressTrackMove = ^(float progressTime) {
        
        CMTime currentTime = CMTimeMakeWithSeconds(progressTime,TIMESCALE);
        
        [rdPlayer seekToTime:currentTime];
        
    };
    
    
    
    clipTimeRange = kCMTimeRangeZero;
    clipSliderTimeRange = kCMTimeRangeZero;
    if(_file.isReverse){
        _selectVideoDuration = CMTimeGetSeconds(_file.reverseVideoTimeRange.duration);
        if(_selectVideoDuration == 0 || isnan(_selectVideoDuration)){
            _selectVideoDuration = CMTimeGetSeconds([AVURLAsset assetWithURL:_file.reverseVideoURL].duration);
        }
        clipTimeRange = CMTimeRangeMake(_file.reverseVideoTimeRange.start, CMTimeMakeWithSeconds(_selectVideoDuration, TIMESCALE));
        clipSliderTimeRange = _file.reverseVideoTrimTimeRange;
    }else{
        if (_file.isGif) {
            _selectVideoDuration = CMTimeGetSeconds(_file.imageDurationTime);
            if(_selectVideoDuration == 0 || isnan(_selectVideoDuration)){
                _selectVideoDuration = CMTimeGetSeconds([AVURLAsset assetWithURL:_file.contentURL].duration);
            }
            clipTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(_selectVideoDuration, TIMESCALE));
            if (CMTimeCompare(_file.imageTimeRange.duration, kCMTimeZero) == 1) {
                clipSliderTimeRange = _file.imageTimeRange;
            }else {
                clipSliderTimeRange = clipTimeRange;
            }
        }else {
            _selectVideoDuration = CMTimeGetSeconds(_file.videoTimeRange.duration);
            if(_selectVideoDuration == 0 || isnan(_selectVideoDuration)){
                _selectVideoDuration = CMTimeGetSeconds([AVURLAsset assetWithURL:_file.contentURL].duration);
            }
            clipTimeRange = CMTimeRangeMake(_file.videoTimeRange.start, CMTimeMakeWithSeconds(_selectVideoDuration, TIMESCALE));
            clipSliderTimeRange = _file.videoTrimTimeRange;
        }
    }
    _videoSlider.durationValue = _selectVideoDuration/(float)_file.speed;
    
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
    
    _videoSlider.imageGenerator = [self imageGenerator];
    _videoSlider.mode = true;
    
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
        self.startTrimLabel.text = [RDHelpClass timeToStringFormat:(start1 - start)/_file.speed];
        self.trimRangeLabel.text = [RDHelpClass timeToStringFormat:duration1/_file.speed];
        self.endTrimLabel.text = [RDHelpClass timeToStringFormat:((start1 - start) + duration1)/_file.speed];
        //self.startTrimLabel.text = [RDHelpClass timeToStringFormat:start1/_trimFile.speed];
        //self.trimRangeLabel.text = [RDHelpClass timeToStringFormat:duration1/_trimFile.speed];
        //self.endTrimLabel.text = [RDHelpClass timeToStringFormat:(start1 + duration1)/_trimFile.speed];
    }
    
    CMTime startTime = CMTimeMakeWithSeconds(rdPlayer.duration*_videoSlider.lowerValue, TIMESCALE);
    [rdPlayer seekToTime:startTime toleranceTime:kCMTimeZero completionHandler:nil];
}

- (AVAssetImageGenerator *)imageGenerator{
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:thumbImageVideoCore.composition];
    imageGenerator.videoComposition = thumbImageVideoCore.videoComposition;
    imageGenerator.appliesPreferredTrackTransform = YES;
    
    CGSize siz = CGSizeMake(100*[UIScreen mainScreen].scale, 60*[UIScreen mainScreen].scale);
    imageGenerator.maximumSize = siz;
    
    return imageGenerator;
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
#pragma mark - RDVECoreDelegate
- (void)tapPlayerView{
    [self playVideo:![rdPlayer isPlaying]];
}

- (void)progressCurrentTime:(CMTime)currentTime{
    CMTime time = currentTime;
    if(!rdPlayer.isPlaying){
        return;
    }
    //NSLog(@"%d",time.value/time.timescale);
    if([[NSString stringWithFormat:@"%f", CMTimeGetSeconds(time)] isEqualToString:@"nan"])
    {
        return;
    }
    float progress = CMTimeGetSeconds(time);
    
    CMTime endtime = CMTimeMakeWithSeconds(rdPlayer.duration*_videoSlider.upperValue, TIMESCALE);
    
    if(CMTimeCompare(CMTimeAdd(currentTime, CMTimeMake(1, kEXPORTFPS)), endtime) == 1){
            [self playToEnd];
            return;
    }
    
//    if(!isnan(progress)){
        [_videoSlider progress:progress];
//    }
}

/**播放暂停按键
 */
- (UIButton *)playButton{
    if(!_playButton){
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _playButton.backgroundColor = [UIColor clearColor];
        _playButton.frame = CGRectMake(5, _playerView.frame.origin.y + _playerView.frame.size.height - 44, 44, 44);
        [_playButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
        [_playButton addTarget:self action:@selector(tapPlayButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playButton;
}

/**播放暂停
 */
- (void)tapPlayButton{
    [self playVideo:![rdPlayer isPlaying]];
}

- (void)playToEnd{
    [self playVideo:NO];
    CMTime start = CMTimeMakeWithSeconds(rdPlayer.duration*_videoSlider.lowerValue, TIMESCALE);
    [rdPlayer seekToTime:start toleranceTime:kCMTimeZero completionHandler:nil];    
}

- (void)playVideo:(BOOL)play{
    
    if(!play){
        if([rdPlayer isPlaying]){
            [rdPlayer pause];
        }
        [_playButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
    }else{
        [_playButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateNormal];
        if(![rdPlayer isPlaying]){
            [rdPlayer play];
        }
    }
}

#pragma mark- NMCutRangeSlider_RDDelegate
- (void)NMCutRangeSliderLoadThumbsCompletion {
    [thumbImageVideoCore stop];
    thumbImageVideoCore = nil;
}

- (void)beginScrub:(NMCutRangeSlider_RD *)slider{
    [self playVideo:NO];
}

- (void)scrub:(NMCutRangeSlider_RD *)slider{
    CMTime start = CMTimeMakeWithSeconds(rdPlayer.duration*_videoSlider.lowerValue, TIMESCALE);
    CMTime endtime = CMTimeMakeWithSeconds(rdPlayer.duration*_videoSlider.upperValue,TIMESCALE);
    
    NSLog(@"%f",CMTimeGetSeconds(endtime));
    _startTrimLabel.text = [NSString stringWithFormat:@"%@",[RDHelpClass timeToStringFormat:(CMTimeGetSeconds(start))]];
    _trimRangeLabel.text = [NSString stringWithFormat:@"%@",[RDHelpClass timeToStringFormat:(CMTimeGetSeconds(endtime) - CMTimeGetSeconds(start))]];
    _endTrimLabel.text = [NSString stringWithFormat:@"%@",[RDHelpClass timeToStringFormat:(CMTimeGetSeconds(endtime))]];
    
    if(slider.handleLeft){
        [rdPlayer seekToTime:CMTimeMakeWithSeconds(rdPlayer.duration*_videoSlider.lowerValue, TIMESCALE) toleranceTime:kCMTimeZero completionHandler:nil];
    }else if(slider.handleRight){
        [rdPlayer seekToTime:CMTimeMakeWithSeconds(rdPlayer.duration*_videoSlider.upperValue,TIMESCALE) toleranceTime:kCMTimeZero completionHandler:nil];
    }
}

- (void)endScrub:(NMCutRangeSlider_RD *)slider{
}


//导出
-(void)export
{
    [self playVideo:NO];
    CMTime start = CMTimeMakeWithSeconds(rdPlayer.duration*_videoSlider.lowerValue, TIMESCALE);
    CMTime endtime = CMTimeMakeWithSeconds(rdPlayer.duration*_videoSlider.upperValue,TIMESCALE);
    
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
    [RDVECore video2audiowithtype:_type videoUrl:_file.contentURL trimStart:CMTimeGetSeconds(start) duration:CMTimeGetSeconds(CMTimeSubtract(endtime, start)) outputFolderPath:_outputPath samplerate:_samplerate completion:^(BOOL result, NSString *outputFilePath) {
        if(result){
            NSLog(@"导出音频完成");
            dispatch_async(dispatch_get_main_queue(), ^{
                [RDSVProgressHUD dismiss];
                [self dismissViewControllerAnimated:YES completion:^{
                    if( _finishAction )
                        _finishAction(outputFilePath, CMTimeRangeMake(start, CMTimeSubtract(endtime, start)) );
                }];
            });
        }else{
            NSLog(@"导出音频失败");
            dispatch_async(dispatch_get_main_queue(), ^{
                [RDSVProgressHUD dismiss];
                UIAlertView *alertView = [[UIAlertView alloc]
                                          initWithTitle:RDLocalizedString(@"提示",nil)
                                          message:RDLocalizedString(@"导出音频失败！",nil)
                                          delegate:self
                                          cancelButtonTitle:RDLocalizedString(@"确定",nil)
                                          otherButtonTitles:nil, nil];
                alertView.tag = 2;
                [alertView show];
            });
        }
    }];
}

#pragma mark- UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (alertView.tag) {
        case 2:
            break;
    }
}
@end
